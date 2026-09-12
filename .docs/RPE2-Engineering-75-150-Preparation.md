# RPE2 Engineering 75–150 Preparation

## Purpose and authority

This document is the implementation source of truth for the vanilla Classic Engineering **75–150 profession tier** in RPE2. It was prepared for #230 and is intended to drive #231 (Spells/Auras), #232 (Items/shared materials), and #233 (Recipes) without those issues independently re-researching source data.

The exact implementation boundary is:

```text
required Engineering skill > 75 and <= 150
```

Skill-75 records are already present in the completed 1–75 slice and must not be duplicated.

The complete vanilla Classic inventory in this boundary is **35 recipes**.

This document records two distinct things wherever they differ:

1. **Source Classic behavior/data** — original recipe identity, acquisition, reagents, output quantities, item metadata and gameplay effect.
2. **RPE representation** — trainer learning, normalized material inputs, canonical RPE references, supported generic mechanics and deliberate simplifications/blockers.

## Project decisions carried forward

The following are authoritative for this slice:

- Every recipe in this range uses RPE `learnMode = "trainer"`, regardless of its original trainer/vendor/drop/quest/schematic source. Historical acquisition remains recorded as provenance only.
- Explosive radius effects use the existing multi-target Spell abstraction. Radius wording is not itself a blocker.
- Ammo uses the Core Ammo slot and Ranged Attack Power representation.
- Scopes use the existing modification/stat model and Ranged Attack Power representation.
- Reusable Recipe tools use **Blacksmith Hammer** `61fdf3df:518sbr8g` only. Do not author Arclight Spanner or any other Engineering-crafted Item as a Recipe tool, even where Classic lists one.
- Mechanical Squirrel remains deliberately excluded; do not reintroduce it.
- Shared materials belong physically in their canonical owner datasets, not Engineering and not range-specific mutation/helper files.
- Engineering-only component chains are flattened to canonical base materials for dependent recipes, while the component's own source recipe/output is retained when it falls inside this range.

## Current RPE contracts and canonical references

Engineering dataset:

```text
Engineering dataset       af503002
Engineering skill         f82db71a:xprqs3y1
```

Relevant packaged datasets:

```text
Core                      f82db71a
Blacksmithing             61fdf3df
Tailoring                 7259f1d3
Leatherworking            538a54a0
Jewelcrafting             4999dcec
Enchanting                732368d4
Misc                      3eb7e9bb
```

Core references used by this slice:

```text
Physical damage school    f82db71a:v1azo4j6
Fire damage school        f82db71a:esjguw6d
Ranged slot               f82db71a:q8ve6n6t
Ammo slot                 f82db71a:atsoi5vr
Head slot                 f82db71a:bgvs1zx6
Trinket slot              f82db71a:139phg06
Gun weapon type           f82db71a:anoo8qfp
Ranged Attack Power       f82db71a:v2rs9cpy
Armor                     f82db71a:v42albuv
Stamina                   f82db71a:ygjno50i
Spirit                    f82db71a:kec9rhli
Intellect                 f82db71a:75y3a8ib
Fishing skill             f82db71a:ahx59weu
```

Current canonical material references reused by this slice:

```text
Copper Bar                61fdf3df:nntycdj5
Rough Stone               61fdf3df:c7urqe23
Coarse Stone              61fdf3df:qcah9yrg
Heavy Stone               61fdf3df:u8qtuhfq
Bronze Bar                61fdf3df:xegz4i5q
Silver Bar                61fdf3df:nvc1anz9
Gold Bar                  61fdf3df:j6g2b8ye
Blacksmith Hammer         61fdf3df:518sbr8g
Weak Flux                 3eb7e9bb:3yvy546j
Wooden Stock              3eb7e9bb:4wc5b4tv
Linen Cloth               7259f1d3:agzskvec
Wool Cloth                7259f1d3:1wssn0qp
Light Leather             538a54a0:sm9q37oi
Medium Leather            538a54a0:84y6qzsn
Heavy Leather             538a54a0:55k8gjup
Tigerseye                 4999dcec:n2q67aox
Malachite                 4999dcec:fcj318z0
Shadowgem                 4999dcec:l3c8nzh7
Lesser Moonstone          4999dcec:w1ryslhj
Moss Agate                4999dcec:gw6wflop
Elemental Fire            732368d4:sclalidn
```

### Live runtime findings relevant to implementation

Current `Recipe`/crafting behavior still distinguishes consumed `rpe_item` inputs from reusable `tool` inputs. Crafting availability requires all declared inputs; consumption removes only `rpe_item` inputs.

The live Engineering trainer-cost formula is:

```text
floor(75 + requiredSkillLevel * 28 + requiredSkillLevel^2 * 1.6)
```

Costs needed by this slice are:

| Skill | Trainer cost (copper) |
| ---: | ---: |
| 85 | 14,015 |
| 90 | 15,555 |
| 100 | 18,875 |
| 105 | 20,655 |
| 110 | 22,515 |
| 120 | 26,475 |
| 125 | 28,575 |
| 130 | 30,755 |
| 135 | 33,015 |
| 140 | 35,355 |
| 145 | 37,775 |
| 150 | 40,275 |

The previous `cancelOnDamage` limitation is **no longer current**: current Aura/damage execution supports removing a qualifying Aura after subsequent damage. It must not be carried forward as a blocker.

The following generic caveats remain relevant:

- player cooldown-group discovery is still action-bar-oriented, so separate Item-only unavailable Spells may not automatically discover one another for shared cooldown-group propagation;
- Item conditions are serializable/tooltipable, but use/equip/modification mutation paths do not uniformly enforce every condition directly;
- there is no generic source-faithful per-Item finite-charge state suitable for Classic devices such as the Flame Deflector and Minor Recombobulator.

## Complete vanilla Classic recipe inventory

All 35 entries below use RPE `learnMode = "trainer"`. Historical source is provenance only.

| # | Skill | Recipe / output | WoW output ID | Historical Classic acquisition | Output | Trainer cost |
| ---: | ---: | --- | ---: | --- | ---: | ---: |
| 1 | 85 | Target Dummy | 4366 | Engineering trainer | 1 | 14,015 |
| 2 | 90 | Silver Contact | 4404 | Engineering trainer | 5 | 15,555 |
| 3 | 100 | Practice Lock | 6712 | Engineering trainer | 1 | 18,875 |
| 4 | 100 | EZ-Thro Dynamite | 6714 | Schematic: EZ-Thro Dynamite (6716), rare/world drop | 1–3 | 18,875 |
| 5 | 100 | Small Seaforium Charge | 4367 | Schematic: Small Seaforium Charge (4409), rare/world/container/fishing source | 1 | 18,875 |
| 6 | 100 | Flying Tiger Goggles | 4368 | Engineering trainer | 1 | 18,875 |
| 7 | 105 | Bronze Tube | 4371 | Engineering trainer | 1 | 20,655 |
| 8 | 105 | Large Copper Bomb | 4370 | Engineering trainer | 2–4 | 20,655 |
| 9 | 105 | Deadly Blunderbuss | 4369 | Engineering trainer | 1 | 20,655 |
| 10 | 110 | Standard Scope | 4406 | Engineering trainer | 1 | 22,515 |
| 11 | 120 | Small Bronze Bomb | 4374 | Engineering trainer | 1–3 | 26,475 |
| 12 | 120 | Lovingly Crafted Boomstick | 4372 | Schematic: Lovingly Crafted Boomstick (13309), limited sale from Fradd Swiftgear / Jinky Twizzlefixxit | 1 | 26,475 |
| 13 | 120 | Shadow Goggles | 4373 | Schematic: Shadow Goggles (4410), rare/world drop | 1 | 26,475 |
| 14 | 125 | Heavy Blasting Powder | 4377 | Engineering trainer | 1 | 28,575 |
| 15 | 125 | Whirring Bronze Gizmo | 4375 | Engineering trainer | 1 | 28,575 |
| 16 | 125 | Crafted Solid Shot | 8069 | Engineering trainer | 200 | 28,575 |
| 17 | 125 | Heavy Dynamite | 4378 | Engineering trainer | 1–5 | 28,575 |
| 18 | 125 | Flame Deflector | 4376 | Schematic: Flame Deflector (4411), Mekgineer Thermaplugg rare drop | 1 | 28,575 |
| 19 | 125 | Gnomish Universal Remote | 7506 | Schematic: Gnomish Universal Remote (7560), limited vendor stock and Mekgineer Thermaplugg drop | 1 | 28,575 |
| 20 | 125 | Small Blue Rocket | 21558 | Schematic: Small Blue Rocket (21724), Lunar Festival Small Rocket Recipes | 3 | 28,575 |
| 21 | 125 | Small Green Rocket | 21559 | Schematic: Small Green Rocket (21725), Lunar Festival Small Rocket Recipes | 3 | 28,575 |
| 22 | 125 | Small Red Rocket | 21557 | Schematic: Small Red Rocket (21726), Lunar Festival Small Rocket Recipes | 3 | 28,575 |
| 23 | 130 | Silver-plated Shotgun | 4379 | Engineering trainer | 1 | 30,755 |
| 24 | 135 | Ornate Spyglass | 5507 | Engineering trainer | 1 | 33,015 |
| 25 | 140 | Big Bronze Bomb | 4380 | Engineering trainer | 2–4 | 35,355 |
| 26 | 140 | Minor Recombobulator | 4381 | Schematic: Minor Recombobulator (14639), limited vendors; also historically obtainable through Gnomeregan Matrix Punchograph progression | 1 | 35,355 |
| 27 | 145 | Bronze Framework | 4382 | Engineering trainer | 1 | 37,775 |
| 28 | 145 | Moonsight Rifle | 4383 | Schematic: Moonsight Rifle (4412), rare/world drop | 1 | 37,775 |
| 29 | 150 | Explosive Sheep | 4384 | Engineering trainer | 1 | 40,275 |
| 30 | 150 | Green Tinted Goggles | 4385 | Engineering trainer | 1 | 40,275 |
| 31 | 150 | Gold Power Core | 10558 | Engineering trainer | 3 | 40,275 |
| 32 | 150 | Aquadynamic Fish Attractor | 6533 | Engineering trainer | 3 | 40,275 |
| 33 | 150 | Blue Firework | 9312 | Schematic: Blue Firework (18649), limited Alliance engineering-supplies vendors | 3 | 40,275 |
| 34 | 150 | Green Firework | 9313 | Schematic: Green Firework (18648), limited neutral engineering-supplies vendors | 3 | 40,275 |
| 35 | 150 | Red Firework | 9318 | Schematic: Red Firework (18647), limited Horde engineering-supplies vendors | 3 | 40,275 |

### Firework schematic provenance

For source-history purposes:

- Blue Firework: limited Alliance sale, including Gearcutter Cogspinner in Ironforge and Darian Singh in Stormwind.
- Green Firework: limited neutral sale, including Crazk Sparks in Booty Bay and Gagsprocket in Ratchet.
- Red Firework: limited Horde sale, including Nogg and Sovik in Orgrimmar.

These differences do not alter RPE learning; all three are trainer Recipes in RPE.

## Shared-material ownership

### Existing materials

All existing materials in the canonical-ref list above must be reused directly. They must not be duplicated in Engineering.

### Missing shared materials to add in #232

Four source reagents are genuinely absent from the current packaged data. They belong physically in `data/default/professions/misc.lua` under dataset `3eb7e9bb`.

| WoW ID | Name | Icon | Quality | Item level | Source requirements / stack | Planned owner |
| ---: | --- | --- | --- | ---: | --- | --- |
| 159 | Refreshing Spring Water | `interface/icons/inv_drink_07.blp` | common | 5 | Requires level 1; stack 20 | Misc |
| 814 | Flask of Oil | `interface/icons/inv_drink_07.blp` | common | 1 | Trade Goods/Parts; stack 20 | Misc |
| 4400 | Heavy Stock | `interface/icons/inv_mace_11.blp` | common | 25 | Trade Goods/Parts; stack 10 | Misc |
| 6530 | Nightcrawlers | `interface/icons/inv_misc_monstertail_03.blp` | common | 20 | Fishing 50 source-use requirement; +50 Fishing lure for 10 min; stack 20 | Misc |

For these Items, #232 must allocate new stable RPE IDs after collision-checking the current owners. The preparation document intentionally does not pre-assign random RPE IDs.

Nightcrawlers' fishing-lure source effect does not require a new generic use implementation merely to serve as a Recipe reagent.

## Engineering component normalization

The RPE crafting economy deliberately avoids requiring dependent Engineering Recipes to craft chains of Engineering-only components first. Source reagents remain recorded, but dependent RPE inputs use the normalized base materials below.

### Component mapping table

| Engineering component | Source identity | Normalized RPE material | RPE ref | Rule |
| --- | --- | --- | --- | --- |
| Rough Blasting Powder | prior slice | Rough Stone | `61fdf3df:c7urqe23` | carry-forward |
| Coarse Blasting Powder | prior slice | Coarse Stone | `61fdf3df:qcah9yrg` | carry-forward |
| Handful of Copper Bolts | prior slice | Copper Bar | `61fdf3df:nntycdj5` | carry-forward |
| Copper Tube | prior slice | Copper Bar | `61fdf3df:nntycdj5` | carry-forward |
| Copper Modulator | prior slice | Copper Bar | `61fdf3df:nntycdj5` | carry-forward |
| Silver Contact | this slice | Silver Bar | `61fdf3df:nvc1anz9` | 1 component unit -> 1 base-material unit |
| Bronze Tube | this slice | Bronze Bar | `61fdf3df:xegz4i5q` | 1:1 semantic flattening |
| Heavy Blasting Powder | this slice | Heavy Stone | `61fdf3df:u8qtuhfq` | 1:1 semantic flattening |
| Whirring Bronze Gizmo | this slice | Bronze Bar | `61fdf3df:xegz4i5q` | 1:1 semantic flattening |
| Bronze Framework | this slice | Bronze Bar | `61fdf3df:xegz4i5q` | 1:1 semantic flattening |
| Gold Power Core | this slice | Gold Bar | `61fdf3df:j6g2b8ye` | 1:1 semantic flattening |

The project convention is a semantic component-to-base substitution, not recursive multiplication by the component Recipe's own output yield. For example, a dependent Recipe requiring one Silver Contact consumes one Silver Bar in RPE even though the Silver Contact Recipe creates five contacts.

### Composite dependency: Flying Tiger Goggles

Green Tinted Goggles source reagents include one finished Flying Tiger Goggles. A finished equippable Item is not an RPE Recipe tool and should not be required as an intermediate dependency.

Flatten the consumed Flying Tiger Goggles to its source raw payload:

```text
Flying Tiger Goggles x1 -> Light Leather x6 + Tigerseye x2
```

Therefore Green Tinted Goggles uses:

```text
Medium Leather x4
Moss Agate x2
Light Leather x6
Tigerseye x2
Blacksmith Hammer x1 (tool)
```

### Small Flame Sac

Flame Deflector's source recipe uses one Small Flame Sac. The current packaged project deliberately removed the generic Small Flame Sac material and already uses Enchanting-owned Elemental Fire for this material role. Do not recreate Small Flame Sac.

Use:

```text
Small Flame Sac x1 -> Elemental Fire x1 (`732368d4:sclalidn`)
```

This is a project material-normalization decision, not a claim that the WoW items are identical.

## Detailed Recipe implementation plan

`Hammer` below means reusable `tool` input `61fdf3df:518sbr8g`. No other Recipe tool is permitted in this slice.

| # | Recipe | Source reagents | Normalized RPE inputs | Hammer | Output |
| ---: | --- | --- | --- | :---: | --- |
| 1 | Target Dummy | Copper Modulator 1; Handful of Copper Bolts 2; Bronze Bar 1; Wool Cloth 1 | Copper Bar 3; Bronze Bar 1; Wool Cloth 1 | Yes | Target Dummy 1 |
| 2 | Silver Contact | Silver Bar 1 | Silver Bar 1 | No | Silver Contact 5 |
| 3 | Practice Lock | Bronze Bar 1; Handful of Copper Bolts 2; Weak Flux 1 | Bronze Bar 1; Copper Bar 2; Weak Flux 1 | Yes | Practice Lock 1 |
| 4 | EZ-Thro Dynamite | Coarse Blasting Powder 4; Wool Cloth 1 | Coarse Stone 4; Wool Cloth 1 | No | EZ-Thro Dynamite 1–3 |
| 5 | Small Seaforium Charge | Coarse Blasting Powder 2; Copper Modulator 1; Light Leather 1; Refreshing Spring Water 1 | Coarse Stone 2; Copper Bar 1; Light Leather 1; Refreshing Spring Water 1 | No | Small Seaforium Charge 1 |
| 6 | Flying Tiger Goggles | Light Leather 6; Tigerseye 2 | Light Leather 6; Tigerseye 2 | Yes | Flying Tiger Goggles 1 |
| 7 | Bronze Tube | Bronze Bar 2; Weak Flux 1 | Bronze Bar 2; Weak Flux 1 | Yes | Bronze Tube 1 |
| 8 | Large Copper Bomb | Copper Bar 3; Coarse Blasting Powder 4; Silver Contact 1 | Copper Bar 3; Coarse Stone 4; Silver Bar 1 | Yes | Large Copper Bomb 2–4 |
| 9 | Deadly Blunderbuss | Copper Tube 2; Handful of Copper Bolts 4; Wooden Stock 1; Medium Leather 2 | Copper Bar 6; Wooden Stock 1; Medium Leather 2 | Yes | Deadly Blunderbuss 1 |
| 10 | Standard Scope | Bronze Tube 1; Moss Agate 1 | Bronze Bar 1; Moss Agate 1 | Yes | Standard Scope 1 |
| 11 | Small Bronze Bomb | Coarse Blasting Powder 4; Bronze Bar 2; Silver Contact 1; Wool Cloth 1 | Coarse Stone 4; Bronze Bar 2; Silver Bar 1; Wool Cloth 1 | Yes | Small Bronze Bomb 1–3 |
| 12 | Lovingly Crafted Boomstick | Bronze Tube 2; Handful of Copper Bolts 2; Heavy Stock 1; Moss Agate 3 | Bronze Bar 2; Copper Bar 2; Heavy Stock 1; Moss Agate 3 | Yes | Lovingly Crafted Boomstick 1 |
| 13 | Shadow Goggles | Medium Leather 4; Shadowgem 2 | Medium Leather 4; Shadowgem 2 | No | Shadow Goggles 1 |
| 14 | Heavy Blasting Powder | Heavy Stone 1 | Heavy Stone 1 | No | Heavy Blasting Powder 1 |
| 15 | Whirring Bronze Gizmo | Bronze Bar 2; Wool Cloth 1 | Bronze Bar 2; Wool Cloth 1 | Yes | Whirring Bronze Gizmo 1 |
| 16 | Crafted Solid Shot | Heavy Blasting Powder 1; Bronze Bar 1 | Heavy Stone 1; Bronze Bar 1 | No | Crafted Solid Shot 200 |
| 17 | Heavy Dynamite | Heavy Blasting Powder 2; Wool Cloth 1 | Heavy Stone 2; Wool Cloth 1 | No | Heavy Dynamite 1–5 |
| 18 | Flame Deflector | Whirring Bronze Gizmo 1; Small Flame Sac 1 | Bronze Bar 1; Elemental Fire 1 | Yes | Flame Deflector 1 |
| 19 | Gnomish Universal Remote | Bronze Bar 6; Whirring Bronze Gizmo 1; Flask of Oil 2; Tigerseye 1; Malachite 1 | Bronze Bar 7; Flask of Oil 2; Tigerseye 1; Malachite 1 | Yes | Gnomish Universal Remote 1 |
| 20 | Small Blue Rocket | Coarse Blasting Powder 1; Medium Leather 1 | Coarse Stone 1; Medium Leather 1 | No | Small Blue Rocket 3 |
| 21 | Small Green Rocket | Coarse Blasting Powder 1; Medium Leather 1 | Coarse Stone 1; Medium Leather 1 | No | Small Green Rocket 3 |
| 22 | Small Red Rocket | Coarse Blasting Powder 1; Medium Leather 1 | Coarse Stone 1; Medium Leather 1 | No | Small Red Rocket 3 |
| 23 | Silver-plated Shotgun | Bronze Tube 2; Whirring Bronze Gizmo 2; Heavy Stock 1; Silver Bar 3 | Bronze Bar 4; Heavy Stock 1; Silver Bar 3 | No | Silver-plated Shotgun 1 |
| 24 | Ornate Spyglass | Bronze Tube 2; Whirring Bronze Gizmo 2; Copper Modulator 1; Moss Agate 1 | Bronze Bar 4; Copper Bar 1; Moss Agate 1 | No | Ornate Spyglass 1 |
| 25 | Big Bronze Bomb | Heavy Blasting Powder 2; Bronze Bar 3; Silver Contact 1 | Heavy Stone 2; Bronze Bar 3; Silver Bar 1 | Yes | Big Bronze Bomb 2–4 |
| 26 | Minor Recombobulator | Bronze Tube 1; Whirring Bronze Gizmo 2; Medium Leather 2; Moss Agate 1 | Bronze Bar 3; Medium Leather 2; Moss Agate 1 | No | Minor Recombobulator 1 |
| 27 | Bronze Framework | Bronze Bar 2; Medium Leather 1; Wool Cloth 1 | Bronze Bar 2; Medium Leather 1; Wool Cloth 1 | No | Bronze Framework 1 |
| 28 | Moonsight Rifle | Bronze Tube 3; Whirring Bronze Gizmo 3; Heavy Stock 1; Lesser Moonstone 2 | Bronze Bar 6; Heavy Stock 1; Lesser Moonstone 2 | Yes | Moonsight Rifle 1 |
| 29 | Explosive Sheep | Bronze Framework 1; Whirring Bronze Gizmo 1; Heavy Blasting Powder 2; Wool Cloth 2 | Bronze Bar 2; Heavy Stone 2; Wool Cloth 2 | Yes | Explosive Sheep 1 |
| 30 | Green Tinted Goggles | Medium Leather 4; Moss Agate 2; Flying Tiger Goggles 1 | Medium Leather 4; Moss Agate 2; Light Leather 6; Tigerseye 2 | Yes | Green Tinted Goggles 1 |
| 31 | Gold Power Core | Gold Bar 1 | Gold Bar 1 | Yes | Gold Power Core 3 |
| 32 | Aquadynamic Fish Attractor | Bronze Bar 2; Nightcrawlers 1; Coarse Blasting Powder 1 | Bronze Bar 2; Nightcrawlers 1; Coarse Stone 1 | No | Aquadynamic Fish Attractor 3 |
| 33 | Blue Firework | Heavy Blasting Powder 1; Heavy Leather 1 | Heavy Stone 1; Heavy Leather 1 | No | Blue Firework 3 |
| 34 | Green Firework | Heavy Blasting Powder 1; Heavy Leather 1 | Heavy Stone 1; Heavy Leather 1 | No | Green Firework 3 |
| 35 | Red Firework | Heavy Blasting Powder 1; Heavy Leather 1 | Heavy Stone 1; Heavy Leather 1 | No | Red Firework 3 |

Where Classic source data lists Arclight Spanner alongside Blacksmith Hammer, the RPE plan deliberately reduces that tool set to Blacksmith Hammer only.

## Item inventory and RPE representation

All crafted outputs below are Engineering-owned Items in dataset `af503002`. Shared missing reagents are the four Misc Items identified above.

### Components and materials

| Item | WoW ID | Icon | Source metadata | RPE representation |
| --- | ---: | --- | --- | --- |
| Silver Contact | 4404 | `interface/icons/inv_ingot_04.blp` | common, ilvl 18, stack 20 | `material`, stackable |
| Bronze Tube | 4371 | `interface/icons/inv_gizmo_pipe_01.blp` | common, ilvl 21, stack 20 | `material`, stackable |
| Heavy Blasting Powder | 4377 | `interface/icons/classic_inv_misc_dust_06.blp` | common, ilvl 25, stack 20 | `material`, stackable |
| Whirring Bronze Gizmo | 4375 | `interface/icons/inv_gizmo_02.blp` | common, ilvl 25, stack 10 | `material`, stackable |
| Bronze Framework | 4382 | `interface/icons/inv_gizmo_bronzeframework_01.blp` | common, ilvl 29, stack 10 | `material`, stackable |
| Gold Power Core | 10558 | `interface/icons/inv_battery_02.blp` | common, ilvl 30, Trade Goods/Parts, stack 20 | `material`, stackable |

These component Items remain valid Recipe outputs even though dependent Recipes use normalized base materials rather than consuming them.

### Guns

All four guns use `itemType = "weapon"`, Ranged slot `f82db71a:q8ve6n6t`, Gun type `f82db71a:anoo8qfp`, Physical school `f82db71a:v1azo4j6`, bind-on-equip, one generic `mod` capacity, and the source level requirement.

| Item | WoW ID | Icon | ilvl / level | Source weapon data |
| --- | ---: | --- | --- | --- |
| Deadly Blunderbuss | 4369 | `interface/icons/inv_weapon_rifle_07.blp` | 21 / 16 | uncommon; 21–39 damage; speed 2.60; durability 50 |
| Lovingly Crafted Boomstick | 4372 | `interface/icons/inv_weapon_rifle_07.blp` | 24 / 19 | uncommon; Classic data reports 12–23 damage at speed 1.80; durability 55 |
| Silver-plated Shotgun | 4379 | `interface/icons/inv_weapon_rifle_07.blp` | 26 / 21 | uncommon; 27–50 damage; speed 2.70; durability 60 |
| Moonsight Rifle | 4383 | `interface/icons/inv_weapon_rifle_06.blp` | 29 / 24 | uncommon; 14–26 damage; speed 1.70; durability 65 |

Do not convert weapon damage into RAP; use the existing weapon min/max damage fields. Scope modifications apply separately.

### Goggles

| Item | WoW ID | Icon | Source metadata | RPE stats |
| --- | ---: | --- | --- | --- |
| Flying Tiger Goggles | 4368 | `interface/icons/inv_helmet_47.blp` | uncommon, ilvl20, BoE, Cloth Head, 27 Armor, Eng 100, +4 Sta, +4 Spirit, durability35 | Armor 27; Stamina 4; Spirit 4; Head slot; Engineering condition 100 |
| Shadow Goggles | 4373 | `interface/icons/inv_helmet_47.blp` | uncommon, ilvl24, BoE, Cloth Head, 31 Armor, Eng 120, +5 Int, +6 Spirit, durability40 | Armor 31; Intellect 5; Spirit 6; Head slot; Engineering condition 120 |
| Green Tinted Goggles | 4385 | `interface/icons/inv_helmet_47.blp` | uncommon, ilvl30, BoE, Cloth Head, 35 Armor, Eng 150, +8 Sta, +7 Spirit, durability45 | Armor 35; Stamina 8; Spirit 7; Head slot; Engineering condition 150 |

Use the established armor Item representation and one generic modification capacity where current equipment conventions require it.

### Ammo and scope

#### Crafted Solid Shot — item 8069

Source metadata:

- icon `interface/icons/inv_ammo_bullet_02.blp`;
- common;
- item level 35;
- requires level 30;
- Ammo/Bullet;
- source tooltip contribution: +8.5 damage per second;
- source stacks can exceed RPE's normal Item stack convention.

RPE representation follows the already-approved Crafted Light/Heavy Shot pattern:

```text
itemType: equippable armor/cosmetic abstraction
slot: Ammo `f82db71a:atsoi5vr`
Ranged Attack Power: +8.5 `f82db71a:v2rs9cpy`
maxStackSize: 200
Recipe output: 200
```

#### Standard Scope — item 4406

Source metadata:

- icon `interface/icons/inv_misc_spyglass_02.blp`;
- common;
- item level 22;
- requires level 10;
- stack 5;
- applies +2 ranged weapon damage.

RPE representation:

```text
itemType: modification
generic modification key: mod
target: Ranged slot
Ranged Attack Power: +2
```

This intentionally follows the Crude Scope precedent rather than inventing a new weapon-damage modification subsystem.

### Explosives

| Item | WoW ID | Icon | Source metadata / effect | RPE use behavior |
| --- | ---: | --- | --- | --- |
| EZ-Thro Dynamite | 6714 | `interface/icons/inv_misc_bomb_06.blp` | common, ilvl25, level10, stack20; 51–69 Fire in 5 yd; 1 min CD | Spell, midpoint 60 Fire, multi-target |
| Large Copper Bomb | 4370 | `interface/icons/inv_misc_bomb_01.blp` | common, ilvl26, Eng105, stack20; 43–57 Fire + 1 sec incapacitate in 5 yd; unreliable >36 | Spell, 50 Fire + 1-turn control Aura, multi-target |
| Small Bronze Bomb | 4374 | `interface/icons/inv_misc_bomb_09.blp` | common, ilvl29, Eng120, stack20; 73–97 Fire + 2 sec incapacitate in 3 yd; unreliable >39 | Spell, 85 Fire + 1-turn control Aura, multi-target |
| Heavy Dynamite | 4378 | `interface/icons/inv_misc_bomb_06.blp` | common, ilvl30, Eng125, stack20; 128–172 Fire in 5 yd | Spell, 150 Fire, multi-target |
| Big Bronze Bomb | 4380 | `interface/icons/inv_misc_bomb_05.blp` | common, ilvl33, Eng140, stack20; 85–115 Fire + 2 sec incapacitate in 5 yd; unreliable >44 | Spell, 100 Fire + 1-turn control Aura, multi-target |

The source higher-level unreliability rolls are deliberately omitted because the generic RPE Spell system does not have a target-level random-failure primitive. The Items/Spells are not blocked by that omission.

### Devices and utility Items

#### Target Dummy — item 4366

- icon `interface/icons/inv_crate_06.blp`;
- common, item level17, Engineering85, stack10;
- source use creates a temporary dummy that attracts nearby monsters for up to 15 seconds / until destroyed; 2 minute cooldown.

Author the Item and Recipe. Do **not** attach `summon_pet`: a pet is semantically wrong. Source-faithful use is blocked pending a generic temporary independently targetable/threat-generating unit/device capability.

#### Practice Lock — item 6712

- icon `interface/icons/inv_box_01.blp`;
- common, item level20;
- non-equippable, locked, source requirement Lockpicking 1.

Author as a utility/metadata Item with no `useSpellRef`. RPE has no lockpicking-practice interactable mechanic. This is a deliberate no-effect representation, not a Recipe blocker.

#### Small Seaforium Charge — item 4367

- icon `interface/icons/inv_misc_urn_01.blp`;
- common, item level20, Engineering100, stack10;
- source use blasts open simple locked doors/chests.

Author as a utility Item with no executable effect. RPE has no generic lock/open-world-object action. Do not fake this as damage.

#### Flame Deflector — item 4376

- icon `interface/icons/inv_gizmo_01.blp`;
- common, item level25, requires level15;
- source use absorbs 500 Fire damage for 1 minute;
- 15 minute cooldown;
- 5 charges.

Author the Item and Recipe. Do not attach an approximate Spell: current generic Item/Spell state cannot faithfully represent both source damage-absorption semantics and finite per-Item charges. See blocker section.

#### Gnomish Universal Remote — item 7506

- icon `interface/icons/inv_misc_pocketwatch_01.blp`;
- uncommon, item level25, BoE Trinket, Engineering125;
- source use attempts temporary control of a mechanical target, may fail by rooting/angering it;
- 3 minute cooldown.

Author the Trinket and Recipe without `useSpellRef`. Current generic mechanics do not express mechanical-only temporary control plus randomized failure/backfire outcomes.

#### Ornate Spyglass — item 5507

- icon `interface/icons/inv_misc_spyglass_01.blp`;
- common, item level27, non-stackable;
- source use changes camera zoom/view distance.

Author as metadata-only utility. Camera manipulation is outside RPE combat/item execution and does not justify a new generic gameplay mechanic.

#### Minor Recombobulator — item 4381

- icon `interface/icons/inv_gizmo_07.blp`;
- uncommon, item level28, Trinket, Engineering140;
- source has 10 charges;
- use restores 150–250 health and mana to a friendly target and attempts to remove Polymorph;
- reduced effectiveness against Polymorph from level31+ casters;
- 5 minute cooldown.

Author the Item/Recipe without an approximate use Spell. Although generic heal/resource/remove-aura primitives exist independently, source-faithful behavior requires finite per-Item charges, a Polymorph-category dispel rather than a hardcoded specific Aura ref, and level-dependent effectiveness. See blocker section.

#### Explosive Sheep — item 4384

- icon `interface/icons/spell_nature_polymorph.blp`;
- common, item level30, Engineering150, stack20;
- source creates an autonomous sheep that seeks an enemy and explodes for 135–165 damage; persists up to roughly 3 minutes; 1 minute cooldown.

Author Item/Recipe only. Do not collapse this into direct instant damage and do not use `summon_pet`; both would materially change the source behavior. Source-faithful use remains blocked by temporary autonomous device-unit behavior.

#### Aquadynamic Fish Attractor — item 6533

- icon `interface/icons/inv_misc_food_26.blp`;
- common, item level30, Trade Goods/Devices, stack20;
- source requires Fishing100 to use;
- source applies +100 Fishing to a fishing pole for 10 minutes;
- Recipe output3.

Author as a utility/metadata Item. The Core Fishing skill exists, but there is no generic temporary lure-to-fishing-pole attachment mechanic. Do not model it as permanent skill equipment.

### Fireworks and small rockets

Small rockets:

| Item | ID | Icon | Source metadata |
| --- | ---: | --- | --- |
| Small Blue Rocket | 21558 | `interface/icons/inv_misc_missilesmall_blue.blp` | common, ilvl1, stack20, requires firework launcher, output3 |
| Small Green Rocket | 21559 | `interface/icons/inv_misc_missilesmall_green.blp` | common, ilvl1, stack20, requires firework launcher, output3 |
| Small Red Rocket | 21557 | `interface/icons/inv_misc_missilesmall_red.blp` | common, ilvl1, stack20, requires firework launcher, output3 |

Full-size fireworks:

| Item | ID | Icon | Source metadata |
| --- | ---: | --- | --- |
| Blue Firework | 9312 | `interface/icons/spell_ice_magicdamage.blp` | common, ilvl20, stack5, 1 sec source cooldown, output3 |
| Green Firework | 9313 | `interface/icons/spell_nature_abolishmagic.blp` | common, ilvl20, stack5, 1 sec source cooldown, output3 |
| Red Firework | 9318 | `interface/icons/spell_fire_fireball02.blp` | common, ilvl20, stack5, 1 sec source cooldown, output3 |

All six are metadata-only Items in this slice. RPE currently has no firework launcher/world cosmetic projectile action. Do not invent combat damage for them.

## Spell and Aura design inventory for #231

Only source effects that map cleanly to the generic RPE Spell/Aura model should become executable Spells in #231.

### Explosive Spell conventions

For all five executable explosives:

```text
learnMode = "unavailable"
cast time = instant
ignoreGCD = true
triggersGCD = false
cooldown = 5 turns
cooldownGroup = "engineering_explosive"
```

The 5-turn cooldown follows the established RPE mapping used by the previous Engineering explosive slice for source 1-minute Engineering explosive cooldowns.

Use Fire school `f82db71a:esjguw6d` and the existing multi-target model. Default explosive targeting should select **1–5 enemy units**; use range 30 for thrown dynamite and range 20 for bombs, matching the previous slice's project convention rather than attempting geometric yard-radius execution.

| Spell | Item | Effect | Target plan |
| --- | --- | --- | --- |
| EZ-Thro Dynamite | 6714 | 60 flat Fire damage | multi 1–5 enemies, range30 |
| Large Copper Bomb | 4370 | 50 flat Fire damage, then incapacitation Aura | shared multi 1–5 enemy group, range20 |
| Small Bronze Bomb | 4374 | 85 flat Fire damage, then incapacitation Aura | shared multi 1–5 enemy group, range20 |
| Heavy Dynamite | 4378 | 150 flat Fire damage | multi 1–5 enemies, range30 |
| Big Bronze Bomb | 4380 | 100 flat Fire damage, then incapacitation Aura | shared multi 1–5 enemy group, range20 |

For each bomb, damage and Aura components must use the same casting group/target-selection policy so both effects apply to the same selected targets.

### Bomb incapacitation Aura

The three bombs may share one new supporting Aura for this slice if names/tooltips remain appropriate, or use equivalent separate Auras if dataset authoring conventions favor output-specific names. Behavior is:

```text
duration = 1 turn
preventCasting = true
movementRangeOverride = 0
cancelOnDamage = true
forceAutoHitAgainstTarget = false
maxStacks = 1
stackBehavior = refresh_duration
```

Unlike the previous preparation notes, `cancelOnDamage` is now backed by current runtime behavior and is not merely descriptive metadata.

### Item-based effects that are not Spells

- Standard Scope: Ranged modification, +2 RAP.
- Crafted Solid Shot: Ammo equipment, +8.5 RAP.
- Guns: ordinary weapon data.
- Goggles: ordinary equipment stats.

### Deliberate no-effect / blocked use representations

No `useSpellRef` should be authored for:

- Practice Lock;
- Small Seaforium Charge;
- Flame Deflector;
- Gnomish Universal Remote;
- Ornate Spyglass;
- Minor Recombobulator;
- Target Dummy;
- Explosive Sheep;
- Aquadynamic Fish Attractor;
- Small Blue/Green/Red Rocket;
- Blue/Green/Red Firework.

The reasons are documented in the Item section and blocker section. Absence of a use Spell is deliberate and must not be interpreted by #231/#232 as forgotten research.

## Generic limitation re-check

### `cancelOnDamage`

**Resolved in current runtime.** Damage handling can remove an Aura whose control effect declares `cancelOnDamage`. Bomb incapacitation can therefore rely on this field.

### Item-only shared cooldown groups

Still a generic caveat. Player cooldown metadata is built primarily from action-bar spell refs. Item-only unavailable Spells are individually cooldownable, but propagation to other Item-only Spells in `engineering_explosive` may not occur unless those Spells are discoverable in the player's cooldown metadata.

Do not expand #231 into generic cooldown architecture unless separately requested. Author the correct `cooldownGroup` data regardless.

### Item condition enforcement

Level/Engineering/Fishing conditions can be authored and surfaced in tooltips, but current use/equip/modification mutation paths do not uniformly enforce every condition. Author source requirements faithfully; do not remove them merely because enforcement is incomplete.

### Finite per-Item charges

No generic Item state currently supplies the finite source-charge behavior needed for Flame Deflector and Minor Recombobulator. Spell charges are not equivalent: they model reusable Spell recharge state, not depletion of a particular physical Item's charge count.

## Version and seasonal exclusions

The following were explicitly checked and excluded:

- every required-skill <=75 record, because the previous slice already owns those records;
- every required-skill >150 record;
- Mechanical Squirrel, by explicit project decision;
- **Shredder Autosalvage Unit (Engineering 135)** — this appears in some current Classic-Era aggregations but is Season of Discovery content and is not part of the vanilla Classic source set;
- TBC, Wrath, Anniversary, modern-retail and other later-era recipes;
- obsolete/beta-only records that are not part of vanilla Classic gameplay.

Modern database pages may show stat squishes, changed level requirements, later trainer availability, or post-Cataclysm acquisition changes. The implementation plan above uses source-era Classic identities/behavior and retains historical Classic vendor/drop provenance rather than modern acquisition changes.

## Source notes

The inventory was cross-checked against current Classic engineering recipe listings, individual Classic item/schematic records, and a public Classic item metadata dump. Individual source pages were used to resolve ambiguous vendor/drop provenance and seasonal contamination.

Especially relevant source identities include:

- WoW item IDs and Classic tooltips for the 35 crafted outputs;
- Schematic IDs 6716, 4409, 13309, 4410, 4411, 7560, 21724–21726, 14639, 4412 and 18647–18649;
- Classic limited-sale provenance for Lovingly Crafted Boomstick, Gnomish Universal Remote, Minor Recombobulator and the three full-size fireworks;
- Classic rare-drop provenance for EZ-Thro Dynamite, Small Seaforium Charge, Shadow Goggles, Flame Deflector and Moonsight Rifle;
- Lunar Festival provenance for the three Small Rocket schematics.

Where current sources disagree because of later expansion scaling, this document records the Classic representation selected for RPE and does not silently import modern values.

## Deterministic validation

Preparation validation checklist:

- [x] Exactly 35 valid vanilla Classic Engineering Recipes are listed for required skill `>75 and <=150`.
- [x] No skill-75 record from the prior slice is duplicated.
- [x] No required-skill >150 Recipe is included.
- [x] Season of Discovery Shredder Autosalvage Unit is explicitly excluded.
- [x] Mechanical Squirrel is not reintroduced.
- [x] Every Recipe has a historical source/acquisition classification and RPE `learnMode = "trainer"` decision.
- [x] Every Recipe has original source reagents and exact normalized RPE inputs.
- [x] Every Engineering-only intermediate has an explicit normalize/retain decision.
- [x] Every normalized existing input resolves to a current packaged canonical Item ref.
- [x] The four genuinely missing shared materials have an explicit canonical owner and complete source metadata.
- [x] No Engineering-crafted Item is planned as a reusable Recipe tool.
- [x] Every planned reusable tool is Blacksmith Hammer `61fdf3df:518sbr8g`.
- [x] Every crafted output has an Item identity and intended RPE representation.
- [x] AoE explosives use the supported multi-target Spell model.
- [x] Ammo and scope outputs use the established RAP representations.
- [x] Current `cancelOnDamage` support was re-checked and the stale blocker removed.
- [x] Unsupported utility effects are explicitly represented as deliberate metadata-only Items or genuine behavior blockers rather than fake mechanics.
- [x] #230 requires no implementation data/runtime changes beyond this preparation document.

## Incomplete / Blocked Items and Recipes

**Recipe and Item data preparation: None.** All 35 Recipes have sufficient identity, source reagent, normalization, ownership, output and metadata decisions for #231–#233.

The following **source-faithful Item use behaviors** remain blocked by generic capabilities. Their Items and Recipes are still fully authorable:

1. **Target Dummy** — requires a temporary independently targetable/threat-generating summoned device unit. `summon_pet` is not semantically correct.
2. **Flame Deflector** — requires source-faithful Fire-damage absorption/shield behavior plus finite per-Item charges.
3. **Gnomish Universal Remote** — requires mechanical-only temporary control with source failure/backfire outcomes.
4. **Minor Recombobulator** — requires finite per-Item charges plus Polymorph-category dispel and level-dependent effectiveness; approximating it with a single hardcoded Aura removal would be incorrect.
5. **Explosive Sheep** — requires a temporary autonomous device unit that seeks a target and explodes on contact/delay. Direct instant damage or `summon_pet` would materially change the source behavior.

The following effects are **deliberately simplified to metadata-only Items**, not unresolved Recipe blockers:

- Practice Lock — no lockpicking-practice interactable mechanic;
- Small Seaforium Charge — no generic locked-world-object opening mechanic;
- Ornate Spyglass — camera zoom is outside RPE gameplay execution;
- Aquadynamic Fish Attractor — no temporary lure-to-fishing-pole attachment mechanic;
- Small Blue/Green/Red Rocket — no firework-launcher/world cosmetic projectile mechanic;
- Blue/Green/Red Firework — no world cosmetic firework-launch action.

The remaining generic caveats are the Item-only shared cooldown-group propagation path and non-uniform Item condition enforcement. They do not block authoring the prepared data.