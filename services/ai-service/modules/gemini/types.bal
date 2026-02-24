
# Request for embedding generation
public type EmbeddingRequest record {|
    string model = "models/text-embedding-004";
    record {|
        string[] parts;
    |} content;
|};

# Response with embedding
public type EmbeddingResponse record {|
    record {|
        record {|
            decimal[] values;
        |} values;
    |} embedding;
|};
