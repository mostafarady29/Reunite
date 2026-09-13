import { query } from '../core/database/pool.js';

export interface CommentRecord {
  comment_id: number;
  report_id: number;
  user_id: number;
  content: string;
  added_at: string;
  author_name?: string;
  author_phone?: string;
}

export class CommentRepository {
  public async findByReportId(reportId: number | string): Promise<CommentRecord[]> {
    const sql = `
      SELECT 
        c.comment_id,
        c.report_id,
        c.user_id,
        c.content,
        c.added_at,
        u.name AS author_name,
        u.phone AS author_phone
      FROM comment c
      JOIN "User" u ON u.user_id = c.user_id
      WHERE c.report_id = $1
      ORDER BY c.added_at ASC
    `;
    const { rows } = await query<CommentRecord>(sql, [reportId]);
    return rows;
  }

  public async create(
    reportId: number | string,
    userId: number | string,
    content: string
  ): Promise<CommentRecord> {
    const sql = `
      INSERT INTO comment (report_id, user_id, content, added_at)
      VALUES ($1, $2, $3, now())
      RETURNING comment_id, report_id, user_id, content, added_at
    `;
    const { rows } = await query<CommentRecord>(sql, [reportId, userId, content.trim()]);
    return rows[0];
  }
}

export const commentRepository = new CommentRepository();
