// components/sign-out-button.tsx
'use client';

import React from 'react';
import { SignOutButton } from '@asgardeo/nextjs';
import { Button, buttonVariants } from '@/components/ui/button';
import { cn } from '@/lib/utils';

interface SignOutButtonProps {
  variant?: 'default' | 'ghost' | 'outline' | 'secondary' | 'destructive' | 'link';
  size?: 'default' | 'sm' | 'lg' | 'icon';
  className?: string;
}

export function SignOutButtonComponent({ 
  variant = 'default', 
  size = 'default',
  className 
}: SignOutButtonProps) {
  return (
    <SignOutButton
      className={cn(
        buttonVariants({ variant, size }),
        className
      )}
    >
      Sign Out
    </SignOutButton>
  );
}