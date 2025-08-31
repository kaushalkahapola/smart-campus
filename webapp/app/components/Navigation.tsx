'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { SignedIn, SignedOut, SignInButton, SignOutButton, UserDropdown } from '@asgardeo/nextjs';
import { useAppSelector } from '../lib/redux/hooks';
import { selectIsAuthenticated } from '../lib/redux/slices/authSlice';

export default function Navigation() {
  const pathname = usePathname();
  const isAuthenticated = useAppSelector(selectIsAuthenticated);

  return (
    <nav className="w-full bg-white shadow-md py-4 px-6">
      <div className="max-w-7xl mx-auto flex justify-between items-center">
        <div className="flex items-center space-x-4">
          <Link href="/" className="text-xl font-bold">Campus Resource</Link>
          
          <div className="hidden md:flex space-x-4">
            <Link 
              href="/" 
              className={`${pathname === '/' ? 'text-blue-600 font-medium' : 'text-gray-600 hover:text-blue-600'}`}
            >
              Home
            </Link>
            
            <SignedIn>
              <Link 
                href="/dashboard" 
                className={`${pathname === '/dashboard' ? 'text-blue-600 font-medium' : 'text-gray-600 hover:text-blue-600'}`}
              >
                Dashboard
              </Link>
              <Link 
                href="/resources" 
                className={`${pathname === '/resources' ? 'text-blue-600 font-medium' : 'text-gray-600 hover:text-blue-600'}`}
              >
                Resources
              </Link>
              <Link 
                href="/bookings" 
                className={`${pathname === '/bookings' ? 'text-blue-600 font-medium' : 'text-gray-600 hover:text-blue-600'}`}
              >
                Bookings
              </Link>
            </SignedIn>
          </div>
        </div>
        
        <div className="flex items-center space-x-4">
          <SignedIn>
            <UserDropdown />
            <SignOutButton className="px-4 py-2 border border-gray-300 rounded-md text-sm font-medium text-gray-700 hover:bg-gray-50" />
          </SignedIn>
          <SignedOut>
            <SignInButton className="px-4 py-2 bg-blue-600 rounded-md text-sm font-medium text-white hover:bg-blue-700" />
          </SignedOut>
        </div>
      </div>
    </nav>
  );
}