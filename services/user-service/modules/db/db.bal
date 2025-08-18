import ballerina/sql;

# This module provides database operations for user management in the Finmate application.

# Get user by email address
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

# Get user by ID
# 
# + userId - The ID of the user to be retrieved.
# + return - Returns a `User` record if found, or an error if not found.
public isolated function getUserById(string userId) returns User|error {
    User? user = check databaseClient->queryRow(getUserByIdQuery(userId));
    if user is User {
        return user;
    } else {
        return error("User not found with ID: " + userId);
    }
}

# Get all users with optional filtering and pagination
# 
# + filter - Optional filter criteria for user query
# + page - Page number (1-based)
# + pageSize - Number of users per page
# + return - Returns array of User records or error
public isolated function getAllUsers(UserFilter? filter, int page, int pageSize) returns User[]|error {
    stream<User, sql:Error?> userStream = databaseClient->query(getAllUsersQuery(filter, page, pageSize));
    return from User user in userStream select user;
}

# Get total count of users with optional filtering
# 
# + filter - Optional filter criteria for user count
# + return - Returns total count of users or error
public isolated function getUserCount(UserFilter? filter) returns int|error {
    record {int count;} countResult = check databaseClient->queryRow(getUserCountQuery(filter));
    return countResult.count;
}

# Add a new user to the database
# + user - User object to add to the database.
# + return - return affected row count.
public isolated function addUser(AddUser user) returns int|error {
    sql:ExecutionResult|error result = databaseClient->execute(addUserQuery(user));
    if result is error {
        return result;
    }
    return <int>result.affectedRowCount;
}

# Update user information in the database
# + user - The user object with updated fields.
# + return - Returns the number of affected rows or an error if the update fails.
public isolated function updateUser(UpdateUser user) returns int|error {
    sql:ExecutionResult|error result = databaseClient->execute(updateUserQuery(user));
    if result is error {
        return result;
    }
    return <int>result.affectedRowCount;
}

# Update user status in the database
# + userId - The ID of the user to update
# + status - The new status for the user
# + return - Returns the number of affected rows or an error if the update fails.
public isolated function updateUserStatus(string userId, UserStatus status) returns int|error {
    sql:ExecutionResult|error result = databaseClient->execute(updateUserStatusQuery(userId, status));
    if result is error {
        return result;
    }
    return <int>result.affectedRowCount;
}
