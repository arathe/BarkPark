const express = require('express');
const cors = require('cors');
require('dotenv').config();
require('dotenv').config({ path: '.env.local' });

const authRoutes = require('./routes/auth');
const dogRoutes = require('./routes/dogs');
const parkRoutes = require('./routes/parks');
const friendRoutes = require('./routes/friends');
const userRoutes = require('./routes/users');
const adminRoutes = require('./routes/admin');
const postRoutes = require('./routes/posts');
const notificationRoutes = require('./routes/notifications');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Health check endpoint
app.get('/health', async (req, res) => {
  const health = {
    status: 'OK',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  };
  
  // Quick database check (non-blocking)
  try {
    const pool = require('./config/database');
    await pool.query('SELECT 1');
    health.database = 'connected';
  } catch (error) {
    health.database = 'error';
    console.error('[Health] Database check failed:', error.message);
  }
  
  res.json(health);
});

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/dogs', dogRoutes);
app.use('/api/parks', parkRoutes);
app.use('/api/friends', friendRoutes);
app.use('/api/users', userRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/posts', postRoutes);
app.use('/api/notifications', notificationRoutes);

// Debug/diagnostic routes — only available outside production
if (process.env.NODE_ENV !== 'production') {
  const diagnosticRoutes = require('./routes/diagnostic');
  const debugDbRoutes = require('./routes/debug-db');
  const testFeedRoutes = require('./routes/test-feed');
  const schemaValidationRoutes = require('./routes/schema-validation');

  app.use('/api/diagnostic', diagnosticRoutes);
  app.use('/api/debug', debugDbRoutes);
  app.use('/api/test-feed', testFeedRoutes);
  app.use('/api/schema', schemaValidationRoutes);
}

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
      health: '/health'
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

// Only start the server if this file is run directly (not imported)
if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`BarkPark API server running on port ${PORT}`);
    console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
  });
}

module.exports = app;
