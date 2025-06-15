const express = require('express');
const pool = require('../config/database');
const router = express.Router();

// Compare schemas between environments
router.get('/compare', async (req, res) => {
  try {
    // Get comprehensive schema information
    const schemaQuery = `
      SELECT 
        t.table_name,
        c.column_name,
        c.data_type,
        c.character_maximum_length,
        c.numeric_precision,
        c.numeric_scale,
        c.is_nullable,
        c.column_default,
        c.ordinal_position
      FROM information_schema.tables t
      JOIN information_schema.columns c 
        ON t.table_name = c.table_name
      WHERE t.table_schema = 'public'
        AND t.table_type = 'BASE TABLE'
        AND t.table_name NOT IN ('schema_migrations')
      ORDER BY t.table_name, c.ordinal_position
    `;

    const constraintQuery = `
      SELECT 
        tc.table_name,
        tc.constraint_name,
        tc.constraint_type,
        cc.column_name,
        rc.unique_constraint_name,
        rc.delete_rule,
        rc.update_rule
      FROM information_schema.table_constraints tc
      LEFT JOIN information_schema.constraint_column_usage cc
        ON tc.constraint_name = cc.constraint_name
      LEFT JOIN information_schema.referential_constraints rc
        ON tc.constraint_name = rc.constraint_name
      WHERE tc.table_schema = 'public'
        AND tc.table_name NOT IN ('schema_migrations')
      ORDER BY tc.table_name, tc.constraint_name
    `;

    const indexQuery = `
      SELECT 
        schemaname,
        tablename,
        indexname,
        indexdef
      FROM pg_indexes
      WHERE schemaname = 'public'
        AND tablename NOT IN ('schema_migrations')
      ORDER BY tablename, indexname
    `;

    // Execute all queries in parallel
    const [schemaResult, constraintResult, indexResult] = await Promise.all([
      pool.query(schemaQuery),
      pool.query(constraintQuery),
      pool.query(indexQuery)
    ]);

    // Group schema by table
    const schema = {};
    schemaResult.rows.forEach(row => {
      if (!schema[row.table_name]) {
        schema[row.table_name] = {
          columns: [],
          constraints: [],
          indexes: []
        };
      }
      schema[row.table_name].columns.push({
        name: row.column_name,
        type: row.data_type,
        maxLength: row.character_maximum_length,
        nullable: row.is_nullable === 'YES',
        default: row.column_default,
        position: row.ordinal_position
      });
    });

    // Add constraints
    constraintResult.rows.forEach(row => {
      if (schema[row.table_name]) {
        schema[row.table_name].constraints.push({
          name: row.constraint_name,
          type: row.constraint_type,
          column: row.column_name,
          references: row.unique_constraint_name,
          deleteRule: row.delete_rule,
          updateRule: row.update_rule
        });
      }
    });

    // Add indexes
    indexResult.rows.forEach(row => {
      if (schema[row.tablename]) {
        schema[row.tablename].indexes.push({
          name: row.indexname,
          definition: row.indexdef
        });
      }
    });

    // Check migration status
    const migrationResult = await pool.query(
      'SELECT id, description, executed_at FROM schema_migrations ORDER BY executed_at'
    );

    res.json({
      environment: process.env.NODE_ENV || 'development',
      database: process.env.DATABASE_URL ? 'Railway PostgreSQL' : 'Local PostgreSQL',
      timestamp: new Date().toISOString(),
      migrations: migrationResult.rows,
      schema,
      summary: {
        tableCount: Object.keys(schema).length,
        tables: Object.keys(schema)
      }
    });

  } catch (error) {
    console.error('Schema validation error:', error);
    res.status(500).json({
      error: 'Failed to retrieve schema',
      message: error.message
    });
  }
});

// Validate required columns exist
router.get('/validate', async (req, res) => {
  try {
    const requiredSchema = {
      users: ['id', 'email', 'password_hash', 'first_name', 'last_name', 'is_searchable'],
      dogs: ['id', 'user_id', 'name', 'birthday', 'gender', 'size_category', 'bio'],
      dog_parks: ['id', 'name', 'address', 'latitude', 'longitude', 'website', 'borough'],
      friendships: ['id', 'requester_id', 'addressee_id', 'status'],
      checkins: ['id', 'user_id', 'dog_park_id', 'checked_in_at']
    };

    const issues = [];
    const validations = {};

    for (const [table, requiredColumns] of Object.entries(requiredSchema)) {
      const result = await pool.query(`
        SELECT column_name 
        FROM information_schema.columns
        WHERE table_name = $1
      `, [table]);

      const existingColumns = result.rows.map(r => r.column_name);
      const missingColumns = requiredColumns.filter(col => !existingColumns.includes(col));

      validations[table] = {
        required: requiredColumns.length,
        found: existingColumns.length,
        missing: missingColumns,
        status: missingColumns.length === 0 ? 'PASS' : 'FAIL'
      };

      if (missingColumns.length > 0) {
        issues.push(`Table '${table}' is missing columns: ${missingColumns.join(', ')}`);
      }
    }

    const overallStatus = issues.length === 0 ? 'PASS' : 'FAIL';

    res.json({
      status: overallStatus,
      timestamp: new Date().toISOString(),
      validations,
      issues,
      recommendation: overallStatus === 'FAIL' 
        ? 'Run migrations to fix schema issues: npm run db:migrate --seed'
        : 'Schema validation passed - all required columns present'
    });

  } catch (error) {
    console.error('Schema validation error:', error);
    res.status(500).json({
      error: 'Validation failed',
      message: error.message
    });
  }
});

module.exports = router;