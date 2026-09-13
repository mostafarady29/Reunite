import { FastifyPluginAsync } from 'fastify';
import { locationRepository } from '../repositories/location.repository.js';

export const locationRoutes: FastifyPluginAsync = async (fastify) => {
  fastify.get('/api/governorates', async (_request, reply) => {
    const data = await locationRepository.getGovernorates();
    return reply.send({ success: true, data });
  });

  fastify.get<{ Params: { id: string } }>('/api/governorates/:id/cities', async (request, reply) => {
    const govId = parseInt(request.params.id, 10);
    const data = await locationRepository.getCitiesByGovernorate(govId);
    return reply.send({ success: true, data });
  });
};
