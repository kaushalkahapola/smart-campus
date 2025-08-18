import ballerina/sql;
import ballerina/time;

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
            department,
            student_id,
            employee_id,
            preferences,
            is_verified,
            is_active,
            created_at,
            updated_at,
            last_login
        FROM 
            users 
        WHERE 
            email = ${email}
    `;
}

# This returns a parameterized SQL query to retrieve a user by their ID.
# + userId - The ID of the user to be retrieved.
# + return - Returns a `sql:ParameterizedQuery` that can be executed to fetch the user details.
isolated function getUserByIdQuery(string userId) returns sql:ParameterizedQuery {
    return
    `
        SELECT 
            id, 
            username, 
            email, 
            role, 
            department,
            student_id,
            preferences,
            is_verified,
            is_active,
            created_at,
            updated_at,
            last_login
        FROM 
            users 
        WHERE 
            id = ${userId}
    `;
}

# This returns a parameterized SQL query to get all users with filtering and pagination.
# + filter - Optional filter criteria
# + page - Page number (1-based)
# + pageSize - Number of users per page
# + return - Returns a `sql:ParameterizedQuery` that can be executed to fetch users.
isolated function getAllUsersQuery(UserFilter? filter, int page, int pageSize) returns sql:ParameterizedQuery {
    sql:ParameterizedQuery baseQuery = `
        SELECT 
            id, 
            username, 
            email, 
            role, 
            department,
            student_id,
            employee_id,
            preferences,
            is_verified,
            is_active,
            created_at,
            updated_at,
            last_login
        FROM 
            users
    `;
    
    sql:ParameterizedQuery whereClause = ``;
    if filter is UserFilter {
        sql:ParameterizedQuery[] conditions = [];
        
        if filter.department is string {
            conditions.push(`department = ${filter.department}`);
        }
        
        if filter.role is string {
            conditions.push(`role = ${filter.role}`);
        }
        
        if filter.isActive is boolean {
            conditions.push(`is_active = ${filter.isActive}`);
        }
        
        if filter.isVerified is boolean {
            conditions.push(`is_verified = ${filter.isVerified}`);
        }
        
        if filter?.searchTerm is string {
            string searchTerm = <string>filter.searchTerm;
            string searchPattern = "%" + searchTerm + "%";
            conditions.push(`(username LIKE ${searchPattern} OR email LIKE ${searchPattern})`);
        }
        
        if conditions.length() > 0 {
            whereClause = ` WHERE `;
            foreach int i in 0 ..< conditions.length() {
                if i > 0 {
                    whereClause = sql:queryConcat(whereClause, ` AND `);
                }
                whereClause = sql:queryConcat(whereClause, conditions[i]);
            }
        }
    }
    
    int offset = (page - 1) * pageSize;
    sql:ParameterizedQuery paginationClause = ` ORDER BY created_at DESC LIMIT ${pageSize} OFFSET ${offset}`;
    
    return sql:queryConcat(baseQuery, whereClause, paginationClause);
}

# This returns a parameterized SQL query to count users with filtering.
# + filter - Optional filter criteria
# + return - Returns a `sql:ParameterizedQuery` that can be executed to count users.
isolated function getUserCountQuery(UserFilter? filter) returns sql:ParameterizedQuery {
    sql:ParameterizedQuery baseQuery = `SELECT COUNT(*) as count FROM users`;
    
    sql:ParameterizedQuery whereClause = ``;
    if filter is UserFilter {
        sql:ParameterizedQuery[] conditions = [];
        
        if filter.department is string {
            conditions.push(`department = ${filter.department}`);
        }
        
        if filter.role is string {
            conditions.push(`role = ${filter.role}`);
        }
        
        if filter.isActive is boolean {
            conditions.push(`is_active = ${filter.isActive}`);
        }
        
        if filter.isVerified is boolean {
            conditions.push(`is_verified = ${filter.isVerified}`);
        }
        
        if filter.searchTerm is string {
            string searchPattern = "%" + <string>filter.searchTerm + "%";
            conditions.push(`(username LIKE ${searchPattern} OR email LIKE ${searchPattern})`);
        }
        
        if conditions.length() > 0 {
            whereClause = ` WHERE `;
            foreach int i in 0 ..< conditions.length() {
                if i > 0 {
                    whereClause = sql:queryConcat(whereClause, ` AND `);
                }
                whereClause = sql:queryConcat(whereClause, conditions[i]);
            }
        }
    }
    
    return sql:queryConcat(baseQuery, whereClause);
}

# This returns a parameterized SQL query to add a new user to the database.
# + user - The user details to be added.
# + return - Returns a `sql:ParameterizedQuery` that can be executed to insert the user.
isolated function addUserQuery(AddUser user) returns sql:ParameterizedQuery {
    return
    `
        INSERT INTO 
            users (
                id, 
                username, 
                email, 
                role, 
                department,
                student_id,
                employee_id,
                preferences,
                is_verified,
                is_active
            )
        VALUES 
            (
                ${user.id}, 
                ${user.username}, 
                ${user.email}, 
                ${user.role}, 
                ${user.department},
                ${user.studentId},
                ${user.employeeId},
                ${user?.preferences.toString()},
                ${user.isVerified},
                ${user.isActive}
            )
    `;
}

# This returns a parameterized SQL query to update a user's status in the database.
# + userId - The ID of the user to update.
# + status - The new status to set for the user.
# + return - Returns a `sql:ParameterizedQuery` that can be executed to update the user's status.
isolated function updateUserStatusQuery(string userId, UserStatus status) returns sql:ParameterizedQuery {
    boolean isActive = status == ACTIVE;
    return
    `
        UPDATE 
            users 
        SET 
            is_active = ${isActive},
            updated_at = CURRENT_TIMESTAMP
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
    
    if updateUser.role is Role {
        setParts.push(`role = ${updateUser.role}`);
    }
    
    if updateUser.department is string {
        setParts.push(`department = ${updateUser.department}`);
    }
    
    if updateUser.studentId is string {
        setParts.push(`student_id = ${updateUser.studentId}`);
    }
    
    if updateUser.preferences is json {
        string preferencesString = updateUser.preferences.toString();
        setParts.push(`preferences = ${preferencesString}`);
    }
    
    if updateUser.isActive is boolean {
        setParts.push(`is_active = ${updateUser.isActive}`);
    }
    
    if updateUser.isVerified is boolean {
        setParts.push(`is_verified = ${updateUser.isVerified}`);
    }
    
    if updateUser.lastLogin is time:Civil {
        setParts.push(`last_login = ${updateUser.lastLogin}`);
    }
    
    // Always update the timestamp
    setParts.push(`updated_at = CURRENT_TIMESTAMP`);
    
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