#!/usr/bin/env node

/**
 * Test MongoDB Connection
 * 
 * This script tests if your MongoDB connection string is valid
 */

const mongoose = require('mongoose');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });

async function testConnection() {
  console.log('🧪 Testing MongoDB Connection\n');
  
  if (!process.env.MONGO_URI) {
    console.error('❌ MONGO_URI not found in .env file');
    process.exit(1);
  }
  
  console.log('Connection String:');
  console.log(process.env.MONGO_URI.replace(/\/\/([^:]+):([^@]+)@/, '//$1:****@'));
  console.log('\n' + '='.repeat(60));
  
  try {
    console.log('\n⏳ Attempting to connect...\n');
    
    const options = {
      serverSelectionTimeoutMS: 10000,
      socketTimeoutMS: 45000,
    };
    
    await mongoose.connect(process.env.MONGO_URI, options);
    
    console.log('✅ Successfully connected to MongoDB!');
    console.log('   Database:', mongoose.connection.db.databaseName);
    console.log('   Host:', mongoose.connection.host);
    
    // List collections
    const collections = await mongoose.connection.db.listCollections().toArray();
    console.log('\n📦 Collections in database:');
    if (collections.length === 0) {
      console.log('   (No collections yet - database is empty)');
    } else {
      collections.forEach(col => {
        console.log(`   - ${col.name}`);
      });
    }
    
    await mongoose.connection.close();
    console.log('\n👋 Disconnected from MongoDB');
    console.log('\n✅ Connection test successful!\n');
    
  } catch (error) {
    console.error('\n❌ Connection failed!');
    console.error('Error:', error.message);
    console.error('\nCommon issues:');
    console.error('1. Incorrect cluster address');
    console.error('2. Wrong username or password');
    console.error('3. Network access not configured (add 0.0.0.0/0)');
    console.error('4. Database user doesn\'t have permissions');
    console.error('\nPlease check:');
    console.error('- MongoDB Atlas → Clusters → Connect');
    console.error('- Copy the correct connection string');
    console.error('- Update your .env file with the correct MONGO_URI\n');
    process.exit(1);
  }
}

testConnection();
