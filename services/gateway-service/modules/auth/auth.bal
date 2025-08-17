import ballerina/http;
import ballerina/log;

public configurable AppRoles authorizedRoles = {
    Admin: "admin",
    Staff: "staff",
    Student: "student"
};

# Interceptor to handle authentication
public isolated service class AuthInterceptor {
    *http:RequestInterceptor;

    # This function intercepts incoming requests to validate JWT tokens.
    # 
    # + ctx - The HTTP request context
    # + req - The HTTP request
    # + return - Returns an HTTP response indicating whether the request is authorized or not
    isolated resource function default [string... path](http:RequestContext ctx, http:Request req)
        returns http:NextService|http:Forbidden|http:InternalServerError|error? {
        
        // Extract the request path to determine if authentication is required
        string requestPath = req.rawPath;
        
        // Public endpoints that don't require authentication
        if (!isPublicEndpoint(requestPath)) {
            // Extract Authorization header
            string|http:HeaderNotFoundError authHeader = req.getHeader("Authorization");
            if (authHeader is http:HeaderNotFoundError) {
                log:printError("Missing Authorization header");
                return createUnauthorizedResponse("Missing Authorization header");
            }
            
            // Validate Bearer token format
            if (!authHeader.startsWith("Bearer ")) {
                log:printError("Invalid Authorization header format");
                return createUnauthorizedResponse("Invalid Authorization header format");
            }
            
            // Extract access token
            string accessToken = authHeader.substring(7); // Remove "Bearer " prefix

            // Validate access token
            boolean|error isvalid = validateToken(accessToken);
            if (isvalid is error) {
                log:printError("Token validation failed: " + isvalid.message());
                return createUnauthorizedResponse("Invalid or expired token");
            }
            log:printInfo("Token validation successful");
            json|error jwtPayload = getCachedUserInfo(accessToken);
            if (jwtPayload is error) {
                log:printError("JWT validation failed: " + jwtPayload.message());
                return createUnauthorizedResponse("Invalid JWT token");
            }
            log:printInfo("JWT payload retrieved: " + jwtPayload.toString());

            // Add user information to request context for downstream services
            if (jwtPayload is map<json>) {
                json|error username = jwtPayload["username"];
                json|error userId = jwtPayload["sub"];
                json|error groups = jwtPayload["groups"]; // Asgardeo roles come in 'groups' claim
                
                if (username is string && userId is string) {
                    ctx.set("username", username);
                    ctx.set("userId", userId);
                    
                    // Set user groups for downstream services
                    if (groups is json[]) {
                        ctx.set("userGroups", groups.toString());
                    } else {
                        ctx.set("userGroups", "[]"); // Empty array string if no groups
                    }
                } else {
                    log:printError("Username not found or invalid in JWT payload");
                    return createUnauthorizedResponse("Invalid JWT payload");
                }
            } else {
                log:printError("JWT payload is not a valid map");
                return createUnauthorizedResponse("Invalid JWT payload format");
            }

            log:printInfo("User authenticated successfully: ");
        }

        // Generate a new access token for M2M communication using cache
        string m2mToken = check getCachedM2MToken();
        ctx.set("m2mToken", m2mToken);

        // Continue to the next service
        return ctx.next();
    }
}
