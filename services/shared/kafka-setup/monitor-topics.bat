@echo off
echo =================================================
echo      Kafka Consumer Test for Campus Booking
echo =================================================

REM Set Kafka home
set KAFKA_HOME=%cd%\kafka
set PATH=%KAFKA_HOME%\bin\windows;%PATH%

echo 🎯 Choose a topic to monitor:
echo 1. booking-events
echo 2. waitlist-events
echo 3. conflict-events
echo 4. notification-events
echo 5. All topics
set /p choice="Enter your choice (1-5): "

if "%choice%"=="1" (
    echo 👀 Monitoring booking-events...
    kafka-console-consumer.bat --topic booking-events --from-beginning --bootstrap-server localhost:9092
) else if "%choice%"=="2" (
    echo 👀 Monitoring waitlist-events...
    kafka-console-consumer.bat --topic waitlist-events --from-beginning --bootstrap-server localhost:9092
) else if "%choice%"=="3" (
    echo 👀 Monitoring conflict-events...
    kafka-console-consumer.bat --topic conflict-events --from-beginning --bootstrap-server localhost:9092
) else if "%choice%"=="4" (
    echo 👀 Monitoring notification-events...
    kafka-console-consumer.bat --topic notification-events --from-beginning --bootstrap-server localhost:9092
) else if "%choice%"=="5" (
    echo 👀 Starting multiple consumers for all topics...
    start "Booking Events" cmd /k "kafka-console-consumer.bat --topic booking-events --from-beginning --bootstrap-server localhost:9092"
    start "Waitlist Events" cmd /k "kafka-console-consumer.bat --topic waitlist-events --from-beginning --bootstrap-server localhost:9092"
    start "Conflict Events" cmd /k "kafka-console-consumer.bat --topic conflict-events --from-beginning --bootstrap-server localhost:9092"
    start "Notification Events" cmd /k "kafka-console-consumer.bat --topic notification-events --from-beginning --bootstrap-server localhost:9092"
    echo ✅ All consumers started in separate windows
) else (
    echo ❌ Invalid choice!
)

pause
