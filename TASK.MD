Revalidation of current `main` (`d1f9515`, Issue #33 rev 2): **FAIL — leave open**.

The previous repeated-Item defect is fixed correctly: the transaction now keeps immutable `itemSnapshots` for rollback and a separate mutable `expectedItemStates` map for intra-transaction drift checks, updating the expected state after each successful Item reward.

One acceptance-critical transaction-cascade defect remains.

### Nested reward delivery can be rolled back by the outer transaction
The canonical gain APIs dispatch Achievement triggers synchronously:
- `Inventory.AddItem()` calls `Inventory.SetItems()`, which immediately invokes registered change listeners; the Achievement listener calls `ProcessTrigger("item_gain", ...)`.
- `Profile.AddCurrencyAmount()` immediately calls `Achievements:ProcessTrigger("currency_gain", ...)` when the applied gain is positive.
- If that gain completes another Achievement, `_CommitState()` immediately calls `DeliverRewards()` for that newly completed Achievement.

That means a reward transaction can execute another reward transaction *inside* its own `Inventory.AddItem()` / `Profile.AddCurrencyAmount()` call.

Concrete Item case:
1. Achievement A completes and starts reward transaction A.
2. A grants Item X x1.
3. `Inventory.AddItem()` writes X and synchronously emits `item_gain` before returning.
4. That completes Achievement B, whose `_CommitState()` immediately runs reward transaction B.
5. B also grants Item X x1 and finishes `complete`.
6. Control returns to A's original `Inventory.AddItem()` call.
7. A calculates `actualAdded` from its pre-call X state to the final post-call X state. It therefore sees **2**, not its configured **1**.
8. A treats this as `item-award-failed`; its `transaction.itemAwards` also records the full observed delta, so rollback can remove both A's and B's Item X.
9. B remains durably complete with `rewardState.status = complete`, but B's reward has been removed by A's rollback and will not be automatically replayed.

The same problem exists for Currency: an outer `Profile.AddCurrencyAmount()` can synchronously complete B, B can reward the same Currency, and the outer transaction then observes an inflated `actualAdded` and can restore the Currency to its own pre-transaction snapshot, undoing B's completed reward.

This violates multiple Task 11 requirements:
- rollback must restore **this transaction only**;
- newly completed Achievements must receive supported rewards exactly once;
- reward-generated Item/Currency gains are explicitly allowed to progress other Achievements;
- a completed nested reward must not be silently undone while remaining marked `complete`.

The fix needs to prevent nested reward *execution* from interleaving with an active reward transaction while preserving the intentional gain-trigger cascade. A suitable design is a transaction-depth / FIFO delivery queue: allow `item_gain` / `currency_gain` to update and complete other Achievements normally, but when `DeliverRewards()` is requested while another reward transaction is active, enqueue that completed Achievement's reward delivery and drain the queue only after the outer transaction reaches a final persisted state. Do not suppress the gain triggers themselves.

All earlier fixes remain valid: variant-aware rollback, repeated Item refs, currency caps, persisted `in-progress`, restart recovery blocking, safe retry restrictions, Grant integration, unsupported-type exclusion, and legacy completion behavior.

No CI/status checks or GitHub Actions workflow runs are configured for this revision.