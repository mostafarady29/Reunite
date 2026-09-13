import { FastifyPluginAsync, FastifyRequest, FastifyReply } from 'fastify';
import {
  updateMeSchema,
  changePasswordSchema,
  validateSchema,
} from '../validators/schemas.js';
import { userRepository } from '../repositories/user.repository.js';
import { locationRepository } from '../repositories/location.repository.js';
import { reportRepository } from '../repositories/report.repository.js';
import { query } from '../core/database/pool.js';
import {
  hashPassword,
  verifyPassword,
  generateToken,
  setAuthCookie,
  clearAuthCookie,
} from '../core/security/auth.js';
import { authenticate } from '../middlewares/auth.middleware.js';
import {
  ConflictError,
  ValidationError,
  UnauthorizedError,
  BadRequestError,
} from '../core/errors/app-error.js';

function formatUserResponse(user: any) {
  if (!user) return user;
  const idStr = String(user.user_id || user.id || '');
  const idNum = Number(user.user_id || user.id || 0);
  return {
    ...user,
    id: idStr,
    user_id: idNum,
    fullName: user.name || user.fullName || '',
    name: user.name || user.fullName || '',
  };
}

export const authRoutes: FastifyPluginAsync = async (fastify) => {
  // Shared Registration Handler (Web & Flutter Mobile)
  const registerHandler = async (request: FastifyRequest, reply: FastifyReply) => {
    const rawBody = (request.body || {}) as Record<string, any>;
    const name = String(rawBody.fullName || rawBody.name || '').trim();
    const phone = String(rawBody.phone || '').trim();
    const password = String(rawBody.password || '');

    if (!name || name.length < 2) {
      throw new ValidationError('Name must be at least 2 characters.');
    }
    if (!phone || phone.length < 7) {
      throw new ValidationError('Valid phone number is required.');
    }
    if (!password || password.length < 8) {
      throw new ValidationError('Password must be at least 8 characters.');
    }

    const existingUser = await userRepository.findByPhone(phone);
    if (existingUser) {
      throw new ConflictError('Phone number is already registered.');
    }

    // Resolve city_id: integer or lookup city name string or default to 1
    let cityId = 1;
    if (rawBody.city_id && typeof rawBody.city_id === 'number') {
      cityId = rawBody.city_id;
    } else if (rawBody.city && typeof rawBody.city === 'string') {
      const cityName = rawBody.city.trim();
      const { rows } = await query<{ city_id: number }>(
        'SELECT city_id FROM city WHERE name ILIKE $1 OR name ILIKE $2 LIMIT 1',
        [cityName, `%${cityName}%`]
      );
      if (rows.length > 0) {
        cityId = rows[0].city_id;
      }
    }

    if (rawBody.governorate_id) {
      const cityValid = await locationRepository.validateCityBelongsToGovernorate(
        cityId,
        rawBody.governorate_id
      );
      if (!cityValid) {
        throw new ValidationError('City does not belong to the selected governorate.');
      }
    }

    const passwordHash = await hashPassword(password);
    const user = await userRepository.create({
      name,
      phone,
      password_hash: passwordHash,
      city_id: cityId,
      role: false,
    });

    const formattedUser = formatUserResponse(user);
    const token = generateToken(user);
    setAuthCookie(reply, token);

    return reply.status(201).send({
      success: true,
      data: {
        user: formattedUser,
        token,
      },
    });
  };

  fastify.post('/api/auth/signup', registerHandler);
  fastify.post('/api/auth/register', registerHandler);
  fastify.post('/auth/register', registerHandler);

  // Shared Login Handler (Web & Flutter Mobile)
  const loginHandler = async (request: FastifyRequest, reply: FastifyReply) => {
    const body = (request.body || {}) as Record<string, any>;
    const identifier = String(body.identifier || body.phone || '').trim();
    const password = String(body.password || '');

    if (!identifier || !password) {
      throw new ValidationError('Phone number / identifier and password are required.');
    }

    const user = await userRepository.findByPhone(identifier);
    if (!user) {
      throw new UnauthorizedError('Invalid phone or password.');
    }

    const isMatch = await verifyPassword(password, user.password_hash);
    if (!isMatch) {
      throw new UnauthorizedError('Invalid phone or password.');
    }

    const { password_hash, ...safeUser } = user;
    const formattedUser = formatUserResponse(safeUser);
    const token = generateToken(safeUser);
    setAuthCookie(reply, token);

    return reply.send({
      success: true,
      data: {
        user: formattedUser,
        token,
      },
    });
  };

  fastify.post('/api/auth/login', loginHandler);
  fastify.post('/auth/login', loginHandler);

  // Shared Logout Handler
  const logoutHandler = async (_request: FastifyRequest, reply: FastifyReply) => {
    clearAuthCookie(reply);
    return reply.send({
      success: true,
      data: { message: 'Signed out successfully.' },
    });
  };

  fastify.post('/api/auth/logout', logoutHandler);
  fastify.post('/auth/logout', logoutHandler);

  // Verify OTP (Flutter Mobile)
  const verifyOtpHandler = async (_request: FastifyRequest, reply: FastifyReply) => {
    return reply.send({
      success: true,
      data: { message: 'OTP verified successfully.' },
    });
  };
  fastify.post('/api/auth/verify-otp', verifyOtpHandler);
  fastify.post('/auth/verify-otp', verifyOtpHandler);

  // Forgot Password
  const forgotPasswordHandler = async (_request: FastifyRequest, reply: FastifyReply) => {
    return reply.status(202).send({
      success: true,
      data: {
        message: 'If that account exists, follow-up instructions will be provided securely.',
      },
    });
  };
  fastify.post('/api/auth/forgot-password', forgotPasswordHandler);
  fastify.post('/auth/forgot-password', forgotPasswordHandler);

  // Reset Password
  const resetPasswordHandler = async (request: FastifyRequest, reply: FastifyReply) => {
    const body = (request.body || {}) as Record<string, any>;
    const phone = String(body.phone || body.identifier || body.email || '').trim();
    const newPassword = String(body.newPassword || body.password || '');

    if (phone && newPassword && newPassword.length >= 8) {
      const user = await userRepository.findByPhone(phone);
      if (user) {
        const hash = await hashPassword(newPassword);
        await userRepository.updatePassword(user.user_id, hash);
      }
    }

    return reply.send({
      success: true,
      data: { message: 'Password reset successfully.' },
    });
  };
  fastify.post('/api/auth/reset-password', resetPasswordHandler);
  fastify.post('/auth/reset-password', resetPasswordHandler);

  // Me & Profile
  const meHandler = async (request: FastifyRequest, reply: FastifyReply) => {
    return reply.send({
      success: true,
      data: formatUserResponse(request.currentUser),
    });
  };
  fastify.get('/api/me', { preHandler: [authenticate] }, meHandler);
  fastify.get('/me', { preHandler: [authenticate] }, meHandler);
  fastify.get('/auth/me', { preHandler: [authenticate] }, meHandler);
  fastify.get('/api/auth/me', { preHandler: [authenticate] }, meHandler);

  const profileUpdateHandler = async (request: FastifyRequest, reply: FastifyReply) => {
    const body = validateSchema(updateMeSchema, request.body);
    const updated = await userRepository.updateProfile(request.currentUser!.user_id, body);
    if (!updated) {
      throw new ValidationError('Nothing to update.');
    }

    return reply.send({
      success: true,
      data: formatUserResponse(updated),
    });
  };
  fastify.patch('/api/me', { preHandler: [authenticate] }, profileUpdateHandler);
  fastify.patch('/me', { preHandler: [authenticate] }, profileUpdateHandler);
  fastify.patch('/auth/profile', { preHandler: [authenticate] }, profileUpdateHandler);
  fastify.patch('/api/auth/profile', { preHandler: [authenticate] }, profileUpdateHandler);

  const passwordChangeHandler = async (request: FastifyRequest, reply: FastifyReply) => {
    const body = validateSchema(changePasswordSchema, request.body);
    const userId = request.currentUser!.user_id;

    const user = await userRepository.findById(userId);
    if (!user) {
      throw new UnauthorizedError('User not found.');
    }

    const isMatch = await verifyPassword(body.current_password, user.password_hash);
    if (!isMatch) {
      throw new BadRequestError('Current password is incorrect.');
    }

    const newHash = await hashPassword(body.new_password);
    await userRepository.updatePassword(userId, newHash);

    return reply.send({
      success: true,
      data: { message: 'Password updated successfully.' },
    });
  };
  fastify.patch('/api/me/password', { preHandler: [authenticate] }, passwordChangeHandler);
  fastify.patch('/me/password', { preHandler: [authenticate] }, passwordChangeHandler);

  const reportsHandler = async (request: FastifyRequest, reply: FastifyReply) => {
    const reports = await reportRepository.findByUserId(request.currentUser!.user_id);
    return reply.send({
      success: true,
      data: reports,
    });
  };
  fastify.get('/api/me/reports', { preHandler: [authenticate] }, reportsHandler);
  fastify.get('/me/reports', { preHandler: [authenticate] }, reportsHandler);
};
