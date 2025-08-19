import ballerina/sql;
import ballerina/time;

# Generate SQL query to get booking by ID
#
# + bookingId - The booking ID to search for
# + return - SQL query with parameters
public function getBookingByIdQuery(string bookingId) returns sql:ParameterizedQuery {
    return `SELECT 
        id, user_id, resource_id, title, description, start_time, end_time, 
        status, purpose, attendees_count, special_requirements, approval_needed,
        approved_by, approved_at, check_in_time, check_out_time, actual_attendees,
        feedback_rating, feedback_comment, recurring_pattern, recurring_end_date,
        parent_booking_id, created_at, updated_at
    FROM bookings 
    WHERE id = ${bookingId}`;
}

# Generate SQL query to get bookings by user ID
#
# + userId - The user ID to search for
# + filter - Optional filter parameters
# + 'limit - Maximum number of results
# + offset - Offset for pagination
# + return - SQL query with parameters
public function getBookingsByUserQuery(string userId, BookingFilter? filter = (), int 'limit = 20, int offset = 0) returns sql:ParameterizedQuery {
    sql:ParameterizedQuery baseQuery = `SELECT 
        id, user_id, resource_id, title, description, start_time, end_time, 
        status, purpose, attendees_count, special_requirements, approval_needed,
        approved_by, approved_at, check_in_time, check_out_time, actual_attendees,
        feedback_rating, feedback_comment, recurring_pattern, recurring_end_date,
        parent_booking_id, created_at, updated_at
    FROM bookings 
    WHERE user_id = ${userId}`;
    
    if filter is BookingFilter {
        if filter.status is BookingStatus {
            baseQuery = sql:queryConcat(baseQuery, ` AND status = ${filter.status}`);
        }
        if filter.startDateFrom is time:Date {
            baseQuery = sql:queryConcat(baseQuery, ` AND DATE(start_time) >= ${filter.startDateFrom}`);
        }
        if filter.startDateTo is time:Date {
            baseQuery = sql:queryConcat(baseQuery, ` AND DATE(start_time) <= ${filter.startDateTo}`);
        }
        if filter.approvalNeeded is boolean {
            baseQuery = sql:queryConcat(baseQuery, ` AND approval_needed = ${filter.approvalNeeded}`);
        }
        if filter.recurringOnly is boolean && filter.recurringOnly == true {
            baseQuery = sql:queryConcat(baseQuery, ` AND recurring_pattern IS NOT NULL`);
        }
        if filter.searchTerm is string && filter.searchTerm != "" {
            string searchPattern = "%" + <string>filter.searchTerm + "%";
            baseQuery = sql:queryConcat(baseQuery, ` AND (title LIKE ${searchPattern} OR description LIKE ${searchPattern})`);
        }
    }
    
    return sql:queryConcat(baseQuery, ` ORDER BY start_time DESC LIMIT ${'limit} OFFSET ${offset}`);
}

# Generate SQL query to get bookings by resource ID
#
# + resourceId - The resource ID to search for
# + filter - Optional filter parameters
# + 'limit - Maximum number of results
# + offset - Offset for pagination
# + return - SQL query with parameters
public function getBookingsByResourceQuery(string resourceId, BookingFilter? filter = (), int 'limit = 20, int offset = 0) returns sql:ParameterizedQuery {
    sql:ParameterizedQuery baseQuery = `SELECT 
        b.id, b.user_id, b.resource_id, b.title, b.description, b.start_time, b.end_time, 
        b.status, b.purpose, b.attendees_count, b.special_requirements, b.approval_needed,
        b.approved_by, b.approved_at, b.check_in_time, b.check_out_time, b.actual_attendees,
        b.feedback_rating, b.feedback_comment, b.recurring_pattern, b.recurring_end_date,
        b.parent_booking_id, b.created_at, b.updated_at
    FROM bookings b
    LEFT JOIN users u ON b.user_id = u.id
    WHERE resource_id = ${resourceId}`;
    
    if filter is BookingFilter {
        if filter.status is BookingStatus {
            baseQuery = sql:queryConcat(baseQuery, ` AND b.status = ${filter.status}`);
        }
        if filter.startDateFrom is time:Date {
            baseQuery = sql:queryConcat(baseQuery, ` AND DATE(b.start_time) >= ${filter.startDateFrom}`);
        }
        if filter.startDateTo is time:Date {
            baseQuery = sql:queryConcat(baseQuery, ` AND DATE(b.start_time) <= ${filter.startDateTo}`);
        }
        if filter.username is string {
            baseQuery = sql:queryConcat(baseQuery, ` AND u.email = ${filter.username}`);
        }
    }

    return sql:queryConcat(baseQuery, ` ORDER BY b.start_time ASC LIMIT ${'limit} OFFSET ${offset}`);
}

# Generate SQL query to add a new booking
#
# + booking - The booking data to insert
# + return - SQL query with parameters
public function addBookingQuery(CreateBooking booking) returns sql:ParameterizedQuery {
    return `INSERT INTO bookings (
        id, user_id, resource_id, title, description, start_time, end_time,
        status, purpose, attendees_count, special_requirements, approval_needed,
        recurring_pattern, recurring_end_date, parent_booking_id
    ) VALUES (
        ${booking.id}, ${booking.userId}, ${booking.resourceId}, ${booking.title}, 
        ${booking.description}, ${booking.startTime}, ${booking.endTime},
        ${booking.status}, ${booking.purpose}, ${booking.attendeesCount}, 
        ${booking.specialRequirements}, ${booking.approvalNeeded},
        ${booking.recurringPattern}, ${booking.recurringEndDate}, ${booking.parentBookingId}
    )`;
}

# Generate SQL query to update booking
#
# + booking - The booking data to update
# + return - SQL query with parameters
public function updateBookingQuery(UpdateBooking booking) returns sql:ParameterizedQuery {
    sql:ParameterizedQuery baseQuery = `UPDATE bookings SET updated_at = NOW()`;
    
    if booking.title is string {
        baseQuery = sql:queryConcat(baseQuery, `, title = ${booking.title}`);
    }
    if booking.description is string {
        baseQuery = sql:queryConcat(baseQuery, `, description = ${booking.description}`);
    }
    if booking.startTime is time:Civil {
        baseQuery = sql:queryConcat(baseQuery, `, start_time = ${booking.startTime}`);
    }
    if booking.endTime is time:Civil {
        baseQuery = sql:queryConcat(baseQuery, `, end_time = ${booking.endTime}`);
    }
    if booking.status is BookingStatus {
        baseQuery = sql:queryConcat(baseQuery, `, status = ${booking.status}`);
    }
    if booking.purpose is string {
        baseQuery = sql:queryConcat(baseQuery, `, purpose = ${booking.purpose}`);
    }
    if booking.attendeesCount is int {
        baseQuery = sql:queryConcat(baseQuery, `, attendees_count = ${booking.attendeesCount}`);
    }
    if booking.specialRequirements is string {
        baseQuery = sql:queryConcat(baseQuery, `, special_requirements = ${booking.specialRequirements}`);
    }
    if booking.approvalNeeded is boolean {
        baseQuery = sql:queryConcat(baseQuery, `, approval_needed = ${booking.approvalNeeded}`);
    }
    if booking.approvedBy is string {
        baseQuery = sql:queryConcat(baseQuery, `, approved_by = ${booking.approvedBy}, approved_at = NOW()`);
    }
    if booking.checkInTime is time:Civil {
        baseQuery = sql:queryConcat(baseQuery, `, check_in_time = ${booking.checkInTime}`);
    }
    if booking.checkOutTime is time:Civil {
        baseQuery = sql:queryConcat(baseQuery, `, check_out_time = ${booking.checkOutTime}`);
    }
    if booking.actualAttendees is int {
        baseQuery = sql:queryConcat(baseQuery, `, actual_attendees = ${booking.actualAttendees}`);
    }
    if booking.feedbackRating is int {
        baseQuery = sql:queryConcat(baseQuery, `, feedback_rating = ${booking.feedbackRating}`);
    }
    if booking.feedbackComment is string {
        baseQuery = sql:queryConcat(baseQuery, `, feedback_comment = ${booking.feedbackComment}`);
    }
    
    return sql:queryConcat(baseQuery, ` WHERE id = ${booking.id}`);
}

# Generate SQL query to delete booking
#
# + bookingId - The booking ID to delete
# + return - SQL query with parameters
public function deleteBookingQuery(string bookingId) returns sql:ParameterizedQuery {
    return `DELETE FROM bookings WHERE id = ${bookingId}`;
}

# Generate SQL query to check for booking conflicts
#
# + resourceId - The resource ID to check
# + startTime - Start time of the new booking
# + endTime - End time of the new booking
# + excludeBookingId - Optional booking ID to exclude from conflict check
# + return - SQL query with parameters
public function checkConflictsQuery(string resourceId, time:Civil startTime, time:Civil endTime, string? excludeBookingId = ()) returns sql:ParameterizedQuery {
    sql:ParameterizedQuery baseQuery = `SELECT 
        id, title, start_time, end_time, user_id
    FROM bookings 
    WHERE resource_id = ${resourceId} 
        AND status NOT IN ('cancelled', 'no_show', 'completed')
        AND (
            (start_time <= ${startTime} AND end_time > ${startTime}) OR
            (start_time < ${endTime} AND end_time >= ${endTime}) OR
            (start_time >= ${startTime} AND end_time <= ${endTime})
        )`;
    
    if excludeBookingId is string {
        baseQuery = sql:queryConcat(baseQuery, ` AND id != ${excludeBookingId}`);
    }
    
    return sql:queryConcat(baseQuery, ` ORDER BY start_time ASC`);
}

# Generate SQL query to get upcoming bookings
#
# + filter - Optional filter parameters
# + 'limit - Maximum number of results
# + offset - Offset for pagination
# + return - SQL query with parameters
public function getUpcomingBookingsQuery(BookingFilter? filter = (), int 'limit = 20, int offset = 0) returns sql:ParameterizedQuery {
    sql:ParameterizedQuery baseQuery = `SELECT 
        b.id, u.email as user_email, b.resource_id, b.title, b.description, b.start_time, b.end_time, 
        b.status, b.purpose, b.attendees_count, b.special_requirements, b.approval_needed,
        b.approved_by, b.approved_at, b.check_in_time, b.check_out_time, b.actual_attendees,
        b.feedback_rating, b.feedback_comment, b.recurring_pattern, b.recurring_end_date,
        b.parent_booking_id, b.created_at, b.updated_at
    FROM bookings b
    LEFT JOIN users u ON b.user_id = u.id
    WHERE b.start_time > NOW()`;

    if filter is BookingFilter {
        if filter.username is string {
            baseQuery = sql:queryConcat(baseQuery, ` AND u.email = ${filter.username}`);
        }
        if filter.resourceId is string {
            baseQuery = sql:queryConcat(baseQuery, ` AND b.resource_id = ${filter.resourceId}`);
        }
        if filter.status is BookingStatus {
            baseQuery = sql:queryConcat(baseQuery, ` AND b.status = ${filter.status}`);
        }
        if filter.approvalNeeded is boolean {
            baseQuery = sql:queryConcat(baseQuery, ` AND b.approval_needed = ${filter.approvalNeeded}`);
        }
    }

    return sql:queryConcat(baseQuery, ` ORDER BY b.start_time ASC LIMIT ${'limit} OFFSET ${offset}`);
}

# Generate SQL query to get booking count
#
# + filter - Optional filter parameters
# + return - SQL query with parameters
public function getBookingCountQuery(BookingFilter? filter = ()) returns sql:ParameterizedQuery {
    sql:ParameterizedQuery baseQuery = `SELECT COUNT(*) as count FROM bookings b LEFT JOIN users u ON b.user_id = u.id WHERE 1=1`;

    if filter is BookingFilter {
        if filter.username is string {
            baseQuery = sql:queryConcat(baseQuery, ` AND u.email = ${filter.username}`);
        }
        if filter.resourceId is string {
            baseQuery = sql:queryConcat(baseQuery, ` AND b.resource_id = ${filter.resourceId}`);
        }
        if filter.status is BookingStatus {
            baseQuery = sql:queryConcat(baseQuery, ` AND b.status = ${filter.status}`);
        }
        if filter.startDateFrom is time:Date {
            baseQuery = sql:queryConcat(baseQuery, ` AND DATE(b.start_time) >= ${filter.startDateFrom}`);
        }
        if filter.startDateTo is time:Date {
            baseQuery = sql:queryConcat(baseQuery, ` AND DATE(b.start_time) <= ${filter.startDateTo}`);
        }
        if filter.approvalNeeded is boolean {
            baseQuery = sql:queryConcat(baseQuery, ` AND b.approval_needed = ${filter.approvalNeeded}`);
        }
        if filter.recurringOnly is boolean && filter.recurringOnly == true {
            baseQuery = sql:queryConcat(baseQuery, ` AND b.recurring_pattern IS NOT NULL`);
        }
        if filter.searchTerm is string && filter.searchTerm != "" {
            string searchPattern = "%" + <string>filter.searchTerm + "%";
            baseQuery = sql:queryConcat(baseQuery, ` AND (b.title LIKE ${searchPattern} OR b.description LIKE ${searchPattern})`);
        }
    }
    
    return baseQuery;
}

# Generate SQL query to get resource availability
#
# + resourceId - The resource ID to check
# + startDate - Start date for availability check
# + endDate - End date for availability check
# + return - SQL query with parameters
public function getResourceAvailabilityQuery(string resourceId, time:Date startDate, time:Date endDate) returns sql:ParameterizedQuery {
    return `SELECT 
        start_time, end_time, title, status
    FROM bookings 
    WHERE resource_id = ${resourceId}
        AND status NOT IN ('cancelled', 'no_show')
        AND DATE(start_time) >= ${startDate}
        AND DATE(end_time) <= ${endDate}
    ORDER BY start_time ASC`;
}

# Generate SQL query to add waitlist entry
#
# + entry - Waitlist entry data
# + return - SQL query with parameters
public function addWaitlistEntryQuery(WaitlistEntry entry) returns sql:ParameterizedQuery {
    return `INSERT INTO waitlist (
        id, user_id, resource_id, desired_start_time, desired_end_time, 
        priority, status, created_at
    ) VALUES (
        ${entry.id}, ${entry.userId}, ${entry.resourceId}, 
        ${entry.desiredStartTime}, ${entry.desiredEndTime},
        ${entry.priority}, ${entry.status}, ${entry.createdAt}
    )`;
}

# Generate SQL query to get waitlist entries for a resource
#
# + resourceId - The resource ID
# + return - SQL query with parameters
public function getWaitlistEntriesQuery(string resourceId) returns sql:ParameterizedQuery {
    return `SELECT 
        id, user_id, resource_id, desired_start_time, desired_end_time,
        priority, status, created_at, notified_at, expires_at
    FROM waitlist 
    WHERE resource_id = ${resourceId} AND status = 'waiting'
    ORDER BY priority DESC, created_at ASC`;
}
