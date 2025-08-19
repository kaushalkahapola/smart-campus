// app/auth/sign-up/page.tsx
'use client';

import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { useRouter } from "next/navigation";
import { useAuth } from "@/contexts/auth-context";
import { useEffect } from "react";
import { toast } from "sonner";
import { SignedOut, SignInButton } from '@asgardeo/nextjs';

export default function SignUpPage() {
  const router = useRouter();
  const { isAuthenticated } = useAuth();

  // Redirect authenticated users to dashboard
  useEffect(() => {
    if (isAuthenticated) {
      router.push("/dashboard");
    }
  }, [isAuthenticated, router]);

  const handleAdminSignUp = () => {
    toast.info("Contact your campus administrator to create an account.");
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
      <Card className="w-full max-w-md">
        <CardHeader className="space-y-1">
          <CardTitle className="text-2xl font-bold text-center">Campus Account Registration</CardTitle>
          <CardDescription className="text-center">
            Campus accounts are managed by administrators
          </CardDescription>
        </CardHeader>
        <CardContent className="flex flex-col items-center justify-center py-8">
          <div className="w-full space-y-6">
            <div className="text-center">
              <p className="text-muted-foreground">
                Campus accounts are created and managed by your university administrators. 
                If you need access to the system, please contact your campus IT department.
              </p>
            </div>
            <div className="flex justify-center">
              <Button 
                onClick={handleAdminSignUp}
                variant="outline"
              >
                Request Campus Account
              </Button>
            </div>
            <div className="relative">
              <div className="absolute inset-0 flex items-center">
                <div className="w-full border-t border-gray-300" />
              </div>
              <div className="relative flex justify-center text-xs uppercase">
                <span className="bg-gray-50 px-2 text-muted-foreground">
                  Or continue with
                </span>
              </div>
            </div>
            <SignedOut>
              <div className="flex justify-center">
                <SignInButton
                  className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-md transition-colors"
                >
                  Sign In with University Account
                </SignInButton>
              </div>
            </SignedOut>
          </div>
        </CardContent>
        <CardFooter className="flex flex-col space-y-4">
          <div className="text-sm text-center text-muted-foreground">
            <button
              onClick={() => router.push("/auth/sign-in")}
              className="text-primary hover:underline"
            >
              Already have access? Sign in
            </button>
          </div>
        </CardFooter>
      </Card>
    </div>
  );
}