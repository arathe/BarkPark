const { Client } = require('pg');
const fs = require('fs').promises;
const path = require('path');

// Database connection from environment variables
const dbConfig = process.env.DATABASE_URL
  ? {
      connectionString: process.env.DATABASE_URL,
      ssl: process.env.NODE_ENV === 'production' 
        ? { rejectUnauthorized: false }
        : false
    }
  : {
      host: process.env.DB_HOST || 'localhost',
      port: process.env.DB_PORT || 5432,
      database: process.env.DB_NAME || 'barkpark',
      user: process.env.DB_USER || 'postgres',
      password: process.env.DB_PASSWORD,
      ssl: process.env.NODE_ENV === 'production' 
        ? { rejectUnauthorized: false } 
        : false
    };

// Migration files in order
const migrations = [
  'init-db.sql',
  'update-dogs-table.sql',
  'extend-parks-schema.sql',
  'add-privacy-settings.sql'
];

// Seed data files
const seedFiles = [
  'seed-parks.sql',
  'dog_runs_import.sql'
];

async function runMigrations() {
  const client = new Client(dbConfig);
  
  try {
    console.log('Connecting to database...');
    await client.connect();
    
    // Create migrations tracking table if it doesn't exist
    await client.query(`
      CREATE TABLE IF NOT EXISTS schema_migrations (
        id SERIAL PRIMARY KEY,
        filename VARCHAR(255) UNIQUE NOT NULL,
        executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    
    // Run each migration
    for (const migration of migrations) {
      console.log(`\nChecking migration: ${migration}`);
      
      // Check if migration has already been run
      const result = await client.query(
        'SELECT filename FROM schema_migrations WHERE filename = $1',
        [migration]
      );
      
      if (result.rows.length > 0) {
        console.log(`✓ Migration ${migration} already executed, skipping...`);
        continue;
      }
      
      // Read and execute migration file
      console.log(`Running migration: ${migration}`);
      const migrationPath = path.join(__dirname, '..', 'migrations', migration);
      const sql = await fs.readFile(migrationPath, 'utf8');
      
      await client.query(sql);
      
      // Record successful migration
      await client.query(
        'INSERT INTO schema_migrations (filename) VALUES ($1)',
        [migration]
      );
      
      console.log(`✓ Migration ${migration} completed successfully`);
    }
    
    // Ask user if they want to run seed data
    if (process.argv.includes('--seed')) {
      console.log('\n--- Running seed data ---');
      
      for (const seedFile of seedFiles) {
        console.log(`\nRunning seed: ${seedFile}`);
        const seedPath = path.join(__dirname, '..', 'migrations', seedFile);
        
        try {
          const sql = await fs.readFile(seedPath, 'utf8');
          await client.query(sql);
          console.log(`✓ Seed ${seedFile} completed successfully`);
        } catch (error) {
          console.error(`✗ Error running seed ${seedFile}:`, error.message);
          // Continue with other seeds even if one fails
        }
      }
    }
    
    console.log('\n✓ All migrations completed successfully!');
    
  } catch (error) {
    console.error('\n✗ Migration failed:', error);
    process.exit(1);
  } finally {
    await client.end();
  }
}

// Run migrations
runMigrations().catch(console.error);