#!/bin/bash
# ============================================================
# create-topics-aws.sh
# Creates required Kafka topics on Amazon MSK
#
# USAGE:
#   export MSK_BOOTSTRAP="b-1.xxx.kafka.us-east-1.amazonaws.com:9092"
#   chmod +x create-topics-aws.sh
#   ./create-topics-aws.sh
#
# REQUIREMENTS:
#   - Kafka CLI tools installed (kafka-topics.sh in PATH)
#   - Run from EC2/bastion host inside the same VPC as MSK
#   - If MSK uses IAM auth, set MSK_BOOTSTRAP to port 9098 and
#     provide a client.properties file with SASL_IAM config
#
# For MSK with IAM auth, create client.properties:
#   security.protocol=SASL_SSL
#   sasl.mechanism=AWS_MSK_IAM
#   sasl.jaas.config=software.amazon.msk.auth.iam.IAMLoginModule required;
#   sasl.client.callback.handler.class=software.amazon.msk.auth.iam.IAMClientCallbackHandler
# ============================================================

set -e

BOOTSTRAP="${MSK_BOOTSTRAP:-localhost:9092}"
REPLICATION_FACTOR="${MSK_REPLICATION_FACTOR:-2}"   # Use 2 for multi-AZ MSK cluster
PARTITIONS="${MSK_PARTITIONS:-3}"
CLIENT_PROPS="${MSK_CLIENT_PROPS:-}"                 # Path to client.properties for IAM auth

echo "=== SmartCampus MSK Topic Creation ==="
echo "Bootstrap: $BOOTSTRAP"
echo "Replication factor: $REPLICATION_FACTOR"
echo "Partitions: $PARTITIONS"
echo ""

# Build command suffix for auth
AUTH_ARGS=""
if [ -n "$CLIENT_PROPS" ]; then
  AUTH_ARGS="--command-config $CLIENT_PROPS"
fi

create_topic() {
  local topic=$1
  local retention_ms=${2:-604800000}  # Default: 7 days

  echo "Creating topic: $topic"
  kafka-topics.sh \
    --bootstrap-server "$BOOTSTRAP" \
    --create \
    --if-not-exists \
    --topic "$topic" \
    --partitions "$PARTITIONS" \
    --replication-factor "$REPLICATION_FACTOR" \
    --config retention.ms="$retention_ms" \
    $AUTH_ARGS \
    && echo "  ✓ $topic created (or already exists)" \
    || echo "  ✗ Failed to create $topic"
}

# ---- Create all SmartCampus topics ----
create_topic "booking-events"        604800000   # 7 days
create_topic "waitlist-events"       604800000
create_topic "conflict-events"       604800000
create_topic "analytics-events"      2592000000  # 30 days (analytics retention)
create_topic "notification-events"   86400000    # 1 day (ephemeral)
create_topic "user-events"           604800000
create_topic "resource-events"       604800000
create_topic "email-events"          86400000    # 1 day

echo ""
echo "=== Topic creation complete. Listing all topics: ==="
kafka-topics.sh --bootstrap-server "$BOOTSTRAP" --list $AUTH_ARGS
