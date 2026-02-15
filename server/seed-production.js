#!/usr/bin/env node

/**
 * Production Database Seeder
 * 
 * This script seeds your production MongoDB Atlas database.
 * Run it locally with your production MongoDB URI.
 * 
 * Usage:
 *   node seed-production.js
 * 
 * Make sure to set MONGO_URI in your .env file or pass it as an environment variable:
 *   MONGO_URI="mongodb+srv://..." node seed-production.js
 */

const { execSync } = require('child_process');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });

console.log('🌱 Production Database Seeder\n');

// Check if MONGO_URI is set
if (!process.env.MONGO_URI) {
  console.error('❌ Error: MONGO_URI environment variable is not set\n');
  console.log('Please set it in one of these ways:\n');
  console.log('1. Add to .env file:');
  console.log('   MONGO_URI=mongodb+srv://username:password@cluster.mongodb.net/lpg_dealer_shop\n');
  console.log('2. Pass as environment variable:');
  console.log('   MONGO_URI="mongodb+srv://..." node seed-production.js\n');
  process.exit(1);
}

// Confirm before seeding production
console.log('⚠️  WARNING: This will seed your production database!\n');
console.log('Database:', process.env.MONGO_URI.replace(/\/\/([^:]+):([^@]+)@/, '//$1:****@'));
console.log('\nPress Ctrl+C to cancel, or wait 5 seconds to continue...\n');

setTimeout(() => {
  try {
    console.log('🚀 Starting database seeder...\n');
    execSync('node seeders/databaseSeeder.js', { 
      stdio: 'inherit',
      env: process.env 
    });
    console.log('\n✅ Production database seeded successfully!');
  } catch (error) {
    console.error('\n❌ Error seeding database:', error.message);
    process.exit(1);
  }
}, 5000);
