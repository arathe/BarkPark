#!/usr/bin/env node

/**
 * Local Database Migration Runner
 * This version is optimized for local development without PostGIS
 */

const fs = require('fs').promises;
const path = require('path');
const { Client } = require('pg');
require('dotenv').config({ path: path.join(__dirname, '../.env.local') });

// Local migrations that work without PostGIS
const localMigrations = [
  {
    id: '000_create_initial_schema_compat',
    file: '000_create_initial_schema_compat.sql',
    description: 'Create all base tables (PostGIS-compatible version)'
  },
  {
    id: '002_add_dogs_extended_fields',
    file: '002_add_dogs_extended_fields.sql',
    description: 'Add extended fields to dogs table'
  },
  {
    id: '003_add_parks_extended_fields',
    file: '003_add_parks_extended_fields.sql',
    description: 'Add NYC enrichment fields to parks table'
  },
  {
    id: '004_add_user_privacy',
    file: '004_add_user_privacy.sql',
    description: 'Add is_searchable field to users table'
  },
  {
    id: '005_seed_initial_parks_compat',
    file: '005_seed_initial_parks_compat.sql',
    description: 'Seed initial 12 parks (lat/lng version)'
  },
  {
    id: '006_seed_nyc_parks_compat',
    file: '006_seed_nyc_parks_compat.sql',
    description: 'Import 91 NYC dog runs (lat/lng version)'
  },
  {
    id: '007_add_social_feed',
    file: '007_add_social_feed.sql',
    description: 'Add social feed tables'
  }
];

async function ensureMigrationTable(client) {
  await client.query(`
    CREATE TABLE IF NOT EXISTS schema_migrations (
      id VARCHAR(255) PRIMARY KEY,
      checksum VARCHAR(64) NOT NULL,
      executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      success BOOLEAN DEFAULT TRUE,
      error_message TEXT
    )
  `);
}

async function getMigrationChecksum(content) {
  const crypto = require('crypto');
  return crypto.createHash('sha256').update(content, 'utf8').digest('hex');
}

async function runMigration(client, migration) {
  const migrationPath = path.join(__dirname, '../migrations', migration.file);
  
  // Check if we need to create a compat version
  if (migration.file.includes('_compat.sql') && !await fs.access(migrationPath).then(() => true).catch(() => false)) {
    console.log(`Creating compatibility version of ${migration.file}...`);
    await createCompatMigration(migration);
  }
  
  const content = await fs.readFile(migrationPath, 'utf8');
  const checksum = await getMigrationChecksum(content);
  
  // Check if migration was already run
  const result = await client.query(
    'SELECT * FROM schema_migrations WHERE id = $1',
    [migration.id]
  );
  
  if (result.rows.length > 0) {
    console.log(`✓ ${migration.id} already executed`);
    return;
  }
  
  console.log(`→ Running ${migration.id}...`);
  
  try {
    await client.query('BEGIN');
    await client.query(content);
    await client.query(
      'INSERT INTO schema_migrations (id, checksum) VALUES ($1, $2)',
      [migration.id, checksum]
    );
    await client.query('COMMIT');
    console.log(`✓ ${migration.id} completed`);
  } catch (error) {
    await client.query('ROLLBACK');
    console.error(`✗ ${migration.id} failed:`, error.message);
    throw error;
  }
}

async function createCompatMigration(migration) {
  const originalPath = path.join(__dirname, '../migrations', migration.file.replace('_compat', ''));
  const compatPath = path.join(__dirname, '../migrations', migration.file);
  
  if (migration.file === '005_seed_initial_parks_compat.sql') {
    // Read original and convert ST_MakePoint to lat/lng values
    const original = await fs.readFile(originalPath, 'utf8');
    const compat = original.replace(
      /ST_MakePoint\(([-\d.]+),\s*([-\d.]+)\)::geography/g,
      "$2, $1"
    ).replace(
      "INSERT INTO dog_parks (name, description, address, location, amenities, rules, hours_open, hours_close)",
      "INSERT INTO dog_parks (name, description, address, latitude, longitude, amenities, rules, hours_open, hours_close)"
    );
    await fs.writeFile(compatPath, compat);
  } else if (migration.file === '006_seed_nyc_parks_compat.sql') {
    // Similar conversion for NYC parks
    const original = await fs.readFile(originalPath, 'utf8');
    let compat = original.replace(
      /ST_MakePoint\(([-\d.]+),\s*([-\d.]+)\)::geography/g,
      "$2, $1"
    );
    // Handle multi-line INSERT format
    compat = compat.replace(
      /INSERT INTO dog_parks \(\s*name, description, address, location, amenities, rules,/g,
      "INSERT INTO dog_parks (\n    name, description, address, latitude, longitude, amenities, rules,"
    );
    await fs.writeFile(compatPath, compat);
  }
}

async function main() {
  const dbConfig = {
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 5432,
    database: process.env.DB_NAME || 'barkpark',
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD || ''
  };
  
  console.log('🚀 Starting local database migration...');
  console.log(`📍 Connecting to ${dbConfig.host}:${dbConfig.port}/${dbConfig.database}`);
  
  const client = new Client(dbConfig);
  
  try {
    await client.connect();
    await ensureMigrationTable(client);
    
    for (const migration of localMigrations) {
      await runMigration(client, migration);
    }
    
    console.log('\n✅ All migrations completed successfully!');
    
    // Show summary
    const count = await client.query('SELECT COUNT(*) FROM dog_parks');
    console.log(`\n📊 Database Summary:`);
    console.log(`   - Dog Parks: ${count.rows[0].count}`);
    
  } catch (error) {
    console.error('\n❌ Migration failed:', error.message);
    process.exit(1);
  } finally {
    await client.end();
  }
}

main();