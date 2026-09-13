import { query } from '../core/database/pool.js';

export interface Governorate {
  id: number;
  name: string;
}

export interface City {
  id: number;
  gov_id: number;
  name: string;
}

export class LocationRepository {
  public async getGovernorates(): Promise<Governorate[]> {
    const { rows } = await query<Governorate>(
      'SELECT governorate_id AS id, name FROM governorate ORDER BY name'
    );
    return rows;
  }

  public async getCitiesByGovernorate(govId: number): Promise<City[]> {
    const { rows } = await query<City>(
      'SELECT city_id AS id, governorate_id AS gov_id, name FROM city WHERE governorate_id = $1 ORDER BY name',
      [govId]
    );
    return rows;
  }

  public async validateCityBelongsToGovernorate(cityId: number, govId: number): Promise<boolean> {
    const { rows } = await query(
      'SELECT 1 FROM city WHERE city_id = $1 AND governorate_id = $2',
      [cityId, govId]
    );
    return rows.length > 0;
  }

  public async getGovernoratesWithCities(): Promise<
    Array<{ id: number; name: string; cities: Array<{ id: number; name: string }> }>
  > {
    const sql = `
      SELECT 
        g.governorate_id AS id,
        g.name,
        COALESCE(
          json_agg(
            json_build_object('id', c.city_id, 'name', c.name)
          ) FILTER (WHERE c.city_id IS NOT NULL),
          '[]'
        ) AS cities
      FROM governorate g
      LEFT JOIN city c ON c.governorate_id = g.governorate_id
      GROUP BY g.governorate_id, g.name
      ORDER BY g.name
    `;
    const { rows } = await query(sql);
    return rows;
  }

  public async cityExists(cityId: number): Promise<boolean> {
    const { rows } = await query('SELECT 1 FROM city WHERE city_id = $1', [cityId]);
    return rows.length > 0;
  }
}

export const locationRepository = new LocationRepository();
