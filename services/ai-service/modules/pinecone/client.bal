import ballerina/http;
import ballerina/log;

configurable string pineconeApiKey = ?;
configurable string pineconeIndexHost = ?; // "https://<index-host>.svc.pinecone.io"

public isolated client class Client {
    final http:Client pineconeClient;

    public isolated function init() returns error? {
        self.pineconeClient = check new (pineconeIndexHost,
            config = {
                headers: {
                    "Api-Key": pineconeApiKey,
                    "Content-Type": "application/json"
                }
            }
        );
        log:printInfo("🌲 Pinecone client initialized with host: " + pineconeIndexHost);
    }

    # Upsert vectors to Pinecone
    # 
    # + vectors - List of vectors to upsert
    # + namespace - Optional namespace
    # + return - Number of upserted vectors or error
    remote isolated function upsert(Vector[] vectors, string? namespace = ()) returns int|error {
        UpsertRequest req = {
            vectors: vectors,
            namespace: namespace
        };

        http:Response|error response = self.pineconeClient->post("/vectors/upsert", req);
        if response is error {
            log:printError("Error calling Pinecone upsert", 'error = response);
            return response;
        }

        if response.statusCode != 200 {
            log:printError("Pinecone upsert failed", status = response.statusCode);
            return error("Pinecone upsert failed: " + check response.getTextPayload());
        }

        json payload = check response.getJsonPayload();
        UpsertResponse upsertResp = check payload.cloneWithType(UpsertResponse);
        return upsertResp.upsertedCount;
    }

    # Query vectors in Pinecone
    # 
    # + req - The query request
    # + return - List of matches or error
    remote isolated function query(QueryRequest req) returns ScoredVector[]|error {
        http:Response|error response = self.pineconeClient->post("/query", req);
        if response is error {
            log:printError("Error calling Pinecone query", 'error = response);
            return response;
        }

        if response.statusCode != 200 {
            log:printError("Pinecone query failed", status = response.statusCode);
            return error("Pinecone query failed: " + check response.getTextPayload());
        }

        json payload = check response.getJsonPayload();
        QueryResponse queryResp = check payload.cloneWithType(QueryResponse);
        return queryResp.matches;
    }
}
