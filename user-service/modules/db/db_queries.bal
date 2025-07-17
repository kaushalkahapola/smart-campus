import ballerina/sql;

# This function returns a parameterized SQL query to retrieve a user by their email address.
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
            is_active 
        FROM 
            users 
        WHERE 
            email = ${email}
    `;
}

isolated function addUserQuery(AddUser user) returns sql:ParameterizedQuery {
    return
    `
        INSERT INTO 
            users (id, username, email, hashed_password, role, is_active)
        VALUES 
            (${user.id}, ${user.username}, ${user.email}, ${user.hashedPassword}, ${user.role}, ${user.isActive})
    `;
}
