/**
 * Environment Setup for Browser
 * This script sets up environment variables that can be accessed by other modules
 */

// Auto-detect environment based on hostname
const isLocalhost = window.location.hostname === 'localhost' || 
                    window.location.hostname === '127.0.0.1' ||
                    window.location.hostname === '';

// Set backend URL - auto-switch between local and production
const LOCAL_BACKEND_URL = 'http://127.0.0.1:8000';
const PRODUCTION_BACKEND_URL = 'https://prototype-production-6284.up.railway.app'; // ✅ Railway backend URL

window.BACKEND_URL = isLocalhost ? LOCAL_BACKEND_URL : PRODUCTION_BACKEND_URL;

// You can also set other environment variables here
window.APP_ENV = window.APP_ENV || (isLocalhost ? 'development' : 'production');
window.APP_VERSION = window.APP_VERSION || '1.0.0';

// Log configuration in development
if (isLocalhost) {
  console.log('🔧 Environment:', window.APP_ENV);
  console.log('🔗 Backend URL:', window.BACKEND_URL);
}

// ---------------------------------------------------------------------------
// Console logging controls
// ---------------------------------------------------------------------------

const CONSOLE_LEVELS_TO_MUTE = ['log', 'info', 'debug', 'trace'];
const CONSOLE_STORAGE_KEY = 'uthm-dashboard:debug-logs';

const originalConsole = CONSOLE_LEVELS_TO_MUTE.reduce((acc, level) => {
  const method = console[level] ? console[level].bind(console) : console.log.bind(console);
  acc[level] = method;
  return acc;
}, {});

const restoreConsole = () => {
  CONSOLE_LEVELS_TO_MUTE.forEach((level) => {
    if (originalConsole[level]) {
      console[level] = originalConsole[level];
    }
  });
};

const silenceConsole = () => {
  const noop = () => {};
  CONSOLE_LEVELS_TO_MUTE.forEach((level) => {
    console[level] = noop;
  });
};

const isDebugFlagFromWindow = Boolean(window.ENABLE_DEBUG_LOGS);

let isDebugFlagFromStorage = false;
try {
  isDebugFlagFromStorage = window.localStorage && window.localStorage.getItem(CONSOLE_STORAGE_KEY) === 'true';
} catch (error) {
  // localStorage not available (private mode, etc.)
}

let isDebugFlagFromQuery = false;
try {
  const params = new URLSearchParams(window.location.search);
  isDebugFlagFromQuery = ['debug', 'debugLogs', 'logs'].some((key) => params.get(key) === 'true');
} catch (error) {
  // URL parsing failed; ignore
}

const shouldEnableDebugLogs = isDebugFlagFromWindow || isDebugFlagFromStorage || isDebugFlagFromQuery;

const persistDebugPreference = (enabled) => {
  try {
    if (!window.localStorage) return;
    if (enabled) {
      window.localStorage.setItem(CONSOLE_STORAGE_KEY, 'true');
    } else {
      window.localStorage.removeItem(CONSOLE_STORAGE_KEY);
    }
  } catch (error) {
    // Ignore storage failures
  }
};

window.enableDebugLogs = (persist = true) => {
  restoreConsole();
  if (persist) {
    persistDebugPreference(true);
  }
};

window.disableDebugLogs = (persist = true) => {
  silenceConsole();
  if (persist) {
    persistDebugPreference(false);
  }
};

if (window.APP_ENV === 'production' && !shouldEnableDebugLogs) {
  silenceConsole();
} else {
  restoreConsole();
}

window.isDebugLoggingEnabled = () => console.log === originalConsole.log;

if (window.APP_ENV === 'production' && !shouldEnableDebugLogs && originalConsole.info) {
  originalConsole.info('ℹ️ Console logs disekat untuk mode production. Jalankan enableDebugLogs() untuk debug.');
}
