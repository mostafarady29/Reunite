import { FastifyPluginAsync } from 'fastify';
import { checkDatabaseHealth } from '../core/database/pool.js';
import { env } from '../config/env.js';

export const healthRoutes: FastifyPluginAsync = async (fastify) => {
  fastify.get('/api/health', async (_request, reply) => {
    return reply.send({
      success: true,
      data: {
        status: 'ok',
        service: 'reunite-node',
        version: '1.0.0',
        timestamp: new Date().toISOString(),
      },
    });
  });

  fastify.get('/api/ready', async (_request, reply) => {
    const databaseReady = await checkDatabaseHealth();
    const modelReady = Boolean(env.AI_SPACE);

    if (!databaseReady && env.NODE_ENV === 'production') {
      return reply.status(503).send({
        success: false,
        error: {
          message: 'Service dependencies are not ready',
          database: databaseReady,
          model: modelReady,
        },
      });
    }

    return reply.send({
      success: true,
      data: {
        status: 'ready',
        database: databaseReady,
        model: modelReady,
      },
    });
  });
};
