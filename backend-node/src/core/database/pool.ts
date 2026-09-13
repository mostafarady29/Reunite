import pg from 'pg';
import { getDatabaseConnectionString, env } from '../../config/env.js';

const { Pool } = pg;

function createPool(): pg.Pool {
  if (env.DB_HOST && env.DB_HOST.startsWith('/')) {
    return new Pool({
      host: env.DB_HOST,
      database: env.DB_NAME || 'reunite',
      user: env.DB_USER || process.env.USER || 'mostafa',
      max: env.DB_POOL_MAX,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 10000,
    });
  }

  const connStr = getDatabaseConnectionString();
  return new Pool({
    connectionString: connStr,
    max: env.DB_POOL_MAX,
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 10000,
    ssl: connStr.includes('sslmode=require')
      ? { rejectUnauthorized: false }
      : undefined,
  });
}

export const pool = createPool();

pool.on('error', (err) => {
  console.error('Unexpected error on idle database client:', err);
});

export async function query<T extends pg.QueryResultRow = any>(
  text: string,
  params?: unknown[]
): Promise<pg.QueryResult<T>> {
  const start = Date.now();
  const res = await pool.query<T>(text, params);
  const duration = Date.now() - start;
  if (env.NODE_ENV === 'development' && duration > 200) {
    console.warn(`Slow query (${duration}ms):`, text);
  }
  return res;
}

export async function withTransaction<T>(
  callback: (client: pg.PoolClient) => Promise<T>
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

export async function checkDatabaseHealth(): Promise<boolean> {
  try {
    const res = await pool.query('SELECT 1 AS health');
    return res.rows.length > 0;
  } catch (error) {
    console.error('Database health check failed:', error);
    return false;
  }
}

export async function closePool(): Promise<void> {
  await pool.end();
}
