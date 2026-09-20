## Problem

Creating a new Unit only seeds stats whose core Stat definition has `seedNPCStat = true`. The current Core dataset has several omissions/inconsistencies, so a newly-created NPC does not start with all of the baseline combat stats that should normally be authorable.

`core/internal/database/Database.lua::buildSeededUnitFields()` is already driven by `seedNPCStat`; this issue should fix the Core dataset flags rather than hard-code a separate NPC stat list.

## Required changes

Update the relevant Stat definitions in `data/default/core.lua`.

### Set `seedNPCStat = true`

- **Movement Speed** (`f82db71a:s1mt6jh9`)
  - Universal Unit property with a non-zero base value (30).
  - Existing NPCs already need to carry it explicitly; a new Unit should inherit the Stat's base value automatically.

- **Shadow Resistance** (`f82db71a:itpo751d`)
  - Fire, Frost, Nature and Arcane Resistance are already seeded.
  - Shadow is also an active damage-school mitigation stat, so leaving it out is inconsistent.

- **Holy Resistance** (`f82db71a:hlyrsstn`)
  - Keep resistance authoring consistent across all resistance stats exposed by the Core dataset.
  - Seed at 0 like the other resistances.

### Leave unseeded

Do **not** simply enable seeding for every Core stat.

Keep these unseeded unless another feature explicitly requires them:

- Primary attributes: Strength, Agility, Intellect, Spirit, Stamina
  - NPC Units author direct combat stats/resources; seeding primaries as well would add noise and can overlap with derived combat stats.
- Dismount Resistance
  - Mounted/special-case stat.
- Damage Done / Damage Reduction
  - These are special-purpose encounter/mechanic modifiers, not baseline NPC authoring fields. Both should remain absent from newly-created Units unless explicitly added.
- Healing Done / Healing Received
  - Situational modifiers, not baseline NPC stats.
- Threat Generated
  - Situational and not required for general NPC baseline authoring.
- Damage vs. creature-type stats
  - Player/specialised modifiers and would heavily clutter every Unit.
- Defense Rating
  - Specialised critical-damage mitigation; not a universal NPC baseline.

Existing seeded combat stats such as Armor, hit chances, Parry/Dodge/Block/Magic Resistance, AP/SP, crit chances, Healing Power, resistances and Resource Regeneration should remain seeded, except that **Damage Done must be changed from `seedNPCStat = true` to `false`**.

## Seeding behaviour

`buildSeededUnitFields()` must continue to derive the seeded list entirely from `seedNPCStat` and initialize each entry from the Stat's `baseValue`.

Do not introduce a second hard-coded list in the Unit editor or database layer.

If the Unit level-scaling work from #381 has landed by implementation time, seed using the **current canonical Unit stat schema** (initial/per-level fields) rather than restoring legacy `value` fields.

## Validation

Add/update deterministic coverage for Unit creation so that:

1. A new Unit created in the Core dataset contains all Core stats marked `seedNPCStat = true`.
2. Movement Speed is seeded with its Core `baseValue` of 30.
3. Shadow Resistance and Holy Resistance are seeded at 0.
4. Damage Done and Damage Reduction are not seeded.
5. The explicitly excluded stats above are not seeded.
6. No duplicate stat refs are produced.
7. Unit serialization round-trips the seeded stats without dropping or silently adding entries.
8. Existing Unit creation for datasets with no seeded stats remains unchanged.

## Scope

This issue is only about **which Core stats are seeded into newly-created NPC Units and the correctness of that seeding path**. Do not change combat formulas, derived-stat behaviour, challenge-level balance, or runtime NPC stat resolution.