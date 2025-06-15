#!/usr/bin/env node

/**
 * Verify JWT Secret Change
 * This script tests that old tokens are invalid and new auth works
 */

const API_URL = process.env.API_URL || 'https://barkpark-production.up.railway.app/api';

// Old tokens that should now be invalid
const OLD_TOKENS = [
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjExLCJpYXQiOjE3NDk5MTQ5NzYsImV4cCI6MTc1MDUxOTc3Nn0.6t7Eu4mE0CxYR4dpnSd-Oxa9XeXWfLW6-3V3TzWKVks',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjEzLCJpYXQiOjE3NDk5MTYxMDQsImV4cCI6MTc1MDUyMDkwNH0.tXvHiRvLl_mQqbMXvXz2dz0YFj9-cVPx9bPuU_IxlHs'
];

async function testOldToken(token) {
  console.log('\n🔍 Testing old token...');
  try {
    const response = await fetch(`${API_URL}/auth/me`, {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });
    
    if (response.status === 401) {
      console.log('✅ Old token is properly rejected (401 Unauthorized)');
      return true;
    } else {
      console.log(`❌ SECURITY ISSUE: Old token still accepted! Status: ${response.status}`);
      return false;
    }
  } catch (error) {
    console.error('❌ Error testing old token:', error.message);
    return false;
  }
}

async function testNewAuth() {
  console.log('\n🔑 Testing new authentication...');
  
  // Create a test user
  const testEmail = `security_test_${Date.now()}@example.com`;
  
  try {
    const response = await fetch(`${API_URL}/auth/register`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        email: testEmail,
        password: 'SecureTest123!',
        firstName: 'Security',
        lastName: 'Test'
      })
    });
    
    if (response.ok) {
      const data = await response.json();
      if (data.token) {
        console.log('✅ New authentication working - received new JWT token');
        
        // Test the new token
        const meResponse = await fetch(`${API_URL}/auth/me`, {
          headers: {
            'Authorization': `Bearer ${data.token}`
          }
        });
        
        if (meResponse.ok) {
          console.log('✅ New token is valid and working');
          return true;
        }
      }
    }
    
    console.log('❌ Failed to authenticate with new secret');
    return false;
  } catch (error) {
    console.error('❌ Error testing new auth:', error.message);
    return false;
  }
}

async function main() {
  console.log('🔐 JWT Secret Change Verification');
  console.log('=================================');
  console.log(`API URL: ${API_URL}`);
  
  let allTestsPassed = true;
  
  // Test that old tokens are rejected
  for (const token of OLD_TOKENS) {
    const passed = await testOldToken(token);
    if (!passed) allTestsPassed = false;
  }
  
  // Test that new authentication works
  const newAuthWorks = await testNewAuth();
  if (!newAuthWorks) allTestsPassed = false;
  
  console.log('\n' + '='.repeat(50));
  if (allTestsPassed) {
    console.log('✅ JWT Secret successfully changed!');
    console.log('✅ All old tokens are invalidated');
    console.log('✅ New authentication is working');
  } else {
    console.log('❌ JWT Secret change verification FAILED');
    console.log('⚠️  Check Railway logs for errors');
  }
}

main().catch(console.error);