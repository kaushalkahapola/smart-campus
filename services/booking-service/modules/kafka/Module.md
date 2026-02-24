# Kafka Integration Module

This module provides Kafka integration for the booking service, enabling real-time event streaming and notifications.

## Features

- **Event Publishing**: Publish booking, waitlist, conflict, and notification events
- **Message Serialization**: JSON-based event serialization
- **Reliable Delivery**: Configurable acknowledgments and retries
- **Event Schemas**: Structured event data with metadata

## Event Types

### Booking Events
- `booking.created` - New booking created
- `booking.updated` - Booking details modified
- `booking.confirmed` - Booking approved by admin
- `booking.cancelled` - Booking cancelled
- `booking.checkedin` - User checked into booking
- `booking.checkedout` - User checked out of booking
- `booking.noshow` - User didn't show up

### Waitlist Events
- `waitlist.joined` - User joined waitlist
- `waitlist.promoted` - User promoted from waitlist to booking
- `waitlist.expired` - Waitlist entry expired

### Conflict Events
- `conflict.detected` - Booking conflict detected
- `conflict.resolved` - Conflict resolved with alternatives

### Notification Events
- `notification.booking_confirmation` - Send booking confirmation
- `notification.booking_reminder` - Send booking reminder
- `notification.waitlist_promotion` - Send waitlist promotion notification

## Usage

```ballerina
import booking_service.kafka;

// Publish a booking created event
error? result = kafka:publishBookingEvent(
    "booking.created",
    bookingId,
    userId,
    resourceId,
    bookingData
);
```
