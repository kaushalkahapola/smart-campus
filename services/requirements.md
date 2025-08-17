# Smart Campus Resource Management Platform
## AI-Powered Resource Optimization with Real-time Analytics

## Project Overview

**Project Name:** Smart Campus Resource Management Platform **[Competition Demo]**  
**Goal:** Build an intelligent campus resource management system using Ballerina and AI/ML to optimize resource allocation, predict usage patterns, and provide smart recommendations for students and administrators.  
**Tech Focus:** Microservices architecture, Asgardeo RBAC, Kafka event streaming, Pinecone AI integration, WebSocket real-time updates, and Ballerina observability.

## Functional Requirements

### 1. User Management & Authentication
- **Student/Staff Registration**: Register campus users with university email verification (via Asgardeo)
- **Role-Based Login**: OAuth2-based authentication with student/staff/admin roles (Asgardeo integration)
- **Profile Management**: View and update campus profiles with preferences
- **Advanced RBAC**: Support for student, staff, and admin roles with Asgardeo group mapping
- **Campus Email Verification**: Verify university email addresses during registration
- **Token Management**: JWT token validation, caching, and M2M token generation
- **Asgardeo Integration**: Complete OAuth2 flow with university identity provider

### 2. Resource Management
- **Resource Registration**: Register lecture halls, computer labs, meeting rooms, equipment
- **Resource Discovery**: Search and filter resources by type, capacity, features, availability
- **Real-time Availability**: Live status updates for all campus resources
- **Resource Features**: Track AV equipment, accessibility, software availability, capacity
- **Maintenance Tracking**: Schedule and track resource maintenance with AI predictions
- **Multi-campus Support**: Support for multiple campus locations and buildings

### 3. Smart Booking System
- **Intelligent Booking**: Create bookings with AI-powered conflict detection and resolution
- **Real-time Conflict Management**: Automatic detection and alternative suggestions
- **Recurring Bookings**: Schedule recurring events with pattern recognition
- **Waitlist Management**: Automated waitlist with priority-based allocation
- **Bulk Operations**: Administrative bulk booking capabilities
- **Mobile-first Booking**: Optimized mobile booking experience

### 4. AI-Powered Intelligence ⭐ **Innovation Highlight**
- **Usage Pattern Analysis**: Pinecone vector embeddings for booking behavior analysis
- **Smart Recommendations**: AI-powered alternative resource and time slot suggestions
- **Predictive Analytics**: Forecast resource demand and optimize allocation
- **Anomaly Detection**: Identify unusual usage patterns and potential issues
- **Similarity Matching**: Find similar booking patterns and user preferences
- **Optimization Engine**: Continuous learning for resource utilization optimization

### 5. Notification & Communication System
- **Real-time Notifications**: WebSocket-based live booking updates
- **Email Notifications**: Booking confirmations and reminders via campus email
- **Mobile Push**: Native mobile app push notifications
- **Admin Alerts**: System-wide notifications for administrators
- **Integration Ready**: Slack/Teams integration for administrative workflows
- **Event-Driven Messaging**: Kafka-based notification triggers

### 6. Analytics & Insights Dashboard
- **Real-time Utilization**: Live resource usage monitoring and analytics
- **Usage Trends**: Historical analysis and pattern identification
- **Efficiency Scoring**: Resource and user efficiency metrics
- **Predictive Insights**: AI-powered demand forecasting and recommendations
- **Cost Optimization**: Analysis of resource allocation and cost savings
- **Executive Reporting**: High-level dashboards for campus administration

### 7. API Gateway & Routing
- **Centralized Entry Point**: Single API gateway for all campus services
- **Advanced RBAC**: Role-based routing with Asgardeo group claims extraction
- **Rate Limiting**: Per-role API rate limiting (student: 100/min, admin: 1000/min)
- **Request Validation**: Comprehensive input validation and sanitization
- **Error Handling**: Centralized error handling with user-friendly responses
- **Load Balancing**: Intelligent service discovery and load balancing

## Non-Functional Requirements

### 1. Security
- **OAuth2 Implementation**: Asgardeo-based secure token authentication with university integration
- **Advanced RBAC**: Role-based authorization with Asgardeo group claims (student, staff, admin)
- **JWT Token Management**: Access token validation with caching and M2M token generation
- **Data Protection**: Encrypt sensitive campus data at rest and in transit
- **HTTPS/TLS**: All communications over HTTPS for campus security compliance
- **Input Validation**: Comprehensive validation for all campus resource data
- **Audit Logging**: Complete audit trail for all booking and resource activities
- **Token Caching**: Secure token caching with role-based expiration management

### 2. Performance
- **Response Time**: API responses under 1 second for real-time booking
- **Throughput**: Handle 5000+ concurrent campus users during peak hours
- **Scalability**: Horizontal scaling capability for multiple campuses
- **AI Performance**: Sub-second AI recommendations via Pinecone integration
- **Real-time Updates**: WebSocket connections for live resource status
- **Caching Strategy**: Multi-layer caching for resource availability and user preferences

### 3. Reliability
- **High Availability**: 99.9% uptime target for critical campus operations
- **Fault Tolerance**: Graceful degradation when AI or external services fail
- **Booking Integrity**: ACID compliance for all booking transactions
- **Conflict Resolution**: Robust conflict detection and automatic resolution
- **Data Consistency**: Ensure booking data consistency across all services
- **Disaster Recovery**: Automated backup for critical campus resource data

### 4. Observability
- **Distributed Tracing**: Request tracing across all microservices with correlation IDs
- **AI Metrics**: Track AI recommendation accuracy and performance
- **Business Metrics**: Resource utilization, booking success rates, user satisfaction
- **Real-time Monitoring**: Live dashboards for system health and campus operations
- **Alerting**: Automated alerts for system issues and resource conflicts
- **Usage Analytics**: Comprehensive analytics for campus resource optimization

### 5. Integration (Campus Ecosystem)
- **University Systems**: Integration-ready for existing campus management systems
- **AI/ML Platform**: Pinecone vector database for intelligent recommendations
- **Message Queuing**: Kafka for event-driven architecture and real-time updates
- **Campus Database**: MySQL for resource and booking data with optimized queries
- **Email Integration**: SMTP integration with university email systems
- **Mobile Ready**: WebSocket and REST APIs optimized for mobile applications

## Technical Requirements

### 1. Technology Stack (Campus-Optimized)
- **Primary Language**: Ballerina
- **Database**: MySQL (with campus resource and booking data)
- **AI/ML Platform**: Pinecone (vector database for AI recommendations)
- **Message Broker**: Apache Kafka (for real-time event streaming)
- **Authentication**: Asgardeo OAuth2/JWT with university integration
- **API Documentation**: OpenAPI/Swagger for campus developers
- **Testing**: Ballerina test framework with comprehensive coverage
- **Monitoring**: Built-in Ballerina observability with custom metrics

### 2. Ballerina Modules
- `ballerina/http` - HTTP services, clients, and WebSocket connections
- `ballerina/sql` - Database operations for campus resources and bookings
- `ballerina/kafka` - Event streaming for real-time updates
- `ballerina/websocket` - Real-time communication for live booking updates
- `ballerina/auth` - Authentication and authorization with Asgardeo
- `ballerina/jwt` - JWT token handling and validation
- `ballerina/time` - Scheduling operations and time-based analytics
- `ballerina/config` - Configuration management for campus environments
- `ballerina/observe` - Built-in observability and metrics collection
- `ballerina/log` - Structured logging with correlation IDs
- `ballerina/uuid` - UUID generation for bookings and resources
- `ballerina/graphql` - GraphQL API for complex resource queries

### 3. Service Ports
- Gateway Service: 9090
- User Service: 9092
- Resource Service: 9093
- Booking Service: 9094
- Notification Service: 9091
- Analytics Service: 9095
- AI Service: 9096

### 4. Data Models

#### User Roles
- **student**: Regular campus user (own bookings and basic resource access)
- **staff**: Faculty/staff member (department resources and advanced booking)
- **admin**: Campus administrator (full system access and management)

#### Core Entities
- **User**: id, email, role, department, preferences, verification_status
- **Resource**: id, name, type, capacity, features, location, availability
- **Booking**: id, user_id, resource_id, start_time, end_time, status, purpose
- **Notification**: id, user_id, type, message, channel, status, booking_id

## API Requirements

### 1. Gateway Service APIs
- `POST /api/user/register` - Campus user registration
- `POST /api/user/login` - Authentication with role-based access
- `GET /api/user/verify` - University email verification
- All downstream service APIs with `/api` prefix and role-based routing

### 2. User Service APIs
- `POST /register` - Register campus user (via Asgardeo)
- `POST /login` - Authenticate user (OAuth2 with Asgardeo)
- `GET /verify` - Verify university email
- `GET /me` - Get user profile with campus preferences
- `PUT /me` - Update profile and preferences
- `GET /userinfo` - Get cached user information with roles and department

### 3. Resource Service APIs
- `POST /resources` - Create new campus resource (admin only)
- `GET /resources` - List available resources with filters
- `GET /resources/{id}` - Get detailed resource information
- `PUT /resources/{id}` - Update resource details (admin/staff)
- `GET /resources/{id}/availability` - Real-time availability check
- `POST /resources/{id}/maintenance` - Schedule maintenance (admin)

### 4. Booking Service APIs
- `POST /bookings` - Create new booking with conflict detection
- `GET /bookings` - List user bookings or all bookings (admin)
- `GET /bookings/{id}` - Get booking details
- `PUT /bookings/{id}` - Update booking (within rules)
- `DELETE /bookings/{id}` - Cancel booking
- `POST /bookings/bulk` - Bulk booking creation (admin/staff)

### 5. AI Service APIs
- `POST /ai/recommend/resources` - Get AI-powered resource recommendations
- `POST /ai/recommend/times` - Get optimal time slot suggestions
- `GET /ai/patterns/{userId}` - Get user booking patterns
- `POST /ai/predict/demand` - Predict resource demand (admin)
- `GET /ai/insights/usage` - Get usage optimization insights

### 6. Analytics Service APIs
- `GET /analytics/utilization` - Resource utilization metrics
- `GET /analytics/trends` - Usage trends and patterns
- `GET /analytics/efficiency` - Efficiency scoring and recommendations
- `GET /analytics/predictions` - AI-powered demand predictions
- `GET /analytics/reports/{type}` - Generate custom reports

### 7. Notification Service APIs
- `POST /notifications` - Send notification
- `GET /notifications` - List user notifications
- `PUT /notifications/{id}/read` - Mark notification as read
- `POST /notifications/broadcast` - Broadcast to user groups (admin)

## Compliance Requirements
- **University Integration**: Seamless integration with existing campus management systems
- **Data Privacy**: Student and staff data protection compliance (FERPA-like requirements)
- **Accessibility**: WCAG 2.1 compliance for inclusive campus resource access
- **Audit Trail**: Complete audit trail for all resource bookings and system activities
- **Multi-tenant Support**: Support for multiple campuses and departments

## Deployment Requirements
- **Containerization**: Docker support for all microservices
- **Orchestration**: Kubernetes deployment capability for campus scale
- **CI/CD**: Automated build and deployment pipeline for rapid updates
- **Environment Management**: Dev, staging, and production environments for campus rollout
- **Configuration Management**: Environment-specific configurations for different campuses
- **Service Discovery**: Automatic service discovery and health monitoring
