// services/notificationService.ts
import { apiClient } from './api';
import { Notification } from '@/types/notification';

// Notification service functions
export const notificationService = {
  // Get all notifications for the current user
  getMyNotifications: async (params?: {
    page?: number;
    limit?: number;
    unreadOnly?: boolean;
  }): Promise<{ notifications: Notification[]; totalCount: number }> => {
    const searchParams = new URLSearchParams();
    
    if (params?.page) searchParams.append('page', params.page.toString());
    if (params?.limit) searchParams.append('limit', params.limit.toString());
    if (params?.unreadOnly) searchParams.append('unreadOnly', params.unreadOnly.toString());

    const queryString = searchParams.toString();
    const endpoint = `/notifications${queryString ? `?${queryString}` : ''}`;

    return await apiClient.get<{ notifications: Notification[]; totalCount: number }>(endpoint);
  },

  // Mark a notification as read
  markAsRead: async (id: string): Promise<Notification> => {
    return await apiClient.put<Notification>(`/notifications/${id}/read`, {});
  },

  // Mark all notifications as read
  markAllAsRead: async (): Promise<{ count: number }> => {
    return await apiClient.put<{ count: number }>('/notifications/read-all', {});
  },

  // Delete a notification
  deleteNotification: async (id: string): Promise<void> => {
    return await apiClient.delete<void>(`/notifications/${id}`);
  },

  // Get unread notification count
  getUnreadCount: async (): Promise<{ count: number }> => {
    return await apiClient.get<{ count: number }>('/notifications/unread-count');
  },
};