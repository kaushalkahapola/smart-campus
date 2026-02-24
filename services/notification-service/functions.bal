import notification_service.email;

import ballerina/log;
import ballerina/time;
import ballerina/regex;

# Email notification service utility functions

# Validate email address format
# 
# + emailAddress - Email address to validate
# + return - True if valid, false otherwise
public function isValidEmail(string emailAddress) returns boolean {
    // Basic email validation - contains @ and has characters before and after
    if !emailAddress.includes("@") {
        return false;
    }
    
    string[] parts = regex:split(emailAddress, "@");
    if parts.length() != 2 {
        return false;
    }
    
    string localPart = parts[0];
    string domainPart = parts[1];
    
    // Check local part is not empty and domain part contains a dot
    return localPart.length() > 0 && domainPart.includes(".") && domainPart.length() > 3;
}

# Parse priority string to EmailPriority enum
# 
# + priorityStr - Priority string ("HIGH", "MEDIUM", "LOW")
# + return - EmailPriority enum value
public function parseEmailPriority(string priorityStr) returns email:EmailPriority {
    match priorityStr.toUpperAscii() {
        "HIGH" => {
            return email:HIGH;
        }
        "LOW" => {
            return email:LOW;
        }
        _ => {
            return email:MEDIUM;
        }
    }
}

# Format email template with data
# 
# + templateType - Type of email template
# + templateData - Data to populate in template
# + return - Formatted HTML content
public function formatEmailTemplate(string templateType, map<anydata> templateData) returns string {
    match templateType {
        "booking_confirmation" => {
            return formatBookingConfirmationTemplate(templateData);
        }
        "booking_cancellation" => {
            return formatBookingCancellationTemplate(templateData);
        }
        "waitlist_notification" => {
            return formatWaitlistNotificationTemplate(templateData);
        }
        "resource_reminder" => {
            return formatResourceReminderTemplate(templateData);
        }
        "account_welcome" => {
            return formatAccountWelcomeTemplate(templateData);
        }
        "password_reset" => {
            return formatPasswordResetTemplate(templateData);
        }
        _ => {
            return formatGenericTemplate(templateData);
        }
    }
}

# Format booking confirmation email template
# 
# + data - Template data
# + return - HTML email content
function formatBookingConfirmationTemplate(map<anydata> data) returns string {
    string userName = data.get("userName").toString();
    string resourceName = data.get("resourceName").toString();
    string bookingDate = data.get("bookingDate").toString();
    string bookingTime = data.get("bookingTime").toString();
    string location = data.get("location").toString();
    string bookingId = data.get("bookingId").toString();

    return string `
    <!DOCTYPE html>
    <html>
    <head>
        <style>
            body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background-color: #f4f4f4; }
            .container { max-width: 600px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; }
            .header { text-align: center; color: #2e7d32; margin-bottom: 30px; }
            .booking-details { background: #e8f5e8; padding: 20px; border-radius: 8px; margin: 20px 0; }
            .footer { text-align: center; color: #666; margin-top: 30px; font-size: 12px; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🎉 Booking Confirmed!</h1>
            </div>
            
            <p>Dear ${userName},</p>
            
            <p>Your booking has been confirmed! Here are the details:</p>
            
            <div class="booking-details">
                <h3>📋 Booking Details</h3>
                <p><strong>Resource:</strong> ${resourceName}</p>
                <p><strong>Date:</strong> ${bookingDate}</p>
                <p><strong>Time:</strong> ${bookingTime}</p>
                <p><strong>Location:</strong> ${location}</p>
                <p><strong>Booking ID:</strong> ${bookingId}</p>
            </div>
            
            <p>Please arrive on time and bring any necessary items. If you need to cancel or modify your booking, please contact us at least 24 hours in advance.</p>
            
            <p>Thank you for using our campus resource management system!</p>
            
            <div class="footer">
                <p>Campus Resource Management System<br>
                University Email: campus@university.edu</p>
            </div>
        </div>
    </body>
    </html>
    `;
}

# Format booking cancellation email template
# 
# + data - Template data
# + return - HTML email content
function formatBookingCancellationTemplate(map<anydata> data) returns string {
    string userName = data.get("userName").toString();
    string resourceName = data.get("resourceName").toString();
    string bookingDate = data.get("bookingDate").toString();
    string bookingId = data.get("bookingId").toString();

    return string `
    <!DOCTYPE html>
    <html>
    <head>
        <style>
            body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background-color: #f4f4f4; }
            .container { max-width: 600px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; }
            .header { text-align: center; color: #d32f2f; margin-bottom: 30px; }
            .booking-details { background: #ffeee; padding: 20px; border-radius: 8px; margin: 20px 0; }
            .footer { text-align: center; color: #666; margin-top: 30px; font-size: 12px; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>❌ Booking Cancelled</h1>
            </div>
            
            <p>Dear ${userName},</p>
            
            <p>Your booking has been cancelled as requested:</p>
            
            <div class="booking-details">
                <h3>📋 Cancelled Booking</h3>
                <p><strong>Resource:</strong> ${resourceName}</p>
                <p><strong>Date:</strong> ${bookingDate}</p>
                <p><strong>Booking ID:</strong> ${bookingId}</p>
            </div>
            
            <p>You can make a new booking anytime through our campus resource management system.</p>
            
            <div class="footer">
                <p>Campus Resource Management System<br>
                University Email: campus@university.edu</p>
            </div>
        </div>
    </body>
    </html>
    `;
}

# Format waitlist notification email template
# 
# + data - Template data
# + return - HTML email content
function formatWaitlistNotificationTemplate(map<anydata> data) returns string {
    string userName = data.get("userName").toString();
    string resourceName = data.get("resourceName").toString();
    string availableDate = data.get("availableDate").toString();
    string availableTime = data.get("availableTime").toString();

    return string `
    <!DOCTYPE html>
    <html>
    <head>
        <style>
            body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background-color: #f4f4f4; }
            .container { max-width: 600px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; }
            .header { text-align: center; color: #ff9800; margin-bottom: 30px; }
            .booking-details { background: #fff3e0; padding: 20px; border-radius: 8px; margin: 20px 0; }
            .footer { text-align: center; color: #666; margin-top: 30px; font-size: 12px; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🔔 Resource Available!</h1>
            </div>
            
            <p>Dear ${userName},</p>
            
            <p>Great news! A resource you were waiting for is now available:</p>
            
            <div class="booking-details">
                <h3>📋 Available Resource</h3>
                <p><strong>Resource:</strong> ${resourceName}</p>
                <p><strong>Available Date:</strong> ${availableDate}</p>
                <p><strong>Available Time:</strong> ${availableTime}</p>
            </div>
            
            <p>Please book quickly as this slot may be taken by other users. Log in to the campus resource management system to secure your booking.</p>
            
            <div class="footer">
                <p>Campus Resource Management System<br>
                University Email: campus@university.edu</p>
            </div>
        </div>
    </body>
    </html>
    `;
}

# Format resource reminder email template
# 
# + data - Template data
# + return - HTML email content
function formatResourceReminderTemplate(map<anydata> data) returns string {
    string userName = data.get("userName").toString();
    string resourceName = data.get("resourceName").toString();
    string reminderDate = data.get("reminderDate").toString();
    string reminderTime = data.get("reminderTime").toString();

    return string `
    <!DOCTYPE html>
    <html>
    <head>
        <style>
            body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background-color: #f4f4f4; }
            .container { max-width: 600px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; }
            .header { text-align: center; color: #1976d2; margin-bottom: 30px; }
            .booking-details { background: #e3f2fd; padding: 20px; border-radius: 8px; margin: 20px 0; }
            .footer { text-align: center; color: #666; margin-top: 30px; font-size: 12px; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>⏰ Booking Reminder</h1>
            </div>
            
            <p>Dear ${userName},</p>
            
            <p>This is a friendly reminder about your upcoming booking:</p>
            
            <div class="booking-details">
                <h3>📋 Upcoming Booking</h3>
                <p><strong>Resource:</strong> ${resourceName}</p>
                <p><strong>Date:</strong> ${reminderDate}</p>
                <p><strong>Time:</strong> ${reminderTime}</p>
            </div>
            
            <p>Please make sure to arrive on time. If you need to cancel or modify your booking, please do so at least 24 hours in advance.</p>
            
            <div class="footer">
                <p>Campus Resource Management System<br>
                University Email: campus@university.edu</p>
            </div>
        </div>
    </body>
    </html>
    `;
}

# Format account welcome email template
# 
# + data - Template data
# + return - HTML email content
function formatAccountWelcomeTemplate(map<anydata> data) returns string {
    string userName = data.get("userName").toString();
    string userEmail = data.get("userEmail").toString();

    return string `
    <!DOCTYPE html>
    <html>
    <head>
        <style>
            body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background-color: #f4f4f4; }
            .container { max-width: 600px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; }
            .header { text-align: center; color: #4caf50; margin-bottom: 30px; }
            .welcome-box { background: #e8f5e8; padding: 20px; border-radius: 8px; margin: 20px 0; }
            .footer { text-align: center; color: #666; margin-top: 30px; font-size: 12px; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🎓 Welcome to Campus Resources!</h1>
            </div>
            
            <p>Dear ${userName},</p>
            
            <p>Welcome to the Campus Resource Management System! Your account has been successfully created.</p>
            
            <div class="welcome-box">
                <h3>👤 Account Details</h3>
                <p><strong>Name:</strong> ${userName}</p>
                <p><strong>Email:</strong> ${userEmail}</p>
            </div>
            
            <p>You can now start booking campus resources like meeting rooms, labs, equipment, and more. Log in to explore all available resources and make your first booking!</p>
            
            <div class="footer">
                <p>Campus Resource Management System<br>
                University Email: campus@university.edu</p>
            </div>
        </div>
    </body>
    </html>
    `;
}

# Format password reset email template
# 
# + data - Template data
# + return - HTML email content
function formatPasswordResetTemplate(map<anydata> data) returns string {
    string userName = data.get("userName").toString();
    string resetLink = data.get("resetLink").toString();
    string expiryTime = data.get("expiryTime").toString();

    return string `
    <!DOCTYPE html>
    <html>
    <head>
        <style>
            body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background-color: #f4f4f4; }
            .container { max-width: 600px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; }
            .header { text-align: center; color: #f44336; margin-bottom: 30px; }
            .reset-box { background: #ffebee; padding: 20px; border-radius: 8px; margin: 20px 0; text-align: center; }
            .reset-button { display: inline-block; padding: 12px 25px; background: #f44336; color: white; text-decoration: none; border-radius: 5px; margin: 15px 0; }
            .footer { text-align: center; color: #666; margin-top: 30px; font-size: 12px; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🔐 Password Reset Request</h1>
            </div>
            
            <p>Dear ${userName},</p>
            
            <p>You have requested to reset your password for the Campus Resource Management System.</p>
            
            <div class="reset-box">
                <h3>🔑 Reset Your Password</h3>
                <p>Click the button below to reset your password:</p>
                <a href="${resetLink}" class="reset-button">Reset Password</a>
                <p><strong>Link expires:</strong> ${expiryTime}</p>
            </div>
            
            <p><strong>Security Note:</strong> If you didn't request this password reset, please ignore this email and your password will remain unchanged.</p>
            
            <div class="footer">
                <p>Campus Resource Management System<br>
                University Email: campus@university.edu</p>
            </div>
        </div>
    </body>
    </html>
    `;
}

# Format generic email template
# 
# + data - Template data
# + return - HTML email content
function formatGenericTemplate(map<anydata> data) returns string {
    string message = data.get("message").toString();
    string title = "Notification";
    
    anydata titleData = data.get("title");
    if titleData is string {
        title = titleData;
    }

    return string `
    <!DOCTYPE html>
    <html>
    <head>
        <style>
            body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background-color: #f4f4f4; }
            .container { max-width: 600px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; }
            .header { text-align: center; color: #333; margin-bottom: 30px; }
            .message-box { background: #f5f5f5; padding: 20px; border-radius: 8px; margin: 20px 0; }
            .footer { text-align: center; color: #666; margin-top: 30px; font-size: 12px; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>📧 ${title}</h1>
            </div>
            
            <div class="message-box">
                <p>${message}</p>
            </div>
            
            <div class="footer">
                <p>Campus Resource Management System<br>
                University Email: campus@university.edu</p>
            </div>
        </div>
    </body>
    </html>
    `;
}

# Get current timestamp in UTC
# 
# + return - Current UTC timestamp as string
public function getCurrentTimestamp() returns string {
    time:Utc currentTime = time:utcNow();
    return currentTime.toString();
}

# Log email activity
# 
# + emailId - Email ID
# + recipient - Email recipient
# + status - Email status ("sent", "failed", "pending")
public function logEmailActivity(string emailId, string recipient, string status) {
    log:printInfo(string `📧 Email Activity - ID: ${emailId}, To: ${recipient}, Status: ${status}`);
}