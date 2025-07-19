import ballerina/http;

# Notfound Response record type
type NotFoundResponse record {|
    *http:NotFound;
    # payload 
    record {|
        string errorMessage;
    |} body;
|};

# BadRequest Response record type
type BadRequestResponse record {|
    *http:BadRequest;
    # payload 
    record {|
        string errorMessage;
    |} body;
|};

# InternalServerError Response record type
type InternalServerErrorResponse record {|
    *http:InternalServerError;
    # payload 
    record {|
        string errorMessage;
    |} body;
|};

# Conflict Response record type
type ConflictResponse record {|
    *http:Conflict;
    # payload 
    record {|
        string errorMessage;
    |} body;
|};

# Unauthorized Response record type
type UnauthorizedResponse record {|
    *http:Unauthorized;
    # payload 
    record {|
        string errorMessage;
    |} body;
|};

# RegisterUser record type
type RegisterRequest record {|
    # Username of the user to be added
    string username;
    # Email address of the user to be added
    string email;
    # Hashed password of the user to be added
    string password;
    # Confirmation of the password for validation
    string confirmPassword;
|};

# LoginRequest record type
type LoginRequest record {|
    # Email of the user
    string email;
    # Password of the user
    string password;
|};

# UserRegisteredResponse record type
type UserRegisteredResponse record {|
    *http:Created;
    # payload 
    record {|
        string userId;
        string message;
    |} body;
|};    

# UserVerifiedResponse record type
type UserVerifiedResponse record {|
    *http:Ok;
    # payload 
    record {|
        string message;
    |} body;
|};

# UserLoginResponse record type
type UserLoginResponse record {|
    *http:Ok;
    # payload 
    record {|
        string token;
        string tokenType;
    |} body;
|};