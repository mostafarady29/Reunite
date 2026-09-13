import { query } from '../core/database/pool.js';

export interface UserRecord {
  user_id: number;
  name: string;
  phone: string;
  password_hash: string;
  city_id: number | null;
  joined_at: string;
  role: boolean;
}

export interface UserSummary {
  user_id: number;
  name: string;
  phone: string;
  city_id: number | null;
  governorate_id?: number | null;
  joined_at: string;
  role: boolean;
  report_count?: number;
}

export class UserRepository {
  public async findByPhone(phone: string): Promise<UserRecord | null> {
    const { rows } = await query<UserRecord>(
      'SELECT * FROM "User" WHERE phone = $1',
      [phone.trim()]
    );
    return rows[0] || null;
  }

  public async findById(id: number | string): Promise<UserRecord | null> {
    const { rows } = await query<UserRecord>(
      'SELECT * FROM "User" WHERE user_id = $1',
      [id]
    );
    return rows[0] || null;
  }

  public async create(data: {
    name: string;
    phone: string;
    password_hash: string;
    city_id: number;
    role?: boolean;
  }): Promise<Omit<UserRecord, 'password_hash'>> {
    const { rows } = await query<Omit<UserRecord, 'password_hash'>>(
      `INSERT INTO "User" (name, phone, password_hash, city_id, joined_at, role)
       VALUES ($1, $2, $3, $4, now(), $5)
       RETURNING user_id, name, phone, city_id, joined_at, role`,
      [data.name.trim(), data.phone.trim(), data.password_hash, data.city_id, data.role ?? false]
    );
    return rows[0];
  }

  public async updateProfile(
    userId: number | string,
    data: { name?: string; city_id?: number | null }
  ): Promise<Omit<UserRecord, 'password_hash' | 'role'> | null> {
    const fields: string[] = [];
    const values: unknown[] = [];

    if (data.name !== undefined) {
      values.push(data.name.trim());
      fields.push(`name = $${values.length}`);
    }
    if (data.city_id !== undefined) {
      values.push(data.city_id);
      fields.push(`city_id = $${values.length}`);
    }

    if (fields.length === 0) return null;

    values.push(userId);
    const { rows } = await query<Omit<UserRecord, 'password_hash' | 'role'>>(
      `UPDATE "User" SET ${fields.join(', ')}
       WHERE user_id = $${values.length}
       RETURNING user_id, name, phone, city_id, joined_at`,
      values
    );
    return rows[0] || null;
  }

  public async updatePassword(userId: number | string, passwordHash: string): Promise<boolean> {
    const res = await query(
      'UPDATE "User" SET password_hash = $1 WHERE user_id = $2',
      [passwordHash, userId]
    );
    return (res.rowCount ?? 0) > 0;
  }

  public async findAllWithStats(): Promise<UserSummary[]> {
    const sql = `
      SELECT 
        u.user_id,
        u.name,
        u.phone,
        u.city_id,
        c.governorate_id,
        u.joined_at,
        u.role,
        COUNT(DISTINCT r.report_id)::int AS report_count
      FROM "User" u
      LEFT JOIN city c ON c.city_id = u.city_id
      LEFT JOIN report r ON r.user_id = u.user_id
      GROUP BY u.user_id, c.governorate_id
      ORDER BY u.joined_at DESC
    `;
    const { rows } = await query<UserSummary>(sql);
    return rows;
  }

  public async adminUpdate(
    userId: number | string,
    fieldsToUpdate: {
      name?: string;
      phone?: string;
      city_id?: number | null;
      role?: boolean;
      password_hash?: string;
    }
  ): Promise<Omit<UserRecord, 'password_hash'> | null> {
    const fields: string[] = [];
    const values: unknown[] = [];

    if (fieldsToUpdate.name !== undefined) {
      values.push(fieldsToUpdate.name.trim());
      fields.push(`name = $${values.length}`);
    }
    if (fieldsToUpdate.phone !== undefined) {
      values.push(fieldsToUpdate.phone.trim());
      fields.push(`phone = $${values.length}`);
    }
    if (fieldsToUpdate.city_id !== undefined) {
      values.push(fieldsToUpdate.city_id);
      fields.push(`city_id = $${values.length}`);
    }
    if (fieldsToUpdate.role !== undefined) {
      values.push(fieldsToUpdate.role);
      fields.push(`role = $${values.length}`);
    }
    if (fieldsToUpdate.password_hash !== undefined) {
      values.push(fieldsToUpdate.password_hash);
      fields.push(`password_hash = $${values.length}`);
    }

    if (fields.length === 0) return null;

    values.push(userId);
    const { rows } = await query<Omit<UserRecord, 'password_hash'>>(
      `UPDATE "User" SET ${fields.join(', ')}
       WHERE user_id = $${values.length}
       RETURNING user_id, name, phone, city_id, joined_at, role`,
      values
    );
    return rows[0] || null;
  }

  public async deleteUser(userId: number | string): Promise<boolean> {
    const res = await query('DELETE FROM "User" WHERE user_id = $1', [userId]);
    return (res.rowCount ?? 0) > 0;
  }
}

export const userRepository = new UserRepository();
