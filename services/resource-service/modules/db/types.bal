import ballerina/sql;
import ballerinax/mysql;

# Database configuration
type DBConfig record {|
    # Database user configuration
    string user;
    # Database user password
    string password;
    # Database host address
    string host;
    # Database port number
    int port;
    # Database name
    string database;
|};

# ClientDBConfig record type
type ClientDBConfig record {|
    *DBConfig;
    # Optional MySQL connection options
    mysql:Options? options;
|};

# Resource type enumeration
public enum ResourceType {
    # Lecture hall for large classes
    LECTURE_HALL = "lecture_hall",
    # Computer lab with programming facilities
    COMPUTER_LAB = "computer_lab",
    # Meeting room for discussions
    MEETING_ROOM = "meeting_room",
    # Study room for group work
    STUDY_ROOM = "study_room",
    # Equipment like projectors, laptops
    EQUIPMENT = "equipment",
    # Vehicles for campus transport
    VEHICLE = "vehicle"
}

# Resource status enumeration
public enum ResourceStatus {
    # Resource is available for booking
    AVAILABLE = "available",
    # Resource is under maintenance
    MAINTENANCE = "maintenance",
    # Resource is temporarily unavailable
    UNAVAILABLE = "unavailable",
    # Resource is reserved/booked
    RESERVED = "reserved"
}

# Resource record type
public type Resource record {|
    # Unique identifier for the resource
    string id;
    # Name of the resource
    string name;
    # Type of the resource
    ResourceType 'type;
    # Maximum capacity of the resource
    int capacity;
    # Features available in JSON format
    string? features;
    # Location description
    string location;
    # Building name
    string building;
    # Floor number
    string? floor;
    # Room number
    @sql:Column {
        name: "room_number"
    }
    string? roomNumber;
    # Current status of the resource
    ResourceStatus status;
    # Hourly rate for booking
    @sql:Column {
        name: "hourly_rate"
    }
    decimal hourlyRate;
    # Description of the resource
    string? description;
    # Image URL
    @sql:Column {
        name: "image_url"
    }
    string? imageUrl;
    # Contact person for the resource
    @sql:Column {
        name: "contact_person"
    }
    string? contactPerson;
    # Resource created timestamp
    @sql:Column {
        name: "created_at"
    }
    string createdAt;
    # Resource updated timestamp
    @sql:Column {
        name: "updated_at"
    }
    string updatedAt;
    # Created by user ID
    @sql:Column {
        name: "created_by"
    }
    string? createdBy;
|};

# AddResource record type for creating new resources
public type AddResource record {|
    # Resource ID
    string id;
	# Resource name
    string name;
	# Resource type
    @sql:Column {
        name: "type"
    }
    ResourceType 'type; 
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

# UpdateResource record type for updating existing resources
public type UpdateResource record {|
    # Unique identifier for the resource
    string id;
    # Name of the resource
    string name?;
    # Type of the resource
    ResourceType 'type?;
    # Maximum capacity of the resource
    int capacity?;
    # Features available in JSON format
    json features?;
    # Location description
    string location?;
    # Building name
    string building?;
    # Floor number
    string floor?;
    # Room number
    string roomNumber?;
    # Current status of the resource
    ResourceStatus status?;
    # Hourly rate for booking
    decimal hourlyRate?;
    # Description of the resource
    string description?;
    # Image URL
    string imageUrl?;
    # Contact person for the resource
    string contactPerson?;
|};

# Resource search filter
public type ResourceFilter record {|
    # Filter by resource type
    ResourceType? 'type;
    # Filter by building
    string? building;
    # Filter by minimum capacity
    int? minCapacity;
    # Filter by maximum capacity
    int? maxCapacity;
    # Filter by status
    ResourceStatus? status;
    # Search text for name or description
    string? searchText;
|};
