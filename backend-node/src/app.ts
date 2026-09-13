import Fastify, { FastifyInstance } from 'fastify';
import cors from '@fastify/cors';
import cookie from '@fastify/cookie';
import multipart from '@fastify/multipart';
import helmet from '@fastify/helmet';
import rateLimit from '@fastify/rate-limit';

import { env } from './config/env.js';
import { AppError } from './core/errors/app-error.js';
import { healthRoutes } from './routes/health.routes.js';
import { locationRoutes } from './routes/location.routes.js';
import { authRoutes } from './routes/auth.routes.js';
import { reportRoutes } from './routes/report.routes.js';
import { searchRoutes } from './routes/search.routes.js';
import { adminRoutes } from './routes/admin.routes.js';
import { casesMobileRoutes } from './routes/cases-mobile.routes.js';

export async function buildApp(): Promise<FastifyInstance> {
  const app = Fastify({
    logger:
      env.NODE_ENV === 'test'
        ? false
        : {
            level: env.NODE_ENV === 'production' ? 'info' : 'debug',
            transport:
              env.NODE_ENV === 'development'
                ? {
                    target: 'pino-pretty',
                    options: { colorize: true },
                  }
                : undefined,
          },
    trustProxy: true,
  });

  // 1. Security Headers
  await app.register(helmet, {
    contentSecurityPolicy: false, // Let frontend handle CSP or adjust for API
    crossOriginResourcePolicy: { policy: 'cross-origin' },
  });

  // 2. CORS configuration matching Frontend and mobile
  const allowedOrigins = env.FRONTEND_URL.split(',').map((url) => url.trim());
  await app.register(cors, {
    origin: (origin, cb) => {
      // Allow requests with no origin (like mobile apps or curl)
      if (!origin) return cb(null, true);
      if (allowedOrigins.includes(origin) || env.NODE_ENV !== 'production') {
        return cb(null, true);
      }
      return cb(new Error('Not allowed by CORS'), false);
    },
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With', 'Accept'],
  });

  // 3. Cookies
  await app.register(cookie, {
    secret: env.JWT_SECRET,
    hook: 'onRequest',
  });

  // 4. Multipart file uploads
  await app.register(multipart, {
    limits: {
      fileSize: 15 * 1024 * 1024, // 15MB
      files: 5,
    },
  });

  // 5. Rate Limiting (120 requests per minute per IP)
  await app.register(rateLimit, {
    max: 120,
    timeWindow: '1 minute',
    allowList: ['127.0.0.1', 'localhost'],
  });

  // 6. Centralized Error Handler
  app.setErrorHandler((error, _request, reply) => {
    if (error instanceof AppError) {
      if (error.statusCode >= 500) {
        app.log.error(error);
      }
      return reply.status(error.statusCode).send({
        success: false,
        error: {
          code: error.code,
          message: error.message,
          details: error.details,
        },
      });
    }

    // Fastify / schema validation errors
    const err = error as Error & { validation?: unknown };
    if (err.validation) {
      return reply.status(422).send({
        success: false,
        error: {
          code: 'VALIDATION_ERROR',
          message: err.message,
          details: err.validation,
        },
      });
    }

    // Fallback unhandled errors
    app.log.error(error);
    return reply.status(500).send({
      success: false,
      error: {
        code: 'INTERNAL_SERVER_ERROR',
        message:
          env.NODE_ENV === 'production'
            ? 'An unexpected error occurred. Please try again later.'
            : err.message,
      },
    });
  });

  // 7. Register Domain Routes
  await app.register(healthRoutes);
  await app.register(locationRoutes);
  await app.register(authRoutes);
  await app.register(reportRoutes);
  await app.register(searchRoutes);
  await app.register(adminRoutes);
  await app.register(casesMobileRoutes, { prefix: '/api' });
  await app.register(casesMobileRoutes, { prefix: '' });

  return app;
}
