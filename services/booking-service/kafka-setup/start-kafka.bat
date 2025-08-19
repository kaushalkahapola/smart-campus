@echo off
echo =================================================
echo      Smart Campus Kafka Setup for Windows
echo =================================================

REM Check if Kafka directory exists
if not exist "kafka" (
    echo ❌ Kafka directory not found!
    echo Please extract your Kafka download to a 'kafka' folder in this directory
    echo Download from: https://kafka.apache.org/downloads
    pause
    exit /b 1
)

echo ✅ Kafka directory found

REM Set Kafka home
set KAFKA_HOME=%cd%\kafka
set PATH=%KAFKA_HOME%\bin\windows;%PATH%

echo 📂 KAFKA_HOME set to: %KAFKA_HOME%

REM Create logs directory if it doesn't exist
if not exist "logs" mkdir logs

echo 🚀 Starting Zookeeper...
start "Zookeeper" cmd /k "cd /d %KAFKA_HOME% && bin\windows\zookeeper-server-start.bat config\zookeeper.properties"

echo ⏳ Waiting for Zookeeper to start (10 seconds)...
timeout /t 10 /nobreak > nul

echo 🚀 Starting Kafka Server...
start "Kafka Server" cmd /k "cd /d %KAFKA_HOME% && bin\windows\kafka-server-start.bat config\server.properties"

echo ⏳ Waiting for Kafka Server to start (15 seconds)...
timeout /t 15 /nobreak > nul

echo ✅ Kafka and Zookeeper should now be running!
echo 📝 Next steps:
echo    1. Run 'create-topics.bat' to create required topics
echo    2. Run 'bal build' in the booking-service directory
echo    3. Run 'bal run' to start the booking service with Kafka

pause
