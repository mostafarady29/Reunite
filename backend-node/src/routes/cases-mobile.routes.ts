import crypto from 'crypto';
import { FastifyPluginAsync } from 'fastify';
import { reportRepository } from '../repositories/report.repository.js';
import { photoRepository } from '../repositories/photo.repository.js';
import { storageService } from '../core/storage/supabase-storage.js';
import { locationRepository } from '../repositories/location.repository.js';
import { commentRepository } from '../repositories/comment.repository.js';
import { userRepository } from '../repositories/user.repository.js';
import { agentMemoryService } from '../services/agent-memory.service.js';
import { notificationRepository } from '../repositories/notification.repository.js';
import { fcmService } from '../services/fcm.service.js';
import { authenticate, optionalAuth } from '../middlewares/auth.middleware.js';
import { NotFoundError, ValidationError } from '../core/errors/app-error.js';

async function attachPhotoIfProvided(reportId: number, photoData?: any) {
  if (!photoData || typeof photoData !== 'string' || !photoData.startsWith('data:image')) {
    return;
  }
  try {
    const commaIdx = photoData.indexOf(',');
    const base64Str = commaIdx !== -1 ? photoData.substring(commaIdx + 1) : photoData;
    const buffer = Buffer.from(base64Str, 'base64');
    const mimeMatch = photoData.match(/^data:(image\/[a-zA-Z0-9+.-]+);base64/);
    const mime = mimeMatch ? mimeMatch[1] : 'image/jpeg';
    const ext = mime === 'image/png' ? '.png' : mime === 'image/webp' ? '.webp' : '.jpg';
    const storagePath = `reports/${reportId}/${crypto.randomUUID()}${ext}`;

    if (storageService.isConfigured()) {
      const uploaded = await storageService.uploadObject(storagePath, buffer, mime);
      if (uploaded) {
        const photo = await photoRepository.create(reportId, storagePath);
        agentMemoryService
          .extractEmbeddingFromImage(buffer, `photo${ext}`)
          .then((vector) => agentMemoryService.upsertEmbedding(photo.photo_id, vector))
          .catch((err) => console.warn('Embedding extraction deferred:', err));
      }
    }
  } catch (err) {
    console.error('Failed to attach case photo:', err);
  }
}

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

    await attachPhotoIfProvided(report.report_id, body.photo || body.photoSeed);
    const fullReport = await reportRepository.findById(report.report_id);

    // Send FCM push broadcast for emergency missing child
    fcmService
      .sendBroadcast({
        type: 'emergency',
        title: 'تنبيه طفل مفقود عاجل',
        body: `تم الإبلاغ عن اختفاء طفل: ${body.name || 'طفل مجهول'}`,
        caseId: String(report.report_id),
        data: {
          caseId: String(report.report_id),
        },
      })
      .catch((err) => request.log.error(err, 'Failed to send missing case FCM broadcast'));

    return reply.status(201).send({ success: true, data: fullReport || report });
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

    await attachPhotoIfProvided(report.report_id, body.photo || body.photoSeed);
    const fullReport = await reportRepository.findById(report.report_id);

    return reply.status(201).send({ success: true, data: fullReport || report });
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

    // Notify report owner if another user reports a sighting
    if (report.user_id && report.user_id !== userId) {
      fcmService
        .sendToUser(report.user_id, {
          type: 'sighting',
          title: 'مشاهدة جديدة بخصوص بلاغك',
          body: `تم الإبلاغ عن مشاهدة جديدة للطفل: ${report.name}`,
          caseId: String(caseId),
          data: {
            caseId: String(caseId),
          },
        })
        .catch((err) => request.log.error(err, 'Failed to send sighting notification to report owner'));
    }

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


  // 20. GET /me/findings (User's reported found cases)
  fastify.get('/me/findings', { preHandler: [optionalAuth] }, async (request, reply) => {
    if (!request.currentUser) {
      return reply.send({ success: true, data: [] });
    }
    const all = await reportRepository.findByUserId(request.currentUser.user_id);
    const findings = all.filter((r) => r.kind === 'Found');
    return reply.send({ success: true, data: findings });
  });

  // 21. GET /me/sightings (Sightings reported by user)
  fastify.get('/me/sightings', { preHandler: [optionalAuth] }, async (request, reply) => {
    if (!request.currentUser) {
      return reply.send({ success: true, data: [] });
    }
    const all = await reportRepository.findByUserId(request.currentUser.user_id);
    return reply.send({ success: true, data: all });
  });

  // 22. POST /notifications/device-token (Register FCM device token)
  fastify.post('/notifications/device-token', { preHandler: [optionalAuth] }, async (request, reply) => {
    const body = request.body as { token?: string; platform?: string };
    if (!body?.token) {
      throw new ValidationError('Device token is required.');
    }
    const userId = request.currentUser ? request.currentUser.user_id : null;
    await notificationRepository.saveDeviceToken(userId, body.token, body.platform || 'android');
    return reply.send({ success: true, message: 'Device token registered successfully.' });
  });

  // 23. GET /notifications (Mobile notifications feed)
  fastify.get('/notifications', { preHandler: [optionalAuth] }, async (request, reply) => {
    if (!request.currentUser) {
      return reply.send({ success: true, data: [] });
    }
    const records = await notificationRepository.getNotificationsByUserId(
      request.currentUser.user_id
    );
    const data = records.map((r) => ({
      id: String(r.notification_id),
      type: r.type,
      titleKey: r.title,
      title: r.title,
      bodyKey: r.body,
      body: r.body,
      createdAt: r.created_at,
      caseId: r.case_id ? String(r.case_id) : null,
      namedArgs: r.metadata || {},
      read: r.is_read,
    }));
    return reply.send({ success: true, data });
  });

  // 24. POST /notifications/read-all (Mark notifications read)
  fastify.post('/notifications/read-all', { preHandler: [optionalAuth] }, async (request, reply) => {
    if (request.currentUser) {
      await notificationRepository.markAllRead(request.currentUser.user_id);
    }
    return reply.send({
      success: true,
      data: { message: 'All notifications marked as read.' },
    });
  });
};
