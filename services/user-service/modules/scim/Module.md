# SCIM Module

This module provides SCIM 2.0 integration with Asgardeo for user and group management in the Campus Resource Management System.

## Features
- User creation with automatic group assignment
- Bulk user import from CSV/Excel
- Group management for campus roles (student, staff, admin)
- User profile synchronization between Asgardeo and local database

## Configuration
Configure SCIM client details in Config.toml:
```toml
[user_service.scim]
baseUrl = "https://api.asgardeo.io/t/{org-name}/scim2"
clientId = "your-client-id"
clientSecret = "your-client-secret"
```
