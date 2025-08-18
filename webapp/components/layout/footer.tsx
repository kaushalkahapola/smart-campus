// components/layout/footer.tsx
import React from 'react';
import Link from 'next/link';
import { BookOpen } from 'lucide-react';

export function Footer() {
  return (
    <footer className="border-t bg-background">
      <div className="container py-8 md:py-12">
        <div className="grid grid-cols-1 gap-8 md:grid-cols-4">
          {/* Brand */}
          <div className="md:col-span-1">
            <Link href="/" className="flex items-center space-x-2">
              <BookOpen className="h-6 w-6 text-primary" />
              <span className="font-bold">CampusBook</span>
            </Link>
            <p className="mt-4 text-sm text-muted-foreground">
              Smart campus resource management platform for efficient booking and resource allocation.
            </p>
          </div>

          {/* Quick Links */}
          <div>
            <h3 className="text-sm font-semibold uppercase tracking-wider">Platform</h3>
            <ul className="mt-4 space-y-2">
              <li>
                <Link href="/resources" className="text-sm text-muted-foreground hover:text-foreground">
                  Resources
                </Link>
              </li>
              <li>
                <Link href="/bookings" className="text-sm text-muted-foreground hover:text-foreground">
                  Bookings
                </Link>
              </li>
              <li>
                <Link href="/analytics" className="text-sm text-muted-foreground hover:text-foreground">
                  Analytics
                </Link>
              </li>
            </ul>
          </div>

          {/* Support */}
          <div>
            <h3 className="text-sm font-semibold uppercase tracking-wider">Support</h3>
            <ul className="mt-4 space-y-2">
              <li>
                <Link href="/help" className="text-sm text-muted-foreground hover:text-foreground">
                  Help Center
                </Link>
              </li>
              <li>
                <Link href="/contact" className="text-sm text-muted-foreground hover:text-foreground">
                  Contact Us
                </Link>
              </li>
              <li>
                <Link href="/feedback" className="text-sm text-muted-foreground hover:text-foreground">
                  Feedback
                </Link>
              </li>
            </ul>
          </div>

          {/* Legal */}
          <div>
            <h3 className="text-sm font-semibold uppercase tracking-wider">Legal</h3>
            <ul className="mt-4 space-y-2">
              <li>
                <Link href="/privacy" className="text-sm text-muted-foreground hover:text-foreground">
                  Privacy Policy
                </Link>
              </li>
              <li>
                <Link href="/terms" className="text-sm text-muted-foreground hover:text-foreground">
                  Terms of Service
                </Link>
              </li>
              <li>
                <Link href="/accessibility" className="text-sm text-muted-foreground hover:text-foreground">
                  Accessibility
                </Link>
              </li>
            </ul>
          </div>
        </div>

        {/* Copyright */}
        <div className="mt-8 border-t pt-8 text-center text-sm text-muted-foreground">
          <p>© {new Date().getFullYear()} CampusBook. All rights reserved.</p>
          <p className="mt-2">
            Built with ❤️ for smarter campus resource management.
          </p>
        </div>
      </div>
    </footer>
  );
}