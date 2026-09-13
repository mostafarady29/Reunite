import { env } from '../../config/env.js';

export class SupabaseStorageService {
  private get baseUrl(): string {
    return env.SUPABASE_URL.replace(/\/+$/, '');
  }

  private get headers(): Record<string, string> {
    return {
      Authorization: `Bearer ${env.SUPABASE_SERVICE_ROLE_KEY}`,
      apikey: env.SUPABASE_SERVICE_ROLE_KEY,
    };
  }

  public isConfigured(): boolean {
    return Boolean(env.SUPABASE_URL && env.SUPABASE_SERVICE_ROLE_KEY);
  }

  /**
   * Generates a signed URL for a private image in Supabase storage
   */
  public async getSignedImageUrl(path: string, expiresIn = 3600): Promise<string | null> {
    if (!this.isConfigured() || !path) return null;

    try {
      const url = `${this.baseUrl}/storage/v1/object/sign/${env.STORAGE_BUCKET}`;
      const res = await fetch(url, {
        method: 'POST',
        headers: {
          ...this.headers,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          paths: [path],
          expiresIn,
        }),
      });

      if (!res.ok) {
        console.warn(`Supabase signed URL failed with status ${res.status}`);
        return null;
      }

      const data = await res.json() as any;
      const item = Array.isArray(data) ? data[0] : data;
      const signed = item?.signedURL || item?.signedUrl;
      if (!signed) return null;

      return signed.startsWith('/') ? `${this.baseUrl}/storage/v1${signed}` : signed;
    } catch (error) {
      console.error('Error generating signed URL:', error);
      return null;
    }
  }

  /**
   * Uploads an image buffer to Supabase Storage
   */
  public async uploadObject(path: string, buffer: Buffer, contentType: string): Promise<boolean> {
    if (!this.isConfigured()) return false;

    try {
      const url = `${this.baseUrl}/storage/v1/object/${env.STORAGE_BUCKET}/${path}`;
      const res = await fetch(url, {
        method: 'PUT',
        headers: {
          ...this.headers,
          'Content-Type': contentType,
        },
        body: buffer,
      });

      return res.ok;
    } catch (error) {
      console.error('Error uploading image to Supabase:', error);
      return false;
    }
  }

  /**
   * Deletes an object from Supabase Storage
   */
  public async deleteObject(path: string): Promise<void> {
    if (!this.isConfigured() || !path) return;

    try {
      const url = `${this.baseUrl}/storage/v1/object/${env.STORAGE_BUCKET}/${path}`;
      await fetch(url, {
        method: 'DELETE',
        headers: this.headers,
      });
    } catch (error) {
      console.error('Error deleting object from Supabase storage:', error);
    }
  }
}

export const storageService = new SupabaseStorageService();
