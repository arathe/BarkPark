#!/usr/bin/env node

/**
 * Check staging database for dog parks data
 * Usage: DATABASE_URL=your-staging-url node scripts/check-staging-data.js
 */

const path = require('path');

// Ensure we're using the correct node_modules
const modulePath = path.join(__dirname, '..', 'node_modules', 'pg');
let Client;

try {
  Client = require(modulePath).Client;
} catch (err) {
  console.error('Error loading pg module. Make sure you run "npm install" in the backend directory.');
  console.error('Current directory:', process.cwd());
  console.error('Script directory:', __dirname);
  console.error('Looking for pg at:', modulePath);
  process.exit(1);
}

async function checkStagingData() {
  // Check if DATABASE_URL is provided
  if (!process.env.DATABASE_URL) {
    console.error('ERROR: Please provide DATABASE_URL environment variable');
    console.error('Usage: DATABASE_URL=your-staging-url node scripts/check-staging-data.js');
    process.exit(1);
  }

  const client = new Client({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false } // Required for Railway
  });

  try {
    console.log('Connecting to staging database...');
    await client.connect();
    console.log('Connected successfully!\n');

    // Check if dog_parks table exists
    const tableCheck = await client.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'dog_parks'
      );
    `);

    if (!tableCheck.rows[0].exists) {
      console.log('❌ dog_parks table does not exist');
      return;
    }

    // Count dog parks
    const countResult = await client.query('SELECT COUNT(*) FROM dog_parks');
    const count = parseInt(countResult.rows[0].count);
    console.log(`📊 Dog parks in database: ${count}`);

    // Check migration status
    console.log('\n📋 Migration status:');
    const migrationCheck = await client.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'schema_migrations'
      );
    `);

    if (migrationCheck.rows[0].exists) {
      const migrations = await client.query(`
        SELECT id, description, applied_at 
        FROM schema_migrations 
        ORDER BY applied_at;
      `);

      if (migrations.rows.length > 0) {
        console.log('Applied migrations:');
        migrations.rows.forEach(m => {
          console.log(`  ✅ ${m.id}: ${m.description}`);
          console.log(`     Applied: ${new Date(m.applied_at).toLocaleString()}`);
        });

        // Check specifically for seed migrations
        const hasSeedMigrations = migrations.rows.some(m => 
          m.id === '005_seed_initial_parks' || m.id === '006_seed_nyc_parks'
        );

        if (!hasSeedMigrations) {
          console.log('\n⚠️  Seed migrations have not been run!');
          console.log('  Missing: 005_seed_initial_parks');
          console.log('  Missing: 006_seed_nyc_parks');
        }
      } else {
        console.log('No migrations have been applied');
      }
    } else {
      console.log('❌ Migration tracking table does not exist');
    }

    // Sample some parks if they exist
    if (count > 0) {
      console.log('\n🏞️  Sample parks:');
      const sample = await client.query(`
        SELECT name, borough, created_at 
        FROM dog_parks 
        ORDER BY created_at DESC 
        LIMIT 5;
      `);
      
      sample.rows.forEach(park => {
        console.log(`  - ${park.name} (${park.borough || 'Unknown'})`);
      });
    }

    // Check PostGIS
    console.log('\n🌍 PostGIS status:');
    try {
      const postgis = await client.query(`SELECT PostGIS_Version();`);
      console.log(`  ✅ PostGIS installed: ${postgis.rows[0].postgis_version}`);
    } catch (e) {
      console.log('  ❌ PostGIS not installed');
    }

  } catch (error) {
    console.error('Error:', error.message);
  } finally {
    await client.end();
  }
}

checkStagingData();