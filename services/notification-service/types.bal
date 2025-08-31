import ballerina/http;
import ballerina/time;

# ========================================
# ERROR RESPONSE TYPES
# ========================================

# NotFound Response record type
public type NotFoundResponse record {|
    *http:NotFound;
    # payload 
    record {|
        string errorMessage;
        string? details;
    |} body;
|};

# BadRequest Response record type
public type BadRequestResponse record {|
    *http:BadRequest;
    # payload 
    record {|
        string errorMessage;
        string? details;
    |} body;
|};

# InternalServerError Response record type
public type InternalServerErrorResponse record {|
    *http:InternalServerError;
    # payload 
    record {|
        string errorMessage;
        string? details;
    |} body;
|};

# Conflict Response record type
public type ConflictResponse record {|
    *http:Conflict;
    # payload 
    record {|
        string errorMessage;
        string? details;
    |} body;
|};

# Unauthorized Response record type
public type UnauthorizedResponse record {|
    *http:Unauthorized;
    # payload 
    record {|
        string errorMessage;
    |} body;
|};

# Forbidden Response record type
public type ForbiddenResponse record {|
    *http:Forbidden;
    # payload 
    record {|
        string errorMessage;
        string? details;
    |} body;
|};

# ========================================
# EMAIL TYPES & ENUMS
# ========================================

# Email notification status types
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

# Email template types
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

# ========================================
# EMAIL REQUEST TYPES
# ========================================

# Send email notification request (Updated for service.bal compatibility)
public type SendEmailRequest record {
    # email recipient
    string to;
    # email subject
    string subject;
    # email body
    string body;
    # email template type
    string? templateType;
    # email priority
    string? priority;
    # email carbon copy
    string[]? cc;
    # email blind carbon copy
    string[]? bcc;
    # email reply-to
    string? replyTo;
    # email is HTML
    boolean? isHtml;
    # email template data   
    map<anydata>? templateData;
    # email scheduled at
    time:Utc? scheduledAt;
};

# Send bulk email request
public type SendBulkEmailRequest record {|
    # List of email recipients
    string[] recipients;
    # email subject
    string subject;
    # email body
    string body;
    # email template type
    EmailTemplateType? templateType;
    # email template data in JSON format
    json? templateData;
    # email priority
    EmailPriority priority?;
    # email carbon copy
    string? cc;
    # email blind carbon copy
    string? bcc;
    # email reply-to
    string? replyTo;
    # email is HTML
    boolean isHtml?;
    # email scheduled at
    time:Utc? scheduledAt;
|};

# Email template request
public type CreateEmailTemplateRequest record {|
    # Name of the email template
    string name;
    # Type of the email template
    EmailTemplateType templateType;
    # Subject of the email template
    string subject;
    # Body template of the email
    string bodyTemplate;
    # Description of the email template
    string description?;
    # Default data for the template in JSON format
    json? defaultData;
    # Is the email template active?
    boolean isActive?;
|};

# Update email template request
public type UpdateEmailTemplateRequest record {|
    # Name of the email template
    string name?;
    # Subject of the email template
    string subject?;
    # Body template of the email
    string bodyTemplate?;
    # Description of the email template
    string description?;
    # Default data for the template in JSON format
    json? defaultData;
    # Is the email template active?
    boolean isActive?;
|};

# ========================================
# EMAIL RESPONSE TYPES
# ========================================

# Email sent response
public type EmailSentResponse record {|
    *http:Ok;
    # payload 
    record {|
        string message;
        string emailId;
        string recipient;
        EmailStatus status;
        string timestamp;
    |} body;
|};

# Bulk email sent response
public type BulkEmailSentResponse record {|
    *http:Ok;
    # payload 
    record {|
        string message;
        string batchId;
        int totalRecipients;
        int successCount;
        int failureCount;
        string timestamp;
    |} body;
|};

# Email status response
public type EmailStatusResponse record {|
    *http:Ok;
    # payload 
    record {|
        string message;
        record {|
            string emailId;
            string recipient;
            EmailStatus status;
            string? errorMessage;
            time:Utc sentAt;
            time:Utc? deliveredAt;
            int retryCount;
        |} data;
        string timestamp;
    |} body;
|};

# Email history response
public type EmailHistoryResponse record {|
    *http:Ok;
    # payload 
    record {|
        string message;
        record {|
            json[] emails;
            int total;
            int page;
            int pageSize;
        |} data;
        string timestamp;
    |} body;
|};

# Email template response
public type EmailTemplateResponse record {|
    *http:Ok;
    # payload 
    record {|
        string message;
        json data;
        string timestamp;
    |} body;
|};

# Email templates list response
public type EmailTemplatesResponse record {|
    *http:Ok;
    # payload 
    record {|
        string message;
        record {|
            json[] templates;
            int total;
        |} data;
        string timestamp;
    |} body;
|};

# Health check response
public type HealthResponse record {|
    *http:Ok;
    # payload 
    record {|
        string message;
        record {|
            string status;
            string 'service;
            string 'version;
            int uptime_seconds;
            record {|
                boolean smtpConnected;
                boolean kafkaConnected;
                int totalEmailsSent;
                int pendingEmails;
                string? lastError;
            |} dependencies;
        |} data;
        string timestamp;
    |} body;
|};

# Success Response (Generic)
public type SuccessResponse record {|
    *http:Ok;
    # payload 
    record {|
        string message;
        json? data;
        string timestamp;
    |} body;
|};

# ========================================
# EMAIL DATA TYPES
# ========================================

# Email notification details
public type EmailDetails record {|
    # Unique identifier for the email.
    string emailId;

    # Email address of the recipient.
    string recipient;

    # Subject line of the email.
    string subject;

    # Body content of the email.
    string body;

    # Type of the email template used, if any.
    EmailTemplateType? templateType;

    # Priority level of the email.
    EmailPriority priority;

    # Current status of the email (e.g., sent, failed).
    EmailStatus status;

    # Comma-separated list of CC recipients, if any.
    string? cc;

    # Comma-separated list of BCC recipients, if any.
    string? bcc;

    # Email address for reply-to, if specified.
    string? replyTo;

    # Indicates if the email body is in HTML format.
    boolean isHtml;

    # Data used for populating the email template, if applicable.
    json? templateData;

    # Timestamp when the email was created (in UTC).
    time:Utc createdAt;

    # Scheduled time for sending the email (in UTC), if applicable.
    time:Utc? scheduledAt;

    # Timestamp when the email was sent (in UTC), if applicable.
    time:Utc? sentAt;

    # Timestamp when the email was delivered (in UTC), if applicable.
    time:Utc? deliveredAt;

    # Error message if sending failed, if any.
    string? errorMessage;

    # Number of times sending the email has been retried.
    int retryCount;
|};

# Email template details
public type EmailTemplate record {|
    # Unique identifier for the email template.
    string templateId;

    # Name of the email template.
    string name;

    # Type of the email template.
    EmailTemplateType templateType;

    # Subject line of the email.
    string subject;

    # Body content template for the email.
    string bodyTemplate;

    # Description of the email template.
    string description;

    # Default data to be used in the template, if any.
    json? defaultData;

    # Indicates whether the template is active.
    boolean isActive;

    # Timestamp when the template was created (UTC).
    time:Utc createdAt;

    # Timestamp when the template was last updated (UTC).
    time:Utc updatedAt;

    # Identifier of the user who created the template.
    string createdBy;
|};

# Email analytics
public type EmailAnalytics record {|
    # The start of the analytics period (inclusive).
    time:Utc periodStart;
    # The end of the analytics period (exclusive).
    time:Utc periodEnd;

    # Total number of emails sent during the period.
    int totalSent;

    # Total number of emails delivered during the period.
    int totalDelivered;

    # Total number of emails failed during the period.
    int totalFailed;

    # Total number of emails bounced during the period.
    int totalBounced;

    # Email template usage breakdown
    map<int> templateBreakdown;

    # Email priority level breakdown
    map<int> priorityBreakdown;

    # Timestamp when the analytics data was generated (UTC).
    time:Utc generatedAt;
|};

# SMTP configuration
public type SMTPConfig record {|
    # Hostname or IP address of the SMTP server.
    string host;

    # Port number for the SMTP server.
    int port;

    # Username for SMTP authentication.
    string username;

    # Password for SMTP authentication.
    string password;

    # Indicates whether to use SSL for the SMTP connection.
    boolean useSSL;

    # Indicates whether to use STARTTLS for the SMTP connection.
    boolean useStartTLS;

    # Email address to use as the "from" address.
    string? fromEmail;  

    # Name to use as the "from" name.
    string? fromName;
|};