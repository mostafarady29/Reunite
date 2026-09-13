import dotenv from 'dotenv';
import { z } from 'zod';
import path from 'path';

dotenv.config();

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  PORT: z.coerce.number().int().positive().default(8000),
  HOST: z.string().default('0.0.0.0'),
  FRONTEND_URL: z.string().default('http://localhost:5173,https://reunitee.pages.dev'),
  DATABASE_URL: z.string().optional(),
  DB_HOST: z.string().optional(),
  DB_PORT: z.coerce.number().default(5432),
  DB_NAME: z.string().default('postgres'),
  DB_USER: z.string().optional(),
  DB_PASSWORD: z.string().optional(),
  DB_POOL_MAX: z.coerce.number().int().positive().default(10),
  JWT_SECRET: z.string().min(8).default('reunite-super-secure-jwt-secret-key-2025'),
  JWT_EXPIRES_IN_DAYS: z.coerce.number().int().positive().default(7),
  AUTH_COOKIE_NAME: z.string().default('reunite_session'),
  AUTH_COOKIE_SECURE: z.preprocess(
    (val) => (typeof val === 'string' ? val.toLowerCase() === 'true' : Boolean(val)),
    z.boolean().default(false)
  ),
  AUTH_COOKIE_SAMESITE: z.enum(['lax', 'strict', 'none']).default('lax'),
  SUPABASE_URL: z.string().optional().default(''),
  SUPABASE_SERVICE_ROLE_KEY: z.string().optional().default(''),
  STORAGE_BUCKET: z.string().default('Photos'),
  AI_SPACE: z.string().optional().default(''),
  AI_SERVICE_URL: z.string().optional().default(''),
  AI_TOKEN: z.string().optional().default(''),
  AI_API_NAME: z.string().default('/embed'),
  EMBEDDING_DIM: z.coerce.number().int().positive().default(512),
});

export type Env = z.infer<typeof envSchema>;

function parseEnv(): Env {
  const result = envSchema.safeParse(process.env);
  if (!result.success) {
    console.error('❌ Environment validation failed:', JSON.stringify(result.error.format(), null, 2));
    throw new Error('Invalid environment configuration');
  }
  return result.data;
}

export const env = parseEnv();

export function getDatabaseConnectionString(): string {
  if (env.DATABASE_URL) return env.DATABASE_URL;
  if (env.DB_HOST && env.DB_USER) {
    const password = env.DB_PASSWORD ? `:${encodeURIComponent(env.DB_PASSWORD)}` : '';
    return `postgresql://${env.DB_USER}${password}@${env.DB_HOST}:${env.DB_PORT}/${env.DB_NAME}?sslmode=require`;
  }
  return 'postgresql://postgres:postgres@localhost:5432/postgres';
}
