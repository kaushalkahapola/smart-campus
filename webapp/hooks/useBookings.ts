// hooks/useBookings.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { bookingService } from '@/services/bookingService';
import { Booking } from '@/types/booking';

// Query keys for booking-related queries
export const bookingQueryKeys = {
  all: ['bookings'] as const,
  my: (params: any) => [...bookingQueryKeys.all, 'my', params] as const,
  detail: (id: string) => [...bookingQueryKeys.all, 'detail', id] as const,
  list: (params: any) => [...bookingQueryKeys.all, 'list', params] as const,
};

// Hook to create a booking
export const useCreateBooking = () => {
  const queryClient = useQueryClient();
  
  return useMutation<Booking, Error, Omit<Booking, 'id' | 'createdAt' | 'updatedAt' | 'status'>>({
    mutationFn: (bookingData) => bookingService.createBooking(bookingData),
    onSuccess: () => {
      // Invalidate the user's bookings list to refetch it
      queryClient.invalidateQueries({ queryKey: bookingQueryKeys.my({}) });
      
      // Show a success message to the user
      console.log('Booking created successfully');
    },
    onError: (error) => {
      // Show an error message to the user
      console.error('Failed to create booking:', error);
    },
  });
};

// Hook to get current user's bookings
export const useMyBookings = (params?: {
  page?: number;
  limit?: number;
  status?: string;
  startDate?: string;
  endDate?: string;
}) => {
  return useQuery<{ bookings: Booking[]; totalCount: number }, Error>({
    queryKey: bookingQueryKeys.my(params || {}),
    queryFn: () => bookingService.getMyBookings(params),
    placeholderData: (previousData) => previousData, // Keep previous data while fetching new data
  });
};

// Hook to get a specific booking by ID
export const useBooking = (id: string) => {
  return useQuery<Booking, Error>({
    queryKey: bookingQueryKeys.detail(id),
    queryFn: () => bookingService.getBookingById(id),
    enabled: !!id, // Only run the query if id is truthy
  });
};

// Hook to update a booking
export const useUpdateBooking = () => {
  const queryClient = useQueryClient();
  
  return useMutation<Booking, Error, { id: string; data: Partial<Booking> }>({
    mutationFn: ({ id, data }) => bookingService.updateBooking(id, data),
    onSuccess: (updatedBooking) => {
      // Update the booking in the cache
      queryClient.setQueryData(bookingQueryKeys.detail(updatedBooking.id), updatedBooking);
      
      // Invalidate the user's bookings list to refetch it
      queryClient.invalidateQueries({ queryKey: bookingQueryKeys.my({}) });
      
      // Show a success message to the user
      console.log('Booking updated successfully');
    },
    onError: (error) => {
      // Show an error message to the user
      console.error('Failed to update booking:', error);
    },
  });
};

// Hook to cancel a booking
export const useCancelBooking = () => {
  const queryClient = useQueryClient();
  
  return useMutation<Booking, Error, string>({
    mutationFn: (id) => bookingService.cancelBooking(id),
    onSuccess: (cancelledBooking) => {
      // Update the booking in the cache
      queryClient.setQueryData(bookingQueryKeys.detail(cancelledBooking.id), cancelledBooking);
      
      // Invalidate the user's bookings list to refetch it
      queryClient.invalidateQueries({ queryKey: bookingQueryKeys.my({}) });
      
      // Show a success message to the user
      console.log('Booking cancelled successfully');
    },
    onError: (error) => {
      // Show an error message to the user
      console.error('Failed to cancel booking:', error);
    },
  });
};

// Hook to join waitlist
export const useJoinWaitlist = () => {
  return useMutation<any, Error, { resourceId: string; startTime: string; endTime: string }>({
    mutationFn: ({ resourceId, startTime, endTime }) => 
      bookingService.joinWaitlist(resourceId, startTime, endTime),
    onSuccess: () => {
      // Show a success message to the user
      console.log('Joined waitlist successfully');
    },
    onError: (error) => {
      // Show an error message to the user
      console.error('Failed to join waitlist:', error);
    },
  });
};

// Hook to get all bookings (admin/staff only)
export const useBookings = (params?: {
  page?: number;
  limit?: number;
  userId?: string;
  resourceId?: string;
  status?: string;
  startDate?: string;
  endDate?: string;
}) => {
  return useQuery<{ bookings: Booking[]; totalCount: number }, Error>({
    queryKey: bookingQueryKeys.list(params || {}),
    queryFn: () => bookingService.getAllBookings(params),
    placeholderData: (previousData) => previousData, // Keep previous data while fetching new data
  });
};

// Hook to update booking status (admin/staff only)
export const useUpdateBookingStatus = () => {
  const queryClient = useQueryClient();
  
  return useMutation<Booking, Error, { id: string; status: string }>({
    mutationFn: ({ id, status }) => bookingService.updateBookingStatus(id, status),
    onSuccess: (updatedBooking) => {
      // Update the booking in the cache
      queryClient.setQueryData(bookingQueryKeys.detail(updatedBooking.id), updatedBooking);
      
      // Invalidate the bookings list to refetch it
      queryClient.invalidateQueries({ queryKey: bookingQueryKeys.list({}) });
      queryClient.invalidateQueries({ queryKey: bookingQueryKeys.my({}) });
      
      // Show a success message to the user
      console.log('Booking status updated successfully');
    },
    onError: (error) => {
      // Show an error message to the user
      console.error('Failed to update booking status:', error);
    },
  });
};