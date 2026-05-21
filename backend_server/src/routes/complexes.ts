import type { FastifyPluginAsync } from "fastify";
import { z } from "zod";
import { authenticate } from "../middleware/authenticate.js";

const checkQuerySchema = z.object({
  roadAddress: z.string().min(1),
});

const createComplexSchema = z.object({
  roadAddress: z.string().min(1).max(255),
  jibunAddress: z.string().max(255).optional().nullable(),
  zipCode: z.string().max(20).optional().nullable(),
  buildingName: z.string().max(100).optional().nullable(),
  alias: z.string().min(1).max(100),
});

const inviteCodeSchema = z.object({
  code: z.string().min(1).max(32),
});

const normalizeAddress = (value: string) => value.trim().replace(/\s+/g, " ");
const normalizeOptional = (value?: string | null) => {
  const trimmed = value?.trim();
  return trimmed ? trimmed : null;
};

const splitRoadAddress = (value: string) => {
  const normalized = normalizeAddress(value);
  const match = normalized.match(/^(.*)\(([^()]*)\)\s*$/);
  if (!match) return { roadAddress: normalized, buildingName: null };

  const roadAddress = normalizeAddress(match[1]);
  const parenthetical = match[2]?.trim();
  const buildingName = parenthetical
    ?.split(",")
    .map((part) => part.trim())
    .filter(Boolean)
    .at(-1) ?? null;

  if (!roadAddress || !buildingName) return { roadAddress: normalized, buildingName: null };
  return { roadAddress, buildingName };
};

const complexRoutes: FastifyPluginAsync = async (app) => {
  app.addHook("preHandler", authenticate);

  // GET /complexes/check?roadAddress=...
  app.get("/check", async (req) => {
    const query = checkQuerySchema.parse(req.query);
    const parsedAddress = splitRoadAddress(query.roadAddress);
    const roadAddress = parsedAddress.roadAddress;

    const complex = await app.prisma.complex.findUnique({
      where: { roadAddress },
      select: {
        id: true,
        roadAddress: true,
        jibunAddress: true,
        zipCode: true,
        buildingName: true,
        alias: true,
        name: true,
      },
    });

    if (!complex) {
      return { exists: false, roadAddress };
    }

    return {
      exists: true,
      complex: {
        id: complex.id,
        roadAddress: complex.roadAddress,
        jibunAddress: complex.jibunAddress,
        zipCode: complex.zipCode,
        buildingName: complex.buildingName,
        alias: complex.alias || complex.name,
      },
    };
  });

  // POST /complexes
  app.post("/", async (req, reply) => {
    const body = createComplexSchema.parse(req.body);
    const parsedAddress = splitRoadAddress(body.roadAddress);
    const roadAddress = parsedAddress.roadAddress;
    const buildingName = normalizeOptional(body.buildingName) ?? parsedAddress.buildingName;
    const alias = body.alias.trim();

    const existing = await app.prisma.complex.findUnique({
      where: { roadAddress },
    });
    if (existing) {
      return reply.code(409).send({ error: "이미 등록된 단지 주소입니다." });
    }

    const complex = await app.prisma.$transaction(async (tx) => {
      const created = await tx.complex.create({
        data: {
          name: alias,
          address: roadAddress,
          roadAddress,
          jibunAddress: normalizeOptional(body.jibunAddress),
          zipCode: normalizeOptional(body.zipCode),
          buildingName,
          alias,
          totalSlots: 0,
        },
      });

      await tx.complexMember.create({
        data: {
          userId: req.user.sub,
          complexId: created.id,
          role: "COMPLEX_MANAGER",
        },
      });

      await tx.user.update({
        where: { id: req.user.sub },
        data: { currentComplexId: created.id },
      });

      return created;
    });

    return reply.code(201).send({
      complex: {
        id: complex.id,
        roadAddress: complex.roadAddress,
        jibunAddress: complex.jibunAddress,
        zipCode: complex.zipCode,
        buildingName: complex.buildingName,
        alias: complex.alias,
      },
    });
  });

  // POST /complexes/:complexId/join-request
  app.post("/:complexId/join-request", async (req, reply) => {
    const { complexId } = req.params as { complexId: string };
    const complex = await app.prisma.complex.findUnique({ where: { id: complexId } });
    if (!complex) return reply.code(404).send({ error: "단지를 찾을 수 없습니다." });

    const existingMember = await app.prisma.complexMember.findUnique({
      where: { userId_complexId: { userId: req.user.sub, complexId } },
    });
    if (existingMember?.isActive) {
      await app.prisma.user.update({
        where: { id: req.user.sub },
        data: { currentComplexId: complexId },
      });
      return { message: "이미 가입된 단지로 전환했습니다." };
    }

    await app.prisma.$transaction(async (tx) => {
      const pending = await tx.request.findFirst({
        where: {
          complexId,
          requesterId: req.user.sub,
          type: "RESIDENT_JOIN",
          status: "PENDING",
        },
      });

      if (!pending) {
        await tx.request.create({
          data: {
            complexId,
            requesterId: req.user.sub,
            type: "RESIDENT_JOIN",
          },
        });
      }

      await tx.user.update({
        where: { id: req.user.sub },
        data: { currentComplexId: complexId },
      });
    });

    return reply.code(201).send({
      message: "입주민 가입 요청이 접수되었습니다.",
      complex: {
        id: complex.id,
        alias: complex.alias,
        roadAddress: complex.roadAddress,
        buildingName: complex.buildingName,
      },
    });
  });

  // POST /complexes/use-invite
  app.post("/use-invite", async (req, reply) => {
    const body = inviteCodeSchema.parse(req.body);
    const invite = await app.prisma.inviteCode.findUnique({
      where: { code: body.code.trim() },
      include: { complex: true },
    });

    if (!invite) return reply.code(400).send({ error: "유효하지 않은 초대 코드입니다." });
    if (invite.usedAt) return reply.code(409).send({ error: "이미 사용된 초대 코드입니다." });
    if (invite.expiresAt < new Date()) return reply.code(410).send({ error: "만료된 초대 코드입니다." });

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
      app.prisma.user.update({
        where: { id: req.user.sub },
        data: { currentComplexId: invite.complexId },
      }),
    ]);

    return {
      message: "단지 가입이 완료되었습니다.",
      complex: {
        id: invite.complex.id,
        alias: invite.complex.alias,
        roadAddress: invite.complex.roadAddress,
        buildingName: invite.complex.buildingName,
      },
    };
  });
};

export default complexRoutes;
