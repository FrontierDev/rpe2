# RPE 2 — NPC Autopilot Performance Hitch Elimination
## Implementation Plan

**Status:** Proposed implementation sequence  
**Target:** RPEngine 2.0 (`FrontierDev/rpe2`, `dev`)  
**Source design:** `.docs/RPE2-NPC-Autopilot-Performance-Hitch-Elimination-PDD.md`  
**Execution model:** Two issues, executed sequentially in this conversation by GPT-5.6 Sol High  
**Issues:** #180, #181  

---

# 1. Objective

Remove the two observed host-side Autopilot frame hitches without changing gameplay behaviour:

- turn advance currently allows an Autopilot planner slice of approximately **179.92 ms**;
- **Authorise All** currently executes synchronously and has been measured at approximately **4123.09 ms** for a five-unit event.

The implementation must preserve existing:

- turn scheduling;
- target selection;
- utility ranking;
- action-economy ordering;
- shared-marker movement;
- resource/cooldown/GCD/charge semantics;
- spell lifecycle execution;
- dependency/stale handling;
- explicit DM authorization.

The plan deliberately uses only **two implementation issues**. The first removes authorization/UI amplification. The second makes the planner genuinely bounded and removes completion/copy duplication.

---

# 2. Execution Protocol for GPT-5.6 Sol High

For each issue, in order:

1. Read the **current `dev` version** of every affected file before editing. Do not assume code is unchanged from this plan or PDD.
2. Trace the exact current wrapper/load-order call path being modified, especially across `Authorization.lua`, `Execution.lua`, `AuthorizationSequence.lua`, DM Helper extensions and planner wrappers.
3. Implement only the current issue's scope. Do not opportunistically redesign adjacent combat, UI, TaskQueue or spellcasting architecture.
4. Preserve public API behaviour unless the issue explicitly changes that API.
5. Add or exercise deterministic pure-logic tests/mocks where practical.
6. Review the resulting diff for accidental architectural expansion.
7. Identify regressions for every modified public API and wrapper call site.
8. Perform all non-WoW validation available from the repository/runtime environment.
9. Provide the exact in-game validation procedure required for behaviour that cannot be verified outside WoW.
10. Do not close the issue until its acceptance criteria have been validated to the extent possible; where user in-game timing is required, stop and request that result before closure.
11. Do not proceed to the next issue until the current issue is complete/closed or the user explicitly instructs otherwise.

Do not increase the global TaskQueue budget as a performance workaround.

---

# 3. Delivery Sequence

```text
#180 Authorization + DM Helper hitch elimination
    ↓
In-game Authorise All validation
    ↓
#181 Planner bounded slices + completion/allocation optimization
    ↓
In-game planner/turn-advance validation
```

---

# 4. Task A — Issue #180: Authorization and DM Helper Hitch Elimination

**GitHub issue:** #180 — `Eliminate Autopilot Authorise All and DM Helper frame hitches`  
**Primary symptom:** `Autopilot authorize all took 4123.09ms` for a five-unit event  

## Goal

Make **Authorise All** resumable and remove synchronous helper-refresh amplification so a bulk authorization no longer freezes the WoW client.

## Current path to re-read before editing

At minimum, trace the current implementations/wrappers in:

```text
client/autopilot/Authorization.lua
client/autopilot/Execution.lua
client/autopilot/AuthorizationSequence.lua
client/autopilot/Helper.lua
client/ui/widgets/widget_Event_DMHelper.lua
client/ui/widgets/widget_Event_AutopilotHelper.lua
core/internal/tasks/TaskQueue.lua
client/spellcasting/Lifecycle.lua
RPEngine_Dev.toc
```

Confirm the actual TOC load order before changing wrapped APIs.

## Required work

### A1. Make helper refresh genuinely deferred and coalesced

Refactor `Client:QueueAutopilotDMHelperRefresh()` so it becomes a dirty-notification boundary rather than calling `RefreshCombatLogHistoryPanel()` immediately.

Required behaviour:

```text
first notification
    -> set pending/dirty state
    -> enqueue one refresh flush
subsequent notifications before flush
    -> do not enqueue another flush
flush
    -> verify event/panel/mode still current
    -> clear pending state
    -> perform one current-state refresh
```

Use the existing task/deferred infrastructure rather than creating a bespoke OnUpdate loop.

The queued refresh must safely no-op if:

- the event changed;
- the panel was closed;
- the panel mode changed;
- the host is no longer eligible for the Autopilot dashboard.

Do not allow an unbounded refresh queue.

### A2. Bypass hidden generic DM Helper reconstruction in Autopilot dashboard mode

Trace the current wrapping chain of `EventWidget:RefreshCombatLogHistoryPanel()`.

When all of the following are true:

```text
combatLogHistoryMode == "dm-helper"
active event is host Autopilot event
dedicated Autopilot dashboard is active
```

route refresh directly to the dedicated Autopilot dashboard presentation.

Do not first rebuild the generic DM Helper provider list/scroll that will immediately be hidden.

Preserve generic DM Helper behaviour for:

- manual events;
- non-Autopilot providers;
- ordinary Combat Log history mode.

### A3. Remove redundant explicit post-action UI refreshes

The Autopilot UI button callbacks currently call an action API and then explicitly call `RefreshCombatLogHistoryPanel()` even though the action path already marks helper state dirty.

Remove direct duplicate refresh calls where the new queued helper refresh is the canonical presentation invalidation path.

Review at least:

- individual Authorise;
- Reject;
- Confirm Moved/Done;
- Authorise All;
- Replan;
- Skip Movement;
- Set Position Here.

Do not remove a refresh unless the action path reliably marks the helper dirty or the callback explicitly does so through the new queue boundary.

### A4. Replace synchronous `Authorise All` with a sliceable authorization batch

Do not process the entire batch from the toolbar button callback.

Introduce a resumable batch state owned by the active event/authorization plan and execute it through `Tasks:EnqueueSliceable()` or the current equivalent.

The batch must preserve:

- `plan.orderedActionIds` order;
- sequence dependency semantics;
- movement dependencies;
- current event/turn/tick/actor/schedule validation;
- action status transitions;
- stale/failure classifications;
- normal `ExecuteEventUnitSpell()` and normal spell lifecycle;
- explicit DM initiation of the batch.

Prefer a small internal authorization core used by both single-action and batch paths rather than repeatedly calling the full public single-action wrapper from inside the batch.

The internal core should not directly render UI. State changes should mark helper presentation dirty.

After each executed action:

1. update status/dependencies as required so the next action in the same caster sequence can become eligible;
2. stop when the TaskQueue deadline is reached;
3. resume from explicit batch cursor/state on the next slice.

The batch must cancel or stop safely if its identity becomes stale.

Do not automatically confirm movement. Movement-dependent actions remain blocked until the DM has explicitly confirmed movement.

### A5. Add one aggregate batch diagnostic

Preserve the current policy of concise full-process INTERNAL timings.

Emit one completion/cancellation summary for the batch with fields sufficient to validate frame behaviour, for example:

```text
Autopilot authorize all complete event=... turn=... tick=...
actions=...
slices=...
yields=...
maxSlice=...ms
wall=...ms
outcome=completed|cancelled|failed
```

Do not add default per-action timing spam.

## Deterministic validation

Exercise the orchestration with stubs/mocks where practical:

1. three helper dirty notifications before the flush create one scheduled refresh;
2. dirty notification after a flush can schedule a new refresh;
3. stale event/panel identity causes a queued refresh to no-op;
4. two-action caster sequence authorizes action 1 before action 2;
5. action 2 becomes eligible only after action 1 resolves to the existing allowed predecessor status;
6. stale/failed predecessor preserves the existing blocking reason for later actions;
7. movement-dependent spell remains blocked until movement is confirmed;
8. batch cancellation after turn/tick/event change executes no further actions;
9. failed action does not incorrectly unlock a successor;
10. one action per slice / forced-deadline test proves batch cursor resumes correctly;
11. individual Authorise still behaves correctly;
12. generic non-Autopilot DM Helper refresh still works.

## In-game validation

Use a representative Autopilot event with approximately five units and several pending spell actions.

### Test A — helper open

1. `/rpe debug internal on`.
2. Open **DM Helper**.
3. Ensure multiple spell actions are currently authorisable.
4. Click **Authorise All**.
5. Confirm the client does not freeze for seconds.
6. Capture the aggregate authorization timing line.
7. Confirm `maxSlice < 16.7ms`; target `<= 8ms`.
8. Verify actions execute in correct dependency order.
9. Verify spell targets, resources, cooldowns, charges, GCD and combat results remain correct.
10. Verify the helper updates during/after the batch without repeated visible reconstruction.

### Test B — helper closed

Repeat with DM Helper closed and compare the batch timing. Closing the helper should not materially change gameplay execution semantics and should not be required to avoid the hitch.

### Test C — invalidation

Cause one pending action to become stale/invalid before or during the batch where practical. Verify:

- stale/failed status is preserved;
- dependent actions do not bypass their predecessor;
- unrelated valid sequences are handled according to existing semantics;
- no Lua errors occur.

## Acceptance

Task A is complete when:

- `QueueAutopilotDMHelperRefresh()` is truly queued/coalesced;
- Autopilot dashboard mode bypasses the hidden generic provider-list rebuild;
- toolbar/action callbacks do not force redundant full refreshes;
- `Authorise All` is no longer a full synchronous loop on the button stack;
- the batch is resumable and stale-safe;
- aggregate diagnostics expose batch `maxSlice`;
- the five-unit reproduction records no batch slice above 16.7 ms, target <=8 ms;
- single-action authorization and all existing gameplay semantics remain correct;
- manual/non-Autopilot DM Helper behaviour remains correct.

---

# 5. Task B — Issue #181: Planner Bounded Slices and Completion/Allocation Optimization

**GitHub issue:** #181 — `Bound Autopilot planner slices and remove completion copy/publication duplication`  
**Primary symptom:** planner `maxSlice=179.92ms`, `wall=5865.87ms`; outer planning `6509.10ms`  

## Goal

Make planner work genuinely resumable at the expensive inner operations, eliminate duplicated completion publication/copy work, and reduce projected-Aura allocation pressure without changing plan decisions.

## Current path to re-read before editing

At minimum, trace:

```text
client/client_AutopilotPlanner.lua
client/autopilot/Planner.lua
client/autopilot/PlannerIntegration.lua
client/autopilot/TargetSelector.lua
client/autopilot/MovementSolver.lua
client/autopilot/SequencePlanning.lua
client/autopilot/SpellEvaluator.lua
client/autopilot/AuraEvaluator.lua
client/autopilot/Authorization.lua
client/autopilot/AuthorizationSequence.lua
client/spellcasting/Helpers.lua
core/internal/tasks/TaskQueue.lua
RPEngine_Dev.toc
```

Read current `Planner.Step`, completion callbacks and `Planner.ReleaseScratch` wrappers before selecting the exact seam.

## Required work

### B1. Add aggregate per-phase planner diagnostics first

Before broad optimization, extend the existing single planner-complete INTERNAL line with aggregate phase information sufficient to identify the remaining maximum atomic region.

Track phase totals and/or maximum indivisible segment for at least:

- snapshot/activation;
- target selection/candidate build;
- solve actors/movement/sequence;
- finalization;
- completion handoff if included by the outer coordinator.

Keep logging to one planner completion line. Do not emit every candidate/target evaluation.

Use the new measurements during implementation to confirm which current atomic helper dominates the reproduction rather than optimizing blindly.

### B2. Make candidate target evaluation resumable

`buildCandidateFromSelection()` currently evaluates every selected target synchronously after target selection finishes.

Convert this into explicit resumable state with at least:

- activation/profile/selection/intent references;
- target cursor;
- accumulated utility totals;
- interrupt/healing/control aggregate state;
- output candidate when complete.

The planner must be able to return to TaskQueue when the deadline is reached between target evaluations.

Preserve the exact existing `SpellEvaluator.EvaluateCandidate()` semantics and candidate fields.

### B3. Make sequence candidate reevaluation resumable

`SequencePlanning.ReevaluateCandidate()` currently loops across candidate targets atomically and is called from both fixed-position and movement-anchor solving.

Introduce a resumable equivalent/state machine or another bounded approach so movement solving cannot hide a large target-evaluation loop inside one `MovementSolver.Step()` iteration.

Required properties:

- same candidate utility output as the current pure function;
- same tactical ledger inputs;
- yield boundary between target evaluations;
- fixed-position solver and marker movement solver both use the bounded path;
- preserve a synchronous convenience wrapper only if other non-planner callers require it and it cannot reintroduce the planner hitch.

### B4. Bound per-member sequence/ledger work where diagnostics require it

After B2/B3, use the new aggregate diagnostics to determine whether `BuildSequence` / `SummarizeSequence` / `ReserveSequence` still creates a frame-budget violation.

If it does, split the affected planner usage into resumable stages rather than increasing the TaskQueue budget.

Do not rewrite action-economy rules merely for performance.

### B5. Reduce projected Aura ledger cloning

Refactor Autopilot projected Aura state so immutable planning data is shared rather than recursively copied on every branch.

At minimum:

- treat Aura profile/definition data as immutable while in the planner;
- copy mutable stack/duration state as required;
- use branch/path copy-on-write for projected ledger updates where safe;
- ensure sibling projected ledgers cannot mutate each other;
- never mutate the live AuraManager definition/state through the projected ledger.

Add deterministic aliasing tests proving branch independence.

### B6. Make planner finalization bounded

`phaseFinalize()` currently builds/copies the completed snapshot and output collections without deadline-aware continuation.

Move final result construction into resumable subphases/cursors or otherwise guarantee bounded work in the known reproduction.

At minimum, large collections must be copied incrementally with deadline checks.

### B7. Remove duplicate completed-plan publication

Establish one publication owner.

Preferred current ownership:

```text
client_AutopilotPlanner.lua onComplete
    -> publish completed plan once
    -> release scratch
```

Remove publication from the `Planner.ReleaseScratch()` wrapper in `Authorization.lua` or refactor the wrapper so release is cleanup-only.

Validate:

- successful plan publishes exactly once;
- cancelled plan publishes zero times;
- failed plan publishes zero pending ready plan;
- authorization status remains correct.

### B8. Remove the second full completed-plan deep copy

Replace the current `Planner.CopyCompletedPlan()` deep snapshot duplication with explicit completed-result ownership transfer/detachment or an equivalent safe mechanism.

The final object retained by `planRecord.result` must:

- remain valid after scratch release;
- not retain mutable planner scratch structures that are later cleared/reused;
- be treated as immutable planning output;
- remain compatible with pending-plan publication.

Do not merely move the same deep copy to another function.

### B9. Re-measure activation only if still required

`phaseActivation()` still calls canonical activation snapshot construction per spell. Do not pre-emptively duplicate spell legality logic.

After B2–B8, inspect aggregate diagnostics. If activation itself produces an atomic segment above 16.7 ms in the known reproduction, make activation bounded by extending/reusing canonical activation logic rather than creating a divergent Autopilot legality implementation.

This is a conditional subtask inside the same issue, not a third issue.

## Deterministic validation

Where practical, validate:

1. resumable candidate build produces byte/field-equivalent utility results to the prior synchronous calculation for deterministic inputs;
2. resumable reevaluation produces equivalent candidate totals for 0, 1 and multiple targets;
3. forced deadline after each target resumes without duplicate accumulation;
4. fixed actor solver preserves selected sequence;
5. marker movement solver preserves selected anchor/sequence for deterministic fixture inputs;
6. healing ledger reservation remains identical;
7. Aura projected ledger sibling branches remain independent;
8. immutable Aura profile/definition references are never mutated;
9. finalization can resume across multiple slices without missing/duplicating records;
10. completed-plan handoff survives scratch release;
11. ready plan publication count is exactly one;
12. cancel/failure publication count is zero;
13. manual event path does not instantiate this planner work.

## In-game validation

Use the same reproduction that previously reported approximately:

```text
maxSlice=179.92ms
wall=5865.87ms
spells=14
targets=18
anchors=3
```

1. `/rpe debug internal on`.
2. Advance into the same NPC Autopilot step.
3. Capture the single planner completion line.
4. Verify `maxSlice < 16.7ms`; target `<= 8ms`.
5. Inspect aggregate phase fields and confirm no hidden phase exceeds the frame budget.
6. Verify the generated pending plan has the expected number/order of NPC actions.
7. Verify target choices and shared-marker movement recommendations remain sensible/equivalent to the pre-fix semantics.
8. Verify the plan appears once in DM Helper.
9. Verify no duplicate publication/refresh occurs after planner completion.
10. Repeat with the DM Helper closed.
11. Repeat a case containing healing if available.
12. Repeat a case containing an Aura/control spell if available to exercise projected Aura optimization.
13. Repeat a marked melee cohort to exercise movement-anchor reevaluation.

## Acceptance

Task B is complete when:

- aggregate planner diagnostics identify phase ownership without per-helper spam;
- expensive candidate and sequence reevaluation loops are resumable;
- known planner finalization work is bounded;
- projected Aura planning no longer recursively duplicates immutable profile/definition data for every branch;
- completed-plan publication has one owner;
- completed-plan handoff avoids the redundant second deep snapshot copy;
- the known reproduction records no planner slice above 16.7 ms, target <=8 ms;
- planner decisions, action ordering, movement behaviour and spell legality remain correct;
- no manual-event or normal spellcasting regression is introduced.

---

# 6. Cross-Issue Regression Checklist

Before closing the second issue, re-check the combined result across:

```text
Client:QueueAutopilotDMHelperRefresh
EventWidget:RefreshCombatLogHistoryPanel
EventWidget:RefreshAutopilotHelperDashboard
Client:AuthorizeAutopilotPendingAction
Client:AuthorizeAllAutopilotPendingActions
Client:OnAutopilotPendingActionAuthorized
Client:ExecuteEventUnitSpell
Authorization.RefreshPlanDependencies
Client:PublishAutopilotPendingPlan
Planner.Step
Planner completion handoff
Planner.ReleaseScratch
SequencePlanning.ReevaluateCandidate / resumable replacement
MovementSolver.Step
AuraEvaluator projected ledger functions
SpellEvaluator.EvaluateCandidate
```

Combined in-game smoke test:

1. start an Autopilot event;
2. advance through at least one player step and one NPC Autopilot step;
3. inspect pending movement/actions;
4. confirm movement where required;
5. use **Authorise All**;
6. advance again;
7. verify no major frame freeze on either planning or authorization;
8. verify combat state, log state and next-turn scheduling remain correct;
9. start a manual event and verify existing manual behaviour.

---

# 7. Completion Criteria

The implementation plan is complete when #180 and #181 are closed and the user-provided in-game reproduction demonstrates:

```text
Planner maxSlice < 16.7ms       (target <= 8ms)
Authorise All maxSlice < 16.7ms (target <= 8ms)
```

while preserving existing Autopilot decisions and explicit DM authorization semantics.
