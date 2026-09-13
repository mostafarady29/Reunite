import { env } from '../config/env.js';
import { query } from '../core/database/pool.js';
import { ValidationError, ServiceUnavailableError } from '../core/errors/app-error.js';

export interface MemoryVectorMatch {
  record_id: string;
  similarity: number;
  composite_score?: number;
  recency_score?: number;
  metadata: {
    report_id: string;
    kind: string;
    name?: string;
    created_at?: string;
    distance_km?: number;
  };
}

export interface SearchMemoryOptions {
  limit?: number;
  threshold?: number;
  status?: string;
  kind?: string;
  userLat?: number;
  userLng?: number;
  radiusKm?: number;
  applyRecencyDecay?: boolean;
}

export class AgentMemoryService {
  private readonly dimension = env.EMBEDDING_DIM; // 512

  /**
   * Convert an array of numbers (float32) to a binary Buffer for storage in BYTEA column
   */
  public vectorToBuffer(vector: number[]): Buffer {
    if (vector.length !== this.dimension) {
      throw new ValidationError(`Vector dimension mismatch. Expected ${this.dimension}, got ${vector.length}`);
    }
    const floatArray = new Float32Array(vector);
    return Buffer.from(floatArray.buffer);
  }

  /**
   * Convert raw database BYTEA buffer into Float32Array vector
   */
  public bufferToVector(buffer: Buffer): Float32Array {
    // If pg returned hex string '\\x...'
    let rawBuf = buffer;
    if (typeof buffer === 'string') {
      const hex = (buffer as string).startsWith('\\x') ? (buffer as string).slice(2) : buffer;
      rawBuf = Buffer.from(hex, 'hex');
    }
    return new Float32Array(rawBuf.buffer, rawBuf.byteOffset, rawBuf.byteLength / 4);
  }

  /**
   * Computes normalized cosine similarity between two Float32 vectors
   */
  public cosineSimilarity(a: Float32Array | number[], b: Float32Array | number[]): number {
    let dot = 0;
    let normA = 0;
    let normB = 0;

    for (let i = 0; i < this.dimension; i++) {
      const va = a[i];
      const vb = b[i];
      dot += va * vb;
      normA += va * va;
      normB += vb * vb;
    }

    const denominator = Math.sqrt(normA) * Math.sqrt(normB);
    if (denominator === 0) return 0;
    return dot / denominator;
  }

  /**
   * Calculate temporal recency decay score based on cognitive decay model
   * Half-life of 30 days
   */
  public calculateRecencyScore(createdAt: Date | string, halfLifeDays = 30): number {
    const created = typeof createdAt === 'string' ? new Date(createdAt) : createdAt;
    const diffHours = Math.max(0, (Date.now() - created.getTime()) / (1000 * 60 * 60));
    const halfLifeHours = halfLifeDays * 24;
    return Math.pow(0.5, diffHours / halfLifeHours);
  }

  /**
   * Great-circle distance between two coordinates in kilometers (Haversine formula)
   */
  public calculateHaversineDistance(
    lat1: number,
    lon1: number,
    lat2: number,
    lon2: number
  ): number {
    const R = 6371; // Earth's radius in km
    const dLat = ((lat2 - lat1) * Math.PI) / 180;
    const dLon = ((lon2 - lon1) * Math.PI) / 180;
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos((lat1 * Math.PI) / 180) *
        Math.cos((lat2 * Math.PI) / 180) *
        Math.sin(dLon / 2) *
        Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  }

  /**
   * Upsert vector embedding for a photo in the semantic memory store
   */
  public async upsertEmbedding(photoId: string | number, vector: number[]): Promise<void> {
    const buffer = this.vectorToBuffer(vector);
    await query(
      `INSERT INTO embedding (photo_id, vector)
       VALUES ($1, $2)
       ON CONFLICT (photo_id) DO UPDATE SET vector = EXCLUDED.vector`,
      [photoId, buffer]
    );
  }

  /**
   * Search memory for similar identity embeddings with optional cognitive recency and geo-filtering
   */
  public async searchSimilarMemories(
    queryEmbedding: number[],
    options: SearchMemoryOptions = {}
  ): Promise<MemoryVectorMatch[]> {
    const {
      limit = 5,
      threshold = 0.38,
      status = 'OPEN',
      kind,
      userLat,
      userLng,
      radiusKm,
      applyRecencyDecay = false,
    } = options;

    if (queryEmbedding.length !== this.dimension) {
      throw new ValidationError(`Query vector dimension mismatch. Expected ${this.dimension}`);
    }

    const queryVector = new Float32Array(queryEmbedding);

    // Pre-filtering query to ensure candidate memory matches active context
    const whereConditions = ['r.status = $1'];
    const params: unknown[] = [status];

    if (kind) {
      params.push(kind.toUpperCase());
      whereConditions.push(`r.kind = $${params.length}`);
    }

    const sql = `
      SELECT 
        e.photo_id,
        r.report_id,
        r.kind,
        r.name,
        r.created_at,
        r.latitude,
        r.longitude,
        e.vector
      FROM embedding e
      JOIN photo p ON p.photo_id = e.photo_id
      JOIN report r ON r.report_id = p.report_id
      WHERE ${whereConditions.join(' AND ')}
    `;

    const { rows } = await query(sql, params);
    const matches: MemoryVectorMatch[] = [];

    for (const row of rows) {
      const candidateVector = this.bufferToVector(row.vector);
      if (candidateVector.length !== this.dimension) continue;

      const similarity = this.cosineSimilarity(queryVector, candidateVector);
      if (similarity < threshold) continue;

      // Optional Haversine spatial filter
      let distanceKm: number | undefined;
      if (userLat !== undefined && userLng !== undefined && row.latitude && row.longitude) {
        distanceKm = this.calculateHaversineDistance(
          userLat,
          userLng,
          Number(row.latitude),
          Number(row.longitude)
        );
        if (radiusKm !== undefined && distanceKm > radiusKm) {
          continue; // Outside search radius
        }
      }

      // Optional temporal scoring from cognitive agent memory
      let compositeScore = similarity;
      let recencyScore: number | undefined;
      if (applyRecencyDecay && row.created_at) {
        recencyScore = this.calculateRecencyScore(row.created_at);
        compositeScore = similarity * 0.75 + recencyScore * 0.25;
      }

      matches.push({
        record_id: String(row.photo_id),
        similarity: Number(similarity.toFixed(4)),
        composite_score: applyRecencyDecay ? Number(compositeScore.toFixed(4)) : undefined,
        recency_score: recencyScore ? Number(recencyScore.toFixed(4)) : undefined,
        metadata: {
          report_id: String(row.report_id),
          kind: row.kind,
          name: row.name,
          created_at: row.created_at,
          distance_km: distanceKm !== undefined ? Number(distanceKm.toFixed(2)) : undefined,
        },
      });
    }

    // Sort descending by score
    const sortField = applyRecencyDecay ? 'composite_score' : 'similarity';
    return matches
      .sort((a, b) => (b[sortField] ?? b.similarity) - (a[sortField] ?? a.similarity))
      .slice(0, limit);
  }

  /**
   * Request facial embedding vector from local AI service or Hugging Face Space
   */
  public async extractEmbeddingFromImage(imageBuffer: Buffer, filename = 'image.jpg'): Promise<number[]> {
    const endpoint = env.AI_SERVICE_URL
      ? `${env.AI_SERVICE_URL.replace(/\/$/, '')}/api${env.AI_API_NAME}`
      : env.AI_SPACE
        ? `https://${env.AI_SPACE.replace('/', '-')}.hf.space/api${env.AI_API_NAME}`
        : null;

    if (!endpoint) {
      if (env.NODE_ENV !== 'production') {
        return this.generateMockEmbedding(imageBuffer);
      }
      throw new ServiceUnavailableError('AI embedding service is not configured');
    }

    try {
      const formData = new FormData();
      const blob = new Blob([imageBuffer]);
      formData.append('data', blob, filename);

      const headers: Record<string, string> = {};
      if (env.AI_TOKEN) {
        headers['Authorization'] = `Bearer ${env.AI_TOKEN}`;
      }

      const response = await fetch(endpoint, {
        method: 'POST',
        headers,
        body: formData,
        signal: AbortSignal.timeout(15000),
      });

      if (!response.ok) {
        throw new Error(`AI service responded with HTTP status ${response.status}`);
      }

      const json = (await response.json()) as any;
      let rawEmbedding = json?.data ? json.data[0] : json;
      if (typeof rawEmbedding === 'object' && rawEmbedding !== null && 'embedding' in rawEmbedding) {
        rawEmbedding = rawEmbedding.embedding;
      }

      if (!Array.isArray(rawEmbedding) || rawEmbedding.length !== this.dimension) {
        throw new ValidationError(`Invalid embedding received from model. Expected ${this.dimension} floats`);
      }

      return rawEmbedding.map(Number);
    } catch (error: any) {
      if (env.NODE_ENV !== 'production') {
        return this.generateMockEmbedding(imageBuffer);
      }
      console.error('Error invoking AI embedding service:', error);
      throw new ServiceUnavailableError('AI embedding service is unavailable');
    }
  }

  /**
   * Find possible matches for a case using visual identity memory + temporal + geo-proximity
   */
  public async findPossibleMatchesForCase(
    caseId: number | string,
    limit = 10
  ): Promise<
    Array<{
      foundCase: any;
      matchPercent: number;
      distanceMeters: number;
      timeGapHours: number;
    }>
  > {
    // 1. Get embedding for the source case
    const sql = `
      SELECT e.vector, r.kind, r.latitude, r.longitude, r.occurrence_date, r.created_at
      FROM embedding e
      JOIN photo p ON p.photo_id = e.photo_id
      JOIN report r ON r.report_id = p.report_id
      WHERE r.report_id = $1
      LIMIT 1
    `;
    const { rows } = await query(sql, [caseId]);
    if (!rows[0]) {
      return [];
    }

    const source = rows[0];
    const sourceVector = Array.from(this.bufferToVector(source.vector));
    const targetKind = source.kind === 'MISSING' ? 'FOUND' : 'MISSING';

    const matches = await this.searchSimilarMemories(sourceVector, {
      limit,
      threshold: 0.25,
      status: 'OPEN',
      kind: targetKind,
      applyRecencyDecay: true,
    });

    const results = [];
    for (const match of matches) {
      const candidateId = match.metadata.report_id;
      const { rows: cRows } = await query(
        `SELECT r.*,
          COALESCE(
            json_agg(
              json_build_object('id', p.photo_id, 'path', p.path)
            ) FILTER (WHERE p.photo_id IS NOT NULL),
            '[]'
          ) AS photos
        FROM report r
        LEFT JOIN photo p ON p.report_id = r.report_id
        WHERE r.report_id = $1
        GROUP BY r.report_id`,
        [candidateId]
      );
      if (!cRows[0]) continue;

      const candidate = cRows[0];
      let distanceMeters = 0;
      if (
        source.latitude &&
        source.longitude &&
        candidate.latitude &&
        candidate.longitude
      ) {
        const distKm = this.calculateHaversineDistance(
          Number(source.latitude),
          Number(source.longitude),
          Number(candidate.latitude),
          Number(candidate.longitude)
        );
        distanceMeters = Math.round(distKm * 1000);
      }

      const t1 = new Date(source.occurrence_date || source.created_at).getTime();
      const t2 = new Date(candidate.occurrence_date || candidate.created_at).getTime();
      const timeGapHours = Math.round(Math.abs(t1 - t2) / (1000 * 60 * 60));

      results.push({
        foundCase: candidate,
        matchPercent: Math.round(match.similarity * 100),
        distanceMeters,
        timeGapHours,
      });
    }

    return results;
  }

  /**
   * Deterministic mock vector generation for local testing & development without HF token
   */
  public generateMockEmbedding(seedBuffer: Buffer): number[] {
    const vector = new Float32Array(this.dimension);
    let hash = 0;
    for (let i = 0; i < Math.min(seedBuffer.length, 1024); i++) {
      hash = (hash << 5) - hash + seedBuffer[i];
      hash |= 0;
    }

    let norm = 0;
    for (let i = 0; i < this.dimension; i++) {
      const val = Math.sin(hash + i);
      vector[i] = val;
      norm += val * val;
    }

    // L2 normalize
    const l2 = Math.sqrt(norm);
    return Array.from(vector).map((v) => (l2 === 0 ? 0 : v / l2));
  }
}

export const agentMemoryService = new AgentMemoryService();
