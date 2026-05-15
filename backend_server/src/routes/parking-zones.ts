import type { FastifyPluginAsync } from "fastify";
import { z } from "zod";
import { authenticate, requireRole } from "../middleware/authenticate.js";

const createZoneSchema = z.object({
  complexId: z.string(),
  name: z.string().min(1).max(50),
  totalSlots: z.number().int().min(0),
});

const updateZoneSchema = z.object({
  name: z.string().min(1).max(50).optional(),
  totalSlots: z.number().int().min(0).optional(),
});

const parkingZoneRoutes: FastifyPluginAsync = async (app) => {
  app.addHook("preHandler", authenticate);

  // ── GET /parking-zones ──────────────────────────────────────────────────────
  app.get("/", async (req) => {
    const query = req.query as Record<string, string>;
    const complexId = query.complexId ?? req.user.complexId;

    const zones = await app.prisma.parkingZone.findMany({
      where: { complexId },
      orderBy: { createdAt: "asc" },
    });

    // Get total occupied vehicles for the complex
    const occupiedCount = await app.prisma.vehicle.count({
      where: { complexId, isParked: true },
    });

    const totalSlots = zones.reduce((sum, z) => sum + z.totalSlots, 0);
    const occupancyRate = totalSlots > 0 ? Math.round((occupiedCount / totalSlots) * 100) : 0;

    return {
      zones,
      summary: {
        totalSlots,
        occupiedSlots: occupiedCount,
        availableSlots: Math.max(0, totalSlots - occupiedCount),
        occupancyRate,
      },
    };
  });

  // ── POST /parking-zones ─────────────────────────────────────────────────────
  app.post("/", {
    preHandler: [requireRole("COMPLEX_MANAGER", "APP_ADMIN")],
  }, async (req, reply) => {
    const body = createZoneSchema.parse(req.body);

    const zone = await app.prisma.parkingZone.create({
      data: { complexId: body.complexId, name: body.name, totalSlots: body.totalSlots },
    });

    return reply.code(201).send(zone);
  });

  // ── PUT /parking-zones/:id ──────────────────────────────────────────────────
  app.put("/:id", {
    preHandler: [requireRole("COMPLEX_MANAGER", "APP_ADMIN")],
  }, async (req, reply) => {
    const { id } = req.params as { id: string };
    const body = updateZoneSchema.parse(req.body);

    const zone = await app.prisma.parkingZone.findUnique({ where: { id } });
    if (!zone) return reply.code(404).send({ error: "주차 구역을 찾을 수 없습니다." });

    const updated = await app.prisma.parkingZone.update({ where: { id }, data: body });
    return updated;
  });

  // ── DELETE /parking-zones/:id ───────────────────────────────────────────────
  app.delete("/:id", {
    preHandler: [requireRole("COMPLEX_MANAGER", "APP_ADMIN")],
  }, async (req, reply) => {
    const { id } = req.params as { id: string };

    const zone = await app.prisma.parkingZone.findUnique({ where: { id } });
    if (!zone) return reply.code(404).send({ error: "주차 구역을 찾을 수 없습니다." });

    await app.prisma.parkingZone.delete({ where: { id } });
    return { message: "주차 구역이 삭제되었습니다." };
  });
};

export default parkingZoneRoutes;
