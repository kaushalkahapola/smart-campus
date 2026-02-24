import ballerinax/java.jdbc;
import ballerinax/mysql;
import ballerinax/mysql.driver as _;

// External configuration for DB connection
configurable DBConfig dbConfig = ?;

// Create the database client configuration with additional options
ClientDBConfig preparedDbConfig = {
    ...dbConfig,
    options: {
        ssl: {
            mode: mysql:SSL_REQUIRED
        },
        connectTimeout: 30
    }
};

// Returns a MySQL client if the configuration is valid
function createDbClient() returns mysql:Client|error {
    return new mysql:Client(...preparedDbConfig);
};

// Define the JDBC client instance to interact with the database
final jdbc:Client databaseClient = check createDbClient();
