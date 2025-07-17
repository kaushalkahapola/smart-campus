import ballerina/email;

configurable SmtpCredentials smtpCredentials = ?;

final email:SmtpClient smtpClient = check new (
    smtpCredentials.host,
    smtpCredentials.username,
    smtpCredentials.password
);

