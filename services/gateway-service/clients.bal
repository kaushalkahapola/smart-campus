import ballerina/http;

configurable string userServiceUrl = "http://localhost:9092";
configurable string notificationServiceUrl = "http://localhost:9091";
configurable string resourceServiceUrl = "http://localhost:9093";

final http:Client userServiceClient = check new (userServiceUrl);
final http:Client notificationServiceClient = check new (notificationServiceUrl);
final http:Client resourceServiceClient = check new (resourceServiceUrl);