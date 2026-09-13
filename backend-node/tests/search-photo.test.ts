import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { FastifyInstance } from 'fastify';
import { buildApp } from '../src/app.js';
import { closePool } from '../src/core/database/pool.js';
import { agentMemoryService } from '../src/services/agent-memory.service.js';
import { photoRepository } from '../src/repositories/photo.repository.js';
import { reportRepository } from '../src/repositories/report.repository.js';

describe('Photo Visual Search & Agent Memory End-to-End', () => {
  let app: FastifyInstance;
  let missingReportId: number;
  let foundReportId: number;
  let missingPhotoId: number;
  let foundPhotoId: number;

  beforeAll(async () => {
    app = await buildApp();
    await app.ready();

    // Create a Missing report
    const missing = await reportRepository.create({
      userId: 1,
      kind: 'MISSING',
      name: 'Mariam Khaled',
      age: 7,
      gender: 'FEMALE',
      occurrenceDate: new Date().toISOString(),
      latitude: 30.0444,
      longitude: 31.2357,
      description: 'Missing girl in Cairo',
    });
    missingReportId = missing.report_id;

    // Create a Found report
    const found = await reportRepository.create({
      userId: 1,
      kind: 'FOUND',
      name: 'Unknown Young Girl',
      age: 7,
      gender: 'FEMALE',
      occurrenceDate: new Date().toISOString(),
      latitude: 30.05,
      longitude: 31.24,
      description: 'Found girl near Tahrir Square',
    });
    foundReportId = found.report_id;

    // Create photo records
    const p1 = await photoRepository.create(missingReportId, 'reports/missing/mariam.jpg');
    missingPhotoId = p1.photo_id;

    const p2 = await photoRepository.create(foundReportId, 'reports/found/girl.jpg');
    foundPhotoId = p2.photo_id;

    // Generate deterministic vectors: high similarity between the two
    const baseVector = agentMemoryService.generateMockEmbedding(Buffer.from('mariam-identity-seed'));
    await agentMemoryService.upsertEmbedding(missingPhotoId, baseVector);

    // Slightly perturbed vector for found child (representing same person from another angle)
    const perturbed = baseVector.map((v, i) => (i % 20 === 0 ? v + 0.05 : v));
    const norm = Math.sqrt(perturbed.reduce((sum, v) => sum + v * v, 0));
    const normalizedPerturbed = perturbed.map((v) => v / norm);
    await agentMemoryService.upsertEmbedding(foundPhotoId, normalizedPerturbed);
  });

  afterAll(async () => {
    // Cleanup reports
    await reportRepository.deleteWithCascade(missingReportId);
    await reportRepository.deleteWithCascade(foundReportId);
    await app.close();
    await closePool();
  });

  it('GET /api/cases/:id/matches returns matched found case with high similarity score', async () => {
    const res = await app.inject({
      method: 'GET',
      url: `/api/cases/${missingReportId}/matches`,
    });

    expect(res.statusCode).toBe(200);
    const body = res.json();
    expect(body.success).toBe(true);
    expect(Array.isArray(body.data)).toBe(true);
    expect(body.data.length).toBeGreaterThan(0);

    const match = body.data.find((m: any) => m.foundCase.report_id === foundReportId);
    expect(match).toBeDefined();
    expect(match.matchPercent).toBeGreaterThan(80); // High facial similarity
    expect(match.distanceMeters).toBeGreaterThan(0); // Near distance computed
    expect(match.timeGapHours).toBeDefined();
  });

  it('POST /api/search/photo performs visual face similarity search from uploaded image', async () => {
    const boundary = '----WebKitFormBoundaryTest123';
    const fakeImageBuffer = Buffer.from('mariam-identity-seed');
    
    const body = [
      `--${boundary}`,
      'Content-Disposition: form-data; name="file"; filename="search_query.jpg"',
      'Content-Type: image/jpeg',
      '',
      fakeImageBuffer.toString('binary'),
      `--${boundary}--`,
    ].join('\r\n');

    const res = await app.inject({
      method: 'POST',
      url: '/api/search/photo',
      headers: {
        'content-type': `multipart/form-data; boundary=${boundary}`,
      },
      payload: Buffer.from(body, 'binary'),
    });

    expect(res.statusCode).toBe(200);
    const result = res.json();
    expect(result.success).toBe(true);
    expect(Array.isArray(result.data)).toBe(true);
    expect(result.data.length).toBeGreaterThan(0);

    const firstMatch = result.data[0];
    expect(firstMatch.report).toBeDefined();
    expect(firstMatch.similarity).toBeGreaterThan(0.38);
    expect(firstMatch.composite_score).toBeDefined();
  });
});
