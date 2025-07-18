import ballerina/http;
import ballerina/email;
import ballerina/log;

service  on new http:Listener(9091) {
    resource function post sendVerificationEmail(VerificationEmailRequest req) 
        returns VerificationEmailResponse | InternalServerErrorResponse {
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
            return <InternalServerErrorResponse>{
                body: {
                    errorMessage: errorMessage
                }
            };
        }

        return <VerificationEmailResponse>{
            body: {
                message: "Verification email sent successfully."
            }
        };
    }
}
