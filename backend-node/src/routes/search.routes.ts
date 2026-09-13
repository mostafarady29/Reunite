import { FastifyPluginAsync } from 'fastify';
import { agentMemoryService } from '../services/agent-memory.service.js';
import { reportRepository } from '../repositories/report.repository.js';
import { ValidationError } from '../core/errors/app-error.js';

export const searchRoutes: FastifyPluginAsync = async (fastify) => {
  // POST /api/search/photo (Visual face similarity search with agent memory)
  fastify.post('/api/search/photo', async (request, reply) => {
    const file = await request.file();
    if (!file) {
      throw new ValidationError('An image file is required.');
    }

    const allowedMimes = ['image/jpeg', 'image/png', 'image/webp'];
    if (!allowedMimes.includes(file.mimetype)) {
      throw new ValidationError('Only image files (JPEG, PNG, WebP) are allowed.');
    }

    const buffer = await file.toBuffer();
    const queryEmbedding = await agentMemoryService.extractEmbeddingFromImage(buffer, file.filename);

    const matches = await agentMemoryService.searchSimilarMemories(queryEmbedding, {
      limit: 5,
      threshold: 0.38,
      status: 'OPEN',
      applyRecencyDecay: true, // Agent Memory temporal decay scoring
    });

    const results = [];
    for (const match of matches) {
      const report = await reportRepository.findById(match.metadata.report_id);
      if (report && report.status === 'Open') {
        results.push({
          report,
          similarity: match.similarity,
          composite_score: match.composite_score,
          recency_score: match.recency_score,
        });
      }
    }

    return reply.send({
      success: true,
      data: results,
    });
  });

  // GET /api/search/reports (Full-text query search for open reports)
  fastify.get<{ Querystring: { search?: string; kind?: string } }>(
    '/api/search/reports',
    async (request, reply) => {
      const search = request.query.search || '';
      const kind = request.query.kind || null;

      const data = await reportRepository.findPaginated({
        search,
        kind,
        status: 'Open',
        page: 1,
        limit: 50,
      });

      return reply.send(data);
    }
  );

  // POST /api/embeddings (Generate raw embedding vector)
  fastify.post('/api/embeddings', async (request, reply) => {
    const file = await request.file();
    if (!file) {
      throw new ValidationError('An image file is required.');
    }

    const buffer = await file.toBuffer();
    const embedding = await agentMemoryService.extractEmbeddingFromImage(buffer, file.filename);

    return reply.send({
      success: true,
      data: {
        dimension: embedding.length,
        embedding,
      },
    });
  });

  // POST /api/embeddings/store (Store embedding directly)
  fastify.post('/api/embeddings/store', async (request, reply) => {
    const parts = request.parts();
    let recordId: string | undefined;
    let imageBuffer: Buffer | undefined;
    let filename = 'image.jpg';

    for await (const part of parts) {
      if (part.type === 'file' && part.fieldname === 'image') {
        imageBuffer = await part.toBuffer();
        filename = part.filename;
      } else if (part.type === 'field' && part.fieldname === 'record_id') {
        recordId = String(part.value);
      }
    }

    if (!recordId || !imageBuffer) {
      throw new ValidationError('Both record_id and image file are required.');
    }

    const embedding = await agentMemoryService.extractEmbeddingFromImage(imageBuffer, filename);
    await agentMemoryService.upsertEmbedding(recordId, embedding);

    return reply.send({
      success: true,
      data: {
        record_id: recordId,
        dimension: embedding.length,
        stored: true,
      },
    });
  });

  // POST /api/embeddings/search (Vector similarity search endpoint)
  fastify.post('/api/embeddings/search', async (request, reply) => {
    const parts = request.parts();
    let imageBuffer: Buffer | undefined;
    let filename = 'image.jpg';
    let limit = 5;
    let threshold = 0.38;

    for await (const part of parts) {
      if (part.type === 'file' && part.fieldname === 'image') {
        imageBuffer = await part.toBuffer();
        filename = part.filename;
      } else if (part.type === 'field') {
        if (part.fieldname === 'limit') limit = parseInt(String(part.value), 10) || 5;
        if (part.fieldname === 'threshold') threshold = parseFloat(String(part.value)) || 0.38;
      }
    }

    if (!imageBuffer) {
      throw new ValidationError('An image file is required.');
    }

    const embedding = await agentMemoryService.extractEmbeddingFromImage(imageBuffer, filename);
    const matches = await agentMemoryService.searchSimilarMemories(embedding, {
      limit,
      threshold,
      status: 'OPEN',
    });

    return reply.send({
      success: true,
      data: { matches },
    });
  });
};
