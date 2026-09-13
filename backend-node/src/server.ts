import { buildApp } from './app.js';
import { env } from './config/env.js';
import { checkDatabaseHealth, closePool } from './core/database/pool.js';

async function bootstrap() {
  const app = await buildApp();

  // Test DB connection at startup
  const dbConnected = await checkDatabaseHealth();
  if (dbConnected) {
    app.log.info('✅ PostgreSQL connection pool initialized and healthy');
  } else {
    app.log.warn('⚠️ PostgreSQL connection failed or database is not reachable yet');
  }

  // Graceful shutdown handling
  const signals = ['SIGINT', 'SIGTERM'] as const;
  for (const signal of signals) {
    process.on(signal, async () => {
      app.log.info(`Received ${signal}, initiating graceful shutdown...`);
      try {
        await app.close();
        app.log.info('Fastify server closed');
        await closePool();
        app.log.info('Database pool drained');
        process.exit(0);
      } catch (err) {
        app.log.error(err, 'Error during graceful shutdown');
        process.exit(1);
      }
    });
  }

  try {
    const address = await app.listen({ port: env.PORT, host: env.HOST });
    app.log.info(`🚀 Reunite Node.js API server listening at ${address}`);
  } catch (err) {
    app.log.error(err);
    process.exit(1);
  }
}

bootstrap().catch((err) => {
  console.error('Fatal bootstrap error:', err);
  process.exit(1);
});
