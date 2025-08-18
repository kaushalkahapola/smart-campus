// components/layout/header.tsx
'use client';

import React from 'react';
import { useAuth } from '@/contexts/auth-context';
import { SignInButtonComponent } from '@/components/sign-in-button';
import { SignOutButtonComponent } from '@/components/sign-out-button';
import { Button } from '@/components/ui/button';
import { 
  BookOpen, 
  Calendar, 
  Building, 
  Bell, 
  User, 
  Menu,
  Home,
  BarChart3,
  Settings
} from 'lucide-react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';

interface HeaderProps {
  onMenuToggle?: () => void;
}

export function Header({ onMenuToggle }: HeaderProps) {
  const { user, isAuthenticated } = useAuth();
  const pathname = usePathname();

  // Define navigation items based on user role
  const getNavItems = () => {
    if (!isAuthenticated) {
      return [
        { name: 'Home', href: '/', icon: Home },
      ];
    }

    const baseItems = [
      { name: 'Dashboard', href: '/dashboard', icon: Home },
      { name: 'Resources', href: '/resources', icon: Building },
      { name: 'My Bookings', href: '/bookings', icon: Calendar },
    ];

    // Add admin items if user is admin
    if (user?.role === 'admin') {
      baseItems.push(
        { name: 'Admin', href: '/admin/users', icon: Settings },
        { name: 'Analytics', href: '/admin/analytics', icon: BarChart3 }
      );
    }

    return baseItems;
  };

  const navItems = getNavItems();

  return (
    <header className="sticky top-0 z-50 w-full border-b bg-background/95 backdrop-blur">
      <div className="container flex h-14 items-center">
        <div className="flex flex-1 items-center justify-between">
          <div className="flex items-center">
            {/* Mobile menu button */}
            {isAuthenticated && (
              <Button 
                variant="ghost" 
                size="icon" 
                className="mr-2 md:hidden"
                onClick={onMenuToggle}
              >
                <Menu className="h-5 w-5" />
                <span className="sr-only">Toggle menu</span>
              </Button>
            )}

            {/* Logo */}
            <Link href="/" className="flex items-center space-x-2">
              <BookOpen className="h-6 w-6 text-primary" />
              <span className="font-bold">CampusBook</span>
            </Link>

            {/* Desktop Navigation */}
            <nav className="hidden md:ml-10 md:flex md:space-x-8">
              {navItems.map((item) => {
                const Icon = item.icon;
                const isActive = pathname === item.href;
                
                return (
                  <Link
                    key={item.name}
                    href={item.href}
                    className={`inline-flex items-center text-sm font-medium transition-colors hover:text-primary ${
                      isActive 
                        ? 'text-primary' 
                        : 'text-muted-foreground'
                    }`}
                  >
                    <Icon className="mr-2 h-4 w-4" />
                    {item.name}
                  </Link>
                );
              })}
            </nav>
          </div>

          <div className="flex items-center space-x-2">
            {isAuthenticated && (
              <>
                {/* Notifications */}
                <Button variant="ghost" size="icon" className="relative">
                  <Bell className="h-5 w-5" />
                  <span className="absolute right-0 top-0 h-2 w-2 rounded-full bg-red-500"></span>
                  <span className="sr-only">Notifications</span>
                </Button>

                {/* User Profile */}
                <Link href="/profile">
                  <Button variant="ghost" size="icon" className="relative">
                    <User className="h-5 w-5" />
                    <span className="sr-only">User profile</span>
                  </Button>
                </Link>
              </>
            )}

            {/* Auth Buttons */}
            {!isAuthenticated ? (
              <SignInButtonComponent variant="ghost" />
            ) : (
              <SignOutButtonComponent variant="ghost" />
            )}
          </div>
        </div>
      </div>
    </header>
  );
}