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
 * Connect to MongoDB with connection caching for serverless environments
 * This prevents creating new connections on every function invocation
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
    
    const options = {
      serverSelectionTimeoutMS: 10000, // Timeout after 10s
      socketTimeoutMS: 45000,
      maxPoolSize: 10,
      minPoolSize: 2,
      retryWrites: true,
      w: 'majority'
    };

    await mongoose.connect(encodedURI, options);
    
    cachedConnection = mongoose.connection;
    
    console.log('✅ MongoDB connected successfully');
    
    // Handle connection events
    mongoose.connection.on('error', (err) => {
      console.error('❌ MongoDB connection error:', err);
      cachedConnection = null;
    });

    mongoose.connection.on('disconnected', () => {
      console.log('⚠️  MongoDB disconnected');
      cachedConnection = null;
    });

    return cachedConnection;
  } catch (error) {
    console.error('❌ MongoDB connection failed:', error.message);
    console.error('Full error:', error);
    cachedConnection = null;
    throw error;
  }
}

module.exports = { connectDB, encodeMongoURI };
