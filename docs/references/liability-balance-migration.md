# Liability balance sign migration (one-time)

After deploying **liability-aware** ledger aggregation, `accounts/{id}` rows for **`creditCard`**, **`loan`**, and **`mortgage`** use **positive `balanceMinor` = amount owed**. Data written under the previous convention (typically **negative** balance while debt was outstanding) must be **negated once** per Firebase project so balances match the new rules.

**When to run:** Immediately after deploying the updated Cloud Functions **and** client, for each environment (**dev** and **prod** separately). **Do not** run twice on the same project (it would flip signs back).

## Option A — npm script (recommended)

Prerequisites: [Application Default Credentials](https://cloud.google.com/docs/authentication/provide-credentials-adc) with Firestore access to the target project (`gcloud auth application-default login`).

```bash
cd functions
npm run build
# Dry-run (logs paths only):
DRY_RUN=1 GOOGLE_CLOUD_PROJECT=<your-project-id> npm run migrate:liability-balances
# Apply:
GOOGLE_CLOUD_PROJECT=<your-project-id> npm run migrate:liability-balances
```

Use the Firebase **project id** that matches your environment (`finkoappmx-dev` vs `finkoappmx`, etc.).

The script is [`functions/src/tools/migrateLiabilityBalances.ts`](../../functions/src/tools/migrateLiabilityBalances.ts) (compiled to `lib/tools/migrateLiabilityBalances.js`). It negates `balanceMinor` and `balanceMinorMain` on each liability account document.

## Option B — manual Firestore console

For each user’s liability account documents, set `balanceMinor` and `balanceMinorMain` to their arithmetic negation. Error-prone at scale; prefer Option A.

## See also

- [`docs/data-model.md`](../data-model.md) §4.2 / §5 — asset vs liability definitions.
- [`docs/ledger-aggregations-and-ui-flow.md`](../ledger-aggregations-and-ui-flow.md) §4 — `applyAccountDelta` liability factor.

### Revision log

| Date | Change |
|------|--------|
| 2026-04-18 | Documented npm migration path and `DRY_RUN`. |
