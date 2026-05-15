import type { FastifyPluginAsync } from "fastify";
import { authenticate } from "../middleware/authenticate.js";

const notificationRoutes: FastifyPluginAsync = async (app) => {
  app.addHook("preHandler", authenticate);

  // ── GET /notifications ──────────────────────────────────────────────────────
  app.get("/", async (req) => {
    const query = req.query as Record<string, string>;
    const page = Math.max(1, Number(query.page ?? 1));
    const limit = Math.min(100, Math.max(1, Number(query.limit ?? 20)));

    const where = { userId: req.user.sub };

    const [notifications, total, unreadCount] = await Promise.all([
      app.prisma.notification.findMany({
        where,
        orderBy: { createdAt: "desc" },
        skip: (page - 1) * limit,
        take: limit,
      }),
      app.prisma.notification.count({ where }),
      app.prisma.notification.count({ where: { userId: req.user.sub, isRead: false } }),
    ]);

    return { notifications, total, unreadCount, page, limit };
  });

  // ── POST /notifications/mark-read ───────────────────────────────────────────
  app.post("/mark-read", async (req) => {
    const body = req.body as { ids?: string[]; all?: boolean };

    if (body.all) {
      await app.prisma.notification.updateMany({
        where: { userId: req.user.sub, isRead: false },
        data: { isRead: true },
      });
    } else if (body.ids?.length) {
      await app.prisma.notification.updateMany({
        where: { userId: req.user.sub, id: { in: body.ids } },
        data: { isRead: true },
      });
    }

    return { message: "읽음 처리되었습니다." };
  });

  // ── DELETE /notifications/:id ───────────────────────────────────────────────
  app.delete("/:id", async (req, reply) => {
    const { id } = req.params as { id: string };

    const notification = await app.prisma.notification.findUnique({ where: { id } });
    if (!notification || notification.userId !== req.user.sub) {
      return reply.code(404).send({ error: "알림을 찾을 수 없습니다." });
    }

    await app.prisma.notification.delete({ where: { id } });
    return { message: "알림이 삭제되었습니다." };
  });
};

export default notificationRoutes;
