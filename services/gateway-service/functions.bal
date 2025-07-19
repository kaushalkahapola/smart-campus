import ballerina/http;  

# This function creates a error response for the gateway service
# 
# + return - Returns an `http:Response` with a 500 status code and a JSON payload indicating an internal server error.
isolated function createInternalServerError() returns http:Response {
    http:Response errorResponse = new;
    errorResponse.statusCode = 500;
    errorResponse.setJsonPayload({
        "error": "Internal Server Error"
    });
    return errorResponse;
}

# This function creates a bad request error response for the gateway service
# + message - The error message to include in the response.
# + return - Returns an `http:Response` with a 400 status code and a JSON payload indicating a bad request error.
isolated function createBadRequestError(string message) returns http:Response {
    http:Response errorResponse = new;
    errorResponse.statusCode = 400;
    errorResponse.setJsonPayload({
        "error": "Bad Request",
        "message": message
    });
    return errorResponse;
}

# This function create a Forbidden error response for the gateway service
# + message - The error message to include in the response.
# + return - Returns an `http:Response` with a 403 status code and a JSON payload indicating a forbidden error.
isolated function createForbiddenError(string message) returns http:Response {
    http:Response errorResponse = new;
    errorResponse.statusCode = 403;
    errorResponse.setJsonPayload({
        "error": "Forbidden",
        "message": message
    });
    return errorResponse;
}