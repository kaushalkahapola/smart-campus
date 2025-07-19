import ballerina/http;
// import ballerina/jwt;
// import ballerina/oauth2;
import ballerina/log;
import ballerina/url;

configurable string asgardeoURL = ?;
configurable string clientId = ?;
configurable string clientSecret = ?;

final http:Client asgardeoClient = check new (asgardeoURL);

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
    http:Response response = check asgardeoClient->post("/oauth2/introspect", 
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
    http:Response response = check asgardeoClient->get("/oauth2/userinfo",
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