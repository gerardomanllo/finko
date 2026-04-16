# Backend strategy & aggregation (living document)

This document captures **how we understand Finko today**, the **aggregation problem**, and a **recommended Firebase-centric backend** that balances **scalability**, **pricing**, and **performance**. It is meant to evolve: when decisions change, update the **Revision log** at the bottom.

---

## 1. How we understand the app (current)

**Finko** is a **personal** finance tracker (Flutter on iOS, Android, Web). Users manage **accounts**, **categories**, **transactions** (past and upcoming), **budgets**, and **recurring** cash flows. Auth is email/password plus Google and Apple. Optional **WhatsApp / Telegram** integrations are for **messaging-based flows** (e.g. sending transactions or querying data via links the user configures), not for core OLTP storage.

**Core domains (conceptual):**

| Domain | Role |
|--------|------|
| **Accounts** | Containers with a type (checking, credit, savings, investment, etc.) and balances derived from activity. **Net cash** is a **derived aggregate** across cash-flow-heavy accounts, not a stored account row. |
| **Transactions** | Dated, amount, category, account(s); includes **scheduled / future** rows for “upcoming” UI. |
| **Categories** | Income vs expense taxonomy; drives budgets and charts. |
| **Budgets** | Monthly (and possibly category-level) targets vs spend. |
| **Recurring** | Rules that project **next occurrences** and power the two-week calendar and “due soon” lists. |

**Read-heavy surfaces (aggregation-heavy):**

- **Dashboard**: Net worth trend (~30 days), monthly expense snapshot, account-type accordion with balances, upcoming + recent transactions, monthly budget teaser with top categories.
- **Spending**: Period pills (week → year), per-period income/expense mini-metrics, donut + top transactions.
- **Budgets**: Month pager, spending pace, bills vs earnings, savings projection, per-category progress.

The **hottest path** is the **dashboard**: many metrics at once, often on every app open. Doing all of that by **scanning raw transactions on the client** does not scale in **read cost**, **latency**, or **battery**—especially as history grows.

---

## 2. What “aggregation” means here

**Aggregation** is any **roll-up** of many rows into a smaller set of numbers or time series used by the UI: balances, monthly totals, category splits, net worth over time, budget burn-down, recurring projections.

We can group aggregates by **freshness** and **write frequency**:

| Aggregate | Typical freshness | Notes |
|-----------|-------------------|--------|
| **Per-account balance** | Near real-time | Updates on each affecting transaction (transfers, CC payments, etc.). |
| **Net worth (current)** | Near real-time | Sum of account balances + investment positions if added later. |
| **Net worth history (e.g. 30 days)** | Near real-time | Series is stored as **daily buckets**; each balance-affecting tx **incrementally** updates the right days; backdated txs restate past buckets. |
| **Calendar month income / expense** | Near real-time | Drives cards, pills, and accordions. |
| **Category spend (month, top-N, donut)** | Near real-time | Incrementally maintain monthly per-category totals. |
| **Budget progress** | Near real-time | Derived from category spend vs monthly targets. |
| **Recurring “next date” / calendar dots** | Minutes to hours | Can be **recomputed** from rules; notifications may need server truth. |
| **Search / full transaction list** | N/A | **Not** aggregated—**indexed raw reads** with filters and pagination. |

The **main decision** is where each aggregate **lives** and **who maintains it** (client vs server vs scheduled job).

---

## 3. Options considered (short)

| Approach | Pros | Cons |
|----------|------|------|
| **Client-only** (load transactions, aggregate in Dart) | Simple to ship v0 | Read volume and memory grow with history; slow dashboard; inconsistent if multiple clients. |
| **Firestore queries only** (e.g. `sum` via many reads) | No Functions code | Firestore has **no** server-side `SUM` across arbitrary filters; you still read docs or use narrow shards. |
| **Incremental aggregates in Firestore** (denormalized counters/summary docs updated on write) | **Predictable read cost** for dashboard; **O(1)** reads per widget | More writes per transaction; must handle **correctness** (idempotency, edits, deletes, multi-account transfers). |
| **Scheduled Cloud Functions** (cron rollups) | Cheap for **historical** series (e.g. daily net worth point) | Not alone for “just posted a transaction” UX—combine with incremental or targeted recompute. |
| **BigQuery (export extension or ETL)** | Great for **ad-hoc analytics** and huge history | Cold path; overkill for core dashboard MVP; extra cost and pipeline complexity. |

**Conclusion for Finko:** **incremental aggregates** for hot paths (balances, monthly/category slices, month and day buckets). **Scheduled** rollups are **not** part of the MVP product contract—see [`data-contract.md`](data-contract.md): aggregates stay current via **write triggers** + **real-time listeners**. Optional **BigQuery** remains a later analytics path.

---

## 4. Recommendation: Firebase services (balanced)

### 4.1 Primary stack (MVP → growth)

| Service | Use | Why |
|---------|-----|-----|
| **Firebase Authentication** | Email/password, Google, Apple | Standard fit for Flutter; ties to `uid`-scoped data. |
| **Cloud Firestore** | System of record: transactions, accounts metadata, categories, budgets, recurring rules; **plus aggregate/summary documents** | Real-time sync, offline-friendly clients, security rules per `uid`. Aggregates live in **known doc paths** to cap dashboard reads. |
| **Cloud Functions** (2nd gen) | **Triggers** on transaction (and related) writes to **patch aggregate docs**; optional **HTTPS** for Telegram/WhatsApp webhooks later | Keeps client thin; **no** cron-driven aggregation in MVP ([`data-contract.md`](data-contract.md)). |
| **Cloud Storage** | Optional: attachments, exports, statement PDFs | Not required for aggregation; add when product needs files. |
| **Firebase Hosting** | Web app | Already planned; pair with framework if using Flutter web build. |
| **App Check** | Protect callable/HTTP endpoints and reduce abuse | Enable before public webhooks. |

### 4.2 Aggregation pattern (recommended shape)

1. **Transactional source of truth**  
   Store **immutable or versioned** transaction rows under something like `users/{uid}/transactions/{txId}` with enough fields to recompute if needed (**repair job**).

2. **Incremental summary documents** (maintained by Functions)  
   Examples (names illustrative):  
   - `users/{uid}/summaries/monthly/{yyyy-mm}` — total income, expense, optional per-category map or subcollections.  
   - `users/{uid}/accounts/{accountId}` — **current balance** and maybe **last reconciled** metadata.  
   - `users/{uid}/summaries/netWorthDaily/{yyyy-mm-dd}` — one point per day for charts (written by **schedule** or throttled updates).

3. **Idempotency & edge cases**  
   Use **transaction IDs**, **writes with deterministic keys** for derived rows, or **Firestore transactions** when updating multiple aggregates so **retries** do not double-count. Transfers and splits must update **two** accounts and **category** logic consistently—centralizing in Functions reduces bugs.

4. **Reads for dashboard**  
   Prefer **a handful of document reads** (summaries + account list) instead of querying all transactions for the month.

### 4.3 Pricing & performance (practical tradeoffs)

- **Writes**: Each transaction may trigger **several aggregate updates**—still usually **cheaper** than daily full scans of history on the client, and **read pricing** dominates for a read-heavy dashboard.
- **Functions**: Batch related updates; avoid **N** sequential writes per field—use **batched writes** or a single summary doc where possible.
- **Indexes**: Only add composite indexes **required** by list screens (e.g. transactions by date desc); aggregates reduce need for heavy ad-hoc queries.

### 4.4 What we are **not** leading with

- **Firebase Data Connect (PostgreSQL)** — strong for relational reporting and joins; adds **ops + schema migration** surface. Consider if you later need **complex SQL reporting** or **strong multi-entity consistency** in one database. Not required for first Firebase-native MVP if Firestore + Functions is modeled cleanly.
- **Realtime Database** — possible for presence or ultra-low-latency counters; **not** necessary if Firestore + aggregate docs meet latency goals.

---

## 5. Open questions (to resolve in future revisions)

- **Investment / holdings**: If net worth includes live market prices, aggregation may pull from **external quotes** (scheduled) vs manual balances.
- **Multi-currency**: Requires FX source and whether aggregates are **per currency** or **normalized to one display currency**.
- **WhatsApp / Telegram**: Likely **HTTPS Functions** + verified webhooks; still **write into** the same transaction pipeline so aggregation rules stay one place.
- **Compliance / export**: GDPR-style delete must **purge** or anonymize transactions **and** rebuild or delete aggregate docs—design **uid** lifecycle early.

---

## 6. Hierarchical paths, two-layer aggregation, and backdated transactions

### 6.1 Product constraint (near real-time + backdating)

All aggregates that power the UI should be **near real-time**. Users often enter transactions **days or weeks late**; aggregation must **never** assume “only today” updates. Every transaction carries a **business date** (and optionally `createdAt`). **Any** write with an arbitrary date must **correctly restate** the affected **day** and **month** (and accounts, categories, net-worth buckets).

### 6.2 Does a month → day → transaction hierarchy make sense?

A layout such as:

`users/{userId}/ledger/{yyyy-mm}/days/{dd}/transactions/{transactionId}`

(or the same idea with `transactions` as the month collection name) is **logically coherent**: the path encodes the **date dimension**, so a trigger scoped to that write knows **which month and day** are in play without scanning the whole database.

**Important:** Firestore does **not** automatically roll up child documents into parents. There is **no** built-in `SUM` or map-reduce. **Cloud Functions** (or client-side writes you control) perform aggregation. The hierarchy helps **humans and triggers route updates**; it does not replace **incremental math**.

### 6.3 “Reaggregation” — full re-sum vs incremental deltas

- **Avoid** chaining triggers that **re-read every transaction in a month** on each insert to recompute totals. That **scales poorly** (read costs grow with history) and adds latency.
- **Prefer** **incremental** updates: on create/update/delete, apply **deltas** to:
  - a **day** summary (optional),
  - a **month** summary doc (`…/summaries/monthly/{yyyy-mm}` or equivalent),
  - **account** balances,
  - **category** counters for that month,
  - and any **user-level** rollups that are simple functions of those (again incrementally).

For **edits** and **date changes**, the function needs **before/after** (or a replay of old state) to **subtract** old contributions and **add** new ones—possibly touching **two** months if the date moves across a boundary.

### 6.4 One trigger wave vs stacked triggers

A **cascading** design (trigger on day doc → writes month doc → another trigger writes user doc) **works** but is easy to get wrong:

- **More invocations** = more cost and more chances for **races** or duplicate application.
- Prefer **one** `onWrite` on the transaction document that **batch-writes** (or uses a **Firestore transaction**) to update **day (if modeled), month summary, accounts, and user-level counters** in a **single** logical step—**or** a single downstream step with explicit idempotency keys.

Stacked triggers are acceptable if **idempotent** and cheap; **single-pass** is usually simpler to reason about.

### 6.5 Hierarchical storage vs flat `transactions/{txId}`

| | **Nested by month/day** | **Flat collection + date fields** |
|--|-------------------------|-----------------------------------|
| **Pros** | Path encodes bucket; natural scope for triggers | Simple **global list** queries (`orderBy(date)` + pagination); **one doc move** when correcting date (still two logical buckets if month changes). |
| **Cons** | **Date change** may require **delete + create** across paths; “all transactions” needs **collection group** query + indexes | Trigger must derive `yyyy-mm` / `dd` from fields—trivial in code |

Both are valid. Many teams use **flat** transaction docs with indexed `postedOn` / `yearMonth` fields for queries, and **separate** summary collections for aggregates. Others use **nested** docs for strong physical locality. **Pick one primary query pattern** (full ledger list vs bucket-only reads) and optimize for it.

### 6.6 Scalability notes

- **Personal** scale: one user rarely exceeds Firestore **sustained write** limits on a single doc; still avoid making one **giant** document hold unbounded maps (e.g. every category ever). Prefer **bounded** monthly summary docs or **subcollections** for category shards if maps grow large.
- **Hotspot**: A single `users/{uid}/summary/total` updated on every tx worldwide is usually fine for **one user**; multi-tenant **shared** counters would need sharding—**not** the typical personal-finance model.

### 6.7 How to improve the two-layer idea

1. **Incremental counters everywhere**; full **recompute** only via admin repair or migrations.
2. **Single function path** with **batched writes** / **transactions** for multi-doc consistency.
3. **Explicit handling** of **transfers** and **splits** so the same event does not double-count category or cash-flow metrics.
4. **Optional day-level** summary docs only if the UI or charts need them; otherwise **month** + **account** + **net-worth daily** may suffice.
5. **Collection group** indexes if using nested paths and querying across months.

### 6.8 Flat `transactions/{transactionId}` + diffed summaries — what to store per period?

**Yes — recommended:** keep a **flat** ledger `users/{userId}/transactions/{transactionId}` (with `postedOn`, amounts, account refs, category, etc.) and apply **incremental diffs** to a **small set of summary documents** on every write. That is the usual scalable pattern.

**No — you usually do *not* need one maintained document family per UI period** (week, month, quarter, year, rolling 30) all **updated on every transaction**. That **write amplification** adds cost and failure modes. Instead, split **canonical buckets** (cheap to update on each tx) from **views** (computed when needed or cached lightly).

| Bucket | Typical role | Updated on every affecting tx? |
|--------|----------------|-------------------------------|
| **Per-account balance** (or running total) | Current P&L / accordion | **Yes** (diff) |
| **Per calendar month** — income, expense, per-category totals | Budgets, spending month mode, donut for that month | **Yes** (diff into `summaries/monthly/{yyyy-mm}` or equivalent) |
| **Per calendar day** — spend/income (optional split by category) | Week strips, building week/quarter from days, “activity by day” | **Often yes** for the **affected day(s)** only — small diff |
| **Calendar week / quarter / year** as separate docs | Convenience | **Usually no** — **derive** by summing **daily** or **monthly** docs in range at **read time**, or run a **scheduled** job to refresh a cache if reads are hot |
| **Rolling last 30 days** | Dashboard chart | **Usually no** as a single pre-merged doc updated on every tx — often **query** the last **30 daily** summary docs (or recompute a bounded window in a Function **on read** if daily set is small) |

**Why not maintain week + quarter + year + rolling 30 all incrementally?**  
Each transaction would touch **many** period keys (e.g. which ISO week? which fiscal quarter?), and **backdated** txs would rewrite past periods repeatedly. **Month + day** (and account) are enough to **derive** larger periods without N×writes per event.

**Net worth / balance *history* caveat:**  
A tx posted in the past changes **cumulative** balance from that date forward. Purely **incremental daily net-worth** docs may require updating **many** day buckets after a backdated transfer (or you accept **nightly** reconciliation / **recompute** for charts). Product choice: **eventual** chart accuracy vs write fan-out — document explicitly when you implement.

**Practical default:**  
- **Write path (diff):** accounts + **monthly** aggregates + **daily** income/expense (and category maps as needed).  
- **Read path:** week / quarter / year / rolling windows = **sum over** dailies or monthlies in range, unless profiling says you need **materialized** week/quarter caches.

### 6.9 Many day buckets touched by a backdated tx — downside, and clean fast patterns

**Two different problems — do not conflate:**

| Metric | What a backdated tx touches | Fan-out |
|--------|------------------------------|--------|
| **Non-cumulative** (spend/income **on** a day, category totals for a month) | Only the **true calendar day(s)** and **month(s)** for that tx | **O(1)** summary docs per write (plus account if needed) |
| **Cumulative** (end-of-day **net worth** or running balance **through time**) | Every **subsequent** calendar day up to “today” in the stored series | **O(days)** document updates if you incrementally patch each day |

**Downside of updating many day buckets for cumulative series**

- **Write cost**: Firestore bills **per document write**; one backdated tx could mean **hundreds** of `dailyNetWorth` updates.
- **Function time**: Approaches **batch limits** (500 writes/batch), needs chunking, longer cold runs.
- **Hotspots & races**: Sequential updates to adjacent day docs; concurrent backdated txs need careful ordering or **single-writer** semantics.
- **Failure modes**: Partial updates leave an inconsistent curve until repaired.

So for **many backdated transactions**, **do not** make “patch every future day document on every write” your primary strategy for **cumulative** charts.

**Recommended directions (pick one primary; combine as needed)**

1. **Materialize the chart window in one pass (preferred for clarity)**  
   On demand (or on a **debounced** trigger): run a **single** Cloud Function that:
   - Loads **ordered** transactions (or account legs) needed to build **end-of-day net worth** for each day in `[chartStart, chartEnd]` — often by **one streaming query** or paginated reads + in-memory sweep.
   - Writes **only the `N` daily points** for that window in **batched writes**, or returns the series to the client without persisting.  
   **Key:** you **read** history once per recompute, not **fan out writes** per day on the hot path of every tx.

2. **Checkpoint + replay only a suffix**  
   Store rare **checkpoints** (e.g. end-of-month total balance / per-account). To build a 30-day chart, start from the **latest checkpoint before the window** and apply only txs in `(checkpointDate, end]` — caps work if checkpoint is valid. **Invalidate** checkpoints **at or after** any tx with `postedOn` ≤ checkpoint boundary (or bump a **version** and recompute from last good checkpoint).

3. **Dirty flag + asynchronous materialization (good UX under load)**  
   On transaction write: **do not** update daily NW docs; only set `netWorthSeriesDirty: true` (or increment `ledgerVersion`). A **scheduled** job or **task queue** rebuilds the last **90** daily points in **one pass** when idle. Dashboard reads **cached** series; optional **stale-while-revalidate** or “Updating…” state.

4. **Separate “cashflow by day” (incremental) from “NW curve” (recomputed)**  
   Keep **incremental** diffs for **spend/income** (cheap). Treat **net worth history** as a **derived view** refreshed by (1)–(3), not as **per-tx incremental** patches across the whole tail.

5. **Nightly reconciliation**  
   **Out of scope for MVP** per [`data-contract.md`](data-contract.md); prefer **trigger-time** recompute of affected windows.

**What “clean and fast” usually means here:** **O(1) writes on the transaction write path** for cumulative curves (plus monthly/account diffs), and **bounded O(transactions in replay window)** work in a **single** recompute job or read request — not **O(days)** writes per event.

### 6.10 `monthlyTotals/{yyyy-mm}` — single doc per month with embedded JSON maps

A sensible pattern alongside a **flat** `transactions/{transactionId}` ledger:

`users/{userId}/monthlyTotals/{yyyy-mm}` — **one document per calendar month**, with aggregates stored as **maps / nested objects** in that document (not a subcollection per day).

**Why it helps**

- **Write amplification vs many day documents:** You go from **up to ~31 documents per month** (one per day) to **1 document per month**. Each transaction typically touches **one** month key → **O(1) monthly doc writes** for month-scoped aggregates (two if a rare operation spans months, e.g. moving a tx’s date across a boundary).
- **Cloud Function:** One invocation can **`set`/`update` with merge** on that single doc — apply **incremental diffs** to numeric fields and to nested paths like `byCategory.{id}` or `days.{dd}` (see below).

**Weekly views from “monthly” data**

- If the doc only stores **one rolled-up total for the entire month** (no finer grain), you **cannot** recover an arbitrary **calendar week** inside that month — **information is lost**.
- To support **Spending** week mode and cross-month weeks with at most **two** month reads, include **enough structure** inside the monthly JSON, for example:
  - **`days`**: map `dd → { income, expense, byCategory… }` (up to 31 keys — fine under Firestore’s **1 MiB** per document limit if payloads stay lean), **or**
  - **`isoWeeks`** (or similar): pre-aggregated buckets for weeks that intersect that month — often **redundant** if `days` exists, since week = sum of 7 days (watch **ISO week** spanning December/January: still **≤2** month docs).

So: **O(2) month documents** for a week straddling months is right; **derive weeks** by summing **day** (or week) slices **inside** those docs, not from a single month total alone.

**Caveats**

- **Document size:** Keep maps bounded (prune old detail if needed; **1 MiB** hard cap).
- **Hotspot:** Firestore recommends ~**1 sustained write/s per document** — unlikely to bind a **personal** ledger; batch imports might — use **throttling** or **async** rebuild.
- **Cumulative net worth:** Same semantics as §6.9. Embedding `days.{dd}.netWorthEod` lets you **batch** many day-level numbers into **one** document write, but the Function must still **compute** those values correctly after backdating — often **recompute the affected month’s NW series in one pass** inside the Function, then write the updated `days` map **once**.

**Verdict:** **Yes** — flat transactions + **`monthlyTotals` with `{yyyy-mm}` ids and embedded maps** is a **clean, scalable** shape for **non-cumulative** monthly/daily-within-month aggregates; align embedded fields with what the UI must **derive** (weeks, MTD, category splits).

---

## 7. Revision log

| Date | Change |
|------|--------|
| 2026-04-14 | Initial version: product understanding, aggregation framing, hybrid Firestore + Functions recommendation, service matrix, deferred Data Connect / BigQuery to optional phases. |
| 2026-04-14 | Section 6: hierarchical date paths, incremental vs full re-sum, stacked vs single-pass triggers, flat-vs-nested tradeoff, backdated transactions, scalability notes. |
| 2026-04-14 | Section 6.8: flat ledger + diffed summaries; which period docs to maintain vs derive; note on net-worth history and backdating. |
| 2026-04-14 | Section 6.9: downside of many day-bucket writes for cumulative metrics; incremental OK for non-cumulative; recompute/checkpoint/dirty-queue patterns for net worth at scale. |
| 2026-04-14 | Section 6.10: `monthlyTotals/{yyyy-mm}` with embedded JSON; weekly derivation needs day- or finer-grained fields; caveats (size, hotspot, NW). |
