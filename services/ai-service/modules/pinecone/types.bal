
# Represents a vector with its metadata
public type Vector record {|
    string id;
    decimal[] values;
    map<string> metadata?;
|};

# Request to upsert vectors
public type UpsertRequest record {|
    Vector[] vectors;
    string namespace?;
|};

# Request to query vectors
public type QueryRequest record {|
    string namespace?;
    int topK;
    decimal[] vector?;
    string id?;
    boolean includeValues?;
    boolean includeMetadata?;
    map<json> filter?;
|};

# Match found in query
public type ScoredVector record {|
    string id;
    decimal score;
    decimal[] values?;
    map<string> metadata?;
|};

# Response from query
public type QueryResponse record {|
    ScoredVector[] matches;
    string namespace?;
|};

# Response from upsert
public type UpsertResponse record {|
    int upsertedCount;
|};
