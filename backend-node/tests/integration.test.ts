import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { FastifyInstance } from 'fastify';
import { buildApp } from '../src/app.js';
import { closePool } from '../src/core/database/pool.js';

describe('Unified Backend Connectivity & API Integration Tests', () => {
  let app: FastifyInstance;
  let testPhone: string;
  let authToken: string;
  let testReportId: number;

  beforeAll(async () => {
    app = await buildApp();
    await app.ready();
    testPhone = `+2010${Math.floor(10000000 + Math.random() * 90000000)}`;
  });

  afterAll(async () => {
    await app.close();
    await closePool();
  });

  // 1. Health & Dependency Readiness
  it('GET /api/health returns service status ok', async () => {
    const res = await app.inject({
      method: 'GET',
      url: '/api/health',
    });
    expect(res.statusCode).toBe(200);
    const body = res.json();
    expect(body.success).toBe(true);
    expect(body.data.status).toBe('ok');
    expect(body.data.service).toBe('reunite-node');
  });

  it('GET /api/ready checks database connectivity', async () => {
    const res = await app.inject({
      method: 'GET',
      url: '/api/ready',
    });
    expect(res.statusCode).toBe(200);
    const body = res.json();
    expect(body.success).toBe(true);
    expect(body.data.database).toBe(true);
  });

  // 2. Location Services (Web & Mobile formats)
  it('GET /api/governorates returns 27 Egyptian governorates for Web Frontend', async () => {
    const res = await app.inject({
      method: 'GET',
      url: '/api/governorates',
    });
    expect(res.statusCode).toBe(200);
    const body = res.json();
    expect(body.success).toBe(true);
    expect(Array.isArray(body.data)).toBe(true);
    expect(body.data.length).toBe(27);
    expect(body.data.some((g: any) => g.name === 'Cairo')).toBe(true);
  });

  it('GET /api/governorates/1/cities returns cities for Cairo', async () => {
    const res = await app.inject({
      method: 'GET',
      url: '/api/governorates/1/cities',
    });
    expect(res.statusCode).toBe(200);
    const body = res.json();
    expect(body.success).toBe(true);
    expect(Array.isArray(body.data)).toBe(true);
    expect(body.data.length).toBeGreaterThan(0);
  });

  it('GET /api/locations/governorates returns governorates with nested cities for Flutter Mobile', async () => {
    const res = await app.inject({
      method: 'GET',
      url: '/api/locations/governorates',
    });
    expect(res.statusCode).toBe(200);
    const body = res.json();
    expect(body.success).toBe(true);
    expect(Array.isArray(body.data)).toBe(true);
    const cairo = body.data.find((g: any) => g.name === 'Cairo');
    expect(cairo).toBeDefined();
    expect(Array.isArray(cairo.cities)).toBe(true);
    expect(cairo.cities.length).toBeGreaterThan(0);
  });

  // 3. Root Path Aliasing (Mobile compatibility when baseUrl lacks /api)
  it('GET /locations/governorates rewrites to /api/locations/governorates seamlessly', async () => {
    const res = await app.inject({
      method: 'GET',
      url: '/locations/governorates',
    });
    expect(res.statusCode).toBe(200);
    const body = res.json();
    expect(body.success).toBe(true);
    expect(body.data.length).toBe(27);
  });

  // 4. Authentication (Dual Web Cookie + Mobile Bearer Token)
  it('POST /api/auth/register registers a new member and returns JWT token & cookie', async () => {
    const res = await app.inject({
      method: 'POST',
      url: '/api/auth/register',
      payload: {
        name: 'Test Volunteer',
        phone: testPhone,
        password: 'SecurePassword123!',
        city_id: 1,
        governorate_id: 1,
      },
    });

    expect(res.statusCode).toBe(201);
    const body = res.json();
    expect(body.success).toBe(true);
    expect(body.data.user.phone).toBe(testPhone);
    expect(body.data.token).toBeDefined();
    authToken = body.data.token;

    // Verify auth cookie is set for Web
    const setCookie = res.headers['set-cookie'];
    expect(setCookie).toBeDefined();
  });

  it('GET /api/auth/me authenticates via Mobile Bearer token', async () => {
    const res = await app.inject({
      method: 'GET',
      url: '/api/auth/me',
      headers: {
        Authorization: `Bearer ${authToken}`,
      },
    });

    expect(res.statusCode).toBe(200);
    const body = res.json();
    expect(body.success).toBe(true);
    expect(body.data.phone).toBe(testPhone);
  });

  it('GET /api/me authenticates via Bearer token (Web Frontend endpoint)', async () => {
    const res = await app.inject({
      method: 'GET',
      url: '/api/me',
      headers: {
        Authorization: `Bearer ${authToken}`,
      },
    });

    expect(res.statusCode).toBe(200);
    const body = res.json();
    expect(body.success).toBe(true);
    expect(body.data.name).toBe('Test Volunteer');
  });

  // 5. Case & Sighting Lifecycle
  it('POST /api/cases/missing creates a new missing person report', async () => {
    const res = await app.inject({
      method: 'POST',
      url: '/api/cases/missing',
      headers: {
        Authorization: `Bearer ${authToken}`,
      },
      payload: {
        name: 'Youssef Ahmed',
        age: 8,
        gender: 'MALE',
        missingSince: new Date().toISOString(),
        coordinates: {
          lat: 30.0444,
          lng: 31.2357,
        },
        description: 'Wearing blue jacket and black trousers',
      },
    });

    expect(res.statusCode).toBe(201);
    const body = res.json();
    expect(body.success).toBe(true);
    expect(body.data.name).toBe('Youssef Ahmed');
    expect(body.data.kind).toBe('Missing');
    expect(body.data.status).toBe('Open');
    testReportId = body.data.report_id;
  });

  it('GET /api/cases/:id retrieves report details with coordinates and metadata', async () => {
    const res = await app.inject({
      method: 'GET',
      url: `/api/cases/${testReportId}`,
    });

    expect(res.statusCode).toBe(200);
    const body = res.json();
    expect(body.success).toBe(true);
    expect(body.data.report_id).toBe(testReportId);
    expect(body.data.latitude).toBeCloseTo(30.0444, 4);
    expect(body.data.longitude).toBeCloseTo(31.2357, 4);
  });

  it('POST /api/sightings submits a community sighting linked to the case', async () => {
    const res = await app.inject({
      method: 'POST',
      url: '/api/sightings',
      headers: {
        Authorization: `Bearer ${authToken}`,
      },
      payload: {
        caseId: testReportId,
        latitude: 30.05,
        longitude: 31.24,
        description: 'Spotted near metro station',
        notes: 'Accompanied by an elderly woman',
      },
    });

    expect(res.statusCode).toBe(201);
    const body = res.json();
    expect(body.success).toBe(true);
    expect(Number(body.data.caseId)).toBe(Number(testReportId));
    expect(body.data.content).toContain('Spotted near metro station');
  });

  it('GET /api/cases/nearby finds open cases within radius', async () => {
    const res = await app.inject({
      method: 'GET',
      url: '/api/cases/nearby?lat=30.0444&lng=31.2357&radius=15000',
    });

    expect(res.statusCode).toBe(200);
    const body = res.json();
    expect(body.success).toBe(true);
    expect(Array.isArray(body.data)).toBe(true);
    expect(body.data.some((c: any) => c.report_id === testReportId)).toBe(true);
  });

  it('GET /api/cases/statistics returns platform-wide metrics', async () => {
    const res = await app.inject({
      method: 'GET',
      url: '/api/cases/statistics',
    });

    expect(res.statusCode).toBe(200);
    const body = res.json();
    expect(body.success).toBe(true);
    expect(body.data.activeCases).toBeGreaterThan(0);
    expect(body.data.reportsToday).toBeGreaterThan(0);
  });
});
