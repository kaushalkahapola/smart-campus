import ballerina/email;
import ballerina/log;

public isolated function sendVerificationEmail(VerificationEmailRequest req) 
        returns boolean | error {
            string:RegExp pattern = re `\{\{verification_link\}\}`;
            string updatedHtml = pattern.replaceAll(verificationEmailBody, req.verificationLink);
            email:Message message = {
            to: req.to,
            subject: req.subject,
            body: req.body,
            htmlBody: updatedHtml
        };

        email:Error? response = smtpClient->sendMessage(message);

        if response is email:Error {
            string errorMessage = "Failed to send verification email: " + response.message();
            log:printError(errorMessage);
            return error(errorMessage);
        }

        return true;
}
