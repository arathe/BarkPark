const https = require('https');

const ADMIN_KEY = process.env.ADMIN_KEY || 'your-admin-key-here';

function checkTables() {
  const options = {
    hostname: 'barkpark-production.up.railway.app',
    path: `/api/admin/tables?key=${ADMIN_KEY}`,
    method: 'GET'
  };

  https.get(options, (res) => {
    let data = '';
    res.on('data', (chunk) => data += chunk);
    res.on('end', () => {
      try {
        const result = JSON.parse(data);
        if (result.tables) {
          const socialTables = result.tables.filter(t => 
            t.startsWith('post') || t === 'notifications'
          );
          
          console.log('Social feed tables found:');
          socialTables.forEach(table => console.log(`  - ${table}`));
          
          if (socialTables.length === 0) {
            console.log('  (none - migration may not have run yet)');
          }
        } else {
          console.log('Error:', result);
        }
      } catch (error) {
        console.error('Failed to parse response:', error);
        console.log('Raw response:', data);
      }
    });
  }).on('error', (err) => {
    console.error('Request error:', err);
  });
}

checkTables();