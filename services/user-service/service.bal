import user_service.auth;
import user_service.db;
import user_service.scim;

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

service http:InterceptableService / on new http:Listener(9095) {

    public function createInterceptors() returns http:Interceptor[] {
        return [new auth:AuthInterceptor(), new ErrorInterceptor()];
    }

    # ========================================
    # ADMIN USER MANAGEMENT ENDPOINTS
    # ========================================

    # Admin bulk import users from CSV/Excel - Admin only
    # + req - The HTTP request with bulk user data
    # + return - Returns bulk import results
    resource function post admin/users/bulk\-import(BulkImportUsersRequest req) returns BulkImportResponse|BadRequestResponse|InternalServerErrorResponse {
        
        log:printInfo("Admin bulk import: processing " + req.users.length().toString() + " users");
        
        int successCount = 0;
        int failureCount = 0;
        record {| string email; string reason; |}[] failures = [];
        
        foreach scim:CampusUser user in req.users {
            
            // Validate user data
            error? validationResult = validateUserData(user);
            if validationResult is error {
                failures.push({
                    email: user.email,
                    reason: validationResult.message()
                });
                failureCount += 1;
                continue;
            }
            
            // Create user in Asgardeo and local DB
            scim:UserCreationResult result = createCampusUser(user);
            if result.success {
                successCount += 1;
            } else {
                failures.push({
                    email: user.email,
                    reason: result.errorMessage ?: "Unknown error"
                });
                failureCount += 1;
            }
        }
        
        log:printInfo("Bulk import completed: " + successCount.toString() + " success, " + failureCount.toString() + " failures");
        
        return <BulkImportResponse> {
            body: {
                message: "Bulk import completed",
                data: {
                    totalUsers: req.users.length(),
                    successfullyCreated: successCount,
                    failed: failureCount,
                    failures: failures
                },
                timestamp: time:utcNow()[0].toString()
            }
        };
    }

    # Admin create single user - Admin only
    # + user - The HTTP request with user data
    # + return - Returns user creation result
    resource function post admin/users(scim:CampusUser user) returns UserCreatedResponse|BadRequestResponse|ConflictResponse|InternalServerErrorResponse {
        
        log:printInfo("Admin creating user: " + user.email);
            
        
        // Validate user data
        error? validationResult = validateUserData(user);
        if validationResult is error {
            log:printError("User validation failed: " + validationResult.message());
            return <BadRequestResponse> {
                body: {
                    errorMessage: "Invalid user data",
                    details: validationResult.message()
                }
            };
        }
        
        // Create user in Asgardeo and local DB
        scim:UserCreationResult result = createCampusUser(user);
        if !result.success {
            log:printError("User creation failed: " + (result.errorMessage ?: "Unknown error"));
            return <InternalServerErrorResponse> {
                body: {
                    errorMessage: "Failed to create user",
                    details: result.errorMessage
                }
            };
        }
        
        log:printInfo("Successfully created user: " + user.email);
        return <UserCreatedResponse> {
            body: {
                message: "User created successfully",
                userId: result.localUserId ?: "",
                asgardeoUserId: result.asgardeoUserId ?: "",
                timestamp: time:utcNow()[0].toString()
            }
        };
    }

    # Admin list all users with filtering - Admin only
    # + role - Filter by role (optional)
    # + department - Filter by department (optional)
    # + isActive - Filter by active status (optional)
    # + page - Page number for pagination (optional)
    # + pageSize - Page size for pagination (optional)
    # + return - Returns list of users
    resource function get admin/users(scim:CampusRole? role = (), 
                                      string? department = (), 
                                      boolean? isActive = (), 
                                      int page = 1, 
                                      int pageSize = 20) 
        returns UserListResponse|InternalServerErrorResponse {
        
        log:printInfo("Admin fetching users with filters");
        
        // Build filter for database query
        db:UserFilter? filter = ();
        if role is string || department is string || isActive is boolean {
            filter = {
                role: role,
                department: department,
                isActive: isActive,
                isVerified: null,
                searchTerm: null
            };
        }
        
        // Get users from database
        db:User[]|error users = db:getAllUsers(filter, page, pageSize);
        if users is error {
            log:printError("Error fetching users: " + users.message());
            return <InternalServerErrorResponse> {
                body: {
                    errorMessage: "Failed to fetch users",
                    details: users.message()
                }
            };
        }
        
        // Convert to JSON array
        json[] usersJson = [];
        foreach db:User u in users {
            usersJson.push(u.toJson());
        }
        
        // Get total count for pagination
        int|error totalCount = db:getUserCount(filter);
        int total = totalCount is error ? 0 : totalCount;
        
        log:printInfo("Successfully fetched " + users.length().toString() + " users");
        return <UserListResponse> {
            body: {
                message: "Users fetched successfully",
                data: {
                    users: usersJson,
                    total: total,
                    page: page,
                    pageSize: pageSize
                },
                timestamp: time:utcNow()[0].toString()
            }
        };
    }

    # Get own user profile - All authenticated users
    # + return - Returns user profile
    resource function get users/me(http:Request req) returns UserProfileResponse|NotFoundResponse|InternalServerErrorResponse|http:HeaderNotFoundError {

        string email = check req.getHeader("X-Username");

        log:printInfo("User fetching own profile: " + email);

        db:User|error user = db:getUserByEmail(email);
        if user is error {
            log:printError("User not found: " + email);
            return <NotFoundResponse> {
                body: {
                    errorMessage: "User not found",
                    details: "User profile not found"
                }
            };
        }

        log:printInfo("Successfully fetched user profile: " + email);
        return <UserProfileResponse> {
            body: {
                message: "User profile fetched successfully",
                data: user.toJson(),
                timestamp: time:utcNow()[0].toString()
            }
        };
    }

    # Get user database id from email
    #
    # + email - The email of the user
    # + return - Returns the user database ID or an error
    resource function get users/[string email]/id() returns SuccessResponse|NotFoundResponse|InternalServerErrorResponse {

        log:printInfo("Fetching user database ID for email: " + email);

        db:User|error user = db:getUserByEmail(email);
        if user is error {
            log:printError("User not found: " + email);
            return <NotFoundResponse> {
                body: {
                    errorMessage: "User not found",
                    details: "User with email " + email + " not found"
                }
            };
        }

        log:printInfo("Successfully fetched user database ID for email: " + email);
        return <SuccessResponse> {
            body: {
                message: "User database ID fetched successfully",
                data: {
                    userId: user.id.toString()
                },
                timestamp: time:utcNow()[0].toString()
            }
        };
    }

    # Health check endpoint
    # + return - Returns service health status
    resource function get health() returns HealthResponse {
        
        // TODO: Check Asgardeo and database connectivity
        boolean asgardeoConnected = true; // Check SCIM connectivity
        boolean databaseConnected = true; // Check DB connectivity
        int totalUsers = 0; // Get from database
        
        return <HealthResponse> {
            body: {
                message: "Health check successful",
                data: {
                    status: "UP",
                    'service: "user-service",
                    'version: "1.0.0",
                    uptime_seconds: 0,
                    dependencies: {
                        asgardeoConnected: asgardeoConnected,
                        databaseConnected: databaseConnected,
                        totalUsers: totalUsers
                    }
                },
                timestamp: time:utcNow()[0].toString()
            }
        };
    }
}
