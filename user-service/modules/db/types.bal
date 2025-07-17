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
    # SQL connection pool for database operations
    sql:ConnectionPool connectionPool;
|};

# ClientDBConfig record type
type ClientDBConfig record {|
    *DBConfig;
    # Optional MySQL connection options
    mysql:Options? options;
|};

# Role enumeration
enum Role {
    # Represents an admin user with elevated privileges
    ADMIN = "admin",
    # Represents a regular user with standard privileges
    USER = "user"
}

# User record type
type User record {|
    # Unique identifier for the user
    int id;
    # Username of the user
    string username;
    # Email address of the user
    string email;
    # Role of the user (e.g., admin, user)
    Role role;
    # Indicates if the user is active
    @sql:Column {
        name: "is_active"
    }
    boolean isActive;
|};

# CreateUser record type
type CreateUser record {|
    # Username of the user to be added
    string username;
    # Email address of the user to be added
    string email;
    # Hashed password of the user to be added
    string password;
    # Confirmation of the password for validation
    string confirmPassword;
    # Role of the user to be added (e.g., admin, user)
    Role role;
|};
