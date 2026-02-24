-- V2 Campus Resource DB Schema (Notification Service Focus)
-- Changes: Align notifications table with updated event types, remove deprecated notification types, ensure support for current notification flows

DROP DATABASE IF EXISTS campus_resource_db;
CREATE DATABASE IF NOT EXISTS campus_resource_db;

USE campus_resource_db;

-- ...existing user, resource, booking, and other tables remain unchanged...

-- Updated notifications table for V2
DROP TABLE IF EXISTS notifications;
CREATE TABLE notifications (
    id VARCHAR(100) NOT NULL PRIMARY KEY UNIQUE,
    user_id VARCHAR(100) NOT NULL,
    type ENUM('booking_confirmation', 'booking_reminder', 'booking_cancelled', 'booking_modified', 'maintenance_alert', 'system_announcement', 'waitlist_added', 'waitlist_removed', 'waitlist_promoted', 'resource_available', 'resource_maintenance', 'welcome_email') NOT NULL,
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

-- ...other tables and views remain unchanged from V1...

-- Note: If you need to migrate data, consider writing ALTER TABLE statements or data migration scripts as needed.
