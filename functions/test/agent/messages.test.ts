import { actionsFromReplyMarkup } from "../../src/agent/channels/app/messages";

describe("actionsFromReplyMarkup", () => {
  it("parses inline keyboard buttons", () => {
    const actions = actionsFromReplyMarkup({
      inline_keyboard: [
        [
          { text: "✓", callback_data: "cf" },
          { text: "✗", callback_data: "cx" },
        ],
      ],
    });
    expect(actions).toHaveLength(2);
    expect(actions![0].callbackCode).toBe("cf");
    expect(actions![1].callbackCode).toBe("cx");
  });
});
