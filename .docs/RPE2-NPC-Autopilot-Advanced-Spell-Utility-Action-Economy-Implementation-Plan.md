# RPE 2 — NPC Autopilot Advanced Spell Utility and Action Economy
## Implementation Plan

**Status:** Proposed implementation sequence  
**Target:** RPEngine 2.0 (`FrontierDev/rpe2`)  
**Target coding model:** 5.6-Luna-ExtraHigh  
**Source design:** `.docs/RPE2-NPC-Autopilot-Advanced-Spell-Utility-Action-Economy-PDD.md`  
**Current-source baseline inspected:** `dev` at `bf41c95a48f0e05c12dd2e00900a388f85cc3d19`  
**Delivery issues:** #141–#148

---

# 1. Objective

Extend the existing NPC Autopilot implementation without replacing its current lifecycle, spatial model, authorization model or canonical spellcasting integration.

The update should make Autopilot capable of:

- valuing predictable damage-over-time and healing-over-time effects;
- inspecting active aura state so it avoids obvious redundant refreshes/stacks;
- assigning bounded tactical value to movement/casting control;
- selecting interrupts when a valid hostile cast exists;
- producing a bounded per-NPC sequence rather than exactly one spell action;
- using eligible instant non-GCD actions before a normal GCD/terminal action;
- respecting current resource, cooldown-group and `ignoreGCD` lockout semantics while constructing the sequence;
- solving shared raid-marker movement against the whole selected sequence;
- publishing several stable pending actions for one caster;
- preserving explicit DM authorization and live canonical revalidation for every individual action;
- displaying the resulting sequence clearly in DM Helper;
- remaining deterministic, sliceable and side-effect-free during planning.

Manual event behavior must remain unchanged.

---

# 2. Current Source Findings

The implementation must begin from current source, not from older PDD assumptions.

## 2.1 Current spell utility is direct-only

`client/autopilot/SpellEvaluator.lua` currently:

- classifies `damage` and `heal` spell components;
- computes deterministic expected direct damage/healing;
- computes resource/cooldown/charge commitment;
- caps immediate useful healing through the projected-healing ledger;
- gives urgent healing priority;
- compares candidates by utility, then commitment, then stable IDs.

It does not resolve an applied Aura definition and therefore does not currently value pure DoT/HoT/control spells.

## 2.2 Planner candidates are generated through canonical activation

`client/autopilot/PlannerIntegration.lua` currently:

```text
snapshot units
→ snapshot positions
→ snapshot resolved spell refs
→ snapshot movement
→ BuildSpellActivationSnapshot(..., casterEventId, includeTargetCandidates=true)
→ BuildSpellProfile
→ TargetSelector
→ build candidate
→ solve actors
→ revalidate
→ finalize
```

The advanced update must retain this canonical activation path. Do not create another cooldown/resource/condition/target-legality implementation.

## 2.3 Current action candidate contains one selected action per member

`client/autopilot/MovementSolver.lua` currently evaluates each anchor and stores one `evalBestCandidate` per active member. `PlannerIntegration.finalizeMarkedActor()` then converts that selected candidate to one spell action.

This is the main tactical integration seam that must eventually change from:

```text
best candidate per member
```

to:

```text
best bounded action sequence per member
```

## 2.4 Current action IDs assume one spell per caster

`PlannerIntegration.buildSpellAction()` currently creates:

```text
<planId>:spell:<casterEventId>
```

This is not unique once one caster can have multiple actions.

`Authorization.lua` already stores actions generically in:

```lua
actionsById
orderedActionIds
spellActionIds
```

so the existing pending-plan container can be extended rather than replaced.

## 2.5 Current execution already re-resolves live canonical spell state

`client/autopilot/Execution.lua::ExecuteEventUnitSpell()` revalidates:

- current plan/event/turn/tick/actor identity;
- current caster activity/alive/controller state;
- current turn eligibility;
- movement dependency;
- a fresh explicit-caster activation snapshot;
- current canonical target candidates and target policy.

This must remain the final authority for every action in a sequence.

## 2.6 Current GCD semantics must be reused, not redesigned

`core/classes/Spell.lua` defaults:

```lua
triggersGCD = true
ignoreGCD = false
```

and normalizes `ignoreGCD = true` to `triggersGCD = false`.

`client/spellcasting/Cooldowns.lua` currently:

- blocks only spells which use the global cooldown when GCD is active;
- applies GCD when a spell uses it;
- permits non-GCD and ignore-GCD spells while a GCD exists;
- applies a one-turn external lockout from one `ignoreGCD` spell to other `ignoreGCD` spells owned by the caster.

Autopilot sequence construction must project these current semantics. Do not change them in this update.

## 2.7 AuraManager is the canonical aura/control source

`client/spellcasting/AuraManager.lua` already owns:

- active aura records;
- aura identity;
- stacking and duration;
- runtime aura definitions;
- control-state aggregation;
- event-triggered effects;
- normal application/removal/proc execution.

Advanced planning may copy/interpret current aura state, but must not create another runtime aura system.

## 2.8 Current load order

The current TOC loads:

```text
client/autopilot/Spatial.lua
client/autopilot/SpellEvaluator.lua
client/autopilot/TargetSelector.lua
client/autopilot/Planner.lua
...
client/spellcasting/Cooldowns.lua
client/spellcasting/Lifecycle.lua
client/spellcasting/AuraManager.lua
client/autopilot/MovementAllowance.lua
client/autopilot/MovementSolver.lua
...
client/autopilot/PlannerIntegration.lua
client/autopilot/Authorization.lua
client/autopilot/Execution.lua
```

If `AuraEvaluator.lua` or `ActionEconomy.lua` are introduced, their load order must satisfy their actual dependencies. Do not simply insert them beside the conceptual module they resemble if they call APIs loaded later.

A narrow helper may need to depend only on Registry/database structures rather than `AuraManager` itself so it can load near `SpellEvaluator`; alternatively load the evaluator after AuraManager and ensure `PlannerIntegration` sees it. Inspect current dependency usage before editing the TOC.

---

# 3. Non-Negotiable Architectural Constraints

1. **Read current source for every issue.** The baseline above is informational only; implementation must inspect the current branch immediately before editing.
2. **Planning remains read-only.** No planned utility calculation may roll combat RNG, apply an aura, alter resources, start cooldowns or create spellcasts.
3. **Canonical spell activation remains authoritative.** Do not recreate cast legality inside Autopilot.
4. **Canonical aura semantics remain authoritative.** Do not invent an Autopilot-only aura identity/stack system.
5. **Current GCD semantics remain authoritative.** This implementation consumes `triggersGCD`, `ignoreGCD`, cooldown groups and resource costs; it does not redefine them.
6. **Action economy is bounded.** Maximum initial design is two auxiliary actions plus one primary/terminal action per NPC per batch.
7. **One use per spellRef per NPC per batch.** Charges do not permit repeated same-spell planner loops in this update.
8. **A persistent cast is terminal for the sequence.** Once an action would create a live spellcast/channel, the planner selects no later same-caster action.
9. **Marked cohorts never split.** Every selected melee action in a sequence must be feasible from the same one marker position.
10. **Every spell action remains explicitly DM-authorized.** Sequence planning does not imply automatic execution.
11. **Execution revalidates each action live.** Projected ledgers are optimization/planning constraints, never authority.
12. **No automatic tactical replan after rejection/failure.** Existing explicit Replan remains the recovery operation.
13. **All added combinatorial work remains sliceable/bounded.** Do not increase global TaskQueue budget.
14. **No author-facing AI metadata.** No `aiPriority`, archetype, behavior tree or per-spell AI tuning schema in this update.
15. **Manual mode remains unchanged.** Any generic helper factoring must preserve manual/player spell behavior.

---

# 4. Delivery Graph

```text
#141 Frozen aura/cast context + AuraEvaluator foundation
   ├──────────────┐
   ↓              ↓
#142 Periodic     #143 Control + interrupt
utility/ledger     utility
   └───────┬──────┘
           ↓
#144 Bounded off-GCD action-sequence planning
           ↓
#145 Sequence-aware shared-marker movement/planner integration
           ↓
#146 Ordered multi-action authorization/execution
           ↓
#147 DM Helper sequence presentation
           ↓
#148 Integration hardening/performance/regression pass
```

#142 and #143 may be implemented independently after #141 if desired. #144 should consume the richer candidate shape but can be developed against deterministic mock candidates. #145 is the first issue that changes production output from one action per NPC to several.

---

# 5. Task A — Issue #141: Frozen Aura/Cast Context and AuraEvaluator Foundation

## Goal

Create the read-only planning foundation needed by later periodic/control/interrupt scoring without changing current candidate selection behavior yet.

## Primary current files

- `client/autopilot/PlannerIntegration.lua`
- `client/autopilot/SpellEvaluator.lua`
- `client/spellcasting/AuraManager.lua`
- `core/classes/Aura.lua`
- `core/classes/Spell.lua`
- `RPEngine_Dev.toc`

Potential new file:

- `client/autopilot/AuraEvaluator.lua`

## Work

### Freeze relevant aura state

Extend planner scratch/snapshot support so advanced evaluation can inspect a stable copy of active aura state relevant to candidate targets.

At minimum preserve enough data to derive:

```text
aura identity/ref
dataset context where required
caster event ID
target event ID
current stacks
remaining duration/turns
stack behavior/max stacks
resolved definition/ref
control state relevant to the target
```

Do not copy the whole live AuraManager bucket blindly if narrower immutable records are sufficient.

### Freeze active spellcast summary for target-side interrupt decisions

Capture current active cast information required to answer whether a target is casting and, where available, urgency/remaining turns.

Do not attach new Autopilot identity to casts.

### Aura definition resolution/cache

Provide a per-plan lookup/cache that resolves an applied `auraRef` through the same registry/dataset rules as normal spell/aura execution.

Support both application patterns:

```text
component.effect.type = apply_aura
```

and:

```text
damage/heal component with applyAura = true
```

### Read-only profile API

Expose a deterministic API capable of returning a normalized aura planning profile without scoring it yet, conceptually:

```lua
AuraEvaluator.BuildAuraProfile(...)
```

including:

- damage/heal effects present;
- control effects present;
- triggered-event descriptors;
- duration/stacking metadata;
- no side effects.

### Sliceability

Any scan over active auras or event definitions which can grow with datasets/targets must fit the existing resumable planner or be pre-indexed/cached in bounded work.

## Explicitly not in scope

- periodic future-value math;
- refresh utility;
- control score coefficients;
- interrupt prioritization;
- multiple actions per NPC;
- authorization/UI changes.

## Validation

Exercise deterministic fixtures for:

1. pure `apply_aura` spell resolves its Aura definition;
2. damage/heal `applyAura` resolves the same definition path;
3. active aura copies retain caster/target/stacks/duration identity;
4. `refresh_duration` and `independent_duration` remain distinguishable;
5. control flags are read without mutating live control state;
6. active target cast summary can be frozen without changing cast state;
7. repeated aura refs hit the per-plan cache;
8. no planning call applies/removes/advances an aura;
9. current direct-only Autopilot choices remain unchanged.

---

# 6. Task B — Issue #142: Periodic Damage/Healing Utility and Projected Aura Reservations

## Goal

Make predictable DoT/HoT effects participate in deterministic spell utility while avoiding obvious redundant applications.

## Depends on

- #141

## Primary current files

- `client/autopilot/AuraEvaluator.lua`
- `client/autopilot/SpellEvaluator.lua`
- `client/autopilot/PlannerIntegration.lua`
- `client/autopilot/TargetSelector.lua`

## Work

### Predictable periodic effects

Trace the actual AuraManager event lifecycle and identify which current aura event triggers have a deterministic future cadence that can safely be projected.

Do not assume arbitrary reactive events fire once per turn.

For predictable triggers:

```text
expected effect magnitude
× proc probability
× future-value discount
```

Do not roll RNG.

### Discount future value

Introduce one code-level planning constant, initially targeting:

```lua
FUTURE_EFFECT_DISCOUNT = 0.8
```

Document it and keep it out of Spell/Aura authoring metadata.

### Incremental aura value

Use frozen active aura state to score only the value added by another application.

For `refresh_duration`:

- healthy existing aura => low/zero incremental value;
- near-expiry aura => value of newly gained future uptime only.

For `independent_duration`:

- additional stack/application may contribute;
- respect `maxStacks`;
- no value when no additional effective stack can be added.

### Projected aura ledger

Add planning-only reservations so later cohort members see same-plan intended aura applications.

The ledger must understand canonical aura identity sufficiently to prevent duplicate non-stackable applications while permitting valid independent stacks.

### Projected health caps

For periodic damage:

```text
useful future damage <= projected target health
```

For periodic healing:

```text
useful future healing <= projected missing health
```

Do not simulate future incoming damage.

### Candidate utility shape

Extend candidate/profile output with distinct fields such as:

```lua
immediateDamage
periodicDamage
immediateHealing
periodicHealing
```

while preserving existing compatibility fields where current callers require them.

## Explicitly not in scope

- control utility;
- interrupts;
- off-GCD sequences;
- changing generic aura execution.

## Validation

At minimum:

1. pure DoT receives positive utility;
2. pure HoT receives positive utility on an injured ally;
3. immediate + periodic values combine;
4. future discount is deterministic;
5. chance uses expected value without `math.random()`;
6. reactive unpredictable proc is not multiplied by guessed future triggers;
7. DoT useful value caps at target projected health;
8. HoT useful value caps at projected missing health;
9. healthy refresh-duration aura is heavily discounted;
10. near-expiry refresh gains only incremental uptime value;
11. independent stack can add value below max stacks;
12. max-stack application receives no false extra value;
13. first cohort application reserves the aura for later NPC evaluation;
14. direct damage/heal regressions remain unchanged.

---

# 7. Task C — Issue #143: Deterministic Control and Interrupt Utility

## Goal

Allow pure control and interrupt spells to become meaningful candidates without introducing a general behavior-tree/AI weighting system.

## Depends on

- #141

## Primary current files

- `client/autopilot/AuraEvaluator.lua`
- `client/autopilot/SpellEvaluator.lua`
- `client/autopilot/TargetSelector.lua`
- `client/autopilot/PlannerIntegration.lua`
- `client/spellcasting/AuraManager.lua`

## Work

### Movement control

Score the incremental restriction from `movementRangeOverride` against current frozen effective target control/mobility state.

Required cases:

```text
20 → 10 = useful slow
20 → 0  = stronger root
0 → 0   = redundant
```

Use bounded code-level constants. Do not express control as unlimited pseudo-damage.

### Casting prevention

Score `preventCasting = true` only where it adds meaningful new control.

Prefer targets for which casting is currently relevant using existing resolved spell/cast state rather than adding class/archetype metadata.

### Fragile control

Reduce utility when `cancelOnDamage = true`.

Do not simulate all future friendly attacks.

### Interrupts

Recognize spell components/effects which perform an interrupt.

Pure interrupt candidate exists only for a legal hostile target which is currently casting and interruptible through the normal rules.

Priority should be deterministic and use available live/frozen cast information, then threat/eventID tie-breaking.

A useful urgent interrupt should outrank routine damage but remain below meaningful urgent healing.

### Candidate comparison

Extend candidate ordering with explicit urgent-interrupt/control state while keeping existing urgent-heal behavior intact.

## Explicitly not in scope

- generic stat-buff/debuff utility;
- `forceAutoHitAgainstTarget` valuation;
- summon/revert utility;
- sequence planning.

## Validation

At minimum:

1. unrestricted target receives positive slow value;
2. root scores above weaker slow where otherwise equivalent;
3. target already rooted does not receive full duplicate root value;
4. casting prevention is useful on a relevant caster;
5. equivalent existing casting prevention suppresses duplicate value;
6. fragile control is discounted;
7. valid active hostile cast makes interrupt selectable;
8. no active cast makes pure interrupt utility zero;
9. urgent heal still outranks routine interrupt where the design requires;
10. valid interrupt outranks routine low-value damage;
11. stable target tie-breaks remain deterministic.

---

# 8. Task D — Issue #144: Bounded Off-GCD Action-Sequence Planning

## Goal

Add a pure planning module which turns one NPC's candidate set into a bounded legal sequence under projected action-economy constraints.

## Depends on

- #141
- consumes candidate fields from #142/#143 when available

## Primary current files

- `client/autopilot/SpellEvaluator.lua`
- `client/autopilot/PlannerIntegration.lua`
- `client/spellcasting/Cooldowns.lua` read/reuse only unless a pure helper must be factored
- `core/classes/Spell.lua`
- `RPEngine_Dev.toc`

Potential new file:

- `client/autopilot/ActionEconomy.lua`

## Work

### Classify candidate action economy

For a currently legal activation classify:

```text
auxiliary
primary
terminal
```

Auxiliary requires:

- no GCD consumption under current canonical semantics;
- instant resolution;
- no persistent active cast/channel.

Primary is a normal principal GCD action.

Any action which begins a persistent cast/channel is terminal regardless of GCD flags.

### Bound the search

Implement:

```lua
MAX_AUXILIARY_ACTIONS_PER_NPC = 2
```

and one use per `spellRef` per batch.

Do not search unrestricted subsets/permutations.

### Build main action first

Choose the preferred primary/terminal action first, then reserve it.

This prevents a cheap auxiliary from consuming resources needed by a substantially more useful main action.

### Projected action-economy ledger

Track planning-only reservations for:

- resources, including relevant start/end costs;
- cooldown groups;
- selected spell refs;
- ignore-GCD mutual lockout;
- primary GCD commitment;
- terminal-cast state.

No canonical cooldown/resource mutation.

### Greedy auxiliary selection

After the main action is reserved, select up to two highest-value compatible auxiliary actions in deterministic order.

Final order:

```text
auxiliary 1
auxiliary 2
main primary/terminal
```

### Pure API

Expose a deterministic function/state machine which can be tested using mock candidates independently of marker movement.

## Explicitly not in scope

- changing production plan output to multiple actions;
- movement solver integration;
- authorization/execution changes;
- DM Helper changes.

## Validation

At minimum:

1. one non-GCD instant + one GCD attack => both selected;
2. two compatible auxiliaries + primary => three actions selected;
3. third auxiliary excluded by cap;
4. same spellRef never repeats;
5. two ignore-GCD spells conflict per canonical one-turn peer lockout;
6. ordinary cooldown-group conflict excludes incompatible pair;
7. auxiliary cannot consume resource reserved by main action;
8. combined resource reservations prevent overspend;
9. non-GCD timed spell is terminal;
10. terminal action ends sequence;
11. active-GCD legality follows canonical candidate input rather than custom reinterpretation;
12. deterministic equal-utility sequence tie-breaks.

---

# 9. Task E — Issue #145: Sequence-Aware Marker Movement and Planner Integration

## Goal

Change production planning from one candidate per NPC to one bounded sequence per NPC, including marker-anchor feasibility and final plan output.

## Depends on

- #142
- #143
- #144

## Primary current files

- `client/autopilot/MovementSolver.lua`
- `client/autopilot/PlannerIntegration.lua`
- `client/autopilot/ActionEconomy.lua`
- `client/autopilot/SpellEvaluator.lua`
- `client/autopilot/TargetSelector.lua`

## Work

### Per-anchor sequence evaluation

Replace `evalBestCandidate`-style one-action member evaluation with a bounded per-member sequence result.

At each candidate shared marker anchor:

1. determine spatial feasibility for every candidate;
2. pass feasible candidates to ActionEconomy;
3. obtain one selected sequence for the member;
4. aggregate all action utility for whole-cohort anchor comparison.

### Multiple melee actions

Every melee-requiring action selected for one marked member must be feasible from the same candidate anchor.

Do not permit the sequence to imply intermediate movement or per-action hidden positions.

### Whole-cohort score

Retain current priorities:

- aggregate tactical value;
- useful member coverage;
- urgent-healing priority;
- stable/current-position preference;
- movement penalty/distance;
- stable tie-breaks.

Extend as necessary to include urgent interrupts and summed sequence utility.

### Projection ordering across cohort members

Once a member sequence is selected/frozen for the chosen anchor, reserve:

- healing from all selected heals/HoTs;
- aura applications/stacks;
- other relevant planning ledgers;

before later member planning where the existing planner's deterministic member order requires it.

Be careful not to make anchor evaluation mutate cross-anchor shared ledgers. Each anchor evaluation needs isolated or resettable projected state.

### Final plan output

Emit one action record per selected spell in the sequence.

Use sequence-aware stable identity:

```text
<planId>:spell:<casterEventId>:<sequenceIndex>
```

Store:

```lua
casterSequenceIndex
casterSequenceCount
actionEconomyClass
previousCasterActionId
requiresMovementActionId
```

where applicable.

### No-action semantics

An NPC with no useful selected sequence still receives the existing no-action record.

## Validation

At minimum:

1. singleton NPC can emit two actions;
2. marker member can emit auxiliary ranged + primary melee where one anchor makes melee feasible;
3. two selected melee actions to different targets require one anchor in range of both;
4. impossible second melee action is omitted/replaced rather than splitting movement;
5. one marker movement proposal still serves the entire cohort;
6. each movement-dependent action carries the dependency;
7. ranged auxiliary need not be movement-blocked if it is independently feasible;
8. action IDs remain unique for several actions from same caster;
9. anchor evaluation ledgers do not leak between anchors;
10. current one-action direct-damage cases preserve previous result;
11. marker no-split and least-mobile constraints remain unchanged;
12. planner remains resumable/yieldable.

---

# 10. Task F — Issue #146: Ordered Multi-Action Authorization and Execution

## Goal

Extend existing Pending Authorization so several spell actions belonging to one caster are explicit, ordered, dependency-aware and safely executed one at a time.

## Depends on

- #145

## Primary current files

- `client/autopilot/Authorization.lua`
- `client/autopilot/Execution.lua`
- `client/autopilot/PlannerIntegration.lua`

## Work

### Preserve multiple same-caster actions

`PublishAutopilotPendingPlan()` must accept all unique sequence-aware action IDs and preserve their order.

### Sequence gating

Only the earliest unresolved action in one caster's sequence should be authorizable.

Later action state should expose an explicit sequence dependency without pretending the spell itself is canonically invalid.

Recommended distinction:

```text
blocked: previous-caster-action-pending
```

or equivalent structured state.

### Completion/rejection behavior

- successful instant/handoff completion unlocks the next action;
- explicit rejection may unlock the next action because positive cross-spell dependency modeling is out of scope;
- stale/failed execution stops the rest of that caster's sequence and exposes Replan rather than continuing blindly.

### Live revalidation

Every newly unlocked action still flows through the existing `ExecuteEventUnitSpell()` live canonical activation and target validation.

Do not trust the projected ledger at execution time.

### Authorize All

Bulk authorization must process deterministic action order and sequence prerequisites.

For each caster:

```text
auxiliary 1
→ auxiliary 2
→ primary/terminal
```

If one same-caster action fails/stales, stop progressing that caster. Other unaffected casters may continue if their actions remain current.

### Persistent cast terminal rule

Once a terminal timed/channel spell is successfully handed to canonical spellcasting, there must be no later same-caster action in that sequence. Treat presence of one as planner/output corruption and do not execute it.

### Movement dependencies

Retain independent movement dependency validation per action.

## Validation

At minimum:

1. two same-caster action IDs coexist in one pending plan;
2. second action is initially sequence-blocked;
3. first completed action unlocks second;
4. first rejected action unlocks second;
5. first stale/failed action prevents automatic continuation;
6. repeated authorize click still cannot double-execute;
7. fresh activation after earlier action reflects updated resources/cooldowns/GCD;
8. projected plan that becomes invalid is correctly marked stale rather than silently adjusted;
9. Authorize All respects same-caster order;
10. failure of caster A does not corrupt caster B's sequence;
11. movement-dependent action cannot bypass Confirm Moved;
12. terminal cast remains fire-and-forget after handoff and no later action executes.

---

# 11. Task G — Issue #147: DM Helper Sequence Presentation

## Goal

Expose the advanced planner result without making the host infer sequence order or utility type from raw diagnostics.

## Depends on

- #146

## Primary current files

- `client/autopilot/Helper.lua`
- `client/ui/widgets/widget_Event_AutopilotHelper.lua`
- `client/ui/widgets/widget_Event_DMHelper.lua`

## Work

### Group/order actions by NPC

Pending Actions should make same-caster sequence order explicit.

Example:

```text
[NPC Mage]
1. Arcane Surge — Off GCD
2. Fireball → Player A
```

Use existing stable action IDs for row callbacks.

### Explain action class

Add derived display annotations where relevant:

```text
Off GCD
DoT
HoT
Interrupt
Control
Casting
```

These are UI derivations from structured plan data, not new Spell metadata.

### Sequence-blocked state

Later actions should remain visible with a readable reason such as:

```text
Waiting for previous action
```

and no invalid Authorise button until unlocked.

### Preserve current dashboard design

Do not undo the current marker selector / Pending Actions / Outcomes This Turn / Details architecture from the newer DM Helper work.

This issue adds sequence information to the existing dashboard rather than redesigning the entire panel again.

### Details/explainability

Where advanced planner details are selected, expose useful structured explanation such as immediate/periodic/control intent without requiring raw numerical utility in the normal row.

## Validation

At minimum:

1. several actions from one NPC appear in sequence order;
2. same-spell names across different NPCs remain correctly bound to action IDs;
3. blocked later action shows waiting state and cannot authorize;
4. unlocking first action refreshes second action controls;
5. rejected/stale/failed sequence states use existing semantic row status colors;
6. movement-dependent and sequence-dependent states are distinguishable;
7. Off GCD / DoT / HoT / Interrupt / Control annotations are derived correctly;
8. participants never see DM-only sequence data;
9. manual mode and Combat Log remain unchanged.

---

# 12. Task H — Issue #148: Integration Hardening, Sliceability and Regression Pass

## Goal

Validate the complete advanced system against current production paths and remove accidental architectural expansion before the feature is considered finished.

## Depends on

- #141–#147

## Primary surfaces

All files modified by #141–#147 plus current generic spell/aura code used as canonical dependencies.

## Work

### Current-source re-trace

Before changing anything, trace the final actual call paths after #141–#147. Do not assume intermediate issue designs were implemented exactly as originally described.

### Deterministic regression matrix

Exercise the PDD's full advanced validation matrix, including:

- direct damage/healing regressions;
- DoT/HoT projection;
- aura refresh/stack semantics;
- control/interrupt choices;
- GCD/non-GCD/ignore-GCD combinations;
- resource/cooldown-group conflicts;
- auxiliary cap and spellRef deduplication;
- timed terminal actions;
- multi-action marker movement;
- unique action IDs;
- same-caster authorization gating;
- Authorize All failure isolation;
- live canonical revalidation;
- host-only behavior;
- manual mode.

### Performance/sliceability

Instrument/force large candidate sets and verify:

- aura resolution is cached;
- target/aura scans yield where needed;
- sequence construction remains bounded;
- anchor evaluation does not explode combinatorially;
- no repeated whole-dataset aura resolution per anchor;
- no TaskQueue global budget increase.

### Architectural review

Review the final diff specifically for:

- duplicated aura identity/stack logic;
- duplicated GCD/cooldown legality;
- planner-side gameplay mutation;
- per-member hidden marker positions;
- accidental auto-authorization;
- automatic tactical retry/replan loops;
- positive-synergy simulation that exceeds PDD scope;
- generic spellcasting changes introduced only to simplify Autopilot;
- author-facing AI metadata;
- unbounded subset/permutation searches.

### Remove dead compatibility paths

If sequence implementation leaves one-action-only helper aliases/fields that are no longer called, remove them only where call-site search proves they are dead. Do not perform unrelated cleanup.

## Acceptance

The final feature must satisfy every PDD acceptance criterion and preserve the architecture:

```text
current canonical state
→ frozen bounded planning
→ advanced deterministic utility
→ one shared marker solve
→ bounded action sequences
→ explicit pending authorization
→ per-action live revalidation
→ canonical spell/aura execution
```

---

# 13. 5.6-Luna-ExtraHigh Task Execution Rules

Each issue is deliberately scoped so one high-reasoning coding pass can complete it without requiring the model to hold the entire feature rewrite in one context.

For **every** issue #141–#148, the implementation agent should be instructed to:

1. work from the current `dev` branch;
2. read the current version of every affected file before editing;
3. trace the exact current callers/callees being changed;
4. do not assume the PDD's source snapshot is still current;
5. implement only the issue's explicit scope;
6. do not pre-implement later issues merely because a future API is obvious;
7. prefer small pure helper APIs that can be deterministically tested;
8. search every modified public/internal API for all call sites;
9. identify regressions for every changed caller/callee contract;
10. exercise pure logic with deterministic Lua fixtures/mocks wherever possible;
11. inspect the resulting diff for accidental architectural expansion;
12. verify manual mode, host-only boundaries, canonical spellcasting and same-marker invariants where relevant;
13. close only the current issue once its own acceptance criteria are fully validated;
14. stop after that issue and do not proceed to the next task until instructed.

---

# 14. Final Delivery State

After #148, the production flow should be:

```text
Start current NPC step
    ↓
Freeze canonical event/spell/aura/cast/spatial state
    ↓
Build direct + periodic + control/interrupt candidates
    ↓
For each NPC/anchor, build bounded legal action sequence
    ↓
Solve one shared marker position per marked cohort
    ↓
Publish movement + ordered spell actions
    ↓
DM confirms movement and authorizes actions explicitly
    ↓
Each action revalidates against current canonical spell state
    ↓
Normal RPE spellcasting owns actual execution/effects
```

The design should remain a lightweight deterministic DM assistant, not a second combat simulation engine.
