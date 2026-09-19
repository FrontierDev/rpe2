# RPE 2 — Spell Ranks
## Product Design Document

**Status:** Draft  
**Target branch:** dev  
**Scope:** level-derived spell ranks, ruleset scaling, spell learning level, aura rank propagation, authoring and presentation

---

# 1. Purpose

RPE 2 should support optional level-derived ranks for Spell definitions.

The system has four product requirements:

1. Spell ranks are controlled by the active Ruleset and are enabled by default.
2. The Ruleset defines the percentage by which a spell's scalable effects increase for each additional rank.
3. Every Spell defines the level at which Rank 1 is learned and the number of levels between later ranks.
4. A spell's rank must carry through to any Aura applied by that spell so that the Aura's numeric effects use the same rank scaling as the originating cast.

The system must integrate with the existing Spell, Profile, Ruleset, spellcasting, tooltip, Aura and autopilot architecture rather than storing a second set of rank-specific spell definitions.

---

# 2. Current Architecture Relevant to Spell Ranks

## 2.1 Spell definitions are single canonical objects

Spell definitions are normalized in:

core/classes/Spell.lua

The current Spell model stores one set of components and effects. A ranked spell should therefore remain one Spell definition rather than creating separate Rank 1, Rank 2, Rank 3 records.

The rank is runtime context derived from:

- the Spell definition;
- the caster's level;
- the active Ruleset.

No separate dataset entries should be generated for each rank.

---

## 2.2 Character level already exists

Profiles already have a normalized level and the Ruleset already has character-level configuration.

Spell ranks should consume the existing level value. They should not introduce a second "spell level" or progression counter.

NPC/event casts must use the same rank resolver with the best authoritative level available for that caster. The rank system must not be hard-coded to the local player's Profile.

---

## 2.3 The effective spellbook is derived

core/internal/profile/Profile.lua builds the effective known-spell list from:

- manually stored spellbook references;
- always-learned Spells in activated datasets;
- mount-provided Spells.

Rank must not be stored beside those spell references.

A stored rank would immediately become stale if:

- the character gains a level;
- the Spell's rank interval changes;
- the Spell's learn level changes;
- the active Ruleset changes its rank settings.

Rank is therefore always calculated on demand.

---

## 2.4 Numeric spell effects already have centralized resolution paths

Direct spell damage and healing are resolved through the Combat amount resolvers before later combat modifiers are applied.

Current direct magnitude-bearing effects include:

- damage;
- healing;
- resource adjustment.

Spell rank scaling should be inserted into these amount-resolution paths rather than modifying authored Spell data before execution.

---

## 2.5 Aura power already carries application-time state, but its semantics are not rank scaling

Applied Auras already carry a powerLevel.

AuraManager currently resolves an Aura effect approximately as:

~~~text
base effect
+ applied aura powerLevel
+ stat scaling
then stacks / percentage-mode handling
~~~

The important distinction is that powerLevel is a **flat additive quantity**.

A rank rule is a **percentage multiplier**.

These are not interchangeable.

For example, an Aura with two effects of 10 and 100 cannot receive a single additive power value that correctly represents +20% for both effects.

Therefore:

**Spell rank scaling must not redefine or overload Aura powerLevel.**

The existing power mechanic remains intact. Rank propagation uses a separate applied-Aura multiplier.

---

# 3. Core Data Model

Add two fields to Spell:

~~~lua
learnLevel = 1
rankInterval = 8
~~~

Definitions:

**learnLevel**

The character/caster level at which the Spell's Rank 1 becomes available.

Default:

~~~text
1
~~~

**rankInterval**

The number of levels between successive Spell ranks.

Default:

~~~text
8
~~~

Both fields are positive integers.

Invalid, missing, zero or negative values normalize to their defaults.

---

# 4. Rank Formula

Given:

~~~text
L = caster level
S = spell learnLevel
N = spell rankInterval
~~~

the Spell is below its learning level when:

~~~text
L < S
~~~

At and above the learning level:

~~~text
rank = 1 + floor((L - S) / N)
~~~

Examples for:

~~~text
learnLevel = 1
rankInterval = 8
~~~

| Caster level | Rank |
|---:|---:|
| 1–8 | 1 |
| 9–16 | 2 |
| 17–24 | 3 |
| 25–32 | 4 |
| 33–40 | 5 |

Examples for:

~~~text
learnLevel = 5
rankInterval = 8
~~~

| Caster level | Result |
|---:|---|
| 1–4 | Below learning level |
| 5–12 | Rank 1 |
| 13–20 | Rank 2 |
| 21–28 | Rank 3 |

There is no rank cap in this project.

---

# 5. Ruleset Configuration

Add Ruleset controls for spell ranks.

Recommended location:

~~~text
Character
~~~

Rules:

~~~lua
use_spell_ranks = true
spell_rank_effect_gain_percent = 10
~~~

The initial 10% value is a balance default, not an architectural constant. The active Ruleset may configure any non-negative percentage.

The first rule controls whether later ranks increase effects.

The second rule defines the percentage increase for **each additional rank above Rank 1**.

Rank 1 is the authored baseline and receives no bonus.

---

# 6. Effect Multiplier

Given:

~~~text
P = ruleset spell_rank_effect_gain_percent
R = resolved rank
~~~

the number of bonus ranks is:

~~~text
bonusRanks = max(0, R - 1)
~~~

and the rank multiplier is:

~~~text
rankMultiplier = 1 + bonusRanks * (P / 100)
~~~

For a 10% gain:

| Rank | Multiplier |
|---:|---:|
| 1 | 1.00 |
| 2 | 1.10 |
| 3 | 1.20 |
| 4 | 1.30 |

The increase is linear, not compounded.

Rank 3 at 10% is +20%, not +21%.

---

# 7. Disabled Rank Behaviour

When:

~~~text
use_spell_ranks = false
~~~

all casts use:

~~~text
effective rank multiplier = 1.0
~~~

The authored learnLevel and rankInterval fields remain in the Spell definition and are not erased.

The UI should suppress rank-progression presentation when the feature is disabled.

The minimum learnLevel remains Spell metadata and may still be used by the learning system; disabling rank scaling must not destructively rewrite Spell learning configuration.

---

# 8. Spell Learning Level

learnLevel is the minimum level for normal Spell acquisition/availability.

It does not replace learnMode.

The existing learnMode still decides **how** the Spell is acquired:

~~~text
always_learned
trainer
book
unavailable
~~~

learnLevel decides **when** a level-using character may obtain/use it.

Required behaviour:

- an always-learned Spell becomes part of the effective spellbook when the character reaches learnLevel;
- trainer/book acquisition must reject a character below learnLevel;
- a manually stored spellbook reference is not deleted if the Spell's learnLevel later rises;
- if a stored Spell is below its current learnLevel, it is temporarily unavailable until the requirement is met;
- action-bar references are preserved while unavailable.

This avoids destructive profile migration when dataset authors change progression values.

---

# 9. Rank Is Derived State

The Profile must not store:

~~~lua
spellRanks = {
    ["dataset:spell"] = 3
}
~~~

The canonical state remains:

~~~text
Profile level
+
known Spell reference
+
Spell definition
+
active Ruleset
~~~

This means:

- leveling updates ranks immediately;
- changing rankInterval updates ranks immediately;
- changing learnLevel updates the progression boundary immediately;
- changing the Ruleset percentage updates future effect resolution immediately.

No Profile schema change is required for rank storage.

---

# 10. Cast-Time Rank Snapshot

A cast should resolve its rank once when the cast context becomes authoritative.

The cast context should carry:

~~~lua
spellRank = 3
spellRankMultiplier = 1.20
~~~

All components of that cast use the same snapshot.

This matters for:

- multi-component Spells;
- projectiles;
- channels;
- delayed resolution;
- persistent casts;
- Aura application.

A character leveling up or a Ruleset changing while an already-started cast is resolving must not cause different components of the same cast to use different ranks.

A later cast uses the newly resolved rank.

---

# 11. Effective Caster Level

Rank resolution must use one canonical effective-caster-level helper.

The resolver should prefer authoritative cast/event-unit level information when available and fall back to the local Profile level only when appropriate.

If no meaningful caster level is available, the safe fallback is:

~~~text
level 1
~~~

The same helper must be used by:

- live player casting;
- host-controlled NPC casting;
- autopilot;
- spell tooltip previews;
- tests.

UI code must not independently implement the rank formula.

---

# 12. What Rank Scaling Applies To

Rank scaling applies to numeric **effect output**, not to every numeric field on a Spell.

For the currently supported direct effect types it applies to:

- resolved damage magnitude;
- resolved healing magnitude;
- resolved resource-effect magnitude;
- numeric effects executed by an Aura applied by the ranked Spell.

The scaling should encompass the authored output contribution, including applicable stat and weapon scaling, so a rank represents the strength of the whole effect rather than only the literal baseDamage/baseHealing field.

---

# 13. Damage Resolution

For a direct damage effect, the existing raw amount conceptually becomes:

~~~text
authored base damage
+ weapon contribution
+ stat scaling
→ variance
→ spell rank multiplier
→ existing critical / mitigation / final damage modifiers
~~~

Equivalent multiplication before variance is acceptable if rounding remains deterministic, but rank must be applied before downstream target mitigation.

The rank system must not separately multiply:

- critical multiplier;
- damage-dealt stat;
- target mitigation;
- threat coefficient.

Those systems continue to operate on the already rank-scaled damage result.

Threat that is derived from damage naturally rises because the damage itself is larger.

---

# 14. Healing Resolution

For direct healing:

~~~text
authored base healing
+ stat scaling
→ variance
→ spell rank multiplier
→ existing critical healing
→ healing-done modifier
→ healing-received modifier
~~~

The rank system must not apply a second multiplier to the later healing modifiers.

---

# 15. Resource Effects

For direct resource effects, rank scales the effect magnitude while preserving sign.

Examples at a 20% rank bonus:

~~~text
+10 resource  -> +12
-10 resource  -> -12
~~~

For percentage modes:

~~~text
10% of max resource -> 12% of max resource
~~~

No new clamp should be introduced beyond the existing resource application rules.

Spell resource **costs** are not resource effects and are explicitly excluded from rank scaling.

---

# 16. Effects That Do Not Scale

Spell rank must not automatically scale:

- resource costs;
- cast time;
- cooldown;
- cooldown groups;
- cooldown-channel behaviour;
- charges;
- range;
- target count;
- target selection;
- stacks;
- Aura duration;
- taunt duration;
- hit chance;
- critical chance;
- projectile speed;
- conditions;
- dispel count;
- remove-Aura behaviour;
- interrupt behaviour;
- summon count unless a future effect explicitly defines a scalable magnitude;
- any arbitrary numeric field merely because it is numeric.

Rank scaling must be opt-in at the effect-resolution contract level, not a recursive multiplication of Spell tables.

---

# 17. Aura Rank Propagation

When a ranked Spell applies an Aura, the Aura application snapshots:

~~~lua
rankMultiplier = context.spellRankMultiplier or 1
~~~

This is stored on the applied Aura runtime entry and transmitted anywhere the Aura application state must be synchronized.

The existing fields remain independent:

~~~lua
powerLevel = existing additive aura power
rankMultiplier = multiplicative source-spell rank scaling
~~~

Legacy or non-Spell Aura sources default to:

~~~text
rankMultiplier = 1
~~~

---

# 18. Aura Effect Formula

The Aura amount resolver should conceptually become:

~~~text
per-stack amount =
    base Aura effect
    + applied powerLevel
    + stat scaling

per-stack amount =
    per-stack amount * rankMultiplier

then:
    existing percentage-mode conversion
    existing stack multiplication
    existing downstream combat handling
~~~

This preserves the current additive Aura power mechanic while applying the originating Spell's percentage rank bonus to the complete Aura effect.

---

# 19. Aura Snapshot Semantics

An active Aura keeps the multiplier from the cast that applied it.

If the caster gains a level while the Aura remains active:

- the active Aura does not silently change strength;
- the next application/refresh uses the newly resolved Spell rank.

When an Aura is refreshed/reapplied by a new cast, the new application-time rankMultiplier becomes authoritative for the refreshed instance.

This is consistent with the existing application-time powerLevel model and prevents active effects changing without a new action.

---

# 20. Aura Synchronization

Any Aura application or batch payload that currently carries:

- Aura reference;
- stacks;
- duration/turns;
- powerLevel;

must also preserve rankMultiplier.

The multiplier must participate in any application signatures/deduplication keys where differing effect strength must produce a distinct operation.

Older payloads that do not contain rankMultiplier normalize to:

~~~text
1
~~~

This preserves compatibility.

---

# 21. Embedded Aura Application

Rank transfer must cover every Spell path that can apply an Aura, including:

- a dedicated apply_aura effect;
- damage effects with applyAura;
- healing effects with applyAura;
- any other existing Spell component path that delegates to Aura application.

No path should accidentally apply a ranked direct effect but an unranked Aura.

---

# 22. Non-Spell Aura Sources

Auras may also originate from systems such as:

- Traits;
- items/consumables;
- event/admin operations;
- other Aura effects.

Unless that source explicitly executes through a ranked Spell cast, it receives:

~~~text
rankMultiplier = 1
~~~

The Spell-rank project must not change the power of unrelated Aura sources.

---

# 23. Autopilot

Autopilot must evaluate the same rank-scaled values that live execution will produce.

In particular, client/autopilot/AuraEvaluator.lua currently evaluates Aura power separately from live Aura execution.

It must be supplied with the same:

~~~text
spellRank
spellRankMultiplier
~~~

used by the real cast.

Otherwise an NPC may choose actions using Rank 1 estimates while live execution produces Rank 4 effects.

Autopilot must not implement a second rank formula.

---

# 24. Spell Tooltips

Spell tooltips should show the current resolved rank when spell ranks are enabled.

Recommended presentation:

~~~text
Fireball
Rank 3
...
Next rank at level 25
~~~

The final line is omitted when the UI does not have a meaningful player/caster level context.

If the player is below learnLevel:

~~~text
Requires Level 20
~~~

should be shown instead of presenting a usable Rank.

Existing tokenized tooltip generation must remain authoritative for effect descriptions.

The numeric values rendered by the tooltip/DescriptionBuilder should use the same rank multiplier as live execution, so a Rank 3 tooltip describes Rank 3 damage/healing/Aura amounts.

No hand-written duplicate effect description should be introduced.

---

# 25. Profile Spellbook UI

The Profile Spellbook should expose current rank without duplicating the Spell definition.

A row may show:

~~~text
Fireball — Rank 3
~~~

or equivalent secondary text.

Below-learn-level Spells that remain referenced in the Profile should be visibly unavailable and show the required level.

When rank support is disabled, rank labels are hidden and the existing presentation is retained.

---

# 26. Spell Authoring UI

Extend the Spell inspector Learning page in:

client/ui/editor/inspectors/spell/page_InspectorSpellGeneral.lua

with:

~~~text
Learn Level
Rank Interval
~~~

Defaults:

~~~text
Learn Level: 1
Rank Interval: 8
~~~

Both inputs accept positive integers only.

The editor should explain the progression with concise help text, for example:

~~~text
Rank 1 is learned at Learn Level. A new rank is gained every Rank Interval levels.
~~~

These fields are stored regardless of whether the currently active Ruleset enables rank scaling.

---

# 27. Ruleset Authoring UI

Ruleset UI is definition-driven from the Ruleset rule definitions.

Add:

~~~text
Use Spell Ranks
Spell Rank Effect Gain (%)
~~~

The percentage field must normalize to a non-negative finite number.

Changing the active value must invalidate any cached spell tooltip/effect preview context that depends on the multiplier.

No dataset edit is required merely to change global rank scaling.

---

# 28. Default and Legacy Spell Data

Existing Spell records do not contain learnLevel or rankInterval.

They normalize as:

~~~text
learnLevel = 1
rankInterval = 8
~~~

Therefore old datasets remain valid.

Existing Profile spellbook references remain valid.

No destructive dataset conversion is necessary merely to load old content.

Canonical export/serialization should include the normalized fields so newly saved Spells are explicit.

---

# 29. Caching and Invalidation

Any cache that can contain rank-dependent data must be invalidated when relevant context changes.

Relevant changes include:

- Profile level;
- active Ruleset;
- spell_rank_effect_gain_percent;
- use_spell_ranks;
- the Spell definition's learnLevel;
- the Spell definition's rankInterval.

This applies especially to:

- spell tooltip/description caches;
- effective-spellbook presentation;
- autopilot value caches;
- any activation signature that embeds resolved effect previews.

Live Aura instances are intentionally excluded because they snapshot rankMultiplier at application time.

---

# 30. API Shape

The exact function names may follow current module conventions, but the implementation should provide one canonical set of helpers equivalent to:

~~~lua
Spell.ResolveLearnLevel(spell)
Spell.ResolveRankInterval(spell)
Spell.ResolveRankForLevel(spell, casterLevel)

Spellcasting.ResolveSpellRankContext(spell, casterContext)
Spellcasting.ApplySpellRankMultiplier(context, amount)
~~~

The resolved context should contain at least:

~~~lua
{
    eligible = true,
    rank = 3,
    multiplier = 1.20,
    nextRankLevel = 25,
}
~~~

Ruleset lookup and caster-level lookup should live behind these helpers.

Do not duplicate rank arithmetic in:

- tooltips;
- Profile UI;
- combat effects;
- Aura code;
- autopilot.

---

# 31. Rounding

Rank multiplication should occur before the existing final amount rounding for the affected effect.

The project must retain each effect system's established rounding convention.

The rank subsystem itself should not introduce a new global integer-rounding rule.

The multiplier remains a floating-point value until the normal resolver rounds the resulting effect amount.

---

# 32. Example

Given:

~~~text
Spell: Holy Light
Learn Level: 5
Rank Interval: 8
Ruleset Gain: 10%
Caster Level: 22
~~~

The rank is:

~~~text
Rank 3
~~~

because ranks are reached at:

~~~text
5, 13, 21
~~~

The multiplier is:

~~~text
1 + (3 - 1) * 0.10 = 1.20
~~~

If the Spell would otherwise resolve to:

~~~text
100 healing
~~~

before downstream critical/healing modifiers, Rank 3 resolves:

~~~text
120 healing
~~~

If the same Spell applies an Aura, that Aura stores:

~~~text
rankMultiplier = 1.20
~~~

and its numeric Aura effects use the same multiplier until the Aura is refreshed/reapplied.

---

# 33. Acceptance Criteria — Rank Calculation

Given learnLevel 1 and rankInterval 8:

~~~text
Level 1  -> Rank 1
Level 8  -> Rank 1
Level 9  -> Rank 2
Level 16 -> Rank 2
Level 17 -> Rank 3
~~~

Given learnLevel 5 and rankInterval 8:

~~~text
Level 4  -> below learning level
Level 5  -> Rank 1
Level 12 -> Rank 1
Level 13 -> Rank 2
~~~

Invalid rankInterval values normalize to 8.

Invalid learnLevel values normalize to 1.

No rank is persisted to the Profile.

---

# 34. Acceptance Criteria — Ruleset

Spell ranks are enabled by default.

The active Ruleset can disable rank scaling.

The active Ruleset exposes one global percentage gain per additional rank.

Rank 1 always has multiplier 1.0.

At 10%:

~~~text
Rank 2 -> 1.10
Rank 3 -> 1.20
~~~

Changing the Ruleset affects subsequent casts and tooltip previews without rewriting dataset Spell records.

---

# 35. Acceptance Criteria — Learning

An always-learned Spell with learnLevel 10 is not effectively known before level 10 and becomes known at level 10.

Trainer/book acquisition cannot successfully learn a Spell below its learnLevel.

A manually stored spellbook reference is not deleted because the character is below the current learnLevel.

An action-bar slot referencing such a Spell remains intact but the Spell is unavailable until the requirement is satisfied.

---

# 36. Acceptance Criteria — Direct Effects

At Rank 1, current damage/healing/resource-effect behaviour is unchanged.

At higher ranks, the configured multiplier applies exactly once.

Damage scaling includes the resolved authored damage contribution, including existing weapon/stat scaling, before downstream mitigation.

Healing scaling includes existing stat scaling before critical/healing-done/healing-received modifiers.

Resource-effect scaling preserves sign.

Spell resource costs do not increase with rank.

---

# 37. Acceptance Criteria — Auras

A Spell-applied Aura receives the source cast's rankMultiplier.

Existing powerLevel behaviour remains additive and unchanged.

A Rank 3 Aura effect is not incorrectly represented by adding one flat "rank power" value.

Legacy/non-Spell Aura applications default to multiplier 1.

An active Aura does not change strength solely because its caster levels up.

Refreshing/reapplying the Aura snapshots the new cast's rank multiplier.

Rank multiplier survives the normal Aura synchronization/application path.

Damage/heal effects that embed Aura application propagate rank exactly as a dedicated apply_aura effect does.

---

# 38. Acceptance Criteria — Tooltip and Autopilot Parity

The Spell tooltip's numeric values match live execution for the same rank context.

The tooltip displays the current Rank while ranks are enabled.

Tokenized/generated spell descriptions remain the source of effect text.

Autopilot evaluates rank-scaled damage/healing/Aura value.

Autopilot and live execution use one shared rank resolver and agree on rank/multiplier.

---

# 39. Regression Requirements

At minimum, deterministic tests must cover:

~~~text
Rank 1 boundary
Rank 2 boundary
Multiple later ranks
Custom learnLevel
Custom rankInterval
Ranks disabled
Zero-percent Ruleset gain
Non-integer/invalid authored progression values
Damage scaling
Weapon contribution scaling
Stat contribution scaling
Healing scaling
Resource gain scaling
Resource loss scaling
Percentage resource-effect scaling
No resource-cost scaling
No cooldown/cast-time/range scaling
Dedicated apply_aura propagation
Damage+Aura propagation
Heal+Aura propagation
Aura powerLevel + rankMultiplier interaction
Aura stacks
Aura refresh with higher rank
Aura remains snapshotted across level change
Legacy Aura payload without rankMultiplier
NPC caster rank
Player caster rank
Tooltip/live parity
Autopilot/live parity
Below-learn-level always-learned Spell
Below-learn-level stored Spell reference
~~~

---

# 40. Non-Goals

This project does not implement:

~~~text
Separate dataset records per Spell rank
Manually purchased individual ranks
Talent-based rank bonuses
Per-Spell percentage-gain overrides
Rank caps
Compounding rank bonuses
Rank-specific cooldowns
Rank-specific costs
Rank-specific durations/stacks
Rank-specific icons
Rank-specific descriptions written by hand
Automatic rescaling of already-active Auras
A replacement for Aura powerLevel
A generic "multiply every numeric Spell field" system
~~~

These can be considered separately if later required.

---

# 41. Principal Architectural Decisions

**A Spell remains one dataset object regardless of rank.**

**Rank is derived from caster level, learnLevel and rankInterval; it is never Profile state.**

**Rank 1 is the authored baseline. The Ruleset percentage applies once per additional rank.**

**The gain is linear, not compounded.**

**learnLevel defaults to 1 and rankInterval defaults to 8.**

**The active cast snapshots rank and multiplier so one cast cannot change strength midway through resolution.**

**Rank scales effect output through existing amount resolvers rather than mutating authored Spell tables.**

**Only magnitude-bearing effect contracts scale; costs, cooldowns, durations, stacks and other unrelated numeric fields do not.**

**Aura powerLevel keeps its existing additive meaning.**

**Spell-applied Auras carry a separate rankMultiplier snapshot because an additive Aura power value cannot faithfully represent percentage rank scaling.**

**Active Auras retain their application-time multiplier until refreshed/reapplied.**

**Tooltips and autopilot use the same rank resolver as live execution.**

This adds predictable level-based Spell progression without duplicating Spell definitions or creating a parallel Aura scaling system.
