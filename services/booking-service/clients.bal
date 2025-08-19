import ballerina/http;

configurable string userServiceUrl = "http://localhost:9095";

final http:Client userServiceClient = check new (userServiceUrl);