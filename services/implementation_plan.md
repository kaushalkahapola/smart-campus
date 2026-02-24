# Kafka Integration Implementation Plan

## Goal
Fully enable the Event-Driven Design by activating the Kafka producer in the `booking-service`. This involves fixing the missing dependency and configuration issues that currently prevent the existing implementation from working.

## Analysis
- **Current State**: 
    - `booking-service` has a `kafka` module (`modules/kafka`) with a full producer implementation (`kafka_producer.bal`).
    - `booking-service/Ballerina.toml` **missing** `ballerinax/kafka` dependency.
    - `modules/kafka/kafka_producer.bal` **missing** `bootstrap_servers` configuration variable definition, causing compilation errors.
    - There is a misleading empty file `booking-service/kafka_producer.bal` in the root.
- **Why it failed previously**: The service would fail to compile or run due to missing dependencies and config variables, making it appear "mocked" or broken.

## Proposed Changes

### 1. Fix Dependencies `booking-service/Ballerina.toml`
- Add `ballerinax/kafka` version `3.4.0` (compatible with distribution 2201.10.1).

### 2. Fix Producer Implementation `booking-service/modules/kafka/kafka_producer.bal`
- Add `configurable string[] bootstrap_servers = ["localhost:9092"];` to the configuration section.

### 3. Cleanup
- Delete the empty `booking-service/kafka_producer.bal`.

## Verification Plan

### Automated Verification
- We cannot run `bal build` directly in this environment (restricted).
- We will verify the file contents match the requirements.
- We will verify the `docker-compose.yml` allows `booking-service` to talk to `kafka`.

### Manual Verification Instructions
After changes:
1.  Run `docker-compose up -d --build booking-service`.
2.  Check logs: `docker-compose logs -f booking-service`.
3.  Look for "Kafka producer initialized successfully".
4.  Create a booking via API.
5.  Check `notification-service` logs for "Received booking created event".
