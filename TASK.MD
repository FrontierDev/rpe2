## Rev 1 static validation: FAIL — derived-state continuation still hides unbounded work inside one slice

Validated commit `af84774b9748633926e044f8336225a85593e235` (`Issue #65 rev 1`) against #65, the runtime-performance plan, and the previous static failure. `TASK.MD` is intentionally ignored.

### What rev 1 fixes correctly

The previous outbound-aura blocker is fixed:

- outbound aura flushing now uses `EnqueueSliceable` rather than a normal `Tasks:Enqueue` callback;
- pending order is scanned incrementally;
- transmitted batches are capped (`OUTBOUND_AURA_BATCH_ENTRY_LIMIT = 16`);
- operations are removed from the authoritative pending map only after a successful send;
- cancellation leaves unsent operations pending rather than silently discarding them;
- per-scope ordering/count state is maintained and compacted cooperatively.

The full local derived-state path is also substantially improved:

- event startup now creates/resumes `CreateLocalPlayerDerivedStateContinuation` rather than directly calling the old monolithic full refresh;
- `Profile` and `Resolver` now expose continuation paths;
- stat/resource output is built into continuation-owned temporary tables and assigned to `localUnit.stats/resources` only on completion;
- resolver collection/build/sort phases check the TaskQueue deadline between continuation iterations;
- event startup releases the continuation on stale/cancel and suppresses the duplicate synchronous derived-state refresh after the continuation commits.

No configured commit-status checks are present.

### Remaining blocker: one resolver iteration can still traverse an unbounded derived-stat graph

`Resolver.StepResolvedStateContinuation()` is cooperative only at the **top-level stat-row** boundary. In its `build-stats` phase it performs:

```lua
local row = buildResolvedStatRow(entry, context)
...
-- deadline is checked only after this call returns
```

But `buildResolvedStatRow()` uses the existing recursive `resolveStatComponents(...)`. For every `derivedSource`, that function recursively calls itself:

```lua
local sourceComponents = resolveStatComponents(
    sourceEntry,
    byRef,
    cache,
    activeRefs,
    profileBonuses,
    equipmentBonuses,
    auraContext,
    progressionContext
)
```

The shared cache prevents duplicate work, but it does **not** bound one call. A single top-level stat can traverse an arbitrarily wide/deep connected derived-stat dependency graph before returning to `StepResolvedStateContinuation()`. During that traversal there is no `deadlineMs`/`ShouldYield()` check.

Therefore the new continuation can still execute a content-scaled resolver operation as one indivisible slice. This violates #65's core acceptance criterion:

> No converted slice processes its full potentially-large collection unconditionally in one call.

and the explicit requirement that a queued 50+ ms content-scaled operation no longer remain indivisible merely because its caller is sliceable.

### Additional unbounded work before the first resolver yield

`Resolver.CreateResolvedStateContinuation()` also synchronously calls `buildItemStatBonusMap()` before the first `Step...` call. That function iterates equipped slots and resolves each item through `Equipment.ResolveItemDefinition()`. `ResolveItemDefinition()` performs a linear scan of `dataset.items` for each equipped item.

This is another content-scaled collection traversal occurring during continuation creation, before the continuation has a chance to honor the slice deadline. With current small datasets it may be cheap, but #65's scheduler contract must not depend on dataset size staying small.

### Required fix

#### A. Make derived-stat dependency resolution itself continuation-aware

Do not call the recursive `resolveStatComponents()` as an indivisible operation from the continuation.

Implement an explicit dependency-resolution stack/state machine (or equivalent) so that:

1. one continuation retains the current stat/dependency stack across slices;
2. derived-source traversal advances incrementally and checks `deadlineMs` between dependency operations;
3. cycle protection and the existing resolved-component cache semantics are preserved;
4. each completed stat produces exactly the same components/value as the current recursive resolver;
5. partially resolved stats are not published to the final row cache until their dependency evaluation is complete;
6. stale cancellation discards the temporary dependency stack/cache without exposing partial resolved state.

It is acceptable to retain the existing recursive helper for ordinary bounded/non-sliceable callers; the continuation path needs its own cooperative equivalent.

#### B. Remove content-scaled synchronous preparation from continuation creation

Move `buildItemStatBonusMap()` (and any similarly collection-scaled preparation needed by this continuation) into explicit continuation phases, or replace the repeated linear item-definition lookup with an already valid revision-keyed O(1) definition index/cache.

At minimum, continuation creation itself must remain small and must not perform `equipped slots × dataset.items` scanning before the first deadline-aware step.

### Re-validation after fix

Static review must show that no full derived-stat dependency traversal or dataset-sized item scan remains hidden inside one derived-state slice. Then run the existing #65 in-game gate:

- high-content event startup with timings enabled;
- trait/aura/derived-state work visibly spans bounded slices;
- `TaskQueue.Slice` timings stay near the ~2 ms target and no converted slice produces a visible frame freeze;
- final stats/resources/traits/auras match existing behavior;
- stale/cancelled startup does not publish partial state;
- large outbound aura queues flush incrementally without losing/reordering operations;
- ordinary small `Tasks:Enqueue` behavior remains unchanged.

#65 remains open pending this fix.