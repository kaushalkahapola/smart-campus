# Database Module

This module handles all database operations for the booking service.

## Functions

- `getBookingById` - Retrieve a booking by ID
- `getBookingsByUser` - Get all bookings for a specific user
- `getBookingsByResource` - Get all bookings for a specific resource
- `createBooking` - Create a new booking
- `updateBooking` - Update an existing booking
- `deleteBooking` - Delete a booking
- `checkConflicts` - Check for booking conflicts
- `getUpcomingBookings` - Get upcoming bookings with filters

## Types

- `Booking` - Main booking record type
- `CreateBooking` - Booking creation data
- `UpdateBooking` - Booking update data
- `BookingFilter` - Filter options for booking queries
- `BookingStatus` - Booking status enumeration
