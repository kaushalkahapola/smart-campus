import ballerinax/kafka;
import ballerina/log;
import ballerina/uuid;
import ballerina/time;

# Email notification callback function type
public type EmailCallback isolated function(EmailNotificationMessage emailMessage) returns error?;

# Email callback holder
isolated EmailCallback? emailCallback = ();

# Kafka configuration
configurable string[] bootstrap_servers = ["localhost:9092"];
configurable string client_id = "notification-service";
configurable string group_id = "notification-group";
configurable string auto_offset_reset = "earliest";
configurable boolean enable_auto_commit = true;
configurable decimal auto_commit_interval_ms = 1000;
configurable decimal session_timeout_ms = 30000;
configurable int heartbeat_interval_ms = 10000;

# Topic configuration
configurable string booking_events = "booking-events";
configurable string waitlist_events = "waitlist-events";
configurable string user_events = "user-events";
configurable string resource_events = "resource-events";
configurable string email_events = "email-events";

# Kafka consumer configuration
final kafka:ConsumerConfiguration & readonly consumerConfig = {
    clientId: client_id,
    groupId: group_id,
    offsetReset: kafka:OFFSET_RESET_EARLIEST,
    autoCommit: enable_auto_commit,
    autoCommitInterval: auto_commit_interval_ms,
    sessionTimeout: session_timeout_ms
};


listener kafka:Listener bookingListener = new (bootstrap_servers, consumerConfig);
listener kafka:Listener waitlistListener = new (bootstrap_servers, consumerConfig);
listener kafka:Listener userListener = new (bootstrap_servers, consumerConfig);
listener kafka:Listener resourceListener = new (bootstrap_servers, consumerConfig);

# Kafka producer for email events
isolated kafka:Producer? emailProducer = ();

# Set the email callback function
#
# + callback - field description
public isolated function setEmailCallback(EmailCallback callback) {
    lock {
        emailCallback = callback;
    }
}

# Send email using the callback
#
# + emailMessage - field description
# + return - field description
isolated function sendEmail(EmailNotificationMessage emailMessage) returns error? {
    lock {
        EmailCallback? callback = emailCallback;
        if callback is EmailCallback {
            return callback(emailMessage.clone());
        } else {
            log:printWarn("No email callback set");
            return error("No email callback set");
        }
    }
}

# Initialize Kafka listeners and producer
#
# + return - field description
public isolated function initializeKafka() returns error? {
    // Email events producer
    kafka:ProducerConfiguration producerConfig = {
        clientId: "email-producer",
        acks: "all",
        retryCount: 3
    };
    lock {
	    emailProducer = check new kafka:Producer(bootstrap_servers, producerConfig.clone());
    }
    log:printInfo("📤 Email events producer initialized");
    return ();
}

# Publish email event
#
# + emailId - field description
# + status - field description
# + recipient - field description
# + return - field description
public isolated function publishEmailEvent(string emailId, string status, string recipient) returns error? {
    lock {
        kafka:Producer? producer = emailProducer;
        if producer is kafka:Producer {
            EmailEvent emailEvent = {
                eventId: uuid:createType1AsString(),
                eventType: "email_status_update",
                timestamp: time:utcNow().toString(),
                eventData: {
                    "emailId": emailId,
                    "recipient": recipient,
                    "status": status
                },
                metadata: {
                    'service: "notification-service",
                    'version: "1.0.0",
                    environment: "dev"
                },
                emailId: emailId,
                recipient: recipient,
                templateType: SYSTEM_ANNOUNCEMENT,
                priority: MEDIUM,
                status: status
            };
            
            check producer->send({
                topic: email_events,
                value: emailEvent.toJson()
            });
            
            log:printInfo("📨 Published email event: " + emailId + " -> " + status);
        } else {
            return error("Email producer not initialized");
        }
    }
    return ();
}

# Kafka service for booking events
service /booking_events on bookingListener {
    remote function onConsumerRecord(kafka:BytesConsumerRecord[] records) returns error? {
        foreach kafka:BytesConsumerRecord r in records {
            error? result = processBookingEvent(r);
            if result is error {
                log:printError("Error processing booking event", 'error = result);
            }
        }
        return ();
    }
}

# Kafka service for waitlist events
service /waitlist_events on waitlistListener {
    remote function onConsumerRecord(kafka:BytesConsumerRecord[] records) returns error? {
        foreach kafka:BytesConsumerRecord r in records {
            error? result = processWaitlistEvent(r);
            if result is error {
                log:printError("Error processing waitlist event", 'error = result);
            }
        }
        return ();
    }
}

# Kafka service for user events
service /user_events on userListener {
    remote function onConsumerRecord(kafka:BytesConsumerRecord[] records) returns error? {
        foreach kafka:BytesConsumerRecord r in records {
            error? result = processUserEvent(r);
            if result is error {
                log:printError("Error processing user event", 'error = result);
            }
        }
        return ();
    }
}

# Kafka service for resource events
service /resource_events on resourceListener {
    remote function onConsumerRecord(kafka:BytesConsumerRecord[] records) returns error? {
        foreach kafka:BytesConsumerRecord r in records {
            error? result = processResourceEvent(r);
            if result is error {
                log:printError("Error processing resource event", 'error = result);
            }
        }
        return ();
    }
}

# Process booking event and trigger email notifications
#
# + rec - field description
# + return - field description
function processBookingEvent(kafka:BytesConsumerRecord rec) returns error? {
    byte[] value = rec.value;
    string eventJson = check string:fromBytes(value);
    json eventData = check eventJson.fromJsonString();
    BookingEvent bookingEvent = check eventData.cloneWithType(BookingEvent);
    log:printInfo("🔔 Processing booking event: " + bookingEvent.eventType + " for booking: " + bookingEvent.bookingId);
    EmailNotificationMessage emailMessage;
    match bookingEvent.eventType {
        BOOKING_CREATED => {
            emailMessage = createBookingCreatedEmail(bookingEvent);
            check sendEmail(emailMessage);
            log:printInfo("✅ Sent booking created email to: " + bookingEvent.userEmail);
        }
        BOOKING_UPDATED => {
            emailMessage = createBookingUpdatedEmail(bookingEvent);
            check sendEmail(emailMessage);
            log:printInfo("✅ Sent booking updated email to: " + bookingEvent.userEmail);
        }
        BOOKING_CANCELLED => {
            emailMessage = createBookingCancelledEmail(bookingEvent);
            check sendEmail(emailMessage);
            log:printInfo("✅ Sent booking cancelled email to: " + bookingEvent.userEmail);
        }
        BOOKING_CHECKED_IN => {
            emailMessage = createBookingCheckedInEmail(bookingEvent);
            check sendEmail(emailMessage);
            log:printInfo("✅ Sent check-in email to: " + bookingEvent.userEmail);
        }
        BOOKING_CHECKED_OUT => {
            emailMessage = createBookingCheckedOutEmail(bookingEvent);
            check sendEmail(emailMessage);
            log:printInfo("✅ Sent check-out email to: " + bookingEvent.userEmail);
        }
        BOOKING_NO_SHOW => {
            emailMessage = createBookingNoShowEmail(bookingEvent);
            check sendEmail(emailMessage);
            log:printInfo("✅ Sent no-show email to: " + bookingEvent.userEmail);
        }
        _ => {
            log:printWarn("Unhandled booking event type: " + bookingEvent.eventType);
        }
    }
    return ();
}

# Process waitlist event and trigger email notifications
#
# + rec - field description
# + return - field description
function processWaitlistEvent(kafka:BytesConsumerRecord rec) returns error? {
    byte[] value = rec.value;
    string eventJson = check string:fromBytes(value);
    json eventData = check eventJson.fromJsonString();
    WaitlistEvent waitlistEvent = check eventData.cloneWithType(WaitlistEvent);
    log:printInfo("🔔 Processing waitlist event: " + waitlistEvent.eventType + " for waitlist: " + waitlistEvent.waitlistId);
    EmailNotificationMessage emailMessage;
    match waitlistEvent.eventType {
        WAITLIST_ADDED => {
            emailMessage = createWaitlistAddedEmail(waitlistEvent);
            check sendEmail(emailMessage);
            log:printInfo("✅ Sent waitlist added email to: " + waitlistEvent.userEmail);
        }
        WAITLIST_REMOVED => {
            emailMessage = createWaitlistRemovedEmail(waitlistEvent);
            check sendEmail(emailMessage);
            log:printInfo("✅ Sent waitlist removed email to: " + waitlistEvent.userEmail);
        }
        WAITLIST_PROMOTED => {
            emailMessage = createWaitlistPromotedEmail(waitlistEvent);
            check sendEmail(emailMessage);
            log:printInfo("✅ Sent waitlist promoted email to: " + waitlistEvent.userEmail);
        }
        _ => {
            log:printWarn("Unhandled waitlist event type: " + waitlistEvent.eventType);
        }
    }
    return ();
}

# Process user event and trigger email notifications
#
# + rec - field description
# + return - field description
function processUserEvent(kafka:BytesConsumerRecord rec) returns error? {
    byte[] value = rec.value;
    string eventJson = check string:fromBytes(value);
    json eventData = check eventJson.fromJsonString();
    UserEvent userEvent = check eventData.cloneWithType(UserEvent);
    log:printInfo("🔔 Processing user event: " + userEvent.eventType + " for user: " + userEvent.userId);
    EmailNotificationMessage emailMessage;
    match userEvent.eventType {
        USER_CREATED => {
            emailMessage = createUserWelcomeEmail(userEvent);
            check sendEmail(emailMessage);
            log:printInfo("✅ Sent welcome email to: " + userEvent.userEmail);
        }
        _ => {
            log:printInfo("User event processed: " + userEvent.eventType);
        }
    }
    return ();
}

# Process resource event and trigger email notifications
#
# + rec - field description
# + return - field description
function processResourceEvent(kafka:BytesConsumerRecord rec) returns error? {
    byte[] value = rec.value;
    string eventJson = check string:fromBytes(value);
    json eventData = check eventJson.fromJsonString();
    ResourceEvent resourceEvent = check eventData.cloneWithType(ResourceEvent);
    log:printInfo("🔔 Processing resource event: " + resourceEvent.eventType + " for resource: " + resourceEvent.resourceId);
    match resourceEvent.eventType {
        RESOURCE_CREATED => {
            check sendResourceAvailableEmail(resourceEvent);
        }
        RESOURCE_UPDATED => {
            check sendResourceMaintenanceEmail(resourceEvent);
        }
        _ => {
            log:printInfo("Resource event processed: " + resourceEvent.eventType);
        }
    }
    return ();
}

# Create booking created email
#
# + event - field description
# + return - field description
isolated function createBookingCreatedEmail(BookingEvent event) returns EmailNotificationMessage {
    return {
        notificationId: uuid:createType1AsString(),
        recipient: event.userEmail,
        subject: "Booking Confirmed - " + event.resourceName,
        body: "Your booking has been confirmed for " + event.resourceName,
        templateType: BOOKING_CONFIRMATION,
        priority: MEDIUM,
        templateData: {
            "resourceName": event.resourceName,
            "startTime": event.startTime,
            "endTime": event.endTime,
            "bookingId": event.bookingId
        },
        createdAt: time:utcNow(),
        scheduledAt: (),
        bookingId: event.bookingId,
        userId: event.userId,
        resourceId: event.resourceId
    };
}

# Create booking updated email
#
# + event - field description
# + return - field description
isolated function createBookingUpdatedEmail(BookingEvent event) returns EmailNotificationMessage {
    return {
        notificationId: uuid:createType1AsString(),
        recipient: event.userEmail,
        subject: "Booking Updated - " + event.resourceName,
        body: "Your booking has been updated for " + event.resourceName,
        templateType: BOOKING_UPDATED_TEMPLATE,
        priority: MEDIUM,
        templateData: {
            "resourceName": event.resourceName,
            "startTime": event.startTime,
            "endTime": event.endTime,
            "bookingId": event.bookingId
        },
        createdAt: time:utcNow(),
        scheduledAt: (),
        bookingId: event.bookingId,
        userId: event.userId,
        resourceId: event.resourceId
    };
}

# Create booking cancelled email
#
# + event - field description
# + return - field description
isolated function createBookingCancelledEmail(BookingEvent event) returns EmailNotificationMessage {
    return {
        notificationId: uuid:createType1AsString(),
        recipient: event.userEmail,
        subject: "Booking Cancelled - " + event.resourceName,
        body: "Your booking has been cancelled for " + event.resourceName,
        templateType: BOOKING_CANCELLED_TEMPLATE,
        priority: HIGH,
        templateData: {
            "resourceName": event.resourceName,
            "bookingId": event.bookingId
        },
        createdAt: time:utcNow(),
        scheduledAt: (),
        bookingId: event.bookingId,
        userId: event.userId,
        resourceId: event.resourceId
    };
}

# Create booking check-in email
#
# + event - field description
# + return - field description
isolated function createBookingCheckedInEmail(BookingEvent event) returns EmailNotificationMessage {
    return {
        notificationId: uuid:createType1AsString(),
        recipient: event.userEmail,
        subject: "Checked In - " + event.resourceName,
        body: "You have successfully checked in to " + event.resourceName,
        templateType: CHECK_IN_REMINDER,
        priority: LOW,
        templateData: {
            "resourceName": event.resourceName,
            "bookingId": event.bookingId
        },
        createdAt: time:utcNow(),
        scheduledAt: (),
        bookingId: event.bookingId,
        userId: event.userId,
        resourceId: event.resourceId
    };
}

# Create booking check-out email
#
# + event - field description
# + return - field description
isolated function createBookingCheckedOutEmail(BookingEvent event) returns EmailNotificationMessage {
    return {
        notificationId: uuid:createType1AsString(),
        recipient: event.userEmail,
        subject: "Checked Out - " + event.resourceName,
        body: "You have successfully checked out from " + event.resourceName,
        templateType: CHECK_IN_REMINDER,
        priority: LOW,
        templateData: {
            "resourceName": event.resourceName,
            "bookingId": event.bookingId
        },
        createdAt: time:utcNow(),
        scheduledAt: (),
        bookingId: event.bookingId,
        userId: event.userId,
        resourceId: event.resourceId
    };
}

# Create booking no-show email
#
# + event - field description
# + return - field description
isolated function createBookingNoShowEmail(BookingEvent event) returns EmailNotificationMessage {
    return {
        notificationId: uuid:createType1AsString(),
        recipient: event.userEmail,
        subject: "Booking No-Show - " + event.resourceName,
        body: "You were marked as no-show for " + event.resourceName,
        templateType: BOOKING_REMINDER,
        priority: HIGH,
        templateData: {
            "resourceName": event.resourceName,
            "bookingId": event.bookingId
        },
        createdAt: time:utcNow(),
        scheduledAt: (),
        bookingId: event.bookingId,
        userId: event.userId,
        resourceId: event.resourceId
    };
}

# Create waitlist added email
#
# + event - field description
# + return - field description
isolated function createWaitlistAddedEmail(WaitlistEvent event) returns EmailNotificationMessage {
    return {
        notificationId: uuid:createType1AsString(),
        recipient: event.userEmail,
        subject: "Added to Waitlist - " + event.resourceName,
        body: "You have been added to the waitlist for " + event.resourceName,
        templateType: WAITLIST_NOTIFICATION,
        priority: MEDIUM,
        templateData: {
            "resourceName": event.resourceName,
            "waitlistId": event.waitlistId
        },
        createdAt: time:utcNow(),
        scheduledAt: (),
        bookingId: (),
        userId: event.userId,
        resourceId: event.resourceId
    };
}

# Create waitlist removed email
#
# + event - field description
# + return - field description
isolated function createWaitlistRemovedEmail(WaitlistEvent event) returns EmailNotificationMessage {
    return {
        notificationId: uuid:createType1AsString(),
        recipient: event.userEmail,
        subject: "Removed from Waitlist - " + event.resourceName,
        body: "You have been removed from the waitlist for " + event.resourceName,
        templateType: WAITLIST_NOTIFICATION,
        priority: MEDIUM,
        templateData: {
            "resourceName": event.resourceName,
            "waitlistId": event.waitlistId
        },
        createdAt: time:utcNow(),
        scheduledAt: (),
        bookingId: (),
        userId: event.userId,
        resourceId: event.resourceId
    };
}

# Create waitlist promoted email
#
# + event - field description
# + return - field description
isolated function createWaitlistPromotedEmail(WaitlistEvent event) returns EmailNotificationMessage {
    return {
        notificationId: uuid:createType1AsString(),
        recipient: event.userEmail,
        subject: "Booking Available! - " + event.resourceName,
        body: "Great news! A spot opened up for " + event.resourceName + ". Please confirm your booking.",
        templateType: WAITLIST_NOTIFICATION,
        priority: URGENT,
        templateData: {
            "resourceName": event.resourceName,
            "waitlistId": event.waitlistId
        },
        createdAt: time:utcNow(),
        scheduledAt: (),
        bookingId: (),
        userId: event.userId,
        resourceId: event.resourceId
    };
}

# Create user welcome email
#
# + event - field description
# + return - field description
isolated function createUserWelcomeEmail(UserEvent event) returns EmailNotificationMessage {
    return {
        notificationId: uuid:createType1AsString(),
        recipient: event.userEmail,
        subject: "Welcome to Campus Resource Management",
        body: "Welcome to our campus resource management system!",
        templateType: USER_WELCOME,
        priority: MEDIUM,
        templateData: {
            "userName": event.userName,
            "userId": event.userId
        },
        createdAt: time:utcNow(),
        scheduledAt: (),
        bookingId: (),
        userId: event.userId,
        resourceId: ()
    };
}

# Send resource maintenance email
#
# + event - The resource event containing details about the maintenance
# + return - An error if the email sending fails
isolated function sendResourceMaintenanceEmail(ResourceEvent event) returns error? {
    EmailNotificationMessage emailMessage = {
        notificationId: uuid:createType1AsString(),
        recipient: "admin@university.edu", // Default admin email since ResourceEvent doesn't have notifyEmail
        subject: "Maintenance Scheduled - " + event.resourceName,
        body: "Maintenance has been scheduled for " + event.resourceName,
        templateType: MAINTENANCE_ALERT,
        priority: HIGH,
        templateData: {
            "resourceName": event.resourceName,
            "resourceId": event.resourceId
        },
        createdAt: time:utcNow(),
        scheduledAt: (),
        bookingId: (),
        userId: (),
        resourceId: event.resourceId
    };
    
    check sendEmail(emailMessage);
    log:printInfo("✅ Sent maintenance email");
    return ();
}

# Send resource available email
#
# + event - The resource event containing details about the availability
# + return - An error if the email sending fails
isolated function sendResourceAvailableEmail(ResourceEvent event) returns error? {
    EmailNotificationMessage emailMessage = {
        notificationId: uuid:createType1AsString(),
        recipient: "admin@university.edu", // Default admin email since ResourceEvent doesn't have notifyEmail
        subject: "Resource Available - " + event.resourceName,
        body: event.resourceName + " is now available for booking.",
        templateType: SYSTEM_ANNOUNCEMENT,
        priority: MEDIUM,
        templateData: {
            "resourceName": event.resourceName,
            "resourceId": event.resourceId
        },
        createdAt: time:utcNow(),
        scheduledAt: (),
        bookingId: (),
        userId: (),
        resourceId: event.resourceId
    };
    
    check sendEmail(emailMessage);
    log:printInfo("✅ Sent resource available email");
    return ();
}
