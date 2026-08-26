## Goal
Remove the Inventory runtime’s repeated whole-list normalization/resolution work and make normal item mutations **incremental, revisioned, and transaction-aware**.

Authoritative documents:

- `.docs/RPE2-Runtime-Performance-Hitch-Elimination-PDD.md`
- `.docs/RPE2-Runtime-Performance-Hitch-Elimination-Implementation-Plan.md`

Depends on: #61

This task owns Inventory storage/runtime behavior only. Inventory window/page refresh behavior is handled by the next task.

## Primary files

- `client/character/inventory/Inventory.lua`
- runtime transaction/revision module added by #59
- `client/client_Achievements.lua` only for adapting Inventory change-listener integration where required
- `client/client_Crafting.lua` / `client/character/inventory/window_ItemModification.lua` only where their registered listeners require payload compatibility updates

Inspect every current `Inventory.RegisterChangeListener(...)` caller before changing listener semantics.

## 1. Make stored Inventory records canonical

`Inventory.GetItems()` must become a read operation.

Normalize/canonicalize Inventory records only at ownership boundaries such as:

```text
SavedVariable initialization/load normalization
SetItems bulk replacement
AddItem input
Remove/split/merge/bind/modification mutation functions
```

Requirements:

- do not normalize/rewrite the entire persistent list on every `GetItems()`;
- preserve dataset ID, item ID, quantity/count semantics, soulbound state and modifications;
- preserve legacy/corrupt-record safety currently provided by normalizers;
- use one load/migration normalization pass rather than repeated read-side repair.

Do not introduce a user-visible migration step.

## 2. Add `InventoryRevision`

Integrate Inventory mutations with the runtime revision system from #59.

Requirements:

- increment/publish once per logical Inventory transaction;
- append affected stack/index/item references to the ChangeSet where known;
- bulk replacement marks Inventory structural/full-refresh state;
- read-only calls do not change the revision;
- nested Achievement reward transactions participate in the existing outer transaction.

## 3. Add deterministic stack identity/indexing

Replace repeated full scans + recursive `deepEqual(modifications)` comparisons with an in-memory stack index keyed by a stable identity equivalent to:

```text
dataset:id | soulbound | modificationSignature
```

Requirements:

- modification signature is deterministic for equivalent normalized modifications;
- do not rely on Lua table iteration order when constructing it;
- build/rebuild the index once after load/bulk replacement;
- update incrementally on add/remove/split/merge/bind/modification operations;
- invalidate/rebuild safely if an external/bulk replacement makes the index stale;
- do not persist the index.

If two records are semantically non-stackable by existing rules, the new index must not merge them merely because the string key matches a subset of their state.

## 4. Rewrite normal `Inventory.AddItem()` incrementally

For a normal add:

```text
normalize incoming record once
resolve item definition once
calculate stack behavior/signature once
query matching stack candidates
mutate only affected stacks
append new stack(s) if required
mark Inventory change
return existing public result
```

Do not perform the current complete:

```text
GetItems -> whole normalization -> full scan/deepEqual -> SetItems -> whole normalization
```

round trip.

Preserve:

- stack-size limits;
- bind-on-pickup behavior;
- soulbound semantics;
- modifications;
- overflow behavior;
- public return values;
- existing item-gain Achievement semantics.

## 5. Add revision-cached display snapshot

Create one resolved Inventory display snapshot keyed by:

```text
InventoryRevision + ConfigurationRevision
```

The snapshot should resolve each stored record to its dataset/item definition once per key and expose presentation/filter fields currently recomputed by page code.

Include fields equivalent to:

```text
sourceIndex/stack identity
record
datasetId
itemId
dataset
item
isActive
isMissing
quantity
soulbound
modifications
quality
itemType
tags
normalized search text
```

Requirements:

- do not deep-copy immutable dataset definitions merely for the snapshot;
- build normalized search text once per snapshot entry;
- publish a completed immutable/current snapshot atomically; never expose a half-built one;
- invalidate on InventoryRevision or relevant ConfigurationRevision change;
- repeated reads for the same revision tuple return/reuse the cached snapshot.

The actual public API may remain `Inventory.GetDisplayItems()` if changing callers is unnecessary.

## 6. Coalesce Inventory listeners around transaction commit

Current listeners are invoked synchronously by mutation functions.

Refactor listener dispatch so one outer Runtime transaction produces one consolidated Inventory notification payload.

Requirements:

- Achievement item-gain handling still receives exact added quantities/references required for criteria;
- Crafting/item-modification consumers remain correct;
- listeners should not force unrelated UI refresh before the outer transaction commits;
- listener errors remain isolated;
- keep compatibility for direct Inventory calls outside an explicit outer transaction via an implicit transaction.

Do not silently drop existing listener behavior; adapt all current registered consumers deliberately.

## 7. Reduce hot-path allocation

Remove avoidable transient allocations associated with:

```text
repeated full normalization arrays
repeated modification deep copies
repeated search-string construction
repeated resolved display arrays for the same revision
```

Do not use manual `collectgarbage()` calls as a fix.

## Acceptance criteria

- [ ] `Inventory.GetItems()` no longer rewrites/normalizes the entire inventory on a normal read.
- [ ] Inventory load/bulk replacement canonicalizes records safely.
- [ ] Normal `AddItem()` does not perform a complete GetItems + SetItems round trip.
- [ ] Stack matching uses an incremental deterministic index/signature.
- [ ] Existing stack/bind/modification semantics remain unchanged.
- [ ] InventoryRevision changes once per logical Inventory transaction.
- [ ] Display resolution is cached by `InventoryRevision + ConfigurationRevision`.
- [ ] Search/filter presentation fields are precomputed once per snapshot entry.
- [ ] Repeated `GetDisplayItems()` calls for an unchanged revision reuse the snapshot.
- [ ] Inventory listeners receive one consolidated post-commit payload per outer transaction.
- [ ] Achievement item-gain processing still receives correct quantities.
- [ ] Existing Inventory SavedVariables load without user intervention.

## Validation matrix

Use inventories of roughly 10, 50 and 150+ stacks.

```text
call GetItems repeatedly without mutation
-> InventoryRevision unchanged
-> no whole-list normalization/rewrite

add to existing stack
-> only matching stack changes
-> one InventoryRevision commit

add stackable quantity beyond max stack
-> existing stack fills
-> overflow stack(s) created correctly

add non-stackable item
-> new record created; no unrelated stack mutation

same item with different modifications
-> variants do not merge

same item soulbound vs unbound
-> variants do not merge when current semantics forbid it

bulk SetItems
-> canonicalizes once
-> rebuilds stack index
-> invalidates display snapshot

GetDisplayItems twice unchanged
-> one snapshot build

Achievement reward grants several items
-> one outer transaction
-> one consolidated Inventory listener payload
-> exact quantities delivered
```

## Constraints

- Do not redesign Inventory UI in this task.
- Do not change item stacking/gameplay rules.
- Do not persist cache/index structures.
- Do not expose half-built snapshots.
- Do not remove listener consumers without adapting their required behavior.
- Do not deep-copy immutable dataset definitions on hot reads.
- Do not manually force garbage collection.

## Coding-agent instructions
Use current `FrontierDev/rpe2` as authoritative. This task is intended for **5.6-Luna-ExtraHigh**. Read both runtime-performance documents and completed #61. Trace every Inventory mutation function and every registered change listener before editing. Preserve public API/stacking semantics while changing internal ownership and notification timing. Report canonicalization boundaries, stack-key/signature design, revision/snapshot keys, listener payload changes, files changed, and timing results for 10/50/150+ stack cases.