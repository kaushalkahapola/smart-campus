@echo off
setlocal enableextensions
echo =================================================
echo      Creating Kafka Topics for Campus Booking
echo =================================================

REM Resolve Kafka home relative to this script (robust even if run from elsewhere)
set "KAFKA_HOME=%~dp0kafka"
if not exist "%KAFKA_HOME%" (
	echo ERROR: Kafka directory not found at %KAFKA_HOME%
	echo Please ensure the 'kafka' folder exists beside this script.
	goto :end
)

set "KAFKA_TOPICS=%KAFKA_HOME%\bin\windows\kafka-topics.bat"
if not exist "%KAFKA_TOPICS%" (
	echo ERROR: kafka-topics.bat not found under %KAFKA_HOME%\bin\windows
	goto :end
)

echo Creating booking-events topic...
"%KAFKA_TOPICS%" --create --topic booking-events --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1

echo Creating waitlist-events topic...
"%KAFKA_TOPICS%" --create --topic waitlist-events --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1

echo Creating conflict-events topic...
"%KAFKA_TOPICS%" --create --topic conflict-events --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1

echo Creating analytics-events topic...
"%KAFKA_TOPICS%" --create --topic analytics-events --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1

echo Creating notification-events topic...
"%KAFKA_TOPICS%" --create --topic notification-events --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1

echo Listing all topics...
"%KAFKA_TOPICS%" --list --bootstrap-server localhost:9092

echo Done.

:end
endlocal
pause
