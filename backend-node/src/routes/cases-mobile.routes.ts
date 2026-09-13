import { FastifyPluginAsync } from 'fastify';
import { reportRepository } from '../repositories/report.repository.js';
import { locationRepository } from '../repositories/location.repository.js';
import { commentRepository } from '../repositories/comment.repository.js';
import { userRepository } from '../repositories/user.repository.js';
import { agentMemoryService } from '../services/agent-memory.service.js';
import { authenticate, optionalAuth } from '../middlewares/auth.middleware.js';
import { hashPassword, generateToken, setAuthCookie } from '../core/security/auth.js';
import {
  authSignupSchema,
  updateMeSchema,
  validateSchema,
} from '../validators/schemas.js';
import {
  NotFoundError,
  ValidationError,
  ConflictError,
  UnauthorizedError,
} from '../core/errors/app-error.js';

export const casesMobileRoutes: FastifyPluginAsync = async (fastify) => {
  // 1. GET /cases/missing
  fastify.get('/cases/missing', async (request, reply) => {
    const q = request.query as Record<string, any>;
    const search = q.search || '';
    const gender = q.gender ? String(q.gender).toUpperCase() : null;

    const data = await reportRepository.findPaginated({
      kind: 'MISSING',
      status: 'OPEN',
      search,
      page: 1,
      limit: 100,
    });

    let items = data.items;
    if (gender) {
      items = items.filter((item) => item.gender?.toUpperCase() === gender);
    }
    if (q.minAge !== undefined) {
      const min = parseInt(q.minAge, 10);
      if (!isNaN(min)) items = items.filter((item) => (item.age ?? 0) >= min);
    }
    if (q.maxAge !== undefined) {
      const max = parseInt(q.maxAge, 10);
      if (!isNaN(max)) items = items.filter((item) => (item.age ?? 0) <= max);
    }

    return reply.send({ success: true, data: items });
  });

  // 2. GET /cases/found
  fastify.get('/cases/found', async (_request, reply) => {
    const data = await reportRepository.findPaginated({
      kind: 'FOUND',
      status: 'OPEN',
      page: 1,
      limit: 100,
    });

    return reply.send({ success: true, data: data.items });
  });

  // 3. GET /cases/statistics
  fastify.get('/cases/statistics', async (_request, reply) => {
    const stats = await reportRepository.getStatistics();
    return reply.send({ success: true, data: stats });
  });

  // 4. GET /cases/nearby
  fastify.get('/cases/nearby', async (request, reply) => {
    const q = request.query as { lat?: string; lng?: string; radius?: string };
    const lat = parseFloat(q.lat || '0');
    const lng = parseFloat(q.lng || '0');
    const radiusMeters = parseInt(q.radius || '10000', 10);

    if (isNaN(lat) || isNaN(lng)) {
      throw new ValidationError('Valid lat and lng query parameters are required.');
    }

    const nearby = await reportRepository.findNearby(lat, lng, radiusMeters);
    return reply.send({ success: true, data: nearby });
  });

  // 5. GET /cases/:id
  fastify.get<{ Params: { id: string } }>('/cases/:id', async (request, reply) => {
    const id = parseInt(request.params.id, 10);
    const report = await reportRepository.findById(id);
    if (!report) {
      throw new NotFoundError('Case not found.');
    }
    return reply.send({ success: true, data: report });
  });

  // 6. GET /cases/:id/matches
  fastify.get<{ Params: { id: string } }>('/cases/:id/matches', async (request, reply) => {
    const id = parseInt(request.params.id, 10);
    const matches = await agentMemoryService.findPossibleMatchesForCase(id);
    return reply.send({ success: true, data: matches });
  });

  // 7. POST /cases/missing
  fastify.post('/cases/missing', { preHandler: [optionalAuth] }, async (request, reply) => {
    const body = request.body as Record<string, any>;
    const userId = request.currentUser?.user_id || 1; // Default to community/first user if unauthenticated

    let lat: number | null = null;
    let lng: number | null = null;
    if (body.coordinates && typeof body.coordinates === 'object') {
      lat = body.coordinates.lat ?? body.coordinates.latitude ?? null;
      lng = body.coordinates.lng ?? body.coordinates.longitude ?? null;
    } else if (body.latitude !== undefined && body.longitude !== undefined) {
      lat = Number(body.latitude);
      lng = Number(body.longitude);
    }

    const report = await reportRepository.create({
      userId,
      kind: 'MISSING',
      name: body.name || 'Unknown Child',
      age: body.age ? parseInt(body.age, 10) : null,
      gender: body.gender ? String(body.gender).toUpperCase() : null,
      occurrenceDate: body.missingSince || body.occurrence_date || null,
      latitude: lat,
      longitude: lng,
      description: body.description || body.clothing || null,
    });

    return reply.status(201).send({ success: true, data: report });
  });

  // 8. POST /cases/found
  fastify.post('/cases/found', { preHandler: [optionalAuth] }, async (request, reply) => {
    const body = request.body as Record<string, any>;
    const userId = request.currentUser?.user_id || 1;

    let lat: number | null = null;
    let lng: number | null = null;
    if (body.coordinates && typeof body.coordinates === 'object') {
      lat = body.coordinates.lat ?? body.coordinates.latitude ?? null;
      lng = body.coordinates.lng ?? body.coordinates.longitude ?? null;
    } else if (body.latitude !== undefined && body.longitude !== undefined) {
      lat = Number(body.latitude);
      lng = Number(body.longitude);
    }

    const report = await reportRepository.create({
      userId,
      kind: 'FOUND',
      name: body.name || 'Found Child',
      age: body.estimatedAge ? parseInt(body.estimatedAge, 10) : null,
      gender: body.gender ? String(body.gender).toUpperCase() : null,
      occurrenceDate: body.foundSince || body.occurrence_date || null,
      latitude: lat,
      longitude: lng,
      description: body.description || body.clothing || null,
    });

    return reply.status(201).send({ success: true, data: report });
  });

  // 9. POST /sightings
  fastify.post('/sightings', { preHandler: [optionalAuth] }, async (request, reply) => {
    const body = request.body as Record<string, any>;
    const caseId = parseInt(body.caseId || body.case_id || body.report_id, 10);
    if (!caseId) {
      throw new ValidationError('caseId is required for sighting submission.');
    }

    const report = await reportRepository.findById(caseId);
    if (!report) {
      throw new NotFoundError('Report case not found.');
    }

    const userId = request.currentUser?.user_id || 1;
    const locationInfo =
      body.latitude && body.longitude
        ? `[Sighting at coordinates (${body.latitude}, ${body.longitude})] `
        : '';
    const content = `${locationInfo}${body.description || 'Reported a sighting'}${
      body.notes ? ` - Notes: ${body.notes}` : ''
    }`;

    const comment = await commentRepository.create(caseId, userId, content);

    return reply.status(201).send({
      success: true,
      data: {
        sightingId: comment.comment_id,
        caseId,
        content,
        addedAt: comment.added_at,
      },
    });
  });

  // 10. GET /locations/governorates
  fastify.get('/locations/governorates', async (_request, reply) => {
    const list = await locationRepository.getGovernoratesWithCities();
    return reply.send({ success: true, data: list });
  });

  // 11. POST /auth/register (Mobile alias for signup)
  fastify.post('/auth/register', async (request, reply) => {
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

  // 12. GET /auth/me (Mobile alias for /me)
  fastify.get('/auth/me', { preHandler: [authenticate] }, async (request, reply) => {
    return reply.send({
      success: true,
      data: request.currentUser,
    });
  });

  // 13. PATCH /auth/profile (Mobile alias for updating profile)
  fastify.patch('/auth/profile', { preHandler: [authenticate] }, async (request, reply) => {
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

  // 14. GET /me/findings (User's reported found cases)
  fastify.get('/me/findings', { preHandler: [authenticate] }, async (request, reply) => {
    const all = await reportRepository.findByUserId(request.currentUser!.user_id);
    const findings = all.filter((r) => r.kind === 'Found');
    return reply.send({ success: true, data: findings });
  });

  // 15. GET /me/sightings (Sightings reported by user)
  fastify.get('/me/sightings', { preHandler: [authenticate] }, async (request, reply) => {
    const all = await reportRepository.findByUserId(request.currentUser!.user_id);
    return reply.send({ success: true, data: all });
  });
};
