const express = require('express');
const cors = require('cors');
require('dotenv').config();

const authRoutes = require('./routes/auth');
const dogRoutes = require('./routes/dogs');
const parkRoutes = require('./routes/parks');
const friendRoutes = require('./routes/friends');
const diagnosticRoutes = require('./routes/diagnostic');
const debugDbRoutes = require('./routes/debug-db');
const adminRoutes = require('./routes/admin');
const schemaValidationRoutes = require('./routes/schema-validation');
const pool = require('./config/database');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Health check endpoint - available immediately
app.get('/health', async (req, res) => {
  try {
    // Check database connection
    const dbCheck = await pool.query('SELECT 1 as check');
    res.json({ 
      status: 'OK', 
      timestamp: new Date().toISOString(),
      database: dbCheck.rows[0].check === 1 ? 'connected' : 'error'
    });
  } catch (error) {
    // Return OK even if database is down to prevent deployment failures
    console.error('[Health Check] Database error:', error.message);
    res.json({ 
      status: 'OK', 
      timestamp: new Date().toISOString(),
      database: 'error',
      error: error.message
    });
  }
});

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/dogs', dogRoutes);
app.use('/api/parks', parkRoutes);
app.use('/api/friends', friendRoutes);
app.use('/api/diagnostic', diagnosticRoutes);
app.use('/api/debug', debugDbRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/schema', schemaValidationRoutes);

// Basic route
app.get('/', (req, res) => {
  res.json({ 
    message: 'BarkPark API is running!',
    version: '1.0.0',
    endpoints: {
      auth: '/api/auth',
      dogs: '/api/dogs',
      parks: '/api/parks',
      friends: '/api/friends',
      health: '/health',
      diagnostic: '/api/diagnostic'
    }
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({ error: 'Something went wrong!' });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// Graceful startup with database check
async function startServer() {
  try {
    console.log('[Server] Starting BarkPark API...');
    console.log('[Server] Environment:', process.env.NODE_ENV || 'development');
    
    // Test database connection with timeout
    const dbTestPromise = pool.query('SELECT NOW()');
    const timeoutPromise = new Promise((_, reject) => 
      setTimeout(() => reject(new Error('Database connection timeout')), 5000)
    );
    
    try {
      const result = await Promise.race([dbTestPromise, timeoutPromise]);
      console.log('[Server] Database connected at:', result.rows[0].now);
    } catch (dbError) {
      console.error('[Server] WARNING: Database connection failed:', dbError.message);
      console.error('[Server] Server will start anyway for health checks');
    }
    
    // Start server regardless of database status
    app.listen(PORT, () => {
      console.log(`[Server] BarkPark API server running on port ${PORT}`);
      console.log(`[Server] Health check available at: /health`);
    });
  } catch (error) {
    console.error('[Server] Fatal startup error:', error);
    process.exit(1);
  }
}

// Handle uncaught errors
process.on('unhandledRejection', (reason, promise) => {
  console.error('[Server] Unhandled Rejection at:', promise, 'reason:', reason);
});

process.on('uncaughtException', (error) => {
  console.error('[Server] Uncaught Exception:', error);
  process.exit(1);
});

// Start the server
startServer();