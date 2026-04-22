import { telegramStartLinkTokenFromMessageText } from "../src/telegram/parseTelegramStart";

describe("telegramStartLinkTokenFromMessageText", () => {
  it("parses /start link_<token> (hex)", () => {
    expect(telegramStartLinkTokenFromMessageText("/start link_deadbeef")).toBe("deadbeef");
  });

  it("parses /start@BotUsername link_<token>", () => {
    expect(
      telegramStartLinkTokenFromMessageText("/start@FinkoDevBot link_deadbeef")
    ).toBe("deadbeef");
  });

  it("decodes URL-encoded payload fragment", () => {
    expect(telegramStartLinkTokenFromMessageText("/start link_%30%31%32")).toBe("012");
  });

  it("returns null for plain /start", () => {
    expect(telegramStartLinkTokenFromMessageText("/start")).toBeNull();
  });

  it("returns null for wrong prefix", () => {
    expect(telegramStartLinkTokenFromMessageText("/start other")).toBeNull();
  });
});
