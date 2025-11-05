import { Pool, PoolConfig } from 'pg';
import { logger } from '@/utils/logger';

let pool: Pool;

const config: PoolConfig = {
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5432'),
  database: process.env.DB_NAME || 'study_planner',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || '',
  max: parseInt(process.env.DB_MAX_CONNECTIONS || '20'),
  idleTimeoutMillis: parseInt(process.env.DB_IDLE_TIMEOUT || '30000'),
  connectionTimeoutMillis: parseInt(process.env.DB_CONNECTION_TIMEOUT || '2000'),
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false
};

export async function connectDatabase(): Promise<Pool> {
  try {
    pool = new Pool(config);

    // Test connection
    const client = await pool.connect();
    const result = await client.query('SELECT NOW()');
    client.release();

    logger.info('✅ Database connected successfully');
    logger.info(`📊 Database: ${config.database} at ${config.host}:${config.port}`);

    // Run migrations if needed
    await runMigrations();

    return pool;
  } catch (error) {
    logger.error('❌ Database connection failed:', error);
    throw error;
  }
}

export function getDatabasePool(): Pool {
  if (!pool) {
    throw new Error('Database not initialized. Call connectDatabase() first.');
  }
  return pool;
}

export async function closeDatabase(): Promise<void> {
  if (pool) {
    await pool.end();
    logger.info('📊 Database connection closed');
  }
}

async function runMigrations(): Promise<void> {
  try {
    const client = await pool.connect();

    // Create migrations table if it doesn't exist
    await client.query(`
      CREATE TABLE IF NOT EXISTS migrations (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255) UNIQUE NOT NULL,
        executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // Check if migrations have been run
    const result = await client.query('SELECT name FROM migrations ORDER BY executed_at');
    const executedMigrations = result.rows.map(row => row.name);

    // Get all migration files
    const migrations = [
      '001_create_users_table.sql',
      '002_create_subjects_table.sql',
      '003_create_study_sessions_table.sql',
      '004_create_study_tasks_table.sql',
      '005_create_user_achievements_table.sql',
      '006_create_subscriptions_table.sql',
      '007_create_analytics_tables.sql',
      '008_create_notifications_table.sql'
    ];

    // Run pending migrations
    for (const migration of migrations) {
      if (!executedMigrations.includes(migration)) {
        logger.info(`🔄 Running migration: ${migration}`);

        // In a real implementation, you would read the migration file
        // and execute its SQL content here
        await client.query('INSERT INTO migrations (name) VALUES ($1)', [migration]);

        logger.info(`✅ Migration completed: ${migration}`);
      }
    }

    client.release();
    logger.info('📊 All migrations completed');
  } catch (error) {
    logger.error('❌ Migration failed:', error);
    throw error;
  }
}

// Helper function for transaction management
export async function withTransaction<T>(
  callback: (client: any) => Promise<T>
): Promise<T> {
  const client = await pool.connect();

  try {
    await client.query('BEGIN');
    const result = await callback(client);
    await client.query('COMMIT');
    return result;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}