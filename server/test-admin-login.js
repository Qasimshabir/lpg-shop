#!/usr/bin/env node

/**
 * Test Admin Login on Vercel
 * 
 * This script tests if the seeded admin user can login
 * 
 * Usage:
 *   node test-admin-login.js
 */

const https = require('https');

const BASE_URL = 'https://server-lpg-shop.vercel.app';

function makeRequest(url, method = 'GET', data = null) {
  return new Promise((resolve, reject) => {
    const urlObj = new URL(url);
    
    const options = {
      hostname: urlObj.hostname,
      port: 443,
      path: urlObj.pathname + urlObj.search,
      method: method,
      headers: {
        'Content-Type': 'application/json',
      }
    };

    if (data) {
      const jsonData = JSON.stringify(data);
      options.headers['Content-Length'] = Buffer.byteLength(jsonData);
    }

    const req = https.request(options, (res) => {
      let body = '';

      res.on('data', (chunk) => {
        body += chunk;
      });

      res.on('end', () => {
        try {
          const jsonBody = JSON.parse(body);
          resolve({
            statusCode: res.statusCode,
            headers: res.headers,
            body: jsonBody
          });
        } catch (e) {
          resolve({
            statusCode: res.statusCode,
            headers: res.headers,
            body: body
          });
        }
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    req.setTimeout(15000, () => {
      req.destroy();
      reject(new Error('Request timeout after 15 seconds'));
    });

    if (data) {
      req.write(JSON.stringify(data));
    }

    req.end();
  });
}

async function testAdminLogin() {
  console.log('🧪 Testing Admin Login on Vercel\n');
  console.log('Base URL:', BASE_URL);
  console.log('='.repeat(60));

  // Test 1: Health Check
  console.log('\n1️⃣  Health Check...');
  try {
    const health = await makeRequest(`${BASE_URL}/api/health`, 'GET');
    if (health.statusCode === 200) {
      console.log('✅ Server is running');
      console.log('   Message:', health.body.message);
    } else {
      console.log('❌ Health check failed');
      console.log('   Status:', health.statusCode);
      return;
    }
  } catch (error) {
    console.log('❌ Cannot reach server:', error.message);
    return;
  }

  // Test 2: Check Environment
  console.log('\n2️⃣  Checking Environment...');
  try {
    const debug = await makeRequest(`${BASE_URL}/api/debug/env`, 'GET');
    if (debug.statusCode === 200) {
      console.log('✅ Environment check passed');
      console.log('   MongoDB Configured:', debug.body.mongoConfigured ? 'Yes' : 'No');
      console.log('   JWT Configured:', debug.body.jwtConfigured ? 'Yes' : 'No');
      console.log('   MongoDB URI:', debug.body.mongoUri);
      
      if (!debug.body.mongoConfigured) {
        console.log('\n❌ MongoDB is not configured!');
        console.log('   Please set MONGO_URI in Vercel environment variables');
        return;
      }
    }
  } catch (error) {
    console.log('⚠️  Could not check environment:', error.message);
  }

  // Test 3: Admin Login
  console.log('\n3️⃣  Testing Admin Login...');
  console.log('   Email: admin@lpgdealer.com');
  console.log('   Password: admin123');
  
  const credentials = {
    identifier: 'admin@lpgdealer.com',
    password: 'admin123'
  };

  try {
    console.log('   Sending login request...');
    const response = await makeRequest(`${BASE_URL}/api/login`, 'POST', credentials);
    
    console.log('   Response Status:', response.statusCode);
    
    if (response.statusCode === 200) {
      console.log('\n✅ Admin Login Successful!');
      console.log('   User Name:', response.body.data?.user?.name || response.body.data?.name);
      console.log('   Email:', response.body.data?.user?.email || response.body.data?.email);
      console.log('   Shop:', response.body.data?.user?.shopName || response.body.data?.shopName);
      console.log('   Token:', response.body.data?.token ? 'Received ✓' : 'Not received ✗');
      
      // Test 4: Get Profile with Token
      if (response.body.data?.token) {
        console.log('\n4️⃣  Testing Get Profile...');
        try {
          const profileResponse = await new Promise((resolve, reject) => {
            const options = {
              hostname: 'server-lpg-shop.vercel.app',
              port: 443,
              path: '/api/users/me',
              method: 'GET',
              headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${response.body.data.token}`
              }
            };

            const req = https.request(options, (res) => {
              let body = '';
              res.on('data', (chunk) => body += chunk);
              res.on('end', () => {
                try {
                  resolve({ statusCode: res.statusCode, body: JSON.parse(body) });
                } catch (e) {
                  resolve({ statusCode: res.statusCode, body: body });
                }
              });
            });

            req.on('error', reject);
            req.setTimeout(15000, () => {
              req.destroy();
              reject(new Error('Request timeout'));
            });
            req.end();
          });

          if (profileResponse.statusCode === 200) {
            console.log('✅ Get Profile Successful!');
            console.log('   Name:', profileResponse.body.data?.name);
            console.log('   Email:', profileResponse.body.data?.email);
            console.log('   Shop:', profileResponse.body.data?.shopName);
          } else {
            console.log('❌ Get Profile Failed');
            console.log('   Status:', profileResponse.statusCode);
            console.log('   Response:', JSON.stringify(profileResponse.body, null, 2));
          }
        } catch (error) {
          console.log('❌ Get Profile Error:', error.message);
        }
      }
      
    } else if (response.statusCode === 401) {
      console.log('\n❌ Login Failed - Invalid Credentials');
      console.log('   This means the admin user is not in the database');
      console.log('   You need to seed the database first!');
      console.log('\n   Run: npm run seed:production');
    } else if (response.statusCode === 503) {
      console.log('\n❌ Login Failed - Database Unavailable');
      console.log('   Response:', response.body.message);
      console.log('\n   Check:');
      console.log('   1. MONGO_URI is set in Vercel environment variables');
      console.log('   2. MongoDB Atlas network access allows 0.0.0.0/0');
      console.log('   3. MongoDB connection string is correct');
    } else {
      console.log('\n❌ Login Failed');
      console.log('   Status Code:', response.statusCode);
      console.log('   Response:', JSON.stringify(response.body, null, 2));
    }
  } catch (error) {
    console.log('\n❌ Login Error:', error.message);
    console.log('   This usually means:');
    console.log('   - Network timeout (check MongoDB connection)');
    console.log('   - Server error (check Vercel logs)');
  }

  console.log('\n' + '='.repeat(60));
  console.log('Test Complete');
  console.log('='.repeat(60));
}

testAdminLogin().catch(error => {
  console.error('❌ Test failed:', error);
  process.exit(1);
});
