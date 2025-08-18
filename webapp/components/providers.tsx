// components/providers.tsx
'use client';

import React, { ReactNode } from 'react';
import { QueryClientProvider } from '@/lib/reactQuery';
import { queryClient } from '@/lib/reactQuery';
import { AuthProvider } from '@/contexts/auth-context';
import { UserProvider } from '@/contexts/user-context';
import { NotificationProvider } from '@/contexts/notification-context';
import { ConfirmProvider } from '@/contexts/confirm-context';

export function Providers({ children }: { children: ReactNode }) {
  return (
    <QueryClientProvider client={queryClient}>
      <AuthProvider>
        <UserProvider>
          <NotificationProvider>
            <ConfirmProvider>
              {children}
            </ConfirmProvider>
          </NotificationProvider>
        </UserProvider>
      </AuthProvider>
    </QueryClientProvider>
  );
}