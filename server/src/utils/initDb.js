import pg from 'pg';
import config from '../config/index.js';
import fs from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const { Pool } = pg;

async function initializeDatabase() {
  // First connect to postgres database to create the database
  const pool = new Pool({
    host: config.database.host,
    port: config.database.port,
    database: 'postgres', // Connect to default database
    user: config.database.user,
    password: config.database.password,
  });

  try {
    console.log('Connecting to PostgreSQL...');

    // Check if database exists, create if not
    const dbCheckResult = await pool.query(
      'SELECT 1 FROM pg_database WHERE datname = $1',
      [config.database.name]
    );

    if (dbCheckResult.rows.length === 0) {
      console.log(`Creating database: ${config.database.name}`);
      await pool.query(`CREATE DATABASE ${config.database.name}`);
      console.log('Database created successfully');
    } else {
      console.log(`Database ${config.database.name} already exists`);
    }

    await pool.end();

    // Now connect to the target database and run schema
    const targetPool = new Pool({
      host: config.database.host,
      port: config.database.port,
      database: config.database.name,
      user: config.database.user,
      password: config.database.password,
    });

    // Read and execute schema
    const schemaPath = join(__dirname, '../config/init.sql');
    const schema = fs.readFileSync(schemaPath, 'utf-8');

    console.log('Executing database schema...');
    await targetPool.query(schema);
    console.log('Database schema initialized successfully');

    await targetPool.end();

    console.log('\n✅ Database initialization complete!');
    console.log(`\nDatabase: ${config.database.name}`);
    console.log(`Host: ${config.database.host}:${config.database.port}`);

  } catch (error) {
    console.error('Failed to initialize database:', error.message);
    process.exit(1);
  }
}

initializeDatabase();
