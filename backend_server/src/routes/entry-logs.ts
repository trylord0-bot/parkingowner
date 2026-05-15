import type { FastifyPluginAsync } from "fastify";
import { authenticate } from "../middleware/authenticate.js";

const entryLogRoutes: FastifyPluginAsync = async (app) => {
  app.addHook("preHandler", authenticate);

  // ── GET /entry-logs ─────────────────────────────────────────────────────────
  app.get("/", async (req) => {
    const query = req.query as Record<string, string>;
    const complexId = query.complexId ?? req.user.complexId;
    const direction = query.direction as "ENTRY" | "EXIT" | undefined;
    const page = Math.max(1, Number(query.page ?? 1));
    const limit = Math.min(100, Math.max(1, Number(query.limit ?? 20)));

    const where: Record<string, unknown> = { complexId };
    if (direction) where.direction = direction;

    const [logs, total] = await Promise.all([
      app.prisma.entryLog.findMany({
        where,
        include: { vehicle: { include: { household: true } } },
        orderBy: { createdAt: "desc" },
        skip: (page - 1) * limit,
        take: limit,
      }),
      app.prisma.entryLog.count({ where }),
    ]);

    return { logs, total, page, limit };
  });

  // ── POST /entry-logs/unregistered ───────────────────────────────────────────
  // Record an unregistered vehicle detection (from scan by resident or attendant)
  app.post("/unregistered", async (req, reply) => {
    const body = req.body as {
      complexId?: string;
      plateNumber: string;
      imageUrl?: string;
      note?: string;
    };

    const complexId = body.complexId ?? req.user.complexId;
    if (!complexId) return reply.code(400).send({ error: "complexId required" });

    // Log as entry with [미등록] marker — no vehicle record needed
    // We create a temporary vehicle entry or just log the plate in note
    const log = await app.prisma.entryLog.create({
      data: {
        complexId,
        vehicleId: await getOrCreateTempVehicle(app.prisma, complexId, body.plateNumber),
        direction: "ENTRY",
        processedBy: req.user.sub,
        note: `[미등록] ${body.note ?? ""}`.trim(),
      },
    });

    return reply.code(201).send(log);
  });
};

async function getOrCreateTempVehicle(
  prisma: import("@prisma/client").PrismaClient,
  complexId: string,
  plateNumber: string
): Promise<string> {
  const existing = await prisma.vehicle.findUnique({
    where: { complexId_plateNumber: { complexId, plateNumber } },
  });
  if (existing) return existing.id;

  const created = await prisma.vehicle.create({
    data: { complexId, plateNumber, type: "REGISTERED" },
  });
  return created.id;
}

export default entryLogRoutes;
