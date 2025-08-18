// contexts/user-context.tsx
'use client';

import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { useCurrentUser } from '@/hooks/useUser';
import { User, UserPreferences } from '@/types/user';

// Define the user context type
interface UserContextType {
  user: User | null;
  preferences: UserPreferences | null;
  isLoading: boolean;
  error: Error | null;
  refreshUser: () => void;
  updatePreferences: (preferences: Partial<UserPreferences>) => void;
}

// Create the user context
const UserContext = createContext<UserContextType | undefined>(undefined);

// User provider component
export const UserProvider = ({ children }: { children: ReactNode }) => {
  const { data: currentUser, isLoading, error, refetch } = useCurrentUser();
  const [user, setUser] = useState<User | null>(null);
  const [preferences, setPreferences] = useState<UserPreferences | null>(null);

  // Update user state when current user data changes
  useEffect(() => {
    if (currentUser) {
      setUser(currentUser);
      
      // Initialize preferences (in a real app, these would come from the backend)
      const initialPreferences: UserPreferences = {
        emailNotifications: true,
        pushNotifications: true,
        reminderTime: 30, // 30 minutes before booking
        timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
      };
      
      setPreferences(initialPreferences);
    } else {
      setUser(null);
      setPreferences(null);
    }
  }, [currentUser]);

  // Refresh user data
  const refreshUser = () => {
    refetch();
  };

  // Update user preferences
  const updatePreferences = (newPreferences: Partial<UserPreferences>) => {
    if (preferences) {
      setPreferences({
        ...preferences,
        ...newPreferences,
      });
    }
  };

  const value = {
    user,
    preferences,
    isLoading,
    error,
    refreshUser,
    updatePreferences,
  };

  return (
    <UserContext.Provider value={value}>
      {children}
    </UserContext.Provider>
  );
};

// Custom hook to use the user context
export const useUserContext = () => {
  const context = useContext(UserContext);
  if (context === undefined) {
    throw new Error('useUserContext must be used within a UserProvider');
  }
  return context;
};