jest.mock("../src/telegram/chatBindings", () => ({
  deleteTelegramChatBinding: jest.fn().mockResolvedValue(undefined),
}));

jest.mock("../src/telegram/sessions", () => ({
  deleteTelegramBotSession: jest.fn().mockResolvedValue(undefined),
}));

jest.mock("../src/telegram/telegramLinkState", () => ({
  deleteTelegramLinkState: jest.fn().mockResolvedValue(undefined),
}));

import { deleteMyAccountForUid } from "../src/deleteMyAccount";
import { deleteTelegramChatBinding } from "../src/telegram/chatBindings";
import { deleteTelegramBotSession } from "../src/telegram/sessions";
import { deleteTelegramLinkState } from "../src/telegram/telegramLinkState";

describe("deleteMyAccountForUid", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it("deletes Telegram assets when linked, recursiveDeletes user root, deletes auth user", async () => {
    const userRef = { get: jest.fn(), path: "users/u1" };
    const db = {
      doc: jest.fn().mockReturnValue(userRef),
      recursiveDelete: jest.fn().mockResolvedValue(undefined),
    };
    userRef.get.mockResolvedValue({
      exists: true,
      data: () => ({ integrations: { telegram: { chatId: "  99  " } } }),
    });
    const auth = { deleteUser: jest.fn().mockResolvedValue(undefined) };

    await deleteMyAccountForUid(db as never, auth as never, "u1");

    expect(db.doc).toHaveBeenCalledWith("users/u1");
    expect(deleteTelegramChatBinding).toHaveBeenCalledWith(db, "99");
    expect(deleteTelegramBotSession).toHaveBeenCalledWith(db, "99");
    expect(deleteTelegramLinkState).toHaveBeenCalledWith(db, "u1");
    expect(db.recursiveDelete).toHaveBeenCalledWith(userRef);
    expect(auth.deleteUser).toHaveBeenCalledWith("u1");
  });

  it("still recursiveDeletes and deletes auth when profile is missing", async () => {
    const userRef = { get: jest.fn(), path: "users/u1" };
    const db = {
      doc: jest.fn().mockReturnValue(userRef),
      recursiveDelete: jest.fn().mockResolvedValue(undefined),
    };
    userRef.get.mockResolvedValue({ exists: false });
    const auth = { deleteUser: jest.fn().mockResolvedValue(undefined) };

    await deleteMyAccountForUid(db as never, auth as never, "u1");

    expect(deleteTelegramChatBinding).not.toHaveBeenCalled();
    expect(deleteTelegramBotSession).not.toHaveBeenCalled();
    expect(deleteTelegramLinkState).toHaveBeenCalledWith(db, "u1");
    expect(db.recursiveDelete).toHaveBeenCalledWith(userRef);
    expect(auth.deleteUser).toHaveBeenCalledWith("u1");
  });

  it("treats auth/user-not-found as success", async () => {
    const userRef = { get: jest.fn(), path: "users/u1" };
    const db = {
      doc: jest.fn().mockReturnValue(userRef),
      recursiveDelete: jest.fn().mockResolvedValue(undefined),
    };
    userRef.get.mockResolvedValue({ exists: false });
    const err = new Error("not found") as Error & { code: string };
    err.code = "auth/user-not-found";
    const auth = { deleteUser: jest.fn().mockRejectedValue(err) };

    await expect(deleteMyAccountForUid(db as never, auth as never, "u1")).resolves.toBeUndefined();
  });
});
