import ballerina/websocket;
import ballerina/log;
import ballerina/uuid;
import ballerina/time;

# WebSocket configuration
configurable int websocket_port = 9096;
configurable int max_frame_size = 65536;
configurable string[] subprotocols = ["chat", "notifications"];
configurable int idle_timeout = 900;
configurable int read_timeout = 60;
configurable int write_timeout = 60;

# In-memory storage for WebSocket connections
map<WebSocketConnection> activeConnections = {};
map<string[]> userConnections = {}; // userId -> connectionIds[]
map<ChannelSubscription> channels = {};
ConnectionStats connectionStats = {
    totalConnections: 0,
    activeConnections: 0,
    totalMessagesReceived: 0,
    totalMessagesSent: 0,
    lastReset: time:utcNow(),
    messageTypeStats: {}
};

# WebSocket service configuration
public websocket:ServiceConfig wsConfig = {
    maxFrameSize: max_frame_size,
    subProtocols: subprotocols,
    idleTimeout: idle_timeout,
    readTimeout: read_timeout,
    writeTimeout: write_timeout
};

# Handle new WebSocket connection
#
# + caller - WebSocket caller
# + userId - User ID extracted from authentication
# + return - Success or error
public isolated function handleConnection(websocket:Caller caller, string userId) returns error? {
    string connectionId = uuid:createType1AsString();
    
    WebSocketConnection connection = {
        connectionId: connectionId,
        userId: userId,
        caller: caller,
        status: CONNECTED,
        connectedAt: time:utcNow(),
        lastActivity: time:utcNow(),
        subscribedChannels: []
    };
    
    lock {
        activeConnections[connectionId] = connection;
        
        // Track user connections
        if userConnections.hasKey(userId) {
            userConnections[userId] = [...userConnections.get(userId), connectionId];
        } else {
            userConnections[userId] = [connectionId];
        }
        
        // Update stats
        connectionStats.totalConnections += 1;
        connectionStats.activeConnections += 1;
    }
    
    // Send welcome message
    WebSocketMessage welcomeMessage = {
        messageId: uuid:createType1AsString(),
        'type: SYSTEM,
        payload: {
            "type": "welcome",
            "connectionId": connectionId,
            "message": "Connected to notification service"
        },
        timestamp: time:utcNow()
    };
    
    check sendMessageToConnection(connectionId, welcomeMessage);
    log:printInfo("🔌 New WebSocket connection established for user: " + userId + " (Connection: " + connectionId + ")");
}

# Handle WebSocket disconnection
#
# + connectionId - Connection ID
# + return - Success or error
public isolated function handleDisconnection(string connectionId) returns error? {
    lock {
        if activeConnections.hasKey(connectionId) {
            WebSocketConnection connection = activeConnections.get(connectionId);
            string userId = connection.userId;
            
            // Remove from active connections
            _ = activeConnections.remove(connectionId);
            
            // Update user connections
            if userConnections.hasKey(userId) {
                string[] userConns = userConnections.get(userId);
                string[] updatedConns = [];
                foreach string connId in userConns {
                    if connId != connectionId {
                        updatedConns.push(connId);
                    }
                }
                if updatedConns.length() > 0 {
                    userConnections[userId] = updatedConns;
                } else {
                    _ = userConnections.remove(userId);
                }
            }
            
            // Unsubscribe from all channels
            foreach string channel in connection.subscribedChannels {
                check unsubscribeFromChannel(connectionId, channel);
            }
            
            // Update stats
            connectionStats.activeConnections -= 1;
            
            log:printInfo("🔌 WebSocket connection closed for user: " + userId + " (Connection: " + connectionId + ")");
        }
    }
}

# Handle incoming WebSocket message
#
# + connectionId - Connection ID
# + message - Received message
# + return - Success or error
public isolated function handleMessage(string connectionId, string message) returns error? {
    lock {
        connectionStats.totalMessagesReceived += 1;
        
        if activeConnections.hasKey(connectionId) {
            WebSocketConnection connection = activeConnections.get(connectionId);
            connection.lastActivity = time:utcNow();
            activeConnections[connectionId] = connection;
        }
    }
    
    // Parse the message
    json messageJson = check message.fromJsonString();
    WebSocketMessage wsMessage = check messageJson.cloneWithType(WebSocketMessage);
    
    // Update message type stats
    lock {
        string messageType = wsMessage.'type;
        if connectionStats.messageTypeStats.hasKey(messageType) {
            connectionStats.messageTypeStats[messageType] = connectionStats.messageTypeStats.get(messageType) + 1;
        } else {
            connectionStats.messageTypeStats[messageType] = 1;
        }
    }
    
    log:printInfo("📨 Received WebSocket message: " + wsMessage.'type + " from connection: " + connectionId);
    
    // Handle different message types
    match wsMessage.'type {
        SUBSCRIBE => {
            check handleSubscriptionMessage(connectionId, wsMessage);
        }
        UNSUBSCRIBE => {
            check handleUnsubscriptionMessage(connectionId, wsMessage);
        }
        HEARTBEAT => {
            check handleHeartbeatMessage(connectionId, wsMessage);
        }
        ACK => {
            check handleAckMessage(connectionId, wsMessage);
        }
        _ => {
            log:printWarn("Unhandled WebSocket message type: " + wsMessage.'type);
        }
    }
}

# Send notification to specific user
#
# + userId - Target user ID
# + message - WebSocket message to send
# + return - Success or error
public isolated function sendNotificationToUser(string userId, WebSocketMessage message) returns error? {
    lock {
        if userConnections.hasKey(userId) {
            string[] connectionIds = userConnections.get(userId);
            foreach string connectionId in connectionIds {
                error? result = sendMessageToConnection(connectionId, message);
                if result is error {
                    log:printError("Failed to send notification to connection: " + connectionId, 'error = result);
                }
            }
            log:printInfo("📤 Sent notification to user: " + userId + " (" + connectionIds.length().toString() + " connections)");
        } else {
            log:printInfo("📭 User not connected: " + userId + " - notification will be stored for later delivery");
            // Here you could store the notification for later delivery
        }
    }
}

# Send message to specific connection
#
# + connectionId - Connection ID
# + message - WebSocket message
# + return - Success or error
isolated function sendMessageToConnection(string connectionId, WebSocketMessage message) returns error? {
    lock {
        if activeConnections.hasKey(connectionId) {
            WebSocketConnection connection = activeConnections.get(connectionId);
            string messageJson = message.toJsonString();
            error? result = connection.caller->writeMessage(messageJson);
            
            if result is error {
                log:printError("Failed to send message to connection: " + connectionId, 'error = result);
                return result;
            }
            
            connectionStats.totalMessagesSent += 1;
            return;
        } else {
            return error("Connection not found: " + connectionId);
        }
    }
}

# Broadcast message to all connected users
#
# + message - Message to broadcast
# + return - Success or error
public isolated function broadcastMessage(WebSocketMessage message) returns error? {
    lock {
        foreach WebSocketConnection connection in activeConnections {
            error? result = sendMessageToConnection(connection.connectionId, message);
            if result is error {
                log:printError("Failed to broadcast to connection: " + connection.connectionId, 'error = result);
            }
        }
        log:printInfo("📢 Broadcasted message to " + activeConnections.length().toString() + " connections");
    }
}

# Broadcast to users in specific channel
#
# + channelName - Channel name
# + message - Message to broadcast
# + return - Success or error
public isolated function broadcastToChannel(string channelName, WebSocketMessage message) returns error? {
    lock {
        if channels.hasKey(channelName) {
            ChannelSubscription channel = channels.get(channelName);
            foreach string userId in channel.subscribedUsers {
                if userConnections.hasKey(userId) {
                    string[] connectionIds = userConnections.get(userId);
                    foreach string connectionId in connectionIds {
                        error? result = sendMessageToConnection(connectionId, message);
                        if result is error {
                            log:printError("Failed to send to connection: " + connectionId, 'error = result);
                        }
                    }
                }
            }
            log:printInfo("📢 Broadcasted to channel: " + channelName + " (" + channel.subscribedUsers.length().toString() + " users)");
        }
    }
}

# Subscribe connection to channel
#
# + connectionId - Connection ID
# + channelName - Channel name
# + return - Success or error
isolated function subscribeToChannel(string connectionId, string channelName) returns error? {
    lock {
        if activeConnections.hasKey(connectionId) {
            WebSocketConnection connection = activeConnections.get(connectionId);
            
            // Add channel to connection's subscribed channels
            if !connection.subscribedChannels.some(channel => channel == channelName) {
                connection.subscribedChannels.push(channelName);
                activeConnections[connectionId] = connection;
            }
            
            // Add user to channel's subscribers
            if channels.hasKey(channelName) {
                ChannelSubscription channel = channels.get(channelName);
                if !channel.subscribedUsers.some(user => user == connection.userId) {
                    channel.subscribedUsers.push(connection.userId);
                    channels[channelName] = channel;
                }
            } else {
                ChannelSubscription newChannel = {
                    channelName: channelName,
                    subscribedUsers: [connection.userId],
                    createdAt: time:utcNow()
                };
                channels[channelName] = newChannel;
            }
            
            log:printInfo("✅ Subscribed connection " + connectionId + " to channel: " + channelName);
        }
    }
}

# Unsubscribe connection from channel
#
# + connectionId - Connection ID  
# + channelName - Channel name
# + return - Success or error
isolated function unsubscribeFromChannel(string connectionId, string channelName) returns error? {
    lock {
        if activeConnections.hasKey(connectionId) {
            WebSocketConnection connection = activeConnections.get(connectionId);
            
            // Remove channel from connection's subscribed channels
            string[] updatedChannels = [];
            foreach string channel in connection.subscribedChannels {
                if channel != channelName {
                    updatedChannels.push(channel);
                }
            }
            connection.subscribedChannels = updatedChannels;
            activeConnections[connectionId] = connection;
            
            // Remove user from channel's subscribers
            if channels.hasKey(channelName) {
                ChannelSubscription channel = channels.get(channelName);
                string[] updatedUsers = [];
                foreach string userId in channel.subscribedUsers {
                    if userId != connection.userId {
                        updatedUsers.push(userId);
                    }
                }
                channel.subscribedUsers = updatedUsers;
                
                // Remove channel if no subscribers
                if updatedUsers.length() == 0 {
                    _ = channels.remove(channelName);
                } else {
                    channels[channelName] = channel;
                }
            }
            
            log:printInfo("❌ Unsubscribed connection " + connectionId + " from channel: " + channelName);
        }
    }
}

# Handle subscription message
#
# + connectionId - Connection ID
# + message - Subscription message
# + return - Success or error
isolated function handleSubscriptionMessage(string connectionId, WebSocketMessage message) returns error? {
    SubscriptionMessage subMsg = check message.payload.cloneWithType(SubscriptionMessage);
    
    foreach string channel in subMsg.channels {
        check subscribeToChannel(connectionId, channel);
    }
    
    // Send acknowledgment
    WebSocketMessage ack = {
        messageId: uuid:createType1AsString(),
        'type: ACK,
        payload: {
            "originalMessageId": message.messageId,
            "status": "processed",
            "subscribedChannels": subMsg.channels
        },
        timestamp: time:utcNow()
    };
    
    check sendMessageToConnection(connectionId, ack);
}

# Handle unsubscription message
#
# + connectionId - Connection ID
# + message - Unsubscription message
# + return - Success or error
isolated function handleUnsubscriptionMessage(string connectionId, WebSocketMessage message) returns error? {
    SubscriptionMessage unsubMsg = check message.payload.cloneWithType(SubscriptionMessage);
    
    foreach string channel in unsubMsg.channels {
        check unsubscribeFromChannel(connectionId, channel);
    }
    
    // Send acknowledgment
    WebSocketMessage ack = {
        messageId: uuid:createType1AsString(),
        'type: ACK,
        payload: {
            "originalMessageId": message.messageId,
            "status": "processed",
            "unsubscribedChannels": unsubMsg.channels
        },
        timestamp: time:utcNow()
    };
    
    check sendMessageToConnection(connectionId, ack);
}

# Handle heartbeat message
#
# + connectionId - Connection ID
# + message - Heartbeat message
# + return - Success or error
isolated function handleHeartbeatMessage(string connectionId, WebSocketMessage message) returns error? {
    // Update last activity
    lock {
        if activeConnections.hasKey(connectionId) {
            WebSocketConnection connection = activeConnections.get(connectionId);
            connection.lastActivity = time:utcNow();
            activeConnections[connectionId] = connection;
        }
    }
    
    // Send heartbeat response
    WebSocketMessage response = {
        messageId: uuid:createType1AsString(),
        'type: HEARTBEAT,
        payload: {
            "connectionId": connectionId,
            "timestamp": time:utcNow(),
            "status": "alive"
        },
        timestamp: time:utcNow()
    };
    
    check sendMessageToConnection(connectionId, response);
}

# Handle acknowledgment message
#
# + connectionId - Connection ID
# + message - Acknowledgment message
# + return - Success or error
isolated function handleAckMessage(string connectionId, WebSocketMessage message) returns error? {
    AckMessage ackMsg = check message.payload.cloneWithType(AckMessage);
    log:printInfo("✅ Received ACK for message: " + ackMsg.originalMessageId + " with status: " + ackMsg.status);
    
    // Here you could update delivery status tracking
    // For example, mark notification as delivered
}

# Get active connections count
#
# + return - Number of active connections
public isolated function getActiveConnectionsCount() returns int {
    lock {
        return activeConnections.length();
    }
}

# Get connection statistics
#
# + return - Connection statistics
public isolated function getConnectionStats() returns ConnectionStats {
    lock {
        return connectionStats.clone();
    }
}

# Get user presence information
#
# + userId - User ID
# + return - User presence info
public isolated function getUserPresence(string userId) returns UserPresence? {
    lock {
        if userConnections.hasKey(userId) {
            string[] connectionIds = userConnections.get(userId);
            return {
                userId: userId,
                status: CONNECTED,
                lastSeen: time:utcNow(),
                activeConnections: connectionIds
            };
        }
        return ();
    }
}

# Get all online users
#
# + return - List of online user IDs
public isolated function getOnlineUsers() returns string[] {
    lock {
        return userConnections.keys();
    }
}

# Clean up inactive connections
#
# + timeoutMinutes - Timeout in minutes for inactive connections
# + return - Number of connections cleaned up
public isolated function cleanupInactiveConnections(int timeoutMinutes) returns int {
    int cleanedUp = 0;
    time:Utc cutoffTime = time:utcAddSeconds(time:utcNow(), -(timeoutMinutes * 60));
    
    lock {
        string[] connectionsToRemove = [];
        
        foreach WebSocketConnection connection in activeConnections {
            if time:utcDiffSeconds(cutoffTime, connection.lastActivity) > 0 {
                connectionsToRemove.push(connection.connectionId);
            }
        }
        
        foreach string connectionId in connectionsToRemove {
            error? result = handleDisconnection(connectionId);
            if result is error {
                log:printError("Failed to cleanup connection: " + connectionId, 'error = result);
            } else {
                cleanedUp += 1;
            }
        }
    }
    
    if cleanedUp > 0 {
        log:printInfo("🧹 Cleaned up " + cleanedUp.toString() + " inactive connections");
    }
    
    return cleanedUp;
}
