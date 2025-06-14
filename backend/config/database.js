const { Pool } = require('pg');
require('dotenv').config();

// Log database connection method on startup
console.log('[Database] Initializing connection...');
console.log('[Database] NODE_ENV:', process.env.NODE_ENV);
console.log('[Database] DATABASE_URL exists:', !!process.env.DATABASE_URL);

// Railway provides DATABASE_URL, but we also support individual env vars
const connectionConfig = process.env.DATABASE_URL
  ? {
      connectionString: process.env.DATABASE_URL,
      ssl: process.env.NODE_ENV === 'production' 
        ? { rejectUnauthorized: false }
        : false
    }
  : {
      host: process.env.DB_HOST || 'localhost',
      port: process.env.DB_PORT || 5432,
      database: process.env.DB_NAME || 'barkpark',
      user: process.env.DB_USER || 'postgres',
      password: process.env.DB_PASSWORD,
    };

// Log which connection method is being used
if (process.env.DATABASE_URL) {
  try {
    const url = new URL(process.env.DATABASE_URL);
    console.log('[Database] Using DATABASE_URL');
    console.log('[Database] Host:', url.hostname);
    console.log('[Database] Database:', url.pathname.slice(1));
  } catch (e) {
    console.log('[Database] DATABASE_URL parse error:', e.message);
  }
} else {
  console.log('[Database] Using individual environment variables');
  console.log('[Database] Host:', connectionConfig.host);
  console.log('[Database] Database:', connectionConfig.database);
}

const pool = new Pool(connectionConfig);

pool.on('error', (err) => {
  console.error('Unexpected error on idle client', err);
  process.exit(-1);
});

module.exports = pool;