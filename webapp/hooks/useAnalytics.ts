// hooks/useAnalytics.ts
import { useQuery, useMutation } from '@tanstack/react-query';
import { analyticsService } from '@/services/analyticsService';

// Query keys for analytics-related queries
export const analyticsQueryKeys = {
  all: ['analytics'] as const,
  utilization: (params: any) => [...analyticsQueryKeys.all, 'utilization', params] as const,
  trends: (params: any) => [...analyticsQueryKeys.all, 'trends', params] as const,
  efficiency: (params: any) => [...analyticsQueryKeys.all, 'efficiency', params] as const,
  report: (params: any) => [...analyticsQueryKeys.all, 'report', params] as const,
};

// Hook to get resource utilization metrics
export const useResourceUtilization = (params?: {
  resourceId?: string;
  startDate?: string;
  endDate?: string;
  granularity?: 'hour' | 'day' | 'week' | 'month';
}) => {
  return useQuery<any, Error>({
    queryKey: analyticsQueryKeys.utilization(params || {}),
    queryFn: () => analyticsService.getResourceUtilization(params),
  });
};

// Hook to get usage trends and patterns
export const useUsageTrends = (params?: {
  resourceId?: string;
  userId?: string;
  startDate?: string;
  endDate?: string;
  granularity?: 'day' | 'week' | 'month';
}) => {
  return useQuery<any, Error>({
    queryKey: analyticsQueryKeys.trends(params || {}),
    queryFn: () => analyticsService.getUsageTrends(params),
  });
};

// Hook to get efficiency scoring
export const useEfficiencyScore = (params?: {
  userId?: string;
  resourceId?: string;
  startDate?: string;
  endDate?: string;
}) => {
  return useQuery<any, Error>({
    queryKey: analyticsQueryKeys.efficiency(params || {}),
    queryFn: () => analyticsService.getEfficiencyScore(params),
  });
};

// Hook to get executive reporting data (admin only)
export const useExecutiveReport = (params?: {
  startDate?: string;
  endDate?: string;
  department?: string;
}) => {
  return useQuery<any, Error>({
    queryKey: analyticsQueryKeys.report(params || {}),
    queryFn: () => analyticsService.getExecutiveReport(params),
  });
};

// Hook to export analytics data (admin only)
export const useExportAnalytics = () => {
  return useMutation<Blob, Error, { 
    format: 'csv' | 'pdf'; 
    params?: {
      type: 'utilization' | 'trends' | 'efficiency' | 'report';
      startDate?: string;
      endDate?: string;
    } 
  }>({
    mutationFn: ({ format, params }) => analyticsService.exportAnalytics(format, params),
    onSuccess: (blob, variables) => {
      // Create a download link for the exported file
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `analytics-export.${variables.format}`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      window.URL.revokeObjectURL(url);
      
      // Show a success message to the user
      console.log('Analytics exported successfully');
    },
    onError: (error) => {
      // Show an error message to the user
      console.error('Failed to export analytics:', error);
    },
  });
};