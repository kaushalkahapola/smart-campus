# Smart Campus Resource Management Platform - System Architecture Design

## Architecture Overview

The Smart Campus Resource Management Platform follows a microservices architecture pattern with **AI-powered event-driven communication**, implementing intelligent campus resource optimization using **Pinecone vector database** for machine learning recommendations. The system showcases **advanced Ballerina capabilities** while solving real campus resource allocation problems.

## System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    Client Applications                          │
│              (Web App, Mobile App, Third-party)                │
└─────────────────────┬───────────────────────────────────────────┘
                      │ HTTPS/WSS
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                  Gateway Service (Port 9090)                   │
│              ┌─────────────────────────────────┐                │
│              │     API Gateway & Router        │                │
│              │   - OAuth2 Token Validation     │                │
│              │   - Campus Role Authorization   │                │
│              │   - Request Routing             │                │
│              │   - Rate Limiting               │                │
│              │   - Error Handling              │                │
│              └─────────────────────────────────┘                │
└─────────┬─────────┬─────────┬─────────┬─────────┬───────────────┘
          │         │         │         │         │
          ▼         ▼         ▼         ▼         ▼
┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│ User Service│ │Resource Svc │ │Booking Svc  │ │AI Service   │ │Notification │
│ (Port 9092) │ │(Port 9093)  │ │(Port 9094)  │ │(Port 9096)  │ │Svc(Port 9091│
│             │ │             │ │             │ │             │ │             │
│- Campus     │ │- Resource   │ │- Smart      │ │- Pinecone   │ │- Email/SMS  │
│  Registration│ │  Management │ │  Booking    │ │  AI Recs    │ │- WebSocket  │
│- Profile    │ │- Availability│ │- Conflict   │ │- Usage      │ │- Kafka      │
│- JWT Tokens │ │- Features   │ │  Detection  │ │  Patterns   │ │  Consumer   │
│- Department │ │- Maintenance│ │- Waitlist   │ │- Predictions│ │- Campus     │
│  Management │ │- Multi-loc  │ │- Bulk Ops   │ │- Analytics  │ │  Alerts     │
└─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘
      │               │               │               │               │
      └───────────────┼───────────────┼───────────────┼───────────────┘
                      │               │               │
                      ▼               ▼               ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Apache Kafka Message Broker                 │
│                      (Event Streaming)                         │
│                                                                 │
│  Topics:                                                        │
│  • user-events        • booking-events                         │
│  • resource-events    • notification-events                    │
│  • ai-prediction      • maintenance-events                     │
│  • audit-events       • waitlist-events                        │
└─────────────────────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Data Layer                                 │
│                                                                 │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────┐ │
│  │   MySQL Campus DB   │    Redis Cache    │  │  Pinecone   │ │
│  │                 │    │                 │    │  Vector DB  │ │
│  │ • Users         │    │ • Sessions      │    │             │ │
│  │ • Resources     │    │ • Tokens        │    │ • AI        │ │
│  │ • Bookings      │    │ • Rate Limits   │    │   Patterns  │ │
│  │ • Notifications │    │ • Availability  │    │ • ML Models │ │
│  │ • Analytics     │    │ • User Prefs    │    │ • Vectors   │ │
│  └─────────────────┘    └─────────────────┘    └─────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                 Observability Stack                            │
│                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │   Prometheus    │  │     Grafana     │  │     Jaeger      │ │
│  │   (Metrics)     │  │  (Dashboard)    │  │   (Tracing)     │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## Service Architecture Details

### 1. Gateway Service (Port 9090)

**Role**: API Gateway and entry point for all client requests

**Components**:
- **Authentication Interceptor**: Validates OAuth2 JWT tokens
- **Request Router**: Routes requests to appropriate microservices  
- **Error Handler**: Centralized error handling and response formatting
- **Rate Limiter**: API rate limiting and throttling

**Current Implementation**:
```ballerina
service http:InterceptableService /api on new http:Listener(9090) {
    public function createInterceptors() returns http:Interceptor[] {
        return [new auth:AuthInterceptor(), new ErrorInterceptor()];
    }
    
    // Route to user service
    resource function post user/register(http:Caller caller, http:Request req)
    resource function post user/login(http:Caller caller, http:Request req)
    resource function get user/verify(http:Caller caller, http:Request req)
}
```

**Responsibilities**:
- Validate JWT tokens from Authorization header
- Extract user context (user ID, role) from tokens
- Forward requests to downstream services with user context headers
- Handle cross-cutting concerns (logging, monitoring, rate limiting)

### 2. User Service (Port 9092)

**Role**: Campus user management and authentication

**Database Schema**:
```sql
CREATE TABLE users (
    id VARCHAR(100) PRIMARY KEY,
    username VARCHAR(50) UNIQUE,
    email VARCHAR(100) UNIQUE,
    role ENUM('student', 'staff', 'admin') DEFAULT 'student',
    department VARCHAR(100),
    student_id VARCHAR(20),
    is_verified BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    last_login TIMESTAMP
);
```

**Current Implementation**:
```ballerina
service http:InterceptableService / on new http:Listener(9092) {
    // Authentication interceptor for internal service calls
    public function createInterceptors() returns http:Interceptor[] {
        return [new auth:AuthInterceptor(), new ErrorInterceptor()];
    }
}
```

**Key Features**:
- Campus user registration with university email verification
- OAuth2 authentication with Asgardeo integration
- JWT token generation and validation
- Role-based access control (student, staff, admin)
- Department-based user management
- Campus profile management with preferences

### 3. Resource Service (Port 9093)

**Role**: Campus resource management and availability tracking

**Database Schema**:
```sql
CREATE TABLE resources (
    id VARCHAR(100) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    type ENUM('lecture_hall', 'computer_lab', 'meeting_room', 'study_room', 'equipment', 'vehicle'),
    capacity INT DEFAULT 1,
    features JSON,
    location VARCHAR(255),
    building VARCHAR(100),
    floor VARCHAR(10),
    room_number VARCHAR(20),
    status ENUM('available', 'maintenance', 'unavailable', 'reserved'),
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);
```

**Key Features**:
- **Campus Resource Registration**: Lecture halls, labs, meeting rooms, equipment
- **Real-time Availability Tracking**: Live status updates for all resources
- **Feature Management**: AV equipment, accessibility, software capabilities
- **Multi-location Support**: Multiple buildings and campus locations
- **Maintenance Scheduling**: Track and schedule resource maintenance
- **Search and Filtering**: Advanced resource discovery with filters

### 4. Booking Service (Port 9094)

**Role**: Intelligent booking management and conflict resolution

**Database Schema**:
```sql
CREATE TABLE bookings (
    id VARCHAR(100) PRIMARY KEY,
    user_id VARCHAR(100),
    resource_id VARCHAR(100),
    title VARCHAR(255),
    description TEXT,
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    status ENUM('pending', 'confirmed', 'in_progress', 'completed', 'cancelled', 'no_show'),
    purpose VARCHAR(100),
    attendees_count INT,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (resource_id) REFERENCES resources(id)
);
```

**Key Features**:
- **Smart Booking Creation**: AI-powered conflict detection and resolution
- **Real-time Conflict Management**: Automatic detection and alternative suggestions
- **Recurring Bookings**: Schedule recurring events with pattern recognition
- **Waitlist Management**: Automated waitlist with priority-based allocation
- **Bulk Operations**: Administrative bulk booking capabilities
- **Event Integration**: Kafka event emission for booking lifecycle

### 5. AI Service (Port 9096) ⭐ **Innovation Highlight**

**Role**: AI-powered recommendations and predictive analytics

**Integration**:
- **Pinecone Vector Database**: Store and query booking behavior embeddings
- **Machine Learning Models**: Pattern recognition and demand prediction
- **Real-time Analytics**: Usage optimization and recommendation engine

**Key Features**:
- **Usage Pattern Analysis**: Vector embeddings for booking behavior analysis
- **Smart Recommendations**: AI-powered alternative resource and time suggestions
- **Predictive Analytics**: Forecast resource demand and optimize allocation
- **Anomaly Detection**: Identify unusual usage patterns and potential issues
- **Similarity Matching**: Find similar booking patterns and user preferences
- **Optimization Engine**: Continuous learning for resource utilization

### 6. Notification Service (Port 9091)

**Role**: Multi-channel notification delivery for campus events

**Current Implementation**:
```ballerina
service on new http:Listener(9091) {
    resource function post sendVerificationEmail(email:VerificationEmailRequest req) 
        returns VerificationEmailResponse | InternalServerErrorResponse {
        // Email sending logic
    }
}
```

**Database Schema**:
```sql
CREATE TABLE notifications (
    id VARCHAR(100) PRIMARY KEY,
    user_id VARCHAR(100),
    type ENUM('booking_confirmation', 'booking_reminder', 'booking_cancelled', 'maintenance_alert', 'system_announcement'),
    channel ENUM('email', 'websocket', 'push'),
    title VARCHAR(255),
    message TEXT,
    status ENUM('pending', 'sent', 'delivered', 'failed'),
    scheduled_at TIMESTAMP,
    sent_at TIMESTAMP,
    booking_id VARCHAR(100),
    metadata JSON,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (booking_id) REFERENCES bookings(id)
);
```

**Key Features**:
- **Campus Email Notifications**: Booking confirmations and reminders
- **WebSocket Real-time Updates**: Live booking status for campus users
- **Kafka Event Consumer**: Campus event processing and notification triggers
- **Campus Notification Preferences**: Student/staff notification management
- **Admin Alert System**: System-wide notifications for campus administrators

### Security Architecture

### Authentication Flow (Asgardeo Integration)
```
1. User login → Asgardeo OAuth2 authentication
2. Asgardeo returns JWT access token with user claims and roles
3. Client includes JWT in Authorization header
4. Gateway validates JWT via Asgardeo introspection endpoint
5. Gateway extracts user context (ID, username, roles) from user info
6. Gateway forwards request with user headers to services
7. Gateway generates M2M token for service-to-service communication
```

### Current Implementation Status
- ✅ **Token Validation**: JWT token introspection with Asgardeo
- ✅ **User Info Caching**: Cached user information with 10-minute expiry
- ✅ **M2M Token Management**: Cached M2M tokens with automatic refresh
- ✅ **Public Endpoint Filtering**: Skip auth for registration/login/verify
- ❌ **Role-Based Authorization**: Role extraction and validation needed

### Authorization Model
- **Token-based**: JWT tokens validated against Asgardeo
- **Asgardeo Integration**: Complete OAuth2 flow with university identity provider
- **Role-based Access Control (RBAC)**: Campus roles stored in Asgardeo user groups
  - `student`: Own bookings and resource viewing access
  - `staff`: Department resource management and student booking oversight
  - `admin`: Full campus system access and administration
- **Token Caching**: User info and M2M tokens cached for performance
- **M2M Authentication**: Service-to-service communication via M2M tokens

### Security Headers
```
X-User-Id: Extracted from Asgardeo user info (sub claim)
X-User-Role: User's role from Asgardeo user profile
X-Username: Username from Asgardeo user info
Authorization: Bearer token for service-to-service calls (M2M)
```

### Asgardeo Configuration
```toml
[gateway_service.auth]
clientId = "NffMwG6ChBwpfOu8feWsp_88qVMa"           # Client application
clientSecret = "C8VRc_sIGX_8sDbzjC3KWf24Ci955rtKMdKFkfQaldYa"
M2MClientId = "H4U8YLSGBrjPQYX3TBiCaGWZ_PAa"        # M2M application  
M2MClientSecret = "f4IExZ8uDReDfM5zCpf1TRlJs31AhXffXBOsUQx3CRsa"
authProviderURL = "https://api.asgardeo.io/t/kaushalorg2"
```

## Data Flow Architecture

### 1. Synchronous Request-Response Flow
```
Client → Gateway → Service → Database → Response
```

### 2. Asynchronous Event-Driven Flow
```
Service → Kafka Topic → Notification Service → External Systems
```

### 3. Event Topics
- `user-events`: Registration, login, profile updates
- `account-events`: Account creation, status changes
- `transaction-events`: Transaction completion, failures
- `notification-events`: Notification delivery status
- `fraud-alerts`: Suspicious activity detection
- `audit-events`: Security and compliance events

## Integration Architecture

### External Bank Integration (Demo Mode)
- **Mock PSD2 APIs**: Simulated banking responses with local data
- **Demo OAuth2 Flow**: Simulate bank authentication without real banks
- **Virtual Account Aggregation**: Mock external account data sync
- **Simulated Transfer Processing**: Demo external bank transfers
- **Realistic Error Scenarios**: Handle mock bank API failures for demo
- **Competition-Safe Implementation**: No real banking integrations required

### Message Broker Integration
- **Apache Kafka**: Event streaming and async communication
- **Topic Partitioning**: Scalable message distribution
- **Consumer Groups**: Parallel message processing
- **Dead Letter Queues**: Failed message handling

## Deployment Architecture

### Service Discovery
- **Configuration-based**: Service URLs in config files
- **Health Checks**: Regular health status monitoring
- **Load Balancing**: Round-robin or weighted distribution

### Scalability Patterns
- **Horizontal Scaling**: Multiple service instances
- **Database Sharding**: User-based data partitioning
- **Caching Strategy**: Redis for session and frequently accessed data
- **Connection Pooling**: Database connection optimization

## Monitoring and Observability

### Metrics Collection
- **Ballerina Observe**: Built-in observability features
- **Prometheus**: Metrics collection and storage
- **Grafana**: Visualization and alerting dashboards

### Distributed Tracing
- **Jaeger**: Request tracing across microservices
- **Correlation IDs**: Request tracking across services
- **Span Propagation**: Context propagation between services

### Logging Strategy
- **Structured Logging**: JSON-formatted logs
- **Centralized Logging**: Aggregated log collection
- **Log Levels**: DEBUG, INFO, WARN, ERROR, FATAL
- **Correlation IDs**: Request tracking across services

## Configuration Management

### Environment-Specific Configurations
- **Config.toml**: Service-specific configurations
- **Environment Variables**: Runtime configuration override
- **Secret Management**: Secure credential storage

### Configuration Structure
```toml
[database]
host = "localhost"
port = 3306
username = "finmate_user"
password = "secure_password"
database = "finmate"

[kafka]
bootstrapServers = "localhost:9092"
topics = ["user-events", "transaction-events"]

[security]
jwtSecret = "jwt_secret_key"
tokenExpiry = 3600
refreshTokenExpiry = 86400
```
