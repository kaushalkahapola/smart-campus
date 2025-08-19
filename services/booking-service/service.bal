import booking_service.auth;
import booking_service.db;

import ballerina/http;
import ballerina/log;
import ballerina/time;
import ballerina/data.jsondata;
import ballerina/uuid;


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

service http:InterceptableService / on new http:Listener(9094) {

    public function createInterceptors() returns http:Interceptor[] {
        return [new auth:AuthInterceptor(), new ErrorInterceptor()];
    }

    # ========================================
    # ADMIN BOOKING MANAGEMENT ENDPOINTS
    # ========================================

    # Admin list all bookings with filtering - Admin and Staff only
    # + status - Filter by booking status (optional)
    # + resourceId - Filter by resource ID (optional)
    # + userId - Filter by user ID (optional)
    # + startDate - Filter by start date from (optional)
    # + endDate - Filter by start date to (optional)
    # + page - Page number for pagination (optional)
    # + pageSize - Page size for pagination (optional)
    # + return - Returns list of all bookings
    resource function get admin/bookings(string? status = (),
                                         string? resourceId = (),
                                         string? userId = (),
                                         string? startDate = (),
                                         string? endDate = (),
                                         int page = 1,
                                         int pageSize = 50) 
        returns BookingListResponse|InternalServerErrorResponse {
        
        log:printInfo("Admin fetching all bookings with filters");
        
        // Build filter
        db:BookingFilter? filter = ();
        if status is string || resourceId is string || userId is string || startDate is string || endDate is string {
            db:BookingStatus? bookingStatus = ();
            if status is string {
                bookingStatus = status == "pending" ? db:PENDING : 
                               status == "confirmed" ? db:CONFIRMED :
                               status == "in_progress" ? db:IN_PROGRESS :
                               status == "completed" ? db:COMPLETED :
                               status == "cancelled" ? db:CANCELLED :
                               status == "no_show" ? db:NO_SHOW : ();
            }
            
            time:Date? startDateFilter = ();
            time:Date? endDateFilter = ();
            if startDate is string {
                time:Date|error startDateResult = parseDate(startDate);
                if startDateResult is time:Date {
                    startDateFilter = startDateResult;
                }
            }
            if endDate is string {
                time:Date|error endDateResult = parseDate(endDate);
                if endDateResult is time:Date {
                    endDateFilter = endDateResult;
                }
            }
            
            filter = {
                userId: userId,
                resourceId: resourceId,
                status: bookingStatus,
                startDateFrom: startDateFilter,
                startDateTo: endDateFilter,
                approvalNeeded: null,
                recurringOnly: null,
                searchTerm: null
            };
        }
        
        // Get all bookings from database
        db:Booking[]|error bookings = db:getUpcomingBookings(filter, page, pageSize);
        if bookings is error {
            log:printError("Error fetching admin bookings: " + bookings.message());
            return <InternalServerErrorResponse> {
                body: {
                    errorMessage: "Failed to fetch bookings",
                    details: bookings.message()
                }
            };
        }
        
        // Convert to JSON array
        json[] bookingsJson = [];
        foreach db:Booking booking in bookings {
            bookingsJson.push(bookingToJson(booking));
        }
        
        // Get total count for pagination
        int|error totalCount = db:getBookingCount(filter);
        int total = totalCount is error ? 0 : totalCount;
        
        log:printInfo("Successfully fetched " + bookings.length().toString() + " bookings for admin");
        return <BookingListResponse> {
            body: {
                message: "Admin bookings fetched successfully",
                data: {
                    bookings: bookingsJson,
                    total: total,
                    page: page,
                    pageSize: pageSize
                },
                timestamp: getCurrentTimestamp()
            }
        };
    }

    # Admin approve/reject booking - Admin only
    # + bookingId - The booking ID to approve/reject
    # + httpReq - The HTTP request
    # + action - Action to take: "approve" or "reject"
    # + return - Returns approval result
    resource function patch admin/bookings/[string bookingId]/[string action](http:Request httpReq) returns BookingUpdatedResponse|NotFoundResponse|BadRequestResponse|InternalServerErrorResponse|http:HeaderNotFoundError {

        string|error userId = getUserIdFromRequest(httpReq);
        if userId is error {
            return <NotFoundResponse> {
                body: {
                    errorMessage: "User ID not found",
                    details: userId.message()
                }
            };
        }
        string username = check httpReq.getHeader("X-Username");
        
        log:printInfo("Admin " + action + " booking: " + bookingId + " by: " + username);
        
        if action != "approve" && action != "reject" {
            return <BadRequestResponse> {
                body: {
                    errorMessage: "Invalid action",
                    details: "Action must be 'approve' or 'reject'"
                }
            };
        }
        
        // Get existing booking
        db:Booking|error existingBooking = db:getBookingById(bookingId);
        if existingBooking is error {
            log:printError("Booking not found: " + bookingId);
            return <NotFoundResponse> {
                body: {
                    errorMessage: "Booking not found",
                    details: "Booking with ID " + bookingId + " not found"
                }
            };
        }
        
        // Update booking status
        db:BookingStatus newStatus = action == "approve" ? db:CONFIRMED : db:CANCELLED;
        db:UpdateBooking updateRecord = {
            id: bookingId,
            title: null,
            description: null,
            startTime: null,
            endTime: null,
            status: newStatus,
            purpose: null,
            attendeesCount: null,
            specialRequirements: null,
            approvalNeeded: null,
            approvedBy: action == "approve" ? userId : null,
            checkInTime: null,
            checkOutTime: null,
            actualAttendees: null,
            feedbackRating: null,
            feedbackComment: null
        };
        
        int|error result = db:updateBooking(updateRecord);
        if result is error {
            log:printError("Failed to " + action + " booking: " + result.message());
            return <InternalServerErrorResponse> {
                body: {
                    errorMessage: "Failed to " + action + " booking",
                    details: result.message()
                }
            };
        }
        
        log:printInfo("Successfully " + action + "d booking: " + bookingId);
        return <BookingUpdatedResponse> {
            body: {
                message: "Booking " + action + "d successfully",
                bookingId: bookingId,
                timestamp: getCurrentTimestamp()
            }
        };
    }

    # ========================================
    # BOOKING UTILITY ENDPOINTS
    # ========================================

    # Check booking conflicts for a resource and time slot
    # + resourceId - The resource ID to check
    # + startTime - Start time to check (ISO format)
    # + endTime - End time to check (ISO format)
    # + excludeBookingId - Optional booking ID to exclude from check
    # + return - Returns conflict check result
    resource function get conflicts/[string resourceId](string startTime, string endTime, string? excludeBookingId = ()) returns ConflictCheckResponse|BadRequestResponse|InternalServerErrorResponse {
        
        log:printInfo("Checking conflicts for resource: " + resourceId);
        
        // Parse datetime strings
        time:Civil|error parsedStartTime = parseDateTime(startTime);
        time:Civil|error parsedEndTime = parseDateTime(endTime);
        
        if parsedStartTime is error || parsedEndTime is error {
            return <BadRequestResponse> {
                body: {
                    errorMessage: "Invalid datetime format",
                    details: "Start time and end time must be in ISO format"
                }
            };
        }
        
        // Check for conflicts
        db:BookingConflict[]|error conflicts = db:checkBookingConflicts(resourceId, parsedStartTime, parsedEndTime, excludeBookingId);
        if conflicts is error {
            log:printError("Error checking conflicts: " + conflicts.message());
            return <InternalServerErrorResponse> {
                body: {
                    errorMessage: "Failed to check conflicts",
                    details: conflicts.message()
                }
            };
        }
        
        // TODO: Get alternative resource suggestions (AI integration)
        db:ResourceAlternative[] alternatives = [];
        
        log:printInfo("Conflict check completed for resource: " + resourceId + ", conflicts: " + conflicts.length().toString());
        return <ConflictCheckResponse> {
            body: {
                message: "Conflict check completed",
                data: {
                    hasConflicts: conflicts.length() > 0,
                    conflicts: conflicts,
                    alternatives: alternatives
                },
                timestamp: getCurrentTimestamp()
            }
        };
    }

    # Get resource availability for a date range
    # + resourceId - The resource ID to check
    # + startDate - Start date for availability check (ISO format)
    # + endDate - End date for availability check (ISO format)
    # + return - Returns availability information
    resource function get availability/[string resourceId](string startDate, string endDate) returns AvailabilityResponse|BadRequestResponse|InternalServerErrorResponse {
        
        log:printInfo("Checking availability for resource: " + resourceId);
        
        // Parse date strings
        time:Date|error parsedStartDate = parseDate(startDate);
        time:Date|error parsedEndDate = parseDate(endDate);
        
        if parsedStartDate is error || parsedEndDate is error {
            return <BadRequestResponse> {
                body: {
                    errorMessage: "Invalid date format",
                    details: "Start date and end date must be in ISO format (YYYY-MM-DD)"
                }
            };
        }
        
        // Get booked time slots
        db:TimeSlot[]|error bookedSlots = db:getResourceAvailability(resourceId, parsedStartDate, parsedEndDate);
        if bookedSlots is error {
            log:printError("Error getting availability: " + bookedSlots.message());
            return <InternalServerErrorResponse> {
                body: {
                    errorMessage: "Failed to get availability",
                    details: bookedSlots.message()
                }
            };
        }
        
        // TODO: Calculate available slots based on resource operating hours
        db:TimeSlot[] availableSlots = [];
        
        log:printInfo("Availability check completed for resource: " + resourceId);
        return <AvailabilityResponse> {
            body: {
                message: "Availability fetched successfully",
                data: {
                    resourceId: resourceId,
                    date: startDate + " to " + endDate,
                    availableSlots: availableSlots,
                    bookedSlots: bookedSlots
                },
                timestamp: getCurrentTimestamp()
            }
        };
    }

    # ========================================
    # BOOKING MANAGEMENT ENDPOINTS
    # ========================================

    # Create a new booking
    # + req - The HTTP request with booking data
    # + return - Returns booking creation result
    resource function post bookings(CreateBookingRequest req, http:Request httpReq) returns BookingCreatedResponse|BadRequestResponse|ConflictResponse|InternalServerErrorResponse|NotFoundResponse|http:HeaderNotFoundError {
        
        string|error userId = getUserIdFromRequest(httpReq);
        if userId is error {
            return <NotFoundResponse> {
                body: {
                    errorMessage: "User ID not found",
                    details: userId.message()
                }
            };
        }
        
        // Validate booking request
        error? validationResult = validateBookingRequest(req);
        if validationResult is error {
            log:printError("Booking validation failed: " + validationResult.message());
            return <BadRequestResponse> {
                body: {
                    errorMessage: "Invalid booking data",
                    details: validationResult.message()
                }
            };
        }
        
        // Create booking record
        db:CreateBooking|error bookingRecord = createBookingRecord(req, userId);
        if bookingRecord is error {
            log:printError("Failed to create booking record: " + bookingRecord.message());
            return <BadRequestResponse> {
                body: {
                    errorMessage: "Invalid booking data",
                    details: bookingRecord.message()
                }
            };
        }
        
        // Check for conflicts
        time:Civil startTime = bookingRecord.startTime;
        time:Civil endTime = bookingRecord.endTime;
        db:BookingConflict[]|error conflicts = db:checkBookingConflicts(req.resourceId, startTime, endTime);
        if conflicts is error {
            log:printError("Error checking conflicts: " + conflicts.message());
            return <InternalServerErrorResponse> {
                body: {
                    errorMessage: "Failed to check booking conflicts",
                    details: conflicts.message()
                }
            };
        }
        
        if conflicts.length() > 0 {
            log:printWarn("Booking conflicts detected for resource: " + req.resourceId);
            return <ConflictResponse> {
                body: {
                    errorMessage: "Booking conflicts detected",
                    details: "The requested time slot conflicts with existing bookings",
                    conflicts: conflicts
                }
            };
        }
        
        // Create booking in database
        int|error result = db:createBooking(bookingRecord);
        if result is error {
            log:printError("Failed to create booking: " + result.message());
            return <InternalServerErrorResponse> {
                body: {
                    errorMessage: "Failed to create booking",
                    details: result.message()
                }
            };
        }

        // Publish booking created event (mock Kafka implementation)
        json eventData = {
            "id": bookingRecord.id,
            "userId": bookingRecord.userId,
            "resourceId": bookingRecord.resourceId,
            "title": bookingRecord.title,
            "status": bookingRecord.status,
            "startTime": formatDateTime(startTime),
            "endTime": formatDateTime(endTime)
        };
        error? eventResult = publishBookingEvent("booking.created", bookingRecord.id, userId, req.resourceId, eventData);
        if eventResult is error {
            log:printWarn("Failed to publish booking event: " + eventResult.message());
        }
        
        log:printInfo("Successfully created booking: " + bookingRecord.id);
        return <BookingCreatedResponse> {
            body: {
                message: "Booking created successfully",
                bookingId: bookingRecord.id,
                resourceId: bookingRecord.resourceId,
                startTime: formatDateTime(startTime),
                endTime: formatDateTime(endTime),
                timestamp: getCurrentTimestamp()
            }
        };
    }

    # Get user's bookings
    # + req - The HTTP request
    # + status - Filter by booking status (optional)
    # + resourceId - Filter by resource ID (optional)
    # + startDate - Filter by start date from (optional)
    # + endDate - Filter by start date to (optional)
    # + page - Page number for pagination (optional)
    # + pageSize - Page size for pagination (optional)
    # + return - Returns list of user's bookings
    resource function get bookings(http:Request req,
                                   string? status = (),
                                   string? resourceId = (),
                                   string? startDate = (),
                                   string? endDate = (),
                                   int page = 1,
                                   int pageSize = 20) 
        returns BookingListResponse|InternalServerErrorResponse|http:HeaderNotFoundError|NotFoundResponse {

        string|error userId = getUserIdFromRequest(req);
        if userId is error {
            return <NotFoundResponse> {
                body: {
                    errorMessage: "User ID not found",
                    details: userId.message()
                }
            };
        }
        log:printInfo("Fetching bookings for user: " + userId);

        // Build filter
        db:BookingFilter? filter = ();
        if status is string || resourceId is string || startDate is string || endDate is string {
            db:BookingStatus? bookingStatus = ();
            if status is string {
                // TODO: Convert string to BookingStatus enum
                bookingStatus = status == "pending" ? db:PENDING : 
                               status == "confirmed" ? db:CONFIRMED :
                               status == "in_progress" ? db:IN_PROGRESS :
                               status == "completed" ? db:COMPLETED :
                               status == "cancelled" ? db:CANCELLED :
                               status == "no_show" ? db:NO_SHOW : ();
            }
            
            time:Date? startDateFilter = ();
            time:Date? endDateFilter = ();
            if startDate is string {
                time:Date|error startDateResult2 = parseDate(startDate);
                if startDateResult2 is time:Date {
                    startDateFilter = startDateResult2;
                }
            }
            if endDate is string {
                time:Date|error endDateResult2 = parseDate(endDate);
                if endDateResult2 is time:Date {
                    endDateFilter = endDateResult2;
                }
            }
            
            filter = {
                userId: userId,
                resourceId: resourceId,
                status: bookingStatus,
                startDateFrom: startDateFilter,
                startDateTo: endDateFilter,
                approvalNeeded: null,
                recurringOnly: null,
                searchTerm: null
            };
        } else {
            filter = {
                userId: userId,
                resourceId: null,
                status: null,
                startDateFrom: null,
                startDateTo: null,
                approvalNeeded: null,
                recurringOnly: null,
                searchTerm: null
            };
        }
        
        // Get bookings from database
        db:Booking[]|error bookings = db:getBookingsByUser(userId, filter, page, pageSize);
        if bookings is error {
            log:printError("Error fetching bookings: " + bookings.message());
            return <InternalServerErrorResponse> {
                body: {
                    errorMessage: "Failed to fetch bookings",
                    details: bookings.message()
                }
            };
        }
        
        // Convert to JSON array
        json[] bookingsJson = [];
        foreach db:Booking booking in bookings {
            bookingsJson.push(bookingToJson(booking));
        }
        
        // Get total count for pagination
        int|error totalCount = db:getBookingCount(filter);
        int total = totalCount is error ? 0 : totalCount;

        log:printInfo("Successfully fetched " + bookings.length().toString() + " bookings for user: " + userId);
        return <BookingListResponse> {
            body: {
                message: "Bookings fetched successfully",
                data: {
                    bookings: bookingsJson,
                    total: total,
                    page: page,
                    pageSize: pageSize
                },
                timestamp: getCurrentTimestamp()
            }
        };
    }

    # Get specific booking by ID
    # + bookingId - The booking ID to fetch
    # + httpReq - The HTTP request
    # + return - Returns booking details
    resource function get bookings/[string bookingId](http:Request httpReq) returns BookingDetailsResponse|NotFoundResponse|ForbiddenResponse|InternalServerErrorResponse|http:HeaderNotFoundError {
        string|error userId = getUserIdFromRequest(httpReq);
        if userId is error {
            return <NotFoundResponse> {
                body: {
                    errorMessage: "User ID not found",
                    details: userId.message()
                }
            };
        }
        string username = check httpReq.getHeader("X-Username");
        string groups = check httpReq.getHeader("X-User-Groups");

        string[]|error groupsList = jsondata:parseString(groups);

        if groupsList is error {
            log:printError("Error parsing user groups: " + groupsList.message());
            return <InternalServerErrorResponse> {
                body: {
                    errorMessage: "Failed to parse user groups",
                    details: groupsList.message()
                }
            };
        }

        log:printInfo("Fetching booking: " + bookingId + " for user: " + username);
        
        // Get booking from database
        db:Booking|error booking = db:getBookingById(bookingId);
        if booking is error {
            log:printError("Booking not found: " + bookingId);
            return <NotFoundResponse> {
                body: {
                    errorMessage: "Booking not found",
                    details: "Booking with ID " + bookingId + " not found"
                }
            };
        }
        
        // Check access permissions
        auth:UserInfo userInfo = {
            userId: userId,
            groups: groupsList
        };
        
        if !canAccessBooking(booking, userInfo) {
            log:printWarn("Access denied for user: " + username + " to booking: " + bookingId);
            return <ForbiddenResponse> {
                body: {
                    errorMessage: "Access denied",
                    details: "You don't have permission to access this booking"
                }
            };
        }
        
        log:printInfo("Successfully fetched booking: " + bookingId);
        return <BookingDetailsResponse> {
            body: {
                message: "Booking fetched successfully",
                data: bookingToJson(booking),
                timestamp: getCurrentTimestamp()
            }
        };
    }

    # Update an existing booking
    # + bookingId - The booking ID to update
    # + req - The update request data
    # + httpReq - The HTTP request
    # + return - Returns booking update result
    resource function patch bookings/[string bookingId](UpdateBookingRequest req, http:Request httpReq) returns BookingUpdatedResponse|NotFoundResponse|ForbiddenResponse|BadRequestResponse|ConflictResponse|InternalServerErrorResponse|http:HeaderNotFoundError {
        
        string|error userId = getUserIdFromRequest(httpReq);
        if userId is error {
            return <NotFoundResponse> {
                body: {
                    errorMessage: "User ID not found",
                    details: userId.message()
                }
            };
        }
        string username = check httpReq.getHeader("X-Username");
        string groups = check httpReq.getHeader("X-User-Groups");

        string[]|error groupsList = jsondata:parseString(groups);

        if groupsList is error {
            log:printError("Error parsing user groups: " + groupsList.message());
            return <InternalServerErrorResponse> {
                body: {
                    errorMessage: "Failed to parse user groups",
                    details: groupsList.message()
                }
            };
        }
        
        log:printInfo("Updating booking: " + bookingId + " for user: " + username);
        
        // Get existing booking
        db:Booking|error existingBooking = db:getBookingById(bookingId);
        if existingBooking is error {
            log:printError("Booking not found: " + bookingId);
            return <NotFoundResponse> {
                body: {
                    errorMessage: "Booking not found",
                    details: "Booking with ID " + bookingId + " not found"
                }
            };
        }
        
        // Check modification permissions
        auth:UserInfo userInfo = {
            userId: userId,
            groups: groupsList
        };
        
        if !canModifyBooking(existingBooking, userInfo) {
            log:printWarn("Modification denied for user: " + username + " to booking: " + bookingId);
            return <ForbiddenResponse> {
                body: {
                    errorMessage: "Access denied",
                    details: "You don't have permission to modify this booking"
                }
            };
        }
        
        // Create update record
        db:UpdateBooking|error updateRecord = createUpdateBookingRecord(req, bookingId);
        if updateRecord is error {
            log:printError("Failed to create update record: " + updateRecord.message());
            return <BadRequestResponse> {
                body: {
                    errorMessage: "Invalid update data",
                    details: updateRecord.message()
                }
            };
        }
        
        // Check for conflicts if time is being updated
        if req.startTime is string || req.endTime is string {
            time:Civil newStartTime = existingBooking.startTime;
            time:Civil newEndTime = existingBooking.endTime;
            
            if req.startTime is string {
                time:Civil|error parsedStart = parseDateTime(<string>req.startTime);
                if parsedStart is time:Civil {
                    newStartTime = parsedStart;
                }
            }
            
            if req.endTime is string {
                time:Civil|error parsedEnd = parseDateTime(<string>req.endTime);
                if parsedEnd is time:Civil {
                    newEndTime = parsedEnd;
                }
            }
            
            db:BookingConflict[]|error conflicts = db:checkBookingConflicts(existingBooking.resourceId, newStartTime, newEndTime, bookingId);
            if conflicts is error {
                log:printError("Error checking conflicts: " + conflicts.message());
                return <InternalServerErrorResponse> {
                    body: {
                        errorMessage: "Failed to check booking conflicts",
                        details: conflicts.message()
                    }
                };
            }
            
            if conflicts.length() > 0 {
                log:printWarn("Booking conflicts detected for updated time");
                return <ConflictResponse> {
                    body: {
                        errorMessage: "Booking conflicts detected",
                        details: "The updated time slot conflicts with existing bookings",
                        conflicts: conflicts
                    }
                };
            }
        }
        
        // Update booking in database
        int|error result = db:updateBooking(updateRecord);
        if result is error {
            log:printError("Failed to update booking: " + result.message());
            return <InternalServerErrorResponse> {
                body: {
                    errorMessage: "Failed to update booking",
                    details: result.message()
                }
            };
        }
        
        log:printInfo("Successfully updated booking: " + bookingId);
        return <BookingUpdatedResponse> {
            body: {
                message: "Booking updated successfully",
                bookingId: bookingId,
                timestamp: getCurrentTimestamp()
            }
        };
    }

    # Cancel/Delete a booking
    # + bookingId - The booking ID to cancel
    # + httpReq - The HTTP request
    # + return - Returns booking cancellation result
    resource function delete bookings/[string bookingId](http:Request httpReq) returns BookingDeletedResponse|NotFoundResponse|ForbiddenResponse|InternalServerErrorResponse|http:HeaderNotFoundError {

        string|error userId = getUserIdFromRequest(httpReq);
        if userId is error {
            return <NotFoundResponse> {
                body: {
                    errorMessage: "User ID not found",
                    details: userId.message()
                }
            };
        }
        string username = check httpReq.getHeader("X-Username");
        string groups = check httpReq.getHeader("X-User-Groups");

        string[]|error groupsList = jsondata:parseString(groups);

        if groupsList is error {
            log:printError("Error parsing user groups: " + groupsList.message());
            return <InternalServerErrorResponse> {
                body: {
                    errorMessage: "Failed to parse user groups",
                    details: groupsList.message()
                }
            };
        }
        
        log:printInfo("Cancelling booking: " + bookingId + " for user: " + username);
        
        // Get existing booking
        db:Booking|error existingBooking = db:getBookingById(bookingId);
        if existingBooking is error {
            log:printError("Booking not found: " + bookingId);
            return <NotFoundResponse> {
                body: {
                    errorMessage: "Booking not found",
                    details: "Booking with ID " + bookingId + " not found"
                }
            };
        }
        
        // Check modification permissions
        auth:UserInfo userInfo = {
            userId: userId,
            groups: groupsList
        };
        
        if !canModifyBooking(existingBooking, userInfo) {
            log:printWarn("Cancellation denied for user: " + username + " to booking: " + bookingId);
            return <ForbiddenResponse> {
                body: {
                    errorMessage: "Access denied",
                    details: "You don't have permission to cancel this booking"
                }
            };
        }
        
        // Update booking status to cancelled instead of deleting
        db:UpdateBooking cancelUpdate = {
            id: bookingId,
            title: null,
            description: null,
            startTime: null,
            endTime: null,
            status: db:CANCELLED,
            purpose: null,
            attendeesCount: null,
            specialRequirements: null,
            approvalNeeded: null,
            approvedBy: null,
            checkInTime: null,
            checkOutTime: null,
            actualAttendees: null,
            feedbackRating: null,
            feedbackComment: null
        };
        
        int|error result = db:updateBooking(cancelUpdate);
        if result is error {
            log:printError("Failed to cancel booking: " + result.message());
            return <InternalServerErrorResponse> {
                body: {
                    errorMessage: "Failed to cancel booking",
                    details: result.message()
                }
            };
        }
        
        log:printInfo("Successfully cancelled booking: " + bookingId);
        return <BookingDeletedResponse> {
            body: {
                message: "Booking cancelled successfully",
                bookingId: bookingId,
                timestamp: getCurrentTimestamp()
            }
        };
    }

    
    # ========================================
    # WAITLIST MANAGEMENT ENDPOINTS
    # ========================================

    # Join waitlist for a resource
    # + resourceId - The resource ID to join waitlist for
    # + req - Waitlist request data
    # + httpReq - The HTTP request
    # + return - Returns waitlist entry result
    resource function post waitlist/[string resourceId](WaitlistRequest req, http:Request httpReq) returns WaitlistResponse|BadRequestResponse|InternalServerErrorResponse|http:HeaderNotFoundError {
        
        string|error userId = getUserIdFromRequest(httpReq);
        if userId is error {
            return <BadRequestResponse> {
                body: {
                    errorMessage: "User ID not found",
                    details: userId.message()
                }
            };
        }
        
        log:printInfo("Adding user " + userId + " to waitlist for resource: " + resourceId);
        
        // Parse desired times
        time:Civil|error desiredStartTime = parseDateTime(req.desiredStartTime);
        time:Civil|error desiredEndTime = parseDateTime(req.desiredEndTime);
        
        if desiredStartTime is error || desiredEndTime is error {
            return <BadRequestResponse> {
                body: {
                    errorMessage: "Invalid datetime format",
                    details: "Desired start and end times must be in ISO format"
                }
            };
        }
        
        // Calculate priority
        string groups = check httpReq.getHeader("X-User-Groups");
        string[]|error groupsList = jsondata:parseString(groups);
        
        if groupsList is error {
            return <InternalServerErrorResponse> {
                body: {
                    errorMessage: "Failed to parse user groups",
                    details: groupsList.message()
                }
            };
        }
        
        auth:UserInfo userInfo = {
            userId: userId,
            groups: groupsList
        };
        
        int priority = calculateWaitlistPriority(userInfo, resourceId);
        
        // Create waitlist entry
        db:CreateWaitlistEntry entry = {
            id: uuid:createType1AsString(),
            userId: userId,
            resourceId: resourceId,
            preferredStart: desiredStartTime,
            preferredEnd: desiredEndTime,
            priorityScore: priority,
            status: "active",
            autoBook: true,
            flexibilityHours: 0,
            expiresAt: null
        };
        
        int|error result = db:addWaitlistEntry(entry);
        if result is error {
            log:printError("Failed to add waitlist entry: " + result.message());
            return <InternalServerErrorResponse> {
                body: {
                    errorMessage: "Failed to join waitlist",
                    details: result.message()
                }
            };
        }

        // Publish waitlist joined event
        error? eventResult = publishWaitlistEvent(
            "waitlist.joined",
            entry.id,
            userId,
            resourceId,
            {
                "priority": entry.priorityScore ?: 0,
                "preferredStart": formatDateTime(entry.preferredStart),
                "preferredEnd": formatDateTime(entry.preferredEnd),
                "autoBook": entry.autoBook ?: true
            }
        );
        if eventResult is error {
            log:printError("Failed to publish waitlist event: " + eventResult.message());
        }
        
        // Get position in waitlist
        db:WaitlistEntry[]|error waitlistEntries = db:getWaitlistEntries(resourceId);
        int position = 1; // Default position
        if waitlistEntries is db:WaitlistEntry[] {
            foreach int i in 0 ..< waitlistEntries.length() {
                if waitlistEntries[i].id == entry.id {
                    position = i + 1;
                    break;
                }
            }
        }
        
        log:printInfo("Successfully added user to waitlist, position: " + position.toString());
        return <WaitlistResponse> {
            body: {
                message: "Successfully joined waitlist",
                data: {
                    waitlistId: entry.id,
                    position: position,
                    estimatedAvailability: "Will notify when available"
                },
                timestamp: getCurrentTimestamp()
            }
        };
    }

    # Get user's waitlist entries
    # + httpReq - The HTTP request
    # + return - Returns user's waitlist entries
    resource function get waitlist(http:Request httpReq) returns BookingListResponse|InternalServerErrorResponse|http:HeaderNotFoundError {
        
        string|error userId = getUserIdFromRequest(httpReq);
        if userId is error {
            return <InternalServerErrorResponse> {
                body: {
                    errorMessage: "User ID not found",
                    details: userId.message()
                }
            };
        }
        
        log:printInfo("Fetching waitlist entries for user: " + userId);
        
        // Get user's waitlist entries
        db:WaitlistEntry[]|error waitlistEntries = db:getUserWaitlistEntries(userId);
        if waitlistEntries is error {
            return <InternalServerErrorResponse> {
                body: {
                    errorMessage: "Failed to fetch waitlist entries",
                    details: waitlistEntries.message()
                }
            };
        }
        
        // Convert to JSON array
        json[] waitlistJson = [];
        foreach db:WaitlistEntry entry in waitlistEntries {
            waitlistJson.push({
                "id": entry.id,
                "resourceId": entry.resourceId,
                "preferredStart": formatDateTime(entry.preferredStart),
                "preferredEnd": formatDateTime(entry.preferredEnd),
                "priorityScore": entry.priorityScore ?: 0,
                "status": entry.status ?: "active",
                "flexibilityHours": entry.flexibilityHours ?: 0,
                "autoBook": entry.autoBook ?: true,
                "position": 0, // TODO: Calculate actual position
                "createdAt": entry.createdAt is time:Utc ? time:utcToString(<time:Utc>entry.createdAt) : "N/A"
            });
        }
        
        return <BookingListResponse> {
            body: {
                message: "Waitlist entries fetched successfully",
                data: {
                    bookings: waitlistJson,
                    total: waitlistEntries.length(),
                    page: 1,
                    pageSize: 20
                },
                timestamp: getCurrentTimestamp()
            }
        };
    }

    # Leave waitlist
    # + waitlistId - The waitlist entry ID to remove
    # + httpReq - The HTTP request
    # + return - Returns removal result
    resource function delete waitlist/[string waitlistId](http:Request httpReq) returns BookingDeletedResponse|NotFoundResponse|ForbiddenResponse|InternalServerErrorResponse|http:HeaderNotFoundError {
        
        string|error userId = getUserIdFromRequest(httpReq);
        if userId is error {
            return <InternalServerErrorResponse> {
                body: {
                    errorMessage: "User ID not found",
                    details: userId.message()
                }
            };
        }
        
        log:printInfo("Removing waitlist entry: " + waitlistId + " for user: " + userId);
        
        int|error result = db:removeWaitlistEntry(waitlistId);
        if result is error {
            return <InternalServerErrorResponse> {
                body: {
                    errorMessage: "Failed to remove waitlist entry",
                    details: result.message()
                }
            };
        }
        
        if result == 0 {
            return <NotFoundResponse> {
                body: {
                    errorMessage: "Waitlist entry not found",
                    details: "No waitlist entry found with ID: " + waitlistId
                }
            };
        }
        
        return <BookingDeletedResponse> {
            body: {
                message: "Successfully left waitlist",
                bookingId: waitlistId,
                timestamp: getCurrentTimestamp()
            }
        };
    }

    # ========================================
    # CHECK-IN/CHECK-OUT ENDPOINTS
    # ========================================

    # Check into a booking
    # + bookingId - The booking ID to check into
    # + req - Check-in request data
    # + httpReq - The HTTP request
    # + return - Returns check-in result
    resource function post bookings/[string bookingId]/checkin(CheckInRequest req, http:Request httpReq) returns CheckInResponse|NotFoundResponse|ForbiddenResponse|BadRequestResponse|InternalServerErrorResponse|http:HeaderNotFoundError {
        
        string|error userId = getUserIdFromRequest(httpReq);
        if userId is error {
            return <InternalServerErrorResponse> {
                body: {
                    errorMessage: "User ID not found",
                    details: userId.message()
                }
            };
        }
        
        log:printInfo("Check-in for booking: " + bookingId + " by user: " + userId);
        
        // Get existing booking
        db:Booking|error existingBooking = db:getBookingById(bookingId);
        if existingBooking is error {
            return <NotFoundResponse> {
                body: {
                    errorMessage: "Booking not found",
                    details: "Booking with ID " + bookingId + " not found"
                }
            };
        }
        
        // Verify user owns the booking
        if existingBooking.userId != userId {
            return <ForbiddenResponse> {
                body: {
                    errorMessage: "Access denied",
                    details: "You can only check into your own bookings"
                }
            };
        }
        
        // Update booking with check-in time
        time:Civil checkInTime = time:utcToCivil(time:utcNow());
        db:UpdateBooking updateRecord = {
            id: bookingId,
            title: null,
            description: null,
            startTime: null,
            endTime: null,
            status: db:IN_PROGRESS,
            purpose: null,
            attendeesCount: null,
            specialRequirements: null,
            approvalNeeded: null,
            approvedBy: null,
            checkInTime: checkInTime,
            checkOutTime: null,
            actualAttendees: req.actualAttendees,
            feedbackRating: null,
            feedbackComment: null
        };
        
        int|error result = db:updateBooking(updateRecord);
        if result is error {
            return <InternalServerErrorResponse> {
                body: {
                    errorMessage: "Failed to check in",
                    details: result.message()
                }
            };
        }
        
        log:printInfo("Successfully checked into booking: " + bookingId);
        return <CheckInResponse> {
            body: {
                message: "Successfully checked in",
                bookingId: bookingId,
                checkInTime: formatDateTime(checkInTime),
                timestamp: getCurrentTimestamp()
            }
        };
    }

    # Check out of a booking
    # + bookingId - The booking ID to check out of
    # + req - Check-out request data
    # + httpReq - The HTTP request
    # + return - Returns check-out result
    resource function post bookings/[string bookingId]/checkout(CheckOutRequest req, http:Request httpReq) returns CheckOutResponse|NotFoundResponse|ForbiddenResponse|BadRequestResponse|InternalServerErrorResponse|http:HeaderNotFoundError {
        
        string|error userId = getUserIdFromRequest(httpReq);
        if userId is error {
            return <InternalServerErrorResponse> {
                body: {
                    errorMessage: "User ID not found",
                    details: userId.message()
                }
            };
        }
        
        log:printInfo("Check-out for booking: " + bookingId + " by user: " + userId);
        
        // Get existing booking
        db:Booking|error existingBooking = db:getBookingById(bookingId);
        if existingBooking is error {
            return <NotFoundResponse> {
                body: {
                    errorMessage: "Booking not found",
                    details: "Booking with ID " + bookingId + " not found"
                }
            };
        }
        
        // Verify user owns the booking
        if existingBooking.userId != userId {
            return <ForbiddenResponse> {
                body: {
                    errorMessage: "Access denied",
                    details: "You can only check out of your own bookings"
                }
            };
        }
        
        // Update booking with check-out time
        time:Civil checkOutTime = time:utcToCivil(time:utcNow());
        db:UpdateBooking updateRecord = {
            id: bookingId,
            title: null,
            description: null,
            startTime: null,
            endTime: null,
            status: db:COMPLETED,
            purpose: null,
            attendeesCount: null,
            specialRequirements: null,
            approvalNeeded: null,
            approvedBy: null,
            checkInTime: null,
            checkOutTime: checkOutTime,
            actualAttendees: req.actualAttendees,
            feedbackRating: req.feedbackRating,
            feedbackComment: req.feedbackComment
        };
        
        int|error result = db:updateBooking(updateRecord);
        if result is error {
            return <InternalServerErrorResponse> {
                body: {
                    errorMessage: "Failed to check out",
                    details: result.message()
                }
            };
        }
        
        log:printInfo("Successfully checked out of booking: " + bookingId);
        return <CheckOutResponse> {
            body: {
                message: "Successfully checked out",
                bookingId: bookingId,
                checkOutTime: formatDateTime(checkOutTime),
                timestamp: getCurrentTimestamp()
            }
        };
    }

    # ========================================
    # BULK OPERATIONS ENDPOINTS
    # ========================================

    # Admin bulk create bookings
    # + req - Bulk booking request data
    # + httpReq - The HTTP request
    # + return - Returns bulk creation result
    resource function post admin/bookings/bulk(BulkBookingRequest req, http:Request httpReq) returns BulkBookingResponse|BadRequestResponse|InternalServerErrorResponse|http:HeaderNotFoundError {
        
        string|error userId = getUserIdFromRequest(httpReq);
        if userId is error {
            return <InternalServerErrorResponse> {
                body: {
                    errorMessage: "User ID not found",
                    details: userId.message()
                }
            };
        }
        
        log:printInfo("Bulk creating " + req.bookings.length().toString() + " bookings by admin: " + userId);
        
        int successfulBookings = 0;
        record {|string resourceId; string startTime; string reason;|}[] failures = [];
        
        foreach CreateBookingRequest bookingReq in req.bookings {
            // Validate and create each booking
            error? validationResult = validateBookingRequest(bookingReq);
            if validationResult is error {
                failures.push({
                    resourceId: bookingReq.resourceId,
                    startTime: bookingReq.startTime,
                    reason: validationResult.message()
                });
                continue;
            }
            
            // Create booking record
            db:CreateBooking|error bookingRecord = createBookingRecord(bookingReq, userId);
            if bookingRecord is error {
                failures.push({
                    resourceId: bookingReq.resourceId,
                    startTime: bookingReq.startTime,
                    reason: bookingRecord.message()
                });
                continue;
            }
            
            // Create booking in database
            int|error result = db:createBooking(bookingRecord);
            if result is error {
                failures.push({
                    resourceId: bookingReq.resourceId,
                    startTime: bookingReq.startTime,
                    reason: result.message()
                });
            } else {
                successfulBookings += 1;
            }
        }
        
        log:printInfo("Bulk booking completed: " + successfulBookings.toString() + " successful, " + failures.length().toString() + " failed");
        
        return <BulkBookingResponse> {
            body: {
                message: "Bulk booking operation completed",
                data: {
                    totalRequests: req.bookings.length(),
                    successfulBookings: successfulBookings,
                    failed: failures.length(),
                    failures: failures
                },
                timestamp: getCurrentTimestamp()
            }
        };
    }

    # Health check endpoint
    # + return - Returns service health status
    resource function get health() returns HealthResponse {
        
        // TODO: Check database and external service connectivity
        boolean databaseConnected = true; // Check DB connectivity
        boolean resourceServiceConnected = true; // Check resource service
        boolean notificationServiceConnected = true; // Check notification service
        int totalBookings = 0; // Get from database
        int activeBookings = 0; // Get from database
        
        return <HealthResponse> {
            body: {
                message: "Health check successful",
                data: {
                    status: "UP",
                    'service: "booking-service",
                    'version: "1.0.0",
                    uptime_seconds: 0,
                    dependencies: {
                        databaseConnected: databaseConnected,
                        resourceServiceConnected: resourceServiceConnected,
                        notificationServiceConnected: notificationServiceConnected,
                        totalBookings: totalBookings,
                        activeBookings: activeBookings
                    }
                },
                timestamp: getCurrentTimestamp()
            }
        };
    }
}
