# Kafka Module

This module handles Kafka event consumption for the notification service. It processes events from various topics and triggers appropriate notifications.

## Features

- **Multi-topic Consumption**: Consumes events from booking, waitlist, conflict, notification, user, and resource topics
- **Event Processing**: Processes different event types and triggers appropriate notifications
- **Concurrent Processing**: Uses worker threads for parallel event consumption
- **Error Handling**: Robust error handling and logging for event processing
- **Type Safety**: Strongly typed event structures for reliable processing

## Event Types

### Booking Events
- `booking.created` - New booking confirmation
- `booking.updated` - Booking modification
- `booking.cancelled` - Booking cancellation
- `booking.checked_in` - User check-in
- `booking.checked_out` - User check-out
- `booking.no_show` - No-show detection

### Waitlist Events
- `waitlist.added` - Added to waitlist
- `waitlist.removed` - Removed from waitlist
- `waitlist.promoted` - Promoted from waitlist to booking

### Conflict Events
- `conflict.detected` - Booking conflict detected
- `conflict.resolved` - Conflict resolution

### User Events
- `user.created` - New user registration
- `user.updated` - User profile update

### Resource Events
- `resource.created` - New resource added
- `resource.updated` - Resource modification
- `resource.deleted` - Resource removal

## Configuration

Configure Kafka settings in `Config.toml`:

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
```

## Usage

```ballerina
import notification_service.kafka as kafka;

// Initialize consumers
check kafka:initializeKafkaConsumers();

// Start consuming events
check kafka:startBookingEventConsumer();
check kafka:startWaitlistEventConsumer();
check kafka:startConflictEventConsumer();
check kafka:startNotificationEventConsumer();
check kafka:startUserEventConsumer();
check kafka:startResourceEventConsumer();
```

## Dependencies

- `ballerinax/kafka` - Kafka client
- `ballerina/log` - Logging
- `ballerina/uuid` - UUID generation
- `ballerina/time` - Time utilities
- `notification_service.websocket` - WebSocket notifications
