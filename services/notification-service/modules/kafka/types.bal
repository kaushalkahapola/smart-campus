import ballerina/time;

# Event types for campus resource management
public enum EventType {
    BOOKING_CREATED = "booking.created",
    BOOKING_UPDATED = "booking.updated", 
    BOOKING_CANCELLED = "booking.cancelled",
    BOOKING_CHECKED_IN = "booking.checked_in",
    BOOKING_CHECKED_OUT = "booking.checked_out",
    BOOKING_NO_SHOW = "booking.no_show",
    WAITLIST_ADDED = "waitlist.added",
    WAITLIST_REMOVED = "waitlist.removed",
    WAITLIST_PROMOTED = "waitlist.promoted",
    CONFLICT_DETECTED = "conflict.detected",
    CONFLICT_RESOLVED = "conflict.resolved",
    USER_CREATED = "user.created",
    RESOURCE_CREATED = "resource.created",
    RESOURCE_UPDATED = "resource.updated",
    RESOURCE_DELETED = "resource.deleted",
    EMAIL_SEND = "email.send",
    EMAIL_SENT = "email.sent",
    EMAIL_FAILED = "email.failed"
}

# Email template types for notifications
public enum NotificationTemplateType {
    BOOKING_CONFIRMATION = "booking_confirmation",
    BOOKING_REMINDER = "booking_reminder",
    BOOKING_CANCELLED_TEMPLATE = "booking_cancelled",
    BOOKING_UPDATED_TEMPLATE = "booking_updated",
    WAITLIST_NOTIFICATION = "waitlist_notification",
    CHECK_IN_REMINDER = "check_in_reminder",
    MAINTENANCE_ALERT = "maintenance_alert",
    SYSTEM_ANNOUNCEMENT = "system_announcement",
    USER_WELCOME = "user_welcome",
    PASSWORD_RESET = "password_reset"
}

# Email priority levels
public enum EmailPriority {
    LOW = "low",
    MEDIUM = "medium",
    HIGH = "high",
    URGENT = "urgent"
}
    
# Description.
#
# + eventId - field description  
# + eventType - field description  
# + timestamp - field description  
# + eventData - field description  
# + metadata - field description
public type BaseEvent record {|
    string eventId;
    string eventType;
    string timestamp;
    json eventData;
    EventMetadata metadata;
|};


# Description.
#
# + 'service - field description  
# + 'version - field description  
# + environment - field description
public type EventMetadata record {|
    string 'service;
    string 'version;
    string environment;
|};


# Description.
#
# + bookingId - field description  
# + userId - field description  
# + resourceId - field description  
# + userEmail - field description  
# + userName - field description  
# + resourceName - field description  
# + startTime - field description  
# + endTime - field description  
# + location - field description
public type BookingEvent record {|
    *BaseEvent;
    string bookingId;
    string userId;
    string resourceId;
    string userEmail;
    string userName;
    string resourceName;
    string startTime;
    string endTime;
    string location;
|};


# Description.
#
# + waitlistId - field description  
# + userId - field description  
# + resourceId - field description  
# + userEmail - field description  
# + userName - field description  
# + resourceName - field description  
# + position - field description
public type WaitlistEvent record {|
    *BaseEvent;
    string waitlistId;
    string userId;
    string resourceId;
    string userEmail;
    string userName;
    string resourceName;
    int position;
|};


# Description.
#
# + userId - field description  
# + userEmail - field description  
# + userName - field description  
# + role - field description  
# + department - field description
public type UserEvent record {|
    *BaseEvent;
    string userId;
    string userEmail;
    string userName;
    string role;
    string department;
|};


# Description.
#
# + resourceId - field description  
# + resourceName - field description  
# + resourceType - field description  
# + location - field description  
# + status - field description
public type ResourceEvent record {|
    *BaseEvent;
    string resourceId;
    string resourceName;
    string resourceType;
    string location;
    string status;
|};


# Description.
#
# + emailId - field description  
# + recipient - field description  
# + templateType - field description  
# + priority - field description  
# + status - field description
public type EmailEvent record {|
    *BaseEvent;
    string emailId;
    string recipient;
    NotificationTemplateType templateType;
    EmailPriority priority;
    string status;
|};


# Description.
#
# + notificationId - field description  
# + recipient - field description  
# + subject - field description  
# + body - field description  
# + templateType - field description  
# + priority - field description  
# + templateData - field description  
# + createdAt - field description  
# + scheduledAt - field description  
# + bookingId - field description  
# + userId - field description  
# + resourceId - field description
public type EmailNotificationMessage record {|
    string notificationId;
    string recipient;
    string subject;
    string body;
    NotificationTemplateType templateType;
    EmailPriority priority;
    json? templateData;
    time:Utc createdAt;
    time:Utc? scheduledAt;
    string? bookingId;
    string? userId;
    string? resourceId;
|};


# Description.
#
# + bootstrapServers - field description  
# + clientId - field description  
# + groupId - field description  
# + autoOffsetReset - field description  
# + enableAutoCommit - field description  
# + autoCommitIntervalMs - field description  
# + sessionTimeoutMs - field description  
# + heartbeatIntervalMs - field description
public type KafkaConsumerConfig record {|
    string[] bootstrapServers;
    string clientId;
    string groupId;
    string autoOffsetReset;
    boolean enableAutoCommit;
    int autoCommitIntervalMs;
    int sessionTimeoutMs;
    int heartbeatIntervalMs;
|};


# Description.
#
# + bookingEvents - field description  
# + waitlistEvents - field description  
# + userEvents - field description  
# + resourceEvents - field description  
# + emailEvents - field description
public type TopicConfig record {|
    string bookingEvents;
    string waitlistEvents;
    string userEvents;
    string resourceEvents;
    string emailEvents;
|};


# Description.
#
# + emailId - field description  
# + recipient - field description  
# + status - field description  
# + errorMessage - field description  
# + timestamp - field description  
# + retryCount - field description
public type EmailDeliveryStatus record {|
    string emailId;
    string recipient;
    string status;
    string? errorMessage;
    time:Utc timestamp;
    int retryCount;
|};

# Kafka consumer group offset tracking
#
# + topic - field description  
# + partition - field description  
# + offset - field description  
# + lastCommitted - field description
public type ConsumerOffset record {|
    string topic;
    int partition;
    int offset;
    time:Utc lastCommitted;
|};
