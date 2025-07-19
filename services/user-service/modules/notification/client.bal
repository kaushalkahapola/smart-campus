import ballerina/http;

configurable string notificationServiceUrl = "http://localhost:9091";

final http:Client notificationClient = check new (notificationServiceUrl);