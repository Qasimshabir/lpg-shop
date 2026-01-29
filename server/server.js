const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const path = require('path');
const fs = require('fs');
require('dotenv').config();

const app = express();

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
    
    // Check if the origin is in the allowed list or matches local network pattern
    if (allowedOrigins.includes(origin) || /^http:\/\/192\.168\.1\..+:3000$/.test(origin)) {
      return callback(null, true);
    }
    
    callback(new Error('Not allowed by CORS'));
  },
  credentials: true
}));

// Built-in middlewares
app.use(express.json({ limit: '25mb' }));
app.use(express.urlencoded({ extended: true, limit: '25mb' }));

// Ensure uploads directory exists and serve it statically
const uploadsDir = path.join(__dirname, 'uploads');
const productUploadsDir = path.join(uploadsDir, 'products');
if (!fs.existsSync(productUploadsDir)) {
  fs.mkdirSync(productUploadsDir, { recursive: true });
}
app.use('/uploads', express.static(uploadsDir));

// Routes
app.use('/api', require('./routes/authRoutes'));
app.use('/api/users', require('./routes/userRoutes'));
app.use('/api/roles', require('./routes/roleRoutes'));
app.use('/api/brands', require('./routes/brandRoutes'));
app.use('/api/categories', require('./routes/categoryRoutes'));
app.use('/api/feedback', require('./routes/feedbackRoutes'));

// LPG Dealer Routes
app.use('/api/products', require('./routes/lpgProductRoutes'));
app.use('/api/customers', require('./routes/lpgCustomerRoutes'));
app.use('/api/sales', require('./routes/lpgSalesRoutes'));
app.use('/api/cylinders', require('./routes/cylinderRoutes'));
app.use('/api/safety', require('./routes/safetyRoutes'));
app.use('/api/delivery', require('./routes/deliveryRoutes'));

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.status(200).json({
    status: 'OK',
    message: 'LPG Dealer Management API is running',
    timestamp: new Date().toISOString()
  });
});

// Global error handler
app.use(require('./middleware/errorHandler'));

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    message: 'Route not found'
  });
});

// MongoDB Connection
mongoose.connect(process.env.MONGO_URI)
  .then(() => {
    console.log('✅ MongoDB Connected Successfully');
  })
  .catch((err) => {
    console.error('❌ MongoDB Connection Error:', err.message);
    process.exit(1);
  });

// Start Server
const PORT = process.env.PORT || 5000;
const HOST = process.env.HOST || '0.0.0.0'; // Listen on all network interfaces

app.listen(PORT, HOST, () => {
  console.log(`🚀 Server running on http://${HOST}:${PORT}`);
  console.log(`🌐 Local Network: http://192.168.1.3:${PORT}`);
  console.log(`🌍 Environment: ${process.env.NODE_ENV}`);
});
