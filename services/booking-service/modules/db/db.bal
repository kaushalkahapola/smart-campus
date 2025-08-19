import ballerina/sql;
import ballerina/log;
import ballerina/time;

# Get booking by ID
#
# + bookingId - The booking ID to retrieve
# + return - Booking record or error
public isolated function getBookingById(string bookingId) returns Booking|error {
    sql:ParameterizedQuery query = getBookingByIdQuery(bookingId);
    
    
    Booking|sql:Error result = databaseClient->queryRow(query);
    if result is sql:NoRowsError {
        return error("Booking not found with ID: " + bookingId);
    }
    return result;
}

# Get bookings by user ID
#
# + userId - The user ID to search for
# + filter - Optional filter parameters
# + page - Page number for pagination
# + pageSize - Page size for pagination
# + return - Array of booking records or error
public isolated function getBookingsByUser(string userId, BookingFilter? filter = (), int page = 1, int pageSize = 20) returns Booking[]|error {
    int offset = (page - 1) * pageSize;
    sql:ParameterizedQuery query = getBookingsByUserQuery(userId, filter, pageSize, offset);
    
    
    stream<Booking, sql:Error?> bookingStream = databaseClient->query(query);
    return from Booking booking in bookingStream
           select booking;
}

# Get bookings by resource ID
#
# + resourceId - The resource ID to search for
# + filter - Optional filter parameters
# + page - Page number for pagination
# + pageSize - Page size for pagination
# + return - Array of booking records or error
public isolated function getBookingsByResource(string resourceId, BookingFilter? filter = (), int page = 1, int pageSize = 20) returns Booking[]|error {
    int offset = (page - 1) * pageSize;
    sql:ParameterizedQuery query = getBookingsByResourceQuery(resourceId, filter, pageSize, offset);
    
    
    stream<Booking, sql:Error?> bookingStream = databaseClient->query(query);
    return from Booking booking in bookingStream
           select booking;
}

# Create a new booking
#
# + booking - The booking data to create
# + return - Number of affected rows or error
public isolated function createBooking(CreateBooking booking) returns int|error {
    sql:ParameterizedQuery query = addBookingQuery(booking);
    
    
    sql:ExecutionResult|sql:Error result = databaseClient->execute(query);
    if result is sql:Error {
        log:printError("Error creating booking: " + result.message());
        return result;
    }
    
    return result.affectedRowCount ?: 0;
}

# Update an existing booking
#
# + booking - The booking data to update
# + return - Number of affected rows or error
public isolated function updateBooking(UpdateBooking booking) returns int|error {
    sql:ParameterizedQuery query = updateBookingQuery(booking);
    
    
    sql:ExecutionResult|sql:Error result = databaseClient->execute(query);
    if result is sql:Error {
        log:printError("Error updating booking: " + result.message());
        return result;
    }
    
    return result.affectedRowCount ?: 0;
}

# Delete a booking
#
# + bookingId - The booking ID to delete
# + return - Number of affected rows or error
public isolated function deleteBooking(string bookingId) returns int|error {
    sql:ParameterizedQuery query = deleteBookingQuery(bookingId);
    
    
    sql:ExecutionResult|sql:Error result = databaseClient->execute(query);
    if result is sql:Error {
        log:printError("Error deleting booking: " + result.message());
        return result;
    }
    
    return result.affectedRowCount ?: 0;
}

# Check for booking conflicts
#
# + resourceId - The resource ID to check
# + startTime - Start time of the new booking
# + endTime - End time of the new booking
# + excludeBookingId - Optional booking ID to exclude from conflict check
# + return - Array of conflicting bookings or error
public isolated function checkBookingConflicts(string resourceId, time:Civil startTime, time:Civil endTime, string? excludeBookingId = ()) returns BookingConflict[]|error {
    sql:ParameterizedQuery query = checkConflictsQuery(resourceId, startTime, endTime, excludeBookingId);
    
    log:printInfo("Conflict check query for resource: " + resourceId);
    log:printInfo("Start time: " + startTime.toString());
    log:printInfo("End time: " + endTime.toString());
    
    stream<record {|string id; string title; time:Civil start_time; time:Civil end_time; string user_id;|}, sql:Error?> conflictStream = databaseClient->query(query);
    
    BookingConflict[]|error conflicts = from var conflictRow in conflictStream
           select {
               bookingId: conflictRow.id,
               title: conflictRow.title,
               startTime: conflictRow.start_time,
               endTime: conflictRow.end_time,
               userId: conflictRow.user_id
           };
    
    if conflicts is error {
        log:printError("Error querying conflicts: " + conflicts.message());
        return conflicts;
    }
    
    log:printInfo("Found " + conflicts.length().toString() + " conflicts");
    
    return conflicts;
}

# Get upcoming bookings
#
# + filter - Optional filter parameters
# + page - Page number for pagination
# + pageSize - Page size for pagination
# + return - Array of booking records or error
public isolated function getUpcomingBookings(BookingFilter? filter = (), int page = 1, int pageSize = 20) returns Booking[]|error {
    int offset = (page - 1) * pageSize;
    sql:ParameterizedQuery query = getUpcomingBookingsQuery(filter, pageSize, offset);
    
    
    stream<Booking, sql:Error?> bookingStream = databaseClient->query(query);
    return from Booking booking in bookingStream
           select booking;
}

# Get booking count with optional filters
#
# + filter - Optional filter parameters
# + return - Total count of bookings or error
public isolated function getBookingCount(BookingFilter? filter = ()) returns int|error {
    sql:ParameterizedQuery query = getBookingCountQuery(filter);
    
    
    record {|int count;|}|sql:Error result = databaseClient->queryRow(query);
    if result is sql:Error {
        return result;
    }
    
    return result.count;
}

# Get resource availability for a date range
#
# + resourceId - The resource ID to check
# + startDate - Start date for availability check
# + endDate - End date for availability check
# + return - Array of time slots or error
public isolated function getResourceAvailability(string resourceId, time:Date startDate, time:Date endDate) returns TimeSlot[]|error {
    sql:ParameterizedQuery query = getResourceAvailabilityQuery(resourceId, startDate, endDate);
    
    
    stream<record {|time:Civil start_time; time:Civil end_time; string title; string status;|}, sql:Error?> bookingStream = databaseClient->query(query);
    
    return from var bookingRow in bookingStream
           select {
               startTime: bookingRow.start_time,
               endTime: bookingRow.end_time,
               available: false 
           };
}

# Add entry to waitlist
#
# + entry - Waitlist entry data
# + return - Number of affected rows or error
public isolated function addWaitlistEntry(CreateWaitlistEntry entry) returns int|error {
    sql:ParameterizedQuery query = addWaitlistEntryQuery(entry);
    
    
    sql:ExecutionResult|sql:Error result = databaseClient->execute(query);
    if result is sql:Error {
        log:printError("Error adding waitlist entry: " + result.message());
        return result;
    }
    
    return result.affectedRowCount ?: 0;
}

# Get waitlist entries for a resource
#
# + resourceId - The resource ID
# + return - Array of waitlist entries or error
public isolated function getWaitlistEntries(string resourceId) returns WaitlistEntry[]|error {
    sql:ParameterizedQuery query = getWaitlistEntriesQuery(resourceId);
    
    
    stream<WaitlistEntry, sql:Error?> waitlistStream = databaseClient->query(query);
    return from WaitlistEntry entry in waitlistStream
           select entry;
}

# Get user's waitlist entries
#
# + userId - The user ID
# + return - Array of waitlist entries or error
public isolated function getUserWaitlistEntries(string userId) returns WaitlistEntry[]|error {
    sql:ParameterizedQuery query = getUserWaitlistEntriesQuery(userId);
    
    
    stream<WaitlistEntry, sql:Error?> waitlistStream = databaseClient->query(query);
    return from WaitlistEntry entry in waitlistStream
           select entry;
}

# Remove waitlist entry
#
# + waitlistId - The waitlist entry ID to remove
# + return - Number of affected rows or error
public isolated function removeWaitlistEntry(string waitlistId) returns int|error {
    sql:ParameterizedQuery query = removeWaitlistEntryQuery(waitlistId);
    
    
    sql:ExecutionResult|sql:Error result = databaseClient->execute(query);
    if result is sql:Error {
        log:printError("Error removing waitlist entry: " + result.message());
        return result;
    }
    
    return result.affectedRowCount ?: 0;
}

# Update waitlist entry status
#
# + waitlistId - The waitlist entry ID to update
# + status - New status
# + fulfilledBookingId - Booking ID if fulfilled
# + return - Number of affected rows or error
public isolated function updateWaitlistEntry(string waitlistId, string status, string? fulfilledBookingId = ()) returns int|error {
    sql:ParameterizedQuery query = updateWaitlistEntryQuery(waitlistId, status, fulfilledBookingId);
    
    
    sql:ExecutionResult|sql:Error result = databaseClient->execute(query);
    if result is sql:Error {
        log:printError("Error updating waitlist entry: " + result.message());
        return result;
    }
    
    return result.affectedRowCount ?: 0;
}

# Mark waitlist entry as notified
#
# + waitlistId - The waitlist entry ID to mark as notified
# + return - Number of affected rows or error
public isolated function markWaitlistNotified(string waitlistId) returns int|error {
    sql:ParameterizedQuery query = markWaitlistNotifiedQuery(waitlistId);
    
    
    sql:ExecutionResult|sql:Error result = databaseClient->execute(query);
    if result is sql:Error {
        log:printError("Error marking waitlist as notified: " + result.message());
        return result;
    }
    
    return result.affectedRowCount ?: 0;
}