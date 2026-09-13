import { FastifyReply, FastifyRequest } from 'fastify';
import { extractToken, verifyToken } from '../core/security/auth.js';
import { userRepository } from '../repositories/user.repository.js';
import { UnauthorizedError, ForbiddenError } from '../core/errors/app-error.js';

export async function authenticate(
  request: FastifyRequest,
  reply: FastifyReply
): Promise<void> {
  const token = extractToken(request);
  if (!token) {
    throw new UnauthorizedError('Authentication required');
  }

  const payload = verifyToken(token);
  const user = await userRepository.findById(payload.sub);
  if (!user) {
    throw new UnauthorizedError('User not found');
  }

  request.currentUser = {
    user_id: user.user_id,
    name: user.name,
    phone: user.phone,
    city_id: user.city_id,
    joined_at: user.joined_at,
    role: user.role,
  };
}

export async function requireAdmin(
  request: FastifyRequest,
  reply: FastifyReply
): Promise<void> {
  await authenticate(request, reply);
  if (!request.currentUser?.role) {
    throw new ForbiddenError('Administrator access is required');
  }
}

export async function optionalAuth(
  request: FastifyRequest,
  reply: FastifyReply
): Promise<void> {
  const token = extractToken(request);
  if (!token) return;

  try {
    const payload = verifyToken(token);
    const user = await userRepository.findById(payload.sub);
    if (user) {
      request.currentUser = {
        user_id: user.user_id,
        name: user.name,
        phone: user.phone,
        city_id: user.city_id,
        joined_at: user.joined_at,
        role: user.role,
      };
    }
  } catch {
    // Ignore invalid token in optional authentication
  }
}
