import fastifyCors from "@fastify/cors";
import fp from "fastify-plugin";
import type { FastifyPluginAsync } from "fastify";
import { config } from "../config/index.js";

const corsPlugin: FastifyPluginAsync = fp(async (app) => {
  app.register(fastifyCors, {
    origin: config.NODE_ENV === "development" ? true : ["https://parkingowner.com"],
    credentials: true,
  });
});

export default corsPlugin;
