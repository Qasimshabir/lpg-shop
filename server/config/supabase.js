const { createClient } = require('@supabase/supabase-js');

let supabaseClient = null;

/**
 * Initialize Supabase client
 * @returns {Object} Supabase client instance
 */
function getSupabaseClient() {
  if (supabaseClient) {
    return supabaseClient;
  }

  const supabaseUrl = process.env.SUPABASE_URL;
  const supabaseKey = process.env.SUPABASE_SERVICE_KEY || process.env.SUPABASE_ANON_KEY;

  if (!supabaseUrl || !supabaseKey) {
    console.error('❌ Missing Supabase credentials. Please set SUPABASE_URL and SUPABASE_SERVICE_KEY/SUPABASE_ANON_KEY in environment variables');
    throw new Error('Missing Supabase credentials. Please configure environment variables in Vercel.');
  }

  supabaseClient = createClient(supabaseUrl, supabaseKey, {
    auth: {
      autoRefreshToken: true,
      persistSession: false
    },
    db: {
      schema: 'public'
    }
  });

  console.log('✅ Supabase client initialized');
  return supabaseClient;
}

/**
 * Test database connection
 */
async function testConnection() {
  try {
    const supabase = getSupabaseClient();
    
    // Simple query to test connection
    const { data, error } = await supabase
      .from('users')
      .select('count')
      .limit(1);

    if (error && error.code !== 'PGRST116') { // PGRST116 = table doesn't exist yet
      throw error;
    }

    console.log('✅ Supabase connection successful');
    return true;
  } catch (error) {
    console.error('❌ Supabase connection failed:', error.message);
    throw error;
  }
}

/**
 * Get connection status
 */
function getConnectionStatus() {
  return supabaseClient ? 'connected' : 'disconnected';
}

module.exports = {
  getSupabaseClient,
  testConnection,
  getConnectionStatus
};
