import user_service.scim;
import user_service.db;

import ballerina/uuid;
import ballerina/log;

# Validate user data before creation
#
# + user - The user data to validate
# + return - error? - Returns an error if validation fails
function validateUserData(scim:CampusUser user) returns error? {
    
    // Validate email format
    if !user.email.includes("@") {
        return error("Invalid email format");
    }
    
    // Validate university email domain
    // if !user.email.endsWith("@university.edu") {
    //     return error("Email must be a university email address");
    // }
    
    // Validate required fields
    if user.firstName.trim().length() == 0 {
        return error("First name is required");
    }
    
    if user.lastName.trim().length() == 0 {
        return error("Last name is required");
    }
    
    if user.department.trim().length() == 0 {
        return error("Department is required");
    }
    
    // Role-specific validations
    if user.role == scim:STUDENT && user.studentId is () {
        return error("Student ID is required for students");
    }
    
    if (user.role == scim:STAFF || user.role == scim:ADMIN) && user.employeeId is () {
        return error("Employee ID is required for staff and admin users");
    }
    
    return ();
}

# Create campus user in both Asgardeo and local database
#
# + user - The user data to create
# + return - The result of the user creation
function createCampusUser(scim:CampusUser user) returns scim:UserCreationResult {
    // Create user in Asgardeo first
    string asgardeoUserId = checkUserExistsInAsgardeo(user.email);

    if asgardeoUserId != "" {
        log:printWarn("User already exists in Asgardeo: " + user.email);
    }
    else {
        scim:SCIMUserResponse|error asgardeoResult = scim:createUserInAsgardeo(user);
        if asgardeoResult is error {
            log:printError("Failed to create user in Asgardeo: " + asgardeoResult.message());
            return {
                success: false,
            asgardeoUserId: null,
            localUserId: null,
            errorMessage: "Failed to create user in Asgardeo: " + asgardeoResult.message()
            };
        }
        asgardeoUserId = asgardeoResult.id;
    }

    // Create user in local database
    boolean userExistsInDB = checkUserExistsDB(user.email);
    string localUserId = uuid:createType1AsString();

    if userExistsInDB {
        log:printWarn("User already exists in database: " + user.email);
    }
    else {
        // Create user in local database
        db:AddUser dbUser = {
        id: localUserId,
        username: user.email,
        email: user.email,
        role: user.role,
        department: user.department,
        studentId: user.studentId,
        employeeId: user.employeeId,
        preferences: {}, // Default empty preferences
        isVerified: true, // University users are pre-verified
        isActive: true
        };
    
        int|error dbResult = db:addUser(dbUser);
        if dbResult is error {
            log:printError("Failed to create user in database: " + dbResult.message());
            
            // Rollback: Delete user from Asgardeo
            error? deleteResult = scim:deleteUserFromAsgardeo(asgardeoUserId);
            if deleteResult is error {
                log:printError("Failed to rollback user creation in Asgardeo: " + deleteResult.message());
            }
            
            return {
                success: false,
                asgardeoUserId: null,
                localUserId: null,
                errorMessage: "Failed to create user in database: " + dbResult.message()
            };
        }
    }
    
    log:printInfo("Successfully created user: " + user.email);
    return {
        success: true,
        asgardeoUserId: asgardeoUserId,
        localUserId: localUserId,
        errorMessage: null
    };
}

# Check if user already exists in database
#
# + email - The email of the user to check
# + return - Returns true if user exists, false otherwise
function checkUserExistsDB(string email) returns boolean {

    // TODO: Check in database if user with email exists
    // For now, return false
    return false;
}

# Check if user already exists in asgardeo
#
# + email - The email of the user to check
# + return - Returns the user id if exists, empty string otherwise
function checkUserExistsInAsgardeo(string email) returns string {

    // TODO: Check in database if user with email exists
    // For now, return false
    return "";
}