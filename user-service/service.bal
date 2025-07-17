import user_service.auth;
import user_service.db;
import user_service.notification;

import ballerina/http;
import ballerina/log;
import ballerina/regex;
import ballerina/uuid;

service / on new http:Listener(9090) {

    # This resource function handles user registration requests.
    # + user - The user details to be registered.
    # + return - Created | BadRequest | InternalServerError | Conflict.
    resource function post register(RegisterUser user)
        returns http:Created|http:BadRequest|http:InternalServerError|http:Conflict {
        

        log:printInfo("Received registration request for user: " + user.username);

        // Validate the user input
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
        
        log:printInfo("Generated UUID for new user: " + userId.toString());

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

        // send the verification email
        error? emailError = notification:sendVerificationEmail(user.email);
        if emailError is error {
            string errorMessage = "Error sending verification email: " + emailError.message();
            log:printError(errorMessage);
            return <http:InternalServerError>{
                body: errorMessage
            };
        }

        return http:CREATED;
    }
};
