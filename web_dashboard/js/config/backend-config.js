/**
 * Backend Configuration for Cloud Development
 * Update these URLs after deploying your backend
 */

const BACKEND_CONFIG = {
  // Backend API URLs - Use environment variable or fallback
  baseUrl: 'https://prototype-348e.onrender.com',
  
  // API Endpoints
  endpoints: {
    auth: '/api/auth',
    users: {
      list: '/api/users',
      create: '/api/users',
      get: '/api/users',
      update: '/api/users',
      delete: '/api/users',
      getStats: '/api/users/stats'
    },
    events: {
      list: '/api/events',
      create: '/api/events',
      get: '/api/events',
      update: '/api/events',
      delete: '/api/events'
    },
    achievements: '/api/achievements',
    media: '/api/media',
    search: '/api/search',
    analytics: '/api/analytics',
    profiles: '/api/profiles',
    showcase: '/api/showcase',
    sync: '/api/sync',
    system: {
      status: '/health',
      health: '/health'
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

// Helper function to get full API URL
function getApiUrl(endpoint) {
  return `${BACKEND_CONFIG.baseUrl}${endpoint}`;
}

// Helper function to get auth headers
async function getAuthHeaders() {
  // Try to get Supabase session token
  let token = null;
  
  try {
    // Import supabase client
    const { supabase } = await import('./supabase-config.js');
    const { data: { session } } = await supabase.auth.getSession();
    
    if (session?.access_token) {
      token = session.access_token;
    }
  } catch (error) {
    console.warn('Could not get Supabase session:', error);
  }
  
  // Fallback to localStorage token
  if (!token) {
    token = localStorage.getItem(BACKEND_CONFIG.auth.tokenKey);
  }
  
  return {
    ...BACKEND_CONFIG.cors.headers,
    ...(token && { 'Authorization': `Bearer ${token}` })
  };
}

// Helper function to test backend connection
async function testBackendConnection() {
  try {
    // Try the correct health endpoint
    const response = await fetch(`${BACKEND_CONFIG.baseUrl}/health`, {
      method: 'GET',
      headers: BACKEND_CONFIG.cors.headers,
      timeout: BACKEND_CONFIG.timeout
    });
    return response.ok;
  } catch (error) {
    console.warn('Backend connection test failed, using fallback:', error.message);
    return false;
  }
}

// Helper function to make authenticated requests
async function makeAuthenticatedRequest(endpoint, options = {}) {
  try {
    const url = getApiUrl(endpoint);
    const headers = await getAuthHeaders(); // Now async
    
    const response = await fetch(url, {
      ...options,
      headers: { ...headers, ...options.headers }
    });
    
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }
    
    return await response.json();
  } catch (error) {
    console.error('Authenticated request failed:', error);
    throw error;
  }
}

// Export configuration for ES6 modules
export const API_ENDPOINTS = BACKEND_CONFIG.endpoints;
export { BACKEND_CONFIG, getApiUrl, getAuthHeaders, testBackendConnection, makeAuthenticatedRequest };

// Fallback for older browsers
if (typeof window !== 'undefined') {
  window.BACKEND_CONFIG = BACKEND_CONFIG;
  window.API_ENDPOINTS = API_ENDPOINTS;
  window.getApiUrl = getApiUrl;
  window.getAuthHeaders = getAuthHeaders;
  window.testBackendConnection = testBackendConnection;
  window.makeAuthenticatedRequest = makeAuthenticatedRequest;
}