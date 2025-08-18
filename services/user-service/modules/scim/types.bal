# SCIM 2.0 Configuration
type SCIMConfig record {|
    # Base URL for SCIM API
    string baseUrl;
    # Client ID for SCIM API
    string clientId;
    # Client Secret for SCIM API
    string clientSecret;
    # Token URL for SCIM API
    string tokenUrl;
|};
    
# SCIM User Response
public type SCIMUserResponse record {
    # Unique identifier of the user
    string id;
    # Unique username of the user
    string userName;
};

# SCIM Group Request
public type SCIMGroupRequest record {|
    # List of schemas used for the request
    string[] schemas;
    # Display name of the group
    string displayName;
    # Members of the group
    record {|
        # Member user ID
        string value;
        # Member display name
        string display;
    |}[] members?;
|};

# SCIM Group Response
public type SCIMGroupResponse record {|
    # List of schemas used for the response
    string[] schemas;
    # Unique identifier of the group
    string id;
    # Display name of the group
    string displayName;
    # Members of the group
    record {|
        # Member user ID
        string value;
        # Member display name
        string display;
    |}[] members?;
    # Metadata about the group resource
    record {|
        # Creation timestamp
        string created;
        # Last modified timestamp
        string lastModified;
        # Resource location (URL)
        string location;
        # Resource type (e.g., Group)
        string resourceType;
    |} meta;
|};

# SCIM Error Response
public type SCIMErrorResponse record {|
    # List of schemas used for the response
    string[] schemas;
    # Detailed error message
    string detail;
    # HTTP status code of the error
    int status;
|};

# Campus User Role
public enum CampusRole {
    # Represents a student role
    STUDENT = "student",
    # Represents a staff role
    STAFF = "staff", 
    # Represents an administrator role
    ADMIN = "admin"
}

# Campus User for Bulk Import
public type CampusUser record {|
    # First name of the user
    string firstName;
    # Last name of the user
    string lastName;
    # Primary email address of the user
    string email;
    # Role assigned to the user
    CampusRole role;
    # Department of the user
    string department;
    # Student ID (if applicable)
    string studentId?;
    # Employee ID (if applicable)
    string employeeId?;
    # Contact phone number of the user
    string phone?;
|};

# Bulk Import Request
public type BulkImportRequest record {|
    # List of users to be imported
    CampusUser[] users;
    # Whether to send a welcome email to imported users
    boolean sendWelcomeEmail?;
    # Whether to auto-generate passwords for users
    boolean autoGeneratePassword?;
|};

# Bulk Import Response
public type BulkImportResponse record {|
    # Total number of users attempted for import
    int totalUsers;
    # Number of users successfully created
    int successfullyCreated;
    # Number of users that failed creation
    int failed;
    # Details of users that failed to be created
    record {|
        # Email address of the failed user
        string email;
        # Reason for failure
        string reason;
    |}[] failures?;
|};

# User Creation Result
public type UserCreationResult record {|
    # Whether the user creation was successful
    boolean success;
    # Asgardeo system user ID (if available)
    string? asgardeoUserId;
    # Local system user ID (if available)
    string? localUserId;
    # Error message in case of failure
    string? errorMessage;
|};

# Configurable type for group IDs
public type CampusGroups record {|
    # SCIM group ID for student group
    string studentGroupId;
    # SCIM group ID for staff group
    string staffGroupId;
    # SCIM group ID for admin group
    string adminGroupId;
|};
