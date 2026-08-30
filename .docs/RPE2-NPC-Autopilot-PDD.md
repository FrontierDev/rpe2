# RPE 2 — NPC Autopilot
## Product Design Document

**Status:** Proposed  
**Target:** RPEngine 2.0 (`FrontierDev/rpe2`)  
**Scope:** Host-authoritative NPC decision-making, raid-marker cohort turns, host-side spatial simulation, spell/target selection, automated NPC spell execution, Event Manager controls, Turn Summary integration  
**Primary objective:** Allow the event host to run NPC turns automatically while presenting concise movement and action instructions in the host-only Turn Summary  
**Related issues:** #100 Combat Log history, #101 host-only Turn Summary  
**Out of scope:** Blizzard instance support, pathfinding, collision/obstacle simulation, exact WoW hitboxes, player autopilot, general-purpose tactical AI, authored AI behavior trees

---

# 1. Purpose

RPE events currently require the event host to manually control NPC units, choose their spells, choose their targets, and interpret physical positioning.

NPC Autopilot adds a lightweight host-side decision system which can perform that repetitive work while keeping the host in control of event pacing.

The desired interaction is:

```text
NPC cohort turn begins
        ↓
Host samples player positions
        ↓
Autopilot evaluates the NPCs in the active cohort
        ↓
Autopilot chooses movement, spells and targets
        ↓
Turn Summary shows concise DM instructions

Move {cross} near Player A, Player B.
[NPC 1] attacks Player A.
[NPC 2] attacks Player B.
[NPC 3] heals [NPC 1].
        ↓
Chosen NPC spells execute through normal RPE combat
        ↓
Host advances the event when ready
```

The system is not intended to replace the event host with a sophisticated AI. It should make the common case fast and predictable:

- injured allies make healing more valuable;
- otherwise NPCs generally attack;
- enemies with more threat are preferred;
- multi-target damage starts from the highest-threat target and expands to nearby enemies;
- melee positioning uses real player coordinates and virtual NPC coordinates;
- NPCs represented by the same raid marker act as one cohort.

The host remains responsible for narrative interpretation, physically moving any raid markers used to represent NPC groups, exceptional tactical decisions, and advancing the event.

---

# 2. Product Requirements

The first implementation must provide all of the following.

## 2.1 Event mode

The Event Manager must expose an **NPC Autopilot** mode.

Manual events must retain their existing behavior.

Autopilot must be an explicit event mode because it changes both:

- NPC execution behavior; and
- how NPCs are grouped into turn steps.

Autopilot mode should be fixed when the event starts for the initial implementation. Live switching between manual and autopilot turn scheduling is out of scope because changing the schedule while a turn is already in progress can invalidate `tickNumber`, cast, aura and cooldown state.

---

## 2.2 Explicit instance warning

Autopilot must display a clear warning that it does **not** work in Blizzard instances.

The warning should state that exact party/raid coordinates are unavailable in:

```text
Dungeons
Raids
Battlegrounds
Arenas
```

If the host attempts to start an event with NPC Autopilot enabled while the required position API is unavailable, RPE must not silently invent coordinates.

The host should be told to use Manual mode.

If position access becomes unavailable after the event has already started, the autopilot runtime enters a suspended state and performs no new automatic NPC decisions until valid position data is available again.

The event itself remains active.

---

## 2.3 Host-authoritative behavior

Only the event host computes autopilot decisions.

Participant clients must not independently:

- evaluate NPC spells;
- choose targets;
- calculate virtual NPC movement;
- emit autopilot Turn Summary directives.

Existing RPE spellcast, resource, threat and combat synchronization remains responsible for distributing the resulting authoritative gameplay state.

---

## 2.4 Raid-marker cohort turns

All active NPC EventUnits sharing the same non-zero `raidMarker` must be treated as one atomic NPC cohort for turn scheduling.

Example:

```text
NPC 1    raidMarker = cross
NPC 2    raidMarker = cross
NPC 3    raidMarker = cross

→ all three are eligible on the same event step
→ all three are planned from the same pre-action snapshot
→ the host receives one movement instruction for the cross marker
```

`raidMarker = 0` must **not** mean that every unmarked NPC forms one giant cohort.

Unmarked NPCs remain singleton scheduling actors.

Existing player-shared-turn pet semantics remain unchanged: a player pet continues to share the player's turn rather than becoming an independent autopilot cohort.

---

## 2.5 Lightweight spell selection

Autopilot chooses among the spells already resolved for the NPC.

The initial system should infer spell purpose from existing Spell components rather than requiring new Unit AI authoring fields.

At minimum it must understand:

```text
damage
heal
```

Mixed spells can contribute both kinds of utility.

Pure utility spells whose benefit cannot be evaluated cheaply and deterministically may be ignored by the initial selector.

The engine must not duplicate existing resource-cost, cooldown, charge, condition or target-validity rules. Only spells that pass the canonical RPE activation checks are candidates.

---

## 2.6 Target selection

For hostile single-target actions:

```text
highest threat valid enemy
```

is the default preference.

For enemy multi-target/AoE actions:

```text
1. choose the highest-threat valid enemy as the primary target;
2. order remaining valid enemies by mathematical distance from that primary target;
3. fill the target group up to the existing maxTargets limit.
```

For healing:

```text
most injured valid ally
```

is the default preference, with effective healing and overhealing considered when comparing spells.

All existing Spell target policy rules remain authoritative.

---

## 2.7 Range and spatial behavior

Autopilot does not require a new spell range model.

For the initial system:

- a damage component with `damageType = "melee"` requires the relevant NPC/marker position to be within **5 yards** of its target;
- `damageType = "ranged"` does not require moving into melee;
- `damageType = "spell"` does not require moving into melee;
- healing does not receive a new spatial range rule.

This deliberately uses the combat component information which already exists instead of creating a second range classification.

The existing `Spell.range` field is not used by the initial autopilot scoring system.

---

# 3. Current Codebase — Event Turn Architecture

This section describes the inspected current implementation and is the basis for the proposed design.

## 3.1 Event state already has synchronized turn identity

`core/classes/Event.lua` stores:

```lua
turnNumber
tickNumber
totalTicks
```

`Event:ToStateArguments()` transmits these values through the event state protocol.

`client/client_Event.lua` compares previous and incoming turn/tick identity and routes turn-advance consequences from those synchronized fields.

This is the correct foundation for autopilot. A separate NPC turn counter must not be introduced.

---

## 3.2 Current tick eligibility is coupled to unit pages

Current RPE turn eligibility is page-based.

`client/spellcasting/Helpers.lua` implements:

```lua
Spellcasting.GetUnitPageIndex(...)
Spellcasting.IsCasterTurnOnTick(...)
```

and `Spellcasting.IsCasterTurnOnTick()` effectively checks:

```text
eventState.tickNumber == Event.GetUnitPageIndex(...)
```

`server/server_Event.lua` computes `totalTicks` from active unit count and `DEFAULT_MAX_EVENT_UNITS`, currently five.

`core/classes/Event.lua` exposes:

```lua
Event.GetUnitPageIndex(...)
Event.GetUnitsForPage(...)
```

The result is an important architectural coupling:

```text
visual/event unit page
        =
spellcast eligibility group
        =
event tick
```

That works for manual events because units are simply sorted and divided into fixed pages.

It is insufficient for autopilot because a raid-marker cohort is atomic and therefore must never be split across two turn steps.

---

## 3.3 Current initiative order is deterministic

`Event.SortUnitsByInitiative()` sorts units using the existing comparator:

```text
higher initiative first
then lower eventID
then stable textual fallbacks
```

Autopilot should preserve that deterministic ordering.

It should group units into scheduling actors **after** the normal active-unit and shared-pet rules are applied.

---

# 4. Proposed Turn Scheduling Model

Introduce an explicit scheduling layer for autopilot rather than modifying the meaning of `raidMarker` throughout combat code.

Conceptually:

```lua
TurnActor {
    key
    kind
    initiative
    raidMarker
    unitEventIds
}
```

Examples:

```lua
{
    key = "player:12",
    kind = "player",
    initiative = 18,
    unitEventIds = { 12 },
}

{
    key = "marker:4",
    kind = "npc_marker",
    initiative = 16,
    raidMarker = 4,
    unitEventIds = { 21, 22, 27 },
}

{
    key = "npc:31",
    kind = "npc",
    initiative = 11,
    raidMarker = 0,
    unitEventIds = { 31 },
}
```

---

## 4.1 Actor construction rules

Build actors from active event units:

```text
Player
    → singleton player actor

Player-shared-turn pet
    → remains attached to existing player turn semantics

NPC with raidMarker > 0
    → actor key "marker:<raidMarker>"
    → every active NPC with that marker joins the same actor

NPC with raidMarker == 0
    → singleton NPC actor
```

Teams do not alter grouping.

If two hostile NPCs are deliberately assigned the same raid marker, they still form one cohort. The raid marker is therefore the explicit host grouping instruction.

---

## 4.2 Cohort initiative

A marker cohort's scheduling initiative should be:

```text
maximum initiative among its active members
```

Rationale:

- the cohort becomes eligible when its earliest/highest-initiative member would otherwise become eligible;
- no member loses its original earliest opportunity merely because it was grouped;
- the calculation is deterministic and requires no new stored initiative field.

Within the cohort, member execution order remains:

```text
initiative descending
eventID ascending
```

That internal order is only an execution ordering. Planning still uses one shared snapshot so same-marker members behave as simultaneous decision makers.

---

## 4.3 Packing actors into event steps

Manual mode keeps the current fixed unit-page behavior unchanged.

Autopilot mode builds ordered actors and packs them into `TurnStep` values without splitting an actor:

```lua
TurnStep {
    actors = { ... },
    unitEventIds = { ... },
}
```

`max_event_units` remains the target visible step capacity.

Packing rule:

```text
Walk actors in initiative order.

If the next actor fits in the current step:
    add it.

If adding it would exceed the configured page size:
    start the next step.

Never split one raid-marker actor.

If one marker cohort itself exceeds the page size:
    place that cohort alone in an oversized step.
```

This keeps autopilot close to the existing page/tick model while guaranteeing same-marker simultaneity.

---

## 4.4 Decouple turn eligibility from portrait pagination

The current `GetUnitPageIndex()` helper should no longer be the universal source of turn eligibility.

Introduce mode-aware helpers such as:

```lua
Event.BuildTurnSchedule(eventState)
Event.GetUnitTurnStepIndex(eventState, eventId)
Event.GetUnitsForTurnStep(eventState, tickNumber)
```

Then:

```lua
Spellcasting.IsCasterTurnOnTick(...)
```

uses:

```text
manual mode
    → existing unit page index

autopilot mode
    → autopilot TurnStep index
```

The visual EventWidget may still paginate an oversized active step, but pagination must not change which cohort members are eligible.

This is the central turn-order architecture change required by autopilot.

---

# 5. Event Data and Network State

Add a normalized Event field:

```lua
turnMode = "manual"
```

Allowed values:

```text
manual
autopilot
```

`manual` is the default for all existing events and legacy network payloads.

Required integration points include:

```text
core/classes/Event.lua
server/server_Event.lua
server/ui/eventmanage/page_EventManageSettings.lua
client/client_Event.lua
client/spellcasting/Helpers.lua
client/ui/widgets/widget_Event.lua
```

The mode must be synchronized because every client needs to agree on turn eligibility.

Use optional trailing network fields in the existing Event start/state serialization so older payloads safely normalize to `manual`.

No Dataset or Profile schema change is required.

---

# 6. Host Spatial Model

Autopilot uses a host-local spatial simulation.

It combines:

```text
real player positions
+
virtual NPC/raid-marker positions
```

in one two-dimensional coordinate space measured in yards.

---

## 6.1 Player positions

The host resolves event players to WoW group unit tokens:

```text
player
party1 ... party4
raid1 ... raid40
```

using normalized character names.

At planning time:

```lua
local x, y, _, instanceID = UnitPosition(unitToken)
```

is sampled for each relevant player.

The values are used directly as yard-space coordinates.

Autopilot should sample positions when an NPC turn is planned rather than continuously polling every frame.

A single group-token scan can build:

```lua
playerEventId -> unitToken -> position
```

for the planning snapshot.

---

## 6.2 Existing Movement precedent

`core/internal/Movement.lua` already uses:

```lua
UnitPosition("player")
```

and Euclidean X/Y distance for RPE movement tracking.

Autopilot should share/refactor the same low-level vector/distance helpers where practical rather than introducing incompatible distance math.

---

## 6.3 NPC spatial positions

NPC positions are virtual and host-local.

For marked NPCs, the raid marker is the physical representation of the cohort, so the spatial position belongs to the **marker**, not to each member independently.

Position key:

```text
raidMarker > 0
    → "marker:<raidMarker>"

raidMarker == 0
    → "unit:<eventID>"
```

Therefore:

```text
NPC 1 = cross
NPC 2 = cross
NPC 3 = cross

all three share one virtual coordinate
```

This is what makes a Turn Summary instruction such as:

```text
Move {cross} near Player A and Player B.
```

meaningful.

---

## 6.4 Runtime structure

Example host-local runtime:

```lua
AutopilotRuntimeByEventId[eventId] = {
    status = "ready",

    positionByActorKey = {
        ["marker:4"] = {
            x = 1234.2,
            y = 882.1,
        },
    },

    playerPositionByEventId = {},

    plansByStepKey = {},
}
```

This state exists only for the lifetime of the active event.

It is not SavedVariables data and does not need to be broadcast to participants in Phase 1.

---

## 6.5 Two-dimensional distance

Use:

```lua
distance = math.sqrt(
    (a.x - b.x) ^ 2 +
    (a.y - b.y) ^ 2
)
```

The initial system intentionally ignores vertical geometry, obstacles and pathing.

The spatial simulation answers:

```text
Who is near whom?
Is a melee target within 5 yards?
Which units are nearest to an AoE primary target?
Where should the raid marker be represented?
```

It does not answer:

```text
Can an NPC physically walk around this wall?
How long is the navigable path?
Does terrain block line of sight?
```

---

# 7. Coordinate Capability and Instance Handling

WoW restricts `UnitPosition()` in instanced content.

The current documented API behavior is:

```text
UnitPosition works with player/partyN/raidN outdoors.
It is restricted in dungeons, raids, battlegrounds and arenas.
```

Autopilot therefore requires a capability check.

---

## 7.1 Start-time validation

When the host enables NPC Autopilot in Event Manager, show persistent helper/warning text:

> NPC Autopilot uses party/raid world coordinates and does not work in dungeons, raids, battlegrounds or arenas.

On event start:

```text
Autopilot selected
        ↓
IsInInstance() / coordinate capability check
        ↓
restricted
        → block autopilot start
        → tell host to use Manual mode

available
        → continue
```

The event may still be started after the host selects Manual mode.

---

## 7.2 Runtime suspension

Even outdoors, a player can fail position resolution because:

- the player is not in the host's WoW party/raid;
- the unit token cannot be matched;
- `UnitPosition()` returns nil;
- the player is in a different world/instance ID.

Autopilot must not invent that coordinate.

For a position-dependent decision:

```text
valid coordinate
    → candidate may be used

no valid coordinate
    → candidate cannot be used for a melee/spatial decision
```

If no viable plan remains, the NPC takes no automatic action and the Turn Summary explains that position information was unavailable.

---

# 8. Autopilot Planning Snapshot

All members of one marker cohort are considered to take their turn together.

To prevent arbitrary execution order from changing their choices, the host captures a planning snapshot before choosing any cohort actions.

The snapshot includes, at minimum:

```text
event ID
turn number
tick number
unit active/dead state
unit teams
current/max resources
NPC threat tables
resolved NPC spell refs
cooldown/charge availability
spell resource affordability
active auras/conditions required by spell legality
player coordinates
virtual NPC/marker coordinates
```

Every member is planned against this same baseline.

---

## 8.1 Simultaneous planning, sequential execution

Actual RPE combat remains sequential because the existing spell lifecycle, resource deltas and network messages are sequential.

This is acceptable.

"Same time" means:

```text
same event step
+
same pre-action decision snapshot
+
one frozen cohort plan
```

not that Lua effects execute literally in parallel.

After planning:

```text
freeze plan
        ↓
execute members in deterministic order
        ↓
do not re-score later members because an earlier member happened to resolve first
```

This prevents the implementation from creating accidental tactical behavior based only on Lua execution order.

---

## 8.2 Healing reservation ledger

There is one exception useful for avoiding obviously wasteful simultaneous plans.

The planner may maintain projected health in planning scratch state:

```lua
projectedHealth[targetEventId]
```

When one NPC chooses a heal, reserve its expected effective healing.

Subsequent healers evaluate the projected missing health rather than all independently choosing the same nearly-full ally.

This changes only planning utility.

Actual health changes still come exclusively from normal spell execution.

---

# 9. Canonical Spell Candidate Resolution

The current codebase already has most of the legality checks autopilot needs.

`client/spellcasting/Cooldowns.lua` builds activation snapshots which already represent:

- resolved caster/spell;
- cooldown state;
- charges;
- global cooldown;
- spell conditions;
- resource affordability;
- target groups;
- valid target candidates.

Autopilot must reuse this machinery.

It must not implement a parallel set of checks such as:

```text
if mana >= ...
if cooldown == ...
if condition ...
```

inside the AI.

---

## 9.1 Explicit-caster activation

The existing UI flow resolves an activation around the currently controlled/action-bar caster.

Autopilot needs to evaluate several NPCs without repeatedly changing `Client.ControlledEventUnitId`.

Extend the activation API with an explicit caster option, conceptually:

```lua
Client:ResolveSpellActivationSnapshot(spellRef, {
    casterEventId = npc.eventID,
    includeTargetCandidates = true,
})
```

or an equivalent internal API.

The resulting snapshot must use exactly the same spell legality rules as manual casting.

---

# 10. Spell Intent Classification

No new AI metadata is required for the initial version.

Inspect the Spell's existing components.

---

## 10.1 Damage intent

A component whose effect type is:

```text
damage
```

contributes offensive utility.

The existing Damage effect already exposes:

```text
baseDamage
statScaling
damageType
damageSchoolRefs
threatCoefficient
...
```

For planning, use a deterministic expected magnitude.

Do not invoke the real damage roll, critical roll or variance roll while scoring a spell.

Actual randomness remains part of real spell execution.

---

## 10.2 Healing intent

A component whose effect type is:

```text
heal
```

contributes healing utility.

The existing Heal implementation resolves base healing, stat scaling and combat modifiers at execution time.

The planner should use an expected deterministic amount and cap useful healing at the target's missing health:

```lua
effectiveHealing = math.min(expectedHealing, missingHealth)
```

This prevents a huge heal on a nearly full target from being considered as valuable as its raw tooltip amount.

---

## 10.3 Mixed spells

A spell can contain several components.

The planner builds an intent summary such as:

```lua
{
    expectedDamage = ...,
    expectedHealing = ...,
    hasMeleeDamage = true,
    hasRangedDamage = false,
    hasSpellDamage = false,
}
```

The actual components are still executed by the normal spellcasting engine.

---

## 10.4 Unsupported pure utility in Phase 1

The Spell model also supports effects such as:

```text
apply_aura
remove_aura
resource
interrupt
revert
summon_pet
```

These remain fully usable manually.

Phase 1 autopilot does not need to assign tactical values to every possible pure utility spell.

A mixed spell containing a damage/heal component can still be selected and its secondary effects execute normally.

Future versions can add explicit utility evaluators without changing the core planner architecture.

---

# 11. Lightweight Decision Policy

The selector should be understandable and deterministic rather than a large weighted behavior tree.

Use a small priority hierarchy.

---

## 11.1 Priority tier 1 — urgent healing

If a living allied target is at or below:

```text
50% health
```

and at least one meaningful legal heal exists, healing outranks damage.

Among urgent heals, prefer the action with the greatest expected effective healing on the highest-need target.

This directly provides the desired behavior:

```text
an ally is in danger
→ healing takes priority over damage
```

The 50% threshold should initially be an internal constant, not a new ruleset surface.

It can become configurable later if real event usage demonstrates a need.

---

## 11.2 Priority tier 2 — useful healing

If no ally is in the urgent tier, healing can still be selected when it produces meaningful effective healing rather than mostly overheal.

Useful-heal scoring considers:

```text
health fraction
absolute missing health
effective expected heal
projected healing already reserved by cohort members
```

---

## 11.3 Priority tier 3 — damage

If no higher-priority healing action is warranted, choose the highest-value legal damage action.

Damage comparison uses deterministic expected damage.

When two damage actions have similar immediate value, prefer the less committed option:

```text
lower resource burden
shorter cooldown / no charge expenditure
stable spellRef tie-break
```

This avoids needing a complex future-value model while reducing obviously wasteful use of expensive abilities.

---

## 11.4 Stable tie-breaking

Every score comparison must end in deterministic tie-breakers such as:

```text
higher utility
lower resource/cooldown commitment
spellRef lexical order
target eventID ascending
```

Two clients should never need to make the decision, but deterministic logic is still important for debugging and tests.

---

# 12. Hostile Target Selection

Use the NPC's existing `threatTable`.

The inspected combat path already records threat against non-player defenders as:

```text
target NPC threatTable[sourceEventId] += generatedThreat
```

and threat updates are synchronized alongside resource deltas.

This gives autopilot the correct source of truth.

---

## 12.1 Single-target enemy policy

For a legal hostile target candidate:

```lua
threat = npc.threatTable[target.eventID] or 0
```

Order candidates by:

```text
1. threat descending
2. spatial proximity to current actor position, when available
3. eventID ascending
```

If all legal enemies have zero threat:

```text
nearest valid enemy when coordinates exist
otherwise lowest eventID
```

No new aggro database is required.

---

# 13. Healing Target Selection

Healing does not use threat.

For each legal allied candidate:

```lua
healthFraction = currentHealth / maxHealth
missingHealth = maxHealth - currentHealth
```

Order primarily by:

```text
1. lower health fraction
2. greater absolute missing health
3. lower eventID
```

When evaluating a particular heal spell, use `effectiveHealing` after projected cohort reservations.

Dead targets remain controlled by the Spell's existing `allowDeadTargets`/target-policy semantics.

Autopilot must not silently allow resurrection targeting for a spell that does not already allow it.

---

# 14. Multi-Target / AoE Selection

The Spell target policy already supplies:

```text
minTargets
maxTargets
targetDisposition
requiresTarget
allowDeadTargets
```

Autopilot must use those limits rather than inventing its own target count.

---

## 14.1 Offensive AoE

For enemy multi-target groups:

```text
1. choose highest-threat enemy as primary;
2. obtain the primary target's spatial position;
3. calculate distance from every other legal enemy to that primary;
4. sort nearest first;
5. append until maxTargets is reached.
```

Tie-break by eventID.

This implements the requested behavior of centering an AoE decision around the highest-threat target and then taking nearby enemies.

If spatial positions are unavailable for secondary targets, append resolvable nearest targets first and then use stable threat/eventID fallback ordering for the remaining legal slots.

---

## 14.2 Multi-target healing

For allied multi-target healing:

```text
1. choose the most injured ally;
2. choose additional allies by projected healing need;
3. stop at maxTargets.
```

Do not fill optional target slots with full-health allies merely to reach `maxTargets` unless the target policy requires `minTargets`.

---

# 15. Melee Spatial Requirement

Define:

```lua
MELEE_RANGE_YARDS = 5
```

This is an RPE autopilot simplification.

It is centre-to-centre Euclidean distance in the virtual space.

The system does not attempt to reproduce Blizzard unit hitbox radii.

---

## 15.1 Damage component range classification

Autopilot looks at the chosen Spell's damage components:

```text
damageType = melee
    → target must be within 5 yards of the actor position

damageType = ranged
    → no melee-position requirement

damageType = spell
    → no melee-position requirement
```

Do not add a second `autopilotRange` field to Spell or Unit.

Do not require Dataset authors to duplicate the component's combat type.

---

# 16. Shared Raid-Marker Position Planning

A marked NPC cohort has one shared virtual coordinate.

The planner therefore cannot simply place each NPC independently beside its own target.

It must select one marker anchor that best supports the frozen cohort plan.

---

## 16.1 Provisional actions

First choose each NPC's preferred spell and target without committing movement.

Collect the primary targets of planned melee actions.

Example:

```text
NPC 1 → melee Player A
NPC 2 → melee Player B
NPC 3 → heal NPC 1
```

The cross marker must now be positioned to support Player A and Player B as well as possible.

---

## 16.2 Lightweight candidate-point solver

Do not implement continuous pathfinding or expensive geometric optimization.

Build a small deterministic set of candidate anchor points:

```text
current marker position, if known
each required melee target position
centroid of all required melee target positions
pairwise midpoints of required melee target positions
```

Score each candidate by:

```text
1. number of planned melee actions whose targets are <= 5 yards
2. summed action utility satisfied at that point
3. lower total distance to required melee targets
4. deterministic coordinate tie-break
```

Choose the best candidate.

The number of NPCs and targets in an RPE turn is small, so this remains cheap.

---

## 16.3 Re-evaluate infeasible melee actions

If the selected shared marker position leaves one provisional melee target outside 5 yards:

```text
re-evaluate that NPC at the chosen marker position
```

Preference order:

```text
another legal melee target in range
then a legal ranged/spell damage action
then a legal heal
otherwise no action
```

Do not move the marker a second time for one member after the cohort plan has been frozen.

One marker gets one movement destination for the step.

---

## 16.4 Movement summary

When a marker anchor changes materially, emit one host-only directive:

```text
Move {cross} near Player A and Player B.
```

The displayed names should be the relevant movement-objective targets, not raw X/Y coordinates.

Coordinates remain an implementation detail.

For an unmarked singleton NPC, the directive may use the NPC name:

```text
Move [NPC Name] near Player A.
```

---

# 17. Programmatic NPC Spell Execution

Autopilot must not simulate Action Bar clicks or the targeting UI.

The current manual path is:

```text
ActivateActionBarSpell
    ↓
ResolveSpellActivationSnapshot
    ↓
PendingSpellTargeting
    ↓
QueueLocalSpellTargetSelection
    ↓
OnSpellcastStart
    ↓
normal lifecycle/effects/comms
```

Autopilot should join this pipeline after UI interaction has been replaced by a programmatic target selection.

---

## 17.1 Current mutable target-selection limitation

`Spellcasting.QueueLocalSpellTargetSelection()` currently writes one mutable:

```lua
self.QueuedSpellTargetSelection
```

and identifies it primarily by `spellRef`.

That is unsafe as a general parallel-autopilot contract because several NPCs in one cohort can cast the same spell with different targets.

Autopilot must not rely on several outstanding values in this single slot.

---

## 17.2 Required explicit-caster execution API

Introduce a programmatic API, conceptually:

```lua
Client:ExecuteEventUnitSpell({
    casterEventId = npc.eventID,
    spellRef = spellRef,
    activationSnapshot = snapshot,
    targetSelections = targetSelections,
    targetSelectionOrder = groupOrder,
    source = "autopilot",
})
```

Responsibilities:

```text
verify current event/turn/tick
verify explicit caster is active and eligible
revalidate activation snapshot
revalidate selected targets against canonical candidate policies
apply existing spell costs/cooldowns
create cast entry with explicit casterEventId
start/complete through existing spell lifecycle
use existing NPC authority/comms path
```

Manual Action Bar casting may continue using its existing UI wrappers, but both paths should converge on the same lower-level execution function.

---

## 17.3 Do not duplicate combat execution

Autopilot must not directly call Damage/Heal effect contracts as a shortcut.

The existing lifecycle already provides:

- start/end resource costs;
- cooldowns and charges;
- conditions;
- cast times;
- cast state;
- combat effects;
- threat generation;
- resource deltas;
- combat log entries;
- network authority;
- interrupt behavior.

Autopilot chooses an action.

The spellcasting system executes it.

---

# 18. NPC Spellcast Authority

`server/server_Spellcasting.lua` already supports NPC spellcast authority and validates the sender against the NPC controller/host relationship.

No new "AI authority" network identity is required.

Autopilot-generated casts should remain ordinary:

```text
authorityType = "npc"
```

Participant clients receive and process them exactly like manually controlled NPC casts.

This is preferable to adding an `AUTOPILOT_CAST` opcode.

---

# 19. Plan Execution Queue

A cohort plan is frozen first, then executed in stable member order.

Example:

```lua
AutopilotPlan {
    eventId = "...",
    turnNumber = 4,
    tickNumber = 2,
    actorKey = "marker:4",

    movement = { ... },

    actions = {
        {
            casterEventId = 21,
            spellRef = "dataset:slash",
            targetSelections = ...,
        },
        ...
    },

    status = "planned",
}
```

---

## 19.1 Idempotence

Key every plan by:

```text
eventId : turnNumber : tickNumber : actorKey
```

The host can receive several state refreshes for the same step.

That must not make NPCs cast twice.

Plan states:

```text
planned
executing
completed
cancelled
failed
```

A plan already in `executing` or `completed` must never be regenerated merely because the EventWidget refreshed.

---

## 19.2 Stale-work guards

Existing turn commit code already guards deferred work with event/turn/tick/generation identity.

Autopilot must use the same pattern.

Before each execution:

```text
same event?
same turn?
same tick?
actor still active on this step?
caster still active?
target still valid?
```

If the event has advanced, discard the stale action.

---

## 19.3 Invalid target during sequential resolution

Because planning is simultaneous but execution is sequential, an earlier action can kill or otherwise invalidate a later planned target.

In that case:

```text
revalidate
target invalid
→ skip the planned action
```

Do not perform a full mid-cohort tactical replan.

That preserves the frozen-plan semantics and prevents execution ordering from changing the intended simultaneous decision.

---

# 20. Turn Summary Integration

Issue #100 proposes retained structured event-widget banner history.

Issue #101 proposes a host-only Turn Summary view filtered to the current `turnNumber`.

NPC Autopilot should extend that host-only view rather than creating another window.

---

## 20.1 Turn Summary becomes a composite provider

Introduce a provider such as:

```lua
Client:GetTurnSummaryEntries(eventState)
```

which can return:

```text
host-local autopilot directives for the current turn
+
current-turn combat-log/banner history from #101
```

The existing Turn Summary side panel remains the one presentation surface.

---

## 20.2 Autopilot directives must remain host-only

Do **not** send movement instructions through the existing `COMBAT_LOG` opcode.

If this were done, participants would receive DM-only instructions such as:

```text
Move {cross} near Player A.
```

and they could appear in participant Combat Logs.

Instead maintain a local event-scoped collection:

```lua
AutopilotSummaryByEventId[eventId]
```

with structured entries:

```lua
{
    turnNumber = 4,
    tickNumber = 2,
    summaryType = "movement",
    actorKey = "marker:4",
    text = "Move {cross} near Player A and Player B.",
}
```

and:

```lua
{
    turnNumber = 4,
    tickNumber = 2,
    summaryType = "action",
    casterEventId = 21,
    targetEventIds = { 5 },
    spellRef = "dataset:slash",
    text = "[NPC 1] attacks Player A.",
}
```

These entries are consumed only by the host Turn Summary provider.

---

## 20.3 Suggested summary wording

Movement:

```text
Move {cross} near Player A, Player B.
Move [Unmarked NPC] near Player C.
```

Damage:

```text
[NPC 1] attacks Player A with [Cleave].
[NPC 2] attacks Player B with [Fire Bolt].
```

Healing:

```text
[NPC 3] heals [NPC 1] with [Mend].
```

No action:

```text
[NPC 4] takes no action — no valid spell or target.
```

Capability problem:

```text
Autopilot paused — position unavailable for Player A.
```

Keep the default Turn Summary concise. Detailed AI scores belong in internal debug logging, not the DM-facing summary.

---

# 21. Combat Log Interaction

Autopilot actions themselves already generate normal RPE combat-log/event-widget entries because they execute ordinary spells.

Therefore the host may see both:

```text
Autopilot directive:
[NPC 1] attacks Player A with [Cleave].

Normal resolved combat entry:
[NPC 1] hits Player A for 14 Health.
```

This is desirable.

The directive explains intended behavior.

The normal combat log records the actual resolved result.

---

# 22. Event Manager UI

Add a section in Event Manager settings:

```text
NPC AUTOPILOT

[ ] Enable NPC Autopilot

NPC Autopilot automatically chooses NPC spells and targets.
NPCs sharing a raid marker act as one cohort.

WARNING:
Autopilot uses WoW party/raid world coordinates and does not
work in dungeons, raids, battlegrounds or arenas.
```

When the setting is enabled, optionally show current capability:

```text
Available
Unavailable: Instanced content
Unavailable: Party/raid position data unavailable
```

Do not hide the restriction in a tooltip only.

The warning must be visible before event start.

---

# 23. Event Widget Behavior

For the host:

```text
[ Combat Log ] [ Turn Summary ]
```

continues to follow issue #101.

Autopilot does not require another button.

When an autopilot cohort becomes active:

1. the host generates/fetches the frozen plan;
2. Turn Summary immediately refreshes with the movement/action directives;
3. normal combat banners continue to arrive as execution resolves.

Participants see only the existing participant UI and Combat Log behavior.

---

# 24. Manual Host Control and Event Advancement

NPC Autopilot automates NPC decisions/actions.

It does **not** automatically advance the event.

After the active NPC cohort has resolved:

```text
host reviews Turn Summary
host physically moves any represented raid marker
host handles narrative consequences
host presses Advance
```

This preserves DM pacing.

---

## 24.1 Manual override

Phase 1 does not require per-action "approve/deny" controls.

However, autopilot must not double-act a unit if the host manually performs an action for that NPC on the same step before the automatic action is committed.

Maintain a step action ledger:

```lua
actedByCasterEventId[casterEventId] = true
```

and consult existing local interaction/cast state where useful.

A caster already recorded as having acted for the current autopilot step is skipped.

Future versions can expose explicit pause/override buttons.

---

# 25. Cooldowns, Cast Times and Auras

Autopilot must not special-case these systems.

If the chosen spell has a cast time:

```text
autopilot starts the cast
existing active-cast runtime tracks it
existing turn advancement progresses it
existing completion path resolves it
```

If a spell is on cooldown, lacks charges, lacks resources or fails conditions:

```text
canonical activation snapshot says canCast = false
→ planner excludes it
```

Auras continue to modify normal RPE combat and spell legality through existing systems.

---

# 26. Threat Behavior

No new threat rules are required.

Autopilot reads the threat state already maintained by combat.

Damage execution continues to generate threat through the normal Damage path and synchronize it through resource-delta threat updates.

This creates a natural loop:

```text
Player A damages NPC
        ↓
NPC threatTable[Player A] increases
        ↓
Next NPC autopilot turn
        ↓
Player A becomes more likely to be primary target
```

This is exactly the desired target-selection feedback.

---

# 27. Performance Requirements

Autopilot planning must be lightweight.

The current performance work in RPE already treats event/turn/spell operations as frame-time-sensitive. Autopilot must not reintroduce large synchronous scans.

Target budgets:

```text
player token/position snapshot: <= 2 ms typical
one NPC evaluation: <= 1 ms typical
one normal cohort plan: <= 4 ms target
no autopilot planning slice > 8 ms
```

For large cohorts, use the existing TaskQueue/deferred work mechanism to slice planning across frames if necessary.

Do not execute one enormous synchronous loop over every activated Dataset spell.

Only inspect spell refs resolved for the active NPCs.

---

## 27.1 Per-plan caching

Within one planning snapshot cache:

```text
resolved spell definition by spellRef
activation snapshot by caster+spell
health snapshot by eventID
position by eventID/actor key
distance pairs used by AoE/marker solver
expected effect magnitude by caster+spell
```

Discard these caches when the plan is complete.

No global long-lived tactical cache is necessary.

---

# 28. Determinism and Debugging

Every generated plan should be reproducible from its snapshot.

Internal debug logging should support a compact trace:

```text
Autopilot plan event=<id> turn=4 tick=2 actor=marker:4

NPC 21:
  heal: Mend → Ally 26 score=urgent
  damage: Slash → Player 5 expected=14 threat=42
  selected: Mend → Ally 26

NPC 22:
  damage: Cleave → Player 5, Player 8 expected=24
  selected: Cleave

marker:4:
  candidate anchors=4
  selected=(1234.2, 882.1)
  melee-actions-in-range=1/1
```

This logging is diagnostic only and should be behind internal/debug flags.

---

# 29. Runtime Lifecycle

## Event start

```text
Event starts with turnMode=autopilot
        ↓
validate host capability
        ↓
initialize host AutopilotRuntimeByEventId
        ↓
clear previous summary/plans/spatial state
```

## Turn/tick state received on host

```text
event state advances
        ↓
build/resolve current TurnStep
        ↓
does step contain NPC actor(s)?
        ↓ yes
validate capability
sample positions
capture planning snapshot
plan each NPC actor/cohort
freeze plan
publish host-only summary
execute plan once
```

## Event end

Clear:

```text
AutopilotRuntimeByEventId[eventId]
AutopilotSummaryByEventId[eventId]
position caches
planning caches
pending execution tasks
```

The cleanup should be integrated into existing event teardown rather than introducing a second unrelated event lifecycle.

---

# 30. Failure States

The runtime should expose explicit statuses:

```text
off
ready
planning
executing
completed
suspended-instance
suspended-position
cancelled-stale
failed
```

Examples:

### Instance

```text
NPC Autopilot unavailable in instanced content.
Use Manual mode.
```

### Player not in party/raid token map

```text
Autopilot could not resolve Player A's party/raid position.
```

### No legal spell

```text
[NPC 1] takes no action — no usable spell.
```

### No valid target

```text
[NPC 1] takes no action — no valid target.
```

### Stale plan

Do not surface noisy UI for normal stale cancellation caused by the host advancing the turn.

Log it internally and discard it.

---

# 31. Proposed Module Layout

Exact filenames may follow implementation conventions, but responsibilities should remain separated.

```text
core/
  classes/
    Event.lua
      normalize/network turnMode
      mode-aware turn schedule helpers

  internal/
    Movement.lua
      optionally share pure vector/distance helpers

client/
  client_Autopilot.lua
      host runtime coordinator
      event/tick lifecycle
      idempotence
      execution queue

  autopilot/
    Spatial.lua
      party/raid token map
      UnitPosition sampling
      vector/distance helpers
      virtual actor positions
      marker anchor solver

    Planner.lua
      planning snapshot
      cohort planning
      action reservation ledger
      deterministic plan output

    SpellEvaluator.lua
      spell intent extraction
      expected damage/healing
      priority tiers
      resource/cooldown tie-breaks

    TargetSelector.lua
      threat target selection
      heal target selection
      AoE nearest-neighbor selection

    Summary.lua
      host-only structured Turn Summary directives
      formatting

  client_Event.lua
      invoke autopilot when synchronized step becomes active
      cleanup hooks

  client_Targeting.lua
      programmatic explicit-caster target selection/execution facade

  spellcasting/
    Helpers.lua
      mode-aware turn eligibility

    Cooldowns.lua
      explicit-caster activation snapshot support

    Lifecycle.lua
      lower-level explicit-caster cast execution
      avoid one shared queued target-selection dependency

  ui/widgets/
    widget_Event.lua
      composite Turn Summary provider integration
      host autopilot status/warnings if required

server/
  server_Event.lua
      mode-aware total tick calculation
      turn schedule semantics

  ui/eventmanage/
    page_EventManageSettings.lua
      NPC Autopilot setting and explicit no-instance warning

RPEngine_Dev.toc
  add new modules in dependency-safe order
```

---

# 32. Implementation Phases

## Phase 1 — Turn mode and spatial foundation

Implement:

- `Event.turnMode`;
- network normalization;
- Event Manager toggle;
- explicit instance warning;
- host capability check;
- group unit-token resolution;
- player position snapshot;
- host virtual marker/NPC positions;
- pure vector/distance helpers;
- autopilot `TurnActor`/`TurnStep` schedule;
- mode-aware `IsCasterTurnOnTick`;
- oversized atomic cohort handling.

Acceptance:

```text
Manual events behave exactly as before.

Autopilot event cannot silently start with unusable instance coordinates.

All NPCs sharing one raid marker are eligible on the same tick.

No marker cohort is split between ticks.

raidMarker=0 NPCs do not all become one cohort.

Every client agrees on unit turn eligibility.
```

---

## Phase 2 — Spell/target planning

Implement:

- explicit-caster activation snapshot;
- damage/heal intent extraction;
- deterministic expected magnitude;
- urgent/useful heal priorities;
- threat-based enemy selection;
- healing target selection;
- AoE nearest-neighbor selection;
- melee 5-yard rule;
- shared marker anchor solver;
- frozen cohort plan;
- projected healing reservation.

Acceptance:

```text
A critically injured ally causes a legal healing action to outrank damage.

Without meaningful healing need, NPCs choose a legal damage action.

Highest-threat valid enemy is the default hostile primary target.

AoE secondary targets are chosen nearest to the primary target.

A melee action is not accepted from >5 yards after marker placement.

Several NPCs sharing a marker receive one shared virtual position.
```

---

## Phase 3 — Programmatic execution

Implement:

- explicit-caster spell execution API;
- target selections carried with the caster/cast rather than relying on one shared mutable UI queue;
- cohort execution queue;
- per-step action ledger;
- stale plan guards;
- normal NPC authority path;
- idempotence.

Acceptance:

```text
Two cohort NPCs can cast the same spell at different targets safely.

Autopilot does not mutate ControlledEventUnitId to impersonate each NPC.

Autopilot casts use normal resource costs, cooldowns, charges and conditions.

Normal combat effects/threat/resource deltas/combat logs are produced.

Repeated event-state refreshes cannot make an NPC act twice.
```

---

## Phase 4 — Turn Summary integration

Implement against #100/#101:

- host-local autopilot summary history;
- current-turn/current-step filtering;
- movement rows;
- action rows;
- no-action/capability rows;
- composite Turn Summary provider;
- immediate refresh when plan is generated.

Acceptance:

```text
Host sees movement/action instructions in Turn Summary.

Participants never receive autopilot directives.

Participant Combat Log remains ordinary combat/status history.

Actual resolved combat banners still appear normally.

Advancing the turn removes previous-turn directives from the active Turn Summary view.
```

---

# 33. Test Matrix

At minimum cover:

## Turn scheduling

- one unmarked NPC;
- several unmarked NPCs;
- two NPCs sharing one marker;
- three marker cohorts;
- mixed players + marked NPCs + unmarked NPCs;
- marker cohort larger than `max_event_units`;
- inactive/dead cohort member;
- player-shared-turn pet;
- equal initiatives.

## Positioning

- all players have valid positions;
- target >5 yards from current marker;
- two melee targets close enough for one marker;
- two melee targets too far apart;
- player position missing;
- player in different `instanceID`;
- event begins in a dungeon/raid/BG/arena;
- position API becomes unavailable mid-event.

## Decision policy

- healthy allies, damage available;
- one ally at 20% HP;
- one ally at 60% HP with large missing health;
- heal would almost completely overheal;
- no heal spell castable;
- damage spell on cooldown;
- insufficient resource;
- target condition fails;
- all threat values zero;
- clear highest-threat enemy;
- equal threat tie;
- single-target damage;
- multi-target/AoE damage;
- multi-target heal.

## Execution

- two NPCs cast different spells;
- two NPCs cast same spell at different targets;
- instant spells;
- multi-turn cast spells;
- first action kills second action's target;
- stale task after host advances;
- repeated EVENT_STATE for same tick;
- host manually acts before autopilot execution ledger commits.

## UI

- host Turn Summary contains directives;
- participant never sees Turn Summary directives;
- Combat Log contains only normal combat/status entries;
- explicit instance warning visible before start;
- manual event has no autopilot UI noise.

---

# 34. Explicit Non-Goals

Phase 1-4 do not implement:

```text
pathfinding
navmesh generation
terrain collision
line-of-sight simulation
movement speed or maximum NPC movement allowance
exact Blizzard hitbox range
autopilot inside restricted instances
client-side distributed AI
player-character autopilot
LLM/NPC language-model decision making
behavior trees
per-Unit authored AI scripts
aggro rules separate from the existing threat table
new spell range authoring
automatic event advancement
automatic DM narration
general-purpose crowd-control valuation
full tactical valuation of every aura/resource/revert/summon effect
network synchronization of virtual NPC coordinates to participants
```

These can be added later without replacing the proposed host planner/turn actor architecture.

---

# 35. Principal Architectural Decisions

**Autopilot is host-authoritative.**

**Manual events remain unchanged.**

**Autopilot is an explicit Event turn mode because raid-marker cohorts change turn eligibility.**

**Current visual unit pages must no longer be the universal definition of spellcast turn eligibility.**

**NPCs sharing a non-zero raid marker form one atomic turn actor and share one virtual spatial position.**

**Unmarked NPCs remain singleton actors.**

**Marked cohort decisions are planned from one pre-action snapshot and then executed sequentially through normal RPE systems.**

**The existing NPC threat table is the hostile targeting source of truth.**

**Existing Spell components provide enough information for initial damage/heal intent inference.**

**Autopilot does not require new Unit AI metadata in its first version.**

**Spell legality comes from the existing activation snapshot, not duplicated AI checks.**

**Autopilot does not depend on `Spell.range`; melee positioning is inferred from damage components with `damageType = "melee"` and a 5-yard RPE melee rule.**

**AoE targeting uses highest threat for the primary enemy and mathematical proximity for secondary enemies.**

**Healing uses health deficit/effective healing and explicitly outranks damage for critically injured allies.**

**The current one-slot `QueuedSpellTargetSelection` is not a sufficient multi-NPC API; programmatic casting must carry explicit caster and target-selection state.**

**Autopilot actions remain normal NPC spellcasts and therefore reuse cooldowns, costs, combat effects, threat, resource deltas and combat-log output.**

**Autopilot does not automatically advance the event. The host retains pacing control.**

**Autopilot movement/action instructions are host-local Turn Summary data and must not be sent through the participant-visible COMBAT_LOG channel.**

**Issue #101's Turn Summary should become the single host surface for both current-turn combat history and autopilot directives.**

**Autopilot never guesses coordinates when WoW position data is unavailable.**

---

# 36. External WoW API Constraint

The spatial portion of this design relies on the current WoW API behavior documented for:

- `UnitPosition(unit)` — returns group unit world positions in yards and is restricted in instanced dungeon/raid/battleground/arena content:
  https://warcraft.wiki.gg/wiki/API_UnitPosition
- `IsInInstance()` — provides the current instance state/type:
  https://warcraft.wiki.gg/wiki/API_IsInInstance

This restriction is a product constraint, not an RPE bug.

The required user-facing behavior is therefore explicit:

> **NPC Autopilot does not work in instances. Use Manual event mode in dungeons, raids, battlegrounds and arenas.**
