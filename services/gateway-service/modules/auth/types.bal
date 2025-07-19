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

# Type for M2M token cache
public type TokenCache record {|
    # The cached access token
    string accessToken;
    # The expiration time (Unix timestamp in seconds)
    int expiresAt;
|};

# Type for user info cache
public type UserInfoCache record {|
    # The access token used to fetch this user info
    string accessToken;
    # The cached user information
    json userInfo;
    # The expiration time (Unix timestamp in seconds)
    int expiresAt;
|};

# Global variable to store the cached M2M token
isolated TokenCache? cachedM2MToken = ();

# Global variable to store the cached user info
isolated UserInfoCache? cachedUserInfo = ();