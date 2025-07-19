import ballerina/email;
import ballerina/log;

import notification_service.types;

public isolated function sendVerificationEmail(types:VerificationEmailRequest req) 
        returns types:VerificationEmailResponse | types:InternalServerErrorResponse {
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
            return <types:InternalServerErrorResponse>{
                body: {
                    errorMessage: errorMessage
                }
            };
        }

        return <types:VerificationEmailResponse>{
            body: {
                message: "Verification email sent successfully."
            }
        };
}