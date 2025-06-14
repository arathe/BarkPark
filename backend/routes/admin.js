const express = require('express');
const fs = require('fs');
const path = require('path');
const pool = require('../config/database');
const router = express.Router();

// Simple admin authentication
const ADMIN_KEY = process.env.ADMIN_KEY || 'default-admin-key-change-me';

// Middleware to check admin key
const requireAdminKey = (req, res, next) => {
  const providedKey = req.headers['x-admin-key'] || req.query.adminKey;
  
  if (providedKey !== ADMIN_KEY) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  
  next();
};

// Run dogs table migration
router.post('/migrate/dogs', requireAdminKey, async (req, res) => {
  try {
    console.log('[Admin] Running dogs table migration...');
    
    // Read the migration file
    const migrationPath = path.join(__dirname, '../migrations/fix-dogs-columns.sql');
    const migrationSQL = fs.readFileSync(migrationPath, 'utf8');
    
    // Start transaction
    await pool.query('BEGIN');
    
    try {
      // Run migration
      await pool.query(migrationSQL);
      
      // Verify the schema
      const schemaResult = await pool.query(`
        SELECT column_name, data_type 
        FROM information_schema.columns
        WHERE table_name = 'dogs'
        ORDER BY ordinal_position
      `);
      
      await pool.query('COMMIT');
      
      res.json({
        success: true,
        message: 'Dogs table migration completed successfully',
        columns: schemaResult.rows.length,
        schema: schemaResult.rows
      });
      
    } catch (err) {
      await pool.query('ROLLBACK');
      throw err;
    }
    
  } catch (error) {
    console.error('[Admin] Migration error:', error);
    res.status(500).json({
      error: 'Migration failed',
      message: error.message,
      code: error.code
    });
  }
});

// Check migration status
router.get('/migrate/status', requireAdminKey, async (req, res) => {
  try {
    // Check dogs table schema
    const schemaResult = await pool.query(`
      SELECT column_name 
      FROM information_schema.columns
      WHERE table_name = 'dogs'
      ORDER BY ordinal_position
    `);
    
    const columns = schemaResult.rows.map(r => r.column_name);
    const requiredColumns = ['birthday', 'gender', 'size_category', 'energy_level', 'bio'];
    const hasAllColumns = requiredColumns.every(col => columns.includes(col));
    
    res.json({
      tableName: 'dogs',
      totalColumns: columns.length,
      hasRequiredColumns: hasAllColumns,
      missingColumns: requiredColumns.filter(col => !columns.includes(col)),
      currentColumns: columns
    });
    
  } catch (error) {
    res.status(500).json({
      error: 'Status check failed',
      message: error.message
    });
  }
});

module.exports = router;