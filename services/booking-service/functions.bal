import booking_service.db;
import booking_service.auth;

import ballerina/uuid;
import ballerina/log;
import ballerina/time;

# Validate booking request data
#
# + request - The booking request to validate
# + return - error? - Returns an error if validation fails
function validateBookingRequest(CreateBookingRequest request) returns error? {
    
    // Validate required fields
    if request.resourceId.trim().length() == 0 {
        return error("Resource ID is required");
    }
    
    if request.title.trim().length() == 0 {
        return error("Booking title is required");
    }
    
    if request.startTime.trim().length() == 0 {
        return error("Start time is required");
    }
    
    if request.endTime.trim().length() == 0 {
        return error("End time is required");
    }
    
    // Validate attendees count
    if request.attendeesCount < 1 {
        return error("Attendees count must be at least 1");
    }
    
    // TODO: Validate datetime formats
    // TODO: Validate that end time is after start time
    // TODO: Validate that booking is not in the past
    // TODO: Validate maximum booking duration
    
    return ();
}

# Convert ISO datetime string to Civil time
#
# + isoString - ISO format datetime string
# + return - Civil time or error
function parseDateTime(string isoString) returns time:Civil|error {
    // TODO: Implement proper ISO datetime parsing
    // For now, return a mock Civil time
    return {
        year: 2025,
        month: 8,
        day: 18,
        hour: 10,
        minute: 0,
        second: 0
    };
}

# Convert ISO date string to Date
#
# + isoString - ISO format date string
# + return - Date or error
function parseDate(string isoString) returns time:Date|error {
    // TODO: Implement proper ISO date parsing
    // For now, return a mock Date
    return {
        year: 2025,
        month: 8,
        day: 18
    };
}

# Convert Civil time to ISO datetime string
#
# + civil - Civil time
# + return - ISO format datetime string
function formatDateTime(time:Civil civil) returns string {
    // TODO: Implement proper ISO datetime formatting
    return "2025-08-18T10:00:00Z";
}

# Convert Date to ISO date string
#
# + date - Date
# + return - ISO format date string
function formatDate(time:Date date) returns string {
    // TODO: Implement proper ISO date formatting
    return "2025-08-18";
}

# Create booking record from request
#
# + request - Create booking request
# + userId - User ID creating the booking
# + return - CreateBooking record or error
function createBookingRecord(CreateBookingRequest request, string userId) returns db:CreateBooking|error {
    
    time:Civil startTime = check parseDateTime(request.startTime);
    time:Civil endTime = check parseDateTime(request.endTime);
    
    time:Date? recurringEndDate = ();
    if request.recurringEndDate is string {
        recurringEndDate = check parseDate(<string>request.recurringEndDate);
    }
    
    return {
        id: uuid:createType1AsString(),
        userId: userId,
        resourceId: request.resourceId,
        title: request.title,
        description: request.description,
        startTime: startTime,
        endTime: endTime,
        status: db:PENDING, // Default status
        purpose: request.purpose,
        attendeesCount: request.attendeesCount,
        specialRequirements: request.specialRequirements,
        approvalNeeded: false, // TODO: Determine based on resource or organization policy
        recurringPattern: request.recurringPattern,
        recurringEndDate: recurringEndDate,
        parentBookingId: null // For non-recurring bookings
    };
}

# Create update booking record from request
#
# + request - Update booking request
# + bookingId - ID of booking to update
# + return - UpdateBooking record or error
function createUpdateBookingRecord(UpdateBookingRequest request, string bookingId) returns db:UpdateBooking|error {
    
    time:Civil? startTime = ();
    time:Civil? endTime = ();
    
    if request.startTime is string {
        startTime = check parseDateTime(<string>request.startTime);
    }
    
    if request.endTime is string {
        endTime = check parseDateTime(<string>request.endTime);
    }
    
    return {
        id: bookingId,
        title: request.title,
        description: request.description,
        startTime: startTime,
        endTime: endTime,
        status: null, // Don't update status through regular update
        purpose: request.purpose,
        attendeesCount: request.attendeesCount,
        specialRequirements: request.specialRequirements,
        approvalNeeded: null,
        approvedBy: null,
        checkInTime: null,
        checkOutTime: null,
        actualAttendees: null,
        feedbackRating: null,
        feedbackComment: null
    };
}

# Check if user can access booking
#
# + booking - Booking to check access for
# + userInfo - User information
# + return - True if user can access the booking
function canAccessBooking(db:Booking booking, auth:UserInfo userInfo) returns boolean {
    // Users can access their own bookings
    if booking.userId == userInfo.userId {
        return true;
    }
    
    // Admin and staff can access all bookings
    if userInfo.role == "admin" || userInfo.role == "staff" {
        return true;
    }
    
    return false;
}

# Check if user can modify booking
#
# + booking - Booking to check modification rights for
# + userInfo - User information
# + return - True if user can modify the booking
function canModifyBooking(db:Booking booking, auth:UserInfo userInfo) returns boolean {
    // Only booking owner can modify (unless admin/staff)
    if booking.userId == userInfo.userId {
        return true;
    }
    
    // Admin can modify any booking
    if userInfo.role == "admin" {
        return true;
    }
    
    return false;
}

# Get current timestamp as string
#
# + return - Current timestamp
function getCurrentTimestamp() returns string {
    // TODO: Implement proper timestamp formatting
    return "2025-08-18T10:00:00Z";
}

# Convert booking to JSON
#
# + booking - Booking record
# + return - JSON representation
function bookingToJson(db:Booking booking) returns json {
    return {
        "id": booking.id,
        "userId": booking.userId,
        "resourceId": booking.resourceId,
        "title": booking.title,
        "description": booking.description,
        "startTime": formatDateTime(booking.startTime),
        "endTime": formatDateTime(booking.endTime),
        "status": booking.status,
        "purpose": booking.purpose,
        "attendeesCount": booking.attendeesCount,
        "specialRequirements": booking.specialRequirements,
        "approvalNeeded": booking.approvalNeeded,
        "approvedBy": booking.approvedBy,
        "approvedAt": booking.approvedAt,
        "checkInTime": booking.checkInTime,
        "checkOutTime": booking.checkOutTime,
        "actualAttendees": booking.actualAttendees,
        "feedbackRating": booking.feedbackRating,
        "feedbackComment": booking.feedbackComment,
        "recurringPattern": booking.recurringPattern,
        "recurringEndDate": booking.recurringEndDate is time:Date ? formatDate(<time:Date>booking.recurringEndDate) : null,
        "parentBookingId": booking.parentBookingId,
        "createdAt": booking.createdAt,
        "updatedAt": booking.updatedAt
    };
}

# Generate recurring bookings
#
# + parentBooking - Parent booking record
# + pattern - Recurring pattern
# + endDate - End date for recurrence
# + return - Array of recurring booking records
function generateRecurringBookings(db:CreateBooking parentBooking, string pattern, time:Date endDate) returns db:CreateBooking[]|error {
    db:CreateBooking[] recurringBookings = [];
    
    // TODO: Implement recurring booking generation logic
    // For now, return empty array
    log:printInfo("Generating recurring bookings with pattern: " + pattern);
    
    return recurringBookings;
}

# Calculate priority for waitlist entry
#
# + userInfo - User information
# + resourceId - Resource ID
# + return - Priority score (higher = more priority)
function calculateWaitlistPriority(auth:UserInfo userInfo, string resourceId) returns int {
    int priority = 100; // Base priority
    
    // Admin and staff get higher priority
    if userInfo.role == "admin" {
        priority += 50;
    } else if userInfo.role == "staff" {
        priority += 25;
    }
    
    // TODO: Add more priority calculation logic
    // - Department-based priority
    // - Booking history
    // - Special requirements
    
    return priority;
}
