## Rev 4 static validation: FAIL — cold aura stat aggregation can still monopolize one slice

Validated commit `c35396bf98a142e0ed70a81d8d524181e5862a80` (`Issue #65 rev 4`) against #65, the runtime-performance plan, and the previous rev-3 failure. `TASK.MD` is intentionally ignored.

### What rev 4 fixes correctly

The prior Lua scoping blocker is fixed correctly. `Resolver.lua` now forward-declares `shouldYieldResolvedStateContinuation` before `stepResolvedStatComponents(...)` and assigns the function later, so the continuation no longer resolves a nil global at the yield check.

The other #65 architecture remains in place:

- explicit TaskQueue sliceable jobs with ~2 ms deadlines, diagnostics, cancellation/stale hooks and normal `Enqueue` compatibility;
- event startup uses explicit trait-runtime, automatic-aura, event-aura and resolved-state continuations with no monolithic fallback;
- derived-stat dependency traversal uses an explicit continuation stack with a deadline check between dependency operations;
- item/equipment preparation is incremental rather than `equipped slots × dataset.items` synchronous scanning;
- outbound aura flushing remains incremental/batched.

No configured commit-status checks are present.

### Blocking defect: one resolved-stat completion still performs an unbounded cold aura scan

The converted resolved-state path is not yet fully frame-bounded.

`completeResolvedStatFrame(...)` still obtains aura modifiers via `resolveAuraBonusesForStat(...)`, which synchronously calls:

```lua
AuraManager:BuildStatModifierTotals(eventState, unitEventId, statRef)
```

On a cache hit that is fine. On a cache miss, however, `BuildStatModifierTotals(...)` performs content-scaled work before returning:

1. `getBucketAuraEntriesForTarget(...)` materializes the full aura list for the target;
2. it loops over every target aura;
3. for each aura it obtains/builds the aura runtime;
4. it loops that aura's effect keys and calls the effect accumulator.

So a single call to `completeResolvedStatFrame(...)` can still execute `target auras × aura effects` synchronously. The next `shouldYieldResolvedStateContinuation(deadlineMs)` check happens only **after** that whole call returns.

This is particularly relevant during event startup because the aura synchronization immediately preceding resolved-state refresh changes the aura bucket revision, making the per-stat modifier cache cold. With many auras/effects, one nominal continuation operation can therefore still become a long indivisible frame.

That violates #65's explicit acceptance criterion:

> No converted slice processes its full potentially-large collection unconditionally in one call.

and the requirement that the converted `resolved trait-state refresh` path be genuinely frame-bounded.

## Required fix

Make local-player aura stat-modifier aggregation cooperative for the derived-state continuation. A good design is to build the aura modifier map once, incrementally, before stat rows are finalized:

1. Add continuation-owned state for the local unit's aura modifier aggregation, keyed by the current event id / aura bucket revision / configuration revision.
2. Iterate the target aura key list directly with retained `auraIndex` / `effectIndex` state and check the supplied deadline between aura/effect operations. Do not materialize and scan the entire target-aura collection inside one helper call.
3. Accumulate all affected stat refs into a temporary map such as `statRef -> { flat, percent }`, preserving the existing `contract:Accumulate(...)` semantics and effect order.
4. `completeResolvedStatFrame(...)` should then read the prepared map in O(1) rather than call cold `BuildStatModifierTotals(...)` per stat.
5. Preserve the existing AuraManager cache semantics where useful, but only publish/populate shared cache entries once the continuation is complete and still current. Stale/cancelled work must not expose a partial aggregate.
6. If cold `buildAuraRuntimeEntry(...)` itself can process an unbounded effect/event collection for one aura, either make that preparation cooperative as part of the same continuation or ensure the required runtime data is already prepared by the preceding sliced aura-sync phase. Do not hide another unbounded nested loop inside one aura step.
7. Preserve event/config/aura revision staleness checks and final stat/resource results exactly.

After this is fixed, static re-validation should confirm that the full cold event-start resolved-state path has no remaining potentially-large collection traversal hidden between deadline checks. Then proceed to the mandatory in-game high-content startup test with timings enabled.

#65 remains open.