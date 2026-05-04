import type { Firestore } from "firebase-admin/firestore";

/** Injected by the Telegram handler for read-only ledger tools (never from model text). */
export type TelegramGenkitToolContext = { db: Firestore; uid: string };
