import { describe, it, expect } from 'vitest';
import { AgentMemoryService } from '../src/services/agent-memory.service.js';

describe('AgentMemoryService (CoALA Cognitive & Vector Architecture)', () => {
  const memoryService = new AgentMemoryService();

  it('should serialize and deserialize a 512-dimension vector to BYTEA buffer', () => {
    const vector = new Array(512).fill(0).map((_, i) => Math.sin(i));
    const buffer = memoryService.vectorToBuffer(vector);
    expect(buffer.length).toBe(512 * 4); // 2048 bytes for float32

    const deserialized = memoryService.bufferToVector(buffer);
    expect(deserialized.length).toBe(512);
    expect(deserialized[0]).toBeCloseTo(vector[0], 5);
    expect(deserialized[100]).toBeCloseTo(vector[100], 5);
  });

  it('should compute exact cosine similarity between identical and orthogonal vectors', () => {
    const vecA = new Float32Array(512);
    const vecB = new Float32Array(512);
    const vecC = new Float32Array(512);

    for (let i = 0; i < 512; i++) {
      vecA[i] = i % 2 === 0 ? 1 : 0;
      vecB[i] = i % 2 === 0 ? 1 : 0; // identical to A
      vecC[i] = i % 2 === 1 ? 1 : 0; // orthogonal to A
    }

    const similarityIdentical = memoryService.cosineSimilarity(vecA, vecB);
    expect(similarityIdentical).toBeCloseTo(1.0, 4);

    const similarityOrthogonal = memoryService.cosineSimilarity(vecA, vecC);
    expect(similarityOrthogonal).toBeCloseTo(0.0, 4);
  });

  it('should calculate cognitive recency decay score with 30-day half-life', () => {
    const now = new Date();
    const recentScore = memoryService.calculateRecencyScore(now);
    expect(recentScore).toBeCloseTo(1.0, 2);

    const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
    const halfLifeScore = memoryService.calculateRecencyScore(thirtyDaysAgo);
    expect(halfLifeScore).toBeCloseTo(0.5, 2);

    const sixtyDaysAgo = new Date(Date.now() - 60 * 24 * 60 * 60 * 1000);
    const twoHalfLifeScore = memoryService.calculateRecencyScore(sixtyDaysAgo);
    expect(twoHalfLifeScore).toBeCloseTo(0.25, 2);
  });

  it('should accurately calculate Haversine distance between geographical coordinates', () => {
    // Cairo: 30.0444° N, 31.2357° E
    // Alexandria: 31.2001° N, 29.9187° E
    const distance = memoryService.calculateHaversineDistance(30.0444, 31.2357, 31.2001, 29.9187);
    // Real distance is ~180-185 km
    expect(distance).toBeGreaterThan(170);
    expect(distance).toBeLessThan(195);
  });

  it('should generate a valid unit-norm 512-dimension mock embedding', () => {
    const seed = Buffer.from('test-image-content-for-embedding');
    const embedding = memoryService.generateMockEmbedding(seed);

    expect(embedding.length).toBe(512);

    // Verify L2 norm is 1.0 (normalized vector)
    const norm = Math.sqrt(embedding.reduce((sum, v) => sum + v * v, 0));
    expect(norm).toBeCloseTo(1.0, 4);
  });

  it('should throw ValidationError for vector with wrong dimensions', () => {
    expect(() => memoryService.vectorToBuffer([1, 2, 3])).toThrow('Vector dimension mismatch');
  });

  it('should return 0 similarity for zero vectors', () => {
    const zero = new Float32Array(512).fill(0);
    const v = new Float32Array(512).fill(1);
    const sim = memoryService.cosineSimilarity(zero, v);
    expect(sim).toBe(0);
  });
});
