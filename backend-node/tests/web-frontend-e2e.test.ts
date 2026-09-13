import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { FastifyInstance } from 'fastify';
import { buildApp } from '../src/app.js';
import { query } from '../src/core/database/pool.js';

describe('Web Frontend E2E Simulation Flow', () => {
  let app: FastifyInstance;
  let sessionCookie: string;
  const testPhone = `+2010${Math.floor(10000000 + Math.random() * 90000000)}`;
  const testPassword = 'SecurePassword123!';
  let createdReportId: number;

  beforeAll(async () => {
    app = await buildApp();
    await app.ready();
  });

  afterAll(async () => {
    // Cleanup created test records
    if (createdReportId) {
      await query('DELETE FROM comment WHERE report_id = $1', [createdReportId]);
      await query('DELETE FROM photo WHERE report_id = $1', [createdReportId]);
      await query('DELETE FROM report WHERE report_id = $1', [createdReportId]);
    }
    await query('DELETE FROM "User" WHERE phone = $1', [testPhone]);
    await app.close();
  });

  it('1. Web Frontend loads governorates and cities for registration dropdown', async () => {
    const govRes = await app.inject({
      method: 'GET',
      url: '/api/governorates',
    });
    expect(govRes.statusCode).toBe(200);
    const govs = govRes.json().data;
    expect(Array.isArray(govs)).toBe(true);
    expect(govs.length).toBeGreaterThan(0);

    const cairoId = govs.find((g: any) => g.name === 'Cairo')?.id || 1;
    const citiesRes = await app.inject({
      method: 'GET',
      url: `/api/governorates/${cairoId}/cities`,
    });
    expect(citiesRes.statusCode).toBe(200);
    const cities = citiesRes.json().data;
    expect(Array.isArray(cities)).toBe(true);
    expect(cities.length).toBeGreaterThan(0);
  });

  it('2. Web Frontend registers a new user via POST /api/auth/signup', async () => {
    const res = await app.inject({
      method: 'POST',
      url: '/api/auth/signup',
      payload: {
        name: 'Web Test Volunteer',
        phone: testPhone,
        password: testPassword,
        governorate_id: 1,
        city_id: 1,
      },
    });

    expect(res.statusCode).toBe(201);
    const body = res.json();
    expect(body.success).toBe(true);
    expect(body.data.user.phone).toBe(testPhone);

    const cookies = res.cookies;
    const authCookie = cookies.find((c: any) => c.name === 'reunite_session');
    expect(authCookie).toBeDefined();
    sessionCookie = `reunite_session=${authCookie!.value}`;
  });

  it('3. Web Frontend authenticates via POST /api/auth/login and receives session cookie', async () => {
    const res = await app.inject({
      method: 'POST',
      url: '/api/auth/login',
      payload: {
        phone: testPhone,
        password: testPassword,
      },
    });

    expect(res.statusCode).toBe(200);
    const body = res.json();
    expect(body.success).toBe(true);
    expect(body.data.user.name).toBe('Web Test Volunteer');

    const authCookie = res.cookies.find((c: any) => c.name === 'reunite_session');
    expect(authCookie).toBeDefined();
    sessionCookie = `reunite_session=${authCookie!.value}`;
  });

  it('4. Web Frontend checks session via GET /api/me with cookie', async () => {
    const res = await app.inject({
      method: 'GET',
      url: '/api/me',
      headers: {
        cookie: sessionCookie,
      },
    });

    expect(res.statusCode).toBe(200);
    const body = res.json();
    expect(body.success).toBe(true);
    expect(body.data.phone).toBe(testPhone);
    expect(body.data.name).toBe('Web Test Volunteer');
  });

  it('5. Web Frontend updates profile name via PATCH /api/me', async () => {
    const res = await app.inject({
      method: 'PATCH',
      url: '/api/me',
      headers: {
        cookie: sessionCookie,
      },
      payload: {
        name: 'Web Volunteer Updated',
      },
    });

    expect(res.statusCode).toBe(200);
    const body = res.json();
    expect(body.success).toBe(true);
    expect(body.data.name).toBe('Web Volunteer Updated');
  });

  it('6. Web Frontend browses public reports via GET /api/reports', async () => {
    const res = await app.inject({
      method: 'GET',
      url: '/api/reports?page=1&limit=10',
    });

    expect(res.statusCode).toBe(200);
    const body = res.json();
    expect(body.success).toBe(true);
    expect(Array.isArray(body.data.items)).toBe(true);
  });

  it('7. Web Frontend publishes a missing child report via POST /api/reports', async () => {
    const res = await app.inject({
      method: 'POST',
      url: '/api/reports',
      headers: {
        cookie: sessionCookie,
      },
      payload: {
        kind: 'Missing',
        name: 'Omar Sherif',
        age: 8,
        gender: 'Male',
        occurrence_date: '2026-09-13',
        latitude: 30.0444,
        longitude: 31.2357,
        description: 'Wearing navy blue t-shirt and white sneakers in Downtown Cairo',
      },
    });

    expect(res.statusCode).toBe(201);
    const body = res.json();
    expect(body.success).toBe(true);
    expect(body.data.name).toBe('Omar Sherif');
    expect(body.data.kind).toBe('Missing');
    createdReportId = body.data.report_id || body.data.id;
  });

  it('8. Web Frontend retrieves details of the published report via GET /api/reports/:id', async () => {
    const res = await app.inject({
      method: 'GET',
      url: `/api/reports/${createdReportId}`,
      headers: {
        cookie: sessionCookie,
      },
    });

    expect(res.statusCode).toBe(200);
    const body = res.json();
    expect(body.success).toBe(true);
    expect(body.data.name).toBe('Omar Sherif');
    expect(body.data.status).toBe('Open');
  });

  it('9. Web Frontend adds a community sighting/comment via POST /api/reports/:id/comments', async () => {
    const res = await app.inject({
      method: 'POST',
      url: `/api/reports/${createdReportId}/comments`,
      headers: {
        cookie: sessionCookie,
      },
      payload: {
        content: 'I noticed a child matching this description near Tahrir Square metro.',
      },
    });

    expect(res.statusCode).toBe(201);
    const body = res.json();
    expect(body.success).toBe(true);
    expect(body.data.content).toContain('Tahrir Square');
    expect(body.data.author_name).toBe('Web Volunteer Updated');
  });

  it('10. Web Frontend checks user personal reports via GET /api/me/reports', async () => {
    const res = await app.inject({
      method: 'GET',
      url: '/api/me/reports',
      headers: {
        cookie: sessionCookie,
      },
    });

    expect(res.statusCode).toBe(200);
    const body = res.json();
    expect(body.success).toBe(true);
    expect(Array.isArray(body.data)).toBe(true);
    expect(body.data.some((r: any) => r.report_id === createdReportId || r.id === createdReportId)).toBe(true);
  });

  it('11. Web Frontend marks case as closed via POST /api/reports/:id/close', async () => {
    const res = await app.inject({
      method: 'POST',
      url: `/api/reports/${createdReportId}/close`,
      headers: {
        cookie: sessionCookie,
      },
    });

    expect(res.statusCode).toBe(200);
    const body = res.json();
    expect(body.success).toBe(true);
    expect(body.data.status).toBe('Closed');
  });

  it('12. Web Frontend logs out via POST /api/auth/logout and clears cookie', async () => {
    const res = await app.inject({
      method: 'POST',
      url: '/api/auth/logout',
      headers: {
        cookie: sessionCookie,
      },
    });

    expect(res.statusCode).toBe(200);
    const body = res.json();
    expect(body.success).toBe(true);
    const clearedCookie = res.cookies.find((c: any) => c.name === 'reunite_session');
    expect(clearedCookie).toBeDefined();
  });
});
