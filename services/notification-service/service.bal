import ballerina/http;

import notification_service.email;

service  on new http:Listener(9091) {
    resource function post sendVerificationEmail(email:VerificationEmailRequest req) 
        returns VerificationEmailResponse | InternalServerErrorResponse {
        boolean|error result = email:sendVerificationEmail(req);
        if result is error {
            return <InternalServerErrorResponse>{
                body: {
                    errorMessage: "Failed to send verification email."
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
