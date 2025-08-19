// components/protected-route.tsx
'use client';

import React, { ReactNode, useEffect } from 'react';
import { useAuth } from '@/contexts/auth-context';
import { useRouter, usePathname } from 'next/navigation';

interface ProtectedRouteProps {
  children: ReactNode;
  requiredRole?: 'student' | 'staff' | 'admin';
}

export function ProtectedRoute({ children, requiredRole }: ProtectedRouteProps) {
  const { isAuthenticated, isLoading, getUserRole } = useAuth();
  const router = useRouter();
  const pathname = usePathname();

  useEffect(() => {
    // Redirect to login if not authenticated and not already on auth pages
    if (!isLoading && !isAuthenticated && !pathname.startsWith('/auth')) {
      router.push('/auth/sign-in');
    }
    
    // Check role requirements
    if (isAuthenticated && requiredRole) {
      const userRole = getUserRole();
      if (userRole && userRole !== requiredRole) {
        // Check if user has sufficient permissions
        const hasAccess = checkRoleAccess(userRole, requiredRole);
        if (!hasAccess) {
          router.push('/unauthorized');
        }
      }
    }
  }, [isAuthenticated, isLoading, requiredRole, getUserRole, router, pathname]);

  // Check if user role has access to required role level
  const checkRoleAccess = (userRole: string, requiredRole: string): boolean => {
    const roleHierarchy: Record<string, number> = {
      'student': 1,
      'staff': 2,
      'admin': 3,
    };

    return roleHierarchy[userRole] >= roleHierarchy[requiredRole];
  };

  // Show loading state while checking auth status
  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-blue-500"></div>
      </div>
    );
  }

  // If not authenticated and not on auth pages, don't render children
  if (!isAuthenticated && !pathname.startsWith('/auth')) {
    return null;
  }

  // If role check fails, don't render children
  if (isAuthenticated && requiredRole) {
    const userRole = getUserRole();
    if (userRole && !checkRoleAccess(userRole, requiredRole)) {
      return null;
    }
  }

  return <>{children}</>;
}