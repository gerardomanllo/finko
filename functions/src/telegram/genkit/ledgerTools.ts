import type { Firestore } from "firebase-admin/firestore";
import * as logger from "firebase-functions/logger";
import type { Genkit } from "genkit";
import { z } from "genkit";

import { loadAccountsForBot, loadCategoriesForBot } from "../ledgerToolkit";

const MAX_RECENT = 15;

/**
 * Read-only Firestore tools; `uid` is fixed by the Telegram handler — never taken from model text.
 */
export function createTelegramLedgerReadTools(ai: Genkit, db: Firestore, uid: string) {
  const listAccounts = ai.dynamicTool(
    {
      name: "list_accounts",
      description: "Load the user's accounts (id, name, currency).",
      inputSchema: z.object({}),
      outputSchema: z.object({
        accounts: z.array(z.object({ id: z.string(), name: z.string(), currency: z.string() })),
      }),
    },
    async () => {
      const rows = await loadAccountsForBot(db, uid);
      return {
        accounts: rows.map((a) => ({ id: a.id, name: a.name, currency: a.currency })),
      };
    }
  );

  const listCategories = ai.dynamicTool(
    {
      name: "list_categories",
      description: "Load the user's categories (id, name, kind: income or expense).",
      inputSchema: z.object({}),
      outputSchema: z.object({
        categories: z.array(z.object({ id: z.string(), name: z.string(), kind: z.string() })),
      }),
    },
    async () => {
      const rows = await loadCategoriesForBot(db, uid);
      return {
        categories: rows.map((c) => ({ id: c.id, name: c.name, kind: c.kind })),
      };
    }
  );

  const recentTransactions = ai.dynamicTool(
    {
      name: "recent_transactions",
      description: "Recent posted transactions (newest first), capped for a quick summary.",
      inputSchema: z.object({}),
      outputSchema: z.object({
        transactions: z.array(
          z.object({
            id: z.string(),
            transactionDate: z.string(),
            amountMinor: z.number(),
            direction: z.string(),
            currency: z.string(),
            memo: z.string().nullable(),
            categoryId: z.string().nullable(),
            accountId: z.string().nullable(),
            type: z.string().nullable(),
          })
        ),
      }),
    },
    async () => {
      let snap;
      try {
        snap = await db
          .collection(`users/${uid}/transactions`)
          .orderBy("loadedAt", "desc")
          .limit(MAX_RECENT)
          .get();
      } catch (e) {
        logger.warn("telegramGenkit: recent_transactions query failed", {
          err: e instanceof Error ? e.message : String(e),
          uid,
        });
        return { transactions: [] };
      }
      const transactions = snap.docs.map((d) => {
        const x = d.data() as Record<string, unknown>;
        const memo = typeof x.memo === "string" ? x.memo : null;
        const cat = typeof x.categoryId === "string" ? x.categoryId : null;
        const acc = typeof x.accountId === "string" ? x.accountId : null;
        const cur = typeof x.currency === "string" ? x.currency : "";
        const dir = x.direction === "in" || x.direction === "out" ? x.direction : "out";
        const amt = typeof x.amountMinor === "number" && Number.isFinite(x.amountMinor) ? Math.trunc(x.amountMinor) : 0;
        const ymd = typeof x.transactionDate === "string" ? x.transactionDate : "";
        const typ = typeof x.type === "string" ? x.type : null;
        return {
          id: d.id,
          transactionDate: ymd,
          amountMinor: amt,
          direction: dir,
          currency: cur,
          memo,
          categoryId: cat,
          accountId: acc,
          type: typ,
        };
      });
      return { transactions };
    }
  );

  return [listAccounts, listCategories, recentTransactions];
}
