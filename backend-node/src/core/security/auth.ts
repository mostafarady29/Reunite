import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { FastifyReply, FastifyRequest } from 'fastify';
import { env } from '../../config/env.js';
import { UnauthorizedError, ForbiddenError } from '../errors/app-error.js';

export interface UserSessionPayload {
  sub: string;
  phone?: string;
  role?: boolean;
  exp?: number;
}

export interface AuthenticatedUser {
  user_id: number;
  name: string;
  phone: string;
  city_id: number | null;
  joined_at: string;
  role: boolean;
}

declare module 'fastify' {
  interface FastifyRequest {
    currentUser?: AuthenticatedUser;
  }
}

export async function hashPassword(plainText: string): Promise<string> {
  const salt = await bcrypt.genSalt(10);
  return bcrypt.hash(plainText, salt);
}

export async function verifyPassword(plainText: string, hashed: string): Promise<boolean> {
  return bcrypt.compare(plainText, hashed);
}

export function generateToken(user: { user_id: number | string; phone?: string; role?: boolean }): string {
  const payload: UserSessionPayload = {
    sub: String(user.user_id),
    phone: user.phone,
    role: user.role,
  };
  return jwt.sign(payload, env.JWT_SECRET, {
    expiresIn: `${env.JWT_EXPIRES_IN_DAYS}d`,
    algorithm: 'HS256',
  });
}

export function verifyToken(tokenString: string): UserSessionPayload {
  try {
    return jwt.verify(tokenString, env.JWT_SECRET, { algorithms: ['HS256'] }) as UserSessionPayload;
  } catch {
    throw new UnauthorizedError('Invalid or expired session');
  }
}

export function extractToken(request: FastifyRequest): string | null {
  // 1. Check HTTP-only cookie
  const cookieToken = request.cookies[env.AUTH_COOKIE_NAME];
  if (cookieToken) return cookieToken;

  // 2. Check Authorization: Bearer <token>
  const authHeader = request.headers.authorization;
  if (authHeader && authHeader.startsWith('Bearer ')) {
    return authHeader.substring(7).trim();
  }

  return null;
}

export function setAuthCookie(reply: FastifyReply, token: string): void {
  reply.setCookie(env.AUTH_COOKIE_NAME, token, {
    path: '/',
    httpOnly: true,
    secure: env.AUTH_COOKIE_SECURE,
    sameSite: env.AUTH_COOKIE_SAMESITE,
    maxAge: env.JWT_EXPIRES_IN_DAYS * 24 * 60 * 60,
  });
}

export function clearAuthCookie(reply: FastifyReply): void {
  reply.clearCookie(env.AUTH_COOKIE_NAME, {
    path: '/',
    httpOnly: true,
    secure: env.AUTH_COOKIE_SECURE,
    sameSite: env.AUTH_COOKIE_SAMESITE,
  });
}
