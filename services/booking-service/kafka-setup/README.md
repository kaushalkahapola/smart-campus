# Kafka Setup Guide for Windows - Smart Campus Booking System

## Prerequisites

1. **Java 8+** installed and available in PATH
2. **Downloaded Kafka** from https://kafka.apache.org/downloads
3. **Ballerina** installed for running the booking service

## Step-by-Step Setup

### 1. Download and Extract Kafka

1. Go to https://kafka.apache.org/downloads
2. Download the latest Kafka binary (e.g., `kafka_2.13-3.6.0.tgz`)
3. Extract it to your desired location (e.g., `C:\kafka`)

### 2. Setup Kafka in Your Project

1. Navigate to the booking service Kafka setup directory:
   ```cmd
   cd f:\finmate\services\booking-service\kafka-setup
   ```

2. Create a `kafka` folder and copy your extracted Kafka files:
   ```cmd
   mkdir kafka
   xcopy "C:\path\to\your\extracted\kafka" kafka\ /E /I
   ```

   Or create a symbolic link:
   ```cmd
   mklink /D kafka "C:\path\to\your\extracted\kafka"
   ```

### 3. Start Kafka Services

1. **Start Kafka and Zookeeper**:
   ```cmd
   start-kafka.bat
   ```
   This will:
   - Start Zookeeper on port 2181
   - Start Kafka Server on port 9092
   - Open separate command windows for each service

2. **Create Required Topics**:
   ```cmd
   create-topics.bat
   ```
   This creates all necessary topics:
   - `booking-events` - Booking lifecycle events
   - `waitlist-events` - Waitlist management events
   - `conflict-events` - Booking conflict events
   - `analytics-events` - Usage analytics events
   - `notification-events` - User notification events

### 4. Test Kafka Integration

1. **Monitor Topics** (Optional):
   ```cmd
   monitor-topics.bat
   ```
   Choose which topics to monitor and see events in real-time.

2. **Build and Run Booking Service**:
   ```cmd
   cd f:\finmate\services\booking-service
   bal build
   bal run
   ```

### 5. Test Event Publishing

Create a booking to test Kafka integration:

```bash
curl -X POST http://localhost:9094/bookings \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "X-Username: test.user" \
  -d '{
    "resourceId": "res_001",
    "title": "Test Meeting",
    "startTime": "2025-08-20T10:00:00Z",
    "endTime": "2025-08-20T12:00:00Z",
    "attendeesCount": 5
  }'
```

You should see Kafka events being published in the console!

## Troubleshooting

### Issue: "Java not found"
**Solution**: Ensure Java is installed and in your PATH:
```cmd
java -version
```
If not found, add Java to your PATH or set JAVA_HOME.

### Issue: "Port 9092 already in use"
**Solution**: Stop existing Kafka processes:
```cmd
stop-kafka.bat
```
Wait a few seconds, then restart.

### Issue: "Topic already exists"
**Solution**: This is normal if you've run the setup before. You can delete topics if needed:
```cmd
kafka-topics.bat --delete --topic booking-events --bootstrap-server localhost:9092
```

### Issue: "Connection refused"
**Solution**: 
1. Ensure Zookeeper is running first
2. Wait at least 10 seconds between starting Zookeeper and Kafka
3. Check Windows Firewall is not blocking ports 2181 and 9092

## Event Schema Examples

### Booking Created Event
```json
{
  "eventId": "uuid-123",
  "eventType": "booking.created",
  "bookingId": "booking-456",
  "userId": "user-789",
  "resourceId": "res_001",
  "timestamp": "2025-08-19T10:00:00Z",
  "eventData": {
    "title": "Team Meeting",
    "status": "confirmed",
    "startTime": "2025-08-20T14:00:00Z",
    "endTime": "2025-08-20T16:00:00Z",
    "attendeesCount": 5
  },
  "metadata": {
    "service": "booking-service",
    "version": "1.0.0",
    "environment": "development"
  }
}
```

### Waitlist Joined Event
```json
{
  "eventId": "uuid-456",
  "eventType": "waitlist.joined",
  "waitlistId": "waitlist-789",
  "userId": "user-123",
  "resourceId": "res_001",
  "timestamp": "2025-08-19T10:05:00Z",
  "eventData": {
    "priority": 100,
    "preferredStart": "2025-08-20T14:00:00Z",
    "preferredEnd": "2025-08-20T16:00:00Z",
    "autoBook": true
  },
  "metadata": {
    "service": "booking-service",
    "version": "1.0.0",
    "environment": "development"
  }
}
```

## Architecture Benefits

With Kafka integration, your campus booking system now supports:

### ✅ **Real-time Notifications**
- Instant email/SMS when bookings are confirmed
- Push notifications for mobile apps
- Slack/Teams integration for staff

### ✅ **Event-Driven Analytics**
- Real-time booking metrics
- Usage pattern analysis
- Demand forecasting

### ✅ **System Integration**
- ERP system integration
- Calendar synchronization
- Maintenance management

### ✅ **Audit Trail**
- Complete event history
- Compliance reporting
- Data lineage tracking

### ✅ **Scalability**
- Horizontal scaling with partitions
- Load balancing across consumers
- Fault tolerance

## Next Steps

1. **Notification Service**: Create a consumer service for sending notifications
2. **Analytics Service**: Create a consumer for real-time analytics
3. **Mobile Integration**: Use events for mobile push notifications
4. **AI Integration**: Feed events to AI service for pattern analysis

## Production Considerations

For production deployment:

1. **Security**: Enable SASL/SSL authentication
2. **Clustering**: Set up multi-broker Kafka cluster
3. **Monitoring**: Use Kafka Manager or Confluent Control Center
4. **Backup**: Configure topic replication and backups
5. **Performance**: Tune batch sizes, compression, and partitions

Your Smart Campus Booking System is now event-driven and ready to scale! 🚀
