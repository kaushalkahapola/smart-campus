# Email Module

This module provides email notification functionality for the Smart Campus Resource Management Platform.

## Features

- **Email Sending**: SMTP-based email delivery
- **Template Support**: HTML and text email templates
- **Template Management**: Create, update, and manage email templates
- **Delivery Tracking**: Track email delivery status and failures
- **Retry Logic**: Automatic retry for failed email deliveries
- **Campus Integration**: Integration with university email systems

## Dependencies

- `ballerina/email`: Core email functionality
- `ballerina/log`: Logging support
- `ballerina/uuid`: UUID generation for tracking
- `ballerina/time`: Time handling for scheduling

## Configuration

Email configuration should be provided in Config.toml:

```toml
[notification_service.email]
host = "smtp.university.edu"
port = 587
username = "campus-notifications@university.edu"
password = "secure_password"
useStartTLS = true
fromEmail = "campus-notifications@university.edu"
fromName = "Campus Resource Management"
```

## Usage

The email module is used by the notification service to send campus-related emails such as:

- Booking confirmations and reminders
- Resource maintenance alerts
- User welcome emails
- System announcements
