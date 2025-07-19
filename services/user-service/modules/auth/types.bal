# Type for jwt issuer configuration.
type IssuerConfig record {
    # The username for the issuer.
    string username;
    # The issuer.
    string issuer;
    # The audience for the token.
    string audience;
    # The expiration time for the token in seconds.
    decimal expTime;
};