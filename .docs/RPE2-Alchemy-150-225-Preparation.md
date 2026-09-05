# RPE 2 — Classic Alchemy 150–225 Preparation

**Issue:** #211  
**Target branch:** `dev`  
**Canonical Alchemy dataset:** `data/default/professions/alchemy.lua`  
**Alchemy dataset ID:** `d6ffc4e2`  
**Prepared against Alchemy dataset version:** 11

## 1. Purpose and scope

This document is the implementation source of truth for the next vanilla Classic Alchemy slice. The interval is **`(150,225]`**: recipes requiring Alchemy 151 through 225. Skill-150 recipes are already owned by #207–#210 and must not be duplicated.

The validated vanilla set contains **28 recipes**. It includes trainer recipes, vendor/world-drop recipe items, quest/NPC-taught recipes, one Engineering-created recipe item, two transmutes, the Philosopher's Stone, direct-use potions, long-duration elixirs, weapon oils and one Engineering reagent.

Implementation is split across:

- #212 — item-use Spells and supporting Auras;
- #213 — Items, intermediate outputs and shared materials required by this slice;
- #214 — Recipes.

No gameplay/data implementation belongs in #211 itself.

---

## 2. Current RPE architecture inspected

The preparation was checked against current `dev` rather than assuming the code remained unchanged after #210.

### 2.1 Item use

`client/client_ItemUse.lua` accepts inventory `itemType = "consumable"` items with a valid `useSpellRef`, resolves the referenced Spell through the Registry, activates the generic Spell path, and consumes one inventory item only after cast acceptance.

Representable manual-use potions should therefore continue to use:

```text
Item.useSpellRef -> generic Spell activation -> Spell components/Auras
```

Long-duration stat elixirs should continue using `consumableTrait` where that accurately represents the intended RPE effect.

### 2.2 Item schema

`core/classes/Item.lua` currently supports:

- consumable types `potion`, `flask`, `elixir`, `scroll`, `rune`, `enhancement`;
- elixir categories `generic`, `battle`, `guardian`;
- `useSpellRef`;
- embedded `consumableTrait` and `equipmentTrait` payloads;
- item stats, skill bonuses, level conditions and normal equipment fields.

### 2.3 Spell/Aura capability relevant to this slice

The current generic Spell/Aura system can represent:

- direct healing;
- fixed resource restoration;
- application of supporting Auras;
- flat stat changes through Auras/Traits;
- normal item-use cooldowns and shared cooldown groups.

It does **not** currently provide a clean generic representation for:

- school-specific absorb pools;
- invisibility or invisibility/stealth detection;
- timed melee-weapon oils with on-hit proc Spells;
- self-centered periodic AoE pulses such as Oil of Immolation;
- category/tag-based repeated dispelling for magic/curse/poison/disease;
- school-specific spell-power bonuses such as Frost-only spell power;
- recipe/transmutation cooldowns.

Blocked effects must not be approximated with unrelated mechanics.

### 2.4 Recipe semantics

`core/classes/Recipe.lua` supports:

```text
always_learned
trainer
book
unavailable
```

Normal consumed RPE materials use `kind = "rpe_item"`; reusable tools use `kind = "tool"`.

`client/client_Crafting.lua` still calculates trainer price as:

```text
floor(75 + requiredSkillLevel * 28 + requiredSkillLevel^2 * 1.6)
```

Relevant values:

| Skill | trainerCostCopper |
|---:|---:|
| 155 | 42855 |
| 160 | 45515 |
| 165 | 48255 |
| 175 | 53975 |
| 180 | 56955 |
| 185 | 60015 |
| 190 | 63155 |
| 195 | 66375 |
| 200 | 69675 |
| 205 | 73055 |
| 210 | 76515 |
| 215 | 80055 |
| 225 | 87375 |

Non-trainer recipes may retain the calculated serialized `trainerCostCopper`; `learnMode` remains authoritative for trainer indexing.

### 2.5 Dependency limitation

Current `core/internal/database/Dependecies.lua` recomputes dependencies from Items, Spells, Auras, Traits and other runtime objects, but does **not** inspect Recipe `input.itemRef` / `output.itemRef` fields. #214 must re-check this on live `dev`; do not broaden the recipe issue into a dependency-system redesign unless runtime behavior actually requires it.

---

## 3. Source/version decisions

### 3.1 Vanilla Classic data is authoritative

Use Classic-era records for names, recipe identity, reagents, quantities, effects, required levels, item levels, icons and stack sizes. Modern/TBC/Cata/SoD pages can expose changed reagents, vial types, stacks or effect values.

Principal source family: Wowhead Classic (`/classic/`), cross-checked against Warcraft Wiki and legacy Classic databases where acquisition or historical behavior required clarification.

### 3.2 Vial/version drift

The following choices are deliberate:

- Greater Healing Potion through Frost Oil use the vanilla Leaded-Vial recipes where listed below.
- **Frost Oil** is `4 Khadgar's Whisker + 2 Wintersbite + 1 Leaded Vial`; later Dragon's Teeth/Crystal-Vial variants are not valid for this slice.
- **Goblin Rocket Fuel** is `Firebloom + Volatile Rum + Leaded Vial`; modern pages can show Crystal Vial.
- **Lesser Stoneshield Potion** uses Leaded Vial.
- Later recipes that genuinely use Crystal Vial retain Crystal Vial.

### 3.3 Elixir of Greater Defense drift

Vanilla Classic Elixir of Greater Defense is **+250 Armor for 1 hour**, not the later +100 value. Use +250 Armor. Its exact Classic icon is `inv_potion_65`.

### 3.4 Philosopher's Stone drift

For this vanilla slice, Philosopher's Stone is the bind-on-pickup Alchemy transmutation tool. The later trinket/+5-all-primary-stats form must not be imported into this data.

RPE representation:

- non-consumable material/tool item;
- bind on pickup;
- no fabricated equipment stats;
- reusable `kind = "tool"` input for transmute recipes.

Exact icon: `inv_misc_orb_01`.

### 3.5 Transmute cooldowns

Vanilla Classic behavior:

- Iron -> Gold: **24-hour** cooldown;
- Mithril -> Truesilver: **48-hour** cooldown;
- both use the character transmutation cooldown family.

The current Recipe schema has no recipe cooldown field. #214 should implement the recipes and Philosopher's Stone tool requirement but must not fabricate cooldown behavior without a separate generic capability change.

### 3.6 Exclusions

Do not add:

- Elixir of Ogre's Strength or Free Action Potion (skill 150; previous slice);
- Dreamless Sleep Potion or any recipe requiring >225;
- SoD-only recipes such as Mildly Irradiated Rejuvenation Potion;
- Anniversary/seasonal additions that did not exist in vanilla Classic;
- later-expansion reagent/effect revisions.

**Elixir of Frost Power is included.** It is a vanilla Winter Veil-era recipe despite seasonal acquisition.

---

## 4. Existing refs used by this slice

### 4.1 Core refs

| Meaning | Ref |
|---|---|
| Alchemy | `f82db71a:pdyzyudy` |
| Armor | `f82db71a:v42albuv` |
| Strength | `f82db71a:zfqm8dxp` |
| Agility | `f82db71a:xqz0daz2` |
| Stamina | `f82db71a:ygjno50i` |
| Spirit | `f82db71a:kec9rhli` |
| Intellect | `f82db71a:75y3a8ib` |
| Mana | `f82db71a:4c8mfm99` |
| Rage | `f82db71a:e2tfklq7` |
| Fire resistance | `f82db71a:0w7c7p09` |
| Frost resistance | `f82db71a:jjn0my8k` |
| Nature resistance | `f82db71a:pg0ytacb` |
| Arcane resistance | `f82db71a:954yunb9` |
| Shadow resistance | `f82db71a:itpo751d` |

### 4.2 Existing Alchemy refs

| Item | Ref |
|---|---|
| Liferoot | `d6ffc4e2:wdct8173` |
| Kingsblood | `d6ffc4e2:avcd4nsv` |
| Stranglekelp | `d6ffc4e2:gl5mwfe7` |
| Fire Oil | `d6ffc4e2:q5f2o7ze` |
| Fadeleaf | `d6ffc4e2:fvc8vvs2` |
| Wild Steelbloom | `d6ffc4e2:zryl4kbv` |
| Grave Moss | `d6ffc4e2:punrvxpv` |
| Goldthorn | `d6ffc4e2:onr6v77u` |
| Wintersbite | `d6ffc4e2:i580qrgo` |
| Khadgar's Whisker | `d6ffc4e2:bne5607a` |
| Purple Lotus | `d6ffc4e2:y3a574bb` |
| Firebloom | `d6ffc4e2:uz4jtdrb` |
| Sungrass | `d6ffc4e2:uvldarfw` |
| Leaded Vial | `d6ffc4e2:jdxdj7eh` |
| Crystal Vial | `d6ffc4e2:804x8qak` |

Wildvine already belongs to Misc:

```text
3eb7e9bb:2hbdmyj4
```

---

## 5. Material ownership decisions

Repository searches found no existing packaged definitions for the following shared materials. #213 should re-check before writing and add them only if still absent.

### 5.1 Misc-owned world/creature materials

Add to `data/default/professions/misc.lua`:

| Material | Vanilla item ID |
|---|---:|
| Small Flame Sac | 4402 |
| Large Fang | 5637 |
| Ichor of Undeath | 7972 |
| Elemental Earth | 7067 |
| Volatile Rum | 9260 |
| Black Vitriol | 9262 |

### 5.2 Blacksmithing/mining-owned metals

Add to `data/default/professions/blacksmithing.lua` if still absent:

| Material | Vanilla item ID |
|---|---:|
| Mithril Ore | 3858 |
| Iron Bar | 3575 |
| Mithril Bar | 3860 |
| Gold Bar | 3577 |
| Truesilver Bar | 6037 |

Gold Bar and Truesilver Bar are transmute outputs but remain shared metal materials owned by Blacksmithing/mining rather than Alchemy.

Any packaged dataset modified for these materials must have its version bumped independently.

---

## 6. Authoritative recipe inventory

All recipes create quantity **1**. Every recipe uses `skillRef = "f82db71a:pdyzyudy"`.

| Skill | Recipe/output | Acquisition | RPE learnMode | Exact vanilla inputs | Cross-dataset/new input | Cost |
|---:|---|---|---|---|---|---:|
| 155 | Greater Healing Potion | Trainer | `trainer` | Liferoot; Kingsblood; Leaded Vial | — | 42855 |
| 160 | Mana Potion | Trainer | `trainer` | Stranglekelp; Kingsblood; Leaded Vial | — | 45515 |
| 165 | Fire Protection Potion | Vendor recipe | `book` | Small Flame Sac; Fire Oil; Leaded Vial | Small Flame Sac -> Misc | 48255 |
| 165 | Lesser Invisibility Potion | Trainer | `trainer` | Fadeleaf; Wild Steelbloom; Leaded Vial | — | 48255 |
| 165 | Shadow Oil | Vendor recipe | `book` | 4 Fadeleaf; 4 Grave Moss; Leaded Vial | — | 48255 |
| 175 | Elixir of Fortitude | World-drop recipe | `book` | Wild Steelbloom; Goldthorn; Leaded Vial | — | 53975 |
| 175 | Great Rage Potion | Vendor recipe | `book` | Large Fang; Kingsblood; Leaded Vial | Large Fang -> Misc | 53975 |
| 180 | Mighty Troll's Blood Potion | Henry Stern / special NPC teaching | `book` | Liferoot; Bruiseweed; Leaded Vial | — | 56955 |
| 185 | Elixir of Agility | Trainer | `trainer` | Stranglekelp; Goldthorn; Leaded Vial | — | 60015 |
| 190 | Elixir of Frost Power | Winter Veil recipe/reward | `book` | 2 Wintersbite; Khadgar's Whisker; Leaded Vial | — | 63155 |
| 190 | Frost Protection Potion | Vendor recipe | `book` | Wintersbite; Goldthorn; Leaded Vial | — | 63155 |
| 190 | Nature Protection Potion | Vendor recipe | `book` | Liferoot; Stranglekelp; Leaded Vial | — | 63155 |
| 195 | Elixir of Detect Lesser Invisibility | World-drop recipe | `book` | Khadgar's Whisker; Fadeleaf; Leaded Vial | — | 66375 |
| 195 | Elixir of Greater Defense | Trainer | `trainer` | Wild Steelbloom; Goldthorn; Leaded Vial | — | 66375 |
| 200 | Catseye Elixir | Trainer | `trainer` | Goldthorn; Fadeleaf; Leaded Vial | — | 69675 |
| 200 | Frost Oil | Vendor recipe | `book` | 4 Khadgar's Whisker; 2 Wintersbite; Leaded Vial | — | 69675 |
| 205 | Greater Mana Potion | Trainer | `trainer` | Khadgar's Whisker; Goldthorn; Leaded Vial | — | 73055 |
| 205 | Oil of Immolation | Trainer | `trainer` | Firebloom; Goldthorn; Crystal Vial | — | 73055 |
| 210 | Goblin Rocket Fuel | Recipe item created by Goblin Engineers | `book` | Firebloom; Volatile Rum; Leaded Vial | Volatile Rum -> Misc | 76515 |
| 210 | Magic Resistance Potion | World-drop recipe | `book` | Khadgar's Whisker; Purple Lotus; Crystal Vial | — | 76515 |
| 215 | Elixir of Greater Water Breathing | Trainer | `trainer` | Ichor of Undeath; 2 Purple Lotus; Crystal Vial | Ichor -> Misc | 80055 |
| 215 | Lesser Stoneshield Potion | Quest reward recipe | `book` | Mithril Ore; Goldthorn; Leaded Vial | Mithril Ore -> Blacksmithing | 80055 |
| 215 | Restorative Potion | Quest-taught after Badlands Reagent Run II | `book` | Elemental Earth; Goldthorn; Crystal Vial | Elemental Earth -> Misc | 80055 |
| 215 | Superior Healing Potion | Trainer | `trainer` | Sungrass; Khadgar's Whisker; Crystal Vial | — | 80055 |
| 225 | Philosopher's Stone | Vendor recipe | `book` | 4 Iron Bar; Black Vitriol; 4 Purple Lotus; 4 Firebloom | Iron Bar -> Blacksmithing; Black Vitriol -> Misc | 87375 |
| 225 | Wildvine Potion | World-drop recipe | `book` | Wildvine; Purple Lotus; Crystal Vial | Wildvine -> Misc existing ref | 87375 |
| 225 | Transmute: Iron to Gold | Vendor recipe | `book` | Iron Bar; Philosopher's Stone (tool) | Iron/Gold Bar -> Blacksmithing | 87375 |
| 225 | Transmute: Mithril to Truesilver | Vendor recipe | `book` | Mithril Bar; Philosopher's Stone (tool) | Mithril/Truesilver Bar -> Blacksmithing | 87375 |

### 6.1 Quest/NPC teaching mapping

RPE has no dedicated `quest` learn mode. Recipes learned outside the profession trainer through quest/NPC/manual mechanisms use `book`, because profile recipebook knowledge keeps them out of the trainer index. This includes Mighty Troll's Blood Potion and Restorative Potion as well as physical recipe items.

### 6.2 Transmute tool input

For both transmutes, Philosopher's Stone is a reusable tool:

```lua
{
    kind = "tool",
    itemRef = "d6ffc4e2:<philosophers-stone-item-id>",
    quantity = 1,
}
```

The metal bar remains the consumed `rpe_item` input.

---

## 7. Authoritative item/output inventory

Serialize icon paths as `interface/icons/<icon>.blp`.

Classic stack rules for this slice:

- ordinary potions/elixirs/oils: **5**;
- Goblin Rocket Fuel: **20**;
- shared bars: **20**;
- Philosopher's Stone: **1**.

| Output | WoW ID | Exact icon | ilvl | Req. level | Quality / stack | RPE classification | Vanilla effect / intended RPE representation |
|---|---:|---|---:|---:|---|---|---|
| Greater Healing Potion | 1710 | `inv_potion_52` | 31 | 21 | common / 5 | consumable / potion | Heal 455–585 -> `useSpellRef`, midpoint `baseHealing = 520` |
| Mana Potion | 3827 | `inv_potion_72` | 32 | 22 | common / 5 | consumable / potion | Mana 455–585 -> `useSpellRef`, fixed 520 Mana |
| Fire Protection Potion | 6049 | `inv_potion_16` | 33 | 23 | common / 5 | consumable / potion | Fire absorb -> blocked: no school absorb pool |
| Lesser Invisibility Potion | 3823 | `inv_potion_18` | 33 | 23 | common / 5 | consumable / potion | Lesser invisibility 15 sec -> blocked: no invisibility state |
| Shadow Oil | 3824 | `inv_potion_23` | 34 | 24 | common / 5 | consumable / enhancement | 30-min melee weapon oil, 15% Shadow Bolt III proc -> blocked |
| Elixir of Fortitude | 3825 | `inv_potion_43` | 35 | 25 | common / 5 | consumable / elixir / guardian | +120 max Health 1h -> guardian Trait +12 Stamina |
| Great Rage Potion | 5633 | `inv_potion_21` | 35 | 25 | common / 5 | consumable / potion | 30–60 Rage -> `useSpellRef`, fixed midpoint 45 Rage |
| Mighty Troll's Blood Potion | 3826 | `inv_potion_79` | 36 | 26 | common / 5 | consumable / elixir / guardian | 12 Health/5 sec 1h -> guardian Trait +12 Spirit |
| Elixir of Agility | 8949 | `inv_potion_93` | 37 | 27 | common / 5 | consumable / elixir / battle | +15 Agility 1h -> battle Trait +15 Agility |
| Elixir of Frost Power | 17708 | `inv_potion_03` | 38 | 28 | common / 5 | consumable / elixir / battle | +15 Frost spell power -> blocked; do not generalize without approval |
| Frost Protection Potion | 6050 | `inv_potion_13` | 38 | 28 | common / 5 | consumable / potion | 1350–2250 Frost absorb -> blocked |
| Nature Protection Potion | 6052 | `inv_potion_06` | 38 | 28 | common / 5 | consumable / potion | 1350–2250 Nature absorb -> blocked |
| Elixir of Detect Lesser Invisibility | 3828 | `inv_potion_01` | 39 | 29 | common / 5 | consumable / elixir / generic | Detect lesser invisibility 10 min -> blocked |
| Elixir of Greater Defense | 8951 | `inv_potion_65` | 39 | 29 | common / 5 | consumable / elixir / guardian | +250 Armor 1h -> guardian Trait +250 Armor |
| Catseye Elixir | 10592 | `inv_potion_36` | 40 | 30 | common / 5 | consumable / elixir / guardian | Increased stealth detection 10 min -> blocked |
| Frost Oil | 3829 | `inv_potion_20` | 40 | 30 | common / 5 | consumable / enhancement | 30-min melee weapon oil, 10% Frostbolt proc -> blocked |
| Greater Mana Potion | 6149 | `inv_potion_73` | 41 | 31 | common / 5 | consumable / potion | Mana 700–900 -> `useSpellRef`, fixed 800 Mana |
| Oil of Immolation | 8956 | `inv_potion_11` | 41 | 31 | common / 5 | consumable / potion | 50 Fire AoE every 3 sec for 15 sec -> blocked |
| Goblin Rocket Fuel | 9061 | `inv_cask_02` | 42 | — | common / 20 | material | Engineering reagent; no combat `useSpellRef` |
| Magic Resistance Potion | 9036 | `inv_potion_16` | 42 | 32 | common / 5 | consumable / potion | +50 all magic resistances 3 min -> supporting Aura for 10 RPE turns |
| Restorative Potion | 9030 | `inv_potion_01` | 42 | 32 | common / 5 | consumable / potion | Removes one magic/curse/poison/disease every 5 sec for 30 sec -> blocked |
| Lesser Stoneshield Potion | 4623 | `inv_potion_67` | 43 | 33 | common / 5 | consumable / potion | +1000 Armor for 1.5 min -> supporting Aura for **5 RPE turns** |
| Elixir of Greater Water Breathing | 18294 | `inv_potion_05` | 45 | 35 | common / 5 | consumable / elixir / generic | Water breathing 1h -> gameplay effect deliberately ignored |
| Superior Healing Potion | 3928 | `inv_potion_53` | 45 | 35 | common / 5 | consumable / potion | Heal 700–900 -> `useSpellRef`, midpoint `baseHealing = 800` |
| Philosopher's Stone | 9149 | `inv_misc_orb_01` | 45 | — | common / 1 | material/tool, bind-on-pickup | Required for transmutation; reusable Recipe tool; no fabricated trinket stats |
| Wildvine Potion | 9144 | `inv_potion_34` | 45 | 35 | common / 5 | consumable / potion | 1–1500 Health + 1–1500 Mana -> `useSpellRef`, floor midpoint 750 Health + 750 Mana |
| Gold Bar | 3577 | `inv_ingot_03` | 30 | — | common / 20 | Blacksmithing/mining material | Transmute output; shared external Item |
| Truesilver Bar | 6037 | `inv_ingot_08` | 50 | — | common / 20 | Blacksmithing/mining material | Transmute output; shared external Item |

---

## 8. Spell/Aura implementation inventory for #212

### 8.1 Directly representable item-use Spells

Unless current code changes before #212, all normal potion Spells use:

```text
castTime = 0
learnMode = unavailable
ignoreGCD = true
triggersGCD = false
cooldown = 10
cooldownGroup = potion
description = ""
target = caster
```

| Item | Components |
|---|---|
| Greater Healing Potion | `heal`, `baseHealing = 520` |
| Mana Potion | `resource`, Mana `amount = 520` |
| Great Rage Potion | `resource`, Rage `amount = 45` |
| Greater Mana Potion | `resource`, Mana `amount = 800` |
| Superior Healing Potion | `heal`, `baseHealing = 800` |
| Wildvine Potion | `heal`, `baseHealing = 750`; `resource`, Mana `amount = 750` |

As with the existing Rage Potion, do not invent a hard-coded Warrior class ref solely to enforce the source class restriction unless current class refs make that unambiguously safe.

### 8.2 Supporting-Aura Spells

#### Magic Resistance Potion

Spell:

- caster/self;
- instant;
- 10-turn shared potion cooldown;
- applies supporting Aura for **10 turns**.

Aura:

- duration 10 turns;
- maxStacks 1;
- refresh duration;
- +50 Fire resistance;
- +50 Frost resistance;
- +50 Nature resistance;
- +50 Arcane resistance;
- +50 Shadow resistance.

This extends the user-approved Minor Magic Resistance convention: a 3-minute magic-resistance potion maps to 10 RPE turns.

#### Lesser Stoneshield Potion

Spell:

- caster/self;
- instant;
- 10-turn shared potion cooldown;
- applies supporting Aura for **5 turns**.

Aura:

- duration 5 turns;
- maxStacks 1;
- refresh duration;
- +1000 Armor using `f82db71a:v42albuv`.

The source effect is 1.5 minutes. Using the established 3-minute -> 10-turn resistance conversion proportionally gives **5 turns**.

### 8.3 Long-duration consumable Traits

These require no item-use Spell:

| Item | Elixir type | Trait |
|---|---|---|
| Elixir of Fortitude | Guardian | +12 Stamina |
| Mighty Troll's Blood Potion | Guardian | +12 Spirit |
| Elixir of Agility | Battle | +15 Agility |
| Elixir of Greater Defense | Guardian | +250 Armor |

### 8.4 Deliberately ignored gameplay effect

**Elixir of Greater Water Breathing**: Item + Recipe only, no Spell/Aura. This carries forward the explicit project decision to ignore water-breathing gameplay instead of introducing an environmental breathing subsystem.

### 8.5 Explicit blockers

| Item | Vanilla behavior | Smallest missing generic capability |
|---|---|---|
| Fire Protection Potion | Fire absorb pool | school-specific absorb/shield effect |
| Frost Protection Potion | Frost absorb pool | school-specific absorb/shield effect |
| Nature Protection Potion | Nature absorb pool | school-specific absorb/shield effect |
| Lesser Invisibility Potion | invisibility | visibility/invisibility state and targeting interaction |
| Elixir of Detect Lesser Invisibility | detect invisibility | invisibility-detection state |
| Catseye Elixir | stealth detection | stealth-detection state |
| Shadow Oil | timed weapon enhancement + Shadow Bolt proc | consumable weapon enhancement/on-hit proc model |
| Frost Oil | timed weapon enhancement + Frostbolt proc | consumable weapon enhancement/on-hit proc model |
| Elixir of Frost Power | +15 Frost spell power | school-specific spell-power modifier/stat; do not generalize without approval |
| Oil of Immolation | periodic self-centered Fire AoE | periodic AoE pulse centered on Aura owner |
| Restorative Potion | repeated category dispel | Aura tag/category cleanse + periodic dispel |
| Transmutes | 24h/48h shared cooldown | Recipe/transmutation cooldown support |

Blocked consumables still receive canonical Item and Recipe records in #213/#214 but no fake `useSpellRef`.

---

## 9. Item categorization summary for #213

### Consumable potions

Greater Healing Potion; Mana Potion; Fire Protection Potion; Lesser Invisibility Potion; Great Rage Potion; Frost Protection Potion; Nature Protection Potion; Greater Mana Potion; Oil of Immolation; Magic Resistance Potion; Lesser Stoneshield Potion; Restorative Potion; Superior Healing Potion; Wildvine Potion.

### Elixirs

Elixir of Fortitude; Mighty Troll's Blood Potion; Elixir of Agility; Elixir of Frost Power; Elixir of Detect Lesser Invisibility; Elixir of Greater Defense; Catseye Elixir; Elixir of Greater Water Breathing.

### Weapon enhancements/oils

Shadow Oil; Frost Oil.

### Materials/tools

Goblin Rocket Fuel; Philosopher's Stone.

### External metal outputs

Gold Bar; Truesilver Bar.

---

## 10. Source notes

Principal Classic references used to resolve this slice:

- Classic Alchemy list: https://www.wowhead.com/classic/spells/professions/alchemy
- Greater Healing Potion: https://www.wowhead.com/classic/spell=7181/greater-healing-potion
- Mana Potion: https://www.wowhead.com/classic/item=3827/mana-potion
- Fire Protection Potion recipe: https://www.wowhead.com/classic/item=6055/recipe-fire-protection-potion
- Lesser Invisibility Potion: https://www.wowhead.com/classic/item=3823/lesser-invisibility-potion
- Shadow Oil: https://www.wowhead.com/classic/item=3824/shadow-oil
- Elixir of Fortitude: https://www.wowhead.com/classic/item=3825/elixir-of-fortitude
- Great Rage Potion recipe: https://www.wowhead.com/classic/item=5643/recipe-great-rage-potion
- Mighty Troll's Blood Potion recipe: https://www.wowhead.com/classic/item=3831/recipe-mighty-trolls-blood-potion
- Elixir of Agility: https://www.wowhead.com/classic/item=8949/elixir-of-agility
- Elixir of Frost Power recipe: https://www.wowhead.com/classic/item=17709/recipe-elixir-of-frost-power
- Frost Protection Potion recipe: https://www.wowhead.com/classic/item=6056/recipe-frost-protection-potion
- Nature Protection Potion recipe: https://www.wowhead.com/classic/item=6057/recipe-nature-protection-potion
- Elixir of Detect Lesser Invisibility recipe: https://www.wowhead.com/classic/item=3832/recipe-elixir-of-detect-lesser-invisibility
- Elixir of Greater Defense: https://www.wowhead.com/classic/item=8951/elixir-of-greater-defense
- Elixir of Greater Defense icon: https://www.wowhead.com/classic/icon=134845/inv-potion-65
- Catseye Elixir: https://www.wowhead.com/classic/item=10592/catseye-elixir
- Frost Oil recipe: https://www.wowhead.com/classic/item=14634/recipe-frost-oil
- Greater Mana Potion: https://www.wowhead.com/classic/spell=11448/greater-mana-potion
- Oil of Immolation: https://www.wowhead.com/classic/item=8956/oil-of-immolation
- Recipe: Goblin Rocket Fuel: https://www.wowhead.com/classic/item=10644/recipe-goblin-rocket-fuel
- Goblin Rocket Fuel craft: https://www.wowhead.com/classic/spell=11456/goblin-rocket-fuel
- Magic Resistance Potion recipe: https://www.wowhead.com/classic/item=9293/recipe-magic-resistance-potion
- Elixir of Greater Water Breathing: https://www.wowhead.com/classic/spell=22808/elixir-of-greater-water-breathing
- Lesser Stoneshield Potion recipe: https://www.wowhead.com/classic/item=4624/recipe-lesser-stoneshield-potion
- Restorative Potion: https://www.wowhead.com/classic/item=9030/restorative-potion
- Restorative Potion quest/source cross-check: https://warcraft.wiki.gg/wiki/Restorative_Potion
- Superior Healing Potion: https://www.wowhead.com/classic/spell=11457/superior-healing-potion
- Philosopher's Stone recipe: https://www.wowhead.com/classic/item=9303/recipe-philosophers-stone
- Philosopher's Stone craft: https://www.wowhead.com/classic/spell=11459/philosophers-stone
- Wildvine Potion recipe: https://www.wowhead.com/classic/item=9294/recipe-wildvine-potion
- Wildvine Potion craft: https://www.wowhead.com/classic/spell=11458/wildvine-potion
- Iron -> Gold recipe: https://www.wowhead.com/classic/item=9304/recipe-transmute-iron-to-gold
- Iron -> Gold cooldown/icon cross-check: https://wowclassicdb.com/spell/11479
- Mithril -> Truesilver recipe: https://www.wowhead.com/classic/item=9305/recipe-transmute-mithril-to-truesilver
- Mithril -> Truesilver cooldown: https://www.wowhead.com/classic/spell=11480/transmute-mithril-to-truesilver
- Gold Bar icon cross-check: https://wowclassicdb.com/spell/3308
- Truesilver Bar icon cross-check: https://wowclassicdb.com/spell/10098

Where later-version data contradicts a Classic record, the Classic record is authoritative for #212–#214.

---

## 11. Downstream implementation scope

### #212 — Spells/Auras

Implement only:

- Greater Healing Potion;
- Mana Potion;
- Great Rage Potion;
- Greater Mana Potion;
- Magic Resistance Potion + supporting Aura;
- Lesser Stoneshield Potion + supporting Aura;
- Superior Healing Potion;
- Wildvine Potion.

Do not implement fake effects for the blocker list. Greater Water Breathing remains intentionally effectless.

### #213 — Items/materials

Implement:

- all 26 Alchemy-owned outputs represented by the 28 recipes;
- approved `useSpellRef` values from #212;
- four stat-elixir Traits;
- missing external Misc materials;
- missing external Blacksmithing/mining materials, including Gold/Truesilver transmute outputs;
- exact Classic item metadata/icons.

Bump every packaged dataset modified.

### #214 — Recipes

Implement all 28 recipes exactly as listed in §6 using final refs from #213. Use `kind = "tool"` for Philosopher's Stone in both transmutes. Do not fabricate transmute cooldown behavior.

---

## 12. Validation checklist

This preparation establishes:

- **28** recipes exactly in `(150,225]`;
- no skill-150 duplicate from #210;
- all skill-225 recipes in scope included;
- no >225 recipes;
- vanilla Classic reagent/vial versions resolved explicitly;
- acquisition modes mapped to current RPE semantics;
- output quantity 1 for every recipe;
- complete output metadata, including concrete icons, for all 28 recipe outputs;
- shared material ownership resolved;
- representable manual effects defined with concrete RPE values;
- long-duration stat elixirs assigned to Trait mechanics;
- Magic Resistance mapped to 10 turns;
- Lesser Stoneshield mapped proportionally to **5 turns**;
- water breathing deliberately ignored;
- unsupported invisibility, detection, absorb, weapon-oil, school-spell-power, periodic-AoE, repeated-dispel and transmute-cooldown behavior recorded as blockers;
- Classic stack sizes retained instead of modern stack revisions;
- Philosopher's Stone kept as the vanilla transmutation tool rather than importing later trinket stats;
- no implementation data/runtime files changed by #211.

This document is authoritative for #212–#214 unless the user explicitly changes a project-level adaptation decision before those issues are implemented.
