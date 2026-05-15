import type { FastifyPluginAsync } from "fastify";
import { z } from "zod";
import { authenticate } from "../middleware/authenticate.js";
import { sendNotificationToComplexManagers } from "../services/notification.js";

const createVehicleSchema = z.object({
  complexId: z.string(),
  plateNumber: z.string().min(4).max(10),
  type: z.enum(["REGISTERED", "VISITOR"]),
  ownerName: z.string().optional(),
  carModel: z.string().optional(),
  memo: z.string().optional(),
  householdId: z.string().optional(),
  // Visitor expiry: specify duration or explicit datetime
  expiresAt: z.string().datetime().optional(),
});

const updateVehicleSchema = createVehicleSchema.partial().omit({ complexId: true });

const vehicleRoutes: FastifyPluginAsync = async (app) => {
  // All routes require authentication
  app.addHook("preHandler", authenticate);

  // ── GET /vehicles ──────────────────────────────────────────────────────────
  app.get("/", async (req) => {
    const query = req.query as Record<string, string>;
    const complexId = query.complexId ?? req.user.complexId;
    const type = query.type as "REGISTERED" | "VISITOR" | undefined;
    const search = query.search;
    const page = Math.max(1, Number(query.page ?? 1));
    const limit = Math.min(100, Math.max(1, Number(query.limit ?? 20)));

    const where: Record<string, unknown> = { complexId };
    if (type) where.type = type;
    if (search) {
      where.OR = [
        { plateNumber: { contains: search } },
        { ownerName: { contains: search } },
      ];
    }

    const [vehicles, total] = await Promise.all([
      app.prisma.vehicle.findMany({
        where,
        include: { household: true },
        orderBy: { updatedAt: "desc" },
        skip: (page - 1) * limit,
        take: limit,
      }),
      app.prisma.vehicle.count({ where }),
    ]);

    return { vehicles, total, page, limit };
  });

  // ── POST /vehicles ──────────────────────────────────────────────────────────
  app.post("/", async (req, reply) => {
    const body = createVehicleSchema.parse(req.body);

    const existing = await app.prisma.vehicle.findUnique({
      where: { complexId_plateNumber: { complexId: body.complexId, plateNumber: body.plateNumber } },
    });
    if (existing) {
      return reply.code(409).send({ error: "이미 등록된 번호판입니다." });
    }

    const vehicle = await app.prisma.vehicle.create({
      data: {
        complexId: body.complexId,
        plateNumber: body.plateNumber,
        type: body.type,
        ownerName: body.ownerName,
        carModel: body.carModel,
        memo: body.memo,
        householdId: body.householdId,
        expiresAt: body.expiresAt ? new Date(body.expiresAt) : undefined,
      },
      include: { household: true },
    });

    // Notify managers when visitor vehicle registered
    if (body.type === "VISITOR") {
      await sendNotificationToComplexManagers(app.prisma, body.complexId, {
        type: "VISITOR_ENTRY",
        title: "방문 차량 등록",
        body: `방문 차량(${body.plateNumber})이 등록되었습니다.`,
        data: { vehicleId: vehicle.id },
      });
    }

    return reply.code(201).send(vehicle);
  });

  // ── GET /vehicles/:id ───────────────────────────────────────────────────────
  app.get("/:id", async (req, reply) => {
    const { id } = req.params as { id: string };

    const vehicle = await app.prisma.vehicle.findUnique({
      where: { id },
      include: { household: true },
    });
    if (!vehicle) return reply.code(404).send({ error: "차량을 찾을 수 없습니다." });

    return vehicle;
  });

  // ── PUT /vehicles/:id ───────────────────────────────────────────────────────
  app.put("/:id", async (req, reply) => {
    const { id } = req.params as { id: string };
    const body = updateVehicleSchema.parse(req.body);

    const vehicle = await app.prisma.vehicle.findUnique({ where: { id } });
    if (!vehicle) return reply.code(404).send({ error: "차량을 찾을 수 없습니다." });

    const updated = await app.prisma.vehicle.update({
      where: { id },
      data: {
        ...body,
        expiresAt: body.expiresAt ? new Date(body.expiresAt) : undefined,
      },
      include: { household: true },
    });

    return updated;
  });

  // ── DELETE /vehicles/:id ────────────────────────────────────────────────────
  app.delete("/:id", async (req, reply) => {
    const { id } = req.params as { id: string };

    const vehicle = await app.prisma.vehicle.findUnique({ where: { id } });
    if (!vehicle) return reply.code(404).send({ error: "차량을 찾을 수 없습니다." });

    await app.prisma.vehicle.delete({ where: { id } });

    return { message: "차량이 삭제되었습니다." };
  });

  // ── GET /vehicles/:id/entry-history ────────────────────────────────────────
  app.get("/:id/entry-history", async (req, reply) => {
    const { id } = req.params as { id: string };
    const query = req.query as Record<string, string>;
    const limit = Math.min(50, Math.max(1, Number(query.limit ?? 20)));

    const vehicle = await app.prisma.vehicle.findUnique({ where: { id } });
    if (!vehicle) return reply.code(404).send({ error: "차량을 찾을 수 없습니다." });

    const logs = await app.prisma.entryLog.findMany({
      where: { vehicleId: id },
      orderBy: { createdAt: "desc" },
      take: limit,
    });

    return { logs };
  });

  // ── POST /vehicles/:id/entry ────────────────────────────────────────────────
  app.post("/:id/entry", async (req, reply) => {
    const { id } = req.params as { id: string };

    const vehicle = await app.prisma.vehicle.findUnique({ where: { id } });
    if (!vehicle) return reply.code(404).send({ error: "차량을 찾을 수 없습니다." });
    if (vehicle.isParked) return reply.code(409).send({ error: "이미 입차 중인 차량입니다." });

    // Check visitor vehicle expiry
    if (vehicle.type === "VISITOR" && vehicle.expiresAt && vehicle.expiresAt < new Date()) {
      return reply.code(422).send({ error: "방문 허가가 만료된 차량입니다." });
    }

    const [log] = await app.prisma.$transaction([
      app.prisma.entryLog.create({
        data: {
          complexId: vehicle.complexId,
          vehicleId: id,
          direction: "ENTRY",
          processedBy: req.user.sub,
        },
      }),
      app.prisma.vehicle.update({
        where: { id },
        data: { isParked: true },
      }),
    ]);

    if (vehicle.type === "VISITOR") {
      await sendNotificationToComplexManagers(app.prisma, vehicle.complexId, {
        type: "VISITOR_ENTRY",
        title: "방문 차량 입차",
        body: `방문 차량(${vehicle.plateNumber})이 입차했습니다.`,
        data: { vehicleId: id },
      });
    }

    return reply.code(201).send(log);
  });

  // ── POST /vehicles/:id/exit ─────────────────────────────────────────────────
  app.post("/:id/exit", async (req, reply) => {
    const { id } = req.params as { id: string };

    const vehicle = await app.prisma.vehicle.findUnique({ where: { id } });
    if (!vehicle) return reply.code(404).send({ error: "차량을 찾을 수 없습니다." });
    if (!vehicle.isParked) return reply.code(409).send({ error: "입차 중이 아닌 차량입니다." });

    const [log] = await app.prisma.$transaction([
      app.prisma.entryLog.create({
        data: {
          complexId: vehicle.complexId,
          vehicleId: id,
          direction: "EXIT",
          processedBy: req.user.sub,
        },
      }),
      app.prisma.vehicle.update({
        where: { id },
        data: { isParked: false },
      }),
    ]);

    return reply.code(201).send(log);
  });

  // ── POST /vehicles/:id/flag-illegal ────────────────────────────────────────
  // 무단주차 마킹
  app.post("/:id/flag-illegal", async (req, reply) => {
    const { id } = req.params as { id: string };
    const body = req.body as { note?: string };

    const vehicle = await app.prisma.vehicle.findUnique({ where: { id } });
    if (!vehicle) return reply.code(404).send({ error: "차량을 찾을 수 없습니다." });

    await app.prisma.entryLog.create({
      data: {
        complexId: vehicle.complexId,
        vehicleId: id,
        direction: "ENTRY",
        processedBy: req.user.sub,
        note: `[무단주차] ${body.note ?? ""}`.trim(),
      },
    });

    await sendNotificationToComplexManagers(app.prisma, vehicle.complexId, {
      type: "ILLEGAL_PARKING",
      title: "무단주차 차량",
      body: `무단주차 차량(${vehicle.plateNumber})이 마킹되었습니다.`,
      data: { vehicleId: id },
    });

    return { message: "무단주차 마킹이 완료되었습니다." };
  });
};

export default vehicleRoutes;
