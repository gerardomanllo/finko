import { looksLikeSmallTalk } from "../../src/telegram/smallTalk";

describe("looksLikeSmallTalk", () => {
  it("detects common EN/ES greetings and thanks", () => {
    expect(looksLikeSmallTalk("hello")).toBe(true);
    expect(looksLikeSmallTalk("hola")).toBe(true);
    expect(looksLikeSmallTalk("hey there")).toBe(true);
    expect(looksLikeSmallTalk("gracias")).toBe(true);
    expect(looksLikeSmallTalk("thanks!")).toBe(true);
    expect(looksLikeSmallTalk("buenos días")).toBe(true);
  });

  it("rejects amounts and long noise", () => {
    expect(looksLikeSmallTalk("12 coffee")).toBe(false);
    expect(looksLikeSmallTalk("hello 5")).toBe(false);
    expect(looksLikeSmallTalk("x".repeat(50))).toBe(false);
  });
});
