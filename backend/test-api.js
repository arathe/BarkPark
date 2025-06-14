const axios = require('axios');

const API_URL = 'https://barkpark-production.up.railway.app/api';

// Test data
const testUser = {
  email: `test_${Date.now()}@example.com`,
  password: 'TestPassword123!',
  firstName: 'Test',
  lastName: 'User'
};

async function testEndpoints() {
  console.log('=== Testing BarkPark API Endpoints ===\n');
  
  let authToken = null;
  let userId = null;

  // Test 1: Register
  console.log('1. Testing Registration...');
  try {
    const response = await axios.post(`${API_URL}/auth/register`, testUser);
    console.log('✅ Registration successful');
    console.log('Response:', response.data);
    authToken = response.data.token;
    userId = response.data.user.id;
  } catch (error) {
    console.log('❌ Registration failed');
    console.log('Error:', error.response?.data || error.message);
    console.log('Status:', error.response?.status);
    console.log('Headers:', error.response?.headers);
  }

  // Test 2: Login
  console.log('\n2. Testing Login...');
  try {
    const response = await axios.post(`${API_URL}/auth/login`, {
      email: testUser.email,
      password: testUser.password
    });
    console.log('✅ Login successful');
    console.log('Response:', response.data);
    if (!authToken) {
      authToken = response.data.token;
      userId = response.data.user.id;
    }
  } catch (error) {
    console.log('❌ Login failed');
    console.log('Error:', error.response?.data || error.message);
  }

  // If we don't have a token, try with a known test account
  if (!authToken) {
    console.log('\n3. Trying with test account...');
    try {
      const response = await axios.post(`${API_URL}/auth/login`, {
        email: 'test@example.com',
        password: 'password123'
      });
      console.log('✅ Test account login successful');
      authToken = response.data.token;
      userId = response.data.user.id;
    } catch (error) {
      console.log('❌ Test account login failed');
      console.log('Error:', error.response?.data || error.message);
    }
  }

  if (!authToken) {
    console.log('\n⚠️  Cannot proceed with authenticated endpoints without a valid token');
    return;
  }

  // Configure axios with auth token
  const authAxios = axios.create({
    headers: { 'Authorization': `Bearer ${authToken}` }
  });

  // Test 3: Get user profile
  console.log('\n4. Testing Get Profile...');
  try {
    const response = await authAxios.get(`${API_URL}/auth/me`);
    console.log('✅ Get profile successful');
    console.log('Response:', response.data);
  } catch (error) {
    console.log('❌ Get profile failed');
    console.log('Error:', error.response?.data || error.message);
  }

  // Test 4: Get parks (requires location)
  console.log('\n5. Testing Get Parks...');
  try {
    const response = await authAxios.get(`${API_URL}/parks`, {
      params: {
        latitude: 40.7128,
        longitude: -74.0060,
        radius: 10
      }
    });
    console.log('✅ Get parks successful');
    console.log(`Found ${response.data.parks.length} parks`);
    if (response.data.parks.length > 0) {
      console.log('First park:', response.data.parks[0]);
    }
  } catch (error) {
    console.log('❌ Get parks failed');
    console.log('Error:', error.response?.data || error.message);
  }

  // Test 5: Search parks
  console.log('\n6. Testing Search Parks...');
  try {
    const response = await authAxios.get(`${API_URL}/parks/search`, {
      params: { q: 'Central' }
    });
    console.log('✅ Search parks successful');
    console.log(`Found ${response.data.parks.length} parks matching "Central"`);
  } catch (error) {
    console.log('❌ Search parks failed');
    console.log('Error:', error.response?.data || error.message);
  }

  // Test 6: Get dogs
  console.log('\n7. Testing Get Dogs...');
  try {
    const response = await authAxios.get(`${API_URL}/dogs`);
    console.log('✅ Get dogs successful');
    console.log(`Found ${response.data.dogs.length} dogs`);
  } catch (error) {
    console.log('❌ Get dogs failed');
    console.log('Error:', error.response?.data || error.message);
  }

  // Test 7: Get friends
  console.log('\n8. Testing Get Friends...');
  try {
    const response = await authAxios.get(`${API_URL}/friends`);
    console.log('✅ Get friends successful');
    console.log('Response:', response.data);
  } catch (error) {
    console.log('❌ Get friends failed');
    console.log('Error:', error.response?.data || error.message);
  }

  console.log('\n=== API Testing Complete ===');
}

// Run tests
testEndpoints().catch(console.error);