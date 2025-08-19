import ballerina/time;

# Event types
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
    USER_UPDATED = "user.updated",
    USER_DELETED = "user.deleted",
    RESOURCE_CREATED = "resource.created",
    RESOURCE_UPDATED = "resource.updated",
    RESOURCE_DELETED = "resource.deleted",
    NOTIFICATION_SEND = "notification.send"
}

# Notification types
public enum NotificationType {
    EMAIL = "email",
    SMS = "sms",
    PUSH = "push",
    WEBSOCKET = "websocket",
    IN_APP = "in_app"
}

# Notification priority levels
public enum NotificationPriority {
    LOW = "low",
    MEDIUM = "medium",
    HIGH = "high",
    URGENT = "urgent"
}

# Base event structure from Kafka
public type BaseEvent record {|
    string eventId;
    string eventType;
    string timestamp;
    json eventData;
    EventMetadata metadata;
|};

# Event metadata
public type EventMetadata record {|
    string 'service;
    string 'version;
    string environment;
|};

# Booking event structure
public type BookingEvent record {|
    *BaseEvent;
    string bookingId;
    string userId;
    string resourceId;
|};

# Waitlist event structure
public type WaitlistEvent record {|
    *BaseEvent;
    string waitlistId;
    string userId;
    string resourceId;
|};

# Conflict event structure
public type ConflictEvent record {|
    *BaseEvent;
    string resourceId;
|};

# User event structure
public type UserEvent record {|
    *BaseEvent;
    string userId;
|};

# Resource event structure
public type ResourceEvent record {|
    *BaseEvent;
    string resourceId;
|};

# Notification event structure
public type NotificationEvent record {|
    *BaseEvent;
    string userId;
|};

# Notification message structure
public type NotificationMessage record {|
    string notificationId;
    string userId;
    string title;
    string message;
    NotificationType 'type;
    NotificationPriority priority;
    string? targetChannel;
    json? additionalData;
    time:Utc createdAt;
    time:Utc? scheduledAt;
    boolean isRead;
    string? actionUrl;
    string? imageUrl;
|};

# Email notification data
public type EmailNotificationData record {|
    string to;
    string subject;
    string body;
    string? cc;
    string? bcc;
    string? replyTo;
    boolean isHtml?;
    string? templateId;
    json? templateData;
|};

# SMS notification data
public type SmsNotificationData record {|
    string to;
    string message;
    string? 'from;
|};

# Push notification data
public type PushNotificationData record {|
    string[] deviceTokens;
    string title;
    string body;
    string? icon;
    string? sound;
    json? data;
    string? clickAction;
|};

# WebSocket notification data
public type WebSocketNotificationData record {|
    string[] userIds;
    string 'type;
    json payload;
    boolean broadcast?;
|};

# Consumer configuration
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

# Topic configuration
public type TopicConfig record {|
    string bookingEvents;
    string waitlistEvents;
    string conflictEvents;
    string notificationEvents;
    string userEvents;
    string resourceEvents;
|};

# Notification template
public type NotificationTemplate record {|
    string templateId;
    string name;
    NotificationType 'type;
    string subject?;
    string bodyTemplate;
    json? defaultData;
    boolean isActive;
|};

# Notification delivery status
public type NotificationDeliveryStatus record {|
    string notificationId;
    string userId;
    NotificationType 'type;
    string status; // sent, delivered, failed, pending
    string? errorMessage;
    time:Utc timestamp;
    int retryCount;
|};

# Consumer group offset tracking
public type ConsumerOffset record {|
    string topic;
    int partition;
    int offset;
    time:Utc lastCommitted;
|};
