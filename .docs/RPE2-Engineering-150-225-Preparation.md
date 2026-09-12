# RPE2 Engineering 150–225 Preparation

## Purpose and authority

This document is the implementation source of truth for Issue #260 and the subsequent Engineering 150–225 implementation issues.

The exact skill boundary is:

```text
required Engineering skill > 150 and <= 225
```

The product scope is intentionally the same focused subset directed for the preceding Engineering slice, with two explicit user-requested exceptions. **Only these output categories are in scope:**

- bombs, grenades and dynamite, including Goblin Sapper Charge;
- guns;
- armour / goggles and other wearable armour pieces;
- ammunition;
- Ice Deflector as an explicit defensive-consumable exception.

Everything else in vanilla Classic Engineering `(150,225]` is deliberately out of scope even when it is a valid recipe in the band.

The final scoped inventory is **23 Recipes / 23 crafted outputs**.

## Explicit exclusions

Do not implement components, modifications, or generic devices merely for source completeness. This slice explicitly excludes:

- scopes / modifications;
- standalone Engineering components and intermediates;
- target dummies;
- pets;
- standalone trinkets and devices;
- mortars;
- mines, including Goblin Land Mine;
- seaforium charges other than the explicitly included Goblin Sapper Charge;
- repair kits;
- reflectors / deflectors other than the explicitly included Ice Deflector;
- fireworks;
- other utility outputs that are not wearable armour.

`Explosive Sheep` is excluded because its recipe requires exactly 150 Engineering, which belongs to the previous boundary rather than this slice.

`The Big One` is excluded because the vanilla recipe requires 235 Engineering even though some later/current item data displays a 225 Engineering use requirement.

Season of Discovery-only recipes such as Polished Truesilver Gears and the radiation/hyperconductive recipes are excluded.

## Current project rules carried forward

- Engineering dataset: `af503002`.
- Engineering skill: `f82db71a:xprqs3y1`.
- Current Engineering packaged version before implementation: `9`.
- Every Recipe implemented from this document uses `learnMode = "trainer"` regardless of original Classic acquisition source.
- Original trainer/vendor/drop/specialization provenance below is audit data only.
- Engineering component chains remain flattened using the semantic component-to-base-material convention; do not recursively multiply by component recipe cost/yield.
- Finished wearable items deliberately used as ingredients remain real item dependencies when both items are meaningful equipment, matching the Green Tinted Goggles precedent.
- Reusable Engineering Recipe tools may use only Blacksmith Hammer `61fdf3df:518sbr8g`; never author Arclight Spanner or Gyromatic Micro-Adjustor as `tool` inputs.
- A recipe only gets the Blacksmith Hammer tool when its Classic source recipe actually uses Blacksmith Hammer; do not replace every historical Engineering tool with a hammer.
- Manually activated item/equipment effects use `Item.useSpellRef -> Spell` only when the generic Spell/Aura system can represent them accurately.
- Ice Deflector intentionally follows the established Flame Deflector RPE abstraction rather than literal vanilla absorb semantics: self-targeted +50 school Resistance for 3 turns, 10-turn `potion` cooldown.
- Explosive direct damage uses the existing multi-target model (`target.type = "multi"`, 1–5 enemies) and the shared `engineering_explosive` cooldown group used by the prior slice.
- Bomb/incapacitate effects that break on damage use a one-turn control Aura with `cancelOnDamage = true`, `preventCasting = true`, `movementRangeOverride = 0`.
- Guns use Core Ranged slot `f82db71a:q8ve6n6t`, Gun type `f82db71a:anoo8qfp`, Physical school `f82db71a:v1azo4j6`, and one generic modification slot.
- Ammo uses Core Ammo slot `f82db71a:atsoi5vr` and Core Ranged Attack Power `f82db71a:v2rs9cpy`.
- Head armour uses Core Head slot `f82db71a:bgvs1zx6`; wearable pieces use their current Core slots and stats rather than local duplicates.

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

Physical school          f82db71a:v1azo4j6
Fire school              f82db71a:esjguw6d
Frost school             f82db71a:hx7pnwv4
Ranged slot              f82db71a:q8ve6n6t
Ammo slot                f82db71a:atsoi5vr
Head slot                f82db71a:bgvs1zx6
Gun weapon type          f82db71a:anoo8qfp
Armor                    f82db71a:v42albuv
Agility                  f82db71a:xqz0daz2
Stamina                  f82db71a:ygjno50i
Spirit                   f82db71a:kec9rhli
Intellect                f82db71a:75y3a8ib
Spell Power              f82db71a:7t7xgzcx
Fire Resistance          f82db71a:0w7c7p09
Frost Resistance         f82db71a:jjn0my8k
Ranged Attack Power      f82db71a:v2rs9cpy

Heavy Stone              61fdf3df:u8qtuhfq
Solid Stone              61fdf3df:o1ogtdcq
Iron Bar                 61fdf3df:h4i9b6wc
Silver Bar               61fdf3df:nvc1anz9
Gold Bar                 61fdf3df:j6g2b8ye
Mithril Bar              61fdf3df:i5m1b7xd
Truesilver Bar           61fdf3df:k7t3b9zf
Blacksmith Hammer        61fdf3df:518sbr8g
Silk Cloth               7259f1d3:jt6ktqiu
Mageweave Cloth          7259f1d3:edth2zu1
Heavy Leather            538a54a0:55k8gjup
Thick Leather            538a54a0:u0wy9jz1
Citrine                  4999dcec:ht59o8mx
Aquamarine               4999dcec:5nrqhg0t
Star Ruby                4999dcec:mr1cbt76
Elemental Fire           732368d4:sclalidn
Elemental Earth          3eb7e9bb:d9e5e2sy
Heavy Stock              3eb7e9bb:u7rzoqvg
Frost Oil                d6ffc4e2:p9f4o8ek
Catseye Elixir           d6ffc4e2:o8c3e7dj
Goblin Rocket Fuel       d6ffc4e2:q1g5m9fl
Black Mageweave Boots    7259f1d3:t9oha2l3
Dusky Belt               538a54a0:rfhy92ax
Green Tinted Goggles     af503002:c5cbkans
```

## Missing shared materials for #262

Three source materials needed by the focused inventory are not currently packaged and should be added once, in the stated owner dataset:

| Material | WoW ID | Classic metadata | Owner |
| --- | ---: | --- | --- |
| Blue Pearl | 4611 | item level 1, stack 20, common crafting material | Jewelcrafting `4999dcec` |
| Shadow Silk | 10285 | item level 40, stack 10, common crafting material | Tailoring `7259f1d3` |
| Flask of Mojo | 8151 | item level 40, stack 20, common crafting material | Misc `3eb7e9bb` |

Use new stable IDs at #262 implementation time after collision checking. Do not create Engineering-local copies.

## Component normalization

The following source Engineering components are not added as dependent-recipe requirements in this slice. Use the semantic 1:1 substitution below. This is intentionally **not** recursive material-cost expansion.

| Source component | RPE normalized input |
| --- | --- |
| Heavy Blasting Powder | Heavy Stone `61fdf3df:u8qtuhfq` 1:1 |
| Solid Blasting Powder | Solid Stone `61fdf3df:o1ogtdcq` 1:1 |
| Whirring Bronze Gizmo | Bronze Bar `61fdf3df:xegz4i5q` 1:1 |
| Silver Contact | Silver Bar `61fdf3df:nvc1anz9` 1:1 |
| Mithril Tube | Mithril Bar `61fdf3df:i5m1b7xd` 1:1 |
| Mithril Casing | Mithril Bar `61fdf3df:i5m1b7xd` 1:1 |
| Unstable Trigger | Mithril Bar `61fdf3df:i5m1b7xd` 1:1 |
| Gold Power Core | Gold Bar `61fdf3df:j6g2b8ye` 1:1 |
| Gyrochronatom | Gold Bar `61fdf3df:j6g2b8ye` 1:1 |
| Bolt of Mageweave | Mageweave Cloth `7259f1d3:edth2zu1` 1:1 |

Preserve these finished-item dependencies instead of flattening them:

- Fire Goggles consumes Green Tinted Goggles `af503002:c5cbkans`.
- Gnomish Goggles consumes the Fire Goggles output added by this slice.
- Gnomish Harm Prevention Belt consumes Dusky Belt `538a54a0:rfhy92ax`.
- Gnomish/Goblin Rocket Boots consume Black Mageweave Boots `7259f1d3:t9oha2l3`.

## Trainer-cost formula

Current `client/client_Crafting.lua` calculates:

```text
floor(75 + requiredSkillLevel * 28 + requiredSkillLevel^2 * 1.6)
```

| Skill | Cost copper |
| ---: | ---: |
| 155 | 42,855 |
| 175 | 53,975 |
| 185 | 60,015 |
| 190 | 63,155 |
| 200 | 69,675 |
| 205 | 73,055 |
| 210 | 76,515 |
| 215 | 80,055 |
| 220 | 83,675 |
| 225 | 87,375 |

## Final scoped Recipe inventory

All implementation-stage recipes use `skillRef = "f82db71a:xprqs3y1"` and `learnMode = "trainer"`.

| Skill | Output | WoW ID | Original Classic source | Original reagents | Normalized RPE inputs | Qty | Cost |
| ---: | --- | ---: | --- | --- | --- | ---: | ---: |
| 155 | Ice Deflector | 4386 | Schematic 13308, limited vendor | Whirring Bronze Gizmo x1; Frost Oil x1 | Bronze Bar x1; Frost Oil x1; Blacksmith Hammer tool | 1 | 42,855 |
| 175 | Solid Dynamite | 10507 | Trainer | Solid Blasting Powder x1; Silk Cloth x1 | Solid Stone x1; Silk Cloth x1 | 2 | 53,975 |
| 175 | Iron Grenade | 4390 | Trainer | Iron Bar x1; Heavy Blasting Powder x1; Silk Cloth x1 | Iron Bar x1; Heavy Stone x1; Silk Cloth x1; Blacksmith Hammer tool | 2 | 53,975 |
| 175 | Bright-Eye Goggles | 10499 | Schematic 10601, world drop | Heavy Leather x6; Citrine x2 | same | 1 | 53,975 |
| 185 | Craftsman's Monocle | 4393 | Schematic 4415, world drop | Heavy Leather x6; Citrine x2 | same | 1 | 60,015 |
| 185 | Flash Bomb | 4852 | Schematic 6672, quest/drop | Blue Pearl x1; Heavy Blasting Powder x1; Silk Cloth x1 | Blue Pearl x1; Heavy Stone x1; Silk Cloth x1 | 1 | 60,015 |
| 190 | Big Iron Bomb | 4394 | Trainer | Iron Bar x3; Heavy Blasting Powder x3; Silver Contact x1 | Iron Bar x3; Heavy Stone x3; Silver Bar x1; Blacksmith Hammer tool | 2 | 63,155 |
| 200 | EZ-Thro Dynamite II | 18588 | Schematic 18650, limited vendor | Solid Blasting Powder x1; Mageweave Cloth x2 | Solid Stone x1; Mageweave Cloth x2 | 1 | 69,675 |
| 205 | Fire Goggles | 10500 | Trainer | Green Tinted Goggles x1; Citrine x2; Elemental Fire x2; Heavy Leather x4 | same | 1 | 73,055 |
| 205 | Goblin Construction Helmet | 10543 | Goblin Engineering trainer | Mithril Bar x8; Citrine x1; Elemental Fire x4 | same; Blacksmith Hammer tool | 1 | 73,055 |
| 205 | Goblin Mining Helmet | 10542 | Goblin Engineering trainer | Mithril Bar x8; Citrine x1; Elemental Earth x4 | same; Blacksmith Hammer tool | 1 | 73,055 |
| 205 | Mithril Blunderbuss | 10508 | Trainer | Mithril Tube x1; Unstable Trigger x1; Heavy Stock x1; Mithril Bar x4; Elemental Fire x2 | Mithril Bar x6; Heavy Stock x1; Elemental Fire x2; Blacksmith Hammer tool | 1 | 73,055 |
| 205 | Goblin Sapper Charge | 10646 | Goblin Engineering trainer | Mageweave Cloth x1; Solid Blasting Powder x3; Unstable Trigger x1 | Mageweave Cloth x1; Solid Stone x3; Mithril Bar x1 | 1 | 73,055 |
| 210 | Gnomish Goggles | 10545 | Gnomish Engineering trainer | Fire Goggles x1; Mithril Tube x1; Gold Power Core x2; Flask of Mojo x2; Heavy Leather x2 | Fire Goggles x1; Mithril Bar x1; Gold Bar x2; Flask of Mojo x2; Heavy Leather x2 | 1 | 76,515 |
| 210 | Hi-Impact Mithril Slugs | 10512 | Trainer | Mithril Bar x1; Solid Blasting Powder x1 | Mithril Bar x1; Solid Stone x1; Blacksmith Hammer tool | 200 | 76,515 |
| 215 | Mithril Frag Bomb | 10514 | Trainer | Mithril Casing x1; Unstable Trigger x1; Solid Blasting Powder x1 | Mithril Bar x2; Solid Stone x1; Blacksmith Hammer tool | 3 | 80,055 |
| 215 | Gnomish Harm Prevention Belt | 10721 | Gnomish Engineering trainer | Dusky Belt x1; Mithril Bar x4; Truesilver Bar x2; Unstable Trigger x1; Aquamarine x2 | Dusky Belt x1; Mithril Bar x5; Truesilver Bar x2; Aquamarine x2 | 1 | 80,055 |
| 220 | Catseye Ultra Goggles | 10501 | Schematic 10603, world drop | Thick Leather x4; Aquamarine x2; Catseye Elixir x1 | same | 1 | 83,675 |
| 220 | Mithril Heavy-bore Rifle | 10510 | Schematic 10604, world drop | Mithril Tube x2; Unstable Trigger x1; Heavy Stock x1; Mithril Bar x6; Citrine x2 | Mithril Bar x9; Heavy Stock x1; Citrine x2; Blacksmith Hammer tool | 1 | 83,675 |
| 225 | Gnomish Rocket Boots | 10724 | Gnomish Engineering trainer | Black Mageweave Boots x1; Mithril Tube x2; Heavy Leather x4; Solid Blasting Powder x8; Gyrochronatom x4 | Black Mageweave Boots x1; Mithril Bar x2; Heavy Leather x4; Solid Stone x8; Gold Bar x4; Blacksmith Hammer tool | 1 | 87,375 |
| 225 | Goblin Rocket Boots | 7189 | Goblin Engineering trainer | Black Mageweave Boots x1; Mithril Tube x2; Heavy Leather x4; Goblin Rocket Fuel x2; Unstable Trigger x1 | Black Mageweave Boots x1; Mithril Bar x3; Heavy Leather x4; Goblin Rocket Fuel x2; Blacksmith Hammer tool | 1 | 87,375 |
| 225 | Parachute Cloak | 10518 | Schematic 10606, world drop | Bolt of Mageweave x4; Shadow Silk x2; Unstable Trigger x1; Solid Blasting Powder x4 | Mageweave Cloth x4; Shadow Silk x2; Mithril Bar x1; Solid Stone x4 | 1 | 87,375 |
| 225 | Spellpower Goggles Xtreme | 10502 | Schematic 10605, world drop | Thick Leather x4; Star Ruby x2 | same | 1 | 87,375 |

## Item representation and effect preparation

### Defensive consumable exception

- **Ice Deflector** — item level 31, required level 21, source item uses charges in vanilla Classic. For RPE, intentionally mirror Flame Deflector rather than literal source absorb semantics: potion-like consumable with `useSpellRef`, self-targeted instant Spell, 10-turn cooldown in cooldown group `potion`, applying an Aura for 3 turns that grants **+50 Frost Resistance** via `f82db71a:jjn0my8k`. Use the same stack behavior as Flame Deflector (`maxStacks = 1`, `refresh_duration`). The inventory item is consumed only after the cast is accepted. This is an explicit project abstraction and is not blocked.

### Explosives

- **Solid Dynamite** — item level 35, common, stack 20, Engineering 175. Source effect deals 213–287 Fire damage in a 5-yard radius. RPE: midpoint `250 Fire`, multi-target 1–5, shared 5-turn `engineering_explosive` cooldown.
- **Iron Grenade** — item level 35, common, stack 10, Engineering 175. Source effect deals 132–218 Fire damage and incapacitates/stuns targets for about 3 seconds, breaking on damage. RPE: midpoint `175 Fire`, multi-target 1–5, one-turn break-on-damage control Aura, shared explosive cooldown.
- **Flash Bomb** — item level 37, required level 27, common, stack 5. Source causes Beasts in the radius to flee for 10 seconds. RPE currently has no creature-family predicate / fear-movement behavior that can reproduce this without affecting non-Beasts, so active behavior is blocked rather than generalized inaccurately.
- **Big Iron Bomb** — item level 43, common, stack 10, Engineering 190. Source effect deals 149–201 Fire damage and incapacitates/stuns targets for about 3 seconds, breaking on damage. RPE: midpoint `175 Fire`, multi-target 1–5, one-turn break-on-damage control Aura, shared explosive cooldown.
- **EZ-Thro Dynamite II** — required level 30, common, stack 20. It is the non-engineer dynamite analogue and should have no Engineering-use condition. RPE: midpoint `250 Fire` from the vanilla 213–287 source range, multi-target 1–5, shared explosive cooldown.
- **Goblin Sapper Charge** — item level 41, common, stack 10, Engineering 205. Source deals 450–750 Fire damage to nearby enemies and 375–625 Fire damage to the user. RPE: midpoint `600 Fire` to enemy multi-target 1–5 plus midpoint `500 Fire` self-damage to the caster, sharing the 5-turn `engineering_explosive` cooldown.
- **Mithril Frag Bomb** — item level 43, common, stack 10; recipe skill 215 (the crafted item itself has a lower Engineering-use threshold). Source effect deals 149–201 Fire damage and incapacitates/stuns for about 2 seconds, breaking on damage. RPE: midpoint `175 Fire`, multi-target 1–5, one-turn break-on-damage control Aura, shared explosive cooldown.

### Guns

- **Mithril Blunderbuss** — item level 41, required level 36, uncommon, bind on equip, source damage 36–68, +5 Agility. RPE: normal Gun with 36–68 Physical damage, Agility +5 and one generic modification slot.
- **Mithril Heavy-bore Rifle** — item level 44, required level 39, uncommon, bind on equip, source damage 41–76 and +14 Ranged Attack Power. RPE: normal Gun with 41–76 Physical damage, RAP +14 and one generic modification slot.

### Ammo

- **Hi-Impact Mithril Slugs** — item level 42, required level 37, stack 200, source +12.5 ranged DPS. Continue the existing RPE ammo abstraction: `itemType = "armor"`, Ammo slot, `ammo`/`bullet` tags, and **+12.5 Ranged Attack Power**. This intentionally follows the project's prior direct ammo-number convention rather than inventing a DPS conversion.

### Wearable armour / goggles

- **Bright-Eye Goggles** — ilvl 35, BoE Cloth Head, 38 Armor, +9 Stamina, +9 Spirit, Engineering 175.
- **Craftsman's Monocle** — ilvl 37, required level 32, BoE Cloth Head, 40 Armor, +15 Intellect, Engineering 185.
- **Fire Goggles** — ilvl 41, BoE Cloth Head, 44 Armor, +17 Fire Resistance, Engineering 205.
- **Goblin Construction Helmet** — ilvl 41, BoP Cloth Head, 44 Armor, +15 Fire Resistance, Engineering 205. Source use absorbs 300–500 Fire damage for one minute; exact absorb is blocked by the current Aura effect model.
- **Goblin Mining Helmet** — ilvl 41, BoP Mail Head, 190 Armor, +15 Stamina, Engineering 205, Equip +5 Mining. There is no packaged Mining skill in the current dataset model, so the +5 Mining bonus is blocked; do not create a Mining dataset merely for this item.
- **Gnomish Goggles** — ilvl 42, BoP Cloth Head, 45 Armor, +9 Agility, +9 Stamina, +9 Spirit, Engineering 210.
- **Gnomish Harm Prevention Belt** — ilvl 43, BoE Leather Waist, 66 Armor, +6 Stamina, Engineering 215. Source use absorbs the next 500 damage and has a 5% malfunction/banish. Exact absorb and banish mechanics are unsupported; author the wearable stats but leave the active behavior blocked.
- **Catseye Ultra Goggles** — ilvl 44, BoE Cloth Head, 47 Armor, Engineering 220, passive increased stealth detection. No current generic stat/condition represents stealth detection, so the passive effect is blocked rather than replaced with an unrelated stat.
- **Gnomish Rocket Boots** — ilvl 45, BoE Cloth Feet, 41 Armor, Engineering 225. Source use provides a large movement-speed boost with malfunction risk. Movement Speed itself exists, but the exact Classic active/failure behavior is not generically modeled; do not invent a substitute.
- **Goblin Rocket Boots** — ilvl 45, BoE Cloth Feet, 41 Armor, Engineering 225. Same preparation decision as Gnomish Rocket Boots: wearable item is implementable, exact active/failure semantics remain blocked.
- **Parachute Cloak** — ilvl 45, BoE Back, 30 Armor, +8 Agility, Engineering 225. Slow-fall is not represented by the turn-combat stat/effect model; implement wearable stats but do not invent a combat substitute.
- **Spellpower Goggles Xtreme** — ilvl 43, BoE Cloth Head, 46 Armor, +21 Spell Power. The source item uses a lower Engineering requirement, while the recipe itself is skill 225; the RPE recipe threshold remains 225 and #262 should preserve the prepared item condition from source data.

All wearable armour receives one generic modification slot unless the live Item conventions at #262 have changed.

## Spell/Aura implementation set for #261

Representable active effects:

1. Ice Deflector — self-targeted instant Spell; applies a 3-turn Aura granting +50 Frost Resistance (`f82db71a:jjn0my8k`); cooldown 10, cooldown group `potion`; unavailable as a learned/action-bar Spell; ignore GCD, matching Flame Deflector.
2. Solid Dynamite — 250 Fire, multi 1–5.
3. Iron Grenade — 175 Fire + one-turn break-on-damage control.
4. Big Iron Bomb — 175 Fire + one-turn break-on-damage control.
5. EZ-Thro Dynamite II — 250 Fire, multi 1–5, no Engineering-use condition.
6. Goblin Sapper Charge — 600 Fire to enemy multi 1–5 plus 500 Fire self-damage to caster.
7. Mithril Frag Bomb — 175 Fire + one-turn break-on-damage control.

Potentially no Spell is needed for passive equipment stats.

Do **not** implement inaccurate substitute effects for Flash Bomb, Goblin Construction Helmet, Gnomish Harm Prevention Belt, Catseye Ultra Goggles, the two Rocket Boots, or Parachute Cloak. Their limitations are recorded below.

## Current-code findings relevant to implementation

- `Recipe.lua` still accepts only `rpe_item` and `tool` inputs; tools are structurally separate from consumed reagents.
- `client_Crafting.lua` still calculates trainer cost from skill level at runtime, indexes `trainer` recipes by skill, checks tools separately, consumes only `rpe_item` inputs, and produces the configured output quantity.
- `client_ItemUse.lua` supports consumables from inventory and weapon/armor use effects from equipped items through `useSpellRef`; inventory consumables are removed only after the cast is accepted, while equipped items are not consumed.
- Current `Aura.lua` supports damage/heal/stat/skill/control/apply-aura/resource effects. Ice Deflector uses the supported stat-Aura abstraction already established by Flame Deflector; absorb/shield support is still absent for unrelated source effects such as Goblin Construction Helmet and Gnomish Harm Prevention Belt.
- Current Item schema supports equipment stats, skill bonuses, slots, modifications, and `useSpellRef`; it does not provide a generic stealth-detection or slow-fall mechanic.
- Dependency discovery follows qualified refs, so #262/#263 must add any newly referenced owner datasets and must not duplicate shared materials inside Engineering.
- Packaged default synchronization remains version-driven and preserves activation state; later implementation issues must increment only datasets they actually modify.

## Source audit

Source verification uses vanilla Classic Engineering recipe/item data. The range boundary is determined by **recipe skill**, not a later/current item-use Engineering requirement. This is why `Mithril Frag Bomb` belongs at recipe skill 215 and `Spellpower Goggles Xtreme` belongs at recipe skill 225, while `Explosive Sheep` (150) and `The Big One` (235) are excluded. Ice Deflector and Goblin Sapper Charge are explicit user-requested inclusions within the `(150,225]` band. Ice Deflector intentionally uses the same RPE resistance-buff abstraction as Flame Deflector instead of reproducing its literal vanilla absorb effect.

## Incomplete / Blocked Items and Recipes

The **23 Item and Recipe identities/source rows are complete** for the focused scope. The following gameplay effects cannot currently be represented exactly and must remain explicit implementation blockers rather than receiving inaccurate substitutes:

| Item | Complete | Missing behavior | Blocker | Smallest follow-up |
| --- | --- | --- | --- | --- |
| Flash Bomb | item/recipe/source effect | fear only Beast targets | no creature-family target predicate/fear movement | generic creature-family condition + fear control behavior |
| Goblin Construction Helmet | wearable stats/recipe | 300–500 Fire absorb | no generic absorb/shield Aura effect | generic school-filtered absorb effect |
| Goblin Mining Helmet | wearable stats/recipe | +5 Mining | no packaged Mining skill | add Mining only if professions are intentionally expanded to include it |
| Gnomish Harm Prevention Belt | wearable stats/recipe | 500 absorb + 5% banish malfunction | no absorb and no generic banish/malfunction package | generic absorb plus probabilistic control side-effect support |
| Catseye Ultra Goggles | wearable stats/recipe | stealth detection | no stealth-detection stat/system | add generic detection stat only if stealth gameplay is introduced |
| Gnomish Rocket Boots | wearable stats/recipe | exact speed boost + malfunction | active/failure semantics are not generically defined | define RPE movement-speed mapping and generic malfunction behavior |
| Goblin Rocket Boots | wearable stats/recipe | exact speed boost + explosion malfunction | active/failure semantics are not generically defined | same |
| Parachute Cloak | wearable stats/recipe | slow fall | no fall/movement-physics model | no change unless non-combat movement effects are introduced |

No Recipe is blocked from being authored solely because its active effect is blocked; #261 should omit inaccurate Spells only for the remaining blocked entries, while #262 can still author their canonical Item metadata without a false `useSpellRef`.
