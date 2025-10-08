import ballerina/http;
import ballerina/log;

configurable string geminiApiKey = ?;
const string GEMINI_API_URL = "https://generativelanguage.googleapis.com/v1beta";

public isolated client class Client {
    final http:Client geminiClient;

    public isolated function init() returns error? {
        self.geminiClient = check new (GEMINI_API_URL);
        log:printInfo("♊ Gemini AI client initialized");
    }

    # Generate text embeddings using Gemini
    # 
    # + text - The text to vectorize
    # + return - The embedding vector (list of decimals) or error
    remote isolated function generateEmbedding(string text) returns decimal[]|error {
        
        EmbeddingRequest req = {
            content: {
                parts: [text]
            }
        };

        // Construct URL with API key as query param
        string path = "/models/text-embedding-004:embedContent?key=" + geminiApiKey;

        http:Response|error response = self.geminiClient->post(path, req);
        if response is error {
            log:printError("Error calling Gemini API", 'error = response);
            return response;
        }

        if response.statusCode != 200 {
            log:printError("Gemini API failed", status = response.statusCode);
            return error("Gemini API failed: " + check response.getTextPayload());
        }

        json payload = check response.getJsonPayload();
        EmbeddingResponse embeddingResp = check payload.cloneWithType(EmbeddingResponse);
        
        // Return the vector values
        return embeddingResp.embedding.values.values;
    }
}
