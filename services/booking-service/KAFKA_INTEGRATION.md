# Kafka Integration Guide for Booking Service

## Overview

This guide provides implementation details for integrating Apache Kafka with the booking service to enable real-time event streaming and notifications.

## Event-Driven Architecture

The booking service publishes events for key lifecycle changes:

### Event Types

#### Booking Events
- `booking.created` - When a new booking is created
- `booking.updated` - When booking details are modified
- `booking.cancelled` - When a booking is cancelled
- `booking.confirmed` - When a booking is approved by admin
- `booking.checkedin` - When user checks into booking
- `booking.checkedout` - When user checks out of booking
- `booking.noshow` - When user doesn't show up for booking

#### Waitlist Events
- `waitlist.joined` - When user joins waitlist
- `waitlist.promoted` - When user is promoted from waitlist to booking
- `waitlist.expired` - When waitlist entry expires

#### System Events
- `conflict.detected` - When booking conflicts are detected
- `resource.unavailable` - When resource becomes unavailable

## Kafka Topics

### Topic Structure
```
booking-events          # All booking lifecycle events
waitlist-events         # Waitlist management events
conflict-events         # Conflict detection and resolution
analytics-events        # Usage analytics and patterns
notification-events     # Trigger notifications to users
```

## Event Schema

### Booking Event Schema
```json
{
  "eventId": "string",
  "eventType": "booking.created",
  "bookingId": "string", 
  "userId": "string",
  "resourceId": "string",
  "timestamp": "2025-08-19T10:00:00Z",
  "eventData": {
    "id": "booking-123",
    "title": "Team Meeting",
    "status": "confirmed", 
    "startTime": "2025-08-19T14:00:00Z",
    "endTime": "2025-08-19T16:00:00Z",
    "attendeesCount": 5
  },
  "metadata": {
    "service": "booking-service",
    "version": "1.0.0",
    "correlationId": "req-456"
  }
}
```

### Waitlist Event Schema
```json
{
  "eventId": "string",
  "eventType": "waitlist.joined",
  "waitlistId": "string",
  "userId": "string", 
  "resourceId": "string",
  "timestamp": "2025-08-19T10:00:00Z",
  "eventData": {
    "priority": 100,
    "position": 3,
    "desiredStartTime": "2025-08-19T14:00:00Z",
    "desiredEndTime": "2025-08-19T16:00:00Z"
  },
  "metadata": {
    "service": "booking-service",
    "version": "1.0.0"
  }
}
```

## Implementation Steps

### 1. Add Kafka Dependencies

Add to `Dependencies.toml`:
```toml
[[dependency]]
org = "ballerinax"
name = "kafka"
version = "3.6.0"
```

### 2. Kafka Configuration

Add to `Config.toml`:
```toml
[booking_service.kafka]
bootstrap_servers = ["localhost:9092"]
client_id = "booking-service"
acks = "all"
retries = 3
batch_size = 16384
linger_ms = 10
buffer_memory = 33554432

[booking_service.kafka.topics]
booking_events = "booking-events"
waitlist_events = "waitlist-events"
conflict_events = "conflict-events"
```

### 3. Kafka Producer Implementation

Create `modules/kafka/kafka_producer.bal`:
```ballerina
import ballerinax/kafka;
import ballerina/log;
import ballerina/uuid;

configurable string bootstrapServers = "localhost:9092";
configurable string clientId = "booking-service";

# Kafka producer client
final kafka:Producer kafkaProducer = check new (bootstrapServers, {
    clientId: clientId,
    acks: "all",
    retryCount: 3,
    batchSize: 16384,
    lingerMs: 10,
    bufferMemory: 33554432
});

# Publish booking event
public function publishBookingEvent(
    string eventType,
    string bookingId, 
    string userId,
    string resourceId,
    json eventData
) returns error? {
    
    json event = {
        "eventId": uuid:createType1AsString(),
        "eventType": eventType,
        "bookingId": bookingId,
        "userId": userId,
        "resourceId": resourceId,
        "timestamp": time:utcToString(time:utcNow()),
        "eventData": eventData,
        "metadata": {
            "service": "booking-service",
            "version": "1.0.0"
        }
    };

    kafka:ProducerRecord record = {
        topic: "booking-events",
        value: event.toString(),
        key: bookingId
    };

    check kafkaProducer->send(record);
    log:printInfo("Published booking event: " + eventType);
}
```

### 4. Event Publishing Integration

Update service endpoints to publish events:

```ballerina
# In booking creation endpoint
int|error result = db:createBooking(bookingRecord);
if result is error {
    return <InternalServerErrorResponse>{...};
}

# Publish event
error? eventResult = publishBookingEvent(
    "booking.created",
    bookingRecord.id,
    userId,
    req.resourceId,
    {
        "id": bookingRecord.id,
        "title": bookingRecord.title,
        "status": bookingRecord.status,
        "startTime": formatDateTime(startTime),
        "endTime": formatDateTime(endTime)
    }
);
```

### 5. Kafka Consumer Implementation

Create `modules/kafka/kafka_consumer.bal`:
```ballerina
import ballerinax/kafka;
import ballerina/log;

# Kafka consumer for processing events
service kafka:Service on new kafka:Listener(bootstrapServers, {
    groupId: "booking-service-consumer",
    topics: ["booking-events", "waitlist-events"]
}) {

    remote function onConsumerRecord(kafka:ConsumerRecord[] records) returns error? {
        foreach kafka:ConsumerRecord rec in records {
            json|error event = rec.value.fromJsonString();
            if event is json {
                error? processResult = processBookingEvent(event);
                if processResult is error {
                    log:printError("Failed to process event: " + processResult.message());
                }
            }
        }
    }
}

function processBookingEvent(json event) returns error? {
    string eventType = check event.eventType;
    
    match eventType {
        "booking.created" => {
            // Process booking creation
            // e.g., Send notifications, update analytics
        }
        "waitlist.promoted" => {
            // Process waitlist promotion
            // e.g., Send notification to user
        }
        _ => {
            log:printInfo("Unknown event type: " + eventType);
        }
    }
}
```

## Event Flows

### Booking Creation Flow
1. User creates booking → POST /bookings
2. Service validates and creates booking in database
3. **Event Published**: `booking.created` to `booking-events` topic
4. Notification service consumes event → sends email confirmation
5. Analytics service consumes event → updates usage metrics

### Waitlist Management Flow
1. User joins waitlist → POST /waitlist/{resourceId}
2. Service adds to waitlist with priority
3. **Event Published**: `waitlist.joined` to `waitlist-events` topic
4. When booking cancelled → `booking.cancelled` event published
5. Waitlist service consumes event → promotes next user in queue
6. **Event Published**: `waitlist.promoted` to `waitlist-events` topic
7. Notification service sends promotion notification

### Conflict Detection Flow
1. Booking request conflicts with existing booking
2. **Event Published**: `conflict.detected` to `conflict-events` topic
3. AI service consumes event → suggests alternative resources
4. Response includes conflict details and alternatives

## Integration Benefits

### Real-time Notifications
- Instant email/SMS notifications on booking status changes
- Push notifications for mobile apps
- Slack/Teams integration for staff notifications

### Analytics & Insights
- Real-time booking metrics and dashboards
- Usage pattern analysis for resource optimization
- Predictive analytics for demand forecasting

### System Integration
- ERP system integration for billing and reporting
- Calendar system synchronization
- Maintenance management system integration

### Audit & Compliance
- Complete audit trail of all booking operations
- Compliance reporting for institutional requirements
- Data lineage tracking for analytics

## Configuration for Your Environment

To enable Kafka integration in your environment, you'll need:

1. **Kafka Cluster**: Running Apache Kafka instance
2. **Topic Creation**: Create the required topics with appropriate partitions
3. **Security**: Configure SASL/SSL if required
4. **Monitoring**: Set up Kafka monitoring (Kafka Manager, Kafdrop, etc.)

### Example Docker Compose for Local Development

```yaml
version: '3.8'
services:
  zookeeper:
    image: confluentinc/cp-zookeeper:7.4.0
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181

  kafka:
    image: confluentinc/cp-kafka:7.4.0
    depends_on:
      - zookeeper
    ports:
      - "9092:9092"
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: 'zookeeper:2181'
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://localhost:9092
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
```

Let me know if you need help with:
- Setting up the Kafka cluster
- Implementing specific event handlers
- Configuring security and authentication
- Performance tuning and monitoring
- Integration with other services
