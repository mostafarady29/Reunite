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

  // 1. GET admin users
  const getAdminUsersHandler = async (_request: any, reply: any) => {
    const users = await userRepository.findAllWithStats();
    return reply.send({ success: true, data: users });
  };
  fastify.get('/api/admin/users', getAdminUsersHandler);
  fastify.get('/admin/users', getAdminUsersHandler);

  // 2. POST admin users
  const createAdminUserHandler = async (request: any, reply: any) => {
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
  };
  fastify.post('/api/admin/users', createAdminUserHandler);
  fastify.post('/admin/users', createAdminUserHandler);

  // 3. PATCH admin users
  const updateAdminUserHandler = async (request: any, reply: any) => {
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
  };
  fastify.patch('/api/admin/users/:id', updateAdminUserHandler);
  fastify.patch('/admin/users/:id', updateAdminUserHandler);

  // 4. DELETE admin users
  const deleteAdminUserHandler = async (request: any, reply: any) => {
    const targetUserId = parseInt(request.params.id, 10);
    const currentAdminId = request.currentUser!.user_id;

    if (targetUserId === currentAdminId) {
      throw new ValidationError('You cannot delete your own administrator account.');
    }

    const targetUser = await userRepository.findById(targetUserId);
    if (!targetUser) {
      throw new NotFoundError('User not found.');
    }

    const photoPaths = await photoRepository.findPathsByUserId(targetUserId);
    await userRepository.deleteUser(targetUserId);

    for (const path of photoPaths) {
      storageService.deleteObject(path).catch(console.error);
    }

    return reply.send({ success: true, data: { deleted: true } });
  };
  fastify.delete('/api/admin/users/:id', deleteAdminUserHandler);
  fastify.delete('/admin/users/:id', deleteAdminUserHandler);
};
