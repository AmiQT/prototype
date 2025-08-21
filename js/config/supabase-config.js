/**
 * Supabase Configuration
 * Replace Firebase with Supabase for authentication and database
 */

// Supabase configuration
const SUPABASE_CONFIG = {
  url: 'https://your-project.supabase.co',
  anonKey: 'your-anon-key'
};

// Initialize Supabase client - use global supabase object from CDN
let supabaseClient;

// Check if supabase is available globally
if (typeof window !== 'undefined' && window.supabase) {
  supabaseClient = window.supabase.createClient(SUPABASE_CONFIG.url, SUPABASE_CONFIG.anonKey);
} else {
  // Fallback - create a mock client
  console.warn('Supabase not loaded, using mock client');
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
    if (error) throw error;
    return data;
  },
  
  signOut: async () => {
    const { error } = await supabaseClient.auth.signOut();
    if (error) throw error;
  },
  
  getCurrentUser: async () => {
    const { data: { user } } = await supabaseClient.auth.getUser();
    return user;
  },
  
  onAuthStateChange: (callback) => {
    return supabaseClient.auth.onAuthStateChange(callback);
  }
};

// Helper functions for database
export const db = {
  from: (table) => supabaseClient.from(table),
  
  select: (table, columns = '*') => supabaseClient.from(table).select(columns),
  
  insert: (table, data) => supabaseClient.from(table).insert(data),
  
  update: (table, data, match) => supabaseClient.from(table).update(data).match(match),
  
  delete: (table, match) => supabaseClient.from(table).delete().match(match)
};
