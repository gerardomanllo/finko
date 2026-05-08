import { resolveIdAtIndex } from "../../src/telegram/telegramPickerOrder";

describe("resolveIdAtIndex", () => {
  it("prefers persisted order over positional fallback", () => {
    const order = ["z", "a", "m"];
    expect(resolveIdAtIndex(order, 1, ["a", "b", "c"])).toBe("a");
  });

  it("falls back to list index when order missing", () => {
    expect(resolveIdAtIndex(undefined, 0, ["x", "y"])).toBe("x");
  });

  it("returns null for out of range index", () => {
    expect(resolveIdAtIndex(["a"], 9, ["a"])).toBeNull();
  });
});
