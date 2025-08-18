// hooks/useUser.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { userService } from '@/services/userService';
import { User } from '@/types/user';

// Query keys for user-related queries
export const userQueryKeys = {
  all: ['users'] as const,
  current: () => [...userQueryKeys.all, 'current'] as const,
  list: (params: any) => [...userQueryKeys.all, 'list', params] as const,
  detail: (id: string) => [...userQueryKeys.all, 'detail', id] as const,
};

// Hook to get current user
export const useCurrentUser = () => {
  return useQuery<User, Error>({
    queryKey: userQueryKeys.current(),
    queryFn: () => userService.getCurrentUser(),
    staleTime: 5 * 60 * 1000, // 5 minutes
  });
};

// Hook to update current user
export const useUpdateCurrentUser = () => {
  const queryClient = useQueryClient();
  
  return useMutation<User, Error, Partial<User>>({
    mutationFn: (userData) => userService.updateCurrentUser(userData),
    onSuccess: (updatedUser) => {
      // Update the current user in the cache
      queryClient.setQueryData(userQueryKeys.current(), updatedUser);
      
      // Show a success message to the user (you might want to use a toast notification)
      console.log('User profile updated successfully');
    },
    onError: (error) => {
      // Show an error message to the user
      console.error('Failed to update user profile:', error);
    },
  });
};

// Hook to get all users (admin only)
export const useUsers = (params?: {
  page?: number;
  limit?: number;
  search?: string;
  role?: string;
}) => {
  return useQuery<{ users: User[]; totalCount: number }, Error>({
    queryKey: userQueryKeys.list(params || {}),
    queryFn: () => userService.getAllUsers(params),
    placeholderData: (previousData) => previousData, // Keep previous data while fetching new data
  });
};

// Hook to create a user (admin only)
export const useCreateUser = () => {
  const queryClient = useQueryClient();
  
  return useMutation<User, Error, Omit<User, 'id' | 'createdAt' | 'updatedAt'>>({
    mutationFn: (userData) => userService.createUser(userData),
    onSuccess: () => {
      // Invalidate the users list to refetch it
      queryClient.invalidateQueries({ queryKey: userQueryKeys.list({}) });
      
      // Show a success message to the user
      console.log('User created successfully');
    },
    onError: (error) => {
      // Show an error message to the user
      console.error('Failed to create user:', error);
    },
  });
};

// Hook to update a user (admin only)
export const useUpdateUser = () => {
  const queryClient = useQueryClient();
  
  return useMutation<User, Error, { userId: string; userData: Partial<User> }>({
    mutationFn: ({ userId, userData }) => userService.updateUser(userId, userData),
    onSuccess: (updatedUser) => {
      // Update the user in the cache
      queryClient.setQueryData(userQueryKeys.detail(updatedUser.id), updatedUser);
      
      // Invalidate the users list to refetch it
      queryClient.invalidateQueries({ queryKey: userQueryKeys.list({}) });
      
      // Show a success message to the user
      console.log('User updated successfully');
    },
    onError: (error) => {
      // Show an error message to the user
      console.error('Failed to update user:', error);
    },
  });
};

// Hook to delete a user (admin only)
export const useDeleteUser = () => {
  const queryClient = useQueryClient();
  
  return useMutation<void, Error, string>({
    mutationFn: (userId) => userService.deleteUser(userId),
    onSuccess: (_, userId) => {
      // Remove the user from the cache
      queryClient.removeQueries({ queryKey: userQueryKeys.detail(userId) });
      
      // Invalidate the users list to refetch it
      queryClient.invalidateQueries({ queryKey: userQueryKeys.list({}) });
      
      // Show a success message to the user
      console.log('User deleted successfully');
    },
    onError: (error) => {
      // Show an error message to the user
      console.error('Failed to delete user:', error);
    },
  });
};

// Hook to set user status (admin only)
export const useSetUserStatus = () => {
  const queryClient = useQueryClient();
  
  return useMutation<User, Error, { userId: string; isActive: boolean }>({
    mutationFn: ({ userId, isActive }) => userService.setUserStatus(userId, isActive),
    onSuccess: (updatedUser) => {
      // Update the user in the cache
      queryClient.setQueryData(userQueryKeys.detail(updatedUser.id), updatedUser);
      
      // Invalidate the users list to refetch it
      queryClient.invalidateQueries({ queryKey: userQueryKeys.list({}) });
      
      // Show a success message to the user
      console.log('User status updated successfully');
    },
    onError: (error) => {
      // Show an error message to the user
      console.error('Failed to update user status:', error);
    },
  });
};