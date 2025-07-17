import ballerina/sql;

# This module provides database operations for user management in the Finmate application.
#
# + email - The email address of the user to be retrieved.
# + return - Returns a `User` record if found, or an error if not found.
public isolated function getUserByEmail(string email) returns User|error {
    User? user = check databaseClient->queryRow(getUserByEmailQuery(email));
    if user is User {
        return user;
    } else {
        return error("User not found with email: " + email);
    }
}

# This function adds a new user to the database.
#
# + user - User object to add to the database.
# + return - return affected row count.
public isolated function addUser(AddUser user) returns int|error {
    sql:ExecutionResult|error result = databaseClient->execute(addUserQuery(user));
    if result is error {
        return result;
    }
    return <int>result.affectedRowCount;
}
