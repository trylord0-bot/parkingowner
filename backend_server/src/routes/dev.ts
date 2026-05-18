import type { FastifyPluginAsync } from "fastify";
import bcrypt from "bcryptjs";
import { config } from "../config/index.js";

const devRoutes: FastifyPluginAsync = async (app) => {
  app.addHook("onRequest", async (_req, reply) => {
    if (config.NODE_ENV === "production") {
      return reply.code(404).send({ error: "Not Found" });
    }
  });

  // POST /dev/reset — 전체 데이터 삭제 후 기본 시드 데이터 삽입
  app.post("/reset", async () => {
    // 외래키 의존 순서에 맞게 삭제
    await app.prisma.ocrCorrectionLog.deleteMany();
    await app.prisma.message.deleteMany();
    await app.prisma.notification.deleteMany();
    await app.prisma.entryLog.deleteMany();
    await app.prisma.request.deleteMany();
    await app.prisma.vehicle.deleteMany();
    await app.prisma.inviteCode.deleteMany();
    await app.prisma.channel.deleteMany();
    await app.prisma.refreshToken.deleteMany();
    await app.prisma.complexMember.deleteMany();
    await app.prisma.household.deleteMany();
    await app.prisma.parkingZone.deleteMany();
    await app.prisma.complex.deleteMany();
    await app.prisma.user.deleteMany();

    // 기본 데이터 세팅
    const adminEmail = config.APP_ADMIN_EMAIL ?? "admin@parkingowner.com";
    const adminPassword = "Admin1234!";

    const admin = await app.prisma.user.create({
      data: {
        name: "앱 관리자",
        email: adminEmail,
        password: await bcrypt.hash(adminPassword, 12),
        emailVerified: true,
        isActive: true,
      },
    });

    const complex = await app.prisma.complex.create({
      data: {
        name: "행복마을아파트",
        address: "서울특별시 강남구 역삼동 123",
        roadAddress: "서울 강남구 테헤란로 123",
        jibunAddress: "서울특별시 강남구 역삼동 123",
        zipCode: "06132",
        alias: "행복마을아파트",
        latitude: 37.5012,
        longitude: 127.0396,
        totalSlots: 200,
      },
    });

    await app.prisma.complexMember.create({
      data: { userId: admin.id, complexId: complex.id, role: "APP_ADMIN" },
    });

    await app.prisma.user.update({
      where: { id: admin.id },
      data: { currentComplexId: complex.id },
    });

    await app.prisma.parkingZone.createMany({
      data: [
        { complexId: complex.id, name: "지상", totalSlots: 80 },
        { complexId: complex.id, name: "지하 B1", totalSlots: 70 },
        { complexId: complex.id, name: "지하 B2", totalSlots: 50 },
      ],
    });

    await app.prisma.channel.createMany({
      data: [
        { complexId: complex.id, type: "ANNOUNCEMENT", name: "📢 공지사항" },
        { complexId: complex.id, type: "STAFF", name: "👮 업무 소통방" },
      ],
    });

    app.log.info(`[DEV] DB reset complete — admin: ${adminEmail}`);

    return {
      message: "DB가 초기화되었습니다.",
      admin: { email: adminEmail, password: adminPassword },
    };
  });
};

export default devRoutes;
