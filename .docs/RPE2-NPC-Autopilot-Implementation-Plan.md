# RPE 2 — NPC Autopilot and DM Helper
## Implementation Plan

**Status:** Proposed implementation sequence  
**Target:** RPEngine 2.0 (`FrontierDev/rpe2`)  
**Source design:** `.docs/RPE2-NPC-Autopilot-PDD.md`  
**Related existing issues:** #100 Combat Log history, #101 DM Helper  

---

# 1. Objective

Implement NPC Autopilot as a host-authoritative, sliceable **planning** system which:

- groups NPCs sharing a raid marker into one atomic turn actor;
- caches player positions at event start and refreshes one player's position only when that player ends their turn;
- evaluates existing NPC spells and legal targets without duplicating spell legality rules;
- chooses healing, damage, threat targets, AoE targets and shared-marker melee positioning using lightweight deterministic logic;
- publishes proposed movement and spell actions to the host-only DM Helper;
- places every executable NPC action into a Pending Authorization state;
- executes nothing until explicitly authorized by the DM;
- routes authorized actions through the existing NPC spell lifecycle;
- uses `Tasks:EnqueueSliceable()` and `Tasks:ShouldYield(deadlineMs)` for all non-trivial planning work;
- does not support Autopilot inside Blizzard instances.

Manual events must remain behaviorally unchanged.

---

# 2. Non-Negotiable Architectural Constraints

The implementation must preserve the following constraints from the PDD.

1. **Planning is not execution.** Planner completion may create pending records and refresh DM Helper, but may not cast spells, spend resources, consume charges, start cooldowns, apply effects or commit proposed movement.
2. **Every NPC spell requires explicit DM authorization.** Bulk authorization is permitted only as an explicit DM action.
3. **Movement is also DM-controlled.** A proposed virtual marker position is committed only after `Confirm Moved`.
4. **Player positions are cached.** Seed once when the event starts; subsequently sample only the player whose turn has just ended.
5. **NPC planning never performs a full party/raid coordinate rescan.** Missing cached coordinates are handled explicitly rather than silently refreshed or guessed.
6. **All planner work is sliceable.** Do not use a normal deferred task containing an indivisible full-cohort planner.
7. **Planner loops honor the queue deadline.** Candidate-spell, candidate-target, AoE and marker-solver loops must call `Tasks:ShouldYield(deadlineMs)` at resumable boundaries.
8. **Canonical spell activation remains authoritative.** Cooldown, charges, GCD, resources, conditions and target legality must come from the existing spellcasting runtime.
9. **Autopilot does not duplicate combat execution.** Authorized actions converge on the normal NPC spell lifecycle.
10. **Same-marker NPCs plan from one frozen snapshot.** Later actions are not tactically re-scored because an earlier authorized action happened to resolve first.
11. **No automatic retargeting on authorization failure.** Invalidated pending actions become stale/failed; the DM explicitly requests a replan.
12. **Autopilot is unavailable in restricted instances.** Never fabricate coordinates.

---

# 3. Existing Code Paths to Reuse

Implementation should extend existing systems rather than create parallel infrastructure.

## Event state and turn lifecycle

Primary files:

```text
core/classes/Event.lua
core/classes/EventUnit.lua
server/server_Event.lua
client/client_Event.lua
client/spellcasting/Helpers.lua
```

Reuse synchronized:

```text
turnNumber
tickNumber
totalTicks
```

and existing stale-work/turn-commit patterns in `client_Event.lua`.

## Task scheduling

Use:

```lua
Tasks:EnqueueSliceable(options)
Tasks:ShouldYield(deadlineMs)
Tasks:Cancel(jobOrId, reason)
Tasks:CancelScope(scope, reason)
```

from `core/internal/tasks/TaskQueue.lua`.

Do not increase the global TaskQueue budget to accommodate Autopilot.

## Spell legality and lifecycle

Primary files:

```text
client/spellcasting/Cooldowns.lua
client/spellcasting/Helpers.lua
client/spellcasting/Lifecycle.lua
client/client_Targeting.lua
client/client_Spellcasting.lua
```

Extend existing activation snapshots to support explicit NPC casters rather than implementing separate cooldown/resource/condition checks.

## Threat and health

Read existing `EventUnit.threatTable` and normal resource/health state. Do not create a second aggro or health model.

## Event UI

Build on:

```text
client/ui/widgets/widget_Event.lua
client/client_CombatLog.lua
```

and existing issue #101 for the host-only **DM Helper** companion-panel mode.

---

# 4. Delivery Strategy

The implementation is divided into eleven bounded work items. The ordering deliberately establishes deterministic event semantics and read-only planner inputs before adding tactical scoring or any execution path.

```text
A. Event mode + capability UI
        ↓
B. TurnActor / TurnStep scheduling
        ↓
C. Host position cache + virtual spatial runtime
        ↓
D. Autopilot runtime + sliceable planner skeleton
        ↓
E. Explicit-caster activation snapshots
        ↓
F. Spell utility evaluator
        ↓
G. Target selectors
        ↓
H. Melee / shared-marker spatial planner
        ↓
I. Full frozen-plan integration
        ↓
J. Pending authorization + DM Helper controls
        ↓
K. Authorized execution + integration hardening
```

Issue #101 is a prerequisite for the final DM Helper authorization presentation, but most planner/runtime work can proceed independently once its provider seam is understood.

---

# 5. Task A — Event Autopilot Mode and Instance Capability

## Goal

Add synchronized Event-level Autopilot mode without changing manual event semantics.

## Primary files

```text
core/classes/Event.lua
server/server_Event.lua
server/ui/eventmanage/page_EventManageSettings.lua
client/client_Event.lua
```

## Work

- Add normalized `turnMode` with allowed values `manual` and `autopilot`.
- Default all legacy/missing values to `manual`.
- Add backward-tolerant network serialization/deserialization.
- Add Event Manager `Enable NPC Autopilot` control.
- Display the explicit no-instance warning whenever selected.
- On event start, block Autopilot when coordinate capability is unavailable or the host is in restricted instanced content.
- Preserve manual start behavior.
- Expose a small capability helper usable by later runtime code.

## Acceptance

- Old events/network payloads remain manual.
- Manual events are unchanged.
- Every client receives the same `turnMode`.
- Autopilot cannot silently start in a restricted instance.
- The warning is visible without requiring a tooltip.

---

# 6. Task B — Mode-Aware TurnActor and TurnStep Scheduling

## Goal

Create deterministic raid-marker cohort scheduling without coupling Autopilot eligibility to fixed visual pages.

## Primary files

```text
core/classes/Event.lua
server/server_Event.lua
client/spellcasting/Helpers.lua
client/ui/widgets/widget_Event.lua
```

## Work

- Implement `TurnActor` construction.
- Players remain singleton actors; shared-turn pets retain existing semantics.
- NPCs with the same non-zero `raidMarker` form one actor.
- `raidMarker == 0` NPCs remain singleton actors.
- Cohort initiative is the maximum member initiative.
- Internal member order is initiative descending, eventID ascending.
- Pack actors into `TurnStep` values without splitting an actor.
- Permit a marker cohort larger than visible page capacity to occupy one oversized step.
- Add mode-aware helpers such as `BuildTurnSchedule`, `GetUnitTurnStepIndex`, `GetUnitsForTurnStep`.
- Make spellcaster tick eligibility use the new schedule only in Autopilot mode.
- Keep visual pagination independent from eligibility where required.

## Acceptance

- Same-marker NPCs are always eligible together.
- Unmarked NPCs do not collapse into one cohort.
- Oversized cohorts are never split.
- Manual mode retains existing page/tick behavior.
- All clients derive the same eligibility.

---

# 7. Task C — Host Player-Position Cache and Virtual Spatial Runtime

## Goal

Provide stable event-local coordinates without polling or rescanning at NPC planning time.

## Primary files

```text
client/client_Autopilot.lua (new)
client/autopilot/Spatial.lua (new)
client/client_Event.lua
core/internal/Movement.lua (shared pure helpers where appropriate)
RPEngine_Dev.toc
```

## Work

- Add host-only event runtime container.
- Resolve player names to `player` / `partyN` / `raidN` tokens.
- Seed player positions once on Autopilot event start.
- Integrate with authoritative player turn-end lifecycle.
- On a completed player turn, call `UnitPosition()` once for that player and replace only that cache entry.
- Do not sample all players on NPC turn start.
- Store `x`, `y`, `instanceID`, sampled turn/tick identity.
- Add virtual positions keyed by `marker:<raidMarker>` or `unit:<eventID>`.
- Add pure 2D distance/vector helpers.
- Add missing-coordinate and capability status handling.
- Clear all spatial state at event teardown.

## Acceptance

- Event start seeds resolvable players once.
- One completed player turn modifies only that player's coordinate record.
- NPC turns call no full player-position rescan.
- No continuous/per-frame coordinate polling exists.
- Missing positions are explicit and never guessed.

---

# 8. Task D — Autopilot Runtime Coordinator and Sliceable Planner Skeleton

## Goal

Establish lifecycle, idempotence and resumable planning infrastructure before tactical logic is added.

## Primary files

```text
client/client_Autopilot.lua
client/autopilot/Planner.lua (new)
client/client_Event.lua
core/internal/tasks/TaskQueue.lua (consumer only; no new queue system)
RPEngine_Dev.toc
```

## Work

- Detect an active Autopilot NPC actor/step on the host.
- Build stable plan identity from event/turn/tick/actor/schedule revision.
- Prevent duplicate planning from repeated state/UI refreshes.
- Allocate lightweight planning state synchronously and immediately enqueue `Tasks:EnqueueSliceable()`.
- Implement resumable phases/cursors without tactical scoring yet.
- Add `Tasks:ShouldYield(deadlineMs)` checks to all loops in the skeleton.
- Add job scope `autopilot:<eventId>` or narrower equivalent.
- Add `isStale` checks for event/turn/tick/actor/schedule changes.
- Add `onCancel` cleanup which publishes no partial plan.
- Add `onComplete` seam which may publish an empty/test plan but executes nothing.
- Cancel scope on event end and cancel replaced planning jobs.
- Add runtime statuses (`ready`, `planning`, `awaiting-authorization`, suspended/failed variants).

## Acceptance

- Turn transition performs only small synchronous setup.
- A representative multi-step dummy planner visibly spans slices when forced large.
- Deadline checks yield correctly.
- Stale jobs cancel without publishing partial data.
- Planner completion cannot execute combat actions.

---

# 9. Task E — Explicit-Caster Canonical Spell Activation Snapshots

## Goal

Allow the planner to query the exact existing spell legality rules for an arbitrary NPC without manipulating Action Bar/controlled-unit UI state.

## Primary files

```text
client/spellcasting/Cooldowns.lua
client/spellcasting/Helpers.lua
client/client_Spellcasting.lua
client/client_Targeting.lua (if candidate resolution lives there)
```

## Work

- Extend activation snapshot APIs with an explicit `casterEventId` or equivalent internal caster option.
- Resolve the NPC's effective spell list.
- Preserve canonical cooldown, charge, GCD, condition, resource and target-policy evaluation.
- Support `includeTargetCandidates = true` for planner calls.
- Ensure this read-only activation path does not mutate `ControlledEventUnitId`, targeting UI state, cooldown state, costs or queued selections.
- Add tests comparing manual/controlled NPC activation results with explicit-caster results for the same caster/spell.

## Acceptance

- Planner can query any active NPC's spell legality directly.
- Read-only evaluation has no gameplay/UI side effects.
- Invalid/expensive/cooldown/condition-blocked spells are excluded by canonical logic.
- Manual spell activation behavior remains unchanged.

---

# 10. Task F — Damage/Healing Intent and Utility Evaluation

## Goal

Implement the lightweight deterministic spell cost-benefit layer independently of target-selection and movement code.

## Primary files

```text
client/autopilot/SpellEvaluator.lua (new)
client/autopilot/Planner.lua
```

## Work

- Inspect only spells resolved for the active NPC.
- Classify `damage` and `heal` intent from existing components/effects.
- Detect melee/ranged/spell damage type from damage components.
- Compute deterministic expected damage/healing without consuming combat RNG.
- Cap useful healing by missing health.
- Add projected-healing scratch ledger for same-cohort planning.
- Implement priority tiers:
  - ally <= 50% HP + meaningful legal heal → urgent healing outranks damage;
  - useful non-urgent healing may outrank low-value damage where appropriate;
  - otherwise choose damage.
- Add simple commitment tie-breaks for resource/cooldown/charge use.
- End comparisons with stable deterministic spellRef tie-breaking.
- Ignore unsupported pure-utility spells in the first tactical model unless attached to a selected damage/heal spell.

## Acceptance

- Critical injured ally selects healing when legal.
- Large overheal has reduced utility.
- Healthy combat defaults toward damage.
- Scoring is deterministic and does not mutate combat RNG/state.

---

# 11. Task G — Threat, Healing and AoE Target Selection

## Goal

Implement target selection against canonical candidate lists and cached event state.

## Primary files

```text
client/autopilot/TargetSelector.lua (new)
client/autopilot/Planner.lua
client/autopilot/Spatial.lua
```

## Work

- Single hostile target: threat descending, then relevant proximity, then eventID.
- All-zero threat fallback: nearest valid target where cached coordinates exist, otherwise eventID.
- Healing target: health fraction ascending, missing health descending, eventID.
- Incorporate projected-healing reservations when selecting later cohort heals.
- Offensive multi-target/AoE:
  - highest-threat legal primary;
  - remaining legal targets ordered by distance from primary;
  - stable fallback when some cached positions are unavailable;
  - obey existing `minTargets` / `maxTargets` / disposition policies.
- Multi-target healing ordered by projected need; avoid filling optional slots with full-health allies unless required.
- Structure all candidate loops so Planner can yield between target evaluations.

## Acceptance

- Clear highest-threat enemy is selected as primary.
- Equal/zero-threat ties are deterministic.
- AoE secondaries are nearest to the primary when coordinates exist.
- Most injured ally is the default healing target.
- Existing target policy counts/dispositions are never bypassed.

---

# 12. Task H — Five-Yard Melee and Shared Raid-Marker Movement Solver

## Goal

Turn chosen melee intent into one feasible shared marker recommendation without committing movement automatically.

## Primary files

```text
client/autopilot/Spatial.lua
client/autopilot/Planner.lua
client/autopilot/SpellEvaluator.lua
client/autopilot/TargetSelector.lua
```

## Work

- Define `MELEE_RANGE_YARDS = 5`.
- Treat `damageType = melee` as requiring <= 5-yard virtual distance.
- Create provisional actions before movement is finalized.
- Collect melee target positions for one marker cohort.
- Generate bounded anchor candidates: current marker, each target, centroid, pairwise midpoints.
- Score anchors by number/utility of feasible melee actions, summed distance, deterministic tie-break.
- Yield during candidate generation/scoring when needed.
- Re-evaluate only infeasible provisional melee actions at the selected anchor using the PDD fallback order.
- Produce a **movement proposal**, not a committed virtual position.
- Attach movement dependency IDs to spell actions requiring the proposal.

## Acceptance

- One cohort produces at most one marker movement proposal per plan.
- Compatible melee targets can be satisfied by one shared anchor.
- Incompatible targets cause deterministic fallback/re-evaluation.
- Proposed movement changes no virtual position until the DM confirms it.

---

# 13. Task I — Full Frozen Cohort Planner Integration

## Goal

Combine Tasks E-H into the production sliceable state machine and publish complete frozen plans without executing them.

## Primary files

```text
client/autopilot/Planner.lua
client/client_Autopilot.lua
client/autopilot/SpellEvaluator.lua
client/autopilot/TargetSelector.lua
client/autopilot/Spatial.lua
```

## Work

- Implement planning phases:
  - validate;
  - snapshot relevant units;
  - resolve spell refs;
  - canonical activation snapshots;
  - intent classification;
  - target evaluation;
  - provisional scoring;
  - shared-marker solve;
  - infeasible-melee fallback;
  - pending-record construction;
  - finalize.
- Cache per-plan spell definitions, activation state, health, distances, expected magnitudes and candidate ordering.
- Preserve one frozen pre-action snapshot for all cohort members.
- Produce one planned action per eligible cohort member where possible.
- Generate no-action/warning helper records when no viable decision exists.
- Ensure `onComplete` atomically publishes only the complete plan.
- Add explicit Replan API which cancels/replaces pending unexecuted plans only when requested by the DM.
- Add timing/debug labels and plan slice/yield metrics.

## Acceptance

- Large plans span frames without exceeding the supplied TaskQueue deadline by design.
- No partial pending actions appear before finalization.
- Cohort members use one baseline snapshot.
- Planner completion mutates no canonical combat state.
- Repeated state/UI refreshes do not duplicate a plan.

---

# 14. Task J — Pending Authorization Store and DM Helper Autopilot Controls

## Goal

Expose frozen plans as host-only operational controls in DM Helper.

## Dependency

Build on issue #101's DM Helper companion panel/provider seam.

## Primary files

```text
client/autopilot/Authorization.lua (new)
client/autopilot/Helper.lua (new)
client/client_Autopilot.lua
client/ui/widgets/widget_Event.lua
RPEngine_Dev.toc
```

## Work

- Add `PendingAutopilotAction` model/state store.
- Add stable action IDs and plan IDs.
- Spell statuses: pending, authorized, executing, completed, rejected, blocked, stale, failed.
- Movement statuses: pending, confirmed, skipped, stale.
- DM Helper displays planning status and pending rows.
- Add `Authorize`, `Reject`, `Authorize All`, `Replan Pending`.
- Add `Confirm Moved` and `Skip` for movement.
- On Confirm Moved, commit the proposed virtual marker position.
- Keep dependent melee spells blocked until movement is confirmed.
- On movement skip, mark dependent actions blocked/stale rather than pretending movement occurred.
- Keep planning/action metadata host-local; never send via `COMBAT_LOG`.
- Include current-turn resolved combat history through #101's provider model where appropriate.
- Mark old-step pending actions stale on turn/tick advance.

## Acceptance

- A completed plan creates pending rows only.
- No spell executes merely because the panel opens/refreshes.
- Every executable spell requires an explicit authorization action.
- Participants never receive planning/authorization rows.
- Movement position commits only after explicit confirmation.
- `Authorize All` remains a user-triggered operation and respects movement dependencies.

---

# 15. Task K — Explicit-Caster Authorized Execution and Integration Hardening

## Goal

Execute authorized pending actions exactly once through normal NPC spellcasting, with canonical revalidation and complete stale handling.

## Primary files

```text
client/autopilot/Authorization.lua
client/client_Autopilot.lua
client/spellcasting/Lifecycle.lua
client/spellcasting/Cooldowns.lua
client/client_Targeting.lua
client/client_Spellcasting.lua
server/server_Spellcasting.lua (only if lower-level reuse needs validation changes)
```

## Work

- Add shared lower-level explicit-caster execution API.
- Carry caster and target selections directly; do not rely on several outstanding `QueuedSpellTargetSelection` values.
- On authorization, revalidate:
  - event/turn/tick/schedule identity;
  - host permission;
  - caster alive/active/eligible;
  - movement dependency;
  - spell activation/cost/cooldown/conditions;
  - target legality/alive state.
- Mark `authorized` / `executing` before entering lifecycle to prevent double execution.
- Execute as ordinary `authorityType = npc` through existing start/complete/cast-time flow.
- Preserve normal resource costs, cooldowns, charges, auras, damage/healing, threat synchronization and combat log.
- Do not silently retarget invalidated actions.
- Make repeated clicks, UI refreshes and duplicate state delivery idempotent.
- `Authorize All` executes in stable cohort order and revalidates each action independently.
- Cancel/stale all remaining pending work on event/step change.
- Add end-to-end test coverage and timing/debug instrumentation.

## Acceptance

- Authorizing one action executes exactly once.
- Rejecting executes nothing.
- Two NPCs can use the same spell with different target selections safely.
- Invalidated actions become stale/failed, not silently retargeted.
- Authorized actions behave identically to manually controlled NPC casts after they enter the normal lifecycle.
- Manual casting and manual events remain unchanged.

---

# 16. Cross-Cutting Test Requirements

Each task should add focused tests where the repository's current test structure allows it. Before declaring the full feature complete, exercise the PDD test matrix across these groups:

## Scheduling

- unmarked NPCs;
- marker cohorts;
- mixed player/NPC actors;
- oversized cohort;
- equal initiative;
- inactive/dead members;
- player shared-turn pets.

## Coordinates

- initial seed;
- local and remote player turn-end refresh;
- only one cache record changes;
- missing token/coordinate;
- token remapping;
- different instanceID;
- restricted instance.

## Sliceable planning

- one-slice small plan;
- multi-slice large plan;
- deadline yielding in spell and target loops;
- cancellation on event/turn change;
- no partial publication;
- no combat mutation on completion.

## Decision policy

- urgent healing;
- useful healing/overheal;
- damage fallback;
- cooldown/resource/condition invalidity;
- threat targeting;
- zero/equal threat;
- AoE proximity;
- melee marker solve;
- incompatible marker targets.

## Authorization

- individual authorize/reject;
- Authorize All;
- movement confirm/skip;
- blocked movement-dependent action;
- target dies before authorization;
- resource/cooldown state changes before authorization;
- repeated click/idempotence;
- Replan Pending;
- step advances with pending actions.

## UI/security

- host-only DM Helper;
- participant-safe Combat Log;
- no DM planning data sent over combat-log traffic;
- visible instance warning;
- manual event has no Autopilot side effects.

---

# 17. Completion Definition

NPC Autopilot is complete when:

1. Autopilot mode can be selected for an outdoor event and is explicitly rejected in restricted instances.
2. Same-marker NPCs form atomic scheduled cohorts while manual events remain unchanged.
3. Player coordinates are seeded once and refreshed only for the player whose turn ends.
4. NPC planning uses only cached coordinates and the existing sliceable TaskQueue.
5. Planner output is deterministic, frozen and combat-state-free.
6. The host receives movement and spell proposals in DM Helper.
7. Every proposed spell remains pending until explicit authorization.
8. Proposed movement is not committed until explicitly confirmed.
9. Authorized actions are revalidated and execute exactly once through the normal NPC spell lifecycle.
10. Participant clients never receive DM-only planning data.
11. Representative large cohorts produce no visible planning hitch and planner slices respect the existing queue deadline.
