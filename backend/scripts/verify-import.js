#!/usr/bin/env node
/**
 * Verify NYC dog runs import data integrity
 */

const pool = require('../config/database');

async function verifyImport() {
    try {
        console.log('🔍 Verifying NYC Dog Runs Import...\n');
        
        // Check total count
        const totalResult = await pool.query('SELECT COUNT(*) as total FROM dog_parks');
        console.log(`📊 Total parks: ${totalResult.rows[0].total}`);
        
        // Check NYC vs existing parks
        const nycResult = await pool.query('SELECT COUNT(*) as nyc_count FROM dog_parks WHERE borough IS NOT NULL');
        const existingResult = await pool.query('SELECT COUNT(*) as existing_count FROM dog_parks WHERE borough IS NULL');
        console.log(`🗽 NYC parks: ${nycResult.rows[0].nyc_count}`);
        console.log(`🏞️  Existing parks: ${existingResult.rows[0].existing_count}\n`);
        
        // Check data completeness
        const completeness = await pool.query(`
            SELECT 
                COUNT(*) as total,
                COUNT(website) as has_website,
                COUNT(phone) as has_phone,
                COUNT(rating) as has_rating,
                COUNT(surface_type) as has_surface,
                COUNT(zipcode) as has_zipcode,
                AVG(rating) as avg_rating
            FROM dog_parks 
            WHERE borough IS NOT NULL
        `);
        
        const stats = completeness.rows[0];
        console.log('📈 Data Completeness for NYC Parks:');
        console.log(`   Websites: ${stats.has_website}/${stats.total} (${Math.round(stats.has_website/stats.total*100)}%)`);
        console.log(`   Phone numbers: ${stats.has_phone}/${stats.total} (${Math.round(stats.has_phone/stats.total*100)}%)`);
        console.log(`   Ratings: ${stats.has_rating}/${stats.total} (${Math.round(stats.has_rating/stats.total*100)}%)`);
        console.log(`   Surface types: ${stats.has_surface}/${stats.total} (${Math.round(stats.has_surface/stats.total*100)}%)`);
        console.log(`   Zip codes: ${stats.has_zipcode}/${stats.total} (${Math.round(stats.has_zipcode/stats.total*100)}%)`);
        console.log(`   Average rating: ${parseFloat(stats.avg_rating).toFixed(1)}/5.0\n`);
        
        // Check borough distribution
        const boroughs = await pool.query(`
            SELECT borough, COUNT(*) as count 
            FROM dog_parks 
            WHERE borough IS NOT NULL 
            GROUP BY borough 
            ORDER BY count DESC
        `);
        
        console.log('🗺️  Borough Distribution:');
        boroughs.rows.forEach(row => {
            console.log(`   ${row.borough}: ${row.count} parks`);
        });
        console.log('');
        
        // Check surface type distribution
        const surfaces = await pool.query(`
            SELECT surface_type, COUNT(*) as count 
            FROM dog_parks 
            WHERE surface_type IS NOT NULL 
            GROUP BY surface_type 
            ORDER BY count DESC
        `);
        
        console.log('🏞️  Surface Type Distribution:');
        surfaces.rows.forEach(row => {
            console.log(`   ${row.surface_type}: ${row.count} parks`);
        });
        console.log('');
        
        // Check location data integrity
        const locationCheck = await pool.query(`
            SELECT 
                COUNT(*) as total,
                COUNT(*) FILTER (WHERE latitude IS NOT NULL AND longitude IS NOT NULL) as has_coords,
                MIN(latitude) as min_lat, MAX(latitude) as max_lat,
                MIN(longitude) as min_lon, MAX(longitude) as max_lon
            FROM dog_parks 
            WHERE borough IS NOT NULL
        `);
        
        const loc = locationCheck.rows[0];
        console.log('📍 Location Data:');
        console.log(`   Parks with coordinates: ${loc.has_coords}/${loc.total} (${Math.round(loc.has_coords/loc.total*100)}%)`);
        console.log(`   Latitude range: ${parseFloat(loc.min_lat).toFixed(4)} to ${parseFloat(loc.max_lat).toFixed(4)}`);
        console.log(`   Longitude range: ${parseFloat(loc.min_lon).toFixed(4)} to ${parseFloat(loc.max_lon).toFixed(4)}\n`);
        
        // Sample some parks for manual verification
        const samples = await pool.query(`
            SELECT name, borough, address, rating, surface_type, website, phone
            FROM dog_parks 
            WHERE borough IS NOT NULL 
            ORDER BY rating DESC NULLS LAST, name
            LIMIT 3
        `);
        
        console.log('🔍 Sample NYC Parks:');
        samples.rows.forEach((park, i) => {
            console.log(`${i + 1}. ${park.name}`);
            console.log(`   Borough: ${park.borough}`);
            console.log(`   Address: ${park.address}`);
            console.log(`   Rating: ${park.rating || 'N/A'}/5.0`);
            console.log(`   Surface: ${park.surface_type || 'N/A'}`);
            console.log(`   Website: ${park.website ? 'Yes' : 'No'}`);
            console.log(`   Phone: ${park.phone ? 'Yes' : 'No'}`);
            console.log('');
        });
        
        console.log('✅ Import verification completed successfully!');
        
    } catch (error) {
        console.error('❌ Verification failed:', error.message);
        process.exit(1);
    } finally {
        await pool.end();
    }
}

verifyImport();