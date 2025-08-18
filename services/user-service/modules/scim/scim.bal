import ballerina/http;
import ballerina/log;

# External configuration for SCIM connection
configurable SCIMConfig scimConfig = ?;

# Group IDs for campus roles (to be configured in Config.toml)
configurable CampusGroups campusGroups = ?;

# Create SCIM client with OAuth2 authentication
# 
# + return - http:Client|error
isolated function createSCIMClient() returns http:Client|error {
    return new http:Client(scimConfig.baseUrl, {
        auth: {
            clientId: scimConfig.clientId,
            clientSecret: scimConfig.clientSecret,
            tokenUrl: scimConfig.tokenUrl,
            scopes: "internal_user_mgt_create internal_user_mgt_list internal_user_mgt_view internal_user_mgt_delete internal_user_mgt_update internal_group_mgt_delete internal_group_mgt_create internal_group_mgt_update internal_group_mgt_view"
        },
        httpVersion: "1.1"
    });
}

# Create a user in Asgardeo via SCIM
#
# + user - The user to create
# + return - SCIMUserResponse|error
public isolated function createUserInAsgardeo(CampusUser user) returns SCIMUserResponse|error {
    http:Client scimClient = check createSCIMClient();
    
    // Determine group based on role
    string groupId = getGroupIdForRole(user.role);
    
    json userRequest = {
        "schemas": [],
        "userName": "DEFAULT/" + user.email,
        "name": {
            "givenName": user.firstName,
            "familyName": user.lastName
        },
        "emails": [
            {
                "value": user.email,
                "primary": true
            }
        ],
        "urn:scim:wso2:schema": {"askPassword": true},
        "urn:ietf:params:scim:schemas:extension:enterprise:2.0:User": {"manager": {"value": ""}}
    };
    
    
    SCIMUserResponse|error response = scimClient->post("/Users", userRequest.toJson());
    if response is error {
        log:printError("Error creating user in Asgardeo: " + response.message());
        return response;
    }

    // adding user to group
    error? addToGroupResult = addUserToGroup(response.id, groupId, user.email);
    if addToGroupResult is error {
        log:printError("Error adding user to group in Asgardeo: " + addToGroupResult.message());
        // delete user from asgardeo
        error? deleteResult = deleteUserFromAsgardeo(response.id);
        if deleteResult is error {
            log:printError("Failed to rollback user creation in Asgardeo: " + deleteResult.message());
        }
        return addToGroupResult;
    }

    log:printInfo("Successfully created user in Asgardeo: " + response.id);
    return response;
}

# Delete user from Asgardeo
#
# + userId - The ID of the user to delete
# + return - error?
public isolated function deleteUserFromAsgardeo(string userId) returns error? {
    http:Client scimClient = check createSCIMClient();
    
    log:printInfo("Deleting user from Asgardeo: " + userId);
    
    http:Response|error response = scimClient->delete("/Users/" + userId);
    if response is error {
        log:printError("Error deleting user from Asgardeo: " + response.message());
        return response;
    }
    
    if response.statusCode != 204 {
        return error("Failed to delete user from Asgardeo. Status: " + response.statusCode.toString());
    }
    
    log:printInfo("Successfully deleted user from Asgardeo: " + userId);
}

# Get user from Asgardeo by ID
#
# + userId - The ID of the user to retrieve
# + return - SCIMUserResponse|error
public isolated function getUserFromAsgardeo(string userId) returns SCIMUserResponse|error {
    http:Client scimClient = check createSCIMClient();
    
    log:printInfo("Fetching user from Asgardeo: " + userId);
    
    SCIMUserResponse|error response = scimClient->get("/Users/" + userId);
    if response is error {
        log:printError("Error fetching user from Asgardeo: " + response.message());
        return response;
    }
    
    return response;
}

# Search users in Asgardeo
#
# + filter - The search filter
# + startIndex - The index of the first result to return
# + count - The maximum number of results to return
# + return - json|error
public isolated function searchUsersInAsgardeo(string? filter = (), int? startIndex = (), int? count = ()) returns json|error {
    http:Client scimClient = check createSCIMClient();
    
    string query = "/Users";
    string[] params = [];
    
    if filter is string {
        params.push("filter=" + filter);
    }
    if startIndex is int {
        params.push("startIndex=" + startIndex.toString());
    }
    if count is int {
        params.push("count=" + count.toString());
    }
    
    if params.length() > 0 {
        query += "?" + string:'join("&", ...params);
    }
    
    log:printInfo("Searching users in Asgardeo with query: " + query);
    
    json|error response = scimClient->get(query);
    if response is error {
        log:printError("Error searching users in Asgardeo: " + response.message());
        return response;
    }
    
    return response;
}

# Get group ID for campus role
#
# + role - The campus role
# + return - The group ID for the specified role
isolated function getGroupIdForRole(CampusRole role) returns string {
    match role {
        STUDENT => {
            return campusGroups.studentGroupId;
        }
        STAFF => {
            return campusGroups.staffGroupId;
        }
        ADMIN => {
            return campusGroups.adminGroupId;
        }
    }
    return "";
}
public isolated function addUserToGroup(string userId, string groupId, string display) returns error? {
    http:Client scimClient = check createSCIMClient();
    
    // PATCH operation to add user to group
    json patchRequest = {
        "schemas": ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
        "Operations": [
            {
                "op": "add",
                "value": {
                    "members": [
                        {
                            "value": userId,
                            "display": "DEFAULT/" + display
                        }
                    ]
                }
            }
        ]
    };
    
    log:printInfo("Adding user " + userId + " to group " + groupId);
    log:printInfo("PATCH request body: " + patchRequest.toJsonString());
    
    http:Response|error response = scimClient->patch("/Groups/" + groupId, patchRequest);
    if response is error {
        log:printError("Error adding user to group: " + response.message());
        return response;
    }
    
    // Log the response details for debugging
    log:printInfo("Response status: " + response.statusCode.toString());
    
    if response.statusCode != 200 {
        // Get the response body to see the actual error
        string|error responseBody = response.getTextPayload();
        if responseBody is string {
            log:printError("Error response body: " + responseBody);
        }
        return error("Failed to add user to group. Status: " + response.statusCode.toString());
    }
    
    log:printInfo("Successfully added user to group");
}

# Remove user from group in Asgardeo
#
# + userId - The ID of the user to remove
# + groupId - The ID of the group to remove the user from
# + display - The display name of the user
# + return - error?
public isolated function removeUserFromGroup(string userId, string groupId, string display) returns error? {
    http:Client scimClient = check createSCIMClient();
    
    // PATCH operation to remove user from group
    json patchRequest = {
        "schemas": ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
        "Operations": [
            {
                "op": "remove",
                "value": {
                    "members": [
                        {
                            "value": userId,
                            "display": "DEFAULT/" + display
                        }
                    ]
                }
            }
        ]
    };
    
    log:printInfo("Removing user " + userId + " from group " + groupId);
    
    http:Response|error response = scimClient->patch("/Groups/" + groupId, patchRequest);
    if response is error {
        log:printError("Error removing user from group: " + response.message());
        return response;
    }
    
    if response.statusCode != 200 {
        return error("Failed to remove user from group. Status: " + response.statusCode.toString());
    }
    
    log:printInfo("Successfully removed user from group");
}
