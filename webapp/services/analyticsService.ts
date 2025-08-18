// services/analyticsService.ts
import { apiClient } from './api';

// Analytics service functions
export const analyticsService = {
  // Get resource utilization metrics
  getResourceUtilization: async (params?: {
    resourceId?: string;
    startDate?: string;
    endDate?: string;
    granularity?: 'hour' | 'day' | 'week' | 'month';
  }): Promise<any> => {
    const searchParams = new URLSearchParams();
    
    if (params?.resourceId) searchParams.append('resourceId', params.resourceId);
    if (params?.startDate) searchParams.append('startDate', params.startDate);
    if (params?.endDate) searchParams.append('endDate', params.endDate);
    if (params?.granularity) searchParams.append('granularity', params.granularity);

    const queryString = searchParams.toString();
    const endpoint = `/analytics/utilization${queryString ? `?${queryString}` : ''}`;

    return await apiClient.get(endpoint);
  },

  // Get usage trends and patterns
  getUsageTrends: async (params?: {
    resourceId?: string;
    userId?: string;
    startDate?: string;
    endDate?: string;
    granularity?: 'day' | 'week' | 'month';
  }): Promise<any> => {
    const searchParams = new URLSearchParams();
    
    if (params?.resourceId) searchParams.append('resourceId', params.resourceId);
    if (params?.userId) searchParams.append('userId', params.userId);
    if (params?.startDate) searchParams.append('startDate', params.startDate);
    if (params?.endDate) searchParams.append('endDate', params.endDate);
    if (params?.granularity) searchParams.append('granularity', params.granularity);

    const queryString = searchParams.toString();
    const endpoint = `/analytics/trends${queryString ? `?${queryString}` : ''}`;

    return await apiClient.get(endpoint);
  },

  // Get efficiency scoring
  getEfficiencyScore: async (params?: {
    userId?: string;
    resourceId?: string;
    startDate?: string;
    endDate?: string;
  }): Promise<any> => {
    const searchParams = new URLSearchParams();
    
    if (params?.userId) searchParams.append('userId', params.userId);
    if (params?.resourceId) searchParams.append('resourceId', params.resourceId);
    if (params?.startDate) searchParams.append('startDate', params.startDate);
    if (params?.endDate) searchParams.append('endDate', params.endDate);

    const queryString = searchParams.toString();
    const endpoint = `/analytics/efficiency${queryString ? `?${queryString}` : ''}`;

    return await apiClient.get(endpoint);
  },

  // Admin: Get executive reporting data (admin only)
  getExecutiveReport: async (params?: {
    startDate?: string;
    endDate?: string;
    department?: string;
  }): Promise<any> => {
    const searchParams = new URLSearchParams();
    
    if (params?.startDate) searchParams.append('startDate', params.startDate);
    if (params?.endDate) searchParams.append('endDate', params.endDate);
    if (params?.department) searchParams.append('department', params.department);

    const queryString = searchParams.toString();
    const endpoint = `/admin/analytics/report${queryString ? `?${queryString}` : ''}`;

    return await apiClient.get(endpoint);
  },

  // Export analytics data (admin only)
  exportAnalytics: async (format: 'csv' | 'pdf', params?: {
    type: 'utilization' | 'trends' | 'efficiency' | 'report';
    startDate?: string;
    endDate?: string;
  }): Promise<Blob> => {
    const searchParams = new URLSearchParams();
    
    searchParams.append('format', format);
    if (params?.type) searchParams.append('type', params.type);
    if (params?.startDate) searchParams.append('startDate', params.startDate);
    if (params?.endDate) searchParams.append('endDate', params.endDate);

    const queryString = searchParams.toString();
    const endpoint = `/admin/analytics/export${queryString ? `?${queryString}` : ''}`;

    // For file downloads, we need to handle the response differently
    const response = await fetch(`${apiClient.baseUrl}${endpoint}`, {
      method: 'GET',
      headers: await apiClient.getHeaders(),
    });

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }

    return await response.blob();
  },
};