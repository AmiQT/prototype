/**
 * Backend Configuration for Cloud Development
 * Update these URLs after deploying your backend
 */

const BACKEND_CONFIG = {
  // ✅ ARCHITECTURE: Custom backend for advanced features
  // CRUD primarily via Supabase; backend optional but supported
  baseUrl: window.BACKEND_URL || null,
  
  // Data mining endpoints (if backend is deployed for analytics)
  dataMiningUrl: null, // Will be set when data mining features are needed
  
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

    media: '/api/media',
    search: '/api/search',
    analytics: '/api/analytics',
    profiles: '/api/profiles',
    showcase: '/api/showcase',
    sync: '/api/sync',
    ai: {
      command: '/api/ai/command',
      history: '/api/ai/history'
    },
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
    const { data: { session }, error } = await supabase.auth.getSession();
    
    if (error) {
      console.warn('Supabase getSession error:', error);
    }
    
    if (session?.access_token) {
      token = session.access_token;
      console.log('✅ Got Supabase access token:', token.substring(0, 20) + '...');
    } else {
      console.warn('No session found. Session:', session);
    }
  } catch (error) {
    console.warn('Could not get Supabase session:', error);
  }
  
  // Fallback to localStorage token
  if (!token) {
    token = localStorage.getItem(BACKEND_CONFIG.auth.tokenKey);
    if (token) {
      console.log('✅ Using token from localStorage');
    } else {
      console.warn('❌ No token found in localStorage or Supabase session');
    }
  }
  
  return {
    ...BACKEND_CONFIG.cors.headers,
    ...(token && { 'Authorization': `Bearer ${token}` })
  };
}

// Fallback function for Supabase-only approach
async function testBackendConnection() {
  if (!BACKEND_CONFIG.baseUrl) {
    console.warn('Backend baseUrl not configured.');
    return false;
  }

  try {
    const response = await fetch(`${BACKEND_CONFIG.baseUrl}${API_ENDPOINTS.system.status}`, {
      method: 'GET',
      headers: await getAuthHeaders(),
      credentials: 'include',
      signal: AbortSignal.timeout?.(BACKEND_CONFIG.timeout) ?? undefined
    });

    if (!response.ok) {
      console.warn(`Backend status check failed: ${response.status}`);
      return false;
    }

    return true;
  } catch (error) {
    console.warn('Backend status check error:', error.message);
    return false;
  }
}

async function makeAuthenticatedRequest(endpoint, options = {}) {
  if (!BACKEND_CONFIG.baseUrl) {
    console.warn('Backend baseUrl not configured. Request aborted.');
    throw new Error('Backend baseUrl not configured');
  }

  const url = endpoint.startsWith('http') ? endpoint : `${BACKEND_CONFIG.baseUrl}${endpoint}`;

  const headers = await getAuthHeaders();
  
  console.log('🔐 Request Headers:', headers);

  const method = (options.method || 'GET').toUpperCase();
  let body = options.body;
  if (body && typeof body === 'object' && !(body instanceof FormData)) {
    body = JSON.stringify(body);
  }

  const requestOptions = {
    method,
    credentials: 'include',
    body,
    ...options,
    headers: {  // ← MOVE headers AFTER ...options to prevent overwrite
      ...headers,
      ...(options.headers || {})
    },
    method // ensure method stays correct after spread
  };
  
  console.log(`📤 ${method} ${url}`);
  console.log('   Final Headers:', requestOptions.headers);
  console.log('   Body:', body);

  const controller = typeof AbortController !== 'undefined' ? new AbortController() : null;
  const timeoutId = controller ? setTimeout(() => controller.abort(), BACKEND_CONFIG.timeout) : null;

  if (controller && !requestOptions.signal) {
    requestOptions.signal = controller.signal;
  }

  try {
    const response = await fetch(url, requestOptions);
    const contentType = response.headers.get('content-type') || '';
    
    console.log(`📥 Response Status: ${response.status}`);

    if (!response.ok) {
      let errorPayload = null;
      if (contentType.includes('application/json')) {
        errorPayload = await response.json().catch(() => null);
      } else {
        errorPayload = await response.text().catch(() => null);
      }
      const errorMessage = typeof errorPayload === 'string' ? errorPayload : JSON.stringify(errorPayload);
      throw new Error(`Request failed (${response.status}): ${errorMessage}`);
    }

    if (response.status === 204 || method === 'HEAD') {
      return null;
    }

    if (contentType.includes('application/json')) {
      return await response.json();
    }
    return await response.text();
  } finally {
    if (timeoutId) {
      clearTimeout(timeoutId);
    }
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
