import { query } from '../core/database/pool.js';

export interface DeviceTokenRecord {
  id: number;
  user_id: number | null;
  token: string;
  platform: string;
  created_at: string;
  updated_at: string;
}

export interface NotificationRecord {
  id?: number;
  notification_id?: number;
  user_id: number | null;
  type: string;
  title?: string | null;
  body?: string | null;
  case_id?: number | null;
  report_id?: number | null;
  report_name?: string | null;
  report_kind?: string | null;
  metadata?: Record<string, any>;
  is_read: boolean;
  created_at: string;
}

export class NotificationRepository {
  public async saveDeviceToken(
    userId: number | null,
    token: string,
    platform: string = 'android'
  ): Promise<void> {
    await query(
      `INSERT INTO "user_device_token" (user_id, token, platform, updated_at)
       VALUES ($1, $2, $3, NOW())
       ON CONFLICT (token) DO UPDATE
       SET user_id = COALESCE(EXCLUDED.user_id, "user_device_token".user_id),
           platform = EXCLUDED.platform,
           updated_at = NOW()`,
      [userId, token.trim(), platform]
    );
  }

  public async removeDeviceToken(token: string): Promise<void> {
    await query(`DELETE FROM "user_device_token" WHERE token = $1`, [token.trim()]);
  }

  public async getTokensByUserId(userId: number): Promise<string[]> {
    const { rows } = await query<{ token: string }>(
      `SELECT token FROM "user_device_token" WHERE user_id = $1`,
      [userId]
    );
    return rows.map((r) => r.token);
  }

  public async getAllTokens(): Promise<string[]> {
    const { rows } = await query<{ token: string }>(
      `SELECT DISTINCT token FROM "user_device_token"`
    );
    return rows.map((r) => r.token);
  }

  public async createNotification(data: {
    userId: number | null;
    type: string;
    title: string;
    body: string;
    caseId?: number | null;
    metadata?: Record<string, any>;
  }): Promise<NotificationRecord> {
    const { rows } = await query<NotificationRecord>(
      `INSERT INTO "notification" (user_id, type, title, body, case_id, report_id, metadata, is_read, created_at)
       VALUES ($1, $2, $3, $4, $5, $5, $6, false, NOW())
       RETURNING *`,
      [
        data.userId ?? null,
        data.type,
        data.title,
        data.body,
        data.caseId ?? null,
        JSON.stringify(data.metadata || {}),
      ]
    );
    return rows[0];
  }

  public async getAllRecentNotifications(limit: number = 50): Promise<NotificationRecord[]> {
    const { rows } = await query<NotificationRecord>(
      `SELECT 
         n.id AS notification_id,
         n.id,
         n.user_id,
         n.type,
         COALESCE(n.title, 'تنبيه') AS title,
         COALESCE(n.body, '') AS body,
         COALESCE(n.case_id, n.report_id) AS case_id,
         COALESCE(n.report_id, n.case_id) AS report_id,
         COALESCE(n.metadata, '{}'::jsonb) AS metadata,
         n.is_read,
         n.created_at,
         r.name AS report_name,
         r.kind AS report_kind,
         r.latitude AS report_latitude,
         r.longitude AS report_longitude
       FROM "notification" n
       LEFT JOIN report r ON r.report_id = COALESCE(n.report_id, n.case_id)
       ORDER BY n.created_at DESC
       LIMIT $1`,
      [limit]
    );
    return rows;
  }

  public async getNotificationsByUserId(
    userId: number | null,
    limit: number = 50
  ): Promise<NotificationRecord[]> {
    if (userId) {
      const { rows } = await query<NotificationRecord>(
        `SELECT 
           n.id AS notification_id,
           n.id,
           n.user_id,
           n.type,
           COALESCE(n.title, 'تنبيه') AS title,
           COALESCE(n.body, '') AS body,
           COALESCE(n.case_id, n.report_id) AS case_id,
           COALESCE(n.report_id, n.case_id) AS report_id,
           COALESCE(n.metadata, '{}'::jsonb) AS metadata,
           n.is_read,
           n.created_at,
           r.name AS report_name,
           r.kind AS report_kind,
           r.latitude AS report_latitude,
           r.longitude AS report_longitude
         FROM "notification" n
         LEFT JOIN report r ON r.report_id = COALESCE(n.report_id, n.case_id)
         WHERE n.user_id = $1 OR n.user_id IS NULL
         ORDER BY n.created_at DESC
         LIMIT $2`,
        [userId, limit]
      );
      if (rows.length > 0) {
        return rows;
      }
      return this.getAllRecentNotifications(limit);
    } else {
      return this.getAllRecentNotifications(limit);
    }
  }

  public async markAllRead(userId: number): Promise<void> {
    await query(
      `UPDATE "notification" SET is_read = true WHERE (user_id = $1 OR user_id IS NULL) AND is_read = false`,
      [userId]
    );
  }
}

export const notificationRepository = new NotificationRepository();
