// components/layout/sidebar.tsx
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
  Home,
  BarChart3,
  Settings,
  X
} from 'lucide-react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';

interface SidebarProps {
  isOpen: boolean;
  onToggle: () => void;
}

export function Sidebar({ isOpen, onToggle }: SidebarProps) {
  const { user, isAuthenticated } = useAuth();
  const pathname = usePathname();

  // Define navigation items based on user role
  const getNavItems = () => {
    if (!isAuthenticated) {
      return [];
    }

    const baseItems = [
      { name: 'Dashboard', href: '/dashboard', icon: Home },
      { name: 'Resources', href: '/resources', icon: Building },
      { name: 'My Bookings', href: '/bookings', icon: Calendar },
    ];

    // Add admin items if user is admin
    if (user?.role === 'admin') {
      baseItems.push(
        { name: 'Admin Panel', href: '/admin/users', icon: Settings },
        { name: 'Analytics', href: '/admin/analytics', icon: BarChart3 }
      );
    }

    return baseItems;
  };

  const navItems = getNavItems();

  return (
    <>
      {/* Overlay for mobile */}
      {isOpen && (
        <div 
          className="fixed inset-0 z-40 bg-black/50 md:hidden"
          onClick={onToggle}
        />
      )}

      {/* Sidebar */}
      <aside 
        className={`fixed left-0 top-14 z-50 h-[calc(100vh-3.5rem)] w-64 border-r bg-background transition-transform duration-300 ease-in-out md:static md:top-0 md:z-auto md:h-screen md:translate-x-0 md:border-r ${
          isOpen ? 'translate-x-0' : '-translate-x-full'
        }`}
      >
        <div className="flex h-full flex-col">
          {/* Close button for mobile */}
          <div className="flex items-center justify-between border-b p-4 md:hidden">
            <span className="text-lg font-semibold">Menu</span>
            <Button variant="ghost" size="icon" onClick={onToggle}>
              <X className="h-5 w-5" />
            </Button>
          </div>

          {/* Navigation */}
          <nav className="flex-1 overflow-y-auto p-4">
            <ul className="space-y-2">
              {navItems.map((item) => {
                const Icon = item.icon;
                const isActive = pathname === item.href;
                
                return (
                  <li key={item.name}>
                    <Link
                      href={item.href}
                      className={`flex items-center rounded-lg px-3 py-2 text-sm font-medium transition-colors ${
                        isActive
                          ? 'bg-primary text-primary-foreground'
                          : 'text-muted-foreground hover:bg-muted hover:text-foreground'
                      }`}
                      onClick={onToggle}
                    >
                      <Icon className="mr-3 h-5 w-5" />
                      {item.name}
                    </Link>
                  </li>
                );
              })}
            </ul>
          </nav>

          {/* Auth Section */}
          <div className="border-t p-4">
            {!isAuthenticated ? (
              <SignInButtonComponent variant="outline" className="w-full" />
            ) : (
              <SignOutButtonComponent variant="outline" className="w-full" />
            )}
          </div>

          {/* User Profile Section */}
          {isAuthenticated && user && (
            <div className="border-t p-4">
              <Link 
                href="/profile" 
                className="flex items-center space-x-3 rounded-lg p-2 hover:bg-muted"
                onClick={onToggle}
              >
                <div className="flex h-10 w-10 items-center justify-center rounded-full bg-primary text-primary-foreground">
                  <User className="h-5 w-5" />
                </div>
                <div className="flex-1 truncate">
                  <p className="text-sm font-medium leading-none">
                    {user.firstName && user.lastName 
                      ? `${user.firstName} ${user.lastName}` 
                      : user.username}
                  </p>
                  <p className="text-xs text-muted-foreground">
                    {user.role}
                  </p>
                </div>
              </Link>
            </div>
          )}
        </div>
      </aside>
    </>
  );
}