import type { FastifyPluginAsync } from "fastify";
import multipart from "@fastify/multipart";
import { nanoid } from "nanoid";
import { createWriteStream } from "node:fs";
import { mkdir, unlink } from "node:fs/promises";
import { extname, join } from "node:path";
import { pipeline } from "node:stream/promises";
import { authenticate } from "../middleware/authenticate.js";
import { config } from "../config/index.js";

const maxProfileImageSize = 5 * 1024 * 1024;
const allowedExtensions = new Set([".jpg", ".jpeg", ".png", ".webp"]);
const allowedMimeTypes = new Set(["image/jpeg", "image/png", "image/webp"]);

const userRoutes: FastifyPluginAsync = async (app) => {
  await app.register(multipart, {
    limits: {
      fileSize: maxProfileImageSize,
      files: 1,
    },
  });

  // ── POST /users/me/profile-image ─────────────────────────────────────────
  app.post("/me/profile-image", { preHandler: [authenticate] }, async (req, reply) => {
    const image = await req.file();

    if (!image || image.fieldname !== "image") {
      return reply.code(400).send({ error: "image 파일을 multipart/form-data로 업로드해 주세요." });
    }

    const extension = extname(image.filename).toLowerCase();
    if (!allowedExtensions.has(extension) || !allowedMimeTypes.has(image.mimetype)) {
      return reply.code(400).send({ error: "jpg, jpeg, png, webp 이미지 파일만 업로드할 수 있습니다." });
    }

    const profileImageDir = join(process.cwd(), "uploads", "profile-images");
    await mkdir(profileImageDir, { recursive: true });

    const fileName = `${req.user.sub}-${nanoid(12)}${extension}`;
    const filePath = join(profileImageDir, fileName);

    try {
      await pipeline(image.file, createWriteStream(filePath));
    } catch (error: any) {
      await unlink(filePath).catch(() => undefined);
      if (error?.code === "FST_REQ_FILE_TOO_LARGE") {
        return reply.code(413).send({ error: "프로필 이미지는 5MB 이하만 업로드할 수 있습니다." });
      }
      throw error;
    }

    const profileImageUrl = `${config.APP_URL.replace(/\/$/, "")}/uploads/profile-images/${fileName}`;
    await app.prisma.user.update({
      where: { id: req.user.sub },
      data: { profileImageUrl },
    });

    return { profileImageUrl };
  });
};

export default userRoutes;
