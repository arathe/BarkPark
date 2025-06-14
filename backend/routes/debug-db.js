const express = require('express');
const router = express.Router();

// Debug endpoint to check database configuration
router.get('/connection', async (req, res) => {
  try {
    // Show which connection method is being used
    const usingDatabaseUrl = !!process.env.DATABASE_URL;
    const nodeEnv = process.env.NODE_ENV;
    
    // Parse DATABASE_URL if it exists (hide password)
    let dbInfo = {};
    if (process.env.DATABASE_URL) {
      try {
        const url = new URL(process.env.DATABASE_URL);
        dbInfo = {
          host: url.hostname,
          port: url.port,
          database: url.pathname.slice(1),
          user: url.username,
          password: '***' + (url.password ? url.password.slice(-4) : ''),
          ssl: process.env.NODE_ENV === 'production'
        };
      } catch (e) {
        dbInfo = { error: 'Could not parse DATABASE_URL' };
      }
    } else {
      dbInfo = {
        host: process.env.DB_HOST || 'localhost',
        port: process.env.DB_PORT || 5432,
        database: process.env.DB_NAME || 'barkpark',
        user: process.env.DB_USER || 'postgres',
        password: process.env.DB_PASSWORD ? '***' + process.env.DB_PASSWORD.slice(-4) : 'not set'
      };
    }
    
    // Get pool configuration
    const pool = require('../config/database');
    const poolConfig = {
      totalCount: pool.totalCount,
      idleCount: pool.idleCount,
      waitingCount: pool.waitingCount
    };
    
    // Test query
    let testResult = null;
    try {
      const result = await pool.query('SELECT current_database(), version()');
      testResult = {
        database: result.rows[0].current_database,
        version: result.rows[0].version.split(',')[0]
      };
    } catch (e) {
      testResult = { error: e.message };
    }
    
    res.json({
      environment: {
        NODE_ENV: nodeEnv,
        usingDatabaseUrl,
        railwayEnvironment: process.env.RAILWAY_ENVIRONMENT
      },
      connection: dbInfo,
      poolStatus: poolConfig,
      testQuery: testResult
    });
    
  } catch (error) {
    res.status(500).json({
      error: 'Debug check failed',
      message: error.message
    });
  }
});

module.exports = router;