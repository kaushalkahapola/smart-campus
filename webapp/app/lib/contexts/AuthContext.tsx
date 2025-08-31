'use client';

import { createContext, useContext, useEffect, ReactNode } from 'react';
import { useAppDispatch, useAppSelector } from '../redux/hooks';
import { selectAuth, loginSuccess, logout, setAccessToken, setSessionId } from '../redux/slices/authSlice';
import ApiService from '../apiService';
import { getSessionData } from '../../temp_token';
import { User } from '@asgardeo/nextjs';

interface AuthContextType {
  initialize: () => Promise<void>;
  handleLogin: (user: typeof User, accessToken: string, sessionId: string) => void;
  handleLogout: () => void;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
  const dispatch = useAppDispatch();
  const auth = useAppSelector(selectAuth);
  const apiService = ApiService.getInstance();

  // Initialize auth state from session
  const initialize = async () => {
    try {
      const data = await getSessionData();
      
      // Handle session ID if available
      if (data.sessionId) {
        dispatch(setSessionId(data.sessionId));
      }
      
      // Handle access token if available
      if (data.accessToken) {
        // Set the token in the API service
        apiService.setAccessToken(data.accessToken);
        
        // Store in Redux
        dispatch(setAccessToken(data.accessToken));
        
        // Log token to console for testing (as requested)
        console.log('Access Token:', data.accessToken);
      } else {
        console.log('No access token available - user may not be signed in');
      }
    } catch (error) {
      console.error('Error initializing auth:', error);
    }
  };

  // Handle successful login
  const handleLogin = (user: typeof User, accessToken: string, sessionId: string) => {
    // Set the token in the API service
    apiService.setAccessToken(accessToken);
    
    // Store in Redux
    dispatch(loginSuccess({
      user,
      accessToken,
      sessionId
    }));
    
    // Log token to console for testing (as requested)
    console.log('Access Token:', accessToken);
  };

  // Handle logout
  const handleLogout = () => {
    // Clear the token from the API service
    apiService.clearAccessToken();
    
    // Clear from Redux
    dispatch(logout());
  };

  // Initialize on mount
  useEffect(() => {
    initialize();
  }, []);

  return (
    <AuthContext.Provider value={{ initialize, handleLogin, handleLogout }}>
      {children}
    </AuthContext.Provider>
  );
}

// Custom hook to use the auth context
export function useAuth() {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}