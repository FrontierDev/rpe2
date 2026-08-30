# RPE 2 — NPC Autopilot and DM Helper
## Product Design Document

**Status:** Proposed  
**Target:** RPEngine 2.0 (`FrontierDev/rpe2`)  
**Scope:** Host-authoritative NPC planning, raid-marker cohort turns, cached player positions, host-side spatial simulation, spell/target selection, pending-action authorization, DM Helper UI, sliceable planning work  
**Primary objective:** Let RPE automatically determine sensible NPC actions while keeping every gameplay action under explicit DM authorization  
**Related issues:** #100 Combat Log history, #101 host-only DM Helper  
**Out of scope:** Blizzard instance support, automatic NPC action execution without DM authorization, pathfinding, collision/obstacle simulation, exact WoW hitboxes, player autopilot, LLM decision-making, authored behavior trees

---

# 1. Purpose

RPE events currently require the event host to manually determine NPC movement, choose NPC spells, choose targets, and then execute those actions. For events with several NPCs this creates repetitive DM workload.

NPC Autopilot should remove the repetitive **decision-making** without removing DM control.

The system is therefore a planner, not a fully automatic combat bot.

The intended flow is:

```text
Player finishes moving/acting
        ↓
Host updates that player's cached position
        ↓
NPC cohort turn becomes active
        ↓
Sliceable autopilot planning job starts
        ↓
Planner chooses movement recommendations, spells and targets
        ↓
Plan is published to DM Helper
        ↓
Every executable NPC action enters Pending Authorization
        ↓
DM reviews each action
        ↓
DM authorizes or rejects actions
        ↓
Only authorized actions execute through normal RPE spellcasting
        ↓
DM advances the event when ready
```

Example DM Helper output:

```text
Move {cross} near Player A, Player B.              [Confirm Moved] [Skip]
[NPC 1] attacks Player A with [Cleave].            [Authorize] [Reject]
[NPC 2] attacks Player B with [Fire Bolt].         [Authorize] [Reject]
[NPC 3] heals [NPC 1] with [Mend].                 [Authorize] [Reject]
```

The planner should make common NPC decisions predictable:

- urgent healing outranks damage;
- otherwise NPCs generally attack;
- hostile targets are primarily selected by threat;
- AoE spells begin with the highest-threat target and select nearby secondary targets;
- melee planning uses a 5-yard spatial rule inferred from existing spell components;
- NPCs sharing a raid marker act as one cohort;
- every cohort is planned from one frozen pre-action snapshot;
- no planned spell action executes until the DM explicitly authorizes it.

---

# 2. Core Product Principles

## 2.1 Autopilot plans; the DM authorizes

Autopilot may automatically:

- detect that an NPC cohort is active;
- build a planning snapshot;
- evaluate legal NPC spells;
- choose targets;
- propose shared raid-marker movement;
- populate the DM Helper.

Autopilot must **not** automatically:

- start a spellcast;
- complete an instant spell;
- spend a resource;
- consume a charge;
- start a cooldown;
- apply damage or healing;
- apply or remove an aura;
- update threat as the result of a planned action;
- commit a virtual marker move which the DM has not confirmed.

Canonical gameplay state changes only after explicit DM authorization.

---

## 2.2 DM Helper replaces Turn Summary

The host-only surface previously described as **Turn Summary** is renamed **DM Helper**.

Expected event-widget controls:

```text
Participant: [ Combat Log ]
Host:        [ Combat Log ] [ DM Helper ]
```

DM Helper is not merely a filtered combat log. It is the host's current-turn operational panel containing:

- autopilot planning status;
- movement recommendations;
- pending NPC actions;
- authorization controls;
- rejected/stale/completed action state;
- current-turn combat history where useful.

Issue #101 should use this name and responsibility.

---

## 2.3 Host authority

Only the event host computes and stores autopilot plans.

Participant clients must not independently:

- evaluate NPC spell utility;
- select NPC targets;
- solve virtual marker positions;
- construct pending-autopilot actions;
- authorize NPC actions;
- receive DM-only movement instructions.

After authorization, the resulting spell is still an ordinary host-controlled NPC spellcast and uses existing RPE synchronization.

---

## 2.4 Manual events remain unchanged

Autopilot is an explicit event mode because it changes NPC turn grouping and adds host planning behavior.

Manual mode must retain the current event scheduling and NPC-control behavior.

For the initial implementation, the mode is fixed when the event starts. Live conversion between manual and autopilot scheduling is out of scope because it can invalidate turn/tick, cast, aura and cooldown state.

---

# 3. Explicit Instance Restriction

NPC Autopilot requires party/raid world coordinates and therefore does not work in Blizzard instances where the necessary position data is unavailable/restricted.

The Event Manager must display an explicit warning whenever Autopilot is selected:

> **NPC Autopilot does not work in instances. Use Manual mode in dungeons, raids, battlegrounds and arenas.**

The restriction must not be hidden only in a tooltip.

On event start:

```text
Autopilot selected
        ↓
coordinate capability unavailable / instanced
        ↓
block Autopilot start
        ↓
explain that Manual mode is required
```

RPE must never invent coordinates.

If required position capability becomes unavailable after an event starts, planning is suspended. Existing pending actions remain visible but cannot be newly authorized when their spatial assumptions can no longer be validated.

---

# 4. Current Codebase Findings

The current repository already provides most of the runtime foundations required by this design.

## 4.1 Event turn identity

`core/classes/Event.lua` stores and synchronizes:

```lua
turnNumber
tickNumber
totalTicks
```

`client/client_Event.lua` already guards turn-sensitive deferred work against stale event/turn/tick identity.

Autopilot should use these synchronized identities. It must not create a parallel NPC turn counter.

---

## 4.2 Current turn eligibility is page-based

Current spellcaster eligibility is effectively coupled to Event unit pages through:

```lua
Spellcasting.GetUnitPageIndex(...)
Spellcasting.IsCasterTurnOnTick(...)
Event.GetUnitPageIndex(...)
```

This means the current model approximately treats:

```text
visual unit page = event tick = spellcast eligibility group
```

Autopilot requires an explicit turn schedule because a raid-marker cohort must never be split across two ticks.

---

## 4.3 Raid marker and threat state already exist

`EventUnit` already contains:

```lua
raidMarker
threatTable
```

Threat is generated by the normal combat path and synchronized with resource-delta traffic. Autopilot should read this state rather than creating another aggro system.

---

## 4.4 Existing spell activation logic should remain canonical

The spellcasting runtime already resolves:

- cooldowns;
- charges;
- global cooldown;
- conditions;
- resource affordability;
- target policies;
- target candidates.

Autopilot must reuse canonical activation-snapshot logic rather than duplicating these checks inside the planner.

---

## 4.5 Current queued target selection is not a sufficient multi-NPC API

Manual targeting currently uses one mutable queued target-selection state. Several same-cohort NPCs can select the same spell with different targets, so autopilot plans cannot safely be represented as several outstanding values in one shared UI queue.

A lower-level explicit-caster execution API is still required, but it is invoked only after authorization.

---

## 4.6 Sliceable TaskQueue support already exists

`core/internal/tasks/TaskQueue.lua` already provides:

```lua
Tasks:EnqueueSliceable(options)
Tasks:ShouldYield(deadlineMs)
Tasks:Cancel(jobOrId, reason)
Tasks:CancelScope(scope, reason)
```

A sliceable job supports:

```text
state
step(state, deadlineMs, job)
scope
isStale / staleCheck
onComplete
onCancel
```

The queue currently defaults to an approximately 2 ms task/slice time budget.

NPC planning must use this sliceable path directly. A normal `Tasks:Enqueue(function() planWholeCohort() end)` job is not sufficient because a deferred but indivisible planner can still hitch the frame.

---

# 5. Event Turn Mode

Add a normalized Event field:

```lua
turnMode = "manual"
```

Allowed values:

```text
manual
autopilot
```

Legacy events and older network payloads normalize to `manual`.

The mode must be synchronized because all clients need to agree on unit turn eligibility even though only the host runs the planner.

Use backward-tolerant trailing network fields where practical.

---

# 6. Raid-Marker Cohort Turn Scheduling

All active NPC EventUnits with the same non-zero `raidMarker` form one atomic scheduling actor.

Example:

```text
NPC 1   cross
NPC 2   cross
NPC 3   cross

→ one marker cohort
→ all become eligible on the same event step
→ all are planned from one snapshot
→ one shared virtual marker position
```

`raidMarker = 0` does not group all unmarked NPCs. Each unmarked NPC is a singleton NPC actor.

Player-shared-turn pets retain their existing player-turn semantics.

---

## 6.1 TurnActor

Conceptual model:

```lua
TurnActor {
    key,
    kind,          -- player | npc_marker | npc
    initiative,
    raidMarker,
    unitEventIds,
}
```

Actor construction:

```text
Player
    → singleton player actor

Player shared-turn pet
    → attached to existing player semantics

NPC raidMarker > 0
    → marker:<raidMarker>

NPC raidMarker == 0
    → npc:<eventID>
```

---

## 6.2 Cohort initiative

A marker cohort uses the highest initiative among its active members as its scheduling initiative.

Within the cohort, deterministic member order is:

```text
initiative descending
eventID ascending
```

This internal order is used for display, authorization-all ordering, and deterministic execution of already-authorized actions. It does not change the shared planning snapshot.

---

## 6.3 TurnStep packing

Manual mode keeps existing page/tick behavior.

Autopilot builds ordered actors and packs them into TurnSteps without splitting an actor.

Rules:

```text
Walk actors in initiative order.
Add an actor if it fits in the current target page capacity.
Otherwise start a new step.
Never split a marker cohort.
If a single marker cohort exceeds page capacity, give it one oversized step.
```

Introduce mode-aware helpers such as:

```lua
Event.BuildTurnSchedule(eventState)
Event.GetUnitTurnStepIndex(eventState, eventId)
Event.GetUnitsForTurnStep(eventState, tickNumber)
```

`Spellcasting.IsCasterTurnOnTick()` should use the autopilot schedule when `turnMode == "autopilot"`.

Visual pagination must not redefine eligibility for an oversized cohort.

---

# 7. Player Position Cache

Player positions do **not** need to be recomputed when an NPC plan starts.

RPE movement rules already prevent a player from moving outside their own turn. Therefore a player's position is stable from the instant their turn ends until their next turn.

The host should cache this stable position.

---

## 7.1 Position refresh events

Coordinates are acquired only at these lifecycle points:

```text
1. Event initialization
   → seed one initial position for each resolvable player.

2. A player ends their turn
   → resolve that player's current party/raid unit token.
   → call UnitPosition once for that player.
   → replace only that player's cached position.
```

Autopilot planning must **not** rescan all players or call `UnitPosition()` for every player every time an NPC cohort becomes active.

There is no continuous polling.

There is no per-frame coordinate work.

---

## 7.2 Turn-end integration

`client/client_Event.lua` already has player-turn-end handling around `TurnEndPending`, `FlushPendingTurnChanges(...)`, and the Movement tracker's `OnPlayerTurnEnd()` hook.

The host-side position cache should integrate with the authoritative turn transition rather than creating another movement observer.

For the local player on the host client, the cache can be updated directly as the local turn ends.

For another player, the host updates that player's coordinate when it receives/commits the authoritative event-step transition showing that the player's actor has finished.

This produces one coordinate sample per completed player turn.

---

## 7.3 Position cache model

```lua
playerPositionByEventId[eventID] = {
    x = ...,
    y = ...,
    instanceID = ...,
    sampledTurnNumber = ...,
    sampledTickNumber = ...,
}
```

The cache is event-local and non-persistent.

If the player's group token changes, token mapping may be refreshed, but coordinates are still sampled at event initialization or turn end rather than continuously.

---

## 7.4 Missing positions

If a required player has no valid cached coordinate:

- do not guess;
- do not automatically resample during planning;
- exclude the target from calculations that require a position;
- if no viable spatial plan remains, publish a DM Helper warning/no-action state.

Non-spatial spell decisions may still be legal if they do not require the missing coordinate.

---

# 8. Host Virtual NPC Spatial Model

Autopilot combines cached real-player positions with host-local virtual NPC positions.

For marked NPCs, position belongs to the marker actor:

```text
raidMarker > 0 → marker:<raidMarker>
raidMarker == 0 → unit:<eventID>
```

All members of one marker cohort therefore share one virtual coordinate.

Example runtime:

```lua
AutopilotRuntimeByEventId[eventId] = {
    status = "ready",
    playerPositionByEventId = {},
    positionByActorKey = {},
    planByStepKey = {},
    pendingActionsById = {},
    pendingActionOrder = {},
}
```

Use two-dimensional Euclidean distance in yards.

The model intentionally does not attempt pathfinding, obstacles, terrain or line of sight.

---

# 9. Planning Snapshot

When an NPC actor/cohort becomes active, planning begins from one frozen logical snapshot.

The snapshot includes at minimum:

```text
eventId
turnNumber
tickNumber
actor key
active/dead state
teams
current/max resources
threat tables
resolved NPC spell refs
cooldown/charge state
conditions and affordability required by activation snapshots
active auras relevant to legality
cached player positions
virtual NPC/marker positions
```

Planning must not mutate canonical combat state.

Same-marker members are evaluated against this same baseline.

---

# 10. Sliceable Planning Architecture

Planning is always performed through `Tasks:EnqueueSliceable`.

No complete cohort planner may run synchronously from the EVENT_STATE handler or EventWidget refresh path.

---

## 10.1 Minimal synchronous work

When a new NPC step becomes active, synchronous work should be limited to:

```text
validate event/host/autopilot mode
build plan identity
detect whether a plan already exists
allocate lightweight planning state
enqueue one sliceable planning job
return
```

Do not resolve every spell or target synchronously before enqueueing the job.

---

## 10.2 Job identity and scope

Recommended identity:

```text
eventId : turnNumber : tickNumber : actorKey/scheduleRevision
```

Recommended scope:

```text
autopilot:<eventId>
```

or a narrower plan-specific scope where useful.

The job state holds cursors rather than relying on one long loop:

```lua
{
    eventId,
    turnNumber,
    tickNumber,
    actorKey,
    actorIndex,
    npcIndex,
    spellIndex,
    targetIndex,
    phase,
    snapshot,
    scratch,
    provisionalActions,
}
```

---

## 10.3 Planning phases

A planning job should advance incrementally through phases such as:

```text
validate
snapshot relevant units
resolve candidate spell refs
resolve canonical activation snapshots
classify spell intent
evaluate targets
score provisional actions
solve shared marker position
re-evaluate infeasible melee actions
build pending authorization records
finalize
```

Each phase must be resumable.

---

## 10.4 Yield discipline

Inside potentially repeated loops, use the supplied slice deadline:

```lua
step = function(state, deadlineMs, job)
    while state.spellIndex <= #state.spells do
        evaluateOneCandidate(...)
        state.spellIndex = state.spellIndex + 1

        if Tasks:ShouldYield(deadlineMs) then
            return false
        end
    end

    return true
end
```

The planner should normally stay within the queue's existing ~2 ms slice budget.

Do not raise the global TaskQueue time budget to make autopilot fit.

---

## 10.5 Stale checks

Use `isStale`/`staleCheck` to cancel work when:

```text
event ended
event changed
turn changed
tick changed
autopilot mode changed / runtime invalidated
active actor no longer matches the planned actor
schedule revision changed
```

`onCancel` should release scratch state without publishing partial actions.

`onComplete` publishes the complete frozen plan to DM Helper and creates pending authorization records.

**onComplete must not execute the actions.**

---

## 10.6 Cancellation lifecycle

On event end:

```lua
Tasks:CancelScope("autopilot:" .. eventId, "event-ended")
```

or equivalent scoped cancellation must remove unfinished planning work.

A new plan replacing an obsolete plan should cancel the old plan before queueing its replacement.

---

# 11. Spell Candidate Resolution

Autopilot evaluates only spell refs resolved for the active NPC.

It must not scan every activated Dataset spell.

For each spell, use canonical activation-snapshot machinery with an explicit caster, conceptually:

```lua
Client:ResolveSpellActivationSnapshot(spellRef, {
    casterEventId = npc.eventID,
    includeTargetCandidates = true,
})
```

The existing activation system remains authoritative for:

```text
cooldown
charges
GCD
resource cost
conditions
target policy
target legality
```

A spell with `canCast ~= true` is not a candidate.

---

# 12. Spell Intent Classification

The initial planner should infer intent from existing spell components rather than adding AI metadata to Unit datasets.

Required Phase 1 intents:

```text
damage
heal
```

Mixed spells can contribute both.

Unsupported pure-utility effects may be ignored by the tactical scorer in the first version while still executing normally if attached to a selected damage/heal spell.

---

## 12.1 Damage

A `damage` effect contributes offensive utility.

Use a deterministic expected magnitude based on the spell/effect configuration and relevant stat scaling.

Do not consume the real combat RNG while planning.

Actual hit, critical and variance behavior remains part of authorized spell execution.

---

## 12.2 Healing

A `heal` effect contributes healing utility.

Useful expected healing is capped by missing health:

```lua
effectiveHealing = math.min(expectedHealing, missingHealth)
```

This prevents large overheals from dominating the planner.

---

# 13. Lightweight Decision Policy

The policy should be deterministic and intentionally small.

## 13.1 Urgent healing

If a living ally is at or below 50% health and a meaningful legal heal exists, healing outranks damage.

Among urgent heals, prefer the action producing the greatest useful healing for the highest-need valid target.

The 50% threshold is initially an internal constant.

---

## 13.2 Useful healing

Outside the urgent tier, healing may still be selected when it produces meaningful effective healing rather than mostly overheal.

Consider:

```text
health fraction
absolute missing health
expected effective heal
projected healing already reserved in the frozen cohort plan
```

A planning-only projected-health ledger may prevent several cohort healers from all selecting the same nearly-full ally.

This ledger does not alter actual resources or health.

---

## 13.3 Damage

If no higher-priority healing action is warranted, choose a legal damage action.

Compare deterministic expected damage, then prefer lower commitment where values are similar:

```text
lower resource burden
lower cooldown/charge commitment
stable spellRef tie-break
```

---

# 14. Hostile Target Selection

For each legal hostile target candidate:

```lua
threat = npc.threatTable[target.eventID] or 0
```

Single-target ordering:

```text
1. threat descending
2. spatial proximity when relevant/available
3. eventID ascending
```

If every legal enemy has zero threat:

```text
nearest valid enemy when cached positions allow it
otherwise eventID ascending
```

No separate aggro state is introduced.

---

# 15. Healing Target Selection

Healing does not use threat.

For legal allies:

```lua
healthFraction = currentHealth / maxHealth
missingHealth = maxHealth - currentHealth
```

Default ordering:

```text
1. lower health fraction
2. greater missing health
3. lower eventID
```

Projected healing reservations are applied only while scoring the frozen cohort plan.

Dead-target behavior remains controlled by existing spell policy and `allowDeadTargets` semantics.

---

# 16. Multi-Target / AoE Selection

Use the spell's existing target policy:

```text
minTargets
maxTargets
targetDisposition
requiresTarget
allowDeadTargets
```

## 16.1 Offensive AoE

```text
1. choose highest-threat valid primary enemy;
2. obtain its cached/spatial position;
3. order remaining legal enemies by distance from the primary;
4. tie-break with eventID;
5. fill up to maxTargets.
```

If some secondary positions are unavailable, use resolvable nearest candidates first and stable threat/eventID fallback for remaining legal slots.

## 16.2 Multi-target healing

Choose the most injured ally first, then additional allies by projected healing need until required/valuable target slots are filled.

Do not fill optional slots with full-health units merely to reach `maxTargets` unless `minTargets` requires them.

---

# 17. Range and Melee Planning

No new spell range taxonomy is required.

Define the initial RPE autopilot melee rule:

```lua
MELEE_RANGE_YARDS = 5
```

Damage component classification:

```text
damageType = melee  → requires <= 5 yards
damageType = ranged → no melee-position requirement
damageType = spell  → no melee-position requirement
```

Healing receives no new range rule in Phase 1.

Do not add an `autopilotRange` field or require Dataset authors to duplicate the component damage type.

---

# 18. Shared Raid-Marker Movement Planning

A marked cohort has one shared virtual position, so individual NPCs cannot independently teleport beside different targets.

The planner first creates provisional actions, then collects targets required by melee actions.

Candidate anchor points can include:

```text
current marker position
each required melee target position
centroid of required melee targets
pairwise midpoints
```

Score candidates by:

```text
1. number of planned melee actions satisfied within 5 yards
2. total utility of satisfied actions
3. lower summed distance to required targets
4. stable coordinate tie-break
```

If a chosen anchor leaves a provisional melee action infeasible, re-evaluate that NPC at the selected marker position:

```text
another melee target in range
→ ranged/spell damage
→ heal
→ no action
```

---

# 19. Movement Is Also DM-Controlled

Autopilot cannot physically move a raid marker or NPC in the game world. It can only recommend a position.

Therefore a movement recommendation is represented in DM Helper as a pending helper action, for example:

```text
Move {cross} near Player A, Player B.  [Confirm Moved] [Skip]
```

A movement record may contain:

```lua
{
    actionId,
    actionType = "movement",
    actorKey = "marker:4",
    raidMarker = 4,
    objectiveTargetEventIds = { ... },
    proposedPosition = { x = ..., y = ... },
    status = "pending",
}
```

`proposedPosition` is host-local implementation data.

The virtual marker position is **not committed** when planning finishes.

It is committed only when the DM confirms that the marker has been moved.

If the DM skips/rejects the movement, dependent melee spell proposals must not execute as though the move occurred.

---

## 19.1 Movement dependencies

A planned spell action can declare:

```lua
requiresMovementActionId = <id>
```

If a melee action requires the proposed marker destination:

```text
movement pending
    → spell remains pending but cannot be authorized yet

movement confirmed
    → commit virtual marker position
    → spell can be authorized after normal revalidation

movement skipped/rejected
    → dependent action becomes blocked/stale
    → DM may request Replan
```

This prevents the internal spatial model from claiming that a physical movement occurred when the DM did not perform it.

---

# 20. Pending Authorization Model

Every executable NPC action generated by Autopilot becomes a structured pending action.

Conceptual model:

```lua
PendingAutopilotAction {
    actionId,
    planId,
    eventId,
    turnNumber,
    tickNumber,
    actorKey,
    casterEventId,
    actionType,             -- spell | movement
    spellRef,
    targetSelections,
    targetSelectionOrder,
    targetEventIds,
    requiresMovementActionId,
    explanation,
    status,
}
```

Spell action status values:

```text
pending
authorized
executing
completed
rejected
blocked
stale
failed
```

Movement action status values:

```text
pending
confirmed
skipped
stale
```

---

## 20.1 Planning completion does not mutate gameplay

`onComplete` of the sliceable planner:

```text
freezes plan
creates pending-action records
stores them in host-local runtime
refreshes DM Helper
returns
```

It must not call the spell lifecycle.

---

## 20.2 Individual authorization

The DM may authorize a pending spell action.

Authorization flow:

```text
click Authorize
        ↓
verify host permission
        ↓
verify action still pending
        ↓
verify event/turn/tick/actor identity
        ↓
verify required movement confirmed
        ↓
revalidate caster/spell/targets through canonical spell rules
        ↓
mark authorized/executing
        ↓
execute through normal NPC spell lifecycle
```

If revalidation fails, the action becomes `stale` or `failed`; it is not silently retargeted.

---

## 20.3 Reject

Rejecting a proposed action:

```text
marks it rejected
does not execute anything
does not automatically replan the entire cohort
```

DM Helper should offer an explicit **Replan Pending** / **Regenerate Plan** control when a materially changed plan is desired.

Automatic replanning after every rejection would make suggestions move underneath the DM while they are reviewing them.

---

## 20.4 Authorize All

A cohort-level **Authorize All** control is useful, but it remains explicit DM authorization.

It should:

- authorize only currently pending executable actions;
- respect unresolved movement dependencies;
- process authorized spells in stable cohort member order;
- revalidate each action before execution;
- skip/mark stale any action invalidated by an earlier authorized action.

The existence of Authorize All must not cause automatic execution when a plan is first generated.

---

# 21. Frozen Plan Semantics

Same-marker NPCs are planned from one pre-action snapshot.

Actual authorized execution remains sequential because RPE's combat lifecycle is sequential.

"Act at the same time" therefore means:

```text
same TurnStep
+
same frozen planning snapshot
+
one planned action per cohort member
```

The planner does not re-score later actions merely because an earlier authorized action resolved first.

If an earlier action makes a later target illegal, the later action becomes stale when authorization/revalidation occurs.

The DM can explicitly request a new plan.

---

# 22. Explicit-Caster Authorized Execution API

Autopilot must not simulate action-bar clicks or targeting-widget interaction.

Introduce a lower-level execution facade, conceptually:

```lua
Client:ExecuteEventUnitSpell({
    casterEventId = npc.eventID,
    spellRef = action.spellRef,
    activationSnapshot = refreshedSnapshot,
    targetSelections = action.targetSelections,
    targetSelectionOrder = action.targetSelectionOrder,
    source = "autopilot-authorized",
})
```

Responsibilities:

```text
verify current event/turn/tick
verify explicit caster active and eligible
revalidate spell activation
revalidate selected targets
apply existing start/end costs
apply cooldown/charges
create normal cast entry
start/complete through existing lifecycle
use existing NPC authority/comms
```

Manual casting can retain its UI wrappers, but both paths should converge on common lower-level spell execution.

Autopilot must not directly call Damage/Heal effect contracts.

---

# 23. NPC Spellcast Authority

Authorized autopilot actions remain ordinary:

```text
authorityType = "npc"
```

No `AUTOPILOT_CAST` opcode is required.

Participants process the resulting authorized cast exactly like a manually controlled NPC cast.

Planning and authorization metadata remain host-local.

---

# 24. DM Helper

DM Helper is the host-only companion panel opened from the event widget.

It replaces the previous Turn Summary naming throughout user-facing UI and new implementation code.

Suggested controls:

```text
[ Combat Log ] [ DM Helper ]
```

Only one companion-panel mode is open at a time.

---

## 24.1 DM Helper contents

For the active turn, DM Helper can show:

```text
Autopilot status: Planning / Ready / Suspended

Movement Recommendations
  Move {cross} near Player A, Player B.     [Confirm Moved] [Skip]

Pending NPC Actions
  [NPC 1] attacks Player A with Cleave.     [Authorize] [Reject]
  [NPC 2] attacks Player B with Fire Bolt.  [Authorize] [Reject]
  [NPC 3] heals NPC 1 with Mend.             [Authorize] [Reject]

  [Authorize All] [Replan Pending]

Current-turn combat history
  ...normal resolved entries...
```

The exact visual hierarchy may follow the existing companion-panel primitives, but authorization state must be obvious.

---

## 24.2 Host-only data

Do not send planning rows or movement instructions through `COMBAT_LOG`.

Maintain host-local structured state such as:

```lua
AutopilotHelperByEventId[eventId]
```

or expose data directly from `AutopilotRuntimeByEventId`.

Participants must never receive text such as:

```text
Move {cross} near Player A.
NPC 3 should heal NPC 1.
```

---

## 24.3 Combat Log interaction

Once an action is authorized and executes, it produces ordinary combat-log entries.

Therefore DM Helper may show both:

```text
Planned/authorized:
[NPC 1] attacks Player A with Cleave.

Resolved combat:
[NPC 1] hits Player A for 14 Health.
```

The first is the DM decision record; the second is the actual game result.

---

# 25. Plan and Action Idempotence

Key a plan by stable step identity, for example:

```text
eventId : turnNumber : tickNumber : actorKey/scheduleRevision
```

Repeated EventWidget refreshes or repeated state messages must not create duplicate pending actions.

Recommended plan states:

```text
queued
planning
ready
partially-authorized
resolved
cancelled
failed
```

A `ready` plan is not regenerated unless:

- the DM explicitly requests Replan;
- the underlying step/schedule identity changes;
- the plan becomes invalid before any action is authorized and the runtime intentionally replaces it.

---

# 26. Stale Action Guards

Before authorization/execution, check:

```text
same event?
same turn?
same tick?
same actor/schedule revision?
caster still active/alive?
caster still eligible on this step?
spell still usable?
targets still legal/alive as required?
required movement confirmed?
```

If the host advances the event while pending actions remain:

```text
mark/cancel them stale
cancel unfinished planner work
never carry them into the next step
```

Normal stale cancellation should not produce noisy error popups.

---

# 27. Cooldowns, Cast Times, Auras and Resources

Planning reads these systems through canonical activation state.

Authorization/execution uses the normal lifecycle.

If a spell has a cast time, authorization starts the cast; existing turn advancement progresses/completes it.

If a pending action becomes unaffordable, loses a charge, becomes condition-blocked, or its target becomes invalid before authorization, revalidation prevents execution and marks the action stale/failed.

No special autopilot versions of cooldown, aura, cost or resource systems are required.

---

# 28. Performance Requirements

Autopilot must not add visible hitching to turn transitions.

Required architecture:

```text
EVENT_STATE / turn transition
    → O(1) or small synchronous setup
    → EnqueueSliceable
    → incremental planning across queue slices
    → publish complete plan
```

Targets:

```text
synchronous plan scheduling: <= 1 ms typical
individual slice: use existing ~2 ms TaskQueue slice budget
no planner slice intentionally exceeds deadline
DM Helper publish/refresh: small deferred/dirty refresh
```

The planner should scale with the spells and valid targets of active NPCs, not all RPE datasets.

---

## 28.1 Per-plan caches

Within one planning job cache:

```text
spell definition by spellRef
activation state by caster+spell
health by eventID
position by eventID/actor key
distance pairs
expected effect magnitude by caster+spell
candidate target ordering
```

Discard scratch caches when the plan completes/cancels.

Do not create a long-lived global tactical cache unless profiling later proves it necessary.

---

# 29. Runtime Lifecycle

## 29.1 Event start

```text
start Autopilot event
        ↓
validate no-instance capability
        ↓
initialize runtime
        ↓
seed player position cache once
        ↓
build synchronized TurnSchedule
        ↓
clear old plans/actions
```

## 29.2 Player turn end

```text
player ends turn
        ↓
authoritative turn-end/step transition
        ↓
host samples only that player's UnitPosition
        ↓
update cached stable position
        ↓
normal event transition continues
```

## 29.3 NPC step begins

```text
NPC actor/cohort becomes active
        ↓
use existing cached player positions
        ↓
queue sliceable planner
        ↓
planner yields across frames as needed
        ↓
complete frozen plan published
        ↓
DM Helper shows pending authorization
        ↓
NO action executes automatically
```

## 29.4 Authorization

```text
DM authorizes action
        ↓
revalidate
        ↓
execute normal NPC spell
        ↓
update action status
        ↓
refresh DM Helper
```

## 29.5 Event end

Clear/cancel:

```text
Autopilot runtime
player position cache
virtual actor positions
planning scratch
pending authorization actions
DM Helper autopilot state
TaskQueue autopilot scope
```

---

# 30. Failure and Status Model

Runtime status values can include:

```text
off
ready
planning
awaiting-authorization
partially-authorized
resolved
suspended-instance
suspended-position
cancelled-stale
failed
```

Useful DM Helper messages:

```text
Planning NPC actions...

NPC Autopilot unavailable in instanced content. Use Manual mode.

Could not resolve Player A's cached position.

[NPC 1] has no usable spell or valid target.

[NPC 2] action became stale because its target is no longer valid.
```

Detailed scoring data belongs in debug logging, not normal DM text.

---

# 31. Debugging and Instrumentation

A reproducible planning trace should include:

```text
plan identity
event/turn/tick
actor/cohort
snapshot revision
NPC/spell cursor counts
candidate spells
candidate targets
threat values
healing need
expected damage/healing
movement anchor candidates
selected actions
yield count
slice count
max slice time
plan total elapsed wall time
authorization result
execution revalidation result
```

TaskQueue already records slice metrics. Autopilot labels should be specific, for example:

```text
Autopilot.Plan event=<id> turn=4 tick=2 actor=marker:4
```

This makes slow plans visible in existing timing diagnostics.

---

# 32. Proposed Module Layout

```text
core/
  classes/
    Event.lua
      turnMode normalization/networking
      mode-aware TurnActor/TurnStep schedule

client/
  client_Autopilot.lua
      host runtime coordinator
      lifecycle hooks
      planning job creation/cancellation
      pending authorization store
      authorization/rejection API

  autopilot/
    Spatial.lua
      group token mapping
      player position cache updates
      vector/distance helpers
      virtual actor positions
      marker anchor solver

    Planner.lua
      sliceable planning state machine
      snapshot construction
      cohort planning
      frozen plan output

    SpellEvaluator.lua
      damage/heal intent
      deterministic expected magnitude
      priority comparison

    TargetSelector.lua
      threat target selection
      healing target selection
      AoE proximity selection

    Authorization.lua
      pending action lifecycle
      dependency checks
      individual/bulk authorization
      rejection/replan

    Helper.lua
      DM Helper structured display state
      wording/status formatting

  client_Event.lua
      player-turn-end position cache hook
      NPC-step planning trigger
      event cleanup

  client_Targeting.lua / spellcasting helpers
      explicit-caster programmatic target validation

  spellcasting/
    Cooldowns.lua
      explicit-caster activation snapshot support

    Lifecycle.lua
      shared lower-level explicit-caster execution API

    Helpers.lua
      mode-aware turn eligibility

  ui/widgets/
    widget_Event.lua
      Combat Log / DM Helper buttons
      DM Helper companion-panel mode
      authorization controls

server/
  server_Event.lua
      mode-aware turn/tick schedule state

  ui/eventmanage/
    page_EventManageSettings.lua
      Autopilot toggle
      explicit no-instance warning

core/internal/tasks/TaskQueue.lua
  no new queue system required
  consume existing EnqueueSliceable/ShouldYield/cancellation APIs
```

---

# 33. Implementation Phases

## Phase 1 — Turn mode, scheduling and position cache

Implement:

- `Event.turnMode`;
- backward-tolerant network state;
- Event Manager toggle;
- explicit instance warning;
- raid-marker TurnActor/TurnStep scheduling;
- mode-aware spellcaster eligibility;
- initial player coordinate seed;
- **one-player coordinate refresh on that player's turn end only**;
- host virtual marker/NPC positions;
- event teardown.

Acceptance:

```text
Manual events are unchanged.
Same-marker NPCs are never split across turns.
Unmarked NPCs remain independent actors.
Autopilot does not continuously poll positions.
NPC-step planning does not rescan player coordinates.
Each completed player turn updates only that player's cached position.
Autopilot is explicitly unavailable in instances.
```

---

## Phase 2 — Sliceable planner

Implement:

- explicit-caster activation snapshot;
- sliceable planning state machine using `Tasks:EnqueueSliceable`;
- `Tasks:ShouldYield(deadlineMs)` checks in candidate loops;
- stale-check and scoped cancellation;
- damage/heal classification;
- threat target selection;
- healing priorities;
- AoE nearest-target ordering;
- 5-yard melee planning;
- shared marker anchor solver;
- frozen plan;
- projected healing reservation.

Acceptance:

```text
No full cohort plan runs synchronously from a turn-transition handler.
Planning can span multiple frames.
Each planner slice respects the supplied deadline.
Event/turn change cancels stale planning.
Planner completion mutates no combat state.
```

---

## Phase 3 — DM Helper and authorization queue

Implement:

- rename Turn Summary → DM Helper;
- host-only DM Helper companion-panel mode;
- pending movement recommendations;
- pending spell-action records;
- Authorize / Reject controls;
- Confirm Moved / Skip controls;
- Authorize All;
- explicit Replan Pending;
- action status rendering;
- movement dependency blocking;
- current-turn combat history integration where appropriate.

Acceptance:

```text
A generated plan produces pending actions only.
No spell starts when planning completes.
Every executable NPC spell requires explicit DM authorization.
Movement recommendations do not commit virtual positions until confirmed.
Participants never receive DM Helper planning data.
```

---

## Phase 4 — Authorized execution

Implement:

- explicit-caster programmatic spell execution;
- canonical authorization-time revalidation;
- per-action stale handling;
- stable Authorize All ordering;
- normal NPC authority/comms path;
- action completion/failure status;
- idempotence.

Acceptance:

```text
Two NPCs may propose the same spell with different targets safely.
Authorizing one action executes exactly once.
Rejecting an action executes nothing.
Repeated UI/state refreshes cannot execute a pending action.
Authorized actions use normal cooldowns, costs, effects, threat and combat log.
An invalidated target causes stale/skip rather than silent retargeting.
```

---

# 34. Test Matrix

## Turn scheduling

- one unmarked NPC;
- several unmarked NPCs;
- two/three NPCs sharing a marker;
- several marker cohorts;
- mixed players + marked NPCs + unmarked NPCs;
- marker cohort larger than visible page capacity;
- inactive/dead cohort member;
- player shared-turn pet;
- equal initiative ties.

## Position caching

- initial event seed;
- local host-player ends turn;
- remote player ends turn;
- only the completed player's cache entry changes;
- NPC step does not call UnitPosition for every player;
- player remains stable through several other actors' turns;
- missing cached position;
- changed party/raid token mapping;
- different instanceID;
- instance start rejected;
- capability becomes unavailable mid-event.

## Sliceable planning

- tiny single-NPC plan completes in one slice;
- large cohort requires several slices;
- repeated spell/target loops yield at deadline;
- event ends mid-plan;
- turn advances mid-plan;
- replacement plan cancels old job;
- `onCancel` publishes no partial actions;
- `onComplete` publishes actions but executes none;
- max slice timing remains inside budget under representative data.

## Decision policy

- healthy allies → damage;
- ally <= 50% → legal heal outranks damage;
- large overheal loses value;
- no castable heal;
- damage spell on cooldown;
- insufficient resource;
- target condition failure;
- clear highest threat target;
- equal threat tie;
- all zero threat;
- offensive AoE;
- multi-target heal;
- melee target requiring marker movement;
- shared marker with incompatible melee targets.

## Authorization

- plan creates pending actions;
- pending spell does not execute by itself;
- authorize one spell;
- reject one spell;
- Authorize All;
- repeated click cannot double-execute;
- movement required before melee authorization;
- Confirm Moved commits virtual position;
- Skip movement blocks dependent melee action;
- target dies before authorization;
- resource becomes insufficient before authorization;
- event advances with pending actions;
- Replan Pending replaces old pending plan explicitly.

## DM Helper

- host sees DM Helper button;
- participant does not;
- DM Helper shows Planning state while sliceable job runs;
- completed planner populates pending action rows;
- authorization status updates immediately;
- rejected/stale rows are distinguishable;
- current-turn combat entries remain available;
- old-turn pending actions disappear/become stale on advance;
- Combat Log remains participant-safe.

---

# 35. Explicit Non-Goals

This design does not implement:

```text
automatic execution immediately after planning
automatic DM authorization
automatic event advancement
continuous player-position polling
per-NPC UnitPosition polling
pathfinding
navmesh generation
terrain collision
line-of-sight simulation
NPC movement-speed budgets
exact Blizzard hitboxes
autopilot inside restricted instances
distributed client AI
player-character autopilot
LLM decisions
behavior trees
per-Unit authored AI scripts
new aggro rules
new spell range authoring
full tactical valuation of every utility effect
automatic replanning whenever the DM rejects one suggestion
network synchronization of DM-only plans or virtual NPC coordinates
```

---

# 36. Principal Architectural Decisions

**Autopilot is a host-authoritative planner, not an automatic executor.**

**Every executable NPC action generated by the planner enters a Pending Authorization list.**

**No planned spell changes gameplay state until the DM explicitly authorizes it.**

**Turn Summary is renamed DM Helper and becomes the host's planning/authorization surface.**

**Movement proposals are also DM-controlled; virtual marker positions are committed only when the DM confirms the physical move.**

**Player positions are initialized at event start and recalculated only when that player ends their turn.**

**NPC planning consumes cached player positions and does not rescan the raid/party on every NPC turn.**

**All autopilot planning uses the existing sliceable TaskQueue via `Tasks:EnqueueSliceable`; a normal deferred but indivisible job is not acceptable.**

**Planner loops must honor the supplied deadline with `Tasks:ShouldYield(deadlineMs)`.**

**Planning jobs use stale checks and scoped cancellation so obsolete event/turn work cannot publish actions.**

**NPCs sharing a non-zero raid marker form one atomic TurnActor and share one virtual position.**

**Unmarked NPCs remain singleton actors.**

**Same-marker decisions are generated from one frozen pre-action snapshot.**

**The existing NPC threat table is the hostile targeting source of truth.**

**Existing Spell components are sufficient for the initial damage/heal intent model.**

**Canonical spell activation remains the source of legality; the planner does not duplicate cooldown, resource or targeting rules.**

**Melee positioning is inferred from `damageType = "melee"` and a 5-yard RPE rule; no new Spell range metadata is required.**

**AoE targeting uses highest threat for the primary target and mathematical proximity for secondary targets.**

**Healing uses health need/effective healing and outranks damage for critically injured allies.**

**Authorized actions converge on the normal NPC spell lifecycle and therefore reuse costs, cooldowns, effects, threat, resource synchronization and combat logging.**

**Autopilot never silently guesses unavailable coordinates and explicitly does not support Blizzard instances.**

---

# 37. External WoW API Constraint

The spatial portion of the design relies on the current WoW API behavior of `UnitPosition(unit)` and the current instance state exposed through `IsInInstance()`.

This is a product constraint rather than an RPE error.

Required user-facing wording remains explicit:

> **NPC Autopilot does not work in instances. Use Manual event mode in dungeons, raids, battlegrounds and arenas.**
