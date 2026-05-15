import type { PrismaClient, NotificationType } from "@prisma/client";
import { sendPushNotificationToMany, sendPushNotification } from "./fcm.js";

interface NotificationPayload {
  type: NotificationType;
  title: string;
  body: string;
  data?: Record<string, unknown>;
}

/**
 * Send a notification to a single user (DB + FCM push).
 */
export async function sendNotificationToUser(
  prisma: PrismaClient,
  userId: string,
  payload: NotificationPayload
): Promise<void> {
  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (!user) return;

  await prisma.notification.create({
    data: {
      userId,
      type: payload.type,
      title: payload.title,
      body: payload.body,
      data: payload.data ?? {},
    },
  });

  if (user.fcmToken) {
    await sendPushNotification(
      user.fcmToken,
      payload.title,
      payload.body,
      stringifyData(payload.data)
    );
  }
}

/**
 * Send a notification to all COMPLEX_MANAGER and ATTENDANT members of a complex.
 */
export async function sendNotificationToComplexManagers(
  prisma: PrismaClient,
  complexId: string,
  payload: NotificationPayload
): Promise<void> {
  const managers = await prisma.complexMember.findMany({
    where: {
      complexId,
      isActive: true,
      role: { in: ["COMPLEX_MANAGER", "ATTENDANT"] },
    },
    include: { user: true },
  });

  if (!managers.length) return;

  // Bulk insert notifications
  await prisma.notification.createMany({
    data: managers.map((m) => ({
      userId: m.userId,
      complexId,
      type: payload.type,
      title: payload.title,
      body: payload.body,
      data: payload.data ?? {},
    })),
  });

  // Push to all FCM tokens
  const tokens = managers.map((m) => m.user.fcmToken).filter(Boolean) as string[];
  if (tokens.length) {
    await sendPushNotificationToMany(tokens, payload.title, payload.body, stringifyData(payload.data));
  }
}

function stringifyData(data?: Record<string, unknown>): Record<string, string> | undefined {
  if (!data) return undefined;
  return Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v ?? "")]));
}
