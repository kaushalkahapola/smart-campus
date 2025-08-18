// contexts/auth-context.tsx
"use client";

import React, {
  createContext,
  useContext,
  useState,
  useEffect,
  ReactNode,
} from "react";
import { User, UserRole } from "@/types/user";

// Define the auth context type
interface AuthContextType {
  user: User | null;
  isLoading: boolean;
  isAuthenticated: boolean;
  getUserRole: () => UserRole | null;
  getAccessToken: () => string | null;
}

// Create the auth context
const AuthContext = createContext<AuthContextType | undefined>(undefined);

// Auth provider component
export const AuthProvider = ({ children }: { children: ReactNode }) => {
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  // Since we're using Asgardeo's built-in auth components,
  // we'll rely on the API client's token management
  // The API client will get the token from cookies/session storage

  // For now, we'll set up a basic user state
  // In a real implementation, you might fetch user data from your backend
  useEffect(() => {
    // Simulate checking authentication status
    const checkAuthStatus = async () => {
      try {
        // In a real app, you might make a call to your backend to verify the token
        // and get user information
        setIsLoading(false);
      } catch (error) {
        console.error("Error checking auth status:", error);
        setIsLoading(false);
      }
    };

    checkAuthStatus();
  }, []);

  // Get user role
  const getUserRole = (): UserRole | null => {
    return user?.role || null;
  };

  // Get access token from API client
  const getAuthAccessToken = (): string | null => {
    // The API client manages the token internally
    // This is a placeholder - you might need to implement
    // a way to get the token from the API client
    return null;
  };

  const value = {
    user,
    isLoading,
    isAuthenticated: !!user,
    getUserRole,
    getAccessToken: getAuthAccessToken,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};

// Custom hook to use the auth context
export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error("useAuth must be used within an AuthProvider");
  }
  return context;
};

// Helper hook to check if user has a specific role
export const useHasRole = (roles: UserRole | UserRole[]) => {
  const { user, isLoading } = useAuth();

  if (isLoading) {
    return false;
  }

  if (!user) {
    return false;
  }

  const rolesArray = Array.isArray(roles) ? roles : [roles];
  return rolesArray.includes(user.role);
};

// Helper hook to check if user is authenticated
export const useIsAuthenticated = () => {
  const { isAuthenticated, isLoading } = useAuth();
  return { isAuthenticated, isLoading };
};
