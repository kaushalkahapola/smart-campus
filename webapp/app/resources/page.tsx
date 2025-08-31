'use client';

import { SignedIn, SignedOut } from '@asgardeo/nextjs';
import Navigation from '../components/Navigation';
import ResourceList from '../components/ResourceList';

export default function ResourcesPage() {
  return (
    <>
      <Navigation />
      <div className="flex flex-col items-center justify-center flex-grow p-6">
        <h1 className="text-2xl font-bold mb-6">Resources</h1>
        
        <SignedIn>
          <ResourceList />
        </SignedIn>
        
        <SignedOut>
          <div className="bg-yellow-100 border border-yellow-400 text-yellow-700 px-4 py-3 rounded mb-4">
            <p>Please sign in to view available resources.</p>
          </div>
        </SignedOut>
      </div>
    </>
  );
}