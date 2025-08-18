// services/resourceService.ts
import { apiClient } from './api';
import { Resource, ResourceAvailability } from '@/types/resource';

// Resource service functions
export const resourceService = {
  // Get all resources with optional filtering
  getAllResources: async (params?: {
    type?: string;
    building?: string;
    capacity?: number;
    features?: string[];
    status?: string;
    page?: number;
    limit?: number;
    search?: string;
  }): Promise<{ resources: Resource[]; totalCount: number }> => {
    const searchParams = new URLSearchParams();
    
    if (params?.type) searchParams.append('type', params.type);
    if (params?.building) searchParams.append('building', params.building);
    if (params?.capacity) searchParams.append('capacity', params.capacity.toString());
    if (params?.status) searchParams.append('status', params.status);
    if (params?.page) searchParams.append('page', params.page.toString());
    if (params?.limit) searchParams.append('limit', params.limit.toString());
    if (params?.search) searchParams.append('search', params.search);
    
    // Handle features array
    if (params?.features && params.features.length > 0) {
      params.features.forEach(feature => searchParams.append('features', feature));
    }

    const queryString = searchParams.toString();
    const endpoint = `/resources${queryString ? `?${queryString}` : ''}`;

    return await apiClient.get<{ resources: Resource[]; totalCount: number }>(endpoint);
  },

  // Get a specific resource by ID
  getResourceById: async (id: string): Promise<Resource> => {
    return await apiClient.get<Resource>(`/resources/${id}`);
  },

  // Get resource availability
  getResourceAvailability: async (
    id: string,
    startDate: string,
    endDate: string
  ): Promise<ResourceAvailability[]> => {
    const searchParams = new URLSearchParams({
      startDate,
      endDate
    });

    const queryString = searchParams.toString();
    const endpoint = `/resources/${id}/availability${queryString ? `?${queryString}` : ''}`;

    return await apiClient.get<ResourceAvailability[]>(endpoint);
  },

  // Admin: Create a new resource (admin/staff only)
  createResource: async (resourceData: Omit<Resource, 'id' | 'createdAt' | 'updatedAt'>): Promise<Resource> => {
    return await apiClient.post<Resource>('/resources', resourceData);
  },

  // Admin: Update a resource (admin/staff only)
  updateResource: async (id: string, resourceData: Partial<Resource>): Promise<Resource> => {
    return await apiClient.put<Resource>(`/resources/${id}`, resourceData);
  },

  // Admin: Delete a resource (admin only)
  deleteResource: async (id: string): Promise<void> => {
    return await apiClient.delete<void>(`/resources/${id}`);
  },

  // Admin: Update resource status (admin/staff only)
  updateResourceStatus: async (id: string, status: string): Promise<Resource> => {
    return await apiClient.put<Resource>(`/resources/${id}/status`, { status });
  },
};