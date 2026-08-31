## Validation result: **FAIL — keep #141 open**

Validated against current `dev` at `6e4a16ac8e6e74816bae435dfa73d589ebf69ae5` (`Issue #141`), with parent `c66602bf8f3157048b0970b97476320860bc1852`.

The implementation is otherwise well-scoped: the commit changes only `RPEngine_Dev.toc`, adds `client/autopilot/AuraEvaluator.lua`, and modifies `PlannerIntegration.lua` / `SpellEvaluator.lua`. Canonical Aura definition resolution is reused, both `apply_aura` and damage/heal `applyAura` spell patterns are recognized, the Aura profile exposes the requested stacking/control/event metadata, active-cast summaries expose the useful cast timing/target state, and the existing direct damage/heal utility comparator is not changed.

However, there are two blocking validation defects.

---

### 1. The new Aura/cast planning snapshot is not actually frozen across planner slices

`Planner.CreateState()` currently stores direct references to the live mutable runtime buckets:

```lua
state.scratch.auraSourceBucket = getEventAuraBucket(eventState.id)
state.scratch.castSourceBucket = Client.ActiveSpellcastsByEventId[tostring(eventState.id or "")]
```

`phaseSnapshotAuras()` then traverses the live Aura table with a resumable cursor:

```lua
local auraKey = next(bucket.byKey, state.cursors.auraKeyScan)
```

and only later copies each live entry:

```lua
local entry = bucket.byKey[auraKey]
local copied = auraEvaluator.CopyAuraEntry(entry, ...)
```

`phaseSnapshotCasts()` does the same thing for the live cast bucket:

```lua
local casterEventId = next(bucket, state.cursors.castKeyScan)
...
local entry = bucket[casterEventId]
local summary = copyActiveCastSummary(entry, ...)
```

Both phases explicitly yield/resume through `Tasks:ShouldYield()`.

Those source tables are not immutable. `AuraManager` adds/removes/mutates `bucket.byKey` entries in place and bumps `bucket.revision`; spellcasting advances `turnsElapsed`/`lastAdvancedTurnNumber` and removes completed cast entries in place.

Therefore, if live Aura/cast state changes after the planner starts but before the corresponding entry has been copied:

- different records in one supposed frozen snapshot can represent different live moments;
- a changed Aura/cast can be silently copied with post-start state;
- an entry removed before its copy can silently disappear;
- a newly added entry can be partially included depending on traversal timing;
- importantly, resuming `next(liveTable, previousKey)` after `previousKey` has been removed can produce Lua's `invalid key to 'next'` failure.

The final `buildSnapshotResult()` deep copy does **not** fix this, because by then the inconsistent live traversal has already happened.

There is also no current validation guard mitigating this: `phaseRevalidate()` / `Planner.IsFrozenSnapshotStale()` do not validate the Aura/cast source generation before publication.

This directly fails #141's requirement that the planner expose a **frozen, immutable** Aura/cast planning context and that later live state changes not alter the snapshot being built.

#### Required fix

Do not traverse a live mutable Aura/cast table across yields without a mutation generation guard.

Use a narrow snapshot-generation design, preferably:

1. **Aura source:** capture the existing Aura bucket `revision` when Aura snapshotting begins.
2. Copy Aura records sliceably as today, but before every resume / before calling `next()` with a saved cursor, verify that the live bucket and revision still match the captured generation.
3. Verify the revision again after the last record is copied. If it changed, discard/reset the partial Aura snapshot and rebuild from one current generation (or fail this planner snapshot as stale through the existing lifecycle). Never publish a mixed-generation result.
4. **Cast source:** add/reuse an equivalent small per-event spellcast generation/revision which is bumped whenever the active-cast bucket is added to, removed from, or advanced. Use the same before/resume/after guard for `snapshot-casts`.
   - If current source offers an existing generic spellcast revision after re-inspection, reuse it instead of adding another one.
   - Do not attach any Autopilot plan/action metadata to persistent casts.
5. Ensure a source-generation mismatch is detected **before** resuming `next(table, previousKey)` so a removed traversal key cannot trigger an invalid-key error.
6. Keep definition/profile resolution sliceable and cached; do not solve this by synchronously deep-copying the entire AuraManager/cast runtime at `CreateState()`.

An equivalent stable-source representation is acceptable if current source supports it more cleanly, but the invariant must be:

```text
one planner Aura/cast snapshot
= one coherent source generation
```

not a traversal of live state over multiple frames.

---

### 2. Final frozen-control aggregation is an unyieldable second full Aura pass

After the per-Aura copy loop, `phaseSnapshotAuras()` currently performs:

```lua
for targetEventId, records in pairs(state.snapshot.activeAurasByTargetEventId) do
    state.snapshot.controlStateByTargetEventId[targetEventId] = controlBuilder(records)
end
```

`AuraEvaluator.BuildControlState(records)` then loops every Aura record for that target.

This work has no cursor / `Tasks:ShouldYield(deadlineMs)` boundary. Consequently, after already slice-copying the active Aura set, one planner slice can perform another O(active Auras) aggregation pass in a single uninterrupted call.

That conflicts with #141's explicit requirement that scans over active Aura state which can grow with event size remain bounded/cached or integrated into the resumable planner.

#### Required fix

Prefer eliminating the second pass entirely:

- incrementally merge each copied Aura record's control state into `state.snapshot.controlStateByTargetEventId[targetEventId]` as `appendFrozenAuraRecord()` runs; or
- add explicit target/record cursors and yield boundaries for the aggregation phase.

The incremental merge is narrower and naturally preserves the same canonical semantics: boolean controls OR together and `movementRangeOverride` takes the minimum value.

---

## Required deterministic regression coverage

Before closing #141, add/run deterministic mocks for at least:

1. Aura snapshot yields after one entry; that entry is then mutated before resume -> the final snapshot must not silently mix generations.
2. Aura snapshot yields; the last traversal key is removed before resume -> no `invalid key to 'next'` and no mixed snapshot.
3. Aura snapshot yields; a new Aura is added before resume -> result is either entirely the old generation or an explicitly rebuilt/new generation, never partial inclusion.
4. Cast snapshot yields; `turnsElapsed` changes before resume -> no mixed cast generation.
5. Cast snapshot yields; the previously visited cast is removed before resume -> safe deterministic handling.
6. Unchanged Aura/cast state across multiple forced yields -> snapshot output is deterministic and equivalent to a one-slice run.
7. Large active-Aura/control sets -> aggregation yields/remains bounded rather than performing one full second pass.
8. Existing direct damage/heal Autopilot choices remain unchanged.
9. Planner-side Aura profile/snapshot calls still mutate no canonical Aura/cast/resource/cooldown/combat state.
10. Manual spell/Aura behavior remains unchanged.

## Status

The new AuraEvaluator/profile/cache work itself is structurally suitable for the next issues, but #141 must remain open until the snapshot source is generation-stable and the remaining unyieldable Aura aggregation is removed/bounded.