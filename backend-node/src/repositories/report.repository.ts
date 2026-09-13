import { query, withTransaction } from '../core/database/pool.js';
import { storageService } from '../core/storage/supabase-storage.js';

export interface ReportPhoto {
  id: number;
  path: string;
  url?: string | null;
}

export interface ReportRecord {
  report_id: number;
  user_id: number;
  kind: string;
  name: string;
  age: number | null;
  gender: string | null;
  occurrence_date: string | null;
  occurrence_location?: string | null;
  latitude: number | null;
  longitude: number | null;
  description: string | null;
  status: string;
  created_at: string;
  closed_at: string | null;
  reporter_name?: string;
  reporter_phone?: string;
  photos?: ReportPhoto[];
}

export interface ReportListOptions {
  page?: number;
  limit?: number;
  kind?: string | null;
  status?: string | null;
  search?: string | null;
}

export class ReportRepository {
  /**
   * Transforms raw database report into client-friendly format expected by Web and Mobile
   */
  public async normalizeReport(row: any): Promise<ReportRecord> {
    const report: ReportRecord = { ...row };

    // Format coordinates string for backwards compatibility
    if (
      !report.occurrence_location &&
      report.latitude !== null &&
      report.latitude !== undefined &&
      report.longitude !== null &&
      report.longitude !== undefined
    ) {
      report.occurrence_location = `(${report.longitude},${report.latitude})`;
    }

    // Standardize Case kind: "Missing" | "Found"
    if (report.kind) {
      const upper = String(report.kind).toUpperCase();
      report.kind = upper === 'FOUND' ? 'Found' : upper === 'MISSING' ? 'Missing' : report.kind;
    }

    // Standardize Status: "Open" | "Closed"
    if (report.status) {
      const upper = String(report.status).toUpperCase();
      report.status = upper === 'OPEN' ? 'Open' : 'Closed';
    }

    // Attach signed URLs for photos
    if (Array.isArray(report.photos)) {
      const signedPhotos = await Promise.all(
        report.photos.map(async (p: any) => {
          const path = p.path || '';
          const url = await storageService.getSignedImageUrl(path);
          return {
            id: p.id || p.photo_id,
            path,
            url,
          };
        })
      );
      report.photos = signedPhotos;
    } else {
      report.photos = [];
    }

    return report;
  }

  public async findPaginated(options: ReportListOptions): Promise<{
    items: ReportRecord[];
    page: number;
    limit: number;
    total: number;
  }> {
    const { page = 1, limit = 20, kind, status, search } = options;
    const whereConditions: string[] = [];
    const params: unknown[] = [];

    if (kind) {
      const normalizedKind = kind.toLowerCase() === 'found' ? 'FOUND' : 'MISSING';
      params.push(normalizedKind);
      whereConditions.push(`r.kind = $${params.length}`);
    }

    if (status) {
      const normalizedStatus = status.toLowerCase() === 'open' ? 'OPEN' : 'RESOLVED';
      params.push(normalizedStatus);
      whereConditions.push(`r.status = $${params.length}`);
    }

    if (search && search.trim()) {
      const searchPattern = `%${search.trim()}%`;
      params.push(searchPattern);
      const idx = params.length;
      whereConditions.push(
        `(r.name ILIKE $${idx} OR r.latitude::text ILIKE $${idx} OR r.longitude::text ILIKE $${idx})`
      );
    }

    const whereClause = whereConditions.length > 0 ? `WHERE ${whereConditions.join(' AND ')}` : '';

    // Count query
    const countSql = `SELECT COUNT(*)::int AS total FROM report r ${whereClause}`;
    const countRes = await query<{ total: number }>(countSql, params);
    const total = countRes.rows[0]?.total || 0;

    // Items query with JSON aggregated photos
    const offset = (page - 1) * limit;
    params.push(limit);
    const limitIdx = params.length;
    params.push(offset);
    const offsetIdx = params.length;

    const dataSql = `
      SELECT 
        r.*,
        COALESCE(
          json_agg(
            json_build_object('id', p.photo_id, 'path', p.path)
          ) FILTER (WHERE p.photo_id IS NOT NULL),
          '[]'
        ) AS photos
      FROM report r
      LEFT JOIN photo p ON p.report_id = r.report_id
      ${whereClause}
      GROUP BY r.report_id
      ORDER BY r.created_at DESC
      LIMIT $${limitIdx} OFFSET $${offsetIdx}
    `;

    const { rows } = await query(dataSql, params);
    const items = await Promise.all(rows.map((row) => this.normalizeReport(row)));

    return { items, page, limit, total };
  }

  public async findById(reportId: number | string): Promise<ReportRecord | null> {
    const sql = `
      SELECT 
        r.*,
        u.name AS reporter_name,
        u.phone AS reporter_phone,
        COALESCE(
          json_agg(
            json_build_object('id', p.photo_id, 'path', p.path)
          ) FILTER (WHERE p.photo_id IS NOT NULL),
          '[]'
        ) AS photos
      FROM report r
      JOIN "User" u ON u.user_id = r.user_id
      LEFT JOIN photo p ON p.report_id = r.report_id
      WHERE r.report_id = $1
      GROUP BY r.report_id, u.name, u.phone
    `;
    const { rows } = await query(sql, [reportId]);
    if (!rows[0]) return null;
    return this.normalizeReport(rows[0]);
  }

  public async findByUserId(userId: number | string): Promise<ReportRecord[]> {
    const sql = `
      SELECT 
        r.*,
        COALESCE(
          json_agg(
            json_build_object('id', p.photo_id, 'path', p.path)
          ) FILTER (WHERE p.photo_id IS NOT NULL),
          '[]'
        ) AS photos
      FROM report r
      LEFT JOIN photo p ON p.report_id = r.report_id
      WHERE r.user_id = $1
      GROUP BY r.report_id
      ORDER BY r.created_at DESC
    `;
    const { rows } = await query(sql, [userId]);
    return Promise.all(rows.map((row) => this.normalizeReport(row)));
  }

  public async create(data: {
    userId: number | string;
    kind: string;
    name: string;
    age?: number | null;
    gender?: string | null;
    occurrenceDate?: string | null;
    latitude?: number | null;
    longitude?: number | null;
    description?: string | null;
  }): Promise<ReportRecord> {
    const sql = `
      INSERT INTO report (
        user_id, kind, name, age, gender, 
        occurrence_date, latitude, longitude, description, 
        status, created_at
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, 'OPEN', now())
      RETURNING *
    `;
    const { rows } = await query(sql, [
      data.userId,
      data.kind.toUpperCase(),
      data.name.trim(),
      data.age ?? null,
      data.gender ? data.gender.toUpperCase() : null,
      data.occurrenceDate ?? null,
      data.latitude ?? null,
      data.longitude ?? null,
      data.description ?? null,
    ]);
    return this.normalizeReport(rows[0]);
  }

  public async update(
    reportId: number | string,
    data: {
      kind?: string;
      name?: string;
      age?: number | null;
      gender?: string | null;
      occurrenceDate?: string | null;
      latitude?: number | null;
      longitude?: number | null;
      description?: string | null;
    }
  ): Promise<ReportRecord | null> {
    const sql = `
      UPDATE report SET
        kind = COALESCE($1, kind),
        name = COALESCE($2, name),
        age = COALESCE($3, age),
        gender = COALESCE($4, gender),
        occurrence_date = COALESCE($5, occurrence_date),
        latitude = COALESCE($6, latitude),
        longitude = COALESCE($7, longitude),
        description = COALESCE($8, description)
      WHERE report_id = $9
      RETURNING *
    `;
    const { rows } = await query(sql, [
      data.kind ? data.kind.toUpperCase() : null,
      data.name ? data.name.trim() : null,
      data.age ?? null,
      data.gender ? data.gender.toUpperCase() : null,
      data.occurrenceDate ?? null,
      data.latitude ?? null,
      data.longitude ?? null,
      data.description ?? null,
      reportId,
    ]);
    if (!rows[0]) return null;
    return this.normalizeReport(rows[0]);
  }

  public async close(reportId: number | string): Promise<ReportRecord | null> {
    const sql = `
      UPDATE report 
      SET status = 'RESOLVED', closed_at = now()
      WHERE report_id = $1
      RETURNING *
    `;
    const { rows } = await query(sql, [reportId]);
    if (!rows[0]) return null;
    return this.normalizeReport(rows[0]);
  }

  public async deleteWithCascade(reportId: number | string): Promise<string[]> {
    return withTransaction(async (client) => {
      // 1. Get photo paths to delete from storage afterwards
      const photoRes = await client.query<{ path: string }>(
        'SELECT path FROM photo WHERE report_id = $1',
        [reportId]
      );
      const paths = photoRes.rows.map((r) => r.path);

      // 2. Cascade delete records in DB
      await client.query('DELETE FROM comment WHERE report_id = $1', [reportId]);
      await client.query(
        'DELETE FROM embedding WHERE photo_id IN (SELECT photo_id FROM photo WHERE report_id = $1)',
        [reportId]
      );
      await client.query('DELETE FROM photo WHERE report_id = $1', [reportId]);
      await client.query('DELETE FROM report WHERE report_id = $1', [reportId]);

      return paths;
    });
  }

  public async getStatistics(): Promise<{
    activeCases: number;
    childrenFound: number;
    reportsToday: number;
    reunifications: number;
  }> {
    const sql = `
      SELECT
        COUNT(*) FILTER (WHERE status = 'OPEN')::int AS "activeCases",
        COUNT(*) FILTER (WHERE kind = 'FOUND')::int AS "childrenFound",
        COUNT(*) FILTER (WHERE created_at >= CURRENT_DATE)::int AS "reportsToday",
        COUNT(*) FILTER (WHERE status = 'RESOLVED')::int AS "reunifications"
      FROM report
    `;
    const { rows } = await query(sql);
    const r = rows[0] || {};
    return {
      activeCases: r.activeCases || 0,
      childrenFound: r.childrenFound || 0,
      reportsToday: r.reportsToday || 0,
      reunifications: r.reunifications || 0,
    };
  }

  public async findNearby(
    lat: number,
    lng: number,
    radiusMeters: number = 10000
  ): Promise<Array<ReportRecord & { distanceMeters: number }>> {
    const sql = `
      SELECT 
        r.*,
        COALESCE(
          json_agg(
            json_build_object('id', p.photo_id, 'path', p.path)
          ) FILTER (WHERE p.photo_id IS NOT NULL),
          '[]'
        ) AS photos
      FROM report r
      LEFT JOIN photo p ON p.report_id = r.report_id
      WHERE r.status = 'OPEN' AND r.latitude IS NOT NULL AND r.longitude IS NOT NULL
      GROUP BY r.report_id
    `;
    const { rows } = await query(sql);
    const R = 6371000;
    const toRad = (d: number) => (d * Math.PI) / 180;
    const lat1 = toRad(lat);
    const lon1 = toRad(lng);

    const matches: Array<{ row: any; distanceMeters: number }> = [];

    for (const row of rows) {
      const lat2 = toRad(Number(row.latitude));
      const lon2 = toRad(Number(row.longitude));
      const dLat = lat2 - lat1;
      const dLon = lon2 - lon1;
      const a =
        Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLon / 2) * Math.sin(dLon / 2);
      const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
      const distance = R * c;

      if (distance <= radiusMeters) {
        matches.push({ row, distanceMeters: Math.round(distance) });
      }
    }

    matches.sort((a, b) => a.distanceMeters - b.distanceMeters);

    return Promise.all(
      matches.map(async (m) => {
        const norm = await this.normalizeReport(m.row);
        return { ...norm, distanceMeters: m.distanceMeters };
      })
    );
  }
}

export const reportRepository = new ReportRepository();
