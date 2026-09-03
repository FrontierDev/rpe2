# RPE 2 — NPC Autopilot Performance Hitch Elimination
## Product Design Document

**Status:** Proposed  
**Target:** RPEngine 2.0 (`FrontierDev/rpe2`, `dev`)  
**Scope:** NPC Autopilot turn-planning frame hitches, `Authorise All` frame hitches, DM Helper refresh amplification, planner completion duplication, and planner allocation/slicing behaviour  
**Primary objective:** Preserve current Autopilot decisions and authorization semantics while ensuring that planning and bulk authorization no longer monopolize a WoW frame  
**Related design:** `.docs/RPE2-NPC-Autopilot-PDD.md`, `.docs/RPE2-NPC-Autopilot-Implementation-Plan.md`, `.docs/RPE2-Runtime-Performance-Hitch-Elimination-PDD.md`  
**Out of scope:** Changing NPC tactical priorities, target-selection rules, action-economy rules, movement semantics, spell effects, combat math, manual-event scheduling, or removing explicit DM authorization

---

# 1. Purpose

NPC Autopilot is functionally operating, but two host-side operations can currently freeze or visibly stall the WoW client:

1. advancing into an NPC Autopilot turn, while the host planner builds the pending plan;
2. clicking **Authorise All**, while the host executes all currently authorisable actions.

The current TaskQueue design intends Autopilot planning to be cooperative and sliceable. Runtime diagnostics show that this contract is not being met: a single planner slice can run for approximately 180 ms. `Authorise All` is more severe because it executes its entire batch synchronously and can occupy the client for several seconds.

This document defines a targeted performance correction. It does **not** redesign Autopilot gameplay. The expected plan, target choices, sequence dependencies, movement rules, spell lifecycle and DM authority remain unchanged.

---

# 2. Runtime Evidence

The following measurements were captured in-game with RPE INTERNAL timing diagnostics enabled.

## 2.1 Turn advance / planner

Observed planner summary:

```text
Autopilot planner complete ...
slices=19
yields=18
maxSlice=179.92ms
wall=5865.87ms
spells=14
targets=18
anchors=3
unreachable=3
```

Observed outer planning process:

```text
Autopilot planning ... took 6509.10ms
```

The total wall time is not itself the frame-rate defect because a cooperative job may legitimately span multiple frames. The critical measurement is:

```text
maxSlice=179.92ms
```

A 179.92 ms indivisible slice necessarily causes a visible frame hitch.

The approximately 643 ms difference between the planner's own wall time and the outer process time is also significant. Static call-path inspection shows substantial completion work after `Planner.Step()` reports completion, including plan copying, publication, helper refreshes and a second publication path.

## 2.2 Authorise All

Observed timing:

```text
Autopilot authorize all took 4123.09ms
[eventUnits=5,outcome=completed,tick=1,turn=2]
```

This is not a background wall-time measurement. The current `Authorise All` path executes the batch synchronously from the button callback, so the several-second timing corresponds directly to client unresponsiveness.

---

# 3. Current Call-Path Diagnosis

## 3.1 `Authorise All` is synchronous execution, not a cheap authorization state update

The current batch path in `client/autopilot/AuthorizationSequence.lua` iterates pending spell actions and calls the public per-action authorization API.

Conceptually:

```text
Authorise All button
    -> Client:AuthorizeAllAutopilotPendingActions()
        -> RefreshPlanDependencies()
        -> for each eligible action
            -> Client:AuthorizeAutopilotPendingAction()
                -> authorization validation
                -> OnAutopilotPendingActionAuthorized()
                    -> ExecuteEventUnitSpell()
                        -> ResolveSpellActivationSnapshot(includeTargetCandidates=true)
                        -> validate planned target selections
                        -> Client:OnSpellcastStart()
                -> dependency/status refresh
        -> final helper refresh
    -> explicit UI RefreshCombatLogHistoryPanel()
```

Authorization therefore performs normal spell execution work. This is correct behaviour from a gameplay-authority perspective, but performing the entire batch on one UI stack is not acceptable.

The bulk operation must become a **resumable authorization/execution batch** while preserving the exact action order and sequence dependencies.

---

## 3.2 `QueueAutopilotDMHelperRefresh()` is currently synchronous

`client/autopilot/Helper.lua` exposes:

```lua
Client:QueueAutopilotDMHelperRefresh()
```

but when the DM Helper panel is open it immediately calls:

```lua
widget:RefreshCombatLogHistoryPanel()
```

The function name therefore describes intent rather than implementation. It does not coalesce or defer work.

This matters because authorization changes an action through several states (`authorized`, `executing`, `completed` or failure states), and multiple wrappers request a helper refresh around the same transition.

For one successful bulk-authorized spell, the present wrapped call path can request a full helper refresh approximately four times before the batch proceeds to the next spell. The batch then performs another refresh, and the toolbar button performs an additional explicit refresh after the API returns.

For N successful spells, the current path is therefore approximately:

```text
4N + 2 synchronous full helper refreshes
```

The exact count can vary with failure paths, but the architectural problem does not: state-change notifications are directly invoking expensive rendering work.

---

## 3.3 Autopilot helper refresh rebuilds both a hidden generic view and the visible dashboard

The dedicated Autopilot dashboard is layered on top of the generic DM Helper/Combat Log History panel.

When the panel refreshes in Autopilot mode, the call chain first runs the generic DM Helper refresh, which builds provider entries and updates the generic scroll/detail presentation. The Autopilot wrapper then runs `RefreshAutopilotHelperDashboard()`, which independently rebuilds the operational Autopilot presentation.

The Autopilot dashboard recalculates or updates:

- marker states;
- pending action rows;
- turn outcomes;
- marker buttons;
- pending/outcome scroll items;
- selected entry state;
- detail contents;
- toolbar controls;
- dashboard layout.

The generic scroll is hidden while the dedicated Autopilot dashboard is active. Rebuilding the generic Autopilot provider representation first is therefore redundant.

In Autopilot dashboard mode, refresh routing must go directly to the dedicated dashboard path.

---

## 3.4 Planner completion publishes the same completed plan twice

`client/client_AutopilotPlanner.lua` explicitly publishes the completed plan during the sliceable job's `onComplete` callback, before releasing scratch state.

`client/autopilot/Authorization.lua` also wraps `Planner.ReleaseScratch()` and republishes a ready `planRecord.result`.

Conceptually:

```text
onComplete
    -> Planner.CopyCompletedPlan()
    -> Client.PublishAutopilotPendingPlan()
    -> Planner.ReleaseScratch()
        -> wrapped ReleaseScratch()
            -> Client.PublishAutopilotPendingPlan()   # second publication
            -> base ReleaseScratch()
```

The base publication API is idempotent for an already-known plan ID, so the second publication does not create a second logical plan. It still causes avoidable status/dependency/helper work through the wrappers around publication.

There must be one owner for completed-plan publication.

---

## 3.5 Planner slicing is cooperative only at outer boundaries

The TaskQueue budget is small, but the budget is only enforced when code reaches `Tasks:ShouldYield(deadlineMs)`.

Several planner operations perform substantial work before the next yield check.

### Activation phase

For one spell, `phaseActivation()` currently performs the complete canonical activation snapshot and spell-profile build before checking the deadline:

```text
BuildSpellActivationSnapshot(includeTargetCandidates=true)
BuildSpellProfile(...)
ShouldYield(...)
```

If either operation becomes expensive, the queue cannot interrupt it.

### Candidate construction

After `TargetSelector.Step()` finishes a target selection, candidate construction loops over all selected targets and calls `SpellEvaluator.EvaluateCandidate()` for each target before returning to a yield boundary.

### Sequence/movement reevaluation

`SequencePlanning.ReevaluateCandidate()` loops over the candidate's targets synchronously. Movement solving invokes that reevaluation while scoring candidate actions at anchors. The movement solver cannot yield inside that call.

### Per-member sequence construction

At an anchor, the movement solver may synchronously run:

```text
BuildSequence()
SummarizeSequence()
ReserveSequence()
```

before its next deadline check.

### Finalization

Planner finalization builds the completed snapshot and copies multiple collections without a deadline-aware continuation. `Planner.CopyCompletedPlan()` then deep-copies the completed snapshot again after the planner itself has finished.

The result is a system that is nominally sliceable but still contains large atomic islands.

---

# 4. Allocation and Copying Diagnosis

## 4.1 Projected Aura ledgers copy immutable data repeatedly

Autopilot candidate evaluation projects future Aura value. The projected Aura ledger is cloned frequently during candidate evaluation and tactical reservation.

Current projected Aura state cloning recursively copies fields including:

- `stackTurns`;
- Aura `profile`;
- Aura `definition`.

The profile and definition are planning inputs and are treated as immutable by the evaluator. Repeatedly deep-copying them for every ledger branch creates unnecessary Lua allocation and GC pressure.

The projected ledger should use structural sharing/copy-on-write semantics:

- mutable branch maps are copied when a branch changes;
- mutable stack state is copied when necessary;
- immutable Aura definitions/profiles are shared by reference;
- no shared immutable object may be mutated by projected-state code.

This change must be internal to Autopilot projection and must not alter live AuraManager state.

## 4.2 Completed planner snapshot ownership is unnecessarily copy-heavy

The planner builds an isolated frozen snapshot for planning. At completion it creates a result snapshot, then `Planner.CopyCompletedPlan()` recursively copies that snapshot into another completed-plan table before the original planner state is released.

A completed immutable planner result should be transferred or detached rather than recursively cloned again solely to survive scratch release.

The implementation may introduce an ownership-transfer API such as a `TakeCompletedPlan()`/detach operation, or an equivalent mechanism, provided:

- callers cannot subsequently mutate planner scratch through the completed result;
- `ReleaseScratch()` remains safe on both complete and cancelled jobs;
- pending authorization receives stable data;
- no second full deep copy is required.

---

# 5. Product and Architectural Requirements

## 5.1 Preserve gameplay semantics

This performance work must not change:

- which NPCs belong to a turn step;
- which spells are legal;
- spell utility ranking;
- healing/damage/control priority;
- threat-based hostile targeting;
- AoE target ordering;
- shared-marker movement rules;
- action-economy sequence ordering;
- resource, cooldown, charge or GCD rules;
- action dependency semantics;
- DM movement confirmation;
- individual Authorise/Reject behaviour;
- the requirement for explicit DM authorization;
- normal spellcasting execution and synchronization.

Performance optimization must operate around the existing canonical gameplay APIs rather than replacing their rules.

## 5.2 Helper refreshes are dirty notifications, not rendering commands

`QueueAutopilotDMHelperRefresh()` must become a true queue/coalescing boundary.

Required behaviour:

```text
first dirty notification
    -> mark helper dirty
    -> schedule one deferred refresh
additional notifications before flush
    -> leave same scheduled refresh pending
flush
    -> render current state once
```

The refresh should be event-safe: if the event/panel/mode changed before the deferred task runs, stale work should no-op.

The implementation must not create an unbounded chain of refresh tasks.

## 5.3 Dedicated Autopilot mode bypasses hidden generic reconstruction

When the history panel is in `dm-helper` mode and the active host event is Autopilot, `RefreshCombatLogHistoryPanel()` must route directly to the dedicated Autopilot dashboard refresh and only perform the minimum shared container/layout work required.

Generic DM Helper rendering remains unchanged for non-Autopilot providers/modes.

## 5.4 `Authorise All` becomes a sliceable batch

Bulk authorization remains an explicit DM action, but execution is processed through a resumable job.

Required properties:

- preserve `plan.orderedActionIds` ordering;
- never authorize an action before its sequence/movement dependencies are satisfied;
- preserve current stale/context validation;
- preserve per-action normal spell execution;
- after an action changes state, make any newly eligible next action discoverable;
- allow the TaskQueue deadline to interrupt the batch between actions and, where practical, between expensive sub-operations;
- do not refresh the visible helper after every intermediate state;
- coalesce presentation refreshes;
- cancel/no-op if the event, turn, tick, actor or active authorization plan changes;
- the button must not synchronously execute the full batch.

The existing single-action Authorise button remains synchronous from the user's perspective unless its underlying spell lifecycle is already deferred. It still benefits from coalesced helper rendering.

## 5.5 Planner must honor a bounded per-frame slice contract

Planner work must be resumable at the boundaries that dominate runtime, not merely at outer loops.

At minimum, the implementation must address known atomic regions in:

- candidate target evaluation;
- sequence candidate reevaluation;
- movement-anchor/member evaluation where candidate reevaluation occurs;
- final result construction/copying.

If aggregate phase diagnostics show that canonical activation snapshot creation itself exceeds the frame budget in the reproduction case, activation work must also be split or otherwise reduced without duplicating spell legality logic.

Increasing the global TaskQueue budget is explicitly prohibited.

## 5.6 One completed-plan publication owner

The explicit `onComplete` publication in the coordinator is the preferred owner because it publishes while the completed plan and runtime are still intentionally live.

`Planner.ReleaseScratch()` must return to being a cleanup operation and must not republish an already completed plan.

Cancellation must never publish.

## 5.7 Diagnostics remain aggregate under RPE INTERNAL

The repository has been adjusted so INTERNAL output reports full-process diagnostics rather than high-volume per-helper timing spam. This policy must be preserved.

Planner completion should include enough aggregate data to identify future regressions without logging every candidate evaluation. Recommended fields:

```text
Autopilot planner complete ...
slices=
yields=
maxSlice=
wall=
activationMax=
targetsMax=
solveMax=
finalize=
spells=
targets=
anchors=
unreachable=
```

The precise field names may follow existing conventions, but the diagnostic must identify which planner phase owned the maximum atomic work.

Bulk authorization should similarly emit one completion summary, for example:

```text
Autopilot authorize all complete ...
actions=
slices=
yields=
maxSlice=
wall=
outcome=
```

Do not add per-action INTERNAL timing lines by default.

---

# 6. Performance Targets

The purpose of this work is frame-hitch elimination, not simply reducing total wall time.

For the five-unit reproduction that produced the measurements above:

## Planner

- no individual planner/TaskQueue slice should exceed **16.7 ms**;
- target maximum slice is **8 ms or less**;
- normal steady-state slices should remain near the existing TaskQueue budget;
- total wall time may span several frames if necessary;
- no optimization may increase the global TaskQueue budget to hide an atomic operation.

## Authorise All

- clicking the button must return without synchronously executing the complete multi-action batch;
- the authorization batch must be resumable and expose a `maxSlice` measurement;
- no batch slice should exceed **16.7 ms** in the reproduction case;
- target maximum slice is **8 ms or less**;
- the DM Helper must remain responsive while the batch progresses;
- intermediate action state must remain valid even if a later action becomes stale or fails.

## Helper rendering

- repeated dirty notifications in one frame/queue interval must coalesce to one pending helper refresh;
- a completed plan should not cause duplicate plan publication;
- Autopilot dashboard refresh must not rebuild the hidden generic DM Helper provider list first.

These are acceptance targets for the known reproduction, not promises that all future arbitrary datasets can never exceed a frame budget. Aggregate diagnostics must make future outliers visible.

---

# 7. Validation Requirements

## 7.1 Deterministic logic validation

Where possible, test/mimic the pure orchestration logic with deterministic stubs:

- multiple helper dirty notifications create only one scheduled flush;
- a stale event/panel token causes the scheduled helper flush to no-op;
- bulk authorization preserves ordered sequence execution;
- action 2 cannot run until action 1 reaches a resolved predecessor status;
- failed/stale predecessor blocks later sequence actions with the existing reason;
- pending movement still blocks movement-dependent spells;
- a batch cancelled by event/turn/tick change executes no further actions;
- one failed action does not incorrectly authorize an ineligible successor;
- completed-plan publication occurs exactly once;
- cancellation publishes zero times;
- projected Aura ledger copies do not mutate sibling branches;
- shared immutable Aura profile/definition references remain unchanged;
- planner ownership transfer leaves no dangling dependence on released scratch state.

## 7.2 In-game validation — Authorise All

Using an Autopilot event with a representative five-unit roster and several pending spell actions:

1. enable RPE INTERNAL diagnostics;
2. open DM Helper;
3. click **Authorise All**;
4. verify the UI does not freeze for seconds;
5. verify action order and outcomes match individual authorization semantics;
6. verify resources, cooldowns, charges, GCD, effects, combat log and target choices remain correct;
7. verify the helper updates to final/intermediate state without duplicate visible rebuilding;
8. repeat with DM Helper closed;
9. compare completion timing and `maxSlice` between open/closed cases;
10. repeat with one action intentionally becoming stale/invalid and verify the remaining sequence behaviour is correct.

## 7.3 In-game validation — turn advance/planner

Using the same or equivalent reproduction:

1. enable RPE INTERNAL diagnostics;
2. advance into the NPC Autopilot step;
3. capture the single planner completion line;
4. verify `maxSlice < 16.7 ms`, target `<= 8 ms`;
5. verify the generated plan contains the same class of movement/spell/target decisions as before the optimization;
6. confirm same-marker NPCs still plan as one spatial cohort;
7. verify healing, interrupt, damage and control choices remain valid when represented in the test dataset;
8. verify the plan appears once in DM Helper;
9. verify no duplicate publication/refresh occurs after planner completion;
10. repeat with the DM Helper closed to ensure planner performance is not presentation-dependent.

## 7.4 Manual-event regression

Start and advance a manual event and verify:

- no Autopilot planner starts;
- no Autopilot authorization batch is created;
- Combat Log/DM Helper behaviour outside the Autopilot dashboard is unchanged;
- normal spellcasting remains unchanged.

---

# 8. Regression Surface

The implementation must explicitly review regressions for these APIs/call sites:

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
Planner.CopyCompletedPlan / replacement ownership-transfer API
Planner.ReleaseScratch
SequencePlanning.ReevaluateCandidate
MovementSolver.Step
AuraEvaluator.CloneProjectedAuraLedger
AuraEvaluator.ReserveProjectedAura
SpellEvaluator.EvaluateCandidate
```

Every wrapper layer must be re-read from the current `dev` branch before editing. The Autopilot modules deliberately wrap several APIs in load order; changing only the apparent base implementation without tracing the wrappers can leave the expensive behaviour active.

---

# 9. Delivery Strategy

Use the minimum practical issue count: **two implementation issues**.

1. **Authorization and DM Helper hitch elimination** — coalesced helper refresh, direct Autopilot dashboard routing, resumable `Authorise All`, and removal of explicit redundant button refreshes.
2. **Planner bounded-slice and completion optimization** — aggregate phase diagnostics, resumable expensive planner regions, projected Aura ledger allocation reduction, single publication ownership, and removal of redundant completed-plan deep copying.

The first issue should be completed and validated before the second is implemented. This separates the 4-second synchronous authorization defect from the planner's 180-ms slice defect while avoiding an unnecessary proliferation of tasks.

---

# 10. Definition of Done

This performance work is complete when:

- `Authorise All` no longer executes the full action batch on one UI stack;
- helper refresh requests are deferred/coalesced;
- Autopilot dashboard mode no longer rebuilds the hidden generic helper representation first;
- the planner no longer produces the observed ~180 ms slice in the reproduction case;
- the known reproduction records no slice above 16.7 ms, with <=8 ms as the target;
- completed plans are published once;
- planner result ownership no longer requires an unnecessary second deep snapshot copy;
- projected Aura branches do not recursively duplicate immutable profile/definition data for every evaluation;
- existing Autopilot gameplay decisions and DM authorization semantics are preserved;
- manual events and normal spellcasting remain unchanged;
- RPE INTERNAL emits concise aggregate process diagnostics sufficient to catch future regressions;
- the required deterministic and in-game validation passes.
