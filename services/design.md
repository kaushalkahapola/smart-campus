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
│              │   - Request Routing             │                │
│              │   - Rate Limiting               │                │
│              │   - Error Handling              │                │
│              └─────────────────────────────────┘                │
└─────────┬─────────┬─────────┬─────────┬─────────┬───────────────┘
          │         │         │         │         │
          ▼         ▼         ▼         ▼         ▼
┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│ User Service│ │Account Svc  │ │Transaction  │ │Analytics    │ │Notification │
│ (Port 9092) │ │(Port 9093)  │ │Svc(Port 9094│ │Svc(Port 9095│ │Svc(Port 9091│
│             │ │             │ │             │ │             │ │             │
│- Registration│ │- Account    │ │- Transfers  │ │- Spending   │ │- Email/SMS  │
│- Login/Auth │ │  Management │ │- History    │ │  Analysis   │ │- WebSocket  │
│- Profile    │ │- Balance    │ │- Validation │ │- Fraud      │ │- Kafka      │
│- JWT Tokens │ │- Bank APIs  │ │- Scheduling │ │  Detection  │ │  Consumer   │
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
│  • user-events        • transaction-events                     │
│  • account-events     • notification-events                    │
│  • fraud-alerts       • audit-events                           │
└─────────────────────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Data Layer                                 │
│                                                                 │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────┐ │
│  │   MySQL/PostgreSQL   │    Redis Cache    │  │  External   │ │
│  │                 │    │                 │    │  Bank APIs  │ │
│  │ • Users         │    │ • Sessions      │    │             │ │
│  │ • Accounts      │    │ • Tokens        │    │ • PSD2      │ │
│  │ • Transactions  │    │ • Rate Limits   │    │ • Account   │ │
│  │ • Notifications │    │ • Temp Data     │    │   Data      │ │
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

**Role**: User management and authentication

**Database Schema**:
```sql
CREATE TABLE users (
    id VARCHAR(100) PRIMARY KEY,
    username VARCHAR(50) UNIQUE,
    hashed_password VARCHAR(255),
    email VARCHAR(100) UNIQUE,
    role ENUM('user', 'admin'),
    is_verified BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT FALSE,
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
- User registration with email verification
- OAuth2 password grant flow for authentication
- JWT token generation (access + refresh tokens)
- Role-based access control (customer, admin, support)
- User profile management

### 3. Account Service (Port 9093)

**Role**: Bank account management and external bank integration

**Database Schema**:
```sql
CREATE TABLE accounts (
    id VARCHAR(100) PRIMARY KEY,
    user_id VARCHAR(100),
    account_number VARCHAR(50) UNIQUE,
    account_type ENUM('savings', 'checking', 'credit'),
    balance DECIMAL(15,2),
    currency VARCHAR(3) DEFAULT 'USD',
    status ENUM('active', 'frozen', 'closed'),
    bank_id VARCHAR(100),
    external_account_id VARCHAR(100),
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

**Key Features**:
- Create and manage **virtual demo accounts**
- **Mock balance inquiries** with realistic banking scenarios
- **Account status management** (demo freeze/unfreeze)
- **Simulated bank data** stored locally for demo purposes
- Multi-currency support for **international demo scenarios**

### 4. Transaction Service (Port 9094)

**Role**: Financial transaction processing and management

**Database Schema**:
```sql
CREATE TABLE transactions (
    id VARCHAR(100) PRIMARY KEY,
    from_account_id VARCHAR(100),
    to_account_id VARCHAR(100),
    amount DECIMAL(15,2),
    currency VARCHAR(3),
    transaction_type ENUM('transfer', 'payment', 'deposit', 'withdrawal'),
    status ENUM('pending', 'processing', 'completed', 'failed', 'cancelled'),
    reference_number VARCHAR(100) UNIQUE,
    description TEXT,
    scheduled_at TIMESTAMP,
    processed_at TIMESTAMP,
    created_at TIMESTAMP,
    FOREIGN KEY (from_account_id) REFERENCES accounts(id),
    FOREIGN KEY (to_account_id) REFERENCES accounts(id)
);
```

**Key Features**:
- **Virtual fund transfers** using demo currency/points
- **Realistic transaction processing** with mock validation
- Real-time transaction status tracking
- **Demo-friendly transaction history** with sample data
- Scheduled payments simulation
- Event emission to Kafka for **live demo notifications**

### 5. Analytics Service (Port 9095)

**Role**: Transaction analytics and insights

**Database Schema**:
```sql
CREATE TABLE analytics_summaries (
    id VARCHAR(100) PRIMARY KEY,
    user_id VARCHAR(100),
    period_type ENUM('daily', 'weekly', 'monthly', 'yearly'),
    period_start DATE,
    period_end DATE,
    total_income DECIMAL(15,2),
    total_expenses DECIMAL(15,2),
    transaction_count INT,
    category_breakdown JSON,
    created_at TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

**Key Features**:
- **Demo spending analysis** and categorization
- Income vs expense trends with **sample financial data**
- Monthly/yearly financial summaries for **presentation**
- **Simple pattern detection** for suspicious activity demo
- Real-time dashboard data for **live competition demo**
- Export capabilities (PDF/CSV) with **sample reports**

### 6. Notification Service (Port 9091)

**Role**: Multi-channel notification delivery

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
    type ENUM('email', 'sms', 'push', 'websocket'),
    channel ENUM('transaction', 'security', 'marketing', 'system'),
    subject VARCHAR(255),
    message TEXT,
    status ENUM('pending', 'sent', 'delivered', 'failed'),
    scheduled_at TIMESTAMP,
    sent_at TIMESTAMP,
    delivered_at TIMESTAMP,
    metadata JSON,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

**Key Features**:
- Email notifications (SMTP) for **demo email accounts**
- **WebSocket real-time notifications** for live presentation
- **Kafka event consumer** for demo event processing
- **Demo notification preferences** management
- **Competition-friendly messaging** (no SMS costs)

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
- **Asgardeo Integration**: Complete OAuth2 flow with identity provider
- **Role-based Access Control (RBAC)**: Roles stored in Asgardeo user profile
  - `customer`: Own data access only
  - `admin`: Full system access
  - `support`: Limited user data for support operations
- **Token Caching**: User info and M2M tokens cached for performance

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
