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

# VerificationEmailRequest is used to send a verification email
type VerificationEmailRequest record {|
    # The recipient's email address
    string to;
    # The subject of the email
    string subject;
    # The body of the email in plain text 
    string body;
    # The verificaiton URL
    string verificationLink;
|};

# SmtpCredentials is used to store SMTP server credentials
type SmtpCredentials record {|
    # The SMTP server host
    string host;
    # The username for SMTP authentication
    string username;
    # The password for SMTP authentication
    string password;
|};

# VerificationEmailResponse record type
type VerificationEmailResponse record {|
    *http:Ok;
    # payload
    record {|
        string message;
    |} body;
|};