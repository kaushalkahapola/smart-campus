'use client';

import axios, { AxiosInstance, AxiosRequestConfig } from 'axios';

class ApiService {
  private static instance: ApiService;
  private axiosInstance: AxiosInstance;
  private accessToken: string | null = null;

  private constructor() {
    this.axiosInstance = axios.create({
      baseURL: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080', // Default to gateway service port
      timeout: 10000,
      headers: {
        'Content-Type': 'application/json',
      },
    });

    // Request interceptor to add auth token
    this.axiosInstance.interceptors.request.use(
      (config) => {
        if (this.accessToken) {
          config.headers['Authorization'] = `Bearer ${this.accessToken}`;
        }
        return config;
      },
      (error) => {
        return Promise.reject(error);
      }
    );

    // Response interceptor for error handling
    this.axiosInstance.interceptors.response.use(
      (response) => response,
      (error) => {
        // Handle common errors (401, 403, etc.)
        if (error.response) {
          if (error.response.status === 401) {
            // Handle unauthorized access
            console.error('Unauthorized access. Please login again.');
            // Could redirect to login page or refresh token
          }
        }
        return Promise.reject(error);
      }
    );
  }

  public static getInstance(): ApiService {
    if (!ApiService.instance) {
      ApiService.instance = new ApiService();
    }
    return ApiService.instance;
  }

  public setAccessToken(token: string): void {
    this.accessToken = token;
  }

  public clearAccessToken(): void {
    this.accessToken = null;
  }

  public getAxiosInstance(): AxiosInstance {
    return this.axiosInstance;
  }

  // Helper methods for common HTTP requests
  public async get<T>(url: string, config?: AxiosRequestConfig): Promise<T> {
    const response = await this.axiosInstance.get<T>(url, config);
    return response.data;
  }

  public async post<T>(url: string, data?: any, config?: AxiosRequestConfig): Promise<T> {
    const response = await this.axiosInstance.post<T>(url, data, config);
    return response.data;
  }

  public async put<T>(url: string, data?: any, config?: AxiosRequestConfig): Promise<T> {
    const response = await this.axiosInstance.put<T>(url, data, config);
    return response.data;
  }

  public async delete<T>(url: string, config?: AxiosRequestConfig): Promise<T> {
    const response = await this.axiosInstance.delete<T>(url, config);
    return response.data;
  }
}

export default ApiService;