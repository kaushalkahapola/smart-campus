import ballerina/log;
import ballerina/http;
import ballerina/url;

configurable string M2MClientId = ?;
configurable string M2MClientSecret = ?;
configurable string authProviderURL = ?;

final http:Client authProviderClient = check new (authProviderURL);

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

# Validates the access token using the oauth2 provider
# + token - The access token to validate
# + return - The payload if valid, or an error if invalid
isolated function validateToken(string token) returns boolean|error {
    http:Response response = check authProviderClient->post("/oauth2/introspect", 
        "token=" + check url:encode(token, "UTF-8"),
        {
            "Authorization": "Basic " + (M2MClientId + ":" + M2MClientSecret).toBytes().toBase64(),
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
