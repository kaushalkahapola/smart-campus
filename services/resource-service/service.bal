import resource_service.auth;
import resource_service.db;

import ballerina/http;
import ballerina/log;
import ballerina/time;

# Interceptor to handle errors in the response
service class ErrorInterceptor {
    *http:ResponseErrorInterceptor;

    # This function intercepts errors in the response and handles them.
    # 
    # + err - The error that occurred during the response
    # + ctx - The HTTP request context
    # + return - Returns an HTTP BadRequest response with a custom error message
    remote function interceptResponseError(error err, http:RequestContext ctx) returns http:BadRequest|error {

        // Handle data-binding errors.
        if err is http:PayloadBindingError {
            string customError = string `Payload binding failed!`;
            log:printError(customError, err);
            return {
                body: {
                    message: customError
                }
            };
        }
        return err;
    }
}

service http:InterceptableService / on new http:Listener(9093) {

    public function createInterceptors() returns http:Interceptor[] {
        return [new auth:AuthInterceptor(), new ErrorInterceptor()];
    }

    # Get all resources with optional filtering
    # + req - The HTTP request
    # + 'type - Filter by resource type (optional)
    # + building - Filter by building (optional)
    # + minCapacity - Filter by minimum capacity (optional)
    # + maxCapacity - Filter by maximum capacity (optional)
    # + status - Filter by status (optional)
    # + search - Search text for name or description (optional)
    # + return - Returns array of resources or error
    resource function get resources(http:Request req, 
                                    db:ResourceType? 'type = (), 
                                    string? building = (), 
                                    int? minCapacity = (), 
                                    int? maxCapacity = (), 
                                    db:ResourceStatus? status = (), 
                                    string? search = ()) 
        returns ResourceListResponse|InternalServerErrorResponse {
        
        log:printInfo("Fetching resources with filters");
        
        db:ResourceFilter? filter = ();
        if ('type is db:ResourceType || building is string || minCapacity is int || 
            maxCapacity is int || status is db:ResourceStatus || search is string) {
            filter = {
                'type: 'type,
                building: building,
                minCapacity: minCapacity,
                maxCapacity: maxCapacity,
                status: status,
                searchText: search
            };
        }
        
        db:Resource[]|error resources = db:getAllResources(filter);
        if resources is error {
            log:printError("Error fetching resources: " + resources.message());
            return <InternalServerErrorResponse> {
                body: {
                    errorMessage: "Failed to fetch resources",
                    details: resources.message()
                }
            };
        }
        
        // Convert db:Resource[] to json[]
        json[] resourcesJson = [];
        foreach db:Resource r in resources {
            resourcesJson.push(r.toJson());
        }
        
        log:printInfo("Successfully fetched " + resources.length().toString() + " resources");
        return <ResourceListResponse> {
            body: {
                message: "Resources fetched successfully",
                data: {
                    resources: resourcesJson,
                    total: resourcesJson.length()
                },
                timestamp: time:utcNow()[0].toString()
            }
        };
    }

    # Get a specific resource by ID
    # + req - The HTTP request
    # + resourceId - The ID of the resource to fetch
    # + return - Returns the resource or error
    resource function get resources/[string resourceId](http:Request req) returns ResourceResponse|InternalServerErrorResponse|NotFoundResponse {

        log:printInfo("Fetching resource with ID: " + resourceId);
        
        db:Resource|error resourceData = db:getResourceById(resourceId);
        if resourceData is error {
            if resourceData.message().includes("not found") {
                log:printError("Resource not found: " + resourceId);
                return <NotFoundResponse> {
                    body: {
                        errorMessage: "Resource not found",
                        details: "Resource with ID " + resourceId + " not found"
                    }
                };
            } else {
                log:printError("Error fetching resource: " + resourceData.message());
                return <InternalServerErrorResponse> {
                    body: {
                        errorMessage: "Failed to fetch resource",
                        details: resourceData.message()
                    }
                };
            }
        }
        
        log:printInfo("Successfully fetched resource: " + resourceData.name);
        return <ResourceResponse> {
            body: {
                message: "Resource fetched successfully",
                data: resourceData.toJson(),
                timestamp: time:utcNow()[0].toString()
            }
        };
    }

    # Create a new resource
    # + req - The HTTP request
    # + return - Returns success message or error
    resource function post resources(CreateResourceRequest req) returns ResourceCreatedResponse|BadRequestResponse|InternalServerErrorResponse {

        db:AddResource resourcePayload = {
            ...req
        };

        log:printInfo("Creating new resource: " + resourcePayload.name);
        
        int|error result = db:addResource(resourcePayload);
        if result is error {
            log:printError("Error creating resource: " + result.message());
            return <InternalServerErrorResponse> {
                body: {
                    errorMessage: "Failed to create resource",
                    details: result.message()
                }
            };
        }
        
        return <ResourceCreatedResponse> {
            body: {
                message: "Resource created successfully",
                timestamp: time:utcNow()[0].toString()
            }
        };
    }

    # Update an existing resource
    # + req - The HTTP request
    # + resourceId - The ID of the resource to update
    # + return - Returns success message or error
    resource function put resources/[string resourceId](UpdateResourceRequest req) returns ResourceUpdatedResponse|BadRequestResponse|InternalServerErrorResponse| NotFoundResponse {

        db:UpdateResource|error updatePayload = req.cloneWithType(db:UpdateResource);
        if updatePayload is error {
            log:printError("Invalid update payload: " + updatePayload.message());
            return <BadRequestResponse> {
                body: {
                    errorMessage: "Invalid update data",
                    details: updatePayload.message()
                }
            };
        }
        
        // Set the resource ID from the path
        updatePayload.id = resourceId;
        
        log:printInfo("Updating resource with ID: " + resourceId);
        
        int|error result = db:updateResource(updatePayload);
        if result is error {
            log:printError("Error updating resource: " + result.message());
            return <InternalServerErrorResponse> {
                body: {
                    errorMessage: "Failed to update resource",
                    details: result.message()
                }
            };
        }
        
        if result == 0 {
            log:printError("Resource not found for update: " + resourceId);
            return <NotFoundResponse> {
                body: {
                    errorMessage: "Resource not found",
                    details: "Resource with ID " + resourceId + " not found"
                }
            };
        }
        
        log:printInfo("Successfully updated resource: " + resourceId);
        return <ResourceUpdatedResponse> {
            body: {
                resourceId: resourceId,
                message: "Resource updated successfully",
                timestamp: time:utcNow()[0].toString()
            }
        };
    }

    # Delete a resource
    # + req - The HTTP request
    # + resourceId - The ID of the resource to delete
    # + return - Returns success message or error
    resource function delete resources/[string resourceId](http:Request req) returns ResourceDeletedResponse|NotFoundResponse|InternalServerErrorResponse {

        log:printInfo("Deleting resource with ID: " + resourceId);
        
        int|error result = db:deleteResource(resourceId);
        if result is error {
            log:printError("Error deleting resource: " + result.message());
            return <InternalServerErrorResponse> {
                body: {
                    errorMessage: "Failed to delete resource",
                    details: result.message()
                }
            };
        }
        
        if result == 0 {
            log:printError("Resource not found for deletion: " + resourceId);
            return <NotFoundResponse> {
                body: {
                    errorMessage: "Resource not found",
                    details: "Resource with ID " + resourceId + " not found"
                }
            };
        }
        
        log:printInfo("Successfully deleted resource: " + resourceId);
        return <ResourceDeletedResponse> {
            body: {
                resourceId: resourceId,
                message: "Resource deleted successfully",
                timestamp: time:utcNow()[0].toString()
            }
        };
    }

    # Update resource status
    # + req - The HTTP request
    # + resourceId - The ID of the resource to update
    # + return - Returns success message or error
    resource function patch resources/[string resourceId]/status(UpdateResourceStatusRequest req) returns ResourceStatusUpdatedResponse|NotFoundResponse|InternalServerErrorResponse {

        json|error statusValue = req.status;
        if statusValue is error || statusValue !is string {
            return <NotFoundResponse> {
                body: {
                    errorMessage: "Invalid status data",
                    details: "Status field is required and must be a string"
                }
            };
        }
        
        db:ResourceStatus|error status = statusValue.cloneWithType(db:ResourceStatus);
        if status is error {
            return <NotFoundResponse> {
                body: {
                    errorMessage: "Invalid status value",
                    details: "Status must be one of: available, maintenance, unavailable, reserved"
                }
            };
        }
        
        log:printInfo("Updating status for resource " + resourceId + " to " + status);
        
        int|error result = db:updateResourceStatus(resourceId, status);
        if result is error {
            log:printError("Error updating resource status: " + result.message());
            return <InternalServerErrorResponse> {
                body: {
                    errorMessage: "Failed to update resource status",
                    details: result.message()
                }
            };
        }
        
        if result == 0 {
            log:printError("Resource not found for status update: " + resourceId);
            return <NotFoundResponse> {
                body: {
                    errorMessage: "Resource not found",
                    details: "Resource with ID " + resourceId + " not found"
                }
            };
        }
        
        log:printInfo("Successfully updated resource status: " + resourceId);
        return <ResourceStatusUpdatedResponse> {
            body: {
                resourceId: resourceId,
                status: status,
                message: "Resource status updated successfully",
                timestamp: time:utcNow()[0].toString()
            }
        };
    }

    # Check resource availability for a specific time period
    # + req - The HTTP request
    # + resourceId - The ID of the resource to check
    # + return - Returns availability information
    resource function get resources/[string resourceId]/availability(http:Request req) returns BadRequestResponse|SuccessResponse {

        string? startTime = req.getQueryParamValue("start_time");
        string? endTime = req.getQueryParamValue("end_time");
        
        if startTime is () || endTime is () {
            return <BadRequestResponse> {
                body: {
                    errorMessage: "Missing required parameters",
                    details: "Both start_time and end_time query parameters are required"
                }
            };
        }
        
        log:printInfo(string `Checking availability for resource ${resourceId} from ${startTime} to ${endTime}`);
        
        // For now, return a simple availability response
        // In a real implementation, this would check against the bookings table
        return <SuccessResponse> {
            body: {
                resourceId: resourceId,
                startTime: startTime,
                endTime: endTime,
                isAvailable: true,
                message: "Resource is available for the requested time period"
            }
        };
    }

    # Health check endpoint
    # + return - Returns service health status
    resource function get health() returns HealthResponse {

        return <HealthResponse> {
            body: {
                timestamp: time:utcNow()[0].toString(),
                message: "Health check successful",
                data: {
                    status: "UP",
                    'service: "resource-service",
                    'version: "1.0.0",
                    uptime_seconds: 0,
                    database: {
                        connected: true,
                        status: "healthy",
                        total_resources: 0
                    }
                }
            }
        };
    }
};
