import ballerina/http;

import notification_service.email_service;
import notification_service.types;

service  on new http:Listener(9091) {
    resource function post sendVerificationEmail(types:VerificationEmailRequest req) 
        returns types:VerificationEmailResponse | types:InternalServerErrorResponse {
        return email_service:sendVerificationEmail(req);
    }
}
