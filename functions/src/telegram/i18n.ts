import type { BotLocale } from "./sessions";

export type MessageKey =
  | "link_connected"
  | "plain_start_hint"
  | "link_token_expired"
  | "link_token_used_other"
  | "link_token_invalid"
  | "small_talk_hint"
  | "generic_error"
  | "help"
  | "not_linked"
  | "unsupported_media"
  | "message_too_long"
  | "emoji_only"
  | "empty_message"
  | "session_expired"
  | "callback_invalid"
  | "callback_saved"
  | "callback_discarded"
  | "transfer_same_account"
  | "posted_expense"
  | "posted_income"
  | "posted_transfer"
  | "posted_recurring"
  | "cancelled"
  | "pick_account"
  | "pick_category"
  | "confirm_transaction"
  | "confirm_transfer"
  | "amount_missing"
  | "parse_error"
  | "need_amount"
  | "need_memo"
  | "conversational_parse_requires_gemini"
  | "language_not_understood"
  | "make_recurring_prompt"
  | "no_categories_available"
  | "no_accounts_available"
  | "pick_transfer_from"
  | "pick_transfer_to"
  | "transfer_enter_amount"
  | "processing_photo"
  | "processing_voice"
  | "pick_recurring_cadence";

const STRINGS: Record<MessageKey, Record<BotLocale, string>> = {
  link_connected: {
    en: "Finko: Telegram is connected. Open the app anytime, or chat here to log expenses and income.",
    es: "Finko: Telegram conectado. Abre la app cuando quieras, o escribe aquí para registrar gastos e ingresos.",
  },
  plain_start_hint: {
    en: "Open Finko → Settings / Onboarding → Telegram → Next and tap Start in this chat using the link from the app.",
    es: "Abre Finko → Ajustes u onboarding → Telegram → Siguiente y pulsa Iniciar en este chat con el enlace de la app.",
  },
  link_token_expired: {
    en:
      "This link expired. Open Finko → Settings → Telegram, tap Next, and start the bot again with the new link from the app.",
    es:
      "Este enlace expiró. Abre Finko → Ajustes → Telegram, pulsa Siguiente e inicia el bot otra vez con el enlace nuevo de la app.",
  },
  link_token_used_other: {
    en:
      "This link was already used from another Telegram chat, or is no longer valid. Open Finko → Settings → Telegram and generate a fresh link.",
    es:
      "Este enlace ya se usó desde otro chat de Telegram o ya no es válido. Abre Finko → Ajustes → Telegram y genera un enlace nuevo.",
  },
  link_token_invalid: {
    en: "I couldn’t verify that link. Open Finko → Settings → Telegram and try connecting again.",
    es: "No pude verificar ese enlace. Abre Finko → Ajustes → Telegram e intenta vincular de nuevo.",
  },
  small_talk_hint: {
    en:
      "Hi! I'm Finko — your personal finance assistant. You can log spending and income right here in chat. Try something like `12 coffee` or `+50 paycheck`. Type /help for all commands.",
    es:
      "¡Hola! Soy Finko, tu asistente de finanzas personales. Puedes registrar gastos e ingresos aquí en el chat. Por ejemplo: `12 café` o `+50 nómina`. Escribe /help para ver todos los comandos.",
  },
  generic_error: {
    en: "Something went wrong on our side. Please try again in a moment, or open the Finko app.",
    es: "Algo salió mal de nuestro lado. Intenta de nuevo en un momento o abre la app Finko.",
  },
  help: {
    en:
      "Commands:\n" +
      "/help — this message\n" +
      "/cancel — reset draft\n" +
      "Expense: `50 coffee` or tap menus after sending an amount.\n" +
      "Income: `+100 paycheck`\n" +
      "Transfer: `/transfer`\n" +
      "Photo receipts and voice notes are supported after linking.",
    es:
      "Comandos:\n" +
      "/help — este mensaje\n" +
      "/cancel — borrar borrador\n" +
      "Gasto: `50 café` o usa los menús tras enviar un monto.\n" +
      "Ingreso: `+100 nómina`\n" +
      "Transferencia: `/transfer`\n" +
      "Fotos de ticket y notas de voz funcionan tras vincular.",
  },
  not_linked: {
    en: "Link Telegram from the Finko app first (Settings → Telegram).",
    es: "Primero vincula Telegram desde la app Finko (Ajustes → Telegram).",
  },
  unsupported_media: {
    en: "I can't use that attachment yet. Send text, a photo, or a voice note, or try /help.",
    es: "Aún no puedo usar ese archivo. Envía texto, foto o nota de voz, o prueba /help.",
  },
  message_too_long: {
    en: "That message is too long. Send something shorter (amount + short note).",
    es: "El mensaje es demasiado largo. Envía algo más corto (monto + nota breve).",
  },
  emoji_only: {
    en: "Send an amount and description (e.g. `12 coffee`) or type /help.",
    es: "Envía un monto y descripción (ej. `12 café`) o escribe /help.",
  },
  empty_message: {
    en: "Send text, a photo with optional caption, or a voice note.",
    es: "Envía texto, foto con texto opcional o nota de voz.",
  },
  session_expired: {
    en: "Session expired — start again with an amount or /help.",
    es: "Sesión caducada — empieza de nuevo con un monto o /help.",
  },
  callback_invalid: {
    en: "That button is no longer valid. Send a new message or /cancel.",
    es: "Ese botón ya no es válido. Envía un mensaje nuevo o /cancel.",
  },
  callback_saved: {
    en: "Saved.",
    es: "Guardado.",
  },
  callback_discarded: {
    en: "Discarded.",
    es: "Descartado.",
  },
  transfer_same_account: {
    en: "Pick two different accounts.",
    es: "Elige dos cuentas distintas.",
  },
  posted_expense: {
    en: "Expense recorded: {{memo}} — {{amount}}",
    es: "Gasto registrado: {{memo}} — {{amount}}",
  },
  posted_income: {
    en: "Income recorded: {{memo}} — {{amount}}",
    es: "Ingreso registrado: {{memo}} — {{amount}}",
  },
  posted_transfer: {
    en: "Transfer recorded — {{amount}}",
    es: "Transferencia registrada — {{amount}}",
  },
  posted_recurring: {
    en: "Recurring rule created.",
    es: "Regla recurrente creada.",
  },
  cancelled: {
    en: "Cancelled.",
    es: "Cancelado.",
  },
  pick_account: {
    en: "{{amountHint}}Pick an account — tap a button:",
    es: "{{amountHint}}Elige una cuenta — toca un botón:",
  },
  pick_category: {
    en: "{{amountHint}}Pick a category — tap a button:",
    es: "{{amountHint}}Elige una categoría — toca un botón:",
  },
  confirm_transaction: {
    en:
      "Please confirm transaction\nType: {{direction}}\nAmount: {{amount}}\nCategory: {{category}}\nAccount: {{account}}\nNote: {{memo}}",
    es:
      "Confirma la transacción\nTipo: {{direction}}\nMonto: {{amount}}\nCategoría: {{category}}\nCuenta: {{account}}\nNota: {{memo}}",
  },
  confirm_transfer: {
    en:
      "Confirm TRANSFER\nFrom: {{fromAcc}} ({{fromCur}})\nTo: {{toAcc}} ({{toCur}})\nOut: {{amountOut}}\nIn: {{amountIn}}\nNote: {{memo}}",
    es:
      "Confirmar TRANSFERENCIA\nDesde: {{fromAcc}} ({{fromCur}})\nHacia: {{toAcc}} ({{toCur}})\nSalida: {{amountOut}}\nEntrada: {{amountIn}}\nNota: {{memo}}",
  },
  amount_missing: {
    en: "Include an amount (e.g. `25 tacos`).",
    es: "Incluye un monto (ej. `25 tacos`).",
  },
  parse_error: {
    en: "Couldn't read that. Try `amount note` or /help.",
    es: "No entendí. Prueba `monto nota` o /help.",
  },
  need_amount: {
    en: "How much? Send the amount (numbers only is fine, e.g. `120.50`).",
    es: "¿Cuánto? Envía el monto (solo números vale, ej. `120.50`).",
  },
  need_memo: {
    en: "What was this for? Send a short name or note.",
    es: "¿En qué fue? Envía un nombre o nota breve.",
  },
  conversational_parse_requires_gemini: {
    en:
      "Full conversational logging in English/Spanish needs the Telegram bot AI feature enabled (Gemini). Try a simple pattern like `50 coffee`, or use the Finko app.",
    es:
      "Registrar en inglés o español conversacional requiere la función de IA del bot (Gemini) activa. Prueba un formato simple como `50 café`, o usa la app Finko.",
  },
  language_not_understood: {
    en: "I can only process English or Spanish right now. Please send your message in English or Spanish.",
    es: "Por ahora solo puedo procesar inglés o español. Envía tu mensaje en inglés o español.",
  },
  make_recurring_prompt: {
    en: "Make this recurring?",
    es: "¿Hacer esto recurrente?",
  },
  no_categories_available: {
    en: "I couldn't find matching categories in your account. Please add categories in the app first.",
    es: "No encontré categorías compatibles en tu cuenta. Agrega categorías en la app primero.",
  },
  no_accounts_available: {
    en: "I couldn't find accounts in your profile. Please add an account in the app first.",
    es: "No encontré cuentas en tu perfil. Agrega una cuenta en la app primero.",
  },
  pick_transfer_from: {
    en: "Transfer: pick **from** account:",
    es: "Transferencia: cuenta **origen**:",
  },
  pick_transfer_to: {
    en: "Pick **to** account:",
    es: "Cuenta **destino**:",
  },
  transfer_enter_amount: {
    en: "Send the amount and optional memo (e.g. `500 rent`).",
    es: "Envía el monto y nota opcional (ej. `500 renta`).",
  },
  processing_photo: {
    en: "Got the photo — extracting details…",
    es: "Foto recibida — extrayendo datos…",
  },
  processing_voice: {
    en: "Got the voice note — transcribing…",
    es: "Nota de voz recibida — transcribiendo…",
  },
  pick_recurring_cadence: {
    en: "Pick recurring cadence:",
    es: "Elige la frecuencia recurrente:",
  },
};

export function t(locale: BotLocale, key: MessageKey, vars?: Record<string, string>): string {
  let s = STRINGS[key][locale] ?? STRINGS[key].en;
  if (vars) {
    for (const [k, v] of Object.entries(vars)) {
      s = s.replaceAll(`{{${k}}}`, v);
    }
  }
  return s;
}
