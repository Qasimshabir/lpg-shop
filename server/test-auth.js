const axios = require('axios');
require('dotenv').config();

const BASE_URL = 'http://localhost:5000/api';

// Test data
const testUser = {
  name: 'Test User',
  email: 'testuser@example.com',
  password: 'Test123456',
  phone: '+919876543299',
  shopName: 'Test LPG Shop',
  ownerName: 'Test Owner',
  address: '123 Test Street',
  city: 'Test City'
};

let authToken = '';

// Helper function to log results
const logResult = (title, success, data) => {
  console.log('\n' + '='.repeat(60));
  console.log(success ? '✅' : '❌', title);
  console.log('='.repeat(60));
  if (data) {
    console.log(JSON.stringify(data, null, 2));
  }
};

// Test 1: Register new user
async function testRegister() {
  try {
    const response = await axios.post(`${BASE_URL}/register`, testUser);
    logResult('REGISTER TEST', true, response.data);
    if (response.data.data && response.data.data.token) {
      authToken = response.data.data.token;
    }
    return true;
  } catch (error) {
    logResult('REGISTER TEST', false, error.response?.data || error.message);
    return false;
  }
}

// Test 2: Login with email
async function testLoginWithEmail() {
  try {
    const response = await axios.post(`${BASE_URL}/login`, {
      identifier: testUser.email,
      password: testUser.password
    });
    logResult('LOGIN WITH EMAIL TEST', true, response.data);
    if (response.data.data && response.data.data.token) {
      authToken = response.data.data.token;
    }
    return true;
  } catch (error) {
    logResult('LOGIN WITH EMAIL TEST', false, error.response?.data || error.message);
    return false;
  }
}

// Test 3: Login with phone
async function testLoginWithPhone() {
  try {
    const response = await axios.post(`${BASE_URL}/login`, {
      identifier: testUser.phone,
      password: testUser.password
    });
    logResult('LOGIN WITH PHONE TEST', true, response.data);
    return true;
  } catch (error) {
    logResult('LOGIN WITH PHONE TEST', false, error.response?.data || error.message);
    return false;
  }
}

// Test 4: Get current user (protected route)
async function testGetMe() {
  try {
    const response = await axios.get(`${BASE_URL}/me`, {
      headers: {
        Authorization: `Bearer ${authToken}`
      }
    });
    logResult('GET ME TEST (Protected Route)', true, response.data);
    return true;
  } catch (error) {
    logResult('GET ME TEST (Protected Route)', false, error.response?.data || error.message);
    return false;
  }
}

// Test 5: Login with existing admin user
async function testLoginAdmin() {
  try {
    const response = await axios.post(`${BASE_URL}/login`, {
      identifier: 'admin@lpgshop.com',
      password: 'admin123' // You may need to update this
    });
    logResult('LOGIN ADMIN TEST', true, response.data);
    if (response.data.data && response.data.data.token) {
      authToken = response.data.data.token;
    }
    return true;
  } catch (error) {
    logResult('LOGIN ADMIN TEST', false, error.response?.data || error.message);
    return false;
  }
}

// Test 6: Invalid login
async function testInvalidLogin() {
  try {
    const response = await axios.post(`${BASE_URL}/login`, {
      identifier: testUser.email,
      password: 'wrongpassword'
    });
    logResult('INVALID LOGIN TEST', false, 'Should have failed but succeeded');
    return false;
  } catch (error) {
    if (error.response?.status === 401) {
      logResult('INVALID LOGIN TEST', true, 'Correctly rejected invalid credentials');
      return true;
    }
    logResult('INVALID LOGIN TEST', false, error.response?.data || error.message);
    return false;
  }
}

// Test 7: Access protected route without token
async function testProtectedWithoutToken() {
  try {
    const response = await axios.get(`${BASE_URL}/me`);
    logResult('PROTECTED WITHOUT TOKEN TEST', false, 'Should have failed but succeeded');
    return false;
  } catch (error) {
    if (error.response?.status === 401) {
      logResult('PROTECTED WITHOUT TOKEN TEST', true, 'Correctly rejected request without token');
      return true;
    }
    logResult('PROTECTED WITHOUT TOKEN TEST', false, error.response?.data || error.message);
    return false;
  }
}

// Run all tests
async function runTests() {
  console.log('\n🧪 Starting Authentication API Tests...\n');
  console.log('Base URL:', BASE_URL);
  console.log('Testing against:', process.env.SUPABASE_URL || 'Supabase');
  
  const results = {
    passed: 0,
    failed: 0
  };

  // Test 1: Register
  if (await testRegister()) results.passed++;
  else results.failed++;

  await new Promise(resolve => setTimeout(resolve, 500));

  // Test 2: Login with email
  if (await testLoginWithEmail()) results.passed++;
  else results.failed++;

  await new Promise(resolve => setTimeout(resolve, 500));

  // Test 3: Login with phone
  if (await testLoginWithPhone()) results.passed++;
  else results.failed++;

  await new Promise(resolve => setTimeout(resolve, 500));

  // Test 4: Get current user
  if (await testGetMe()) results.passed++;
  else results.failed++;

  await new Promise(resolve => setTimeout(resolve, 500));

  // Test 5: Invalid login
  if (await testInvalidLogin()) results.passed++;
  else results.failed++;

  await new Promise(resolve => setTimeout(resolve, 500));

  // Test 6: Protected route without token
  if (await testProtectedWithoutToken()) results.passed++;
  else results.failed++;

  // Summary
  console.log('\n' + '='.repeat(60));
  console.log('📊 TEST SUMMARY');
  console.log('='.repeat(60));
  console.log(`✅ Passed: ${results.passed}`);
  console.log(`❌ Failed: ${results.failed}`);
  console.log(`📈 Total: ${results.passed + results.failed}`);
  console.log('='.repeat(60));

  if (results.failed === 0) {
    console.log('\n🎉 All tests passed!\n');
  } else {
    console.log('\n⚠️  Some tests failed. Please review the errors above.\n');
  }
}

// Run tests
runTests().catch(error => {
  console.error('\n❌ Test suite failed:', error.message);
  process.exit(1);
});
