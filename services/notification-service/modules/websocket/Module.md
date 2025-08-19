# WebSocket Module

This module handles real-time WebSocket communication for the notification service. It manages WebSocket connections, channels, and real-time message delivery.

## Features

- **Real-time Communication**: WebSocket-based real-time messaging
- **Connection Management**: Track and manage active WebSocket connections
- **Channel Subscriptions**: Subscribe/unsubscribe to notification channels
- **User Presence**: Track online users and their connection status
- **Message Broadcasting**: Send messages to individual users or broadcast to channels
- **Heartbeat Monitoring**: Keep-alive mechanism for connection health
- **Error Handling**: Robust error handling and connection cleanup

## Message Types

### Notification Messages
Real-time notifications sent to users:
```json
{
  "messageId": "uuid",
  "type": "notification",
  "payload": {
    "notificationId": "uuid",
    "title": "Booking Confirmed",
    "message": "Your booking has been confirmed",
    "priority": "medium",
    "actionUrl": "/bookings/123",
    "createdAt": "2024-01-01T00:00:00Z"
  },
  "timestamp": "2024-01-01T00:00:00Z",
  "targetUserId": "user123"
}
```

### Subscription Messages
Subscribe to notification channels:
```json
{
  "messageId": "uuid",
  "type": "subscribe",
  "payload": {
    "connectionId": "conn123",
    "channels": ["booking-updates", "waitlist-notifications"],
    "action": "subscribe"
  }
}
```

### Heartbeat Messages
Keep connection alive:
```json
{
  "messageId": "uuid",
  "type": "heartbeat",
  "payload": {
    "connectionId": "conn123",
    "timestamp": "2024-01-01T00:00:00Z",
    "status": "alive"
  }
}
```

## Connection Management

### Connection Lifecycle
1. **Connection**: User connects with authentication
2. **Welcome**: Server sends welcome message with connection ID
3. **Subscription**: Client subscribes to relevant channels
4. **Communication**: Real-time message exchange
5. **Heartbeat**: Periodic keep-alive messages
6. **Cleanup**: Connection cleanup on disconnect

### Channel Subscriptions
Users can subscribe to specific notification channels:
- `booking-updates` - Booking-related notifications
- `waitlist-notifications` - Waitlist status changes
- `system-announcements` - System-wide announcements
- `user-{userId}` - Personal notifications

## Configuration

Configure WebSocket settings in `Config.toml`:

```toml
[notification_service.websocket]
max_frame_size = 65536
subprotocols = ["chat", "notifications"]
idle_timeout = 900
read_timeout = 60
write_timeout = 60
```

## Usage

```ballerina
import notification_service.websocket as ws;

// Handle new connection
check ws:handleConnection(caller, userId);

// Send notification to user
check ws:sendNotificationToUser(userId, notification);

// Broadcast to all users
check ws:broadcastMessage(message);

// Broadcast to channel
check ws:broadcastToChannel("booking-updates", message);

// Get connection stats
ConnectionStats stats = ws:getConnectionStats();

// Cleanup inactive connections
int cleaned = ws:cleanupInactiveConnections(30); // 30 minutes timeout
```

## Error Handling

The module includes comprehensive error handling:
- Connection failures are logged and connections cleaned up
- Invalid messages are logged and ignored
- Network errors trigger automatic reconnection attempts
- Inactive connections are automatically cleaned up

## Security Considerations

- User authentication should be handled before establishing WebSocket connection
- Message validation prevents malformed message injection
- Connection limits can be enforced to prevent DoS attacks
- Channel access control based on user roles

## Dependencies

- `ballerina/websocket` - WebSocket server
- `ballerina/log` - Logging
- `ballerina/uuid` - UUID generation
- `ballerina/time` - Time utilities
- `notification_service.kafka` - Event handling integration
