'use client';

import { useEffect, useState } from 'react';
import ApiService from '../lib/apiService';
import { useAuth } from '../lib/contexts/AuthContext';

interface Resource {
  name: string;
  id: string;
  type?: string;
  status?: string;
}

export default function ResourceList() {
  const [resources, setResources] = useState<Resource[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const { initialize } = useAuth();
  const apiService = ApiService.getInstance();

  useEffect(() => {
    // Make sure auth is initialized first
    initialize().then(() => {
      fetchResources();
    });
  }, []);

  const fetchResources = async () => {
    try {
      setLoading(true);
      // Call the resources endpoint from the gateway service
      const data = await apiService.get('/api/resources');
      console.log('Resources data:', data);
      
      // If the API returns resources in a different format, adjust this
      if (data?.resources) {
        setResources(data.resources.map((name: string, index: number) => ({
          name,
          id: `resource-${index}`
        })));
      } else {
        // Mock data in case the endpoint isn't available yet
        setResources([
          { name: 'Lecture Hall A', id: 'resource-1' },
          { name: 'Computer Lab 1', id: 'resource-2' },
          { name: 'Study Room Alpha', id: 'resource-3' }
        ]);
      }
      setError(null);
    } catch (err) {
      console.error('Error fetching resources:', err);
      setError('Failed to fetch resources. Please try again later.');
      // Set mock data for testing
      setResources([
        { name: 'Lecture Hall A', id: 'resource-1' },
        { name: 'Computer Lab 1', id: 'resource-2' },
        { name: 'Study Room Alpha', id: 'resource-3' }
      ]);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="p-4 bg-white rounded-lg shadow">
      <h2 className="text-xl font-bold mb-4">Available Resources</h2>
      
      {loading && <p>Loading resources...</p>}
      
      {error && (
        <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
          <p>{error}</p>
          <p className="text-sm">Using mock data for demonstration</p>
        </div>
      )}
      
      {!loading && !error && resources.length === 0 && (
        <p>No resources available.</p>
      )}
      
      {resources.length > 0 && (
        <ul className="divide-y divide-gray-200">
          {resources.map((resource) => (
            <li key={resource.id} className="py-3">
              <div className="flex items-center space-x-4">
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-gray-900 truncate">
                    {resource.name}
                  </p>
                  {resource.type && (
                    <p className="text-sm text-gray-500 truncate">
                      Type: {resource.type}
                    </p>
                  )}
                </div>
                {resource.status && (
                  <div className="inline-flex items-center text-sm font-semibold">
                    Status: {resource.status}
                  </div>
                )}
              </div>
            </li>
          ))}
        </ul>
      )}
      
      <button 
        onClick={fetchResources}
        className="mt-4 px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 transition-colors"
      >
        Refresh Resources
      </button>
    </div>
  );
}