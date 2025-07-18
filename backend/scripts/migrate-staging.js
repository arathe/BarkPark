#!/usr/bin/env node

/**
 * Run migrations on staging database
 * Usage: DATABASE_URL=your-staging-url node scripts/migrate-staging.js [--seed]
 */

const path = require('path');
const { spawn } = require('child_process');

// Check if DATABASE_URL is provided
if (!process.env.DATABASE_URL) {
  console.error('ERROR: Please provide DATABASE_URL environment variable');
  console.error('Usage: DATABASE_URL=your-staging-url node scripts/migrate-staging.js [--seed]');
  console.error('\nExample:');
  console.error('DATABASE_URL=postgresql://... node scripts/migrate-staging.js --seed');
  process.exit(1);
}

// Set NODE_ENV to staging to ensure proper SSL configuration
process.env.NODE_ENV = 'staging';

console.log('🚀 Running migrations on staging database...');
console.log('Environment: staging');
console.log('Include seeds:', process.argv.includes('--seed') ? 'Yes' : 'No');
console.log('');

// Run the unified migration script
const args = ['scripts/unified-migrate.js'];
if (process.argv.includes('--seed')) {
  args.push('--seed');
}
if (process.argv.includes('--status')) {
  args.push('--status');
}
if (process.argv.includes('--verify')) {
  args.push('--verify');
}

const migrate = spawn('node', args, {
  cwd: path.join(__dirname, '..'),
  env: process.env,
  stdio: 'inherit'
});

migrate.on('close', (code) => {
  if (code === 0) {
    console.log('\n✅ Migration completed successfully');
  } else {
    console.error(`\n❌ Migration failed with code ${code}`);
  }
  process.exit(code);
});