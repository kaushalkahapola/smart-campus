import ballerina/websocket;
import ballerina/time;

# WebSocket connection types
public enum ConnectionStatus {
    CONNECTED = "connected",
    DISCONNECTED = "disconnected",
    CONNECTING = "connecting",
    ERROR = "error"
}

# WebSocket message types
public enum WebSocketMessageType {
    NOTIFICATION = "notification",
    HEARTBEAT = "heartbeat", 
    SUBSCRIBE = "subscribe",
    UNSUBSCRIBE = "unsubscribe",
    ACK = "ack",
    ERROR = "error",
    SYSTEM = "system"
}

# WebSocket client connection info
public type WebSocketConnection record {|
    string connectionId;
    string userId;
    websocket:Caller caller;
    ConnectionStatus status;
    time:Utc connectedAt;
    time:Utc lastActivity;
    string[] subscribedChannels;
    json? userMetadata;
|};

# WebSocket message structure
public type WebSocketMessage record {|
    string messageId;
    WebSocketMessageType 'type;
    string? channel;
    json payload;
    time:Utc timestamp;
    string? targetUserId;
    boolean broadcast?;
|};

# Notification message for WebSocket
public type WebSocketNotificationPayload record {|
    string notificationId;
    string title;
    string message;
    string priority;
    string? actionUrl;
    string? imageUrl;
    json? additionalData;
    time:Utc createdAt;
|};

# Heartbeat message
public type HeartbeatMessage record {|
    string connectionId;
    time:Utc timestamp;
    string status;
|};

# Subscribe/Unsubscribe message
public type SubscriptionMessage record {|
    string connectionId;
    string[] channels;
    string action; // "subscribe" or "unsubscribe"
|};

# Error message
public type ErrorMessage record {|
    string errorCode;
    string errorMessage;
    string? details;
    time:Utc timestamp;
|};

# System message
public type SystemMessage record {|
    string messageType;
    string content;
    json? data;
    time:Utc timestamp;
|};

# Acknowledgment message
public type AckMessage record {|
    string originalMessageId;
    string status; // "received", "processed", "failed"
    string? errorMessage;
    time:Utc timestamp;
|};

# Channel subscription info
public type ChannelSubscription record {|
    string channelName;
    string[] subscribedUsers;
    time:Utc createdAt;
    json? channelMetadata;
|};

# WebSocket server configuration
public type WebSocketServerConfig record {|
    int port;
    int maxFrameSize;
    string[] subprotocols;
    int idleTimeout;
    int readTimeout;
    int writeTimeout;
|};

# Connection statistics
public type ConnectionStats record {|
    int totalConnections;
    int activeConnections;
    int totalMessagesReceived;
    int totalMessagesSent;
    time:Utc lastReset;
    map<int> messageTypeStats;
|};

# User presence info
public type UserPresence record {|
    string userId;
    ConnectionStatus status;
    time:Utc lastSeen;
    string[] activeConnections;
    json? presenceMetadata;
|};

# Notification delivery confirmation
public type NotificationDelivery record {|
    string notificationId;
    string userId;
    string connectionId;
    string status; // "sent", "delivered", "failed"
    time:Utc timestamp;
    string? errorMessage;
|};

# Broadcast message for multiple users
public type BroadcastMessage record {|
    string broadcastId;
    string[] targetUserIds;
    WebSocketMessage message;
    string? channelFilter;
    json? criteria;
|};

# Connection authentication info
public type ConnectionAuth record {|
    string userId;
    string? token;
    string[] roles;
    string[] permissions;
    time:Utc authenticatedAt;
    time:Utc? expiresAt;
|};

# Channel management
public type ChannelInfo record {|
    string channelName;
    string description;
    boolean isPublic;
    string[] allowedRoles;
    int maxSubscribers;
    int currentSubscribers;
    time:Utc createdAt;
    string createdBy;
|};

# Real-time metrics
public type RealtimeMetrics record {|
    int activeConnections;
    int messageRate; // messages per minute
    int notificationsSent;
    int notificationsDelivered;
    int errorCount;
    time:Utc lastUpdated;
    map<string> userActivityMap;
|};
