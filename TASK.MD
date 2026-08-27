## Goal
Make deferred work **genuinely frame-bounded** by adding cooperative sliceable jobs to `TaskQueue` and converting existing deferred loops whose runtime can scale with content size.

Authoritative documents:

- `.docs/RPE2-Runtime-Performance-Hitch-Elimination-PDD.md`
- `.docs/RPE2-Runtime-Performance-Hitch-Elimination-Implementation-Plan.md`

Depends on: #64

The current TaskQueue only checks its time budget between jobs. A single slow queued function can still monopolize a frame. This task fixes the scheduler contract; event/spell-specific state machines are completed in later issues.

## Primary files

- `core/internal/tasks/TaskQueue.lua`
- `core/debug/Timings.lua`
- `Commands.lua` only for extending #58 queue diagnostics where required
- `client/client_Event.lua`
- `client/client_Traits.lua`
- `client/spellcasting/AuraManager.lua`
- Inventory/Profile files only if #58 proves an existing queued first-build/snapshot operation is unbounded and can be converted without broadening scope

Inspect every existing `Tasks:Enqueue(...)` call in hot runtime paths before converting anything.

## 1. Preserve existing bounded-job API

Keep the existing normal API for known-small work:

```lua
Tasks:Enqueue(fn, ...)
```

Existing callers must continue to work unless deliberately converted.

Do not force every tiny task through a continuation object.

## 2. Add sliceable/continuation jobs

Add a cooperative API equivalent to:

```lua
Tasks:EnqueueSliceable({
    label = "...",
    state = state,
    step = function(jobState, deadlineMs)
        -- bounded work
        -- return true when complete
    end,
})
```

Alternative iterator/continuation syntax is acceptable if it provides the same guarantees.

Requirements:

- each slice receives/can query the current deadline or elapsed budget;
- incomplete jobs retain their state and resume later;
- completed jobs are removed cleanly;
- job labels are available in timing/error diagnostics;
- errors identify the sliceable job and do not corrupt the queue;
- cancellation/stale-check hooks exist for event-scoped jobs that become obsolete;
- normal and sliceable jobs share predictable queue ordering/priority semantics.

Do not rely on Lua coroutine yielding unless repository/runtime constraints make it clearly safer than explicit continuation state.

## 3. Enforce per-slice timing discipline

Target approximately 2 ms of RPE work per slice.

Requirements:

- scheduler checks time within/around repeated slice steps, not only after a complete large job;
- a well-behaved slice can stop before the deadline and resume next frame;
- record slow slices through #58 timing diagnostics;
- expose current normal/sliceable pending counts and last/max slice elapsed time.

The scheduler cannot magically preempt arbitrary Lua functions; converted job `step` functions must cooperate by checking the deadline/processed count.

## 4. Add cancellation/staleness support

Event/configuration transitions can invalidate queued work.

Provide a narrow mechanism equivalent to:

```text
cancel by token/job id
cancel by event scope
job checks expected event id/revision before mutating state
```

Requirements:

- obsolete presentation/derived work can be dropped safely;
- authoritative work is not silently discarded after partially mutating state;
- cancellation state is visible in diagnostics where useful.

## 5. Convert currently deferred unbounded loops

At minimum inspect and convert large deferred work in current event startup/trait/aura paths where #58 timing/cardinality shows content-scaled loops, including current equivalents of:

```text
trait runtime refresh/compilation
automatic trait aura synchronization
event aura synchronization
resolved trait-state refresh
large aura advancement/tick queues if one queued job processes many entries
```

Do not yet redesign turn due-work indexes or spell-component state machines; later issues own those.

For each converted job:

- retain explicit continuation indexes/state;
- preserve operation order;
- verify stale event/config revisions before applying resumed work;
- clear large continuation tables on completion/cancel.

## 6. Keep queue semantics deterministic

Slicing may change which frame presentation finishes on, but must not reorder dependent authoritative operations incorrectly.

Where a sequence requires strict completion before the next phase, chain phases explicitly rather than enqueueing unrelated independent jobs and relying on incidental queue order.

## Acceptance criteria

- [ ] Existing `Tasks:Enqueue` callers remain supported.
- [ ] TaskQueue exposes a sliceable/continuation API.
- [ ] Sliceable work retains state and resumes across frames.
- [ ] Scheduler diagnostics distinguish normal and sliceable jobs.
- [ ] Slow slices are timed against the ~2 ms target.
- [ ] Event-scoped/stale work can be cancelled or rejected safely.
- [ ] At least the existing large event-start trait/aura deferred loops are converted where profiling shows they are unbounded.
- [ ] No converted slice processes its full potentially-large collection unconditionally in one call.
- [ ] Converted jobs preserve logical order/results.
- [ ] A queued 50+ ms content-scaled operation no longer executes as one indivisible frame solely because it was deferred.

## Validation matrix

```text
normal tiny Enqueue job
-> behavior unchanged

sliceable job with 10,000 synthetic iterations
-> completes over multiple slices/frames
-> each slice respects target budget approximately
-> result equals unsliced reference

sliceable job errors on later slice
-> error identifies job label
-> queue remains usable

cancel queued event-scoped job before first slice
-> no mutation occurs

cancel/stale event-scoped derived job after event id changes
-> resumed job does not apply stale output

event startup with many trait/aura entries
-> work is visibly split into bounded slices
-> no individual converted job exceeds hard frame threshold
-> final runtime state matches expected result
```

## Constraints

- Do not increase the global TaskQueue budget as the primary fix.
- Do not claim arbitrary functions are preemptible; callers must cooperate.
- Do not redesign spell component execution here.
- Do not redesign cooldown/aura due indexes here.
- Do not drop partially authoritative work through unsafe cancellation.
- Do not change gameplay ordering to improve throughput.

## Coding-agent instructions
Use current `FrontierDev/rpe2` as authoritative. This task is intended for **5.6-Luna-ExtraHigh**. Read both runtime-performance documents and completed #64. Inspect the current `TaskQueue:Flush()` implementation and hot `Tasks:Enqueue` call sites before designing the continuation API. Keep compatibility for bounded jobs, convert only proven unbounded deferred loops, and make cancellation/stale checks explicit. Report the new scheduler API, slice budget behavior, converted call sites, cancellation semantics, diagnostics, files changed, and timing validation.