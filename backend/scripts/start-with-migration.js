#!/usr/bin/env node

/**
 * Start script that runs migrations with timeout protection
 * Ensures the app starts even if migrations take too long
 */

const { spawn } = require('child_process');
const path = require('path');

console.log('[Startup] BarkPark startup sequence initiated');
console.log('[Startup] Environment:', process.env.NODE_ENV || 'development');

// Run migrations with a timeout
async function runMigrations() {
  return new Promise((resolve) => {
    console.log('[Startup] Running database migrations...');
    
    const migrate = spawn('node', [path.join(__dirname, 'unified-migrate.js')], {
      stdio: 'inherit',
      env: process.env
    });
    
    let migrationCompleted = false;
    
    // Set a timeout for migrations (25 seconds to leave time for app startup)
    const timeout = setTimeout(() => {
      if (!migrationCompleted) {
        console.warn('[Startup] WARNING: Migration timeout after 25 seconds');
        console.warn('[Startup] Continuing with application startup...');
        migrate.kill('SIGTERM');
        resolve(false);
      }
    }, 25000);
    
    migrate.on('close', (code) => {
      migrationCompleted = true;
      clearTimeout(timeout);
      
      if (code === 0) {
        console.log('[Startup] Migrations completed successfully');
        resolve(true);
      } else {
        console.error(`[Startup] Migration process exited with code ${code}`);
        resolve(false);
      }
    });
    
    migrate.on('error', (err) => {
      console.error('[Startup] Failed to start migration process:', err);
      clearTimeout(timeout);
      resolve(false);
    });
  });
}

// Start the application
async function startApp() {
  console.log('[Startup] Starting BarkPark API server...');
  
  const server = spawn('node', [path.join(__dirname, '..', 'server.js')], {
    stdio: 'inherit',
    env: process.env
  });
  
  server.on('error', (err) => {
    console.error('[Startup] Failed to start server:', err);
    process.exit(1);
  });
  
  // Keep the parent process alive
  process.on('SIGTERM', () => {
    console.log('[Startup] Received SIGTERM, shutting down...');
    server.kill('SIGTERM');
    process.exit(0);
  });
  
  process.on('SIGINT', () => {
    console.log('[Startup] Received SIGINT, shutting down...');
    server.kill('SIGINT');
    process.exit(0);
  });
}

// Main execution
async function main() {
  const migrationSuccess = await runMigrations();
  
  if (!migrationSuccess) {
    console.warn('[Startup] Starting server despite migration issues...');
  }
  
  await startApp();
}

main().catch((err) => {
  console.error('[Startup] Fatal error:', err);
  process.exit(1);
});