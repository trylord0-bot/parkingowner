import type { FastifyPluginAsync } from "fastify";
import bcrypt from "bcryptjs";
import { z } from "zod";
import { authenticate } from "../middleware/authenticate.js";
import { config } from "../config/index.js";
import { nanoid } from "nanoid";
import { addDays, addMinutes } from "../utils/date.js";
import { sendVerificationEmail, sendPasswordResetEmail } from "../services/email.js";

const registerSchema = z.object({
  name: z.string().min(1).max(50),
  email: z.string().email(),
  password: z.string().min(8).max(100),
});

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string(),
});

const refreshSchema = z.object({
  refreshToken: z.string(),
});

const verifyEmailSchema = z.object({
  email: z.string().email(),
  code: z.string().length(6),
});

const resendVerificationSchema = z.object({
  email: z.string().email(),
});

const forgotPasswordSchema = z.object({
  email: z.string().email(),
});

const resetPasswordSchema = z.object({
  token: z.string(),
  password: z.string().min(8).max(100),
});

const updateFcmTokenSchema = z.object({
  fcmToken: z.string(),
});

const authRoutes: FastifyPluginAsync = async (app) => {
  // ── POST /auth/register ──────────────────────────────────────────────────
  app.post("/register", async (req, reply) => {
    const body = registerSchema.parse(req.body);

    const existing = await app.prisma.user.findUnique({ where: { email: body.email } });
    if (existing) {
      return reply.code(409).send({ error: "이미 사용 중인 이메일입니다." });
    }

    const hashed = await bcrypt.hash(body.password, 12);
    const emailVerifyCode = String(Math.floor(100000 + Math.random() * 900000));
    const emailVerifyExpiresAt = addMinutes(new Date(), 10);

    const user = await app.prisma.user.create({
      data: {
        name: body.name,
        email: body.email,
        password: hashed,
        emailVerifyToken: emailVerifyCode,
        emailVerifyExpiresAt,
      } as any,
    });

    await sendVerificationEmail(user.email, emailVerifyCode).catch((err) =>
      app.log.error({ err }, "Failed to send verification email")
    );

    return reply.code(201).send({
      message: "회원가입이 완료되었습니다. 이메일을 확인해 주세요.",
      userId: user.id,
    });
  });

  // ── POST /auth/verify-email ──────────────────────────────────────────────
  app.post("/verify-email", async (req, reply) => {
    const { email, code } = verifyEmailSchema.parse(req.body);

    const user = await app.prisma.user.findUnique({ where: { email } });
    if (
      !user ||
      user.emailVerifyToken !== code ||
      !(user as any).emailVerifyExpiresAt ||
      (user as any).emailVerifyExpiresAt < new Date()
    ) {
      return reply.code(400).send({ error: "인증 코드가 유효하지 않거나 만료되었습니다." });
    }

    await app.prisma.user.update({
      where: { id: user.id },
      data: { emailVerified: true, emailVerifyToken: null, emailVerifyExpiresAt: null } as any,
    });

    return { message: "이메일 인증이 완료되었습니다." };
  });

  // ── POST /auth/resend-verification ──────────────────────────────────────
  app.post("/resend-verification", async (req, reply) => {
    const { email } = resendVerificationSchema.parse(req.body);

    const user = await app.prisma.user.findUnique({ where: { email } });
    if (!user || user.emailVerified) {
      return { message: "인증 코드를 발송했습니다." };
    }

    const emailVerifyCode = String(Math.floor(100000 + Math.random() * 900000));
    const emailVerifyExpiresAt = addMinutes(new Date(), 10);

    await app.prisma.user.update({
      where: { id: user.id },
      data: { emailVerifyToken: emailVerifyCode, emailVerifyExpiresAt } as any,
    });

    await sendVerificationEmail(email, emailVerifyCode).catch((err) =>
      app.log.error({ err }, "Failed to resend verification email")
    );

    return { message: "인증 코드를 발송했습니다." };
  });

  // ── POST /auth/login ─────────────────────────────────────────────────────
  app.post("/login", async (req, reply) => {
    const body = loginSchema.parse(req.body);

    const user = await app.prisma.user.findUnique({
      where: { email: body.email },
      include: {
        currentComplex: true,
        complexMembers: { where: { isActive: true } },
      },
    });

    if (!user || !user.password) {
      return reply.code(401).send({ error: "이메일 또는 비밀번호가 올바르지 않습니다." });
    }

    const valid = await bcrypt.compare(body.password, user.password);
    if (!valid) {
      return reply.code(401).send({ error: "이메일 또는 비밀번호가 올바르지 않습니다." });
    }

    if (!user.isActive) {
      return reply.code(403).send({ error: "비활성화된 계정입니다." });
    }

    const primaryMember =
      user.complexMembers.find((m) => m.complexId === user.currentComplexId) ??
      user.complexMembers[0];

    const payload = {
      sub: user.id,
      email: user.email,
      role: primaryMember?.role ?? "RESIDENT",
      complexId: user.currentComplexId ?? primaryMember?.complexId,
    };

    const accessToken = app.jwt.sign(payload);
    const refreshTokenValue = nanoid(64);
    const expiresAt = addDays(new Date(), 7);

    await app.prisma.refreshToken.create({
      data: { token: refreshTokenValue, userId: user.id, expiresAt },
    });

    return {
      accessToken,
      refreshToken: refreshTokenValue,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        profileImageUrl: user.profileImageUrl,
        role: primaryMember?.role ?? "RESIDENT",
        currentComplexId: user.currentComplexId ?? primaryMember?.complexId ?? null,
        complexId: user.currentComplexId ?? primaryMember?.complexId ?? null,
        complexName: user.currentComplex?.alias ?? user.currentComplex?.name ?? null,
        complexBuildingName: user.currentComplex?.buildingName ?? null,
        complexRoadAddress: user.currentComplex?.roadAddress ?? user.currentComplex?.address ?? null,
      },
    };
  });

  // ── POST /auth/refresh ───────────────────────────────────────────────────
  app.post("/refresh", async (req, reply) => {
    const { refreshToken } = refreshSchema.parse(req.body);

    const stored = await app.prisma.refreshToken.findUnique({
      where: { token: refreshToken },
      include: {
        user: {
          include: { complexMembers: { where: { isActive: true } } },
        },
      },
    });

    if (!stored || stored.expiresAt < new Date()) {
      await app.prisma.refreshToken.deleteMany({ where: { token: refreshToken } });
      return reply.code(401).send({ error: "유효하지 않은 리프레시 토큰입니다." });
    }

    const user = stored.user;
    const primaryMember =
      user.complexMembers.find((m) => m.complexId === user.currentComplexId) ??
      user.complexMembers[0];

    const accessToken = app.jwt.sign({
      sub: user.id,
      email: user.email,
      role: primaryMember?.role ?? "RESIDENT",
      complexId: user.currentComplexId ?? primaryMember?.complexId,
    });

    // Rotate refresh token
    const newRefreshToken = nanoid(64);
    await app.prisma.refreshToken.update({
      where: { id: stored.id },
      data: { token: newRefreshToken, expiresAt: addDays(new Date(), 7) },
    });

    return { accessToken, refreshToken: newRefreshToken };
  });

  // ── POST /auth/logout ────────────────────────────────────────────────────
  app.post("/logout", { preHandler: [authenticate] }, async (req, reply) => {
    const { refreshToken } = refreshSchema.parse(req.body);

    await app.prisma.refreshToken.deleteMany({
      where: { token: refreshToken, userId: req.user.sub },
    });

    return { message: "로그아웃되었습니다." };
  });

  // ── POST /auth/forgot-password ───────────────────────────────────────────
  app.post("/forgot-password", async (req, reply) => {
    const { email } = forgotPasswordSchema.parse(req.body);

    const user = await app.prisma.user.findUnique({ where: { email } });
    // Always return success to avoid email enumeration
    if (!user) return { message: "비밀번호 재설정 이메일을 발송했습니다." };

    const token = nanoid(32);
    await app.prisma.user.update({
      where: { id: user.id },
      data: { passwordResetToken: token, passwordResetAt: addMinutes(new Date(), 30) },
    });

    await sendPasswordResetEmail(email, token).catch((err) =>
      app.log.error({ err }, "Failed to send password reset email")
    );

    return { message: "비밀번호 재설정 이메일을 발송했습니다." };
  });

  // ── POST /auth/reset-password ────────────────────────────────────────────
  app.post("/reset-password", async (req, reply) => {
    const { token, password } = resetPasswordSchema.parse(req.body);

    const user = await app.prisma.user.findFirst({
      where: { passwordResetToken: token, passwordResetAt: { gt: new Date() } },
    });

    if (!user) {
      return reply.code(400).send({ error: "유효하지 않거나 만료된 토큰입니다." });
    }

    const hashed = await bcrypt.hash(password, 12);
    await app.prisma.user.update({
      where: { id: user.id },
      data: { password: hashed, passwordResetToken: null, passwordResetAt: null },
    });

    await app.prisma.refreshToken.deleteMany({ where: { userId: user.id } });

    return { message: "비밀번호가 변경되었습니다. 다시 로그인해 주세요." };
  });

  // ── GET /auth/me ─────────────────────────────────────────────────────────
  app.get("/me", { preHandler: [authenticate] }, async (req) => {
    const user = await app.prisma.user.findUnique({
      where: { id: req.user.sub },
      include: {
        currentComplex: true,
        complexMembers: {
          where: { isActive: true },
          include: { complex: true },
        },
      },
    });

    if (!user) return { error: "User not found" };

    return {
      id: user.id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      profileImageUrl: user.profileImageUrl,
      emailVerified: user.emailVerified,
      currentComplexId: user.currentComplexId,
      currentComplexName: user.currentComplex?.alias ?? user.currentComplex?.name ?? null,
      currentComplexBuildingName: user.currentComplex?.buildingName ?? null,
      currentComplexRoadAddress: user.currentComplex?.roadAddress ?? user.currentComplex?.address ?? null,
      complexMembers: user.complexMembers.map((m) => ({
        complexId: m.complexId,
        complexName: m.complex.alias || m.complex.name,
        complexBuildingName: m.complex.buildingName,
        complexRoadAddress: m.complex.roadAddress || m.complex.address,
        role: m.role,
      })),
    };
  });

  // ── PATCH /auth/fcm-token ────────────────────────────────────────────────
  app.patch("/fcm-token", { preHandler: [authenticate] }, async (req) => {
    const { fcmToken } = updateFcmTokenSchema.parse(req.body);

    await app.prisma.user.update({
      where: { id: req.user.sub },
      data: { fcmToken },
    });

    return { message: "FCM 토큰이 업데이트되었습니다." };
  });
};

export default authRoutes;
