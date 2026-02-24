import ballerina/sql;

# This returns a parameterized SQL query to retrieve all resources with optional filtering.
# + filter - The filter criteria for resources (optional)
# + return - Returns a `sql:ParameterizedQuery` that can be executed to fetch resources.
isolated function getAllResourcesQuery(ResourceFilter? filter) returns sql:ParameterizedQuery {
    sql:ParameterizedQuery baseQuery = `
        SELECT 
            id, name, type, capacity, features, location, building, 
            floor, room_number, status, hourly_rate, description, 
            image_url, contact_person, created_at, updated_at, created_by
        FROM 
            resources 
        WHERE 1=1
    `;
    
    if filter is ResourceFilter {
        if filter.'type is ResourceType {
            baseQuery = sql:queryConcat(baseQuery, ` AND type = ${filter.'type}`);
        }
        if filter.building is string {
            baseQuery = sql:queryConcat(baseQuery, ` AND building = ${filter.building}`);
        }
        if filter.minCapacity is int {
            baseQuery = sql:queryConcat(baseQuery, ` AND capacity >= ${filter.minCapacity}`);
        }
        if filter.maxCapacity is int {
            baseQuery = sql:queryConcat(baseQuery, ` AND capacity <= ${filter.maxCapacity}`);
        }
        if filter.status is ResourceStatus {
            baseQuery = sql:queryConcat(baseQuery, ` AND status = ${filter.status}`);
        }
        if filter.searchText is string {
            string searchPattern = "%" + <string>filter.searchText + "%";
            baseQuery = sql:queryConcat(baseQuery, ` AND (name LIKE ${searchPattern} OR description LIKE ${searchPattern})`);
        }
    }
    
    baseQuery = sql:queryConcat(baseQuery, ` ORDER BY name ASC`);
    return baseQuery;
}

# This returns a parameterized SQL query to retrieve a resource by ID.
# + resourceId - The ID of the resource to be retrieved.
# + return - Returns a `sql:ParameterizedQuery` that can be executed to fetch the resource details.
isolated function getResourceByIdQuery(string resourceId) returns sql:ParameterizedQuery {
    return `
        SELECT 
            id, name, type, capacity, features, location, building, 
            floor, room_number, status, hourly_rate, description, 
            image_url, contact_person, created_at, updated_at, created_by
        FROM 
            resources 
        WHERE 
            id = ${resourceId}
    `;
}

# This returns a parameterized SQL query to add a new resource to the database.
# + resourceData - The resource details to be added.
# + return - Returns a `sql:ParameterizedQuery` that can be executed to insert the resource.
isolated function addResourceQuery(AddResource resourceData) returns sql:ParameterizedQuery {
    string? featuresJson = ();
    featuresJson = resourceData?.features.toJsonString();

    return `
        INSERT INTO 
            resources (id, name, type, capacity, features, location, building, 
                    floor, room_number, hourly_rate, description, image_url, 
                    contact_person, created_by)
        VALUES 
            (${resourceData.id}, ${resourceData.name}, ${resourceData.'type}, ${resourceData.capacity}, 
            ${featuresJson}, ${resourceData.location}, ${resourceData.building}, 
            ${resourceData.floor}, ${resourceData.roomNumber}, ${resourceData.hourlyRate}, 
            ${resourceData.description}, ${resourceData.imageUrl}, ${resourceData.contactPerson}, 
            'user_001')
    `;
}

# This returns a parameterized SQL query to update a resource in the database.
# + updateResource - The resource details to be updated.
# + return - Returns a `sql:ParameterizedQuery` that can be executed to update the resource.
isolated function updateResourceQuery(UpdateResource updateResource) returns sql:ParameterizedQuery {
    sql:ParameterizedQuery[] setParts = [];
    
    if updateResource.name is string {
        setParts.push(`name = ${updateResource.name}`);
    }
    
    if updateResource.'type is ResourceType {
        setParts.push(`type = ${updateResource.'type}`);
    }
    
    if updateResource.capacity is int {
        setParts.push(`capacity = ${updateResource.capacity}`);
    }
    
    string featuresJson = updateResource?.features.toJsonString();
    setParts.push(`features = ${featuresJson}`);
    
    if updateResource.location is string {
        setParts.push(`location = ${updateResource.location}`);
    }
    
    if updateResource.building is string {
        setParts.push(`building = ${updateResource.building}`);
    }
    
    if updateResource.floor is string {
        setParts.push(`floor = ${updateResource.floor}`);
    }
    
    if updateResource.roomNumber is string {
        setParts.push(`room_number = ${updateResource.roomNumber}`);
    }
    
    if updateResource.status is ResourceStatus {
        setParts.push(`status = ${updateResource.status}`);
    }
    
    if updateResource.hourlyRate is decimal {
        setParts.push(`hourly_rate = ${updateResource.hourlyRate}`);
    }
    
    if updateResource.description is string {
        setParts.push(`description = ${updateResource.description}`);
    }
    
    if updateResource.imageUrl is string {
        setParts.push(`image_url = ${updateResource.imageUrl}`);
    }
    
    if updateResource.contactPerson is string {
        setParts.push(`contact_person = ${updateResource.contactPerson}`);
    }
    
    // Join the parts with commas
    sql:ParameterizedQuery query = `UPDATE resources SET `;
    foreach int i in 0 ..< setParts.length() {
        if i > 0 {
            query = sql:queryConcat(query, `, `);
        }
        query = sql:queryConcat(query, setParts[i]);
    }
    query = sql:queryConcat(query, ` WHERE id = ${updateResource.id}`);
    
    return query;
}

# This returns a parameterized SQL query to delete a resource by ID.
# + resourceId - The ID of the resource to be deleted.
# + return - Returns a `sql:ParameterizedQuery` that can be executed to delete the resource.
isolated function deleteResourceQuery(string resourceId) returns sql:ParameterizedQuery {
    return `
        DELETE FROM 
            resources 
        WHERE 
            id = ${resourceId}
    `;
}

# This returns a parameterized SQL query to update resource status.
# + resourceId - The ID of the resource to update.
# + status - The new status to set for the resource.
# + return - Returns a `sql:ParameterizedQuery` that can be executed to update the resource status.
isolated function updateResourceStatusQuery(string resourceId, ResourceStatus status) returns sql:ParameterizedQuery {
    return `
        UPDATE 
            resources 
        SET 
            status = ${status}
        WHERE 
            id = ${resourceId}
    `;
}
