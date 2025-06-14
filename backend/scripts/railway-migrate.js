#!/usr/bin/env node

/**
 * Railway Database Migration Runner
 * This script executes database migrations in order, tracking which have been applied
 */

const fs = require('fs');
const path = require('path');
const { Client } = require('pg');
require('dotenv').config({ path: path.join(__dirname, '../.env') });

// Parse command line arguments
const args = process.argv.slice(2);
const shouldSeed = args.includes('--seed');
const forceRun = args.includes('--force');

// Database connection configuration
const getDbConfig = () => {
  // Railway provides DATABASE_URL
  if (process.env.DATABASE_URL) {
    return {
      connectionString: process.env.DATABASE_URL,
      ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false
    };
  }
  
  // Fallback to individual env vars for local development
  return {
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 5432,
    database: process.env.DB_NAME || 'barkpark',
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD || ''
  };
};

// Migration files in order
const migrations = [
  '001_create_schema.sql',
  '002_seed_data.sql',
  '003_nyc_dog_runs.sql'
];

// Only include seed migrations if --seed flag is provided
const getMigrationsToRun = () => {
  if (shouldSeed) {
    return migrations;
  }
  // Only schema migration if not seeding
  return migrations.filter(m => m.includes('schema'));
};

async function runMigrations() {
  const client = new Client(getDbConfig());
  
  try {
    console.log('🔗 Connecting to database...');
    await client.connect();
    console.log('✅ Connected successfully\n');
    
    // Check if this is a fresh database
    const tableCheck = await client.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'schema_migrations'
      );
    `);
    
    const migrationsTableExists = tableCheck.rows[0].exists;
    
    if (!migrationsTableExists && !forceRun) {
      console.log('📋 This appears to be a fresh database.');
      console.log('   Running initial setup...\n');
    }
    
    const migrationsToRun = getMigrationsToRun();
    let appliedCount = 0;
    
    for (const migration of migrationsToRun) {
      const migrationPath = path.join(__dirname, '../migrations', migration);
      
      // Check if migration file exists
      if (!fs.existsSync(migrationPath)) {
        console.error(`❌ Migration file not found: ${migration}`);
        continue;
      }
      
      // Check if migration has already been applied (skip this check for first migration)
      if (migrationsTableExists || migration !== '001_create_schema.sql') {
        try {
          const result = await client.query(
            'SELECT version FROM schema_migrations WHERE version = $1',
            [migration.replace('.sql', '')]
          );
          
          if (result.rows.length > 0 && !forceRun) {
            console.log(`⏭️  Skipping ${migration} (already applied)`);
            continue;
          }
        } catch (err) {
          // schema_migrations table doesn't exist yet, continue
        }
      }
      
      // Read and execute migration
      console.log(`🚀 Running migration: ${migration}`);
      const sql = fs.readFileSync(migrationPath, 'utf8');
      
      try {
        await client.query(sql);
        console.log(`✅ Successfully applied: ${migration}\n`);
        appliedCount++;
      } catch (err) {
        console.error(`❌ Error applying ${migration}:`, err.message);
        throw err;
      }
    }
    
    // Summary
    console.log('\n📊 Migration Summary:');
    console.log(`   Total migrations: ${migrationsToRun.length}`);
    console.log(`   Applied: ${appliedCount}`);
    console.log(`   Skipped: ${migrationsToRun.length - appliedCount}`);
    
    // Verify tables were created
    const tableCount = await client.query(`
      SELECT COUNT(*) FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_type = 'BASE TABLE'
    `);
    
    console.log(`\n✅ Database setup complete!`);
    console.log(`   Tables created: ${tableCount.rows[0].count}`);
    
    if (shouldSeed) {
      const parkCount = await client.query('SELECT COUNT(*) FROM dog_parks');
      console.log(`   Dog parks loaded: ${parkCount.rows[0].count}`);
    }
    
  } catch (err) {
    console.error('\n❌ Migration failed:', err.message);
    if (err.detail) {
      console.error('   Details:', err.detail);
    }
    process.exit(1);
  } finally {
    await client.end();
  }
}

// Show usage
if (args.includes('--help')) {
  console.log(`
Railway Database Migration Runner

Usage: node scripts/railway-migrate.js [options]

Options:
  --seed    Include seed data (parks) in migration
  --force   Force re-run migrations even if already applied
  --help    Show this help message

Examples:
  node scripts/railway-migrate.js              # Run only schema migrations
  node scripts/railway-migrate.js --seed       # Run schema + seed data
  node scripts/railway-migrate.js --force      # Force re-run all migrations
`);
  process.exit(0);
}

// Run migrations
console.log('🏗️  BarkPark Database Migration Tool\n');
runMigrations();