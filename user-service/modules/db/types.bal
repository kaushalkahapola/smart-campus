import ballerina/sql;

# Database configuration
# + user - Database user name
# + password - Database user password
# + host - Database host address
# + port - Database port number
# + database - Database name
# + connectionPool - SQL connection pool for database operations
type DBConfig record {|
    string user;
    string password;
    string host;
    int port;
    string database;
    sql:ConnectionPool connectionPool;
|};

