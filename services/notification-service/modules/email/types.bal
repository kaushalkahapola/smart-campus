import ballerina/time;

# Email delivery status
public enum EmailStatus {
    PENDING = "pending",
    SENT = "sent",
    DELIVERED = "delivered",
    FAILED = "failed",
    BOUNCED = "bounced"
}

# Email priority levels
public enum EmailPriority {
    LOW = "low",
    MEDIUM = "medium",
    HIGH = "high",
    URGENT = "urgent"
}

# Email template types for campus notifications
public enum EmailTemplateType {
    BOOKING_CONFIRMATION = "booking_confirmation",
    BOOKING_REMINDER = "booking_reminder",
    BOOKING_CANCELLED = "booking_cancelled",
    BOOKING_UPDATED = "booking_updated",
    WAITLIST_NOTIFICATION = "waitlist_notification",
    CHECK_IN_REMINDER = "check_in_reminder",
    MAINTENANCE_ALERT = "maintenance_alert",
    SYSTEM_ANNOUNCEMENT = "system_announcement",
    USER_WELCOME = "user_welcome",
    PASSWORD_RESET = "password_reset"
}

# Email notification data for sending
public type EmailData record {|
    # Recipient email address
    string to;
    # Email subject line
    string subject;
    # Email body content
    string body;
    # Template type for the email
    EmailTemplateType? templateType;
    # Priority level
    EmailPriority priority;
    # CC recipients
    string? cc;
    # BCC recipients
    string? bcc;
    # Reply-to address
    string? replyTo;
    # Whether body is HTML format
    boolean isHtml;
    # Template data for variable substitution
    json? templateData;
    # When to send the email
    time:Utc? scheduledAt;
|};

# Email record for database storage
public type Email record {|
    # Unique email identifier
    string emailId;
    # Recipient email address
    string recipient;
    # Email subject line
    string subject;
    # Email body content
    string body;
    # Template type used
    EmailTemplateType? templateType;
    # Priority level
    EmailPriority priority;
    # Current delivery status
    EmailStatus status;
    # CC recipients
    string? cc;
    # BCC recipients
    string? bcc;
    # Reply-to address
    string? replyTo;
    # Whether body is HTML format
    boolean isHtml;
    # Template data used
    json? templateData;
    # When email was created
    time:Utc createdAt;
    # When email is scheduled to be sent
    time:Utc? scheduledAt;
    # When email was actually sent
    time:Utc? sentAt;
    # When email was delivered
    time:Utc? deliveredAt;
    # Error message if sending failed
    string? errorMessage;
    # Number of retry attempts
    int retryCount;
    # Associated booking ID (if applicable)
    string? bookingId;
    # Associated user ID (if applicable)
    string? userId;
|};

# Email template for reusable email content
public type EmailTemplate record {|
    # Unique template identifier
    string templateId;
    # Template name
    string name;
    # Template type
    EmailTemplateType templateType;
    # Subject line template (can contain variables)
    string subject;
    # Body template (can contain variables)
    string bodyTemplate;
    # Template description
    string description;
    # Default template data
    json? defaultData;
    # Whether template is active
    boolean isActive;
    # When template was created
    time:Utc createdAt;
    # When template was last updated
    time:Utc updatedAt;
    # Who created the template
    string createdBy;
|};

# SMTP configuration
public type SMTPConfig record {|
    # SMTP server hostname
    string host;
    # SMTP server port
    int port;
    # SMTP username
    string username;
    # SMTP password
    string password;
    # Use SSL connection
    boolean useSSL;
    # Use STARTTLS
    boolean useStartTLS;
    # Default from email address
    string? fromEmail;
    # Default from name
    string? fromName;
|};

# Email sending result
public type EmailResult record {|
    # Whether email was sent successfully
    boolean success;
    # Email ID for tracking
    string emailId;
    # Error message if failed
    string? errorMessage;
    # When the attempt was made
    time:Utc timestamp;
|};

# Bulk email sending result
public type BulkEmailResult record {|
    # Batch identifier
    string batchId;
    # Total number of emails
    int totalEmails;
    # Number of successful sends
    int successCount;
    # Number of failed sends
    int failureCount;
    # Individual email results
    EmailResult[] results;
    # When the batch was processed
    time:Utc timestamp;
|};

# Email analytics data
public type EmailAnalytics record {|
    # Analytics period start
    time:Utc periodStart;
    # Analytics period end
    time:Utc periodEnd;
    # Total emails sent
    int totalSent;
    # Total emails delivered
    int totalDelivered;
    # Total emails failed
    int totalFailed;
    # Total emails bounced
    int totalBounced;
    # Delivery success rate
    decimal deliveryRate;
    # Failure rate
    decimal failureRate;
    # Breakdown by template type
    map<int> templateBreakdown;
    # Breakdown by priority
    map<int> priorityBreakdown;
    # When analytics were generated
    time:Utc generatedAt;
|};

# Database operations for emails
public type CreateEmail record {|
    # Unique email identifier
    string emailId;

    # Email recipient address
    string recipient;

    # Email subject
    string subject;

    # Email body
    string body;

    # Email template type
    EmailTemplateType? templateType;

    # Email priority
    EmailPriority priority;

    # Email CC addresses
    string? cc; 

    # Email BCC addresses
    string? bcc;

    # Email reply-to address    
    string? replyTo;

    # Whether the email is HTML formatted
    boolean isHtml;

    # Email template data
    json? templateData;

    # Scheduled sending time
    time:Utc? scheduledAt;

    # Email booking ID
    string? bookingId;

    # Email user ID
    string? userId;
|};

# Description.
#
# + emailId - field description  
# + status - field description  
# + sentAt - field description  
# + deliveredAt - field description  
# + errorMessage - field description  
# + retryCount - field description
public type UpdateEmail record {|
    string emailId;
    EmailStatus? status;
    time:Utc? sentAt;
    time:Utc? deliveredAt;
    string? errorMessage;
    int? retryCount;
|};

# Email filter for queries
public type EmailFilter record {|
    # Email recipient address
    string? recipient;

    # Email status
    EmailStatus? status;
    # Email template type
    EmailTemplateType? templateType;

    # Email priority
    EmailPriority? priority;

    # Email sending date range
    time:Utc? startDate;

    # Email sending end date
    time:Utc? endDate;

    # Email booking ID
    string? bookingId;

    # Email user ID
    string? userId;
|};
