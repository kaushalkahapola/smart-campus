import ballerina/http;

# Notfound Response record type
public type NotFoundResponse record {|
    *http:NotFound;
    # payload 
    record {|
        string errorMessage;
    |} body;
|};

# BadRequest Response record type
public type BadRequestResponse record {|
    *http:BadRequest;
    # payload 
    record {|
        string errorMessage;
    |} body;
|};

# InternalServerError Response record type
public type InternalServerErrorResponse record {|
    *http:InternalServerError;
    # payload 
    record {|
        string errorMessage;
    |} body;
|};

# Conflict Response record type
public type ConflictResponse record {|
    *http:Conflict;
    # payload 
    record {|
        string errorMessage;
    |} body;
|};

# Unauthorized Response record type
public type UnauthorizedResponse record {|
    *http:Unauthorized;
    # payload 
    record {|
        string errorMessage;
    |} body;
|};

# VerificationEmailRequest is used to send a verification email
public type VerificationEmailRequest record {|
    # The recipient's email address
    string to;
    # The subject of the email
    string subject;
    # The body of the email in plain text 
    string body;
    # The verificaiton URL
    string verificationLink;
|};

# VerificationEmailResponse record type
public type VerificationEmailResponse record {|
    *http:Ok;
    # payload
    record {|
        string message;
    |} body;
|};