## Static validation: FAIL — two hot content-scaled jobs remain indivisible

Validated commit `fa5d6f3f447b6e5290c1370afce74fce8bc92fbc` (`Issue #65`) against the #65 body and the runtime-performance plan. `TASK.MD` is intentionally ignored per user instruction.

A large part of the implementation is correct:

- existing `Tasks:Enqueue(fn, ...)` compatibility is preserved;
- `Tasks:EnqueueSliceable(...)` retains explicit state across frames and supplies a deadline;
- labels, timing diagnostics, per-slice stats, cancellation by id/scope, stale checks, and error containment are present;
- incomplete sliceable jobs are resumed on later flushes without blocking later queued work;
- event startup is now a scoped/stale-checked sliceable job;
- trait-runtime compilation, automatic-trait-aura synchronization, and event-aura synchronization now use continuations and check the deadline between continuation iterations.

No configured commit status checks are present.

### Blocking defect 1: event-startup resolved-state refresh is still one monolithic slice

`client/client_Event.lua` still performs this startup phase synchronously inside `runEventStartupStep(...)`:

```lua
if runtime.resolvedStateRefreshed ~= true and type(targetClient.RefreshTraitResolvedState) == "function" then
    targetClient:RefreshTraitResolvedState(eventState, "startup")
    runtime.resolvedStateRefreshed = true
    ...
end
```

That call reaches `AuraManager:RefreshLocalPlayerDerivedState(eventState, nil)`. With no narrow impact supplied it takes the full rebuild path:

```lua
rebuildLocalPlayerResolvedState(eventState, localUnit)
```

The full rebuild performs a complete `Profile.ListResolvedStats({ includeAuraBonuses = true })`, iterates all resolved stat rows, resolves the complete resource list, and iterates all resolved resources before returning. There is no continuation index or deadline check in this path.

This is exactly the kind of content-scaled operation #65 is intended to eliminate, and `resolved trait-state refresh` is explicitly named in the issue. Wrapping the caller in a sliceable TaskQueue job does not make this function preemptible: one call can still consume an arbitrarily long frame before the scheduler regains control.

### Blocking defect 2: outbound aura flush remains a normal queued full-collection scan

`client/spellcasting/AuraManager.lua` is unchanged by #65 and still queues `AuraManager:FlushOutboundAuraOperations(...)` through the normal `enqueueAuraWork` / `Tasks:Enqueue` path.

`FlushOutboundAuraOperations` then unconditionally scans the complete pending order in one job:

```lua
for index = 1, #pendingOrder do
    ...
end
```

The size of `PendingOutboundAuraOperationOrder` is not hard-bounded by the scheduler. A sufficiently large aura batch can therefore still become a 50+ ms indivisible queued operation, which violates the issue's core acceptance criterion and the instruction to inspect hot `Tasks:Enqueue(...)` call sites.

## Required fix

### A. Make full local derived-state rebuilding cooperative

Add a continuation/sliceable path for the **full** local-player derived-state rebuild used by event startup and full aura/trait invalidations.

Requirements:

1. Event startup must create/resume a derived-state continuation instead of calling `RefreshTraitResolvedState(..., "startup")` as one indivisible operation.
2. Process stat/resource preparation and row application with explicit continuation state and deadline checks.
3. Preserve atomic presentation/gameplay state: do not expose half-built `localUnit.stats` / `localUnit.resources`; build into continuation-owned temporary structures and commit only on completion.
4. Preserve existing ordering and resource-current/max semantics.
5. If `Profile.ListResolvedStats(...)` / `ListResolvedResources(...)` itself remains a cold monolithic resolver operation, merely slicing the subsequent copy loop is insufficient. Reuse a valid revision-keyed cache or add a cooperative resolver path so a cold full rebuild itself cannot monopolize a frame.
6. Narrow subset refreshes may remain normal only where their cardinality is explicitly bounded/proven small.
7. Event/config/equipment staleness must cancel/restart safely without committing partial derived state.

### B. Make outbound aura flushing bounded

Convert `FlushOutboundAuraOperations` (or the queued wrapper around it) to a sliceable continuation when the pending collection can be large.

Requirements:

1. Retain an explicit pending-order index/current batch state and stop at the deadline.
2. Preserve existing batching and operation order exactly.
3. Do not remove/drop operations in a way that loses unsent authoritative aura updates if the job is cancelled or becomes stale mid-run.
4. Scope/stale-check event work appropriately and clear continuation state on complete/cancel.
5. A large pending aura queue must no longer be scanned in full by one normal `Tasks:Enqueue` callback.

### Re-validation after fix

Static re-check should confirm there is no full derived-state rebuild or full pending-aura scan hidden inside a single slice. Then run the existing required in-game gate with timings enabled:

- high-content event startup -> trait/aura/derived-state work spans bounded slices with no visible freeze;
- `TaskQueue.Slice` timings stay near the ~2 ms target and no converted slice exceeds the hard frame threshold;
- final trait/aura/stat/resource state matches the unsliced behavior;
- cancellation/stale restart does not commit stale or partial state;
- normal tiny `Tasks:Enqueue` behavior remains unchanged.

#65 remains open pending these fixes.