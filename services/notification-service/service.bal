import ballerina/http;
import ballerina/log;
import ballerina/websocket;
import ballerina/time;
import ballerina/uuid;
import notification_service.kafka as kafka;
import notification_service.websocket as ws;

# Configurable variables
configurable int port = 9091;
configurable int websocket_port = 9092;

# HTTP service for notification management
@http:ServiceConfig {
    cors: {
        allowOrigins: ["*"],
        allowCredentials: false,
        allowHeaders: ["ACAO", "Content-Type", "Authorization"],
        allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    }
}
service /notifications on new http:Listener(port) {

    # Initialize the notification service
    function init() {
        log:printInfo("🚀 Starting Notification Service on port " + port.toString());
        
        // Set up the notification callback to bridge kafka and websocket modules
        kafka:setNotificationCallback(sendNotificationToUser);
        
        // Initialize Kafka consumers
        error? kafkaResult = initializeKafka();
        if kafkaResult is error {
            log:printError("Failed to initialize Kafka consumers", 'error = kafkaResult);
        } else {
            log:printInfo("✅ Kafka consumers initialized successfully");
            
            // Start consuming events from different topics
            error? startResult = startKafkaConsumers();
            if startResult is error {
                log:printError("Failed to start Kafka consumers", 'error = startResult);
            } else {
                log:printInfo("✅ All Kafka event consumers started");
            }
        }
        
        log:printInfo("🔔 Notification Service initialized successfully");
    }

    # Health check endpoint
    #
    # + return - Service health status
    resource function get health() returns ServiceHealthStatus|InternalServerErrorResponse {
        try {
            int activeConnections = getActiveConnectionsCount();
            
            ServiceHealthStatus health = {
                status: "healthy",
                'version: "1.0.0",
                timestamp: time:utcNow(),
                components: {
                    kafkaConnected: true, // Would check actual Kafka connection
                    webSocketActive: true,
                    activeConnections: activeConnections
                }
            };
            
            log:printInfo("🏥 Health check - Active connections: " + activeConnections.toString());
            return health;
        } catch (error e) {
            log:printError("Health check failed", 'error = e);
            return {
                body: {errorMessage: "Health check failed: " + e.message()}
            };
        }
    }

    # Send notification to a user
    #
    # + request - Send notification request
    # + return - Send notification response or error
    resource function post send(SendNotificationRequest request) returns SendNotificationResponse|BadRequestResponse|InternalServerErrorResponse {
        try {
            log:printInfo("📤 Sending notification to user: " + request.userId);
            
            string notificationId = uuid:createType1AsString();
            
            // Create notification message using functions.bal
            var priority = convertPriority(request.priority);
            var notification = createNotificationMessage(
                notificationId,
                request.userId,
                request.title,
                request.message,
                priority,
                request.additionalData,
                request.actionUrl,
                request.imageUrl,
                request.scheduledAt
            );
            
            // Send via WebSocket for real-time delivery
            error? wsResult = sendNotificationToUser(request.userId, notification);
            if wsResult is error {
                log:printError("Failed to send WebSocket notification", 'error = wsResult);
            }
            
            SendNotificationResponse response = {
                notificationId: notificationId,
                status: "sent",
                message: "Notification sent successfully",
                timestamp: time:utcNow()
            };
            
            log:printInfo("✅ Notification sent: " + notificationId);
            return response;
            
        } catch (error e) {
            log:printError("Failed to send notification", 'error = e);
            return {
                body: {errorMessage: "Failed to send notification: " + e.message()}
            };
        }
    }

    # Send bulk notifications to multiple users
    #
    # + request - Bulk notification request
    # + return - Bulk notification response or error
    resource function post bulk(BulkNotificationRequest request) returns BulkNotificationResponse|BadRequestResponse|InternalServerErrorResponse {
        try {
            log:printInfo("📤 Sending bulk notification to " + request.userIds.length().toString() + " users");
            
            string batchId = uuid:createType1AsString();
            int successCount = 0;
            int failureCount = 0;
            
            foreach string userId in request.userIds {
                try {
                    string notificationId = uuid:createType1AsString();
                    
                    var priority = convertPriority(request.priority);
                    var notification = createNotificationMessage(
                        notificationId,
                        userId,
                        request.title,
                        request.message,
                        priority,
                        request.additionalData,
                        request.actionUrl,
                        request.imageUrl,
                        request.scheduledAt
                    );
                    
                    error? result = sendNotificationToUser(userId, notification);
                    if result is error {
                        failureCount += 1;
                        log:printError("Failed to send notification to user: " + userId, 'error = result);
                    } else {
                        successCount += 1;
                    }
                } catch (error e) {
                    failureCount += 1;
                    log:printError("Error processing notification for user: " + userId, 'error = e);
                }
            }
            
            BulkNotificationResponse response = {
                batchId: batchId,
                totalRecipients: request.userIds.length(),
                successCount: successCount,
                failureCount: failureCount,
                timestamp: time:utcNow()
            };
            
            log:printInfo("✅ Bulk notification completed - Success: " + successCount.toString() + ", Failed: " + failureCount.toString());
            return response;
            
        } catch (error e) {
            log:printError("Failed to send bulk notification", 'error = e);
            return {
                body: {errorMessage: "Failed to send bulk notification: " + e.message()}
            };
        }
    }

    # Get WebSocket connection status
    #
    # + return - WebSocket connection status
    resource function get websocket/status() returns WebSocketConnectionStatus|InternalServerErrorResponse {
        try {
            int activeConnections = getActiveConnectionsCount();
            string[] onlineUsers = getOnlineUsers();
            
            WebSocketConnectionStatus status = {
                totalConnections: activeConnections,
                activeConnections: activeConnections,
                onlineUsers: onlineUsers,
                timestamp: time:utcNow()
            };
            
            return status;
        } catch (error e) {
            log:printError("Failed to get WebSocket status", 'error = e);
            return {
                body: {errorMessage: "Failed to get WebSocket status: " + e.message()}
            };
        }
    }

    # Get connection statistics
    #
    # + return - Connection statistics
    resource function get stats() returns ConnectionStats|InternalServerErrorResponse {
        try {
            return getWebSocketStats();
        } catch (error e) {
            log:printError("Failed to get connection stats", 'error = e);
            return {
                body: {errorMessage: "Failed to get connection stats: " + e.message()}
            };
        }
    }

    # Broadcast message to all connected users
    #
    # + request - Broadcast message request  
    # + return - Success response or error
    resource function post broadcast(record {|string title; string message; string priority?;|} request) returns SuccessResponse|BadRequestResponse|InternalServerErrorResponse {
        try {
            log:printInfo("📢 Broadcasting message to all users");
            
            error? result = broadcastSystemMessage(request.title, request.message, request.priority ?: "medium");
            if result is error {
                log:printError("Failed to broadcast message", 'error = result);
                return {
                    body: {errorMessage: "Failed to broadcast message: " + result.message()}
                };
            }
            
            log:printInfo("✅ Message broadcasted successfully");
            return {
                body: {
                    message: "Message broadcasted successfully",
                    data: {"timestamp": time:utcNow()}
                }
            };
        } catch (error e) {
            log:printError("Failed to broadcast message", 'error = e);
            return {
                body: {errorMessage: "Failed to broadcast message: " + e.message()}
            };
        }
    }

    # Cleanup inactive WebSocket connections
    #
    # + timeoutMinutes - Timeout in minutes (default: 30)
    # + return - Cleanup result
    resource function post cleanup(record {|int timeoutMinutes?;|} request = {}) returns SuccessResponse|InternalServerErrorResponse {
        try {
            int timeout = request.timeoutMinutes ?: 30;
            int cleanedUp = cleanupInactiveConnections(timeout);
            
            log:printInfo("🧹 Connection cleanup completed - Removed: " + cleanedUp.toString() + " connections");
            return {
                body: {
                    message: "Connection cleanup completed",
                    data: {"cleanedUpConnections": cleanedUp, "timeoutMinutes": timeout}
                }
            };
        } catch (error e) {
            log:printError("Failed to cleanup connections", 'error = e);
            return {
                body: {errorMessage: "Failed to cleanup connections: " + e.message()}
            };
        }
    }
}

# WebSocket service for real-time notifications
@websocket:ServiceConfig ws:wsConfig
service /ws on new websocket:Listener(websocket_port) {

    # Handle WebSocket upgrade and connection
    #
    # + caller - WebSocket caller
    # + request - HTTP request
    # + return - Success or error
    resource function get .(websocket:Caller caller, http:Request request) returns websocket:Service|websocket:UpgradeError {
        
        // Extract user ID from query parameters or headers
        // In production, this should be extracted from a validated JWT token
        string? userId = request.getQueryParamValue("userId");
        
        if userId is () {
            log:printError("WebSocket connection rejected - Missing userId parameter");
            return error websocket:UpgradeError("Missing userId parameter");
        }
        
        log:printInfo("🔌 WebSocket connection request from user: " + userId);
        
        return new WebSocketNotificationService(userId);
    }
}

# WebSocket service implementation for handling individual connections
service class WebSocketNotificationService {
    *websocket:Service;
    
    private string userId;
    private string connectionId = "";

    # Initialize WebSocket service for a user
    #
    # + userId - User ID for this connection
    function init(string userId) {
        self.userId = userId;
    }

    # Handle new WebSocket connection
    #
    # + caller - WebSocket caller
    # + return - Success or error
    remote function onOpen(websocket:Caller caller) returns error? {
        self.connectionId = uuid:createType1AsString();
        error? result = ws:handleConnection(caller, self.userId);
        if result is error {
            log:printError("Failed to handle WebSocket connection for user: " + self.userId, 'error = result);
            return result;
        }
        log:printInfo("✅ WebSocket connection established for user: " + self.userId);
    }

    # Handle incoming WebSocket messages
    #
    # + caller - WebSocket caller
    # + data - Message data
    # + return - Success or error
    remote function onMessage(websocket:Caller caller, websocket:Message data) returns error? {
        string message = check string:fromBytes(data.data);
        error? result = ws:handleMessage(self.connectionId, message);
        if result is error {
            log:printError("Failed to handle WebSocket message from user: " + self.userId, 'error = result);
            return result;
        }
    }

    # Handle WebSocket connection closure
    #
    # + caller - WebSocket caller
    # + statusCode - Close status code
    # + reason - Close reason
    # + return - Success or error
    remote function onClose(websocket:Caller caller, int statusCode, string reason) returns error? {
        error? result = ws:handleDisconnection(self.connectionId);
        if result is error {
            log:printError("Failed to handle WebSocket disconnection for user: " + self.userId, 'error = result);
            return result;
        }
        log:printInfo("🔌 WebSocket connection closed for user: " + self.userId + " (Code: " + statusCode.toString() + ", Reason: " + reason + ")");
    }

    # Handle WebSocket errors
    #
    # + caller - WebSocket caller
    # + err - Error details
    # + return - Success or error
    remote function onError(websocket:Caller caller, error err) returns error? {
        log:printError("WebSocket error for user: " + self.userId, 'error = err);
        error? result = ws:handleDisconnection(self.connectionId);
        if result is error {
            log:printError("Failed to handle WebSocket error cleanup for user: " + self.userId, 'error = result);
        }
    }
}
