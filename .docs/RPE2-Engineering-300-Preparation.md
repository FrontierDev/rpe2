# RPE2 Classic Engineering 300 Preparation

## Purpose and authority

This document is the implementation source of truth for the final **vanilla Classic Engineering recipes requiring exactly 300 Engineering skill**.

```text
required Engineering skill == 300
```

The selected output scope is:

- bombs and grenades;
- armour and wearable equipment;
- trinkets;
- weapons;
- potion-like consumables;
- **modifications**, including Engineering scopes.

Classic Wowhead is authoritative for Classic recipe/item identity, source reagents, item metadata and active effects. Current RPE2 `dev` is authoritative for schema, packaged material ownership, runtime representability, existing item/modification/spell abstractions and trainer-cost rules.

Primary source:

```text
https://www.wowhead.com/classic/guide/engineering-leveling-1-300-wow-classic
```

## Scope result

The selected exact-300 inventory contains **8 outputs**:

1. Arcane Bomb
2. Ultra-Flash Shadow Reflector
3. Core Marksman Rifle
4. Force Reactive Disk
5. Bloodvine Goggles
6. Bloodvine Lens
7. Flawless Arcanite Rifle
8. Biznicks 247x128 Accurascope

The following exact-300 recipes remain excluded:

| Output | Reason |
| --- | --- |
| Field Repair Bot 74A | Standalone utility device |
| Any ammo/component/reagent output | Outside selected final-output scope |

Do not interpret this document as admitting TBC Engineering recipes that also start at 300. The boundary is **vanilla Classic recipes whose Classic recipe itself requires 300**.

## Current RPE implementation rules

- Engineering dataset: `af503002`.
- Engineering packaged version after item implementation: `21`.
- Engineering skill: `f82db71a:xprqs3y1`.
- Every eventual Recipe uses `learnMode = "trainer"`; original drop/vendor/reputation acquisition remains provenance only.
- Trainer cost at skill 300 uses the current RPE formula and is `152475` copper.
- Recursively flatten every Engineering intermediate to existing packaged external material leaves.
- Stop expansion at an existing canonical material Item owned by another packaged dataset.
- Aggregate duplicate leaves after expansion.
- Preserve source output batch quantities exactly.
- Do not create missing shared/raw materials merely to make a recipe resolve. Report the recipe blocked instead.
- Blacksmith Hammer `61fdf3df:518sbr8g` remains the only supported reusable Engineering Recipe tool.
- Ignore Arclight Spanner and Gyromatic Micro-Adjustor as RPE `tool` inputs under the established Engineering rule.
- An Engineering-finished item used as a higher-tier source ingredient must be flattened through its canonical implemented RPE recipe.
- Item-use spells use `Item.useSpellRef -> Spell`; do not add bespoke item runtime code.
- Engineering scopes use the existing generic modification system, not an item-use Spell.

## Trainer cost

Current RPE formula:

```text
floor(75 + requiredSkillLevel * 28 + requiredSkillLevel^2 * 1.6)
```

At skill 300:

```text
floor(75 + 300*28 + 300^2*1.6) = 152475 copper
```

## Existing material ownership relevant to this tier

Current `dev` confirms these relevant external packaged materials exist:

```text
Arcanite Bar             Blacksmithing
Dark Iron Bar            Blacksmithing
Thorium Bar              Blacksmithing
Truesilver Bar           Blacksmithing
Gold Bar                 Blacksmithing
Runecloth                Tailoring
Azerothian Diamond       Jewelcrafting
Large Opal               Jewelcrafting
Star Ruby                Jewelcrafting
Souldarite               Jewelcrafting
Enchanted Thorium Bar    Enchanting
Enchanted Leather        Enchanting
Elemental Earth          Enchanting
Elemental Air            Enchanting
Living Essence           Enchanting
Essence of Undeath       Enchanting
Essence of Fire          Enchanting
Essence of Earth         Enchanting
Bloodvine                Misc
Fiery Core               Misc
Lava Core                Misc
```

Known qualified refs already established by current Engineering work include:

```text
Blacksmith Hammer        61fdf3df:518sbr8g
Dark Iron Bar            61fdf3df:pb24e7k5
Thorium Bar              61fdf3df:5m4zt99z
Truesilver Bar           61fdf3df:ufv4fdnf
Gold Bar                 61fdf3df:hqook9xe
Runecloth                7259f1d3:dx7zh3l2
Azerothian Diamond       4999dcec:atpvfzht
Large Opal               4999dcec:pkgfp4sl
Star Ruby                4999dcec:mr1cbt76
Elemental Earth          732368d4:ku9j8vhw
Elemental Air            732368d4:2616xh4v
Essence of Undeath       732368d4:xtnbjwzj
Enchanted Leather        732368d4:x5hz6tby
Bloodvine                3eb7e9bb:8eummju4
Fiery Core               3eb7e9bb:e0tarf0p
Lava Core                3eb7e9bb:g3ytywfw
```

**Arcanite Bar is confirmed present in the Blacksmithing dataset and is not a blocker.** Implementation should resolve its current qualified ref directly from live `dev`, just as with Souldarite, Enchanted Thorium Bar, Living Essence, Essence of Fire and Essence of Earth.

## Missing material blockers on current `dev`

The remaining unresolved required leaves are:

- `Ironweb Spider Silk`;
- `Powerful Mojo`.

Do not silently substitute them. Recipes depending on them remain blocked until the canonical material exists or the user gives an explicit substitution rule.

## Component expansion rules

| Engineering intermediate | External-leaf expansion |
| --- | --- |
| Delicate Arcanite Converter x1 | Arcanite Bar x1; Ironweb Spider Silk x1 |
| Thorium Widget x1 | Thorium Bar x3; Runecloth x1 |
| Thorium Tube x1 | Thorium Bar x6 |
| Truesilver Transformer x1 | Truesilver Bar x2; Elemental Earth x2; Elemental Air x1 |
| Gold Power Core x1 | Gold Bar x1 |


## Included inventory and representation status

| Skill | Output | WoW item ID | Category | Classic source | RPE status |
| ---: | --- | ---: | --- | --- | --- |
| 300 | Arcane Bomb | 16040 | Bomb | World-drop schematic | Item + use effect implemented; Recipe blocked only by Ironweb Spider Silk |
| 300 | Ultra-Flash Shadow Reflector | 18639 | Trinket | Stratholme schematic drop | Item + resistance abstraction implemented; Recipe material-complete |
| 300 | Core Marksman Rifle | 18282 | Weapon | Molten Core schematic | Item implemented; Recipe blocked only by Ironweb Spider Silk |
| 300 | Force Reactive Disk | 18168 | Armour/shield | Molten Core schematic | Base item implemented; source block value and block-triggered proc omitted for now; Recipe blocked only by Ironweb Spider Silk |
| 300 | Bloodvine Goggles | 19999 | Armour/head | Zandalar Tribe Honored schematic | Item implemented; 9 mana/5 sec is represented as +9 Spirit; Recipe blocked by Ironweb Spider Silk + Powerful Mojo |
| 300 | Bloodvine Lens | 19998 | Armour/head | Zandalar Tribe Friendly schematic | Item implemented except stealth detection; Recipe blocked by Ironweb Spider Silk + Powerful Mojo |
| 300 | Flawless Arcanite Rifle | 16007 | Weapon | World-drop schematic | Item implemented with canonical +4 Guns skill bonus; Recipe material-complete |
| 300 | Biznicks 247x128 Accurascope | 18283 | Modification/scope | Molten Core schematic | Modification implemented as +3% ranged hit on the Ranged slot; Recipe blocked only by Ironweb Spider Silk |

## Item and effect details

### Arcane Bomb

Classic sources:

```text
https://www.wowhead.com/classic/item=16055/schematic-arcane-bomb
https://www.wowhead.com/classic/item=16040/arcane-bomb
```

Source behavior: output x3; drains 675–1125 mana, deals damage equal to 50% of mana actually drained, silences for 5 seconds, 1-minute cooldown.

RPE decision: omit the source damage component. Implement the use effect as a flat 900 mana drain (the midpoint of the Classic 675-1125 range) plus a 1-turn silence, using the existing resource and control-Aura components. The spell uses the normal Engineering explosive multi-target pattern and a 1-turn cooldown abstraction.


### Ultra-Flash Shadow Reflector

Classic sources:

```text
https://www.wowhead.com/classic/item=18658/schematic-ultra-flash-shadow-reflector
https://www.wowhead.com/classic/item=18639/ultra-flash-shadow-reflector
```

Item Level 60, BoE Trinket, +20 Shadow Resistance, level 55, Engineering 300, 5-second Shadow reflection, 5-minute cooldown.

RPE decision: mirror the existing frost/fire reflector abstraction. Preserve +20 Shadow Resistance; item-use Spell applies a 3-turn self Aura granting +50 Shadow Resistance, 5-turn cooldown, unavailable learning, no GCD. Literal reflection remains unsupported.

### Core Marksman Rifle

Classic sources:

```text
https://www.wowhead.com/classic/item=18292/schematic-core-marksman-rifle
https://www.wowhead.com/classic/item=18282/core-marksman-rifle
```

Item Level 65; BoE gun; 64–120 damage; speed 2.50; level 60; +22 ranged Attack Power; +1% hit.

RPE decision: normal ranged gun using existing weapon/stat systems.

### Force Reactive Disk

Classic sources:

```text
https://www.wowhead.com/classic/item=18291/schematic-force-reactive-disk
https://www.wowhead.com/classic/item=18168/force-reactive-disk
```

Item Level 65; BoE Shield; 2548 Armor; 44 Block; +11 Stamina; level 60; damages nearby enemies on successful block.

RPE decision: implement the base shield metadata and omit the successful-block damage proc for now. Do not approximate it with broader damage-taken events. Durability self-damage is also omitted.

### Bloodvine Goggles

Classic sources:

```text
https://www.wowhead.com/classic/item=20000/schematic-bloodvine-goggles
https://www.wowhead.com/classic/item=19999/bloodvine-goggles
```

Item Level 65; BoE Cloth Head; 75 Armor; level 60; +2% spell hit; +1% spell crit; 9 mana/5 sec.

RPE decision: armour/hit/crit use existing stats. Under the Engineering conversion rule, 9 mana per 5 sec is represented as +9 Spirit (`f82db71a:kec9rhli`).

### Bloodvine Lens

Classic sources:

```text
https://www.wowhead.com/classic/item=20001/schematic-bloodvine-lens
https://www.wowhead.com/classic/item=19998/bloodvine-lens
```

Item Level 65; BoE Leather Head; 147 Armor; +12 Stamina; level 60; +2% crit; increased stealth detection.

RPE decision: armour/Stamina/crit are representable. Stealth detection remains unsupported unless a canonical Core stat exists for it.

### Flawless Arcanite Rifle

Classic sources:

```text
https://www.wowhead.com/classic/item=16056/schematic-flawless-arcanite-rifle
https://www.wowhead.com/classic/item=16007/flawless-arcanite-rifle
```

Item Level 61; BoE gun; 65–122 damage; speed 3.00; level 56; +4 Guns; +10 ranged Attack Power.

RPE decision: normal ranged gun. Use `skillBonuses` for +4 Guns only if a canonical Guns skill exists; do not translate it to generic hit.

### Biznicks 247x128 Accurascope

Classic sources:

```text
https://www.wowhead.com/classic/item=18290/schematic-biznicks-247x128-accurascope
https://www.wowhead.com/classic/spell=22793/biznicks-247x128-accurascope
```

Classic metadata:

- Engineering 300;
- crafted item ID `18283`;
- Item Level 60;
- requires level 50;
- stack size 5;
- permanently attaches to a bow or gun;
- increases that ranged weapon's chance to hit by **3%**;
- Classic 1.12 behavior is ranged-only.

RPE representation decision:

- represent as `itemType = "modification"`;
- `modificationKind = "generic"` unless a more specific current generic scope key already exists;
- modification stats grant +3% ranged hit using the canonical ranged-hit stat;
- constrain application through the existing modification targeting fields (`targetSlotRefs` / `targetWeaponTypeRef`) so it applies to bow/gun ranged weapons only;
- do not implement it as `useSpellRef`;
- if current modification targeting can only express one weapon type per item and cannot express both bow and gun, that targeting limitation must be resolved generically rather than broadening the modification to all ranged equipment.

## Final normalized recipe BOM

`Hammer` means Blacksmith Hammer `61fdf3df:518sbr8g` as a non-consumed tool.

| Skill | Output | Final normalized external inputs | Output qty | Material status |
| ---: | --- | --- | ---: | --- |
| 300 | Arcane Bomb | Arcanite Bar x1; Ironweb Spider Silk x1; Thorium Bar x3; Runecloth x1; Hammer | 3 | **Blocked:** Ironweb Spider Silk |
| 300 | Ultra-Flash Shadow Reflector | Dark Iron Bar x8; Truesilver Bar x8; Elemental Earth x8; Elemental Air x4; Living Essence x6; Essence of Undeath x4; Azerothian Diamond x2; Large Opal x2; Hammer | 1 | **Complete** |
| 300 | Core Marksman Rifle | Fiery Core x4; Lava Core x2; Arcanite Bar x8; Ironweb Spider Silk x2; Thorium Bar x12; Hammer | 1 | **Blocked:** Ironweb Spider Silk |
| 300 | Force Reactive Disk | Arcanite Bar x8; Ironweb Spider Silk x2; Essence of Air x8; Living Essence x12; Essence of Earth x8; Hammer | 1 | **Blocked:** Ironweb Spider Silk |
| 300 | Bloodvine Goggles | Bloodvine x4; Souldarite x5; Arcanite Bar x2; Ironweb Spider Silk x2; Powerful Mojo x8; Enchanted Leather x4 | 1 | **Blocked:** Ironweb Spider Silk, Powerful Mojo |
| 300 | Bloodvine Lens | Bloodvine x5; Souldarite x5; Arcanite Bar x1; Ironweb Spider Silk x1; Powerful Mojo x8; Enchanted Leather x4 | 1 | **Blocked:** Ironweb Spider Silk, Powerful Mojo |
| 300 | Flawless Arcanite Rifle | Arcanite Bar x10; Thorium Bar x12; Essence of Fire x2; Essence of Earth x2; Azerothian Diamond x2; Enchanted Leather x2; Hammer | 1 | **Complete** |
| 300 | Biznicks 247x128 Accurascope | Lava Core x2; Essence of Earth x2; Arcanite Bar x4; Ironweb Spider Silk x4; Dark Iron Bar x6; Thorium Bar x6; Hammer | 1 | **Blocked:** Ironweb Spider Silk |

### Tool provenance

Source Blacksmith Hammer requirements are retained. Arclight Spanner and Gyromatic Micro-Adjustor are omitted as RPE tool inputs under the established rule. Bloodvine Goggles/Lens therefore have no RPE tool input because their source recipes do not require the Hammer.

## Incomplete / Blocked Items and Recipes

| Entry | Complete | Missing / blocker | Type | Smallest follow-up |
| --- | --- | --- | --- | --- |
| Arcane Bomb | Item + simplified use effect + BOM | Ironweb Spider Silk | Material | Add/substitute silk |
| Ultra-Flash Shadow Reflector | Item + Spell/Aura abstraction + BOM | None | None | Ready |
| Core Marksman Rifle | Item + BOM | Ironweb Spider Silk | Material | Add/substitute silk |
| Force Reactive Disk | Base item + BOM | Ironweb Spider Silk; 44 block-value stat and successful-block proc omitted | Material + unsupported stat/event | Add/substitute silk; optionally add generic block-value/event support later |
| Bloodvine Goggles | Item + BOM | Ironweb Spider Silk; Powerful Mojo | Material | Add/substitute leaves |
| Bloodvine Lens | Item + BOM | Ironweb Spider Silk; Powerful Mojo; stealth detection omitted | Material + unsupported passive | Add/substitute leaves; optionally add stealth-detection support later unless supported |
| Flawless Arcanite Rifle | Item metadata, material-complete BOM | Verify canonical Guns skill | Possible skill ref | Resolve Guns skill or omit only that bonus |
| Biznicks 247x128 Accurascope | Modification metadata/effect, BOM | Ironweb Spider Silk; verify bow+gun targeting can be expressed without broadening | Material + modification targeting | Add/substitute silk; use/extend generic modification targeting if necessary |

## Implementation sequencing

When implementation is requested:

1. **Spell/Aura support** — Ultra-Flash Shadow Reflector and only newly approved generic support for blocked mechanics.
2. **Items/modifications** — author all source items plus Biznicks as a generic modification; unsupported behavior must not be falsely represented.
3. **Recipes** — implement every recipe whose final external leaves resolve at implementation time.

Do not add Engineering component Items/Recipes as a shortcut.

## Validation checklist

Verify before closing implementation work:

- all selected recipes require exactly 300 Engineering;
- all Recipes use `learnMode = "trainer"`;
- trainer cost is `152475` unless the live formula changes;
- Arcanite Bar resolves from Blacksmithing and is never reported as missing;
- every consumed input is an external packaged material or Blacksmith Hammer;
- no Engineering intermediate survives recursive flattening;
- Arclight Spanner/Gyromatic Micro-Adjustor are not RPE tool inputs;
- output quantities match Classic source data, including Arcane Bomb x3;
- Biznicks is an Item modification, not a use Spell, and provides +3% ranged hit only to valid bow/gun targets;
- Ultra-Flash Shadow Reflector uses the established reflector abstraction;
- blocked mechanics are not approximated silently;
- no TBC Engineering 300+ recipes are introduced;
- IDs/names are unique and dataset versioning remains monotonic;
- final implementation reports any remaining blocked entries explicitly.
