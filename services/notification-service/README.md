# Notification Service

The Notification Service is a comprehensive real-time notification system for the Smart Campus Resource Management Platform. It handles multi-channel notifications through Kafka event consumption and WebSocket real-time communication.

## 🎯 Overview

This service serves as the central notification hub that:
- Consumes events from various campus services via Kafka
- Delivers real-time notifications through WebSocket connections
- Supports multiple notification channels (WebSocket, Email, SMS, Push)
- Manages user connections and presence
- Provides notification delivery tracking and analytics

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Kafka Topics  │    │ Notification    │    │   WebSocket     │
│                 │    │   Service       │    │  Connections    │
│ • booking-events│───▶│                 │───▶│                 │
│ • waitlist-events│   │  Port: 9091     │    │  Port: 9092     │
│ • conflict-events│   │                 │    │                 │
│ • user-events   │    │ ┌─────────────┐ │    │ • Real-time     │
│ • resource-events│   │ │ Kafka Module│ │    │   notifications │
│ • notification- │    │ └─────────────┘ │    │ • Channel mgmt  │
│   events        │    │ ┌─────────────┐ │    │ • User presence │
└─────────────────┘    │ │WebSocket Mod│ │    │ • Broadcasting  │
                       │ └─────────────┘ │    └─────────────────┘
                       └─────────────────┘
```

## 📦 Modules

### Kafka Module (`modules/kafka/`)
Handles event consumption and processing from Kafka topics.

**Files:**
- `types.bal` - Event types and data structures
- `utils.bal` - Kafka consumer logic and event processing
- `Module.md` - Module documentation

**Features:**
- Multi-topic event consumption
- Event type routing and processing
- Notification trigger logic
- Error handling and logging

### WebSocket Module (`modules/websocket/`)
Manages real-time WebSocket connections and message delivery.

**Files:**
- `types.bal` - WebSocket message types and connection structures
- `utils.bal` - Connection management and message handling
- `Module.md` - Module documentation

**Features:**
- Connection lifecycle management
- Channel-based subscriptions
- Real-time message broadcasting
- User presence tracking
- Connection cleanup and health monitoring

## 🚀 Getting Started

### Prerequisites
- Ballerina 2201.10.1+
- Apache Kafka (running on localhost:9092)
- Other campus services (booking, user, resource services)

### Installation
1. Navigate to the notification service directory:
   ```bash
   cd services/notification-service
   ```

2. Install dependencies:
   ```bash
   bal build
   ```

3. Configure the service by updating `Config.toml`:
   ```toml
   [notification_service]
   port = 9091
   websocket_port = 9092

   [notification_service.kafka]
   bootstrap_servers = ["localhost:9092"]
   client_id = "notification-service"
   group_id = "notification-group"
   ```

4. Run the service:
   ```bash
   bal run
   ```

## 📡 API Endpoints

### HTTP API (Port 9091)

#### Health Check
```http
GET /notifications/health
```
Returns service health status and component status.

#### Send Notification
```http
POST /notifications/send
Content-Type: application/json

{
  "userId": "user123",
  "title": "Booking Confirmed",
  "message": "Your booking has been confirmed",
  "priority": "medium",
  "actionUrl": "/bookings/456",
  "additionalData": {...}
}
```

#### Bulk Notifications
```http
POST /notifications/bulk
Content-Type: application/json

{
  "userIds": ["user1", "user2", "user3"],
  "title": "System Maintenance",
  "message": "Scheduled maintenance tonight",
  "priority": "high"
}
```

#### WebSocket Status
```http
GET /notifications/websocket/status
```
Returns current WebSocket connection statistics.

#### Connection Statistics
```http
GET /notifications/stats
```
Returns detailed connection and message statistics.

#### Broadcast Message
```http
POST /notifications/broadcast
Content-Type: application/json

{
  "title": "Campus Alert",
  "message": "Emergency notification to all users",
  "priority": "urgent"
}
```

#### Cleanup Connections
```http
POST /notifications/cleanup
Content-Type: application/json

{
  "timeoutMinutes": 30
}
```

### WebSocket API (Port 9092)

#### Connection
```
ws://localhost:9092/ws?userId=user123
```

#### Message Types

**Subscribe to Channel:**
```json
{
  "messageId": "uuid",
  "type": "subscribe",
  "payload": {
    "channels": ["booking-updates", "system-announcements"]
  }
}
```

**Heartbeat:**
```json
{
  "messageId": "uuid",
  "type": "heartbeat",
  "payload": {
    "timestamp": "2024-01-01T00:00:00Z"
  }
}
```

**Notification (Received):**
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
  "timestamp": "2024-01-01T00:00:00Z"
}
```

## 🔔 Event Processing

The service consumes events from multiple Kafka topics and triggers appropriate notifications:

### Booking Events
- `booking.created` → Booking confirmation notification
- `booking.updated` → Booking update notification
- `booking.cancelled` → Cancellation notification
- `booking.checked_in` → Check-in confirmation
- `booking.checked_out` → Check-out confirmation
- `booking.no_show` → No-show alert

### Waitlist Events
- `waitlist.added` → Waitlist confirmation
- `waitlist.removed` → Removal notification
- `waitlist.promoted` → Available spot notification

### User Events
- `user.created` → Welcome notification
- `user.updated` → Profile update confirmation

### Conflict & Resource Events
- `conflict.detected` → Conflict alert for administrators
- `resource.created/updated/deleted` → Resource change notifications

## 🔧 Configuration

### Service Configuration
```toml
[notification_service]
port = 9091                    # HTTP API port
websocket_port = 9092          # WebSocket port
```

### Kafka Configuration
```toml
[notification_service.kafka]
bootstrap_servers = ["localhost:9092"]
client_id = "notification-service"
group_id = "notification-group"
auto_offset_reset = "earliest"
enable_auto_commit = true
auto_commit_interval_ms = 1000
session_timeout_ms = 30000
heartbeat_interval_ms = 10000

# Topic names
booking_events = "booking-events"
waitlist_events = "waitlist-events"
conflict_events = "conflict-events"
notification_events = "notification-events"
user_events = "user-events"
resource_events = "resource-events"
```

### WebSocket Configuration
```toml
[notification_service.websocket]
max_frame_size = 65536
subprotocols = ["chat", "notifications"]
idle_timeout = 900
read_timeout = 60
write_timeout = 60
```

### Email Configuration (Optional)
```toml
[notification_service.email]
smtp_host = "smtp.gmail.com"
smtp_port = 587
username = "your-email@domain.com"
password = "your-app-password"
from_address = "noreply@campus.edu"
```

## 🔐 Security

- **Authentication**: User authentication should be handled before WebSocket connections
- **Message Validation**: All incoming messages are validated for structure and content
- **Rate Limiting**: Consider implementing rate limiting for notification sending
- **Channel Authorization**: Verify user permissions for channel subscriptions

## 📊 Monitoring

### Connection Statistics
- Total connections made
- Active connections
- Messages sent/received
- Message type breakdown
- Error counts

### Health Monitoring
- Kafka connection status
- WebSocket server status
- Active connection count
- Last error timestamp

### User Analytics
- Online user count
- User presence information
- Connection duration metrics
- Message delivery rates

## 🚨 Error Handling

- **Connection Failures**: Automatic cleanup and logging
- **Kafka Consumer Errors**: Retry mechanism with exponential backoff
- **Message Processing Errors**: Error logging with event details
- **WebSocket Errors**: Connection cleanup and user notification

## 🔄 Integration

### With Other Services
- **Booking Service**: Consumes booking lifecycle events
- **User Service**: Consumes user management events
- **Resource Service**: Consumes resource change events
- **Gateway Service**: Authentication integration for WebSocket connections

### Event Flow
1. Service publishes event to Kafka topic
2. Notification service consumes event
3. Event is processed and notification created
4. Notification is delivered via WebSocket (and other channels)
5. Delivery status is tracked and logged

## 🧪 Testing

### Testing WebSocket Connection
```javascript
const ws = new WebSocket('ws://localhost:9092/ws?userId=test-user');

ws.onopen = () => {
  console.log('Connected to notification service');
  
  // Subscribe to channels
  ws.send(JSON.stringify({
    messageId: 'test-1',
    type: 'subscribe',
    payload: {
      channels: ['booking-updates']
    }
  }));
};

ws.onmessage = (event) => {
  console.log('Received:', JSON.parse(event.data));
};
```

### Testing HTTP API
```bash
# Send notification
curl -X POST http://localhost:9091/notifications/send \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "test-user",
    "title": "Test Notification",
    "message": "This is a test notification"
  }'

# Check health
curl http://localhost:9091/notifications/health

# Get WebSocket status
curl http://localhost:9091/notifications/websocket/status
```

## 📈 Future Enhancements

- [ ] Email notification support
- [ ] SMS notification integration
- [ ] Push notification for mobile apps
- [ ] Notification templates and personalization
- [ ] Notification scheduling and batching
- [ ] User notification preferences
- [ ] Analytics dashboard
- [ ] Multi-language notification support
- [ ] Notification delivery guarantees
- [ ] Integration with external notification services

## 🤝 Contributing

1. Follow the established code patterns in other services
2. Add comprehensive tests for new features
3. Update documentation for API changes
4. Ensure error handling and logging
5. Test integration with other services

## 📄 License

This project is part of the Smart Campus Resource Management Platform.
