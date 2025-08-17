import user_service.auth;

import ballerina/http;
import ballerina/log;

# Interceptor to handle errors in the response
service class ErrorInterceptor {
    *http:ResponseErrorInterceptor;

    # This function intercepts errors in the response and handles them.
    # 
    # + err - The error that occurred during the response
    # + ctx - The HTTP request context
    # + return - Returns an HTTP BadRequest response with a custom error message
    remote function interceptResponseError(error err, http:RequestContext ctx) returns http:BadRequest|error {

        // Handle data-binding errors.
        if err is http:PayloadBindingError {
            string customError = string `Payload binding failed!`;
            log:printError(customError, err);
            return {
                body: {
                    message: customError
                }
            };
        }
        return err;
    }
}

service http:InterceptableService / on new http:Listener(9092) {

    public function createInterceptors() returns http:Interceptor[] {
        return [new auth:AuthInterceptor(), new ErrorInterceptor()];
    }

    # This resource is a sample resource to test the service
    #
    # + req - The HTTP request 
    # + return - Returns a sample response from the user service
    resource function get sample(http:Request req) returns string {
        string|error username = req.getHeader("X-User-Id");
        string|error accessToken = req.getHeader("Authorization");
        if username is error || accessToken is error {
            return "Missing headers in request";
        }
        log:printInfo("Received authorization header: " + accessToken.toString());
        log:printInfo(
            "Received request from username: " 
                + username.toString()
        );

        return "This is a sample resource in the user service.";
    }
};
