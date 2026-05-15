import * as fs from "fs";
import * as admin from "firebase-admin";
import { config } from "../config/index.js";

let initialized = false;

function initFirebase() {
  if (initialized) return;
  if (!fs.existsSync(config.FIREBASE_SERVICE_ACCOUNT_PATH)) {
    console.warn("⚠️  Firebase service account not found. Push notifications disabled.");
    return;
  }

  const serviceAccount = JSON.parse(
    fs.readFileSync(config.FIREBASE_SERVICE_ACCOUNT_PATH, "utf-8")
  );

  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
  initialized = true;
}

export async function sendPushNotification(
  fcmToken: string,
  title: string,
  body: string,
  data?: Record<string, string>
): Promise<void> {
  initFirebase();
  if (!initialized) return;

  try {
    await admin.messaging().send({
      token: fcmToken,
      notification: { title, body },
      data,
      android: { priority: "high" },
      apns: { payload: { aps: { sound: "default" } } },
    });
  } catch (err) {
    console.error("FCM send error:", err);
  }
}

export async function sendPushNotificationToMany(
  fcmTokens: string[],
  title: string,
  body: string,
  data?: Record<string, string>
): Promise<void> {
  if (!fcmTokens.length) return;
  initFirebase();
  if (!initialized) return;

  try {
    await admin.messaging().sendEachForMulticast({
      tokens: fcmTokens,
      notification: { title, body },
      data,
      android: { priority: "high" },
      apns: { payload: { aps: { sound: "default" } } },
    });
  } catch (err) {
    console.error("FCM multicast error:", err);
  }
}
