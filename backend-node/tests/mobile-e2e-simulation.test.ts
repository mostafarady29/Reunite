import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { FastifyInstance } from 'fastify';
import { buildApp } from '../src/app.js';
import { closePool } from '../src/core/database/pool.js';

describe('Flutter Mobile Complete E2E Integration Simulation', () => {
  let app: FastifyInstance;
  const mobilePhone = `+2012${Math.floor(10000000 + Math.random() * 90000000)}`;
  const mobilePassword = 'FlutterSecret123!';
  let authToken = '';
  let userId = '';
  let createdCaseId = 0;

  beforeAll(async () => {
    app = await buildApp();
    await app.ready();
  });

  afterAll(async () => {
    await app.close();
    await closePool();
  });

  it('Step 1: Flutter loads governorates and cities for dropdowns', async () => {
    const res = await app.inject({
      method: 'GET',
      url: '/locations/governorates',
    });
    expect(res.statusCode).toBe(200);
    const body = res.json();
    expect(body.success).toBe(true);
    expect(body.data.length).toBe(27);
    const cairo = body.data.find((g: any) => g.name === 'Cairo');
    expect(cairo).toBeDefined();
    expect(cairo.cities.length).toBeGreaterThan(0);
  });

  it('Step 2: Flutter registers a new user with mobile form payload', async () => {
    const res = await app.inject({
      method: 'POST',
      url: '/auth/register',
      payload: {
        fullName: 'أحمد محمود',
        name: 'أحمد محمود',
        phone: mobilePhone,
        password: mobilePassword,
        city: 'Nasr City',
      },
    });
    expect(res.statusCode).toBe(201);
    const body = res.json();
    expect(body.success).toBe(true);
    expect(body.data.token).toBeDefined();
    expect(body.data.user.id).toBeDefined();
    expect(body.data.user.fullName).toBe('أحمد محمود');
    authToken = body.data.token;
    userId = String(body.data.user.id);
  });

  it('Step 3: Flutter verifies OTP', async () => {
    const res = await app.inject({
      method: 'POST',
      url: '/auth/verify-otp',
      payload: { code: '654321' },
    });
    expect(res.statusCode).toBe(200);
    const body = res.json();
    expect(body.success).toBe(true);
  });

  it('Step 4: Flutter logs in using identifier & password', async () => {
    const res = await app.inject({
      method: 'POST',
      url: '/auth/login',
      payload: {
        identifier: mobilePhone,
        password: mobilePassword,
      },
    });
    expect(res.statusCode).toBe(200);
    const body = res.json();
    expect(body.success).toBe(true);
    expect(body.data.token).toBeDefined();
    authToken = body.data.token;
  });

  it('Step 5: Flutter fetches current user profile via Bearer token', async () => {
    const res = await app.inject({
      method: 'GET',
      url: '/auth/me',
      headers: {
        authorization: `Bearer ${authToken}`,
      },
    });
    expect(res.statusCode).toBe(200);
    const body = res.json();
    expect(body.success).toBe(true);
    expect(String(body.data.id)).toBe(userId);
  });

  it('Step 6: Flutter fetches home screen statistics', async () => {
    const res = await app.inject({
      method: 'GET',
      url: '/cases/statistics',
    });
    expect(res.statusCode).toBe(200);
    const body = res.json();
    expect(body.success).toBe(true);
    expect(body.data.activeCases).toBeDefined();
  });

  it('Step 7: Flutter submits a new missing child report', async () => {
    const res = await app.inject({
      method: 'POST',
      url: '/cases/missing',
      headers: {
        authorization: `Bearer ${authToken}`,
      },
      payload: {
        name: 'يوسف حسام',
        age: 7,
        gender: 'male',
        missingSince: new Date().toISOString(),
        lastKnownLocation: 'مدينة نصر - بالقرب من سيتي ستارز',
        city: 'القاهرة',
        clothing: 'تيشيرت أزرق وبنطلون جينز',
        description: 'طفل يرتدي نظارة طبية',
        coordinates: { lat: 30.0731, lng: 31.3456 },
      },
    });
    expect(res.statusCode).toBe(201);
    const body = res.json();
    expect(body.success).toBe(true);
    expect(body.data.report_id).toBeDefined();
    createdCaseId = body.data.report_id;
  });

  it('Step 8: Flutter views child case details by ID', async () => {
    const res = await app.inject({
      method: 'GET',
      url: `/cases/${createdCaseId}`,
    });
    expect(res.statusCode).toBe(200);
    const body = res.json();
    expect(body.success).toBe(true);
    expect(body.data.name).toBe('يوسف حسام');
    expect(body.data.latitude).toBeCloseTo(30.0731);
  });

  it('Step 9: Flutter reports a community sighting for the child', async () => {
    const res = await app.inject({
      method: 'POST',
      url: '/sightings',
      headers: {
        authorization: `Bearer ${authToken}`,
      },
      payload: {
        caseId: createdCaseId,
        latitude: 30.074,
        longitude: 31.346,
        description: 'تمت رؤية طفل بنفس المواصفات مع سيدة بالقرب من الحديقة',
      },
    });
    expect(res.statusCode).toBe(201);
    const body = res.json();
    expect(body.success).toBe(true);
    expect(body.data.sightingId).toBeDefined();
  });

  it('Step 10: Flutter queries nearby cases for the Map view', async () => {
    const res = await app.inject({
      method: 'GET',
      url: '/cases/nearby?lat=30.0731&lng=31.3456&radius=5000',
    });
    expect(res.statusCode).toBe(200);
    const body = res.json();
    expect(body.success).toBe(true);
    expect(Array.isArray(body.data)).toBe(true);
    expect(body.data.some((c: any) => c.report_id === createdCaseId)).toBe(true);
  });

  it('Step 11: Flutter receives notifications list and marks all read', async () => {
    const getRes = await app.inject({
      method: 'GET',
      url: '/notifications',
    });
    expect(getRes.statusCode).toBe(200);
    const getBody = getRes.json();
    expect(getBody.success).toBe(true);
    expect(Array.isArray(getBody.data)).toBe(true);

    const readRes = await app.inject({
      method: 'POST',
      url: '/notifications/read-all',
    });
    expect(readRes.statusCode).toBe(200);
  });

  it('Step 12: Flutter fetches "My Reports" for the user', async () => {
    const res = await app.inject({
      method: 'GET',
      url: '/me/reports',
      headers: {
        authorization: `Bearer ${authToken}`,
      },
    });
    expect(res.statusCode).toBe(200);
    const body = res.json();
    expect(body.success).toBe(true);
    expect(Array.isArray(body.data)).toBe(true);
    expect(body.data.some((r: any) => r.report_id === createdCaseId)).toBe(true);
  });

  it('Step 13: Flutter logs out', async () => {
    const res = await app.inject({
      method: 'POST',
      url: '/auth/logout',
    });
    expect(res.statusCode).toBe(200);
    const body = res.json();
    expect(body.success).toBe(true);
  });
});
