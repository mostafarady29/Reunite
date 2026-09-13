import { z } from 'zod';
import { ValidationError } from '../core/errors/app-error.js';

export const authSignupSchema = z.object({
  name: z.string().min(2, 'Name must be at least 2 characters').max(120),
  phone: z.string().min(7, 'Phone number must be at least 7 characters').max(30),
  password: z.string().min(8, 'Password must be at least 8 characters').max(128),
  city_id: z.coerce.number().int().positive('City ID is required'),
  governorate_id: z.coerce.number().int().positive('Governorate ID is required'),
});

export const authLoginSchema = z.object({
  phone: z.string().min(7).max(30),
  password: z.string().min(8).max(128),
});

export const updateMeSchema = z.object({
  name: z.string().min(2).max(120).optional(),
  city_id: z.coerce.number().int().positive().nullable().optional(),
});

export const changePasswordSchema = z.object({
  current_password: z.string().min(8).max(128),
  new_password: z.string().min(8).max(128),
});

export const reportBodySchema = z
  .object({
    kind: z.enum(['Found', 'Missing', 'FOUND', 'MISSING']),
    name: z.string().min(1, 'Name is required').max(160),
    age: z.coerce.number().int().min(0).max(130).nullable().optional(),
    gender: z.enum(['Male', 'Female', 'MALE', 'FEMALE']).nullable().optional(),
    occurrence_date: z.string().nullable().optional(),
    occurrence_location: z.any().optional(),
    latitude: z.coerce.number().min(-90).max(90).nullable().optional(),
    longitude: z.coerce.number().min(-180).max(180).nullable().optional(),
    description: z.string().max(5000).nullable().optional(),
  })
  .transform((data) => {
    let lat = data.latitude ?? null;
    let lng = data.longitude ?? null;

    // Parse (lng,lat) string format if latitude and longitude weren't sent directly
    if (lat === null && lng === null && data.occurrence_location) {
      const locStr = String(data.occurrence_location).trim();
      const match = locStr.match(/^\(\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*\)$/);
      if (match) {
        lng = parseFloat(match[1]);
        lat = parseFloat(match[2]);
        if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
          throw new ValidationError('The selected location is outside valid coordinates');
        }
      }
    }

    if ((lat !== null && lng === null) || (lat === null && lng !== null)) {
      throw new ValidationError('Both latitude and longitude are required');
    }

    return {
      ...data,
      latitude: lat,
      longitude: lng,
    };
  });

export const commentBodySchema = z.object({
  content: z.string().min(1, 'Comment cannot be empty').max(2000),
});

export const adminCreateUserSchema = z.object({
  name: z.string().min(2).max(120),
  phone: z.string().min(7).max(30),
  password: z.string().min(8).max(128),
  city_id: z.coerce.number().int().positive(),
  role: z.boolean().default(false),
});

export const adminUpdateUserSchema = z.object({
  name: z.string().min(2).max(120).optional(),
  phone: z.string().min(7).max(30).optional(),
  city_id: z.coerce.number().int().positive().nullable().optional(),
  role: z.boolean().optional(),
  password: z.string().min(8).max(128).optional(),
});

export const reportQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  kind: z.string().nullable().optional(),
  status: z.string().nullable().optional(),
  search: z.string().nullable().optional(),
});

export function validateSchema<T>(schema: z.ZodSchema<T>, data: unknown): T {
  const result = schema.safeParse(data);
  if (!result.success) {
    const firstError = result.error.errors[0];
    const message = firstError ? `${firstError.path.join('.')}: ${firstError.message}` : 'Validation error';
    throw new ValidationError(message, result.error.flatten());
  }
  return result.data;
}
