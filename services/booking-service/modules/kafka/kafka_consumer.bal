import ballerinax/kafka;
import ballerina/log;

# Kafka consumer configuration
configurable string[] bootstrap_servers = ["localhost:9092"];
configurable string consumer_group_id = "booking-service-consumer";

# Kafka consumer configuration
kafka:ConsumerConfiguration consumerConfig = {
    groupId: consumer_group_id,
    topics: [booking_events, waitlist_events, conflict_events, notification_events],
    offsetReset: kafka:OFFSET_RESET_EARLIEST,
    autoCommit: true
};

# Kafka event consumer service
service on new kafka:Listener(bootstrap_servers, consumerConfig) {

    # Process incoming Kafka messages
    #
    # + records - Array of consumer records
    # + return - Success or error
    remote function onConsumerRecord(kafka:BytesConsumerRecord[] records) returns error? {
        foreach kafka:BytesConsumerRecord rec in records {
            string valueStr = check string:fromBytes(rec.value);
            json|error event = valueStr.fromJsonString();
            if event is json {
                // Determine topic from event type pattern
                string eventType = check event.eventType;
                string topic = determineTopicFromEventType(eventType);
                error? processResult = processEvent(topic, event);
                if processResult is error {
                    log:printError("Failed to process event " + eventType + ": " + processResult.message());
                } else {
                    log:printInfo("✅ Successfully processed event: " + eventType);
                }
            } else {
                log:printError("Failed to parse event JSON from partition " + rec.offset.partition.toString() + ": " + event.message());
            }
        }
    }
}

# Determine topic from event type
#
# + eventType - Event type string
# + return - Topic name
function determineTopicFromEventType(string eventType) returns string {
    if eventType.startsWith("booking.") {
        return booking_events;
    } else if eventType.startsWith("waitlist.") {
        return waitlist_events;
    } else if eventType.startsWith("conflict.") {
        return conflict_events;
    } else if eventType.startsWith("notification.") || eventType.startsWith("analytics.") {
        return notification_events;
    } else {
        return "unknown";
    }
}

# Process individual events based on topic and event type
#
# + topic - Kafka topic
# + event - Event data
# + return - Success or error
function processEvent(string topic, json event) returns error? {
    string eventType = check event.eventType;
    
    if topic == booking_events {
        return processBookingEvent(eventType, event);
    } else if topic == waitlist_events {
        return processWaitlistEvent(eventType, event);
    } else if topic == conflict_events {
        return processConflictEvent(eventType, event);
    } else if topic == notification_events {
        return processNotificationEvent(eventType, event);
    } else {
        log:printInfo("Unknown topic: " + topic);
    }
    return;
}

# Process booking events
#
# + eventType - Type of booking event
# + event - Event data
# + return - Success or error
function processBookingEvent(string eventType, json event) returns error? {
    match eventType {
        "booking.created" => {
            log:printInfo("🎯 Processing booking created event");
            // TODO: Send confirmation email, update analytics
        }
        "booking.updated" => {
            log:printInfo("🎯 Processing booking updated event");
            // TODO: Send update notification
        }
        "booking.cancelled" => {
            log:printInfo("🎯 Processing booking cancelled event");
            // TODO: Send cancellation notification, process waitlist
        }
        "booking.confirmed" => {
            log:printInfo("🎯 Processing booking confirmed event");
            // TODO: Send confirmation notification
        }
        "booking.checkedin" => {
            log:printInfo("🎯 Processing booking check-in event");
            // TODO: Update resource status, analytics
        }
        "booking.checkedout" => {
            log:printInfo("🎯 Processing booking check-out event");
            // TODO: Update resource status, process feedback
        }
        _ => {
            log:printInfo("Unknown booking event type: " + eventType);
        }
    }
    return;
}

# Process waitlist events
#
# + eventType - Type of waitlist event
# + event - Event data
# + return - Success or error
function processWaitlistEvent(string eventType, json event) returns error? {
    match eventType {
        "waitlist.joined" => {
            log:printInfo("🎯 Processing waitlist joined event");
            // TODO: Send waitlist confirmation
        }
        "waitlist.promoted" => {
            log:printInfo("🎯 Processing waitlist promotion event");
            // TODO: Send promotion notification, create booking
        }
        "waitlist.expired" => {
            log:printInfo("🎯 Processing waitlist expired event");
            // TODO: Clean up expired entries
        }
        _ => {
            log:printInfo("Unknown waitlist event type: " + eventType);
        }
    }
    return;
}

# Process conflict events
#
# + eventType - Type of conflict event
# + event - Event data
# + return - Success or error
function processConflictEvent(string eventType, json event) returns error? {
    match eventType {
        "conflict.detected" => {
            log:printInfo("🎯 Processing conflict detected event");
            // TODO: Generate alternative suggestions
        }
        _ => {
            log:printInfo("Unknown conflict event type: " + eventType);
        }
    }
    return;
}

# Process notification events
#
# + eventType - Type of notification event
# + event - Event data
# + return - Success or error
function processNotificationEvent(string eventType, json event) returns error? {
    match eventType {
        "notification.booking_confirmation" => {
            log:printInfo("🎯 Processing booking confirmation notification");
            // TODO: Send email/SMS confirmation
        }
        "notification.booking_reminder" => {
            log:printInfo("🎯 Processing booking reminder notification");
            // TODO: Send reminder notification
        }
        "notification.waitlist_promotion" => {
            log:printInfo("🎯 Processing waitlist promotion notification");
            // TODO: Send promotion notification
        }
        _ => {
            log:printInfo("Unknown notification event type: " + eventType);
        }
    }
    return;
}
