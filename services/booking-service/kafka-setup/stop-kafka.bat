@echo off
echo =================================================
echo         Stopping Kafka and Zookeeper
echo =================================================

echo 🛑 Stopping Kafka Server...
taskkill /f /im java.exe /fi "WINDOWTITLE eq Kafka Server*" 2>nul

echo 🛑 Stopping Zookeeper...
taskkill /f /im java.exe /fi "WINDOWTITLE eq Zookeeper*" 2>nul

echo ⏳ Waiting for processes to terminate...
timeout /t 5 /nobreak > nul

echo ✅ Kafka and Zookeeper stopped!

pause
