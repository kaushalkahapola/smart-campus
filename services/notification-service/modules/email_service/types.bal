# SmtpCredentials is used to store SMTP server credentials
type SmtpCredentials record {|
    # The SMTP server host
    string host;
    # The username for SMTP authentication
    string username;
    # The password for SMTP authentication
    string password;
|};