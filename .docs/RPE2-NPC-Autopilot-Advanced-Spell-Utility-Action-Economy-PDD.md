# RPE 2 — NPC Autopilot Advanced Spell Utility and Action Economy
## Product Design Document

**Status:** Proposed  
**Target:** RPEngine 2.0 (`FrontierDev/rpe2`)  
**Current-source baseline inspected:** `dev` at `bf41c95a48f0e05c12dd2e00900a388f85cc3d19`  
**Relationship to existing design:** Additive update to `.docs/RPE2-NPC-Autopilot-PDD.md`  
**Primary objective:** Extend NPC Autopilot so NPCs understand periodic and control-oriented spell effects and can correctly use multiple spells in one turn where RPE's GCD rules allow it.

**In scope:**

- damage-over-time and healing-over-time valuation;
- aura-aware spell evaluation;
- basic control-effect valuation;
- interrupt valuation;
- avoiding redundant aura applications;
- multiple useful off-GCD actions from one NPC;
- one normal GCD action in addition to eligible off-GCD actions;
- projected resource/cooldown/action-economy reservations;
- multiple pending spell actions per NPC;
- deterministic execution ordering;
- corresponding DM Helper presentation.

**Out of scope:**

- authored NPC behavior trees;
- per-NPC AI profiles;
- LLM decision-making;
- full encounter simulation;
- predicting arbitrary future player decisions;
- sophisticated combo planning;
- pathfinding or LOS;
- automatic authorization;
- generic tactical valuation of every possible stat/skill/summon effect;
- changing the existing underlying meaning of `triggersGCD` or `ignoreGCD`.

---

# 1. Purpose

The first NPC Autopilot implementation solves the basic combat loop:

```text
identify usable spell
→ identify legal targets
→ score direct damage/healing
→ solve movement
→ select one action
→ ask the DM to authorize it
```

This is sufficient for NPCs whose spellbooks primarily contain direct attacks and direct heals.

It does not adequately support more complex RPE spellbooks.

Examples include:

```text
Corruption
→ applies an aura
→ deals damage over several turns

Rejuvenation
→ applies an aura
→ heals over several turns

Entangling Roots
→ applies an aura
→ movementRangeOverride = 0

Silence
→ applies an aura
→ preventCasting = true

Interrupt
→ interrupts a spell currently being cast

Battle Cry
→ does not use the GCD

Fireball
→ does use the GCD
```

At present, these create two major limitations.

First, the planner largely sees only **immediate direct damage and healing**. A pure DoT, HoT or control spell may therefore appear to have no tactical value.

Second, Autopilot chooses **one spell per NPC**, even where RPE's spellcasting system permits an NPC to use one or more non-GCD abilities and still perform a normal GCD action.

The next Autopilot update should address both problems without turning the planner into a full combat simulator.

---

# 2. Product Principles

## 2.1 Existing Autopilot invariants remain authoritative

This update must preserve all existing Autopilot requirements:

- host-authoritative planning;
- explicit DM authorization;
- frozen cohort planning snapshots;
- raid-marker cohorts remain spatially indivisible;
- canonical spell legality remains authoritative;
- movement remains DM-confirmed;
- no automatic replanning after ordinary rejection;
- planning remains sliceable;
- manual event behavior remains unchanged;
- Autopilot remains unsupported where required world coordinates are unavailable.

This PDD changes **spell understanding and action economy**, not those foundations.

## 2.2 Understand existing spell data rather than adding AI metadata

The current Spell and Aura models already describe:

- damage;
- healing;
- aura application;
- aura removal;
- resource effects;
- interrupts;
- control effects;
- stat effects;
- skill effects;
- triggered aura events;
- spell cooldowns;
- GCD behavior;
- resources;
- charges;
- targeting.

Autopilot should derive tactical intent from those existing definitions.

Do not add fields such as:

```lua
aiPriority = 5
aiSpellType = "dot"
npcShouldUseWhen = "..."
```

for this update.

The objective remains to produce reasonable behavior from ordinary authored RPE spells.

## 2.3 Planner valuation and combat execution remain separate

The planner may estimate that an aura should deal:

```text
5 damage × 4 expected ticks
```

but it must not actually trigger those ticks while planning.

Expected values are planning-only projections.

Normal spell and aura execution remains responsible for:

- hit checks;
- actual proc rolls;
- actual damage/healing rolls;
- aura application;
- stack handling;
- duration;
- resource expenditure;
- cooldowns;
- spellcasts;
- interrupts;
- combat log output;
- network synchronization.

---

# 3. Current Limitations

## 3.1 Direct effects dominate spell evaluation

`client/autopilot/SpellEvaluator.lua` currently classifies spell components primarily as:

```text
damage
heal
```

and computes expected direct magnitude.

A pure aura spell can therefore produce:

```text
expectedDamage = 0
expectedHealing = 0
```

even though the applied aura may subsequently deal substantial damage, heal allies or control an enemy.

## 3.2 Applied aura effects are not included in tactical utility

Both of these patterns need to be understood:

```text
Spell component:
    type = apply_aura
    auraRef = X
```

and:

```text
Spell component:
    type = damage/heal
    applyAura = true
    auraRef = X
```

The evaluator must resolve the actual Aura definition referenced by the spell and inspect its useful effects.

## 3.3 Control is mechanically supported but tactically invisible

Aura definitions can already contain control state such as:

```lua
preventCasting
movementRangeOverride
cancelOnDamage
forceAutoHitAgainstTarget
```

Existing Autopilot movement already consumes active `movementRangeOverride` state.

However, the planner does not currently understand that **causing** such an effect may itself be useful.

## 3.4 Autopilot currently produces one spell action per NPC

The current planner resolves:

```text
member
→ best candidate
→ one spell action
```

This prevents correct handling of an NPC with:

```text
Off-GCD spell
+
normal GCD spell
```

even where both are independently legal.

---

# 4. Extended Spell Utility Model

Introduce an extended planning representation.

Conceptually:

```lua
SpellUtilityProfile {
    spellRef,

    immediateDamage,
    immediateHealing,

    periodicDamage,
    periodicHealing,

    interruptUtility,
    controlUtility,
    resourceUtility,

    appliedAuras,
    preferredIntent,

    resourceBurden,
    cooldownCommitment,
    chargeCommitment,

    triggersGCD,
    ignoreGCD,
    startsActiveCast,
}
```

Not every field must contribute to every spell.

The profile remains deterministic and read-only.

---

# 5. Periodic Damage and Healing

## 5.1 Pure DoTs and HoTs must become useful candidates

Example:

```text
Corruption
→ apply Corruption aura
→ aura causes 6 damage per turn for 4 turns
```

should no longer have utility zero.

Likewise:

```text
Rejuvenation
→ apply Rejuvenation aura
→ aura heals over several turns
```

must be capable of competing with direct healing spells.

## 5.2 Immediate and periodic value are cumulative

A spell such as:

```text
Flame Shock
12 immediate damage
+
5 damage per periodic trigger
```

receives both:

```text
immediateDamage
+
expectedPeriodicDamage
```

The immediate portion must not be discarded simply because the spell also applies an aura.

The same applies to healing.

## 5.3 Future value is discounted

Future damage/healing should not be treated as equivalent to immediate damage/healing.

Use a deterministic future-value discount.

Conceptually:

```text
tick 1 = 100% value
tick 2 = discounted
tick 3 = further discounted
...
```

A simple geometric discount is sufficient.

Example conceptual implementation:

```lua
value = value + expectedTick * FUTURE_EFFECT_DISCOUNT ^ tickIndex
```

The exact constant should be a single documented Autopilot tuning constant rather than spell-specific metadata.

A value around `0.8` per future trigger is an appropriate initial implementation target.

## 5.4 Chance-based aura effects use expected value

The planner must never roll aura proc RNG.

For a predictable future effect with:

```text
10 damage
50% chance
```

planning value is:

```text
5 expected damage
```

Actual execution still rolls normally.

## 5.5 Only predictable triggered effects are projected

Aura events may react to arbitrary combat events.

Autopilot must not assume:

```text
on spell hit
on melee hit
on critical hit
etc.
```

will occur a particular number of times.

Therefore:

- deterministic periodic/turn-driven triggers may contribute projected future value;
- reactive event effects whose future trigger count cannot be known cheaply should not receive speculative future value;
- if such effects belong to an otherwise useful spell, they still execute normally.

The implementation must trace the existing AuraManager event lifecycle and identify which current event types have a deterministic number of future triggers.

Do not create a second periodic-effect system merely for Autopilot.

## 5.6 Effective periodic damage should avoid obvious overkill

For planning only, useful projected damage should not exceed the target's available projected health where that information is known.

Conceptually:

```lua
effectiveDamage =
    min(expectedDamage, projectedTargetHealth)
```

This prevents a long-duration DoT from appearing exceptionally valuable on a target expected to die almost immediately.

No full future-health simulation is required.

## 5.7 Effective periodic healing should avoid obvious overhealing

Periodic healing should similarly be capped by projected missing health.

Conceptually:

```lua
effectivePeriodicHealing =
    min(expectedPeriodicHealing, projectedMissingHealth)
```

This deliberately remains an approximation.

The planner does not need to predict future incoming damage.

---

# 6. Aura Awareness and Redundant Applications

The planner needs a frozen view of relevant active auras.

For each target, planning should be able to answer:

```text
Is this aura already active?
Who applied it?
How many stacks exist?
How long remains?
What is its stacking behavior?
Would another application add meaningful value?
```

Use the existing AuraManager identity/stacking semantics rather than inventing a simplified aura-key model.

## 6.1 Refresh-duration auras

For:

```text
stackBehavior = refresh_duration
```

reapplying an already healthy aura should be heavily discounted or rejected.

Example:

```text
Corruption has 4 turns remaining
NPC can cast Corruption again
```

should generally produce little or no new utility.

If the aura is near expiration, refreshing it may become worthwhile.

Only the **incremental value gained by refreshing** should count.

## 6.2 Independent-duration stacks

Where the existing aura model allows additional independent stacks:

- another stack may receive value;
- existing stack count must be respected;
- `maxStacks` must be respected;
- projected same-cohort applications must reserve their intended stack.

## 6.3 Projected aura ledger

Add a planning-only aura reservation ledger analogous to projected healing.

Conceptually:

```lua
ProjectedAuraLedger {
    byTargetAndAuraIdentity = {
        ...
    }
}
```

If one NPC in a cohort plans to apply a non-stackable DoT to Player A, another NPC should not independently plan the same redundant application from the same frozen snapshot.

The ledger mutates planning scratch only.

It does not apply any real aura.

---

# 7. Control Effects

Control effects should become selectable even when they deal no direct damage.

Initial support should remain deliberately narrow and deterministic.

## 7.1 Movement control

Recognize aura control effects containing:

```lua
movementRangeOverride
```

Utility depends on the **incremental restriction** produced.

Examples:

```text
target movement allowance 20
spell reduces to 10
→ useful slow

target movement allowance 20
spell reduces to 0
→ strong root

target already restricted to 0
same root applied again
→ little/no new control value
```

Control should be evaluated against the frozen effective control state.

## 7.2 Casting prevention

Recognize:

```lua
preventCasting = true
```

as meaningful hostile control.

It should receive no meaningful value if:

- the target is already prevented from casting by equivalent active control; or
- the aura application would add no additional control duration/stack value.

It should be more attractive against targets for which casting is relevant.

The first implementation may determine casting relevance from existing resolved spell availability rather than introducing class/archetype metadata.

## 7.3 Fragile control

Where:

```lua
cancelOnDamage = true
```

the control effect should receive reduced utility relative to equivalent durable control.

Autopilot should understand that a crowd-control effect which immediately disappears when the target is damaged is less reliable in an active combat situation.

No simulation of future friendly attacks is required.

## 7.4 Control scoring remains bounded

Control must not receive arbitrary enormous equivalent damage values.

The control contribution should be a bounded heuristic bonus based on:

- severity of the restriction;
- whether the target is already equivalently controlled;
- target threat relevance;
- expected control duration;
- whether the control is fragile.

The exact coefficients should be code-level Autopilot constants validated using deterministic fixtures.

Do not add author-facing AI weighting fields in this update.

---

# 8. Interrupts

Interrupts should receive explicit tactical support.

A spell containing an interrupt effect is useful only where an eligible hostile target currently has an interruptible active spellcast.

Target priority:

```text
active caster
→ cast closest to completion / most urgent
→ higher threat
→ eventID
```

The exact ordering should use the reliable cast-state information currently available.

A useful interrupt should normally outrank routine damage.

It should remain below an urgent life-saving heal where the existing urgent-healing threshold is met.

If no valid target is casting:

```text
interruptUtility = 0
```

and a pure interrupt should not be proposed.

---

# 9. Unsupported Utility in This Update

The underlying spell/aura system supports effects which cannot yet be valued cheaply and generically.

The first advanced-utility update does **not** need full tactical understanding of:

- arbitrary stat buffs/debuffs;
- arbitrary skill modifiers;
- summon-pet utility;
- revert effects;
- complex proc chains;
- `forceAutoHitAgainstTarget`;
- arbitrary cross-spell synergy;
- future threat generated by buffs;
- combinations such as "cast damage buff, therefore Fireball becomes 20% stronger".

If such an effect is attached to an otherwise selected spell, it still executes normally.

These can be added incrementally later.

---

# 10. Utility Comparison

The current single `totalUtility` concept should be extended sufficiently to avoid pretending every type of control is simply equivalent to a fixed number of HP.

A candidate should expose a structured breakdown:

```lua
utility = {
    urgentHealing = false,
    urgentInterrupt = false,

    immediateDamage = 0,
    periodicDamage = 0,

    immediateHealing = 0,
    periodicHealing = 0,

    control = 0,
    resource = 0,

    effectiveHealthUtility = 0,
    totalUtility = 0,
}
```

Required ordering behavior:

1. meaningful urgent healing remains highest priority;
2. a valid urgent interrupt can outrank routine damage;
3. direct and periodic damage/healing contribute effective numerical value;
4. meaningful control can cause a control spell to beat a weak routine attack;
5. redundant control/aura applications receive little or no utility;
6. commitment breaks near-ties:
   - lower resource burden;
   - lower cooldown commitment;
   - lower charge commitment;
   - stable spellRef;
   - stable target identity.

The system must remain deterministic.

---

# 11. NPC Action Economy

## 11.1 One candidate is no longer sufficient

Autopilot should produce a **spell sequence per NPC**.

Conceptually:

```text
0..N auxiliary actions
        ↓
0..1 primary/terminal action
```

The sequence is frozen as part of the plan.

## 11.2 Adopt existing canonical GCD semantics

This update does not redefine the existing spell flags.

Current semantics remain authoritative:

### Normal GCD spell

```lua
triggersGCD = true
ignoreGCD = false
```

- obeys an active GCD;
- starts the GCD when used.

### Non-GCD spell

```lua
triggersGCD = false
ignoreGCD = false
```

- does not start the GCD;
- under current canonical behavior, does not require the GCD to be clear.

### Ignore-GCD spell

```lua
ignoreGCD = true
```

- does not start the GCD;
- does not require the GCD to be clear;
- retains the existing one-turn lockout applied to the caster's other `ignoreGCD` spells.

Autopilot must use these existing semantics rather than creating its own definition.

---

# 12. Action Classes

For planning purposes, classify legal spell actions into three categories.

## 12.1 Auxiliary action

A spell may be an auxiliary action when it:

- does not consume the GCD;
- resolves immediately;
- does not begin an active multi-turn cast/channel.

Examples:

```text
instant off-GCD damage
instant off-GCD heal
instant defensive ability
instant control ability
instant ignore-GCD ability
```

Auxiliary actions may be followed by another action.

## 12.2 Primary action

A primary action:

- uses the normal GCD;
- may be instant;
- is the NPC's normal principal action for the turn.

At most one primary action is selected.

## 12.3 Terminal cast action

Any action which begins a persistent active spellcast/channel is terminal for the planned sequence.

This applies regardless of whether it uses the GCD.

Current spell activation blocks a caster which already has an active cast.

Therefore:

```text
instant auxiliary
→ instant auxiliary
→ Fireball begins casting
→ sequence ends
```

is valid.

This is not:

```text
Fireball begins casting
→ off-GCD action afterwards
```

because normal activation would reject the latter while the NPC is casting.

---

# 13. Bounded Auxiliary Actions

Autopilot must not exploit zero-GCD spell definitions to generate an unbounded number of actions.

Initial rule:

```lua
MAX_AUXILIARY_ACTIONS_PER_NPC = 2
```

Therefore an NPC can receive at most:

```text
2 auxiliary actions
+
1 primary/terminal action
```

in one Autopilot planning batch.

Additional safeguards:

- one planned use per `spellRef` per NPC per batch;
- charges do not cause the planner to repeat the same spell multiple times in one batch;
- ordinary cooldown groups remain respected;
- ignore-GCD shared lockout remains respected;
- resource affordability remains respected.

This is an Autopilot planning policy, not a change to manual spellcasting.

---

# 14. Sequence Construction

For every NPC at every candidate marker anchor:

### Step 1 — build legal candidates

Use canonical activation snapshots exactly as today.

### Step 2 — extend candidate utility

Add:

- periodic value;
- aura redundancy;
- control;
- interrupts;
- other supported utility.

### Step 3 — choose the main action

Choose the best:

```text
primary GCD action
OR
terminal cast action
```

Urgent-healing and interrupt priority remain applicable.

The main action is optional.

### Step 4 — reserve the main action

Reserve its:

- resources;
- cooldown group;
- GCD commitment;
- expected healing;
- expected aura applications.

This ensures auxiliary actions do not accidentally consume resources required by the action the planner actually intends as the NPC's main spell.

### Step 5 — choose auxiliary actions

Evaluate auxiliary actions in deterministic utility order.

Select an auxiliary only if it:

- remains legal under projected reservations;
- has positive meaningful utility;
- does not invalidate the reserved main action;
- does not conflict with a previously selected auxiliary;
- does not exceed the auxiliary-action limit.

### Step 6 — order sequence

Execution order:

```text
auxiliary action 1
auxiliary action 2
primary/terminal action
```

The order is frozen.

---

# 15. Projected Action-Economy Ledger

Add a planning-only ledger per NPC.

Conceptually:

```lua
ActionEconomyLedger {
    reservedResources = {},
    reservedCooldownGroups = {},
    reservedSpellRefs = {},
    ignoreGCDCommitted = false,
    primaryGCDCommitted = false,
    terminalCastCommitted = false,
}
```

This must never mutate canonical cooldown/resource state.

## 15.1 Resource reservations

When several actions are selected:

```text
Battle Cry costs 10 rage
Quick Strike costs 20 rage
Mortal Strike costs 30 rage
```

an NPC with 40 rage must not be planned to cast all three.

The reservation system should account for both configured cast-start and cast-end costs where relevant.

## 15.2 Cooldown groups

If one selected action triggers a cooldown group that would lock another selected spell, those actions cannot coexist in the sequence.

Reuse current cooldown-group semantics.

## 15.3 Ignore-GCD lockout

Because the existing runtime applies a one-turn lockout between `ignoreGCD` spells, the sequence builder should normally select at most one such spell.

Do not wait until execution to discover the conflict.

## 15.4 Spell reuse

Do not select the same `spellRef` multiple times in one batch.

This prevents:

```text
zero cooldown
+
no GCD
+
zero resource cost
```

from becoming an unbounded planner loop.

---

# 16. Healing and Aura Reservations Across a Cohort

Existing projected-healing behavior should be generalized to sequences.

If NPC A plans:

```text
off-GCD small heal
+
normal large heal
```

both must contribute to projected healing before later cohort healers choose their actions.

Likewise, planned HoTs must contribute projected useful healing.

The aura ledger should similarly prevent:

```text
NPC A → Corruption on Player 1
NPC B → identical redundant Corruption on Player 1
```

unless the underlying aura stacking model says both applications produce useful additional state.

---

# 17. Target Selection Extensions

## 17.1 DoT targets

For hostile periodic effects:

1. require canonical legal target membership;
2. prefer threat-relevant enemies;
3. avoid targets already carrying an equivalent healthy aura where refreshing adds little value;
4. avoid severe projected overkill;
5. use normal spatial/eventID tie-breaking.

## 17.2 HoT targets

For periodic healing:

1. lower projected health fraction;
2. greater projected missing health;
3. avoid redundant healthy HoTs;
4. account for projected same-cohort healing;
5. stable eventID tie-break.

A HoT does not automatically outrank an urgent direct heal merely because its total lifetime healing is larger.

## 17.3 Control targets

Prefer targets:

- for which the control would actually change current state;
- with greater hostile threat relevance;
- not already under equivalent or stronger control.

AoE control retains existing AoE primary/secondary spatial principles.

## 17.4 Interrupt targets

Consider only currently casting legal hostile targets.

Pure interrupt spells should produce no candidate if there is nothing to interrupt.

---

# 18. Movement Solver Integration

The current shared-marker movement solver selects one best candidate per member at each anchor.

This must become:

```text
one best action sequence per member at each anchor
```

For each candidate shared marker position:

1. filter each spell candidate for spatial feasibility;
2. build the best legal sequence for each active member;
3. aggregate the utility of all selected actions;
4. calculate useful-action coverage;
5. retain urgent-heal/interrupt priority;
6. apply the existing movement/stability penalty;
7. choose the best whole-cohort anchor.

The no-split marker invariant remains unchanged.

## 18.1 Multiple melee actions

If one NPC plans two melee actions, both must be feasible from the same proposed marker location.

Example:

```text
Quick Strike → Player A
Mortal Strike → Player B
```

is valid only where the shared actor position places the NPC within melee range of both targets when each action executes.

Otherwise the sequence builder must choose another combination.

## 18.2 Movement dependencies

Every spell action requiring the proposed marker position continues to carry:

```lua
requiresMovementActionId
```

This now applies independently to every action in the NPC's sequence.

A ranged auxiliary action may therefore be authorizable before movement confirmation while a later melee action remains blocked on movement.

---

# 19. Frozen Snapshot Requirements

Extend the frozen Autopilot snapshot to include the state required for advanced utility.

At minimum:

- active aura records relevant to candidate targets;
- aura definition/ref resolution cache;
- remaining aura duration;
- current stacks;
- stack behavior;
- control state;
- active spellcasts relevant to interrupts;
- spell GCD flags;
- resource state;
- cooldown/charge state;
- cooldown groups;
- expected direct effects;
- expected periodic effects.

The planner must not query mutable live aura/cast state repeatedly while scoring.

Live state is revalidated when the DM authorizes an action.

---

# 20. Pending Action Model

The existing action identity:

```text
plan:spell:<casterEventId>
```

is no longer sufficient.

A caster may now have several spell actions.

Use sequence-aware identity, conceptually:

```text
<planId>:spell:<casterEventId>:<sequenceIndex>
```

Each spell action should include:

```lua
{
    actionType = "spell",

    actionId,
    planId,

    casterEventId,
    spellRef,

    casterSequenceIndex,
    casterSequenceCount,

    actionEconomyClass, -- auxiliary | primary | terminal

    previousCasterActionId,

    requiresMovementActionId,

    targetSelections,

    status,
}
```

The existing pending-plan infrastructure may continue to store these in:

```lua
actionsById
orderedActionIds
spellActionIds
```

No second authorization system is required.

---

# 21. Authorization Ordering

Every spell still requires explicit DM authorization.

For one NPC:

```text
Action 1
↓
Action 2
↓
Action 3
```

Only the earliest unresolved spell action should normally be authorizable.

## 21.1 Completing an action

When an instant action completes:

```text
Action 1 = completed
→ Action 2 becomes authorizable
```

## 21.2 Rejecting an action

If the DM explicitly rejects an auxiliary action:

```text
Action 1 = rejected
→ Action 2 may become authorizable
```

This is safe because the first version does not plan positive cross-spell synergies in which Action 2 requires Action 1's buff.

## 21.3 Failed or stale action

If an action fails or becomes stale during execution:

- do not automatically continue the remaining same-caster sequence;
- later actions become blocked/stale as appropriate;
- expose Replan.

This prevents a sequence from blindly continuing after its projected resource/cooldown assumptions have diverged from reality.

---

# 22. Authorize All

`Authorize All` must respect:

1. movement dependencies;
2. NPC sequence order;
3. deterministic actor/member order.

For each NPC:

```text
auxiliary 1
→ auxiliary 2
→ primary/terminal
```

must remain ordered.

If a same-caster action fails/stales:

```text
stop automatic authorization for that caster
```

Other unaffected NPC sequences may continue if their own state remains valid.

A persistent cast is always terminal, so Authorize All must never attempt another action for that NPC after starting it.

---

# 23. Execution and Live Revalidation

Every individual action continues through the existing canonical execution path.

Immediately before execution:

```text
re-resolve activation
→ validate caster
→ validate turn
→ validate active cast
→ validate resources
→ validate cooldown/GCD
→ validate targets
→ validate movement dependency
→ execute
```

The projected action-economy ledger is **not** authority.

It merely prevents the planner from intentionally building impossible sequences.

Canonical execution remains final authority.

---

# 24. DM Helper Presentation

Multiple actions need to be visually understandable.

Example:

```text
{cross}: Move near Player A.                 [Confirm Moved] [Skip]

[NPC Mage]
  1. [Arcane Surge] — Off GCD                [Authorize] [Reject]
  2. [Fireball] → Player A                   [Authorize] [Reject]

[NPC Warlock]
  1. [Corruption] → Player B — DoT           [Authorize] [Reject]

[NPC Priest]
  1. [Renew] → NPC Mage — HoT                [Authorize] [Reject]
```

Later sequence actions may show:

```text
Waiting for previous action
```

rather than appearing independently authorizable.

Useful compact annotations:

```text
Off GCD
DoT
HoT
Interrupt
Control
Casting
```

These annotations are explanatory UI only.

They must not become new spell metadata.

---

# 25. Planner Explainability

Advanced utility makes decisions less obvious.

Debug/planner records should therefore retain a lightweight utility breakdown.

Example:

```lua
{
    immediateDamage = 10,
    periodicDamage = 18.4,
    controlUtility = 0,
    urgentHealing = false,
    totalUtility = 28.4,
}
```

or:

```lua
{
    interruptUtility = ...,
    reason = "target-casting",
}
```

The DM Helper does not need to display raw scoring numbers by default.

Debug output should make them inspectable when diagnosing selection behavior.

---

# 26. Sliceability and Performance

This update expands the candidate space substantially.

All new work must remain inside the existing sliceable planner.

Loops requiring yield boundaries include:

- resolving aura definitions;
- inspecting aura components/events;
- active-aura lookup;
- periodic-effect projection;
- control evaluation;
- interrupt candidate inspection;
- action sequence building;
- projected ledger checks;
- per-anchor sequence evaluation.

Required per-plan caches:

```text
aura definition by ref
active aura state by target/ref
periodic utility by spell/target
control utility by spell/target
active cast state by target
spell utility profile
action sequence by member/anchor
```

Do not repeatedly resolve the same Aura definition for every anchor.

## 26.1 Bounded search

Do not evaluate the unrestricted power set of all off-GCD spells.

Use the bounded sequence algorithm described above:

```text
choose main action
→ reserve main action
→ greedily select up to 2 compatible auxiliary actions
```

using deterministic candidate order.

This keeps planning complexity predictable.

---

# 27. Likely Code Changes

Primary expected files:

```text
client/autopilot/SpellEvaluator.lua
client/autopilot/TargetSelector.lua
client/autopilot/MovementSolver.lua
client/autopilot/PlannerIntegration.lua
client/autopilot/Authorization.lua
client/autopilot/Execution.lua
client/autopilot/Helper.lua
client/ui/widgets/widget_Event_AutopilotHelper.lua
```

Likely new modules:

```text
client/autopilot/AuraEvaluator.lua
client/autopilot/ActionEconomy.lua
```

Potential canonical helpers may need factoring from:

```text
client/spellcasting/Cooldowns.lua
client/spellcasting/AuraManager.lua
```

However:

- do not change generic GCD semantics merely for Autopilot;
- do not duplicate cooldown logic;
- do not duplicate AuraManager stacking/control semantics.

No Spell or Aura database schema change should be necessary.

---

# 28. Proposed Module Responsibilities

## `AuraEvaluator.lua`

Responsible for planning-only interpretation of existing Aura definitions:

- resolve aura;
- inspect damage/healing/control;
- determine predictable future triggers;
- estimate periodic utility;
- inspect current application/stack state;
- calculate refresh/incremental value;
- expose control contribution;
- never mutate AuraManager state.

## `ActionEconomy.lua`

Responsible for:

- classifying candidate actions;
- identifying auxiliary/primary/terminal actions;
- projected resource reservations;
- cooldown-group reservations;
- ignore-GCD reservation;
- same-spell deduplication;
- auxiliary action cap;
- deterministic sequence construction.

## `SpellEvaluator.lua`

Remains responsible for:

- direct spell effects;
- merging AuraEvaluator output;
- final candidate utility;
- commitment/tie-breaking.

## `MovementSolver.lua`

Moves from:

```text
best candidate per member
```

to:

```text
best compatible sequence per member
```

at each anchor.

---

# 29. Required Regression Behavior

Existing basic cases must remain unchanged.

### Direct melee NPC

```text
Strike only
→ chooses Strike
```

### Direct spell NPC

```text
Fireball stronger than Strike
→ chooses Fireball
```

### Urgent healer

```text
ally <= 50% health
→ meaningful heal outranks ordinary damage
```

### Same-marker cohort

```text
all members remain on one shared virtual coordinate
```

### Immobilized marker member

```text
entire marker remains pinned
```

### Manual event

```text
no Autopilot behavior changes
```

---

# 30. New Required Behavior Examples

## 30.1 Pure DoT

NPC has:

```text
Strike: 10 immediate damage
Corruption: 6 damage × several future triggers
```

Where Corruption's discounted expected useful damage exceeds Strike:

```text
→ Corruption may be selected
```

## 30.2 Existing DoT

Target already has a healthy equivalent Corruption:

```text
→ Corruption receives only incremental refresh/stack value
→ ordinary damage may win instead
```

## 30.3 Pure HoT

Injured ally can benefit meaningfully from Renew:

```text
→ Renew has healing utility
```

Full-health ally:

```text
→ Renew receives little/no useful healing value
```

## 30.4 Root

Hostile target has unrestricted movement:

```text
Root applies movementRangeOverride = 0
→ meaningful control candidate
```

Target already rooted:

```text
→ repeated equivalent root heavily discounted
```

## 30.5 Interrupt

Player A is casting:

```text
NPC has Kick
→ Kick becomes a high-priority candidate
```

No enemy is casting:

```text
→ Kick has zero utility
```

## 30.6 Off-GCD + normal attack

NPC has:

```text
Quick Strike
triggersGCD = false
instant
8 damage

Heavy Strike
triggersGCD = true
20 damage
```

Expected plan:

```text
Quick Strike
→ Heavy Strike
```

provided resources/cooldowns permit both.

## 30.7 Ignore-GCD alternatives

NPC has:

```text
Ability A: ignoreGCD
Ability B: ignoreGCD
Fireball: normal GCD
```

Because the canonical runtime makes ignore-GCD abilities mutually lock each other for a turn:

```text
choose best of A/B
→ Fireball
```

not:

```text
A
→ B
→ Fireball
```

## 30.8 Resource conflict

NPC has 30 mana:

```text
Off-GCD spell: costs 20
Main heal: costs 20
```

The planner must not select both.

If the heal is the preferred main action:

```text
reserve heal first
→ omit incompatible auxiliary
```

## 30.9 Timed off-GCD cast

NPC has:

```text
Channel X
does not use GCD
but creates active cast

Strike
normal GCD
```

Channel X is a terminal action.

It cannot be planned as:

```text
Channel X
→ Strike
```

because the canonical runtime will consider the NPC already casting.

---

# 31. Validation Matrix

Deterministic tests/mocks should cover at minimum:

1. pure direct damage unchanged;
2. pure direct healing unchanged;
3. mixed immediate + DoT utility;
4. pure DoT becomes selectable;
5. pure HoT becomes selectable;
6. future-effect discount;
7. chance-based periodic expected value without RNG;
8. periodic overkill cap;
9. periodic overheal cap;
10. refresh-duration aura already healthy;
11. near-expiry aura refresh;
12. independent-duration stack addition;
13. max-stack rejection;
14. projected same-cohort aura reservation;
15. movement slow against unrestricted target;
16. root against unrestricted target;
17. redundant root against rooted target;
18. fragile control discounted;
19. interrupt with active hostile cast;
20. interrupt with no active cast;
21. normal GCD spell while GCD clear;
22. normal GCD spell while GCD active;
23. non-GCD instant action during existing GCD;
24. ignore-GCD action during existing GCD;
25. ignore-GCD peer lockout prevents two selected ignore-GCD actions;
26. non-GCD auxiliary + normal primary;
27. two compatible auxiliaries + primary;
28. more than two auxiliaries respects cap;
29. same spell cannot repeat in one batch;
30. auxiliary resource reservation;
31. cooldown-group conflict;
32. auxiliary cannot starve reserved main action;
33. timed non-GCD action treated as terminal;
34. multiple actions receive unique action IDs;
35. second same-caster action blocked until first resolves;
36. rejection unlocks next action;
37. completed instant unlocks next action;
38. execution failure stops remaining same-caster sequence;
39. Authorize All follows sequence order;
40. live canonical revalidation still rejects stale resources/cooldowns/targets;
41. multiple actions correctly carry movement dependencies;
42. marker cohort remains spatially indivisible;
43. planner remains sliceable under large spell/aura sets;
44. no planning operation mutates real aura/resource/cooldown state;
45. manual event behavior unchanged.

---

# 32. Acceptance Criteria

The update is complete when:

- [ ] Pure DoT spells can receive useful tactical value.
- [ ] Pure HoT spells can receive useful tactical value.
- [ ] Immediate and periodic effects are valued together.
- [ ] Future effects are discounted deterministically.
- [ ] Predictable chance-based periodic effects use expected value without RNG.
- [ ] Existing aura state prevents obvious redundant reapplication.
- [ ] Aura stacking/refresh behavior follows canonical AuraManager semantics.
- [ ] Basic movement-control effects receive tactical value.
- [ ] Existing equivalent control reduces redundant control utility.
- [ ] Interrupts are proposed against valid active casts.
- [ ] Pure interrupts are not proposed when nothing can be interrupted.
- [ ] An NPC may receive useful off-GCD actions plus a normal GCD action.
- [ ] No NPC receives more than two auxiliary actions in one batch.
- [ ] The same spell is not repeatedly selected within one batch.
- [ ] Current `ignoreGCD` mutual lockout semantics are respected.
- [ ] Projected resources prevent impossible same-turn spell sequences.
- [ ] Cooldown-group conflicts are respected.
- [ ] Persistent casts terminate the same-caster sequence.
- [ ] Every spell action still requires explicit DM authorization.
- [ ] Multiple actions from one NPC have unique stable action IDs.
- [ ] Same-caster actions are authorized/executed in frozen sequence order.
- [ ] Every action is revalidated against canonical live spell state before execution.
- [ ] Movement dependencies continue to work independently for each spell action.
- [ ] Marker cohorts remain spatially indivisible.
- [ ] All new planning work remains sliceable and bounded.
- [ ] No spell/aura database AI metadata is required.
- [ ] Manual mode remains behaviorally unchanged.

---

# 33. Recommended Implementation Sequence

## Phase 1 — Aura utility foundation

Implement:

- Aura resolution cache;
- periodic damage/healing projection;
- active aura inspection;
- refresh/stack incremental utility;
- projected aura ledger.

No multi-action changes yet.

## Phase 2 — Control and interrupt utility

Implement:

- movement control;
- prevent-casting control;
- fragile-control adjustment;
- interrupt target detection;
- deterministic control/interrupt comparison.

## Phase 3 — Action economy

Implement:

- action classification;
- projected action-economy ledger;
- auxiliary cap;
- main-action reservation;
- compatible sequence builder.

## Phase 4 — Movement integration

Change marker-anchor evaluation from:

```text
one action per member
```

to:

```text
one action sequence per member
```

while preserving all existing shared-marker invariants.

## Phase 5 — Pending authorization and execution

Implement:

- sequence-aware action IDs;
- same-caster order metadata;
- authorization gating;
- ordered Authorize All;
- failure/stale propagation.

## Phase 6 — DM Helper

Render:

- multiple actions per NPC;
- sequence order;
- Off GCD / DoT / HoT / Interrupt / Control annotations;
- waiting/blocking states.

## Phase 7 — Integration hardening

Exercise the full regression matrix, review performance instrumentation, and verify that no new combat execution or aura semantics have leaked into the planner.

---

# 34. Final Intended Behavior

After this update, an NPC should no longer think only in terms of:

```text
Which single direct attack or heal has the largest number?
```

Instead, it should be capable of producing bounded, understandable plans such as:

```text
[NPC Warlock]
Apply Corruption to Player A.
Then cast Shadow Bolt at Player A.
```

or:

```text
[NPC Shaman]
Interrupt Player B's cast.
Then attack Player B.
```

where the interrupt is genuinely off-GCD and both actions are legal, or:

```text
[NPC Priest]
Use an off-GCD emergency heal on NPC 1.
Then cast Renew on NPC 1.
```

or:

```text
[NPC Controller]
Root Player A.
```

when control is tactically more useful than its available routine attack.

The planner remains intentionally lightweight:

```text
understand existing effects
→ estimate useful value
→ build a bounded legal sequence
→ solve shared movement
→ present the frozen plan
→ require DM authorization
→ execute through canonical RPE systems
```

This retains the existing philosophy of NPC Autopilot: **reduce repetitive DM decision-making without replacing the DM or creating a second combat rules engine.**
