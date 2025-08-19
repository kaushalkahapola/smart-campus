import ballerina/http;

configurable string userServiceUrl = "http://localhost:9092";
configurable string notificationServiceUrl = "http://localhost:9091";
configurable string resourceServiceUrl = "http://localhost:9093";
configurable string bookingServiceUrl = "http://localhost:9094";

final http:Client userServiceClient = check new (userServiceUrl);
final http:Client notificationServiceClient = check new (notificationServiceUrl);
final http:Client resourceServiceClient = check new (resourceServiceUrl);
final http:Client bookingServiceClient = check new (bookingServiceUrl);