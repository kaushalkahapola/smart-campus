// services/userService.ts
import { apiClient } from './api';
import { User } from '@/types/user';

// User service functions
export const userService = {
  // Get current user profile
  getCurrentUser: async (): Promise<User> => {
    return await apiClient.get<User>('/users/me');
  },

  // Update current user profile
  updateCurrentUser: async (userData: Partial<User>): Promise<User> => {
    return await apiClient.put<User>('/users/me', userData);
  },

  // Admin: Get all users (admin only)
  getAllUsers: async (params?: {
    page?: number;
    limit?: number;
    search?: string;
    role?: string;
  }): Promise<{ users: User[]; totalCount: number }> => {
    const searchParams = new URLSearchParams();
    if (params?.page) searchParams.append('page', params.page.toString());
    if (params?.limit) searchParams.append('limit', params.limit.toString());
    if (params?.search) searchParams.append('search', params.search);
    if (params?.role) searchParams.append('role', params.role);

    const queryString = searchParams.toString();
    const endpoint = `/admin/users${queryString ? `?${queryString}` : ''}`;

    return await apiClient.get<{ users: User[]; totalCount: number }>(endpoint);
  },

  // Admin: Create a new user (admin only)
  createUser: async (userData: Omit<User, 'id' | 'createdAt' | 'updatedAt'>): Promise<User> => {
    return await apiClient.post<User>('/admin/users', userData);
  },

  // Admin: Update a user (admin only)
  updateUser: async (userId: string, userData: Partial<User>): Promise<User> => {
    return await apiClient.put<User>(`/admin/users/${userId}`, userData);
  },

  // Admin: Delete a user (admin only)
  deleteUser: async (userId: string): Promise<void> => {
    return await apiClient.delete<void>(`/admin/users/${userId}`);
  },

  // Admin: Activate/deactivate a user (admin only)
  setUserStatus: async (userId: string, isActive: boolean): Promise<User> => {
    return await apiClient.put<User>(`/admin/users/${userId}/status`, { isActive });
  },
};