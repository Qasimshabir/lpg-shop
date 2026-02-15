const logger = require('../config/logger');

const errorHandler = (err, req, res, next) => {
  let error = { ...err };
  error.message = err.message;

  // Log error with details
  logger.error('Error Handler:', {
    message: err.message,
    stack: err.stack,
    url: req.originalUrl,
    method: req.method,
    ip: req.ip,
    userId: req.user ? req.user.id : 'anonymous',
  });

  // Log to console for dev
  console.error('❌ Error:', err);

  // PostgreSQL/Supabase errors
  if (err.code === '23505') {
    // Unique constraint violation
    const message = 'Duplicate field value entered';
    error = { message, statusCode: 400 };
  }

  if (err.code === '23503') {
    // Foreign key constraint violation
    const message = 'Referenced resource not found';
    error = { message, statusCode: 400 };
  }

  if (err.code === '22P02') {
    // Invalid text representation (bad UUID, etc.)
    const message = 'Invalid ID format';
    error = { message, statusCode: 400 };
  }

  // Validation errors
  if (err.name === 'ValidationError') {
    const message = Object.values(err.errors || {}).map(val => val.message);
    error = { message, statusCode: 400 };
  }

  // JWT errors
  if (err.name === 'JsonWebTokenError') {
    const message = 'Invalid token';
    error = { message, statusCode: 401 };
  }

  if (err.name === 'TokenExpiredError') {
    const message = 'Token expired';
    error = { message, statusCode: 401 };
  }

  res.status(error.statusCode || 500).json({
    success: false,
    message: error.message || 'Server Error',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
};

module.exports = errorHandler;

