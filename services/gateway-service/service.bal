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

    # List all users with filtering - Admin and Staff only
    # + ctx - The HTTP request context
    # + caller - The HTTP caller to respond to.
    # + req - The HTTP request
    # + return - Returns list of users
    resource function get admin/users(http:RequestContext ctx, http:Caller caller, http:Request req) returns error? {
        
        // Check RBAC: Only admin and staff can list users
        string userGroups = ctx.get("userGroups").toString();
        string[] requiredGroups = [auth:authorizedRoles.Admin, auth:authorizedRoles.Staff];
        if (!auth:hasRequiredAccess(userGroups, requiredGroups)) {
            log:printError("Access denied: Admin or staff access required for user management");
            return caller->respond(createForbiddenError("Admin or staff access required to view users"));
        }
        
        // Prepare headers for the user service call
        map<string> headers = {
            "X-User-Id": ctx.get("userId").toString(),
            "X-Username": ctx.get("username").toString(),
            "X-User-Groups": ctx.get("userGroups").toString(),
            "Authorization": "Bearer " + ctx.get("m2mToken").toString()
        };

        // Forward query parameters to user service
        string queryParams = req.rawPath.includes("?") ? req.rawPath.substring(<int>req.rawPath.indexOf("?")) : "";
        string userPath = "/admin/users" + queryParams;

        log:printInfo("Forwarding GET /admin/users request to user service: " + userPath);
        http:Response|error response = userServiceClient->get(userPath, headers = headers);
        if response is http:Response {
            return caller->respond(response);
        } else {
            log:printError("Error calling user service: " + response.message());
            return caller->respond(createInternalServerError());
        }
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

    # Get current user profile - Accessible to all authenticated users
    # + ctx - The HTTP request context
    # + caller - The HTTP caller to respond to.
    # + return - Returns current user's profile
    resource function get user/me(http:RequestContext ctx, http:Caller caller) returns error? {
        
        // Prepare headers for the user service call
        map<string> headers = {
            "X-User-Id": ctx.get("userId").toString(),
            "X-Username": ctx.get("username").toString(),
            "X-User-Groups": ctx.get("userGroups").toString(),
            "Authorization": "Bearer " + ctx.get("m2mToken").toString()
        };

        log:printInfo("Forwarding GET /user/me request to user service");
        http:Response|error response = userServiceClient->get("/users/me", headers = headers);
        if response is http:Response {
            return caller->respond(response);
        } else {
            log:printError("Error calling user service: " + response.message());
            return caller->respond(createInternalServerError());
        }
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
    resource function patch resources/[string resourceId](http:RequestContext ctx, http:Caller caller, http:Request req) returns error? {
        
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

        log:printInfo("Forwarding PATCH /resources/" + resourceId + " request to resource service");
        http:Response|error response = resourceServiceClient->patch("/resources/" + resourceId, payload, headers = headers);
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

    # ===============================================
    # USER SERVICE ENDPOINTS - University User Management
    # ===============================================

    # Bulk import users - Admin only
    # + ctx - The HTTP request context
    # + caller - The HTTP caller to respond to.
    # + req - The HTTP request with bulk user data
    # + return - Returns bulk import results
    resource function post admin/users/bulk\-import(http:RequestContext ctx, http:Caller caller, http:Request req) returns error? {
        
        // Check RBAC: Only admin can bulk import users
        string userGroups = ctx.get("userGroups").toString();
        string[] requiredGroups = [auth:authorizedRoles.Admin];
        if (!auth:hasRequiredAccess(userGroups, requiredGroups)) {
            log:printError("Access denied: Admin access required for bulk user import");
            return caller->respond(createForbiddenError("Admin access required to bulk import users"));
        }
        
        // Prepare headers for the user service call
        map<string> headers = {
            "X-User-Id": ctx.get("userId").toString(),
            "X-Username": ctx.get("username").toString(),
            "X-User-Groups": ctx.get("userGroups").toString(),
            "Authorization": "Bearer " + ctx.get("m2mToken").toString(),
            "Content-Type": "application/json"
        };

        // Get request payload and forward to user service
        json|error payload = req.getJsonPayload();
        if payload is error {
            log:printError("Invalid JSON payload: " + payload.message());
            return caller->respond(createBadRequestError("Invalid JSON payload"));
        }

        log:printInfo("Forwarding POST /admin/users/bulk-import request to user service");
        http:Response|error response = userServiceClient->post("/admin/users/bulk-import", payload, headers = headers);
        if response is http:Response {
            return caller->respond(response);
        } else {
            log:printError("Error calling user service: " + response.message());
            return caller->respond(createInternalServerError());
        }
    }

    # Create single user - Admin only
    # + ctx - The HTTP request context
    # + caller - The HTTP caller to respond to.
    # + req - The HTTP request with user data
    # + return - Returns created user details
    resource function post admin/users(http:RequestContext ctx, http:Caller caller, http:Request req) returns error? {
        
        // Check RBAC: Only admin can create users
        string userGroups = ctx.get("userGroups").toString();
        string[] requiredGroups = [auth:authorizedRoles.Admin];
        if (!auth:hasRequiredAccess(userGroups, requiredGroups)) {
            log:printError("Access denied: Admin access required for user creation");
            return caller->respond(createForbiddenError("Admin access required to create users"));
        }
        
        // Prepare headers for the user service call
        map<string> headers = {
            "X-User-Id": ctx.get("userId").toString(),
            "X-Username": ctx.get("username").toString(),
            "X-User-Groups": ctx.get("userGroups").toString(),
            "Authorization": "Bearer " + ctx.get("m2mToken").toString(),
            "Content-Type": "application/json"
        };

        // Get request payload and forward to user service
        json|error payload = req.getJsonPayload();
        if payload is error {
            log:printError("Invalid JSON payload: " + payload.message());
            return caller->respond(createBadRequestError("Invalid JSON payload"));
        }

        log:printInfo("Forwarding POST /admin/users request to user service");
        http:Response|error response = userServiceClient->post("/admin/users", payload, headers = headers);
        if response is http:Response {
            return caller->respond(response);
        } else {
            log:printError("Error calling user service: " + response.message());
            return caller->respond(createInternalServerError());
        }
    }

    # Get user by ID - Admin and Staff only
    # + ctx - The HTTP request context
    # + caller - The HTTP caller to respond to.
    # + userId - The ID of the user to fetch
    # + return - Returns user details
    resource function get admin/users/[string userId](http:RequestContext ctx, http:Caller caller) returns error? {
        
        // Check RBAC: Only admin and staff can view user details
        string userGroups = ctx.get("userGroups").toString();
        string[] requiredGroups = [auth:authorizedRoles.Admin, auth:authorizedRoles.Staff];
        if (!auth:hasRequiredAccess(userGroups, requiredGroups)) {
            log:printError("Access denied: Admin or staff access required for user details");
            return caller->respond(createForbiddenError("Admin or staff access required to view user details"));
        }
        
        // Prepare headers for the user service call
        map<string> headers = {
            "X-User-Id": ctx.get("userId").toString(),
            "X-Username": ctx.get("username").toString(),
            "X-User-Groups": ctx.get("userGroups").toString(),
            "Authorization": "Bearer " + ctx.get("m2mToken").toString()
        };

        log:printInfo("Forwarding GET /admin/users/" + userId + " request to user service");
        http:Response|error response = userServiceClient->get("/admin/users/" + userId, headers = headers);
        if response is http:Response {
            return caller->respond(response);
        } else {
            log:printError("Error calling user service: " + response.message());
            return caller->respond(createInternalServerError());
        }
    }

    # Update user - Admin only
    # + ctx - The HTTP request context
    # + caller - The HTTP caller to respond to.
    # + req - The HTTP request with updated user data
    # + userId - The ID of the user to update
    # + return - Returns updated user details
    resource function patch admin/users/[string userId](http:RequestContext ctx, http:Caller caller, http:Request req) returns error? {
        
        // Check RBAC: Only admin can update users
        string userGroups = ctx.get("userGroups").toString();
        string[] requiredGroups = [auth:authorizedRoles.Admin];
        if (!auth:hasRequiredAccess(userGroups, requiredGroups)) {
            log:printError("Access denied: Admin access required for user updates");
            return caller->respond(createForbiddenError("Admin access required to update users"));
        }
        
        // Prepare headers for the user service call
        map<string> headers = {
            "X-User-Id": ctx.get("userId").toString(),
            "X-Username": ctx.get("username").toString(),
            "X-User-Groups": ctx.get("userGroups").toString(),
            "Authorization": "Bearer " + ctx.get("m2mToken").toString(),
            "Content-Type": "application/json"
        };

        // Get request payload and forward to user service
        json|error payload = req.getJsonPayload();
        if payload is error {
            log:printError("Invalid JSON payload: " + payload.message());
            return caller->respond(createBadRequestError("Invalid JSON payload"));
        }

        log:printInfo("Forwarding PATCH /admin/users/" + userId + " request to user service");
        http:Response|error response = userServiceClient->patch("/admin/users/" + userId, payload, headers = headers);
        if response is http:Response {
            return caller->respond(response);
        } else {
            log:printError("Error calling user service: " + response.message());
            return caller->respond(createInternalServerError());
        }
    }

    # Deactivate user - Admin only
    # + ctx - The HTTP request context
    # + caller - The HTTP caller to respond to.
    # + userId - The ID of the user to deactivate
    # + return - Returns success message
    resource function patch admin/users/[string userId]/deactivate(http:RequestContext ctx, http:Caller caller) returns error? {
        
        // Check RBAC: Only admin can deactivate users
        string userGroups = ctx.get("userGroups").toString();
        string[] requiredGroups = [auth:authorizedRoles.Admin];
        if (!auth:hasRequiredAccess(userGroups, requiredGroups)) {
            log:printError("Access denied: Admin access required for user deactivation");
            return caller->respond(createForbiddenError("Admin access required to deactivate users"));
        }
        
        // Prepare headers for the user service call
        map<string> headers = {
            "X-User-Id": ctx.get("userId").toString(),
            "X-Username": ctx.get("username").toString(),
            "X-User-Groups": ctx.get("userGroups").toString(),
            "Authorization": "Bearer " + ctx.get("m2mToken").toString()
        };

        log:printInfo("Forwarding PATCH /admin/users/" + userId + "/deactivate request to user service");
        http:Response|error response = userServiceClient->patch("/admin/users/" + userId + "/deactivate", (), headers = headers);
        if response is http:Response {
            return caller->respond(response);
        } else {
            log:printError("Error calling user service: " + response.message());
            return caller->respond(createInternalServerError());
        }
    }

    # User Service - Get user profile
    # 
    # + ctx - The HTTP request context
    # + caller - The HTTP caller to respond to.
    # + return - Returns user profile information
    resource function get users/me(http:RequestContext ctx, http:Caller caller) returns error? {
        
        // Prepare headers for the user service call
        map<string> headers = {
            "X-User-Id": ctx.get("userId").toString(),
            "X-Username": ctx.get("username").toString(),
            "X-User-Groups": ctx.get("userGroups").toString(),
            "Authorization": "Bearer " + ctx.get("m2mToken").toString()
        };

        log:printInfo("Forwarding GET /users/me request to user service");
        http:Response|error response = userServiceClient->get("/users/me", headers = headers);
        if response is http:Response {
            return caller->respond(response);
        } else {
            log:printError("Error calling user service: " + response.message());
            return caller->respond(createInternalServerError());
        }
    }

    # User service health check - Admin only
    # 
    # + ctx - The HTTP request context
    # + caller - The HTTP caller to respond to.
    # + return - Returns health status
    resource function get users/health(http:RequestContext ctx, http:Caller caller) returns error? {
        
        // Check RBAC: Only admin can check service health
        string userGroups = ctx.get("userGroups").toString();
        string[] requiredGroups = [auth:authorizedRoles.Admin];
        if (!auth:hasRequiredAccess(userGroups, requiredGroups)) {
            log:printError("Access denied: Admin access required for health check");
            return caller->respond(createForbiddenError("Admin access required to check service health"));
        }
        
        // Prepare headers for the user service call
        map<string> headers = {
            "X-User-Id": ctx.get("userId").toString(),
            "X-Username": ctx.get("username").toString(),
            "X-User-Groups": ctx.get("userGroups").toString(),
            "Authorization": "Bearer " + ctx.get("m2mToken").toString()
        };

        log:printInfo("Forwarding GET /users/health request to user service");
        http:Response|error response = userServiceClient->get("/health", headers = headers);
        if response is http:Response {
            return caller->respond(response);
        } else {
            log:printError("Error calling user service health endpoint: " + response.message());
            return caller->respond(createInternalServerError());
        }
    }

    # ===============================================
    # Booking SERVICE ENDPOINTS - Campus Booking Management
    # ===============================================

    # Booking Service - Create a new booking
    #
    # + ctx - The HTTP request context
    # + caller - The HTTP caller to respond to.
    # + return - Returns the created booking information
    resource function post bookings(http:RequestContext ctx, http:Caller caller, http:Request req) returns error? {

        // Prepare headers for the booking service call
        map<string> headers = {
            "X-User-Id": ctx.get("userId").toString(),
            "X-Username": ctx.get("username").toString(),
            "X-User-Groups": ctx.get("userGroups").toString(),
            "Authorization": "Bearer " + ctx.get("m2mToken").toString()
        };

        json|error payload = req.getJsonPayload();
        if payload is error {
            log:printError("Error parsing booking data: " + payload.message());
            return caller->respond(createBadRequestError("Invalid booking data"));
        }

        log:printInfo("Forwarding POST /bookings request to booking service");
        http:Response|error response = bookingServiceClient->post("/bookings", payload, headers = headers);
        if response is http:Response {
            return caller->respond(response);
        } else {
            log:printError("Error calling booking service: " + response.message());
            return caller->respond(createInternalServerError());
        }
    }

    # Booking Service - Get all bookings
    #
    # + ctx - The HTTP request context
    # + caller - The HTTP caller to respond to.
    # + return - Returns the list of bookings
    resource function get bookings(http:RequestContext ctx, http:Caller caller) returns error? {

        // Prepare headers for the booking service call
        map<string> headers = {
            "X-User-Id": ctx.get("userId").toString(),
            "X-Username": ctx.get("username").toString(),
            "X-User-Groups": ctx.get("userGroups").toString(),
            "Authorization": "Bearer " + ctx.get("m2mToken").toString()
        };

        log:printInfo("Forwarding GET /bookings request to booking service");
        http:Response|error response = bookingServiceClient->get("/bookings", headers = headers);
        if response is http:Response {
            return caller->respond(response);
        } else {
            log:printError("Error calling booking service: " + response.message());
            return caller->respond(createInternalServerError());
        }
    }

    # Booking Service - Get a specific booking
    #
    # + ctx - The HTTP request context
    # + caller - The HTTP caller to respond to.
    # + bookingId - The ID of the booking to retrieve
    # + return - Returns the booking information
    resource function get bookings/[string bookingId](http:RequestContext ctx, http:Caller caller) returns error? {

        // Prepare headers for the booking service call
        map<string> headers = {
            "X-User-Id": ctx.get("userId").toString(),
            "X-Username": ctx.get("username").toString(),
            "X-User-Groups": ctx.get("userGroups").toString(),
            "Authorization": "Bearer " + ctx.get("m2mToken").toString()
        };

        log:printInfo("Forwarding GET /bookings/" + bookingId + " request to booking service");
        http:Response|error response = bookingServiceClient->get("/bookings/" + bookingId, headers = headers);
        if response is http:Response {
            return caller->respond(response);
        } else {
            log:printError("Error calling booking service: " + response.message());
            return caller->respond(createInternalServerError());
        }
    }

    # Booking Service - Update a specific booking
    #
    # + ctx - The HTTP request context
    # + caller - The HTTP caller to respond to.
    # + bookingId - The ID of the booking to update
    # + return - Returns the updated booking information
    resource function patch bookings/[string bookingId](http:RequestContext ctx, http:Caller caller, http:Request req) returns error? {

        // Prepare headers for the booking service call
        map<string> headers = {
            "X-User-Id": ctx.get("userId").toString(),
            "X-Username": ctx.get("username").toString(),
            "X-User-Groups": ctx.get("userGroups").toString(),
            "Authorization": "Bearer " + ctx.get("m2mToken").toString()
        };

        json|error payload = req.getJsonPayload();
        if payload is error {
            log:printError("Error parsing booking data: " + payload.message());
            return caller->respond(createBadRequestError("Invalid booking data"));
        }

        log:printInfo("Forwarding PATCH /bookings/" + bookingId + " request to booking service");
        http:Response|error response = bookingServiceClient->patch("/bookings/" + bookingId, payload, headers = headers);
        if response is http:Response {
            return caller->respond(response);
        } else {
            log:printError("Error calling booking service: " + response.message());
            return caller->respond(createInternalServerError());
        }
    }

    # Booking Service - Delete a specific booking
    #
    # + ctx - The HTTP request context
    # + caller - The HTTP caller to respond to.
    # + bookingId - The ID of the booking to delete
    # + return - Returns a success message
    resource function delete bookings/[string bookingId](http:RequestContext ctx, http:Caller caller) returns error? {

        // Prepare headers for the booking service call
        map<string> headers = {
            "X-User-Id": ctx.get("userId").toString(),
            "X-Username": ctx.get("username").toString(),
            "X-User-Groups": ctx.get("userGroups").toString(),
            "Authorization": "Bearer " + ctx.get("m2mToken").toString()
        };

        log:printInfo("Forwarding DELETE /bookings/" + bookingId + " request to booking service");
        http:Response|error response = bookingServiceClient->delete("/bookings/" + bookingId, headers = headers);
        if response is http:Response {
            return caller->respond(response);
        } else {
            log:printError("Error calling booking service: " + response.message());
            return caller->respond(createInternalServerError());
        }
    }

    # Booking Service - Check booking conflicts
    #
    # + ctx - The HTTP request context
    # + caller - The HTTP caller to respond to.
    # + req - The HTTP request
    # + resourceId - The ID of the resource to check
    # + return - Returns a list of conflicting bookings
    resource function get conflicts/[string resourceId](http:RequestContext ctx, http:Caller caller, http:Request req) returns error? {

        // Prepare headers for the booking service call
        map<string> headers = {
            "X-User-Id": ctx.get("userId").toString(),
            "X-Username": ctx.get("username").toString(),
            "X-User-Groups": ctx.get("userGroups").toString(),
            "Authorization": "Bearer " + ctx.get("m2mToken").toString()
        };

        // Forward query parameters to booking service
        string queryParams = req.rawPath.includes("?") ? req.rawPath.substring(<int>req.rawPath.indexOf("?")) : "";
        string conflictsPath = "/conflicts/" + resourceId + queryParams;

        log:printInfo("Forwarding GET /conflicts/" + resourceId + " request to booking service: " + conflictsPath);
        http:Response|error response = bookingServiceClient->get(conflictsPath, headers = headers);
        if response is http:Response {
            return caller->respond(response);
        } else {
            log:printError("Error calling booking service: " + response.message());
            return caller->respond(createInternalServerError());
        }
    }

    # Booking Service - Check availability of resource
    #
    # + ctx - The HTTP request context
    # + caller - The HTTP caller to respond to.
    # + req - The HTTP request
    # + resourceId - The ID of the resource to check
    # + return - Returns the availability status of the resource
    resource function get availability/[string resourceId](http:RequestContext ctx, http:Caller caller, http:Request req) returns error? {

        // Prepare headers for the booking service call
        map<string> headers = {
            "X-User-Id": ctx.get("userId").toString(),
            "X-Username": ctx.get("username").toString(),
            "X-User-Groups": ctx.get("userGroups").toString(),
            "Authorization": "Bearer " + ctx.get("m2mToken").toString()
        };

        // Forward query parameters to booking service
        string queryParams = req.rawPath.includes("?") ? req.rawPath.substring(<int>req.rawPath.indexOf("?")) : "";
        string availabilityPath = "/availability/" + resourceId + queryParams;

        log:printInfo("Forwarding GET /availability/" + resourceId + " request to booking service: " + availabilityPath);
        http:Response|error response = bookingServiceClient->get(availabilityPath, headers = headers);
        if response is http:Response {
            return caller->respond(response);
        } else {
            log:printError("Error calling booking service: " + response.message());
            return caller->respond(createInternalServerError());
        }
    }

    # Booking Service - Admin list all bookings
    #
    # + ctx - The HTTP request context
    # + caller - The HTTP caller to respond to.
    # + return - Returns a list of all bookings
    resource function get admin/bookings(http:RequestContext ctx, http:Caller caller) returns error? {

        // Check RBAC: Only admin can schedule maintenance
        string userGroups = ctx.get("userGroups").toString();
        string[] requiredGroups = [auth:authorizedRoles.Admin];
        if (!auth:hasRequiredAccess(userGroups, requiredGroups)) {
            log:printError("Access denied: Admin access required for scheduling maintenance");
            return caller->respond(createForbiddenError("Admin access required to schedule resource maintenance"));
        }

        // Prepare headers for the booking service call
        map<string> headers = {
            "X-User-Id": ctx.get("userId").toString(),
            "X-Username": ctx.get("username").toString(),
            "X-User-Groups": ctx.get("userGroups").toString(),
            "Authorization": "Bearer " + ctx.get("m2mToken").toString()
        };

        log:printInfo("Forwarding GET /admin/bookings request to booking service");
        http:Response|error response = bookingServiceClient->get("/admin/bookings", headers = headers);
        if response is http:Response {
            return caller->respond(response);
        } else {
            log:printError("Error calling booking service: " + response.message());
            return caller->respond(createInternalServerError());
        }
    }

    # Booking Service - Admin 'approve' or 'reject' booking
    #
    # + ctx - The HTTP request context
    # + caller - The HTTP caller to respond to.
    # + bookingId - The ID of the booking to approve or reject
    # + action - The action to perform (approve or reject)
    # + return - Returns the result of the approval or rejection
    resource function patch admin/bookings/[string bookingId]/[string action](http:RequestContext ctx, http:Caller caller) returns error? {

        // Check RBAC: Only admin can approve or reject bookings
        string userGroups = ctx.get("userGroups").toString();
        string[] requiredGroups = [auth:authorizedRoles.Admin];
        if (!auth:hasRequiredAccess(userGroups, requiredGroups)) {
            log:printError("Access denied: Admin access required for approving or rejecting bookings");
            return caller->respond(createForbiddenError("Admin access required to approve or reject bookings"));
        }

        // Prepare headers for the booking service call
        map<string> headers = {
            "X-User-Id": ctx.get("userId").toString(),
            "X-Username": ctx.get("username").toString(),
            "X-User-Groups": ctx.get("userGroups").toString(),
            "Authorization": "Bearer " + ctx.get("m2mToken").toString()
        };

        log:printInfo("Forwarding POST /admin/bookings/" + bookingId + "/" + action + " request to booking service");
        http:Response|error response = bookingServiceClient->patch("/admin/bookings/" + bookingId + "/" + action, (), headers = headers);
        if response is http:Response {
            return caller->respond(response);
        } else {
            log:printError("Error calling booking service: " + response.message());
            return caller->respond(createInternalServerError());
        }
    }

    # Booking Service - Join waitlist for a resource
    #
    # + ctx - The HTTP request context
    # + caller - The HTTP caller to respond to.
    # + req - The HTTP request
    # + resourceId - The resource ID to join waitlist for
    # + return - Returns waitlist join result
    resource function post waitlist/[string resourceId](http:RequestContext ctx, http:Caller caller, http:Request req) returns error? {

        // Prepare headers for the booking service call
        map<string> headers = {
            "X-User-Id": ctx.get("userId").toString(),
            "X-Username": ctx.get("username").toString(),
            "X-User-Groups": ctx.get("userGroups").toString(),
            "Authorization": "Bearer " + ctx.get("m2mToken").toString(),
            "Content-Type": "application/json"
        };

        json|error payload = req.getJsonPayload();
        if payload is error {
            log:printError("Error parsing waitlist data: " + payload.message());
            return caller->respond(createBadRequestError("Invalid waitlist data"));
        }

        log:printInfo("Forwarding POST /waitlist/" + resourceId + " request to booking service");
        http:Response|error response = bookingServiceClient->post("/waitlist/" + resourceId, payload, headers = headers);
        if response is http:Response {
            return caller->respond(response);
        } else {
            log:printError("Error calling booking service: " + response.message());
            return caller->respond(createInternalServerError());
        }
    }

    # Booking Service - Get user's waitlist entries
    #
    # + ctx - The HTTP request context
    # + caller - The HTTP caller to respond to.
    # + return - Returns user's waitlist entries
    resource function get waitlist(http:RequestContext ctx, http:Caller caller) returns error? {

        // Prepare headers for the booking service call
        map<string> headers = {
            "X-User-Id": ctx.get("userId").toString(),
            "X-Username": ctx.get("username").toString(),
            "X-User-Groups": ctx.get("userGroups").toString(),
            "Authorization": "Bearer " + ctx.get("m2mToken").toString()
        };

        log:printInfo("Forwarding GET /waitlist request to booking service");
        http:Response|error response = bookingServiceClient->get("/waitlist", headers = headers);
        if response is http:Response {
            return caller->respond(response);
        } else {
            log:printError("Error calling booking service: " + response.message());
            return caller->respond(createInternalServerError());
        }
    }

    # Booking Service - Leave waitlist
    #
    # + ctx - The HTTP request context
    # + caller - The HTTP caller to respond to.
    # + waitlistId - The waitlist entry ID to remove
    # + return - Returns waitlist removal result
    resource function delete waitlist/[string waitlistId](http:RequestContext ctx, http:Caller caller) returns error? {

        // Prepare headers for the booking service call
        map<string> headers = {
            "X-User-Id": ctx.get("userId").toString(),
            "X-Username": ctx.get("username").toString(),
            "X-User-Groups": ctx.get("userGroups").toString(),
            "Authorization": "Bearer " + ctx.get("m2mToken").toString()
        };

        log:printInfo("Forwarding DELETE /waitlist/" + waitlistId + " request to booking service");
        http:Response|error response = bookingServiceClient->delete("/waitlist/" + waitlistId, headers = headers);
        if response is http:Response {
            return caller->respond(response);
        } else {
            log:printError("Error calling booking service: " + response.message());
            return caller->respond(createInternalServerError());
        }
    }

    # Booking Service - Check into a booking
    #
    # + ctx - The HTTP request context
    # + caller - The HTTP caller to respond to.
    # + req - The HTTP request
    # + bookingId - The booking ID to check into
    # + return - Returns check-in result
    resource function post bookings/[string bookingId]/checkin(http:RequestContext ctx, http:Caller caller, http:Request req) returns error? {

        // Prepare headers for the booking service call
        map<string> headers = {
            "X-User-Id": ctx.get("userId").toString(),
            "X-Username": ctx.get("username").toString(),
            "X-User-Groups": ctx.get("userGroups").toString(),
            "Authorization": "Bearer " + ctx.get("m2mToken").toString(),
            "Content-Type": "application/json"
        };

        json|error payload = req.getJsonPayload();
        if payload is error {
            log:printError("Error parsing check-in data: " + payload.message());
            return caller->respond(createBadRequestError("Invalid check-in data"));
        }

        log:printInfo("Forwarding POST /bookings/" + bookingId + "/checkin request to booking service");
        http:Response|error response = bookingServiceClient->post("/bookings/" + bookingId + "/checkin", payload, headers = headers);
        if response is http:Response {
            return caller->respond(response);
        } else {
            log:printError("Error calling booking service: " + response.message());
            return caller->respond(createInternalServerError());
        }
    }

    # Booking Service -  Check out of a booking
    #
    # + ctx - The HTTP request context
    # + caller - The HTTP caller to respond to.
    # + req - The HTTP request
    # + bookingId - The booking ID to check out of
    # + return - Returns check-out result
    resource function post bookings/[string bookingId]/checkout(http:RequestContext ctx, http:Caller caller, http:Request req) returns error? {

        // Prepare headers for the booking service call
        map<string> headers = {
            "X-User-Id": ctx.get("userId").toString(),
            "X-Username": ctx.get("username").toString(),
            "X-User-Groups": ctx.get("userGroups").toString(),
            "Authorization": "Bearer " + ctx.get("m2mToken").toString(),
            "Content-Type": "application/json"
        };

        json|error payload = req.getJsonPayload();
        if payload is error {
            log:printError("Error parsing check-out data: " + payload.message());
            return caller->respond(createBadRequestError("Invalid check-out data"));
        }

        log:printInfo("Forwarding POST /bookings/" + bookingId + "/checkout request to booking service");
        http:Response|error response = bookingServiceClient->post("/bookings/" + bookingId + "/checkout", payload, headers = headers);
        if response is http:Response {
            return caller->respond(response);
        } else {
            log:printError("Error calling booking service: " + response.message());
            return caller->respond(createInternalServerError());
        }
    }

    # Booking Service - Admin bulk create bookings
    #
    # + ctx - The HTTP request context
    # + caller - The HTTP caller to respond to.
    # + req - The HTTP request
    # + return - Returns bulk creation result
    resource function post admin/bookings/bulk(http:RequestContext ctx, http:Caller caller, http:Request req) returns error? {

        // Check RBAC: Only admin can perform bulk operations
        string userGroups = ctx.get("userGroups").toString();
        string[] requiredGroups = [auth:authorizedRoles.Admin];
        if (!auth:hasRequiredAccess(userGroups, requiredGroups)) {
            log:printError("Access denied: Admin access required for bulk booking operations");
            return caller->respond(createForbiddenError("Admin access required for bulk booking operations"));
        }

        // Prepare headers for the booking service call
        map<string> headers = {
            "X-User-Id": ctx.get("userId").toString(),
            "X-Username": ctx.get("username").toString(),
            "X-User-Groups": ctx.get("userGroups").toString(),
            "Authorization": "Bearer " + ctx.get("m2mToken").toString(),
            "Content-Type": "application/json"
        };

        json|error payload = req.getJsonPayload();
        if payload is error {
            log:printError("Error parsing bulk booking data: " + payload.message());
            return caller->respond(createBadRequestError("Invalid bulk booking data"));
        }

        log:printInfo("Forwarding POST /admin/bookings/bulk request to booking service");
        http:Response|error response = bookingServiceClient->post("/admin/bookings/bulk", payload, headers = headers);
        if response is http:Response {
            return caller->respond(response);
        } else {
            log:printError("Error calling booking service: " + response.message());
            return caller->respond(createInternalServerError());
        }
    }

}