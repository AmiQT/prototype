/**
 * Supabase Configuration
 * Replace Firebase with Supabase for authentication and database
 */

// Supabase configuration
const SUPABASE_CONFIG = {
  url: 'https://your-project.supabase.co',
  anonKey: 'your-anon-key'
};

// Initialize Supabase client
const supabase = supabase.createClient(SUPABASE_CONFIG.url, SUPABASE_CONFIG.anonKey);

// Export Supabase client
export { supabase };

// Helper functions for authentication
export const auth = {
  signIn: async (email, password) => {
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password
    });
    if (error) throw error;
    return data;
  },
  
  signOut: async () => {
    const { error } = await supabase.auth.signOut();
    if (error) throw error;
  },
  
  getCurrentUser: async () => {
    const { data: { user } } = await supabase.auth.getUser();
    return user;
  },
  
  onAuthStateChange: (callback) => {
    return supabase.auth.onAuthStateChange(callback);
  }
};

// Helper functions for database
export const db = {
  from: (table) => supabase.from(table),
  
  select: (table, columns = '*') => supabase.from(table).select(columns),
  
  insert: (table, data) => supabase.from(table).insert(data),
  
  update: (table, data, match) => supabase.from(table).update(data).match(match),
  
  delete: (table, match) => supabase.from(table).delete().match(match)
};
