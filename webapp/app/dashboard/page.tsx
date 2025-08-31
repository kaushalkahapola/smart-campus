'use client';

import { useEffect, useState } from 'react';
import { useAppSelector } from '../lib/redux/hooks';
import { selectAccessToken, selectIsAuthenticated } from '../lib/redux/slices/authSlice';
import ApiService from '../lib/apiService';
import Navigation from '../components/Navigation';

interface Resource {
  id: string;
  name: string;
  type: string;
  location: string;
  capacity: number;
}

export default function Dashboard() {
  const isAuthenticated = useAppSelector(selectIsAuthenticated);
  const accessToken = useAppSelector(selectAccessToken);
  const [resources, setResources] = useState<Resource[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    // Example of using the API service
    const fetchResources = async () => {
      if (!isAuthenticated || !accessToken) {
        setError('You must be logged in to view resources');
        setLoading(false);
        return;
      }

      try {
        const apiService = ApiService.getInstance();
        // Set the token (this is also done in AuthContext, but showing as an example)
        apiService.setAccessToken(accessToken);
        
        // Example API call using the service
        // In a real app, replace with actual endpoint
        const data = await apiService.get<Resource[]>('/resources');
        setResources(data);
        setLoading(false);
      } catch (err) {
        console.error('Error fetching resources:', err);
        setError('Failed to load resources. API might not be available yet.');
        setLoading(false);
        
        // For demo purposes, set some mock data
        setResources([
          { id: '1', name: 'Lecture Hall A', type: 'Classroom', location: 'Building 1', capacity: 100 },
          { id: '2', name: 'Computer Lab', type: 'Lab', location: 'Building 2', capacity: 30 },
          { id: '3', name: 'Conference Room', type: 'Meeting Room', location: 'Building 3', capacity: 20 },
        ]);
      }
    };

    fetchResources();
  }, [isAuthenticated, accessToken]);

  if (!isAuthenticated) {
    return (
      <>
        <Navigation />
        <div className="flex flex-col items-center justify-center flex-grow text-center gap-6">
          <h1 className="text-2xl font-bold">Dashboard</h1>
          <p>Please log in to view the dashboard</p>
        </div>
      </>
    );
  }

  return (
    <>
      <Navigation />
      <div className="flex flex-col items-center justify-center flex-grow p-6">
      <h1 className="text-2xl font-bold mb-6">Resource Dashboard</h1>
      
      {loading ? (
        <p>Loading resources...</p>
      ) : error ? (
        <div className="text-red-500">{error}</div>
      ) : (
        <div className="w-full max-w-4xl">
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {resources.map((resource) => (
              <div key={resource.id} className="border rounded-lg p-4 shadow-sm">
                <h2 className="text-lg font-semibold">{resource.name}</h2>
                <p><span className="font-medium">Type:</span> {resource.type}</p>
                <p><span className="font-medium">Location:</span> {resource.location}</p>
                <p><span className="font-medium">Capacity:</span> {resource.capacity}</p>
                <button className="mt-2 px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600">
                  Book Now
                </button>
              </div>
            ))}
          </div>
        </div>
      )}
      
      <div className="mt-8">
        <p className="text-sm text-gray-500">
          Note: This is a demo dashboard. The API integration is ready but the backend might not be available yet.
          Check the console for the access token that will be used for API calls.
        </p>
      </div>
    </div>
    </>
  );
}