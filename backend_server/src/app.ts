import Fastify from "fastify";
import type { FastifyError } from "fastify";
import fastifyRateLimit from "@fastify/rate-limit";
import fastifyStatic from "@fastify/static";
import { mkdir } from "node:fs/promises";
import { join } from "node:path";

import prismaPlugin from "./plugins/prisma.js";
import jwtPlugin from "./plugins/jwt.js";
import corsPlugin from "./plugins/cors.js";

import authRoutes from "./routes/auth.js";
import dashboardRoutes from "./routes/dashboard.js";
import vehicleRoutes from "./routes/vehicles.js";
import entryLogRoutes from "./routes/entry-logs.js";
import scanRoutes from "./routes/scan.js";
import residentRoutes from "./routes/residents.js";
import parkingZoneRoutes from "./routes/parking-zones.js";
import channelRoutes from "./routes/channels.js";
import notificationRoutes from "./routes/notifications.js";
import ocrRoutes from "./routes/ocr.js";
import userRoutes from "./routes/users.js";
import devRoutes from "./routes/dev.js";
import { config } from "./config/index.js";

export async function buildApp() {
  const app = Fastify({
    logger: {
      transport:
        config.NODE_ENV === "development"
          ? { target: "pino-pretty", options: { colorize: true } }
          : undefined,
    },
  });

  // ── Plugins ──────────────────────────────────────────────────────────────
  await app.register(corsPlugin);
  await app.register(jwtPlugin);
  await app.register(prismaPlugin);
  await app.register(fastifyRateLimit, {
    max: 200,
    timeWindow: "1 minute",
  });
  const uploadsDir = join(process.cwd(), "uploads");
  await mkdir(uploadsDir, { recursive: true });
  await app.register(fastifyStatic, {
    root: uploadsDir,
    prefix: "/uploads/",
  });

  // ── Health check ─────────────────────────────────────────────────────────
  app.get("/health", async () => ({ status: "ok", timestamp: new Date().toISOString() }));

  // ── API Routes ───────────────────────────────────────────────────────────
  const API_PREFIX = "/api";

  app.register(authRoutes, { prefix: `${API_PREFIX}/auth` });
  app.register(dashboardRoutes, { prefix: `${API_PREFIX}/dashboard` });
  app.register(vehicleRoutes, { prefix: `${API_PREFIX}/vehicles` });
  app.register(entryLogRoutes, { prefix: `${API_PREFIX}/entry-logs` });
  app.register(scanRoutes, { prefix: `${API_PREFIX}/scan` });
  app.register(residentRoutes, { prefix: `${API_PREFIX}/residents` });
  app.register(parkingZoneRoutes, { prefix: `${API_PREFIX}/parking-zones` });
  app.register(channelRoutes, { prefix: `${API_PREFIX}/channels` });
  app.register(notificationRoutes, { prefix: `${API_PREFIX}/notifications` });
  app.register(ocrRoutes, { prefix: `${API_PREFIX}/ocr` });
  app.register(userRoutes, { prefix: `${API_PREFIX}/users` });

  if (config.NODE_ENV !== "production") {
    app.register(devRoutes, { prefix: `${API_PREFIX}/dev` });
  }

  // ── Global error handler ─────────────────────────────────────────────────
  app.setErrorHandler((error: FastifyError, _req, reply) => {
    app.log.error(error);
    const statusCode = error.statusCode ?? 500;
    reply.code(statusCode).send({
      error: error.message ?? "Internal Server Error",
    });
  });

  return app;
}
