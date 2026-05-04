import * as fs from "fs";
import * as path from "path";

import { handleTelegramUpdate } from "../../src/telegram/handleUpdate";
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
    expect(String(body.text)).toContain("attachment");
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

  it("bound chat /help sends help text", async () => {
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
    expect(String(body.text)).toContain("/transfer");
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
