#!/usr/bin/env node

/**
 * Schema Drift Monitor
 * Compares database schemas between environments and alerts on differences
 */

const { Pool } = require('pg');
const nodemailer = require('nodemailer');

// Configuration
const ENVIRONMENTS = {
  local: {
    connectionString: process.env.DATABASE_URL || 'postgresql://localhost/barkpark_dev'
  },
  staging: {
    connectionString: process.env.STAGING_DATABASE_URL
  },
  production: {
    connectionString: process.env.PRODUCTION_DATABASE_URL
  }
};

const ALERT_EMAIL = process.env.SCHEMA_ALERT_EMAIL;
const SMTP_CONFIG = {
  host: process.env.SMTP_HOST,
  port: process.env.SMTP_PORT,
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS
  }
};

async function getSchemaInfo(pool) {
  const schemaQuery = `
    SELECT 
      t.table_name,
      array_agg(
        json_build_object(
          'column_name', c.column_name,
          'data_type', c.data_type,
          'is_nullable', c.is_nullable,
          'column_default', c.column_default
        ) ORDER BY c.ordinal_position
      ) as columns,
      array_agg(DISTINCT
        json_build_object(
          'constraint_name', tc.constraint_name,
          'constraint_type', tc.constraint_type
        )
      ) FILTER (WHERE tc.constraint_name IS NOT NULL) as constraints
    FROM information_schema.tables t
    JOIN information_schema.columns c ON t.table_name = c.table_name
    LEFT JOIN information_schema.table_constraints tc ON t.table_name = tc.table_name
    WHERE t.table_schema = 'public' 
    AND t.table_type = 'BASE TABLE'
    GROUP BY t.table_name
    ORDER BY t.table_name;
  `;

  const migrationQuery = `
    SELECT id, checksum, executed_at 
    FROM schema_migrations 
    ORDER BY id;
  `;

  try {
    const [schemaResult, migrationResult] = await Promise.all([
      pool.query(schemaQuery),
      pool.query(migrationQuery).catch(() => ({ rows: [] })) // Handle missing table
    ]);

    return {
      tables: schemaResult.rows,
      migrations: migrationResult.rows
    };
  } catch (error) {
    throw new Error(`Failed to get schema info: ${error.message}`);
  }
}

function compareSchemas(env1Name, schema1, env2Name, schema2) {
  const differences = [];

  // Compare tables
  const tables1 = new Set(schema1.tables.map(t => t.table_name));
  const tables2 = new Set(schema2.tables.map(t => t.table_name));

  // Tables only in env1
  for (const table of tables1) {
    if (!tables2.has(table)) {
      differences.push({
        type: 'TABLE_MISSING',
        table,
        message: `Table '${table}' exists in ${env1Name} but not in ${env2Name}`
      });
    }
  }

  // Tables only in env2
  for (const table of tables2) {
    if (!tables1.has(table)) {
      differences.push({
        type: 'TABLE_MISSING',
        table,
        message: `Table '${table}' exists in ${env2Name} but not in ${env1Name}`
      });
    }
  }

  // Compare columns for common tables
  for (const table1 of schema1.tables) {
    const table2 = schema2.tables.find(t => t.table_name === table1.table_name);
    if (!table2) continue;

    const columns1 = new Map(table1.columns.map(c => [c.column_name, c]));
    const columns2 = new Map(table2.columns.map(c => [c.column_name, c]));

    // Check for column differences
    for (const [colName, col1] of columns1) {
      const col2 = columns2.get(colName);
      if (!col2) {
        differences.push({
          type: 'COLUMN_MISSING',
          table: table1.table_name,
          column: colName,
          message: `Column '${colName}' in table '${table1.table_name}' exists in ${env1Name} but not in ${env2Name}`
        });
      } else if (col1.data_type !== col2.data_type || col1.is_nullable !== col2.is_nullable) {
        differences.push({
          type: 'COLUMN_MISMATCH',
          table: table1.table_name,
          column: colName,
          message: `Column '${colName}' in table '${table1.table_name}' differs between environments`,
          details: {
            [env1Name]: { type: col1.data_type, nullable: col1.is_nullable },
            [env2Name]: { type: col2.data_type, nullable: col2.is_nullable }
          }
        });
      }
    }

    // Check for columns only in env2
    for (const [colName] of columns2) {
      if (!columns1.has(colName)) {
        differences.push({
          type: 'COLUMN_MISSING',
          table: table1.table_name,
          column: colName,
          message: `Column '${colName}' in table '${table1.table_name}' exists in ${env2Name} but not in ${env1Name}`
        });
      }
    }
  }

  // Compare migrations
  const migrations1 = new Map(schema1.migrations.map(m => [m.id, m.checksum]));
  const migrations2 = new Map(schema2.migrations.map(m => [m.id, m.checksum]));

  for (const [id, checksum1] of migrations1) {
    const checksum2 = migrations2.get(id);
    if (!checksum2) {
      differences.push({
        type: 'MIGRATION_MISSING',
        migration: id,
        message: `Migration '${id}' has been run in ${env1Name} but not in ${env2Name}`
      });
    } else if (checksum1 !== checksum2) {
      differences.push({
        type: 'MIGRATION_MISMATCH',
        migration: id,
        message: `Migration '${id}' has different checksums between environments (file may have been modified)`
      });
    }
  }

  return differences;
}

async function sendAlert(differences) {
  if (!ALERT_EMAIL || !SMTP_CONFIG.host) {
    console.log('Email alerts not configured, skipping...');
    return;
  }

  const transporter = nodemailer.createTransport(SMTP_CONFIG);
  
  const html = `
    <h2>Schema Drift Detected</h2>
    <p>${differences.length} differences found between database schemas.</p>
    <h3>Differences:</h3>
    <ul>
      ${differences.map(d => `
        <li>
          <strong>${d.type}</strong>: ${d.message}
          ${d.details ? `<pre>${JSON.stringify(d.details, null, 2)}</pre>` : ''}
        </li>
      `).join('')}
    </ul>
  `;

  await transporter.sendMail({
    from: SMTP_CONFIG.auth.user,
    to: ALERT_EMAIL,
    subject: `[BarkPark] Schema Drift Alert - ${differences.length} differences found`,
    html
  });
}

async function main() {
  const environments = Object.entries(ENVIRONMENTS)
    .filter(([_, config]) => config.connectionString);

  if (environments.length < 2) {
    console.error('At least 2 environment database URLs must be configured');
    process.exit(1);
  }

  console.log('🔍 Checking for schema drift...\n');

  const schemas = {};
  
  // Get schema for each environment
  for (const [envName, config] of environments) {
    const pool = new Pool({ connectionString: config.connectionString });
    try {
      console.log(`📊 Getting schema for ${envName}...`);
      schemas[envName] = await getSchemaInfo(pool);
    } catch (error) {
      console.error(`❌ Failed to get schema for ${envName}: ${error.message}`);
    } finally {
      await pool.end();
    }
  }

  // Compare all environment pairs
  const allDifferences = [];
  const envNames = Object.keys(schemas);
  
  for (let i = 0; i < envNames.length; i++) {
    for (let j = i + 1; j < envNames.length; j++) {
      const env1 = envNames[i];
      const env2 = envNames[j];
      
      console.log(`\n🔄 Comparing ${env1} vs ${env2}...`);
      const differences = compareSchemas(env1, schemas[env1], env2, schemas[env2]);
      
      if (differences.length === 0) {
        console.log('✅ Schemas are in sync');
      } else {
        console.log(`⚠️  Found ${differences.length} differences:`);
        differences.forEach(d => {
          console.log(`  - ${d.message}`);
          allDifferences.push({ ...d, comparison: `${env1} vs ${env2}` });
        });
      }
    }
  }

  // Send alert if differences found
  if (allDifferences.length > 0) {
    console.log(`\n📧 Sending alert for ${allDifferences.length} total differences...`);
    await sendAlert(allDifferences);
  }

  process.exit(allDifferences.length > 0 ? 1 : 0);
}

// Run as script or export for use in other tools
if (require.main === module) {
  main().catch(console.error);
} else {
  module.exports = { getSchemaInfo, compareSchemas };
}