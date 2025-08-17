import ballerina/sql;

# This module provides database operations for resource management in the Campus Resource Management application.

# This function retrieves all resources with optional filtering.
# + filter - Optional filter criteria for resources.
# + return - Returns an array of `Resource` records or an error.
public isolated function getAllResources(ResourceFilter? filter = ()) returns Resource[]|error {
    stream<Resource, sql:Error?> resourceStream = databaseClient->query(getAllResourcesQuery(filter));
    return from Resource resourceData in resourceStream
        select resourceData;
}

# This function retrieves a resource by its ID.
# + resourceId - The ID of the resource to be retrieved.
# + return - Returns a `Resource` record if found, or an error if not found.
public isolated function getResourceById(string resourceId) returns Resource|error {
    Resource? resourceData = check databaseClient->queryRow(getResourceByIdQuery(resourceId));
    if resourceData is Resource {
        return resourceData;
    } else {
        return error("Resource not found with ID: " + resourceId);
    }
}

# This function adds a new resource to the database.
# + resourceData - Resource object to add to the database.
# + return - Returns affected row count or an error.
public isolated function addResource(AddResource resourceData) returns int|error {
    sql:ExecutionResult|error result = databaseClient->execute(addResourceQuery(resourceData));
    if result is error {
        return result;
    }
    return <int>result.affectedRowCount;
}

# This function updates an existing resource in the database.
# + updateResourceData - The resource object with updated fields.
# + return - Returns the number of affected rows or an error if the update fails.
public isolated function updateResource(UpdateResource updateResourceData) returns int|error {
    sql:ExecutionResult|error result = databaseClient->execute(updateResourceQuery(updateResourceData));
    if result is error {
        return result;
    }
    return <int>result.affectedRowCount;
}

# This function deletes a resource from the database.
# + resourceId - The ID of the resource to be deleted.
# + return - Returns the number of affected rows or an error if the deletion fails.
public isolated function deleteResource(string resourceId) returns int|error {
    sql:ExecutionResult|error result = databaseClient->execute(deleteResourceQuery(resourceId));
    if result is error {
        return result;
    }
    return <int>result.affectedRowCount;
}

# This function updates the status of a resource.
# + resourceId - The ID of the resource to update.
# + status - The new status to set for the resource.
# + return - Returns the number of affected rows or an error if the update fails.
public isolated function updateResourceStatus(string resourceId, ResourceStatus status) returns int|error {
    sql:ExecutionResult|error result = databaseClient->execute(updateResourceStatusQuery(resourceId, status));
    if result is error {
        return result;
    }
    return <int>result.affectedRowCount;
}
