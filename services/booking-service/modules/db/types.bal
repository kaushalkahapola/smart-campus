import ballerina/sql;
import ballerinax/mysql;
import ballerina/time;

# Database configuration
type DBConfig record {|
    # Database user configuration
    string user;
    # Database user password
    string password;
    # Database host address
    string host;
    # Database port number
    int port;
    # Database name
    string database;
|};

# ClientDBConfig record type
type ClientDBConfig record {|
    *DBConfig;
    # Optional MySQL connection options
    mysql:Options? options;
|};

# Booking status enumeration
public enum BookingStatus {
    # Booking is pending approval
    PENDING = "pending",
    # Booking is confirmed
    CONFIRMED = "confirmed",
    # Booking is in progress
    IN_PROGRESS = "in_progress",
    # Booking is completed
    COMPLETED = "completed",
    # Booking is cancelled
    CANCELLED = "cancelled",
    # User didn't show up
    NO_SHOW = "no_show"
}

# Recurring pattern enumeration
public enum RecurringPattern {
    # No recurrence
    NONE = "none",
    # Daily recurrence
    DAILY = "daily",
    # Weekly recurrence
    WEEKLY = "weekly",
    # Monthly recurrence
    MONTHLY = "monthly"
}

# Booking record type for database operations (matches campus_resource_db.bookings table)
public type Booking record {|
    # Unique identifier for the booking
    string id;
    # User who made the booking
    @sql:Column {
        name: "user_id"
    }
    string userId;
    # Resource being booked
    @sql:Column {
        name: "resource_id"
    }
    string resourceId;
    # Title of the booking
    string title;
    # Description of the booking
    string? description;
    # Start time of the booking
    @sql:Column {
        name: "start_time"
    }
    time:Civil startTime;
    # End time of the booking
    @sql:Column {
        name: "end_time"
    }
    time:Civil endTime;
    # Status of the booking
    BookingStatus status?;
    # Purpose of the booking
    string? purpose;
    # Number of attendees
    @sql:Column {
        name: "attendees_count"
    }
    int attendeesCount?;
    # Special requirements
    @sql:Column {
        name: "special_requirements"
    }
    string? specialRequirements;
    # Whether approval is needed
    @sql:Column {
        name: "approval_needed"
    }
    boolean approvalNeeded?;
    # Who approved the booking
    @sql:Column {
        name: "approved_by"
    }
    string? approvedBy;
    # When the booking was approved
    @sql:Column {
        name: "approved_at"
    }
    time:Utc? approvedAt;
    # Check-in time
    @sql:Column {
        name: "check_in_time"
    }
    time:Utc? checkInTime;
    # Check-out time
    @sql:Column {
        name: "check_out_time"
    }
    time:Utc? checkOutTime;
    # Actual number of attendees
    @sql:Column {
        name: "actual_attendees"
    }
    int? actualAttendees;
    # Feedback rating (1-5)
    @sql:Column {
        name: "feedback_rating"
    }
    int? feedbackRating;
    # Feedback comment
    @sql:Column {
        name: "feedback_comment"
    }
    string? feedbackComment;
    # Recurring pattern
    @sql:Column {
        name: "recurring_pattern"
    }
    string? recurringPattern;
    # Recurring end date
    @sql:Column {
        name: "recurring_end_date"
    }
    time:Date? recurringEndDate;
    # Parent booking for recurring bookings
    @sql:Column {
        name: "parent_booking_id"
    }
    string? parentBookingId;
    # Creation timestamp
    @sql:Column {
        name: "created_at"
    }
    time:Utc? createdAt;
    # Last update timestamp
    @sql:Column {
        name: "updated_at"
    }
    time:Utc? updatedAt;
|};

# CreateBooking record type for creating new bookings
public type CreateBooking record {|
    # Unique identifier for the booking
    string id;
    # User who made the booking
    string userId;
    # Resource being booked
    string resourceId;
    # Title of the booking
    string title;
    # Description of the booking
    string? description;
    # Start time of the booking
    time:Civil startTime;
    # End time of the booking
    time:Civil endTime;
    # Status of the booking
    BookingStatus status;
    # Purpose of the booking
    string? purpose;
    # Number of attendees
    int attendeesCount;
    # Special requirements
    string? specialRequirements;
    # Whether approval is needed
    boolean approvalNeeded;
    # Recurring pattern
    string? recurringPattern;
    # Recurring end date
    time:Date? recurringEndDate;
    # Parent booking for recurring bookings
    string? parentBookingId;
|};

# UpdateBooking record type for updating booking information
public type UpdateBooking record {|
    # Unique identifier for the booking
    string id;
    # Title of the booking
    string? title;
    # Description of the booking
    string? description;
    # Start time of the booking
    time:Civil? startTime;
    # End time of the booking
    time:Civil? endTime;
    # Status of the booking
    BookingStatus? status;
    # Purpose of the booking
    string? purpose;
    # Number of attendees
    int? attendeesCount;
    # Special requirements
    string? specialRequirements;
    # Whether approval is needed
    boolean? approvalNeeded;
    # Who approved the booking
    string? approvedBy;
    # Check-in time
    time:Civil? checkInTime;
    # Check-out time
    time:Civil? checkOutTime;
    # Actual number of attendees
    int? actualAttendees;
    # Feedback rating (1-5)
    int? feedbackRating;
    # Feedback comment
    string? feedbackComment;
|};

# Booking filter for database queries
public type BookingFilter record {|
    # Filter by user ID
    string? username;
    # Filter by resource ID
    string? resourceId;
    # Filter by status
    BookingStatus? status;
    # Filter by start date (from)
    time:Date? startDateFrom;
    # Filter by start date (to)
    time:Date? startDateTo;
    # Filter by approval needed
    boolean? approvalNeeded;
    # Filter by recurring bookings only
    boolean? recurringOnly;
    # Search term for title/description
    string? searchTerm;
|};

# Booking conflict information
public type BookingConflict record {|
    # Conflicting booking ID
    string bookingId;
    # Conflicting booking title
    string title;
    # Start time of conflict
    time:Civil startTime;
    # End time of conflict
    time:Civil endTime;
    # User who made the conflicting booking
    string userId;
|};

# Alternative resource suggestion
public type ResourceAlternative record {|
    # Alternative resource ID
    string resourceId;
    # Resource name
    string resourceName;
    # Resource type
    string resourceType;
    # Available time slots
    TimeSlot[] availableSlots;
    # Similarity score (0-100)
    decimal similarityScore;
|};

# Time slot information
public type TimeSlot record {|
    # Start time of slot
    time:Civil startTime;
    # End time of slot
    time:Civil endTime;
    # Whether this slot is available
    boolean available;
|};

# Waitlist entry record
public type WaitlistEntry record {|
    # Unique identifier for waitlist entry
    string id;
    # User ID waiting for the booking
    string userId;
    # Resource ID being waited for
    string resourceId;
    # Desired start time
    time:Civil desiredStartTime;
    # Desired end time
    time:Civil desiredEndTime;
    # Priority score (higher = more priority)
    int priority;
    # Status of waitlist entry
    string status; # waiting, notified, expired, converted
    # When the entry was created
    time:Utc createdAt;
    # When user was notified
    time:Utc? notifiedAt;
    # Expiry time for the notification
    time:Utc? expiresAt;
|};
