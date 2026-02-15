#!/usr/bin/env node

/**
 * Test Vercel API Endpoints
 * 
 * This script tests the login and signup APIs on your Vercel deployment
 * 
 * Usage:
 *   node test-vercel-apis.js
 */

const https = require('https');
const http = require('http');

const BASE_URL = 'https://server-lpg-shop.vercel.app';

// Helper function to make HTTP requests
function makeRequest(url, method = 'GET', data = null) {
  return new Promise((resolve, reject) => {
    const urlObj = new URL(url);
    const isHttps = urlObj.protocol === 'https:';
    const lib = isHttps ? https : http;

    const options = {
      hostname: urlObj.hostname,
      port: urlObj.port || (isHttps ? 443 : 80),
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

    const req = lib.request(options, (res) => {
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

    if (data) {
      req.write(JSON.stringify(data));
    }

    req.end();
  });
}

// Test functions
async function testHealthCheck() {
  console.log('\n🏥 Testing Health Check...');
  try {
    const response = await makeRequest(`${BASE_URL}/api/health`, 'GET');
    
    if (response.statusCode === 200) {
      console.log('✅ Health check passed');
      console.log('   Status:', response.body.status);
      console.log('   Message:', response.body.message);
      return true;
    } else {
      console.log('❌ Health check failed');
      console.log('   Status Code:', response.statusCode);
      console.log('   Response:', response.body);
      return false;
    }
  } catch (error) {
    console.log('❌ Health check error:', error.message);
    return false;
  }
}

async function testSignup() {
  console.log('\n📝 Testing Signup API...');
  
  const testUser = {
    name: 'Test User',
    email: `test${Date.now()}@example.com`,
    password: 'test123456',
    shopName: 'Test Shop',
    ownerName: 'Test Owner',
    city: 'Test City',
    phone: '+1234567890',
    address: '123 Test Street'
  };

  try {
    const response = await makeRequest(`${BASE_URL}/api/register`, 'POST', testUser);
    
    if (response.statusCode === 201 || response.statusCode === 200) {
      console.log('✅ Signup successful');
      console.log('   User ID:', response.body.data?.user?._id || response.body.data?._id);
      console.log('   Email:', testUser.email);
      console.log('   Token received:', response.body.data?.token ? 'Yes' : 'No');
      return {
        success: true,
        email: testUser.email,
        password: testUser.password,
        token: response.body.data?.token
      };
    } else {
      console.log('❌ Signup failed');
      console.log('   Status Code:', response.statusCode);
      console.log('   Response:', JSON.stringify(response.body, null, 2));
      return { success: false };
    }
  } catch (error) {
    console.log('❌ Signup error:', error.message);
    return { success: false };
  }
}

async function testLogin(email, password) {
  console.log('\n🔐 Testing Login API...');
  
  const credentials = {
    identifier: email,
    password: password
  };

  try {
    const response = await makeRequest(`${BASE_URL}/api/login`, 'POST', credentials);
    
    if (response.statusCode === 200) {
      console.log('✅ Login successful');
      console.log('   User ID:', response.body.data?.user?._id || response.body.data?._id);
      console.log('   Email:', response.body.data?.user?.email || response.body.data?.email);
      console.log('   Token received:', response.body.data?.token ? 'Yes' : 'No');
      return {
        success: true,
        token: response.body.data?.token
      };
    } else {
      console.log('❌ Login failed');
      console.log('   Status Code:', response.statusCode);
      console.log('   Response:', JSON.stringify(response.body, null, 2));
      return { success: false };
    }
  } catch (error) {
    console.log('❌ Login error:', error.message);
    return { success: false };
  }
}

async function testLoginWithSeededUser() {
  console.log('\n🔐 Testing Login with Seeded Admin User...');
  
  const credentials = {
    identifier: 'admin@lpgdealer.com',
    password: 'admin123'
  };

  try {
    const response = await makeRequest(`${BASE_URL}/api/login`, 'POST', credentials);
    
    if (response.statusCode === 200) {
      console.log('✅ Admin login successful');
      console.log('   User:', response.body.data?.user?.name || response.body.data?.name);
      console.log('   Email:', response.body.data?.user?.email || response.body.data?.email);
      console.log('   Token received:', response.body.data?.token ? 'Yes' : 'No');
      return {
        success: true,
        token: response.body.data?.token
      };
    } else {
      console.log('❌ Admin login failed');
      console.log('   Status Code:', response.statusCode);
      console.log('   Response:', JSON.stringify(response.body, null, 2));
      return { success: false };
    }
  } catch (error) {
    console.log('❌ Admin login error:', error.message);
    return { success: false };
  }
}

async function testGetProfile(token) {
  console.log('\n👤 Testing Get Profile API...');
  
  return new Promise((resolve, reject) => {
    const urlObj = new URL(`${BASE_URL}/api/users/me`);
    
    const options = {
      hostname: urlObj.hostname,
      port: 443,
      path: urlObj.pathname,
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      }
    };

    const req = https.request(options, (res) => {
      let body = '';

      res.on('data', (chunk) => {
        body += chunk;
      });

      res.on('end', () => {
        try {
          const jsonBody = JSON.parse(body);
          
          if (res.statusCode === 200) {
            console.log('✅ Get profile successful');
            console.log('   Name:', jsonBody.data?.name);
            console.log('   Email:', jsonBody.data?.email);
            console.log('   Shop:', jsonBody.data?.shopName);
            resolve({ success: true });
          } else {
            console.log('❌ Get profile failed');
            console.log('   Status Code:', res.statusCode);
            console.log('   Response:', JSON.stringify(jsonBody, null, 2));
            resolve({ success: false });
          }
        } catch (e) {
          console.log('❌ Get profile error:', e.message);
          resolve({ success: false });
        }
      });
    });

    req.on('error', (error) => {
      console.log('❌ Get profile error:', error.message);
      resolve({ success: false });
    });

    req.end();
  });
}

// Main test runner
async function runTests() {
  console.log('🧪 Testing Vercel API Endpoints');
  console.log('🌐 Base URL:', BASE_URL);
  console.log('='.repeat(60));

  let passedTests = 0;
  let totalTests = 0;

  // Test 1: Health Check
  totalTests++;
  if (await testHealthCheck()) passedTests++;

  // Test 2: Signup
  totalTests++;
  const signupResult = await testSignup();
  if (signupResult.success) passedTests++;

  // Test 3: Login with new user
  if (signupResult.success) {
    totalTests++;
    const loginResult = await testLogin(signupResult.email, signupResult.password);
    if (loginResult.success) {
      passedTests++;
      
      // Test 4: Get Profile
      totalTests++;
      if (await testGetProfile(loginResult.token)) passedTests++;
    }
  }

  // Test 5: Login with seeded admin user
  totalTests++;
  const adminLoginResult = await testLoginWithSeededUser();
  if (adminLoginResult.success) {
    passedTests++;
    
    // Test 6: Get Admin Profile
    totalTests++;
    if (await testGetProfile(adminLoginResult.token)) passedTests++;
  }

  // Summary
  console.log('\n' + '='.repeat(60));
  console.log('📊 Test Summary');
  console.log('='.repeat(60));
  console.log(`✅ Passed: ${passedTests}/${totalTests}`);
  console.log(`❌ Failed: ${totalTests - passedTests}/${totalTests}`);
  
  if (passedTests === totalTests) {
    console.log('\n🎉 All tests passed! Your Vercel API is working correctly.');
  } else {
    console.log('\n⚠️  Some tests failed. Check the logs above for details.');
  }
  
  console.log('='.repeat(60));
}

// Run the tests
runTests().catch(error => {
  console.error('❌ Test runner error:', error);
  process.exit(1);
});
