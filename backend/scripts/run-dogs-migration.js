#!/usr/bin/env node

/**
 * Script to run the dogs table update migration on production
 */

const fs = require('fs');
const path = require('path');
const { Client } = require('pg');
require('dotenv').config();

async function runDogsMigration() {
  // Use Railway's DATABASE_URL
  const config = process.env.DATABASE_URL 
    ? {
        connectionString: process.env.DATABASE_URL,
        ssl: { rejectUnauthorized: false }
      }
    : {
        host: process.env.DB_HOST,
        port: process.env.DB_PORT,
        database: process.env.DB_NAME,
        user: process.env.DB_USER,
        password: process.env.DB_PASSWORD
      };

  const client = new Client(config);

  try {
    console.log('🔗 Connecting to database...');
    await client.connect();
    console.log('✅ Connected successfully\n');

    // First, let's backup the existing dogs data
    console.log('📦 Backing up existing dogs data...');
    const backupResult = await client.query('SELECT * FROM dogs');
    console.log(`   Found ${backupResult.rows.length} existing dogs\n`);

    // Read the migration file
    const migrationPath = path.join(__dirname, '../migrations/update-dogs-table-safe.sql');
    const migrationSQL = fs.readFileSync(migrationPath, 'utf8');

    console.log('🚀 Running dogs table update migration...');
    
    // Run the entire migration as a single transaction
    await client.query('BEGIN');
    
    try {
      await client.query(migrationSQL);
      await client.query('COMMIT');
      console.log('   ✅ Migration executed successfully');
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    }

    console.log('✅ Migration completed successfully!\n');

    // Verify the new schema
    console.log('🔍 Verifying new schema...');
    const schemaResult = await client.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns
      WHERE table_name = 'dogs'
      ORDER BY ordinal_position
    `);

    console.log('New dogs table columns:');
    schemaResult.rows.forEach(col => {
      console.log(`   - ${col.column_name}: ${col.data_type}`);
    });

    // Update migration tracking
    try {
      await client.query(
        'INSERT INTO schema_migrations (version, applied_at) VALUES ($1, NOW())',
        ['update-dogs-table']
      );
      console.log('\n✅ Migration tracked in schema_migrations');
    } catch (err) {
      console.log('\n⚠️  Could not track migration (schema_migrations table may not exist)');
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

// Check if running directly
if (require.main === module) {
  console.log('🏗️  BarkPark Dogs Table Migration\n');
  console.log('⚠️  WARNING: This will modify the dogs table structure!');
  console.log('   Make sure you have a database backup.\n');
  
  // Give user a chance to cancel
  console.log('Starting in 5 seconds... (Ctrl+C to cancel)');
  
  setTimeout(() => {
    runDogsMigration();
  }, 5000);
}

module.exports = runDogsMigration;