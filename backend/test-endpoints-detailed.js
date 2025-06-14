const https = require('https');

const API_HOST = 'barkpark-production.up.railway.app';
const API_PATH = '/api';

function makeRequest(options, data = null) {
  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let body = '';
      
      res.on('data', (chunk) => {
        body += chunk;
      });
      
      res.on('end', () => {
        resolve({
          statusCode: res.statusCode,
          headers: res.headers,
          body: body,
          json: () => {
            try {
              return JSON.parse(body);
            } catch (e) {
              return body;
            }
          }
        });
      });
    });
    
    req.on('error', reject);
    
    if (data) {
      req.write(data);
    }
    
    req.end();
  });
}

async function testEndpoints() {
  console.log('=== Detailed API Testing ===\n');
  
  // Test 1: Health check
  console.log('1. Testing health endpoint...');
  try {
    const healthRes = await makeRequest({
      hostname: API_HOST,
      path: '/health',
      method: 'GET'
    });
    console.log(`Status: ${healthRes.statusCode}`);
    console.log(`Body: ${healthRes.body}`);
  } catch (error) {
    console.error('Health check failed:', error);
  }
  
  // Test 2: Registration
  console.log('\n2. Testing registration...');
  const email = `test_${Date.now()}@example.com`;
  const registerData = JSON.stringify({
    email: email,
    password: 'TestPassword123!',
    firstName: 'Test',
    lastName: 'User'
  });
  
  try {
    const registerRes = await makeRequest({
      hostname: API_HOST,
      path: `${API_PATH}/auth/register`,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': registerData.length
      }
    }, registerData);
    
    console.log(`Status: ${registerRes.statusCode}`);
    console.log(`Headers:`, registerRes.headers);
    console.log(`Body: ${registerRes.body}`);
    
    const registerJson = registerRes.json();
    const token = registerJson.token;
    
    if (token) {
      console.log(`\n✅ Got token: ${token.substring(0, 20)}...`);
      
      // Test 3: Create dog with token
      console.log('\n3. Testing dog creation...');
      const dogData = JSON.stringify({
        name: 'Buddy',
        breed: 'Golden Retriever',
        gender: 'male',
        sizeCategory: 'large',
        energyLevel: 'high',
        isVaccinated: true
      });
      
      const dogRes = await makeRequest({
        hostname: API_HOST,
        path: `${API_PATH}/dogs`,
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': dogData.length,
          'Authorization': `Bearer ${token}`
        }
      }, dogData);
      
      console.log(`Status: ${dogRes.statusCode}`);
      console.log(`Body: ${dogRes.body}`);
      
      // Test 4: Get dogs
      console.log('\n4. Testing get dogs...');
      const getDogsRes = await makeRequest({
        hostname: API_HOST,
        path: `${API_PATH}/dogs`,
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });
      
      console.log(`Status: ${getDogsRes.statusCode}`);
      console.log(`Body: ${getDogsRes.body}`);
    }
    
  } catch (error) {
    console.error('Request failed:', error);
  }
  
  // Test 5: Check for specific user
  console.log('\n5. Testing with known user (austin@barkpark.com)...');
  const loginData = JSON.stringify({
    email: 'austin@barkpark.com',
    password: 'password123'
  });
  
  try {
    const loginRes = await makeRequest({
      hostname: API_HOST,
      path: `${API_PATH}/auth/login`,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': loginData.length
      }
    }, loginData);
    
    console.log(`Status: ${loginRes.statusCode}`);
    console.log(`Body: ${loginRes.body}`);
  } catch (error) {
    console.error('Login failed:', error);
  }
}

testEndpoints().catch(console.error);