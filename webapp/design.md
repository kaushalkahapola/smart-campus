# Smart Campus Resource Management Platform - Web Application Architecture Design

## Architecture Overview

The Smart Campus Resource Management Platform web application follows a modern Next.js 15 architecture with React 19, implementing a component-based design with clear separation of concerns. The application integrates with the backend microservices through a centralized API service layer, providing a responsive and accessible user interface for campus resource management.

## Application Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    Client Applications                          │
│                     (Web Browser)                               │
└─────────────────────┬───────────────────────────────────────────┘
                      │ HTTPS
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                  Next.js 15 Web Application                     │
│              ┌─────────────────────────────────┐                │
│              │         App Router              │                │
│              │   - Page Components             │                │
│              │   - Layout Components           │                │
│              │   - Route Handlers              │                │
│              └─────────────────────────────────┘                │
│                                                                 │
│              ┌─────────────────────────────────┐                │
│              │        React 19 Core            │                │
│              │   - Component Architecture      │                │
│              │   - Hooks & State Management    │                │
│              │   - Context Providers           │                │
│              └─────────────────────────────────┘                │
│                                                                 │
│              ┌─────────────────────────────────┐                │
│              │      Styling & UI System        │                │
│              │   - Tailwind CSS                │                │
│              │   - shadcn/ui Components        │                │
│              │   - Responsive Design           │                │
│              │   - Accessibility Features      │                │
│              └─────────────────────────────────┘                │
└─────────┬─────────┬─────────┬─────────┬─────────────────────────┘
          │         │         │         │
          ▼         ▼         ▼         ▼
┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│ Gateway     │ │ User        │ │ Resource    │ │ Booking     │
│ Service     │ │ Service     │ │ Service     │ │ Service     │
│ (Port 9090) │ │ (Port 9092) │ │ (Port 9093) │ │ (Port 9094) │
└─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘
      │               │               │               │
      └───────────────┼───────────────┼───────────────┘
                      │               │
                      ▼               ▼
┌─────────────────────────────────────────────────────────────────┐
│                    AI Service                                   │
│                   (Port 9096)                                   │
└─────────────────────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                 Notification Service                            │
│                   (Port 9091)                                   │
└─────────────────────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Analytics Service                            │
│                   (Port 9095)                                   │
└─────────────────────────────────────────────────────────────────┘
```

## Folder Structure

```
webapp/
├── app/                          # Next.js App Router
│   ├── (auth)/                   # Authentication pages
│   │   ├── sign-in/
│   │   ├── sign-up/
│   │   └── verify/
│   ├── dashboard/                # Main dashboard
│   │   ├── page.tsx
│   │   └── layout.tsx
│   ├── resources/                # Resource management
│   │   ├── page.tsx
│   │   ├── [id]/
│   │   └── components/
│   ├── bookings/                 # Booking system
│   │   ├── page.tsx
│   │   ├── create/
│   │   ├── [id]/
│   │   └── components/
│   ├── analytics/                # Analytics dashboard
│   │   ├── page.tsx
│   │   └── components/
│   ├── profile/                  # User profile
│   │   ├── page.tsx
│   │   └── edit/
│   ├── admin/                    # Admin panel
│   │   ├── users/
│   │   ├── resources/
│   │   └── analytics/
│   ├── api/                      # API route handlers
│   │   ├── auth/
│   │   ├── users/
│   │   ├── resources/
│   │   ├── bookings/
│   │   └── notifications/
│   ├── layout.tsx                # Root layout
│   ├── page.tsx                  # Home page
│   └── ...
├── components/                   # Reusable UI components
│   ├── ui/                       # shadcn/ui components
│   │   ├── button.tsx
│   │   ├── card.tsx
│   │   ├── input.tsx
│   │   ├── modal.tsx
│   │   └── ...
│   ├── layout/                   # Layout components
│   │   ├── header.tsx
│   │   ├── sidebar.tsx
│   │   └── footer.tsx
│   ├── features/                 # Feature-specific components
│   │   ├── resource/
│   │   ├── booking/
│   │   └── user/
│   └── common/                   # Common components
├── contexts/                     # React context providers
│   ├── auth-context.tsx
│   ├── user-context.tsx
│   └── notification-context.tsx
├── hooks/                        # Custom React hooks
│   ├── useAuth.ts
│   ├── useUser.ts
│   ├── useResources.ts
│   ├── useBookings.ts
│   └── useNotifications.ts
├── lib/                          # Utility functions and helpers
│   ├── api.ts                    # API service layer
│   ├── auth.ts                   # Authentication helpers
│   ├── utils.ts                  # General utilities
│   └── constants.ts              # Application constants
├── services/                     # Service layer
│   ├── userService.ts
│   ├── resourceService.ts
│   ├── bookingService.ts
│   ├── aiService.ts
│   ├── notificationService.ts
│   └── analyticsService.ts
├── types/                        # TypeScript type definitions
│   ├── user.ts
│   ├── resource.ts
│   ├── booking.ts
│   └── index.ts
├── public/                       # Static assets
│   ├── images/
│   ├── icons/
│   └── favicon.ico
├── styles/                       # Global styles
│   ├── globals.css
│   └── tailwind.config.ts
├── middleware.ts                 # Next.js middleware
├── next.config.ts                # Next.js configuration
└── ...
```

## Component Architecture

### 1. UI Components
- **shadcn/ui Components**: Pre-built accessible UI components based on Radix UI
- **Layout Components**: Header, sidebar, footer, navigation
- **Feature Components**: Resource cards, booking forms, calendar views
- **Data Components**: Charts, tables, lists, dashboards

### 2. Page Components
- **Authentication Pages**: Sign in, sign up, verification
- **Dashboard Pages**: Main dashboard with overview
- **Resource Pages**: Resource listing, details, management
- **Booking Pages**: Booking creation, management, calendar
- **Profile Pages**: User profile view and edit
- **Admin Pages**: User management, resource management, analytics

### 3. Context Providers
- **Auth Context**: Authentication state and user information
- **User Context**: Detailed user profile and preferences
- **Notification Context**: Notification state and management

## State Management

### 1. Client State
- **React Context API**: For global state management (authentication, user data)
- **useState/useReducer**: For component-level state
- **Custom Hooks**: Encapsulated state logic for common functionality

### 2. Server State
- **React Query**: For API data management, caching, and background updates
- **Service Layer**: Centralized API service for all backend communication

### 3. Form State
- **React Hook Form**: For complex form handling and validation
- **Zod**: For schema validation and type safety

## Authentication Flow

```
1. User visits application
2. Next.js middleware checks authentication status
3. Unauthenticated users redirected to sign-in page
4. User authenticates with Asgardeo OAuth2
5. Asgardeo returns JWT access token
6. Token stored securely in HTTP-only cookie
7. User redirected to dashboard
8. Application fetches user profile and role
9. UI renders based on user role (student/staff/admin)
```

## API Integration Architecture

### 1. Service Layer
Each backend service has a corresponding service module:
- `userService.ts`: User management APIs
- `resourceService.ts`: Resource management APIs
- `bookingService.ts`: Booking management APIs
- `aiService.ts`: AI recommendation APIs
- `notificationService.ts`: Notification APIs
- `analyticsService.ts`: Analytics APIs

### 2. API Client
Centralized API client with:
- Base URL configuration
- Authentication token injection
- Error handling
- Request/response interceptors
- Retry mechanisms

### 3. React Query Integration
- Query caching for improved performance
- Background data synchronization
- Loading and error states
- Pagination support
- Mutation handling for POST/PUT/DELETE operations

## Styling Architecture

### 1. Tailwind CSS
- Utility-first CSS framework
- Custom theme configuration
- Responsive design utilities
- Dark mode support

### 2. shadcn/ui Components
- Accessible UI components built with Radix UI and Tailwind CSS
- Consistent design system
- Customizable components
- TypeScript support

## Security Architecture

### 1. Authentication
- Asgardeo OAuth2 integration
- Secure token storage (HTTP-only cookies)
- Session management
- Role-based UI rendering

### 2. Authorization
- Client-side role checking for UI elements
- Route protection via middleware
- API-level authorization through backend services

### 3. Data Protection
- Input validation and sanitization
- Secure API communication (HTTPS)
- Protection against common web vulnerabilities

## Performance Optimization

### 1. Code Splitting
- Dynamic imports for code splitting
- Route-based code splitting
- Component lazy loading

### 2. Caching
- Browser caching strategies
- React Query data caching
- CDN for static assets

### 3. Bundle Optimization
- Tree shaking
- Minification
- Image optimization

## Accessibility Features

### 1. WCAG Compliance
- Semantic HTML structure
- Proper ARIA attributes
- Keyboard navigation support
- Screen reader compatibility

### 2. Responsive Design
- Mobile-first approach
- Flexible grid layouts
- Touch-friendly interactions
- Cross-device consistency

## Testing Strategy

### 1. Unit Testing
- Component testing with React Testing Library
- Hook testing
- Utility function testing

### 2. Integration Testing
- API service testing
- Context provider testing
- Form validation testing

### 3. End-to-End Testing
- User flow testing
- Authentication flow testing
- Critical path testing

## Deployment Architecture

### 1. CI/CD Pipeline
- Automated testing
- Build optimization
- Deployment automation

### 2. Environment Management
- Development environment
- Staging environment
- Production environment

### 3. Monitoring
- Performance monitoring
- Error tracking
- User behavior analytics

## Error Handling

### 1. Client-Side Errors
- Graceful error boundaries
- User-friendly error messages
- Recovery mechanisms

### 2. API Errors
- Centralized error handling
- Error logging
- Retry mechanisms

### 3. Authentication Errors
- Session expiration handling
- Redirect to login
- Token refresh mechanisms

This architecture provides a scalable, maintainable, and performant web application that integrates seamlessly with the backend microservices while delivering an exceptional user experience for campus resource management.