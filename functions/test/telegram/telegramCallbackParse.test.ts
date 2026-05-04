import { parseTelegramCallbackData } from "../../src/telegram/handleUpdate";

describe("parseTelegramCallbackData", () => {
  const ok: [string, ReturnType<typeof parseTelegramCallbackData>][] = [
    ["cf", { t: "confirm" }],
    ["cx", { t: "cancel" }],
    ["ry", { t: "rec_yes" }],
    ["rn", { t: "rec_no" }],
    ["rm", { t: "rec_cad", cadence: "monthly" }],
    ["rt", { t: "rec_cad", cadence: "twiceMonthly" }],
    ["rb", { t: "rec_cad", cadence: "biweekly" }],
    ["rw", { t: "rec_cad", cadence: "weekly" }],
    ["pa:0", { t: "pick_acc", idx: 0 }],
    ["pc:3", { t: "pick_cat", idx: 3 }],
    ["tf:1", { t: "tf", idx: 1 }],
    ["tt:2", { t: "tt", idx: 2 }],
  ];

  it.each(ok)("parses %s", (raw, expected) => {
    expect(parseTelegramCallbackData(raw)).toEqual(expected);
  });

  it("returns null for tampered or unknown payloads", () => {
    expect(parseTelegramCallbackData("")).toBeNull();
    expect(parseTelegramCallbackData("evil")).toBeNull();
    expect(parseTelegramCallbackData("pa:x")).toBeNull();
    expect(parseTelegramCallbackData("pa:")).toBeNull();
  });
});
