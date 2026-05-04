import type { Firestore } from "firebase-admin/firestore";

/** Minimal ledger rows for bound-chat handler tests. */
export type MockLedgerAccount = {
  id: string;
  name: string;
  currency: string;
  sortOrder?: number;
};

export type MockLedgerCategory = {
  id: string;
  name: string;
  kind: string;
  sortOrder?: number;
};

export type TelegramMockFirestoreOptions = {
  /** `telegramChatBindings` doc id (chat id string) → Firebase uid */
  bindings?: Record<string, string>;
  /** Treat these `update_id`s as already processed (Firestore ALREADY_EXISTS). */
  duplicateUpdateIds?: Set<number>;
  userMainCurrency?: string;
  userTimezone?: string;
  telegramBotPreferences?: Record<string, unknown>;
  accounts?: MockLedgerAccount[];
  categories?: MockLedgerCategory[];
  /** Raw `telegramBotSessions/{chatId}` data; omit or null → no session */
  botSession?: Record<string, unknown> | null;
};

/**
 * Partial Firestore stub for Telegram webhook unit tests (Admin SDK shapes).
 * Extend when new code paths need more collection/doc behavior.
 */
export function createMockFirestoreForTelegram(
  opts: TelegramMockFirestoreOptions = {}
): Firestore {
  const processedIds = new Set<string>();
  const { bindings = {}, duplicateUpdateIds = new Set() } = opts;
  let txDocCounter = 0;

  const accountsSnap = () => {
    const accs = opts.accounts ?? [];
    return {
      docs: accs.map((a) => ({
        id: a.id,
        data: () => ({
          name: a.name,
          currency: a.currency,
          sortOrder: a.sortOrder ?? 0,
        }),
      })),
      empty: accs.length === 0,
    };
  };

  const categoriesSnap = () => {
    const cats = opts.categories ?? [];
    return {
      docs: cats.map((c) => ({
        id: c.id,
        data: () => ({
          name: c.name,
          kind: c.kind,
          sortOrder: c.sortOrder ?? 0,
        }),
      })),
      empty: cats.length === 0,
    };
  };

  const collection = (path: string) => ({
    doc(docId?: string) {
      const id = docId ?? `auto_${++txDocCounter}`;
      if (/^users\/[^/]+\/transactions$/.test(path)) {
        return {
          id,
          async set() {
            /* no-op */
          },
        };
      }
      if (path === "telegramProcessedUpdates") {
        return {
          async create() {
            if (duplicateUpdateIds.has(Number(docId)) || processedIds.has(String(docId))) {
              throw Object.assign(new Error("already-exists"), { code: 6 });
            }
            processedIds.add(String(docId));
          },
          async get() {
            return { exists: false };
          },
        };
      }
      if (path === "telegramChatBindings") {
        return {
          async get() {
            const uid = bindings[String(docId)];
            if (!uid) {
              return { exists: false, id, data: () => undefined };
            }
            return { exists: true, id, data: () => ({ uid }) };
          },
        };
      }
      if (path === "telegramBotSessions") {
        return {
          async get() {
            if (opts.botSession === undefined || opts.botSession === null) {
              return { exists: false, id, data: () => undefined };
            }
            return { exists: true, id, data: () => opts.botSession as Record<string, unknown> };
          },
          async set() {
            /* no-op */
          },
          async delete() {
            /* no-op */
          },
        };
      }
      return {
        async get() {
          return { exists: false, data: () => undefined };
        },
        async set() {
          /* no-op */
        },
      };
    },
    async get() {
      if (/^users\/[^/]+\/accounts$/.test(path)) {
        return accountsSnap();
      }
      if (/^users\/[^/]+\/categories$/.test(path)) {
        return categoriesSnap();
      }
      return { docs: [], empty: true };
    },
  });

  const userDoc = (uid: string) => ({
    async get() {
      return {
        exists: true,
        id: uid,
        data: () => ({
          mainCurrency: opts.userMainCurrency ?? "MXN",
          timezone: opts.userTimezone ?? "America/Mexico_City",
          ...(opts.telegramBotPreferences !== undefined
            ? { telegramBotPreferences: opts.telegramBotPreferences }
            : {}),
        }),
      };
    },
    async set(_data: unknown, _opt?: unknown) {
      /* no-op — used by touchLedgerSourcesLastChangedAt */
    },
  });

  const categoryDoc = (uid: string, catId: string) => ({
    async set() {
      void uid;
      void catId;
    },
  });

  return {
    collection,
    doc(path: string) {
      const segs = path.split("/");
      if (segs[0] === "users" && segs.length === 2) {
        return userDoc(segs[1]);
      }
      if (segs[0] === "users" && segs.length === 4 && segs[2] === "categories") {
        return categoryDoc(segs[1], segs[3]);
      }
      return {
        async get() {
          return { exists: false, data: () => undefined };
        },
        async set() {
          /* no-op */
        },
      };
    },
  } as unknown as Firestore;
}
