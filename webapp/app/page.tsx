'use client'

import { SignedIn, SignedOut, SignInButton, SignOutButton, User, UserDropdown, UserProfile } from '@asgardeo/nextjs';

export default function Home() {
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
                <p>Welcome back, {user.userName || user.username || user.sub}</p>
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
