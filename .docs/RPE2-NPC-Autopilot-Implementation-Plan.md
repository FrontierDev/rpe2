# RPE 2 — NPC Autopilot and DM Helper
## Implementation Plan

**Status:** Proposed implementation sequence  
**Target:** RPEngine 2.0 (`FrontierDev/rpe2`)  
**Source design:** `.docs/RPE2-NPC-Autopilot-PDD.md`  
**Related existing issues:** #100 Combat Log history, #101 DM Helper, #113–#123 NPC Autopilot implementation tasks  

---

# 1. Objective

Implement NPC Autopilot as a host-authoritative, sliceable **planning** system which:

- groups NPCs sharing a raid marker into one atomic TurnActor;
- treats one raid marker as one spatially indivisible virtual actor;
- never gives marked cohort members divergent hidden positions;
- caches player positions at event start and refreshes one player's position only when that player ends their turn;
- evaluates existing NPC spells and legal targets without duplicating spell legality rules;
- reuses existing RPE movement-range and AuraManager control state;
- constrains a marked cohort by its least-mobile active member;
- pins the entire marked cohort if any active member has effective movement allowance zero;
- jointly chooses one reachable shared marker anchor and one useful action per cohort member;
- publishes proposed movement and spell actions to the host-only DM Helper;
- places every executable NPC action into Pending Authorization;
- executes nothing until explicitly authorized by the DM;
- commits no virtual movement until the DM explicitly confirms it;
- routes authorized actions through the existing NPC spell lifecycle;
- uses `Tasks:EnqueueSliceable()` and `Tasks:ShouldYield(deadlineMs)` for all non-trivial planning work;
- does not support Autopilot inside Blizzard instances.

Manual events must remain behaviorally unchanged.

---

# 2. Non-Negotiable Architectural Constraints

1. **Planning is not execution.** Planner completion may create pending records and refresh DM Helper, but may not cast spells, spend resources, consume charges, start cooldowns, apply effects or commit proposed movement.
2. **Every NPC spell requires explicit DM authorization.** Bulk authorization is permitted only as an explicit DM action.
3. **Movement is also DM-controlled.** A proposed virtual marker position is committed only after `Confirm Moved`.
4. **Marked cohorts never split.** One non-zero raid marker maps to one TurnActor and one virtual coordinate. No hidden member positions may diverge while members share the marker.
5. **The least-mobile member constrains the marker.** Resolve effective movement allowance for every active marked member and use the most restrictive result for the shared movement.
6. **Existing movement/control state is authoritative.** Reuse the existing movement-range source and `AuraManager:BuildControlState(...).movementRangeOverride`; do not create a second root/snare model.
7. **Zero movement pins the whole marker.** If any active marked member has effective movement allowance zero, the current marker position is the only legal anchor.
8. **Player positions are cached.** Seed once when the event starts; subsequently sample only the player whose turn has just ended.
9. **NPC planning never performs a full party/raid coordinate rescan.** Missing cached coordinates are handled explicitly rather than silently refreshed or guessed.
10. **All planner work is sliceable.** Do not use a normal deferred task containing an indivisible full-cohort planner.
11. **Planner loops honor the queue deadline.** Candidate-spell, target, AoE, movement-control, anchor-generation and per-anchor cohort-scoring loops must call `Tasks:ShouldYield(deadlineMs)` at resumable boundaries.
12. **Canonical spell activation remains authoritative.** Cooldowns, charges, GCD, resources, conditions and target legality must come from the existing spellcasting runtime.
13. **Autopilot does not duplicate combat execution.** Authorized actions converge on the normal NPC spell lifecycle.
14. **Same-marker NPCs plan from one frozen snapshot.** Later actions are not tactically re-scored because an earlier authorized action happened to resolve first.
15. **No automatic retargeting or replanning on authorization failure.** Invalidated pending actions become stale/failed; the DM explicitly requests a replan.
16. **Autopilot is unavailable in restricted instances.** Never fabricate coordinates.

---

# 3. Existing Code Paths to Reuse

## Event state and turn lifecycle

```text
core/classes/Event.lua
core/classes/EventUnit.lua
server/server_Event.lua
client/client_Event.lua
client/spellcasting/Helpers.lua
```

Reuse synchronized `turnNumber`, `tickNumber`, `totalTicks` and existing stale-work/turn-commit patterns.

## Task scheduling

Use the existing queue:

```lua
Tasks:EnqueueSliceable(options)
Tasks:ShouldYield(deadlineMs)
Tasks:Cancel(jobOrId, reason)
Tasks:CancelScope(scope, reason)
```

Do not increase the global TaskQueue budget to accommodate Autopilot.

## Spell legality and lifecycle

```text
client/spellcasting/Cooldowns.lua
client/spellcasting/Helpers.lua
client/spellcasting/Lifecycle.lua
client/client_Targeting.lua
client/client_Spellcasting.lua
```

Extend activation snapshots to support explicit NPC casters rather than implementing separate cooldown/resource/condition checks.

## Movement and control state

Reuse:

```text
core/internal/Movement.lua
core/internal/profile/Profile.lua
client/spellcasting/AuraManager.lua
```

The existing movement system already resolves a configured movement range and applies the active aura `movementRangeOverride` where present. `AuraManager:BuildControlState(eventState, unitEventId)` is the per-EventUnit control-state source of truth.

Autopilot may add an EventUnit-aware effective movement allowance helper, but it must be a reuse/generalization of these semantics rather than a separate movement ruleset.

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

# 4. Delivery Sequence

```text
#113 Event mode + capability UI
        ↓
#114 TurnActor / TurnStep scheduling
        ↓
#115 Host position cache + one-coordinate spatial runtime
        ↓
#116 Autopilot runtime + sliceable planner skeleton
        ↓
#117 Explicit-caster activation snapshots
        ↓
#118 Spell utility evaluator
        ↓
#119 Target selectors
        ↓
#120 Shared-marker movement/control solver
        ↓
#121 Full frozen-plan integration
        ↓
#122 Pending authorization + DM Helper controls
        ↓
#123 Authorized execution + integration hardening
```

Issue #101 is a prerequisite for the final DM Helper authorization presentation, but planner/runtime work can proceed independently once its provider seam is understood.

---

# 5. Task A — Issue #113: Event Autopilot Mode and Instance Capability

## Goal

Add synchronized Event-level Autopilot mode without changing manual event semantics.

## Work

- Add normalized `turnMode` with `manual` and `autopilot`.
- Default legacy/missing values to `manual`.
- Add backward-tolerant network serialization/deserialization.
- Add Event Manager Autopilot control and explicit no-instance warning.
- Block Autopilot start when coordinate capability is unavailable or restricted.
- Preserve manual start behavior.
- Expose reusable capability helpers for later runtime code.

## Acceptance

- Old events/network payloads remain manual.
- Manual events are unchanged.
- Every client receives the same mode.
- Autopilot cannot silently start in restricted instances.

---

# 6. Task B — Issue #114: Mode-Aware TurnActor and TurnStep Scheduling

## Goal

Create deterministic raid-marker cohort scheduling without coupling Autopilot eligibility to fixed visual pages.

## Work

- Players remain singleton actors; shared-turn pets retain existing semantics.
- NPCs with the same non-zero `raidMarker` form one actor.
- `raidMarker == 0` NPCs remain singleton actors.
- Cohort initiative is the maximum active-member initiative.
- Pack actors into TurnSteps without splitting an actor.
- Permit oversized marker cohorts to occupy one oversized step.
- Add mode-aware schedule/eligibility helpers.
- Keep visual pagination independent from Autopilot eligibility.

## Acceptance

- Same-marker NPCs are always eligible together.
- Unmarked NPCs do not collapse into one cohort.
- Oversized cohorts are never split.
- Manual mode retains existing behavior.

---

# 7. Task C — Issue #115: Host Position Cache and Indivisible Spatial Runtime

## Goal

Provide stable event-local coordinates without polling or rescanning at NPC planning time.

## Work

- Add host-only event runtime container.
- Resolve player names to group unit tokens.
- Seed player positions once on Autopilot event start.
- On completed player turn, update only that player's cache entry.
- Add virtual positions keyed by `marker:<raidMarker>` or `unit:<eventID>`.
- For marked NPCs, store **only the marker actor coordinate**; do not create divergent member coordinates.
- Add pure 2D distance/vector helpers.
- Handle missing coordinates/capability loss explicitly.
- Clear spatial state on event teardown.

## Acceptance

- One completed player turn modifies only that player's coordinate record.
- NPC turns do not rescan all player positions.
- One marked cohort has exactly one coordinate.
- The runtime provides no mechanism for marked members to split spatially.

---

# 8. Task D — Issue #116: Runtime Coordinator and Sliceable Planner Skeleton

## Goal

Establish lifecycle, idempotence and resumable planning infrastructure before tactical logic is added.

## Work

- Detect active Autopilot NPC actor/step on the host.
- Build stable plan identity from event/turn/tick/actor/schedule revision.
- Prevent duplicate planning from repeated state/UI refreshes.
- Allocate lightweight state synchronously and immediately enqueue `Tasks:EnqueueSliceable()`.
- Implement resumable phases/cursors.
- Add deadline checks to repeated work.
- Add scoped cancellation and stale checks.
- Ensure `onCancel` publishes nothing partial.
- Ensure `onComplete` can publish data but executes nothing.

## Acceptance

- Turn transitions perform only small synchronous setup.
- Forced-large dummy planning spans slices.
- Stale jobs cancel cleanly.
- Planner completion cannot execute combat or commit movement.

---

# 9. Task E — Issue #117: Explicit-Caster Canonical Activation Snapshots

## Goal

Allow the planner to query canonical spell legality for any active NPC without manipulating Action Bar/controlled-unit UI state.

## Work

- Add explicit `casterEventId` or equivalent internal caster option.
- Preserve cooldown, charge, GCD, condition, resource and target-policy evaluation.
- Support target-candidate retrieval for planner calls.
- Keep the activation query read-only.
- Compare explicit-caster results against existing manual/controlled NPC results.

## Acceptance

- Planner can query arbitrary active NPC legality.
- Evaluation mutates no gameplay/UI state.
- Manual activation behavior remains unchanged.

---

# 10. Task F — Issue #118: Damage/Healing Intent and Utility

## Goal

Implement the deterministic tactical utility layer independently of movement placement.

## Work

- Inspect only resolved NPC spells.
- Classify damage/heal intent from existing components.
- Detect melee/ranged/spell damage type from existing damage components.
- Compute deterministic expected damage/healing without combat RNG.
- Cap useful healing by missing health.
- Implement urgent healing and normal damage/heal priority.
- Add projected-healing scratch reservations.
- Add stable commitment/tie-break logic.

## Acceptance

- Critical injured allies select legal healing.
- Overheal is discounted.
- Healthy combat defaults toward damage.
- Scoring is deterministic and read-only.

---

# 11. Task G — Issue #119: Threat, Healing and AoE Target Selection

## Goal

Implement deterministic target selection against canonical candidate lists and cached event state.

## Work

- Hostile single target: threat descending, then relevant proximity, then eventID.
- All-zero threat fallback: nearest where coordinates exist, otherwise eventID.
- Healing: health fraction, missing health, eventID.
- Apply projected-healing reservations for later same-cohort heals.
- Offensive AoE: highest-threat primary, then nearest legal secondary targets.
- Multi-heal: projected need; avoid optional full-health targets.
- Keep loops resumable/yieldable.

## Acceptance

- Threat, healing and AoE choices are stable and deterministic.
- Existing target policies are never bypassed.

---

# 12. Task H — Issue #120: Joint Shared-Marker Movement and Control Solver

## Goal

Choose one reachable marker destination and one useful action per marked cohort member without allowing the group to split.

## Work

### Melee geometry

- Define `MELEE_RANGE_YARDS = 5`.
- `damageType = melee` requires target distance <= 5 yards.
- Ranged/spell damage does not require melee placement.

### Effective movement allowance

- Resolve the existing movement-range value for each active EventUnit.
- Apply current AuraManager control state, including `movementRangeOverride`.
- Do not add an Autopilot-only rooted/snare flag.
- Resolve:

```text
cohortMovementAllowance = minimum(active member effective movement allowances)
```

- If any active member resolves to zero movement, pin the entire marker to its current position.
- Positive restrictive movement values limit the shared marker's maximum displacement.

### Joint action + anchor solver

Do **not** let one provisional melee action choose the marker location and repair everyone else afterwards.

Instead:

1. generate a bounded set of plausible legal actions/targets for each member;
2. generate bounded combat-relevant marker anchors;
3. reject anchors outside cohort movement allowance;
4. at each anchor, choose every member's best feasible action from that same position;
5. aggregate whole-cohort utility;
6. select one anchor and one action per member.

Candidate anchors may include current position, relevant target positions, centroids and bounded pairwise midpoint/intersection-like candidates.

### Heuristic

Prefer:

1. higher aggregate cohort utility;
2. more members receiving useful actions;
3. current position when tactically equivalent;
4. lower movement distance;
5. stable coordinate/target tie-break.

Use a small movement/stability penalty to avoid needless marker churn.

### No-split fallback

If movement is impossible or an ideal target is unreachable, change the affected NPC's action:

```text
another in-range melee target
→ ranged/spell damage
→ useful heal
→ no action
```

Never move part of the marked cohort separately.

### Sliceability

Anchor generation, movement-state resolution and per-anchor cohort scoring must yield/resume inside the sliceable planner.

### Output

Produce at most one **pending movement proposal** for the marker. Do not commit it. Attach dependency IDs to actions requiring that destination.

## Acceptance

- Marked members always share one coordinate.
- One immobilized member pins the entire marker.
- Positive restrictions constrain the whole marker to the least-mobile member.
- No split solution can be generated.
- The chosen anchor maximizes aggregate cohort usefulness rather than one member's preferred target.
- Current position wins near-ties where movement adds no material benefit.
- Solver is fully sliceable.
- Planning commits no movement.

---

# 13. Task I — Issue #121: Full Frozen Cohort Planner Integration

## Goal

Combine Tasks E–H into the production sliceable planner and atomically publish complete frozen plans.

## Work

Implement phases such as:

```text
validate
snapshot relevant units
resolve spell refs
resolve canonical activation snapshots
classify utility
evaluate target candidates
resolve per-member movement/control state
resolve cohort movement allowance
generate reachable marker anchors
evaluate whole-cohort actions per anchor
select shared anchor + member actions
build pending records
finalize
```

The frozen snapshot must contain current aura/control movement state, effective per-member movement allowance, cohort movement allowance, cached player positions and committed actor positions.

Per-plan caches should cover spells, activation state, health, movement/control state, distances, target ordering, anchors and per-anchor scores.

Final output contains:

- zero or one movement proposal for a marked actor;
- one planned spell action per useful eligible NPC;
- dependency links;
- no-action/warning records;
- blocked-movement explanation where useful;
- stable identity.

`onComplete` publishes the plan and returns. It does not cast or commit movement.

## Acceptance

- Same-marker NPCs share one snapshot and one spatial coordinate.
- Pinned/restricted movement is reflected in anchor feasibility.
- Whole-cohort utility determines marker placement.
- Large plans span queue slices cleanly.
- No partial plan is published.
- Planner completion mutates no combat/spatial state.

---

# 14. Task J — Issue #122: Pending Authorization and DM Helper Controls

## Goal

Expose frozen plans to the host and keep both movement and spell execution explicitly DM-controlled.

## Work

- Add stable pending spell/movement records.
- Render planning status, movement recommendations, blocked-movement explanations and spell rows in DM Helper.
- Add `Authorize`, `Reject`, `Authorize All`, `Replan Pending`, `Confirm Moved`, `Skip`.
- Movement proposal remains uncommitted while pending.
- A movement-dependent spell cannot be authorized until movement is confirmed.
- `Confirm Moved` must revalidate current event/turn/actor identity and **current effective movement allowance for every active marked member**.
- Recompute the least-mobile cohort allowance before committing.
- If a member is newly immobilized or the destination is no longer reachable, do not commit; mark movement/dependent actions blocked/stale.
- Confirming movement commits exactly one marker coordinate for the whole cohort.
- Removing a movement restriction does not silently improve an existing proposal; DM may explicitly replan.
- Planning/authorization data remains host-only.

## Acceptance

- No generated action executes automatically.
- Marked cohorts cannot split during movement confirmation.
- Newly applied zero-movement control prevents stale movement confirmation.
- Skip/reject executes nothing.
- Replan is explicit.

---

# 15. Task K — Issue #123: Authorized NPC Spell Execution

## Goal

Add the only Autopilot path allowed to mutate combat state: explicit-DM-authorized execution through normal NPC spellcasting.

## Work

- Add shared explicit-caster execution facade.
- Revalidate event/turn/tick/caster/spell/targets/resources/charges/cooldowns/conditions at authorization time.
- Require confirmed movement dependency where applicable.
- Carry explicit target selections rather than relying on the single mutable manual targeting queue.
- Transition pending action to executing atomically before lifecycle entry.
- Reject repeated authorization clicks.
- Reuse normal NPC authority, costs, cooldowns, effects, auras, threat, resource sync and combat log.
- Authorize All processes stable member order and revalidates every action independently.
- Do not silently retarget or replan an invalid action.

## Acceptance

- One authorization executes exactly once.
- Two NPCs can use the same spellRef against different targets safely.
- Invalidated targets become stale rather than retargeted.
- Manual NPC spellcasting remains unchanged.

---

# 16. Required Deterministic Validation

Each implementation issue should include focused pure/mock tests where possible before moving to the next issue.

## Scheduling

- marked cohorts remain atomic;
- oversized cohort remains one step;
- manual mode unchanged.

## Position cache

- only completed player position changes;
- no NPC-step rescan;
- marked cohort has one position only.

## Movement/control

- no control aura;
- positive movement restriction;
- least-mobile member constrains cohort;
- `movementRangeOverride = 0` pins whole marked cohort;
- no hidden split positions;
- unreachable anchor rejected;
- stay-put near-tie preference;
- whole-cohort anchor beats a one-NPC-biased anchor;
- candidate/anchor loops yield correctly.

## Planner

- small plan one slice;
- large plan several slices;
- stale cancellation;
- no partial publication;
- no mutation on completion.

## Authorization

- movement confirmation revalidates current control state;
- newly rooted member blocks movement;
- Confirm Moved changes one marker coordinate only;
- Skip blocks dependencies;
- repeated authorize cannot double execute.

---

# 17. Live WoW Validation Gates

Some behavior cannot be fully proven outside WoW. After relevant implementation tasks, perform concise live checks for:

- group token/`UnitPosition` behavior outdoors;
- Event Manager warning and mode UI;
- actual player turn-end coordinate refresh;
- DM Helper layout/interaction;
- movement-control aura behavior with a marked cohort;
- authorized NPC spell lifecycle and participant synchronization.

Do not use live-only uncertainty as a reason to skip deterministic repository/mock validation first.

---

# 18. Definition of Done for the Full Feature

The Autopilot sequence is complete only when:

- manual events remain behaviorally unchanged;
- restricted instance start is blocked clearly;
- player coordinates update only at initial seed and that player's turn end;
- marked cohorts are atomic in scheduling and **spatially indivisible**;
- one marked cohort has exactly one virtual coordinate;
- existing movement/control state constrains shared movement;
- one immobilized marked member pins the whole cohort;
- the marker solver jointly optimizes the whole cohort's actions and location;
- no planner work introduces visible synchronous hitching;
- all non-trivial planner work is sliceable;
- planning creates pending actions only;
- movement commits only after explicit, revalidated DM confirmation;
- spells execute only after explicit DM authorization;
- authorized spells use the ordinary RPE NPC lifecycle;
- participants never receive DM-only planning metadata.
