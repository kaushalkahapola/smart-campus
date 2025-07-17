# VerificationEmailRequest type 
type VerificationEmailRequest record {|
    # The recipient's email address
    string to;
    # The subject of the email
    string subject;
    # The body of the email
    string body;
    # The verification link to be included in the email
    string verificationLink;
|};