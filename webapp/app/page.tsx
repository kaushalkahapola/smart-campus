'use client'

import { SignedIn, User } from '@asgardeo/nextjs';
import Navigation from './components/Navigation';
import { useEffect } from 'react';
import { useAuth } from './lib/contexts/AuthContext';
import { useAppSelector } from './lib/redux/hooks';
import { selectUser, selectIsAuthenticated } from './lib/redux/slices/authSlice';

export default function Home() {
  const { initialize } = useAuth();
  const user = useAppSelector(selectUser);
  const isAuthenticated = useAppSelector(selectIsAuthenticated);

  useEffect(() => {
    // Initialize auth context which will console log the token
    initialize();
  }, []);

  return (
    <>
      <Navigation />
      <div className="flex flex-col items-center justify-center flex-grow text-center gap-6">
        <main className="flex flex-col items-center gap-4">
          <SignedIn>
            <User>
              {(user) => (
                <div>
                  <p>Welcome back, {user.userName || user.username || user.sub}</p>
                  <p>You are logged in! Check the console for your access token.</p>
                </div>
              )}
            </User>
          </SignedIn>
        </main>
      </div>
    </>
  );
}
