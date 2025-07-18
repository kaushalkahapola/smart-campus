import ballerina/http;

configurable string userServiceUrl = "http://localhost:9092";
configurable string notificationServiceUrl = "http://localhost:9091";

final http:Client userServiceClient = check new (userServiceUrl);
final http:Client notificationServiceClient = check new (notificationServiceUrl);