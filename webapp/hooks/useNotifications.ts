// hooks/useNotifications.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { notificationService } from '@/services/notificationService';
import { Notification } from '@/types/notification';

// Query keys for notification-related queries
export const notificationQueryKeys = {
  all: ['notifications'] as const,
  list: (params: any) => [...notificationQueryKeys.all, 'list', params] as const,
  unreadCount: () => [...notificationQueryKeys.all, 'unreadCount'] as const,
};

// Hook to get current user's notifications
export const useNotifications = (params?: {
  page?: number;
  limit?: number;
  unreadOnly?: boolean;
}) => {
  return useQuery<{ notifications: Notification[]; totalCount: number }, Error>({
    queryKey: notificationQueryKeys.list(params || {}),
    queryFn: () => notificationService.getMyNotifications(params),
    placeholderData: (previousData) => previousData, // Keep previous data while fetching new data
  });
};

// Hook to mark a notification as read
export const useMarkAsRead = () => {
  const queryClient = useQueryClient();
  
  return useMutation<Notification, Error, string>({
    mutationFn: (id) => notificationService.markAsRead(id),
    onSuccess: (updatedNotification) => {
      // Update the notification in the cache
      const notificationsQueryKey = notificationQueryKeys.list({});
      const notificationsData: { notifications: Notification[]; totalCount: number } | undefined = 
        queryClient.getQueryData(notificationsQueryKey);
      
      if (notificationsData) {
        const updatedNotifications = notificationsData.notifications.map(notification => 
          notification.id === updatedNotification.id ? updatedNotification : notification
        );
        
        queryClient.setQueryData(notificationsQueryKey, {
          ...notificationsData,
          notifications: updatedNotifications
        });
      }
      
      // Invalidate the unread count to refetch it
      queryClient.invalidateQueries({ queryKey: notificationQueryKeys.unreadCount() });
      
      // Show a success message to the user
      console.log('Notification marked as read');
    },
    onError: (error) => {
      // Show an error message to the user
      console.error('Failed to mark notification as read:', error);
    },
  });
};

// Hook to mark all notifications as read
export const useMarkAllAsRead = () => {
  const queryClient = useQueryClient();
  
  return useMutation<{ count: number }, Error, void>({
    mutationFn: () => notificationService.markAllAsRead(),
    onSuccess: (result) => {
      // Invalidate the notifications list to refetch it
      queryClient.invalidateQueries({ queryKey: notificationQueryKeys.list({}) });
      
      // Invalidate the unread count to refetch it
      queryClient.invalidateQueries({ queryKey: notificationQueryKeys.unreadCount() });
      
      // Show a success message to the user
      console.log(`Marked ${result.count} notifications as read`);
    },
    onError: (error) => {
      // Show an error message to the user
      console.error('Failed to mark all notifications as read:', error);
    },
  });
};

// Hook to delete a notification
export const useDeleteNotification = () => {
  const queryClient = useQueryClient();
  
  return useMutation<void, Error, string>({
    mutationFn: (id) => notificationService.deleteNotification(id),
    onSuccess: (_, id) => {
      // Remove the notification from the cache
      const notificationsQueryKey = notificationQueryKeys.list({});
      const notificationsData: { notifications: Notification[]; totalCount: number } | undefined = 
        queryClient.getQueryData(notificationsQueryKey);
      
      if (notificationsData) {
        const updatedNotifications = notificationsData.notifications.filter(
          notification => notification.id !== id
        );
        
        queryClient.setQueryData(notificationsQueryKey, {
          ...notificationsData,
          notifications: updatedNotifications,
          totalCount: notificationsData.totalCount - 1
        });
      }
      
      // Invalidate the unread count to refetch it
      queryClient.invalidateQueries({ queryKey: notificationQueryKeys.unreadCount() });
      
      // Show a success message to the user
      console.log('Notification deleted');
    },
    onError: (error) => {
      // Show an error message to the user
      console.error('Failed to delete notification:', error);
    },
  });
};

// Hook to get unread notification count
export const useUnreadNotificationCount = () => {
  return useQuery<{ count: number }, Error>({
    queryKey: notificationQueryKeys.unreadCount(),
    queryFn: () => notificationService.getUnreadCount(),
    refetchInterval: 60000, // Refetch every minute
  });
};