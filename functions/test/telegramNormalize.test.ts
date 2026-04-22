import {
  isLikelyE164,
  isLikelyTelegramUsername,
  normalizeTelegramUsername,
} from "../src/telegram/normalize";

describe("normalizeTelegramUsername", () => {
  it("strips @ and lowercases", () => {
    expect(normalizeTelegramUsername("@MyUser")).toBe("myuser");
  });
});

describe("isLikelyTelegramUsername", () => {
  it("accepts valid handles", () => {
    expect(isLikelyTelegramUsername("validuser")).toBe(true);
  });

  it("rejects short handles", () => {
    expect(isLikelyTelegramUsername("ab")).toBe(false);
  });
});

describe("isLikelyE164", () => {
  it("accepts +52 plus 10 digits", () => {
    expect(isLikelyE164("+5215512345678")).toBe(true);
  });

  it("rejects too short", () => {
    expect(isLikelyE164("+521234")).toBe(false);
  });
});
