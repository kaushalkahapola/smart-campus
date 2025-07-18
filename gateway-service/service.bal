import ballerina/http;

import gateway_service.auth;
import ballerina/log;

# Interceptor to handle errors in the response
service class ErrorInterceptor {
    *http:ResponseErrorInterceptor;

    # This function intercepts errors in the response and handles them.
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

service http:InterceptableService /api on new http:Listener(9090) {

    public function createInterceptors() returns http:Interceptor[] {
        return [new auth:AuthInterceptor(), new ErrorInterceptor()];
    }

    # This resource function handles user registration requests.
    # 
    # + caller - The HTTP caller to respond to.
    # + req - The HTTP request containing user registration details.
    # + return - Returns an `http:Response` with the result of the registration process
    resource function post user/register(http:Caller caller, http:Request req) returns error? {
        http:Response|error response = userServiceClient->post("/register", req);
        log:printInfo("Received response from user service for registration with status: " + (check response).statusCode.toString());
        if response is http:Response {
            log:printInfo("User registered successfully");
            return caller->respond(response);
        } else {
            return caller->respond(createInternalServerError());
        }
    }

    # This resource function handles user verification requests.
    # 
    # + caller - The HTTP caller to respond to.
    # + req - The HTTP request containing the verification token.
    # + return - Returns an `http:Response` with the result of the verification process
    resource function get user/verify(http:Caller caller, http:Request req) returns error? {
        string? token = req.getQueryParamValue("token");
        if token is string {
            http:Response|error response = userServiceClient->/verify( token = token );
            if response is http:Response {
                return caller->respond(response);
            } else {
                return caller->respond(createInternalServerError());
            }
        } else {
            return caller->respond(createBadRequestError("Missing or invalid token"));
        }
    }

    # This resource function handles user login requests.
    # 
    # + caller - The HTTP caller to respond to.
    # + req - The HTTP request containing user
    # + return - Returns an `http:Response` with the result of the login process
    resource function post user/login(http:Caller caller, http:Request req) returns error? {
        http:Response|error response = userServiceClient->post("/login", req);
        if response is http:Response {
            return caller->respond(response);
        } else {
            return caller->respond(createInternalServerError());
        }
    }

    # This resource function is a sample endpoint to demonstrate the interceptor.
    # It can be removed or modified as needed.
    # + ctx - The HTTP request context
    # + caller - The HTTP caller to respond to.
    # + req - The HTTP request.
    # + return - Returns a sample response from the gateway service
    resource function get sample(http:RequestContext ctx, http:Caller caller, http:Request req) returns error? {
        // Check if the user has the required permissions
        boolean hasPermission = auth:hasRequiredPermissions(
            <auth:UserRole>ctx.get("role").toString(),
            [auth:USER]
        );

        if !hasPermission {
            return caller->respond(createForbiddenError("You do not have permission to access this resource"));
        }

        // Prepare headers for the user service call
        map<string> headers = {
            "x-user-id": ctx.get("userId").toString(),
            "x-email": ctx.get("email").toString(),
            "x-role": ctx.get("role").toString()
        };

        // Call the user service with the prepared headers
        log:printInfo("Headers sent to user service: " + headers.toString());
        http:Response|error response = userServiceClient->get("/sample", headers = headers);
        if response is http:Response {
            return caller->respond(response);
        } else {
            return caller->respond(createInternalServerError());
        }
    }
}