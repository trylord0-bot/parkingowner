import cron from "node-cron";
import type { FastifyInstance } from "fastify";
import { config } from "../config/index.js";
import { sendNotificationToComplexManagers } from "./notification.js";

export function startCronJobs(app: FastifyInstance) {
  // ── 1. Daily report — 09:00 KST (00:00 UTC) ─────────────────────────────────
  cron.schedule(config.DAILY_REPORT_CRON, async () => {
    app.log.info("📊 Running daily report cron...");
    try {
      await sendDailyReports(app);
    } catch (err) {
      app.log.error({ err }, "Daily report cron failed");
    }
  });

  // ── 2. Visitor expiry check — every 30 minutes ──────────────────────────────
  cron.schedule("*/30 * * * *", async () => {
    try {
      await checkVisitorExpiry(app);
    } catch (err) {
      app.log.error({ err }, "Visitor expiry cron failed");
    }
  });

  app.log.info("⏰ Cron jobs started.");
}

async function sendDailyReports(app: FastifyInstance) {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const tomorrow = new Date(today);
  tomorrow.setDate(tomorrow.getDate() + 1);

  const complexes = await app.prisma.complex.findMany({
    where: { isActive: true },
    select: { id: true, name: true },
  });

  for (const complex of complexes) {
    const [entries, exits, unregistered] = await Promise.all([
      app.prisma.entryLog.count({
        where: {
          complexId: complex.id,
          direction: "ENTRY",
          note: { not: { contains: "[미등록]" } },
          createdAt: { gte: today, lt: tomorrow },
        },
      }),
      app.prisma.entryLog.count({
        where: {
          complexId: complex.id,
          direction: "EXIT",
          createdAt: { gte: today, lt: tomorrow },
        },
      }),
      app.prisma.entryLog.count({
        where: {
          complexId: complex.id,
          note: { contains: "[미등록]" },
          createdAt: { gte: today, lt: tomorrow },
        },
      }),
    ]);

    await sendNotificationToComplexManagers(app.prisma, complex.id, {
      type: "DAILY_REPORT",
      title: "📊 일일 리포트",
      body: `입차 ${entries}건 | 출차 ${exits}건 | 미등록 감지 ${unregistered}건`,
      data: { complexId: complex.id, entries: String(entries), exits: String(exits), unregistered: String(unregistered) },
    });
  }
}

async function checkVisitorExpiry(app: FastifyInstance) {
  const now = new Date();
  const in30Min = new Date(now.getTime() + 30 * 60_000);

  // Vehicles expiring within 30 minutes — send "expiring soon" alert
  const expiringSoon = await app.prisma.vehicle.findMany({
    where: {
      type: "VISITOR",
      expiresAt: { gt: now, lte: in30Min },
    },
  });

  for (const v of expiringSoon) {
    await sendNotificationToComplexManagers(app.prisma, v.complexId, {
      type: "VISITOR_EXPIRING",
      title: "⏰ 방문 허가 만료 임박",
      body: `방문 차량(${v.plateNumber})의 허가가 곧 만료됩니다.`,
      data: { vehicleId: v.id },
    });
  }

  // Vehicles already expired but still marked as parked
  const expired = await app.prisma.vehicle.findMany({
    where: { type: "VISITOR", expiresAt: { lte: now }, isParked: true },
  });

  for (const v of expired) {
    await sendNotificationToComplexManagers(app.prisma, v.complexId, {
      type: "VISITOR_EXPIRED",
      title: "🔴 방문 허가 만료",
      body: `방문 차량(${v.plateNumber})의 허가가 만료되었습니다.`,
      data: { vehicleId: v.id },
    });
  }
}
