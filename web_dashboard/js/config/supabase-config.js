/**
 * Supabase Configuration
 * Replace Firebase with Supabase for authentication and database
 */

// Supabase configuration - load from environment or prompt user
// IMPORTANT: Replace these with your own Supabase credentials
// For production, use proper environment variable management
const SUPABASE_CONFIG = {
  url: window.ENV?.SUPABASE_URL || 'YOUR_SUPABASE_URL_HERE',
  anonKey: window.ENV?.SUPABASE_ANON_KEY || 'YOUR_SUPABASE_ANON_KEY_HERE'
};

// Check if Supabase is properly configured
const isSupabaseConfigured = () => {
  return SUPABASE_CONFIG.url && 
         SUPABASE_CONFIG.url !== 'YOUR_SUPABASE_URL_HERE' && 
         SUPABASE_CONFIG.anonKey && 
         SUPABASE_CONFIG.anonKey !== 'YOUR_SUPABASE_ANON_KEY_HERE';
};

// Initialize Supabase client - use global supabase object from CDN
let supabaseClient;

// Check if supabase is available globally (v2 API)
if (typeof window !== 'undefined' && window.supabase && isSupabaseConfigured()) {
  try {
    if (window.__sharedSupabaseClient) {
      supabaseClient = window.__sharedSupabaseClient;
      console.log('Supabase client reused');
    } else {
      supabaseClient = window.supabase.createClient(SUPABASE_CONFIG.url, SUPABASE_CONFIG.anonKey);
      window.__sharedSupabaseClient = supabaseClient;
      console.log('Supabase client initialized successfully');
    }
  } catch (error) {
    console.error('Error initializing Supabase client:', error);
    supabaseClient = null;
  }
} else {
  // Fallback - create a mock client
  if (!isSupabaseConfigured()) {
    console.warn('⚠️ Supabase not configured with valid credentials. Please set SUPABASE_URL and SUPABASE_ANON_KEY.');
  } else {
    console.warn('Supabase not loaded or createClient not available, using mock client');
  }
  
  supabaseClient = {
    auth: {
      signInWithPassword: async () => {
        const error = new Error('Supabase not properly configured. Please contact administrator.');
        error.code = 'SUPABASE_NOT_CONFIGURED';
        return { data: null, error };
      },
      signOut: async () => {
        const error = new Error('Supabase not properly configured. Please contact administrator.');
        error.code = 'SUPABASE_NOT_CONFIGURED';
        return { error };
      },
      getUser: async () => {
        const error = new Error('Supabase not properly configured. Please contact administrator.');
        error.code = 'SUPABASE_NOT_CONFIGURED';
        return { data: { user: null }, error };
      },
      getSession: async () => {
        const error = new Error('Supabase not properly configured. Please contact administrator.');
        error.code = 'SUPABASE_NOT_CONFIGURED';
        return { data: { session: null }, error };
      },
      onAuthStateChange: () => ({ data: { subscription: null } })
    },
    from: () => ({
      select: () => {
        const error = new Error('Supabase not properly configured. Please contact administrator.');
        error.code = 'SUPABASE_NOT_CONFIGURED';
        return { data: null, error };
      },
      insert: () => {
        const error = new Error('Supabase not properly configured. Please contact administrator.');
        error.code = 'SUPABASE_NOT_CONFIGURED';
        return { data: null, error };
      },
      update: () => {
        const error = new Error('Supabase not properly configured. Please contact administrator.');
        error.code = 'SUPABASE_NOT_CONFIGURED';
        return { data: null, error };
      },
      delete: () => {
        const error = new Error('Supabase not properly configured. Please contact administrator.');
        error.code = 'SUPABASE_NOT_CONFIGURED';
        return { data: null, error };
      },
      match: () => {
        const error = new Error('Supabase not properly configured. Please contact administrator.');
        error.code = 'SUPABASE_NOT_CONFIGURED';
        return { data: null, error };
      }
    })
  };
}

// Export Supabase client
export { supabaseClient as supabase };

// Helper functions for authentication
export const auth = {
  signIn: async (email, password) => {
    const { data, error } = await supabaseClient.auth.signInWithPassword({
      email,
      password
    });
    return { data, error };
  },
  
  signOut: async () => {
    const { error } = await supabaseClient.auth.signOut();
    return { error };
  },
  
  getUser: async () => {
    const { data, error } = await supabaseClient.auth.getUser();
    return { data, error };
  },

  getSession: async () => {
    const { data, error } = await supabaseClient.auth.getSession();
    return { data, error };
  },
  
  onAuthStateChange: (callback) => {
    return supabaseClient.auth.onAuthStateChange(callback);
  }
};

// Helper functions for database operations
export const db = {
  from: (table) => supabaseClient.from(table)
};

// Export configuration
export { SUPABASE_CONFIG };
