#!/usr/bin/env node

/**
 * Schema Synchronization Tool
 * Compares schemas between environments and generates migration SQL
 */

const SchemaComparer = require('../utils/schema-compare');
const fs = require('fs').promises;
const path = require('path');
const readline = require('readline');
require('dotenv').config({ path: path.join(__dirname, '../.env') });
require('dotenv').config({ path: path.join(__dirname, '../.env.local') });

// Color codes for terminal output
const colors = {
  reset: '\x1b[0m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
  cyan: '\x1b[36m'
};

// Parse command line arguments
const args = process.argv.slice(2);
const flags = {
  source: args.find(a => a.startsWith('--source='))?.split('=')[1] || 'local',
  target: args.find(a => a.startsWith('--target='))?.split('=')[1] || 'production',
  output: args.find(a => a.startsWith('--output='))?.split('=')[1],
  verbose: args.includes('--verbose'),
  help: args.includes('--help')
};

// Database configurations
const dbConfigs = {
  local: {
    name: 'Local Development',
    connectionString: process.env.DATABASE_URL || 
      `postgresql://${process.env.DB_USER || 'postgres'}:${process.env.DB_PASSWORD || ''}@${process.env.DB_HOST || 'localhost'}:${process.env.DB_PORT || 5432}/${process.env.DB_NAME || 'barkpark_dev'}`
  },
  production: {
    name: 'Production (Railway)',
    connectionString: process.env.PRODUCTION_DATABASE_URL
  },
  staging: {
    name: 'Staging',
    connectionString: process.env.STAGING_DATABASE_URL
  }
};

function showHelp() {
  console.log(`
${colors.cyan}BarkPark Schema Synchronization Tool${colors.reset}

${colors.yellow}Usage:${colors.reset}
  npm run db:schema:sync [options]

${colors.yellow}Options:${colors.reset}
  --source=<env>     Source environment (default: local)
  --target=<env>     Target environment (default: production)
  --output=<file>    Output SQL to file instead of console
  --verbose          Show detailed comparison information
  --help             Show this help message

${colors.yellow}Environments:${colors.reset}
  local              Local development database
  production         Production database (requires PRODUCTION_DATABASE_URL)
  staging            Staging database (requires STAGING_DATABASE_URL)

${colors.yellow}Examples:${colors.reset}
  # Compare local to production
  npm run db:schema:sync

  # Compare production to local (reverse check)
  npm run db:schema:sync --source=production --target=local

  # Generate migration SQL file
  npm run db:schema:sync --output=sync-to-production.sql

  # Verbose comparison with all details
  npm run db:schema:sync --verbose

${colors.yellow}Environment Variables:${colors.reset}
  DATABASE_URL               Local database connection
  PRODUCTION_DATABASE_URL    Production database connection
  STAGING_DATABASE_URL       Staging database connection
`);
}

function formatDifference(diff) {
  const severityColors = {
    error: colors.red,
    warning: colors.yellow,
    info: colors.blue
  };
  
  const color = severityColors[diff.severity] || colors.reset;
  const icon = diff.severity === 'error' ? '❌' : 
               diff.severity === 'warning' ? '⚠️ ' : 'ℹ️ ';
  
  console.log(`\n${icon} ${color}${diff.type}${colors.reset}`);
  console.log(`   ${diff.message}`);
  
  if (diff.details && flags.verbose) {
    console.log(`   ${colors.cyan}Details:${colors.reset}`);
    Object.entries(diff.details).forEach(([env, info]) => {
      console.log(`     ${env}: ${JSON.stringify(info)}`);
    });
  }
  
  if (diff.suggestion) {
    console.log(`   ${colors.green}Suggestion:${colors.reset} ${diff.suggestion}`);
  }
  
  if (diff.migrationSQL && flags.verbose) {
    console.log(`   ${colors.magenta}Migration SQL:${colors.reset}`);
    diff.migrationSQL.split('\n').forEach(line => {
      console.log(`     ${line}`);
    });
  }
}

function generateMigrationSQL(differences) {
  const sqlStatements = [];
  const processedTables = new Set();
  
  // Header
  sqlStatements.push(`-- Schema Synchronization SQL`);
  sqlStatements.push(`-- Generated: ${new Date().toISOString()}`);
  sqlStatements.push(`-- Source: ${flags.source}`);
  sqlStatements.push(`-- Target: ${flags.target}`);
  sqlStatements.push(``);
  
  // Group differences by table
  const byTable = {};
  differences.forEach(diff => {
    if (diff.table) {
      if (!byTable[diff.table]) byTable[diff.table] = [];
      byTable[diff.table].push(diff);
    }
  });
  
  // Process each table
  Object.entries(byTable).forEach(([table, diffs]) => {
    sqlStatements.push(`-- Table: ${table}`);
    
    diffs.forEach(diff => {
      if (diff.type === 'COLUMN_MISSING' && diff.severity === 'error') {
        // Generate ALTER TABLE ADD COLUMN
        const col = diff.column;
        sqlStatements.push(`-- Missing column: ${col}`);
        sqlStatements.push(`-- ALTER TABLE ${table} ADD COLUMN ${col} <TYPE>;`);
        sqlStatements.push(``);
      } else if (diff.type === 'LOCATION_STRATEGY_MISMATCH' && diff.migrationSQL) {
        if (!processedTables.has(`${table}_location`)) {
          sqlStatements.push(`-- Location strategy migration`);
          sqlStatements.push(diff.migrationSQL);
          sqlStatements.push(``);
          processedTables.add(`${table}_location`);
        }
      }
    });
  });
  
  // PostGIS extension if needed
  const extensionDiff = differences.find(d => d.type === 'EXTENSION_MISMATCH');
  if (extensionDiff && extensionDiff.suggestion.includes('CREATE EXTENSION')) {
    sqlStatements.unshift('-- Enable PostGIS extension');
    sqlStatements.unshift('CREATE EXTENSION IF NOT EXISTS postgis;');
    sqlStatements.unshift('');
  }
  
  return sqlStatements.join('\n');
}

async function askQuestion(question) {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });
  
  return new Promise((resolve) => {
    rl.question(question, (answer) => {
      rl.close();
      resolve(answer);
    });
  });
}

async function main() {
  if (flags.help) {
    showHelp();
    process.exit(0);
  }
  
  // Validate environments
  const sourceConfig = dbConfigs[flags.source];
  const targetConfig = dbConfigs[flags.target];
  
  if (!sourceConfig) {
    console.error(`${colors.red}Error: Unknown source environment '${flags.source}'${colors.reset}`);
    process.exit(1);
  }
  
  if (!targetConfig) {
    console.error(`${colors.red}Error: Unknown target environment '${flags.target}'${colors.reset}`);
    process.exit(1);
  }
  
  if (!sourceConfig.connectionString) {
    console.error(`${colors.red}Error: No connection string for ${flags.source} environment${colors.reset}`);
    console.error(`Set ${flags.source === 'local' ? 'DATABASE_URL' : flags.source.toUpperCase() + '_DATABASE_URL'} environment variable`);
    process.exit(1);
  }
  
  if (!targetConfig.connectionString) {
    console.error(`${colors.red}Error: No connection string for ${flags.target} environment${colors.reset}`);
    console.error(`Set ${flags.target === 'local' ? 'DATABASE_URL' : flags.target.toUpperCase() + '_DATABASE_URL'} environment variable`);
    process.exit(1);
  }
  
  console.log(`${colors.cyan}🔍 BarkPark Schema Synchronization Tool${colors.reset}\n`);
  console.log(`Comparing schemas:`);
  console.log(`  Source: ${colors.green}${sourceConfig.name}${colors.reset}`);
  console.log(`  Target: ${colors.green}${targetConfig.name}${colors.reset}\n`);
  
  const comparer = new SchemaComparer();
  
  try {
    // Get schemas
    console.log('📊 Retrieving schema information...');
    const [sourceSchema, targetSchema] = await Promise.all([
      comparer.getSchemaInfo({ connectionString: sourceConfig.connectionString }),
      comparer.getSchemaInfo({ connectionString: targetConfig.connectionString })
    ]);
    
    console.log(`\n✓ Source: ${sourceSchema.tableCount} tables${sourceSchema.hasPostGIS ? ' (PostGIS enabled)' : ''}`);
    console.log(`✓ Target: ${targetSchema.tableCount} tables${targetSchema.hasPostGIS ? ' (PostGIS enabled)' : ''}`);
    
    // Compare schemas
    console.log('\n🔄 Comparing schemas...');
    const comparison = comparer.compareSchemas(
      sourceSchema,
      targetSchema,
      sourceConfig.name,
      targetConfig.name
    );
    
    // Display results
    if (comparison.differences.length === 0) {
      console.log(`\n${colors.green}✅ Schemas are in sync!${colors.reset}`);
      console.log('No differences found between environments.\n');
    } else {
      console.log(`\n${colors.yellow}Found ${comparison.differences.length} differences:${colors.reset}`);
      console.log(`  Errors: ${comparison.summary.errors}`);
      console.log(`  Warnings: ${comparison.summary.warnings}`);
      console.log(`  Info: ${comparison.summary.info}`);
      
      // Show differences
      console.log(`\n${colors.cyan}Schema Differences:${colors.reset}`);
      comparison.differences.forEach(formatDifference);
      
      // Show suggestions
      if (comparison.suggestions.length > 0) {
        console.log(`\n${colors.cyan}Synchronization Suggestions:${colors.reset}`);
        comparison.suggestions.forEach(suggestion => {
          const priorityColor = suggestion.priority === 'critical' ? colors.red :
                               suggestion.priority === 'high' ? colors.yellow :
                               colors.blue;
          console.log(`\n${priorityColor}[${suggestion.priority.toUpperCase()}]${colors.reset} ${suggestion.title}`);
          console.log(`  ${suggestion.description}`);
          console.log(`  Steps:`);
          suggestion.steps.forEach((step, i) => {
            console.log(`    ${i + 1}. ${step}`);
          });
        });
      }
      
      // Generate migration SQL
      const migrationSQL = generateMigrationSQL(comparison.differences);
      
      if (flags.output) {
        // Save to file
        const outputPath = path.resolve(flags.output);
        await fs.writeFile(outputPath, migrationSQL, 'utf8');
        console.log(`\n${colors.green}✓ Migration SQL saved to: ${outputPath}${colors.reset}`);
      } else if (comparison.summary.errors > 0) {
        // Show SQL in console
        console.log(`\n${colors.cyan}Generated Migration SQL:${colors.reset}`);
        console.log(`${colors.yellow}${'─'.repeat(60)}${colors.reset}`);
        console.log(migrationSQL);
        console.log(`${colors.yellow}${'─'.repeat(60)}${colors.reset}`);
        
        // Ask to save
        const save = await askQuestion(`\nSave migration SQL to file? (y/N): `);
        if (save.toLowerCase() === 'y') {
          const filename = `schema-sync-${flags.source}-to-${flags.target}-${Date.now()}.sql`;
          await fs.writeFile(filename, migrationSQL, 'utf8');
          console.log(`${colors.green}✓ Saved to: ${filename}${colors.reset}`);
        }
      }
    }
    
  } catch (error) {
    console.error(`\n${colors.red}❌ Error: ${error.message}${colors.reset}`);
    if (flags.verbose) {
      console.error(error.stack);
    }
    process.exit(1);
  }
}

// Run the tool
if (require.main === module) {
  main().catch(console.error);
}

module.exports = { generateMigrationSQL };