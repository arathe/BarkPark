const pool = require('../config/database');
const fs = require('fs');
const path = require('path');

async function seedParks() {
  try {
    console.log('🌱 Starting park data seeding...');

    // Read the SQL file
    const sqlPath = path.join(__dirname, 'seed-parks.sql');
    const sqlContent = fs.readFileSync(sqlPath, 'utf8');

    // Execute the SQL
    await pool.query(sqlContent);

    console.log('✅ Park data seeded successfully!');
    
    // Verify by counting parks
    const countResult = await pool.query('SELECT COUNT(*) FROM dog_parks');
    console.log(`📊 Total parks in database: ${countResult.rows[0].count}`);

  } catch (error) {
    console.error('❌ Error seeding park data:', error);
    throw error;
  } finally {
    await pool.end();
  }
}

// Run if called directly
if (require.main === module) {
  seedParks()
    .then(() => process.exit(0))
    .catch(() => process.exit(1));
}

module.exports = seedParks;