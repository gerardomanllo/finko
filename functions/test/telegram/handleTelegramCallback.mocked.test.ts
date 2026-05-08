import * as fs from "fs";
import * as path from "path";

import { handleTelegramUpdate } from "../../src/telegram/handleUpdate";
import { t } from "../../src/telegram/i18n";
import type { TelegramUpdate } from "../../src/telegram/types";
import { createMockFirestoreForTelegram } from "../helpers/mockFirestoreTelegram";

function fixture(name: string): TelegramUpdate {
  const p = path.join(__dirname, "fixtures", name);
  return JSON.parse(fs.readFileSync(p, "utf8")) as TelegramUpdate;
}

function telegramMethodFromUrl(url: string): string {
  const m = /\/bot[^/]+\/(\w+)/.exec(url);
  return m?.[1] ?? "";
}

describe("handleTelegramUpdate — callback_query contract", () => {
  const botToken = "TEST_TOKEN";
  const originalFetch = global.fetch;

  afterEach(() => {
    global.fetch = originalFetch;
  });

  function mockFetchRecorder() {
    const calls: { url: string; body: Record<string, unknown> }[] = [];
    const jestFetch = jest.fn(async (url: RequestInfo | URL, init?: RequestInit) => {
      let body: Record<string, unknown> = {};
      if (init?.body && typeof init.body === "string") {
        try {
          body = JSON.parse(init.body) as Record<string, unknown>;
        } catch {
          body = {};
        }
      }
      calls.push({ url: String(url), body });
      return { ok: true, json: async () => ({ ok: true }) } as Response;
    });
    return {
      fetchTelegram: jestFetch as unknown as typeof fetch,
      jestFetch,
      calls,
    };
  }

  function expenseConfirmSeed(): Record<string, unknown> {
    return {
      uid: "user_test_1",
      locale: "en",
      intent: "expense",
      step: "confirm",
      draft: {
        intent: "expense",
        direction: "out",
        txKind: "standard",
        amountMinor: 5000,
        memo: "coffee",
        accountId: "acc_a",
        categoryId: "cat_x",
        currency: "MXN",
        _accounts: [{ id: "acc_a", name: "Cash", currency: "MXN" }],
        _categories: [{ id: "cat_x", name: "Food", kind: "expense" }],
      },
    };
  }

  it("confirm (cf) answers callback then edits message with posted expense only", async () => {
    const { fetchTelegram, calls } = mockFetchRecorder();
    const db = createMockFirestoreForTelegram({
      bindings: { "4242": "user_test_1" },
      accounts: [{ id: "acc_a", name: "Cash", currency: "MXN" }],
      categories: [{ id: "cat_x", name: "Food", kind: "expense" }],
      statefulBotSession: true,
      botSession: expenseConfirmSeed(),
    });

    await handleTelegramUpdate(fixture("update_callback_query_confirm.json"), {
      db,
      fetchTelegram,
      botToken,
    });

    expect(calls.length).toBeGreaterThanOrEqual(2);
    expect(telegramMethodFromUrl(calls[0].url)).toBe("answerCallbackQuery");
    expect(String(calls[0].body.callback_query_id)).toBe("cq_confirm_test");
    expect(String(calls[0].body.text ?? "")).toBe(t("en", "callback_saved"));

    expect(telegramMethodFromUrl(calls[1].url)).toBe("editMessageText");
    expect(calls[1].body.chat_id).toBe(4242);
    expect(calls[1].body.message_id).toBe(88);
    const edited = String(calls[1].body.text ?? "");
    expect(edited).toMatch(/Expense recorded/);
    expect(edited).toContain("coffee");
    expect(edited).toContain("MXN $50.00");
    expect(edited).not.toMatch(/recurring/i);
  });

  it("cancel (cx) answers callback with discarded toast then sends cancelled DM", async () => {
    const { fetchTelegram, calls } = mockFetchRecorder();
    const db = createMockFirestoreForTelegram({
      bindings: { "4242": "user_test_1" },
      statefulBotSession: true,
      botSession: expenseConfirmSeed(),
    });

    await handleTelegramUpdate(fixture("update_callback_query_cancel.json"), {
      db,
      fetchTelegram,
      botToken,
    });

    expect(calls.length).toBe(2);
    expect(telegramMethodFromUrl(calls[0].url)).toBe("answerCallbackQuery");
    expect(String(calls[0].body.callback_query_id)).toBe("cq_cancel_test");
    expect(String(calls[0].body.text ?? "")).toBe(t("en", "callback_discarded"));

    expect(telegramMethodFromUrl(calls[1].url)).toBe("sendMessage");
    expect(calls[1].body.chat_id).toBe(4242);
    expect(String(calls[1].body.text ?? "")).toBe(t("en", "cancelled"));
  });

  it("confirm (cf) with wrong session step only answers invalid callback — no edit", async () => {
    const { fetchTelegram, calls } = mockFetchRecorder();
    const db = createMockFirestoreForTelegram({
      bindings: { "4242": "user_test_1" },
      statefulBotSession: true,
      botSession: {
        uid: "user_test_1",
        locale: "en",
        intent: "expense",
        step: "pick_category",
        draft: {
          intent: "expense",
          direction: "out",
          amountMinor: 5000,
          memo: "coffee",
          _accounts: [],
          _categories: [{ id: "cat_x", name: "Food", kind: "expense" }],
        },
      },
    });

    await handleTelegramUpdate(fixture("update_callback_query_confirm_wrong_step.json"), {
      db,
      fetchTelegram,
      botToken,
    });

    expect(calls.length).toBe(1);
    expect(telegramMethodFromUrl(calls[0].url)).toBe("answerCallbackQuery");
    expect(String(calls[0].body.callback_query_id)).toBe("cq_wrong_step");
    expect(String(calls[0].body.text ?? "")).toBe(t("en", "callback_invalid"));
  });

  it("category pick without account prompts inline account buttons", async () => {
    const { fetchTelegram, calls } = mockFetchRecorder();
    const db = createMockFirestoreForTelegram({
      bindings: { "4242": "user_test_1" },
      statefulBotSession: true,
      accounts: [
        { id: "acc_a", name: "Cash", currency: "MXN" },
        { id: "acc_b", name: "Card", currency: "MXN" },
      ],
      categories: [{ id: "cat_x", name: "Food", kind: "expense" }],
      botSession: {
        uid: "user_test_1",
        locale: "en",
        intent: "expense",
        step: "pick_category",
        draft: {
          intent: "expense",
          direction: "out",
          amountMinor: 5000,
          memo: "coffee",
          _accounts: [
            { id: "acc_a", name: "Cash", currency: "MXN" },
            { id: "acc_b", name: "Card", currency: "MXN" },
          ],
          _categories: [{ id: "cat_x", name: "Food", kind: "expense" }],
        },
      },
    });

    await handleTelegramUpdate(
      {
        update_id: 15100,
        callback_query: {
          id: "cq_pick_cat",
          from: { id: 7, language_code: "en" },
          message: {
            message_id: 99,
            chat: { id: 4242, type: "private" },
            date: 1,
            text: "Pick category",
          },
          data: "pc:0",
        },
      },
      { db, fetchTelegram, botToken }
    );

    expect(calls.length).toBeGreaterThanOrEqual(2);
    expect(telegramMethodFromUrl(calls[0].url)).toBe("answerCallbackQuery");
    expect(telegramMethodFromUrl(calls[1].url)).toBe("editMessageText");
    const markup = calls[1].body.reply_markup as { inline_keyboard?: Array<Array<{ callback_data?: string }>> };
    const callbackData = (markup.inline_keyboard ?? []).flat().map((b) => b.callback_data ?? "");
    expect(callbackData.some((v) => v.startsWith("pa:"))).toBe(true);
  });
});
