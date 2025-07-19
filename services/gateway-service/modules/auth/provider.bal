import ballerina/oauth2;

configurable string clientId = ?;
configurable string clientSecret = ?;
configurable string introspectionUrl = ?;

# Creates an OAuth2 provider for token introspection
# 
# + return - An instance of `oauth2:ListenerOAuth2Provider` configured for introspection
isolated function getOauth2Provider() returns oauth2:ListenerOAuth2Provider {
    string authHeader = clientId + ":" + clientSecret;
    byte [] authHeaderBytes = authHeader.toBytes();
    string base64AuthHeader = authHeaderBytes.toBase64();
    
    oauth2:ClientConfiguration clientConfig = {
        customHeaders: {
            "Authorization": "Basic " + base64AuthHeader,
            "Content-Type": "application/x-www-form-urlencoded"            
        }
    };
    
    oauth2:IntrospectionConfig config = {
        url: introspectionUrl,
        clientConfig: clientConfig
    };
    
    return new(config);
}

final oauth2:ListenerOAuth2Provider provider = getOauth2Provider();