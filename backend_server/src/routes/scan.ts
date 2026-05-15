import type { FastifyPluginAsync } from "fastify";
import { z } from "zod";
import { authenticate } from "../middleware/authenticate.js";
import { sendNotificationToComplexManagers } from "../services/notification.js";

const lookupSchema = z.object({
  plateNumber: z.string().min(4).max(10),
  complexId: z.string().optional(),
});

const scanRoutes: FastifyPluginAsync = async (app) => {
  app.addHook("preHandler", authenticate);

  // ── POST /scan/lookup ───────────────────────────────────────────────────────
  // Look up a vehicle by plate number after OCR scan
  app.post("/lookup", async (req) => {
    const body = lookupSchema.parse(req.body);
    const complexId = body.complexId ?? req.user.complexId;

    const now = new Date();
    const vehicle = await app.prisma.vehicle.findUnique({
      where: { complexId_plateNumber: { complexId: complexId!, plateNumber: body.plateNumber } },
      include: {
        household: true,
        entryLogs: { orderBy: { createdAt: "desc" }, take: 5 },
      },
    });

    if (!vehicle) {
      return {
        found: false,
        plateNumber: body.plateNumber,
        status: "UNREGISTERED",
      };
    }

    let status: "REGISTERED" | "VISITOR_VALID" | "VISITOR_EXPIRED" | "UNREGISTERED" = "REGISTERED";
    if (vehicle.type === "VISITOR") {
      status = vehicle.expiresAt && vehicle.expiresAt < now ? "VISITOR_EXPIRED" : "VISITOR_VALID";
    }

    return {
      found: true,
      status,
      vehicle: {
        id: vehicle.id,
        plateNumber: vehicle.plateNumber,
        type: vehicle.type,
        ownerName: vehicle.ownerName,
        carModel: vehicle.carModel,
        isParked: vehicle.isParked,
        expiresAt: vehicle.expiresAt,
        household: vehicle.household
          ? { building: vehicle.household.building, unit: vehicle.household.unit }
          : null,
        recentLogs: vehicle.entryLogs.map((l) => ({
          direction: l.direction,
          note: l.note,
          createdAt: l.createdAt,
        })),
      },
    };
  });

  // ── POST /scan/report-unregistered ──────────────────────────────────────────
  // Resident or attendant reporting an unregistered vehicle detected via scan
  app.post("/report-unregistered", async (req, reply) => {
    const body = req.body as {
      plateNumber: string;
      complexId?: string;
      imageCroppedUrl?: string;
      note?: string;
    };

    const complexId = body.complexId ?? req.user.complexId;
    if (!complexId) return reply.code(400).send({ error: "complexId required" });

    await sendNotificationToComplexManagers(app.prisma, complexId, {
      type: "UNREGISTERED_DETECTED",
      title: "⚠️ 미등록 차량 감지",
      body: `미등록 차량(${body.plateNumber})이 감지되었습니다.`,
      data: { plateNumber: body.plateNumber, imageCroppedUrl: body.imageCroppedUrl },
    });

    return { message: "알림이 발송되었습니다." };
  });
};

export default scanRoutes;
