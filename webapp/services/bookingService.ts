// services/bookingService.ts
import { apiClient } from './api';
import { Booking } from '@/types/booking';

// Booking service functions
export const bookingService = {
  // Create a new booking
  createBooking: async (bookingData: Omit<Booking, 'id' | 'createdAt' | 'updatedAt' | 'status'>): Promise<Booking> => {
    return await apiClient.post<Booking>('/bookings', bookingData);
  },

  // Get all bookings for the current user
  getMyBookings: async (params?: {
    page?: number;
    limit?: number;
    status?: string;
    startDate?: string;
    endDate?: string;
  }): Promise<{ bookings: Booking[]; totalCount: number }> => {
    const searchParams = new URLSearchParams();
    
    if (params?.page) searchParams.append('page', params.page.toString());
    if (params?.limit) searchParams.append('limit', params.limit.toString());
    if (params?.status) searchParams.append('status', params.status);
    if (params?.startDate) searchParams.append('startDate', params.startDate);
    if (params?.endDate) searchParams.append('endDate', params.endDate);

    const queryString = searchParams.toString();
    const endpoint = `/bookings${queryString ? `?${queryString}` : ''}`;

    return await apiClient.get<{ bookings: Booking[]; totalCount: number }>(endpoint);
  },

  // Get a specific booking by ID
  getBookingById: async (id: string): Promise<Booking> => {
    return await apiClient.get<Booking>(`/bookings/${id}`);
  },

  // Update a booking (user can only update their own bookings)
  updateBooking: async (id: string, bookingData: Partial<Booking>): Promise<Booking> => {
    return await apiClient.put<Booking>(`/bookings/${id}`, bookingData);
  },

  // Cancel a booking (user can only cancel their own bookings)
  cancelBooking: async (id: string): Promise<Booking> => {
    return await apiClient.put<Booking>(`/bookings/${id}/cancel`, {});
  },

  // Join waitlist for a fully booked resource
  joinWaitlist: async (resourceId: string, startTime: string, endTime: string): Promise<any> => {
    return await apiClient.post(`/bookings/waitlist`, {
      resourceId,
      startTime,
      endTime
    });
  },

  // Admin: Get all bookings (admin/staff only)
  getAllBookings: async (params?: {
    page?: number;
    limit?: number;
    userId?: string;
    resourceId?: string;
    status?: string;
    startDate?: string;
    endDate?: string;
  }): Promise<{ bookings: Booking[]; totalCount: number }> => {
    const searchParams = new URLSearchParams();
    
    if (params?.page) searchParams.append('page', params.page.toString());
    if (params?.limit) searchParams.append('limit', params.limit.toString());
    if (params?.userId) searchParams.append('userId', params.userId);
    if (params?.resourceId) searchParams.append('resourceId', params.resourceId);
    if (params?.status) searchParams.append('status', params.status);
    if (params?.startDate) searchParams.append('startDate', params.startDate);
    if (params?.endDate) searchParams.append('endDate', params.endDate);

    const queryString = searchParams.toString();
    const endpoint = `/admin/bookings${queryString ? `?${queryString}` : ''}`;

    return await apiClient.get<{ bookings: Booking[]; totalCount: number }>(endpoint);
  },

  // Admin: Update any booking status (admin/staff only)
  updateBookingStatus: async (id: string, status: string): Promise<Booking> => {
    return await apiClient.put<Booking>(`/admin/bookings/${id}/status`, { status });
  },
};