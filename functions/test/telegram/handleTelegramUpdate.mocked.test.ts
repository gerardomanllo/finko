import * as fs from "fs";
import * as path from "path";

import { handleTelegramUpdate } from "../../src/telegram/handleUpdate";
import * as geminiOrchestrator from "../../src/telegram/geminiOrchestrator";
import { t } from "../../src/telegram/i18n";
import type { TelegramUpdate } from "../../src/telegram/types";
import { createMockFirestoreForTelegram } from "../helpers/mockFirestoreTelegram";

function fixture(name: string): TelegramUpdate {
  const p = path.join(__dirname, "fixtures", name);
  return JSON.parse(fs.readFileSync(p, "utf8")) as TelegramUpdate;
}

describe("handleTelegramUpdate — mocked Firestore + fetch", () => {
  const botToken = "TEST_TOKEN";
  const originalFetch = global.fetch;

  afterEach(() => {
    global.fetch = originalFetch;
    jest.restoreAllMocks();
  });

  function mockFetchRecorder() {
    const bodies: unknown[] = [];
    const jestFetch = jest.fn(async (_url: RequestInfo | URL, init?: RequestInit) => {
      if (init?.body && typeof init.body === "string") {
        try {
          bodies.push(JSON.parse(init.body));
        } catch {
          bodies.push(init.body);
        }
      } else {
        bodies.push(undefined);
      }
      return { ok: true, json: async () => ({ ok: true }) } as Response;
    });
    return {
      fetchTelegram: jestFetch as unknown as typeof fetch,
      jestFetch,
      bodies,
    };
  }

  it("does not call Telegram when update_id was already processed", async () => {
    const { fetchTelegram, jestFetch, bodies } = mockFetchRecorder();
    const db = createMockFirestoreForTelegram({ duplicateUpdateIds: new Set([9001]) });
    const update: TelegramUpdate = {
      update_id: 9001,
      message: {
        message_id: 1,
        chat: { id: 4242, type: "private" },
        date: 1,
        text: "hello",
      },
    };
    await handleTelegramUpdate(update, { db, fetchTelegram, botToken });
    expect(jestFetch).not.toHaveBeenCalled();
    expect(bodies.length).toBe(0);
  });

  it("silent_ignore emits zero outbound Bot API calls", async () => {
    const { fetchTelegram, jestFetch } = mockFetchRecorder();
    const db = createMockFirestoreForTelegram();
    const update = fixture("update_channel_post.json");
    await handleTelegramUpdate(update, { db, fetchTelegram, botToken });
    expect(jestFetch).not.toHaveBeenCalled();
  });

  it("graceful_reject sticker sends one localized sendMessage", async () => {
    const { fetchTelegram, jestFetch, bodies } = mockFetchRecorder();
    const db = createMockFirestoreForTelegram();
    const update = fixture("update_sticker.json");
    await handleTelegramUpdate(update, { db, fetchTelegram, botToken });
    expect(jestFetch).toHaveBeenCalledTimes(1);
    const body = bodies[0] as Record<string, unknown>;
    expect(body.chat_id).toBe(4242);
    expect(String(body.text)).toMatch(/attachment|archivo/i);
  });

  it("plain /start without token sends hint DM", async () => {
    const { fetchTelegram, jestFetch, bodies } = mockFetchRecorder();
    const db = createMockFirestoreForTelegram();
    const update = fixture("update_plain_start.json");
    await handleTelegramUpdate(update, { db, fetchTelegram, botToken });
    expect(jestFetch).toHaveBeenCalledTimes(1);
    const body = bodies[0] as Record<string, unknown>;
    expect(String(body.text)).toMatch(/Finko|Open/i);
  });

  it("unbound chat sends not_linked for dialog text", async () => {
    const { fetchTelegram, jestFetch, bodies } = mockFetchRecorder();
    const db = createMockFirestoreForTelegram({ bindings: {} });
    const update: TelegramUpdate = {
      update_id: 9102,
      message: {
        message_id: 3,
        chat: { id: 4242, type: "private" },
        date: 1,
        text: "not parseable xyzqq",
      },
    };
    await handleTelegramUpdate(update, { db, fetchTelegram, botToken });
    expect(jestFetch).toHaveBeenCalledTimes(1);
    const body = bodies[0] as Record<string, unknown>;
    expect(String(body.text)).toMatch(/Link Telegram|vincula/i);
  });

  it("bound chat without Gemini key rejects unknown language turn", async () => {
    const { fetchTelegram, jestFetch, bodies } = mockFetchRecorder();
    const db = createMockFirestoreForTelegram({
      bindings: { "4242": "user_test_1" },
    });
    const update: TelegramUpdate = {
      update_id: 9104,
      message: {
        message_id: 5,
        chat: { id: 4242, type: "private" },
        date: 1,
        from: { id: 1, language_code: "en" },
        text: "hello",
      },
    };
    await handleTelegramUpdate(update, { db, fetchTelegram, botToken });
    expect(jestFetch).toHaveBeenCalledTimes(1);
    const body = bodies[0] as Record<string, unknown>;
    expect(String(body.text)).toMatch(/English|Spanish|inglés|español/i);
  });

  it("bound chat conversational text without Gemini key gets language-not-understood", async () => {
    const { fetchTelegram, jestFetch, bodies } = mockFetchRecorder();
    const db = createMockFirestoreForTelegram({
      bindings: { "4242": "user_test_1" },
    });
    const update: TelegramUpdate = {
      update_id: 9198,
      message: {
        message_id: 11,
        chat: { id: 4242, type: "private" },
        date: 1,
        from: { id: 1, language_code: "en" },
        text: "gasté 100 pesos en el supermercado hoy",
      },
    };
    await handleTelegramUpdate(update, { db, fetchTelegram, botToken });
    expect(jestFetch).toHaveBeenCalledTimes(1);
    const body = bodies[0] as Record<string, unknown>;
    expect(String(body.text)).toMatch(/English|Spanish|inglés|español/i);
  });

  it("confirm_transaction copy includes formatted amount (i18n shape)", () => {
    const s = t("en", "confirm_transaction", {
      direction: "OUT",
      amount: "MXN $50.00",
      memo: "Cafe",
      account: "Cash",
      category: "Food",
    });
    expect(s).toContain("Amount:");
    expect(s).toContain("MXN $50.00");
    expect(s).toContain("Note:");
    expect(s).toContain("Cafe");
  });

  it("bound chat /help without Gemini key gets language-not-understood", async () => {
    const { fetchTelegram, jestFetch, bodies } = mockFetchRecorder();
    const db = createMockFirestoreForTelegram({
      bindings: { "4242": "user_test_1" },
    });
    const update: TelegramUpdate = {
      update_id: 9103,
      message: {
        message_id: 4,
        chat: { id: 4242, type: "private" },
        date: 1,
        text: "/help",
      },
    };
    await handleTelegramUpdate(update, { db, fetchTelegram, botToken });
    expect(jestFetch).toHaveBeenCalledTimes(1);
    const body = bodies[0] as Record<string, unknown>;
    expect(String(body.text)).toMatch(/English|Spanish|inglés|español/i);
  });

  it("Gemini incomplete standard snapshot shows category picker instead of prose", async () => {
    jest.spyOn(geminiOrchestrator, "detectMessageLanguageWithGemini").mockResolvedValue("en");
    jest.spyOn(geminiOrchestrator, "analyzeFirstMessageWithGemini").mockResolvedValue({
      intent: "transaction",
      quickReply: "",
      transaction: {
        complete: false,
        assistantMessage: "Pick a category for me?",
        txKind: "standard",
        direction: "out",
        amountMinor: 5000,
        amountMinorTo: null,
        memo: "coffee",
        categoryId: null,
        accountId: null,
        transferFromId: null,
        transferToId: null,
      },
    });

    const { fetchTelegram, bodies } = mockFetchRecorder();
    const db = createMockFirestoreForTelegram({
      bindings: { "4242": "user_test_1" },
      accounts: [{ id: "acc_a", name: "Cash", currency: "MXN" }],
      categories: [{ id: "cat_x", name: "Food", kind: "expense" }],
    });

    await handleTelegramUpdate(
      {
        update_id: 9220,
        message: {
          message_id: 31,
          chat: { id: 4242, type: "private" },
          date: 1,
          text: "spent 50 on coffee",
        },
      },
      {
        db,
        fetchTelegram,
        botToken,
        geminiApiKey: "TEST_GEMINI_KEY",
      }
    );

    const lastBody = bodies[bodies.length - 1] as Record<string, unknown>;
    const mk = lastBody.reply_markup as { inline_keyboard?: Array<Array<{ callback_data?: string }>> };
    const cbs = (mk.inline_keyboard ?? []).flat().map((b) => b.callback_data ?? "");
    expect(cbs.some((d) => d.startsWith("pc:"))).toBe(true);
    expect(String(lastBody.text)).not.toContain("Pick a category for me?");
  });

  it("Gemini incomplete standard snapshot with category shows account picker", async () => {
    jest.spyOn(geminiOrchestrator, "detectMessageLanguageWithGemini").mockResolvedValue("en");
    jest.spyOn(geminiOrchestrator, "analyzeFirstMessageWithGemini").mockResolvedValue({
      intent: "transaction",
      quickReply: "",
      transaction: {
        complete: false,
        assistantMessage: "Tell me account",
        txKind: "standard",
        direction: "out",
        amountMinor: 5000,
        amountMinorTo: null,
        memo: "coffee",
        categoryId: "cat_x",
        accountId: null,
        transferFromId: null,
        transferToId: null,
      },
    });

    const { fetchTelegram, bodies } = mockFetchRecorder();
    const db = createMockFirestoreForTelegram({
      bindings: { "4242": "user_test_1" },
      accounts: [{ id: "acc_a", name: "Cash", currency: "MXN" }],
      categories: [{ id: "cat_x", name: "Food", kind: "expense" }],
    });

    await handleTelegramUpdate(
      {
        update_id: 9221,
        message: {
          message_id: 32,
          chat: { id: 4242, type: "private" },
          date: 1,
          text: "spent 50 on coffee food",
        },
      },
      {
        db,
        fetchTelegram,
        botToken,
        geminiApiKey: "TEST_GEMINI_KEY",
      }
    );

    const lastBody = bodies[bodies.length - 1] as Record<string, unknown>;
    const mk = lastBody.reply_markup as { inline_keyboard?: Array<Array<{ callback_data?: string }>> };
    const cbs = (mk.inline_keyboard ?? []).flat().map((b) => b.callback_data ?? "");
    expect(cbs.some((d) => d.startsWith("pa:"))).toBe(true);
    expect(String(lastBody.text)).not.toContain("Tell me account");
  });

  it("strict language detection replies in detected language", async () => {
    jest.spyOn(geminiOrchestrator, "detectMessageLanguageWithGemini").mockResolvedValue("es");
    const { fetchTelegram, jestFetch, bodies } = mockFetchRecorder();
    const db = createMockFirestoreForTelegram({
      bindings: { "4242": "user_test_1" },
    });
    const update: TelegramUpdate = {
      update_id: 9210,
      message: {
        message_id: 7,
        chat: { id: 4242, type: "private" },
        date: 1,
        text: "/help",
      },
    };
    await handleTelegramUpdate(update, {
      db,
      fetchTelegram,
      botToken,
      geminiApiKey: "TEST_GEMINI_KEY",
    });
    expect(jestFetch).toHaveBeenCalledTimes(1);
    const body = bodies[0] as Record<string, unknown>;
    expect(String(body.text)).toContain("Comandos:");
  });

  it("duplicate delivery does not send twice", async () => {
    const { fetchTelegram, jestFetch } = mockFetchRecorder();
    const db = createMockFirestoreForTelegram({ bindings: {} });
    const update: TelegramUpdate = {
      update_id: 9200,
      message: {
        message_id: 3,
        chat: { id: 4242, type: "private" },
        date: 1,
        text: "zzz no amount here",
      },
    };
    await handleTelegramUpdate(update, { db, fetchTelegram, botToken });
    const n1 = jestFetch.mock.calls.length;
    await handleTelegramUpdate(update, { db, fetchTelegram, botToken });
    expect(jestFetch.mock.calls.length).toBe(n1);
  });
});
