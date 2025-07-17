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

# Role enumeration
public enum Role {
    # Represents an admin user with elevated privileges
    ADMIN = "admin",
    # Represents a regular user with standard privileges
    USER = "user"
}

# User record type
public type User record {|
    # Unique identifier for the user
    string id;
    # Username of the user
    string username;
    # Hashed password of the user
    @sql:Column {
        name: "hashed_password"
    }
    string hashedPassword;
    # Email address of the user
    string email;
    # Role of the user (e.g., admin, user)
    Role role;
    # Indicates if the user is active
    @sql:Column {
        name: "is_active"
    }
    boolean isActive;
    # Indicates if the user is verified
    @sql:Column {
        name: "is_verified"
    }
    boolean isVerified;
|};

# AddUser record type
public type AddUser record {|
    # Unique identifier for the user
    string id;
    # Username of the user
    string username;
    # Email address of the user
    string email;
    # Hashed password of the user 
    @sql:Column {
        name: "hashed_password"
    }
    string hashedPassword;
|};
