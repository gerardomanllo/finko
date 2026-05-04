import { localeForSmallTalkReply, looksLikeSmallTalk } from "../../src/telegram/smallTalk";

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

describe("localeForSmallTalkReply", () => {
  it("uses Spanish for clear ES greetings and default-ambiguous tokens", () => {
    expect(localeForSmallTalkReply("hola")).toBe("es");
    expect(localeForSmallTalkReply("gracias")).toBe("es");
    expect(localeForSmallTalkReply("buenos días")).toBe("es");
    expect(localeForSmallTalkReply("yo")).toBe("es");
    expect(localeForSmallTalkReply("sup")).toBe("es");
  });

  it("uses English for clear EN greetings and thanks", () => {
    expect(localeForSmallTalkReply("hi")).toBe("en");
    expect(localeForSmallTalkReply("hello")).toBe("en");
    expect(localeForSmallTalkReply("thanks")).toBe("en");
    expect(localeForSmallTalkReply("thank you")).toBe("en");
    expect(localeForSmallTalkReply("good morning")).toBe("en");
    expect(localeForSmallTalkReply("hey there")).toBe("en");
  });
});
