import user_service.auth;
import user_service.db;
import user_service.notification;

import ballerina/http;
import ballerina/log;
import ballerina/regex;
import ballerina/uuid;

configurable string baseUrl = "http://localhost:9090"; 

service / on new http:Listener(9090) {

    # This resource function handles user registration requests.
    # + user - The user details to be registered.
    # + return - Created | BadRequest | InternalServerError | Conflict.
    resource function post register(RegisterUser user)
        returns http:Created|http:BadRequest|http:InternalServerError|http:Conflict {
        // check for valid email format with regex
        if (!regex:matches(user.email, "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$")) {
            string errorMessage = "Invalid email format: " + user.email;
            log:printError(errorMessage);
            return <http:BadRequest>{
                body: errorMessage
            };
        }

        // check if user already exists in the database
        db:User|error existingUser = db:getUserByEmail(user.email);
        if existingUser is db:User {
            string errorMessage = "User with email " + user.email + " already exists.";
            log:printError(errorMessage);
            return <http:Conflict>{
                body: errorMessage
            };
        }

        // check if password and confirmPassword are matching
        if (user.password != user.confirmPassword) {
            string errorMessage = "Passwords do not match.";
            log:printError(errorMessage);
            return <http:BadRequest>{
                body: errorMessage
            };
        }

        // check if password is strong enough
        if (!regex:matches(user.password, "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[@$!%*?&])[A-Za-z\\d@$!%*?&]{8,}$")) {
            string errorMessage = "Password must be at least 8 characters long, contain at least one uppercase letter, one lowercase letter, one number, and one special character.";
            log:printError(errorMessage);
            return <http:BadRequest>{
                body: errorMessage
            };
        }

        // hash the password
        string|error hashedPassword = auth:hashPassword(user.password);
        if hashedPassword is error {
            string errorMessage = "Error hashing password: " + hashedPassword.message();
            log:printError(errorMessage);
            return <http:InternalServerError>{
                body: errorMessage
            };
        }

        string|error userId = uuid:createType1AsString();

        if userId is error {
            string errorMessage = "UUID generation failed";
            log:printError(errorMessage);
            return <http:InternalServerError>{
                body: errorMessage
            };
        }

        // create a new user record
        db:AddUser newUser = {
            id: userId,
            username: user.username,
            hashedPassword: hashedPassword,
            email: user.email
        };

        // Insert the record into the database
        int|error result = db:addUser(newUser);
        if result is error {
            string errorMessage = "Error adding user to the database: " + result.message();
            log:printError(errorMessage);
            return <http:InternalServerError>{
                body: errorMessage
            };
        }

        // create the verification token
        string|error verificationToken = auth:createVerificationToken(userId.toString());
        if verificationToken is error {
            string errorMessage = "Error creating verification token: " + verificationToken.message();
            log:printError(errorMessage);
            return <http:InternalServerError>{
                body: errorMessage
            };
        }

        log:printInfo("Verification Token :" + verificationToken.toString());

        // send the verification email
        error? emailError = notification:sendVerificationEmail(user.email, verificationLink = baseUrl +  "/verify?token=" + verificationToken.toString());
        if emailError is error {
            string errorMessage = "Error sending verification email: " + emailError.message();
            log:printError(errorMessage);
            return <http:InternalServerError>{
                body: errorMessage
            };
        }

        return http:CREATED;
    }

    # This resource function handles user verification requests.
    # It verifies the token provided in the request and updates the user's status in the database.
    # + token - The verification token provided by the user.
    # + return - Ok | BadRequest | InternalServerError | Unauthorized.
    resource function get verify(string token) 
        returns http:Ok|http:BadRequest|http:InternalServerError|http:Unauthorized {
        // replace the spaces with '+' to handle URL encoding
        string updatedToken = regex:replaceAll(token, " ", "+");
        // Verify the token
        string|error userId = auth:verifyToken(updatedToken);
        if userId is error {
            string errorMessage = "Error verifying token: " + userId.message();
            log:printError(errorMessage);
            return <http:BadRequest>{
                body: errorMessage
            };
        }

        // Token is valid, update user status in the database
        int|error rowsAffected = db:updateUserStatus(userId, true);
        if rowsAffected == 0 {
            string errorMessage = "User not found or already verified.";
            log:printError(errorMessage);
            return <http:Unauthorized>{
                body: errorMessage
            };
        } 
        
        if rowsAffected is error {
            string errorMessage = "Error updating user status: " + rowsAffected.message();
            log:printError(errorMessage);
            return <http:InternalServerError>{
                body: errorMessage
            };
        }

        return http:OK;
        
    }
};
