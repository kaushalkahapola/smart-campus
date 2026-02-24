import ballerina/http;
import user_service.scim;

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


# Bulk Import Request from CSV/Excel
public type BulkImportUsersRequest record {|
    # Array of users to import
    scim:CampusUser[] users;
|};

# User Profile Update Request (Self-service)
public type UpdateUserProfileRequest record {|
    # Phone number
    string? phone;
    # User preferences
    json? preferences;
    # Emergency contact
    string? emergencyContact;
|};

# Admin Update User Request
public type AdminUpdateUserRequest record {|
    # First name
    string? firstName;
    # Last name
    string? lastName;
    # Email address
    string? email;
    # User role
    scim:CampusRole? role;
    # Department
    string? department;
    # Student ID
    string? studentId;
    # Employee ID
    string? employeeId;
    # Phone number
    string? phone;
    # Active status
    boolean? isActive;
|};

# ========================================
# SUCCESS RESPONSE TYPES
# ========================================

# User Created Response
public type UserCreatedResponse record {|
    *http:Created;
    # payload 
    record {|
        string message;
        string userId;
        string asgardeoUserId;
        string timestamp;
    |} body;
|};

# Bulk Import Response
public type BulkImportResponse record {|
    *http:Ok;
    # payload 
    record {|
        string message;
        record {|
            int totalUsers;
            int successfullyCreated;
            int failed;
            record {|
                string email;
                string reason;
            |}[] failures;
        |} data;
        string timestamp;
    |} body;
|};

# User List Response
public type UserListResponse record {|
    *http:Ok;
    # payload 
    record {|
        string message;
        record {|
            json[] users;
            int total;
            int page;
            int pageSize;
        |} data;
        string timestamp;
    |} body;
|};

# User Profile Response
public type UserProfileResponse record {|
    *http:Ok;
    # payload 
    record {|
        string message;
        json data; // User profile object
        string timestamp;
    |} body;
|};

# User Updated Response
public type UserUpdatedResponse record {|
    *http:Ok;
    # payload 
    record {|
        string message;
        string userId;
        string timestamp;
    |} body;
|};

# User Deleted Response
public type UserDeletedResponse record {|
    *http:Ok;
    # payload 
    record {|
        string message;
        string userId;
        string timestamp;
    |} body;
|};

# User Info Response (for cached user data)
public type UserInfoResponse record {|
    *http:Ok;
    # payload 
    record {|
        string message;
        record {|
            string userId;
            string username;
            string email;
            string firstName;
            string lastName;
            string role;
            string department;
            string[] groups;
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
                boolean asgardeoConnected;
                boolean databaseConnected;
                int totalUsers;
            |} dependencies;
        |} data;
        string timestamp;
    |} body;
|};

# Success Response (Generic)
public type SuccessResponse record {|
    *http:Ok;
    # payload 
    record {|
        string message;
        json? data;
        string timestamp;
    |} body;
|};