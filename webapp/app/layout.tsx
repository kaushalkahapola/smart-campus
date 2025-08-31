import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import { AsgardeoProvider } from "@asgardeo/nextjs";
import { ReduxProvider } from "./lib/redux/provider";
import { AuthProvider } from "./lib/contexts/AuthContext";
import "./globals.css";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "Smart Campus Resource Management",
  description: "Smart Campus Resource Management Platform",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body
        className={`${geistSans.variable} ${geistMono.variable} antialiased`}
      >
        <ReduxProvider>
          <AsgardeoProvider>
            <AuthProvider>
              <div className="flex flex-col min-h-screen">
                {children}
              </div>
            </AuthProvider>
          </AsgardeoProvider>
        </ReduxProvider>
      </body>
    </html>
  );
}
