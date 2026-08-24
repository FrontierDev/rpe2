# Fix Issue #33 rev 1 — multiple rewards for the same Item reference

The current `client/client_AchievementRewards.lua` implementation still has one transaction-state bug.

## Problem

Multiple Item rewards that reference the same `datasetId:itemId` fail incorrectly.

Example:

```lua
rewards = {
    {
        id = "reward_1",
        type = "item",
        ref = "dataset:item",
        amount = 1,
    },
    {
        id = "reward_2",
        type = "item",
        ref = "dataset:item",
        amount = 1,
    },
}
```

The current implementation captures the correct immutable pre-transaction snapshot.

However, before every Item reward it compares the current inventory against that original snapshot:

```lua
compareInventoryVariants(itemSnapshot.variants, beforeVariants)
```

After `reward_1` succeeds, the inventory has legitimately changed.

Therefore `reward_2` sees a mismatch against the original pre-transaction state, reports:

```text
item-snapshot-drift
```

and rolls the transaction back.

This makes valid multiple-reward definitions fail.

## Required fix

Maintain **two distinct Item-state concepts** during a reward transaction.

### 1. Original snapshots

Keep the existing pre-transaction Item snapshots immutable.

These must represent the exact inventory state before any reward mutation occurred.

They are used only for:

- rollback;
- final rollback verification;
- deciding whether `failed` is safe versus `recovery-required`.

Do **not** update these snapshots after successful rewards.

Conceptually:

```lua
transaction.itemSnapshots
```

remains the immutable rollback baseline.

### 2. Expected current Item state

Add transaction-local expected Item state.

Conceptually:

```lua
transaction.expectedItemStates
```

This should initially be a deep copy of the corresponding original Item snapshot state.

For example:

```lua
transaction = {
    itemAwards = {},
    itemSnapshots = ...,        -- immutable original state
    expectedItemStates = {},    -- mutable expected live state
    currencySnapshots = ...,
}
```

Use a stable key such as the canonical Item ref or another unambiguous `datasetId:itemId` key.

## Before each Item mutation

Currently the code effectively does:

```lua
local itemSnapshot = findItemSnapshot(
    transaction.itemSnapshots,
    reward.datasetId,
    reward.itemId
)

local beforeVariants = getInventoryItemVariants(
    inventory,
    reward.datasetId,
    reward.itemId
)

if not itemSnapshot
    or beforeVariants == nil
    or not compareInventoryVariants(itemSnapshot.variants, beforeVariants)
then
    return finishFailedTransaction(
        achievementRef,
        state,
        transaction,
        reward.id,
        "item-snapshot-drift"
    )
end
```

Change this so drift detection compares the live state against the **expected current transaction state**, not the immutable original snapshot.

Conceptually:

```lua
local expectedVariants = transaction.expectedItemStates[reward.ref]

local beforeVariants = getInventoryItemVariants(
    inventory,
    reward.datasetId,
    reward.itemId
)

if expectedVariants == nil
    or beforeVariants == nil
    or not compareInventoryVariants(expectedVariants, beforeVariants)
then
    return finishFailedTransaction(
        achievementRef,
        state,
        transaction,
        reward.id,
        "item-snapshot-drift"
    )
end
```

The exact storage structure may follow existing code conventions.

## After a successful Item mutation

After:

```lua
Client.Inventory.AddItem(...)
```

has succeeded and the post-add state has been verified, update the expected transaction-local state to the actual verified post-add state.

Conceptually:

```lua
transaction.expectedItemStates[reward.ref] = deepCopy(afterVariants)
```

This allows a subsequent reward for the same Item reference to see the state produced by the previous reward as the expected state.

Example:

```text
Original:
foo:bar = 3

reward_1 +1:
expected state becomes 4

reward_2 checks against 4
reward_2 +1:
expected state becomes 5
```

This must not modify the original rollback snapshot of `3`.

## Rollback behaviour

Keep the existing variant-aware rollback introduced in `Issue #33 rev 1`.

Rollback must still:

1. remove Item quantities awarded by this transaction, in reverse order;
2. distinguish Item variants using:
   - dataset;
   - item ID;
   - modifications;
   - soulbound state;
3. restore affected Currency snapshots through canonical APIs;
4. compare the resulting Item inventory against the **immutable original `itemSnapshots`**;
5. compare Currency balances against their original snapshots.

Use:

```text
failed
```

only when the exact pre-transaction state has been verified as restored.

Use:

```text
recovery-required
```

if that cannot be proven.

Do not use `expectedItemStates` for final rollback verification.

## Important constraints

Do not:

- remove the Item drift check;
- weaken rollback verification;
- overwrite the original Item snapshots after successful rewards;
- introduce another Inventory store;
- introduce another reward transaction persistence root;
- change Achievement completion semantics;
- re-complete or re-announce Achievements during retry;
- change the corrected currency-cap behaviour from `Issue #33 rev 1`.

The fix should be limited to the transaction-local Item state tracking needed for repeated Item reward references.

## Required validation

### Same Item twice

```lua
item A x1
item A x1
```

Expected:

```text
both apply
transaction -> complete
total Item gain = 2
```

### Same Item with different amounts

```lua
item A x2
item A x3
```

Expected:

```text
both apply
transaction -> complete
total Item gain = 5
```

### Interleaved duplicate Item

```lua
item A x1
currency X x10
item A x2
```

Expected:

```text
all rewards apply
transaction -> complete
```

### Multiple different Items

```lua
item A x1
item B x1
```

Expected:

```text
existing behaviour remains correct
```

### Failure after repeated Item rewards

```lua
item A x1
item A x2
later reward fails
```

Expected:

```text
all 3 transaction-awarded copies of Item A are rolled back
the exact original Item variants/quantities are restored
transaction -> failed only if restoration is verified
otherwise -> recovery-required
```

### External inventory drift

If Item A changes externally between reward mutations in a way not caused by the current reward transaction:

```text
expected current state != actual current state
```

Expected:

```text
item-snapshot-drift
rollback attempted
failed only after exact original state is verified
otherwise recovery-required
```

## Definition of done

- Multiple supported Item reward records may reference the same Item.
- Earlier rewards in the same transaction do not trigger false `item-snapshot-drift`.
- Genuine external drift is still detected.
- Original pre-transaction snapshots remain immutable.
- Rollback remains variant-aware and verifies the exact original state.
- Existing currency-cap handling remains unchanged.
- All Issue #33 acceptance criteria remain satisfied.
