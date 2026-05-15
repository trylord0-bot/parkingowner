import fastifyJwt from "@fastify/jwt";
import fp from "fastify-plugin";
import type { FastifyPluginAsync } from "fastify";
import { config } from "../config/index.js";

const jwtPlugin: FastifyPluginAsync = fp(async (app) => {
  app.register(fastifyJwt, {
    secret: config.JWT_SECRET,
    sign: { expiresIn: config.JWT_ACCESS_EXPIRES },
  });
});

export default jwtPlugin;
