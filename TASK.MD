## Goal
Refactor **event turn/tick advancement orchestration** so `HandleEventState()` performs only bounded immediate packet/state work, then processes gameplay consequences through an explicit ordered event-step transition rather than synchronously running the entire runtime graph in the packet handler.

Authoritative documents:

- `.docs/RPE2-Runtime-Performance-Hitch-Elimination-PDD.md`
- `.docs/RPE2-Runtime-Performance-Hitch-Elimination-Implementation-Plan.md`

Depends on: #66

This task owns event-step orchestration and ordering. Sparse cast/cooldown/aura due indexes are implemented in the next task; spell-component slicing follows after that.

## Primary files

- `client/client_Event.lua`
- `client/spellcasting/Core.lua`
- `client/spellcasting/Cooldowns.lua`
- `client/spellcasting/AuraManager.lua`
- `client/client_Resources.lua`
- `client/spellcasting/Helpers.lua`
- runtime transaction module from #59
- TaskQueue continuation API from #65

Before editing, document the **actual current semantic order** inside `HandleEventState()` and the advance functions it calls. Preserve that order unless repository behavior proves a different authoritative dependency.

## 1. Bound the immediate `HandleEventState()` path

The packet/state handler should do only work equivalent to:

```text
validate packet/event identity
apply received turn/tick/state identifiers
record previous/current step
clear/update immediate turn-pending flags
identify whether the event step changed
create/start an event-step transition/transaction
queue/resume ordered consequence processing
return
```

It must not synchronously run all content-scaled cast/cooldown/aura/component consequences to completion before returning.

Keep malformed/stale packet rejection immediate.

## 2. Add explicit `advancing` transition state

Extend the event transition model from #66 to support:

```text
kind = "advancing"
```

with stable state equivalent to:

```text
eventId
previous turn/tick
new turn/tick
phase
transaction/context id
generation
continuation state
```

While the authoritative step is incomplete:

- conflicting RPE actions are gated using the same central readiness mechanism as #66;
- harmless UI remains responsive;
- duplicate/retransmitted state for the same completed step is ignored/handled according to existing semantics;
- a replacement/end event invalidates stale advancing work safely.

## 3. Express consequence processing as explicit ordered phases

Use the **current observed gameplay order** as authoritative. Represent it explicitly rather than relying on one function calling several large functions inline.

Expected phases will include current equivalents of:

```text
advance casts due for the step
complete casts due now
advance aura/tick/expiry consequences
advance cooldown/charge state
apply turn-start/local resource regeneration
movement/turn ownership updates
turn announcements/cues
mark tooltip/action-bar/event visual dirty scopes
network/resource flushes required by authoritative state
commit Runtime ChangeSet
flush/queue presentation
release advancing transition
```

The exact order must match current semantics where it differs from this illustrative list.

## 4. Preserve spell completion sequencing

Current cast advancement can invoke `OnSpellcastComplete()` during step handling.

For now:

- keep cast completion in its correct phase;
- allow the phase to use the existing completion implementation until the later spell task replaces it;
- do not execute visual refreshes between cast completion sub-effects if existing dirty-state infrastructure can defer them;
- do not let another conflicting action begin until the advancing transaction reaches a stable authoritative point.

If current spell completion is still a large indivisible function, instrumentation may still report it as slow after this task; that is expected and is fixed by the later spell issue. The orchestration must nonetheless no longer hide it inside the packet handler call stack.

## 5. Coalesce presentation invalidation

Audit current event-step code that bumps tooltip contexts, invalidates targeting, refreshes Action Bar/event portraits, and announces turn state.

Requirements:

- authoritative state changes mark dirty scopes during the transition;
- broad tooltip-context invalidation should be narrowed to affected units/scopes where existing context data identifies them;
- multiple mutations in the same step produce one queued presentation flush per surface;
- do not refresh visible UI after every phase.

Reuse `DirtyUiRefreshState` and targeted helpers in `client/spellcasting/Helpers.lua` rather than creating a second presentation queue.

## 6. Keep network synchronization ordered but outside presentation work

Required resource/event synchronization must preserve protocol ordering.

Do not interleave expensive UI refresh between related packet sends. Stage/coalesce outbound deltas after authoritative state for the relevant phase/transaction is ready where existing protocol permits.

Do not change network authority or packet meaning in this task.

## 7. Add event-step diagnostics

Report at least:

```text
immediate HandleEventState time
phase times/slice times
step total wall-clock transition duration
number of casts/cooldowns/auras inspected/processed
number of dirty UI scopes
max single phase/slice time
```

The next task should be able to use these cardinalities to prove broad scans were removed.

## Acceptance criteria

- [ ] `HandleEventState()` no longer synchronously owns the entire step consequence graph.
- [ ] Event-step work runs through explicit `advancing` transition state.
- [ ] Current authoritative consequence order is documented and preserved.
- [ ] Conflicting RPE actions are gated until the step reaches a valid authoritative completion point.
- [ ] Replacement/end event safely invalidates stale advancing work.
- [ ] Presentation refreshes are dirty/coalesced rather than executed after every phase.
- [ ] Turn tooltip/action-bar/event invalidation is narrowed where existing affected-state information permits it.
- [ ] Network authority/order remains unchanged.
- [ ] Immediate packet handler time is bounded independently of total multi-frame step work.

## Validation matrix

```text
receive event state with no turn/tick change
-> no advancing transition created
-> no unnecessary runtime advance

receive next turn with no active casts/auras/cooldowns
-> bounded transition completes quickly
-> turn cues/resources/movement remain correct

turn completes one cast
-> cast completion occurs in the same semantic position as before
-> conflicting action blocked until authoritative completion

turn with several aura/cooldown changes
-> ordered phases execute
-> one coalesced presentation flush

receive replacement/end event during advancing work
-> stale transition cannot mutate replacement event

retransmit/duplicate same step according to current protocol behavior
-> no duplicate resource/cast/aura consequences

profiling
-> HandleEventState immediate time excludes later phase wall-clock work
-> phase/cardinality diagnostics are visible
```

## Constraints

- Do not redesign sparse cast/cooldown/aura indexes here; next task owns that.
- Do not fully rewrite spell components here.
- Do not change gameplay effect ordering.
- Do not acknowledge/accept conflicting actions against partially-applied authoritative state.
- Do not create a parallel UI dirty system.
- Do not change protocol meaning merely for batching convenience.

## Coding-agent instructions
Use current `FrontierDev/rpe2` as authoritative. This task is intended for **5.6-Luna-ExtraHigh**. Read both runtime-performance documents and completed #66. Before editing, trace and write down the current `HandleEventState -> AdvanceSpellcastState -> AdvanceCooldownState -> AdvanceAuraState -> resource/movement/UI` ordering from the actual tree. Preserve semantics while moving consequence ownership into an explicit bounded transition. Report the discovered semantic order, transition phases, action gating, presentation coalescing, files changed, and per-phase timing/cardinality results.

## Mandatory scope addendum — avoid narrow event-step implementations

This comment is **normative implementation scope**. Use **5.6-Terra-ExtraHigh**; the older Luna note in the issue body is superseded.

### Repository-wide entry-point audit

Do not treat `HandleEventState()` as the only event-step entry point. Before editing, search for every path that can cause or request an authoritative step change, including:

- `Server:AdvanceEventStep()` direct callers;
- Event widget controls;
- Event Manager/server UI controls;
- local host loopback paths;
- packet-driven `EVENT_STATE` handling;
- slash/debug/programmatic callers;
- any companion/reaction/targeting/spell path that can mutate the same authoritative step state.

All conflicting paths must use the same central transition/readiness contract. UI disablement must be backed by a call-time guard immediately before authoritative mutation.

### Transitive boundedness, not outer-wrapper boundedness

For each `advancing` phase, trace every synchronous helper called before the next TaskQueue deadline check. Cold cache/index creation, recursive helpers, list sorting, resource regeneration, movement updates, tooltip invalidation, network payload building, announcements, commit/finalization, and presentation flushes are in scope if reached from the hot step path.

A phase is not considered bounded merely because it is invoked from a sliceable job. Any content-scaled transitive traversal must itself yield, use a maintained sparse/cache structure, or be proven hard-bounded.

Known intentionally deferred spell-component work owned by #69 may remain indivisible **only if** it is isolated/documented exactly as #67 describes; do not accidentally add new unbounded work outside that explicit deferment.

### Cross-frame Runtime transaction ownership

Before keeping an event-step Runtime transaction open across frames, inspect the #59 implementation and prove the shared/current transaction model supports suspension safely. A global current transaction must not remain active across yields if unrelated runtime work can accidentally join it.

If necessary, change the transition design so continuation state spans frames while Runtime transaction ownership is entered/committed only at safe authoritative boundaries. Do not silently rely on cross-frame transaction behavior that Runtime does not explicitly support.

### Transition composition and stale semantics

`advancing` must compose correctly with the `starting`/`ending` transition model from #66. Define and enforce what happens when:

- an end/replacement arrives mid-advance;
- a duplicate/retransmitted step arrives while the same transition is pending;
- a later step arrives before earlier local consequences have settled;
- stale callbacks/jobs return after a generation change.

Continuation APIs that distinguish complete/incomplete/stale/error must preserve the tri-state through every wrapper. Terminal stale work must be discarded, not retried as ordinary incomplete work.

### Lua/static preflight

Before handoff, audit all changed Lua for:

- local declaration-order/forward-declaration mistakes;
- multi-return helpers passed directly into functions with optional trailing args;
- `pcall`/multi-return mishandling;
- boolean coercion that loses stale/error reasons;
- closures retaining stale event/transition state.

### Required implementation handoff

Report before requesting external validation:

1. every event-step entry point found and its gating rule;
2. the exact pre-refactor semantic order and the new explicit phase order;
3. each phase’s transitive content-scaled callees and where yielding can occur;
4. Runtime transaction lifetime across slices and why it is safe;
5. duplicate/out-of-order/stale packet behavior;
6. cold-path and warm-path timings/cardinalities;
7. any deliberately deferred >16 ms risk and the exact owning follow-up issue.

Do not request user in-game validation until this self-audit is complete.