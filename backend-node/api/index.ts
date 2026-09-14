import type { FastifyInstance } from 'fastify';
import { buildApp } from '../src/app.js';

let app: FastifyInstance | null = null;

export default async function handler(req: any, res: any) {
  try {
    if (!app) {
      app = await buildApp();
      await app.ready();
    }
    if (req.url === '/api/index' || req.url === '/api/index/' || !req.url) {
      req.url = '/';
    }
    app.server.emit('request', req, res);
  } catch (err) {
    console.error('Vercel serverless function error:', err);
    res.statusCode = 500;
    res.setHeader('Content-Type', 'application/json');
    res.end(
      JSON.stringify({
        success: false,
        error: {
          code: 'SERVERLESS_FUNCTION_ERROR',
          message: err instanceof Error ? err.message : String(err),
        },
      })
    );
  }
}
