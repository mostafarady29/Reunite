import crypto from 'crypto';
import path from 'path';
import { FastifyPluginAsync } from 'fastify';
import {
  reportBodySchema,
  commentBodySchema,
  reportQuerySchema,
  validateSchema,
} from '../validators/schemas.js';
import { reportRepository } from '../repositories/report.repository.js';
import { photoRepository } from '../repositories/photo.repository.js';
import { commentRepository } from '../repositories/comment.repository.js';
import { storageService } from '../core/storage/supabase-storage.js';
import { agentMemoryService } from '../services/agent-memory.service.js';
import { authenticate, requireAdmin } from '../middlewares/auth.middleware.js';
import {
  NotFoundError,
  ForbiddenError,
  ValidationError,
  PayloadTooLargeError,
  ServiceUnavailableError,
} from '../core/errors/app-error.js';

export const reportRoutes: FastifyPluginAsync = async (fastify) => {
  // GET /api/reports (Public / Member discovery)
  fastify.get('/api/reports', async (request, reply) => {
    const query = validateSchema(reportQuerySchema, request.query);
    const data = await reportRepository.findPaginated(query);
    return reply.send({ success: true, data });
  });

  // POST /api/reports
  fastify.post('/api/reports', { preHandler: [authenticate] }, async (request, reply) => {
    const body = validateSchema(reportBodySchema, request.body);
    const userId = request.currentUser!.user_id;

    const report = await reportRepository.create({
      userId,
      kind: body.kind,
      name: body.name,
      age: body.age,
      gender: body.gender,
      occurrenceDate: body.occurrence_date,
      latitude: body.latitude,
      longitude: body.longitude,
      description: body.description,
    });

    return reply.status(201).send({ success: true, data: report });
  });

  // GET /api/reports/:id
  fastify.get<{ Params: { id: string } }>(
    '/api/reports/:id',
    { preHandler: [authenticate] },
    async (request, reply) => {
      const reportId = parseInt(request.params.id, 10);
      const report = await reportRepository.findById(reportId);
      if (!report) {
        throw new NotFoundError('Report not found.');
      }
      return reply.send({ success: true, data: report });
    }
  );

  // PATCH /api/reports/:id
  fastify.patch<{ Params: { id: string } }>(
    '/api/reports/:id',
    { preHandler: [authenticate] },
    async (request, reply) => {
      const reportId = parseInt(request.params.id, 10);
      const existing = await reportRepository.findById(reportId);
      if (!existing) {
        throw new NotFoundError('Report not found.');
      }

      const user = request.currentUser!;
      if (String(existing.user_id) !== String(user.user_id) && !user.role) {
        throw new ForbiddenError('You cannot modify this report.');
      }

      const body = validateSchema(reportBodySchema, request.body);
      const updated = await reportRepository.update(reportId, {
        kind: body.kind,
        name: body.name,
        age: body.age,
        gender: body.gender,
        occurrenceDate: body.occurrence_date,
        latitude: body.latitude,
        longitude: body.longitude,
        description: body.description,
      });

      return reply.send({ success: true, data: updated });
    }
  );

  // POST /api/reports/:id/close
  fastify.post<{ Params: { id: string } }>(
    '/api/reports/:id/close',
    { preHandler: [authenticate] },
    async (request, reply) => {
      const reportId = parseInt(request.params.id, 10);
      const existing = await reportRepository.findById(reportId);
      if (!existing) {
        throw new NotFoundError('Report not found.');
      }

      const user = request.currentUser!;
      if (String(existing.user_id) !== String(user.user_id) && !user.role) {
        throw new ForbiddenError('You cannot close this report.');
      }

      const closed = await reportRepository.close(reportId);
      return reply.send({ success: true, data: closed });
    }
  );

  // DELETE /api/reports/:id (Admin only)
  fastify.delete<{ Params: { id: string } }>(
    '/api/reports/:id',
    { preHandler: [requireAdmin] },
    async (request, reply) => {
      const reportId = parseInt(request.params.id, 10);
      const existing = await reportRepository.findById(reportId);
      if (!existing) {
        throw new NotFoundError('Report not found.');
      }

      const deletedPaths = await reportRepository.deleteWithCascade(reportId);
      // Clean up photos from Supabase Storage asynchronously
      for (const storagePath of deletedPaths) {
        storageService.deleteObject(storagePath).catch(console.error);
      }

      return reply.send({ success: true, data: { deleted: true } });
    }
  );

  // POST /api/reports/:id/photos (Upload report photo)
  fastify.post<{ Params: { id: string } }>(
    '/api/reports/:id/photos',
    { preHandler: [authenticate] },
    async (request, reply) => {
      const reportId = parseInt(request.params.id, 10);
      const report = await reportRepository.findById(reportId);
      if (!report) {
        throw new NotFoundError('Report not found.');
      }

      const user = request.currentUser!;
      if (String(report.user_id) !== String(user.user_id) && !user.role) {
        throw new ForbiddenError('You cannot add photos to this report.');
      }

      const file = await request.file();
      if (!file) {
        throw new ValidationError('An image file is required.');
      }

      const allowedMimes = ['image/jpeg', 'image/png', 'image/webp'];
      if (!allowedMimes.includes(file.mimetype)) {
        throw new ValidationError('Only JPEG, PNG, or WebP images are allowed.');
      }

      const buffer = await file.toBuffer();
      if (buffer.length > 10 * 1024 * 1024) {
        throw new PayloadTooLargeError('Image is too large (max 10MB).');
      }

      const ext = path.extname(file.filename || '.jpg').toLowerCase() || '.jpg';
      const storagePath = `reports/${reportId}/${crypto.randomUUID()}${ext}`;

      if (!storageService.isConfigured()) {
        throw new ServiceUnavailableError('Image storage is not configured.');
      }

      const uploaded = await storageService.uploadObject(storagePath, buffer, file.mimetype);
      if (!uploaded) {
        throw new ServiceUnavailableError('Image storage is unavailable.');
      }

      const photo = await photoRepository.create(reportId, storagePath);
      const signedUrl = await storageService.getSignedImageUrl(storagePath);

      // Extract and save face embedding asynchronously into semantic agent memory
      let embeddingStatus = 'not_generated';
      try {
        const vector = await agentMemoryService.extractEmbeddingFromImage(buffer, file.filename);
        await agentMemoryService.upsertEmbedding(photo.photo_id, vector);
        embeddingStatus = 'stored';
      } catch (err) {
        console.warn('Embedding generation deferred or failed:', err);
        embeddingStatus = 'failed';
      }

      return reply.status(201).send({
        success: true,
        data: {
          ...photo,
          url: signedUrl,
          embedding_status: embeddingStatus,
        },
      });
    }
  );

  // DELETE /api/photos/:id
  fastify.delete<{ Params: { id: string } }>(
    '/api/photos/:id',
    { preHandler: [authenticate] },
    async (request, reply) => {
      const photoId = parseInt(request.params.id, 10);
      const photo = await photoRepository.findById(photoId);
      if (!photo) {
        throw new NotFoundError('Photo not found.');
      }

      const user = request.currentUser!;
      if (String(photo.user_id) !== String(user.user_id) && !user.role) {
        throw new ForbiddenError('You cannot delete this photo.');
      }

      await photoRepository.deleteById(photoId);
      storageService.deleteObject(photo.path).catch(console.error);

      return reply.send({ success: true, data: { deleted: true } });
    }
  );

  // GET /api/reports/:id/comments
  fastify.get<{ Params: { id: string } }>(
    '/api/reports/:id/comments',
    { preHandler: [authenticate] },
    async (request, reply) => {
      const reportId = parseInt(request.params.id, 10);
      const comments = await commentRepository.findByReportId(reportId);
      return reply.send({ success: true, data: comments });
    }
  );

  // POST /api/reports/:id/comments
  fastify.post<{ Params: { id: string } }>(
    '/api/reports/:id/comments',
    { preHandler: [authenticate] },
    async (request, reply) => {
      const reportId = parseInt(request.params.id, 10);
      const report = await reportRepository.findById(reportId);
      if (!report) {
        throw new NotFoundError('Report not found.');
      }

      const body = validateSchema(commentBodySchema, request.body);
      const user = request.currentUser!;

      const comment = await commentRepository.create(reportId, user.user_id, body.content);

      return reply.status(201).send({
        success: true,
        data: {
          ...comment,
          author_name: user.name,
          author_phone: user.phone,
        },
      });
    }
  );
};
