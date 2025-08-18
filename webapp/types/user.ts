// types/user.ts
export type UserRole = 'student' | 'staff' | 'admin';

export interface User {
  id: string;
  username: string;
  email: string;
  role: UserRole;
  department?: string;
  studentId?: string;
  firstName?: string;
  lastName?: string;
  isActive: boolean;
  isVerified: boolean;
  createdAt: string; // ISO date string
  updatedAt: string; // ISO date string
  lastLogin?: string; // ISO date string
}

export interface UserPreferences {
  emailNotifications: boolean;
  pushNotifications: boolean;
  reminderTime: number; // minutes before booking
  timezone: string;
}