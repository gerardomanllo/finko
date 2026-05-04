import { FieldValue, Firestore } from "firebase-admin/firestore";

import { TELEGRAM_PROCESSED_UPDATES } from "./constants";

/**
 * Returns `true` if this update_id was newly recorded (should handle update).
 * Returns `false` if already processed (ack Telegram without repeating side effects).
 */
export async function tryConsumeTelegramUpdate(
  db: Firestore,
  updateId: number
): Promise<boolean> {
  const ref = db.collection(TELEGRAM_PROCESSED_UPDATES).doc(String(updateId));
  try {
    await ref.create({
      receivedAt: FieldValue.serverTimestamp(),
    });
    return true;
  } catch (e: unknown) {
    const code =
      typeof e === "object" && e !== null && "code" in e
        ? Number((e as { code?: number }).code)
        : NaN;
    // ALREADY_EXISTS = 6
    if (code === 6) {
      return false;
    }
    throw e;
  }
}
