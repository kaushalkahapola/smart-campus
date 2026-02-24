import ballerina/http;
import ballerina/sql;
import resource_service.db;

# HTTP Response Types with structured bodies

# NotFound Response record type
public type NotFoundResponse record {|
    *http:NotFound;
    # payload 
    record {|
        string errorMessage;
        string? details;
    |} body;
|};

# BadRequest Response record type
public type BadRequestResponse record {|
    *http:BadRequest;
    # payload 
    record {|
        string errorMessage;
        string? details;
    |} body;
|};

# InternalServerError Response record type
public type InternalServerErrorResponse record {|
    *http:InternalServerError;
    # payload 
    record {|
        string errorMessage;
        string? details;
    |} body;
|};

# Conflict Response record type
public type ConflictResponse record {|
    *http:Conflict;
    # payload 
    record {|
        string errorMessage;
        string? details;
    |} body;
|};

# Unauthorized Response record type
public type UnauthorizedResponse record {|
    *http:Unauthorized;
    # payload 
    record {|
        string errorMessage;
    |} body;
|};

# Forbidden Response record type
public type ForbiddenResponse record {|
    *http:Forbidden;
    # payload 
    record {|
        string errorMessage;
        string? details;
    |} body;
|};

# Success Response Types

# ResourceList Success Response
public type ResourceListResponse record {|
    *http:Ok;
    # payload 
    record {|
        string message;
        record {|
            json[] resources;
            int total;
        |} data;
        string timestamp;
    |} body;
|};

# Single Resource Success Response
public type ResourceResponse record {|
    *http:Ok;
    # payload 
    record {|
        string message;
        json data; // Resource object
        string timestamp;
    |} body;
|};

# Resource Created Response
public type ResourceCreatedResponse record {|
    *http:Created;
    # payload 
    record {|
        string message;
        string resourceId;
        string timestamp;
    |} body;
|};

# Resource Updated Response
public type ResourceUpdatedResponse record {|
    *http:Ok;
    # payload 
    record {|
        string message;
        string resourceId;
        string timestamp;
    |} body;
|};

# Resource Deleted Response
public type ResourceDeletedResponse record {|
    *http:Ok;
    # payload 
    record {|
        string message;
        string resourceId;
        string timestamp;
    |} body;
|};

# Resource Status Updated Response
public type ResourceStatusUpdatedResponse record {|
    *http:Ok;
    # payload 
    record {|
        string message;
        string resourceId;
        string status;
        string timestamp;
    |} body;
|};

# Resource Availability Response
public type ResourceAvailabilityResponse record {|
    *http:Ok;
    # payload 
    record {|
        string message;
        record {|
            string resourceId;
            string startTime;
            string endTime;
            boolean isAvailable;
            string availabilityMessage;
        |} data;
        string timestamp;
    |} body;
|};

# Health Check Response
public type HealthResponse record {|
    *http:Ok;
    # payload 
    record {|
        string message;
        record {|
            string status;
            string 'service;
            string 'version;
            int uptime_seconds;
            record {|
                boolean connected;
                string status;
                int? total_resources;
            |} database;
        |} data;
        string timestamp;
    |} body;
|};

# Request Types for Resource Operations

# Create Resource Request
public type CreateResourceRequest record {|
	# Resource name
    string name;
	# Resource type
    @sql:Column {
        name: "type"
    }
    db:ResourceType 'type;
    # Resource capacity
	int capacity?;
	# Resource features
    json features?;
	# Resource location
    string location;
	# Resource building
    string building;
    # Resource floor
    string floor?;
    # Resource room number
    @sql:Column {
        name: "room_number"
    }
    string roomNumber?;
    # Resource hourly rate
    @sql:Column {
        name: "hourly_rate"
    }
    decimal hourlyRate?;
    # Resource description
    string description?;
    # Resource image URL
    @sql:Column {
        name: "image_url"
    }
    string imageUrl?;
    # Resource contact person
    @sql:Column {
        name: "contact_person"
    }
    string contactPerson?;
|};

# Update Resource Request
public type UpdateResourceRequest record {|
	# Resource name
    string name?;
	# Resource type
    @sql:Column {
        name: "type"
    }
    db:ResourceType 'type?;
	# Resource capacity
    int capacity?;
	# Resource features
    json features?;
	# Resource location
    string location?;
	# Resource building
    string building?;
    # Resource floor
    string floor?;
    # Resource room number
    @sql:Column {
        name: "room_number"
    }
    string roomNumber?;
    # Resource status
    db:ResourceStatus status?;
    # Resource hourly rate
    @sql:Column {
        name: "hourly_rate"
    }
	decimal hourlyRate?;
	# Resource description
    string description?;
    # Resource image URL
    @sql:Column {
        name: "image_url"
    }
    string imageUrl?;
    # Resource contact person
    @sql:Column {
        name: "contact_person"
    }
    string contactPerson?;
|};

# Update Resource Status Request
public type UpdateResourceStatusRequest record {|
    # Resource status
    db:ResourceStatus status;
|};

# Simple Success Response
public type SuccessResponse record {|
    *http:Ok;
    # payload
    record {|
        string resourceId;
        string startTime;
        string endTime;
        boolean isAvailable;
        string message;
    |} body;
|};