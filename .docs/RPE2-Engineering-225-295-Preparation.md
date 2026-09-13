# RPE2 Engineering 225–295 Preparation

## Purpose and authority

This document is the implementation source of truth for Issue #277 and Engineering follow-up issues #278–#280.

```text
required Engineering skill > 225 and <= 295
```

Only these crafted-output categories are selected:

- bombs and grenades;
- armour and other wearable equipment;
- trinkets;
- weapons;
- potion-like consumables.

There are no potion-like Engineering consumables in this band.

**High-Powered Flashlight is an explicit user-directed exception to the vanilla-only source rule.** Do not use its inclusion to admit other post-vanilla recipes.

Classic Wowhead is authoritative for source recipe/item identity and RPE2 `dev` is authoritative for schema, runtime representation, dataset ownership, existing materials and trainer costs.

## RPE implementation rules

- Engineering dataset: `af503002`; current preparation-time version: `13`.
- Engineering skill: `f82db71a:xprqs3y1`.
- Every later Recipe uses `learnMode = "trainer"`; original acquisition is provenance only.
- Recursively expand every Engineering intermediate to external packaged material leaves. Do not preserve component Items as Recipe inputs.
- Respect component output quantities by whole source batches; never use fractional source crafts.
- Aggregate duplicate leaf materials after expansion.
- Do not create missing shared/raw materials under #278–#280 merely to unblock a recipe.
- Blacksmith Hammer `61fdf3df:518sbr8g` is the only reusable Engineering Recipe tool. Never use Arclight Spanner or Gyromatic Micro-Adjustor as RPE `tool` inputs.
- Active item behavior uses the generic `Item.useSpellRef -> Spell -> components/Auras` architecture only.
- `client/client_ItemUse.lua` supports inventory use for `consumable` and equipped use for `armor`/`weapon`; therefore Classic trinkets use `itemType = "armor"`, `armorWeight = "cosmetic"`, Core Trinket slot `f82db71a:139phg06`.
- Bomb/grenade actives reuse the existing Engineering explosive pattern: hostile multi-target, 20 yards, 1–5 targets, `engineering_explosive` cooldown group, no GCD, plus a one-turn break-on-damage control Aura for source stuns/incapacitates.

## Canonical RPE refs

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
Gun weapon type          f82db71a:anoo8qfp
Physical school          f82db71a:v1azo4j6
Fire school              f82db71a:esjguw6d
Frost school             f82db71a:hx7pnwv4
Nature school            f82db71a:qtr10qyj
Shadow school            f82db71a:1ggt4t3v

Bronze Bar               61fdf3df:xegz4i5q
Solid Stone              61fdf3df:o1ogtdcq
Mithril Bar              61fdf3df:i5m1b7xd
Truesilver Bar           61fdf3df:k7t3b9zf
Gold Bar                 61fdf3df:j6g2b8ye
Blacksmith Hammer        61fdf3df:518sbr8g
Heavy Leather            538a54a0:55k8gjup
Thick Leather            538a54a0:u0wy9jz1
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
Weak Flux                3eb7e9bb:3yvy546j
Heart of the Wild        3eb7e9bb:w2plwren
Wildvine                 3eb7e9bb:2hbdmyj4
```

Other normalized leaves named below (Thorium Bar, Dark Iron Bar, Arcanite Bar, Dense Stone, Runecloth, Silk Cloth, Mageweave Cloth, Rugged/Medium/Light Leather, Jade, Blue Sapphire, Large Opal, Azerothian Diamond, Huge Emerald, Moss Agate, Tigerseye, Malachite and Icecap) already exist in the packaged owner datasets on `dev`. #280 must resolve and use those current qualified refs, not create Engineering-local copies.

### User-directed material substitutions

These are authoritative:

- source `Ichor of Undeath` -> `Essence of Undeath` `732368d4:xtnbjwzj`;
- source `Heart of Fire` -> `Elemental Fire` `732368d4:sclalidn`;
- Solid Stone is Blacksmithing `61fdf3df:o1ogtdcq` and is not a blocker.

## Component expansion rules

| Engineering intermediate | Source recipe / yield | External-leaf expansion |
| --- | --- | --- |
| Solid Blasting Powder | Solid Stone x2 -> 1 | Solid Stone x2 |
| Dense Blasting Powder | Dense Stone x2 -> 1 | Dense Stone x2 |
| Mithril Casing | Mithril Bar x3 -> 1 | Mithril Bar x3 |
| Mithril Tube | Mithril Bar x3 -> 1 | Mithril Bar x3 |
| Unstable Trigger | Mithril Bar x1; Mageweave Cloth x1; Solid Blasting Powder x1 -> 1 | Mithril Bar x1; Mageweave Cloth x1; Solid Stone x2 |
| Gold Power Core | Gold Bar x1 -> 1 | Gold Bar x1 |
| Thorium Widget | Thorium Bar x3; Runecloth x1 -> 1 | same |
| Thorium Tube | Thorium Bar x6 -> 1 | Thorium Bar x6 |
| Truesilver Transformer | Truesilver Bar x2; Elemental Earth x2; Elemental Air x1 -> 1 | same |
| Inlaid Mithril Cylinder | Mithril Bar x5; Gold Bar x1; Truesilver Bar x1 -> 4 | one whole batch supplies 1–4 required cylinders |
| Bronze Tube | Bronze Bar x2; Weak Flux x1 -> 1 | Bronze Bar x2; Weak Flux x1 |
| Accurate Scope | Bronze Tube x1; Jade x1; Citrine x1 -> 1 | Bronze Bar x2; Weak Flux x1; Jade x1; Citrine x1 |
| Deadly Scope | Mithril Tube x1; Aquamarine x2; Thick Leather x2 -> 1 | Mithril Bar x3; Aquamarine x2; Thick Leather x2 |
| Delicate Arcanite Converter | Arcanite Bar x1; Ironweb Spider Silk x1 -> 1 | Arcanite Bar x1 + missing Ironweb Spider Silk x1 |
| The Big One | Mithril Casing x1; Goblin Rocket Fuel x1; Solid Dynamite x6; Unstable Trigger x1 -> 2 | one batch: Mithril Bar x4; Goblin Rocket Fuel x1; Solid Stone x8; Silk Cloth x3; Mageweave Cloth x1 |

The Big One expansion accounts for Solid Dynamite yielding two per craft: six source Solid Dynamite require three Solid Blasting Powder and three Silk Cloth; the trigger adds another Solid Blasting Powder-equivalent two Solid Stone.

Finished Engineering outputs used as source ingredients are also flattened. Do not preserve Goblin Construction Helmet, Spellpower Goggles Xtreme, Fire Goggles, Green Tinted Goggles or Flying Tiger Goggles as final inputs.

## Trainer costs

Current `client/client_Crafting.lua` formula:

```text
floor(75 + requiredSkillLevel * 28 + requiredSkillLevel^2 * 1.6)
```

| Skill | Copper |
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

The selected inventory is **25 outputs**.

| Skill | Output | WoW item ID | Category | Original acquisition | Status |
| ---: | --- | ---: | --- | --- | --- |
| 230 | Gnomish Battle Chicken | 10725 | Trinket | Gnomish Engineering | Item/recipe; summon active blocked |
| 230 | Goblin Bomb Dispenser | 10587 | Trinket | Goblin Engineering | Item/recipe; summon active blocked |
| 230 | Deepdive Helmet | 10506 | Armour | Schematic | Item/recipe; underwater breathing omitted |
| 230 | Rose Colored Goggles | 10503 | Armour | Trainer | Full passive item/recipe |
| 235 | Gnomish Mind Control Cap | 10726 | Armour | Gnomish Engineering | Item/recipe; mind control blocked |
| 235 | Hi-Explosive Bomb | 10562 | Bomb | Trainer | Full item/spell/recipe |
| 240 | Gnomish Death Ray | 10645 | Trinket | Gnomish Engineering | Item/recipe; exact active blocked |
| 240 | Goblin Dragon Gun | 10727 | Trinket | Goblin Engineering | Item/recipe; cone/backfire active blocked |
| 245 | Green Lens | 10504 | Armour | Trainer | Base item/recipe; random suffix blocked |
| 245 | Goblin Rocket Helmet | 10588 | Armour | Goblin Engineering | Item/recipe; charge/self-stun blocked |
| 250 | Mithril Mechanical Dragonling | 10576 | Trinket | Schematic/vendor | Item/recipe; summon needs unit dependency |
| 250 | High-Powered Flashlight | 45631 | Trinket | Explicit user exception | Include despite later source |
| 260 | Gyrofreeze Ice Reflector | 18634 | Trinket | Schematic | Resistance abstraction supported |
| 260 | Dimensional Ripper - Everlook | 18984 | Trinket | Goblin Engineering | Recipe complete; teleport active blocked |
| 260 | Ultrasafe Transporter: Gadgetzan | 18986 | Trinket | Gnomish Engineering | Recipe blocked by missing leaves; teleport blocked |
| 260 | Thorium Grenade | 15993 | Grenade | Schematic | Full item/spell/recipe |
| 260 | Thorium Rifle | 15995 | Weapon | Schematic | Full item/recipe |
| 265 | Goblin Jumper Cables XL | 18587 | Trinket | Schematic | Recipe + resurrection blocked |
| 270 | Spellpower Goggles Xtreme Plus | 15999 | Armour | Schematic | Full passive item/recipe |
| 275 | Major Recombobulator | 18637 | Trinket | Schematic | Heal/resource supported; polymorph dispel blocked |
| 275 | Dark Iron Rifle | 16004 | Weapon | Schematic | Item/recipe; passive proc conditional on generic trait support |
| 285 | Dark Iron Bomb | 16005 | Bomb | Schematic | Full item/spell/recipe |
| 290 | Hyper-Radiant Flame Reflector | 18638 | Trinket | Schematic | Resistance abstraction supported |
| 290 | Master Engineer's Goggles | 16008 | Armour | Trainer | Full passive item/recipe |
| 290 | Voice Amplification Modulator | 16009 | Neck wearable | Schematic | Recipe blocked; silence-resistance passive blocked |

## Explicit exclusions

| Output/category | Reason |
| --- | --- |
| Dense Dynamite | Dynamite, not bomb/grenade |
| The Big One | Explosive but not selected bomb/grenade classification; used only as a flattened source intermediate |
| Powerful Seaforium Charge | Charge |
| Mithril Gyro-Shot / Thorium Shells | Ammo |
| Sniper Scope and other scopes | Modification |
| Dense Blasting Powder, Thorium Widget, Thorium Tube, Truesilver Transformer, Delicate Arcanite Converter | Component/material outputs |
| World Enlarger | Utility device, not an equipped Classic trinket |
| Salt Shaker | Utility device |
| Gnomish Alarm-O-Bot | Utility/summon device outside selected categories |
| Target dummies | Utility devices |
| Pets, companions, mounts, fireworks | Explicitly outside scope |
| >295 recipes | Outside boundary |
| Other post-vanilla/seasonal recipes | Outside source policy; High-Powered Flashlight is the sole exception |

## Final normalized recipe BOM

`Hammer` below means Blacksmith Hammer `61fdf3df:518sbr8g` as a non-consumed tool. Material names resolve to their existing packaged owner Items.

| Skill | Output | Final normalized external inputs | Qty |
| ---: | --- | --- | ---: |
| 230 | Gnomish Battle Chicken | Mithril Bar x14; Truesilver Bar x7; Gold Bar x2; Jade x2; Hammer | 1 |
| 230 | Goblin Bomb Dispenser | Mithril Bar x7; Solid Stone x10; Mageweave Cloth x1; Truesilver Bar x6; Bronze Bar x4; Weak Flux x2; Jade x2; Citrine x2; Hammer | 1 |
| 230 | Deepdive Helmet | Mithril Bar x11; Truesilver Bar x1; Tigerseye x4; Malachite x4; Hammer | 1 |
| 230 | Rose Colored Goggles | Thick Leather x6; Star Ruby x2 | 1 |
| 235 | Gnomish Mind Control Cap | Mithril Bar x10; Truesilver Bar x4; Gold Bar x1; Star Ruby x2; Mageweave Cloth x4; Hammer | 1 |
| 235 | Hi-Explosive Bomb | Mithril Bar x7; Mageweave Cloth x1; Solid Stone x6; Hammer | 4 |
| 240 | Gnomish Death Ray | Mithril Bar x12; Mageweave Cloth x1; Solid Stone x2; Gold Bar x1; Truesilver Bar x1; Essence of Undeath x5; Hammer | 1 |
| 240 | Goblin Dragon Gun | Mithril Bar x13; Truesilver Bar x6; Goblin Rocket Fuel x4; Mageweave Cloth x1; Solid Stone x2; Hammer | 1 |
| 245 | Green Lens | Thick Leather x8; Jade x3; Aquamarine x3; Heart of the Wild x2; Wildvine x2 | 1 |
| 245 | Goblin Rocket Helmet | Mithril Bar x13; Citrine x1; Elemental Fire x4; Goblin Rocket Fuel x4; Mageweave Cloth x1; Solid Stone x2; Hammer | 1 |
| 250 | Mithril Mechanical Dragonling | Mithril Bar x19; Truesilver Bar x5; Gold Bar x1; Star Ruby x2; Goblin Rocket Fuel x2; Elemental Fire x4; Hammer | 1 |
| 250 | High-Powered Flashlight | Thorium Bar x12; Runecloth x4; Truesilver Bar x6; Essence of Fire x6; Hammer | 1 |
| 260 | Gyrofreeze Ice Reflector | Thorium Bar x18; Runecloth x6; Truesilver Bar x4; Elemental Earth x4; Elemental Air x2; Blue Sapphire x2; Essence of Fire x4; Frost Oil x2; Icecap x4; Hammer | 1 |
| 260 | Dimensional Ripper - Everlook | Mithril Bar x14; Truesilver Bar x2; Elemental Earth x2; Elemental Air x1; Elemental Fire x4; Star Ruby x2; Goblin Rocket Fuel x1; Solid Stone x8; Silk Cloth x3; Mageweave Cloth x1; Hammer | 1 |
| 260 | Ultrasafe Transporter: Gadgetzan | Mithril Bar x17; Truesilver Bar x5; Gold Bar x1; Elemental Earth x4; Elemental Air x2; Core of Earth x4; Globe of Water x2; Aquamarine x4; Hammer | 1, **blocked** |
| 260 | Thorium Grenade | Thorium Bar x6; Dense Stone x6; Runecloth x4; Hammer | 3 |
| 260 | Thorium Rifle | Mithril Bar x15; Thorium Bar x10; Runecloth x2; Aquamarine x2; Thick Leather x2; Hammer | 1 |
| 265 | Goblin Jumper Cables XL | Thorium Bar x6; Runecloth x2; Truesilver Bar x4; Elemental Earth x4; Elemental Air x2; Fused Wiring x2; Ironweb Spider Silk x2; Star Ruby x2; Hammer | 1, **blocked** |
| 270 | Spellpower Goggles Xtreme Plus | Thick Leather x4; Star Ruby x6; Enchanted Leather x2; Runecloth x8 | 1 |
| 275 | Major Recombobulator | Thorium Bar x12; Truesilver Bar x2; Elemental Earth x2; Elemental Air x1; Runecloth x2; Hammer | 1 |
| 275 | Dark Iron Rifle | Thorium Bar x12; Dark Iron Bar x6; Mithril Bar x6; Aquamarine x4; Thick Leather x4; Blue Sapphire x2; Large Opal x2; Rugged Leather x4; Hammer | 1 |
| 285 | Dark Iron Bomb | Thorium Bar x6; Dark Iron Bar x1; Dense Stone x6; Runecloth x5; Hammer | 3 |
| 290 | Hyper-Radiant Flame Reflector | Dark Iron Bar x4; Truesilver Bar x6; Elemental Earth x6; Elemental Air x3; Essence of Water x6; Star Ruby x4; Azerothian Diamond x2; Hammer | 1 |
| 290 | Master Engineer's Goggles | Light Leather x6; Tigerseye x2; Moss Agate x2; Medium Leather x4; Citrine x2; Elemental Fire x2; Heavy Leather x4; Huge Emerald x2; Enchanted Leather x4; Hammer | 1 |
| 290 | Voice Amplification Modulator | Arcanite Bar x2; Ironweb Spider Silk x2; Gold Bar x1; Thorium Bar x3; Runecloth x1; Large Opal x1; Hammer | 1, **blocked** |

### Material-closure blockers

Only these normalized leaves are absent from the current packaged owner datasets and therefore block Recipe implementation under this issue sequence:

- `Core of Earth`;
- `Globe of Water`;
- `Fused Wiring`;
- `Ironweb Spider Silk`.

Do not add them under #278–#280 solely to make these Recipes work.

## Item and effect preparation

### Bombs / grenades

All three are stackable `consumable` Items with Engineering skill conditions and `useSpellRef` item-only Spells (`learnMode = "unavailable"`).

| Item | Prepared generic effect |
| --- | --- |
| Hi-Explosive Bomb | 20 yd, hostile multi 1–5, Fire source range 255–345, one-turn break-on-damage incapacitation, explosive cooldown, no GCD |
| Thorium Grenade | 20 yd, hostile multi 1–5, Fire source range 300–500, one-turn break-on-damage incapacitation, explosive cooldown, no GCD |
| Dark Iron Bomb | 20 yd, hostile multi 1–5, Fire source range 225–675, one-turn break-on-damage incapacitation, explosive cooldown, no GCD |

### Wearable armour

Use source Classic item level, required level, quality, binding, icon, armour, weight and supported stats. Unsupported utility/passive mechanics are omitted rather than replaced with unrelated stats.

- Deepdive Helmet: Cloth Head; +15 Stamina; underwater breathing has no RPE combat effect.
- Rose Colored Goggles: Cloth Head; 49 Armor; +12 Intellect; +13 Spirit.
- Gnomish Mind Control Cap: Cloth Head; 50 Armor; +14 Spirit; mind-control active blocked.
- Green Lens: Cloth Head; 57 Armor; +10 Stamina; random enchantment blocked.
- Goblin Rocket Helmet: Cloth Head; 50 Armor; +15 Stamina; exact charge/self-stun active blocked.
- Spellpower Goggles Xtreme Plus: Cloth Head; 57 Armor; +27 Spell Power.
- Master Engineer's Goggles: Cloth Head; 61 Armor; +16 Stamina; +17 Spirit.
- Voice Amplification Modulator: cosmetic `armor`, Neck slot; silence-resistance passive unsupported.

### Weapons

- Thorium Rifle: Ranged/Gun/Physical; source 42–79 damage, 2.50 speed, required level 47, +17 Ranged Attack Power, one generic modification slot.
- Dark Iron Rifle: Ranged/Gun/Physical; source 53–100 damage, 2.70 speed, required level 50. Its source Shadow Shot chance-on-hit is not a manual item use; author it only as a generic equipment-trait event if #279 confirms this requires no runtime expansion.

### Trinkets

All use cosmetic `armor` + Trinket slot.

- Gnomish Battle Chicken, Goblin Bomb Dispenser, Mithril Mechanical Dragonling: summon behavior requires a Unit definition outside #278; active blocked unless an existing appropriate unit is supplied.
- Gnomish Death Ray: source charging/self-damage active blocked.
- Goblin Dragon Gun: exact cone/channel/backfire active blocked; do not substitute a bomb.
- High-Powered Flashlight: include as directed. Preserve historical intent rather than modern stat conversion; if its Hit passive has no clean current mapping, omit it. Ring-of-light visual use does not justify combat runtime work.
- Gyrofreeze Ice Reflector: preserve +15 Frost Resistance; active uses established project abstraction: self +50 Frost Resistance Aura, 3 turns, 5-turn cooldown.
- Hyper-Radiant Flame Reflector: preserve +18 Fire Resistance; active abstraction: self +50 Fire Resistance Aura, 3 turns, 5-turn cooldown.
- Dimensional Ripper - Everlook / Ultrasafe Transporter: Gadgetzan: teleport unsupported.
- Goblin Jumper Cables XL: probabilistic resurrection unsupported.
- Major Recombobulator: generic friendly heal/resource restoration is supported at source 375–625 magnitude; arbitrary polymorph removal is blocked because `remove_aura` requires a specific Aura ref.

## #278 Spell/Aura implementation set

Implement only supported generic actives:

1. Hi-Explosive Bomb damage + break-on-damage control Aura.
2. Thorium Grenade damage + break-on-damage control Aura.
3. Dark Iron Bomb damage + break-on-damage control Aura.
4. Gyrofreeze Ice Reflector +50 Frost Resistance / 3 turns / self / 5-turn cooldown abstraction.
5. Hyper-Radiant Flame Reflector +50 Fire Resistance / 3 turns / self / 5-turn cooldown abstraction.
6. Major Recombobulator supported heal/resource portion; do not claim generic polymorph dispel.

Generated Spell/Aura descriptions are authoritative for Item `Use:` text.

## Source/version and code audit

- Range is based on Recipe skill, not later item-use Engineering requirements.
- Skill-225 Recipes belong to the preceding slice and are not duplicated.
- High-Powered Flashlight is the sole explicit later-source exception.
- Do not silently copy modern stat-converted values for that item.
- Preparation was checked against current `dev` Engineering and owner datasets; Core item slots/stats/damage schools; `Item.lua`; `Recipe.lua`; `Spell.lua`; `Aura.lua`; `client_Crafting.lua`; `client_ItemUse.lua`; description builders; Item tooltip code; dependency handling; packaged default conventions; and the prior Engineering preparation document.
- The #277 diff is documentation-only. No runtime or dataset data was changed.

## Incomplete / Blocked Items and Recipes

| Item / Recipe | Blocker | Smallest follow-up |
| --- | --- | --- |
| Ultrasafe Transporter: Gadgetzan Recipe | Missing packaged `Core of Earth` and `Globe of Water` | Keep Recipe blocked unless those materials independently exist before #280 |
| Goblin Jumper Cables XL Recipe | Missing packaged `Fused Wiring` and `Ironweb Spider Silk` | Keep Recipe blocked |
| Voice Amplification Modulator Recipe | Missing packaged `Ironweb Spider Silk` | Keep Recipe blocked |
| Gnomish Battle Chicken / Goblin Bomb Dispenser / Mithril Mechanical Dragonling actives | Need summonable RPE Unit definitions | Item/Recipe may be authored; no use Spell unless suitable Units already exist |
| Gnomish Mind Control Cap | Mind control unsupported | Omit active use |
| Gnomish Death Ray | Exact charge/self-damage unsupported | Omit active use |
| Goblin Dragon Gun | Exact cone/channel/backfire unsupported | Omit active use |
| Green Lens | Random suffix generation unsupported | Implement base Item only |
| Goblin Rocket Helmet | Exact charge/self-stun unsupported | Omit active use |
| High-Powered Flashlight | Historical Hit passive and visual use do not map cleanly | Include Item/Recipe; do not invent modern converted stats or combat effect |
| Dimensional Ripper / Ultrasafe Transporter actives | Teleport unsupported | No use Spell |
| Goblin Jumper Cables XL active | Chance-based resurrection unsupported | No use Spell |
| Major Recombobulator | Arbitrary polymorph dispel unsupported | Implement only supported heal/resource effects |
| Dark Iron Rifle proc | Depends on current generic equipment-trait event path | Author only if #279 confirms no runtime expansion |
| Voice Amplification Modulator passive | Silence-resistance stat unsupported | Omit passive |

All selected source identities, category decisions and normalized material quantities are otherwise complete for #278–#280.
