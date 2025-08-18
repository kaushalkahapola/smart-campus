// hooks/useResources.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { resourceService } from '@/services/resourceService';
import { Resource, ResourceAvailability } from '@/types/resource';

// Query keys for resource-related queries
export const resourceQueryKeys = {
  all: ['resources'] as const,
  list: (params: any) => [...resourceQueryKeys.all, 'list', params] as const,
  detail: (id: string) => [...resourceQueryKeys.all, 'detail', id] as const,
  availability: (id: string, startDate: string, endDate: string) => 
    [...resourceQueryKeys.all, 'availability', id, startDate, endDate] as const,
};

// Hook to get all resources
export const useResources = (params?: {
  type?: string;
  building?: string;
  capacity?: number;
  features?: string[];
  status?: string;
  page?: number;
  limit?: number;
  search?: string;
}) => {
  return useQuery<{ resources: Resource[]; totalCount: number }, Error>({
    queryKey: resourceQueryKeys.list(params || {}),
    queryFn: () => resourceService.getAllResources(params),
    placeholderData: (previousData) => previousData, // Keep previous data while fetching new data
  });
};

// Hook to get a specific resource by ID
export const useResource = (id: string) => {
  return useQuery<Resource, Error>({
    queryKey: resourceQueryKeys.detail(id),
    queryFn: () => resourceService.getResourceById(id),
    enabled: !!id, // Only run the query if id is truthy
  });
};

// Hook to get resource availability
export const useResourceAvailability = (
  id: string,
  startDate: string,
  endDate: string
) => {
  return useQuery<ResourceAvailability[], Error>({
    queryKey: resourceQueryKeys.availability(id, startDate, endDate),
    queryFn: () => resourceService.getResourceAvailability(id, startDate, endDate),
    enabled: !!id && !!startDate && !!endDate, // Only run the query if all params are truthy
  });
};

// Hook to create a resource (admin/staff only)
export const useCreateResource = () => {
  const queryClient = useQueryClient();
  
  return useMutation<Resource, Error, Omit<Resource, 'id' | 'createdAt' | 'updatedAt'>>({
    mutationFn: (resourceData) => resourceService.createResource(resourceData),
    onSuccess: () => {
      // Invalidate the resources list to refetch it
      queryClient.invalidateQueries({ queryKey: resourceQueryKeys.list({}) });
      
      // Show a success message to the user
      console.log('Resource created successfully');
    },
    onError: (error) => {
      // Show an error message to the user
      console.error('Failed to create resource:', error);
    },
  });
};

// Hook to update a resource (admin/staff only)
export const useUpdateResource = () => {
  const queryClient = useQueryClient();
  
  return useMutation<Resource, Error, { id: string; data: Partial<Resource> }>({
    mutationFn: ({ id, data }) => resourceService.updateResource(id, data),
    onSuccess: (updatedResource) => {
      // Update the resource in the cache
      queryClient.setQueryData(resourceQueryKeys.detail(updatedResource.id), updatedResource);
      
      // Invalidate the resources list to refetch it
      queryClient.invalidateQueries({ queryKey: resourceQueryKeys.list({}) });
      
      // Show a success message to the user
      console.log('Resource updated successfully');
    },
    onError: (error) => {
      // Show an error message to the user
      console.error('Failed to update resource:', error);
    },
  });
};

// Hook to delete a resource (admin only)
export const useDeleteResource = () => {
  const queryClient = useQueryClient();
  
  return useMutation<void, Error, string>({
    mutationFn: (id) => resourceService.deleteResource(id),
    onSuccess: (_, id) => {
      // Remove the resource from the cache
      queryClient.removeQueries({ queryKey: resourceQueryKeys.detail(id) });
      
      // Invalidate the resources list to refetch it
      queryClient.invalidateQueries({ queryKey: resourceQueryKeys.list({}) });
      
      // Show a success message to the user
      console.log('Resource deleted successfully');
    },
    onError: (error) => {
      // Show an error message to the user
      console.error('Failed to delete resource:', error);
    },
  });
};

// Hook to update resource status (admin/staff only)
export const useUpdateResourceStatus = () => {
  const queryClient = useQueryClient();
  
  return useMutation<Resource, Error, { id: string; status: string }>({
    mutationFn: ({ id, status }) => resourceService.updateResourceStatus(id, status),
    onSuccess: (updatedResource) => {
      // Update the resource in the cache
      queryClient.setQueryData(resourceQueryKeys.detail(updatedResource.id), updatedResource);
      
      // Invalidate the resources list to refetch it
      queryClient.invalidateQueries({ queryKey: resourceQueryKeys.list({}) });
      
      // Show a success message to the user
      console.log('Resource status updated successfully');
    },
    onError: (error) => {
      // Show an error message to the user
      console.error('Failed to update resource status:', error);
    },
  });
};