import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import { AsgardeoProvider } from "@asgardeo/nextjs";
import { Providers } from "@/components/providers";
import { Toaster } from "sonner";
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
  title: "Smart Campus Resource Management Platform",
  description: "Campus resource booking and management system",
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
        <AsgardeoProvider>
          <Providers>{children}</Providers>
        </AsgardeoProvider>
        <Toaster />
      </body>
    </html>
  );
}
