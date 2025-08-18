// components/layout/main-layout.tsx
'use client';

import React, { useState } from 'react';
import { Header } from '@/components/layout/header';
import { Sidebar } from '@/components/layout/sidebar';
import { Footer } from '@/components/layout/footer';

interface MainLayoutProps {
  children: React.ReactNode;
}

export function MainLayout({ children }: MainLayoutProps) {
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);

  const toggleSidebar = () => {
    setIsSidebarOpen(!isSidebarOpen);
  };

  return (
    <div className="flex min-h-screen flex-col">
      <Header onMenuToggle={toggleSidebar} />
      <div className="flex flex-1">
        <Sidebar isOpen={isSidebarOpen} onToggle={toggleSidebar} />
        <main className="flex-1 md:ml-0">
          {children}
        </main>
      </div>
      <Footer />
    </div>
  );
}