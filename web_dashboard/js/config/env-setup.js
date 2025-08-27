/**
 * Environment Setup for Browser
 * This script sets up environment variables that can be accessed by other modules
 */

// COMMENTED OUT: Custom backend URL - Using Supabase only
// window.BACKEND_URL = 'https://prototype-348e.onrender.com';
window.BACKEND_URL = null; // Disabled for Supabase-only approach

// You can also set other environment variables here
window.APP_ENV = 'production';
window.APP_VERSION = '1.0.0';

console.log('Environment variables set:', {
  BACKEND_URL: window.BACKEND_URL || 'disabled',
  APP_ENV: window.APP_ENV,
  APP_VERSION: window.APP_VERSION
});
