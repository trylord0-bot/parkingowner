import type { FastifyPluginAsync } from "fastify";
import { z } from "zod";
import { authenticate } from "../middleware/authenticate.js";

const correctionSchema = z.object({
  complexId: z.string().optional(),
  platform: z.enum(["android", "ios"]),
  deviceModel: z.string().optional(),
  osVersion: z.string().optional(),
  imageOriginalUrl: z.string().optional(),
  imageCroppedUrl: z.string().optional(),
  capturedAt: z.string().datetime().optional(),
  rawText: z.string(),
  confidenceScore: z.number().min(0).max(1).optional(),
  modelVersion: z.string().optional(),
  correctedText: z.string(),
});

const ocrRoutes: FastifyPluginAsync = async (app) => {
  app.addHook("preHandler", authenticate);

  // ── POST /ocr/correction ─────────────────────────────────────────────────────
  // Receives OCR correction data for ML training pipeline
  app.post("/correction", async (req, reply) => {
    const body = correctionSchema.parse(req.body);

    const log = await app.prisma.ocrCorrectionLog.create({
      data: {
        userId: req.user.sub,
        complexId: body.complexId,
        platform: body.platform,
        deviceModel: body.deviceModel,
        osVersion: body.osVersion,
        imageOriginalUrl: body.imageOriginalUrl,
        imageCroppedUrl: body.imageCroppedUrl,
        capturedAt: body.capturedAt ? new Date(body.capturedAt) : undefined,
        rawText: body.rawText,
        confidenceScore: body.confidenceScore,
        modelVersion: body.modelVersion,
        correctedText: body.correctedText,
      },
    });

    return reply.code(201).send({ id: log.id });
  });
};

export default ocrRoutes;
