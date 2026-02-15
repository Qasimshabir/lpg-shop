#!/usr/bin/env node

/**
 * Test Vercel Environment Variables
 * 
 * This script checks if environment variables are properly set on Vercel
 */

const https = require('https');

const BASE_URL = 'https://server-lpg-shop.vercel.app';

function makeRequest(url) {
  return new Promise((resolve, reject) => {
    https.get(url, (res) => {
      let body = '';
      res.on('data', (chunk) => body += chunk);
      res.on('end', () => {
        try {
          resolve({ statusCode: res.statusCode, body: JSON.parse(body) });
        } catch (e) {
          resolve({ statusCode: res.statusCode, body: body });
        }
      });
    }).on('error', reject);
  });
}

async function testEnvCheck() {
  console.log('🔍 Checking Vercel Environment Configuration\n');
  console.log('Base URL:', BASE_URL);
  console.log('='.repeat(60));

  // Test health endpoint
  console.log('\n1️⃣  Testing Health Endpoint...');
  try {
    const health = await makeRequest(`${BASE_URL}/api/health`);
    if (health.statusCode === 200) {
      console.log('✅ Server is running');
      console.log('   Message:', health.body.message);
    } else {
      console.log('❌ Server health check failed');
      console.log('   Status:', health.statusCode);
    }
  } catch (error) {
    console.log('❌ Cannot reach server:', error.message);
  }

  // Test root endpoint
  console.log('\n2️⃣  Testing Root Endpoint...');
  try {
    const root = await makeRequest(`${BASE_URL}/`);
    if (root.statusCode === 200) {
      console.log('✅ Root endpoint working');
      console.log('   Version:', root.body.version);
    }
  } catch (error) {
    console.log('❌ Root endpoint error:', error.message);
  }

  console.log('\n' + '='.repeat(60));
  console.log('📋 Next Steps:\n');
  console.log('1. Go to Vercel Dashboard:');
  console.log('   https://vercel.com/dashboard\n');
  console.log('2. Select your project: server-lpg-shop\n');
  console.log('3. Go to: Settings → Environment Variables\n');
  console.log('4. Add these variables for Production:');
  console.log('   - MONGO_URI: mongodb+srv://username:password@cluster.mongodb.net/lpg_dealer_shop');
  console.log('   - JWT_SECRET: your_long_random_secret_key\n');
  console.log('5. Redeploy your project:');
  console.log('   vercel --prod\n');
  console.log('6. Check MongoDB Atlas Network Access:');
  console.log('   - Allow access from 0.0.0.0/0 (anywhere)\n');
  console.log('='.repeat(60));
}

testEnvCheck().catch(console.error);
