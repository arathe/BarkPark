/**
 * PostGIS-aware Schema Comparison Utility
 * Handles differences between PostGIS and traditional lat/lng implementations
 */

const { Pool } = require('pg');

class SchemaComparer {
  constructor() {
    this.postgisTypes = ['geography', 'geometry', 'raster'];
    this.typeNormalizations = {
      'USER-DEFINED': 'location', // PostGIS types show as USER-DEFINED
      'geography': 'location',
      'geometry': 'location',
      'double precision': 'numeric',
      'character varying': 'varchar',
      'timestamp without time zone': 'timestamp',
      'timestamp with time zone': 'timestamptz'
    };
  }

  /**
   * Get comprehensive schema information from a database
   */
  async getSchemaInfo(connectionConfig) {
    const pool = new Pool(connectionConfig);
    
    try {
      // Check for PostGIS extension
      const postgisCheck = await pool.query(`
        SELECT EXISTS (
          SELECT 1 FROM pg_extension WHERE extname = 'postgis'
        ) as has_postgis
      `);
      
      const hasPostGIS = postgisCheck.rows[0].has_postgis;
      
      // Get detailed column information including UDT (user-defined type) names
      const schemaQuery = `
        SELECT 
          t.table_name,
          c.column_name,
          c.data_type,
          c.udt_name,
          c.character_maximum_length,
          c.numeric_precision,
          c.numeric_scale,
          c.is_nullable,
          c.column_default,
          c.ordinal_position
        FROM information_schema.tables t
        JOIN information_schema.columns c 
          ON t.table_name = c.table_name AND t.table_schema = c.table_schema
        WHERE t.table_schema = 'public'
          AND t.table_type = 'BASE TABLE'
          AND t.table_name NOT IN ('schema_migrations', 'spatial_ref_sys')
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
          AND tc.table_name NOT IN ('schema_migrations', 'spatial_ref_sys')
        ORDER BY tc.table_name, tc.constraint_name
      `;
      
      const indexQuery = `
        SELECT 
          schemaname,
          tablename,
          indexname,
          indexdef,
          CASE 
            WHEN indexdef LIKE '%USING gist%' THEN 'spatial'
            WHEN indexdef LIKE '%USING gin%' THEN 'gin'
            WHEN indexdef LIKE '%USING btree%' THEN 'btree'
            ELSE 'other'
          END as index_type
        FROM pg_indexes
        WHERE schemaname = 'public'
          AND tablename NOT IN ('schema_migrations', 'spatial_ref_sys')
        ORDER BY tablename, indexname
      `;
      
      const [schemaResult, constraintResult, indexResult] = await Promise.all([
        pool.query(schemaQuery),
        pool.query(constraintQuery),
        pool.query(indexQuery)
      ]);
      
      // Process and normalize the schema
      const schema = this.processSchemaResults(
        schemaResult.rows,
        constraintResult.rows,
        indexResult.rows,
        hasPostGIS
      );
      
      return {
        hasPostGIS,
        schema,
        tableCount: Object.keys(schema).length,
        tables: Object.keys(schema)
      };
      
    } finally {
      await pool.end();
    }
  }
  
  /**
   * Process raw schema results and normalize types
   */
  processSchemaResults(columns, constraints, indexes, hasPostGIS) {
    const schema = {};
    
    // Group columns by table
    columns.forEach(col => {
      if (!schema[col.table_name]) {
        schema[col.table_name] = {
          columns: [],
          constraints: [],
          indexes: [],
          hasLocationColumn: false,
          hasLatLngColumns: false
        };
      }
      
      // Normalize the data type
      let normalizedType = col.data_type;
      if (col.udt_name && this.postgisTypes.includes(col.udt_name)) {
        normalizedType = 'location';
        schema[col.table_name].hasLocationColumn = true;
      } else if (this.typeNormalizations[col.data_type]) {
        normalizedType = this.typeNormalizations[col.data_type];
      }
      
      // Check for lat/lng columns
      if (col.column_name === 'latitude' || col.column_name === 'longitude') {
        schema[col.table_name].hasLatLngColumns = true;
      }
      
      schema[col.table_name].columns.push({
        name: col.column_name,
        type: normalizedType,
        rawType: col.data_type,
        udtName: col.udt_name,
        maxLength: col.character_maximum_length,
        precision: col.numeric_precision,
        scale: col.numeric_scale,
        nullable: col.is_nullable === 'YES',
        default: col.column_default,
        position: col.ordinal_position
      });
    });
    
    // Add constraints
    constraints.forEach(con => {
      if (schema[con.table_name]) {
        schema[con.table_name].constraints.push({
          name: con.constraint_name,
          type: con.constraint_type,
          column: con.column_name,
          references: con.unique_constraint_name,
          deleteRule: con.delete_rule,
          updateRule: con.update_rule
        });
      }
    });
    
    // Add indexes with type information
    indexes.forEach(idx => {
      if (schema[idx.tablename]) {
        schema[idx.tablename].indexes.push({
          name: idx.indexname,
          definition: idx.indexdef,
          type: idx.index_type
        });
      }
    });
    
    return schema;
  }
  
  /**
   * Compare two schemas and identify differences
   */
  compareSchemas(schema1, schema2, env1Name = 'env1', env2Name = 'env2') {
    const differences = [];
    const suggestions = [];
    
    // Check PostGIS availability
    if (schema1.hasPostGIS !== schema2.hasPostGIS) {
      differences.push({
        type: 'EXTENSION_MISMATCH',
        severity: 'warning',
        message: `PostGIS extension is ${schema1.hasPostGIS ? 'enabled' : 'disabled'} in ${env1Name} but ${schema2.hasPostGIS ? 'enabled' : 'disabled'} in ${env2Name}`,
        suggestion: schema2.hasPostGIS ? 
          `Run 'CREATE EXTENSION IF NOT EXISTS postgis;' in ${env1Name}` :
          `${env2Name} is missing PostGIS extension which may be required`
      });
    }
    
    // Compare tables
    const tables1 = new Set(schema1.tables);
    const tables2 = new Set(schema2.tables);
    
    // Tables missing in env2
    for (const table of tables1) {
      if (!tables2.has(table)) {
        differences.push({
          type: 'TABLE_MISSING',
          severity: 'error',
          table,
          message: `Table '${table}' exists in ${env1Name} but not in ${env2Name}`,
          suggestion: `Create table '${table}' in ${env2Name} using the appropriate migration`
        });
      }
    }
    
    // Tables missing in env1
    for (const table of tables2) {
      if (!tables1.has(table)) {
        differences.push({
          type: 'TABLE_MISSING',
          severity: 'error',
          table,
          message: `Table '${table}' exists in ${env2Name} but not in ${env1Name}`,
          suggestion: `Create table '${table}' in ${env1Name} using the appropriate migration`
        });
      }
    }
    
    // Compare columns in common tables
    for (const table of tables1) {
      if (!tables2.has(table)) continue;
      
      const table1Data = schema1.schema[table];
      const table2Data = schema2.schema[table];
      
      // Check for location column differences
      if (table === 'dog_parks') {
        const locationDiff = this.checkLocationColumnDifferences(
          table1Data, table2Data, env1Name, env2Name
        );
        if (locationDiff) {
          differences.push(locationDiff);
        }
      }
      
      // Compare individual columns
      const columns1 = new Map(table1Data.columns.map(c => [c.name, c]));
      const columns2 = new Map(table2Data.columns.map(c => [c.name, c]));
      
      // Columns missing in env2
      for (const [colName, col1] of columns1) {
        if (!columns2.has(colName)) {
          // Special handling for location-related columns
          if ((colName === 'latitude' || colName === 'longitude') && table2Data.hasLocationColumn) {
            differences.push({
              type: 'LOCATION_IMPLEMENTATION',
              severity: 'info',
              table,
              column: colName,
              message: `${env1Name} uses separate '${colName}' column while ${env2Name} uses PostGIS location column`,
              suggestion: `This is expected when migrating from lat/lng to PostGIS`
            });
          } else if (colName === 'location' && table2Data.hasLatLngColumns) {
            differences.push({
              type: 'LOCATION_IMPLEMENTATION',
              severity: 'info',
              table,
              column: colName,
              message: `${env1Name} uses PostGIS location column while ${env2Name} uses separate lat/lng columns`,
              suggestion: `Consider migrating ${env2Name} to PostGIS for better spatial query performance`
            });
          } else {
            differences.push({
              type: 'COLUMN_MISSING',
              severity: 'error',
              table,
              column: colName,
              message: `Column '${colName}' in table '${table}' exists in ${env1Name} but not in ${env2Name}`,
              suggestion: `Add column '${colName}' to table '${table}' in ${env2Name}`
            });
          }
        } else {
          // Column exists in both - check type compatibility
          const col2 = columns2.get(colName);
          if (col1.type !== col2.type && !this.areTypesCompatible(col1, col2)) {
            differences.push({
              type: 'COLUMN_TYPE_MISMATCH',
              severity: 'warning',
              table,
              column: colName,
              message: `Column '${colName}' in table '${table}' has different types`,
              details: {
                [env1Name]: { type: col1.type, rawType: col1.rawType },
                [env2Name]: { type: col2.type, rawType: col2.rawType }
              },
              suggestion: `Ensure data type compatibility or create a migration to align types`
            });
          }
        }
      }
      
      // Columns missing in env1
      for (const [colName, col2] of columns2) {
        if (!columns1.has(colName) && 
            !((colName === 'latitude' || colName === 'longitude') && table1Data.hasLocationColumn) &&
            !(colName === 'location' && table1Data.hasLatLngColumns)) {
          differences.push({
            type: 'COLUMN_MISSING',
            severity: 'error',
            table,
            column: colName,
            message: `Column '${colName}' in table '${table}' exists in ${env2Name} but not in ${env1Name}`,
            suggestion: `Add column '${colName}' to table '${table}' in ${env1Name}`
          });
        }
      }
    }
    
    return {
      differences,
      suggestions: this.generateSyncSuggestions(differences),
      summary: {
        total: differences.length,
        errors: differences.filter(d => d.severity === 'error').length,
        warnings: differences.filter(d => d.severity === 'warning').length,
        info: differences.filter(d => d.severity === 'info').length
      }
    };
  }
  
  /**
   * Check for location column implementation differences
   */
  checkLocationColumnDifferences(table1Data, table2Data, env1Name, env2Name) {
    if (table1Data.hasLocationColumn && table2Data.hasLatLngColumns && !table2Data.hasLocationColumn) {
      return {
        type: 'LOCATION_STRATEGY_MISMATCH',
        severity: 'warning',
        table: 'dog_parks',
        message: `${env1Name} uses PostGIS location column while ${env2Name} uses separate lat/lng columns`,
        suggestion: `Consider migrating ${env2Name} to PostGIS using: ALTER TABLE dog_parks ADD COLUMN location GEOGRAPHY(POINT, 4326); UPDATE dog_parks SET location = ST_MakePoint(longitude, latitude)::geography;`,
        migrationSQL: this.generateLocationMigrationSQL('to_postgis')
      };
    } else if (table1Data.hasLatLngColumns && !table1Data.hasLocationColumn && table2Data.hasLocationColumn) {
      return {
        type: 'LOCATION_STRATEGY_MISMATCH',
        severity: 'warning',
        table: 'dog_parks',
        message: `${env1Name} uses separate lat/lng columns while ${env2Name} uses PostGIS location column`,
        suggestion: `${env1Name} should be migrated to PostGIS for consistency`,
        migrationSQL: this.generateLocationMigrationSQL('to_postgis')
      };
    }
    return null;
  }
  
  /**
   * Check if two column types are compatible
   */
  areTypesCompatible(col1, col2) {
    // Location types are compatible with each other
    if (col1.type === 'location' && col2.type === 'location') return true;
    
    // Numeric types compatibility
    const numericTypes = ['numeric', 'integer', 'bigint', 'smallint', 'real', 'double precision'];
    if (numericTypes.includes(col1.rawType) && numericTypes.includes(col2.rawType)) return true;
    
    // Text types compatibility
    const textTypes = ['text', 'varchar', 'character varying', 'char', 'character'];
    if (textTypes.includes(col1.rawType) && textTypes.includes(col2.rawType)) return true;
    
    return false;
  }
  
  /**
   * Generate SQL for location column migration
   */
  generateLocationMigrationSQL(direction) {
    if (direction === 'to_postgis') {
      return `
-- Migrate from lat/lng columns to PostGIS
ALTER TABLE dog_parks ADD COLUMN location GEOGRAPHY(POINT, 4326);
UPDATE dog_parks SET location = ST_MakePoint(longitude, latitude)::geography WHERE latitude IS NOT NULL AND longitude IS NOT NULL;
CREATE INDEX idx_dog_parks_location ON dog_parks USING GIST(location);
-- After verification, drop old columns: ALTER TABLE dog_parks DROP COLUMN latitude, DROP COLUMN longitude;
      `.trim();
    } else {
      return `
-- Migrate from PostGIS to lat/lng columns
ALTER TABLE dog_parks ADD COLUMN latitude DOUBLE PRECISION;
ALTER TABLE dog_parks ADD COLUMN longitude DOUBLE PRECISION;
UPDATE dog_parks SET latitude = ST_Y(location::geometry), longitude = ST_X(location::geometry) WHERE location IS NOT NULL;
CREATE INDEX idx_dog_parks_lat ON dog_parks(latitude);
CREATE INDEX idx_dog_parks_lng ON dog_parks(longitude);
-- After verification, drop location column: ALTER TABLE dog_parks DROP COLUMN location;
      `.trim();
    }
  }
  
  /**
   * Generate synchronization suggestions based on differences
   */
  generateSyncSuggestions(differences) {
    const suggestions = [];
    
    // Group differences by type
    const locationDiffs = differences.filter(d => 
      d.type === 'LOCATION_STRATEGY_MISMATCH' || d.type === 'LOCATION_IMPLEMENTATION'
    );
    
    if (locationDiffs.length > 0) {
      suggestions.push({
        priority: 'high',
        category: 'location_strategy',
        title: 'Location Data Strategy Alignment',
        description: 'Your environments use different strategies for storing location data',
        steps: [
          'Decide on a consistent strategy (PostGIS recommended for spatial queries)',
          'Create a migration to align all environments',
          'Update application code to handle the transition',
          'Test thoroughly with production-like data'
        ]
      });
    }
    
    const missingTables = differences.filter(d => d.type === 'TABLE_MISSING');
    if (missingTables.length > 0) {
      suggestions.push({
        priority: 'critical',
        category: 'missing_tables',
        title: 'Missing Tables',
        description: `${missingTables.length} tables are missing in one or more environments`,
        steps: [
          'Review which migrations have not been run',
          'Run pending migrations in the affected environments',
          'Verify table creation with schema comparison'
        ]
      });
    }
    
    return suggestions;
  }
}

module.exports = SchemaComparer;