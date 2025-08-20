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
    sync: '/api/sync'
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
function getAuthHeaders() {
  const token = localStorage.getItem(BACKEND_CONFIG.auth.tokenKey);
  return {
    ...BACKEND_CONFIG.cors.headers,
    ...(token && { 'Authorization': `Bearer ${token}` })
  };
}

// Export configuration
if (typeof module !== 'undefined' && module.exports) {
  // Node.js environment
  module.exports = { BACKEND_CONFIG, getApiUrl, getAuthHeaders };
} else {
  // Browser environment
  window.BACKEND_CONFIG = BACKEND_CONFIG;
  window.getApiUrl = getApiUrl;
  window.getAuthHeaders = getAuthHeaders;
}