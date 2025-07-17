DROP DATABASE IF EXISTS finmate;
CREATE DATABASE IF NOT EXISTS finmate;

USE finmate;

-- Create users table
-- This table will store user information including username, password hash, email, role, and status
-- It also includes timestamps for creation and updates, as well as a field for the last login time
-- The 'updated_by' field is used to track who last updated the record, which can be useful for auditing purposes
CREATE TABLE users (
    id VARCHAR(100) NOT NULL PRIMARY KEY UNIQUE,
    username VARCHAR(50) NOT NULL UNIQUE,
    hashed_password VARCHAR(255) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    role ENUM('user', 'admin') DEFAULT 'user',
    is_verified BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    last_login TIMESTAMP NULL DEFAULT NULL,
    updated_by VARCHAR(100) NULL DEFAULT NULL
);