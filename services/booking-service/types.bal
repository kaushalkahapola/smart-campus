import ballerina/http;
import booking_service.db;

# ========================================
# ERROR RESPONSE TYPES
# ========================================

# NotFound Response record type
public type NotFoundResponse record {|
    *http:NotFound;
    # payload 
    record {|
        string errorMessage;
        string? details;
    |} body;
|};

# BadRequest Response record type
public type BadRequestResponse record {|
    *http:BadRequest;
    # payload 
    record {|
        string errorMessage;
        string? details;
    |} body;
|};

# InternalServerError Response record type
public type InternalServerErrorResponse record {|
    *http:InternalServerError;
    # payload 
    record {|
        string errorMessage;
        string? details;
    |} body;
|};

# Conflict Response record type
public type ConflictResponse record {|
    *http:Conflict;
    # payload 
    record {|
        string errorMessage;
        string? details;
        db:BookingConflict[]? conflicts;
    |} body;
|};

# Unauthorized Response record type
public type UnauthorizedResponse record {|
    *http:Unauthorized;
    # payload 
    record {|
        string errorMessage;
    |} body;
|};

# Forbidden Response record type
public type ForbiddenResponse record {|
    *http:Forbidden;
    # payload 
    record {|
        string errorMessage;
        string? details;
    |} body;
|};

# ========================================
# REQUEST TYPES
# ========================================

# Create Booking Request
public type CreateBookingRequest record {|
    # Resource ID to book
    string resourceId;
    # Title of the booking
    string title;
    # Description of the booking
    string description?;
    # Start time of the booking
    string startTime; // ISO format datetime
    # End time of the booking
    string endTime; // ISO format datetime
    # Purpose of the booking
    string purpose?;
    # Number of attendees
    int attendeesCount;
    # Special requirements
    string specialRequirements?;
    # Recurring pattern (optional)
    string recurringPattern?;
    # Recurring end date (optional)
    string recurringEndDate?; // ISO format date
|};

# Update Booking Request
public type UpdateBookingRequest record {|
    # Title of the booking
    string title?;
    # Description of the booking
    string description?;
    # Start time of the booking
    string startTime?; # ISO format datetime
    # End time of the booking
    string endTime?; # ISO format datetime
    # Purpose of the booking
    string purpose?;
    # Number of attendees
    int attendeesCount?;
    # Special requirements
    string specialRequirements?;
|};

# Check-in Request
public type CheckInRequest record {|
    # Actual number of attendees
    int? actualAttendees;
|};

# Check-out Request
public type CheckOutRequest record {|
    # Actual number of attendees
    int? actualAttendees;
    # Feedback rating (1-5)
    int? feedbackRating;
    # Feedback comment
    string? feedbackComment;
|};

# Waitlist Request
public type WaitlistRequest record {|
    # Resource ID to wait for
    string resourceId;
    # Desired start time
    string desiredStartTime; // ISO format datetime
    # Desired end time
    string desiredEndTime; // ISO format datetime
|};

# Bulk Booking Request
public type BulkBookingRequest record {|
    # Array of booking requests
    CreateBookingRequest[] bookings;
|};

# ========================================
# SUCCESS RESPONSE TYPES
# ========================================

# Booking Created Response
public type BookingCreatedResponse record {|
    *http:Created;
    # payload 
    record {|
        string message;
        string bookingId;
        string resourceId;
        string startTime;
        string endTime;
        string timestamp;
    |} body;
|};

# Booking Updated Response
public type BookingUpdatedResponse record {|
    *http:Ok;
    # payload 
    record {|
        string message;
        string bookingId;
        string timestamp;
    |} body;
|};

# Booking Deleted Response
public type BookingDeletedResponse record {|
    *http:Ok;
    # payload 
    record {|
        string message;
        string bookingId;
        string timestamp;
    |} body;
|};

# Booking Details Response
public type BookingDetailsResponse record {|
    *http:Ok;
    # payload 
    record {|
        string message;
        json data; # Booking object
        string timestamp;
    |} body;
|};

# Booking List Response
public type BookingListResponse record {|
    *http:Ok;
    # payload 
    record {|
        string message;
        record {|
            json[] bookings;
            int total;
            int page;
            int pageSize;
        |} data;
        string timestamp;
    |} body;
|};

# Conflict Check Response
public type ConflictCheckResponse record {|
    *http:Ok;
    # payload 
    record {|
        string message;
        record {|
            boolean hasConflicts;
            db:BookingConflict[] conflicts;
            db:ResourceAlternative[]? alternatives;
        |} data;
        string timestamp;
    |} body;
|};

# Availability Response
public type AvailabilityResponse record {|
    *http:Ok;
    # payload 
    record {|
        string message;
        record {|
            string resourceId;
            string date;
            db:TimeSlot[] availableSlots;
            db:TimeSlot[] bookedSlots;
        |} data;
        string timestamp;
    |} body;
|};

# Waitlist Response
public type WaitlistResponse record {|
    *http:Ok;
    # payload 
    record {|
        string message;
        record {|
            string waitlistId;
            int position;
            string estimatedAvailability;
        |} data;
        string timestamp;
    |} body;
|};

# Bulk Booking Response
public type BulkBookingResponse record {|
    *http:Ok;
    # payload 
    record {|
        string message;
        record {|
            int totalRequests;
            int successfulBookings;
            int failed;
            record {|
                string resourceId;
                string startTime;
                string reason;
            |}[] failures;
        |} data;
        string timestamp;
    |} body;
|};

# Check-in Response
public type CheckInResponse record {|
    *http:Ok;
    # payload 
    record {|
        string message;
        string bookingId;
        string checkInTime;
        string timestamp;
    |} body;
|};

# Check-out Response
public type CheckOutResponse record {|
    *http:Ok;
    # payload 
    record {|
        string message;
        string bookingId;
        string checkOutTime;
        string timestamp;
    |} body;
|};

# Analytics Response
public type AnalyticsResponse record {|
    *http:Ok;
    # payload 
    record {|
        string message;
        record {|
            string period;
            int totalBookings;
            decimal utilizationRate;
            int uniqueUsers;
            json[] topResources;
            json[] bookingTrends;
        |} data;
        string timestamp;
    |} body;
|};

# Health Check Response
public type HealthResponse record {|
    *http:Ok;
    # payload 
    record {|
        string message;
        record {|
            string status;
            string 'service;
            string 'version;
            int uptime_seconds;
            record {|
                boolean databaseConnected;
                boolean resourceServiceConnected;
                boolean notificationServiceConnected;
                int totalBookings;
                int activeBookings;
            |} dependencies;
        |} data;
        string timestamp;
    |} body;
|};

# Success Response (Generic)
public type SuccessResponse record {|
    *http:Ok;
    # payload 
    record {|
        string message;
        json? data;
        string timestamp;
    |} body;
|};
