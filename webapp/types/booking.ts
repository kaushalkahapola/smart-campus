// types/booking.ts
export type BookingStatus = 
  | 'pending' 
  | 'confirmed' 
  | 'in_progress' 
  | 'completed' 
  | 'cancelled' 
  | 'no_show';

export interface Booking {
  id: string;
  userId: string;
  resourceId: string;
  title: string;
  description?: string;
  startTime: string; // ISO date string
  endTime: string; // ISO date string
  status: BookingStatus;
  purpose?: string;
  attendeesCount?: number;
  createdAt: string; // ISO date string
  updatedAt: string; // ISO date string
}

export interface RecurringBookingPattern {
  frequency: 'daily' | 'weekly' | 'monthly';
  interval: number; // e.g., every 2 weeks
  endDate?: string; // ISO date string
  daysOfWeek?: number[]; // 0-6 for Sunday-Saturday
  weekOfMonth?: number; // 1-4 for first-fourth week
}