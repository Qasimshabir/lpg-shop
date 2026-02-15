const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

const logger = require('./config/logger');
const { testConnection } = require('./config/supabase');
const { requestLogger, detailedLogger } = require('./middleware/requestLogger');

const app = express();

// Test Supabase connection on startup
testConnection().catch(err => {
  logger.error('Failed to connect to Supabase:', err);
  console.error('Failed to connect to Supabase:', err.message);
});

// Request logging middleware (should be early in the chain)
app.use(requestLogger);
app.use(detailedLogger);

// Security middlewares
app.use(helmet());

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.'
});
app.use(limiter);

// CORS Configuration
const allowedOrigins = [
  '*'
].filter(Boolean);

app.use(cors({
  origin: function (origin, callback) {
    // Allow requests with no origin (like mobile apps or curl requests)
    if (!origin) return callback(null, true);
    
    // Allow localhost and 127.0.0.1 for development
    if (origin.includes('localhost') || origin.includes('127.0.0.1')) {
      return callback(null, true);
    }
    
    // Check if the origin is in the allowed list or matches local network pattern
    if (allowedOrigins.includes('*') || allowedOrigins.includes(origin) || /^http:\/\/192\.168\.\d+\.\d+:\d+$/.test(origin)) {
      return callback(null, true);
    }
    
    callback(new Error('Not allowed by CORS'));
  },
  credentials: true
}));

// Built-in middlewares
app.use(express.json({ limit: '25mb' }));
app.use(express.urlencoded({ extended: true, limit: '25mb' }));

// Routes
app.use('/api', require('./routes/authRoutes'));
app.use('/api/users', require('./routes/userRoutes'));
app.use('/api/roles', require('./routes/roleRoutes'));
app.use('/api/brands', require('./routes/brandRoutes'));
app.use('/api/categories', require('./routes/categoryRoutes'));
app.use('/api/feedback', require('./routes/feedbackRoutes'));
app.use('/api/images', require('./routes/imageRoutes'));

// LPG Dealer Routes
app.use('/api/products', require('./routes/lpgProductRoutes'));
app.use('/api/customers', require('./routes/lpgCustomerRoutes'));
app.use('/api/sales', require('./routes/lpgSalesRoutes'));
app.use('/api/cylinders', require('./routes/cylinderRoutes'));
app.use('/api/safety', require('./routes/safetyRoutes'));
app.use('/api/delivery', require('./routes/deliveryRoutes'));

// Health check endpoint
app.get('/api/health', async (req, res) => {
  try {
    const { getConnectionStatus } = require('./config/supabase');
    res.status(200).json({
      status: 'OK',
      message: 'LPG Dealer Management API is running',
      database: 'Supabase',
      connectionStatus: getConnectionStatus(),
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      status: 'ERROR',
      message: 'Health check failed',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Debug endpoint (only for checking if env vars are loaded)
app.get('/api/debug/env', (req, res) => {
  const { getConnectionStatus } = require('./config/supabase');
  
  res.status(200).json({
    success: true,
    environment: process.env.NODE_ENV,
    supabaseConfigured: !!process.env.SUPABASE_URL && !!process.env.SUPABASE_ANON_KEY,
    jwtConfigured: !!process.env.JWT_SECRET,
    supabaseUrl: process.env.SUPABASE_URL || 'NOT SET',
    connectionStatus: getConnectionStatus(),
    timestamp: new Date().toISOString()
  });
});

// Home/Welcome route
app.get('/', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Welcome to LPG Dealer Management API',
    version: '1.0.0',
    endpoints: {
      health: '/api/health',
      auth: {
        register: 'POST /api/register',
        login: 'POST /api/login',
        forgotPassword: 'POST /api/forgot-password'
      },
      users: {
        profile: 'GET /api/users/me',
        updateProfile: 'PUT /api/users/me',
        changePassword: 'PUT /api/users/password'
      },
      products: {
        list: 'GET /api/products',
        create: 'POST /api/products',
        details: 'GET /api/products/:id',
        update: 'PUT /api/products/:id',
        delete: 'DELETE /api/products/:id'
      },
      customers: {
        list: 'GET /api/customers',
        create: 'POST /api/customers',
        update: 'PUT /api/customers/:id',
        delete: 'DELETE /api/customers/:id'
      },
      sales: {
        list: 'GET /api/sales',
        create: 'POST /api/sales',
        report: 'GET /api/sales/report'
      },
      images: {
        get: 'GET /api/images/:id'
      }
    },
    documentation: 'https://github.com/your-repo/lpg-dealer-api',
    timestamp: new Date().toISOString()
  });
});

// API root route
app.get('/api', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'LPG Dealer Management API',
    version: '1.0.0',
    status: 'running',
    endpoints: [
      '/api/health',
      '/api/register',
      '/api/login',
      '/api/users',
      '/api/products',
      '/api/customers',
      '/api/sales',
      '/api/images'
    ],
    timestamp: new Date().toISOString()
  });
});

// Global error handler
app.use(require('./middleware/errorHandler'));

// 404 handler
app.use('*', (req, res) => {
  logger.warn(`404 - Route not found: ${req.method} ${req.originalUrl}`);
  res.status(404).json({
    success: false,
    message: 'Route not found'
  });
});

// Start Server (only if not in serverless environment)
if (process.env.NODE_ENV !== 'production' || !process.env.VERCEL) {
  const PORT = process.env.PORT || 5000;
  const HOST = process.env.HOST || '0.0.0.0';

  app.listen(PORT, HOST, () => {
    const startupMessage = `🚀 Server running on http://${HOST}:${PORT}`;
    logger.info(startupMessage);
    logger.info(`🌐 Local Network: http://192.168.18.196:${PORT}`);
    logger.info(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
    
    console.log(startupMessage);
    console.log(`🌐 Local Network: http://192.168.18.196:${PORT}`);
    console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
  });
}

// Export for Vercel
module.exports = app;

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
  logger.error('Uncaught Exception:', { error: error.message, stack: error.stack });
  console.error('Uncaught Exception:', error);
  process.exit(1);
});

// Handle unhandled promise rejections
process.on('unhandledRejection', (reason, promise) => {
  logger.error('Unhandled Rejection:', { reason, promise });
  console.error('Unhandled Rejection:', reason);
});
