import ballerina/http;

service /api on new http:Listener(9090) {

    # This resource function handles user registration requests.
    # 
    # + caller - The HTTP caller to respond to.
    # + req - The HTTP request containing user registration details.
    # + return - Returns an `http:Response` with the result of the registration process
    resource function post user/register(http:Caller caller, http:Request req) returns error? {
        http:Response|error response = userServiceClient->post("/register", req);
        if response is http:Response {
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
}