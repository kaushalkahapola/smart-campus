import ballerina/http;
import ballerina/log;

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
        log:printInfo("M2M Token validation successful");

        ctx.set("m2mToken", accessToken);

        // Continue to the next service
        return ctx.next();
    }
}
