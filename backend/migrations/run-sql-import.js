#!/usr/bin/env node
/**
 * Run SQL import scripts for NYC dog runs
 */

const fs = require('fs');
const path = require('path');
const pool = require('../config/database');

async function runSQLFile(filename) {
    const filePath = path.join(__dirname, filename);
    
    if (!fs.existsSync(filePath)) {
        throw new Error(`SQL file not found: ${filePath}`);
    }
    
    const sql = fs.readFileSync(filePath, 'utf8');
    console.log(`Running SQL file: ${filename}`);
    
    // Split by semicolon and execute each statement
    const statements = sql.split(';').filter(stmt => stmt.trim().length > 0);
    
    for (let i = 0; i < statements.length; i++) {
        const statement = statements[i].trim();
        if (statement) {
            try {
                await pool.query(statement);
                console.log(`✅ Statement ${i + 1}/${statements.length} executed`);
            } catch (error) {
                console.error(`❌ Error in statement ${i + 1}:`, error.message);
                console.error('Statement:', statement.substring(0, 100) + '...');
            }
        }
    }
}

async function main() {
    try {
        console.log('🔄 Starting NYC Dog Runs Import...');
        
        // First extend the schema
        await runSQLFile('extend-parks-schema.sql');
        console.log('✅ Schema extended successfully');
        
        // Then import the data
        await runSQLFile('012_import_nyc_dog_runs.sql');
        console.log('✅ NYC dog runs imported successfully');
        
        // Verify the import
        const result = await pool.query('SELECT COUNT(*) as total FROM dog_parks');
        console.log(`📊 Total parks in database: ${result.rows[0].total}`);
        
        // Show sample NYC parks
        const nycParks = await pool.query(`
            SELECT name, borough, rating, surface_type, zipcode 
            FROM dog_parks 
            WHERE borough IS NOT NULL 
            ORDER BY rating DESC NULLS LAST 
            LIMIT 5
        `);
        
        console.log('\n🏆 Top NYC Dog Parks:');
        nycParks.rows.forEach((park, i) => {
            console.log(`${i + 1}. ${park.name} (${park.borough}) - Rating: ${park.rating || 'N/A'}`);
        });
        
    } catch (error) {
        console.error('❌ Import failed:', error.message);
        process.exit(1);
    } finally {
        await pool.end();
    }
}

main();