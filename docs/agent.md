# In-app agent (primary channel)

The **in-app agent** is Finko’s canonical way to log transactions and talk to the product. **Telegram** remains a legacy channel (see [`references/telegram-bot-webhook.md`](references/telegram-bot-webhook.md)); new UX (status labels, thread history, native pickers) ships here first.

## Route and shell

| Item | Detail |
|------|--------|
| Path | `/agent` — root stack route, **no** bottom navigation ([`shell-navigation.md`](shell-navigation.md)) |
| Entry | **`AgentEntryPill`** on shell tabs only (hidden on drawer, modals, CRUD stack routes, auth) |
| Back | App bar returns to **`/dashboard`** in one tap |

## Data

| Path | Access |
|------|--------|
| `users/{uid}/agentMessages/{messageId}` | Client read; Functions write |
| `appAgentSessions/{uid}` | Functions only (FSM / draft) |
| `users/{uid}.agentPreferences` | Client merge (renamed from `telegramBotPreferences`) |
| `users/{uid}.launchScreen` | `dashboard` \| `agent` (default `dashboard`) |
| Storage `users/{uid}/agentMedia/{id}` | Client write; Functions read |
| SharedPreferences `finko_agent_catalog_{uid}` | Client only — slim snapshot of categories, accounts, and `agentPreferences` for instant agent resolution (see below) |

## Local catalog + client draft resolution

**`AgentCatalogSyncListener`** (app root) writes a device snapshot whenever **`categoriesStreamProvider`**, **`accountsStreamProvider`**, or profile **`agentPreferences`** emit. **`agentCatalogProvider`** prefers live streams and falls back to the snapshot so the agent card is instant on cold start.

On send, **`resolveAgentDraft`** resolves each field in order:

| Field | Explicit | Implicit | Default |
|-------|----------|----------|---------|
| Amount | Regex in user text | — | unset (skeleton) |
| Memo | Remainder after amount | — | unset |
| Direction | Income/expense keywords | Category kind when matched | **Expense** |
| Category | Chip / field editor | Fuzzy name match in query | `agentPreferences` default for direction |
| Account | Chip / field editor | Fuzzy name match in query | `agentPreferences.defaultAccountId` |

**`buildAgentFlowPlan`** skips category/account picker steps when the draft already resolves those IDs (including via defaults). When all required fields are present, the card shows **Confirm** immediately.

Fields filled via **defaults** show a **Suggested** chip and primary accent on the live card (`agentFieldSuggested`); explicit and implicit values have no cue. Server callables are unchanged (Phase 1); confirm/post still runs on Cloud Functions in the background.

## Processing UX

While a turn runs, the UI shows **`AgentStatusRow`**: typing indicator + playful label from **`statusLabelKey`** (localized in ARB).

When the agent asks to **confirm a transaction or transfer**, the thread renders one **live transaction card** per flow: **amount, memo, direction, category, and account** appear immediately from the local catalog + draft resolver when possible; each manual choice **adds a field with a fade-in**, and the **choice grid swaps in-place** for the next question. **Before save**, tapping any field on the card (amount, note, category, account, or type badge) opens **`AgentDraftFieldEditorSheet`** to edit that value locally. After confirm, the card **seals** (success banner, no buttons).

On failure, **`AgentFailedRow`**: playful **`errorLabelKey`**, optional retry, dismiss (✕). Failed rows are **dismissable** and **auto-hidden** when a later turn succeeds (`superseded` on server; client filters as backup).

### Status keys (EN examples)

| Key | EN |
|-----|-----|
| `agentStatus.receiving` | Got it — one sec… |
| `agentStatus.readingReceipt` | Receipt detective mode… |
| `agentStatus.extractingAmount` | Hunting for numbers… |
| `agentStatus.transcribing` | Ears on — decoding your voice note… |
| `agentStatus.understanding` | Turning words into money moves… |
| `agentStatus.thinking` | Doing the math in my head… |
| `agentStatus.almostThere` | Almost there… |
| `agentStatus.loadingCategories` | Rounding up your categories… |
| `agentStatus.loadingAccounts` | Checking which account… |
| `agentStatus.saving` | Locking it in… |

### Error keys

| Key | EN |
|-----|-----|
| `agentError.generic` | Hmm, I tripped on that one. |
| `agentError.media` | Couldn't make sense of that file — try another? |
| `agentError.timeout` | That took too long — want to send it again? |

## Callables

| Callable | Role |
|----------|------|
| `sendAgentMessage` | Text and/or Storage media; idempotent `clientMessageId` |
| `submitAgentAction` | Native chips → same action codes as legacy bot (`cf`, `pc:N`, …) |
| `dismissAgentMessage` | User dismissed a failed row |

## Launch preference

First open of `/agent` may prompt: **open app to agent**. Sets `launchScreen: agent` on profile + local cache; splash uses [`resolvePostSplashLocation`](../lib/app/auth_redirect.dart). Reversible in Settings.

## Revision log

| Date | Change |
|------|--------|
| 2026-06-01 | **Local catalog:** SharedPreferences snapshot of categories/accounts + **`resolveAgentDraft`** (explicit → implicit → default); instant confirm when defaults fill gaps; **Suggested** affordance on defaulted fields. |
| 2026-05-22 | Optimistic send (instant user bubble + loader), local flow plan with step dots, Spanish direction parsing, subtle Cancel link. |
| 2026-05-22 | Initial spec: primary in-app agent, playful status UX, FAB, launch preference. |
| 2026-05-22 | Fix `sendAgentMessage` INTERNAL: omit `undefined` Firestore fields; app channel skips strict Gemini locale gate; safe `GEMINI_API_KEY` read. |
