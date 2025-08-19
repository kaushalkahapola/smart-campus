// contexts/confirm-context.tsx
'use client';

import React, { createContext, useContext, useState, ReactNode } from 'react';

// Define the confirm options type
export interface ConfirmOptions {
  title: string;
  description: string;
  confirmText?: string;
  cancelText?: string;
  variant?: 'default' | 'destructive';
}

// Define the confirm context type
interface ConfirmContextType {
  confirm: (options: ConfirmOptions) => Promise<boolean>;
}

// Create the confirm context
const ConfirmContext = createContext<ConfirmContextType | undefined>(undefined);

// Confirm provider component
export const ConfirmProvider = ({ children }: { children: ReactNode }) => {
  const [confirmOptions, setConfirmOptions] = useState<ConfirmOptions | null>(null);
  const [resolvePromise, setResolvePromise] = useState<((value: boolean) => void) | null>(null);

  // Show confirmation dialog and return a promise
  const confirm = (options: ConfirmOptions): Promise<boolean> => {
    return new Promise<boolean>(resolve => {
      setConfirmOptions(options);
      setResolvePromise(() => resolve);
    });
  };

  // Handle confirm action
  const handleConfirm = () => {
    if (resolvePromise) {
      resolvePromise(true);
      setConfirmOptions(null);
      setResolvePromise(null);
    }
  };

  // Handle cancel action
  const handleCancel = () => {
    if (resolvePromise) {
      resolvePromise(false);
      setConfirmOptions(null);
      setResolvePromise(null);
    }
  };

  const value = {
    confirm,
  };

  return (
    <ConfirmContext.Provider value={value}>
      {children}
      {confirmOptions && (
        <ConfirmDialog
          options={confirmOptions}
          onConfirm={handleConfirm}
          onCancel={handleCancel}
        />
      )}
    </ConfirmContext.Provider>
  );
};

// Simple confirm dialog component (in a real app, you'd use a proper modal)
const ConfirmDialog = ({ 
  options, 
  onConfirm, 
  onCancel 
}: { 
  options: ConfirmOptions; 
  onConfirm: () => void; 
  onCancel: () => void; 
}) => {
  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white dark:bg-gray-800 rounded-lg p-6 max-w-md w-full mx-4">
        <h3 className="text-lg font-semibold mb-2">{options.title}</h3>
        <p className="text-gray-600 dark:text-gray-300 mb-6">{options.description}</p>
        <div className="flex justify-end space-x-3">
          <button
            onClick={onCancel}
            className="px-4 py-2 text-gray-600 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-md transition-colors"
          >
            {options.cancelText || 'Cancel'}
          </button>
          <button
            onClick={onConfirm}
            className={`px-4 py-2 rounded-md transition-colors ${
              options.variant === 'destructive'
                ? 'bg-red-600 hover:bg-red-700 text-white'
                : 'bg-blue-600 hover:bg-blue-700 text-white'
            }`}
          >
            {options.confirmText || 'Confirm'}
          </button>
        </div>
      </div>
    </div>
  );
};

// Custom hook to use the confirm context
export const useConfirm = () => {
  const context = useContext(ConfirmContext);
  if (context === undefined) {
    throw new Error('useConfirm must be used within a ConfirmProvider');
  }
  return context;
};