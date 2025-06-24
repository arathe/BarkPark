#!/usr/bin/env node

/**
 * Convert NYC Parks from PostGIS format to lat/lng format
 */

const fs = require('fs').promises;
const path = require('path');

async function convertNYCParks() {
  try {
    // Read the original NYC parks file
    const nycParksSQL = await fs.readFile(
      path.join(__dirname, '../migrations/006_seed_nyc_parks.sql'),
      'utf8'
    );
    
    // Convert ST_MakePoint to lat/lng
    let converted = nycParksSQL;
    
    // Replace the INSERT statement structure
    converted = converted.replace(
      /INSERT INTO dog_parks \(\s*name, description, address, location, amenities, rules,\s*hours_open, hours_close, website, phone, rating, review_count,\s*surface_type, has_seating, zipcode, borough, created_at, updated_at\s*\)/g,
      `INSERT INTO dog_parks (
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
)`
    );
    
    // Convert ST_MakePoint(lng, lat) to lat, lng values
    converted = converted.replace(
      /ST_MakePoint\(([-\d.]+),\s*([-\d.]+)\)::geography/g,
      '$2, $1'
    );
    
    // Replace Python boolean values
    converted = converted.replace(/\bTrue\b/g, 'true');
    converted = converted.replace(/\bFalse\b/g, 'false');
    converted = converted.replace(/\bNULL\b/g, 'null');
    
    // Fix array format - convert Python style to PostgreSQL
    converted = converted.replace(/'\{([^}]+)\}'/g, (match, content) => {
      const items = content.split(',').map(item => {
        item = item.trim();
        // Remove quotes if they exist
        if (item.startsWith('"') && item.endsWith('"')) {
          item = item.slice(1, -1);
        }
        return `'${item}'`;
      });
      return `ARRAY[${items.join(', ')}]::text[]`;
    });
    
    // Save the converted file
    const outputPath = path.join(__dirname, 'import-nyc-parks.sql');
    await fs.writeFile(outputPath, converted);
    
    console.log('✅ Converted NYC parks SQL saved to:', outputPath);
    console.log('📊 Now run: psql -U austinrathe -d barkpark < scripts/import-nyc-parks.sql');
    
  } catch (error) {
    console.error('❌ Error converting NYC parks:', error);
  }
}

convertNYCParks();