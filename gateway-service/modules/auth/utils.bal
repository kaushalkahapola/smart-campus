import ballerina/http;
import ballerina/jwt;

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

# Validates a JWT token using the configured keystore
# + token - The JWT token to validate
# + return - The JWT payload if valid, or an error if invalid
isolated function validateJwtToken(string token) returns jwt:Payload|error {
    jwt:ValidatorConfig validatorConfig = {
        username: issuerConfig.username,
        issuer: issuerConfig.issuer,
        audience: issuerConfig.audience,
        signatureConfig: {
            trustStoreConfig: {
                trustStore: {
                    path: keystorePath,
                    password: keystorePassword
                },
                certAlias: keystoreAlias
            }
        }
    };
    
    jwt:Payload jwtPayload = check jwt:validate(token, validatorConfig);

    return jwtPayload;
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
