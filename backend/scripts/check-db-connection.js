require('dotenv').config();
const { URL } = require('url');

console.log('Database Connection Check\n');

if (process.env.DATABASE_URL) {
  console.log('Using DATABASE_URL');
  
  try {
    const dbUrl = new URL(process.env.DATABASE_URL);
    console.log('Host:', dbUrl.hostname);
    console.log('Port:', dbUrl.port);
    console.log('Database:', dbUrl.pathname.slice(1));
    console.log('User:', dbUrl.username);
    console.log('Password:', '***' + dbUrl.password.slice(-4));
  } catch (err) {
    console.log('Could not parse DATABASE_URL');
  }
} else {
  console.log('Using individual environment variables:');
  console.log('DB_HOST:', process.env.DB_HOST);
  console.log('DB_PORT:', process.env.DB_PORT);
  console.log('DB_NAME:', process.env.DB_NAME);
  console.log('DB_USER:', process.env.DB_USER);
}

// Check what the database.js config uses
const pool = require('../config/database');
console.log('\nPool configuration uses:', pool.options.connectionString ? 'DATABASE_URL' : 'Individual env vars');