# RPE 2 — Spell Ranks Implementation Plan

**Status:** Implementation-ready  
**Target branch:** dev  
**PDD:** docs/PDD-Spell-Ranks.md

---

## 1. Purpose

This plan introduces level-derived Spell ranks without duplicating Spell definitions or storing rank state on Profiles.

The implementation must produce this end state:

~~~text
Spell definition
  learnLevel
  rankInterval
        +
caster level
        +
active Ruleset
  use_spell_ranks
  spell_rank_effect_gain_percent
        ↓
resolved cast rank
resolved cast multiplier
        ↓
direct numeric effects
applied Aura rankMultiplier
tooltip values
autopilot values
~~~

The implementation should be staged so Rank 1 remains behaviourally identical to the current system at every intermediate step.

---

## 2. Safety Strategy

The critical compatibility rules are:

1. Existing Spells with no rank fields normalize to learnLevel 1 and rankInterval 8.
2. Existing Profiles are not migrated to store rank data.
3. Rank 1 uses multiplier 1.0, preserving current effect values.
4. Aura powerLevel keeps its current additive semantics.
5. No broad recursive scaling of Spell tables is permitted.
6. Direct execution, tooltip preview and autopilot must converge on one rank resolver.
7. Aura synchronization must accept old payloads that omit rankMultiplier.

Implementation should therefore proceed from data/resolver foundations outward to runtime consumers.

Do not begin Aura propagation before the direct rank resolver and cast-context snapshot are established.

---

## 3. Stage 1 — Spell Schema, Ruleset and Pure Rank Resolution

### Goal

Create the canonical authored fields and pure rank arithmetic before changing any live effect amount.

### Primary files

~~~text
core/classes/Spell.lua
core/internal/ruleset/Rules.lua
core/internal/ruleset/Ruleset.lua             [only if helper/normalization changes are required]
tests/SpellRanksTest.lua                      [new]
~~~

### Changes

#### 3.1 Spell fields

Extend Spell:New defaults with:

~~~lua
learnLevel = 1
rankInterval = 8
~~~

Normalize both as positive integers.

Add them to Spell:ToTable.

Existing imported Spells with missing fields must resolve to:

~~~text
learnLevel = 1
rankInterval = 8
~~~

Do not require a bulk rewrite of existing default Spell records merely to make them load.

#### 3.2 Pure Spell helpers

Add one canonical pure calculation path to the Spell class, equivalent to:

~~~lua
Spell.ResolveLearnLevel(spell)
Spell.ResolveRankInterval(spell)
Spell.ResolveRankForLevel(spell, casterLevel)
Spell.ResolveNextRankLevel(spell, rank)
~~~

ResolveRankForLevel must return a clear below-learn-level result rather than inventing Rank 0 as a user-facing rank.

Recommended internal result shape:

~~~lua
{
    eligible = true,
    rank = 3,
    learnLevel = 1,
    rankInterval = 8,
    nextRankLevel = 25,
}
~~~

#### 3.3 Ruleset definitions

Under the Character category, add:

~~~lua
{
    key = "use_spell_ranks",
    label = "Use Spell Ranks",
    type = "checkbox",
    default = true,
}

{
    key = "spell_rank_effect_gain_percent",
    label = "Spell Rank Effect Gain (%)",
    type = "text",
    default = "10",
}
~~~

Normalize the percentage to a finite non-negative number at the consuming resolver boundary.

The 10% default is balance data and should remain configurable.

#### 3.4 Deterministic tests

Create tests for pure rank arithmetic:

~~~text
learn 1 / interval 8:
  level 1  -> rank 1
  level 8  -> rank 1
  level 9  -> rank 2
  level 16 -> rank 2
  level 17 -> rank 3

learn 5 / interval 8:
  level 4  -> ineligible
  level 5  -> rank 1
  level 12 -> rank 1
  level 13 -> rank 2
~~~

Also cover:

- malformed learnLevel;
- malformed rankInterval;
- zero/negative values;
- non-integer values;
- very high level;
- no rank cap.

### Stage 1 gate

No live damage/healing/resource/Aura amount changes yet.

Existing datasets and Profiles load without errors.

Rank arithmetic has deterministic tests.

---

## 4. Stage 2 — Central Runtime Rank Context

### Goal

Resolve rank once per cast and make that snapshot available to every Spell effect consumer.

### Primary files

~~~text
client/spellcasting/Lifecycle.lua
client/spellcasting/Helpers.lua
core/internal/profile/Profile.lua             [level/profile fallback access only as needed]
client/conditions/Core.lua                    [reuse existing level context rather than duplicate it]
~~~

### Changes

#### 4.1 Canonical runtime resolver

Add one Spellcasting helper equivalent to:

~~~lua
Spellcasting.ResolveSpellRankContext(spell, options)
~~~

It should resolve:

- effective caster level;
- active Ruleset;
- rank feature enabled state;
- resolved Spell rank;
- rank multiplier;
- next-rank level.

Return:

~~~lua
{
    eligible = true,
    rank = 3,
    multiplier = 1.20,
    casterLevel = 20,
    learnLevel = 1,
    rankInterval = 8,
    nextRankLevel = 25,
}
~~~

When rank scaling is disabled:

~~~text
multiplier = 1.0
~~~

The rank formula itself still comes from the pure Spell helper.

#### 4.2 Effective caster level

Use one authoritative level resolver for all cast types.

Priority should follow the real current cast/event data rather than assuming the local Profile.

At minimum account for:

- event/player caster context;
- NPC caster context where level is available;
- local Profile fallback for local out-of-event casts/tooltips;
- level 1 fallback only when no better value exists.

Do not add a second level property solely for Spell ranks.

#### 4.3 Snapshot at cast context creation

When Lifecycle creates the authoritative Spell cast/effect context, attach:

~~~lua
context.spellRank
context.spellRankMultiplier
~~~

The values are snapshots for that cast.

All later components, projectiles, channel ticks and Aura applications from that cast should consume the snapshot.

Do not repeatedly read the Ruleset in each effect executor when a cast context already contains the value.

#### 4.4 Shared multiplier helper

Provide one narrow helper equivalent to:

~~~lua
Spellcasting.ApplySpellRankMultiplier(context, amount)
~~~

Requirements:

- default multiplier 1;
- preserve sign;
- finite-number validation;
- do not round;
- leave rounding to the caller's existing amount resolver.

### Stage 2 gate

A cast context can report the correct rank/multiplier, but live effect amounts are still unchanged until Stage 3.

Player and NPC test contexts produce deterministic results.

---

## 5. Stage 3 — Learning-Level Eligibility

### Goal

Make learnLevel meaningful without changing the Profile storage model.

### Primary files

~~~text
core/internal/profile/Profile.lua
core/internal/database/Database.lua            [only if acquisition validation belongs at this boundary]
client/spellcasting/Lifecycle.lua
client/character/profile/page_ProfileSpellbook.lua
client/ui/tooltips/tooltip_Spell.lua
~~~

### Changes

#### 5.1 Effective always-learned spellbook

Update buildKnownSpellRefs() in core/internal/profile/Profile.lua.

Current behaviour adds every activated Spell with:

~~~text
learnMode = always_learned
~~~

The new behaviour should add it only when the active character satisfies learnLevel.

This means a level-10 always-learned Spell appears automatically at level 10 without a Profile write.

#### 5.2 Manual spellbook references

Do not delete a stored manual Spell reference if the character becomes lower than the current learnLevel because:

- the dataset may have changed;
- the active Ruleset/dataset set may have changed;
- destructive removal would lose authored player state.

Instead, expose a central eligibility check and make the Spell unavailable until the level requirement is met.

Action-bar references remain intact.

#### 5.3 Profile.AddKnownSpell

Profile.AddKnownSpell currently delegates to Database.AddProfileSpellbookSpell.

Add validation at the highest common semantic boundary that knows the Spell definition and character level.

Do not rely on the UI alone.

If trainer/book flows have more specific learn functions by the time this issue is implemented, route them through the same validation.

#### 5.4 Activation guard

Lifecycle/activation must independently reject a cast when the caster is below learnLevel.

This prevents direct API/addon-message paths from bypassing the Profile/UI learning gate.

NPC/event Spells should use their own caster level context.

### Stage 3 gate

- always-learned level gating works;
- manual references are preserved;
- below-level casts are rejected centrally;
- reaching the level makes the Spell available without rewriting the Profile.

---

## 6. Stage 4 — Direct Effect Scaling

### Goal

Apply rank multiplier exactly once to magnitude-bearing direct Spell effects.

### Primary files

~~~text
client/combat/effects/Damage.lua
client/combat/effects/Heal.lua
client/combat/effects/Resource.lua
client/spellcasting/effects/Resource.lua       [audit Aura/alternate resource path]
client/spellcasting/Lifecycle.lua              [context continuity only]
tests/SpellRanksTest.lua
~~~

Also audit every call site of:

~~~text
Combat:ResolveDamageAmount
Combat:ResolveHealingAmount
Combat:ResolveResourceEffectAmount
~~~

before editing.

### Changes

#### 6.1 Damage

Combat:ResolveDamageAmount currently combines:

- baseDamage;
- weapon contribution;
- stat scaling;
- variance;

and returns a rounded raw amount.

Apply spellRankMultiplier to the resolved pre-mitigation amount before the established final rounding.

Do not alter:

- hit resolution;
- crit chance;
- critical multiplier;
- mitigation;
- damage-dealt stat;
- threatCoefficient.

Expected invariant:

~~~text
ranked raw damage
→ existing critical/mitigation pipeline
~~~

#### 6.2 Healing

Combat:ResolveHealingAmount currently combines:

- baseHealing;
- stat scaling;
- variance;

before the later critical/healing modifiers.

Apply rank multiplier at the raw-healing resolver level.

Do not multiply healing-done or healing-received modifiers separately.

#### 6.3 Resource effects

Locate the canonical Combat:ResolveResourceEffectAmount implementation used by client/combat/effects/Resource.lua.

Apply rank multiplier to the resolved effect magnitude.

Requirements:

~~~text
+10 at 1.20 -> +12
-10 at 1.20 -> -12
10% at 1.20 -> 12%
~~~

Do not apply rank multiplier to resourceCosts.

#### 6.4 Do not mutate effect tables

Never implement this by replacing:

~~~text
effect.baseDamage
effect.baseHealing
effect.amount
~~~

in-place before execution.

The authored Spell definition is shared and must remain immutable at runtime.

### Stage 4 gate

At Rank 1 every tested direct effect matches pre-feature output.

At higher ranks damage/healing/resource output changes exactly once.

Resource costs, cooldowns and other non-effect values remain unchanged.

---

## 7. Stage 5 — Aura Rank Propagation

### Goal

Carry the source Spell's multiplier into applied Auras without changing Aura powerLevel semantics.

### Primary files

~~~text
client/spellcasting/AuraManager.lua
client/spellcasting/effects/Aura.lua
client/combat/effects/Aura.lua
client/combat/effects/Damage.lua               [embedded applyAura path]
client/combat/effects/Heal.lua                 [embedded applyAura path]
client/spellcasting/AuraDescriptionBuilder.lua
client/autopilot/AuraEvaluator.lua             [structure preparation; full parity in Stage 7]
~~~

Audit all call sites of:

~~~text
ApplyAuraFromContext
ResolveApplyAuraPowerLevel
buildAuraApplySignature
Aura apply/batch serialization
~~~

before editing.

### Changes

#### 7.1 Applied Aura state

Add:

~~~lua
rankMultiplier = 1
~~~

to the runtime Aura entry.

The value comes from:

~~~lua
context.spellRankMultiplier
~~~

when the source is a ranked Spell cast.

Other sources default to 1.

#### 7.2 Preserve powerLevel

Do not change:

~~~lua
powerLevel
~~~

into a percentage or a rank field.

ResolveApplyAuraPowerLevel continues to represent the existing additive power mechanism.

The applied Aura now carries two independent concepts:

~~~lua
powerLevel       -- additive
rankMultiplier   -- multiplicative
~~~

#### 7.3 Aura amount resolution

Update AuraManager:ResolveEffectAmount.

Current conceptual calculation:

~~~text
base amount + powerLevel + stat scaling
~~~

becomes:

~~~text
(base amount + powerLevel + stat scaling)
* rankMultiplier
~~~

Then continue through existing:

- percentage-mode conversion;
- stack multiplication;
- downstream combat handling.

Keep existing rounding behaviour.

#### 7.4 Every Aura application path

Verify rank propagation for:

- dedicated apply_aura;
- damage + applyAura;
- heal + applyAura;
- triggered Spell paths that reuse the cast context.

No Spell path may drop the multiplier.

#### 7.5 Application snapshot

The Aura stores the multiplier at application time.

Do not recalculate from the caster's current level on each Aura tick.

When a new cast refreshes/reapplies the Aura, the new multiplier replaces the old source multiplier according to the existing refresh semantics.

#### 7.6 Synchronization and deduplication

Where Aura application payloads/signatures currently carry powerLevel, add rankMultiplier.

At minimum review:

~~~text
buildAuraApplySignature
single Aura apply payload
Aura apply batch payload
remote apply handlers
pending-operation signatures
~~~

Missing legacy values normalize to 1.

A different rankMultiplier must not be silently deduplicated as an identical application if effect strength differs.

### Stage 5 gate

Aura power tests prove:

~~~text
Rank 1 multiplier + existing powerLevel == current behaviour
Rank >1 scales the whole Aura effect
powerLevel remains additive
rank multiplier is not double-applied
legacy payload missing multiplier == 1
~~~

---

## 8. Stage 6 — Spell Authoring and Ruleset UI

### Goal

Expose the new configuration through existing editor architecture.

### Primary files

~~~text
client/ui/editor/inspectors/spell/page_InspectorSpellGeneral.lua
client/ui/editor/inspectors/page_InspectorSpell.lua
core/internal/ruleset/Rules.lua
client/ui/ruleset/inspectors/page_InspectorRuleset.lua    [only if generic rendering needs adjustment]
~~~

### Changes

#### 8.1 Spell Learning page

BuildSpellInspectorLearningPage currently provides:

~~~text
Learn Mode
Spellbook Category
~~~

Add:

~~~text
Learn Level
Rank Interval
~~~

Controls:

- positive integer input;
- defaults 1 and 8;
- commits through CommitSelectedSpell;
- refreshes from normalized Spell values;
- no write merely from opening/refreshing the inspector.

Add concise help text describing the formula.

#### 8.2 Ruleset UI

The generic Ruleset editor should expose the two new Character rules automatically.

Confirm the controls render and persist:

~~~text
Use Spell Ranks
Spell Rank Effect Gain (%)
~~~

If generic Ruleset rendering is sufficient, do not add bespoke UI code.

### Stage 6 gate

A Spell can be authored/exported/imported with learnLevel/rankInterval.

Ruleset rank settings can be edited and restored.

No inspector refresh mutates unrelated Spell fields.

---

## 9. Stage 7 — Tooltip, Profile and Autopilot Parity

### Goal

Ensure every consumer reports/evaluates the same rank as live execution.

### Primary files

~~~text
client/ui/tooltips/tooltip_Spell.lua
client/spellcasting/DescriptionBuilder.lua
client/spellcasting/TooltipTemplate.lua         [only if token context needs extension]
client/spellcasting/AuraDescriptionBuilder.lua
core/internal/profile/Profile.lua
client/character/profile/page_ProfileSpellbook.lua
client/autopilot/AuraEvaluator.lua
client/autopilot/*                              [audit direct damage/healing evaluators]
~~~

### Changes

#### 9.1 Tooltip rank presentation

When ranks are enabled:

~~~text
Spell Name
Rank N
...
Next rank at level X
~~~

If below learnLevel:

~~~text
Requires Level X
~~~

When ranks are disabled, retain the existing tooltip presentation.

#### 9.2 Generated/tokenized effect values

Do not add hand-written rank-adjusted effect text.

DescriptionBuilder already delegates damage/healing value calculation to live Combat resolvers.

Ensure its value contexts contain the same resolved rank snapshot/dynamic preview context so generated descriptions show scaled values.

AuraDescriptionBuilder must provide rankMultiplier when previewing an Aura section.

#### 9.3 Tooltip caches

Audit DescriptionBuilder profile/event cache signatures and revision invalidation.

The tooltip must refresh when:

- Profile level changes;
- active Ruleset changes;
- rank percentage changes;
- use_spell_ranks changes;
- Spell learnLevel/rankInterval changes.

Do not globally disable tooltip caching.

#### 9.4 Profile Spellbook

Expose current rank/required level in the Spellbook row/detail model.

Do not persist it.

#### 9.5 Autopilot

AuraEvaluator currently carries a powerLevel estimate.

Extend its evaluation profile with rankMultiplier and use the same live rank resolver.

Audit direct damage/healing value estimates as well.

An NPC action must not be selected using Rank 1 value and then execute at Rank 4 value.

### Stage 7 gate

For the same caster/Spell/Ruleset:

~~~text
tooltip amount
autopilot estimated amount
live pre-mitigation amount
~~~

agree within each subsystem's existing rounding/variance rules.

---

## 10. Stage 8 — Compatibility, Regression and Repository Audit

### Goal

Prove the feature did not create parallel rank logic or alter unrelated mechanics.

### Primary files

~~~text
tests/SpellRanksTest.lua
tests/* relevant deterministic mocks
data/default/*                              [version changes only if required]
docs/PDD-Spell-Ranks.md
docs/PLAN-Spell-Ranks.md
~~~

### Repository-wide searches

Before completion, search for:

~~~text
baseDamage
baseHealing
ResolveDamageAmount
ResolveHealingAmount
ResolveResourceEffectAmount
ApplyAuraFromContext
powerLevel
rankMultiplier
learnMode
always_learned
AddKnownSpell
BuildContext("spell"
~~~

Use these searches to identify bypass paths.

### Compatibility validation

Verify:

- imported old Spell tables work with no rank fields;
- Profiles require no rank migration;
- old Aura payloads work with no rankMultiplier;
- Traits/items that apply Auras directly remain multiplier 1 unless they execute a ranked Spell;
- Rank 1 output matches the baseline;
- changing ruleset percentage does not rewrite Spell definitions;
- changing character level does not rewrite spellbook entries;
- already-active Auras do not live-rescale.

### Static validation

For every modified Lua file:

- load/parse validation using the repository's available Lua validation workflow;
- no duplicate global/helper definitions;
- no stale direct field writes to shared Spell definitions;
- no old/current code path that applies rank a second time;
- no missing TOC entry if a new file is introduced.

If no new runtime module is created, RPEngine2.toc should remain unchanged.

### Stage 8 gate

All PDD acceptance criteria are exercised.

A repository-wide audit finds one canonical rank formula and one canonical Ruleset multiplier resolution path.

---

## 11. Required Test Matrix

The implementation should include deterministic coverage for at least the following.

### Rank boundaries

~~~text
learn=1 interval=8 level=1  -> Rank 1
learn=1 interval=8 level=8  -> Rank 1
learn=1 interval=8 level=9  -> Rank 2
learn=1 interval=8 level=17 -> Rank 3

learn=5 interval=8 level=4  -> unavailable
learn=5 interval=8 level=5  -> Rank 1
learn=5 interval=8 level=13 -> Rank 2
~~~

### Multiplier

At 10%:

~~~text
Rank 1 -> 1.00
Rank 2 -> 1.10
Rank 3 -> 1.20
Rank 8 -> 1.70
~~~

At ranks disabled:

~~~text
any Rank -> effect multiplier 1.00
~~~

### Direct effect examples

~~~text
100 raw damage at Rank 3 / 10% -> 120 before downstream mitigation
100 raw heal at Rank 3 / 10%   -> 120 before crit/healing modifiers
+50 resource at Rank 2 / 10%   -> +55
-50 resource at Rank 2 / 10%   -> -55
10% resource effect at Rank 2  -> 11%
~~~

### Exclusion tests

Rank must not alter:

~~~text
resource cost
cast time
cooldown
cooldown group
cooldown channel
charges
range
Aura stacks
Aura duration
target count
hit chance
crit chance
~~~

### Aura tests

Given:

~~~text
Aura base effect = 100
powerLevel = 20
rankMultiplier = 1.20
~~~

the per-stack pre-downstream amount should be based on:

~~~text
(100 + 20 + stat scaling) * 1.20
~~~

not:

~~~text
100 + 20 + a flat rank-power approximation
~~~

Also test:

- stacks;
- percentage modes;
- reapplication with a higher rank;
- level-up while Aura remains active;
- legacy payload missing rankMultiplier.

---

## 12. End-State Architecture

### Spell definition

~~~lua
Spell {
    learnMode = "trainer",
    learnLevel = 1,
    rankInterval = 8,
    components = { ... },
}
~~~

### Ruleset

~~~lua
character = {
    use_spell_ranks = true,
    spell_rank_effect_gain_percent = 10,
}
~~~

### Profile

Stores:

~~~text
level
known Spell references
~~~

Does not store:

~~~text
rank
rank multiplier
~~~

### Cast context

~~~lua
{
    spellRank = 3,
    spellRankMultiplier = 1.20,
}
~~~

### Applied Aura

~~~lua
{
    powerLevel = 5,
    rankMultiplier = 1.20,
}
~~~

### Amount resolution

~~~text
authored magnitude
+ existing scaling inputs
→ spell rank multiplier
→ established rounding/downstream mechanics
~~~

---

## 13. Implementation-Agent Scope Control

Each implementation unit should follow this workflow:

1. read the current version of every affected file from dev;
2. trace all current call sites of any modified resolver;
3. implement only the current stage;
4. review the resulting diff for accidental architectural expansion;
5. identify regressions for every modified API/call site;
6. add/exercise deterministic tests or mocks for pure logic;
7. run static validation;
8. stop when the stage gate is satisfied.

Do not opportunistically:

- refactor the entire Spell effect framework;
- redesign Profile spell storage;
- convert Aura powerLevel into a new abstraction;
- introduce rank-specific Spell dataset entries;
- add per-Spell rank-gain percentages;
- add rank caps.

---

## 14. Suggested Issue Breakdown

This plan can be implemented as a small sequence of focused GitHub issues:

1. **Spell rank schema and Ruleset foundations**
   - Stage 1.

2. **Rank context and level-gated spell availability**
   - Stages 2–3.

3. **Rank-scaled direct Spell effects**
   - Stage 4.

4. **Rank propagation into applied Auras**
   - Stage 5.

5. **Spell-rank authoring and presentation**
   - Stage 6 plus tooltip/Profile portions of Stage 7.

6. **Autopilot parity and full regression gate**
   - remaining Stage 7 plus Stage 8.

The Aura issue should remain separate from direct-effect scaling because it changes synchronized runtime Aura state and has a materially larger regression surface.

---

## 15. Completion Definition

The project is complete when:

- every Spell has normalized learnLevel/rankInterval data;
- rank is derived, not persisted;
- the Ruleset controls rank enablement and percentage gain;
- Rank 1 preserves current behaviour;
- higher ranks scale direct numeric effects exactly once;
- applied Auras snapshot the source Spell's multiplier;
- Aura powerLevel remains semantically unchanged;
- tooltip, Profile and autopilot presentation agree with live rank resolution;
- below-learn-level availability is enforced centrally;
- old datasets, Profiles and Aura payloads remain compatible;
- deterministic regression tests cover the PDD acceptance criteria.
