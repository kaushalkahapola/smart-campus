// contexts/notification-context.tsx
'use client';

import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { useUnreadNotificationCount } from '@/hooks/useNotifications';

// Define the notification context type
interface NotificationContextType {
  unreadCount: number;
  isLoading: boolean;
  error: Error | null;
  refreshUnreadCount: () => void;
  markAsRead: (id: string) => void;
  markAllAsRead: () => void;
}

// Create the notification context
const NotificationContext = createContext<NotificationContextType | undefined>(undefined);

// Notification provider component
export const NotificationProvider = ({ children }: { children: ReactNode }) => {
  const { data, isLoading, error, refetch } = useUnreadNotificationCount();
  const [unreadCount, setUnreadCount] = useState(0);

  // Update unread count when data changes
  useEffect(() => {
    if (data) {
      setUnreadCount(data.count);
    }
  }, [data]);

  // Refresh unread count
  const refreshUnreadCount = () => {
    refetch();
  };

  // Mark a notification as read (decrements unread count)
  const markAsRead = (id: string) => {
    setUnreadCount(prev => Math.max(0, prev - 1));
  };

  // Mark all notifications as read
  const markAllAsRead = () => {
    setUnreadCount(0);
  };

  const value = {
    unreadCount,
    isLoading,
    error,
    refreshUnreadCount,
    markAsRead,
    markAllAsRead,
  };

  return (
    <NotificationContext.Provider value={value}>
      {children}
    </NotificationContext.Provider>
  );
};

// Custom hook to use the notification context
export const useNotificationContext = () => {
  const context = useContext(NotificationContext);
  if (context === undefined) {
    throw new Error('useNotificationContext must be used within a NotificationProvider');
  }
  return context;
};