## Static validation rev 1: FAIL — rolled-back item grants still publish `item_gain`

Re-validation of current `main` / `a2d0643f068f43649486e2d72d4cfd7c537824a3` confirms that rev 1 fixes the original successful-path ordering defect:

- canonical `Inventory.AddItem()` now emits a typed `item_gain` Runtime mutation event;
- Achievements registers a `RegisterBeforeCommitProcessor("item_gain", ...)` processor;
- the old post-commit Inventory listener is removed when that processor is available;
- successful direct and reward item grants can therefore drive `item_gain` Achievement progress inside the existing outer Runtime transaction.

However, the rollback case required by the previous diagnostic is still incorrect.

### Blocking diagnosis

`client/character/inventory/Inventory.lua::markInventoryMutation()` currently calls:

```lua
Runtime:MarkChanged("inventory", mutation)
Runtime:EmitMutationEvent("item_gain", mutation)
```

for every canonical add. The event is appended immediately to the current Runtime transaction's mutation queue.

`RuntimeTransaction.lua` drains every queued mutation during commit. There is currently no cancellation/netting mechanism for an already queued mutation event.

Achievement reward delivery can then legitimately roll an item grant back **before the outer Runtime transaction commits**:

```text
reward item AddItem()
 -> item_gain event queued
 -> later reward verification/persistence/currency step fails
 -> finishFailedTransaction()
 -> rollbackTransaction()
 -> Inventory.RemoveVariantQuantity() removes the awarded item
 -> reward function returns failure normally
 -> outer Runtime transaction still proceeds to commit
 -> queued item_gain event is drained
 -> Achievement progresses for an item the player no longer owns
```

This path is visible in `client/client_AchievementRewards.lua`: `finishFailedTransaction()` calls `rollbackTransaction()`, which removes prior item awards through `RemoveVariantQuantity()`. `Inventory.RemoveVariantQuantity()` records a removal mutation but does not cancel or offset the pending authoritative `item_gain` event.

Because reward failure is represented by normal return values rather than throwing the Runtime transaction, the queued event survives to the before-commit processor.

This violates:

- the previous rev-1 requirement: **failed/rolled-back reward delivery must not publish a spurious authoritative item-gain event for an item that did not remain granted**;
- #62's requirement to preserve existing item-gain Achievement semantics;
- the transaction model that authoritative dependent effects reflect the final state of the logical transaction.

### Required fix

Make authoritative Inventory gain events represent the **settled/net gain of the outer transaction**, not an irrevocable event at the instant `AddItem()` mutates storage.

An acceptable implementation is either:

1. **Cancellable/netted pending gain events**
   - retain transaction-local pending item-gain records keyed by exact stack variant/item identity;
   - when a removal/rollback in the same transaction removes quantity that came from a pending gain, decrement/cancel that pending gain before before-commit processing;
   - the Achievement processor must ignore gains whose settled quantity is `<= 0`.

or an equivalent design where:

2. **A final Inventory-settlement before-commit processor** computes authoritative item gains only after all Inventory mutations/rollbacks for the transaction have settled, and only then invokes `ProcessTrigger("item_gain", ...)`.

Do not solve this by moving Achievement processing back to post-commit; it must remain authoritative before-commit work and remain in the same outer transaction.

### Re-validation required

After the fix, verify statically:

- direct successful `Inventory.AddItem()` -> one before-commit `item_gain` with exact quantity;
- multiple successful reward item grants -> dependent `item_gain` Achievements remain in the same outer transaction;
- item grant followed by reward rollback -> **zero** `item_gain` progress for the rolled-back quantity;
- partial/net rollback -> only the settled retained quantity is exposed if that case is possible;
- one `InventoryRevision` publish per outer transaction;
- one consolidated post-commit Inventory listener payload;
- presentation listeners remain post-commit only.

No configured commit status checks are present for this revision. Issue remains open; do not run the in-game performance gate yet.