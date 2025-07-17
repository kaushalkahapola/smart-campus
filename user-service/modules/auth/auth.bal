import ballerina/crypto;


configurable string salt = ?;

# This function hashes a password using SHA-256.
#
# + password - the password string to be hashed.
# + return - the hashed password as a hexadecimal string or an error if hashing fails.
public isolated function hashPassword(string password) returns string|error {
    // Use the crypto module to hash the password
    byte[] passwordBytes = password.toBytes();
    byte[] hashedBytes = crypto:hashSha256(passwordBytes, salt.toBytes());
    // Convert the hashed bytes to a hexadecimal string
    string hashedPassword = hashedBytes.toString();
    return hashedPassword;
}
