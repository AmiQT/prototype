/**
 * Supabase Configuration
 * Replace Firebase with Supabase for authentication and database
 */

// Supabase configuration
const SUPABASE_CONFIG = {
  url: 'https://xibffemtpboiecpeynon.supabase.co',
  anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhpYmZmZW10cGJvaWVjcGV5bm9uIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU1ODkzOTYsImV4cCI6MjA3MTE2NTM5Nn0.mwQndhu5_uX26T-qTEOCiLya74DUD6Iw8vV3ffuA5mM'
};

// Initialize Supabase client - use global supabase object from CDN
let supabaseClient;

// Check if supabase is available globally (v2 API)
if (typeof window !== 'undefined' && window.supabase) {
  try {
    // For Supabase v2, the createClient is directly on window.supabase
    supabaseClient = window.supabase.createClient(SUPABASE_CONFIG.url, SUPABASE_CONFIG.anonKey);
    console.log('Supabase client initialized successfully');
  } catch (error) {
    console.error('Error initializing Supabase client:', error);
    supabaseClient = null;
  }
} else {
  // Fallback - create a mock client
  console.warn('Supabase not loaded or createClient not available, using mock client');
  supabaseClient = {
    auth: {
      signInWithPassword: async () => ({ data: null, error: new Error('Supabase not loaded') }),
      signOut: async () => ({ error: new Error('Supabase not loaded') }),
      getUser: async () => ({ data: { user: null }, error: new Error('Supabase not loaded') }),
      onAuthStateChange: () => ({ data: { subscription: null } })
    },
    from: () => ({
      select: () => ({ data: null, error: new Error('Supabase not loaded') }),
      insert: () => ({ data: null, error: new Error('Supabase not loaded') }),
      update: () => ({ data: null, error: new Error('Supabase not loaded') }),
      delete: () => ({ data: null, error: new Error('Supabase not loaded') }),
      match: () => ({ data: null, error: new Error('Supabase not loaded') })
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
