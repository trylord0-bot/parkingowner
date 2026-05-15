import type { FastifyPluginAsync } from "fastify";
import { authenticate } from "../middleware/authenticate.js";

const dashboardRoutes: FastifyPluginAsync = async (app) => {
  app.addHook("preHandler", authenticate);

  // ── GET /dashboard ─────────────────────────────────────────────────────────
  app.get("/", async (req) => {
    const complexId = (req.query as Record<string, string>).complexId ?? req.user.complexId;
    if (!complexId) return { error: "complexId required" };

    const now = new Date();

    const [
      registeredCount,
      visitorCount,
      expiredVisitorCount,
      unregisteredCount,
      pendingVehicleRequests,
      pendingResidentRequests,
      recentLogs,
      parkingZones,
      totalSlots,
      occupiedCount,
    ] = await Promise.all([
      app.prisma.vehicle.count({ where: { complexId, type: "REGISTERED" } }),
      app.prisma.vehicle.count({
        where: { complexId, type: "VISITOR", OR: [{ expiresAt: null }, { expiresAt: { gt: now } }] },
      }),
      app.prisma.vehicle.count({
        where: { complexId, type: "VISITOR", expiresAt: { lte: now } },
      }),
      // Unregistered: vehicles that appeared in entry logs but not in vehicles table
      // We track via entry logs with note containing [미등록]
      app.prisma.entryLog.count({
        where: { complexId, note: { contains: "[미등록]" } },
      }),
      app.prisma.request.count({
        where: { complexId, type: "VEHICLE_REGISTER", status: "PENDING" },
      }),
      app.prisma.request.count({
        where: { complexId, type: "RESIDENT_JOIN", status: "PENDING" },
      }),
      app.prisma.entryLog.findMany({
        where: { complexId },
        include: { vehicle: true },
        orderBy: { createdAt: "desc" },
        take: 10,
      }),
      app.prisma.parkingZone.findMany({ where: { complexId } }),
      app.prisma.parkingZone.aggregate({ where: { complexId }, _sum: { totalSlots: true } }),
      app.prisma.vehicle.count({ where: { complexId, isParked: true } }),
    ]);

    return {
      stats: {
        registeredVehicles: registeredCount,
        visitorVehicles: visitorCount,
        expiredVisitors: expiredVisitorCount,
        unregisteredDetected: unregisteredCount,
        totalSlots: totalSlots._sum.totalSlots ?? 0,
        occupiedSlots: occupiedCount,
      },
      pendingRequests: {
        vehicleRegister: pendingVehicleRequests,
        residentJoin: pendingResidentRequests,
        total: pendingVehicleRequests + pendingResidentRequests,
      },
      recentActivity: recentLogs.map((log) => ({
        id: log.id,
        plateNumber: log.vehicle.plateNumber,
        vehicleType: log.vehicle.type,
        direction: log.direction,
        note: log.note,
        createdAt: log.createdAt,
      })),
      parkingZones: parkingZones.map((z) => ({
        id: z.id,
        name: z.name,
        totalSlots: z.totalSlots,
      })),
    };
  });
};

export default dashboardRoutes;
