import ballerina/crypto;
import ballerina/time;
import ballerina/regex;
import ballerina/mime;
import ballerina/io;

configurable string salt = ?;
configurable string keystorePath = ?;
configurable string keystoreAlias = ?;
configurable string keystorePassword = ?;

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
public isolated function verifyToken(string token) returns boolean|error {
    crypto:PublicKey publicKey = check loadPublicKeyFromKeystore();
    string[] parts = regex:split(token, "\\.");
    if parts.length() != 2 {
        return false;
    }

    string payload = parts[0];
    byte[] payloadBytes = payload.toBytes();

    // Decode signature from Base64
    string|byte[]|io:ReadableByteChannel signature = check mime:base64Decode(parts[1]);

    if signature is string | io:ReadableByteChannel |  error {
        return false;
    }

    // Verify signature
    boolean isValid = check crypto:verifyRsaSha256Signature(payloadBytes, signature, publicKey);
    if !isValid {
        return false;
    }

    // Split payload: userId:timestamp
    string[] payloadParts = regex:split(payload, ":");
    if payloadParts.length() != 2 {
        return false;
    }

    // Validate expiration time
    time:Utc exp = check time:utcFromString(payloadParts[1]);
    if time:utcNow() > exp {
        return false;
    }

    return true;
}

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