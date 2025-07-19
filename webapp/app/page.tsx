'use client'

import { SignedIn, SignedOut, SignInButton, SignOutButton, User, UserDropdown, UserProfile } from '@asgardeo/nextjs';
import { useState, useEffect } from 'react';
import { getSessionData } from './temp_token';

export default function Home() {
  const [sessionData, setSessionData] = useState<{ sessionId: string | null; accessToken: string | null } | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchSessionData = async () => {
      try {
        const data = await getSessionData();
        setSessionData(data);
      } catch (error) {
        console.error('Error fetching session data:', error);
        setSessionData({ sessionId: null, accessToken: null });
      } finally {
        setLoading(false);
      }
    };

    fetchSessionData();
  }, []);

  return (
    <>
    <div className="flex flex-col items-center justify-center min-h-screen text-center gap-6">
      <header className="flex flex-col items-center gap-2">
        <SignedIn>
          <UserDropdown />
          <SignOutButton />
        </SignedIn>
        <SignedOut>
          <SignInButton />
        </SignedOut>
      </header>
      <main className="flex flex-col items-center gap-4">
        <SignedIn>
          <User>
            {(user) => (
              <div>
                <p>Welcome back, {user.userName || user.username || user.sub }</p>
                {loading ? (
                  <p>Loading token...</p>
                ) : (
                  <p>Your accessToken: {sessionData?.accessToken || 'No token available'}</p>
                )}
              </div>
            )}
          </User>
          <UserProfile />
        </SignedIn>
      </main>
      </div>
    </>
  );
}
