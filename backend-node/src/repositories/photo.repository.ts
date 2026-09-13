import { query } from '../core/database/pool.js';

export interface PhotoRecord {
  photo_id: number;
  report_id: number;
  path: string;
  uploaded_at: string;
  url?: string | null;
}

export class PhotoRepository {
  public async create(reportId: number | string, path: string): Promise<PhotoRecord> {
    const { rows } = await query<PhotoRecord>(
      `INSERT INTO photo (report_id, path, uploaded_at)
       VALUES ($1, $2, now())
       RETURNING photo_id, report_id, path, uploaded_at`,
      [reportId, path]
    );
    return rows[0];
  }

  public async findById(photoId: number | string): Promise<(PhotoRecord & { user_id: number }) | null> {
    const { rows } = await query<PhotoRecord & { user_id: number }>(
      `SELECT p.*, r.user_id 
       FROM photo p 
       JOIN report r ON r.report_id = p.report_id 
       WHERE p.photo_id = $1`,
      [photoId]
    );
    return rows[0] || null;
  }

  public async findByReportId(reportId: number | string): Promise<PhotoRecord[]> {
    const { rows } = await query<PhotoRecord>(
      'SELECT photo_id, report_id, path, uploaded_at FROM photo WHERE report_id = $1',
      [reportId]
    );
    return rows;
  }

  public async findPathsByReportId(reportId: number | string): Promise<string[]> {
    const { rows } = await query<{ path: string }>(
      'SELECT path FROM photo WHERE report_id = $1',
      [reportId]
    );
    return rows.map((r) => r.path);
  }

  public async findPathsByUserId(userId: number | string): Promise<string[]> {
    const { rows } = await query<{ path: string }>(
      `SELECT p.path 
       FROM photo p 
       JOIN report r ON r.report_id = p.report_id 
       WHERE r.user_id = $1`,
      [userId]
    );
    return rows.map((r) => r.path);
  }

  public async deleteById(photoId: number | string): Promise<boolean> {
    const res = await query('DELETE FROM photo WHERE photo_id = $1', [photoId]);
    return (res.rowCount ?? 0) > 0;
  }
}

export const photoRepository = new PhotoRepository();
