import ballerina/http;
import ballerina/log;
import ballerina/url;
import ballerina/time;

configurable string authProviderURL = ?;
configurable string clientId = ?;
configurable string clientSecret = ?;
configurable string M2MClientId = ?;
configurable string M2MClientSecret = ?;

final http:Client authProviderClient = check new (authProviderURL);

# Checks if the given endpoint is public and doesn't require authentication
# + requestPath - The request path to check
# + return - true if the endpoint is public, false otherwise
isolated function isPublicEndpoint(string requestPath) returns boolean {
    string[] publicEndpoints = [
        "/api/user/register",
        "/api/user/login", 
        "/api/user/verify"
    ];
    
    foreach string endpoint in publicEndpoints {
        if (requestPath.startsWith(endpoint)) {
            return true;
        }
    }
    
    return false;
}

# Validates the access token using the oauth2 provider
# + token - The access token to validate
# + return - The payload if valid, or an error if invalid
isolated function validateToken(string token) returns boolean|error {
    http:Response response = check authProviderClient->post("/oauth2/introspect", 
        "token=" + check url:encode(token, "UTF-8"),
        {
            "Authorization": "Basic " + (clientId + ":" + clientSecret).toBytes().toBase64(),
            "Content-Type": "application/x-www-form-urlencoded"
        }
    );
    log:printInfo("Token introspection response: " + response.statusCode.toString());
    if response.statusCode != 200 {
        log:printError("Token validation failed: " + response.reasonPhrase);
        return error("Token validation failed");
    }
    log:printInfo("Token validation successful: " + response.reasonPhrase);
    return true;
}

# Creates an unauthorized HTTP response
# + message - The error message to include in the response
# + return - An HTTP Forbidden response with the error message
isolated function createUnauthorizedResponse(string message) returns http:Forbidden {
    http:Forbidden forbiddenResponse = {
        body: {
            "error": "Unauthorized",
            "message": message
        }
    };
    return forbiddenResponse;
}

# Gets user information from the token
# 
# + token - The access token
# + return - User information or an error
isolated function getUserInfo(string token) returns json|error {
    http:Response response = check authProviderClient->get("/oauth2/userinfo",
        headers = {
            "Authorization": "Bearer " + token
        }
    );
    log:printInfo("Get user info response: " + response.statusCode.toString());
    if response.statusCode != 200 {
        log:printError("Failed to get user info: " + response.reasonPhrase);
        return error("Failed to get user information");
    }

    json userInfo = check response.getJsonPayload();
    log:printInfo(userInfo.toString());
    log:printInfo("Successfully retrieved user information");
    return userInfo;
}

# Gets or fetches cached user information from the token
# 
# + token - The access token
# + return - User information or an error
isolated function getCachedUserInfo(string token) returns json|error {
    lock {
        // Check if we have cached user info for this token and it's not expired
        UserInfoCache? currentUserCache = cachedUserInfo;
        if currentUserCache is UserInfoCache {
            int currentTime = time:utcNow()[0]; // Get current Unix timestamp
            if currentTime < currentUserCache.expiresAt && currentUserCache.accessToken == token {
                log:printInfo("Using cached user info");
                return currentUserCache.userInfo.clone();
            } else {
                log:printInfo("Cached user info has expired or token changed, fetching new one");
            }
        } else {
            log:printInfo("No cached user info found, fetching new one");
        }

        // Fetch new user info
        http:Response response = check authProviderClient->get("/oauth2/userinfo",
            headers = {
                "Authorization": "Bearer " + token
            }
        );
        
        log:printInfo("Get user info response: " + response.statusCode.toString());
        if response.statusCode != 200 {
            log:printError("Failed to get user info: " + response.reasonPhrase);
            return error("Failed to get user information");
        }

        json userInfo = check response.getJsonPayload();
        int currentTime = time:utcNow()[0];
        
        // Cache the user info for 10 minutes (600 seconds)
        int expiresAt = currentTime + 600;
        
        cachedUserInfo = {
            accessToken: token,
            userInfo: userInfo.clone(),
            expiresAt: expiresAt
        };
        
        log:printInfo("Successfully fetched and cached user information");
        return userInfo.clone();
    }
}

# Generates a new access token using the M2M client credentials
# 
# + return - The new access token or an error
isolated function generateAccessToken() returns string|error {
    http:Response response = check authProviderClient->post("/oauth2/token",
        "grant_type=client_credentials",
        {
            "Authorization": "Basic " + (M2MClientId + ":" + M2MClientSecret).toBytes().toBase64(),
            "Content-Type": "application/x-www-form-urlencoded"
        }
    );
    log:printInfo("Generate access token response: " + response.statusCode.toString());
    if response.statusCode != 200 {
        log:printError("Failed to generate access token: " + response.reasonPhrase);
        return error("Failed to generate access token");
    }

    json payload = check response.getJsonPayload();
    string accessToken = check payload.access_token;
    log:printInfo("Successfully generated access token");
    return accessToken;
}

# Gets or generates a cached M2M access token
# 
# + return - The cached or newly generated access token or an error
isolated function getCachedM2MToken() returns string|error {
    lock {
        // Check if we have a cached token and it's not expired
        TokenCache? currentCache = cachedM2MToken;
        if currentCache is TokenCache {
            int currentTime = time:utcNow()[0]; // Get current Unix timestamp
            if currentTime < currentCache.expiresAt {
                log:printInfo("Using cached M2M token");
                return currentCache.accessToken;
            } else {
                log:printInfo("Cached M2M token has expired, generating new one");
            }
        } else {
            log:printInfo("No cached M2M token found, generating new one");
        }

        // Generate new token
        http:Response response = check authProviderClient->post("/oauth2/token",
            "grant_type=client_credentials",
            {
                "Authorization": "Basic " + (M2MClientId + ":" + M2MClientSecret).toBytes().toBase64(),
                "Content-Type": "application/x-www-form-urlencoded"
            }
        );
        
        log:printInfo("Generate access token response: " + response.statusCode.toString());
        if response.statusCode != 200 {
            log:printError("Failed to generate access token: " + response.reasonPhrase);
            return error("Failed to generate access token");
        }

        json payload = check response.getJsonPayload();
        string accessToken = check payload.access_token;
        
        // Get expires_in from response (default to 3600 seconds if not present)
        json|error expiresInResult = payload.expires_in;
        int expiresIn = expiresInResult is int ? expiresInResult : 3600;
        int currentTime = time:utcNow()[0];
        
        // Cache the token with a 5-minute buffer before actual expiration
        int expiresAt = currentTime + expiresIn - 300; // 300 seconds = 5 minutes buffer
        
        cachedM2MToken = {
            accessToken: accessToken,
            expiresAt: expiresAt
        };
        
        log:printInfo("Successfully generated and cached new M2M token");
        return accessToken;
    }
}

# Clears the cached user information
# This function can be called when a user logs out or when we want to force refresh user info
isolated function clearUserInfoCache() {
    lock {
        cachedUserInfo = ();
        log:printInfo("User info cache cleared");
    }
}

# Clears the cached M2M token
# This function can be called when we want to force refresh the M2M token
isolated function clearM2MTokenCache() {
    lock {
        cachedM2MToken = ();
        log:printInfo("M2M token cache cleared");
    }
}

# Clears all caches
isolated function clearAllCaches() {
    lock {
        cachedUserInfo = ();
    }
    lock {
        cachedM2MToken = ();
    }
    log:printInfo("All caches cleared");
}
