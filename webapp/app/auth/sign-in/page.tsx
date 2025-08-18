// app/auth/sign-in/page.tsx
'use client';

import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { useRouter } from "next/navigation";
import { SignedOut, SignInButton } from '@asgardeo/nextjs';
import { useAuth } from "@/contexts/auth-context";
import { useEffect } from "react";
import { toast } from "sonner";

export default function SignInPage() {
  const router = useRouter();
  const { isAuthenticated } = useAuth();

  // Redirect authenticated users to dashboard
  useEffect(() => {
    if (isAuthenticated) {
      router.push("/dashboard");
    }
  }, [isAuthenticated, router]);

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
      <Card className="w-full max-w-md">
        <CardHeader className="space-y-1">
          <CardTitle className="text-2xl font-bold text-center">Campus Resource Management</CardTitle>
          <CardDescription className="text-center">
            Sign in with your university account to access campus resources
          </CardDescription>
        </CardHeader>
        <CardContent className="flex flex-col items-center justify-center py-8">
          <SignedOut>
            <div className="w-full space-y-6">
              <div className="text-center">
                <p className="text-muted-foreground">
                  Sign in with your university credentials to access booking systems, resources, and more.
                </p>
              </div>
              <div className="flex justify-center">
                <SignInButton
                  className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-md transition-colors"
                >
                  Sign In with University Account
                </SignInButton>
              </div>
            </div>
          </SignedOut>
        </CardContent>
        <CardFooter className="flex flex-col space-y-4">
          <div className="text-sm text-center text-muted-foreground">
            Need help signing in? Contact your campus IT support.
          </div>
        </CardFooter>
      </Card>
    </div>
  );
}
