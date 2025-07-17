# Type for jwt issuer configuration.
type IssuerConfig record {
    # The issuer.
    string issuer;
    # The audience for the token.
    string audience;
    # The expiration time for the token in seconds.
    decimal expTime;
};