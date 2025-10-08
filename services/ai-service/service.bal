import ballerina/http;
import ballerina/log;
import ballerina/time;
import ballerina/uuid;
import ai_service.auth;
import ai_service.pinecone;
import ai_service.gemini;

configurable int port = 9096;

# Service response types
type AiRecommendResponse record {|
    *http:Ok;
    record {|
        string message;
        json data;
        string timestamp;
    |} body;
|};

type AiErrorResponse record {|
    *http:InternalServerError;
    record {|
        string errorMessage;
        string? details;
    |} body;
|};

type RecommendRequest record {|
    string query; // e.g., "quiet place for 2 people with whiteboard"
    int limit = 5;
|};

service http:InterceptableService /ai on new http:Listener(port) {

    private final pinecone:Client pineconeClient;
    private final gemini:Client geminiClient;

    public function init() returns error? {
        self.pineconeClient = check new ();
        self.geminiClient = check new ();
        log:printInfo("🤖 AI Service initialized with Gemini + Pinecone");
    }

    public function createInterceptors() returns http:Interceptor[] {
        return [new auth:AuthInterceptor()];
    }

    # Get AI-powered resource recommendations
    # + req - Request containing user query (natural language)
    # + return - List of recommended resources
    resource function post recommend/resources(RecommendRequest req) returns AiRecommendResponse|AiErrorResponse {
        log:printInfo("🤖 AI: Generating recommendations for: " + req.query);
        
        // 1. Vectorize the query using Gemini
        decimal[]|error embedding = self.geminiClient->generateEmbedding(req.query);
        
        if embedding is error {
            log:printError("Failed to generate embedding", 'error = embedding);
            return <AiErrorResponse>{
                body: {
                    errorMessage: "Failed to process query",
                    details: embedding.message()
                }
            };
        }

        // 2. Query Pinecone with the generated vector
        pinecone:QueryRequest queryReq = {
            topK: req.limit,
            vector: check embedding,
            includeMetadata: true
        };

        pinecone:ScoredVector[]|error matches = self.pineconeClient->query(queryReq);
        
        if matches is error {
             log:printError("Pinecone query failed", 'error = matches);
             return <AiErrorResponse>{
                body: {
                    errorMessage: "Failed to retrieve recommendations",
                    details: matches.message()
                }
            };
        }

        return <AiRecommendResponse>{
            body: {
                message: "AI Recommendations generated",
                data: matches.toJson(),
                timestamp: time:utcNow().toString()
            }
        };
    }

    # Generate and store embedding for a resource (Internal/Admin use)
    # + req - Resource details
    # + return - Success message
    resource function post embeddings/create(record {| string id; string text; |} req) returns AiRecommendResponse|AiErrorResponse {
        log:printInfo("🤖 AI: Creating embedding for resource: " + req.id);

        decimal[]|error embedding = self.geminiClient->generateEmbedding(req.text);
        
        if embedding is error {
            return <AiErrorResponse>{ body: { errorMessage: "Embedding generation failed", details: embedding.message() } };
        }

        int|error count = self.pineconeClient->upsert([{
            id: req.id,
            values: check embedding,
            metadata: { "description": req.text }
        }]);

        if count is error {
            return <AiErrorResponse>{ body: { errorMessage: "Vector storage failed", details: count.message() } };
        }

        return <AiRecommendResponse>{
            body: {
                message: "Resource embedding created successfully",
                data: { "id": req.id, "vectorDimensions": (check embedding).length() },
                timestamp: time:utcNow().toString()
            }
        };
    }

    # Get optimal time slot suggestions
    resource function post recommend/times() returns AiRecommendResponse {
        // ... (Simulated for now, could be enhanced with Gemini prediction)
        return <AiRecommendResponse>{
            body: {
                message: "Time slot recommendations",
                data: [
                    { "start": "10:00:00", "end": "11:00:00", "confidence": 0.9 }
                ],
                timestamp: time:utcNow().toString()
            }
        };
    }

    # Health check
    resource function get health() returns http:Ok {
        return {
            body: {
                "status": "UP",
                "service": "ai-service",
                "components": ["pinecone", "gemini-1.5-flash"]
            }
        };
    }
}
