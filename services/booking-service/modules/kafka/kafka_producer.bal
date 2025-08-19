import ballerinax/kafka;
import ballerina/log;
import ballerina/uuid;
import ballerina/time;

# Kafka configuration
configurable string client_id = "booking-service";
configurable string acks = "all";
configurable int retries = 3;
configurable int batch_size = 16384;
configurable int linger_ms = 10;
configurable int buffer_memory = 33554432;

# Topic configuration
configurable string booking_events = "booking-events";
configurable string waitlist_events = "waitlist-events";
configurable string conflict_events = "conflict-events";
configurable string analytics_events = "analytics-events";
configurable string notification_events = "notification-events";

# Kafka producer configuration
final kafka:ProducerConfiguration & readonly producerConfig = {
    clientId: client_id,
    acks: "all",
    retryCount: retries,
    batchSize: batch_size,
    bufferMemory: buffer_memory
};

# Kafka producer client - Initialize when needed to avoid early connection
isolated kafka:Producer? kafkaProducerInstance = ();

# Get or create Kafka producer instance
#
# + return - Kafka producer instance or error
isolated function getKafkaProducer() returns kafka:Producer|error {
    lock {
        if kafkaProducerInstance is () {
            kafkaProducerInstance = check new kafka:Producer(bootstrap_servers,producerConfig);
            log:printInfo("Kafka producer initialized successfully");
        }
        return <kafka:Producer>kafkaProducerInstance;
    }
}

# Publish booking event to Kafka
#
# + eventType - Type of booking event
# + bookingId - Booking ID
# + userId - User ID
# + resourceId - Resource ID
# + eventData - Event data
# + return - Success or error
public isolated function publishBookingEvent(
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
            "version": "1.0.0",
            "environment": "development"
        }
    };

    kafka:Producer producer = check getKafkaProducer();
    kafka:AnydataProducerRecord producerRecord = {
        topic: booking_events,
        value: event.toString().toBytes(),
        key: bookingId
    };

    check producer->send(producerRecord);
    log:printInfo("📢 Published booking event: " + eventType + " for booking: " + bookingId);
}

# Publish waitlist event to Kafka
#
# + eventType - Type of waitlist event
# + waitlistId - Waitlist entry ID
# + userId - User ID
# + resourceId - Resource ID
# + eventData - Event data
# + return - Success or error
public isolated function publishWaitlistEvent(
    string eventType,
    string waitlistId,
    string userId,
    string resourceId,
    json eventData
) returns error? {
    
    json event = {
        "eventId": uuid:createType1AsString(),
        "eventType": eventType,
        "waitlistId": waitlistId,
        "userId": userId,
        "resourceId": resourceId,
        "timestamp": time:utcToString(time:utcNow()),
        "eventData": eventData,
        "metadata": {
            "service": "booking-service",
            "version": "1.0.0",
            "environment": "development"
        }
    };

    kafka:Producer producer = check getKafkaProducer();
    kafka:AnydataProducerRecord producerRecord = {
        topic: waitlist_events,
        value: event.toString().toBytes(),
        key: waitlistId
    };

    check producer->send(producerRecord);
    log:printInfo("📢 Published waitlist event: " + eventType + " for waitlist: " + waitlistId);
}

# Publish conflict event to Kafka
#
# + eventType - Type of conflict event
# + resourceId - Resource ID
# + conflictData - Conflict data
# + return - Success or error
public isolated function publishConflictEvent(
    string eventType,
    string resourceId,
    json conflictData
) returns error? {
    
    json event = {
        "eventId": uuid:createType1AsString(),
        "eventType": eventType,
        "resourceId": resourceId,
        "timestamp": time:utcToString(time:utcNow()),
        "eventData": conflictData,
        "metadata": {
            "service": "booking-service",
            "version": "1.0.0",
            "environment": "development"
        }
    };

    kafka:Producer producer = check getKafkaProducer();
    kafka:AnydataProducerRecord producerRecord = {
        topic: conflict_events,
        value: event.toString().toBytes(),
        key: resourceId
    };

    check producer->send(producerRecord);
    log:printInfo("📢 Published conflict event: " + eventType + " for resource: " + resourceId);
}

# Publish notification event to Kafka
#
# + eventType - Type of notification event
# + userId - User ID
# + notificationData - Notification data
# + return - Success or error
public isolated function publishNotificationEvent(
    string eventType,
    string userId,
    json notificationData
) returns error? {
    
    json event = {
        "eventId": uuid:createType1AsString(),
        "eventType": eventType,
        "userId": userId,
        "timestamp": time:utcToString(time:utcNow()),
        "eventData": notificationData,
        "metadata": {
            "service": "booking-service",
            "version": "1.0.0",
            "environment": "development"
        }
    };

    kafka:Producer producer = check getKafkaProducer();
    kafka:AnydataProducerRecord producerRecord = {
        topic: notification_events,
        value: event.toString().toBytes(),
        key: userId
    };

    check producer->send(producerRecord);
    log:printInfo("📢 Published notification event: " + eventType + " for user: " + userId);
}

# Publish analytics event to Kafka
#
# + metricType - Type of analytics metric
# + metricData - Metric data
# + return - Success or error
public isolated function publishAnalyticsEvent(
    string metricType,
    json metricData
) returns error? {
    
    json event = {
        "eventId": uuid:createType1AsString(),
        "eventType": "analytics." + metricType,
        "timestamp": time:utcToString(time:utcNow()),
        "eventData": metricData,
        "metadata": {
            "service": "booking-service",
            "version": "1.0.0",
            "environment": "development"
        }
    };

    kafka:Producer producer = check getKafkaProducer();
    kafka:AnydataProducerRecord producerRecord = {
        topic: analytics_events,
        value: event.toString().toBytes()
    };

    check producer->send(producerRecord);
    log:printInfo("📊 Published analytics event: " + metricType);
}

# Close Kafka producer
#
# + return - Success or error
public isolated function closeProducer() returns error? {
    lock {
        kafka:Producer? producer = kafkaProducerInstance;
        if producer is kafka:Producer {
            check producer->close();
            kafkaProducerInstance = ();
            log:printInfo("Kafka producer closed successfully");
        }
    }
}
