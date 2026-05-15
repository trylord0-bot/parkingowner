import type { FastifyPluginAsync } from "fastify";
import { z } from "zod";
import { authenticate, requireRole } from "../middleware/authenticate.js";

const createChannelSchema = z.object({
  complexId: z.string(),
  type: z.enum(["ANNOUNCEMENT", "STAFF", "DIRECT"]),
  name: z.string().optional(),
  targetUserId: z.string().optional(), // for DIRECT channels
});

const sendMessageSchema = z.object({
  content: z.string().min(1).max(2000),
});

const channelRoutes: FastifyPluginAsync = async (app) => {
  app.addHook("preHandler", authenticate);

  // ── GET /channels ───────────────────────────────────────────────────────────
  app.get("/", async (req) => {
    const query = req.query as Record<string, string>;
    const complexId = query.complexId ?? req.user.complexId;

    const channels = await app.prisma.channel.findMany({
      where: {
        complexId,
        // For DIRECT channels, only show the current user's channels
        OR: [
          { type: { in: ["ANNOUNCEMENT", "STAFF"] } },
          { type: "DIRECT", targetUserId: req.user.sub },
        ],
      },
      include: {
        messages: {
          orderBy: { createdAt: "desc" },
          take: 1,
          include: { sender: { select: { id: true, name: true } } },
        },
      },
      orderBy: { updatedAt: "desc" },
    });

    return {
      channels: channels.map((ch) => ({
        id: ch.id,
        type: ch.type,
        name: ch.name,
        targetUserId: ch.targetUserId,
        lastMessage: ch.messages[0] ?? null,
        unreadCount: 0, // TODO: implement per-user read tracking
      })),
    };
  });

  // ── POST /channels ──────────────────────────────────────────────────────────
  app.post("/", {
    preHandler: [requireRole("COMPLEX_MANAGER", "ATTENDANT", "APP_ADMIN")],
  }, async (req, reply) => {
    const body = createChannelSchema.parse(req.body);

    // Prevent duplicate DIRECT channels
    if (body.type === "DIRECT" && body.targetUserId) {
      const existing = await app.prisma.channel.findFirst({
        where: { complexId: body.complexId, type: "DIRECT", targetUserId: body.targetUserId },
      });
      if (existing) return existing;
    }

    const channel = await app.prisma.channel.create({
      data: {
        complexId: body.complexId,
        type: body.type,
        name: body.name,
        targetUserId: body.targetUserId,
      },
    });

    return reply.code(201).send(channel);
  });

  // ── GET /channels/:id/messages ───────────────────────────────────────────────
  app.get("/:id/messages", async (req, reply) => {
    const { id } = req.params as { id: string };
    const query = req.query as Record<string, string>;
    const page = Math.max(1, Number(query.page ?? 1));
    const limit = Math.min(100, Math.max(1, Number(query.limit ?? 30)));

    const channel = await app.prisma.channel.findUnique({ where: { id } });
    if (!channel) return reply.code(404).send({ error: "채널을 찾을 수 없습니다." });

    const [messages, total] = await Promise.all([
      app.prisma.message.findMany({
        where: { channelId: id },
        include: { sender: { select: { id: true, name: true } } },
        orderBy: { createdAt: "desc" },
        skip: (page - 1) * limit,
        take: limit,
      }),
      app.prisma.message.count({ where: { channelId: id } }),
    ]);

    return { messages: messages.reverse(), total, page, limit };
  });

  // ── POST /channels/:id/messages ──────────────────────────────────────────────
  app.post("/:id/messages", async (req, reply) => {
    const { id } = req.params as { id: string };
    const body = sendMessageSchema.parse(req.body);

    const channel = await app.prisma.channel.findUnique({ where: { id } });
    if (!channel) return reply.code(404).send({ error: "채널을 찾을 수 없습니다." });

    // ANNOUNCEMENT channel: only managers can write
    if (channel.type === "ANNOUNCEMENT") {
      const role = req.user.role;
      if (!["COMPLEX_MANAGER", "ATTENDANT", "APP_ADMIN"].includes(role)) {
        return reply.code(403).send({ error: "공지사항 채널은 관리자만 작성할 수 있습니다." });
      }
    }

    const message = await app.prisma.message.create({
      data: { channelId: id, senderId: req.user.sub, content: body.content },
      include: { sender: { select: { id: true, name: true } } },
    });

    // Update channel's updatedAt so it bubbles to the top in channel list
    await app.prisma.channel.update({ where: { id }, data: { updatedAt: new Date() } });

    return reply.code(201).send(message);
  });
};

export default channelRoutes;
