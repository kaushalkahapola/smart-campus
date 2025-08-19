import ballerina/log;
import ballerina/uuid;
import ballerina/time;
import notification_service.kafka as kafka;
import notification_service.websocket as ws;

# Bridge function to send notification from Kafka module to WebSocket module
#
# + userId - Target user ID
# + notification - Notification message from Kafka module
# + return - Success or error
public isolated function sendNotificationToUser(string userId, kafka:NotificationMessage notification) returns error? {
    // Convert Kafka notification to WebSocket notification payload
    ws:WebSocketNotificationPayload payload = {
        notificationId: notification.notificationId,
        title: notification.title,
        message: notification.message,
        priority: notification.priority,
        actionUrl: notification.actionUrl,
        imageUrl: notification.imageUrl,
        additionalData: notification.additionalData,
        createdAt: notification.createdAt
    };
    
    // Create WebSocket message
    ws:WebSocketMessage wsMessage = {
        messageId: uuid:createType1AsString(),
        'type: ws:NOTIFICATION,
        payload: payload,
        timestamp: time:utcNow(),
        targetUserId: userId
    };
    
    // Send via WebSocket
    return ws:sendNotificationToUser(userId, wsMessage);
}

# Bridge function to broadcast system messages
#
# + title - Message title
# + message - Message content
# + priority - Message priority
# + return - Success or error
public isolated function broadcastSystemMessage(string title, string message, string priority) returns error? {
    ws:WebSocketMessage broadcastMessage = {
        messageId: uuid:createType1AsString(),
        'type: ws:NOTIFICATION,
        payload: {
            notificationId: uuid:createType1AsString(),
            title: title,
            message: message,
            priority: priority,
            createdAt: time:utcNow()
        },
        timestamp: time:utcNow(),
        broadcast: true
    };
    
    return ws:broadcastMessage(broadcastMessage);
}

# Convert priority string to Kafka notification priority enum
#
# + priority - Priority string
# + return - Notification priority enum
public isolated function convertPriority(string? priority) returns kafka:NotificationPriority {
    if priority is () {
        return kafka:MEDIUM;
    }
    
    match priority.toLowerAscii() {
        "low" => {
            return kafka:LOW;
        }
        "medium" => {
            return kafka:MEDIUM;
        }
        "high" => {
            return kafka:HIGH;
        }
        "urgent" => {
            return kafka:URGENT;
        }
        _ => {
            return kafka:MEDIUM;
        }
    }
}

# Create notification message for Kafka processing
#
# + notificationId - Notification ID
# + userId - User ID
# + title - Notification title
# + message - Notification message
# + priority - Notification priority
# + additionalData - Additional data
# + actionUrl - Action URL
# + imageUrl - Image URL
# + scheduledAt - Scheduled time
# + return - Notification message
public isolated function createNotificationMessage(
    string notificationId,
    string userId,
    string title,
    string message,
    kafka:NotificationPriority priority,
    json? additionalData,
    string? actionUrl,
    string? imageUrl,
    time:Utc? scheduledAt
) returns kafka:NotificationMessage {
    return {
        notificationId: notificationId,
        userId: userId,
        title: title,
        message: message,
        'type: kafka:WEBSOCKET,
        priority: priority,
        targetChannel: (),
        additionalData: additionalData,
        createdAt: time:utcNow(),
        scheduledAt: scheduledAt,
        isRead: false,
        actionUrl: actionUrl,
        imageUrl: imageUrl
    };
}

# Get WebSocket connection statistics
#
# + return - Connection statistics
public isolated function getWebSocketStats() returns ws:ConnectionStats {
    return ws:getConnectionStats();
}

# Get active WebSocket connections count
#
# + return - Number of active connections
public isolated function getActiveConnectionsCount() returns int {
    return ws:getActiveConnectionsCount();
}

# Get online users list
#
# + return - List of online user IDs
public isolated function getOnlineUsers() returns string[] {
    return ws:getOnlineUsers();
}

# Cleanup inactive WebSocket connections
#
# + timeoutMinutes - Timeout in minutes
# + return - Number of cleaned up connections
public isolated function cleanupInactiveConnections(int timeoutMinutes) returns int {
    return ws:cleanupInactiveConnections(timeoutMinutes);
}

# Initialize Kafka consumers
#
# + return - Success or error
public isolated function initializeKafka() returns error? {
    return kafka:initializeKafkaConsumers();
}

# Start all Kafka event consumers
#
# + return - Success or error
public isolated function startKafkaConsumers() returns error? {
    // Start all consumer workers
    _ = start kafka:startBookingEventConsumer();
    _ = start kafka:startWaitlistEventConsumer();
    _ = start kafka:startConflictEventConsumer();
    _ = start kafka:startNotificationEventConsumer();
    _ = start kafka:startUserEventConsumer();
    _ = start kafka:startResourceEventConsumer();
    
    log:printInfo("✅ All Kafka event consumers started");
    return;
}

# Close Kafka consumers
#
# + return - Success or error
public isolated function closeKafka() returns error? {
    return kafka:closeKafkaConsumers();
}
