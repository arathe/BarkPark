require('dotenv').config();
const { Pool } = require('pg');

// Use Railway's DATABASE_URL if available, otherwise fall back to individual env vars
const connectionString = process.env.DATABASE_URL;
const sslConfig = process.env.NODE_ENV === 'production' || connectionString ? { rejectUnauthorized: false } : false;

const pool = new Pool({
  connectionString: connectionString || undefined,
  ssl: sslConfig,
  // Fallback to individual env vars if DATABASE_URL not set
  host: connectionString ? undefined : process.env.DB_HOST,
  port: connectionString ? undefined : process.env.DB_PORT,
  user: connectionString ? undefined : process.env.DB_USER,
  password: connectionString ? undefined : process.env.DB_PASSWORD,
  database: connectionString ? undefined : process.env.DB_NAME
});

async function checkDogsTableSchema() {
  try {
    console.log('Checking dogs table schema in production database...\n');
    
    // Query to get all columns and their types from dogs table
    const schemaQuery = `
      SELECT 
        column_name, 
        data_type, 
        is_nullable,
        column_default
      FROM information_schema.columns
      WHERE table_name = 'dogs'
      ORDER BY ordinal_position;
    `;
    
    const result = await pool.query(schemaQuery);
    
    if (result.rows.length === 0) {
      console.log('❌ Dogs table does not exist in the database!');
      return;
    }
    
    console.log('Dogs table columns:');
    console.log('==================');
    result.rows.forEach(col => {
      console.log(`- ${col.column_name}: ${col.data_type} ${col.is_nullable === 'NO' ? '(NOT NULL)' : '(NULL)'}`);
    });
    
    // Check what the Dog model expects
    const expectedColumns = [
      'id', 'user_id', 'name', 'breed', 'birthday', 'weight', 'gender',
      'size_category', 'energy_level', 'friendliness_dogs', 'friendliness_people',
      'training_level', 'favorite_activities', 'is_vaccinated', 'is_spayed_neutered',
      'special_needs', 'bio', 'profile_image_url', 'gallery_images', 
      'created_at', 'updated_at'
    ];
    
    const actualColumns = result.rows.map(row => row.column_name);
    const missingColumns = expectedColumns.filter(col => !actualColumns.includes(col));
    const extraColumns = actualColumns.filter(col => !expectedColumns.includes(col));
    
    console.log('\n\nColumn Analysis:');
    console.log('================');
    
    if (missingColumns.length > 0) {
      console.log('❌ Missing columns that the Dog model expects:');
      missingColumns.forEach(col => console.log(`   - ${col}`));
    } else {
      console.log('✅ All expected columns exist');
    }
    
    if (extraColumns.length > 0) {
      console.log('\n⚠️  Extra columns in database not used by model:');
      extraColumns.forEach(col => console.log(`   - ${col}`));
    }
    
    // Check constraints
    console.log('\n\nConstraints:');
    console.log('============');
    const constraintQuery = `
      SELECT conname, pg_get_constraintdef(oid) as constraint_def
      FROM pg_constraint 
      WHERE conrelid = (SELECT oid FROM pg_class WHERE relname = 'dogs')
      ORDER BY conname;
    `;
    
    const constraints = await pool.query(constraintQuery);
    constraints.rows.forEach(con => {
      console.log(`- ${con.conname}: ${con.constraint_def}`);
    });
    
  } catch (error) {
    console.error('Error checking schema:', error.message);
    if (error.code === 'ECONNREFUSED') {
      console.error('\n⚠️  Could not connect to database. Make sure DATABASE_URL is set correctly.');
    }
  } finally {
    await pool.end();
  }
}

checkDogsTableSchema();