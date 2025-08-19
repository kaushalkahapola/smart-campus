// lib/reactQuery.ts
import { QueryClient, QueryClientProvider, QueryCache, MutationCache } from '@tanstack/react-query';
import { ApiError } from '@/services/api';

// Create a React Query client instance
export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 5 * 60 * 1000, // 5 minutes
      cacheTime: 10 * 60 * 1000, // 10 minutes
      retry: 1, // Retry failed requests once
      refetchOnWindowFocus: false, // Don't refetch on window focus
    },
  },
  queryCache: new QueryCache({
    onError: (error) => {
      // Handle query errors globally
      console.error('Query error:', error);
      
      // If it's an API error, we might want to handle it differently
      if (error instanceof ApiError) {
        // Handle specific API errors
        switch (error.status) {
          case 401:
            // Unauthorized - might want to redirect to login
            console.warn('Unauthorized access - redirecting to login');
            break;
          case 403:
            // Forbidden - show appropriate message
            console.warn('Access forbidden');
            break;
          default:
            // Other API errors
            console.error(`API Error ${error.status}: ${error.message}`);
        }
      }
    },
  }),
  mutationCache: new MutationCache({
    onError: (error) => {
      // Handle mutation errors globally
      console.error('Mutation error:', error);
      
      // If it's an API error, we might want to handle it differently
      if (error instanceof ApiError) {
        // Handle specific API errors
        switch (error.status) {
          case 401:
            // Unauthorized - might want to redirect to login
            console.warn('Unauthorized access - redirecting to login');
            break;
          case 403:
            // Forbidden - show appropriate message
            console.warn('Access forbidden');
            break;
          default:
            // Other API errors
            console.error(`API Error ${error.status}: ${error.message}`);
        }
      }
    },
  }),
});

export { QueryClientProvider };