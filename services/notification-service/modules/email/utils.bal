import ballerina/email;
import ballerina/log;
import ballerina/time;
import ballerina/uuid;
import ballerina/regex;

# Send email using SMTP configuration
# 
# + emailData - Email data to send
# + smtpConfig - SMTP configuration
# + return - Email sending result
public function sendEmail(EmailData emailData, SMTPConfig smtpConfig) returns EmailResult {
    string emailId = uuid:createType1AsString();
    
    log:printInfo("🚀 Sending email: " + emailId + " to " + emailData.to);
    
    do {
        // Create SMTP client configuration
        email:SmtpClient smtpClient = check new (smtpConfig.host, smtpConfig.username, smtpConfig.password);
        
        // Prepare email message
        email:Message emailMessage = {
            to: [emailData.to],
            subject: emailData.subject,
            body: emailData.body,
            'from: smtpConfig.fromEmail ?: smtpConfig.username
        };
        
        // Add optional fields if present
        string? ccEmail = emailData.cc;
        if ccEmail is string && ccEmail != "" {
            emailMessage.cc = ccEmail;
        }
        
        string? bccEmail = emailData.bcc;
        if bccEmail is string && bccEmail != "" {
            emailMessage.bcc = bccEmail;
        }
        
        string? replyToEmail = emailData.replyTo;
        if replyToEmail is string && replyToEmail != "" {
            emailMessage.replyTo = replyToEmail;
        }
        
        // Set content type for HTML emails
        if emailData.isHtml {
            emailMessage.contentType = "text/html";
        }
        
        // Send the email
        error? sendResult = smtpClient->sendMessage(emailMessage);
        if sendResult is error {
            log:printError("Failed to send email: " + sendResult.message());
            return {
                success: false,
                emailId: emailId,
                errorMessage: "Failed to send email: " + sendResult.message(),
                timestamp: time:utcNow()
            };
        }
        
        log:printInfo("✅ Email sent successfully: " + emailId);
        return {
            success: true,
            emailId: emailId,
            errorMessage: (),
            timestamp: time:utcNow()
        };
        
    } on fail error e {
        log:printError("Exception while sending email: " + e.message());
        return {
            success: false,
            emailId: emailId,
            errorMessage: "Exception while sending email: " + e.message(),
            timestamp: time:utcNow()
        };
    }
}

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
public function parseEmailPriority(string priorityStr) returns EmailPriority {
    match priorityStr.toUpperAscii() {
        "HIGH" => {
            return HIGH;
        }
        "LOW" => {
            return LOW;
        }
        _ => {
            return MEDIUM;
        }
    }
}

# Check if email is scheduled for future sending
# 
# + scheduledAt - Scheduled time
# + return - True if scheduled for future, false otherwise
public function isScheduledEmail(time:Utc? scheduledAt) returns boolean {
    if scheduledAt is () {
        return false;
    }
    
    time:Utc currentTime = time:utcNow();
    decimal diffSeconds = time:utcDiffSeconds(scheduledAt, currentTime);
    return diffSeconds > 0d;
}

# Format email timestamp
# 
# + timestamp - UTC timestamp
# + return - Formatted timestamp string
public function formatEmailTimestamp(time:Utc timestamp) returns string {
    return timestamp.toString();
}

# Generate unique email ID
# 
# + return - Unique email ID
public function generateEmailId() returns string {
    return uuid:createType1AsString();
}

# Log email sending activity
# 
# + emailId - Email ID
# + recipient - Email recipient
# + status - Email status
public function logEmailActivity(string emailId, string recipient, string status) {
    log:printInfo(string `📧 Email Activity - ID: ${emailId}, To: ${recipient}, Status: ${status}, Time: ${time:utcNow().toString()}`);
}

# Validate SMTP configuration
# 
# + smtpConfig - SMTP configuration to validate
# + return - True if valid, false otherwise
public function validateSMTPConfig(SMTPConfig smtpConfig) returns boolean {
    // Check required fields
    if smtpConfig.host.length() == 0 {
        return false;
    }
    
    if smtpConfig.port <= 0 || smtpConfig.port > 65535 {
        return false;
    }
    
    if smtpConfig.username.length() == 0 {
        return false;
    }
    
    if smtpConfig.password.length() == 0 {
        return false;
    }
    
    if smtpConfig.fromEmail is string {
        string emailAddr = <string>smtpConfig.fromEmail;
        if !isValidEmail(emailAddr) {
            return false;
        }
    }
    return true;
    
}

# Get email status message
# 
# + success - Whether email was sent successfully
# + errorMessage - Error message if failed
# + return - Status message
public function getEmailStatusMessage(boolean success, string? errorMessage) returns string {
    if success {
        return "Email sent successfully";
    } else {
        return errorMessage ?: "Unknown error occurred while sending email";
    }
}
