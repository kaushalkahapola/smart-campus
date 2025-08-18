import ballerina/sql;
import ballerinax/mysql;
import ballerina/time;

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

# Role enumeration
public enum Role {
    # Represents an admin user with elevated privileges
    ADMIN = "admin",
    # Represents regular staff with standard privileges
    STAFF = "staff",
    # Represents a student user
    STUDENT = "student"
}

# User status enumeration
public enum UserStatus {
    # User is active
    ACTIVE = "active",
    # User is inactive
    INACTIVE = "inactive"
}

# User record type for database operations (matches campus_resource_db.users table)
public type User record {|
    # Unique identifier for the user
    string id;
    # Username of the user
    string username;
    # Email address of the user
    string email;
    # Role of the user
    Role role?;
    # User's department/faculty
    string department?;
    # Student ID (for students)
    @sql:Column {
        name: "student_id"
    }
    string studentId?;
    # Employee ID (for staff)
    @sql:Column {
        name: "employee_id"
    }
    string employeeId?;
    # User preferences as JSON
    json preferences = {};
    # Indicates if the user is verified
    @sql:Column {
        name: "is_verified"
    }
    boolean isVerified?;
    # Indicates if the user is active
    @sql:Column {
        name: "is_active"
    }
    boolean isActive?;
    # User creation timestamp
    @sql:Column {
        name: "created_at"
    }
    time:Utc createdAt?;
    # User last update timestamp
    @sql:Column {
        name: "updated_at"
    }
    time:Utc updatedAt?;
    # Last login timestamp
    @sql:Column {
        name: "last_login"
    }
    time:Utc lastLogin?;
|};

# AddUser record type for creating new users (matches database schema)
public type AddUser record {|
    # Unique identifier for the user
    string id;
    # Username of the user
    string username;
    # Email address of the user
    string email;
    # Role of the user
    Role role;
    # User's department/faculty
    string department?;
    # Student ID (for students)
    @sql:Column {
        name: "student_id"
    }
    string studentId?;
    # Employee ID (for staff)
    @sql:Column {
        name: "employee_id"
    }
    string employeeId?;
    # User preferences as JSON
    json preferences?;
    # Indicates if the user is verified
    @sql:Column {
        name: "is_verified"
    }
    boolean isVerified;
    # Indicates if the user is active
    @sql:Column {
        name: "is_active"
    }
    boolean isActive;
|};

# UpdateUser record type for updating user information (matches database schema)
public type UpdateUser record {|
    # Unique identifier for the user
    string id;
    # Username of the user
    string? username;
    # Email address of the user
    string? email;
    # Role of the user
    Role? role;
    # User's department/faculty
    string? department;
    # Student ID (for students)
    string? studentId;
    # User preferences as JSON
    json? preferences;
    # Indicates if the user is verified
    boolean? isVerified;
    # Indicates if the user is active
    boolean? isActive;
    # Last login timestamp
    time:Civil? lastLogin;
|};

# User filter for database queries
public type UserFilter record {|
    # Filter by department
    string? department;
    # Filter by role
    string? role;
    # Filter by active status
    boolean? isActive;
    # Filter by verified status
    boolean? isVerified;
    # Search term for username, email
    string? searchTerm;
|};
