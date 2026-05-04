/** Narrow Telegram Bot API shapes used by the Finko webhook (extend as needed). */

export type TelegramChat = {
  id?: number;
  username?: string;
  type?: string;
};

export type TelegramUser = {
  id?: number;
  username?: string;
  language_code?: string;
};

export type TelegramPhotoSize = {
  file_id?: string;
  width?: number;
  height?: number;
};

export type TelegramVoice = {
  file_id?: string;
  duration?: number;
};

export type TelegramMessage = {
  message_id?: number;
  date?: number;
  chat?: TelegramChat;
  from?: TelegramUser;
  text?: string;
  caption?: string;
  voice?: TelegramVoice;
  photo?: TelegramPhotoSize[];
  video?: unknown;
  video_note?: unknown;
  animation?: unknown;
  audio?: unknown;
  document?: unknown;
  sticker?: unknown;
  location?: unknown;
  venue?: unknown;
  contact?: unknown;
  poll?: unknown;
  dice?: unknown;
  game?: unknown;
  new_chat_members?: unknown[];
};

export type TelegramCallbackQuery = {
  id?: string | number;
  from?: TelegramUser;
  message?: TelegramMessage;
  inline_message_id?: string;
  data?: string;
};

export type TelegramUpdate = {
  update_id?: number;
  message?: TelegramMessage;
  edited_message?: TelegramMessage;
  callback_query?: TelegramCallbackQuery;
  channel_post?: TelegramMessage;
  edited_channel_post?: TelegramMessage;
  inline_query?: unknown;
  my_chat_member?: unknown;
};
