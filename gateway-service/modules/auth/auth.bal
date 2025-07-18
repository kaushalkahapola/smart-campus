import ballerina/http;
import ballerina/jwt;
import ballerina/log;

configurable string keystorePath = ?;
configurable string keystoreAlias = ?;
configurable string keystorePassword = ?;
configurable IssuerConfig issuerConfig = {
    username: "finmate",
    issuer: "finmate",
    audience: "finmate-clients"
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
        if (isPublicEndpoint(requestPath)) {
            return ctx.next();
        }
        
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
        
        // Extract JWT token
        string jwtToken = authHeader.substring(7); // Remove "Bearer " prefix
        
        // Validate JWT token
        jwt:Payload|error jwtPayload = validateJwtToken(jwtToken);
        if (jwtPayload is error) {
            log:printError("JWT validation failed: " + jwtPayload.message());
            return createUnauthorizedResponse("Invalid or expired token");
        }
        log:printInfo("JWT validation successful: " + jwtPayload.toString());

        string userId = jwtPayload["userId"].toString();
        string email = jwtPayload["email"].toString();
        string role = jwtPayload["role"].toString();
        
        // Add user information to request context for downstream services
        ctx.set("userId", userId);
        ctx.set("email", email);
        ctx.set("role", role);

        log:printInfo("User authenticated successfully: " + email);

        // Continue to the next service
        return ctx.next();
    }
}
