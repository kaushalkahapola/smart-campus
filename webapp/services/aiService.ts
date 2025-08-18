// services/aiService.ts
import { apiClient } from './api';

// AI service functions
export const aiService = {
  // Get AI-powered resource recommendations
  getResourceRecommendations: async (params: {
    userId?: string;
    resourceType?: string;
    capacity?: number;
    features?: string[];
    startTime?: string;
    endTime?: string;
  }): Promise<any> => {
    return await apiClient.post('/ai/recommend/resources', params);
  },

  // Get optimal time slot recommendations
  getTimeSlotRecommendations: async (params: {
    userId?: string;
    resourceId: string;
    duration: number; // in minutes
    startDate?: string;
    endDate?: string;
  }): Promise<any> => {
    return await apiClient.post('/ai/recommend/times', params);
  },

  // Get usage pattern analysis for a user
  getUserUsagePatterns: async (userId?: string): Promise<any> => {
    const endpoint = userId 
      ? `/ai/analytics/user/${userId}` 
      : '/ai/analytics/user';
    return await apiClient.get(endpoint);
  },

  // Get resource utilization predictions
  getResourcePredictions: async (resourceId: string, daysAhead: number = 7): Promise<any> => {
    return await apiClient.get(`/ai/predict/resource/${resourceId}?days=${daysAhead}`);
  },

  // Get anomaly detection for resource usage
  getResourceAnomalies: async (resourceId: string, days: number = 30): Promise<any> => {
    return await apiClient.get(`/ai/anomaly/resource/${resourceId}?days=${days}`);
  },
};