import * as fs from "fs";
import * as path from "path";

import { classifyTelegramUpdate } from "../../src/telegram/classifyUpdate";
import type { TelegramUpdate } from "../../src/telegram/types";

function loadFixture(file: string): TelegramUpdate {
  const p = path.join(__dirname, "fixtures", file);
  return JSON.parse(fs.readFileSync(p, "utf8")) as TelegramUpdate;
}

describe("classifyTelegramUpdate — fixture JSON", () => {
  const table: [string, Record<string, unknown>][] = [
    ["update_channel_post.json", { outcome: "silent_ignore", debug: "channel_post" }],
    ["update_inline_query.json", { outcome: "silent_ignore", debug: "inline_query" }],
    ["update_my_chat_member.json", { outcome: "silent_ignore", debug: "my_chat_member" }],
    ["update_edited_message.json", { outcome: "silent_ignore", debug: "edited_message" }],
    ["update_callback_query_ok.json", { outcome: "callback_query", chatId: 4242 }],
    ["update_callback_query_no_chat.json", { outcome: "silent_ignore", debug: "callback_query_no_chat" }],
    [
      "update_link_token.json",
      { outcome: "link_token", chatId: 999001, token: "deadbeef01deadbeef01deadbeef01" },
    ],
    ["update_plain_start.json", { outcome: "plain_start", chatId: 4242 }],
    [
      "update_text_dialog.json",
      { outcome: "dialog_text", chatId: 4242, text: "12.50 coffee beans" },
    ],
    ["update_text_emoji_only.json", { outcome: "graceful_reject", reason: "emoji_only", chatId: 4242 }],
    ["update_photo.json", { outcome: "photo", chatId: 4242 }],
    ["update_voice.json", { outcome: "voice", chatId: 4242 }],
    ["update_sticker.json", { outcome: "graceful_reject", reason: "unsupported_media", chatId: 4242 }],
    ["update_video.json", { outcome: "graceful_reject", reason: "unsupported_media", chatId: 4242 }],
    ["update_document.json", { outcome: "graceful_reject", reason: "unsupported_media", chatId: 4242 }],
    ["update_poll.json", { outcome: "graceful_reject", reason: "unsupported_media", chatId: 4242 }],
  ];

  it.each(table)("fixture %s", (file, expected) => {
    const update = loadFixture(file);
    expect(classifyTelegramUpdate(update)).toMatchObject(expected);
  });

  it("rejects pasted oversize text (no LLM path)", () => {
    const text = "x".repeat(2001);
    expect(
      classifyTelegramUpdate({
        update_id: 100,
        message: {
          message_id: 1,
          chat: { id: 1, type: "private" },
          date: 1,
          text,
        },
      })
    ).toMatchObject({ outcome: "graceful_reject", reason: "message_too_long" });
  });

  it("treats unknown update envelope as silent_ignore", () => {
    expect(classifyTelegramUpdate({ update_id: 101 } as TelegramUpdate)).toMatchObject({
      outcome: "silent_ignore",
      debug: "no_message:",
    });
  });
});
