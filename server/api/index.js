// Vercel serverless function entry point
// Wrap in try-catch to prevent crashes
try {
  const app = require('../server');
  module.exports = app;
} catch (error) {
  console.error('❌ Failed to initialize server:', error);
  
  // Export a minimal error handler
  module.exports = (req, res) => {
    res.status(500).json({
      success: false,
      error: 'Server initialization failed',
      message: error.message,
      hint: 'Check Vercel environment variables: SUPABASE_URL, SUPABASE_ANON_KEY, JWT_SECRET'
    });
  };
}
