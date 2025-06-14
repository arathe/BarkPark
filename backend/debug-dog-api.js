// This script will test the dog creation API more thoroughly
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

async function debugDogAPI() {
  console.log('=== Debugging Dog API ===\n');
  
  // First, register a new user
  const email = `dogdebug_${Date.now()}@example.com`;
  const registerData = JSON.stringify({
    email: email,
    password: 'TestPassword123!',
    firstName: 'Dog',
    lastName: 'Debug'
  });
  
  console.log('1. Registering new user...');
  const registerRes = await makeRequest({
    hostname: API_HOST,
    path: `${API_PATH}/auth/register`,
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': registerData.length
    }
  }, registerData);
  
  const registerJson = registerRes.json();
  const token = registerJson.token;
  const userId = registerJson.user?.id;
  
  console.log(`User ID: ${userId}`);
  console.log(`Token: ${token?.substring(0, 20)}...`);
  
  if (!token) {
    console.error('Failed to get token');
    return;
  }
  
  // Test different dog creation scenarios
  const testCases = [
    {
      name: 'Minimal dog (only name)',
      data: { name: 'MinimalTest' }
    },
    {
      name: 'Dog with basic fields',
      data: {
        name: 'BasicTest',
        breed: 'Labrador',
        gender: 'female',
        sizeCategory: 'large'
      }
    },
    {
      name: 'Dog with all valid fields',
      data: {
        name: 'FullTest',
        breed: 'German Shepherd',
        birthday: '2020-01-15',
        weight: 75,
        gender: 'male',
        sizeCategory: 'large',
        energyLevel: 'high',
        friendlinessDogs: 4,
        friendlinessPeople: 5,
        trainingLevel: 'advanced',
        favoriteActivities: ['fetch', 'running'],
        isVaccinated: true,
        isSpayedNeutered: true,
        bio: 'A well-trained German Shepherd'
      }
    }
  ];
  
  for (const testCase of testCases) {
    console.log(`\n2. Testing: ${testCase.name}`);
    console.log('Request data:', JSON.stringify(testCase.data, null, 2));
    
    const dogData = JSON.stringify(testCase.data);
    
    try {
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
      console.log(`Response:`, dogRes.json());
      
      if (dogRes.statusCode === 400) {
        console.log('Validation errors detected');
      }
    } catch (error) {
      console.error('Request failed:', error);
    }
  }
  
  // Get all dogs to verify
  console.log('\n3. Getting all dogs for user...');
  const getDogsRes = await makeRequest({
    hostname: API_HOST,
    path: `${API_PATH}/dogs`,
    method: 'GET',
    headers: {
      'Authorization': `Bearer ${token}`
    }
  });
  
  console.log(`Status: ${getDogsRes.statusCode}`);
  console.log(`Dogs:`, getDogsRes.json());
}

debugDogAPI().catch(console.error);