#!/usr/bin/env node

/**
 * Seed Parks for Local Development
 * Imports all 103 dog parks using lat/lng columns
 */

// Load environment variables first
require('dotenv').config({ path: require('path').join(__dirname, '../.env.local') });

const pool = require('../config/database');
const fs = require('fs').promises;
const path = require('path');

async function seedParks() {
  console.log('🌱 Seeding dog parks for local development...\n');
  
  try {
    // Read the original seed files and convert them
    const initialParks = await fs.readFile(
      path.join(__dirname, '../migrations/005_seed_initial_parks.sql'), 
      'utf8'
    );
    
    const nycParks = await fs.readFile(
      path.join(__dirname, '../migrations/006_seed_nyc_parks.sql'),
      'utf8'
    );
    
    // Extract park data from SQL files
    const parks = [];
    
    // Parse initial parks (simpler format)
    const initialMatches = initialParks.matchAll(
      /\('([^']+)',\s*'([^']+)',\s*'([^']+)',\s*ST_MakePoint\(([-\d.]+),\s*([-\d.]+)\)::geography,\s*ARRAY\[([^\]]*)\]::text\[\],\s*([^,]*),\s*'([^']*)'::time,\s*'([^']*)'::time\)/g
    );
    
    for (const match of initialMatches) {
      parks.push({
        name: match[1],
        description: match[2],
        address: match[3],
        longitude: parseFloat(match[4]),
        latitude: parseFloat(match[5]),
        amenities: match[6] ? match[6].split(',').map(a => a.trim().replace(/'/g, '')) : [],
        rules: match[7] === 'NULL' ? null : match[7].replace(/'/g, ''),
        hours_open: match[8] || null,
        hours_close: match[9] || null
      });
    }
    
    console.log(`📍 Found ${parks.length} initial parks`);
    
    // Parse NYC parks (more complex format)
    const nycMatches = nycParks.matchAll(
      /VALUES\s*\(\s*'([^']+)',\s*'([^']+)',\s*'([^']+)',\s*ST_MakePoint\(([-\d.]+),\s*([-\d.]+)\)::geography,\s*ARRAY\[([^\]]*)\]::text\[\],\s*([^,]*),\s*'([^']*)'::time,\s*'([^']*)'::time,\s*'([^']*)',\s*'([^']*)'\s*\)/g
    );
    
    for (const match of nycMatches) {
      parks.push({
        name: match[1],
        description: match[2],
        address: match[3],
        longitude: parseFloat(match[4]),
        latitude: parseFloat(match[5]),
        amenities: match[6] ? match[6].split(',').map(a => a.trim().replace(/'/g, '')) : [],
        rules: match[7] === 'NULL' ? null : match[7].replace(/'/g, ''),
        hours_open: match[8] || null,
        hours_close: match[9] || null,
        zipcode: match[10],
        borough: match[11]
      });
    }
    
    console.log(`📍 Found ${parks.length - 12} NYC parks`);
    console.log(`📊 Total parks to seed: ${parks.length}\n`);
    
    // Clear existing parks
    await pool.query('DELETE FROM dog_parks');
    console.log('🧹 Cleared existing parks');
    
    // Insert parks
    let inserted = 0;
    for (const park of parks) {
      try {
        await pool.query(`
          INSERT INTO dog_parks (
            name, description, address, latitude, longitude, 
            amenities, rules, hours_open, hours_close, zipcode, borough
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
        `, [
          park.name,
          park.description,
          park.address,
          park.latitude,
          park.longitude,
          park.amenities || [],
          park.rules,
          park.hours_open,
          park.hours_close,
          park.zipcode || null,
          park.borough || null
        ]);
        inserted++;
        
        if (inserted % 10 === 0) {
          process.stdout.write(`\r✅ Inserted ${inserted}/${parks.length} parks...`);
        }
      } catch (error) {
        console.error(`\n❌ Failed to insert park "${park.name}":`, error.message);
      }
    }
    
    console.log(`\n\n✅ Successfully seeded ${inserted} dog parks!`);
    
    // Show sample data
    const sample = await pool.query(`
      SELECT name, address, latitude, longitude 
      FROM dog_parks 
      ORDER BY id 
      LIMIT 5
    `);
    
    console.log('\n📋 Sample parks:');
    sample.rows.forEach(park => {
      console.log(`   - ${park.name} (${park.latitude}, ${park.longitude})`);
    });
    
    // Update migration record
    await pool.query(`
      INSERT INTO schema_migrations (id, checksum) VALUES 
        ('005_seed_initial_parks', 'local_seed'),
        ('006_seed_nyc_parks', 'local_seed')
      ON CONFLICT (id) DO UPDATE SET checksum = 'local_seed'
    `);
    
    console.log('\n✅ Migration records updated');
    
  } catch (error) {
    console.error('❌ Error seeding parks:', error);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

// Run if called directly
if (require.main === module) {
  seedParks();
}