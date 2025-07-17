# RegisterUser record type
type RegisterUser record {|
    # Username of the user to be added
    string username;
    # Email address of the user to be added
    string email;
    # Hashed password of the user to be added
    string password;
    # Confirmation of the password for validation
    string confirmPassword;
|};
