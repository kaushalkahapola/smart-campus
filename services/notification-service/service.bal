import ballerina/http;

service  on new http:Listener(9091) {
    resource function post sample(http:Request req) 
        returns error? {
    }
}
