DROP DATABASE IF EXISTS campus_resource_db;
CREATE DATABASE IF NOT EXISTS campus_resource_db;

USE campus_resource_db;

-- Create users table for campus users (students, staff, admin)
-- This table stores user information including campus-specific details like department and student ID
-- Role-based access control: student, staff, admin, system
CREATE TABLE users (
    id VARCHAR(100) NOT NULL PRIMARY KEY UNIQUE,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    role ENUM('student', 'staff', 'admin', 'system') DEFAULT 'student',
    department VARCHAR(100) NULL,
    student_id VARCHAR(20) NULL,
    preferences JSON NULL,
    is_verified BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    last_login TIMESTAMP NULL DEFAULT NULL
);

-- Create resources table for campus facilities and equipment
-- This table stores all bookable resources including rooms, labs, and equipment
-- Features JSON field stores capabilities like AV equipment, software, accessibility features
CREATE TABLE resources (
    id VARCHAR(100) NOT NULL PRIMARY KEY UNIQUE,
    name VARCHAR(255) NOT NULL,
    type ENUM('lecture_hall', 'computer_lab', 'meeting_room', 'study_room', 'equipment', 'vehicle') NOT NULL,
    capacity INT DEFAULT 1,
    features JSON NULL COMMENT 'Equipment, software, accessibility features',
    location VARCHAR(255) NOT NULL,
    building VARCHAR(100) NOT NULL,
    floor VARCHAR(10) NULL,
    room_number VARCHAR(20) NULL,
    status ENUM('available', 'maintenance', 'unavailable', 'reserved') DEFAULT 'available',
    hourly_rate DECIMAL(8,2) DEFAULT 0.00 COMMENT 'Cost per hour if applicable',
    description TEXT NULL,
    image_url VARCHAR(500) NULL,
    contact_person VARCHAR(100) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NULL,
    FOREIGN KEY (created_by) REFERENCES users(id)
);

-- Create bookings table for resource reservations
-- This table handles all booking requests with conflict detection
-- Status tracking: pending, confirmed, in_progress, completed, cancelled, no_show
CREATE TABLE bookings (
    id VARCHAR(100) NOT NULL PRIMARY KEY UNIQUE,
    user_id VARCHAR(100) NOT NULL,
    resource_id VARCHAR(100) NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NULL,
    start_time DATETIME NOT NULL,
    end_time DATETIME NOT NULL,
    status ENUM('pending', 'confirmed', 'in_progress', 'completed', 'cancelled', 'no_show') DEFAULT 'pending',
    purpose TEXT NULL,
    attendees_count INT DEFAULT 1,
    special_requirements TEXT NULL,
    approval_needed BOOLEAN DEFAULT FALSE,
    approved_by VARCHAR(100) NULL,
    approved_at TIMESTAMP NULL,
    check_in_time TIMESTAMP NULL,
    check_out_time TIMESTAMP NULL,
    actual_attendees INT NULL,
    feedback_rating INT NULL COMMENT 'Rating 1-5',
    feedback_comment TEXT NULL,
    recurring_pattern VARCHAR(50) NULL COMMENT 'daily, weekly, monthly, etc.',
    recurring_end_date DATE NULL,
    parent_booking_id VARCHAR(100) NULL COMMENT 'For recurring bookings',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (resource_id) REFERENCES resources(id),
    FOREIGN KEY (approved_by) REFERENCES users(id),
    FOREIGN KEY (parent_booking_id) REFERENCES bookings(id),
    INDEX idx_booking_time (start_time, end_time),
    INDEX idx_resource_time (resource_id, start_time, end_time),
    INDEX idx_user_bookings (user_id, start_time)
);

-- Create notifications table for system notifications
-- This table stores all notifications sent to users via email, WebSocket, etc.
-- Supports different channels and tracks delivery status
CREATE TABLE notifications (
    id VARCHAR(100) NOT NULL PRIMARY KEY UNIQUE,
    user_id VARCHAR(100) NOT NULL,
    type ENUM('booking_confirmation', 'booking_reminder', 'booking_cancelled', 'booking_modified', 'maintenance_alert', 'system_announcement') NOT NULL,
    channel ENUM('email', 'websocket', 'push', 'sms') NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    status ENUM('pending', 'sent', 'delivered', 'failed', 'read') DEFAULT 'pending',
    booking_id VARCHAR(100) NULL,
    resource_id VARCHAR(100) NULL,
    scheduled_at TIMESTAMP NULL,
    sent_at TIMESTAMP NULL,
    delivered_at TIMESTAMP NULL,
    read_at TIMESTAMP NULL,
    metadata JSON NULL COMMENT 'Additional notification data',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (booking_id) REFERENCES bookings(id),
    FOREIGN KEY (resource_id) REFERENCES resources(id),
    INDEX idx_user_notifications (user_id, created_at),
    INDEX idx_notification_status (status, scheduled_at)
);

-- Create booking_patterns table for AI pattern analysis
-- This table stores booking behavior patterns for Pinecone AI integration
-- Used for machine learning recommendations and usage optimization
CREATE TABLE booking_patterns (
    id VARCHAR(100) NOT NULL PRIMARY KEY UNIQUE,
    user_id VARCHAR(100) NOT NULL,
    resource_type ENUM('lecture_hall', 'computer_lab', 'meeting_room', 'study_room', 'equipment', 'vehicle') NOT NULL,
    booking_hour INT NOT NULL COMMENT 'Hour of day (0-23)',
    booking_day INT NOT NULL COMMENT 'Day of week (0-6)',
    booking_duration INT NOT NULL COMMENT 'Duration in minutes',
    attendees_count INT DEFAULT 1,
    features_used JSON NULL COMMENT 'Features utilized during booking',
    success_rate DECIMAL(5,2) DEFAULT 100.00 COMMENT 'Percentage of successful bookings',
    pattern_vector JSON NULL COMMENT 'Vector embedding for Pinecone',
    booking_context JSON NULL COMMENT 'Additional context data',
    frequency_count INT DEFAULT 1 COMMENT 'How often this pattern occurs',
    last_occurrence TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    INDEX idx_user_patterns (user_id, resource_type),
    INDEX idx_pattern_time (booking_hour, booking_day)
);

-- Create resource_analytics table for usage analytics
-- This table stores aggregated analytics data for resource utilization
-- Used for admin dashboards and optimization insights
CREATE TABLE resource_analytics (
    id VARCHAR(100) NOT NULL PRIMARY KEY UNIQUE,
    resource_id VARCHAR(100) NOT NULL,
    date DATE NOT NULL,
    total_bookings INT DEFAULT 0,
    total_hours_booked DECIMAL(8,2) DEFAULT 0.00,
    total_hours_used DECIMAL(8,2) DEFAULT 0.00 COMMENT 'Actual usage time',
    utilization_rate DECIMAL(5,2) DEFAULT 0.00 COMMENT 'Percentage utilization',
    average_booking_duration DECIMAL(8,2) DEFAULT 0.00,
    peak_hour INT NULL COMMENT 'Most popular hour',
    no_show_count INT DEFAULT 0,
    cancellation_count INT DEFAULT 0,
    unique_users INT DEFAULT 0,
    revenue_generated DECIMAL(10,2) DEFAULT 0.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (resource_id) REFERENCES resources(id),
    UNIQUE KEY unique_resource_date (resource_id, date),
    INDEX idx_analytics_date (date),
    INDEX idx_analytics_utilization (utilization_rate)
);

-- Create maintenance_logs table for resource maintenance tracking
-- This table tracks maintenance schedules and history for all resources
-- Supports predictive maintenance with AI recommendations
CREATE TABLE maintenance_logs (
    id VARCHAR(100) NOT NULL PRIMARY KEY UNIQUE,
    resource_id VARCHAR(100) NOT NULL,
    maintenance_type ENUM('scheduled', 'emergency', 'preventive', 'corrective') NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NULL,
    scheduled_start DATETIME NOT NULL,
    scheduled_end DATETIME NOT NULL,
    actual_start DATETIME NULL,
    actual_end DATETIME NULL,
    status ENUM('scheduled', 'in_progress', 'completed', 'cancelled', 'delayed') DEFAULT 'scheduled',
    technician_name VARCHAR(100) NULL,
    cost DECIMAL(10,2) DEFAULT 0.00,
    parts_used TEXT NULL,
    notes TEXT NULL,
    predicted_by_ai BOOLEAN DEFAULT FALSE COMMENT 'Whether maintenance was AI-predicted',
    ai_confidence_score DECIMAL(5,2) NULL COMMENT 'AI prediction confidence (0-100)',
    created_by VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (resource_id) REFERENCES resources(id),
    FOREIGN KEY (created_by) REFERENCES users(id),
    INDEX idx_maintenance_schedule (scheduled_start, scheduled_end),
    INDEX idx_maintenance_status (status, scheduled_start)
);

-- Create waitlist table for booking queue management
-- This table manages waiting lists when resources are fully booked
-- Supports automatic booking when slots become available
CREATE TABLE waitlist (
    id VARCHAR(100) NOT NULL PRIMARY KEY UNIQUE,
    user_id VARCHAR(100) NOT NULL,
    resource_id VARCHAR(100) NOT NULL,
    preferred_start DATETIME NOT NULL,
    preferred_end DATETIME NOT NULL,
    flexibility_hours INT DEFAULT 0 COMMENT 'How many hours flexible on timing',
    priority_score INT DEFAULT 0 COMMENT 'Priority ranking',
    status ENUM('active', 'fulfilled', 'expired', 'cancelled') DEFAULT 'active',
    fulfilled_booking_id VARCHAR(100) NULL,
    auto_book BOOLEAN DEFAULT TRUE COMMENT 'Automatically book when available',
    notification_sent BOOLEAN DEFAULT FALSE,
    expires_at DATETIME NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (resource_id) REFERENCES resources(id),
    FOREIGN KEY (fulfilled_booking_id) REFERENCES bookings(id),
    INDEX idx_waitlist_resource (resource_id, preferred_start),
    INDEX idx_waitlist_user (user_id, status)
);

-- Insert sample data for development and demo

-- Sample users (students, staff, admin)
INSERT INTO users (id, username, email, role, department, student_id, is_verified, is_active) VALUES
('user_001', 'john.doe', 'john.doe@university.edu', 'student', 'Computer Science', 'CS2021001', TRUE, TRUE),
('user_002', 'jane.smith', 'jane.smith@university.edu', 'student', 'Engineering', 'EN2021002', TRUE, TRUE),
('user_003', 'prof.wilson', 'prof.wilson@university.edu', 'staff', 'Computer Science', NULL, TRUE, TRUE),
('user_004', 'admin.campus', 'admin@university.edu', 'admin', 'Administration', NULL, TRUE, TRUE),
('user_005', 'ai.system', 'system@university.edu', 'system', 'IT', NULL, TRUE, TRUE);

-- Sample resources (lecture halls, labs, meeting rooms)
INSERT INTO resources (id, name, type, capacity, features, location, building, floor, room_number, status, description) VALUES
('res_001', 'Main Lecture Hall A', 'lecture_hall', 200, '{"projector": true, "microphone": true, "recording": true, "accessibility": true}', 'Academic Block 1', 'AB1', '1', '101A', 'available', 'Large lecture hall with modern AV equipment'),
('res_002', 'Computer Lab 1', 'computer_lab', 30, '{"computers": 30, "software": ["Visual Studio", "MATLAB", "Python"], "projector": true}', 'IT Building', 'IT', '2', '201', 'available', 'Computer lab with latest software for programming'),
('res_003', 'Study Room Alpha', 'study_room', 8, '{"whiteboard": true, "projector": false, "quiet": true}', 'Library', 'LIB', '3', '301A', 'available', 'Quiet study room for group work'),
('res_004', 'Meeting Room Executive', 'meeting_room', 12, '{"video_conferencing": true, "projector": true, "whiteboard": true}', 'Administration', 'ADM', '5', '501', 'available', 'Executive meeting room with video conferencing'),
('res_005', 'Projector Mobile Unit 1', 'equipment', 1, '{"portable": true, "4k_support": true, "wireless": true}', 'Equipment Center', 'EC', '1', 'STORE', 'available', 'Portable 4K projector for events');

-- Sample bookings for demonstration
INSERT INTO bookings (id, user_id, resource_id, title, description, start_time, end_time, status, purpose, attendees_count) VALUES
('book_001', 'user_001', 'res_002', 'Programming Workshop', 'Introduction to Python programming', '2025-08-18 10:00:00', '2025-08-18 12:00:00', 'confirmed', 'Educational', 25),
('book_002', 'user_002', 'res_003', 'Study Group', 'Mathematics study session', '2025-08-18 14:00:00', '2025-08-18 16:00:00', 'confirmed', 'Study', 6),
('book_003', 'user_003', 'res_001', 'CS Lecture', 'Data Structures and Algorithms', '2025-08-19 09:00:00', '2025-08-19 11:00:00', 'confirmed', 'Lecture', 150);

-- Sample notifications
INSERT INTO notifications (id, user_id, type, channel, title, message, status, booking_id) VALUES
('notif_001', 'user_001', 'booking_confirmation', 'email', 'Booking Confirmed', 'Your booking for Computer Lab 1 has been confirmed for August 18, 2025 10:00-12:00', 'sent', 'book_001'),
('notif_002', 'user_002', 'booking_reminder', 'websocket', 'Booking Reminder', 'Your study room booking starts in 30 minutes', 'pending', 'book_002');

-- Sample booking patterns for AI analysis
INSERT INTO booking_patterns (id, user_id, resource_type, booking_hour, booking_day, booking_duration, attendees_count, frequency_count) VALUES
('pattern_001', 'user_001', 'computer_lab', 10, 1, 120, 25, 5), -- Monday 10 AM, 2 hours, frequent pattern
('pattern_002', 'user_002', 'study_room', 14, 1, 120, 6, 3),   -- Monday 2 PM, 2 hours
('pattern_003', 'user_003', 'lecture_hall', 9, 2, 120, 150, 2); -- Tuesday 9 AM, 2 hours

-- Sample resource analytics
INSERT INTO resource_analytics (id, resource_id, date, total_bookings, total_hours_booked, utilization_rate, unique_users) VALUES
('analytics_001', 'res_001', '2025-08-17', 3, 6.0, 75.0, 3),
('analytics_002', 'res_002', '2025-08-17', 4, 8.0, 100.0, 4),
('analytics_003', 'res_003', '2025-08-17', 2, 4.0, 50.0, 2);

-- Create indexes for optimal query performance
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_department ON users(department);

CREATE INDEX idx_resources_type ON resources(type);
CREATE INDEX idx_resources_building ON resources(building);
CREATE INDEX idx_resources_status ON resources(status);
CREATE INDEX idx_resources_capacity ON resources(capacity);

CREATE INDEX idx_bookings_status ON bookings(status);
CREATE INDEX idx_bookings_date_range ON bookings(start_time, end_time);

-- Create views for common queries

-- Active bookings view
CREATE VIEW active_bookings AS
SELECT 
    b.id,
    b.title,
    u.username,
    u.email,
    r.name as resource_name,
    r.type as resource_type,
    r.location,
    b.start_time,
    b.end_time,
    b.status,
    b.attendees_count
FROM bookings b
JOIN users u ON b.user_id = u.id
JOIN resources r ON b.resource_id = r.id
WHERE b.status IN ('confirmed', 'in_progress')
AND b.start_time >= CURDATE();

-- Resource utilization view
CREATE VIEW resource_utilization AS
SELECT 
    r.id,
    r.name,
    r.type,
    r.capacity,
    r.building,
    r.location,
    COUNT(b.id) as total_bookings,
    COALESCE(AVG(ra.utilization_rate), 0) as avg_utilization,
    COALESCE(SUM(ra.total_hours_booked), 0) as total_hours_booked
FROM resources r
LEFT JOIN bookings b ON r.id = b.resource_id 
    AND b.status = 'confirmed' 
    AND b.start_time >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
LEFT JOIN resource_analytics ra ON r.id = ra.resource_id 
    AND ra.date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY r.id, r.name, r.type, r.capacity, r.building, r.location;

-- User booking summary view
CREATE VIEW user_booking_summary AS
SELECT 
    u.id,
    u.username,
    u.email,
    u.role,
    u.department,
    COUNT(b.id) as total_bookings,
    COUNT(CASE WHEN b.status = 'completed' THEN 1 END) as completed_bookings,
    COUNT(CASE WHEN b.status = 'no_show' THEN 1 END) as no_shows,
    AVG(CASE WHEN b.feedback_rating IS NOT NULL THEN b.feedback_rating END) as avg_rating
FROM users u
LEFT JOIN bookings b ON u.id = b.user_id 
    AND b.start_time >= DATE_SUB(CURDATE(), INTERVAL 90 DAY)
GROUP BY u.id, u.username, u.email, u.role, u.department;
