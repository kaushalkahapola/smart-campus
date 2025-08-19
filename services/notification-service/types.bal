import ballerina/http;
import ballerina/time;

# Notfound Response record type
public type NotFoundResponse record {|
    *http:NotFound;
    # payload 
    record {|
        string errorMessage;
    |} body;
|};

# BadRequest Response record type
public type BadRequestResponse record {|
    *http:BadRequest;
    # payload 
    record {|
        string errorMessage;
    |} body;
|};

# InternalServerError Response record type
public type InternalServerErrorResponse record {|
    *http:InternalServerError;
    # payload 
    record {|
        string errorMessage;
    |} body;
|};

# Conflict Response record type
public type ConflictResponse record {|
    *http:Conflict;
    # payload 
    record {|
        string errorMessage;
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

# Success Response record type
public type SuccessResponse record {|
    *http:Ok;
    # payload
    record {|
        string message;
        json? data;
    |} body;
|};

# Notification delivery channel types
public enum DeliveryChannel {
    EMAIL = "email",
    SMS = "sms", 
    PUSH = "push",
    WEBSOCKET = "websocket",
    IN_APP = "in_app"
}

# Notification status types
public enum NotificationStatus {
    PENDING = "pending",
    SENT = "sent",
    DELIVERED = "delivered",
    FAILED = "failed",
    READ = "read"
}

# API request/response types for HTTP endpoints

# Send notification request
public type SendNotificationRequest record {|
    string userId;
    string title;
    string message;
    string priority?; // low, medium, high, urgent
    DeliveryChannel[] channels?;
    string? actionUrl;
    string? imageUrl;
    json? additionalData;
    time:Utc? scheduledAt;
|};

# Send notification response
public type SendNotificationResponse record {|
    string notificationId;
    string status;
    string message;
    time:Utc timestamp;
|};

# Bulk notification request
public type BulkNotificationRequest record {|
    string[] userIds;
    string title;
    string message;
    string priority?;
    DeliveryChannel[] channels?;
    string? actionUrl;
    string? imageUrl;
    json? additionalData;
    time:Utc? scheduledAt;
|};

# Bulk notification response
public type BulkNotificationResponse record {|
    string batchId;
    int totalRecipients;
    int successCount;
    int failureCount;
    time:Utc timestamp;
|};

# Get notifications request (query parameters)
public type GetNotificationsParams record {|
    string? userId;
    NotificationStatus? status;
    int? 'limit;
    int? offset;
    string? startDate;
    string? endDate;
|};

# Notification details
public type NotificationDetails record {|
    string notificationId;
    string userId;
    string title;
    string message;
    string priority;
    DeliveryChannel[] channels;
    NotificationStatus status;
    string? actionUrl;
    string? imageUrl;
    json? additionalData;
    time:Utc createdAt;
    time:Utc? scheduledAt;
    time:Utc? sentAt;
    time:Utc? deliveredAt;
    time:Utc? readAt;
    boolean isRead;
|};

# Get notifications response
public type GetNotificationsResponse record {|
    NotificationDetails[] notifications;
    int totalCount;
    int 'limit;
    int offset;
|};

# Mark notification as read request
public type MarkAsReadRequest record {|
    string[] notificationIds;
|};

# Mark as read response  
public type MarkAsReadResponse record {|
    int updatedCount;
    string message;
    time:Utc timestamp;
|};

# Delete notifications request
public type DeleteNotificationsRequest record {|
    string[] notificationIds;
|};

# Delete notifications response
public type DeleteNotificationsResponse record {|
    int deletedCount;
    string message;
    time:Utc timestamp;
|};

# WebSocket connection status
public type WebSocketConnectionStatus record {|
    int totalConnections;
    int activeConnections;
    string[] onlineUsers;
    time:Utc timestamp;
|};

# Service health status
public type ServiceHealthStatus record {|
    string status; // healthy, degraded, unhealthy
    string 'version;
    time:Utc timestamp;
    record {|
        boolean kafkaConnected;
        boolean webSocketActive;
        int activeConnections;
        string? lastError;
    |} components;
|};

# Notification template for reusable notifications
public type NotificationTemplate record {|
    string templateId;
    string name;
    string description;
    string titleTemplate;
    string messageTemplate;
    DeliveryChannel[] defaultChannels;
    string defaultPriority;
    json? defaultData;
    boolean isActive;
    time:Utc createdAt;
    time:Utc updatedAt;
    string createdBy;
|};

# Template usage request
public type UseTemplateRequest record {|
    string templateId;
    string[] userIds;
    json? templateData;
    time:Utc? scheduledAt;
|};

# Notification preferences for users
public type NotificationPreferences record {|
    string userId;
    DeliveryChannel[] enabledChannels;
    boolean emailEnabled;
    boolean smsEnabled;
    boolean pushEnabled;
    boolean webSocketEnabled;
    string quietHoursStart?; // HH:MM format
    string quietHoursEnd?;   // HH:MM format
    string timezone?;
    json? channelSettings;
    time:Utc updatedAt;
|};

# Update preferences request
public type UpdatePreferencesRequest record {|
    DeliveryChannel[] enabledChannels?;
    boolean? emailEnabled;
    boolean? smsEnabled;
    boolean? pushEnabled;
    boolean? webSocketEnabled;
    string? quietHoursStart;
    string? quietHoursEnd;
    string? timezone;
    json? channelSettings;
|};

# Notification analytics
public type NotificationAnalytics record {|
    time:Utc periodStart;
    time:Utc periodEnd;
    int totalSent;
    int totalDelivered;
    int totalRead;
    int totalFailed;
    decimal deliveryRate; // percentage
    decimal readRate;     // percentage
    map<int> channelBreakdown;
    map<int> priorityBreakdown;
    time:Utc generatedAt;
|};

# Connection statistics (from websocket module)
public type ConnectionStats record {|
    int totalConnections;
    int activeConnections;
    int totalMessagesReceived;
    int totalMessagesSent;
    time:Utc lastReset;
    map<int> messageTypeStats;
|};