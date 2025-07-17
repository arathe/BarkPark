#!/usr/bin/env node

/**
 * Unified Database Migration Runner for BarkPark
 * This replaces both migrate.js and railway-migrate.js with a single, consistent system
 */

const fs = require('fs').promises;
const path = require('path');
const { Client } = require('pg');
require('dotenv').config({ path: path.join(__dirname, '../.env') });
require('dotenv').config({ path: path.join(__dirname, '../.env.local') });

// Parse command line arguments
const args = process.argv.slice(2);
const flags = {
  seed: args.includes('--seed'),
  force: args.includes('--force'),
  verify: args.includes('--verify'),
  status: args.includes('--status'),
  help: args.includes('--help')
};

// Database connection configuration
const getDbConfig = () => {
  const environment = process.env.NODE_ENV || 'development';
  
  if (process.env.DATABASE_URL) {
    console.log(`[Migration] Using DATABASE_URL for connection (${environment} environment)`);
    return {
      connectionString: process.env.DATABASE_URL,
      ssl: ['production', 'staging'].includes(environment) ? { rejectUnauthorized: false } : false
    };
  }
  
  console.log(`[Migration] Using individual environment variables (${environment} environment)`);
  return {
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 5432,
    database: process.env.DB_NAME || 'barkpark',
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD || ''
  };
};

// Unified migration list with proper ordering
const migrations = [
  {
    id: '001_create_initial_schema',
    file: '001_create_initial_schema.sql',
    description: 'Create all base tables with initial schema'
  },
  {
    id: '002_add_dogs_extended_fields',
    file: '002_add_dogs_extended_fields.sql',
    description: 'Add extended fields to dogs table (birthday, gender, etc)'
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
    id: '005_seed_initial_parks',
    file: '005_seed_initial_parks.sql',
    description: 'Seed initial 12 parks',
    isSeed: true
  },
  {
    id: '006_seed_nyc_parks',
    file: '006_seed_nyc_parks.sql',
    description: 'Import 91 NYC dog runs',
    isSeed: true
  },
  {
    id: '007_add_social_feed',
    file: '007_add_social_feed.sql',
    description: 'Add social feed tables (posts, media, likes, comments, notifications)'
  },
  {
    id: '008_add_password_reset',
    file: '008_add_password_reset.sql',
    description: 'Add password reset functionality'
  },
  {
    id: '009_add_password_reset_attempts',
    file: '009_add_password_reset_attempts.sql',
    description: 'Add password reset attempt tracking'
  },
  {
    id: '010_fix_column_names',
    file: '010_fix_column_names.sql',
    description: 'Fix column names to match application code'
  }
];

// Get migrations to run based on flags
const getMigrationsToRun = () => {
  if (flags.seed) {
    return migrations; // Run all including seeds
  }
  return migrations.filter(m => !m.isSeed); // Only schema migrations
};

// Create or verify migration tracking table
async function ensureMigrationTable(client) {
  try {
    console.log('📋 Ensuring schema_migrations table exists...');
    
    // First check if table exists
    const tableExists = await client.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_name = 'schema_migrations'
      )
    `);
    
    if (tableExists.rows[0].exists) {
      console.log('⚠️  schema_migrations table already exists, checking structure...');
      
      // Get current columns
      const columns = await client.query(`
        SELECT column_name, data_type 
        FROM information_schema.columns 
        WHERE table_name = 'schema_migrations'
        ORDER BY ordinal_position
      `);
      
      console.log('   Current columns:', columns.rows.map(c => c.column_name).join(', '));
      
      // Check if we need to migrate from old schema
      const hasIdColumn = columns.rows.some(c => c.column_name === 'id');
      
      if (!hasIdColumn) {
        console.log('🔄 Migrating schema_migrations table to new format...');
        
        // Drop the old table and recreate with new schema
        await client.query('DROP TABLE schema_migrations');
        console.log('   Dropped old schema_migrations table');
        
        await client.query(`
          CREATE TABLE schema_migrations (
            id VARCHAR(255) PRIMARY KEY,
            description TEXT,
            executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            execution_time_ms INTEGER,
            checksum VARCHAR(64)
          )
        `);
        console.log('   Created new schema_migrations table with id column');
      }
    } else {
      // Create new table
      await client.query(`
        CREATE TABLE schema_migrations (
          id VARCHAR(255) PRIMARY KEY,
          description TEXT,
          executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          execution_time_ms INTEGER,
          checksum VARCHAR(64)
        )
      `);
      console.log('✅ Created new schema_migrations table');
    }
    
    console.log('✅ schema_migrations table ready');
  } catch (err) {
    console.error('❌ Error managing schema_migrations table:', err.message);
    console.error('   Full error:', err);
    throw err;
  }
}

// Calculate file checksum for change detection
async function calculateChecksum(content) {
  const crypto = require('crypto');
  return crypto.createHash('sha256').update(content).digest('hex');
}

// Check if migration has been applied
async function isMigrationApplied(client, migrationId) {
  try {
    const result = await client.query(
      'SELECT id, checksum FROM schema_migrations WHERE id = $1',
      [migrationId]
    );
    return result.rows.length > 0 ? result.rows[0] : null;
  } catch (err) {
    console.error(`❌ Error checking migration ${migrationId}:`, err.message);
    if (err.message.includes('does not exist')) {
      console.error('   The schema_migrations table may not exist yet.');
    }
    throw err;
  }
}

// Record successful migration
async function recordMigration(client, migration, checksum, executionTime) {
  await client.query(
    `INSERT INTO schema_migrations (id, description, checksum, execution_time_ms) 
     VALUES ($1, $2, $3, $4)
     ON CONFLICT (id) DO UPDATE SET 
       checksum = $3,
       executed_at = CURRENT_TIMESTAMP,
       execution_time_ms = $4`,
    [migration.id, migration.description, checksum, executionTime]
  );
}

// Verify schema consistency
async function verifySchema(client) {
  console.log('\n🔍 Verifying Database Schema...\n');
  
  const tables = ['users', 'dogs', 'dog_parks', 'friendships', 'checkins', 'messages', 'park_notices'];
  const issues = [];
  
  for (const table of tables) {
    const result = await client.query(`
      SELECT column_name, data_type, is_nullable
      FROM information_schema.columns
      WHERE table_name = $1
      ORDER BY ordinal_position
    `, [table]);
    
    if (result.rows.length === 0) {
      issues.push(`Table '${table}' is missing`);
      continue;
    }
    
    console.log(`✓ Table '${table}' exists with ${result.rows.length} columns`);
    
    // Check for specific required columns
    const columns = result.rows.map(r => r.column_name);
    
    if (table === 'dogs') {
      const requiredDogColumns = ['birthday', 'gender', 'size_category', 'energy_level', 'bio'];
      const missing = requiredDogColumns.filter(col => !columns.includes(col));
      if (missing.length > 0) {
        issues.push(`Table 'dogs' is missing columns: ${missing.join(', ')}`);
      }
    }
    
    if (table === 'users' && !columns.includes('is_searchable')) {
      issues.push(`Table 'users' is missing 'is_searchable' column`);
    }
    
    if (table === 'dog_parks') {
      const nycColumns = ['website', 'phone', 'rating', 'borough'];
      const missing = nycColumns.filter(col => !columns.includes(col));
      if (missing.length > 0) {
        issues.push(`Table 'dog_parks' is missing NYC enrichment columns: ${missing.join(', ')}`);
      }
    }
  }
  
  if (issues.length === 0) {
    console.log('\n✅ Schema verification passed - all tables and columns are correct\n');
  } else {
    console.log('\n⚠️  Schema Issues Found:');
    issues.forEach(issue => console.log(`   - ${issue}`));
    console.log('\n   Run migrations to fix these issues\n');
  }
  
  return issues;
}

// Show migration status
async function showStatus(client) {
  console.log('\n📊 Migration Status\n');
  
  try {
    const applied = await client.query(`
      SELECT id, description, executed_at, execution_time_ms 
      FROM schema_migrations 
      ORDER BY executed_at
    `);
  
  console.log('Applied Migrations:');
  if (applied.rows.length === 0) {
    console.log('   (none)\n');
  } else {
    applied.rows.forEach(m => {
      const date = new Date(m.executed_at).toLocaleString();
      console.log(`   ✓ ${m.id} - ${m.description}`);
      console.log(`     Applied: ${date} (${m.execution_time_ms}ms)\n`);
    });
  }
  
  const appliedIds = applied.rows.map(r => r.id);
  const pending = migrations.filter(m => !appliedIds.includes(m.id));
  
  console.log('Pending Migrations:');
  if (pending.length === 0) {
    console.log('   (none)\n');
  } else {
    pending.forEach(m => {
      console.log(`   ○ ${m.id} - ${m.description}`);
    });
    console.log('');
  }
  
    // Also verify schema
    await verifySchema(client);
  } catch (err) {
    console.error('❌ Error in showStatus:', err.message);
    console.error('   Query error details:', err.detail || 'No additional details');
    console.error('   This might indicate the schema_migrations table does not exist yet.');
    throw err;
  }
}

// Run migrations
async function runMigrations() {
  const client = new Client(getDbConfig());
  
  try {
    console.log('🔗 Connecting to database...');
    await client.connect();
    console.log('✅ Connected successfully\n');
    
    // Ensure migration tracking table exists
    try {
      console.log('[DEBUG] About to call ensureMigrationTable...');
      await ensureMigrationTable(client);
      console.log('[DEBUG] ensureMigrationTable completed successfully');
    } catch (err) {
      console.error('[DEBUG] Error in ensureMigrationTable:', err.message);
      throw err;
    }
    
    // Check existing tables before running migrations
    console.log('\n📊 Checking existing database tables...');
    const existingTables = await client.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_type = 'BASE TABLE'
      ORDER BY table_name
    `);
    
    if (existingTables.rows.length > 0) {
      console.log('   Existing tables:', existingTables.rows.map(t => t.table_name).join(', '));
      
      // Check dog_parks table structure if it exists
      const hasDogParks = existingTables.rows.some(t => t.table_name === 'dog_parks');
      if (hasDogParks) {
        const dogParksColumns = await client.query(`
          SELECT column_name, data_type, udt_name
          FROM information_schema.columns 
          WHERE table_name = 'dog_parks'
          ORDER BY ordinal_position
        `);
        console.log('\n   dog_parks columns:');
        dogParksColumns.rows.forEach(col => {
          console.log(`     - ${col.column_name}: ${col.data_type} (${col.udt_name})`);
        });
        
        // Check if we have PostGIS location column
        const hasLocationColumn = dogParksColumns.rows.some(c => c.column_name === 'location' && c.udt_name === 'geometry');
        if (hasLocationColumn) {
          console.log('\n   ⚠️  WARNING: dog_parks table has PostGIS geometry column, but app expects lat/lng columns');
          console.log('   Migration will need to convert or add lat/lng columns');
        }
      }
    } else {
      console.log('   No existing tables found (fresh database)');
    }
    console.log('');
    
    const migrationsToRun = getMigrationsToRun();
    let appliedCount = 0;
    let skippedCount = 0;
    
    for (const migration of migrationsToRun) {
      const migrationPath = path.join(__dirname, '../migrations', migration.file);
      
      // Check if file exists
      try {
        await fs.access(migrationPath);
      } catch (err) {
        console.error(`❌ Migration file not found: ${migration.file}`);
        continue;
      }
      
      // Read migration content
      const content = await fs.readFile(migrationPath, 'utf8');
      const checksum = await calculateChecksum(content);
      
      // Check if already applied
      console.log(`[DEBUG] Checking if migration ${migration.id} is already applied...`);
      const existing = await isMigrationApplied(client, migration.id);
      console.log(`[DEBUG] Migration ${migration.id} check complete`);
      
      if (existing && !flags.force) {
        if (existing.checksum === checksum) {
          console.log(`⏭️  Skipping ${migration.id} (already applied)`);
          skippedCount++;
          continue;
        } else {
          console.log(`⚠️  Warning: ${migration.id} has been modified since it was applied`);
          console.log(`   Use --force to re-apply modified migrations`);
          skippedCount++;
          continue;
        }
      }
      
      // Run migration
      console.log(`🚀 Running migration: ${migration.id}`);
      console.log(`   ${migration.description}`);
      
      const startTime = Date.now();
      
      try {
        await client.query('BEGIN');
        await client.query(content);
        await recordMigration(client, migration, checksum, Date.now() - startTime);
        await client.query('COMMIT');
        
        console.log(`   ✅ Applied successfully (${Date.now() - startTime}ms)\n`);
        appliedCount++;
      } catch (err) {
        await client.query('ROLLBACK');
        console.error(`   ❌ Failed: ${err.message}`);
        throw err;
      }
    }
    
    // Summary
    console.log('\n📊 Migration Summary:');
    console.log(`   Total migrations: ${migrationsToRun.length}`);
    console.log(`   Applied: ${appliedCount}`);
    console.log(`   Skipped: ${skippedCount}`);
    
    // Verify final state
    if (appliedCount > 0 || flags.verify) {
      await verifySchema(client);
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
function showHelp() {
  console.log(`
BarkPark Unified Database Migration Tool

Usage: npm run db:migrate [options]

Options:
  --seed      Include seed data (parks) in migration
  --force     Force re-run migrations even if already applied
  --verify    Only verify schema without running migrations  
  --status    Show migration status and schema verification
  --help      Show this help message

Examples:
  npm run db:migrate                # Run only schema migrations
  npm run db:migrate --seed          # Run schema + seed data
  npm run db:migrate --status        # Check migration status
  npm run db:migrate --verify        # Verify schema consistency
  npm run db:migrate --force --seed  # Force re-run all migrations

Production:
  railway run npm run db:migrate --seed     # Run in Railway environment
`);
}

// Main execution
async function main() {
  if (flags.help) {
    showHelp();
    process.exit(0);
  }
  
  const client = new Client(getDbConfig());
  
  try {
    await client.connect();
    
    // Always ensure migration table exists for consistency
    await ensureMigrationTable(client);
    
    if (flags.status) {
      await showStatus(client);
    } else if (flags.verify) {
      await verifySchema(client);
    } else {
      console.log('🏗️  BarkPark Database Migration Tool\n');
      await runMigrations();
    }
    
  } catch (err) {
    console.error('Error:', err.message);
    process.exit(1);
  } finally {
    await client.end();
  }
}

// Run if called directly
if (require.main === module) {
  main();
}

module.exports = { runMigrations, verifySchema };