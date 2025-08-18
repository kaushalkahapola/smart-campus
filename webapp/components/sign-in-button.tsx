// components/sign-in-button.tsx
"use client";

import React from "react";
import { SignInButton } from "@asgardeo/nextjs";
import { Button, buttonVariants } from "@/components/ui/button";
import { cn } from "@/lib/utils";

interface SignInButtonProps {
  variant?:
    | "default"
    | "ghost"
    | "outline"
    | "secondary"
    | "destructive"
    | "link";
  size?: "default" | "sm" | "lg" | "icon";
  className?: string;
}

export function SignInButtonComponent({
  variant = "default",
  size = "default",
  className,
}: SignInButtonProps) {
  return (
    <SignInButton className={cn(buttonVariants({ variant, size }), className)}>
      Sign In
    </SignInButton>
  );
}
