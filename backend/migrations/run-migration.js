const fs = require('fs');
const path = require('path');
const pool = require('../config/database');

async function runMigration() {
  try {
    console.log('🔄 Running privacy settings migration...');
    
    // Read the migration SQL file
    const migrationPath = path.join(__dirname, 'add-privacy-settings.sql');
    const migrationSQL = fs.readFileSync(migrationPath, 'utf8');
    
    // Execute the migration
    await pool.query(migrationSQL);
    
    console.log('✅ Privacy settings migration completed successfully!');
    
    // Verify the migration worked
    const result = await pool.query(`
      SELECT column_name, data_type, is_nullable, column_default 
      FROM information_schema.columns 
      WHERE table_name = 'users' AND column_name = 'is_searchable'
    `);
    
    if (result.rows.length > 0) {
      console.log('✅ Verified: is_searchable column added to users table');
      console.log('Column details:', result.rows[0]);
    } else {
      console.log('❌ Column verification failed');
    }
    
  } catch (error) {
    console.error('❌ Migration failed:', error.message);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

runMigration();