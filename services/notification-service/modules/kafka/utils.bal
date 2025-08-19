import ballerinax/kafka;
import ballerina/log;
import ballerina/uuid;
import ballerina/time;

# Kafka configuration
configurable string[] bootstrap_servers = ["localhost:9092"];
configurable string client_id = "notification-service";
configurable string group_id = "notification-group";
configurable string auto_offset_reset = "earliest";
configurable boolean enable_auto_commit = true;
configurable int auto_commit_interval_ms = 1000;
configurable int session_timeout_ms = 30000;
configurable int heartbeat_interval_ms = 10000;

# Topic configuration
configurable string booking_events = "booking-events";
configurable string waitlist_events = "waitlist-events";
configurable string conflict_events = "conflict-events";
configurable string notification_events = "notification-events";
configurable string user_events = "user-events";
configurable string resource_events = "resource-events";

# Callback function type for sending notifications
public type NotificationCallback isolated function(string userId, NotificationMessage notification) returns error?;

# Global callback for sending notifications
isolated NotificationCallback? notificationCallback = ();

# Kafka consumer configuration
final kafka:ConsumerConfiguration & readonly consumerConfig = {
    clientId: client_id,
    groupId: group_id,
    offsetReset: kafka:OFFSET_RESET_EARLIEST,
    autoCommit: enable_auto_commit,
    autoCommitInterval: auto_commit_interval_ms,
    sessionTimeout: session_timeout_ms,
    heartbeatInterval: heartbeat_interval_ms
};

# Kafka consumer instances
isolated kafka:Consumer? bookingConsumer = ();
isolated kafka:Consumer? waitlistConsumer = ();
isolated kafka:Consumer? conflictConsumer = ();
isolated kafka:Consumer? notificationConsumer = ();
isolated kafka:Consumer? userConsumer = ();
isolated kafka:Consumer? resourceConsumer = ();

# Set the notification callback function
#
# + callback - Callback function to send notifications
public isolated function setNotificationCallback(NotificationCallback callback) {
    lock {
        notificationCallback = callback;
    }
}

# Send notification using the callback
#
# + userId - User ID
# + notification - Notification message
# + return - Success or error
isolated function sendNotification(string userId, NotificationMessage notification) returns error? {
    lock {
        NotificationCallback? callback = notificationCallback;
        if callback is NotificationCallback {
            return callback(userId, notification);
        } else {
            log:printWarn("No notification callback set");
            return error("No notification callback set");
        }
    }
}

# Initialize Kafka consumers
#
# + return - Success or error
public isolated function initializeKafkaConsumers() returns error? {
    lock {
        // Initialize booking events consumer
        bookingConsumer = check new kafka:Consumer(bootstrap_servers, consumerConfig);
        check (<kafka:Consumer>bookingConsumer)->subscribe([booking_events]);
        log:printInfo("📥 Booking events consumer initialized");

        // Initialize waitlist events consumer  
        waitlistConsumer = check new kafka:Consumer(bootstrap_servers, consumerConfig);
        check (<kafka:Consumer>waitlistConsumer)->subscribe([waitlist_events]);
        log:printInfo("📥 Waitlist events consumer initialized");

        // Initialize conflict events consumer
        conflictConsumer = check new kafka:Consumer(bootstrap_servers, consumerConfig);
        check (<kafka:Consumer>conflictConsumer)->subscribe([conflict_events]);
        log:printInfo("📥 Conflict events consumer initialized");

        // Initialize notification events consumer
        notificationConsumer = check new kafka:Consumer(bootstrap_servers, consumerConfig);
        check (<kafka:Consumer>notificationConsumer)->subscribe([notification_events]);
        log:printInfo("📥 Notification events consumer initialized");

        // Initialize user events consumer
        userConsumer = check new kafka:Consumer(bootstrap_servers, consumerConfig);
        check (<kafka:Consumer>userConsumer)->subscribe([user_events]);
        log:printInfo("📥 User events consumer initialized");

        // Initialize resource events consumer
        resourceConsumer = check new kafka:Consumer(bootstrap_servers, consumerConfig);
        check (<kafka:Consumer>resourceConsumer)->subscribe([resource_events]);
        log:printInfo("📥 Resource events consumer initialized");
    }
}

# Start consuming booking events
#
# + return - Success or error
public isolated function startBookingEventConsumer() returns error? {
    worker BookingEventWorker {
        while true {
            lock {
                kafka:Consumer? consumer = bookingConsumer;
                if consumer is kafka:Consumer {
                    kafka:ConsumerRecord[]|error records = consumer->poll(1.0);
                    if records is kafka:ConsumerRecord[] {
                        foreach kafka:ConsumerRecord record in records {
                            error? result = processBookingEvent(record);
                            if result is error {
                                log:printError("Error processing booking event", 'error = result);
                            }
                        }
                    } else {
                        log:printError("Error polling booking events", 'error = records);
                    }
                }
            }
        }
    }
}

# Start consuming waitlist events
#
# + return - Success or error
public isolated function startWaitlistEventConsumer() returns error? {
    worker WaitlistEventWorker {
        while true {
            lock {
                kafka:Consumer? consumer = waitlistConsumer;
                if consumer is kafka:Consumer {
                    kafka:ConsumerRecord[]|error records = consumer->poll(1.0);
                    if records is kafka:ConsumerRecord[] {
                        foreach kafka:ConsumerRecord record in records {
                            error? result = processWaitlistEvent(record);
                            if result is error {
                                log:printError("Error processing waitlist event", 'error = result);
                            }
                        }
                    } else {
                        log:printError("Error polling waitlist events", 'error = records);
                    }
                }
            }
        }
    }
}

# Start consuming conflict events
#
# + return - Success or error
public isolated function startConflictEventConsumer() returns error? {
    worker ConflictEventWorker {
        while true {
            lock {
                kafka:Consumer? consumer = conflictConsumer;
                if consumer is kafka:Consumer {
                    kafka:ConsumerRecord[]|error records = consumer->poll(1.0);
                    if records is kafka:ConsumerRecord[] {
                        foreach kafka:ConsumerRecord record in records {
                            error? result = processConflictEvent(record);
                            if result is error {
                                log:printError("Error processing conflict event", 'error = result);
                            }
                        }
                    } else {
                        log:printError("Error polling conflict events", 'error = records);
                    }
                }
            }
        }
    }
}

# Start consuming notification events
#
# + return - Success or error
public isolated function startNotificationEventConsumer() returns error? {
    worker NotificationEventWorker {
        while true {
            lock {
                kafka:Consumer? consumer = notificationConsumer;
                if consumer is kafka:Consumer {
                    kafka:ConsumerRecord[]|error records = consumer->poll(1.0);
                    if records is kafka:ConsumerRecord[] {
                        foreach kafka:ConsumerRecord record in records {
                            error? result = processNotificationEvent(record);
                            if result is error {
                                log:printError("Error processing notification event", 'error = result);
                            }
                        }
                    } else {
                        log:printError("Error polling notification events", 'error = records);
                    }
                }
            }
        }
    }
}

# Start consuming user events
#
# + return - Success or error
public isolated function startUserEventConsumer() returns error? {
    worker UserEventWorker {
        while true {
            lock {
                kafka:Consumer? consumer = userConsumer;
                if consumer is kafka:Consumer {
                    kafka:ConsumerRecord[]|error records = consumer->poll(1.0);
                    if records is kafka:ConsumerRecord[] {
                        foreach kafka:ConsumerRecord record in records {
                            error? result = processUserEvent(record);
                            if result is error {
                                log:printError("Error processing user event", 'error = result);
                            }
                        }
                    } else {
                        log:printError("Error polling user events", 'error = records);
                    }
                }
            }
        }
    }
}

# Start consuming resource events
#
# + return - Success or error
public isolated function startResourceEventConsumer() returns error? {
    worker ResourceEventWorker {
        while true {
            lock {
                kafka:Consumer? consumer = resourceConsumer;
                if consumer is kafka:Consumer {
                    kafka:ConsumerRecord[]|error records = consumer->poll(1.0);
                    if records is kafka:ConsumerRecord[] {
                        foreach kafka:ConsumerRecord record in records {
                            error? result = processResourceEvent(record);
                            if result is error {
                                log:printError("Error processing resource event", 'error = result);
                            }
                        }
                    } else {
                        log:printError("Error polling resource events", 'error = records);
                    }
                }
            }
        }
    }
}

# Process booking event and trigger notifications
#
# + record - Kafka record containing booking event
# + return - Success or error
isolated function processBookingEvent(kafka:ConsumerRecord record) returns error? {
    byte[] value = record.value;
    string eventJson = check string:fromBytes(value);
    json eventData = check eventJson.fromJsonString();
    
    BookingEvent bookingEvent = check eventData.cloneWithType(BookingEvent);
    log:printInfo("🔔 Processing booking event: " + bookingEvent.eventType + " for booking: " + bookingEvent.bookingId);
    
    match bookingEvent.eventType {
        BOOKING_CREATED => {
            NotificationMessage notification = createBookingCreatedNotification(bookingEvent);
            check sendNotification(bookingEvent.userId, notification);
            log:printInfo("✅ Sent booking created notification to user: " + bookingEvent.userId);
        }
        BOOKING_UPDATED => {
            NotificationMessage notification = createBookingUpdatedNotification(bookingEvent);
            check sendNotification(bookingEvent.userId, notification);
            log:printInfo("✅ Sent booking updated notification to user: " + bookingEvent.userId);
        }
        BOOKING_CANCELLED => {
            NotificationMessage notification = createBookingCancelledNotification(bookingEvent);
            check sendNotification(bookingEvent.userId, notification);
            log:printInfo("✅ Sent booking cancelled notification to user: " + bookingEvent.userId);
        }
        BOOKING_CHECKED_IN => {
            NotificationMessage notification = createBookingCheckedInNotification(bookingEvent);
            check sendNotification(bookingEvent.userId, notification);
            log:printInfo("✅ Sent check-in notification to user: " + bookingEvent.userId);
        }
        BOOKING_CHECKED_OUT => {
            NotificationMessage notification = createBookingCheckedOutNotification(bookingEvent);
            check sendNotification(bookingEvent.userId, notification);
            log:printInfo("✅ Sent check-out notification to user: " + bookingEvent.userId);
        }
        BOOKING_NO_SHOW => {
            NotificationMessage notification = createBookingNoShowNotification(bookingEvent);
            check sendNotification(bookingEvent.userId, notification);
            log:printInfo("✅ Sent no-show notification to user: " + bookingEvent.userId);
        }
        _ => {
            log:printWarn("Unhandled booking event type: " + bookingEvent.eventType);
        }
    }
}

# Process waitlist event and trigger notifications
#
# + record - Kafka record containing waitlist event
# + return - Success or error
isolated function processWaitlistEvent(kafka:ConsumerRecord record) returns error? {
    byte[] value = record.value;
    string eventJson = check string:fromBytes(value);
    json eventData = check eventJson.fromJsonString();
    
    WaitlistEvent waitlistEvent = check eventData.cloneWithType(WaitlistEvent);
    log:printInfo("🔔 Processing waitlist event: " + waitlistEvent.eventType + " for waitlist: " + waitlistEvent.waitlistId);
    
    match waitlistEvent.eventType {
        WAITLIST_ADDED => {
            NotificationMessage notification = createWaitlistAddedNotification(waitlistEvent);
            check sendNotification(waitlistEvent.userId, notification);
            log:printInfo("✅ Sent waitlist added notification to user: " + waitlistEvent.userId);
        }
        WAITLIST_REMOVED => {
            NotificationMessage notification = createWaitlistRemovedNotification(waitlistEvent);
            check sendNotification(waitlistEvent.userId, notification);
            log:printInfo("✅ Sent waitlist removed notification to user: " + waitlistEvent.userId);
        }
        WAITLIST_PROMOTED => {
            NotificationMessage notification = createWaitlistPromotedNotification(waitlistEvent);
            check sendNotification(waitlistEvent.userId, notification);
            log:printInfo("✅ Sent waitlist promoted notification to user: " + waitlistEvent.userId);
        }
        _ => {
            log:printWarn("Unhandled waitlist event type: " + waitlistEvent.eventType);
        }
    }
}

# Process conflict event and trigger notifications
#
# + record - Kafka record containing conflict event
# + return - Success or error
isolated function processConflictEvent(kafka:ConsumerRecord record) returns error? {
    byte[] value = record.value;
    string eventJson = check string:fromBytes(value);
    json eventData = check eventJson.fromJsonString();
    
    ConflictEvent conflictEvent = check eventData.cloneWithType(ConflictEvent);
    log:printInfo("🔔 Processing conflict event: " + conflictEvent.eventType + " for resource: " + conflictEvent.resourceId);
    
    match conflictEvent.eventType {
        CONFLICT_DETECTED => {
            check sendConflictDetectedNotification(conflictEvent);
        }
        CONFLICT_RESOLVED => {
            check sendConflictResolvedNotification(conflictEvent);
        }
        _ => {
            log:printWarn("Unhandled conflict event type: " + conflictEvent.eventType);
        }
    }
}

# Process notification event and send notifications
#
# + record - Kafka record containing notification event
# + return - Success or error
isolated function processNotificationEvent(kafka:ConsumerRecord record) returns error? {
    byte[] value = record.value;
    string eventJson = check string:fromBytes(value);
    json eventData = check eventJson.fromJsonString();
    
    NotificationEvent notificationEvent = check eventData.cloneWithType(NotificationEvent);
    log:printInfo("🔔 Processing notification event: " + notificationEvent.eventType + " for user: " + notificationEvent.userId);
    
    // Extract notification data and send via appropriate channels
    json notificationData = notificationEvent.eventData;
    check sendDirectNotification(notificationEvent.userId, notificationData);
}

# Process user event and trigger relevant notifications
#
# + record - Kafka record containing user event
# + return - Success or error
isolated function processUserEvent(kafka:ConsumerRecord record) returns error? {
    byte[] value = record.value;
    string eventJson = check string:fromBytes(value);
    json eventData = check eventJson.fromJsonString();
    
    UserEvent userEvent = check eventData.cloneWithType(UserEvent);
    log:printInfo("🔔 Processing user event: " + userEvent.eventType + " for user: " + userEvent.userId);
    
    match userEvent.eventType {
        USER_CREATED => {
            NotificationMessage notification = createUserWelcomeNotification(userEvent);
            check sendNotification(userEvent.userId, notification);
            log:printInfo("✅ Sent welcome notification to user: " + userEvent.userId);
        }
        USER_UPDATED => {
            NotificationMessage notification = createUserUpdatedNotification(userEvent);
            check sendNotification(userEvent.userId, notification);
            log:printInfo("✅ Sent profile updated notification to user: " + userEvent.userId);
        }
        _ => {
            log:printInfo("User event processed: " + userEvent.eventType);
        }
    }
}

# Process resource event and trigger relevant notifications
#
# + record - Kafka record containing resource event
# + return - Success or error
isolated function processResourceEvent(kafka:ConsumerRecord record) returns error? {
    byte[] value = record.value;
    string eventJson = check string:fromBytes(value);
    json eventData = check eventJson.fromJsonString();
    
    ResourceEvent resourceEvent = check eventData.cloneWithType(ResourceEvent);
    log:printInfo("🔔 Processing resource event: " + resourceEvent.eventType + " for resource: " + resourceEvent.resourceId);
    
    match resourceEvent.eventType {
        RESOURCE_CREATED => {
            check sendResourceCreatedNotification(resourceEvent);
        }
        RESOURCE_UPDATED => {
            check sendResourceUpdatedNotification(resourceEvent);
        }
        RESOURCE_DELETED => {
            check sendResourceDeletedNotification(resourceEvent);
        }
        _ => {
            log:printInfo("Resource event processed: " + resourceEvent.eventType);
        }
    }
}

# Send booking created notification
#
# + event - Booking event
# + return - Notification message to send
public isolated function createBookingCreatedNotification(BookingEvent event) returns NotificationMessage {
    return {
        notificationId: uuid:createType1AsString(),
        userId: event.userId,
        title: "Booking Confirmed",
        message: "Your booking has been confirmed for " + event.resourceId,
        'type: WEBSOCKET,
        priority: MEDIUM,
        targetChannel: (),
        additionalData: (),
        createdAt: time:utcNow(),
        scheduledAt: (),
        isRead: false,
        actionUrl: "/bookings/" + event.bookingId,
        imageUrl: ()
    };
}

# Send booking updated notification
#
# + event - Booking event
# + return - Notification message to send
public isolated function createBookingUpdatedNotification(BookingEvent event) returns NotificationMessage {
    return {
        notificationId: uuid:createType1AsString(),
        userId: event.userId,
        title: "Booking Updated",
        message: "Your booking has been updated for " + event.resourceId,
        'type: WEBSOCKET,
        priority: MEDIUM,
        targetChannel: (),
        additionalData: (),
        createdAt: time:utcNow(),
        scheduledAt: (),
        isRead: false,
        actionUrl: "/bookings/" + event.bookingId,
        imageUrl: ()
    };
}

# Send booking cancelled notification
#
# + event - Booking event
# + return - Notification message to send
public isolated function createBookingCancelledNotification(BookingEvent event) returns NotificationMessage {
    return {
        notificationId: uuid:createType1AsString(),
        userId: event.userId,
        title: "Booking Cancelled",
        message: "Your booking has been cancelled for " + event.resourceId,
        'type: WEBSOCKET,
        priority: HIGH,
        targetChannel: (),
        additionalData: (),
        createdAt: time:utcNow(),
        scheduledAt: (),
        isRead: false,
        actionUrl: "/bookings/" + event.bookingId,
        imageUrl: ()
    };
}

# Send booking checked in notification
#
# + event - Booking event
# + return - Notification message to send
public isolated function createBookingCheckedInNotification(BookingEvent event) returns NotificationMessage {
    return {
        notificationId: uuid:createType1AsString(),
        userId: event.userId,
        title: "Checked In",
        message: "You have successfully checked in to " + event.resourceId,
        'type: WEBSOCKET,
        priority: LOW,
        targetChannel: (),
        additionalData: (),
        createdAt: time:utcNow(),
        scheduledAt: (),
        isRead: false,
        actionUrl: "/bookings/" + event.bookingId,
        imageUrl: ()
    };
}

# Send booking checked out notification
#
# + event - Booking event
# + return - Notification message to send
public isolated function createBookingCheckedOutNotification(BookingEvent event) returns NotificationMessage {
    return {
        notificationId: uuid:createType1AsString(),
        userId: event.userId,
        title: "Checked Out",
        message: "You have successfully checked out from " + event.resourceId,
        'type: WEBSOCKET,
        priority: LOW,
        targetChannel: (),
        additionalData: (),
        createdAt: time:utcNow(),
        scheduledAt: (),
        isRead: false,
        actionUrl: "/bookings/" + event.bookingId,
        imageUrl: ()
    };
}

# Send booking no-show notification
#
# + event - Booking event
# + return - Notification message to send
public isolated function createBookingNoShowNotification(BookingEvent event) returns NotificationMessage {
    return {
        notificationId: uuid:createType1AsString(),
        userId: event.userId,
        title: "Booking No-Show",
        message: "You were marked as no-show for " + event.resourceId,
        'type: WEBSOCKET,
        priority: HIGH,
        targetChannel: (),
        additionalData: (),
        createdAt: time:utcNow(),
        scheduledAt: (),
        isRead: false,
        actionUrl: "/bookings/" + event.bookingId,
        imageUrl: ()
    };
}

# Send waitlist added notification
#
# + event - Waitlist event
# + return - Notification message to send
public isolated function createWaitlistAddedNotification(WaitlistEvent event) returns NotificationMessage {
    return {
        notificationId: uuid:createType1AsString(),
        userId: event.userId,
        title: "Added to Waitlist",
        message: "You have been added to the waitlist for " + event.resourceId,
        'type: WEBSOCKET,
        priority: MEDIUM,
        targetChannel: (),
        additionalData: (),
        createdAt: time:utcNow(),
        scheduledAt: (),
        isRead: false,
        actionUrl: "/waitlist/" + event.waitlistId,
        imageUrl: ()
    };
}

# Send waitlist removed notification
#
# + event - Waitlist event
# + return - Notification message to send
public isolated function createWaitlistRemovedNotification(WaitlistEvent event) returns NotificationMessage {
    return {
        notificationId: uuid:createType1AsString(),
        userId: event.userId,
        title: "Removed from Waitlist",
        message: "You have been removed from the waitlist for " + event.resourceId,
        'type: WEBSOCKET,
        priority: MEDIUM,
        targetChannel: (),
        additionalData: (),
        createdAt: time:utcNow(),
        scheduledAt: (),
        isRead: false,
        actionUrl: (),
        imageUrl: ()
    };
}

# Send waitlist promoted notification
#
# + event - Waitlist event
# + return - Notification message to send
public isolated function createWaitlistPromotedNotification(WaitlistEvent event) returns NotificationMessage {
    return {
        notificationId: uuid:createType1AsString(),
        userId: event.userId,
        title: "Booking Available!",
        message: "Great news! A spot opened up for " + event.resourceId + ". Please confirm your booking.",
        'type: WEBSOCKET,
        priority: URGENT,
        targetChannel: (),
        additionalData: (),
        createdAt: time:utcNow(),
        scheduledAt: (),
        isRead: false,
        actionUrl: "/waitlist/" + event.waitlistId + "/confirm",
        imageUrl: ()
    };
}

# Send conflict detected notification
#
# + event - Conflict event
# + return - Success or error
isolated function sendConflictDetectedNotification(ConflictEvent event) returns error? {
    // This would typically notify administrators or affected users
    log:printInfo("⚠️ Conflict detected for resource: " + event.resourceId);
    // Implementation would depend on who needs to be notified
}

# Send conflict resolved notification
#
# + event - Conflict event
# + return - Success or error
isolated function sendConflictResolvedNotification(ConflictEvent event) returns error? {
    // This would typically notify administrators or affected users
    log:printInfo("✅ Conflict resolved for resource: " + event.resourceId);
    // Implementation would depend on who needs to be notified
}

# Send user welcome notification
#
# + event - User event
# + return - Notification message to send
public isolated function createUserWelcomeNotification(UserEvent event) returns NotificationMessage {
    return {
        notificationId: uuid:createType1AsString(),
        userId: event.userId,
        title: "Welcome to Campus Resources!",
        message: "Your account has been created successfully. Explore and book campus resources.",
        'type: WEBSOCKET,
        priority: MEDIUM,
        targetChannel: (),
        additionalData: (),
        createdAt: time:utcNow(),
        scheduledAt: (),
        isRead: false,
        actionUrl: "/dashboard",
        imageUrl: ()
    };
}

# Send user updated notification
#
# + event - User event
# + return - Notification message to send
public isolated function createUserUpdatedNotification(UserEvent event) returns NotificationMessage {
    return {
        notificationId: uuid:createType1AsString(),
        userId: event.userId,
        title: "Profile Updated",
        message: "Your profile has been updated successfully.",
        'type: WEBSOCKET,
        priority: LOW,
        targetChannel: (),
        additionalData: (),
        createdAt: time:utcNow(),
        scheduledAt: (),
        isRead: false,
        actionUrl: "/profile",
        imageUrl: ()
    };
}

# Send resource created notification (for admins)
#
# + event - Resource event
# + return - Success or error
isolated function sendResourceCreatedNotification(ResourceEvent event) returns error? {
    // Typically notify admins or interested users
    log:printInfo("📋 Resource created: " + event.resourceId);
}

# Send resource updated notification
#
# + event - Resource event
# + return - Success or error
isolated function sendResourceUpdatedNotification(ResourceEvent event) returns error? {
    // Notify users who have bookings or are on waitlist
    log:printInfo("📋 Resource updated: " + event.resourceId);
}

# Send resource deleted notification
#
# + event - Resource event
# + return - Success or error
isolated function sendResourceDeletedNotification(ResourceEvent event) returns error? {
    // Notify users with affected bookings
    log:printInfo("📋 Resource deleted: " + event.resourceId);
}

# Send direct notification
#
# + userId - User ID
# + notificationData - Notification data
# + return - Success or error
isolated function sendDirectNotification(string userId, json notificationData) returns error? {
    // Parse notification data and send via appropriate channel
    log:printInfo("📤 Sending direct notification to user: " + userId);
    // Implementation depends on the notification data structure
}

# Close all Kafka consumers
#
# + return - Success or error
public isolated function closeKafkaConsumers() returns error? {
    lock {
        if bookingConsumer is kafka:Consumer {
            check (<kafka:Consumer>bookingConsumer)->close();
            log:printInfo("Booking consumer closed");
        }
        if waitlistConsumer is kafka:Consumer {
            check (<kafka:Consumer>waitlistConsumer)->close();
            log:printInfo("Waitlist consumer closed");
        }
        if conflictConsumer is kafka:Consumer {
            check (<kafka:Consumer>conflictConsumer)->close();
            log:printInfo("Conflict consumer closed");
        }
        if notificationConsumer is kafka:Consumer {
            check (<kafka:Consumer>notificationConsumer)->close();
            log:printInfo("Notification consumer closed");
        }
        if userConsumer is kafka:Consumer {
            check (<kafka:Consumer>userConsumer)->close();
            log:printInfo("User consumer closed");
        }
        if resourceConsumer is kafka:Consumer {
            check (<kafka:Consumer>resourceConsumer)->close();
            log:printInfo("Resource consumer closed");
        }
    }
}
