#!/bin/sh
# ============================================================
# docker-entrypoint-aws.sh
# ECS/Fargate runtime entrypoint for Ballerina services
#
# Config injection strategy (in priority order):
#  1. Environment variables (set in ECS Task Definition)
#  2. Mounted Config.toml (from ECS Volume / Secrets Manager sidecar)
#  3. Bundled Config.toml.example (fallback / local test)
#
# All sensitive values (DB_PASSWORD, Kafka creds) come from
# ECS Task Definition "secrets" field → AWS Secrets Manager.
# ============================================================

set -e

echo "=== SmartCampus Ballerina Service Startup (AWS/ECS) ==="

CONFIG_FILE="/app/Config.toml"
EXAMPLE_FILE="/app/Config.toml.example"

# If no Config.toml was mounted, fall back to the example
if [ ! -f "$CONFIG_FILE" ] && [ -f "$EXAMPLE_FILE" ]; then
  echo "[INFO] No Config.toml found — using Config.toml.example as template"
  cp "$EXAMPLE_FILE" "$CONFIG_FILE"
fi

# ---- Patch DB host/port if env vars are set (Amazon RDS) ----
if [ -n "$DB_HOST" ]; then
  echo "[INFO] Patching DB host: $DB_HOST"
  sed -i "s|host = \".*\"|host = \"$DB_HOST\"|g" "$CONFIG_FILE"
fi

if [ -n "$DB_PORT" ]; then
  sed -i "s|port = [0-9]*|port = $DB_PORT|g" "$CONFIG_FILE"
fi

if [ -n "$DB_USER" ]; then
  sed -i "s|user = \".*\"|user = \"$DB_USER\"|g" "$CONFIG_FILE"
fi

if [ -n "$DB_PASSWORD" ]; then
  sed -i "s|password = \".*\"|password = \"$DB_PASSWORD\"|g" "$CONFIG_FILE"
fi

if [ -n "$DB_NAME" ]; then
  sed -i "s|database = \".*\"|database = \"$DB_NAME\"|g" "$CONFIG_FILE"
fi

# ---- Patch Kafka bootstrap servers (Amazon MSK) ----
if [ -n "$KAFKA_BOOTSTRAP_SERVERS" ]; then
  echo "[INFO] Patching Kafka bootstrap servers for MSK"
  # Build TOML array from comma-separated env var value
  # e.g. "b-1.xxx:9098,b-2.xxx:9098" → ["b-1.xxx:9098","b-2.xxx:9098"]
  TOML_KAFKA_ARRAY=$(echo "$KAFKA_BOOTSTRAP_SERVERS" | \
    sed 's/,/","/g' | sed 's/^/["/' | sed 's/$/"]/') 
  sed -i "s|bootstrap_servers = \[.*\]|bootstrap_servers = $TOML_KAFKA_ARRAY|g" "$CONFIG_FILE"
fi

echo "[INFO] Final bootstrap_servers in config:"
grep -i "bootstrap_servers" "$CONFIG_FILE" || echo "(not present in this service)"

echo "[INFO] Launching Ballerina service..."
exec java -jar /app/service.jar
