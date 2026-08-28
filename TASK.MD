## Goal

Fix the current aura/turn-advance correctness regression in **one implementation task**.

Observed in-game: already-applied auras remain in **Pending Changes** as `apply` operations when the turn is advanced. Periodic auras can consequently remain in a refreshed/rebased state instead of ticking and expiring normally.

Authoritative implementation plan:

- `.docs/RPE2-Aura-Turn-Advance-Regression-Implementation-Plan.md`

**Authoritative tree:** current `main` (the tree after `5f33b816acae618abe0daee50dd366cc3fc6267f`, which reverted #67).

**Coding model:** **5.6-Luna-ExtraHigh**.

This rewritten issue supersedes the older #72 body and its dependency assumptions. Do **not** make #67 or #68 prerequisites for this repair.

---

## Verified current-code findings

### 1. The Pending Changes screenshot represents real queued aura operations

`client/client_PendingChanges.lua` builds its Aura rows directly from `Client.PendingOutboundAuraOperations` and the turn-scope pending order. The screenshot is therefore evidence that actual aura `apply` operations remain pending; this is not simply the active-aura display being rendered incorrectly.

### 2. Turn flush APIs became asynchronous, but the advance caller still treats them as a barrier

`Client:FlushPendingTurnChanges()` calls the resource flush and `AuraManager:FlushOutboundAuraOperations()`.

The aura flush no longer means "packets have been sent". It now queues a sliceable `outbound-aura-flush` job and returns before `AURA_APPLY_BATCH` / `AURA_DISPEL_BATCH` are actually sent. The resource path is likewise deferred/sliceable.

`Server:AdvanceEventStep()` nevertheless does:

```text
FlushPendingTurnChanges()
-> immediately increment turn/tick
-> immediately broadcast EVENT_STATE
```

There is no completion barrier between the previous turn's pending changes and the new authoritative event step.

### 3. Re-applying an existing aura resets its progression

`AuraManager:UpsertAura()` intentionally treats a real re-application as a refresh/stack operation. For a normal existing aura it resets `turnsRemaining`, then writes the current turn/progress cursor as the new `lastAdvanced...` state.

That is correct for an intentional re-cast, but a delayed/replayed/re-queued apply can keep the aura looking newly applied and suppress normal ticking/decrementing.

### 4. The original #72 progress bug still exists

Aura progression still flattens `(turnNumber, tickNumber, totalTicks)` into an absolute scalar and stores `lastAdvancedStep`.

`totalTicks` changes when event page topology changes. That makes the scalar unstable: page-count shrink can make progress appear to move backwards and page-count growth can create artificial catch-up.

The replacement must not depend on `(turn - 1) * currentTotalTicks + tick` or an equivalent mutable multiplier.

### 5. Unit-delta/startup reconciliation must remain idempotent

`HandleEventUnitDeltaBatch()` can restart trait/automatic-aura/event-aura startup reconciliation. Ordinary runtime unit changes must not cause that reconciliation to forget an unchanged aura identity and enqueue a fresh application.

Audit and harden this path, but do not redesign the whole startup system.

---

# Implementation requirements

## A. Add one completion-aware pending-turn commit/barrier

Introduce a narrow event-scoped coordinator for turn-scope outbound work. It must capture at least:

```text
event id
source turn/tick
request/generation identity
resource flush status
aura flush status
whether host advancement was requested
completion / cancellation / failure
```

Preserve the intended order:

```text
turn resource deltas
-> turn aura operations
-> authoritative step mutation
-> EVENT_STATE broadcast
```

A phase is complete only when the matching send work actually completed successfully and its pending entries were removed because they were sent. "Sliceable job queued" is **not** completion.

Do not busy-loop and do not convert the queues back into large synchronous loops.

## B. Make `Server:AdvanceEventStep()` wait for the barrier

The public Advance request must:

1. validate readiness/current event;
2. start or attach to the current source-step commit if pending work exists;
3. return without mutating the step while that commit is incomplete;
4. on successful completion, revalidate exact event + source turn/tick + generation;
5. increment/broadcast the step exactly once.

Keep the actual increment/send in one internal helper if necessary so the completion callback cannot recursively create another commit.

Rapid repeated Advance requests for the same source step must collapse to one advance.

If event end/replacement occurs while waiting, stale completion must not advance the replacement event.

If a required send fails, do **not** advance and silently lose the operation.

## C. Keep `Client:EndTurn()` completion-aware

Non-host End Turn should retain its pending/gated state while the turn-scope commit drains. Do not treat a queued send job as successful completion.

Refresh the Pending Changes tooltip/action state when operations are actually removed after successful send.

## D. Preserve legitimate aura refreshes while preventing reconciliation/replay refreshes

Audit:

- `ApplyAuraFromContext()` / `QueueAuraApply()`
- inbound aura apply/batch handlers
- automatic trait aura reconciliation
- event aura reconciliation
- event-unit-delta-triggered runtime refresh

Requirements:

- deliberate spell re-casts still refresh/stack according to the authored aura definition;
- unchanged automatic/event aura identities are not re-upserted as fresh applications merely because reconciliation ran;
- ordinary runtime unit/threat/resource changes cannot erase unchanged aura identity;
- stale pending `apply` operations from an invalidated turn/event cannot be sent later;
- do **not** globally ignore applies to an already-existing aura, because real re-casts must still work.

Prefer fixing operation ownership/reconciliation over weakening `UpsertAura()` globally.

## E. Replace the flattened aura progress cursor

Implement a stable logical aura progression representation that does not depend on mutable `totalTicks`.

Preferred semantics: an aura advances once for each event turn in which its caster's owner page is reached after the aura became active. Use an explicit logical owner-turn / `(turn, owner occurrence)` representation, or another representation proven stable under page-count growth/shrink.

Before coding, document the expected behavior for:

- aura applied before its caster page in the current turn;
- aura applied on/after its caster page;
- intentional aura refresh;
- caster page moving because roster/page topology changes.

Normal sequential advancement should be O(1) per due owner occurrence. If multi-turn catch-up is retained, it must be resumable/bounded and must not contain an unbounded `last + 1 .. current` loop inside one aura entry.

## F. Keep this repair narrow

Do **not** restore the reverted #67 implementation wholesale and do not first implement #68 sparse due-work indexes.

Use the TaskQueue slicing APIs already present on current `main`; add only the completion/stability machinery needed for this correctness repair.

---

## Primary files

- `server/server_Event.lua`
- `client/client_Event.lua`
- `client/client_Resources.lua`
- `client/spellcasting/AuraManager.lua`
- `client/client_Traits.lua` only where reconciliation hardening is required
- `client/client_PendingChanges.lua` only for genuine completion refresh behavior; do not hide real pending rows

---

## Acceptance criteria

- [ ] Previous-turn resource and aura operations are actually sent/drained before host turn/tick mutation.
- [ ] Next-step `EVENT_STATE` cannot overtake the previous turn's pending aura mutations.
- [ ] `FlushPendingTurnChanges()` no longer has an ambiguous queued-vs-complete meaning for advance callers.
- [ ] Double-click/repeated Advance while a commit is pending produces one authoritative step.
- [ ] Event replacement/end invalidates stale pending-turn work.
- [ ] Send failure cannot silently advance and discard unsent changes.
- [ ] Aura `apply` rows disappear from Pending Changes after their real successful send; they are not merely hidden.
- [ ] Advancing a turn does not create a fresh `apply` for an unchanged persistent aura.
- [ ] Ordinary unit-delta reconciliation does not refresh unchanged aura duration/cursor.
- [ ] Intentional re-casts still apply normal refresh/stack rules.
- [ ] Periodic auras tick/decrement on the intended caster-owner occurrence and expire normally.
- [ ] Aura progress no longer uses a scalar multiplied by mutable `totalTicks`.
- [ ] Page-count growth/shrink cannot permanently stall an aura or create phantom catch-up ticks.
- [ ] Any retained multi-owner-turn catch-up is cooperatively bounded.

---

## Required validation matrix

```text
Shadow Word: Pain
-> cast once
-> one pending aura apply
-> End Turn / Advance
-> aura send completes before next EVENT_STATE
-> pending apply is removed
-> next proper owner occurrence ticks once and duration decreases
-> no new apply appears without another cast

Empower Ward + Shadow Word: Pain + Seal of Righteousness
-> each legitimate apply appears once
-> one turn commit drains all three
-> later turn advances do not recreate them

intentional aura refresh
-> cast same aura again after duration has decreased
-> authored refresh/stack behavior still works
-> exactly one new outbound apply for that actual re-cast

resource + aura action
-> resource queue completes
-> aura queue completes
-> only then next EVENT_STATE is sent

multi-frame flush
-> UI remains responsive
-> source step does not move during intermediate slices
-> completion advances exactly once

double-click Advance
-> one commit / one step

forced send failure
-> source step does not advance
-> unsent operation remains retryable or commit enters explicit failure

event replaced/ended mid-commit
-> stale completion cannot mutate/advance replacement

ordinary runtime EVENT_UNIT_DELTA_BATCH with existing aura
-> no new aura apply
-> existing duration/cursor unchanged

page-count grow then shrink with periodic aura active
-> exactly expected owner-turn ticks
-> no permanent stall
-> no catch-up burst

short-duration aura
-> decrements and expires once
-> stale queued apply cannot resurrect it
```

---

## Required Luna handoff

Before requesting user in-game validation, report:

1. exact action -> pending operation -> queued flush -> actual packet send -> `EVENT_STATE` trace before and after;
2. new turn-commit completion contract;
3. every authoritative Advance entry point found and its duplicate/stale guard;
4. resource/aura/state packet ordering;
5. send failure and event-replacement behavior;
6. new aura progress cursor and why `totalTicks` changes cannot corrupt it;
7. reconciliation audit result and any hardening made;
8. files/functions changed;
9. static validation results;
10. results of the matrix above.

**Do not close this issue from static validation alone. User in-game validation is required.**