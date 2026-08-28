# RPE2 Aura / Turn-Advance Regression — Implementation Plan

## Status

**Priority:** correctness regression / urgent

**Authoritative tree:** `main` at `5f33b816acae618abe0daee50dd366cc3fc6267f` (`Revert "Issue #67"`).

**Implementation issue:** #72. This plan deliberately consolidates the fix into **one coding task**. Do not split it into a chain of performance tasks unless a genuinely independent blocker is discovered.

**Coding model:** 5.6-Luna-ExtraHigh.

## User-visible regression

Auras that have already been applied appear again in **Pending Changes** as `apply` operations when the turn is advanced. Periodic auras then fail to behave like persistent ticking state because the aura lifecycle can be refreshed/rebased instead of simply advancing.

The screenshot associated with this regression shows three aura operations still in the turn-scope pending queue (`Empower Ward`, `Shadow Word: Pain`, and `Seal of Righteousness`) alongside resource deltas.

This is not merely a tooltip presentation problem: `client/client_PendingChanges.lua` builds the Aura section directly from `Client.PendingOutboundAuraOperations` / the turn-scope operation order. If the tooltip says an aura is pending as `apply`, there is an actual queued outbound aura operation.

---

# Findings from the current codebase

## 1. `FlushPendingTurnChanges()` is no longer a completion barrier

`Client:FlushPendingTurnChanges()` in `client/client_Event.lua` calls, in order:

1. `FlushDeferredTurnResourceDeltas(...)`
2. `AuraManager:FlushOutboundAuraOperations(...)`

and returns the resulting boolean.

That call site still reads like a synchronous **flush-before-advance** boundary.

It is not one anymore.

After the TaskQueue slicing work, `AuraManager:FlushOutboundAuraOperations()` now delegates to `queueOutboundAuraFlush(...)`. That function creates an `outbound-aura-flush` sliceable job and returns `true` as soon as the job has been queued. The actual `AURA_APPLY_BATCH` / `AURA_DISPEL_BATCH` send occurs later, inside the queued continuation.

The resource side has the same semantic shape: deferred resource work can also be queued for later execution rather than fully transmitted before the caller continues.

This means the meaning of the old API changed from roughly:

```text
flush -> network operations are complete -> caller may advance
```

to:

```text
flush -> asynchronous work has been scheduled -> caller continues immediately
```

without its turn-advance callers being converted to a completion-aware contract.

## 2. `Server:AdvanceEventStep()` advances immediately after merely scheduling that flush

Current `Server:AdvanceEventStep()` does this:

```text
if local host:
    Client:FlushPendingTurnChanges(...)

increment tick/turn
broadcast EVENT_STATE
```

There is no wait for the turn-scope resource or aura queues to drain.

This is the main correctness regression to fix.

A turn-scoped aura application may therefore still exist as pending work while the authoritative event step is incremented and `EVENT_STATE` is broadcast. At minimum this breaks the intended transactional boundary represented by the Pending Changes UI. For other clients it can also reverse the intended logical ordering: a new event step can be observed before the previous step's aura mutation has actually been broadcast.

## 3. Aura re-application is destructive to aura progression

`AuraManager:UpsertAura()` treats an accepted apply to an existing non-independent aura as a real re-application. It restores `turnsRemaining` to the applied duration and then sets:

```text
lastAdvancedTurnNumber = current turn
lastAdvancedStep       = current flattened step
```

That is correct for an intentional spell re-cast/refresh, but it is damaging when the same logical application is replayed, delayed, or repeatedly re-queued by turn orchestration.

A replayed apply therefore both refreshes the duration and moves the advancement cursor to the current step. This directly explains why an aura can remain perpetually "new" and fail to tick/decrement as expected.

## 4. Aura progress still depends on a flattened coordinate whose multiplier is mutable

The original #72 diagnosis remains a separate, real defect.

Aura state uses a flattened step derived from:

```text
turnNumber, tickNumber, totalTicks
```

and compares that value to `lastAdvancedStep`.

`totalTicks` is not immutable: it changes when the active event-unit/page topology changes. The same logical event position can therefore map to a different scalar after a roster/page-count change. A shrink can make the scalar move backwards and suppress due work; a growth can create artificial forward catch-up.

The reverted #67 implementation was statically rejected partly because its aura continuation still traversed this unstable scalar range inside one aura entry. Do not restore that approach.

## 5. Event-unit delta handling can unnecessarily replay startup aura reconciliation

`Client:HandleEventUnitDeltaBatch()` calls `queueEventTraitRuntimeRefresh(...)` after every accepted unit delta batch. That helper restarts a `starting` transition and marks trait, automatic-aura, event-aura and resolved-state startup phases dirty.

The trait/event aura continuations are intended to reconcile existing tracked identities, so this path should normally be idempotent. It is nevertheless too broad: ordinary runtime unit upserts (for example threat/state changes) must not be allowed to forget aura identity and turn an unchanged persistent aura into a fresh application.

This is a **hardening requirement** for the regression fix, not a reason to redesign the whole event startup system.

## 6. Issue state does not match the authoritative tree

- #67 is closed as completed, but its implementation commit `703a7ac...` was explicitly reverted by current HEAD.
- #68 is closed as completed, but the sparse due-work implementation it describes is not the implementation to use as a prerequisite for this regression.
- #72 is still useful, but its old body is too narrow and its dependency assumptions are stale.

The regression fix must use the current tree as source of truth and must not assume #67 or #68 code exists merely because their issues are closed.

---

# Target behavior

A turn is a small authoritative transaction:

```text
player actions mutate local pending state
    -> End Turn / Advance requested
    -> previous turn's pending resource operations are sent
    -> previous turn's pending aura operations are sent
    -> both turn-scope queues are actually drained
    -> authoritative event step advances exactly once
    -> EVENT_STATE for the new step is broadcast
    -> clients advance casts/cooldowns/auras for that new step
```

The word **sent/drained** is important. "A TaskQueue job was created" is not equivalent to completion.

The fix must retain cooperative slicing; do not solve this by turning all queued resource/aura work back into a large synchronous loop.

---

# Single implementation task

## A. Add one explicit pending-turn commit/barrier

Create one small event-scoped coordinator for the existing turn-scope outbound queues. The exact names are flexible, but the contract must be explicit, e.g.:

```text
RequestPendingTurnCommit(eventState, options)
IsPendingTurnCommitCurrent(eventId, sourceTurn, sourceTick, generation)
CompletePendingTurnCommit(...)
CancelPendingTurnCommit(...)
```

The coordinator must capture at least:

```text
event id
source turn number
source tick number
request/generation identity
whether host advancement was requested
resource phase status
aura phase status
completion/cancelled/failed status
```

### Required ordering

Preserve the current intended flush order:

```text
turn resource deltas
-> turn aura operations
-> authoritative step mutation / EVENT_STATE send
```

If the existing queue ordering proves a different authoritative dependency, document it before changing the order.

### Completion semantics

The coordinator may use callbacks/completion handles around the existing sliceable resource/aura jobs. Do not busy-loop and do not synchronously process an unbounded pending queue.

A phase is complete only when:

- its send job has completed successfully;
- relevant turn-scope pending entries for this event/source step have been removed from the queue because they were actually sent;
- there is no still-running matching flush job whose completion can mutate this commit.

A boolean meaning "queued" must not be consumed as "flushed" by the turn-advance path.

### Failure semantics

If an outbound send fails:

- do **not** advance the authoritative step;
- retain/retry the unsent pending operations according to the existing retry policy, or surface a clear failed commit state if no retry policy exists;
- never silently clear an unsent aura and then advance.

## B. Make every authoritative advance path use the barrier

Audit all callers of `Server:AdvanceEventStep()` and all UI/programmatic paths that can request the same mutation.

Refactor `Server:AdvanceEventStep()` so the public/request path does not mutate the step until the commit is complete.

A straightforward structure is:

```text
Server:AdvanceEventStep()
    validate readiness
    if local-host pending turn commit is required:
        request/attach to commit
        return accepted/pending
    else:
        AdvanceEventStepNow(expected source identity)

on commit completion:
    revalidate exact event + source turn/tick + generation
    AdvanceEventStepNow(...)
```

Keep the actual increment/broadcast in one private/internal function so completion cannot recurse through the request path and create a second commit.

### Duplicate input

Rapid/double clicks while one advance is pending must collapse to one authoritative advance. Do not queue two advances for the same source `(eventId, turn, tick)`.

### Stale input

If the event ends, is replaced, or has already moved to another source step while the commit is outstanding, completion must not advance it.

## C. Keep `Client:EndTurn()` completion-aware

For a non-host player, `EndTurn()` may keep `TurnEndPending = true` while its turn-scope commit drains.

Do not restore action availability merely because the send jobs were queued. The existing next authoritative `EVENT_STATE` should remain the normal signal that the turn actually moved.

Ensure the local pending tooltip/action-bar state refreshes when operations are genuinely removed, not only when a flush job is scheduled.

## D. Make aura identity/reconciliation unable to refresh an unchanged aura

Audit these paths together:

- `ApplyAuraFromContext()` / `QueueAuraApply()`
- inbound `AURA_APPLY` / `AURA_APPLY_BATCH`
- `SyncAutomaticTraitAuras()` / its continuation
- `SyncEventAuras()` / its continuation
- `queueEventTraitRuntimeRefresh()` after `EVENT_UNIT_DELTA_BATCH`

Requirements:

1. An **intentional re-cast/re-application** must retain the existing gameplay behavior: refresh/stack according to the aura definition.
2. Merely reconciling an already-tracked automatic/event aura must not call `UpsertAura()` as a fresh application.
3. Ordinary unit-state/threat/resource deltas must not erase reconciliation identity for unchanged auras.
4. A stale queued `apply` belonging to a superseded event/turn commit must not be sent after that commit is invalidated.
5. Do not add a generic rule that "existing aura apply packets are ignored"; legitimate re-casts must continue to work.

Prefer fixing operation ownership/identity at the orchestration/reconciliation layer rather than weakening `UpsertAura()` semantics globally.

## E. Replace the mutable flattened aura progress cursor

Keep this in the same issue so there is one aura-correctness task.

Remove the use of a scalar whose value is multiplied by current `totalTicks` as the authoritative aura progression cursor.

Preferred conceptual model: track the **logical owner-turn occurrence** for each aura, not a topology-dependent absolute page number.

An aura should advance at most once for each event turn in which its caster's owner page is reached after the aura became active. The cursor must remain stable if `totalTicks` grows or shrinks.

A suitable representation can be based on explicit fields such as:

```text
lastProcessedOwnerTurnNumber
appliedTurnNumber
appliedTickNumber / whether owner page had already passed at application
```

or another explicit `(turn, tick/owner-occurrence)` representation proven stable under page-count changes.

Do **not** recreate:

```text
(turn - 1) * currentTotalTicks + tick
```

under another name.

### Catch-up

Normal sequential `EVENT_STATE` processing should be O(1) per aura owner occurrence. If catch-up across multiple logical owner turns is supported, it must be resumable/bounded; no unbounded `last + 1 .. current` loop inside one aura entry.

### Preserve application timing semantics

Before changing the cursor, write down the current expected behavior for:

- aura applied before its caster's page in the current turn;
- aura applied on/after its caster's page;
- aura refreshed intentionally;
- aura caster page moves because event topology changes.

Use those semantics to initialize the new cursor.

## F. Do not re-introduce the reverted #67 architecture as a prerequisite

This task is a correctness repair, not a replay of #67.

Do not first rebuild the full `advancing` transition or #68 sparse due indexes. Those can be revisited independently after aura/turn correctness is restored.

Reuse the existing TaskQueue slicing APIs already present on `main` and introduce only the narrow completion coordination required by this bug.

---

# Primary files to inspect/change

Expected primary files:

- `server/server_Event.lua`
  - `Server:AdvanceEventStep()`
  - new internal commit-completion advance helper if required
- `client/client_Event.lua`
  - `Client:FlushPendingTurnChanges()`
  - `Client:EndTurn()`
  - event-scoped stale/cancellation integration
  - `HandleEventUnitDeltaBatch()` only where reconciliation invalidation needs narrowing/hardening
- `client/client_Resources.lua`
  - expose reliable turn-scope flush completion/drained state
- `client/spellcasting/AuraManager.lua`
  - expose reliable turn-scope flush completion/drained state
  - pending operation ownership/staleness
  - stable aura progression cursor
- `client/client_Traits.lua`
  - only if automatic/event aura reconciliation can lose identity and reapply unchanged auras
- `client/client_PendingChanges.lua`
  - only if tooltip refresh/completion state requires a narrow adjustment; do not hide real pending entries to make the symptom disappear

Avoid unrelated UI or spell-system refactors.

---

# Required implementation sequence for 5.6-Luna-ExtraHigh

Use this sequence within the **single issue**:

1. **Reproduce/trace current ordering.** Add temporary tracing if needed. Prove when pending aura/resource entries are created, when the sliceable flush job is queued, when each packet is actually sent, and when `EVENT_STATE` is sent.
2. **Implement the completion-aware pending-turn barrier.** Convert host Advance and non-host End Turn to use it. Validate double-click and stale-event behavior before touching aura cursor logic.
3. **Verify the screenshot regression disappears.** After a successful turn commit, previous-turn aura `apply` entries must no longer remain in Pending Changes unless a new gameplay action legitimately created them.
4. **Audit aura reconciliation.** Confirm automatic/event aura startup reconciliation and ordinary unit-delta refreshes cannot enqueue a fresh application for an unchanged identity.
5. **Replace the flattened aura cursor.** Preserve actual aura timing semantics while making page-count changes safe and catch-up bounded.
6. **Run static and in-game validation.** Do not close #72 until the specific matrix below is reported.

This sequence is intentionally explicit so Luna does not broaden the task into a new event runtime architecture.

---

# Acceptance criteria

- [ ] Pending turn aura/resource operations are **actually sent/drained** before the authoritative host step is incremented.
- [ ] `EVENT_STATE` for the next step cannot overtake the previous turn's pending aura operations.
- [ ] `FlushPendingTurnChanges()` no longer exposes an ambiguous queued-vs-complete contract to advance callers.
- [ ] Rapid repeated Advance requests for the same source step produce exactly one step advance.
- [ ] Event end/replacement invalidates stale pending-turn completion callbacks/jobs.
- [ ] Failed outbound sends cannot silently advance and drop the pending mutation.
- [ ] Auras disappear from Pending Changes after their real send completes; the UI is not merely hiding still-pending operations.
- [ ] An unchanged persistent aura is not re-applied merely because the turn advanced or a unit delta caused trait/event reconciliation.
- [ ] Intentional aura re-casts still refresh/stack according to authored aura rules.
- [ ] Periodic auras tick/decrement at the intended caster-owner turn and expire normally.
- [ ] Aura progression does not use a flattened coordinate dependent on mutable `totalTicks`.
- [ ] Event page-count growth/shrink cannot suppress an aura forever or create phantom catch-up ticks.
- [ ] Any multi-owner-turn catch-up is cooperatively bounded/resumable.
- [ ] No reverted #67 implementation is restored wholesale as a prerequisite.

---

# Validation matrix

## Baseline persistent aura

```text
cast Shadow Word: Pain
-> Pending Changes contains one aura apply
-> end/advance turn
-> aura apply packet is sent before next EVENT_STATE
-> pending apply is removed after successful send
-> next appropriate caster-owner occurrence ticks exactly once
-> duration decrements
-> no fresh apply appears without another cast
```

## Multiple auras

```text
apply Empower Ward + Shadow Word: Pain + Seal of Righteousness
-> each legitimate apply appears once in Pending Changes
-> one turn commit drains them
-> later Advance requests do not recreate those apply rows
```

## Intentional refresh

```text
apply an aura
advance until it has fewer turns remaining
cast/apply the same aura again deliberately
-> authored refresh/stack rule is honored
-> this explicit new apply is broadcast once
```

## Resource + aura ordering

```text
one action produces resource deltas and an aura apply
-> resource turn queue completes
-> aura turn queue completes
-> only then is next EVENT_STATE sent
```

Record actual packet/send trace order in the implementation report.

## Async multi-frame flush

```text
force enough pending operations to require multiple TaskQueue slices
-> UI remains responsive
-> step does not advance during intermediate slices
-> completion advances exactly once
```

## Double click

```text
double-click Advance while commit pending
-> one commit identity
-> one EVENT_STATE advancement
```

## Send failure

```text
force/ simulate aura or resource send failure
-> event step remains at source turn/tick
-> unsent operation is retained/retried or commit enters explicit failure state
```

## Event replacement/end

```text
start turn commit
end/replace event before it completes
-> stale completion cannot send/advance the replacement event
```

## Unit delta reconciliation

```text
existing persistent auras active
receive an ordinary runtime unit upsert (e.g. threat/state-only)
-> derived/visual state may refresh as required
-> unchanged aura identities do not generate new QueueAuraApply operations
-> duration/cursor unchanged
```

Then test a genuine structural roster change and confirm desired automatic/event aura membership reconciles correctly without refreshing unchanged members.

## Topology growth/shrink (#72 original case)

```text
periodic aura active
change active event-unit/page count upward
advance through owner page
-> exactly one expected tick per owner turn

repeat with page-count shrink
-> no permanent stall
-> no phantom catch-up burst
```

## Expiry

```text
short-duration aura
advance normally
-> ticks/decrements
-> expires once
-> stale queued apply cannot resurrect it
```

---

# Required handoff report

Before asking for user in-game validation, Luna must report:

1. exact root-cause trace from action -> pending operation -> flush scheduling -> actual send -> `EVENT_STATE`;
2. the new completion contract and where it is enforced;
3. every authoritative `AdvanceEventStep()` caller found and how duplicate requests are gated;
4. resource-vs-aura-vs-state packet ordering after the fix;
5. stale/event-replacement behavior;
6. the new aura progression cursor and why `totalTicks` changes cannot corrupt it;
7. whether any trait/event reconciliation path was capable of losing aura identity and the exact hardening made;
8. files/functions changed;
9. static validation performed;
10. results for the validation matrix above.

Do not close #72 from static inspection alone. User in-game validation is required for this regression.