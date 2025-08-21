/**
 * Environment Setup for Browser
 * This script sets up environment variables that can be accessed by other modules
 */

// Set environment variables for browser
window.BACKEND_URL = 'https://prototype-348e.onrender.com';

// You can also set other environment variables here
window.APP_ENV = 'production';
window.APP_VERSION = '1.0.0';

console.log('Environment variables set:', {
  BACKEND_URL: window.BACKEND_URL,
  APP_ENV: window.APP_ENV,
  APP_VERSION: window.APP_VERSION
});
