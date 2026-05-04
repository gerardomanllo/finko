import { inferBotLocaleFromUserText, pickBotLocale } from "../../src/telegram/localeInference";
import type { TelegramMessage } from "../../src/telegram/types";

describe("localeInference", () => {
  it("inferBotLocaleFromUserText detects Spanish from diacritics and words", () => {
    expect(inferBotLocaleFromUserText("gasté 100 pesos")).toBe("es");
    expect(inferBotLocaleFromUserText("¿cuánto fue?")).toBe("es");
    expect(inferBotLocaleFromUserText("compré café")).toBe("es");
  });

  it("inferBotLocaleFromUserText detects English spending words", () => {
    expect(inferBotLocaleFromUserText("spent 12 dollars on lunch")).toBe("en");
    expect(inferBotLocaleFromUserText("paid 50 usd")).toBe("en");
  });

  it("inferBotLocaleFromUserText returns null for ambiguous short input", () => {
    expect(inferBotLocaleFromUserText("ok")).toBeNull();
    expect(inferBotLocaleFromUserText("50")).toBeNull();
  });

  it("pickBotLocale respects localeOverride first", () => {
    const msg: TelegramMessage = { from: { language_code: "es" } };
    expect(pickBotLocale({ localeOverride: "en", userText: "gasté mucho", message: msg })).toBe("en");
  });

  it("pickBotLocale uses user text before Telegram language_code", () => {
    const msg: TelegramMessage = { from: { language_code: "en" } };
    expect(pickBotLocale({ userText: "gasté 100 en el super", message: msg })).toBe("es");
  });

  it("pickBotLocale defaults to es when no signal", () => {
    expect(pickBotLocale({ message: {} })).toBe("es");
  });
});
