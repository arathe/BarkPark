const express = require('express');
const pool = require('../config/database');
const router = express.Router();

// Diagnostic endpoint to check database schema
router.get('/schema/dogs', async (req, res) => {
  try {
    // Get current database connection info
    const dbInfoQuery = `SELECT current_database(), current_schema(), version()`;
    const dbInfo = await pool.query(dbInfoQuery);
    
    // Get dogs table columns
    const schemaQuery = `
      SELECT 
        column_name, 
        data_type, 
        is_nullable
      FROM information_schema.columns
      WHERE table_name = 'dogs'
      ORDER BY ordinal_position;
    `;
    
    const columns = await pool.query(schemaQuery);
    
    // Try a test insert to see what happens
    let testInsertError = null;
    try {
      const testQuery = `
        INSERT INTO dogs (
          user_id, name, breed, birthday, weight, gender, size_category,
          energy_level, friendliness_dogs, friendliness_people, training_level,
          favorite_activities, is_vaccinated, is_spayed_neutered, special_needs,
          bio, profile_image_url
        )
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17)
        RETURNING *
      `;
      
      const testValues = [
        1, 'DiagnosticTest', 'Test', '2020-01-01', 20, 'male', 'medium',
        'medium', 3, 3, 'basic', '[]', true, false, null, null, null
      ];
      
      const testResult = await pool.query(testQuery, testValues);
      // Clean up test data
      await pool.query('DELETE FROM dogs WHERE name = $1', ['DiagnosticTest']);
    } catch (error) {
      testInsertError = {
        message: error.message,
        code: error.code,
        position: error.position,
        detail: error.detail
      };
    }
    
    res.json({
      database: {
        name: dbInfo.rows[0].current_database,
        schema: dbInfo.rows[0].current_schema,
        version: dbInfo.rows[0].version
      },
      dogsTable: {
        exists: columns.rows.length > 0,
        columnCount: columns.rows.length,
        columns: columns.rows.map(col => ({
          name: col.column_name,
          type: col.data_type,
          nullable: col.is_nullable === 'YES'
        })),
        hasBirthdayColumn: columns.rows.some(col => col.column_name === 'birthday')
      },
      testInsert: {
        success: !testInsertError,
        error: testInsertError
      }
    });
    
  } catch (error) {
    res.status(500).json({
      error: 'Diagnostic check failed',
      message: error.message,
      code: error.code
    });
  }
});

module.exports = router;