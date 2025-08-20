/**
 * Backend Configuration for Cloud Development
 * Update these URLs after deploying your backend
 */

const BACKEND_CONFIG = {
  // Backend API URLs
  baseUrl: process.env.BACKEND_URL || 'https://prototype-348e.onrender.com',
  
  // API Endpoints
  endpoints: {
    auth: '/api/auth',
    users: '/api/users',
    events: '/api/events',
    achievements: '/api/achievements',
    media: '/api/media',
    search: '/api/search',
    analytics: '/api/analytics',
    profiles: '/api/profiles',
    showcase: '/api/showcase',
    sync: '/api/sync',
    system: {
      status: '/api/system/status',
      health: '/api/system/health'
    }
  },
  
  // API Settings
  timeout: 30000, // 30 seconds
  retryAttempts: 3,
  retryDelay: 1000, // 1 second
  
  // Authentication
  auth: {
    tokenKey: 'auth_token',
    refreshTokenKey: 'refresh_token',
    tokenExpiryKey: 'token_expiry'
  },
  
  // CORS Settings
  cors: {
    credentials: true,
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    }
  },
  
  // Feature Flags
  features: {
    enableRealTimeUpdates: true,
    enableOfflineMode: true,
    enablePushNotifications: true,
    enableAnalytics: true
  },
  
  // Development Settings
  development: {
    enableLogging: true,
    enableMockData: false,
    enablePerformanceMonitoring: true
  }
};

// Export API_ENDPOINTS for compatibility
export const API_ENDPOINTS = BACKEND_CONFIG.endpoints;

// Helper function to get full API URL
export function getApiUrl(endpoint) {
  return `${BACKEND_CONFIG.baseUrl}${endpoint}`;
}

// Helper function to get auth headers
export function getAuthHeaders() {
  const token = localStorage.getItem(BACKEND_CONFIG.auth.tokenKey);
  return {
    ...BACKEND_CONFIG.cors.headers,
    ...(token && { 'Authorization': `Bearer ${token}` })
  };
}

// Helper function for authenticated requests
export async function makeAuthenticatedRequest(endpoint, options = {}) {
  try {
    const url = getApiUrl(endpoint);
    const headers = getAuthHeaders();
    
    const response = await fetch(url, {
      ...options,
      headers: {
        ...headers,
        ...options.headers
      }
    });
    
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }
    
    return await response.json();
  } catch (error) {
    console.error(`Request failed for ${endpoint}:`, error);
    throw error;
  }
}

// Helper function to test backend connection
export async function testBackendConnection() {
  try {
    const response = await fetch(`${BACKEND_CONFIG.baseUrl}/docs`, {
      method: 'GET',
      headers: {
        'Accept': 'text/html'
      }
    });
    return response.ok;
  } catch (error) {
    console.error('Backend connection test failed:', error);
    return false;
  }
}

// Export configuration
if (typeof module !== 'undefined' && module.exports) {
  // Node.js environment
  module.exports = { 
    BACKEND_CONFIG, 
    API_ENDPOINTS,
    getApiUrl, 
    getAuthHeaders, 
    makeAuthenticatedRequest,
    testBackendConnection
  };
} else {
  // Browser environment
  window.BACKEND_CONFIG = BACKEND_CONFIG;
  window.API_ENDPOINTS = API_ENDPOINTS;
  window.getApiUrl = getApiUrl;
  window.getAuthHeaders = getAuthHeaders;
  window.makeAuthenticatedRequest = makeAuthenticatedRequest;
  window.testBackendConnection = testBackendConnection;
}