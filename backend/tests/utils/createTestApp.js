const express = require('express');
const cors = require('cors');

/**
 * Creates a minimal Express app for testing, mounting only the specified routes.
 *
 * Usage:
 *   const createTestApp = require('./utils/createTestApp');
 *   const app = createTestApp({ '/api/dogs': require('../routes/dogs') });
 *
 * @param {Object} routeMap  e.g. { '/api/auth': authRouter, '/api/dogs': dogRouter }
 * @returns {import('express').Application}
 */
function createTestApp(routeMap = {}) {
  const app = express();
  app.use(cors());
  app.use(express.json({ limit: '10mb' }));
  app.use(express.urlencoded({ extended: true, limit: '10mb' }));

  for (const [path, router] of Object.entries(routeMap)) {
    app.use(path, router);
  }

  // Basic error handler
  app.use((err, req, res, next) => {
    console.error('Test app error:', err.message);
    res.status(err.status || 500).json({ error: err.message || 'Internal server error' });
  });

  return app;
}

module.exports = createTestApp;
