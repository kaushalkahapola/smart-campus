# Service Migration Instructions

## 🚫 **Services to Remove**

### 1. Remove Account Service
```bash
# Delete the entire account-service directory
rm -rf account-service/
```
**Reason**: No financial accounts needed in campus resource management

### 2. Remove Transaction Service  
```bash
# Delete the entire transaction-service directory
rm -rf transaction-service/
```
**Reason**: No financial transactions needed in campus resource management

### 3. Clean up Financial Database Schema
```bash
# Remove or modify shared/sql/V1_create_db_n_user.sql
# Remove financial tables, keep users table with modifications
```

---

## ✅ **Services to Keep & Modify**

### 1. Gateway Service ✅ **Keep & Enhance**
- **Current**: Basic gateway with Asgardeo auth
- **Enhancement Needed**: Add role-based routing for student/staff/admin
- **File**: `gateway-service/`

### 2. User Service ✅ **Keep & Modify**  
- **Current**: Basic user management
- **Enhancement Needed**: Add campus-specific user profiles, departments
- **File**: `user-service/`

### 3. Notification Service ✅ **Keep & Enhance**
- **Current**: Basic email notifications
- **Enhancement Needed**: Add WebSocket support, booking-specific notifications
- **File**: `notification-service/`

### 4. Analytics Service ✅ **Keep & Repurpose**
- **Current**: Basic analytics
- **Enhancement Needed**: Resource utilization analytics, AI insights
- **File**: `analytic-service/` (rename to `analytics-service/`)

---

## 🆕 **New Services to Create**

### 1. Resource Service **NEW**
```bash
# Create new resource-service directory
mkdir resource-service/
cd resource-service/

# Create Ballerina project
bal new resource-service
```
**Purpose**: Manage campus resources (rooms, labs, equipment)

### 2. Booking Service **NEW**
```bash
# Create new booking-service directory  
mkdir booking-service/
cd booking-service/

# Create Ballerina project
bal new booking-service
```
**Purpose**: Handle booking logic, conflict detection, scheduling

### 3. AI Service **NEW**
```bash
# Create new ai-service directory
mkdir ai-service/
cd ai-service/

# Create Ballerina project
bal new ai-service
```
**Purpose**: Pinecone integration, AI recommendations, pattern analysis

---

## 📊 **Database Schema Changes**

### Update User Table
```sql
-- Modify existing users table for campus users
ALTER TABLE users 
ADD COLUMN department VARCHAR(100),
ADD COLUMN student_id VARCHAR(20),
ADD COLUMN preferences JSON,
MODIFY COLUMN role ENUM('student', 'staff', 'admin', 'system');
```

### New Tables Needed
```sql
-- Resources table
CREATE TABLE resources (
    id VARCHAR(100) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    type ENUM('lecture_hall', 'computer_lab', 'meeting_room', 'equipment'),
    capacity INT,
    features JSON,
    location VARCHAR(255),
    building VARCHAR(100),
    status ENUM('available', 'maintenance', 'unavailable'),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Bookings table
CREATE TABLE bookings (
    id VARCHAR(100) PRIMARY KEY,
    user_id VARCHAR(100),
    resource_id VARCHAR(100),
    start_time DATETIME,
    end_time DATETIME,
    status ENUM('confirmed', 'pending', 'cancelled'),
    purpose TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (resource_id) REFERENCES resources(id)
);

-- AI patterns table (for Pinecone backup/analytics)
CREATE TABLE booking_patterns (
    id VARCHAR(100) PRIMARY KEY,
    user_id VARCHAR(100),
    pattern_vector JSON,
    booking_context JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

## 🔄 **Migration Steps (Priority Order)**

### Day 1 Morning: Clean Up
1. ✅ **Remove** `account-service/` and `transaction-service/`
2. ✅ **Update** database schema with new tables
3. ✅ **Enhance** gateway service with role-based routing

### Day 1 Afternoon: Core Services
4. ✅ **Create** `resource-service/` with basic CRUD
5. ✅ **Create** `booking-service/` with conflict detection
6. ✅ **Enhance** user service for campus profiles

### Day 2 Morning: AI & Advanced Features  
7. ✅ **Create** `ai-service/` with Pinecone integration
8. ✅ **Add** WebSocket support to notification service
9. ✅ **Enhance** analytics service for resource metrics

### Day 2 Afternoon: Demo Polish
10. ✅ **Integration testing** across all services
11. ✅ **Demo UI** preparation
12. ✅ **Documentation** and video creation

---

## 📁 **Final Directory Structure**

```
services/
├── gateway-service/          ✅ Enhanced with RBAC
├── user-service/             ✅ Campus user profiles  
├── resource-service/         🆕 Resource management
├── booking-service/          🆕 Smart booking system
├── ai-service/              🆕 Pinecone AI integration
├── notification-service/     ✅ Enhanced notifications
├── analytics-service/        ✅ Resource analytics
├── shared/
│   └── sql/
│       └── V2_campus_schema.sql  🆕 New campus schema
└── target/                   ✅ Keep for testing
```

---

## 🎯 **Key Benefits of This Migration**

### Innovation Score Boost
- ✅ **AI Integration**: Pinecone vector similarity search
- ✅ **Real-world Problem**: Campus resource optimization
- ✅ **Modern Architecture**: Event-driven microservices

### Ballerina Usage Optimization  
- ✅ **HTTP/WebSocket**: Real-time booking updates
- ✅ **Kafka Integration**: Event-driven architecture
- ✅ **External APIs**: Pinecone AI integration
- ✅ **Built-in Observability**: Service monitoring

### Competition Advantages
- ✅ **Judges can relate**: Everyone understands campus booking problems
- ✅ **Demonstrable**: Live booking conflicts and AI recommendations
- ✅ **Scalable**: Real production potential for universities

**This migration transforms your solid technical foundation into an innovative, competition-winning platform!** 🏆
