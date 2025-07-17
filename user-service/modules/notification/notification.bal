import ballerina/http;

# This function sends a verification email to the user.
#
# + email - the email address of the user to send the verification email to
# + verificationLink - the link to be included in the email for verification
# + return - an error if the email could not be sent
public isolated function sendVerificationEmail(string email, string verificationLink) returns error? {
    VerificationEmailRequest payload = {
        to: email,
        subject: "Verify Your Email - FinMate",
        body: "Hi,\nThanks for registering. Please verify your email.",
        verificationLink: verificationLink
    };

    http:Response|error resp = notificationClient->post("/sendVerificationEmail", payload);
    if resp is error {
        return error("Failed to send email: " + resp.message());
    }

    return;
}
