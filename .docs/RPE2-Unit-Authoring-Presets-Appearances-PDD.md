# RPE2 Unit Authoring and Preset Overhaul — Product Design Document

**Status:** Proposed  
**Product:** RPE2  
**Area:** Units, Data Editor, Event Management, Event Runtime  
**Repository:** `FrontierDev/rpe2`

---

# 1. Summary

RPE2 currently treats each NPC Unit definition as a complete standalone creature. If a campaign contains several mechanically related NPC variants, each variant must be authored separately even when most of its configuration is identical.

For example, a campaign may currently require separate full Unit definitions for:

- Brigand
- Brigand Marauder
- Brigand Hedge Wizard
- Brigand Archer
- Brigand Veteran

This produces substantial duplicated authoring work and makes balancing changes difficult. Changing the baseline health or armour of the Brigand family requires editing every variant independently.

This overhaul introduces **Unit Presets**.

A Unit becomes a **base archetype** containing shared properties such as:

- base name;
- creature type/size;
- challenge level;
- stats;
- resources;
- resistances;
- spells;
- equipment;
- attributes;
- tags;
- appearance pool.

Each Unit can then contain an ordered list of **Presets**. A Preset describes a mechanical variation of the base Unit using flat and/or percentage modifiers, together with an optional replacement appearance pool.

Example:

```text
Base Unit
Brigand

Preset 1
Marauder
+10% Health
+10% Attack Power
+10% Armour
-10% Spell Power

Preset 2
Hedge Wizard
-10% Health
+30% Spell Power
+5 Spell Crit
```

When spawned, these become:

```text
Brigand
Brigand Marauder
Brigand Hedge Wizard
```

The host selects the base Unit and Preset. The runtime stores the selected Preset index and a host-selected appearance index so every client sees the same variant and model.

---

# 2. Problem

## 2.1 Excessive duplication

Unit definitions currently contain their complete stats, resources, spells, resistances, equipment, model and display transforms. A mechanically similar Unit therefore requires duplicating almost all of that information.

For campaigns with dozens of NPC variants, the Unit editor becomes unnecessarily cumbersome.

## 2.2 Balance changes become expensive

Suppose every Brigand variant should gain 20 base Health.

Under the current model, Brigand, Brigand Marauder, Brigand Hedge Wizard, Brigand Archer and Brigand Veteran may all need to be updated independently.

With the proposed model, changing the Brigand base Health automatically changes every Preset-derived variant.

## 2.3 Visual repetition

Units currently contain a single model/display configuration.

Multiple Brigands therefore tend either to look identical or require duplicate Unit definitions purely to provide visual variety.

The Unit model should instead support an **appearance pool**, allowing individual EventUnit instances to choose different models while sharing the same Unit definition.

---

# 3. Goals

The overhaul must:

1. Allow a single Unit definition to represent a family of related NPCs.
2. Allow each Unit to define zero or more Presets.
3. Allow Presets to modify Unit Stats using flat bonuses and percentage bonuses.
4. Allow Presets to modify Unit Resources using flat bonuses and percentage bonuses.
5. Allow negative modifiers.
6. Preserve the existing base Unit as a valid spawn without selecting a Preset.
7. Generate names automatically using `<Base Unit Name> <Preset Name>`.
8. Replace the single Unit model configuration with an appearance pool.
9. Allow Presets to define their own appearance pool.
10. Make a non-empty Preset appearance pool replace the base Unit appearance pool.
11. Select appearance and Preset authoritatively on the host.
12. Send the selected Preset and appearance indices to clients.
13. Materialize authoritative runtime Stats/Resources at spawn time.
14. Preserve compatibility with existing Unit definitions.
15. Integrate cleanly with challenge levels, player-count scaling and Event difficulty.

---

# 4. Non-goals

The first version does **not** make Presets separate globally reusable Dataset objects.

Presets belong to a specific Unit:

```text
Brigand
    Marauder
    Hedge Wizard

Cultist
    Fanatic
    Warlock
```

There is no global `Marauder` Preset shared automatically by unrelated Units.

The initial overhaul also does not introduce Preset-specific:

- spell additions/removals;
- equipment overrides;
- resistance overrides;
- creature type overrides;
- creature size overrides;
- challenge level overrides;
- tags;
- attributes.

V1 Presets are intentionally focused on name, stat modifiers, resource modifiers and appearance overrides.

---

# 5. Core terminology

## Base Unit

The ordinary Unit definition, e.g. `Brigand`. The Base Unit remains independently spawnable.

## Preset

A named variation belonging to a Base Unit, e.g. `Marauder`, `Hedge Wizard`, `Archer` or `Veteran`.

## Variant

The resolved combination of Base Unit plus optional Preset.

Examples:

```text
Brigand
Brigand Marauder
Brigand Hedge Wizard
```

## Appearance

One model and its associated display transforms. An Appearance contains both the model identity and the settings required to display it correctly.

---

# 6. Proposed Unit data model

The Unit model becomes conceptually:

```lua
Unit {
    id = "...",
    name = "Brigand",

    creatureType = "humanoid",
    creatureSize = "medium",
    challengeLevel = "normal",

    appearances = {
        ...
    },

    stats = {
        ...
    },

    resources = {
        ...
    },

    resistances = {
        ...
    },

    spells = {
        ...
    },

    presets = {
        ...
    },

    ...
}
```

The existing Unit fields unrelated to this overhaul remain unchanged.

---

# 7. Appearance model

The existing fields:

```text
displayId
fileDataId
cam
rot
z
```

should be replaced by an ordered appearance pool:

```lua
appearances = {
    {
        displayId = 12345,
        fileDataId = nil,
        cam = 1.0,
        rot = 0,
        z = -0.35,
    },
    {
        displayId = 23456,
        fileDataId = nil,
        cam = 0.95,
        rot = 0.1,
        z = -0.32,
    },
}
```

Each entry is a complete display configuration.

Different models often require different camera distance, rotation and vertical offset. The transform therefore belongs to the Appearance, not to the Unit globally.

---

# 8. Preset data model

A Preset is stored directly inside its Unit:

```lua
presets = {
    {
        name = "Marauder",

        statModifiers = {
            ...
        },

        resourceModifiers = {
            ...
        },

        appearances = {
            ...
        },
    },
}
```

Preset order is meaningful because Event runtime uses the Preset's array index.

```text
0 / nil = Base Unit
1       = Marauder
2       = Hedge Wizard
3       = Archer
```

No separate Registry ID is required for Presets.

---

# 9. Modifier data model

Each target Stat should have at most one Preset modifier entry.

Recommended structure:

```lua
statModifiers = {
    {
        statRef = "campaign:attack_power",
        percentBonus = 10,
        flatBonus = 0,
    },
    {
        statRef = "campaign:armor",
        percentBonus = 10,
        flatBonus = 0,
    },
}
```

Resources use the same model:

```lua
resourceModifiers = {
    {
        resourceRef = "campaign:health",
        percentBonus = 10,
        flatBonus = 0,
    },
}
```

Both fields are retained even when one is zero.

This supports positive or negative percentage and flat modifiers, and allows both modes to be combined where desired.

---

# 10. Modifier formula

For Stats:

```text
resolved value =
(base value × (1 + percentBonus / 100))
+ flatBonus
```

Example:

```text
Base Attack Power = 50
Preset = +10%, +5 flat

50 × 1.10 + 5
= 60
```

Percentage modification therefore applies to the underlying value first. Flat modification is applied afterwards.

---

# 11. Percentage Stats versus percentage modifiers

Preset modifier semantics remain independent of what the target Stat represents.

For example, if Spell Crit Stat is `10` and the author wants `+5 percentage points Spell Crit`, the Preset should use `Flat Bonus = 5`, giving `15`.

If instead the author uses `Percent Bonus = 5`, the underlying Stat is multiplied:

```text
10 × 1.05 = 10.5
```

The Preset system must not attempt to infer whether an authored Stat represents percentage points, attack power, armour, rating, chance or another custom value. It simply applies numeric flat/percentage modifiers.

---

# 12. Missing base Stats

Presets may modify Stats which do not explicitly exist on the Base Unit.

The implicit base value is `0`.

Therefore:

```text
missing Stat + flat 5
-> 5

missing Stat + 30%
-> 0
```

This allows a Hedge Wizard Preset to introduce `Spell Crit +5` without requiring every Brigand to contain a zero-valued Spell Crit row.

---

# 13. Resource modifiers

Resources require Preset modifiers because Health is currently part of the Unit Resource model rather than the Unit Stat model.

For Event NPCs, the intended resolution order is:

```text
authored Unit resource
-> existing player-count scaling
-> Preset resource modifier
-> Event difficulty modifier, where applicable
-> runtime EventUnit resource
```

For example:

```text
Brigand Health
100 base
+20/player scaling resolves to 200

Marauder
+10% Health

200 × 1.10
= 220

Heroic Event
+10% NPC Health

220 × 1.10
= 242
```

This preserves the semantic meaning that a Marauder has approximately 10% more Health than another Brigand regardless of group size.

Flat resource bonuses remain fixed:

```text
resolved Health = 200
Preset flat Health = +25
-> 225
```

Resource maxima must not resolve below zero.

---

# 14. Example Presets

## Brigand Marauder

```lua
{
    name = "Marauder",

    resourceModifiers = {
        {
            resourceRef = "campaign:health",
            percentBonus = 10,
            flatBonus = 0,
        },
    },

    statModifiers = {
        {
            statRef = "campaign:attack_power",
            percentBonus = 10,
            flatBonus = 0,
        },
        {
            statRef = "campaign:armor",
            percentBonus = 10,
            flatBonus = 0,
        },
        {
            statRef = "campaign:spell_power",
            percentBonus = -10,
            flatBonus = 0,
        },
    },
}
```

## Brigand Hedge Wizard

```lua
{
    name = "Hedge Wizard",

    resourceModifiers = {
        {
            resourceRef = "campaign:health",
            percentBonus = -10,
            flatBonus = 0,
        },
    },

    statModifiers = {
        {
            statRef = "campaign:spell_power",
            percentBonus = 30,
            flatBonus = 0,
        },
        {
            statRef = "campaign:spell_crit",
            percentBonus = 0,
            flatBonus = 5,
        },
    },
}
```

---

# 15. Variant naming

The runtime display name is generated as:

```text
base name + " " + preset name
```

Examples:

```text
Brigand
Brigand Marauder
Brigand Hedge Wizard
```

If `presetIndex = nil / 0`, the name remains `Brigand`.

Preset names should be trimmed during normalization. A blank Preset name should not be allowed through the editor.

---

# 16. Appearance pool resolution

Every Unit may contain a shared appearance pool in `Unit.appearances`.

Every Preset may optionally contain `Preset.appearances`.

Resolution is intentionally simple:

```text
Preset exists AND Preset appearance pool is non-empty
    -> use Preset appearance pool

otherwise
    -> use Base Unit appearance pool
```

The pools are not merged.

Example:

```text
Brigand
Base appearances:
    Male Brigand A
    Male Brigand B
    Female Brigand A
    Female Brigand B

Marauder preset appearances:
    Heavy Brigand A
    Heavy Brigand B
```

A Brigand Marauder can therefore only select from the two Marauder appearances, while a Preset with no appearance entries inherits the four Brigand appearances.

---

# 17. Appearance selection

Appearance selection must be **host-authoritative**.

Clients must never independently choose a random model.

When an NPC is added/spawned:

```text
resolve effective appearance pool
-> host randomly selects one appearance
-> record appearanceIndex
-> distribute appearanceIndex to clients
```

Runtime identity therefore contains:

```text
registryID
presetIndex
appearanceIndex
```

Example:

```text
registryID      = campaign:brigand
presetIndex     = 2
appearanceIndex = 3
```

Every client resolves the same Base Unit, Preset and selected Appearance and therefore renders the same NPC.

Repeated Brigands may still select different appearance indices.

---

# 18. Base Unit appearance

The Base Unit behaves conceptually as `presetIndex = 0` and uses `Unit.appearances`.

This keeps the Base Unit independently spawnable.

---

# 19. EventUnit runtime model

Add runtime provenance fields to NPC EventUnits:

```lua
presetIndex = 0,
appearanceIndex = 0,
```

The EventUnit continues to retain `registryID` as the Base Unit reference.

Example:

```lua
EventUnit {
    registryID = "campaign:brigand",
    presetIndex = 1,
    appearanceIndex = 2,
    name = "Brigand Marauder",
    ...
}
```

---

# 20. Runtime authority

The selected Preset index is useful for name resolution, appearance resolution, Event Manager presentation, debugging and identifying the authored variant.

It should **not** be the sole authority for combat values.

When the host creates the EventUnit, it should resolve and materialize the resulting `stats` and `resources` into the runtime EventUnit snapshot.

This prevents combat results from changing because a Dataset is subsequently edited or because different clients resolve authored Preset data at different points.

The host remains authoritative for the spawned variant. Clients receive resolved runtime values through the existing EventUnit synchronization system.

---

# 21. Spawn resolution pipeline

NPC creation should conceptually become:

```text
select Unit definition
-> select Preset index
-> validate Preset
-> resolve display name
-> resolve Base Unit Stats
-> apply Preset Stat modifiers
-> resolve Base Unit Resources
-> apply existing player-count scaling
-> apply Preset Resource modifiers
-> apply Event difficulty Health scaling
-> resolve effective appearance pool
-> choose appearance index
-> construct EventUnit
-> serialize/broadcast EventUnit
```

The exact internal decomposition should be shared rather than duplicated across Event start, manual additions and summon paths.

---

# 22. EventUnit network contract

The existing EventUnit network representation should be extended with:

```text
presetIndex
appearanceIndex
```

Both full Event snapshots and EventUnit delta updates must carry them.

Legacy payloads without these fields resolve as:

```text
presetIndex = 0
appearanceIndex = 0
```

The EventUnit's transmitted `name` remains the already-resolved variant name so logs/UI can still identify `Brigand Marauder` even where the originating Dataset definition cannot currently be resolved.

---

# 23. Appearance rendering

`UnitPortrait` currently resolves an NPC model from its underlying Unit definition.

After this overhaul it must instead resolve:

```text
EventUnit
-> registryID
-> Base Unit
-> presetIndex
-> effective appearance pool
-> appearanceIndex
```

The runtime-selected appearance must take priority over simply displaying the first/base Unit model.

The same resolver should be reusable by Event portraits, Event Unit previews, target UI and other NPC model surfaces. Do not implement separate Preset/model logic in each widget.

---

# 24. Data Editor — Base Unit appearance pool

The existing Unit **Model** inspector page should become an **Appearances** page.

Instead of one model field, it should contain an ordered list.

Example:

```text
Appearances

1. Display 12345
2. Display 23456
3. Display 34567

[Add Appearance]
```

Selecting an Appearance exposes:

```text
Model selector
Camera Distance
Rotation
Vertical Offset
```

Required operations:

```text
Add
Edit
Remove
Move Up
Move Down
```

A preview displays the selected Appearance.

---

# 25. Data Editor — Presets page

Add a new Unit inspector page:

```text
Presets
```

It manages Presets belonging to the selected Unit.

Recommended structure:

```text
Preset:
[ Marauder ▼ ]

[Add] [Duplicate] [Delete]

Name:
[Marauder]

Stat Modifiers
--------------------------------
Attack Power     +10%      +0
Armour           +10%      +0
Spell Power      -10%      +0

Resource Modifiers
--------------------------------
Health           +10%      +0

Appearance Override
--------------------------------
Heavy Brigand A
Heavy Brigand B
```

---

# 26. Preset modifier editor

The Stat modifier table should expose:

```text
Stat
Percent
Flat
```

The Resource modifier table should expose:

```text
Resource
Percent
Flat
```

Reference selectors should use the existing Data Editor cross-Dataset reference selection patterns.

Duplicate modifier targets should not be allowed within the same Preset.

---

# 27. Preset appearance editor

Each Preset has its own appearance list.

When empty, the UI should communicate:

```text
Using Base Unit appearance pool
```

Once at least one Preset appearance is added:

```text
Preset appearance pool overrides Base Unit appearances.
```

There is no need for a separate `overrideBaseAppearance` boolean. The rule is derived from whether the Preset pool is empty.

---

# 28. Preset duplication

The editor should support `Duplicate Preset`.

Duplication creates an independent deep copy. Subsequent edits must not mutate the source Preset.

---

# 29. Event Manager — Add NPC workflow

The Event Unit window should change from:

```text
Unit
Team
```

to approximately:

```text
Unit
Preset
Team
```

After selecting `Brigand`, the Preset selector contains:

```text
Base
Marauder
Hedge Wizard
...
```

`Base` corresponds to `presetIndex = 0`.

Selecting `Marauder` updates the preview to `Brigand Marauder`.

The preview should use the resolved Preset data rather than only the Base Unit data.

---

# 30. Adding several copies

The current Shift-add workflow should continue to work.

Repeatedly adding `Brigand Marauder` may produce different appearance indices for each EventUnit. Each added EventUnit rolls its appearance independently while the mechanical Preset remains identical.

---

# 31. Event Manager unit list

The Event Manager should display the resolved name, e.g. `Brigand Marauder` or `Brigand Hedge Wizard`, rather than only `Brigand`.

Where space permits, viewing an EventUnit should expose:

```text
Base Unit: Brigand
Preset: Marauder
```

This is useful for debugging and encounter preparation.

---

# 32. Summoned Units

Any runtime path which creates an NPC from a Unit definition must use the same variant resolver.

Summoning APIs may optionally accept `presetIndex`. If no Preset is supplied, `presetIndex = 0`.

Appearance selection occurs through the normal effective-pool rule.

There must not be one Preset implementation for manually added NPCs and another for summoned NPCs.

---

# 33. Challenge level interaction

`challengeLevel` remains a property of the Base Unit.

Presets do not override it in V1.

Therefore:

```text
Brigand
challengeLevel = normal

Brigand Marauder
-> normal

Brigand Hedge Wizard
-> normal
```

This preserves one clear encounter classification for the Unit family and keeps player-count scaling configuration independent of Preset authoring.

---

# 34. Player-count scaling interaction

The intended Resource order is:

```text
Base Unit resource
-> player-count scaling, if the Unit challenge level permits it
-> Preset modifier
-> Event difficulty modifier
```

This integrates with challenge-level scaling without duplicating that system inside Presets.

---

# 35. Event difficulty interaction

Difficulty remains an Event-wide NPC modifier.

Example:

```text
Base Brigand Health = 100
player-count resolved Health = 200
Marauder +10% -> 220
Heroic +10% -> 242
```

Preset Stat modification and Event difficulty combat modifiers compose rather than overwrite one another.

---

# 36. Legacy Unit migration

Existing Units contain:

```text
displayId
fileDataId
cam
rot
z
```

When loading a legacy Unit without `appearances`, these fields should be interpreted as one appearance:

```lua
appearances = {
    {
        displayId = old.displayId,
        fileDataId = old.fileDataId,
        cam = old.cam,
        rot = old.rot,
        z = old.z,
    },
}
```

Existing Units without Presets become:

```lua
presets = {}
```

Their gameplay behavior therefore remains unchanged.

---

# 37. Dataset schema

This overhaul changes serialized Unit definitions and requires a Dataset schema increment using the next schema version available on the implementation branch.

The migration must be additive and backwards compatible.

Do not assume a specific schema number in advance because other pending Unit/Achievement work may increment the Dataset schema first.

---

# 38. Invalid Preset handling

Runtime inputs must be validated.

If `presetIndex` is invalid or the Preset definition is missing, resolve safely as the Base Unit.

Do not throw an Event-breaking Lua error.

The host should normalize the invalid value before broadcasting where possible.

---

# 39. Invalid appearance handling

If the effective appearance pool is empty:

```text
appearanceIndex = 0
```

and existing no-model/fallback portrait behavior applies.

If an incoming appearance index is outside the effective pool, fall back to appearance 1 for presentation only. Combat state is unaffected.

---

# 40. Performance requirements

Preset resolution should occur primarily at NPC materialization time.

Do not repeatedly rebuild modified Stat/Resource arrays during portrait refresh, tooltip hover, Event table refresh, targeting refresh or combat text rendering.

Runtime EventUnits should already contain the resolved combat values.

Appearance resolution is cheap and can be cached by `registryID`, `presetIndex`, `appearanceIndex` and configuration revision where necessary.

No new unbounded per-frame scans should be introduced.

---

# 41. Authoritative state boundaries

Dataset definitions remain immutable gameplay definitions during an Event.

Creating `Brigand Marauder` must not mutate `Brigand.stats`, `Brigand.resources` or `Brigand.presets`.

Instead:

```text
definition
-> resolve variant
-> create runtime snapshot
```

All Preset application must therefore operate on copies/resolved values.

---

# 42. Acceptance criteria

## Data model

- [ ] Unit supports an ordered `presets` collection.
- [ ] Unit supports an ordered `appearances` collection.
- [ ] Presets support a name.
- [ ] Presets support Stat modifiers.
- [ ] Presets support Resource modifiers.
- [ ] Presets support their own Appearance pool.
- [ ] Legacy single-model Units load as a one-entry Appearance pool.
- [ ] Legacy Units without Presets behave unchanged.

## Modifiers

- [ ] Each modifier supports a percentage value.
- [ ] Each modifier supports a flat value.
- [ ] Negative values are supported.
- [ ] Percentage is applied before flat.
- [ ] Missing Stats/Resources resolve from zero.
- [ ] A flat modifier can introduce a previously absent Stat.
- [ ] Resource values cannot resolve below zero.

## Naming

- [ ] Base Unit spawns using the Base Unit name.
- [ ] Preset Unit spawns as `<Base Name> <Preset Name>`.
- [ ] Event lists, portraits and combat presentation use the resolved name.

## Appearances

- [ ] Base Units can contain multiple appearances.
- [ ] Each appearance stores its own model/display transforms.
- [ ] A Preset with no appearances inherits the Base Unit pool.
- [ ] A Preset with one or more appearances completely replaces the Base Unit pool.
- [ ] Appearance selection occurs once on the host.
- [ ] All clients receive the same appearance index.
- [ ] Clients do not randomize NPC models independently.

## Event runtime

- [ ] EventUnit stores `presetIndex`.
- [ ] EventUnit stores `appearanceIndex`.
- [ ] EventUnit retains the Base Unit `registryID`.
- [ ] Host materializes resolved Stats/Resources.
- [ ] Full Event snapshots carry Preset/appearance identity.
- [ ] EventUnit delta updates carry Preset/appearance identity.
- [ ] Event cloning/draft synchronization preserves both values.
- [ ] Summoned NPCs use the same variant resolver.

## Editor

- [ ] Unit Model page becomes an Appearance Pool editor.
- [ ] Unit editor gains a Presets page.
- [ ] Presets can be added, duplicated, removed and reordered.
- [ ] Stat modifiers use proper Stat reference selectors.
- [ ] Resource modifiers use proper Resource reference selectors.
- [ ] Percentage and flat values are editable independently.
- [ ] Preset appearance override state is apparent to the author.
- [ ] Base and Preset appearances can be previewed.

## Event Manager

- [ ] Add NPC window exposes a Preset selector.
- [ ] Base/no Preset is always available.
- [ ] Presets appear in Unit-defined order.
- [ ] Preview uses the resolved Preset name.
- [ ] Preview uses the effective Appearance pool.
- [ ] Repeated additions can independently select different appearances.

---

# 43. Validation example

Author:

```text
Brigand

Health:       100
Attack Power: 50
Spell Power:  20
Armour:       40
Spell Crit:    5
```

Marauder:

```text
Health       +10%
Attack Power +10%
Spell Power  -10%
Armour       +10%
```

Resolved:

```text
Brigand Marauder

Health:       110
Attack Power: 55
Spell Power:  18
Armour:       44
Spell Crit:    5
```

Hedge Wizard:

```text
Health       -10%
Spell Power  +30%
Spell Crit   +5 flat
```

Resolved:

```text
Brigand Hedge Wizard

Health:        90
Attack Power:  50
Spell Power:   26
Armour:        40
Spell Crit:    10
```

With a Base appearance pool:

```text
A
B
C
D
```

and Marauder appearance pool:

```text
E
F
```

possible spawns are:

```text
Brigand
-> A/B/C/D

Brigand Hedge Wizard
-> A/B/C/D

Brigand Marauder
-> E/F
```

The host chooses the concrete appearance when the EventUnit is created, and all clients render that same selection.

---

# 44. Resulting authoring workflow

Instead of creating and maintaining a complete duplicate Unit for every related NPC variant, the campaign author creates the Base Unit once and then authors only the differences:

```text
Create Brigand once

Add Preset: Marauder
    Health       +10%
    Attack Power +10%
    Spell Power  -10%
    Armour       +10%

Add Preset: Hedge Wizard
    Health       -10%
    Spell Power  +30%
    Spell Crit   +5

Add Preset-specific models only where necessary
```

This makes the **Base Unit the source of truth** and Presets lightweight variations rather than duplicated creature definitions.
