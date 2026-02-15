// Test script to verify Vercel setup
require('dotenv').config();

console.log('🔍 Checking Vercel Setup...\n');

// Check required environment variables
const requiredEnvVars = ['MONGO_URI', 'JWT_SECRET'];
let allPresent = true;

requiredEnvVars.forEach(varName => {
  if (process.env[varName]) {
    console.log(`✅ ${varName}: Set`);
  } else {
    console.log(`❌ ${varName}: Missing`);
    allPresent = false;
  }
});

console.log('\n📦 Checking dependencies...');

try {
  require('express');
  console.log('✅ express');
} catch (e) {
  console.log('❌ express - Run: npm install');
}

try {
  require('mongoose');
  console.log('✅ mongoose');
} catch (e) {
  console.log('❌ mongoose - Run: npm install');
}

try {
  require('jsonwebtoken');
  console.log('✅ jsonwebtoken');
} catch (e) {
  console.log('❌ jsonwebtoken - Run: npm install');
}

console.log('\n📁 Checking file structure...');

const fs = require('fs');
const path = require('path');

const requiredFiles = [
  'server.js',
  'api/index.js',
  'vercel.json',
  'package.json'
];

requiredFiles.forEach(file => {
  if (fs.existsSync(path.join(__dirname, file))) {
    console.log(`✅ ${file}`);
  } else {
    console.log(`❌ ${file}`);
    allPresent = false;
  }
});

console.log('\n' + '='.repeat(50));

if (allPresent) {
  console.log('✅ Setup looks good! Ready to deploy to Vercel.');
  console.log('\nNext steps:');
  console.log('1. Run: vercel');
  console.log('2. Add environment variables in Vercel dashboard');
  console.log('3. Run: vercel --prod');
} else {
  console.log('❌ Setup incomplete. Please fix the issues above.');
}

console.log('='.repeat(50) + '\n');
