/**
 * Seed script — creates a default app admin and a sample complex.
 * Run: npm run db:seed
 */
import "dotenv/config";
import { PrismaClient } from "@prisma/client";
import bcrypt from "bcryptjs";

const prisma = new PrismaClient();

async function main() {
  // ── App Admin ────────────────────────────────────────────────────────────
  const adminEmail = process.env.APP_ADMIN_EMAIL ?? "admin@parkingowner.com";
  const adminPassword = "Admin1234!";

  const existing = await prisma.user.findUnique({ where: { email: adminEmail } });
  if (!existing) {
    const admin = await prisma.user.create({
      data: {
        name: "앱 관리자",
        email: adminEmail,
        password: await bcrypt.hash(adminPassword, 12),
        emailVerified: true,
        isActive: true,
      },
    });

    // ── Sample Complex ─────────────────────────────────────────────────────
    const complex = await prisma.complex.create({
      data: {
        name: "행복마을아파트",
        address: "서울특별시 강남구 역삼동 123",
        latitude: 37.5012,
        longitude: 127.0396,
        totalSlots: 200,
      },
    });

    await prisma.complexMember.create({
      data: { userId: admin.id, complexId: complex.id, role: "APP_ADMIN" },
    });

    await prisma.parkingZone.createMany({
      data: [
        { complexId: complex.id, name: "지상", totalSlots: 80 },
        { complexId: complex.id, name: "지하 B1", totalSlots: 70 },
        { complexId: complex.id, name: "지하 B2", totalSlots: 50 },
      ],
    });

    await prisma.channel.createMany({
      data: [
        { complexId: complex.id, type: "ANNOUNCEMENT", name: "📢 공지사항" },
        { complexId: complex.id, type: "STAFF", name: "👮 업무 소통방" },
      ],
    });

    console.log(`✅ Seeded admin: ${adminEmail} / ${adminPassword}`);
    console.log(`✅ Seeded complex: ${complex.name} (id: ${complex.id})`);
  } else {
    console.log("ℹ️  Admin already exists, skipping seed.");
  }
}

main()
  .catch((e) => { console.error(e); process.exit(1); })
  .finally(() => prisma.$disconnect());
