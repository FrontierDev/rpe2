# RPE2 Engineering 1–75 Preparation

**Issue:** #226  
**Target branch:** `dev`  
**Downstream issues:** #227 Spells/Auras, #228 Items/materials, #229 Recipes  
**Canonical Engineering dataset:** `data/default/professions/engineering.lua`  
**Engineering dataset ID:** `af503002`  
**Core Engineering skill:** `f82db71a:xprqs3y1`

## 1. Purpose and scope

This document is the authoritative implementation source of truth for the first vanilla Classic Engineering slice: every legitimate Engineering recipe whose required skill is **1 through 75 inclusive**.

The validated source set contains **14 recipes**:

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

This is not a leveling-guide subset. Skill 1 and skill 75 are included; skill >75 is excluded. `Target Dummy` begins at Engineering 85 and `Silver Contact` at 90, so neither belongs in this slice.

No gameplay implementation belongs in #226. #227–#229 must re-read current source before implementation and treat this document as the prepared data source rather than assuming runtime code is unchanged.

---

## 2. Version/source decisions

Original/vanilla Classic data is authoritative. TBC-era records may be used when they preserve the original vanilla component model. Retail, Cataclysm-remapped profession data, Season of Discovery additions, Anniversary-only changes and later-expansion rewrites are excluded.

Resolved drift cases:

- **Coarse Blasting Powder** requires Engineering **75** for the vanilla progression used here. Do not use later profession-system remaps that surface it at 65.
- **Coarse Dynamite** requires Engineering **75**, consumes **3 Coarse Blasting Powder + 1 Linen Cloth**, and creates **1–3 Coarse Dynamite**. Later data that reduces the powder requirement is not authoritative.
- **Crude Scope** uses the original component recipe: **1 Copper Tube + 1 Malachite + 1 Handful of Copper Bolts**.
- **Mechanical Squirrel Box** uses the original recipe containing **Copper Modulator**. Patch 4.3 removed Copper Modulator and rewrote dependent recipes; that rewrite is excluded.
- **Crafted Light Shot**, **Crafted Heavy Shot** and **Copper Modulator** remain in the source inventory even though later versions removed/replaced them.
- Classic stack sizes are used rather than later 200/1000-stack profession-material conventions.

For implementation cross-checking, the relevant vanilla recipe spell IDs are:

```text
3918  Rough Blasting Powder
3919  Rough Dynamite
3920  Crafted Light Shot
3922  Handful of Copper Bolts
3923  Rough Copper Bomb
3924  Copper Tube
3925  Rough Boomstick
3926  Copper Modulator
3928  Mechanical Squirrel
3929  Coarse Blasting Powder
3930  Crafted Heavy Shot
3931  Coarse Dynamite
3977  Crude Scope
7430  Arclight Spanner
```

Relevant output/item IDs are:

```text
2840  Copper Bar
2880  Weak Flux
4357  Rough Blasting Powder
4358  Rough Dynamite
4359  Handful of Copper Bolts
4360  Rough Copper Bomb
4361  Copper Tube
4362  Rough Boomstick
4363  Copper Modulator
4364  Coarse Blasting Powder
4365  Coarse Dynamite
4399  Wooden Stock
4401  Mechanical Squirrel Box
4405  Crude Scope
4408  Schematic: Mechanical Squirrel
6219  Arclight Spanner
8067  Crafted Light Shot
8068  Crafted Heavy Shot
```

---

## 3. Current RPE architecture inspected

The preparation was checked against current `dev`, including the required profession datasets, `Item.lua`, `Spell.lua`, `Aura.lua`, `Recipe.lua`, item use, crafting, description generation, item tooltips, dependency extraction, packaged dataset registration/install and `RPEngine_Dev.toc`.

### 3.1 Engineering skill

Core already defines Engineering:

```text
f82db71a:xprqs3y1
```

It is an always-available crafting skill. The Engineering dataset must reference this skill and must not create a duplicate.

### 3.2 Item/use architecture

`core/classes/Item.lua` supports the relevant broad types and fields, including weapons, consumables, materials, tools, modifications, equipment slots, stats, skill bonuses and `useSpellRef`.

Manual-use items follow:

```text
Item.useSpellRef -> Spell -> components/effects/Auras
```

Do not add Engineering-specific execution behavior directly to Items.

Core refs used by this slice include:

```text
Ranged slot:  f82db71a:q8ve6n6t
Ammo slot:    f82db71a:atsoi5vr
Main Hand:    f82db71a:d212x0h1
Gun type:     f82db71a:anoo8qfp
Fire school:  f82db71a:esjguw6d
Physical:     f82db71a:v1azo4j6
Engineering:  f82db71a:xprqs3y1
```

### 3.3 Spell/Aura capabilities

Current generic Spells can represent direct damage, healing/resources, Aura application/removal, interrupt/revert/summon-pet effects, single targets and bounded non-spatial multi-target selections.

Current Auras can represent stat/skill/resource changes, periodic effects and control fields such as:

```text
cancelOnDamage
preventCasting
movementRangeOverride
forceAutoHitAgainstTarget
```

Current generic targeting does **not** provide a geometric radius around an impact point. A bounded `multi` target is not equivalent to source bomb/dynamite AoE.

Current `summon_pet` is a combat-pet mechanic and must not be used for the cosmetic Mechanical Squirrel companion.

### 3.4 Recipe semantics

`core/classes/Recipe.lua` supports:

```text
learnMode = always_learned | trainer | book | unavailable
input.kind = rpe_item | tool
```

Reusable recipe tools are therefore representable and must not be consumed.

Current trainer-cost calculation in `client/client_Crafting.lua` is:

```text
floor(75 + requiredSkillLevel * 28 + requiredSkillLevel^2 * 1.6)
```

Relevant values:

| Skill | Trainer-cost field |
|---:|---:|
| 1 | 104 |
| 30 | 2,355 |
| 50 | 5,475 |
| 60 | 7,515 |
| 65 | 8,655 |
| 75 | 11,175 |

#229 must re-read the live function and recalculate these values before authoring in case the formula changes.

### 3.5 Packaged dataset behavior

`DefaultDatasets:Register()` requires a unique dataset ID and positive integer version. Packaged definitions are synchronized by the normal default-dataset installation path. Packaged updates must not reactivate a dataset the user has disabled.

---

## 4. Canonical Engineering dataset plan

#227 creates:

```text
data/default/professions/engineering.lua
```

Stable dataset ID:

```text
af503002
```

No collision was found during preparation.

Initial structure:

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

Dependencies represented in this prepared slice:

- Core `f82db71a`;
- Blacksmithing `61fdf3df`;
- Tailoring `7259f1d3`;
- Jewelcrafting `4999dcec`;
- Misc `3eb7e9bb`.

If dependency derivation/current canonical conventions change before implementation, #227 must retain only dependencies genuinely required by the current model rather than copying redundant values blindly.

Add `data/default/professions/engineering.lua` to the packaged-default section of `RPEngine_Dev.toc` in an order where shared owner datasets are available before Engineering data is consumed. Do not introduce range-specific Engineering extension/mutation files.

---

## 5. Shared material ownership

Engineering must reuse existing packaged materials rather than create a parallel material economy. There is no Mining dataset.

### 5.1 Existing canonical inputs

| Material/tool | Owner | Qualified ref | Use in this slice |
|---|---|---|---|
| Rough Stone | Blacksmithing | `61fdf3df:c7urqe23` | Starting explosives/powder; normalization target. |
| Coarse Stone | Blacksmithing | `61fdf3df:qcah9yrg` | Skill-75 explosives/powder; normalization target. |
| Bronze Bar | Blacksmithing | `61fdf3df:xegz4i5q` | Not consumed in 1–75 after normalization; canonical future `Bronze Framework -> Bronze Bar` target. |
| Blacksmith Hammer | Blacksmithing | `61fdf3df:518sbr8g` | Reusable `tool` input where listed. |
| Linen Cloth | Tailoring | `7259f1d3:agzskvec` | Explosives/components. |
| Malachite | Jewelcrafting | `4999dcec:fcj318z0` | Crude Scope and Mechanical Squirrel. |

### 5.2 Missing shared material: Copper Bar

Owner: **Blacksmithing** (`61fdf3df`). Do not place it in Engineering.

| Field | Prepared value |
|---|---|
| WoW item ID | `2840` |
| Name | Copper Bar |
| Icon | `interface/icons/inv_ingot_02.blp` |
| Item level | 10 |
| Required level | none |
| Quality | common |
| Classic stack | 20 |
| Binding | none |
| Trade | tradeable |
| RPE itemType | `material` |

#228 must follow Blacksmithing's current material/WoW-conversion conventions and increment the Blacksmithing packaged version monotonically.

### 5.3 Missing shared material: Weak Flux

Owner: **Misc** (`3eb7e9bb`). It is a general vendor trade material, not an Engineering-crafted component.

| Field | Prepared value |
|---|---|
| WoW item ID | `2880` |
| Name | Weak Flux |
| Icon | `interface/icons/inv_misc_ammo_gunpowder_02.blp` |
| Item level | 5 |
| Required level | none |
| Quality | common |
| Classic stack | 10 |
| Binding | none |
| Trade | tradeable |
| RPE itemType | `material` |

### 5.4 Missing shared material: Wooden Stock

Owner: **Misc** (`3eb7e9bb`). It is a purchased Engineering/blacksmith-supplies part, not an Engineering-crafted component.

| Field | Prepared value |
|---|---|
| WoW item ID | `4399` |
| Name | Wooden Stock |
| Icon | `interface/icons/inv_mace_11.blp` |
| Item level | 10 |
| Required level | none |
| Quality | common |
| Classic stack | 10 |
| Binding | none |
| Trade | tradeable |
| RPE itemType | `material` |

The icon token is resolved and is no longer an implementation blocker.

---

## 6. Engineering component normalization

### 6.1 Project rule

Engineering component normalization is a **1:1 substitution rule**, not recursive raw-cost expansion.

When a dependent Engineering recipe consumes a mapped Engineering-only component, replace each unit of that component with the same quantity of the designated shared/base material unless explicitly stated otherwise.

Examples:

```text
2 Rough Blasting Powder   -> 2 Rough Stone
1 Handful of Copper Bolts -> 1 Copper Bar
1 Copper Tube             -> 1 Copper Bar
```

Do not expand the full raw cost that was required to craft the component. The component recipe/output still exists for source completeness; downstream recipes simply do not require the component item where a normalization mapping exists.

Reusable tools are not flattened.

### 6.2 Authoritative normalization table

| Engineering component | RPE normalized material | Quantity rule | Retain component Item/Recipe? |
|---|---|---|---|
| Rough Blasting Powder | Rough Stone | 1:1 | Yes |
| Handful of Copper Bolts | Copper Bar | 1:1 | Yes |
| Copper Tube | Copper Bar | 1:1 | Yes |
| Copper Modulator | Copper Bar | 1:1 | Yes |
| Coarse Blasting Powder | Coarse Stone | 1:1 | Yes |
| Arclight Spanner | none | remains reusable tool | Yes |

Future-range policy already fixed by the project:

```text
Bronze Framework -> Bronze Bar, 1:1
```

Bronze Framework itself is outside skill 1–75 and must not be introduced by #227–#229.

---

## 7. Authoritative recipe inventory

The `Vanilla source inputs` column records the original Engineering recipe. `Normalized RPE inputs` is authoritative for #229.

| # | Skill | Recipe | Acquisition / learnMode | Vanilla source inputs | Normalized RPE inputs | Output | Reusable tools | Trainer cost |
|---:|---:|---|---|---|---|---|---|---:|
| 1 | 1 | Rough Blasting Powder | starting / `always_learned` | Rough Stone x1 | Rough Stone x1 | Rough Blasting Powder x1 | none | 104 |
| 2 | 1 | Rough Dynamite | starting / `always_learned` | Rough Blasting Powder x2; Linen Cloth x1 | Rough Stone x2; Linen Cloth x1 | Rough Dynamite x2 | none | 104 |
| 3 | 1 | Crafted Light Shot | starting / `always_learned` | Rough Blasting Powder x1; Copper Bar x1 | Rough Stone x1; Copper Bar x1 | Crafted Light Shot x200 | none | 104 |
| 4 | 30 | Handful of Copper Bolts | trainer / `trainer` | Copper Bar x1 | Copper Bar x1 | Handful of Copper Bolts x1 | Blacksmith Hammer | 2,355 |
| 5 | 30 | Rough Copper Bomb | trainer / `trainer` | Copper Bar x1; Handful of Copper Bolts x1; Rough Blasting Powder x2; Linen Cloth x1 | Copper Bar x2; Rough Stone x2; Linen Cloth x1 | Rough Copper Bomb x2 | Blacksmith Hammer | 2,355 |
| 6 | 50 | Arclight Spanner | trainer / `trainer` | Copper Bar x6 | Copper Bar x6 | Arclight Spanner x1 | Blacksmith Hammer | 5,475 |
| 7 | 50 | Copper Tube | trainer / `trainer` | Copper Bar x2; Weak Flux x1 | Copper Bar x2; Weak Flux x1 | Copper Tube x1 | Blacksmith Hammer | 5,475 |
| 8 | 50 | Rough Boomstick | trainer / `trainer` | Copper Tube x1; Handful of Copper Bolts x1; Wooden Stock x1 | Copper Bar x2; Wooden Stock x1 | Rough Boomstick x1 | Blacksmith Hammer | 5,475 |
| 9 | 60 | Crude Scope | trainer / `trainer` | Copper Tube x1; Malachite x1; Handful of Copper Bolts x1 | Copper Bar x2; Malachite x1 | Crude Scope x1 | Arclight Spanner | 7,515 |
| 10 | 65 | Copper Modulator | trainer / `trainer` | Handful of Copper Bolts x2; Copper Bar x1; Linen Cloth x2 | Copper Bar x3; Linen Cloth x2 | Copper Modulator x1 | Blacksmith Hammer; Arclight Spanner | 8,655 |
| 11 | 75 | Coarse Blasting Powder | trainer / `trainer` | Coarse Stone x1 | Coarse Stone x1 | Coarse Blasting Powder x1 | none | 11,175 |
| 12 | 75 | Coarse Dynamite | trainer / `trainer` | Coarse Blasting Powder x3; Linen Cloth x1 | Coarse Stone x3; Linen Cloth x1 | Coarse Dynamite x1–3 | none | 11,175 |
| 13 | 75 | Crafted Heavy Shot | trainer / `trainer` | Coarse Blasting Powder x1; Copper Bar x1 | Coarse Stone x1; Copper Bar x1 | Crafted Heavy Shot x200 | none | 11,175 |
| 14 | 75 | Mechanical Squirrel Box | world-drop schematic / `book` | Copper Modulator x1; Handful of Copper Bolts x1; Copper Bar x1; Malachite x2 | Copper Bar x3; Malachite x2 | Mechanical Squirrel Box x1 | Blacksmith Hammer; Arclight Spanner | — |

### 7.1 Qualified refs for external normalized inputs

Where already present on `dev`, #229 uses:

```text
Rough Stone      61fdf3df:c7urqe23
Coarse Stone     61fdf3df:qcah9yrg
Linen Cloth      7259f1d3:agzskvec
Malachite        4999dcec:fcj318z0
Blacksmith Hammer 61fdf3df:518sbr8g
```

Copper Bar, Weak Flux and Wooden Stock refs are assigned by #228 after the new canonical Items are authored. #229 must read those final refs rather than guessing IDs.

### 7.2 Starting recipes

The three starting recipes are:

- Rough Blasting Powder;
- Rough Dynamite;
- Crafted Light Shot.

Use `always_learned`, matching current RPE starting-profession semantics.

### 7.3 Mechanical Squirrel acquisition

Source recipe item:

```text
Schematic: Mechanical Squirrel
WoW item ID: 4408
quality: uncommon
item level: 15
requires Engineering 75
source: rare world drop
```

Use RPE `learnMode = "book"`. Do not flatten this into a trainer recipe.

#229 must trace the current book-learning path before deciding whether an explicit RPE schematic Item is required. If the current path can represent book acquisition without a physical schematic Item, no extra Item should be added solely for symmetry.

### 7.4 Workstation abstraction

Some source recipes require an Anvil. Current Recipe data models reusable Item tools but not a world workstation/environment requirement.

For 1–75:

- preserve Blacksmith Hammer and Arclight Spanner as `kind = "tool"` where listed;
- do not create/consume an Anvil Item;
- do not block otherwise-valid recipes because the workstation requirement is not modeled;
- treat the missing Anvil requirement as an approved environmental abstraction.

---

## 8. Authoritative item inventory

Use exact source item levels below. Do not replace known Engineering item levels with a generic `required level + 5` rule.

| Item | WoW ID | Source metadata | Icon | RPE representation |
|---|---:|---|---|---|
| Rough Blasting Powder | 4357 | common; ilvl 5; req level none; stack 20; nonbinding/tradeable | `interface/icons/inv_misc_dust_01.blp` | `material`; retained output, but dependent recipes use Rough Stone. |
| Rough Dynamite | 4358 | common; ilvl 10; req level none; stack 20; nonbinding/tradeable; requires Engineering 1 to use | `interface/icons/inv_misc_bomb_06.blp` | `consumable` with #227 `useSpellRef`. |
| Crafted Light Shot | 8067 | common; ilvl 10; req level 5; stack 200; Ammo/Bullet; +2 WoW ammo DPS; nonbinding/tradeable | `interface/icons/inv_ammo_bullet_02.blp` | Ammo item metadata; combat ammo effect blocked. |
| Handful of Copper Bolts | 4359 | common; ilvl 8; req level none; stack 10; nonbinding/tradeable | `interface/icons/inv_misc_gear_06.blp` | `material`; retained output, dependent recipes use Copper Bar. |
| Rough Copper Bomb | 4360 | common; ilvl 14; req level none; stack 10; nonbinding/tradeable; requires Engineering 30 to use | `interface/icons/inv_misc_bomb_09.blp` | `consumable` with #227 `useSpellRef`. |
| Arclight Spanner | 6219 | common; ilvl 10; req level none; Main Hand Miscellaneous; 5–8 damage; speed 2.40; requires Engineering 50; nonbinding/tradeable | `interface/icons/inv_misc_wrench_01.blp` | Main-Hand `weapon`; also reusable recipe `tool`. Preserve 5–8 damage in current weapon abstraction; source attack speed is not serialized. |
| Copper Tube | 4361 | common; ilvl 10; req level none; stack 10; nonbinding/tradeable | `interface/icons/inv_gizmo_pipe_02.blp` | `material`; retained output, dependent recipes use Copper Bar. |
| Rough Boomstick | 4362 | uncommon; ilvl 10; req level 5; BoE; Ranged Gun; 6–13 damage; speed 2.30; durability 35 | `interface/icons/inv_weapon_rifle_03.blp` | `weapon`; Ranged slot `f82db71a:q8ve6n6t`; Gun `f82db71a:anoo8qfp`; physical damage. |
| Crude Scope | 4405 | common; ilvl 12; req level 5; stack 5; nonbinding/tradeable; permanently adds +1 weapon damage to bow/gun | `interface/icons/inv_misc_spyglass_02.blp` | `modification` targeted to ranged bows/guns; +1 weapon-damage effect blocked. |
| Copper Modulator | 4363 | common; ilvl 13; req level none; stack 10; nonbinding/tradeable | `interface/icons/inv_gizmo_03.blp` | `material`; retained output, dependent recipes use Copper Bar. |
| Coarse Blasting Powder | 4364 | common; ilvl 15; req level none; stack 20; nonbinding/tradeable | `interface/icons/inv_misc_dust_02.blp` | `material`; retained output, dependent recipes use Coarse Stone. |
| Coarse Dynamite | 4365 | common; ilvl 20; req level none; stack 20; nonbinding/tradeable; requires Engineering 75 to use | `interface/icons/inv_misc_bomb_06.blp` | `consumable` with #227 `useSpellRef`. |
| Crafted Heavy Shot | 8068 | common; ilvl 20; req level 15; stack 200; Ammo/Bullet; +4.5 WoW ammo DPS; nonbinding/tradeable | `interface/icons/inv_ammo_bullet_02.blp` | Ammo item metadata; combat ammo effect blocked. |
| Mechanical Squirrel Box | 4401 | common; ilvl 15; req level none; stack 1; binds when used; cosmetic non-combat companion | `interface/icons/inv_crate_01.blp` | Item metadata; companion use effect blocked rather than misusing combat `summon_pet`. |

### 8.1 Profession requirements on Items

Several source outputs require a minimum Engineering rank to use/equip. #228 must re-read the current generic Item condition system before authoring these restrictions. If it can express a crafting-skill requirement correctly, use it. If not, do not substitute a character-level condition; retain the source requirement in the validation report as an enforcement limitation.

### 8.2 Component output retention

The following remain real Engineering Items and Recipes even though mapped dependent inputs do not consume them:

- Rough Blasting Powder;
- Handful of Copper Bolts;
- Copper Tube;
- Copper Modulator;
- Coarse Blasting Powder.

This preserves the complete vanilla source inventory without forcing an Engineering-component dependency chain.

---

## 9. Spell/Aura design inventory

Only three 1–75 outputs require RPE combat-use Spells in this slice:

- Rough Dynamite;
- Rough Copper Bomb;
- Coarse Dynamite.

Mechanical Squirrel Box has a source use effect but is deliberately blocked because current `summon_pet` means combat pet rather than cosmetic companion.

### 9.1 Shared Engineering explosive cooldown

Source explosives use a one-minute shared-style Engineering cooldown. Preserve the project's turn-time mapping used by current item-use design:

```text
1 minute source cooldown -> 5 RPE turns
```

Use one shared cooldown group:

```text
engineering_explosive
```

Prepared use-Spell defaults:

```text
castTime = 0
cooldown = 5
cooldownGroup = "engineering_explosive"
ignoreGCD = true
triggersGCD = false
learnMode = "unavailable"
```

Do not add item-local cooldown execution.

### 9.2 Rough Dynamite

Source effect:

```text
26–34 Fire damage in a 5-yard radius.
```

Prepared RPE effect:

- target: one enemy;
- range: 30;
- direct Fire damage;
- `baseDamage = 30` midpoint;
- damage school `f82db71a:esjguw6d`;
- no stat scaling;
- 5-turn shared Engineering explosive cooldown;
- no Aura.

The source 5-yard radial AoE is **not** representable by current spatial targeting. Do not fake it with an arbitrary bounded `multi` target.

Item tooltip must come from the generated Spell description through `useSpellRef`; do not duplicate a hand-authored effect description on the Item. Expected semantic form:

```text
Use: Deal approximately 30 Fire damage to an enemy. (5 turn cooldown)
```

The current description builder may render its normal damage variance rather than the literal midpoint.

### 9.3 Rough Copper Bomb

Source effect:

```text
22–28 Fire damage in a 3-yard radius.
Incapacitates for 1 second; damage breaks the effect.
Unreliable against targets above level 24.
```

Prepared RPE Spell:

- target: one enemy;
- range: 20;
- component 1: direct Fire damage, `baseDamage = 25`, no scaling;
- component 2: apply the supporting control Aura below;
- order damage **before** Aura application so the bomb's own damage cannot cancel the just-applied Aura;
- 5-turn shared Engineering explosive cooldown;
- ignore GCD.

Supporting Aura:

```text
Name: Rough Copper Bomb Incapacitation
Duration: 1 turn
maxStacks: 1
stackBehavior: refresh_duration
cancelOnDamage: true
preventCasting: true
movementRangeOverride: 0
forceAutoHitAgainstTarget: false
```

One RPE turn is the approved coarse adaptation of the source one-second incapacitation.

Not represented exactly:

- source 3-yard radial AoE;
- the source higher-level unreliability rule.

Do not invent an ad-hoc target-level reliability mechanic inside the Engineering dataset.

### 9.4 Coarse Dynamite

Source effect:

```text
51–69 Fire damage in a 5-yard radius.
```

Prepared RPE effect:

- target: one enemy;
- range: 30;
- direct Fire damage;
- `baseDamage = 60` midpoint;
- damage school `f82db71a:esjguw6d`;
- no stat scaling;
- 5-turn shared Engineering explosive cooldown;
- no Aura.

The source 5-yard radial AoE remains blocked by missing spatial impact-radius targeting. Do not simulate it using an arbitrary max-target count.

### 9.5 Other gameplay classifications

| Output | Classification | Decision |
|---|---|---|
| Rough Boomstick | normal weapon | Represent through existing ranged weapon data, not a use Spell. |
| Arclight Spanner | weapon + recipe tool | Represent through existing weapon/tool semantics. |
| Crude Scope | modification | Item/targeting metadata is representable; +1 weapon damage modification is blocked. |
| Crafted Light Shot | ammo | Item metadata representable; +2 DPS ammo combat semantics blocked. |
| Crafted Heavy Shot | ammo | Item metadata representable; +4.5 DPS ammo combat semantics blocked. |
| Mechanical Squirrel Box | cosmetic use | Do not use combat-pet `summon_pet`; metadata only until generic cosmetic companion support exists. |
| Powders/bolts/tubes/modulator | materials | No Spell/Aura. |

---

## 10. Downstream implementation plan

### #227 — Spells and supporting Aura

1. Re-read current `dev` Spell/Aura/item-use/description paths.
2. Create canonical `engineering.lua` with dataset ID `af503002` and packaged version 1.
3. Add the file to `RPEngine_Dev.toc` in the packaged-default section.
4. Implement Rough Dynamite Spell.
5. Implement Rough Copper Bomb Spell and one-turn incapacitation Aura.
6. Implement Coarse Dynamite Spell.
7. Use shared `engineering_explosive` cooldown semantics.
8. Validate generated descriptions and do not add duplicate Item effect prose.
9. Do not add spatial AoE, cosmetic companion or other generic-engine work under #227.

### #228 — Items and shared materials

1. Re-read final current owner datasets before writing.
2. Reuse Rough Stone, Coarse Stone, Bronze Bar, Linen Cloth, Malachite and Blacksmith Hammer rather than duplicating them.
3. Add Copper Bar to canonical Blacksmithing if still absent.
4. Add Weak Flux and Wooden Stock to canonical Misc if still absent.
5. Use Wooden Stock icon `interface/icons/inv_mace_11.blp`.
6. Add all 14 prepared Engineering output Items to canonical `engineering.lua`.
7. Attach only the three exact #227 `useSpellRef` values.
8. Preserve component outputs as real Items even though dependent recipe inputs normalize them away.
9. Preserve exact source item levels/icons/stack/binding/equipment metadata.
10. Increment every modified packaged dataset monotonically without reactivating disabled datasets.

### #229 — Recipes

1. Re-read final current Item refs and crafting code.
2. Implement all 14 prepared recipes directly in canonical `engineering.lua`.
3. Use the `Normalized RPE inputs` column, not mapped Engineering-component refs.
4. Preserve `always_learned`, `trainer` and `book` acquisition distinctions.
5. Preserve output quantities exactly, especially Rough Dynamite x2, Rough Copper Bomb x2, ammunition x200 and Coarse Dynamite x1–3.
6. Use Blacksmith Hammer/Arclight Spanner as reusable tool inputs where specified.
7. Recalculate trainer cost from live code before authoring.
8. Compare the final implementation against all 14 source rows and explicitly report any omission or partial implementation.

---

## 11. Deterministic validation completed for #226

- [x] Complete vanilla Classic Engineering 1–75 source inventory identified: **14 recipes**.
- [x] Skill 1 included.
- [x] Skill 75 included.
- [x] No >75 recipe included.
- [x] Starting, trainer and world-drop/book acquisition resolved for every recipe.
- [x] Mechanical Squirrel preserved as a world-drop/book recipe.
- [x] Original source reagents and quantities recorded separately from normalized RPE inputs.
- [x] Output quantities resolved for every recipe.
- [x] Every Engineering intermediate/component in the range has an explicit retain/flatten decision.
- [x] Component normalization is explicit 1:1 project substitution, not recursive raw-cost expansion.
- [x] `Rough Blasting Powder -> Rough Stone` explicit.
- [x] `Coarse Blasting Powder -> Coarse Stone` explicit.
- [x] Copper bolts/tube/modulator normalization to Copper Bar explicit.
- [x] Future `Bronze Framework -> Bronze Bar` policy preserved.
- [x] Existing Rough Stone, Coarse Stone, Bronze Bar, Linen Cloth, Malachite and Blacksmith Hammer refs resolved.
- [x] Copper Bar assigned to Blacksmithing rather than Engineering.
- [x] Weak Flux and Wooden Stock assigned to Misc rather than Engineering.
- [x] Wooden Stock icon resolved to `interface/icons/inv_mace_11.blp`.
- [x] No Mining dataset proposed.
- [x] Every crafted output has prepared WoW ID, exact name/icon, item level, required character level, quality, Classic stack and binding/trade decision.
- [x] Equipment slot/weapon metadata prepared where applicable.
- [x] Manual-use outputs have concrete Spell/Aura designs or an explicit blocker.
- [x] Unsupported spatial AoE is not disguised as bounded non-spatial multi-targeting.
- [x] Mechanical Squirrel is not incorrectly mapped to a combat pet.
- [x] Crude Scope is not approximated using an unrelated stat.
- [x] Ammo DPS is not approximated using an unrelated stat.
- [x] Engineering dataset ID, skeleton, dependency and TOC/load plan are prepared.
- [x] Packaged version/update behavior is documented.
- [x] Later-era and seasonal drift is explicitly excluded.
- [x] No implementation code/data change was made under #226.

## Incomplete / Blocked Items and Recipes

The **source-data preparation is complete**: there are no unresolved recipe identities, source reagent quantities, acquisition methods, normalized material mappings, shared-material owners, output quantities, item IDs, item icons, item levels, required character levels, qualities, stack sizes or binding decisions in the 1–75 inventory.

The following are deliberate **downstream engine/representation limitations**, and must remain flagged in #227–#229 implementation reports rather than being silently approximated:

| Item / recipe | Complete prepared portion | Incomplete / blocked source behavior | Smallest generic follow-up |
|---|---|---|---|
| Rough Dynamite | Item, recipe, single-target Fire Spell, shared cooldown | Original 5-yard radial AoE | Add generic impact-radius/spatial AoE targeting. |
| Rough Copper Bomb | Item, recipe, single-target Fire damage, one-turn break-on-damage incapacitation, shared cooldown | Original 3-yard radial AoE and higher-level unreliability rule | Add spatial AoE targeting and a reusable target-level/effect-reliability gate. |
| Coarse Dynamite | Item, recipe, single-target Fire Spell, shared cooldown | Original 5-yard radial AoE | Add generic impact-radius/spatial AoE targeting. |
| Crafted Light Shot | Item metadata and recipe | +2 WoW ammo DPS / ammunition combat semantics | Add generic ammo equipment/consumption and ranged-damage contribution support. |
| Crafted Heavy Shot | Item metadata and recipe | +4.5 WoW ammo DPS / ammunition combat semantics | Add generic ammo equipment/consumption and ranged-damage contribution support. |
| Crude Scope | Item metadata, modification targeting and recipe | Permanent +1 bow/gun weapon damage | Add a generic weapon-damage modification path. |
| Mechanical Squirrel Box | Item metadata and book recipe | Cosmetic non-combat companion summon | Add generic cosmetic companion/non-combat summon support, or explicitly retain metadata-only behavior. |