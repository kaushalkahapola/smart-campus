# User info custom type for Asgardeo token.
public type CustomJwtPayload record {
    # User email
    string email;
    # User ID
    string userId;
    # user role
    string role;
};

# Type for jwt issuer configuration.
type IssuerConfig record {|
    # The username for the issuer.
    string username;
    # The issuer.
    string issuer;
    # The audience for the token.
    string audience;
|};

public enum UserRole {
    # Admin role
    ADMIN = "admin",
    # User role
    USER = "user"  
};