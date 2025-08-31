'use client';

import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import { RootState } from '../store';

// Define the type for our auth state
interface AuthState {
  isAuthenticated: boolean;
  user: {
    userName?: string;
    username?: string;
    sub?: string;
    [key: string]: any; // For other user properties
  } | null;
  accessToken: string | null;
  sessionId: string | null;
  loading: boolean;
  error: string | null;
}

// Define the initial state
const initialState: AuthState = {
  isAuthenticated: false,
  user: null,
  accessToken: null,
  sessionId: null,
  loading: false,
  error: null,
};

// Create the auth slice
export const authSlice = createSlice({
  name: 'auth',
  initialState,
  reducers: {
    // Set loading state
    setLoading: (state, action: PayloadAction<boolean>) => {
      state.loading = action.payload;
    },
    
    // Set error state
    setError: (state, action: PayloadAction<string | null>) => {
      state.error = action.payload;
    },
    
    // Set user data
    setUser: (state, action: PayloadAction<AuthState['user']>) => {
      state.user = action.payload;
      state.isAuthenticated = !!action.payload;
    },
    
    // Set access token
    setAccessToken: (state, action: PayloadAction<string | null>) => {
      state.accessToken = action.payload;
    },
    
    // Set session ID
    setSessionId: (state, action: PayloadAction<string | null>) => {
      state.sessionId = action.payload;
    },
    
    // Login success action
    loginSuccess: (state, action: PayloadAction<{
      user: AuthState['user'];
      accessToken: string;
      sessionId: string;
    }>) => {
      state.isAuthenticated = true;
      state.user = action.payload.user;
      state.accessToken = action.payload.accessToken;
      state.sessionId = action.payload.sessionId;
      state.loading = false;
      state.error = null;
    },
    
    // Logout action
    logout: (state) => {
      state.isAuthenticated = false;
      state.user = null;
      state.accessToken = null;
      state.sessionId = null;
      state.error = null;
    },
  },
});

// Export actions
export const {
  setLoading,
  setError,
  setUser,
  setAccessToken,
  setSessionId,
  loginSuccess,
  logout,
} = authSlice.actions;

// Export selectors
export const selectAuth = (state: RootState) => state.auth;
export const selectIsAuthenticated = (state: RootState) => state.auth.isAuthenticated;
export const selectUser = (state: RootState) => state.auth.user;
export const selectAccessToken = (state: RootState) => state.auth.accessToken;
export const selectSessionId = (state: RootState) => state.auth.sessionId;

// Export reducer
export default authSlice.reducer;