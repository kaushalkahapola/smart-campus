# Authentication Module

This module handles authentication and authorization for the booking service.

## Functions

- `AuthInterceptor` - HTTP interceptor for authentication
- `validateToken` - Validate OAuth2 tokens with Asgardeo
- `extractUserInfo` - Extract user information from tokens
- `hasRole` - Check if user has required role
- `isPublicEndpoint` - Check if endpoint requires authentication

## Types

- `UserInfo` - User information from token
- `AuthError` - Authentication error types
