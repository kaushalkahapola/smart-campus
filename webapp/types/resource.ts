// types/resource.ts
export type ResourceType = 
  | 'lecture_hall' 
  | 'computer_lab' 
  | 'meeting_room' 
  | 'study_room' 
  | 'equipment' 
  | 'vehicle';

export type ResourceStatus = 
  | 'available' 
  | 'maintenance' 
  | 'unavailable' 
  | 'reserved';

export interface Resource {
  id: string;
  name: string;
  type: ResourceType;
  capacity: number;
  features: Record<string, any>; // Flexible features object
  location: string;
  building: string;
  floor: string;
  roomNumber: string;
  status: ResourceStatus;
  imageUrl?: string;
  description?: string;
  createdAt: string; // ISO date string
  updatedAt: string; // ISO date string
}

export interface ResourceAvailability {
  date: string; // YYYY-MM-DD
  timeSlots: TimeSlot[];
}

export interface TimeSlot {
  startTime: string; // HH:mm
  endTime: string; // HH:mm
  isAvailable: boolean;
  bookingId?: string; // If booked, reference to booking
}