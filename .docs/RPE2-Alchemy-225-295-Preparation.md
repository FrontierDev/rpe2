# RPE 2 — Classic Alchemy 225–295 Preparation

**Issue:** #215  
**Target branch:** `dev`  
**Canonical Alchemy dataset:** `data/default/professions/alchemy.lua`  
**Alchemy dataset ID:** `d6ffc4e2`  
**Prepared against Alchemy dataset version:** 13  
**Range:** **`(225,295]`** — skill 225 excluded; skill 295 included.

## 1. Purpose and scope

This document is the authoritative implementation source of truth for the vanilla Classic Alchemy recipes requiring **Alchemy >225 and <=295**.

The validated set contains **45 recipes**. It includes:

- trainer recipes;
- vendor and world-drop recipe items;
- Zandalar Tribe reputation recipes;
- Argent Dawn and Timbermaw Hold reputation transmutes;
- special-vendor elemental transmutes;
- direct-use potions;
- long-duration elixirs;
- Stonescale Oil and Ghost Dye intermediates;
- Arcanite and elemental transmutations.

Implementation is split across:

- #216 — item-use Spells and supporting Auras;
- #217 — Items, intermediate outputs and shared materials;
- #218 — Recipes.

No gameplay/data implementation belongs in #215 itself.

---

## 2. Current RPE architecture inspected

This preparation was checked against current `dev`, not against assumptions from #211–#214.

### 2.1 Item-use path

`client/client_ItemUse.lua` continues to use the generic item-use path:

```text
Item.useSpellRef -> generic Spell activation -> Spell components / Auras
```

Inventory consumption occurs only after an item-use cast is accepted. Manual-use effects should therefore continue to be authored as Spells rather than duplicated in Item fields.

### 2.2 Item schema

`core/classes/Item.lua` still supports:

- `itemType = "consumable"`;
- consumable types `potion`, `flask`, `elixir`, `scroll`, `rune`, `enhancement`;
- elixir classes `generic`, `battle`, `guardian`;
- `useSpellRef`;
- embedded `consumableTrait` / `equipmentTrait`;
- normal stats, skill bonuses and level conditions.

### 2.3 Recipe schema

`core/classes/Recipe.lua` still normalizes:

```text
learnMode = always_learned | trainer | book | unavailable
input.kind = rpe_item | tool
```

There is still **no recipe/transmutation cooldown field**.

`client/client_Crafting.lua` still calculates trainer price as:

```text
floor(75 + requiredSkillLevel * 28 + requiredSkillLevel^2 * 1.6)
```

Relevant values:

| Skill | trainerCostCopper |
|---:|---:|
| 230 | 91155 |
| 235 | 95015 |
| 240 | 98955 |
| 245 | 102975 |
| 250 | 107075 |
| 255 | 111255 |
| 260 | 115515 |
| 265 | 119855 |
| 270 | 124275 |
| 275 | 128775 |
| 280 | 133355 |
| 285 | 138015 |
| 290 | 142755 |
| 295 | 147575 |

`learnMode` remains authoritative for trainer indexing. The serialized cost can still be present on non-trainer recipes without making them trainer recipes.

### 2.4 Dependency limitation

The current dependency recomputation path does not use Recipe input/output refs as a complete cross-dataset dependency source. #218 must re-check this before implementation. Do not broaden #218 into a dependency redesign if active packaged datasets already make the recipes functional.

### 2.5 Generic combat/stat capability relevant to this slice

Current generic Spell/Aura/Trait data can cleanly represent:

- direct healing;
- fixed resource restoration;
- direct Rage restoration;
- temporary flat stat Auras;
- long-duration stat Traits;
- Armor changes;
- primary-stat changes;
- generic Spell Power;
- the Core physical critical-hit stats;
- normal potion cooldowns and shared cooldown groups.

Current Core refs needed here include:

| Meaning | Ref |
|---|---|
| Alchemy | `f82db71a:pdyzyudy` |
| Armor | `f82db71a:v42albuv` |
| Strength | `f82db71a:zfqm8dxp` |
| Agility | `f82db71a:xqz0daz2` |
| Stamina | `f82db71a:ygjno50i` |
| Spirit | `f82db71a:kec9rhli` |
| Intellect | `f82db71a:75y3a8ib` |
| Spell Power | `f82db71a:7t7xgzcx` |
| Mana | `f82db71a:4c8mfm99` |
| Rage | `f82db71a:e2tfklq7` |
| Melee Crit. Chance | `f82db71a:jslmczbi` |
| Ranged Crit. Chance | `f82db71a:fercjhm5` |

The engine still does **not** cleanly provide the source mechanics needed for:

- invisibility/tracking/remote-vision states;
- school-specific absorb pools;
- physical immunity;
- creature-type-specific attack power;
- school-specific spell-power bonuses;
- timed self-sleep plus over-time dual health/mana restoration;
- category dispels / stun-and-snare cleansing plus immunity;
- reactive proc debuffs like Gift of Arthas;
- per-resource regeneration-rate Traits such as mana-per-5;
- recipe/transmute cooldowns.

Blocked effects must not be replaced with misleading stat approximations.

---

## 3. Vanilla/version-drift decisions

### 3.1 Vanilla Classic is authoritative

Use vanilla-era recipe identity, skill requirement, acquisition, reagents, quantities, output quantity, item level, required level, stack size and effect.

Primary source family used for the preparation:

- Wowhead Classic;
- ClassicDB / legacy vanilla database records;
- WoW Classic Database;
- historical comments where patch/version changes are explicitly documented.

Modern/TBC/Cata/SoD data is used only to identify drift, not as the canonical recipe definition.

### 3.2 Plaguebloom, not later Sorrowmoss naming

Vanilla high-level recipes in this band use **Plaguebloom**. Later database versions may present the same item slot/reagent as Sorrowmoss. #217/#218 must author/use the vanilla name **Plaguebloom**.

Affected recipes include:

- Elixir of the Sages;
- Elixir of Brute Force;
- Mageblood Potion;
- Elixir of the Mongoose;
- Purification Potion;
- Major Troll's Blood Potion.

### 3.3 Superior Mana Potion acquisition drift

In vanilla, **Recipe: Superior Mana Potion** is vendor-sold and therefore maps to `learnMode = "book"`.

It was changed to trainer-taught in patch 2.0. That later behavior must not be imported into this vanilla slice.

### 3.4 Stonescale Oil vial drift

Vanilla Stonescale Oil is:

```text
Stonescale Eel + Leaded Vial
```

Use the existing Alchemy Leaded Vial ref:

```text
d6ffc4e2:jdxdj7eh
```

Do not substitute a later Crystal Vial recipe.

### 3.5 Greater Stoneshield Potion quantity drift

Vanilla Greater Stoneshield Potion at skill 280 uses:

```text
3 Stonescale Oil
1 Thorium Ore
1 Crystal Vial
```

The **3 Stonescale Oil** quantity is deliberate and must be preserved.

### 3.6 Living Action Potion vanilla recipe

Vanilla/Classic phase-4 recipe:

```text
2 Icecap
2 Mountain Silversage
2 Heart of the Wild
1 Crystal Vial
```

Later versions changed the reagent list. Preserve the vanilla four-input recipe above.

### 3.7 Greater Holy Protection Potion excluded

Although modern Classic-family databases may expose recipe data for Greater Holy Protection Potion, the recipe was not obtainable by normal vanilla players. It must **not** be included in this vanilla `(225,295]` implementation.

The five valid greater protection potions in this slice are:

- Greater Arcane Protection Potion;
- Greater Fire Protection Potion;
- Greater Frost Protection Potion;
- Greater Nature Protection Potion;
- Greater Shadow Protection Potion.

### 3.8 Skill-300 recipes excluded

Do not add any recipe requiring 300 Alchemy under this slice, including the level-cap flask recipes and other 300-skill crafts. This document stops at 295.

---

## 4. Existing packaged refs and material ownership

### 4.1 Existing Alchemy refs reused

| Item | Ref |
|---|---|
| Goldthorn | `d6ffc4e2:onr6v77u` |
| Purple Lotus | `d6ffc4e2:y3a574bb` |
| Sungrass | `d6ffc4e2:uvldarfw` |
| Firebloom | `d6ffc4e2:uz4jtdrb` |
| Fire Oil | `d6ffc4e2:q5f2o7ze` |
| Shadow Oil | `d6ffc4e2:e7s2o6tz` |
| Khadgar's Whisker | `d6ffc4e2:bne5607a` |
| Leaded Vial | `d6ffc4e2:jdxdj7eh` |
| Crystal Vial | `d6ffc4e2:804x8qak` |
| Philosopher's Stone | `d6ffc4e2:y9p4s8nt` |

### 4.2 Existing Misc ref reused

| Item | Ref |
|---|---|
| Heart of the Wild | `3eb7e9bb:w2plwren` |

### 4.3 Existing Enchanting reagents reused

The Enchanting dataset already owns the elemental/essence reagent family. Reuse it instead of duplicating these items.

| Item | Ref |
|---|---|
| Dream Dust | `732368d4:gvva5lmf` |
| Essence of Fire | `732368d4:50qj8dzw` |
| Essence of Water | `732368d4:7z1lti71` |
| Essence of Earth | `732368d4:tfwg197j` |
| Essence of Air | `732368d4:fiea7e66` |
| Essence of Undeath | `732368d4:xtnbjwzj` |
| Living Essence | `732368d4:lxqnh3pp` |
| Elemental Earth | `732368d4:ku9j8vhw` |
| Elemental Air | `732368d4:2616xh4v` |
| Elemental Water | `732368d4:vlwvpmfx` |
| Elemental Fire | `732368d4:sclalidn` |

This explicitly carries forward the user's #213 corrections: do not create Small Flame Sac/Ichor equivalents in Misc, and do not create a Mining dataset.

### 4.4 New Alchemy-owned herbs/materials required

The following were not found in current packaged data and should be added to canonical Alchemy data by #217 if still absent:

| Material | Vanilla item ID | Ownership |
|---|---:|---|
| Arthas' Tears | 8836 | Alchemy herb |
| Blindweed | 8839 | Alchemy herb |
| Ghost Mushroom | 8845 | Alchemy herb |
| Gromsblood | 8846 | Alchemy herb |
| Dreamfoil | 13463 | Alchemy herb |
| Plaguebloom | 13466 | Alchemy herb |
| Golden Sansam | 13464 | Alchemy herb |
| Mountain Silversage | 13465 | Alchemy herb |
| Icecap | 13467 | Alchemy herb |

### 4.5 Fishing-owned material required

`Stonescale Eel` is absent from packaged data.

#217 should add it to the existing Fishing dataset if still absent:

| Material | Vanilla item ID | Ownership |
|---|---:|---|
| Stonescale Eel | 13422 | Fishing |

### 4.6 Blacksmithing-owned metals required

No standalone Mining dataset is permitted. The following are absent and should be added to the existing Blacksmithing dataset if still absent:

| Material | Vanilla item ID | Role |
|---|---:|---|
| Thorium Ore | 10620 | Greater Stoneshield input |
| Thorium Bar | 12359 | Arcanite transmute input |
| Arcanite Bar | 12360 | Arcanite transmute output |

`Arcanite Bar` remains a shared metal owned by Blacksmithing even though Alchemy produces it.

### 4.7 Arcane Crystal ownership

`Arcane Crystal` is absent from packaged data. It is a shared magical reagent rather than an Alchemy herb/output and should be added to **Enchanting** if still absent:

| Material | Vanilla item ID | Ownership |
|---|---:|---|
| Arcane Crystal | 12363 | Enchanting reagent |

Do not create a Mining dataset for it.

### 4.8 Purple Dye ownership

`Purple Dye` is absent from packaged data. It should be added to **Tailoring** if still absent, because it is a shared dye/vendor reagent rather than an Alchemy herb:

| Material | Vanilla item ID | Ownership |
|---|---:|---|
| Purple Dye | 4342 | Tailoring |

### 4.9 Rejected fallback materials

Do not introduce or reuse the following as generic substitutions for this range:

- Small Flame Sac;
- Ichor of Undeath;
- Volatile Rum;
- Black Vitriol;
- Large Fang.

Every recipe below has a fully resolved intended material plan without them.

---

## 5. Authoritative recipe inventory — 45 recipes

Every recipe produces quantity **1** and uses:

```text
skillRef = f82db71a:pdyzyudy
```

`book` is used for recipe items, vendor recipes, world drops, reputation recipes and other non-trainer learned recipes because RPE has no separate quest/reputation/vendor learn mode.

| Skill | Recipe/output | Acquisition | RPE learnMode | Exact vanilla inputs | Cost |
|---:|---|---|---|---|---:|
| 230 | Elixir of Detect Undead | Trainer | `trainer` | Arthas' Tears; Crystal Vial | 91155 |
| 230 | Dreamless Sleep Potion | Trainer | `trainer` | 3 Purple Lotus; Crystal Vial | 91155 |
| 235 | Arcane Elixir | Trainer | `trainer` | Blindweed; Goldthorn; Crystal Vial | 95015 |
| 235 | Elixir of Greater Intellect | Trainer | `trainer` | Blindweed; Khadgar's Whisker; Crystal Vial | 95015 |
| 235 | Invisibility Potion | World-drop recipe | `book` | Ghost Mushroom; Sungrass; Crystal Vial | 95015 |
| 240 | Elixir of Greater Agility | Trainer | `trainer` | Sungrass; Goldthorn; Crystal Vial | 98955 |
| 240 | Gift of Arthas | Drop recipe | `book` | Arthas' Tears; Blindweed; Crystal Vial | 98955 |
| 240 | Elixir of Dream Vision | World-drop recipe | `book` | 3 Purple Lotus; Crystal Vial | 98955 |
| 245 | Ghost Dye | Vendor recipe | `book` | 2 Ghost Mushroom; Purple Dye; Crystal Vial | 102975 |
| 245 | Elixir of Giants | World-drop recipe | `book` | Sungrass; Gromsblood; Crystal Vial | 102975 |
| 250 | Stonescale Oil | Trainer | `trainer` | Stonescale Eel; Leaded Vial | 107075 |
| 250 | Elixir of Detect Demon | Trainer | `trainer` | 2 Gromsblood; Crystal Vial | 107075 |
| 250 | Elixir of Greater Firepower | World-drop recipe | `book` | 3 Fire Oil; 3 Firebloom; Crystal Vial | 107075 |
| 250 | Elixir of Shadow Power | Vendor recipe | `book` | 3 Ghost Mushroom; Crystal Vial | 107075 |
| 250 | Elixir of Demonslaying | Vendor recipe | `book` | Gromsblood; Ghost Mushroom; Crystal Vial | 107075 |
| 250 | Limited Invulnerability Potion | World-drop recipe | `book` | 2 Blindweed; Ghost Mushroom; Crystal Vial | 107075 |
| 255 | Mighty Rage Potion | World-drop recipe | `book` | 3 Gromsblood; Crystal Vial | 111255 |
| 260 | Superior Mana Potion | Vendor recipe in vanilla | `book` | 2 Sungrass; 2 Blindweed; Crystal Vial | 115515 |
| 265 | Elixir of Superior Defense | Vendor recipe | `book` | 2 Stonescale Oil; Sungrass; Crystal Vial | 119855 |
| 270 | Elixir of the Sages | World-drop recipe | `book` | Dreamfoil; 2 Plaguebloom; Crystal Vial | 124275 |
| 275 | Transmute: Arcanite | Alchemist Pestlezugg vendor recipe | `book` | Thorium Bar; Arcane Crystal; Philosopher's Stone (`tool`) | 128775 |
| 275 | Major Healing Potion | Vendor recipe | `book` | 2 Golden Sansam; Mountain Silversage; Crystal Vial | 128775 |
| 275 | Elixir of Brute Force | World-drop recipe | `book` | 2 Gromsblood; 2 Plaguebloom; Crystal Vial | 128775 |
| 275 | Greater Dreamless Sleep Potion | Zandalar Tribe Friendly | `book` | 2 Dreamfoil; Golden Sansam; Crystal Vial | 128775 |
| 275 | Mageblood Potion | Zandalar Tribe Revered | `book` | Dreamfoil; 2 Plaguebloom; Crystal Vial | 128775 |
| 275 | Transmute: Air to Fire | Argent Dawn Honored | `book` | Essence of Air; Philosopher's Stone (`tool`) | 128775 |
| 275 | Transmute: Earth to Water | Timbermaw Hold Friendly | `book` | Essence of Earth; Philosopher's Stone (`tool`) | 128775 |
| 275 | Transmute: Fire to Earth | Plugger Spazzring vendor | `book` | Essence of Fire; Philosopher's Stone (`tool`) | 128775 |
| 275 | Transmute: Water to Air | Magnus Frostwake vendor | `book` | Essence of Water; Philosopher's Stone (`tool`) | 128775 |
| 275 | Transmute: Undeath to Water | World-drop recipe | `book` | Essence of Undeath; Philosopher's Stone (`tool`) | 128775 |
| 275 | Transmute: Water to Undeath | World-drop recipe | `book` | Essence of Water; Philosopher's Stone (`tool`) | 128775 |
| 275 | Transmute: Life to Earth | World-drop recipe | `book` | Living Essence; Philosopher's Stone (`tool`) | 128775 |
| 275 | Transmute: Earth to Life | World-drop recipe | `book` | Essence of Earth; Philosopher's Stone (`tool`) | 128775 |
| 280 | Elixir of the Mongoose | World-drop recipe | `book` | 2 Mountain Silversage; 2 Plaguebloom; Crystal Vial | 133355 |
| 280 | Greater Stoneshield Potion | World-drop recipe | `book` | 3 Stonescale Oil; Thorium Ore; Crystal Vial | 133355 |
| 285 | Greater Arcane Elixir | World-drop recipe | `book` | 3 Dreamfoil; Mountain Silversage; Crystal Vial | 138015 |
| 285 | Living Action Potion | Zandalar Tribe Exalted | `book` | 2 Icecap; 2 Mountain Silversage; 2 Heart of the Wild; Crystal Vial | 138015 |
| 285 | Purification Potion | World-drop recipe | `book` | 2 Icecap; 2 Plaguebloom; Crystal Vial | 138015 |
| 290 | Major Troll's Blood Potion | Zandalar Tribe Honored | `book` | Gromsblood; 2 Plaguebloom; Crystal Vial | 142755 |
| 290 | Greater Arcane Protection Potion | Drop recipe | `book` | Dream Dust; Dreamfoil; Crystal Vial | 142755 |
| 290 | Greater Fire Protection Potion | Drop recipe | `book` | Elemental Fire; Dreamfoil; Crystal Vial | 142755 |
| 290 | Greater Frost Protection Potion | Drop recipe | `book` | Elemental Water; Dreamfoil; Crystal Vial | 142755 |
| 290 | Greater Nature Protection Potion | Drop recipe | `book` | Elemental Earth; Dreamfoil; Crystal Vial | 142755 |
| 290 | Greater Shadow Protection Potion | Drop recipe | `book` | Shadow Oil; Dreamfoil; Crystal Vial | 142755 |
| 295 | Major Mana Potion | BoP recipe; Magnus Frostwake vendor / Darkmaster Gandling drop | `book` | 3 Dreamfoil; 2 Icecap; Crystal Vial | 147575 |

### 5.1 Boundary validation

- No skill-225 recipe is present.
- Skill 295 is represented by Major Mana Potion.
- No recipe requiring >295 is present.
- Greater Holy Protection Potion is deliberately excluded as non-obtainable vanilla player content.

---

## 6. Transmute behavior and cooldowns

All eight skill-275 transmute recipes require the existing Philosopher's Stone as a reusable tool:

```lua
{
    kind = "tool",
    itemRef = "d6ffc4e2:y9p4s8nt",
    quantity = 1,
}
```

### 6.1 Source cooldowns

Vanilla source behavior includes a shared transmute cooldown family:

- **Transmute: Arcanite** — historically **48 hours / 2 days**;
- elemental/essence transmutes — generally **24 hours / 1 day**.

The current Recipe schema does not encode this. #218 should implement the canonical recipe/tool requirements but must **not fabricate cooldown behavior**. Record the limitation in the completion note unless a separate generic cooldown feature exists by then.

---

## 7. Item-use Spell/Aura preparation for #216

### 7.1 Shared item-only Spell convention

For representable manual-use potions:

```text
castTime = 0
learnMode = unavailable
ignoreGCD = true
triggersGCD = false
cooldown = 10
cooldownGroup = potion
description = ""
target = caster/self
```

The RPE ten-turn potion cooldown is the established project convention and is intentionally not a literal conversion of WoW's two-minute potion cooldown.

### 7.2 Directly representable item-use Spells

#### Mighty Rage Potion

Vanilla effect:

```text
Restores 45–75 Rage and increases Strength by 60 for 20 sec.
```

RPE representation:

- fixed **60 Rage** (midpoint);
- apply supporting Aura **Mighty Rage**;
- Aura: +60 Strength;
- Aura duration: **1 RPE turn** (source effect is only 20 sec; 1 turn is the minimum useful event duration);
- normal 10-turn potion cooldown.

#### Superior Mana Potion

Vanilla effect: restores roughly 900–1500 mana.

RPE representation:

- fixed **1200 Mana** midpoint;
- normal potion cooldown.

#### Major Healing Potion

Vanilla effect: restores 1050–1750 health.

RPE representation:

- `baseHealing = 1400` midpoint;
- current generic healing variance remains authoritative;
- normal potion cooldown.

#### Greater Stoneshield Potion

Vanilla effect: +2000 Armor for 2 minutes.

RPE representation:

- apply supporting Aura **Greater Stoneshield**;
- +2000 Armor using `f82db71a:v42albuv`;
- duration **7 RPE turns**.

Duration rationale: the existing project convention maps 3 minutes to 10 turns; 2 minutes is 6.67 turns, rounded to 7.

#### Major Mana Potion

Vanilla effect: restores 1350–2250 mana.

RPE representation:

- fixed **1800 Mana** midpoint;
- normal potion cooldown.

### 7.3 #216 expected direct-use inventory

Expected data-only #216 additions from this preparation:

- **5 item-use Spells**;
- **2 supporting Auras** (Mighty Rage, Greater Stoneshield).

No other item in this band should receive a manual-use Spell unless #216 discovers that current generic capabilities have materially changed.

---

## 8. Long-duration elixir Trait preparation

These effects fit the existing `consumableTrait` model and should not be implemented as fake manual-use Spells.

| Item | Elixir class | RPE Trait representation |
|---|---|---|
| Arcane Elixir | battle | +20 Spell Power |
| Elixir of Greater Intellect | guardian | +25 Intellect |
| Elixir of Greater Agility | battle | +25 Agility |
| Elixir of Giants | battle | +25 Strength |
| Elixir of Superior Defense | guardian | +450 Armor |
| Elixir of the Sages | guardian | +18 Intellect, +18 Spirit |
| Elixir of Brute Force | generic | +18 Strength, +18 Stamina |
| Elixir of the Mongoose | battle | +25 Agility, +2% Melee Crit Chance, +2% Ranged Crit Chance |
| Major Troll's Blood Potion | guardian | **+20 Spirit project approximation** |

### 8.1 Elixir of the Mongoose critical-hit mapping

The source effect gives +25 Agility and +2% critical-hit chance. RPE has separate physical crit stats:

```text
Melee Crit. Chance  = f82db71a:jslmczbi
Ranged Crit. Chance = f82db71a:fercjhm5
```

Apply +2 to both so the physical critical-hit bonus is not lost.

### 8.2 Major Troll's Blood Potion approximation

Vanilla: regenerate 20 health every 5 sec for 1 hour.

The project already represents Troll's Blood regeneration through Spirit:

- Strong Troll's Blood -> +6 Spirit for 6 health/5 sec;
- Mighty Troll's Blood -> +12 Spirit for 12 health/5 sec.

Continue that project mapping proportionally:

```text
Major Troll's Blood Potion -> +20 Spirit
```

This is explicitly an RPE simplification, not a literal WoW mechanic.

---

## 9. Unsupported / deliberately non-represented effects

The Item metadata/recipe should still be implemented where applicable, but **no misleading `useSpellRef`** should be attached.

| Item | Vanilla behavior | Decision / blocker |
|---|---|---|
| Elixir of Detect Undead | Tracks nearby undead | No tracking/detection state |
| Dreamless Sleep Potion | Sleeps user while restoring 1200 health/mana over time | Timed self-sleep + dual over-time restoration unsupported |
| Invisibility Potion | Invisibility | No invisibility state |
| Gift of Arthas | +10 Shadow resistance plus reactive disease/debuff proc when struck | Reactive proc/debuff mechanic not cleanly supported; do not partial-fake |
| Elixir of Dream Vision | Dream/remote vision | No remote-vision/camera mechanic |
| Elixir of Detect Demon | Tracks demons | No tracking/detection state |
| Elixir of Greater Firepower | +40 Fire spell damage | Fire-only spell-power stat missing; do not generalize silently |
| Elixir of Shadow Power | +40 Shadow spell damage | Shadow-only spell-power stat missing; do not generalize silently |
| Elixir of Demonslaying | Attack power versus demons | Creature-type-specific attack-power modifier missing |
| Limited Invulnerability Potion | Physical damage immunity | Immunity/absorb mechanic missing |
| Greater Dreamless Sleep Potion | Sleeps user while restoring health/mana over time | Same blocker as Dreamless Sleep |
| Mageblood Potion | +12 mana per 5 sec | No clean consumable Trait for per-resource regeneration rate; do not substitute Spirit without approval |
| Living Action Potion | Removes stun/movement impairing and grants temporary immunity | Category cleanse + control-immunity model missing |
| Purification Potion | Removes Curse, Disease and Poison | Category dispel model missing |
| Greater Arcane Protection Potion | Arcane absorb | School-specific absorb pool missing |
| Greater Fire Protection Potion | Fire absorb | School-specific absorb pool missing |
| Greater Frost Protection Potion | Frost absorb | School-specific absorb pool missing |
| Greater Nature Protection Potion | Nature absorb | School-specific absorb pool missing |
| Greater Shadow Protection Potion | Shadow absorb | School-specific absorb pool missing |

### 9.1 Mageblood is not a Troll's Blood analogue

Do **not** map Mageblood to Spirit merely because Major Troll's Blood uses a Spirit proxy. Mageblood modifies mana regeneration specifically; a generic Spirit conversion would change unrelated resource behavior and is not an approved project convention.

---

## 10. Crafted output Item metadata for #217

All ordinary potions/elixirs in this table are common quality and stack to 5 unless stated otherwise. Icon values use the Classic inventory icon basename; #217 should serialize them as `interface/icons/<name>.blp`.

| Output | WoW ID | ilvl | Req. level | Quality / stack | Item classification | Icon | Intended RPE behavior |
|---|---:|---:|---:|---|---|---|---|
| Elixir of Detect Undead | 9154 | 46 | 36 | common / 5 | consumable elixir, generic | `inv_potion_53` | no effect; tracking blocker |
| Dreamless Sleep Potion | 12190 | 45 | 35 | common / 5 | consumable potion | `inv_potion_83` | no effect; sleep/HoT/Mana-over-time blocker |
| Arcane Elixir | 9155 | 47 | 37 | common / 5 | consumable elixir, battle | `inv_potion_30` | Trait +20 Spell Power |
| Elixir of Greater Intellect | 9179 | 47 | 37 | common / 5 | consumable elixir, guardian | `inv_potion_10` | Trait +25 Intellect |
| Invisibility Potion | 9172 | 47 | 37 | common / 5 | consumable potion | `inv_potion_18` | no effect; invisibility blocker |
| Elixir of Greater Agility | 9187 | 48 | 38 | common / 5 | consumable elixir, battle | `inv_potion_93` | Trait +25 Agility |
| Gift of Arthas | 9088 | 48 | 38 | common / 5 | consumable elixir, guardian | `inv_potion_28` | no partial effect; reactive-proc blocker |
| Elixir of Dream Vision | 9197 | 48 | 38 | common / 5 | consumable elixir, generic | `inv_potion_14` | no effect; remote-vision blocker |
| Ghost Dye | 9210 | 49 | — | common / 10 | material | `inv_poison_mindnumbing` | material/intermediate |
| Elixir of Giants | 9206 | 48 | 38 | common / 5 | consumable elixir, battle | `inv_potion_61` | Trait +25 Strength |
| Stonescale Oil | 13423 | 50 | — | common / 20 | material / enhancement intermediate | `inv_potion_68` | recipe intermediate; no fake use Spell |
| Elixir of Detect Demon | 9233 | 50 | 40 | common / 5 | consumable elixir, generic | `inv_potion_53` | no effect; tracking blocker |
| Elixir of Greater Firepower | 21546 | 50 | 40 | common / 5 | consumable elixir, battle | `inv_potion_60` | no effect; Fire-only SP blocker |
| Elixir of Shadow Power | 9264 | 50 | 40 | common / 5 | consumable elixir, battle | `inv_potion_46` | no effect; Shadow-only SP blocker |
| Elixir of Demonslaying | 9224 | 50 | 40 | common / 5 | consumable elixir, battle | `inv_potion_27` | no effect; creature-specific AP blocker |
| Limited Invulnerability Potion | 3387 | 50 | 45 | common / 5 | consumable potion | `inv_potion_62` | no effect; physical-immunity blocker |
| Mighty Rage Potion | 13442 | 51 | 46 | common / 5 | consumable potion | `inv_potion_41` | #216 Spell: 60 Rage + Strength Aura |
| Superior Mana Potion | 13443 | 51 | 41 | common / 5 | consumable potion | `inv_potion_74` | #216 Spell: 1200 Mana |
| Elixir of Superior Defense | 13445 | 53 | 43 | common / 5 | consumable elixir, guardian | `inv_potion_66` | Trait +450 Armor |
| Elixir of the Sages | 13447 | 54 | 44 | common / 5 | consumable elixir, guardian | `inv_potion_29` | Trait +18 Intellect/+18 Spirit |
| Major Healing Potion | 13446 | 55 | 45 | common / 5 | consumable potion | `inv_potion_54` | #216 Spell: heal midpoint 1400 |
| Elixir of Brute Force | 13453 | 55 | 45 | common / 5 | consumable elixir, generic | `inv_potion_40` | Trait +18 Strength/+18 Stamina |
| Greater Dreamless Sleep Potion | 20002 | 60 | 55 | common / 5 | consumable potion | `inv_potion_83` | no effect; sleep/over-time blocker |
| Mageblood Potion | 20007 | 50 | 40 | common / 5 | consumable potion/elixir-style long buff | `inv_potion_45` | no effect; mana-regeneration blocker |
| Elixir of the Mongoose | 13452 | 56 | 46 | common / 5 | consumable elixir, battle | `inv_potion_32` | Trait +25 Agility/+2 melee crit/+2 ranged crit |
| Greater Stoneshield Potion | 13455 | 56 | 46 | common / 5 | consumable potion | `inv_potion_69` | #216 Armor Aura |
| Greater Arcane Elixir | 13454 | 57 | 47 | common / 5 | consumable elixir, battle | `inv_potion_25` | see note below |
| Living Action Potion | 20008 | 57 | 47 | common / 5 | consumable potion | `inv_potion_07` | no effect; cleanse/immunity blocker |
| Purification Potion | 13462 | 57 | 47 | common / 5 | consumable potion | `inv_potion_31` | no effect; category-dispel blocker |
| Major Troll's Blood Potion | 20004 | 58 | 53 | common / 5 | consumable elixir, guardian | `inv_potion_80` | Trait +20 Spirit project proxy |
| Greater Arcane Protection Potion | 13461 | 58 | 48 | common / 5 | consumable potion | `inv_potion_83` | no effect; Arcane absorb blocker |
| Greater Fire Protection Potion | 13457 | 58 | 48 | common / 5 | consumable potion | `inv_potion_24` | no effect; Fire absorb blocker |
| Greater Frost Protection Potion | 13456 | 58 | 48 | common / 5 | consumable potion | `inv_potion_20` | no effect; Frost absorb blocker |
| Greater Nature Protection Potion | 13458 | 58 | 48 | common / 5 | consumable potion | `inv_potion_22` | no effect; Nature absorb blocker |
| Greater Shadow Protection Potion | 13459 | 58 | 48 | common / 5 | consumable potion | `inv_potion_23` | no effect; Shadow absorb blocker |
| Major Mana Potion | 13444 | 59 | 49 | common / 5 | consumable potion | `inv_potion_76` | #216 Spell: 1800 Mana |

### 10.1 Greater Arcane Elixir representation

Vanilla Greater Arcane Elixir increases spell damage by 35. This maps cleanly to the existing generic Spell Power stat:

```text
consumableTrait: +35 Spell Power
consumableElixirType = battle
```

This is a generic all-spell-damage source effect, unlike Greater Firepower and Shadow Power, so no school-specific approximation is required.

### 10.2 External transmute output metadata

These are shared materials and should **not** be duplicated in Alchemy:

| Output | WoW ID | ilvl | Req. level | Quality / stack | Owner | RPE behavior |
|---|---:|---:|---:|---|---|---|
| Arcanite Bar | 12360 | 55 | — | common / 20 | Blacksmithing | material/transmute output |
| Essence of Fire | 7078 | 55 | — | existing Enchanting material | Enchanting | transmute input/output |
| Essence of Water | 7080 | 55 | — | existing Enchanting material | Enchanting | transmute input/output |
| Essence of Earth | 7076 | 55 | — | existing Enchanting material | Enchanting | transmute input/output |
| Essence of Air | 7082 | 55 | — | existing Enchanting material | Enchanting | transmute input/output |
| Essence of Undeath | 12808 | 55 | — | existing Enchanting material | Enchanting | transmute input/output |
| Living Essence | 12803 | 55 | — | existing Enchanting material | Enchanting | transmute input/output |

Use the existing Enchanting records/refs rather than replacing their current packaged stack/quality metadata merely to imitate source-game stacks under this Alchemy issue.

---

## 11. New reagent metadata notes for #217

#217 should use canonical vanilla item names/icons for newly authored materials and preserve the owning-dataset conventions above.

### 11.1 Alchemy herbs

All are normal tradeable material Items with no combat use behavior:

- Arthas' Tears — item 8836;
- Blindweed — item 8839;
- Ghost Mushroom — item 8845;
- Gromsblood — item 8846;
- Dreamfoil — item 13463;
- Golden Sansam — item 13464;
- Mountain Silversage — item 13465;
- Plaguebloom — item 13466;
- Icecap — item 13467.

These should follow the current Alchemy herb material conventions (`allowWowConversion`, material typing, stackable, no `useSpellRef`).

### 11.2 Cross-profession materials

- Stonescale Eel item 13422 -> Fishing.
- Purple Dye item 4342 -> Tailoring.
- Thorium Ore item 10620 -> Blacksmithing.
- Thorium Bar item 12359 -> Blacksmithing.
- Arcanite Bar item 12360 -> Blacksmithing.
- Arcane Crystal item 12363 -> Enchanting.

Before writing #217, re-search live packaged data so a concurrently-added canonical record is reused rather than duplicated.

---

## 12. Acquisition notes for downstream implementation

Important non-trainer mappings:

- Invisibility Potion — world-drop recipe item.
- Gift of Arthas — dropped recipe.
- Ghost Dye — vendor recipe.
- Elixir of Giants — world-drop recipe.
- Elixir of Greater Firepower — world-drop recipe.
- Elixir of Shadow Power — vendor recipe.
- Elixir of Demonslaying — vendor recipe.
- Limited Invulnerability Potion — world-drop recipe.
- Mighty Rage Potion — world-drop recipe.
- Superior Mana Potion — **vendor recipe in vanilla**.
- Elixir of Superior Defense — vendor recipe.
- Elixir of the Sages — world-drop recipe.
- Transmute: Arcanite — Alchemist Pestlezugg vendor recipe.
- Major Healing Potion — vendor recipe.
- Elixir of Brute Force — world-drop recipe.
- Greater Dreamless Sleep Potion — Zandalar Tribe Friendly.
- Mageblood Potion — Zandalar Tribe Revered.
- Transmute: Air to Fire — Argent Dawn Honored.
- Transmute: Earth to Water — Timbermaw Hold Friendly.
- Transmute: Fire to Earth — Plugger Spazzring vendor.
- Transmute: Water to Air — Magnus Frostwake vendor.
- Undeath/Water, Water/Undeath, Life/Earth, Earth/Life transmutes — world-drop recipes.
- Elixir of the Mongoose — world-drop recipe.
- Greater Stoneshield Potion — world-drop recipe.
- Greater Arcane Elixir — world-drop recipe.
- Living Action Potion — Zandalar Tribe Exalted.
- Purification Potion — world-drop recipe in vanilla; later versions trained it.
- Major Troll's Blood Potion — Zandalar Tribe Honored.
- five greater protection recipes — drop recipes.
- Major Mana Potion recipe — bind-on-pickup; Magnus Frostwake vendor / Darkmaster Gandling drop.

All of these map to `learnMode = "book"` under current RPE semantics.

---

## 13. Expected implementation inventory

### #216

Expected:

- 5 item-use Spells;
- 2 supporting Auras;
- Alchemy dataset version bump only;
- no Item or Recipe records.

### #217

Expected Alchemy-owned outputs:

- all potion/elixir/intermediate output Items in section 10 except externally-owned transmute outputs;
- Stonescale Oil and Ghost Dye;
- nine new Alchemy herb materials;
- exact `useSpellRef`s from #216;
- long-duration Traits from section 8.

Expected cross-dataset additions if still absent:

- Fishing: Stonescale Eel;
- Tailoring: Purple Dye;
- Blacksmithing: Thorium Ore, Thorium Bar, Arcanite Bar;
- Enchanting: Arcane Crystal.

Do not create a Mining dataset and do not duplicate existing Enchanting elemental/essence records.

### #218

Expected:

- exactly **45** recipes;
- no skill 225 recipe;
- one skill 295 recipe;
- no >295 recipe;
- eight skill-275 transmutes with Philosopher's Stone `tool` input;
- source cooldown limitation documented, not faked.

---

## 14. Deterministic validation checklist

Before #215 is considered complete:

- [x] full `(225,295]` inventory collated;
- [x] 45 recipes identified;
- [x] skill 225 excluded;
- [x] skill 295 included;
- [x] no >295 recipe included;
- [x] trainer/vendor/drop/reputation/special acquisition resolved;
- [x] exact reagent quantities resolved;
- [x] vanilla Plaguebloom naming preserved;
- [x] Superior Mana vendor/trainer version drift resolved;
- [x] Stonescale Oil Leaded Vial version resolved;
- [x] Greater Stoneshield 3-oil quantity resolved;
- [x] Living Action vanilla reagent set resolved;
- [x] Greater Holy Protection excluded as non-obtainable vanilla content;
- [x] transmute tool and source cooldown limitations documented;
- [x] item-use effects classified as direct/Aura/Trait/blocked;
- [x] no unsupported mechanic silently approximated;
- [x] elemental/essence refs resolved to Enchanting;
- [x] Elemental Fire resolved as `732368d4:sclalidn`;
- [x] no standalone Mining dataset proposed;
- [x] cross-profession material ownership resolved;
- [x] current trainer-cost formula re-read from live code;
- [x] current Recipe input/tool semantics re-read from live code.

---

## 15. Downstream source-of-truth rule

#216, #217 and #218 should treat this document as authoritative for:

- recipe identity and range membership;
- vanilla acquisition mode;
- exact reagent quantities;
- explicit source-era naming/version choices;
- material ownership decisions;
- effect classification;
- approved RPE approximations;
- direct-use amounts and Aura durations;
- transmute tool/cooldown limitations.

If live code changes before a downstream issue begins, re-read the affected APIs and adapt serialization/call paths, but **do not re-research or silently reinterpret the vanilla recipe inventory** unless a concrete factual defect in this preparation is found.
