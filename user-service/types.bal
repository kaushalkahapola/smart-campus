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
type LoginResuest record {|
    # Email of the user
    string email;
    # Password of the user
    string password;
|};
