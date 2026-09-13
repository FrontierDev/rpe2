# RPE2 Engineering 225–295 Preparation

## Purpose and authority

This document is the implementation source of truth for Issue #277 and the subsequent Engineering 225–295 Spell, Item, and Recipe issues (#278–#280).

The exact recipe-skill boundary is:

```text
required Engineering skill > 225 and <= 295
```

The selected output scope is deliberately narrow. Implement only:

- bombs and grenades;
- armour and other wearable equipment;
- trinkets;
- weapons;
- potion-like consumables.

There are no potion-like Engineering consumables in this band.

High-Powered Flashlight is an explicit user-directed exception to the vanilla-only source rule. Its inclusion does not authorize any other post-vanilla Engineering recipe.

Source truth for this preparation is Classic Wowhead for Engineering/item/recipe identity and the current RPE2 `dev` branch for canonical dataset ownership, schema, runtime representation, trainer costs, and existing refs.

## Current RPE rules

- Engineering dataset: `af503002`.
- Engineering skill: `f82db71a:xprqs3y1`.
- Engineering packaged version at preparation time: `13`.
- All implementation-stage recipes use `learnMode = "trainer"`, regardless of their original trainer/vendor/drop/specialization acquisition.
- Original acquisition remains provenance only.
- Every Engineering intermediary is recursively expanded until consumed inputs are external packaged materials or the supported reusable tool.
- Component recipe output quantities are respected. If a component recipe makes multiple items, craft enough whole batches to satisfy the final recipe; do not use fractional source batches.
- Duplicate leaves are aggregated after expansion.
- No Engineering intermediate may remain in a final normalized input list.
- No new raw/shared material may be added merely to unblock this band. Recipes whose leaves are absent remain blocked.
- Blacksmith Hammer `61fdf3df:518sbr8g` is the only reusable Engineering recipe tool that may appear where the source recipe requires a reusable tool. Do not use Arclight Spanner or Gyromatic Micro-Adjustor as Recipe `tool` inputs.
- Active item behavior uses `Item.useSpellRef -> Spell -> components/Auras`; do not introduce Engineering-specific runtime behavior.
- Inventory-use items must be `itemType = "consumable"`; equipped on-use items must be represented as `itemType = "armor"` or `itemType = "weapon"` because `client/client_ItemUse.lua` only accepts those equipped types.
- Therefore Classic trinkets are represented as `itemType = "armor"`, `armorWeight = "cosmetic"`, with Core Trinket slot `f82db71a:139phg06`.
- Neck wearables use Core Neck slot `f82db71a:ujxndj4q`.
- Guns use Core Ranged slot `f82db71a:q8ve6n6t`, Gun type `f82db71a:anoo8qfp`, Physical school `f82db71a:v1azo4j6`, and the existing generic modification-slot convention.
- Bombs/grenades use the established generic Engineering explosive model: 20-yard multi-target hostile targeting, 1–5 targets, `engineering_explosive` cooldown group, no GCD, and a one-turn break-on-damage control Aura where the Classic source stuns/incapacitates.

## Current canonical refs

```text
Core                     f82db71a
Blacksmithing            61fdf3df
Tailoring                7259f1d3
Leatherworking           538a54a0
Jewelcrafting            4999dcec
Enchanting               732368d4
Alchemy                  d6ffc4e2
Misc                     3eb7e9bb

Engineering skill        f82db71a:xprqs3y1
Head slot                f82db71a:bgvs1zx6
Neck slot                f82db71a:ujxndj4q
Trinket slot             f82db71a:139phg06
Ranged slot              f82db71a:q8ve6n6t
Main Hand slot           f82db71a:d212x0h1
Off Hand slot            f82db71a:l1hvib8g
Gun weapon type          f82db71a:anoo8qfp
Physical school          f82db71a:v1azo4j6
Fire school              f82db71a:esjguw6d
Frost school             f82db71a:hx7pnwv4
Nature school            f82db71a:qtr10qyj
Shadow school            f82db71a:1ggt4t3v

Solid Stone              61fdf3df:o1ogtdcq
Mithril Bar              61fdf3df:i5m1b7xd
Truesilver Bar           61fdf3df:k7t3b9zf
Gold Bar                 61fdf3df:j6g2b8ye
Blacksmith Hammer        61fdf3df:518sbr8g
Thick Leather            538a54a0:u0wy9jz1
Heavy Leather            538a54a0:55k8gjup
Aquamarine               4999dcec:5nrqhg0t
Citrine                  4999dcec:ht59o8mx
Star Ruby                4999dcec:mr1cbt76
Elemental Fire           732368d4:sclalidn
Essence of Undeath       732368d4:xtnbjwzj
Essence of Fire          732368d4:50qj8dzw
Essence of Earth         732368d4:tfwg197j
Essence of Air           732368d4:fiea7e66
Living Essence           732368d4:lxqnh3pp
Elemental Earth          732368d4:ku9j8vhw
Elemental Air            732368d4:2616xh4v
Enchanted Leather        732368d4:x5hz6tby
Frost Oil                d6ffc4e2:p9f4o8ek
Goblin Rocket Fuel       d6ffc4e2:q1g5m9fl
```

For advanced packaged leaves not listed above (Thorium Bar, Dark Iron Bar, Arcanite Bar, Dense Stone, Runecloth, Rugged Leather, Jade, Blue Sapphire, Large Opal, Azerothian Diamond, Huge Emerald, Moss Agate, Tigerseye, Malachite, Heart of the Wild, Wildvine, Icecap), #280 must use the existing item from its current owner dataset and must not create an Engineering-local duplicate. The owner datasets are already packaged on `dev`; the implementation must resolve the exact current qualified ref before authoring each input.

### Explicit material substitutions

These substitutions are authoritative for this band:

- `Ichor of Undeath` -> existing `Essence of Undeath` `732368d4:xtnbjwzj`.
- `Heart of Fire` -> existing `Elemental Fire` `732368d4:sclalidn`.
- Solid Stone is already packaged in Blacksmithing as `61fdf3df:o1ogtdcq`; it is not a blocker.

## Recursive component expansion rules

Use the following source component recipes when normalizing the selected final recipes. These are expansion rules, not Engineering inputs to preserve.

| Engineering component | Source component recipe / yield | Flattening consequence |
| --- | --- | --- |
| Solid Blasting Powder | Solid Stone x2 -> 1 | each powder = Solid Stone x2 |
| Dense Blasting Powder | Dense Stone x2 -> 1 | each powder = Dense Stone x2 |
| Mithril Casing | Mithril Bar x3 -> 1 | each casing = Mithril Bar x3 |
| Mithril Tube | Mithril Bar x3 -> 1 | each tube = Mithril Bar x3 |
| Unstable Trigger | Mithril Bar x1; Mageweave Cloth x1; Solid Blasting Powder x1 -> 1 | Mithril Bar x1; Mageweave Cloth x1; Solid Stone x2 |
| Gold Power Core | Gold Bar x1 -> 1 | Gold Bar x1 |
| Thorium Widget | Thorium Bar x3; Runecloth x1 -> 1 | Thorium Bar x3; Runecloth x1 |
| Thorium Tube | Thorium Bar x6 -> 1 | Thorium Bar x6 |
| Truesilver Transformer | Truesilver Bar x2; Elemental Earth x2; Elemental Air x1 -> 1 | same leaves |
| Inlaid Mithril Cylinder | Mithril Bar x5; Gold Bar x1; Truesilver Bar x1 -> 4 | one source batch covers requirements of 1–4 cylinders |
| Deadly Scope | Mithril Tube x1; Aquamarine x2; Thick Leather x2 -> 1 | Mithril Bar x3; Aquamarine x2; Thick Leather x2 |
| Delicate Arcanite Converter | Arcanite Bar x1; Ironweb Spider Silk x1 -> 1 | blocked wherever used because Ironweb Spider Silk is not currently packaged |

Finished Engineering outputs used as source ingredients are also recursively expanded for this issue. Do not preserve Fire Goggles, Green Tinted Goggles, Spellpower Goggles Xtreme, Goblin Construction Helmet, The Big One, or other Engineering outputs as recipe inputs.

## Trainer cost formula

Current `client/client_Crafting.lua` calculates:

```text
floor(75 + requiredSkillLevel * 28 + requiredSkillLevel^2 * 1.6)
```

| Skill | Trainer cost (copper) |
| ---: | ---: |
| 230 | 91,155 |
| 235 | 95,015 |
| 240 | 98,955 |
| 245 | 102,975 |
| 250 | 107,075 |
| 260 | 115,515 |
| 265 | 119,855 |
| 270 | 124,275 |
| 275 | 128,775 |
| 285 | 138,015 |
| 290 | 142,755 |

## Included inventory

The authoritative selected inventory is **25 outputs**.

| Skill | Output | WoW item ID | Category | Original source | Implementation status |
| ---: | --- | ---: | --- | --- | --- |
| 230 | Gnomish Battle Chicken | 10725 | Trinket | Gnomish Engineering | Item/recipe; active summon blocked |
| 230 | Goblin Bomb Dispenser | 10587 | Trinket | Goblin Engineering | Item/recipe; active summon blocked |
| 230 | Deepdive Helmet | 10506 | Armour | Schematic | Item/recipe; underwater-breathing passive has no combat analogue |
| 230 | Rose Colored Goggles | 10503 | Armour | Trainer | Full passive item/recipe |
| 235 | Gnomish Mind Control Cap | 10726 | Armour | Gnomish Engineering | Item/recipe; mind control blocked |
| 235 | Hi-Explosive Bomb | 10562 | Bomb | Trainer | Full item/spell/recipe |
| 240 | Gnomish Death Ray | 10645 | Trinket | Gnomish Engineering | Item/recipe; exact charge/self-damage behavior blocked |
| 240 | Goblin Dragon Gun | 10727 | Trinket | Goblin Engineering | Item/recipe; exact cone/backfire behavior blocked |
| 245 | Green Lens | 10504 | Armour | Trainer | Base item/recipe; random enchantment blocked |
| 245 | Goblin Rocket Helmet | 10588 | Armour | Goblin Engineering | Item/recipe; exact charge/self-stun blocked |
| 250 | Mithril Mechanical Dragonling | 10576 | Trinket | Schematic/vendor | Item/recipe; summon requires unit dependency |
| 250 | High-Powered Flashlight | 45631 | Trinket | Explicit user-directed later recipe | Include; later-source exception only |
| 260 | Gyrofreeze Ice Reflector | 18634 | Trinket | Schematic | Full item/recipe with established resistance abstraction |
| 260 | Dimensional Ripper - Everlook | 18984 | Trinket | Goblin Engineering | Item/recipe; teleport blocked |
| 260 | Ultrasafe Transporter: Gadgetzan | 18986 | Trinket | Gnomish Engineering | Recipe blocked by missing leaves; teleport also blocked |
| 260 | Thorium Grenade | 15993 | Grenade | Trainer | Full item/spell/recipe |
| 260 | Thorium Rifle | 15995 | Weapon | Schematic | Full item/recipe |
| 265 | Goblin Jumper Cables XL | 18587 | Trinket | Schematic | Recipe blocked by missing leaves; resurrection/chance behavior blocked |
| 270 | Spellpower Goggles Xtreme Plus | 15999 | Armour | Schematic | Full passive item/recipe |
| 275 | Major Recombobulator | 18637 | Trinket | Schematic | Heal/resource use representable; generic polymorph dispel blocked |
| 275 | Dark Iron Rifle | 16004 | Weapon | Schematic | Item/recipe; passive proc via generic equipment trait if current trait path supports it |
| 285 | Dark Iron Bomb | 16005 | Bomb | Schematic | Full item/spell/recipe |
| 290 | Hyper-Radiant Flame Reflector | 18638 | Trinket | Schematic | Full item/recipe with established resistance abstraction |
| 290 | Master Engineer's Goggles | 16008 | Armour | Trainer | Full passive item/recipe after recursive goggles expansion |
| 290 | Voice Amplification Modulator | 16009 | Neck armour | Schematic | Recipe blocked by missing Ironweb Spider Silk; silence-resistance passive blocked |

## Explicit exclusions

The following are deliberately not selected even when their source recipe falls in `(225,295]`:

| Output/category | Reason |
| --- | --- |
| Dense Dynamite | Dynamite is excluded; scope is specifically bombs/grenades |
| The Big One | Rocket/explosive but not classified as bomb/grenade for this batch; may only appear as a source intermediate and is flattened away |
| Powerful Seaforium Charge | Charge, excluded |
| Mithril Gyro-Shot / Thorium Shells | Ammo, excluded |
| Sniper Scope and other scopes | Modification, excluded |
| Dense Blasting Powder | Engineering material/component, excluded as final output |
| Thorium Widget | Engineering component, excluded as final output |
| Thorium Tube | Engineering component, excluded as final output |
| Truesilver Transformer | Engineering component, excluded as final output |
| Delicate Arcanite Converter | Engineering component, excluded as final output |
| World Enlarger | Utility device; not an equipped Classic trinket |
| Salt Shaker | Utility device |
| Gnomish Alarm-O-Bot | Utility/summon device outside selected categories |
| Masterwork Target Dummy and target dummies | Utility device |
| Pets, companions, mounts, fireworks | Explicitly outside scope |
| Recipes above 295 | Outside boundary |
| Other post-vanilla/seasonal recipes | Excluded; High-Powered Flashlight is the sole explicit exception |

## Recipe normalization table

All rows use `skillRef = "f82db71a:xprqs3y1"`, `learnMode = "trainer"`, and the trainer cost for their skill shown above. `Hammer` means Blacksmith Hammer `61fdf3df:518sbr8g` as `kind = "tool"` where source crafting requires it.

| Skill | Output | Original source reagents | Recursive expansion / final normalized bill of materials | Output |
| ---: | --- | --- | --- | ---: |
| 230 | Gnomish Battle Chicken | Mithril Casing x1; Truesilver Bar x6; Mithril Bar x6; Inlaid Mithril Cylinder x2; Gold Power Core x1; Jade x2 | Casing -> Mithril x3; Cylinder x2 is covered by one 4-output batch -> Mithril x5 + Gold x1 + Truesilver x1; Power Core -> Gold x1. **Final:** Mithril Bar x14; Truesilver Bar x7; Gold Bar x2; Jade x2; Hammer | 1 |
| 230 | Goblin Bomb Dispenser | Mithril Casing x2; Solid Blasting Powder x4; Truesilver Bar x6; Unstable Trigger x1; Accurate Scope x2 | Casing x2 -> Mithril x6; powder x4 -> Solid Stone x8; trigger -> Mithril x1 + Mageweave x1 + Solid Stone x2; Accurate Scope source chain must be flattened to its non-Engineering leaves. **Known aggregate before scope expansion:** Mithril Bar x7; Solid Stone x10; Mageweave Cloth x1; Truesilver Bar x6 + two Accurate Scope leaf sets; Hammer | 1 |
| 230 | Deepdive Helmet | Mithril Bar x8; Mithril Casing x1; Truesilver Bar x1; Tigerseye x4; Malachite x4 | Casing -> Mithril x3. **Final:** Mithril Bar x11; Truesilver Bar x1; Tigerseye x4; Malachite x4; Hammer | 1 |
| 230 | Rose Colored Goggles | Thick Leather x6; Star Ruby x2 | **Final:** Thick Leather x6; Star Ruby x2 | 1 |
| 235 | Gnomish Mind Control Cap | Mithril Bar x10; Truesilver Bar x4; Gold Power Core x1; Star Ruby x2; Mageweave Cloth x4 | Core -> Gold Bar x1. **Final:** Mithril Bar x10; Truesilver Bar x4; Gold Bar x1; Star Ruby x2; Mageweave Cloth x4; Hammer | 1 |
| 235 | Hi-Explosive Bomb | Mithril Casing x2; Unstable Trigger x1; Solid Blasting Powder x2 | Casing x2 -> Mithril x6; trigger -> Mithril x1 + Mageweave x1 + Solid Stone x2; powder x2 -> Solid Stone x4. **Final:** Mithril Bar x7; Mageweave Cloth x1; Solid Stone x6; Hammer | 4 |
| 240 | Gnomish Death Ray | Mithril Tube x2; Unstable Trigger x1; Essence of Undeath x1; Ichor of Undeath x4; Inlaid Mithril Cylinder x1 | Tube x2 -> Mithril x6; trigger -> Mithril x1 + Mageweave x1 + Solid Stone x2; Ichor is normalized to Essence of Undeath; one Cylinder requires one source batch -> Mithril x5 + Gold x1 + Truesilver x1. **Final:** Mithril Bar x12; Mageweave Cloth x1; Solid Stone x2; Gold Bar x1; Truesilver Bar x1; Essence of Undeath x5; Hammer | 1 |
| 240 | Goblin Dragon Gun | Mithril Tube x2; Goblin Rocket Fuel x4; Mithril Bar x6; Truesilver Bar x6; Unstable Trigger x1 | Tubes -> Mithril x6; trigger -> Mithril x1 + Mageweave x1 + Solid Stone x2. **Final:** Mithril Bar x13; Truesilver Bar x6; Goblin Rocket Fuel x4; Mageweave Cloth x1; Solid Stone x2; Hammer | 1 |
| 245 | Green Lens | Thick Leather x8; Jade x3; Aquamarine x3; Heart of the Wild x2; Wildvine x2 | No Engineering intermediates. **Final:** same leaves | 1 |
| 245 | Goblin Rocket Helmet | Goblin Construction Helmet x1; Goblin Rocket Fuel x4; Mithril Bar x4; Unstable Trigger x1 | Construction Helmet source -> Mithril Bar x8 + Citrine x1 + Elemental Fire x4; trigger -> Mithril x1 + Mageweave x1 + Solid Stone x2. **Final:** Mithril Bar x13; Citrine x1; Elemental Fire x4; Goblin Rocket Fuel x4; Mageweave Cloth x1; Solid Stone x2; Hammer | 1 |
| 250 | Mithril Mechanical Dragonling | Star Ruby x2; Truesilver Bar x4; Mithril Bar x14; Goblin Rocket Fuel x2; Heart of Fire x4; Inlaid Mithril Cylinder x2 | Heart of Fire -> Elemental Fire. Cylinder x2 is covered by one 4-output batch -> Mithril x5 + Gold x1 + Truesilver x1. **Final:** Mithril Bar x19; Truesilver Bar x5; Gold Bar x1; Star Ruby x2; Goblin Rocket Fuel x2; Elemental Fire x4; Hammer | 1 |
| 250 | High-Powered Flashlight | Thorium Widget x4; Truesilver Bar x6; Essence of Fire x6 | Widgets -> Thorium Bar x12 + Runecloth x4. **Final:** Thorium Bar x12; Runecloth x4; Truesilver Bar x6; Essence of Fire x6; Hammer | 1 |
| 260 | Gyrofreeze Ice Reflector | Thorium Widget x6; Truesilver Transformer x2; Blue Sapphire x2; Essence of Fire x4; Frost Oil x2; Icecap x4 | Widgets -> Thorium x18 + Runecloth x6; transformers -> Truesilver x4 + Elemental Earth x4 + Elemental Air x2. **Final:** Thorium Bar x18; Runecloth x6; Truesilver Bar x4; Elemental Earth x4; Elemental Air x2; Blue Sapphire x2; Essence of Fire x4; Frost Oil x2; Icecap x4; Hammer | 1 |
| 260 | Dimensional Ripper - Everlook | Mithril Bar x10; Truesilver Transformer x1; Heart of Fire x4; Star Ruby x2; The Big One x1 | Transformer -> Truesilver x2 + Elemental Earth x2 + Elemental Air x1; Heart of Fire -> Elemental Fire x4. The Big One must be expanded through its Classic source component tree; it must not remain an Engineering input. **Final base before The Big One expansion:** Mithril Bar x10; Truesilver Bar x2; Elemental Earth x2; Elemental Air x1; Elemental Fire x4; Star Ruby x2 + The Big One leaf set; Hammer | 1 |
| 260 | Ultrasafe Transporter: Gadgetzan | Mithril Bar x12; Truesilver Transformer x2; Core of Earth x4; Globe of Water x2; Aquamarine x4; Inlaid Mithril Cylinder x1 | Transformer x2 -> Truesilver x4 + Elemental Earth x4 + Elemental Air x2; one Cylinder batch -> Mithril x5 + Gold x1 + Truesilver x1. **Would normalize to:** Mithril x17; Truesilver x5; Gold x1; Elemental Earth x4; Elemental Air x2; Core of Earth x4; Globe of Water x2; Aquamarine x4. **BLOCKED:** Core of Earth and Globe of Water are not packaged canonical leaves. | 1 |
| 260 | Thorium Grenade | Thorium Widget x1; Thorium Bar x3; Dense Blasting Powder x3; Runecloth x3 | Widget -> Thorium x3 + Runecloth x1; powder x3 -> Dense Stone x6. **Final:** Thorium Bar x6; Dense Stone x6; Runecloth x4; Hammer | 3 |
| 260 | Thorium Rifle | Mithril Tube x2; Mithril Casing x2; Thorium Widget x2; Thorium Bar x4; Deadly Scope x1 | Tubes x2 -> Mithril x6; casings x2 -> Mithril x6; widgets x2 -> Thorium x6 + Runecloth x2; Deadly Scope -> Mithril x3 + Aquamarine x2 + Thick Leather x2. **Final:** Mithril Bar x15; Thorium Bar x10; Runecloth x2; Aquamarine x2; Thick Leather x2; Hammer | 1 |
| 265 | Goblin Jumper Cables XL | Thorium Widget x2; Truesilver Transformer x2; Fused Wiring x2; Ironweb Spider Silk x2; Star Ruby x2 | Widgets -> Thorium x6 + Runecloth x2; transformers -> Truesilver x4 + Elemental Earth x4 + Elemental Air x2. **Would normalize to:** Thorium x6; Runecloth x2; Truesilver x4; Elemental Earth x4; Elemental Air x2; Fused Wiring x2; Ironweb Spider Silk x2; Star Ruby x2. **BLOCKED:** Fused Wiring and Ironweb Spider Silk are not packaged canonical leaves. | 1 |
| 270 | Spellpower Goggles Xtreme Plus | Spellpower Goggles Xtreme x1; Star Ruby x4; Enchanted Leather x2; Runecloth x8 | Spellpower Goggles Xtreme source -> Thick Leather x4 + Star Ruby x2. **Final:** Thick Leather x4; Star Ruby x6; Enchanted Leather x2; Runecloth x8 | 1 |
| 275 | Major Recombobulator | Thorium Tube x2; Truesilver Transformer x1; Runecloth x2 | Tubes -> Thorium x12; transformer -> Truesilver x2 + Elemental Earth x2 + Elemental Air x1. **Final:** Thorium Bar x12; Truesilver Bar x2; Elemental Earth x2; Elemental Air x1; Runecloth x2; Hammer | 1 |
| 275 | Dark Iron Rifle | Thorium Tube x2; Dark Iron Bar x6; Deadly Scope x2; Blue Sapphire x2; Large Opal x2; Rugged Leather x4 | Tubes -> Thorium x12; scopes x2 -> Mithril x6 + Aquamarine x4 + Thick Leather x4. **Final:** Thorium Bar x12; Dark Iron Bar x6; Mithril Bar x6; Aquamarine x4; Thick Leather x4; Blue Sapphire x2; Large Opal x2; Rugged Leather x4; Hammer | 1 |
| 285 | Dark Iron Bomb | Thorium Widget x2; Dark Iron Bar x1; Dense Blasting Powder x3; Runecloth x3 | Widgets -> Thorium x6 + Runecloth x2; powder -> Dense Stone x6. **Final:** Thorium Bar x6; Dark Iron Bar x1; Dense Stone x6; Runecloth x5; Hammer | 3 |
| 290 | Hyper-Radiant Flame Reflector | Dark Iron Bar x4; Truesilver Transformer x3; Essence of Water x6; Star Ruby x4; Azerothian Diamond x2 | Transformers -> Truesilver x6 + Elemental Earth x6 + Elemental Air x3. **Final:** Dark Iron Bar x4; Truesilver Bar x6; Elemental Earth x6; Elemental Air x3; Essence of Water x6; Star Ruby x4; Azerothian Diamond x2; Hammer | 1 |
| 290 | Master Engineer's Goggles | Fire Goggles x1; Huge Emerald x2; Enchanted Leather x4 | Fire Goggles -> Green Tinted Goggles + Citrine x2 + Elemental Fire x2 + Heavy Leather x4; Green Tinted Goggles -> Flying Tiger Goggles + Moss Agate x2 + Medium Leather x4; Flying Tiger Goggles -> Light Leather x6 + Tigerseye x2. **Final:** Light Leather x6; Tigerseye x2; Moss Agate x2; Medium Leather x4; Citrine x2; Elemental Fire x2; Heavy Leather x4; Huge Emerald x2; Enchanted Leather x4; Hammer | 1 |
| 290 | Voice Amplification Modulator | Delicate Arcanite Converter x2; Gold Power Core x1; Thorium Widget x1; Large Opal x1 | Converters -> Arcanite Bar x2 + Ironweb Spider Silk x2; Power Core -> Gold x1; Widget -> Thorium x3 + Runecloth x1. **Would normalize to:** Arcanite Bar x2; Ironweb Spider Silk x2; Gold Bar x1; Thorium Bar x3; Runecloth x1; Large Opal x1. **BLOCKED:** Ironweb Spider Silk is not packaged. | 1 |

### Normalization validation notes

- No final normalized bill above intentionally preserves an Engineering component.
- The only rows still showing a named Engineering source dependency in prose are Goblin Bomb Dispenser (Accurate Scope) and Dimensional Ripper - Everlook (The Big One). Those names are audit-tree nodes only; #280 must use their flattened external leaves, not the Engineering item itself.
- Component output yields are batch-aware. Inlaid Mithril Cylinder produces four; recipes consuming one or two cylinders therefore consume one whole component batch.
- The user's Ichor/Heart substitutions are applied before leaf aggregation.

## Item representation preparation

### Bombs / grenades

`Hi-Explosive Bomb`, `Thorium Grenade`, and `Dark Iron Bomb` are `itemType = "consumable"`, stackable, and use `useSpellRef` to an unavailable-learn-mode item spell. Preserve Classic Engineering skill conditions. Their source damage/control is represented by the established Engineering explosive spell pattern rather than bespoke code.

Prepared effects:

| Item | RPE effect |
| --- | --- |
| Hi-Explosive Bomb | 20 yd; 1–5 hostile targets; Fire damage using source 255–345 range under the existing RPE variance convention; apply one-turn break-on-damage incapacitation; `engineering_explosive`; no GCD |
| Thorium Grenade | 20 yd; 1–5 hostile targets; Fire damage using source 300–500 range; one-turn break-on-damage incapacitation; `engineering_explosive`; no GCD |
| Dark Iron Bomb | 20 yd; 1–5 hostile targets; Fire damage using source 225–675 range; one-turn break-on-damage incapacitation; `engineering_explosive`; no GCD |

### Armour / wearables

Use source Classic item level, required level, quality, binding, icon, armour amount, armour weight and passive stats. Wearables receive the current generic modification-slot convention. Unsupported non-combat/passive mechanics are omitted rather than replaced with unrelated stats.

- Deepdive Helmet: Cloth Head; source +15 Stamina; underwater breathing has no useful RPE combat representation.
- Rose Colored Goggles: Cloth Head; source 49 Armor, +12 Intellect, +13 Spirit.
- Gnomish Mind Control Cap: Cloth Head; source 50 Armor, +14 Spirit. Active mind control is blocked.
- Green Lens: Cloth Head; source 57 Armor, +10 Stamina. Random enchantment/suffix generation is blocked; do not invent a fixed suffix.
- Goblin Rocket Helmet: Cloth Head; source 50 Armor, +15 Stamina. Exact charge plus user self-stun is blocked.
- Spellpower Goggles Xtreme Plus: Cloth Head; source 57 Armor, +27 Spell Power.
- Master Engineer's Goggles: Cloth Head; source 61 Armor, +16 Stamina, +17 Spirit.
- Voice Amplification Modulator: cosmetic `armor` using Neck slot `f82db71a:ujxndj4q`. Source silence-resistance passive is blocked because there is no generic silence-resistance stat.

### Weapons

- Thorium Rifle: `itemType = "weapon"`; Ranged/Gun/Physical; source 42–79 damage, 2.50 speed, required level 47, +17 Ranged Attack Power; one generic modification slot.
- Dark Iron Rifle: Ranged/Gun/Physical; source 53–100 damage, 2.70 speed, required level 50; source chance-on-hit Shadow Shot is not a manual `useSpellRef`. If #279 confirms the current equipment-trait event model can express the proc without new runtime code, author it there; otherwise leave the proc explicitly blocked.

### Trinkets

All trinkets use `itemType = "armor"`, `armorWeight = "cosmetic"`, `validSlotRefs = { "f82db71a:139phg06" }`. Active trinkets use `useSpellRef` only where their effect is representable.

- Gnomish Battle Chicken / Goblin Bomb Dispenser / Mithril Mechanical Dragonling: source summon behavior requires an RPE unit definition. Do not create units in #278; active effect remains blocked unless an existing appropriate unit is deliberately supplied.
- Gnomish Death Ray: exact life-force charging and self-damage mechanic is blocked.
- Goblin Dragon Gun: exact forward cone, periodic channel and malfunction/backfire semantics are blocked; do not substitute a normal bomb.
- High-Powered Flashlight: include item. Preserve the older item's intended Hit-related passive rather than modern stat-converted data; if no direct current RPE mapping is suitable, leave the passive blocked. Its ring-of-light visual use has no turn-combat effect and does not justify runtime work.
- Gyrofreeze Ice Reflector: preserve source +15 Frost Resistance. For the active reflect use the existing project abstraction: self Aura, +50 Frost Resistance, 3 turns, 5-turn cooldown. Do not implement literal spell reflection.
- Hyper-Radiant Flame Reflector: preserve source +18 Fire Resistance. Active abstraction: self Aura, +50 Fire Resistance, 3 turns, 5-turn cooldown.
- Dimensional Ripper - Everlook / Ultrasafe Transporter: Gadgetzan: teleport effects are outside the current combat Spell model and remain blocked.
- Goblin Jumper Cables XL: chance-based resurrection is blocked by the current item-use Spell model.
- Major Recombobulator: friendly-target use; generic heal and resource restoration are supported. Prepare one heal component and one resource component using the source 375–625 magnitude under current RPE numeric conventions. Arbitrary removal of polymorph is not represented by `remove_aura` without a specific aura ref, so the polymorph-removal clause remains blocked.

## Spell/Aura implementation set for #278

Implement only the generic effects that are concrete and supported:

1. Hi-Explosive Bomb damage + one-turn break-on-damage incapacitation Aura.
2. Thorium Grenade damage + one-turn break-on-damage incapacitation Aura.
3. Dark Iron Bomb damage + one-turn break-on-damage incapacitation Aura.
4. Gyrofreeze Ice Reflector RPE resistance abstraction (+50 Frost Resistance, 3 turns, self, 5-turn cooldown).
5. Hyper-Radiant Flame Reflector RPE resistance abstraction (+50 Fire Resistance, 3 turns, self, 5-turn cooldown).
6. Major Recombobulator heal/resource portion; do not claim generic polymorph dispel unless the live model gains a safe generic mechanism before implementation.

Other selected active effects remain blocked rather than receiving inaccurate approximations.

Item-only spells use `learnMode = "unavailable"`; their generated descriptions are authoritative and should be exposed by Item tooltips through `useSpellRef`.

## Source/version audit

The range is determined by recipe skill, not later item-use Engineering requirements. Skill-225 records belong to the preceding slice and are not duplicated here. Skill-295 recipes are eligible if they satisfy category scope; recipes above 295 are excluded.

High-Powered Flashlight is intentionally included even though it is not a vanilla Classic-era recipe. This is an explicit user instruction and is the only source-version exception in this preparation.

Where later Wowhead pages stat-convert an old item, use the historical Classic-era meaning rather than silently copying modern converted stats. High-Powered Flashlight is the relevant case in this batch.

## Current-code audit

The preparation was checked against current `dev` versions of the required architecture/data areas:

- Engineering and owner profession datasets;
- Core item slots/stats/damage schools;
- `core/classes/Item.lua`;
- `core/classes/Recipe.lua`;
- `core/classes/Spell.lua` and `core/classes/Aura.lua` generic effect model;
- `client/client_Crafting.lua` trainer cost/index behavior;
- `client/client_ItemUse.lua` inventory/equipment item-use restrictions;
- `client/spellcasting/DescriptionBuilder.lua`;
- `client/spellcasting/AuraDescriptionBuilder.lua`;
- `client/ui/tooltips/tooltip_Item.lua`;
- `core/internal/database/Dependecies.lua`;
- packaged default installation/dependency conventions;
- prior Engineering 150–225 preparation and current Engineering version 13 data.

No runtime or dataset implementation is part of #277.

## Deterministic validation

- Boundary is strictly `>225 and <=295`; no skill-225 row is selected.
- The selected set is restricted to bombs/grenades, armour/wearables, trinkets, and weapons. No potion-like consumable exists in this band.
- 25 outputs are selected after the explicit High-Powered Flashlight exception.
- Ammo, scopes, components, tools, pets, mounts, target dummies, generic utility devices, dynamite, charges and out-of-band recipes are explicitly excluded.
- Engineering intermediates are recursively flattened conceptually to external leaves and component yields are accounted for.
- Solid Stone is treated as the existing Blacksmithing material, not a blocker.
- Ichor of Undeath is normalized to Essence of Undeath.
- Heart of Fire is normalized to Elemental Fire.
- No Engineering-crafted reusable tool is planned as a Recipe tool.
- All later implementation recipes use `learnMode = "trainer"` and the live trainer-cost formula.
- Active behavior is assigned to the current generic Spell/Aura path where representable, otherwise explicitly blocked.
- High-Powered Flashlight is documented as the sole later-source exception and does not broaden the source policy.

## Incomplete / Blocked Items and Recipes

| Item / Recipe | Complete | Blocker | Smallest follow-up |
| --- | --- | --- | --- |
| Goblin Bomb Dispenser recipe | Identity/source recipe/category complete | Accurate Scope audit-tree leaf expansion still needs to be copied into #280's final authored input list; scope itself must not remain an Engineering input | Expand Accurate Scope to its current external leaves during #280 authoring |
| Dimensional Ripper - Everlook recipe | Identity/source recipe/base expansion complete | The Big One audit-tree node still requires its exact external leaf expansion in the final authored list | Expand The Big One from Classic Wowhead source tree in #280; do not preserve the Engineering item |
| Ultrasafe Transporter: Gadgetzan recipe | Identity and expansion known | `Core of Earth` and `Globe of Water` are not present as packaged canonical material Items | Keep recipe blocked unless those materials already exist before #280 for an independent reason |
| Goblin Jumper Cables XL recipe | Identity and expansion known | `Fused Wiring` and `Ironweb Spider Silk` are not packaged canonical leaves | Keep recipe blocked; do not add them under this issue sequence |
| Voice Amplification Modulator recipe | Identity and expansion known | `Ironweb Spider Silk` is not packaged | Keep recipe blocked |
| Gnomish Battle Chicken | Item/recipe identity complete | summon requires an RPE unit | Item may be authored; active use remains blocked unless an existing unit is supplied |
| Goblin Bomb Dispenser | Item/recipe identity complete | summon requires an RPE unit | Item may be authored; active use blocked |
| Gnomish Mind Control Cap | Item/passive stats complete | mind-control mechanic unsupported | Omit active use rather than invent a substitute |
| Gnomish Death Ray | Item identity complete | exact charging/self-damage behavior unsupported | Omit active use |
| Goblin Dragon Gun | Item identity complete | cone/channel/backfire semantics unsupported | Omit active use |
| Green Lens | Base item complete | random enchantment generation unsupported | Implement base item only |
| Goblin Rocket Helmet | Base item complete | exact charge/self-stun semantics unsupported | Implement item only |
| Mithril Mechanical Dragonling | Item/recipe identity complete | summon requires unit definition | Active use blocked unless unit supplied separately |
| High-Powered Flashlight | Explicit inclusion and recipe complete | old Hit-rating passive and visual light-use do not map cleanly to current turn-combat model | Include item; do not invent modern converted stats or a combat spell |
| Dimensional Ripper / Ultrasafe Transporter | Item identity complete | teleport unsupported | No item-use Spell |
| Goblin Jumper Cables XL | Item identity complete | probabilistic resurrection unsupported | No item-use Spell |
| Major Recombobulator | Heal/resource portion supported | arbitrary polymorph dispel unsupported by specific-aura `remove_aura` model | Implement heal/resource only unless generic dispel support exists by #278 |
| Dark Iron Rifle | Weapon identity/stats complete | passive Shadow Shot proc depends on current generic equipment-trait event expressiveness | Use equipment trait only if no runtime expansion is required |
| Voice Amplification Modulator | Neck representation complete | silence-resistance passive has no current generic stat | Author wearable only if recipe becomes available; omit passive |

No other selected entry has a known source-identity or scope blocker.
