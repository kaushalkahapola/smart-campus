// hooks/useAuthRedirect.ts
import { useEffect } from 'react';
import { useAuth } from '@/contexts/auth-context';
import { useRouter, usePathname } from 'next/navigation';

export const useAuthRedirect = (options?: {
  redirectIfAuthenticated?: string; // Redirect authenticated users to this path
  redirectIfNotAuthenticated?: string; // Redirect unauthenticated users to this path
}) => {
  const { isAuthenticated, isLoading } = useAuth();
  const router = useRouter();
  const pathname = usePathname();

  useEffect(() => {
    if (isLoading) return;

    // Redirect authenticated users
    if (isAuthenticated && options?.redirectIfAuthenticated && pathname !== options.redirectIfAuthenticated) {
      router.push(options.redirectIfAuthenticated);
    }

    // Redirect unauthenticated users
    if (!isAuthenticated && options?.redirectIfNotAuthenticated && pathname !== options.redirectIfNotAuthenticated) {
      router.push(options.redirectIfNotAuthenticated);
    }
  }, [isAuthenticated, isLoading, router, pathname, options]);

  return { isAuthenticated, isLoading };
};