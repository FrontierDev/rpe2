# RPE2 Engineering 1–75 Preparation

## Purpose

This document is the authoritative implementation inventory for the first vanilla Classic Engineering slice: recipes whose required Engineering skill is **1 through 75 inclusive**.

It is the implementation source of truth for:

- #227 — Engineering 1–75 Spells/Auras;
- #228 — Engineering 1–75 Items and missing shared materials;
- #229 — Engineering 1–75 Recipes.

This document is preparation only. It does not itself add Engineering runtime data.

## Scope and source-version decision

The target is original/vanilla Classic Engineering data, not Retail, Cataclysm-remapped profession data, Season of Discovery additions, or a leveling-guide subset.

The final source inventory contains **14 recipes**:

1. Rough Blasting Powder
2. Rough Dynamite
3. Crafted Light Shot
4. Handful of Copper Bolts
5. Rough Copper Bomb
6. Arclight Spanner
7. Copper Tube
8. Rough Boomstick
9. Crude Scope
10. Copper Modulator
11. Coarse Blasting Powder
12. Coarse Dynamite
13. Crafted Heavy Shot
14. Mechanical Squirrel Box

`Target Dummy` begins at Engineering 85 and is outside this slice. `Silver Contact` begins at 90. Later bombs, scopes, guns and devices are likewise outside this document.

### Version-drift cases resolved

Several current databases expose later-era rewrites alongside Classic data. The following decisions are authoritative for RPE:

- **Coarse Blasting Powder** requires Engineering **75** for the vanilla/Classic profession progression used by RPE. Later profession-system pages may surface a remapped `Classic Engineering (65)` value; do not use that remap for this dataset.
- **Coarse Dynamite** requires Engineering **75** and consumes **3 Coarse Blasting Powder + 1 Linen Cloth**, producing **1–3 Coarse Dynamite**. Later data changed the powder requirement to 1; that later value is excluded.
- **Crude Scope** uses the original component recipe: **1 Copper Tube + 1 Malachite + 1 Handful of Copper Bolts**. Do not copy later recipes that directly replace those components with a different bar/gem count.
- **Mechanical Squirrel Box** uses the vanilla recipe containing **Copper Modulator**. Patch 4.3 removed Copper Modulator and rewrote dependent recipes; that rewrite is excluded.
- **Crafted Light Shot**, **Crafted Heavy Shot**, and **Copper Modulator** are retained even though later expansions removed or replaced them.
- Classic stack sizes are used rather than later 200/1000-stack profession-material values.
- Season of Discovery-specific supply mechanics and recipes are not part of this dataset.

Primary cross-checks were the Classic/TBC Classic versions of the relevant Wowhead item/spell records, Classic-era database records, and archived Classic profession pages. Later-version records were used only to identify drift, not as authoritative values where they disagree with vanilla data.

## Current RPE architecture findings

The implementation issues must re-read the current files again before editing, but the `dev` state inspected for this preparation establishes the following architecture.

### Existing Engineering skill

Core already defines Engineering:

```text
f82db71a:xprqs3y1
```

It is an always-available crafting skill. Do not create a second Engineering skill in the new dataset.

### Current Item model

`core/classes/Item.lua` supports the relevant broad item types (`consumable`, `weapon`, `material`, `tool`, `modification`, etc.), equipment slots, weapon types, stats, skill bonuses and `useSpellRef`.

Manual-use Items should use:

```text
Item.useSpellRef -> Spell -> components / Auras
```

The inventory Item-use path currently executes only Items that have the normal usable-item shape; do not add Engineering-specific execution logic.

Core already provides:

```text
Ranged slot: f82db71a:q8ve6n6t
Ammo slot:   f82db71a:atsoi5vr
Gun type:    f82db71a:anoo8qfp
Fire school: f82db71a:esjguw6d
```

### Current Spell/Aura model

The generic Spell system can represent:

- direct damage;
- healing/resources;
- application/removal of known Auras;
- interrupt/revert/summon-pet effects;
- single targets and bounded multi-target selections;
- cast time, range, cooldown and cooldown groups.

The generic Aura system can represent stat/skill/resource changes, periodic damage/healing, and control states including `preventCasting`, `movementRangeOverride` and `cancelOnDamage`.

It does **not** currently provide a geometric `N-yard radius around impact point` selector. A generic `multi` target is a bounded target count, not spatial AoE.

The existing `summon_pet` Spell effect represents RPE combat pets and is not an appropriate substitute for a cosmetic WoW companion.

### Current recipe model

`core/classes/Recipe.lua` supports:

```text
learnMode = always_learned | trainer | book | unavailable
input.kind = rpe_item | tool
```

Reusable tools are therefore representable without consuming them.

The current trainer-cost formula in `client/client_Crafting.lua` is:

```text
floor(75 + requiredSkillLevel * 28 + requiredSkillLevel^2 * 1.6)
```

Relevant results are:

| Required skill | Trainer-cost formula result |
|---:|---:|
| 1 | 104 |
| 30 | 2,355 |
| 50 | 5,475 |
| 60 | 7,515 |
| 65 | 8,655 |
| 75 | 11,175 |

For `book` recipes the trainer cost is not used for acquisition.

### Packaged datasets and synchronization

`DefaultDatasets:Register()` requires a unique non-empty dataset ID and positive integer packaged version. `data/default/Install.lua` synchronizes registered definitions automatically; a new profession does not require a hard-coded install entry once it is registered and loaded by the TOC.

The packaged update path must preserve an existing user's enabled/disabled state.

## Canonical Engineering dataset plan

Create the new canonical file in #227:

```text
data/default/professions/engineering.lua
```

Use this stable dataset ID:

```text
af503002
```

A repository-wide collision search found no existing use of that ID at preparation time.

The canonical definition should begin at packaged version `1` and use the same self-contained shape as the existing canonical profession datasets:

```lua
Addon.Data.DefaultDatasets:Register({
    version = 1,
    dataset = {
        achievements = {},
        auras = {},
        authorName = "Ortellus-ArgentDawn",
        classes = {},
        currencies = {},
        damageSchools = {},
        datasetType = "crafting",
        dependencies = {
            "f82db71a",
            "61fdf3df",
            "7259f1d3",
            "4999dcec",
            "3eb7e9bb",
        },
        description = "",
        groupName = "Core",
        guildSettings = {},
        id = "af503002",
        interactions = {},
        itemSlots = {},
        items = {},
        recipes = {},
        skills = {},
        spells = {},
        stats = {},
        traits = {},
    },
})
```

The final dependency set above covers Core plus the packaged owners used by the prepared recipes:

- Blacksmithing `61fdf3df`;
- Tailoring `7259f1d3`;
- Jewelcrafting `4999dcec`;
- Misc `3eb7e9bb`.

If the dependency extractor/current canonical conventions have changed by implementation time, retain only dependencies actually required by the current model; do not copy redundant dependencies blindly.

Add `data/default/professions/engineering.lua` to `RPEngine_Dev.toc` through the normal packaged-default load sequence, after its shared owner datasets and before default-dataset installation/synchronization runs. No Engineering range/extension file should be introduced.

# Material ownership

## Existing canonical inputs

The following required inputs already exist and must be reused rather than duplicated:

| Material/tool | Canonical owner | Ref | Notes |
|---|---|---|---|
| Rough Stone | Blacksmithing | `61fdf3df:c7urqe23` | Existing canonical raw stone. |
| Coarse Stone | Blacksmithing | `61fdf3df:qcah9yrg` | Existing canonical raw stone. |
| Bronze Bar | Blacksmithing | `61fdf3df:xegz4i5q` | Not consumed in 1–75 after final inventory, but this is the canonical owner/ref for the requested future `Bronze Framework -> Bronze Bar` policy. |
| Blacksmith Hammer | Blacksmithing | `61fdf3df:518sbr8g` | Existing reusable tool; recipe input uses `kind = "tool"`. |
| Linen Cloth | Tailoring | `7259f1d3:agzskvec` | Existing canonical cloth. |
| Malachite | Jewelcrafting | `4999dcec:fcj318z0` | Existing canonical gem/material. |

No standalone Mining dataset is required.

## Missing shared inputs to add under #228

### Copper Bar

Canonical owner: **Blacksmithing** (`61fdf3df`).

At preparation time Copper Bar is absent from the packaged Blacksmithing dataset even though later bars/stones exist.

Source metadata:

| Field | Value |
|---|---|
| WoW item ID | `2840` |
| Name | Copper Bar |
| Quality | common |
| Item level | 10 |
| Classic stack | 20 |
| Icon | `interface/icons/inv_ingot_02.blp` |
| RPE type | `material` |
| Owner | Blacksmithing |

Use Blacksmithing's current material/conversion conventions. Do not define Copper Bar inside Engineering.

### Weak Flux

Canonical owner: **Misc** (`3eb7e9bb`). It is a general vendor trade material rather than an Engineering-crafted component.

Source metadata:

| Field | Value |
|---|---|
| WoW item ID | `2880` |
| Name | Weak Flux |
| Quality | common |
| Item level | 5 |
| Classic stack | 10 |
| Icon | `interface/icons/inv_misc_ammo_gunpowder_02.blp` |
| RPE type | `material` |
| Owner | Misc |

### Wooden Stock

Canonical owner: **Misc** (`3eb7e9bb`). It is a purchased general Engineering/blacksmith-supplies part rather than a crafted Engineering component.

Source metadata:

| Field | Value |
|---|---|
| WoW item ID | `4399` |
| Name | Wooden Stock |
| Quality | common |
| Item level | 10 |
| Classic stack | 10 |
| Binding | none |
| RPE type | `material` |
| Owner | Misc |

The source databases used for this preparation expose the correct Wooden Stock item art but not a stable icon-file token in their text payload. #228 must obtain the exact Blizzard icon filename from the WoW item record before authoring the Item; do not guess an icon path.

This is the only missing metadata field in the shared-input inventory and is explicitly carried into the incomplete section below.

# Engineering component normalization

## Rule

Engineering component normalization is a **project substitution rule**, not recursive raw-cost expansion.

When a later Engineering recipe consumes an Engineering-only component, replace each unit of that component with the same quantity of its designated shared/base material unless this document explicitly states another quantity.

Examples:

```text
2 Rough Blasting Powder -> 2 Rough Stone
1 Handful of Copper Bolts -> 1 Copper Bar
1 Copper Tube -> 1 Copper Bar
```

Do **not** recursively charge all materials that were needed to craft the component. The component's own recipe still exists in the dataset because it is a legitimate source recipe; dependent recipes simply use the normalized substitute.

Reusable tools are not flattened. `Arclight Spanner` remains a tool when a recipe requires it.

## 1–75 normalization table

| Engineering component | Normalized RPE material | Quantity rule | Applies to dependent recipes |
|---|---|---|---|
| Rough Blasting Powder | Rough Stone | 1:1 | Yes |
| Handful of Copper Bolts | Copper Bar | 1:1 | Yes |
| Copper Tube | Copper Bar | 1:1 | Yes |
| Copper Modulator | Copper Bar | 1:1 | Yes |
| Coarse Blasting Powder | Coarse Stone | 1:1 | Yes |
| Arclight Spanner | none | remains reusable tool | No flattening |

Requested future-range policy marker:

```text
Bronze Framework -> Bronze Bar (1:1 component substitution)
```

Bronze Framework is outside the 1–75 inventory, so no Bronze Framework Item/Recipe is added by #227–#229. The future Engineering range must preserve the 1:1 substitution rule above rather than requiring Bronze Framework as a dependent-recipe input.

# Recipe inventory

All source reagents below are vanilla/Classic quantities. `Normalized RPE inputs` is authoritative for #229.

| # | Recipe | Skill | Acquisition / RPE learn mode | Vanilla source reagents | Normalized RPE inputs | Output | Tools | Trainer-cost result |
|---:|---|---:|---|---|---|---|---|---:|
| 1 | Rough Blasting Powder | 1 | starting recipe / `always_learned` | Rough Stone x1 | Rough Stone x1 | Rough Blasting Powder x1 | none | 104 |
| 2 | Rough Dynamite | 1 | starting recipe / `always_learned` | Rough Blasting Powder x2; Linen Cloth x1 | Rough Stone x2; Linen Cloth x1 | Rough Dynamite x2 | none | 104 |
| 3 | Crafted Light Shot | 1 | starting recipe / `always_learned` | Rough Blasting Powder x1; Copper Bar x1 | Rough Stone x1; Copper Bar x1 | Crafted Light Shot x200 | none | 104 |
| 4 | Handful of Copper Bolts | 30 | trainer / `trainer` | Copper Bar x1 | Copper Bar x1 | Handful of Copper Bolts x1 | Blacksmith Hammer | 2,355 |
| 5 | Rough Copper Bomb | 30 | trainer / `trainer` | Copper Bar x1; Handful of Copper Bolts x1; Rough Blasting Powder x2; Linen Cloth x1 | Copper Bar x2; Rough Stone x2; Linen Cloth x1 | Rough Copper Bomb x2 | Blacksmith Hammer | 2,355 |
| 6 | Arclight Spanner | 50 | trainer / `trainer` | Copper Bar x6 | Copper Bar x6 | Arclight Spanner x1 | Blacksmith Hammer | 5,475 |
| 7 | Copper Tube | 50 | trainer / `trainer` | Copper Bar x2; Weak Flux x1 | Copper Bar x2; Weak Flux x1 | Copper Tube x1 | Blacksmith Hammer | 5,475 |
| 8 | Rough Boomstick | 50 | trainer / `trainer` | Copper Tube x1; Handful of Copper Bolts x1; Wooden Stock x1 | Copper Bar x2; Wooden Stock x1 | Rough Boomstick x1 | Blacksmith Hammer | 5,475 |
| 9 | Crude Scope | 60 | trainer / `trainer` | Copper Tube x1; Malachite x1; Handful of Copper Bolts x1 | Copper Bar x2; Malachite x1 | Crude Scope x1 | Arclight Spanner | 7,515 |
| 10 | Copper Modulator | 65 | trainer / `trainer` | Handful of Copper Bolts x2; Copper Bar x1; Linen Cloth x2 | Copper Bar x3; Linen Cloth x2 | Copper Modulator x1 | Blacksmith Hammer; Arclight Spanner | 8,655 |
| 11 | Coarse Blasting Powder | 75 | trainer / `trainer` | Coarse Stone x1 | Coarse Stone x1 | Coarse Blasting Powder x1 | none | 11,175 |
| 12 | Coarse Dynamite | 75 | trainer / `trainer` | Coarse Blasting Powder x3; Linen Cloth x1 | Coarse Stone x3; Linen Cloth x1 | Coarse Dynamite x1–3 | none | 11,175 |
| 13 | Crafted Heavy Shot | 75 | trainer / `trainer` | Coarse Blasting Powder x1; Copper Bar x1 | Coarse Stone x1; Copper Bar x1 | Crafted Heavy Shot x200 | none | 11,175 |
| 14 | Mechanical Squirrel Box | 75 | world-drop `Schematic: Mechanical Squirrel` / `book` | Copper Modulator x1; Handful of Copper Bolts x1; Copper Bar x1; Malachite x2 | Copper Bar x3; Malachite x2 | Mechanical Squirrel Box x1 | Blacksmith Hammer; Arclight Spanner | — |

## Starting recipes

Rough Blasting Powder, Rough Dynamite and Crafted Light Shot are the three Apprentice Engineering starting recipes in the vanilla data set. They should use `always_learned`, matching the current RPE pattern for automatically known starting profession recipes.

## Mechanical Squirrel acquisition

The source recipe item is:

```text
Schematic: Mechanical Squirrel
WoW item ID: 4408
quality: uncommon
item level: 15
requires Engineering 75
source: rare world drop
```

RPE should map the acquisition to the existing `book` recipe-learning path. Do not expose Mechanical Squirrel as a trainer recipe.

A physical RPE schematic Item is not required merely to make `learnMode = "book"` valid unless the current book-learning flow at implementation time explicitly requires one. #229 must trace that flow before deciding whether a schematic Item record is necessary.

## Anvil/workstation note

Vanilla source records mark several low-level Engineering metalworking crafts as requiring an Anvil in addition to a tool. The current Recipe schema models reusable Items/tools but not a world workstation/environment requirement.

For this slice:

- preserve Blacksmith Hammer and Arclight Spanner as reusable `tool` inputs where listed;
- do not create a consumed `Anvil` Item;
- do not block the recipe solely because RPE has no workstation field;
- treat the omitted Anvil requirement as an approved environmental abstraction.

# Item inventory

The table below records the crafted outputs that #228 must author in Engineering. Exact stable RPE Item IDs are generated during implementation unless a prior stable ID is found in repository history.

| Item | WoW ID | Classic metadata | Icon | Intended RPE representation |
|---|---:|---|---|---|
| Rough Blasting Powder | 4357 | common; item level 5; stack 20; no character level | `interface/icons/inv_misc_dust_01.blp` | `material`; retained as a legitimate crafted output, but dependent recipes substitute Rough Stone. |
| Rough Dynamite | 4358 | common; item level 10; stack 20; requires Engineering 1 to use; no character level | `interface/icons/inv_misc_bomb_06.blp` | `consumable` + `useSpellRef`; single-target RPE damage adaptation described below. |
| Crafted Light Shot | 8067 | common; item level 10; requires level 5; stack 200; Ammo/Bullet; +2 DPS in WoW | `interface/icons/inv_ammo_bullet_02.blp` | retain exact ammo metadata; current RPE ammo combat bonus is blocked. |
| Handful of Copper Bolts | 4359 | common; item level 8; stack 10 | `interface/icons/inv_misc_gear_06.blp` | `material`; retained output, dependent recipes substitute Copper Bar. |
| Rough Copper Bomb | 4360 | common; item level 14; stack 10; requires Engineering 30 to use | `interface/icons/inv_misc_bomb_09.blp` | `consumable` + `useSpellRef`; damage + one-turn break-on-damage control adaptation. |
| Arclight Spanner | 6219 | common; item level 10; Main Hand Miscellaneous; 5–8 damage; speed 2.40; requires Engineering 50 | `interface/icons/inv_misc_wrench_01.blp` | `weapon`, Main Hand; also referenced by recipes using `kind = "tool"`. RPE does not serialize WoW attack speed, so retain 5–8 weapon range and use current weapon abstraction. |
| Copper Tube | 4361 | common; item level 10; stack 10 | `interface/icons/inv_gizmo_pipe_02.blp` | `material`; retained output, dependent recipes substitute Copper Bar. |
| Rough Boomstick | 4362 | uncommon; item level 10; requires level 5; BoE; Ranged Gun; 6–13 damage; speed 2.30; durability 35 | `interface/icons/inv_weapon_rifle_03.blp` | `weapon`; `validSlotRefs = { f82db71a:q8ve6n6t }`; `weaponTypeRef = f82db71a:anoo8qfp`; physical weapon damage through current RPE weapon model. |
| Crude Scope | 4405 | common; item level 12; requires level 5; stack 5; permanently adds +1 damage to bow/gun | `interface/icons/inv_misc_spyglass_02.blp` | `modification`; target ranged bows/guns. The +1 weapon-damage effect itself is currently unsupported and must not be faked. |
| Copper Modulator | 4363 | common; item level 13; stack 10 | `interface/icons/inv_gizmo_03.blp` | `material`; retained output, dependent recipes substitute Copper Bar. |
| Coarse Blasting Powder | 4364 | common; item level 15; stack 20 | `interface/icons/inv_misc_dust_02.blp` | `material`; retained output, dependent recipes substitute Coarse Stone. |
| Coarse Dynamite | 4365 | common; item level 20; stack 20; requires Engineering 75 to use | `interface/icons/inv_misc_bomb_06.blp` | `consumable` + `useSpellRef`; single-target RPE damage adaptation described below. |
| Crafted Heavy Shot | 8068 | common; item level 20; requires level 15; stack 200; Ammo/Bullet; +4.5 DPS in WoW | `interface/icons/inv_ammo_bullet_02.blp` | retain exact ammo metadata; current RPE ammo combat bonus is blocked. |
| Mechanical Squirrel Box | 4401 | common; item level 15; binds when used; stack 1; cosmetic non-combat companion | `interface/icons/inv_crate_01.blp` | Item metadata can exist, but the use effect is blocked because current `summon_pet` is a combat-pet mechanic. |

### RPE item-level rule for this slice

Use the exact source item levels above. Do not apply the equipment `required level + 5` convention to these Engineering records when doing so would overwrite a known source item level; #226 explicitly records exact Classic Engineering item metadata.

### WoW profession requirements on Items

Some explosive/tool source Items require an Engineering skill rank to use/equip. Current `Item` conditions must be re-read by #228 to determine whether the generic condition system can enforce a crafting-skill requirement on an Item. If the current condition model cannot express it, preserve the source requirement in data notes and flag the enforcement limitation rather than inventing a level condition.

# Spell and Aura inventory

Only three 1–75 outputs require an RPE combat-use Spell in the current implementation plan:

- Rough Dynamite;
- Rough Copper Bomb;
- Coarse Dynamite.

Mechanical Squirrel Box has a source use effect, but that effect is deliberately blocked rather than mapped to a combat pet.

## Shared Engineering explosive cooldown

All three source explosives have a 1-minute shared-style Engineering cooldown.

The current Alchemy implementation maps a normal 2-minute WoW potion cooldown to **10 RPE turns**. Preserve that project time mapping here:

```text
1 minute source cooldown -> 5 RPE turns
```

Use one generic cooldown group for these explosives:

```text
engineering_explosive
```

Do not create separate item-local cooldown state.

All three prepared Item-use Spells should use the current consumable convention:

```text
castTime = 0
ignoreGCD = true
triggersGCD = false
learnMode = unavailable
```

The source throw/use time is much shorter than an RPE turn; treating the use as instant is an intentional turn-based adaptation.

## Rough Dynamite Spell

Source effect:

```text
26–34 Fire damage in a 5-yard radius.
1 minute cooldown.
```

Current RPE cannot select a geometric 5-yard impact radius. Do not simulate that with an arbitrary `maxTargets` cap.

Prepared RPE representation:

| Field | Decision |
|---|---|
| Name/icon | Rough Dynamite / item icon |
| Target | `single`, enemy |
| Range | 30 |
| Effect | direct Fire damage |
| Base damage | 30 midpoint |
| Damage school | `f82db71a:esjguw6d` |
| Scaling | none |
| Cast time | 0 turns |
| Cooldown | 5 turns |
| Cooldown group | `engineering_explosive` |
| GCD | ignored / not triggered |
| Aura | none |

Generated Item tooltip expectation through the Spell description path:

```text
Use: Deal approximately 30 Fire damage to an enemy. (5 turn cooldown)
```

The generated builder may show its normal ±10% damage range around the midpoint; do not hand-write a duplicate item description.

The missing radial AoE is explicitly flagged as a partial source-effect limitation below.

## Rough Copper Bomb Spell + Aura

Source effect:

```text
22–28 Fire damage in a 3-yard radius.
Incapacitates for 1 second; any damage breaks the effect.
Unreliable against targets above level 24.
1 minute cooldown.
```

Prepared RPE representation:

| Field | Decision |
|---|---|
| Name/icon | Rough Copper Bomb / item icon |
| Target | `single`, enemy |
| Range | 20 |
| Component 1 | direct Fire damage, base 25 midpoint, no scaling |
| Component 2 | apply Rough Copper Bomb control Aura |
| Cooldown | 5 turns |
| Cooldown group | `engineering_explosive` |
| Cast time | 0 turns |
| GCD | ignored / not triggered |

Order the damage component **before** the Aura application so the bomb's own damage cannot immediately cancel the break-on-damage Aura.

Supporting Aura design:

```text
Name: Rough Copper Bomb Incapacitation
Duration: 1 turn
maxStacks: 1
stackBehavior: refresh_duration
control.cancelOnDamage: true
control.preventCasting: true
control.movementRangeOverride: 0
control.forceAutoHitAgainstTarget: false
```

One RPE turn is intentionally coarser than the source one-second incapacitation.

Do not implement the source `unreliable against targets higher than level 24` behavior unless the current generic effect/condition layer has gained an exact reusable capability by #227. At preparation time there is no appropriate generic hit/reliability gate on an apply-Aura component.

Do not fake the 3-yard radial AoE with bounded non-spatial multi-targeting.

## Coarse Dynamite Spell

Source effect:

```text
51–69 Fire damage in a 5-yard radius.
1 minute cooldown.
```

Prepared RPE representation:

| Field | Decision |
|---|---|
| Name/icon | Coarse Dynamite / item icon |
| Target | `single`, enemy |
| Range | 30 |
| Effect | direct Fire damage |
| Base damage | 60 midpoint |
| Damage school | `f82db71a:esjguw6d` |
| Scaling | none |
| Cast time | 0 turns |
| Cooldown | 5 turns |
| Cooldown group | `engineering_explosive` |
| GCD | ignored / not triggered |
| Aura | none |

As with Rough Dynamite, the source radial AoE remains a known partial limitation rather than being approximated with a non-spatial target cap.

# Non-Spell gameplay representations

## Rough Boomstick

Represent directly as a normal RPE ranged weapon:

```text
valid slot: f82db71a:q8ve6n6t
weapon type: f82db71a:anoo8qfp
physical damage range: 6–13
```

WoW weapon speed is not a current RPE weapon field and is intentionally absorbed into the turn-based weapon abstraction.

## Arclight Spanner

Represent as a Main Hand weapon with the Classic 5–8 damage range, while also allowing recipe inputs to reference it as `kind = "tool"`.

The Recipe schema's `tool` distinction belongs to the input row; the underlying Item does not need to be typed as a non-weapon merely to be reusable by crafting.

## Crafted Light Shot / Crafted Heavy Shot

Core has an Ammo slot, but the current Item/combat architecture does not expose a complete ammo item model that adds source bullet DPS to gun attacks and consumes/uses ammunition appropriately.

Do not convert +2 DPS / +4.5 DPS into an unrelated generic stat.

# Crude Scope

The current modification model can represent an Item that targets eligible equipment, but there is no canonical generic stat/effect for `permanently add +1 weapon damage to this bow/gun`.

Do not substitute Attack Power, Ranged Attack Power, hit chance, or another stat. The Item/Recipe may be authored, but the actual +1 weapon-damage modification remains blocked until a generic weapon-damage modification capability exists.

# Mechanical Squirrel Box

The source Item summons a cosmetic non-combat companion. RPE's existing `summon_pet` Spell effect is part of the combat-pet system and would materially change the source behavior.

Do not attach a `summon_pet` Spell merely to make the Item usable. The correct minimum follow-up is a generic cosmetic companion/non-combat summon capability, or an explicit project decision to keep the Item metadata-only.

# Cross-dataset dependency and ownership summary

By final #229 state, Engineering may reference:

```text
f82db71a  Core: skill, slots, Gun type, Fire school
61fdf3df  Blacksmithing: stones, bars, Blacksmith Hammer
7259f1d3  Tailoring: Linen Cloth
4999dcec  Jewelcrafting: Malachite
3eb7e9bb  Misc: Weak Flux, Wooden Stock
```

No 1–75 recipe needs Leatherworking, Enchanting or Fishing after the final inventory is normalized. Do not add dependencies that are not actually referenced.

# Implementation sequencing

## #227 — Spells/Auras

1. Re-read current `dev` runtime files and this document.
2. Create canonical `engineering.lua` with dataset ID `af503002`, packaged version 1 and normal TOC registration.
3. Implement the three prepared explosive Spells.
4. Implement the Rough Copper Bomb control Aura.
5. Validate generated descriptions, target validation and shared cooldown behavior.
6. Report the known partial/blocked effects listed below.

## #228 — Items and shared materials

1. Re-read the current new `engineering.lua` and final #227 refs.
2. Add Copper Bar to canonical Blacksmithing if still missing.
3. Add Weak Flux and Wooden Stock to Misc if still missing; obtain the exact Wooden Stock icon token before authoring.
4. Add all 14 prepared Engineering output Items.
5. Attach only the three exact #227 `useSpellRef` values.
6. Preserve component outputs as real Items even though dependent recipes normalize their inputs.
7. Bump every changed packaged dataset monotonically without reactivating a disabled dataset.

## #229 — Recipes

1. Re-read the final Item refs and current crafting code.
2. Add all 14 recipes directly to canonical `engineering.lua`.
3. Use the `Normalized RPE inputs` column, not source Engineering-component refs.
4. Preserve `always_learned`, `trainer`, and `book` acquisition distinctions.
5. Preserve output quantities, especially Rough Dynamite x2, Rough Copper Bomb x2, ammunition x200 and Coarse Dynamite x1–3.
6. Use Blacksmith Hammer/Arclight Spanner as reusable tool inputs where specified.
7. Recalculate trainer cost from live code before authoring in case the formula changed.

# Deterministic validation checklist

Before #226 is considered complete, this preparation has been checked against the following requirements:

- [x] Full vanilla Classic Engineering 1–75 inventory is present: 14 recipes.
- [x] Skill 1 recipes are included.
- [x] Skill 75 recipes are included.
- [x] No skill >75 recipe is included.
- [x] Target Dummy (85) and later recipes are excluded.
- [x] Acquisition mode is resolved for every recipe.
- [x] The three starting recipes are separated from trainer recipes.
- [x] Mechanical Squirrel is preserved as a world-drop/book recipe.
- [x] Original source reagents and quantities are recorded for every recipe.
- [x] RPE normalized inputs are separately recorded for every recipe.
- [x] Component normalization is explicitly 1:1 substitution rather than implicit recursive expansion.
- [x] `Rough Blasting Powder -> Rough Stone` is explicit.
- [x] `Coarse Blasting Powder -> Coarse Stone` is explicit.
- [x] `Bronze Framework -> Bronze Bar` is preserved as a future 1:1 policy marker.
- [x] All 1–75 Engineering components have explicit substitute/retain decisions.
- [x] Existing Rough Stone, Coarse Stone, Bronze Bar, Linen Cloth, Malachite and Blacksmith Hammer refs are resolved.
- [x] Copper Bar is assigned to Blacksmithing rather than Engineering.
- [x] Weak Flux and Wooden Stock are assigned to Misc rather than Engineering.
- [x] No Mining dataset is proposed.
- [x] Every output's WoW identity, item level, required character level, quality/category behavior and stack behavior is recorded.
- [x] The exact new Engineering dataset ID and load plan are recorded.
- [x] Every manual combat-use output has a Spell design or explicit blocker.
- [x] Unsupported spatial AoE is not disguised as bounded non-spatial multi-targeting.
- [x] Mechanical Squirrel is not incorrectly mapped to a combat pet.
- [x] Crude Scope is not approximated with an unrelated stat.
- [x] Ammo DPS is not approximated with an unrelated stat.
- [x] Classic/TBC component quantities are preserved where later versions changed them.
- [x] No implementation code/data change is part of this issue.

# Source notes for implementation cross-check

The implementation issues should use the corresponding Classic item/spell records by WoW ID/spell ID, especially:

```text
3919  Rough Dynamite recipe
3920  Crafted Light Shot recipe
3922  Handful of Copper Bolts recipe
3923  Rough Copper Bomb recipe
3924  Copper Tube recipe
3925  Rough Boomstick recipe
3926  Copper Modulator recipe
3928  Mechanical Squirrel recipe
3929  Coarse Blasting Powder recipe
3930  Crafted Heavy Shot recipe
3931  Coarse Dynamite recipe
3977  Crude Scope recipe
7430  Arclight Spanner recipe

4357  Rough Blasting Powder
4358  Rough Dynamite
4359  Handful of Copper Bolts
4360  Rough Copper Bomb
4361  Copper Tube
4362  Rough Boomstick
4363  Copper Modulator
4364  Coarse Blasting Powder
4365  Coarse Dynamite
4401  Mechanical Squirrel Box
4405  Crude Scope
4408  Schematic: Mechanical Squirrel
6219  Arclight Spanner
8067  Crafted Light Shot
8068  Crafted Heavy Shot
```

For any conflict, prefer the Classic/TBC Classic record whose reagent/component model still contains the original vanilla Engineering components. Do not silently substitute modern profession data.

## Incomplete / Blocked Items and Recipes

The source recipe inventory itself is complete. The following implementation limitations must remain visible in the later implementation/validation reports:

| Item / recipe | Complete portion | Incomplete / blocked portion | Smallest follow-up |
|---|---|---|---|
| Rough Dynamite | Item, recipe, shared cooldown, single-target Fire damage | Original 5-yard radial AoE cannot be represented by current spatial targeting | Add generic impact-radius/spatial AoE targeting if exact source behavior is required. |
| Rough Copper Bomb | Item, recipe, single-target Fire damage, one-turn break-on-damage incapacitation Aura, shared cooldown | Original 3-yard radial AoE and `unreliable against targets higher than level 24` rule are not representable exactly | Add spatial AoE targeting and a reusable target-level/reliability gate for effects. |
| Coarse Dynamite | Item, recipe, shared cooldown, single-target Fire damage | Original 5-yard radial AoE cannot be represented by current spatial targeting | Add generic impact-radius/spatial AoE targeting if exact source behavior is required. |
| Crafted Light Shot | Item metadata and recipe | +2 WoW ammo DPS / ammunition combat semantics have no complete RPE execution path | Add generic ammo equipment/consumption and ranged-damage contribution support. |
| Crafted Heavy Shot | Item metadata and recipe | +4.5 WoW ammo DPS / ammunition combat semantics have no complete RPE execution path | Add generic ammo equipment/consumption and ranged-damage contribution support. |
| Crude Scope | Item metadata, modification targeting and recipe | Permanent +1 bow/gun weapon damage cannot be represented by current generic modification stats | Add a generic weapon-damage modification effect/stat path. |
| Mechanical Squirrel Box | Item metadata, world-drop/book recipe | Cosmetic non-combat companion use effect is not represented; current `summon_pet` would be incorrect | Add generic cosmetic companion/non-combat summon support, or explicitly approve metadata-only behavior. |
| Wooden Stock shared material | ID/name/quality/item level/stack/ownership are resolved | Exact Blizzard icon filename was not exposed by the text sources available during preparation | #228 must resolve item 4399's icon token from an authoritative WoW item record before authoring it; do not guess. |