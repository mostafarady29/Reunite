import { FastifyPluginAsync } from 'fastify';
import { agentMemoryService } from '../services/agent-memory.service.js';
import { reportRepository } from '../repositories/report.repository.js';
import { ValidationError } from '../core/errors/app-error.js';

export const searchRoutes: FastifyPluginAsync = async (fastify) => {
  // 1. POST search/photo (Visual face similarity search with agent memory)
  const searchPhotoHandler = async (request: any, reply: any) => {
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
  };
  fastify.post('/api/search/photo', searchPhotoHandler);
  fastify.post('/search/photo', searchPhotoHandler);

  // 2. GET search/reports (Full-text query search for open reports)
  const searchReportsHandler = async (request: any, reply: any) => {
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
  };
  fastify.get('/api/search/reports', searchReportsHandler);
  fastify.get('/search/reports', searchReportsHandler);

  // 3. POST embeddings (Generate raw embedding vector)
  const embeddingsHandler = async (request: any, reply: any) => {
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
  };
  fastify.post('/api/embeddings', embeddingsHandler);
  fastify.post('/embeddings', embeddingsHandler);

  // 4. POST embeddings/store (Store embedding directly)
  const embeddingsStoreHandler = async (request: any, reply: any) => {
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
  };
  fastify.post('/api/embeddings/store', embeddingsStoreHandler);
  fastify.post('/embeddings/store', embeddingsStoreHandler);

  // 5. POST embeddings/search (Vector similarity search endpoint)
  const embeddingsSearchHandler = async (request: any, reply: any) => {
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
  };
  fastify.post('/api/embeddings/search', embeddingsSearchHandler);
  fastify.post('/embeddings/search', embeddingsSearchHandler);
};
