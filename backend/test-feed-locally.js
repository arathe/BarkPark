// Test script to debug feed issues
const https = require('https');

// First, let's see what a raw feed request returns
function testFeed(token) {
  const options = {
    hostname: 'barkpark-production.up.railway.app',
    path: '/api/posts/feed',
    method: 'GET',
    headers: {
      'Authorization': `Bearer ${token}`
    }
  };

  https.get(options, (res) => {
    let data = '';
    res.on('data', (chunk) => data += chunk);
    res.on('end', () => {
      console.log('\n=== Feed Response ===');
      console.log('Status:', res.statusCode);
      console.log('Headers:', res.headers);
      console.log('\nBody:');
      
      try {
        const parsed = JSON.parse(data);
        console.log(JSON.stringify(parsed, null, 2));
        
        // Check structure
        if (parsed.posts && Array.isArray(parsed.posts)) {
          console.log(`\n✅ Has posts array with ${parsed.posts.length} items`);
          if (parsed.posts.length > 0) {
            console.log('\nFirst post structure:');
            console.log(Object.keys(parsed.posts[0]));
          }
        }
      } catch (e) {
        console.log('Raw:', data);
        console.log('Parse error:', e.message);
      }
    });
  }).on('error', (err) => {
    console.error('Request error:', err);
  });
}

// Get a token from command line or use a test token
const token = process.argv[2] || 'test-token';
console.log('Testing with token:', token);

testFeed(token);