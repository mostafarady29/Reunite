import { FastifyPluginAsync } from 'fastify';
import {
  authSignupSchema,
  authLoginSchema,
  updateMeSchema,
  changePasswordSchema,
  validateSchema,
} from '../validators/schemas.js';
import { userRepository } from '../repositories/user.repository.js';
import { locationRepository } from '../repositories/location.repository.js';
import { reportRepository } from '../repositories/report.repository.js';
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

export const authRoutes: FastifyPluginAsync = async (fastify) => {
  fastify.post('/api/auth/signup', async (request, reply) => {
    const body = validateSchema(authSignupSchema, request.body);

    const existingUser = await userRepository.findByPhone(body.phone);
    if (existingUser) {
      throw new ConflictError('Phone number is already registered.');
    }

    const cityValid = await locationRepository.validateCityBelongsToGovernorate(
      body.city_id,
      body.governorate_id
    );
    if (!cityValid) {
      throw new ValidationError('City does not belong to the selected governorate.');
    }

    const passwordHash = await hashPassword(body.password);
    const user = await userRepository.create({
      name: body.name,
      phone: body.phone,
      password_hash: passwordHash,
      city_id: body.city_id,
      role: false,
    });

    const token = generateToken(user);
    setAuthCookie(reply, token);

    return reply.status(201).send({
      success: true,
      data: {
        user,
        token,
      },
    });
  });

  fastify.post('/api/auth/login', async (request, reply) => {
    const body = validateSchema(authLoginSchema, request.body);

    const user = await userRepository.findByPhone(body.phone);
    if (!user) {
      throw new UnauthorizedError('Invalid phone or password.');
    }

    const isMatch = await verifyPassword(body.password, user.password_hash);
    if (!isMatch) {
      throw new UnauthorizedError('Invalid phone or password.');
    }

    const { password_hash, ...safeUser } = user;
    const token = generateToken(safeUser);
    setAuthCookie(reply, token);

    return reply.send({
      success: true,
      data: {
        user: safeUser,
        token,
      },
    });
  });

  fastify.post('/api/auth/logout', async (_request, reply) => {
    clearAuthCookie(reply);
    return reply.send({
      success: true,
      data: { message: 'Signed out successfully.' },
    });
  });

  fastify.post('/api/auth/forgot-password', async (_request, reply) => {
    return reply.status(202).send({
      success: true,
      data: {
        message: 'If that phone number exists, follow-up instructions will be provided securely.',
      },
    });
  });

  fastify.get('/api/me', { preHandler: [authenticate] }, async (request, reply) => {
    return reply.send({
      success: true,
      data: request.currentUser,
    });
  });

  fastify.patch('/api/me', { preHandler: [authenticate] }, async (request, reply) => {
    const body = validateSchema(updateMeSchema, request.body);
    const updated = await userRepository.updateProfile(request.currentUser!.user_id, body);
    if (!updated) {
      throw new ValidationError('Nothing to update.');
    }

    return reply.send({
      success: true,
      data: updated,
    });
  });

  fastify.patch('/api/me/password', { preHandler: [authenticate] }, async (request, reply) => {
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
  });

  fastify.get('/api/me/reports', { preHandler: [authenticate] }, async (request, reply) => {
    const reports = await reportRepository.findByUserId(request.currentUser!.user_id);
    return reply.send({
      success: true,
      data: reports,
    });
  });
};
