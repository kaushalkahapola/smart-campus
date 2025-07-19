import user_service.auth;
import user_service.db;
// import user_service.notification;

import ballerina/http;
import ballerina/log;
import ballerina/regex;
import ballerina/uuid;

configurable string gatewayUrl = "http://localhost:9090"; 

service / on new http:Listener(9092) {

    # This resource function handles user registration requests.
    # 
    # + user - The user details to be registered.
    # + return - UserRegisteredResponse|BadRequestResponse|InternalServerErrorResponse|ConflictResponse
    resource function post register(RegisterRequest user)
        returns UserRegisteredResponse|BadRequestResponse|InternalServerErrorResponse|ConflictResponse {
        // check for valid email format with regex
        if (!regex:matches(user.email, "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$")) {
            string errorMessage = "Invalid email format: " + user.email;
            log:printError(errorMessage);
            return <BadRequestResponse>{
                body:{
                    errorMessage
                }
            };
        }

        // check if user already exists in the database
        db:User|error existingUser = db:getUserByEmail(user.email);
        if existingUser is db:User {
            string errorMessage = "User with email " + user.email + " already exists.";
            log:printError(errorMessage);
            return <ConflictResponse>{
                body:{
                    errorMessage
                }
            };
        }

        // check if password and confirmPassword are matching
        if (user.password != user.confirmPassword) {
            string errorMessage = "Passwords do not match.";
            log:printError(errorMessage);
            return <BadRequestResponse>{
                body:{
                    errorMessage
                }
            };
        }

        // check if password is strong enough
        if (!regex:matches(user.password, "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[@$!%*?&])[A-Za-z\\d@$!%*?&]{8,}$")) {
            string errorMessage = "Password must be at least 8 characters long, " +
                                  "contain at least one uppercase letter, " +
                                  "one lowercase letter, one number, and one special character.";
            log:printError(errorMessage);
            return <BadRequestResponse>{
                body:{
                    errorMessage
                }
            };
        }

        // hash the password
        string|error hashedPassword = auth:hashPassword(user.password);
        if hashedPassword is error {
            string errorMessage = "Error hashing password: " + hashedPassword.message();
            log:printError(errorMessage);
            return <InternalServerErrorResponse>{
                body:{
                    errorMessage
                }
            };
        }

        string|error userId = uuid:createType1AsString();

        if userId is error {
            string errorMessage = "UUID generation failed :" + userId.message();
            log:printError(errorMessage);
            return <InternalServerErrorResponse>{
                body:{
                    errorMessage
                }
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
            return <InternalServerErrorResponse>{
                body:{
                    errorMessage
                }
            };
        }

        // create the verification token
        string|error verificationToken = auth:createVerificationToken(userId.toString());
        if verificationToken is error {
            string errorMessage = "Error creating verification token: " + verificationToken.message();
            log:printError(errorMessage);
            return <InternalServerErrorResponse>{
                body:{
                    errorMessage
                }
            };
        }

        string verificationLink = gatewayUrl +  "/api/user/verify?token=" + verificationToken.toString();
        log:printInfo("Verification Link :" + verificationLink.toString());

        // send the verification email
        // error? emailError = notification:sendVerificationEmail(user.email, verificationLink);
        // if emailError is error {
        //     string errorMessage = "Error sending verification email: " + emailError.message();
        //     log:printError(errorMessage);
        //     return <InternalServerErrorResponse>{
        //         body:{
        //             errorMessage
        //         }
        //     };
        // }

        return <UserRegisteredResponse>{
            body: {
                userId: userId,
                message: "User registered successfully. Please check your email for verification link."
            }
        };
    }

    # This resource function handles user verification requests.
    # 
    # + token - The verification token provided by the user.
    # + return - UserVerifiedResponse|BadRequestResponse|InternalServerErrorResponse|UnauthorizedResponse
    resource function get verify(string token) 
        returns UserVerifiedResponse|BadRequestResponse|InternalServerErrorResponse|UnauthorizedResponse {
        // replace the spaces with '+' to handle URL encoding
        string updatedToken = regex:replaceAll(token, " ", "+");
        // Verify the token
        string|error userId = auth:verifyToken(updatedToken);
        if userId is error {
            string errorMessage = "Error verifying token: " + userId.message();
            log:printError(errorMessage);
            return <BadRequestResponse>{
                body: {
                    errorMessage
                }
            };
        }

        db:UpdateUser updateUser = {
            id: userId.toString(),
            isActive: true,
            isVerified: true
        };

        // Token is valid, update user status in the database
        int|error rowsAffected = db:updateUser(updateUser);

        // Check if the update was successful
        if rowsAffected == 0 {
            string errorMessage = "User not found or already verified.";
            log:printError(errorMessage);
            return <UnauthorizedResponse>{
                body: {
                    errorMessage
                }
            };
        } 
        
        if rowsAffected is error {
            string errorMessage = "Error updating user status: " + rowsAffected.message();
            log:printError(errorMessage);
            return <InternalServerErrorResponse>{
                body: {
                    errorMessage
                }
            };
        }

        return <UserVerifiedResponse>{
            body: {
                message: "User verified successfully."
            }
        };
           
    }

    # This function handles the user login process
    # 
    # + req - User login request
    # + return - UserLoginResponse|UnauthorizedResponse|InternalServerErrorResponse|NotFoundResponse
    resource function post login(LoginRequest req) 
        returns UserLoginResponse|UnauthorizedResponse|InternalServerErrorResponse|NotFoundResponse {

        // Get the user by email
        db:User|error user = db:getUserByEmail(req.email);
        if user is error {
            string errorMessage = "User not found";
            log:printError(errorMessage);
            return <NotFoundResponse>{
                body:  {
                    errorMessage
                }
            };
        }

        // Check if the user is verified
        if !user.isVerified {
            string errorMessage = "User not Verified";
            log:printError(errorMessage);
            return <UnauthorizedResponse>{
                body:  {
                    errorMessage
                }
            };
        }

        // Validate the user with the credentials
        boolean|error isValid = auth:validateUser(user.email, user.hashedPassword, req.password);

        if isValid is false|error{
            string errorMessage = "Username and password do not match";
            log:printError(errorMessage);
            return <UnauthorizedResponse>{
                body:  {
                    errorMessage
                }
            };
        }

        // Generating the access token
        string|error jwt = auth:generateJwtToken(
            userId = user.id,
            username = user.username,
            email = user.email,
            role = user.role
        );

        if jwt is error{
            string errorMessage = "Error while creating the jwt token :" + jwt.message();
            log:printError(errorMessage);
            return <InternalServerErrorResponse>{
                body: {
                    errorMessage
                }
            };
        }

        return <UserLoginResponse>{
            body: {
                token: jwt,
                tokenType: "Bearer"
            }
        };
    }

    # This resource is a sample resource to test the service
    #
    # + req - The HTTP request 
    # + return - Returns a sample response from the user service
    resource function get sample(http:Request req) returns string {
        string|error username = req.getHeader("X-User-Id");
        if username is error {
            return "Missing headers in request";
        }
        log:printInfo(
            "Received request from username: " 
                + username.toString()
        );

        return "This is a sample resource in the user service.";
    }
};
