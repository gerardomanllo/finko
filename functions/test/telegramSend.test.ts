import { telegramSendMessage } from "../src/telegram/telegramSend";

describe("telegramSendMessage", () => {
  const originalFetch = global.fetch;

  afterEach(() => {
    global.fetch = originalFetch;
  });

  it("returns ok when Telegram API succeeds", async () => {
    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      json: async () => ({ ok: true }),
    } as unknown as Response);

    const r = await telegramSendMessage("fake-token", "12345", "hello");
    expect(r.ok).toBe(true);
    expect(global.fetch).toHaveBeenCalledTimes(1);
  });

  it("returns failure when API errors", async () => {
    global.fetch = jest.fn().mockResolvedValue({
      ok: false,
      json: async () => ({ ok: false, description: "Forbidden" }),
    } as unknown as Response);

    const r = await telegramSendMessage("fake-token", "12345", "hello");
    expect(r.ok).toBe(false);
    if (!r.ok) {
      expect(r.description).toContain("Forbidden");
    }
  });
});
