const morgan = require('morgan');
const logger = require('../config/logger');

// Custom token for user ID
morgan.token('user-id', (req) => {
  return req.user ? req.user.id : 'anonymous';
});

// Custom token for request body (sanitized)
morgan.token('body', (req) => {
  if (req.body && Object.keys(req.body).length > 0) {
    // Clone body and remove sensitive fields
    const sanitizedBody = { ...req.body };
    delete sanitizedBody.password;
    delete sanitizedBody.currentPassword;
    delete sanitizedBody.newPassword;
    delete sanitizedBody.token;
    return JSON.stringify(sanitizedBody);
  }
  return '-';
});

// Custom token for response time in ms
morgan.token('response-time-ms', (req, res) => {
  if (!req._startAt || !res._startAt) {
    return '-';
  }
  const ms = (res._startAt[0] - req._startAt[0]) * 1e3 +
    (res._startAt[1] - req._startAt[1]) * 1e-6;
  return ms.toFixed(3);
});

// Define custom format
const customFormat = ':remote-addr - :user-id [:date[clf]] ":method :url HTTP/:http-version" :status :res[content-length] ":referrer" ":user-agent" :response-time-ms ms';

// Create Morgan middleware with custom format
const requestLogger = morgan(customFormat, {
  stream: logger.stream,
  skip: (req, res) => {
    // Skip logging for health check endpoint
    return req.url === '/api/health';
  },
});

// Detailed request logger for debugging (only in development)
const detailedLogger = (req, res, next) => {
  if (process.env.NODE_ENV !== 'production') {
    const startTime = Date.now();
    
    // Log request
    logger.info('Incoming Request', {
      method: req.method,
      url: req.url,
      ip: req.ip,
      userAgent: req.get('user-agent'),
      userId: req.user ? req.user.id : 'anonymous',
    });

    // Log response
    res.on('finish', () => {
      const duration = Date.now() - startTime;
      logger.info('Response Sent', {
        method: req.method,
        url: req.url,
        status: res.statusCode,
        duration: `${duration}ms`,
      });
    });
  }
  next();
};

module.exports = {
  requestLogger,
  detailedLogger,
};
