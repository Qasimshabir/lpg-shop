const mongoose = require('mongoose');

let cachedConnection = null;

/**
 * Encode MongoDB URI password properly
 * Special characters in passwords need to be URL encoded
 */
function encodeMongoURI(uri) {
  if (!uri) return uri;
  
  // Check if URI contains password that needs encoding
  const match = uri.match(/mongodb\+srv:\/\/([^:]+):([^@]+)@(.+)/);
  if (match) {
    const username = match[1];
    const password = match[2];
    const rest = match[3];
    
    // Only encode if not already encoded
    if (password.includes('%')) {
      return uri; // Already encoded
    }
    
    const encodedPassword = encodeURIComponent(password);
    return `mongodb+srv://${username}:${encodedPassword}@${rest}`;
  }
  
  return uri;
}

/**
 * Connect to MongoDB with Stable API and connection caching
 * Following MongoDB Node.js Driver documentation
 * https://www.mongodb.com/docs/drivers/node/current/
 */
async function connectDB() {
  // If we have a cached connection and it's ready, use it
  if (cachedConnection && mongoose.connection.readyState === 1) {
    console.log('✅ Using cached MongoDB connection');
    return cachedConnection;
  }

  // If connection is in progress, wait for it
  if (mongoose.connection.readyState === 2) {
    console.log('⏳ MongoDB connection in progress, waiting...');
    await new Promise(resolve => {
      mongoose.connection.once('connected', resolve);
    });
    return mongoose.connection;
  }

  try {
    console.log('🔌 Creating new MongoDB connection...');
    
    // Encode the URI properly
    const encodedURI = encodeMongoURI(process.env.MONGO_URI);
    
    // MongoDB connection options with Stable API
    const options = {
      // Stable API Version (MongoDB 5.0+)
      serverApi: {
        version: '1',
        strict: true,
        deprecationErrors: true,
      },
      
      // Connection pool settings
      maxPoolSize: 10,
      minPoolSize: 2,
      
      // Timeout settings
      serverSelectionTimeoutMS: 10000, // 10 seconds
      socketTimeoutMS: 45000, // 45 seconds
      connectTimeoutMS: 10000, // 10 seconds
      
      // Retry settings
      retryWrites: true,
      retryReads: true,
      
      // Write concern
      w: 'majority',
      
      // Read preference
      readPreference: 'primaryPreferred',
      
      // Compression
      compressors: ['zlib'],
      
      // Monitoring
      monitorCommands: process.env.NODE_ENV === 'development',
    };

    // Connect to MongoDB
    await mongoose.connect(encodedURI, options);
    
    cachedConnection = mongoose.connection;
    
    console.log('✅ MongoDB connected successfully');
    console.log('   Database:', mongoose.connection.db.databaseName || 'default');
    console.log('   Host:', mongoose.connection.host);
    
    // Ping to confirm connection (like in MongoDB documentation)
    try {
      await mongoose.connection.db.admin().ping();
      console.log('   Ping: Successful ✓');
    } catch (pingError) {
      console.log('   Ping: Failed (but connection established)');
    }
    
    // Handle connection events
    mongoose.connection.on('error', (err) => {
      console.error('❌ MongoDB connection error:', err);
      cachedConnection = null;
    });

    mongoose.connection.on('disconnected', () => {
      console.log('⚠️  MongoDB disconnected');
      cachedConnection = null;
    });

    mongoose.connection.on('reconnected', () => {
      console.log('✅ MongoDB reconnected');
    });

    // Graceful shutdown
    process.on('SIGINT', async () => {
      await mongoose.connection.close();
      console.log('MongoDB connection closed through app termination');
      process.exit(0);
    });

    return cachedConnection;
  } catch (error) {
    console.error('❌ MongoDB connection failed:', error.message);
    console.error('Full error:', error);
    cachedConnection = null;
    throw error;
  }
}

/**
 * Get connection status
 */
function getConnectionStatus() {
  const states = {
    0: 'disconnected',
    1: 'connected',
    2: 'connecting',
    3: 'disconnecting',
  };
  return states[mongoose.connection.readyState] || 'unknown';
}

module.exports = { connectDB, encodeMongoURI, getConnectionStatus };
