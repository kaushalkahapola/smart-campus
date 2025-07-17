import ballerina/http;

# This function sends a verification email to the user.
#
# + email - the email address of the user to send the verification email to
# + return - an error if the email could not be sent
public isolated function sendVerificationEmail(string email) returns error? {
    VerificationEmailRequest payload = {
        to: email,
        subject: "Verify Your Email - FinMate",
        body: "Hi,\nThanks for registering. Please verify your email."
    };

    http:Response|error resp = notificationClient->post("/sendVerificationEmail", payload);
    if resp is error {
        return error("Failed to send email: " + resp.message());
    }

    return;
}
