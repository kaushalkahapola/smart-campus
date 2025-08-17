import ballerina/http;
import ballerina/log;
import ballerina/time;

import gateway_service.auth;

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

service http:InterceptableService /api on new http:Listener(9090) {

    public function createInterceptors() returns http:Interceptor[] {
        return [new auth:AuthInterceptor(), new ErrorInterceptor()];
    }

    # This resource function is a sample endpoint to demonstrate the interceptor.
    # It can be removed or modified as needed.
    # 
    # + ctx - The HTTP request context
    # + caller - The HTTP caller to respond to.
    # + req - The HTTP request.
    # + return - Returns a sample response from the gateway service
    resource function get sample(http:RequestContext ctx, http:Caller caller, http:Request req) returns error? {

        // Prepare headers for the campus service call
        map<string> headers = {
            "X-User-Id": ctx.get("userId").toString(),
            "X-Username": ctx.get("username").toString(),
            "X-User-Groups": ctx.get("userGroups").toString(),
            "Authorization": "Bearer " + ctx.get("m2mToken").toString()
        };

        // Call the user service with the prepared headers
        log:printInfo("Headers sent to user service: " + headers.toString());
        http:Response|error response = userServiceClient->get("/sample", headers = headers);
        if response is http:Response {
            return caller->respond(response);
        } else {
            return caller->respond(createInternalServerError());
        }
    }

    # Admin only endpoint - Test admin access
    # 
    # + ctx - The HTTP request context
    # + caller - The HTTP caller to respond to.
    # + return - Returns a response with admin data
    resource function get admin/dashboard(http:RequestContext ctx, http:Caller caller) returns error? {
        
        // Check RBAC: Only admin can access dashboard
        string userGroups = ctx.get("userGroups").toString();
        string[] requiredGroups = [auth:authorizedRoles.Admin];
        if (!auth:hasRequiredAccess(userGroups, requiredGroups)) {
            log:printError("Access denied: Admin access required for dashboard");
            return caller->respond(createForbiddenError("Admin access required to view dashboard"));
        }
        
        json adminData = {
            "message": "Admin Dashboard Access Granted",
            "data": "Sensitive admin information",
            "timestamp": time:utcNow()[0]
        };
        return caller->respond(adminData);
    }

    # Staff only endpoint - Test staff access  
    # 
    # + ctx - The HTTP request context
    # + caller - The HTTP caller to respond to.
    # + return - Returns a response with staff data
    resource function get admin/users(http:RequestContext ctx, http:Caller caller) returns error? {
        
        // Check RBAC: Only admin and staff can access user management
        string userGroups = ctx.get("userGroups").toString();
        string[] requiredGroups = [auth:authorizedRoles.Admin, auth:authorizedRoles.Staff];
        if (!auth:hasRequiredAccess(userGroups, requiredGroups)) {
            log:printError("Access denied: Admin or staff access required for user management");
            return caller->respond(createForbiddenError("Admin or staff access required to view user management"));
        }
        
        json staffData = {
            "message": "Staff User Management Access Granted", 
            "data": "Student and user data access",
            "timestamp": time:utcNow()[0]
        };
        return caller->respond(staffData);
    }

    # Resource endpoints - Accessible to all authenticated users
    # 
    # + caller - The HTTP caller to respond to.
    # + return - Returns available resources
    resource function get 'resource/list(http:Caller caller) returns error? {
        json resourceData = {
            "message": "Resource List Access Granted",
            "resources": ["Lecture Hall A", "Computer Lab 1", "Study Room Alpha"],
            "timestamp": time:utcNow()[0]
        };
        return caller->respond(resourceData);
    }

    # Booking endpoints - Accessible to all authenticated users
    # 
    # + ctx - The HTTP request context
    # + caller - The HTTP caller to respond to.
    # + return - Returns booking data
    resource function get booking/my(http:RequestContext ctx, http:Caller caller) returns error? {
        json bookingData = {
            "message": "My Bookings Access Granted",
            "userId": ctx.get("userId").toString(),
            "username": ctx.get("username").toString(),
            "userGroups": ctx.get("userGroups").toString(),
            "bookings": ["Computer Lab 1 - 2025-08-18 10:00", "Study Room - 2025-08-19 14:00"],
            "timestamp": time:utcNow()[0]
        };
        return caller->respond(bookingData);
    }

    # AI recommendation endpoint - Accessible to all users
    # 
    # + ctx - The HTTP request context  
    # + caller - The HTTP caller to respond to.
    # + return - Returns AI recommendations
    resource function get ai/recommend/resources(http:RequestContext ctx, http:Caller caller) returns error? {
        json aiData = {
            "message": "AI Recommendations Access Granted",
            "userId": ctx.get("userId").toString(),
            "recommendations": ["Lab B (92% match)", "Study Room Beta (87% match)", "Lecture Hall C (78% match)"],
            "timestamp": time:utcNow()[0]
        };
        return caller->respond(aiData);
    }

    # Student profile endpoint - Should work for students accessing their own data
    # 
    # + ctx - The HTTP request context
    # + caller - The HTTP caller to respond to.
    # + return - Returns user profile
    resource function get user/me(http:RequestContext ctx, http:Caller caller) returns error? {
        json profileData = {
            "message": "User Profile Access Granted",
            "userId": ctx.get("userId").toString(),
            "username": ctx.get("username").toString(),
            "userGroups": ctx.get("userGroups").toString(),
            "profile": {
                "department": "Computer Science",
                "studentId": "CS2021001",
                "email": "student@university.edu"
            },
            "timestamp": time:utcNow()[0]
        };
        return caller->respond(profileData);
    }

    # Analytics endpoint - Should be accessible to staff and admin
    # 
    # + ctx - The HTTP request context
    # + caller - The HTTP caller to respond to.
    # + return - Returns analytics data
    resource function get analytics/usage(http:RequestContext ctx, http:Caller caller) returns error? {
        
        // Check RBAC: Only admin and staff can access analytics
        string userGroups = ctx.get("userGroups").toString();
        string[] requiredGroups = [auth:authorizedRoles.Admin, auth:authorizedRoles.Staff];
        if (!auth:hasRequiredAccess(userGroups, requiredGroups)) {
            log:printError("Access denied: Admin or staff access required for analytics");
            return caller->respond(createForbiddenError("Admin or staff access required to view analytics"));
        }
        
        json analyticsData = {
            "message": "Analytics Access Granted",
            "data": {
                "totalBookings": 245,
                "activeUsers": 89,
                "resourceUtilization": "78%"
            },
            "timestamp": time:utcNow()[0]
        };
        return caller->respond(analyticsData);
    }

    # ===============================================
    # RESOURCE SERVICE ENDPOINTS - Campus Resource Management
    # ===============================================

    # List all resources with optional filtering - Accessible to all authenticated users
    # + ctx - The HTTP request context
    # + caller - The HTTP caller to respond to.
    # + req - The HTTP request
    # + return - Returns list of available resources
    resource function get resources(http:RequestContext ctx, http:Caller caller, http:Request req) returns error? {
        
        // Prepare headers for the resource service call
        map<string> headers = {
            "X-User-Id": ctx.get("userId").toString(),
            "X-Username": ctx.get("username").toString(),
            "X-User-Groups": ctx.get("userGroups").toString(),
            "Authorization": "Bearer " + ctx.get("m2mToken").toString()
        };

        // Forward query parameters to resource service
        string queryParams = req.rawPath.includes("?") ? req.rawPath.substring(<int>req.rawPath.indexOf("?")) : "";
        string resourcePath = "/resources" + queryParams;

        log:printInfo("Forwarding GET /resources request to resource service: " + resourcePath);
        http:Response|error response = resourceServiceClient->get(resourcePath, headers = headers);
        if response is http:Response {
            return caller->respond(response);
        } else {
            log:printError("Error calling resource service: " + response.message());
            return caller->respond(createInternalServerError());
        }
    }

    # Get specific resource by ID - Accessible to all authenticated users
    # + ctx - The HTTP request context
    # + caller - The HTTP caller to respond to.
    # + resourceId - The ID of the resource to fetch
    # + return - Returns the resource details
    resource function get resources/[string resourceId](http:RequestContext ctx, http:Caller caller) returns error? {
        
        // Prepare headers for the resource service call
        map<string> headers = {
            "X-User-Id": ctx.get("userId").toString(),
            "X-Username": ctx.get("username").toString(),
            "X-User-Groups": ctx.get("userGroups").toString(),
            "Authorization": "Bearer " + ctx.get("m2mToken").toString()
        };

        log:printInfo("Forwarding GET /resources/" + resourceId + " request to resource service");
        http:Response|error response = resourceServiceClient->get("/resources/" + resourceId, headers = headers);
        if response is http:Response {
            return caller->respond(response);
        } else {
            log:printError("Error calling resource service: " + response.message());
            return caller->respond(createInternalServerError());
        }
    }

    # Create new campus resource - Admin only
    # + ctx - The HTTP request context
    # + caller - The HTTP caller to respond to.
    # + req - The HTTP request with resource data
    # + return - Returns success message or error
    resource function post resources(http:RequestContext ctx, http:Caller caller, http:Request req) returns error? {
        
        // Check RBAC: Only admin can create resources
        string userGroups = ctx.get("userGroups").toString();
        string[] requiredGroups = [auth:authorizedRoles.Admin];
        if (!auth:hasRequiredAccess(userGroups, requiredGroups)) {
            log:printError("Access denied: Admin access required for creating resources");
            return caller->respond(createForbiddenError("Admin access required to create campus resources"));
        }
        
        // Prepare headers for the resource service call
        map<string> headers = {
            "X-User-Id": ctx.get("userId").toString(),
            "X-Username": ctx.get("username").toString(),
            "X-User-Groups": ctx.get("userGroups").toString(),
            "Authorization": "Bearer " + ctx.get("m2mToken").toString(),
            "Content-Type": "application/json"
        };

        // Get request payload and forward to resource service
        json|error payload = req.getJsonPayload();
        if payload is error {
            log:printError("Invalid JSON payload: " + payload.message());
            return caller->respond(createBadRequestError("Invalid JSON payload"));
        }

        log:printInfo("Forwarding POST /resources request to resource service");
        http:Response|error response = resourceServiceClient->post("/resources", payload, headers = headers);
        if response is http:Response {
            return caller->respond(response);
        } else {
            log:printError("Error calling resource service: " + response.message());
            return caller->respond(createInternalServerError());
        }
    }

    # Update existing resource - Admin and Staff only
    # + ctx - The HTTP request context
    # + caller - The HTTP caller to respond to.
    # + req - The HTTP request with updated resource data
    # + resourceId - The ID of the resource to update
    # + return - Returns success message or error
    resource function put resources/[string resourceId](http:RequestContext ctx, http:Caller caller, http:Request req) returns error? {
        
        // Check RBAC: Only admin and staff can update resources
        string userGroups = ctx.get("userGroups").toString();
        string[] requiredGroups = [auth:authorizedRoles.Admin, auth:authorizedRoles.Staff];
        if (!auth:hasRequiredAccess(userGroups, requiredGroups)) {
            log:printError("Access denied: Admin or staff access required for updating resources");
            return caller->respond(createForbiddenError("Admin or staff access required to update campus resources"));
        }
        
        // Prepare headers for the resource service call
        map<string> headers = {
            "X-User-Id": ctx.get("userId").toString(),
            "X-Username": ctx.get("username").toString(),
            "X-User-Groups": ctx.get("userGroups").toString(),
            "Authorization": "Bearer " + ctx.get("m2mToken").toString(),
            "Content-Type": "application/json"
        };

        // Get request payload and forward to resource service
        json|error payload = req.getJsonPayload();
        if payload is error {
            log:printError("Invalid JSON payload: " + payload.message());
            return caller->respond(createBadRequestError("Invalid JSON payload"));
        }

        log:printInfo("Forwarding PUT /resources/" + resourceId + " request to resource service");
        http:Response|error response = resourceServiceClient->put("/resources/" + resourceId, payload, headers = headers);
        if response is http:Response {
            return caller->respond(response);
        } else {
            log:printError("Error calling resource service: " + response.message());
            return caller->respond(createInternalServerError());
        }
    }

    # Delete resource - Admin only
    # + ctx - The HTTP request context
    # + caller - The HTTP caller to respond to.
    # + resourceId - The ID of the resource to delete
    # + return - Returns success message or error
    resource function delete resources/[string resourceId](http:RequestContext ctx, http:Caller caller) returns error? {
        
        // Check RBAC: Only admin can delete resources
        string userGroups = ctx.get("userGroups").toString();
        string[] requiredGroups = [auth:authorizedRoles.Admin];
        if (!auth:hasRequiredAccess(userGroups, requiredGroups)) {
            log:printError("Access denied: Admin access required for deleting resources");
            return caller->respond(createForbiddenError("Admin access required to delete campus resources"));
        }
        
        // Prepare headers for the resource service call
        map<string> headers = {
            "X-User-Id": ctx.get("userId").toString(),
            "X-Username": ctx.get("username").toString(),
            "X-User-Groups": ctx.get("userGroups").toString(),
            "Authorization": "Bearer " + ctx.get("m2mToken").toString()
        };

        log:printInfo("Forwarding DELETE /resources/" + resourceId + " request to resource service");
        http:Response|error response = resourceServiceClient->delete("/resources/" + resourceId, headers = headers);
        if response is http:Response {
            return caller->respond(response);
        } else {
            log:printError("Error calling resource service: " + response.message());
            return caller->respond(createInternalServerError());
        }
    }

    # Update resource status - Admin and Staff only
    # + ctx - The HTTP request context
    # + caller - The HTTP caller to respond to.
    # + req - The HTTP request with status update
    # + resourceId - The ID of the resource to update status
    # + return - Returns success message or error
    resource function patch resources/[string resourceId]/status(http:RequestContext ctx, http:Caller caller, http:Request req) returns error? {
        
        // Check RBAC: Only admin and staff can update resource status
        string userGroups = ctx.get("userGroups").toString();
        string[] requiredGroups = [auth:authorizedRoles.Admin, auth:authorizedRoles.Staff];
        if (!auth:hasRequiredAccess(userGroups, requiredGroups)) {
            log:printError("Access denied: Admin or staff access required for updating resource status");
            return caller->respond(createForbiddenError("Admin or staff access required to update resource status"));
        }
        
        // Prepare headers for the resource service call
        map<string> headers = {
            "X-User-Id": ctx.get("userId").toString(),
            "X-Username": ctx.get("username").toString(),
            "X-User-Groups": ctx.get("userGroups").toString(),
            "Authorization": "Bearer " + ctx.get("m2mToken").toString(),
            "Content-Type": "application/json"
        };

        // Get request payload and forward to resource service
        json|error payload = req.getJsonPayload();
        if payload is error {
            log:printError("Invalid JSON payload: " + payload.message());
            return caller->respond(createBadRequestError("Invalid JSON payload"));
        }

        log:printInfo("Forwarding PATCH /resources/" + resourceId + "/status request to resource service");
        http:Response|error response = resourceServiceClient->patch("/resources/" + resourceId + "/status", payload, headers = headers);
        if response is http:Response {
            return caller->respond(response);
        } else {
            log:printError("Error calling resource service: " + response.message());
            return caller->respond(createInternalServerError());
        }
    }

    # Check resource availability - Accessible to all authenticated users
    # + ctx - The HTTP request context
    # + caller - The HTTP caller to respond to.
    # + req - The HTTP request
    # + resourceId - The ID of the resource to check availability
    # + return - Returns availability information
    resource function get resources/[string resourceId]/availability(http:RequestContext ctx, http:Caller caller, http:Request req) returns error? {
        
        // Prepare headers for the resource service call
        map<string> headers = {
            "X-User-Id": ctx.get("userId").toString(),
            "X-Username": ctx.get("username").toString(),
            "X-User-Groups": ctx.get("userGroups").toString(),
            "Authorization": "Bearer " + ctx.get("m2mToken").toString()
        };

        // Forward query parameters to resource service
        string queryParams = req.rawPath.includes("?") ? req.rawPath.substring(<int>req.rawPath.indexOf("?")) : "";
        string resourcePath = "/resources/" + resourceId + "/availability" + queryParams;

        log:printInfo("Forwarding GET /resources/" + resourceId + "/availability request to resource service");
        http:Response|error response = resourceServiceClient->get(resourcePath, headers = headers);
        if response is http:Response {
            return caller->respond(response);
        } else {
            log:printError("Error calling resource service: " + response.message());
            return caller->respond(createInternalServerError());
        }
    }

    # Schedule resource maintenance - Admin only
    # + ctx - The HTTP request context
    # + caller - The HTTP caller to respond to.
    # + req - The HTTP request with maintenance data
    # + resourceId - The ID of the resource to schedule maintenance
    # + return - Returns success message or error
    resource function post resources/[string resourceId]/maintenance(http:RequestContext ctx, http:Caller caller, http:Request req) returns error? {
        
        // Check RBAC: Only admin can schedule maintenance
        string userGroups = ctx.get("userGroups").toString();
        string[] requiredGroups = [auth:authorizedRoles.Admin];
        if (!auth:hasRequiredAccess(userGroups, requiredGroups)) {
            log:printError("Access denied: Admin access required for scheduling maintenance");
            return caller->respond(createForbiddenError("Admin access required to schedule resource maintenance"));
        }
        
        // Prepare headers for the resource service call
        map<string> headers = {
            "X-User-Id": ctx.get("userId").toString(),
            "X-Username": ctx.get("username").toString(),
            "X-User-Groups": ctx.get("userGroups").toString(),
            "Authorization": "Bearer " + ctx.get("m2mToken").toString(),
            "Content-Type": "application/json"
        };

        // Get request payload and forward to resource service
        json|error payload = req.getJsonPayload();
        if payload is error {
            log:printError("Invalid JSON payload: " + payload.message());
            return caller->respond(createBadRequestError("Invalid JSON payload"));
        }

        log:printInfo("Forwarding POST /resources/" + resourceId + "/maintenance request to resource service");
        http:Response|error response = resourceServiceClient->post("/resources/" + resourceId + "/maintenance", payload, headers = headers);
        if response is http:Response {
            return caller->respond(response);
        } else {
            log:printError("Error calling resource service: " + response.message());
            return caller->respond(createInternalServerError());
        }
    }

    # Resource service health check - Admin only
    # + ctx - The HTTP request context
    # + caller - The HTTP caller to respond to.
    # + return - Returns health status
    resource function get resources/health(http:RequestContext ctx, http:Caller caller) returns error? {
        
        // Check RBAC: Only admin can check service health
        string userGroups = ctx.get("userGroups").toString();
        string[] requiredGroups = [auth:authorizedRoles.Admin];
        if (!auth:hasRequiredAccess(userGroups, requiredGroups)) {
            log:printError("Access denied: Admin access required for health check");
            return caller->respond(createForbiddenError("Admin access required to check service health"));
        }
        
        // Prepare headers for the resource service call
        map<string> headers = {
            "X-User-Id": ctx.get("userId").toString(),
            "X-Username": ctx.get("username").toString(),
            "X-User-Groups": ctx.get("userGroups").toString(),
            "Authorization": "Bearer " + ctx.get("m2mToken").toString()
        };

        log:printInfo("Forwarding GET /resources/health request to resource service");
        http:Response|error response = resourceServiceClient->get("/health", headers = headers);
        if response is http:Response {
            return caller->respond(response);
        } else {
            log:printError("Error calling resource service health endpoint: " + response.message());
            return caller->respond(createInternalServerError());
        }
    }
}