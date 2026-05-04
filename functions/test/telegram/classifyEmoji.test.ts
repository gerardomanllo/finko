import { isEmojiOrSymbolOnlyText } from "../../src/telegram/classifyUpdate";

describe("isEmojiOrSymbolOnlyText", () => {
  it("accepts letters+digits as non-emoji-only", () => {
    expect(isEmojiOrSymbolOnlyText("café 12")).toBe(false);
    expect(isEmojiOrSymbolOnlyText("50")).toBe(false);
  });

  it("detects plain emoji-only payloads", () => {
    expect(isEmojiOrSymbolOnlyText("🎉")).toBe(true);
    expect(isEmojiOrSymbolOnlyText("👍🏽")).toBe(true);
  });

  it("handles ZWJ sequences without crashing", () => {
    expect(isEmojiOrSymbolOnlyText("👨‍👩‍👧‍👦")).toBe(true);
  });

  it("treats RTL marks plus emoji as emoji-only", () => {
    expect(isEmojiOrSymbolOnlyText("\u200F🎉")).toBe(true);
  });
});
