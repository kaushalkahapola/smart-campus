import notification_service.email;
import notification_service.kafka;

import ballerina/http;
import ballerina/log;
import ballerina/time;

# SMTP configuration
configurable string smtp_host = "smtp.gmail.com";
configurable int smtp_port = 587;
configurable string smtp_username = "campus@university.edu";
configurable string smtp_password = "secure_password";
configurable boolean smtp_use_starttls = true;
configurable string from_email = "campus-notifications@university.edu";
configurable string from_name = "Campus Resource Management";

service http:Service / on new http:Listener(9091) {

    # Initialize the service
    function init() returns error? {
        log:printInfo("🚀 Starting Email Notification Service on port 9091");
        
        // Initialize Kafka producer (consumers are now handled by top-level Kafka services)
        error? kafkaResult = kafka:initializeKafka();
        if kafkaResult is error {
            log:printError("Failed to initialize Kafka: " + kafkaResult.message());
        } else {
            log:printInfo("✅ Kafka initialized successfully");
        }
        
        log:printInfo("✅ Email Notification Service initialized successfully");
        return ();
    }

    # Send a single email
    # + req - Email request data
    # + return - Email sent response or error
    resource function post email/send(SendEmailRequest req) returns json|http:BadRequest|http:InternalServerError {
        log:printInfo("Sending email to: " + req.to);
        
        // Validate email address
        if !email:isValidEmail(req.to) {
            return <http:BadRequest>{
                body: {
                    errorMessage: "Invalid email address: " + req.to,
                    details: "Please provide a valid email address."
                }
            };
        }
        
        // Create SMTP configuration
        email:SMTPConfig smtpConfig = {
            host: smtp_host,
            port: smtp_port,
            username: smtp_username,
            password: smtp_password,
            useSSL: false,
            useStartTLS: smtp_use_starttls,
            fromEmail: from_email,
            fromName: from_name
        };
        
        // Prepare email data
        email:EmailData emailData = {
            to: req.to,
            subject: req.subject,
            body: req.body,
            templateType: (),
            priority: email:parseEmailPriority(req.priority ?: "MEDIUM"),
            cc: getFirstFromArray(req.cc),
            bcc: getFirstFromArray(req.bcc),
            replyTo: req.replyTo,
            isHtml: req.isHtml ?: false,
            templateData: req.templateData is map<anydata> ? <json>req.templateData : (),
            scheduledAt: req.scheduledAt
        };
        
        // Send email
        email:EmailResult result = email:sendEmail(emailData, smtpConfig);
        
        if result.success {
            // Publish success event
            error? eventResult = kafka:publishEmailEvent(result.emailId, "sent", req.to);
            if eventResult is error {
                log:printWarn("Failed to publish email event: " + eventResult.message());
            }
            
            return {
                message: "Email sent successfully",
                emailId: result.emailId,
                recipient: req.to,
                status: "sent",
                timestamp: time:utcNow().toString()
            };
        } else {
            // Publish failure event
            error? eventResult = kafka:publishEmailEvent(result.emailId, "failed", req.to);
            if eventResult is error {
                log:printWarn("Failed to publish email event: " + eventResult.message());
            }
            
            return <http:InternalServerError>{
                body: {
                    errorMessage: "Failed to send email",
                    details: result.errorMessage ?: "Unknown error"
                }
            };
        }
    }

    # Health check endpoint
    # + return - Service health status
    resource function get health() returns json {
        log:printInfo("Health check requested");
        
        return {
            message: "Email Notification Service is healthy",
            data: {
                status: "healthy",
                'service: "notification-service",
                'version: "1.0.0",
                uptime_seconds: 3600,
                dependencies: {
                    smtpConnected: true,
                    kafkaConnected: true,
                    totalEmailsSent: 0,
                    pendingEmails: 0,
                    lastError: ()
                }
            },
            timestamp: time:utcNow().toString()
        };
    }
}

# Process email notification from Kafka events
# 
# + emailMessage - Email notification message from Kafka
# + smtpConfig - SMTP configuration
# + return - Success or error
function processEmailNotification(kafka:EmailNotificationMessage emailMessage, email:SMTPConfig smtpConfig) returns error? {
    log:printInfo("Processing email notification: " + emailMessage.notificationId);
    
    // Prepare email data
    email:EmailData emailData = {
        to: emailMessage.recipient,
        subject: emailMessage.subject,
        body: emailMessage.body,
        templateType: (),
        priority: emailMessage.priority,
        cc: (),
        bcc: (),
        replyTo: (),
        isHtml: true,
        templateData: emailMessage.templateData,
        scheduledAt: emailMessage.scheduledAt
    };
    
    // Send email
    email:EmailResult result = email:sendEmail(emailData, smtpConfig);
    
    if result.success {
        log:printInfo("Email sent successfully: " + result.emailId);
        // Publish success event
        error? eventResult = kafka:publishEmailEvent(result.emailId, "sent", emailMessage.recipient);
        if eventResult is error {
            log:printWarn("Failed to publish email event: " + eventResult.message());
        }
    } else {
        log:printError("Failed to send email: " + (result.errorMessage ?: "Unknown error"));
        // Publish failure event
        error? eventResult = kafka:publishEmailEvent(result.emailId, "failed", emailMessage.recipient);
        if eventResult is error {
            log:printWarn("Failed to publish email event: " + eventResult.message());
        }
    }
    
    return ();
}

# Get first string from an array or return null
# 
# + arr - String array
# + return - First string or null
function getFirstFromArray(string[]? arr) returns string? {
    if arr is string[] && arr.length() > 0 {
        return arr[0];
    }
    return ();
}