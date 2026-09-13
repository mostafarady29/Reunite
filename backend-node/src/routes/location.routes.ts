import { FastifyPluginAsync } from 'fastify';
import { locationRepository } from '../repositories/location.repository.js';

export const locationRoutes: FastifyPluginAsync = async (fastify) => {
  const getGovernorates = async (_request: any, reply: any) => {
    const data = await locationRepository.getGovernorates();
    return reply.send({ success: true, data });
  };
  fastify.get('/api/governorates', getGovernorates);
  fastify.get('/governorates', getGovernorates);

  const getCities = async (request: any, reply: any) => {
    const govId = parseInt(request.params.id, 10);
    const data = await locationRepository.getCitiesByGovernorate(govId);
    return reply.send({ success: true, data });
  };
  fastify.get('/api/governorates/:id/cities', getCities);
  fastify.get('/governorates/:id/cities', getCities);
};
