import ballerina/http;

configurable string userServiceUrl = "http://localhost:9092";

final http:Client userServiceClient = check new (userServiceUrl);