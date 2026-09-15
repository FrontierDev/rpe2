# RPE2 Engineering 75–150 Preparation

## Purpose and authority

This document is the implementation source of truth for Issue #230 and the subsequent Engineering 75–150 implementation issues.

The exact skill boundary remains:

```text
required Engineering skill > 75 and <= 150
```

However, the product scope was explicitly narrowed after the initial preparation pass. **Only the following output categories are to be implemented in this slice:**

- bombs / dynamite;
- guns;
- armour / goggles;
- Flame Deflector, represented as a potion-like consumable;
- ammo.

Everything else in the vanilla Engineering `(75,150]` band is deliberately out of scope for this implementation sequence. Do not add it merely for source completeness.

The final scoped inventory is **14 Recipes / 14 crafted outputs**.

## Explicit exclusions

Do **not** implement any of the following in this slice:

- Target Dummy;
- Silver Contact as its own Item/Recipe;
- Practice Lock;
- Small Seaforium Charge;
- Bronze Tube as its own Item/Recipe;
- Standard Scope or any other scope;
- Heavy Blasting Powder as its own Item/Recipe;
- Whirring Bronze Gizmo as its own Item/Recipe;
- Gnomish Universal Remote;
- Small Blue/Green/Red Rockets;
- Ornate Spyglass;
- Minor Recombobulator;
- Bronze Framework as its own Item/Recipe;
- Explosive Sheep;
- Gold Power Core;
- Aquadynamic Fish Attractor;
- Blue/Green/Red Fireworks;
- Mechanical Squirrel;
- any other utility/device/component output not explicitly listed in the scoped inventory below.

Excluded Engineering components may still appear in **source reagent records**, but dependent RPE Recipes must flatten them to canonical base materials. Their own component Recipes/Items are not part of this slice.

## Project rules carried forward

- Engineering dataset: `af503002`.
- Engineering skill: `f82db71a:xprqs3y1`.
- Every Recipe in this slice uses `learnMode = "trainer"`, regardless of its original Classic acquisition method. The original source is retained below only for provenance.
- Explosive radius effects use the existing multi-target Spell model. Use `target.type = "multi"`, minimum 1 target, maximum 5 targets. The source yard radius is not a blocker and is not spatially simulated.
- Bomb/dynamite Item use follows `Item.useSpellRef -> Spell -> components/Auras`.
- Ammo uses Core Ammo slot `f82db71a:atsoi5vr` and Core Ranged Attack Power `f82db71a:v2rs9cpy`.
- Guns use Core Ranged slot `f82db71a:q8ve6n6t`, Gun weapon type `f82db71a:anoo8qfp`, and Physical school `f82db71a:v1azo4j6`.
- Goggles use Core Head slot `f82db71a:bgvs1zx6` and existing Core stats.
- Reusable Engineering Recipe tools use only Blacksmith Hammer `61fdf3df:518sbr8g`. Never require Arclight Spanner as a Recipe tool.
- Shared materials remain in their canonical owning datasets.
- Mechanical Squirrel remains excluded.

## Current canonical references

```text
Core                      f82db71a
Blacksmithing             61fdf3df
Tailoring                 7259f1d3
Leatherworking            538a54a0
Jewelcrafting             4999dcec
Enchanting                732368d4
Misc                      3eb7e9bb

Physical damage school    f82db71a:v1azo4j6
Fire damage school        f82db71a:esjguw6d
Ranged slot               f82db71a:q8ve6n6t
Ammo slot                 f82db71a:atsoi5vr
Head slot                 f82db71a:bgvs1zx6
Gun weapon type           f82db71a:anoo8qfp
Ranged Attack Power       f82db71a:v2rs9cpy
Armor                     f82db71a:v42albuv
Stamina                   f82db71a:ygjno50i
Spirit                    f82db71a:kec9rhli
Intellect                 f82db71a:75y3a8ib

Copper Bar                61fdf3df:nntycdj5
Coarse Stone              61fdf3df:qcah9yrg
Heavy Stone               61fdf3df:u8qtuhfq
Bronze Bar                61fdf3df:xegz4i5q
Silver Bar                61fdf3df:nvc1anz9
Blacksmith Hammer         61fdf3df:518sbr8g
Wool Cloth                7259f1d3:1wssn0qp
Light Leather             538a54a0:sm9q37oi
Medium Leather            538a54a0:84y6qzsn
Tigerseye                 4999dcec:n2q67aox
Shadowgem                 4999dcec:l3c8nzh7
Lesser Moonstone          4999dcec:w1ryslhj
Moss Agate                4999dcec:gw6wflop
Elemental Fire            732368d4:sclalidn
Wooden Stock              3eb7e9bb:4wc5b4tv
```

`Heavy Stock` is required by two scoped gun Recipes and is not currently packaged. The Item implementation issue must add it to Misc (`3eb7e9bb`) as the canonical shared material. Source metadata: WoW item 4400, common, `interface/icons/inv_mace_11.blp`, item level 25, stack 10.

## Trainer-cost formula

Current `client/client_Crafting.lua` uses:

```text
floor(75 + requiredSkillLevel * 28 + requiredSkillLevel^2 * 1.6)
```

Scoped values:

| Skill | Trainer cost (copper) |
| ---: | ---: |
| 100 | 18,875 |
| 105 | 20,655 |
| 120 | 26,475 |
| 125 | 28,575 |
| 130 | 30,755 |
| 140 | 35,355 |
| 145 | 37,775 |
| 150 | 40,275 |

## Component normalization

The following source Engineering components are **not** implemented as outputs in this slice. When encountered as source reagents, flatten them as follows:

| Source component | RPE normalized material |
| --- | --- |
| Coarse Blasting Powder | Coarse Stone `61fdf3df:qcah9yrg` 1:1 |
| Heavy Blasting Powder | Heavy Stone `61fdf3df:u8qtuhfq` 1:1 |
| Handful of Copper Bolts | Copper Bar `61fdf3df:nntycdj5` 1:1 |
| Copper Tube | Copper Bar `61fdf3df:nntycdj5` 1:1 |
| Bronze Tube | Bronze Bar `61fdf3df:xegz4i5q` 1:1 |
| Silver Contact | Silver Bar `61fdf3df:nvc1anz9` 1:1 |
| Whirring Bronze Gizmo | Bronze Bar `61fdf3df:xegz4i5q` 1:1 |

The substitution is the project semantic 1:1 component-to-base mapping, not recursive multiplication by the component Recipe's own material cost or output yield.

For Flame Deflector, source `Small Flame Sac` follows the existing project material decision: use Enchanting-owned Elemental Fire `732368d4:sclalidn`; do not reintroduce Small Flame Sac.

Green Tinted Goggles are the one deliberate exception to flattening a finished in-scope output: the source Recipe consumes one Flying Tiger Goggles, and the RPE Recipe should preserve that dependency because both goggles are actual scoped equipment rather than throwaway component Items.

## Scoped Recipe inventory

All entries use `skillRef = "f82db71a:xprqs3y1"` and RPE `learnMode = "trainer"`.

| Skill | Output | WoW ID | Original Classic source | Original reagents | Normalized RPE inputs | Output qty | RPE trainer cost |
| ---: | --- | ---: | --- | --- | --- | ---: | ---: |
| 100 | EZ-Thro Dynamite | 6714 | Schematic: EZ-Thro Dynamite (6716), world drop | Coarse Blasting Powder x4; Wool Cloth x1 | Coarse Stone x4; Wool Cloth x1 | 1 | 18,875 |
| 100 | Flying Tiger Goggles | 4368 | Trainer | Light Leather x6; Tigerseye x2 | same; Blacksmith Hammer x1 tool | 1 | 18,875 |
| 105 | Large Copper Bomb | 4370 | Trainer | Copper Bar x3; Coarse Blasting Powder x4; Silver Contact x1 | Copper Bar x3; Coarse Stone x4; Silver Bar x1; Blacksmith Hammer x1 tool | 2 | 20,655 |
| 105 | Deadly Blunderbuss | 4369 | Trainer | Copper Tube x2; Handful of Copper Bolts x4; Wooden Stock x1; Medium Leather x2 | Copper Bar x6; Wooden Stock x1; Medium Leather x2; Blacksmith Hammer x1 tool | 1 | 20,655 |
| 120 | Small Bronze Bomb | 4374 | Trainer | Coarse Blasting Powder x4; Bronze Bar x2; Silver Contact x1; Wool Cloth x1 | Coarse Stone x4; Bronze Bar x2; Silver Bar x1; Wool Cloth x1; Blacksmith Hammer x1 tool | 1–3 | 26,475 |
| 120 | Lovingly Crafted Boomstick | 4372 | Schematic: Lovingly Crafted Boomstick (13309), limited vendor | Bronze Tube x2; Handful of Copper Bolts x2; Heavy Stock x1; Moss Agate x3 | Bronze Bar x2; Copper Bar x2; Heavy Stock x1; Moss Agate x3; Blacksmith Hammer x1 tool | 1 | 26,475 |
| 120 | Shadow Goggles | 4373 | Schematic: Shadow Goggles (4410), world drop | Medium Leather x4; Shadowgem x2 | same | 1 | 26,475 |
| 125 | Crafted Solid Shot | 8069 | Trainer | Heavy Blasting Powder x1; Bronze Bar x1 | Heavy Stone x1; Bronze Bar x1 | 200 | 28,575 |
| 125 | Heavy Dynamite | 4378 | Trainer | Heavy Blasting Powder x2; Wool Cloth x1 | Heavy Stone x2; Wool Cloth x1 | 1–5 | 28,575 |
| 125 | Flame Deflector | 4376 | Schematic: Flame Deflector (4411), Mekgineer Thermaplugg drop | Whirring Bronze Gizmo x1; Small Flame Sac x1 | Bronze Bar x1; Elemental Fire x1; Blacksmith Hammer x1 tool | 1 | 28,575 |
| 130 | Silver-plated Shotgun | 4379 | Trainer | Bronze Tube x2; Whirring Bronze Gizmo x2; Heavy Stock x1; Silver Bar x3 | Bronze Bar x4; Heavy Stock x1; Silver Bar x3 | 1 | 30,755 |
| 140 | Big Bronze Bomb | 4380 | Trainer | Heavy Blasting Powder x2; Bronze Bar x3; Silver Contact x1 | Heavy Stone x2; Bronze Bar x3; Silver Bar x1; Blacksmith Hammer x1 tool | 2 | 35,355 |
| 145 | Moonsight Rifle | 4383 | Schematic: Moonsight Rifle (4412), world drop | Bronze Tube x3; Whirring Bronze Gizmo x3; Heavy Stock x1; Lesser Moonstone x2 | Bronze Bar x6; Heavy Stock x1; Lesser Moonstone x2; Blacksmith Hammer x1 tool | 1 | 37,775 |
| 150 | Green Tinted Goggles | 4385 | Trainer | Medium Leather x4; Moss Agate x2; Flying Tiger Goggles x1 | same; Blacksmith Hammer x1 tool | 1 | 40,275 |

### Tool rule clarification

Classic source data sometimes lists Arclight Spanner, alone or alongside Blacksmith Hammer. Under the current project rule, **Arclight Spanner must never be authored as a Recipe tool**. Where a scoped Recipe has a reusable-tool requirement, use only Blacksmith Hammer.

## Item inventory

### Bombs and dynamite

| Item | WoW ID | Item level | Required level | Quality | Stack | Icon | Source use effect | RPE representation |
| --- | ---: | ---: | ---: | --- | ---: | --- | --- | --- |
| EZ-Thro Dynamite | 6714 | 25 | 10 | common | 20 | `interface/icons/inv_misc_bomb_06.blp` | 51–69 Fire damage in 5 yd; 1 min cooldown; no Engineering use requirement | consumable + item-use Spell; multi 1–5; 60 Fire damage; 5-turn `engineering_explosive` cooldown |
| Large Copper Bomb | 4370 | 26 | — | common | 10 | `interface/icons/inv_misc_bomb_01.blp` | 43–57 Fire damage in 5 yd; incapacitates 1 sec; breaks on damage; Engineering 105 | consumable + item-use Spell; multi 1–5; 50 Fire damage; 1-turn control Aura; 5-turn `engineering_explosive` cooldown |
| Small Bronze Bomb | 4374 | 29 | — | common | 10 | `interface/icons/inv_misc_bomb_09.blp` | 73–97 Fire damage in 3 yd; incapacitates/stuns 2 sec; breaks on damage; Engineering 120 | consumable + item-use Spell; multi 1–5; 85 Fire damage; 1-turn control Aura; 5-turn `engineering_explosive` cooldown |
| Heavy Dynamite | 4378 | 30 | — | common | 20 | `interface/icons/inv_misc_bomb_06.blp` | 128–172 Fire damage in 5 yd; Engineering 125 | consumable + item-use Spell; multi 1–5; 150 Fire damage; 5-turn `engineering_explosive` cooldown |
| Big Bronze Bomb | 4380 | 33 | — | common | 10 | `interface/icons/inv_misc_bomb_05.blp` | 85–115 Fire damage in 5 yd; incapacitates/stuns 2 sec; breaks on damage; Engineering 140 | consumable + item-use Spell; multi 1–5; 100 Fire damage; 1-turn control Aura; 5-turn `engineering_explosive` cooldown |

Damage ranges use their arithmetic midpoint, matching the project's existing simplified fixed-value Engineering representation. The control Auras should use `cancelOnDamage = true`, `preventCasting = true`, `movementRangeOverride = 0`, and the established control semantics used by the prior Rough Copper Bomb implementation.

### Guns

All four guns are `itemType = "weapon"`, bind on equip, use Ranged slot `f82db71a:q8ve6n6t`, Gun type `f82db71a:anoo8qfp`, Physical school `f82db71a:v1azo4j6`, and should expose one generic modification capacity so normal scopes can be applied even though scopes themselves are excluded from this slice.

| Item | WoW ID | Item level | Required level | Quality | Source damage | RPE damage range | Icon |
| --- | ---: | ---: | ---: | --- | --- | --- | --- |
| Deadly Blunderbuss | 4369 | 21 | 16 | uncommon | 15–28 | 15–28 | `interface/icons/inv_weapon_rifle_07.blp` |
| Lovingly Crafted Boomstick | 4372 | 24 | 19 | uncommon | 12–23 | 12–23 | `interface/icons/inv_weapon_rifle_07.blp` |
| Silver-plated Shotgun | 4379 | 26 | 21 | uncommon | 19–37 | 19–37 | `interface/icons/inv_weapon_rifle_07.blp` |
| Moonsight Rifle | 4383 | 29 | 24 | uncommon | 14–26 | 14–26 | `interface/icons/inv_weapon_rifle_07.blp` |

Do not create on-use Spells for these guns.

### Armour / goggles

All three goggles are bind-on-equip Cloth head armour and require the listed Engineering skill as an Item condition.

| Item | WoW ID | Item level | Quality | Icon | Source stats | RPE stats |
| --- | ---: | ---: | --- | --- | --- | --- |
| Flying Tiger Goggles | 4368 | 20 | uncommon | `interface/icons/inv_helmet_47.blp` | 27 Armor, +4 Stamina, +4 Spirit | Armor +27; Stamina +4; Spirit +4 |
| Shadow Goggles | 4373 | 24 | uncommon | `interface/icons/inv_helmet_47.blp` | 31 Armor, +5 Intellect, +6 Spirit | Armor +31; Intellect +5; Spirit +6 |
| Green Tinted Goggles | 4385 | 30 | uncommon | `interface/icons/inv_helmet_47.blp` | 35 Armor, +8 Stamina, +7 Spirit | Armor +35; Stamina +8; Spirit +7 |

Use `itemType = "armor"`, `armorWeight = "cloth"`, Head slot `f82db71a:bgvs1zx6`, and one generic modification capacity consistent with other equipment.

### Ammo

**Crafted Solid Shot** (WoW item 8069):

- item level 35;
- required level 30;
- common;
- max stack 200;
- icon `interface/icons/inv_ammo_bullet_02.blp`;
- source effect: +8.5 ranged weapon DPS;
- RPE: Ammo slot `f82db71a:atsoi5vr`, +8.5 Ranged Attack Power `f82db71a:v2rs9cpy`;
- no `useSpellRef`;
- no Engineering use requirement.

This directly continues the already-approved Crafted Light Shot / Crafted Heavy Shot representation.

## Flame Deflector — user-directed potion-like representation

### Source behavior

Classic Flame Deflector (WoW item 4376) is item level 25, requires level 15, has 5 charges, absorbs 500 Fire damage for up to 1 minute, and has a 15-minute cooldown. Its recipe requires Engineering 125 and originates from Schematic: Flame Deflector (4411), dropped by Mekgineer Thermaplugg.

### RPE behavior

Do **not** model Flame Deflector as a charge-based Engineering device or equippable trinket. Treat it like the existing Alchemy protection-potion pattern:

```text
Item (consumable)
  -> useSpellRef
     -> self-target Spell
        -> Fire-protection Aura
```

Author the Item as a normal consumable so the existing `client_ItemUse.lua` path consumes one Item after cast acceptance.

Use the current Alchemy Fire Protection Potion mechanics as the implementation template:

- `itemType = "consumable"`;
- self/caster target;
- instant activation;
- `ignoreGCD = true`;
- `triggersGCD = false`;
- item-only Spell with `learnMode = "unavailable"`;
- 10-turn cooldown;
- `cooldownGroup = "potion"`;
- supporting Aura duration 3 turns;
- Aura grants +50 Fire Resistance via Core stat `f82db71a:0w7c7p09`;
- generated Spell/Aura description remains authoritative.

This is an intentional RPE simplification. The source five-charge state, 500-point absorb pool, one-minute duration and 15-minute cooldown are **not** separately reproduced. One crafted Flame Deflector becomes one RPE consumable use.

## Spell/Aura inventory

The Spell/Aura implementation issue only needs these six item-use Spells plus three supporting control Auras and one Flame Deflector Aura:

| Spell | Target | Effect | Cooldown |
| --- | --- | --- | --- |
| EZ-Thro Dynamite | multi, 1–5 | 60 Fire damage | 5 turns, `engineering_explosive` |
| Large Copper Bomb | multi, 1–5 | 50 Fire damage + 1-turn break-on-damage control Aura | 5 turns, `engineering_explosive` |
| Small Bronze Bomb | multi, 1–5 | 85 Fire damage + 1-turn break-on-damage control Aura | 5 turns, `engineering_explosive` |
| Heavy Dynamite | multi, 1–5 | 150 Fire damage | 5 turns, `engineering_explosive` |
| Big Bronze Bomb | multi, 1–5 | 100 Fire damage + 1-turn break-on-damage control Aura | 5 turns, `engineering_explosive` |
| Flame Deflector | caster/self | apply +50 Fire Resistance Aura for 3 turns | 10 turns, `potion` |

Bomb Spells should follow the current Engineering 1–75 item-only Spell conventions for cast/GCD/tooltip fields. Flame Deflector should follow the current Alchemy protection-potion conventions instead.

## Dependencies

After this slice is implemented, Engineering requires the current external dependencies used by the scoped data:

```text
f82db71a  Core
61fdf3df  Blacksmithing
7259f1d3  Tailoring
538a54a0  Leatherworking
4999dcec  Jewelcrafting
732368d4  Enchanting
3eb7e9bb  Misc
```

No new profession dataset is required.

## Runtime caveats re-checked on current dev

- `cancelOnDamage` is now represented by the current Aura/damage runtime and should not be reported as a blocker for the new bomb control Auras.
- Item use still resolves consumables through `useSpellRef` and consumes the inventory item only after the cast is accepted, which is suitable for Flame Deflector.
- Item conditions remain serializable and tooltipable, but the generic item-use/equipment mutation paths do not uniformly enforce every Item condition. Engineering skill/use/equip restrictions therefore remain a generic enforcement caveat.
- Item-only shared cooldown-group discovery remains action-bar-oriented. The authored shared `engineering_explosive` group is correct data, but cross-item propagation remains a generic runtime caveat unless separately fixed.

Neither caveat blocks authoring the scoped Items/Spells/Recipes.

## Deterministic validation for downstream issues

The subsequent implementation must verify:

- exactly these 14 scoped Recipes are added for `(75,150]`;
- no excluded Recipe or Item is added;
- all 14 Recipes use `learnMode = "trainer"`;
- no skill-75 Recipe is duplicated;
- no skill >150 Recipe is introduced;
- every normalized material ref resolves, with Heavy Stock added once to Misc;
- no excluded Engineering component is introduced merely to satisfy a dependent Recipe;
- no Arclight Spanner Recipe-tool requirement is authored;
- every gun uses the existing ranged/gun/Physical equipment model;
- all goggles use exact source Armor/stat values and Core refs;
- Crafted Solid Shot uses Ammo slot +8.5 Ranged Attack Power;
- the five explosives use the established multi-target model;
- Flame Deflector uses the Alchemy-style consumable representation defined above;
- no source five-charge device implementation is added for Flame Deflector;
- dataset versions increase monotonically only in files actually changed by downstream implementation.

## Sources used for the scoped preparation

Primary Classic data was cross-checked against current WoW Classic database records for the named Items/Recipes and against current `dev` packaged data. Particularly relevant source identities include:

- WoW Classic Engineering recipe/index data for skill/source boundaries;
- Classic recipe/item records for EZ-Thro Dynamite, Large Copper Bomb, Small Bronze Bomb, Heavy Dynamite and Big Bronze Bomb;
- Classic item/recipe records for Deadly Blunderbuss, Lovingly Crafted Boomstick, Silver-plated Shotgun and Moonsight Rifle;
- Classic records for Flying Tiger Goggles, Shadow Goggles and Green Tinted Goggles;
- Classic Flame Deflector / Schematic: Flame Deflector records;
- Classic Crafted Solid Shot records.

Later retail/seasonal variants were not used for the authored Classic metadata when they differed.

## Incomplete / Blocked Items and Recipes

None of the **scoped 14 Items/Recipes** is blocked from data implementation.

The remaining generic runtime caveats are:

1. item-only shared cooldown-group propagation is not guaranteed across separate inventory-use Spells;
2. Item use/equip skill/level conditions are not uniformly enforced at every mutation boundary.

These are generic runtime limitations, not reasons to omit or substitute any scoped Item or Recipe.