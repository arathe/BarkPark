const pool = require('./config/database');

async function diagnoseDatabase() {
  const client = await pool.connect();
  
  try {
    console.log('=== Database Schema Diagnosis ===\n');
    
    // Check users table columns
    console.log('1. Checking users table schema...');
    const usersQuery = `
      SELECT column_name, data_type, is_nullable, column_default
      FROM information_schema.columns
      WHERE table_name = 'users'
      ORDER BY ordinal_position;
    `;
    const usersResult = await client.query(usersQuery);
    console.log('Users table columns:');
    usersResult.rows.forEach(col => {
      console.log(`  - ${col.column_name}: ${col.data_type} ${col.is_nullable === 'NO' ? 'NOT NULL' : 'NULL'} ${col.column_default ? `DEFAULT ${col.column_default}` : ''}`);
    });
    
    // Check dogs table columns
    console.log('\n2. Checking dogs table schema...');
    const dogsQuery = `
      SELECT column_name, data_type, is_nullable, column_default
      FROM information_schema.columns
      WHERE table_name = 'dogs'
      ORDER BY ordinal_position;
    `;
    const dogsResult = await client.query(dogsQuery);
    console.log('Dogs table columns:');
    dogsResult.rows.forEach(col => {
      console.log(`  - ${col.column_name}: ${col.data_type} ${col.is_nullable === 'NO' ? 'NOT NULL' : 'NULL'} ${col.column_default ? `DEFAULT ${col.column_default}` : ''}`);
    });
    
    // Check dog_parks table columns
    console.log('\n3. Checking dog_parks table schema...');
    const parksQuery = `
      SELECT column_name, data_type, is_nullable, column_default
      FROM information_schema.columns
      WHERE table_name = 'dog_parks'
      ORDER BY ordinal_position;
    `;
    const parksResult = await client.query(parksQuery);
    console.log('Dog_parks table columns:');
    parksResult.rows.forEach(col => {
      console.log(`  - ${col.column_name}: ${col.data_type} ${col.is_nullable === 'NO' ? 'NOT NULL' : 'NULL'} ${col.column_default ? `DEFAULT ${col.column_default}` : ''}`);
    });
    
    // Check constraints on dogs table
    console.log('\n4. Checking constraints on dogs table...');
    const constraintsQuery = `
      SELECT conname, pg_get_constraintdef(oid) 
      FROM pg_constraint 
      WHERE conrelid = 'dogs'::regclass;
    `;
    const constraintsResult = await client.query(constraintsQuery);
    console.log('Constraints:');
    constraintsResult.rows.forEach(constraint => {
      console.log(`  - ${constraint.conname}: ${constraint.pg_get_constraintdef}`);
    });
    
    // Check for PostGIS extension
    console.log('\n5. Checking PostGIS extension...');
    const postgisQuery = `
      SELECT * FROM pg_extension WHERE extname = 'postgis';
    `;
    const postgisResult = await client.query(postgisQuery);
    console.log(`PostGIS installed: ${postgisResult.rows.length > 0 ? 'Yes' : 'No'}`);
    
    // Count records in main tables
    console.log('\n6. Record counts:');
    const countTables = ['users', 'dogs', 'dog_parks', 'friendships', 'checkins'];
    for (const table of countTables) {
      const countResult = await client.query(`SELECT COUNT(*) FROM ${table}`);
      console.log(`  - ${table}: ${countResult.rows[0].count} records`);
    }
    
    // Check schema_migrations
    console.log('\n7. Applied migrations:');
    try {
      const migrationsResult = await client.query('SELECT filename, executed_at FROM schema_migrations ORDER BY executed_at');
      migrationsResult.rows.forEach(migration => {
        console.log(`  - ${migration.filename}: ${new Date(migration.executed_at).toISOString()}`);
      });
    } catch (error) {
      console.log('  - schema_migrations table not found');
    }
    
  } catch (error) {
    console.error('Error diagnosing database:', error);
  } finally {
    client.release();
    process.exit(0);
  }
}

diagnoseDatabase();