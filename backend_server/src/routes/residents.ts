import type { FastifyPluginAsync } from "fastify";
import { z } from "zod";
import { authenticate, requireRole } from "../middleware/authenticate.js";
import { sendNotificationToUser, sendNotificationToComplexManagers } from "../services/notification.js";
import { nanoid } from "nanoid";
import { addDays } from "../utils/date.js";

const joinRequestSchema = z.object({
  complexId: z.string(),
  householdBuilding: z.string().optional(),
  householdUnit: z.string(),
  relationship: z.string().optional(),
});

const inviteCodeSchema = z.object({
  complexId: z.string(),
  expiresInDays: z.number().int().min(1).max(30).default(7),
});

const residentRoutes: FastifyPluginAsync = async (app) => {
  app.addHook("preHandler", authenticate);

  // ── GET /residents ──────────────────────────────────────────────────────────
  // List complex members (residents)
  app.get("/", async (req) => {
    const query = req.query as Record<string, string>;
    const complexId = query.complexId ?? req.user.complexId;
    const status = query.status; // "approved" | "pending"
    const page = Math.max(1, Number(query.page ?? 1));
    const limit = Math.min(100, Math.max(1, Number(query.limit ?? 20)));

    if (status === "pending") {
      const [requests, total] = await Promise.all([
        app.prisma.request.findMany({
          where: { complexId, type: "RESIDENT_JOIN", status: "PENDING" },
          include: { requester: true, household: true },
          orderBy: { createdAt: "desc" },
          skip: (page - 1) * limit,
          take: limit,
        }),
        app.prisma.request.count({
          where: { complexId, type: "RESIDENT_JOIN", status: "PENDING" },
        }),
      ]);
      return { requests, total, page, limit };
    }

    const [members, total] = await Promise.all([
      app.prisma.complexMember.findMany({
        where: { complexId, isActive: true },
        include: { user: true },
        orderBy: { joinedAt: "desc" },
        skip: (page - 1) * limit,
        take: limit,
      }),
      app.prisma.complexMember.count({ where: { complexId, isActive: true } }),
    ]);

    return {
      members: members.map((m) => ({
        id: m.id,
        userId: m.userId,
        name: m.user.name,
        email: m.user.email,
        phone: m.user.phone,
        role: m.role,
        joinedAt: m.joinedAt,
      })),
      total,
      page,
      limit,
    };
  });

  // ── POST /residents/join-request ────────────────────────────────────────────
  // Resident submits a join request for a complex
  app.post("/join-request", async (req, reply) => {
    const body = joinRequestSchema.parse(req.body);

    // Find or create household
    let household = await app.prisma.household.findFirst({
      where: {
        complexId: body.complexId,
        building: body.householdBuilding ?? null,
        unit: body.householdUnit,
      },
    });
    if (!household) {
      household = await app.prisma.household.create({
        data: {
          complexId: body.complexId,
          building: body.householdBuilding,
          unit: body.householdUnit,
        },
      });
    }

    const existing = await app.prisma.request.findFirst({
      where: {
        complexId: body.complexId,
        requesterId: req.user.sub,
        type: "RESIDENT_JOIN",
        status: "PENDING",
      },
    });
    if (existing) {
      return reply.code(409).send({ error: "이미 처리 중인 가입 요청이 있습니다." });
    }

    const request = await app.prisma.request.create({
      data: {
        complexId: body.complexId,
        requesterId: req.user.sub,
        type: "RESIDENT_JOIN",
        householdId: household.id,
        relationship: body.relationship,
      },
    });

    await sendNotificationToComplexManagers(app.prisma, body.complexId, {
      type: "RESIDENT_JOIN_REQUEST",
      title: "세대원 가입 요청",
      body: `새로운 세대원 가입 요청이 접수되었습니다. (${body.householdBuilding ? `${body.householdBuilding}동 ` : ""}${body.householdUnit}호)`,
      data: { requestId: request.id },
    });

    return reply.code(201).send(request);
  });

  // ── POST /residents/:requestId/approve ──────────────────────────────────────
  app.post("/:requestId/approve", {
    preHandler: [requireRole("COMPLEX_MANAGER", "ATTENDANT", "APP_ADMIN")],
  }, async (req, reply) => {
    const { requestId } = req.params as { requestId: string };

    const request = await app.prisma.request.findUnique({
      where: { id: requestId },
      include: { requester: true },
    });
    if (!request) return reply.code(404).send({ error: "요청을 찾을 수 없습니다." });
    if (request.status !== "PENDING") {
      return reply.code(409).send({ error: "이미 처리된 요청입니다." });
    }

    await app.prisma.$transaction([
      app.prisma.request.update({
        where: { id: requestId },
        data: { status: "APPROVED", approverId: req.user.sub },
      }),
      app.prisma.complexMember.upsert({
        where: { userId_complexId: { userId: request.requesterId, complexId: request.complexId } },
        create: {
          userId: request.requesterId,
          complexId: request.complexId,
          role: "RESIDENT",
        },
        update: { isActive: true },
      }),
    ]);

    await sendNotificationToUser(app.prisma, request.requesterId, {
      type: "REQUEST_APPROVED",
      title: "가입 요청 승인",
      body: "단지 가입 요청이 승인되었습니다.",
      data: { requestId },
    });

    return { message: "세대원 가입이 승인되었습니다." };
  });

  // ── POST /residents/:requestId/reject ───────────────────────────────────────
  app.post("/:requestId/reject", {
    preHandler: [requireRole("COMPLEX_MANAGER", "ATTENDANT", "APP_ADMIN")],
  }, async (req, reply) => {
    const { requestId } = req.params as { requestId: string };
    const body = req.body as { reason?: string };

    const request = await app.prisma.request.findUnique({ where: { id: requestId } });
    if (!request) return reply.code(404).send({ error: "요청을 찾을 수 없습니다." });
    if (request.status !== "PENDING") {
      return reply.code(409).send({ error: "이미 처리된 요청입니다." });
    }

    await app.prisma.request.update({
      where: { id: requestId },
      data: { status: "REJECTED", approverId: req.user.sub, rejectionReason: body.reason },
    });

    await sendNotificationToUser(app.prisma, request.requesterId, {
      type: "REQUEST_REJECTED",
      title: "가입 요청 거절",
      body: body.reason ? `가입 요청이 거절되었습니다. 사유: ${body.reason}` : "가입 요청이 거절되었습니다.",
      data: { requestId },
    });

    return { message: "세대원 가입 요청이 거절되었습니다." };
  });

  // ── POST /residents/invite ──────────────────────────────────────────────────
  // Issue invite code for a complex
  app.post("/invite", {
    preHandler: [requireRole("COMPLEX_MANAGER", "ATTENDANT", "APP_ADMIN")],
  }, async (req, reply) => {
    const body = inviteCodeSchema.parse(req.body);

    const code = nanoid(8).toUpperCase();
    const invite = await app.prisma.inviteCode.create({
      data: {
        complexId: body.complexId,
        code,
        issuedById: req.user.sub,
        expiresAt: addDays(new Date(), body.expiresInDays),
      },
    });

    return reply.code(201).send({ code: invite.code, expiresAt: invite.expiresAt });
  });

  // ── POST /residents/use-invite ──────────────────────────────────────────────
  // Resident uses invite code to join complex immediately
  app.post("/use-invite", async (req, reply) => {
    const body = req.body as { code: string; householdUnit: string; householdBuilding?: string };

    const invite = await app.prisma.inviteCode.findUnique({
      where: { code: body.code },
      include: { complex: true },
    });

    if (!invite) return reply.code(400).send({ error: "유효하지 않은 초대 코드입니다." });
    if (invite.usedAt) return reply.code(409).send({ error: "이미 사용된 초대 코드입니다." });
    if (invite.expiresAt < new Date()) return reply.code(410).send({ error: "만료된 초대 코드입니다." });

    let household = await app.prisma.household.findFirst({
      where: {
        complexId: invite.complexId,
        building: body.householdBuilding ?? null,
        unit: body.householdUnit,
      },
    });
    if (!household) {
      household = await app.prisma.household.create({
        data: {
          complexId: invite.complexId,
          building: body.householdBuilding,
          unit: body.householdUnit,
        },
      });
    }

    await app.prisma.$transaction([
      app.prisma.inviteCode.update({
        where: { id: invite.id },
        data: { usedById: req.user.sub, usedAt: new Date() },
      }),
      app.prisma.complexMember.upsert({
        where: { userId_complexId: { userId: req.user.sub, complexId: invite.complexId } },
        create: { userId: req.user.sub, complexId: invite.complexId, role: "RESIDENT" },
        update: { isActive: true },
      }),
    ]);

    await sendNotificationToComplexManagers(app.prisma, invite.complexId, {
      type: "INVITE_CODE_USED",
      title: "초대코드 사용됨",
      body: `초대코드(${body.code})가 사용되어 새 세대원이 가입했습니다.`,
      data: { code: body.code },
    });

    return { message: "단지 가입이 완료되었습니다.", complexName: invite.complex.name };
  });

  // ── DELETE /residents/:memberId ─────────────────────────────────────────────
  app.delete("/:memberId", {
    preHandler: [requireRole("COMPLEX_MANAGER", "APP_ADMIN")],
  }, async (req, reply) => {
    const { memberId } = req.params as { memberId: string };

    const member = await app.prisma.complexMember.findUnique({ where: { id: memberId } });
    if (!member) return reply.code(404).send({ error: "세대원을 찾을 수 없습니다." });

    await app.prisma.complexMember.update({
      where: { id: memberId },
      data: { isActive: false },
    });

    return { message: "세대원이 제거되었습니다." };
  });
};

export default residentRoutes;
