# Role-Based Access Control Implementation Guide
## Smart Campus Resource Management Platform

## Current Status Analysis

### ✅ What's Already Implemented
1. **Asgardeo OAuth2 Integration**
   - Client application (`NffMwG6ChBwpfOu8feWsp_88qVMa`)
   - M2M application (`H4U8YLSGBrjPQYX3TBiCaGWZ_PAa`)
   - Token introspection endpoint integration
   - User info retrieval and caching

2. **Gateway Authentication**
   - JWT token validation via Asgardeo
   - User context extraction (username, user ID)
   - M2M token generation and caching
   - Public endpoint filtering

3. **Service-to-Service Authentication**
   - M2M token validation in user service
   - Proper token caching with expiration

## ❌ Missing: Campus Role-Based Access Control

### Problem
The current implementation extracts `username` and `userId` from Asgardeo user info but doesn't extract or validate campus user **roles** for authorization.

### Solution Required

#### 1. Update Gateway Auth Interceptor
**File**: `f:\finmate\services\gateway-service\modules\auth\auth.bal`

**Current Code**:
```ballerina
// Add user information to request context for downstream services
if (jwtPayload is map<json>) {
    json|error username = jwtPayload["username"];
    json|error userId = jwtPayload["sub"];
    if (username is string && userId is string) {
        ctx.set("username", username);
        ctx.set("userId", userId);
    }
}
```

**Need to Add**:
```ballerina
// Add user information to request context for downstream services
if (jwtPayload is map<json>) {
    json|error username = jwtPayload["username"];
    json|error userId = jwtPayload["sub"];
    json|error groups = jwtPayload["groups"]; // Asgardeo roles come in 'groups' claim
    
    if (username is string && userId is string) {
        ctx.set("username", username);
        ctx.set("userId", userId);
        
        // Extract campus user role from groups array
        string userRole = extractCampusRole(groups);
        ctx.set("userRole", userRole);
        
        // Validate role-based access for the requested campus endpoint
        string requestPath = req.rawPath;
        if (!hasCampusAccess(userRole, requestPath)) {
            log:printError("Access denied for campus role: " + userRole + " to path: " + requestPath);
            return createForbiddenResponse("Insufficient campus permissions");
        }
    }
}
```

#### 2. Add Campus Role Extraction Function
**File**: `f:\finmate\services\gateway-service\modules\auth\utils.bal`

**Add these functions**:
```ballerina
# Extracts campus user role from Asgardeo groups claim
# + groups - The groups claim from Asgardeo user info
# + return - The primary campus user role
isolated function extractCampusRole(json|error groups) returns string {
    if (groups is json[]) {
        // Campus role priority: admin > staff > student
        foreach json group in groups {
            if (group is string) {
                if (group == "admin" || group == "Administrator" || group == "campus_admin") {
                    return "admin";
                } else if (group == "staff" || group == "faculty" || group == "Staff") {
                    return "staff";
                } else if (group == "student" || group == "Student") {
                    return "student";
                }
            }
        }
        return "student"; // Default role for campus users
    }
    return "student"; // Default role if no groups found
}

# Checks if a campus user role has access to a specific endpoint
# + role - The user's campus role (admin, staff, student, system)
# + path - The request path
# + return - true if access is allowed, false otherwise
isolated function hasCampusAccess(string role, string path) returns boolean {
    match role {
        "admin" => {
            return true; // Campus admin has access to everything
        }
        "staff" => {
            // Staff can access student data, resources, and some admin endpoints
            return path.startsWith("/api/user/") || 
                   path.startsWith("/api/resource/") || 
                   path.startsWith("/api/booking/") ||
                   path.startsWith("/api/analytics/") ||
                   path.startsWith("/api/notification/");
        }
        "student" => {
            // Students can access their own data, resources, and bookings
            return path.startsWith("/api/user/me") || 
                   path.startsWith("/api/resource/") || 
                   path.startsWith("/api/booking/") ||
                   path.startsWith("/api/ai/recommend/") ||
                   path.startsWith("/api/notification/");
        }
        "system" => {
            // System role for AI service and automated operations
            return path.startsWith("/api/ai/") ||
                   path.startsWith("/api/analytics/") ||
                   path.startsWith("/api/notification/");
        }
        _ => {
            return false; // Unknown role, deny access
        }
    }
}

# Creates a forbidden HTTP response for campus access denial
# + message - The error message to include in the response
# + return - An HTTP Forbidden response with the error message
isolated function createForbiddenResponse(string message) returns http:Forbidden {
    http:Forbidden forbiddenResponse = {
        body: {
            "error": "Campus Access Forbidden",
            "message": message,
            "details": "Contact campus IT support if you believe this is an error"
        }
    };
    return forbiddenResponse;
}
```

#### 3. Update Security Headers for Campus Services
**File**: `f:\finmate\services\gateway-service\service.bal`

Update the sample endpoint to pass campus role information:
```ballerina
resource function get sample(http:RequestContext ctx, http:Caller caller, http:Request req) returns error? {
    // Prepare headers for the campus service call
    map<string> headers = {
        "X-User-Id": ctx.get("userId").toString(),
        "X-Username": ctx.get("username").toString(),
        "X-User-Role": ctx.get("userRole").toString(),
        "X-Campus-Role": ctx.get("userRole").toString(), // Explicit campus role header
        "Authorization": "Bearer " + ctx.get("m2mToken").toString()
    };
    
    // Rest of the implementation...
}
```

#### 4. Configure Asgardeo Campus Roles
In Asgardeo console, ensure you have:

1. **Campus User Groups/Roles** configured:
   - `admin` - Full campus system access (IT administrators)
   - `staff` - Faculty/staff access for department resources and student data
   - `student` - Regular campus user access (default for university emails)
   - `system` - AI service and automated system operations

2. **User Assignments**: Users assigned to appropriate campus groups based on university email domains

3. **Application Claims**: Ensure `groups` claim is included in user info response

4. **University Email Verification**: Configure email domain validation for campus registration

#### 5. Enhanced Campus Authorization Policies

**Create more granular access control for campus resources**:
```ballerina
# Enhanced role-based access control with campus resource-specific permissions
isolated function hasCampusResourceAccess(string role, string path, string method, string? userId, string? resourceUserId) returns boolean {
    match role {
        "admin" => {
            return true; // Campus admin has full access
        }
        "staff" => {
            // Staff can read most resources and manage their department's resources
            if (method == "GET") {
                return true; // Staff can view all campus resources
            }
            // Staff can create/update resources and manage student bookings
            return path.includes("/resource/") || 
                   path.includes("/booking/") ||
                   path.includes("/notification/");
        }
        "student" => {
            // Students can only access their own bookings and view available resources
            if (method == "GET" && path.includes("/resource/")) {
                return true; // Students can view all available resources
            }
            // Students can only manage their own bookings
            if (userId is string && resourceUserId is string) {
                return userId == resourceUserId;
            }
            // For paths without resource ID, check if it's the student's own data
            return path.startsWith("/api/user/me") || 
                   path.includes("/user/" + (userId ?: "")) ||
                   path.includes("/booking/user/" + (userId ?: ""));
        }
        "system" => {
            // System role for AI recommendations and analytics
            return path.startsWith("/api/ai/") ||
                   path.startsWith("/api/analytics/") ||
                   path.startsWith("/api/notification/system/");
        }
        _ => {
            return false;
        }
    }
}

# Campus-specific department access control
isolated function hasDepartmentAccess(string role, string userDepartment, string resourceDepartment) returns boolean {
    match role {
        "admin" => {
            return true; // Campus admin can access all departments
        }
        "staff" => {
            // Staff can access their own department resources and general campus resources
            return userDepartment == resourceDepartment || resourceDepartment == "general";
        }
        "student" => {
            // Students can access their department resources and general campus resources
            return userDepartment == resourceDepartment || resourceDepartment == "general";
        }
        _ => {
            return false;
        }
    }
}
```

## Implementation Steps

### Step 1: Update Gateway Auth Module ⚡ HIGH PRIORITY
1. Add role extraction logic to `auth.bal`
2. Add authorization functions to `utils.bal`
3. Update security headers to include user role

### Step 2: Configure Asgardeo
1. Create user groups: `admin`, `support`, `customer`
2. Assign users to appropriate groups
3. Ensure `groups` claim is included in user info response

### Step 3: Test Role-Based Access
1. Create test users with different roles
2. Test endpoint access with different role tokens
3. Verify proper access denial for unauthorized roles

### Step 4: Update Campus Services
1. Update all campus services to receive and validate `X-Campus-Role` header
2. Implement resource-level authorization in each campus service
3. Add role-based filtering for campus resource data access
4. Configure department-based access control

## Testing Strategy

### Campus Role Test Cases Required
1. **Admin Role**: Full access to all campus endpoints and resources
2. **Staff Role**: Access to department resources and student data management  
3. **Student Role**: Access only to own bookings and available campus resources
4. **System Role**: AI service access for recommendations and analytics
5. **Invalid Role**: Access denied with campus-specific error message
6. **Missing Role**: Default to student access with university email verification

### Test Campus Endpoints
```bash
# Test with campus admin token
curl -H "Authorization: Bearer <admin_token>" http://localhost:9090/api/resource/all

# Test with student token (should fail for admin endpoints)
curl -H "Authorization: Bearer <student_token>" http://localhost:9090/api/resource/admin

# Test student accessing own bookings (should succeed)  
curl -H "Authorization: Bearer <student_token>" http://localhost:9090/api/booking/user/me

# Test staff accessing department resources (should succeed)
curl -H "Authorization: Bearer <staff_token>" http://localhost:9090/api/resource/department/computer-science

# Test AI service with system token
curl -H "Authorization: Bearer <system_token>" http://localhost:9090/api/ai/recommend/resources
```

## Asgardeo Configuration Requirements

### Required Claims in Campus User Info Response
```json
{
  "sub": "user-uuid",
  "username": "john.doe@university.edu",
  "email": "john.doe@university.edu",
  "groups": ["student", "computer-science"], // Campus role and department
  "given_name": "John",
  "family_name": "Doe",
  "department": "computer-science",
  "campus_id": "main-campus",
  "student_id": "CS2021001" // For students
}
```

### Campus Application Configuration
- Ensure both client app and M2M app have proper campus scopes
- Include `groups`, `department`, and `campus_id` scopes in application configuration
- Configure proper redirect URIs for campus client app
- Set up university email domain validation
- Configure department-based group assignments

This implementation will complete the campus role-based access control system and make the Smart Campus Resource Management Platform production-ready with proper authorization mechanisms for university environments.
