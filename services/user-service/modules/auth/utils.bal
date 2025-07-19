import ballerina/crypto;
import ballerina/time;
import ballerina/mime;
import ballerina/io;
import ballerina/log;
import ballerina/jwt;
import ballerina/http;
import ballerina/url;

configurable string salt = ?;
configurable string keystorePath = ?;
configurable string keystoreAlias = ?;
configurable string keystorePassword = ?;
configurable IssuerConfig issuerConfig = {
    username: "finmate",
    issuer: "finmate",
    audience: "finmate-clients",
    expTime: 3600
};
configurable string M2MClientId = ?;
configurable string M2MClientSecret = ?;
configurable string authProviderURL = ?;

final http:Client authProviderClient = check new (authProviderURL);

# Loads the private key from the keystore.
# + return - the private key if successfully loaded, or an error if loading fails
isolated function loadPrivateKeyFromKeystore() returns crypto:PrivateKey|error {
    crypto:KeyStore keystore = {
        path: keystorePath,
        password: keystorePassword
    };
    return crypto:decodeRsaPrivateKeyFromKeyStore(keystore, keystoreAlias, keystorePassword);
}

# Loads the public key from the keystore.
# + return - the public key if successfully loaded, or an error if loading fails
isolated function loadPublicKeyFromKeystore() returns crypto:PublicKey|error {
    crypto:TrustStore trustStore = {
        path: keystorePath,
        password: keystorePassword
    };
    return crypto:decodeRsaPublicKeyFromTrustStore(trustStore, keystoreAlias);
}

# Hashes a password using SHA-256 and a configurable salt.
# + password - the password to hash
# + return - the hashed password as a Base16 string, or an error if hashing fails
public isolated function hashPassword(string password) returns string|error {
    byte[] passwordBytes = password.toBytes();
    byte[] hashedBytes = crypto:hashSha256(passwordBytes, salt.toBytes());
    return hashedBytes.toBase16();
}

# Creates a signed verification token: `userId:timestamp.signatureBase64`
# + userId - the ID of the user to create the token for
# + return - the signed token as a string, or an error if signing fails
public isolated function createVerificationToken(string userId) returns string|error {
    crypto:PrivateKey privateKey = check loadPrivateKeyFromKeystore();
    time:Utc exp = time:utcAddSeconds(time:utcNow(), 3600); // 1 hour expiry
    string payload = userId + ":" + time:utcToString(exp);
    byte[] payloadBytes = payload.toBytes();
    byte[] signature = check crypto:signRsaSha256(payloadBytes, privateKey);
    string signatureBase64 = signature.toBase64();

    return payload + "." + signatureBase64;
}

# Verifies a signed token and checks expiry.
# + token - the token to verify, formatted as `userId:timestamp.signatureBase64`
# + return - true if the token is valid, false if invalid or expired, or an error if verification fails 
public isolated function verifyToken(string token) returns string|error {
    crypto:PublicKey publicKey = check loadPublicKeyFromKeystore();
    int? dotIndex = token.lastIndexOf(".");
    if dotIndex == () {
        return error("Invalid token format");
    }

    string payload = token.substring(0, dotIndex);
    string encodedSignature = token.substring(dotIndex + 1);

    byte[] payloadBytes = payload.toBytes();
    byte[] encodedSignatureBytes = encodedSignature.toBytes();

    string|byte[]|io:ReadableByteChannel signature = check mime:base64Decode(encodedSignatureBytes);
    if signature is string | io:ReadableByteChannel | error {
        return error("Invalid token signature");
    }

    boolean isValid = check crypto:verifyRsaSha256Signature(payloadBytes, signature, publicKey);
    if !isValid {
        return error("Signature verification failed");
    }

    // Extract userId and timestamp from payload
    int? columnIndex = payload.indexOf(":");
    if columnIndex == () {
        return error("Invalid token payload format");
    }

    string userId = payload.substring(0, columnIndex);
    string timestamp = payload.substring(columnIndex + 1);
    log:printInfo("User ID: " + userId);

    time:Utc exp = check time:utcFromString(timestamp);

    if time:utcNow() > exp {
        return error("Token expired");
    }

    return userId;
}

# Generates a JWT token for the user.
# + userId - the ID of the user to generate the token for
# + username - the username of the user
# + role - the role of the user
# + email - the email of the user
# + return - the generated JWT token as a string, or an error if token generation fails
public isolated function generateJwtToken(string userId, string username, string role, string email) returns string|error {
    jwt:IssuerConfig config = {
        username: issuerConfig.username,
        issuer: issuerConfig.issuer,
        audience: issuerConfig.audience,
        customClaims: {
            "username": username,
            "email": email,
            "userId": userId,
            "role": role
        },
        signatureConfig: {   
            config: {
                keyStore: {
                    path: keystorePath,
                    password: keystorePassword
                },
                keyAlias: keystoreAlias,
                keyPassword: keystorePassword
            }
        }
    };

    string jwtToken = check jwt:issue(config);

    return jwtToken;
}

# Validate the user with email and password
# + email - Email of the user
# + hashedPassword - Hashed password of the user
# + password - Password from reqest
# + return - return the validated user
public isolated function validateUser(string email, string hashedPassword, string password ) 
    returns boolean|error {
    string newHashedPassword = check hashPassword(password);
    if hashedPassword !== newHashedPassword {
        return error("Password do not match");
    }
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