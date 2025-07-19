import ballerina/sql;

# This returns a parameterized SQL query to retrieve a user by their email address.
# + email - The email address of the user to be retrieved.
# + return - Returns a `sql:ParameterizedQuery` that can be executed to fetch the user details.
isolated function getUserByEmailQuery(string email) returns sql:ParameterizedQuery {
    return
    `
        SELECT 
            id, 
            username, 
            email, 
            role, 
            hashed_password,
            is_active,
            is_verified
        FROM 
            users 
        WHERE 
            email = ${email}
    `;
}

# This returns a parameterized SQL query to add a new user to the database.
# + user - The user details to be added.
# + return - Returns a `sql:ParameterizedQuery` that can be executed to insert the user.
isolated function addUserQuery(AddUser user) returns sql:ParameterizedQuery {
    return
    `
        INSERT INTO 
            users (id, username, email, hashed_password)
        VALUES 
            (${user.id}, ${user.username}, ${user.email}, ${user.hashedPassword})
    `;
}

# This returns a parameterized SQL query to update a user's status in the database.
# + userId - The ID of the user to update.
# + verified - The new status to set for the user.
# + return - Returns a `sql:ParameterizedQuery` that can be executed to update the user's status.
isolated function updateUserStatusQuery(string userId, boolean verified) returns sql:ParameterizedQuery {
    return
    `
        UPDATE 
            users 
        SET 
            is_verified = ${verified},
            is_active = ${verified}
        WHERE 
            id = ${userId}
    `;
}

# This return a parameterized SQL query to update a user record with optional fields.
# + updateUser - The user details to be updated.
# + return - Returns a `sql:ParameterizedQuery` that can be executed to update the user.
isolated function updateUserQuery(UpdateUser updateUser) returns sql:ParameterizedQuery {
    sql:ParameterizedQuery[] setParts = [];
    
    if updateUser.username is string {
        setParts.push(`username = ${updateUser.username}`);
    }
    
    if updateUser.email is string {
        setParts.push(`email = ${updateUser.email}`);
    }
    
    if updateUser.hashedPassword is string {
        setParts.push(`hashed_password = ${updateUser.hashedPassword}`);
    }
    
    if updateUser.isActive is boolean {
        setParts.push(`is_active = ${updateUser.isActive}`);
    }
    
    if updateUser.isVerified is boolean {
        setParts.push(`is_verified = ${updateUser.isVerified}`);
    }
    
    // Join the parts with commas
    sql:ParameterizedQuery query = `UPDATE users SET `;
    foreach int i in 0 ..< setParts.length() {
        if i > 0 {
            query = sql:queryConcat(query, `, `);
        }
        query = sql:queryConcat(query, setParts[i]);
    }
    query = sql:queryConcat(query, ` WHERE id = ${updateUser.id}`);
    
    return query;
}