// hooks/useAI.ts
import { useQuery, useMutation } from '@tanstack/react-query';
import { aiService } from '@/services/aiService';

// Query keys for AI-related queries
export const aiQueryKeys = {
  all: ['ai'] as const,
  recommendations: (params: any) => [...aiQueryKeys.all, 'recommendations', params] as const,
  timeSlots: (params: any) => [...aiQueryKeys.all, 'timeSlots', params] as const,
  usagePatterns: (userId?: string) => [...aiQueryKeys.all, 'usagePatterns', userId] as const,
  predictions: (resourceId: string, daysAhead: number) => 
    [...aiQueryKeys.all, 'predictions', resourceId, daysAhead] as const,
  anomalies: (resourceId: string, days: number) => 
    [...aiQueryKeys.all, 'anomalies', resourceId, days] as const,
};

// Hook to get resource recommendations
export const useResourceRecommendations = (params: {
  userId?: string;
  resourceType?: string;
  capacity?: number;
  features?: string[];
  startTime?: string;
  endTime?: string;
}) => {
  return useQuery<any, Error>({
    queryKey: aiQueryKeys.recommendations(params),
    queryFn: () => aiService.getResourceRecommendations(params),
    enabled: !!params.startTime && !!params.endTime, // Only run if time params are provided
  });
};

// Hook to get time slot recommendations
export const useTimeSlotRecommendations = (params: {
  userId?: string;
  resourceId: string;
  duration: number; // in minutes
  startDate?: string;
  endDate?: string;
}) => {
  return useQuery<any, Error>({
    queryKey: aiQueryKeys.timeSlots(params),
    queryFn: () => aiService.getTimeSlotRecommendations(params),
    enabled: !!params.resourceId && params.duration > 0, // Only run if required params are provided
  });
};

// Hook to get user usage patterns
export const useUserUsagePatterns = (userId?: string) => {
  return useQuery<any, Error>({
    queryKey: aiQueryKeys.usagePatterns(userId),
    queryFn: () => aiService.getUserUsagePatterns(userId),
  });
};

// Hook to get resource predictions
export const useResourcePredictions = (resourceId: string, daysAhead: number = 7) => {
  return useQuery<any, Error>({
    queryKey: aiQueryKeys.predictions(resourceId, daysAhead),
    queryFn: () => aiService.getResourcePredictions(resourceId, daysAhead),
    enabled: !!resourceId, // Only run if resourceId is provided
  });
};

// Hook to get resource anomalies
export const useResourceAnomalies = (resourceId: string, days: number = 30) => {
  return useQuery<any, Error>({
    queryKey: aiQueryKeys.anomalies(resourceId, days),
    queryFn: () => aiService.getResourceAnomalies(resourceId, days),
    enabled: !!resourceId, // Only run if resourceId is provided
  });
};