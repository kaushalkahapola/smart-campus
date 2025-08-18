// types/notification.ts
export type NotificationType = 
  | 'booking_confirmation' 
  | 'booking_reminder' 
  | 'booking_cancelled' 
  | 'maintenance_alert' 
  | 'system_announcement';

export type NotificationChannel = 
  | 'email' 
  | 'websocket' 
  | 'push';

export type NotificationStatus = 
  | 'pending' 
  | 'sent' 
  | 'delivered' 
  | 'failed';

export interface Notification {
  id: string;
  userId: string;
  type: NotificationType;
  channel: NotificationChannel;
  title: string;
  message: string;
  status: NotificationStatus;
  scheduledAt?: string; // ISO date string
  sentAt?: string; // ISO date string
  readAt?: string; // ISO date string
  bookingId?: string;
  metadata?: Record<string, any>;
  createdAt: string; // ISO date string
}