## Context

Follow-up refinement to the Spell Ranks implementation.

Design references:

- [Spell Ranks PDD](https://github.com/FrontierDev/rpe2/blob/dev/docs/PDD-Spell-Ranks.md)
- [Spell Ranks implementation plan](https://github.com/FrontierDev/rpe2/blob/dev/docs/PLAN-Spell-Ranks.md)
- #371–#376

This issue changes two assumptions in the original design:

1. individual Spells may explicitly opt out of rank progression entirely;
2. a direct **Spell Resource effect** does **not** scale with rank unless that individual effect explicitly opts in.

This issue is the authoritative target for these two behaviours and supersedes any blanket direct-Resource scaling language in #373 / the original PDD.

---

## 1. Add per-Spell rank opt-out

### Required Spell field

Add a Spell-level boolean equivalent to:

```lua
usesRanks = true
```

The exact field name may follow current conventions, but it must be explicit and serialized as part of the canonical Spell definition.

Default:

```text
true
```

Existing/legacy Spells with no field therefore continue to use ranks.

Example:

```lua
{
    name = "Evocation",
    usesRanks = false,
    learnLevel = 20,
    ...
}
```

### Semantics

When `usesRanks == false`:

- `learnLevel` still applies normally;
- the Spell has no progressing rank system;
- its effect multiplier is always `1.0`;
- `rankInterval` is ignored for runtime progression;
- the stored `rankInterval` value may remain in the definition so toggling ranks back on does not destroy authoring data;
- no next-rank level exists;
- no effect from the Spell receives a higher-rank multiplier;
- Auras applied by the Spell receive `rankMultiplier = 1`;
- autopilot evaluates the same unscaled values as live execution.

The clean runtime representation should remain compatible with the existing rank-context API. For example:

```lua
{
    eligible = true,
    usesRanks = false,
    rank = 1,
    multiplier = 1.0,
    nextRankLevel = nil,
}
```

An internal Rank 1 value is acceptable for compatibility, but **player-facing presentation must treat the Spell as unranked**, not as a Spell visibly stuck at "Rank 1".

### Ruleset interaction

There are now two independent controls:

```text
Ruleset use_spell_ranks = false
    -> globally disables rank scaling/presentation

Spell usesRanks = false
    -> this Spell never progresses regardless of the Ruleset
```

A Spell cannot be made ranked by the Ruleset if its own definition opts out.

### Authoring UI

Update the Spell inspector Learning page in:

`client/ui/editor/inspectors/spell/page_InspectorSpellGeneral.lua`

Add a checkbox:

```text
Uses Ranks
```

Default: checked.

When unchecked:

- retain Learn Level;
- hide or disable Rank Interval because it has no active effect;
- do not clear the stored Rank Interval value.

### Tooltip / Spellbook presentation

For an unranked Spell:

- do not show `Rank 1`;
- do not show `Next rank at level X`;
- still show `Requires Level X` when below `learnLevel`;
- generated/tokenized numeric effect descriptions remain authoritative.

---

## 2. Direct Spell Resource effects are opt-in for rank scaling

### Required effect field

Extend the **Spell component Resource effect** with:

```lua
scaleWithRank = false
```

Default:

```text
false
```

This must be normalized and serialized with the Spell effect.

Current Spell Resource effect shape is created in:

`core/classes/Spell.lua::buildDefaultEffect("resource")`

and normalized in:

`core/classes/Spell.lua::normalizeEffect()`.

Add the new field there rather than creating a side table.

### Semantics

A direct Resource effect behaves as follows:

```text
scaleWithRank = false
    -> use authored resource amount unchanged by Spell rank

scaleWithRank = true
    -> apply the Spell's resolved spellRankMultiplier exactly once
```

Example: Sinister Strike

```lua
{
    type = "resource",
    resourceRef = "<Combo Points>",
    amount = 1,
    amountMode = "flat",
    scaleWithRank = false,
}
```

At Rank 1, Rank 5 or Rank 10 it still grants:

```text
1 combo point
```

Example opt-in effect:

```lua
{
    type = "resource",
    amount = 10,
    amountMode = "flat",
    scaleWithRank = true,
}
```

At Rank 3 with a 10% per-rank gain:

```text
10 -> 12
```

Percentage resource effects follow the same opt-in rule.

### Important distinction: this is the Spell Resource effect only

Do **not** reinterpret this field as an Aura Resource-effect setting.

Aura numeric effects that inherit a source Spell's snapshotted `rankMultiplier` remain governed by the Aura-rank propagation work in #374.

The direct Spell execution path and Aura execution path both currently reach resource amount helpers, so implementation must not accidentally make a missing `scaleWithRank` field disable intended Aura rank propagation.

In particular, inspect:

- `client/combat/effects/Resource.lua`
- `client/spellcasting/effects/Resource.lua`
- the canonical `Combat:ResolveResourceEffectAmount()` implementation

and keep direct Spell Resource opt-in logic at the correct semantic boundary.

### Effect contract

Update the direct Resource effect contract in:

`client/combat/effects/Resource.lua`

so its defaults/fields include:

```lua
scaleWithRank = false
```

where appropriate.

### Spell inspector

Update:

- `client/ui/editor/inspectors/spell/page_InspectorSpellComponents.lua`
- `client/ui/editor/inspectors/page_InspectorSpell.lua`

For a selected Resource effect, expose:

```text
Scale With Rank
```

Default: unchecked.

The control must only apply to the selected **Spell Resource effect**.

Do not expose it for:

- Spell resource costs;
- damage/heal effects;
- Aura effect authoring.

---

## 3. Runtime integration

The rank application helper must distinguish:

### Damage

```text
ranked Spell -> scales
unranked Spell -> multiplier 1
```

### Healing

```text
ranked Spell -> scales
unranked Spell -> multiplier 1
```

### Direct Spell Resource effect

```text
ranked Spell + scaleWithRank=true  -> scales
ranked Spell + scaleWithRank=false -> does not scale
unranked Spell                     -> does not scale
```

### Aura applied by Spell

```text
ranked Spell   -> snapshots Spell rankMultiplier
unranked Spell -> snapshots 1
```

### Resource costs

Never scale.

Do not mutate authored effect tables at runtime.

---

## 4. Tooltip / generated-description parity

Any generated Resource amount in:

- `client/spellcasting/DescriptionBuilder.lua`;
- `client/spellcasting/TooltipTemplate.lua`;
- related Spell tooltip preview paths;

must use the same rule as live execution.

For `scaleWithRank = false`, a tooltip should continue to show:

```text
Generates 1 Combo Point.
```

at every rank.

For `scaleWithRank = true`, the preview should show the rank-adjusted value.

Do not hand-write alternative Resource descriptions.

---

## 5. Autopilot parity

Audit:

- `client/autopilot/SpellEvaluator.lua`;
- `client/autopilot/AuraEvaluator.lua`;
- any direct Resource-value scoring path.

Autopilot must evaluate:

- unranked Spells at multiplier 1;
- direct Resource effects with `scaleWithRank=false` at authored magnitude;
- direct Resource effects with `scaleWithRank=true` at the same scaled magnitude as live execution.

Do not duplicate rank arithmetic.

---

## Primary files

At minimum inspect:

- `core/classes/Spell.lua`
- `client/spellcasting/Lifecycle.lua`
- `client/spellcasting/Helpers.lua`
- `client/combat/effects/Resource.lua`
- `client/spellcasting/effects/Resource.lua`
- canonical `Combat:ResolveResourceEffectAmount()` implementation
- `client/ui/editor/inspectors/spell/page_InspectorSpellGeneral.lua`
- `client/ui/editor/inspectors/spell/page_InspectorSpellComponents.lua`
- `client/ui/editor/inspectors/page_InspectorSpell.lua`
- `client/ui/tooltips/tooltip_Spell.lua`
- `client/spellcasting/DescriptionBuilder.lua`
- `client/autopilot/SpellEvaluator.lua`
- `client/autopilot/AuraEvaluator.lua`
- `tests/SpellRanksTest.lua`

Only modify additional files where tracing current `dev` call paths proves necessary.

---

## Acceptance criteria

### Per-Spell rank opt-out

- [ ] Spell schema contains an explicit rank-progression enable/disable field defaulting to enabled.
- [ ] Legacy Spells with no field remain ranked.
- [ ] `usesRanks=false` preserves `learnLevel`.
- [ ] `usesRanks=false` produces multiplier 1 at every caster level.
- [ ] `usesRanks=false` has no next-rank level.
- [ ] Rank Interval is ignored but not destructively cleared.
- [ ] Unranked Spell tooltips/spellbook entries do not display Rank 1 / Next Rank.
- [ ] Below-level unranked Spells still display/enforce their Learn Level.
- [ ] Auras applied by an unranked Spell snapshot `rankMultiplier=1`.
- [ ] Autopilot treats the same Spell as unranked.

### Resource effect opt-in

- [ ] Spell Resource effect contains `scaleWithRank=false` by default.
- [ ] Legacy/missing field normalizes to false.
- [ ] Resource effect inspector exposes **Scale With Rank** only for Resource effects.
- [ ] Rank 5 Sinister Strike-style `amount=1, scaleWithRank=false` still grants exactly 1.
- [ ] `scaleWithRank=true` scales flat Resource amounts exactly once.
- [ ] `scaleWithRank=true` scales percentage Resource effects exactly once.
- [ ] Resource costs never scale.
- [ ] Aura Resource effects are not accidentally disabled by the direct-Spell flag.
- [ ] Tooltip/generated values match live execution.
- [ ] Autopilot values match live execution.

### Regression

- [ ] Ranked damage/healing behaviour remains unchanged.
- [ ] Ranked Aura propagation remains unchanged.
- [ ] Ruleset-wide `use_spell_ranks=false` still forces multiplier 1 globally.
- [ ] No rank or scale state is persisted to Profiles.
- [ ] No shared Spell/effect definition is mutated during execution.

---

## Deterministic test cases

At minimum:

```text
Spell usesRanks=false, level 1   -> multiplier 1.0
Spell usesRanks=false, level 60  -> multiplier 1.0
Spell usesRanks=false            -> nextRankLevel nil
Spell usesRanks=true             -> existing rank formula unchanged

Resource amount 1, scaleWithRank=false, Rank 5 -> 1
Resource amount 10, scaleWithRank=true, Rank 3 @ 10% -> 12
Resource amount -10, scaleWithRank=true, Rank 3 @ 10% -> -12
Resource 10% max, scaleWithRank=true, Rank 2 @ 10% -> 11%
Resource 10% max, scaleWithRank=false, Rank 8 -> 10%

unranked Spell + Resource scaleWithRank=true -> unchanged because Spell multiplier is 1
```

Also verify that an Aura Resource effect applied from a ranked Spell still follows the Aura rank-propagation contract from #374 rather than this direct-Spell flag.

Before closing, trace all current Resource amount consumers and verify there is no unconditional direct Resource rank scaling left.