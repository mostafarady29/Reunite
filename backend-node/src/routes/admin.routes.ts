import { FastifyPluginAsync } from 'fastify';
import {
  adminCreateUserSchema,
  adminUpdateUserSchema,
  validateSchema,
} from '../validators/schemas.js';
import { userRepository } from '../repositories/user.repository.js';
import { locationRepository } from '../repositories/location.repository.js';
import { photoRepository } from '../repositories/photo.repository.js';
import { storageService } from '../core/storage/supabase-storage.js';
import { hashPassword } from '../core/security/auth.js';
import { requireAdmin } from '../middlewares/auth.middleware.js';
import {
  ConflictError,
  ValidationError,
  NotFoundError,
  ForbiddenError,
} from '../core/errors/app-error.js';

export const adminRoutes: FastifyPluginAsync = async (fastify) => {
  fastify.addHook('preHandler', requireAdmin);

  // GET /api/admin/users
  fastify.get('/api/admin/users', async (_request, reply) => {
    const users = await userRepository.findAllWithStats();
    return reply.send({ success: true, data: users });
  });

  // POST /api/admin/users
  fastify.post('/api/admin/users', async (request, reply) => {
    const body = validateSchema(adminCreateUserSchema, request.body);

    const cityExists = await locationRepository.cityExists(body.city_id);
    if (!cityExists) {
      throw new ValidationError('City does not exist.');
    }

    const existingUser = await userRepository.findByPhone(body.phone);
    if (existingUser) {
      throw new ConflictError('Phone number is already registered.');
    }

    const passwordHash = await hashPassword(body.password);
    const user = await userRepository.create({
      name: body.name,
      phone: body.phone,
      password_hash: passwordHash,
      city_id: body.city_id,
      role: body.role,
    });

    return reply.status(201).send({ success: true, data: user });
  });

  // PATCH /api/admin/users/:id
  fastify.patch<{ Params: { id: string } }>('/api/admin/users/:id', async (request, reply) => {
    const targetUserId = parseInt(request.params.id, 10);
    const currentAdminId = request.currentUser!.user_id;

    const body = validateSchema(adminUpdateUserSchema, request.body);

    if (targetUserId === currentAdminId && body.role === false) {
      throw new ValidationError('You cannot remove administrator access from your own account.');
    }

    if (body.city_id) {
      const cityExists = await locationRepository.cityExists(body.city_id);
      if (!cityExists) {
        throw new ValidationError('City does not exist.');
      }
    }

    if (body.phone) {
      const existingUser = await userRepository.findByPhone(body.phone);
      if (existingUser && existingUser.user_id !== targetUserId) {
        throw new ConflictError('Phone number is already registered.');
      }
    }

    let passwordHash: string | undefined;
    if (body.password) {
      passwordHash = await hashPassword(body.password);
    }

    const updated = await userRepository.adminUpdate(targetUserId, {
      name: body.name,
      phone: body.phone,
      city_id: body.city_id,
      role: body.role,
      password_hash: passwordHash,
    });

    if (!updated) {
      throw new NotFoundError('User not found.');
    }

    return reply.send({ success: true, data: updated });
  });

  // DELETE /api/admin/users/:id
  fastify.delete<{ Params: { id: string } }>('/api/admin/users/:id', async (request, reply) => {
    const targetUserId = parseInt(request.params.id, 10);
    const currentAdminId = request.currentUser!.user_id;

    if (targetUserId === currentAdminId) {
      throw new ValidationError('You cannot delete your own administrator account.');
    }

    const targetUser = await userRepository.findById(targetUserId);
    if (!targetUser) {
      throw new NotFoundError('User not found.');
    }

    // Retrieve storage paths for photos owned by this user
    const photoPaths = await photoRepository.findPathsByUserId(targetUserId);

    // Delete user (database CASCADE will delete comments, embeddings, photos, reports)
    await userRepository.deleteUser(targetUserId);

    // Clean up photo objects in storage
    for (const path of photoPaths) {
      storageService.deleteObject(path).catch(console.error);
    }

    return reply.send({ success: true, data: { deleted: true } });
  });
};
