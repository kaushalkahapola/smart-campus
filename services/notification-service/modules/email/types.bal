# SmtpCredentials is used to store SMTP server credentials
type SmtpCredentials record {|
    # The SMTP server host
    string host;
    # The username for SMTP authentication
    string username;
    # The password for SMTP authentication
    string password;
|};

# VerificationEmailRequest is used to send a verification email
public type VerificationEmailRequest record {|
    # The recipient's email address
    string to;
    # The subject of the email
    string subject;
    # The body of the email in plain text 
    string body;
    # The verification URL
    string verificationLink;
|};