# RPE 2 — Classic Alchemy 75–150 Preparation

**Issue:** #207  
**Target branch:** `dev`  
**Canonical Alchemy dataset:** `data/default/professions/alchemy.lua`  
**Alchemy dataset ID:** `d6ffc4e2`  
**Prepared against Alchemy dataset version:** 7

## 1. Purpose and scope

This document is the implementation source of truth for the next Classic Alchemy slice. The included skill interval is **`(75,150]`**: recipes requiring Alchemy 76 through 150, with skill-150 recipes included.

The validated live-vanilla set contains **18 recipes/outputs**. It includes trainer recipes, world-drop/vendor recipe books, two crafted intermediate oils, direct-use potions, and long-duration elixirs. It deliberately excludes later-era/removed records even when current database indexes surface them beside Classic Alchemy data.

Implementation is split across:

- #208 — Spells/supporting Auras;
- #209 — Items/intermediate outputs/material ownership;
- #210 — Recipes.

No gameplay implementation belongs in #207 itself. This document records both the vanilla source data and the deliberate RPE adaptations approved for implementation.

---

## 2. Approved RPE adaptation decisions

These decisions were confirmed after the initial #207 research pass and are authoritative for #208–#210 even where they intentionally simplify vanilla behavior.

1. **Large Venom Sac belongs in the existing Misc dataset** at `data/default/professions/misc.lua` (`3eb7e9bb`).
2. **Fishing ingredients belong in a new packaged Fishing dataset** at `data/default/professions/fishing.lua`. This dataset must own:
   - Oily Blackmouth;
   - Deviate Fish;
   - Firefin Snapper.
3. **Ignore Swim Speed Potion's swim-speed gameplay effect.** Still implement the canonical item and recipe, but do not create a Spell, Aura, movement override, or engine blocker for its use effect in this slice.
4. **Ignore Elixir of Water Breathing's water-breathing gameplay effect.** Still implement the canonical item and recipe, but do not create a Spell, Aura, environmental system, or engine blocker for its use effect in this slice.
5. **Elixir of Firepower is deliberately generalized in RPE** from +10 Fire spell damage to **+10 generic Spell Power**, using Core Spell Power `f82db71a:7t7xgzcx`. This is an intentional gameplay adaptation, not a claim about the vanilla source effect.
6. **Healing/mana/resource restoration potions use the established apprentice-potion approximation.** Do not block them because the generic effect model lacks exact arbitrary min/max ranges. Follow the same convention already used for Minor Healing Potion and Minor Mana Potion:
   - healing ranges use the source midpoint as `baseHealing`, accepting the existing heal variance behavior;
   - resource ranges use the source midpoint as a fixed `resource` amount;
   - normal potions use the existing 10-turn shared `potion` cooldown convention.

For this range specifically:

- Healing Potion 280–360 Health -> `baseHealing = 320`;
- Lesser Mana Potion 280–360 Mana -> fixed Mana restoration `amount = 320`.

This midpoint convention should also be used for later healing/mana/resource potions unless a future design explicitly replaces it.

---

## 3. Current RPE architecture inspected

The preparation was checked against the current `dev` implementation rather than relying on older PDD assumptions.

### 3.1 Item use

`client/client_ItemUse.lua` accepts inventory `itemType = "consumable"` items with a valid `useSpellRef`, resolves the referenced Spell through the Registry, passes the cast through the generic `ActivateSpellReference()` flow, and removes exactly one inventory item only after the cast is accepted.

Manual potion effects should therefore use `Item.useSpellRef` where this document calls for an actual gameplay effect.

### 3.2 Spell effects

`core/classes/Spell.lua` currently supports:

- `heal`;
- `resource`;
- `apply_aura`;
- `remove_aura` by exact Aura ref;
- `damage`;
- `interrupt`;
- `revert`;
- `summon_pet`.

There is no generic absorb/shield component, no tag/category-wide Aura cleanse, and no future-control-immunity component.

### 3.3 Aura effects

`core/classes/Aura.lua` supports:

- flat/percent stat changes;
- skill changes;
- heal/resource/damage effects;
- nested Aura application;
- control fields `cancelOnDamage`, `preventCasting`, absolute `movementRangeOverride`, and `forceAutoHitAgainstTarget`.

It does **not** provide school-specific absorb pools or immunity to future stun/root/snare effects.

Movement/swim and water-breathing gaps are intentionally irrelevant to this slice because those two source effects are being ignored by project decision.

### 3.4 Recipe semantics

`core/classes/Recipe.lua` supports `always_learned`, `trainer`, `book`, and `unavailable` learn modes. Consumed RPE materials use:

```lua
inputs = {
    {
        kind = "rpe_item",
        itemRef = "dataset:item",
        quantity = 1,
    },
}
```

The normalized output uses `output.itemRef`, `minQuantity`, and `maxQuantity`.

Current trainer-cost calculation in `client/client_Crafting.lua` is:

```text
floor(75 + requiredSkillLevel * 28 + requiredSkillLevel^2 * 1.6)
```

Relevant values:

| Skill | RPE trainer-cost field |
|---:|---:|
| 80 | 12555 |
| 90 | 15555 |
| 100 | 18875 |
| 110 | 22515 |
| 120 | 26475 |
| 125 | 28575 |
| 130 | 30755 |
| 135 | 33015 |
| 140 | 35355 |
| 150 | 40275 |

For consistency with current packaged recipes, the serialized `trainerCostCopper` field may retain the calculated value for `book` recipes; `learnMode` remains authoritative and must not make them trainer-learnable.

### 3.5 Existing refs used by this range

| Meaning | Ref |
|---|---|
| Alchemy | `f82db71a:pdyzyudy` |
| Armor | `f82db71a:v42albuv` |
| Strength | `f82db71a:zfqm8dxp` |
| Agility | `f82db71a:xqz0daz2` |
| Spirit | `f82db71a:kec9rhli` |
| Intellect | `f82db71a:75y3a8ib` |
| Spell Power | `f82db71a:7t7xgzcx` |
| Health resource | `f82db71a:q2ktkztt` |
| Mana resource | `f82db71a:4c8mfm99` |
| Fire resistance | `f82db71a:0w7c7p09` |
| Frost resistance | `f82db71a:jjn0my8k` |
| Nature resistance | `f82db71a:pg0ytacb` |
| Arcane resistance | `f82db71a:954yunb9` |
| Shadow resistance | `f82db71a:itpo751d` |

For Elixir of Firepower, use generic Spell Power deliberately as specified in §2.

---

## 4. Version/source decisions

### 4.1 Vanilla Classic data is authoritative for names, recipes, icons and item metadata

Use Classic-era records where they differ from modern/TBC/Cata data. Later database pages may substitute different vials, stack sizes or effects; those changes must not leak into the source inventory.

The RPE gameplay adaptations in §2 intentionally override only the effect representation, not recipe identity or source metadata.

### 4.2 Vial rules

The validated vanilla recipes use **Empty Vial** or **Leaded Vial**, not later Crystal-Vial substitutions.

Existing Alchemy refs:

- Empty Vial: `d6ffc4e2:cycq8tn6`
- Leaded Vial: `d6ffc4e2:jdxdj7eh`

### 4.3 Poison-resistance naming

Use the vanilla Classic name **Elixir of Poison Resistance**. Do not replace it with later `Potion of Curing` naming.

### 4.4 Excluded database records

Do **not** add:

- Cowardly Flight Potion — beta/database residue, not a live vanilla recipe;
- Elixir of Minor Accuracy — later-era recipe;
- SoD/Anniversary-only or TBC+ additions;
- recipes requiring Alchemy >150.

### 4.5 Skill 150

Skill-150 recipes are included. Elixir of Ogre's Strength and Free Action Potion belong in this slice.

---

## 5. Authoritative recipe inventory

All recipes output quantity **1**.

| Skill | Recipe/output | Acquisition | RPE learnMode | Exact vanilla inputs | Cross-dataset/new input | Cost field |
|---:|---|---|---|---|---|---:|
| 80 | Blackmouth Oil | Trainer | `trainer` | 2 Oily Blackmouth; 1 Empty Vial | Oily Blackmouth -> Fishing | 12555 |
| 90 | Elixir of Giant Growth | World-drop recipe | `book` | 1 Deviate Fish; 1 Earthroot; 1 Empty Vial | Deviate Fish -> Fishing | 15555 |
| 90 | Elixir of Water Breathing | Trainer | `trainer` | 1 Stranglekelp; 2 Blackmouth Oil; 1 Empty Vial | Blackmouth Oil is Alchemy output | 15555 |
| 90 | Elixir of Wisdom | Trainer | `trainer` | 1 Mageroyal; 2 Briarthorn; 1 Empty Vial | none | 15555 |
| 100 | Holy Protection Potion | Vendor recipe | `book` | 1 Bruiseweed; 1 Swiftthistle; 1 Empty Vial | none | 18875 |
| 100 | Swim Speed Potion | Trainer | `trainer` | 1 Swiftthistle; 1 Blackmouth Oil; 1 Empty Vial | none | 18875 |
| 110 | Healing Potion | Trainer | `trainer` | 1 Bruiseweed; 1 Briarthorn; 1 Leaded Vial | none | 22515 |
| 110 | Minor Magic Resistance Potion | World-drop recipe | `book` | 3 Mageroyal; 1 Wild Steelbloom; 1 Empty Vial | none | 22515 |
| 120 | Lesser Mana Potion | Trainer | `trainer` | 1 Mageroyal; 1 Stranglekelp; 1 Empty Vial | none | 26475 |
| 120 | Elixir of Poison Resistance | World-drop recipe | `book` | 1 Large Venom Sac; 1 Bruiseweed; 1 Leaded Vial | Large Venom Sac -> Misc | 26475 |
| 125 | Strong Troll's Blood Potion | Trainer | `trainer` | 2 Bruiseweed; 2 Briarthorn; 1 Leaded Vial | none | 28575 |
| 130 | Fire Oil | Trainer | `trainer` | 2 Firefin Snapper; 1 Empty Vial | Firefin Snapper -> Fishing | 30755 |
| 130 | Elixir of Defense | Trainer | `trainer` | 1 Wild Steelbloom; 1 Stranglekelp; 1 Leaded Vial | none | 30755 |
| 135 | Shadow Protection Potion | Vendor recipe | `book` | 1 Grave Moss; 1 Kingsblood; 1 Leaded Vial | none | 33015 |
| 140 | Elixir of Firepower | Trainer | `trainer` | 2 Fire Oil; 1 Kingsblood; 1 Leaded Vial | Fire Oil is Alchemy output | 35355 |
| 140 | Elixir of Lesser Agility | World-drop recipe | `book` | 1 Wild Steelbloom; 1 Swiftthistle; 1 Leaded Vial | none | 35355 |
| 150 | Elixir of Ogre's Strength | World-drop recipe | `book` | 1 Earthroot; 1 Kingsblood; 1 Leaded Vial | none | 40275 |
| 150 | Free Action Potion | Vendor recipe | `book` | 2 Blackmouth Oil; 1 Stranglekelp; 1 Leaded Vial | none | 40275 |

Acquisition mapping:

- world-drop/vendor recipe items -> `book`;
- profession-trainer recipes -> `trainer`;
- do not flatten book/vendor recipes into trainer recipes.

---

## 6. Authoritative item inventory

Serialize icon paths as `interface/icons/<icon>.blp`.

| Output | WoW item ID | Icon | ilvl | Req. level | Quality / stack | Intended RPE representation |
|---|---:|---|---:|---:|---|---|
| Blackmouth Oil | 6370 | `inv_drink_12` | 15 | — | common / 20 | Alchemy material; no `useSpellRef` |
| Elixir of Giant Growth | 6662 | `inv_potion_10` | 18 | 8 | common / 5 | +8 Strength for 10 turns through Spell/Aura; ignore cosmetic size growth |
| Elixir of Water Breathing | 5996 | `inv_potion_17` | 18 | 8 | common / 5 | Item + recipe only; **ignore gameplay use effect** |
| Elixir of Wisdom | 3383 | `inv_potion_06` | 20 | 10 | common / 5 | Guardian elixir Trait: +6 Intellect |
| Holy Protection Potion | 6051 | `inv_potion_09` | 20 | 10 | common / 5 | Classic absorb effect currently blocked; item metadata still implemented |
| Swim Speed Potion | 6372 | `inv_potion_13` | 20 | 10 | common / 5 | Item + recipe only; **ignore gameplay use effect** |
| Healing Potion | 929 | `inv_potion_51` | 22 | 12 | common / 5 | `useSpellRef`; heal self using midpoint `baseHealing = 320`, same convention as Minor Healing Potion |
| Minor Magic Resistance Potion | 3384 | `inv_potion_08` | 22 | 12 | common / 5 | `useSpellRef`; +25 five magic resistances for 15 turns |
| Lesser Mana Potion | 3385 | `inv_potion_71` | 24 | 14 | common / 5 | `useSpellRef`; restore fixed 320 Mana, same convention as Minor Mana Potion |
| Elixir of Poison Resistance | 3386 | `inv_potion_12` | 55 | 14 | common / 5 | Poison-category cleanse currently blocked; item metadata still implemented |
| Strong Troll's Blood Potion | 3388 | `inv_potion_78` | 25 | 15 | common / 5 | Guardian elixir Trait: +6 Spirit to reproduce current regen mapping |
| Fire Oil | 6371 | `inv_potion_38` | 25 | — | common / 20 | Alchemy material; no `useSpellRef` |
| Elixir of Defense | 3389 | `inv_potion_64` | 26 | 16 | common / 5 | Guardian elixir Trait: +150 Armor |
| Shadow Protection Potion | 6048 | `inv_potion_44` | 27 | 17 | common / 5 | Classic absorb effect currently blocked; item metadata still implemented |
| Elixir of Firepower | 6373 | `inv_potion_33` | 28 | 18 | common / 5 | Battle elixir Trait: **+10 generic Spell Power** (intentional RPE adaptation) |
| Elixir of Lesser Agility | 3390 | `inv_potion_92` | 28 | 18 | common / 5 | Battle elixir Trait: +8 Agility |
| Elixir of Ogre's Strength | 3391 | `inv_potion_57` | 30 | 20 | common / 5 | Battle elixir Trait: +8 Strength |
| Free Action Potion | 5634 | `inv_potion_04` | 30 | 20 | common / 5 | Future stun/root/snare immunity currently blocked; item metadata still implemented |

### 6.1 Stack-size rule

Use vanilla Classic stack sizes for this slice:

- ordinary potions/elixirs: **5**;
- Blackmouth Oil and Fire Oil: **20**.

---

## 7. Spell inventory for #208

### 7.1 Shared potion-use convention

The existing apprentice potion implementation establishes:

```lua
castTime = 0
cooldown = 10
cooldownGroup = "potion"
triggersGCD = false
ignoreGCD = true
learnMode = "unavailable"
```

Use this for normal 2-minute potion-cooldown items in this range.

Descriptions should be generated from the actual Spell components, as with the current Minor Healing/Minor Mana item-use Spells. Do not set `tooltipTemplate = true` without stored template data.

### 7.2 Healing Potion

**Status:** implementable using the established potion approximation.

- target: caster/self;
- cast time: 0;
- component: `heal`;
- `baseHealing = 320` (midpoint of source 280–360);
- no stat scaling;
- cooldown: 10;
- cooldown group: `potion`;
- ignore GCD / do not trigger GCD;
- item-only `learnMode = "unavailable"`;
- generated tooltip should describe healing using the current heal component's calculated range.

Do not add a new exact-min/max heal engine as part of this Alchemy slice.

### 7.3 Lesser Mana Potion

**Status:** implementable using the established potion approximation.

- target: caster/self;
- cast time: 0;
- component: `resource`;
- resource: Mana `f82db71a:4c8mfm99`;
- `amount = 320` (midpoint of source 280–360);
- cooldown: 10;
- cooldown group: `potion`;
- ignore GCD / do not trigger GCD;
- item-only `learnMode = "unavailable"`.

Do not add a ranged-resource engine as part of this slice.

### 7.4 Elixir of Giant Growth

**Status:** Strength effect implementable; cosmetic growth intentionally ignored.

- target: caster/self;
- cast time: 0;
- no resource cost;
- component: `apply_aura`;
- Aura duration: 10 turns;
- Aura effect: flat +8 Strength `f82db71a:zfqm8dxp`;
- the short Classic item-use throttle does not need a turn cooldown.

### 7.5 Minor Magic Resistance Potion

**Status:** implementable.

- target: caster/self;
- cast time: 0;
- cooldown: 10;
- cooldown group: `potion`;
- component: `apply_aura`;
- Aura duration: 15 turns;
- Aura effects:
  - +25 Fire resistance `f82db71a:0w7c7p09`;
  - +25 Frost resistance `f82db71a:jjn0my8k`;
  - +25 Nature resistance `f82db71a:pg0ytacb`;
  - +25 Arcane resistance `f82db71a:954yunb9`;
  - +25 Shadow resistance `f82db71a:itpo751d`.

Do not fabricate Holy resistance.

### 7.6 Intentionally ignored use effects

These items receive **no Spell and no Aura** for their source gameplay effect in this slice:

- Elixir of Water Breathing;
- Swim Speed Potion.

They are not blockers and do not require engine follow-up merely for this Alchemy implementation.

### 7.7 Remaining blocked manual-use effects

Do not attach fake `useSpellRef` values to these until the generic engine can model them:

| Item | Missing generic capability |
|---|---|
| Holy Protection Potion | school-specific absorb/shield pool |
| Elixir of Poison Resistance | remove multiple Auras by poison category/level with count limits |
| Shadow Protection Potion | school-specific absorb/shield pool |
| Free Action Potion | immunity to future stun/root/snare/movement-impair applications without clearing existing effects |

Elixir of Poison Resistance has a short Classic cooldown and must not be put in the shared normal-potion cooldown group if its cleanse is implemented later.

---

## 8. Embedded Trait inventory for #209

These use the existing Alchemy consumable-Trait model rather than item-use Spells:

| Item | Elixir type | RPE Trait effect |
|---|---|---|
| Elixir of Wisdom | guardian | +6 Intellect `f82db71a:75y3a8ib` |
| Strong Troll's Blood Potion | guardian | +6 Spirit `f82db71a:kec9rhli` |
| Elixir of Defense | guardian | +150 Armor `f82db71a:v42albuv` |
| Elixir of Firepower | battle | **+10 Spell Power `f82db71a:7t7xgzcx`** |
| Elixir of Lesser Agility | battle | +8 Agility `f82db71a:xqz0daz2` |
| Elixir of Ogre's Strength | battle | +8 Strength `f82db71a:zfqm8dxp` |

The Firepower mapping is a deliberate RPE balance/generalization choice; the underlying vanilla item remains named Elixir of Firepower.

---

## 9. Supporting material and dataset inventory

### 9.1 Existing Misc dataset

The repository already contains:

```text
data/default/professions/misc.lua
```

Dataset ID:

```text
3eb7e9bb
```

It is a packaged `items` dataset used for shared materials. **Large Venom Sac must be added there**, not to Alchemy and not to Fishing.

#209 must allocate a stable item ID for Large Venom Sac, preserve Misc's current item conventions, and increment the Misc packaged version monotonically.

### 9.2 New Fishing dataset

Create a new packaged dataset:

```text
data/default/professions/fishing.lua
```

It owns the fishing materials required by this Alchemy range:

- Oily Blackmouth;
- Deviate Fish;
- Firefin Snapper.

Requirements for the new dataset:

- allocate a new stable 8-character dataset ID;
- use `Addon.Data.DefaultDatasets:Register(...)` like the other packaged datasets;
- use `datasetType = "items"` unless the current implementation introduces a more appropriate packaged fishing type before #209;
- author the fish as ordinary material Items with their exact Classic names/icons/item metadata;
- preserve normal packaged version semantics, starting at version 1;
- add the file to the addon load manifest (`RPEngine_Dev.toc`) in the appropriate default-profession-data section;
- do not add Alchemy recipes or Spells to the Fishing dataset.

Alchemy recipes must reference the qualified Fishing item refs after #209 assigns them. The Alchemy dataset must include/derive the Fishing dataset dependency as required by the current dependency system.

### 9.3 Intermediate Alchemy outputs

These stay in `d6ffc4e2`:

- Blackmouth Oil;
- Fire Oil.

They are crafted Alchemy materials and are consumed by later recipes in the same range.

### 9.4 Existing inputs already available

The required herbs and vials already exist in canonical Alchemy, including Earthroot, Mageroyal, Briarthorn, Swiftthistle, Stranglekelp, Bruiseweed, Wild Steelbloom, Grave Moss, Kingsblood, Empty Vial, and Leaded Vial.

Before writing, #209/#210 must re-check current packaged data and reuse any exact material that another issue may have added first.

---

## 10. Remaining engine blockers

Three gameplay capability gaps remain genuine blockers for this slice:

1. **School absorb shields** — needed by Holy Protection Potion and Shadow Protection Potion.
2. **Aura-category cleansing** — needed by Elixir of Poison Resistance.
3. **Control immunity** — needed by Free Action Potion.

Any implementation of those capabilities should be generic engine work rather than Alchemy-specific hacks.

The following are explicitly **not** blockers for this slice:

- exact arbitrary healing ranges — use the established midpoint/base-heal convention;
- exact arbitrary resource ranges — use the established fixed midpoint convention;
- water breathing — ignored;
- swim speed — ignored;
- Fire-only spell power — deliberately generalized to generic Spell Power.

---

## 11. Implementation order

### #208 — Spells/Auras

Implement:

- Healing Potion Spell;
- Lesser Mana Potion Spell;
- Giant Growth Strength Spell/Aura;
- Minor Magic Resistance Spell/Aura.

Do not create use Spells for Water Breathing or Swim Speed. Do not approximate the three remaining blocker capability gaps.

### #209 — Items/materials

- add/complete all 18 Alchemy output Items;
- create `data/default/professions/fishing.lua` with Oily Blackmouth, Deviate Fish and Firefin Snapper;
- add Large Venom Sac to `data/default/professions/misc.lua`;
- update `RPEngine_Dev.toc` so Fishing loads as packaged default data;
- increment changed packaged dataset versions monotonically;
- wire `useSpellRef` for Healing Potion, Lesser Mana Potion, Giant Growth and Minor Magic Resistance according to #208;
- leave Water Breathing and Swim Speed without use effects by design;
- apply the embedded Trait mappings from §8, including +10 generic Spell Power for Elixir of Firepower;
- keep blocked items as complete item records without fake effects.

### #210 — Recipes

- implement all 18 recipes from §5;
- preserve trainer vs book acquisition;
- use the exact Empty/Leaded Vial inputs listed;
- reference Fishing for the three fish inputs;
- reference Misc for Large Venom Sac;
- reference Alchemy for Blackmouth Oil/Fire Oil intermediates;
- use current trainer-cost serialization semantics;
- do not add excluded/beta/later-era recipes.

---

## 12. Downstream validation checklist

### Dataset/inventory

- [ ] Exactly 18 `(75,150]` recipes are represented.
- [ ] No Cowardly Flight Potion.
- [ ] No Elixir of Minor Accuracy.
- [ ] Skill 150 included; >150 excluded.
- [ ] No Crystal-Vial substitution.

### Shared materials

- [ ] Large Venom Sac is defined in Misc `3eb7e9bb`, not Alchemy/Fishing.
- [ ] New `data/default/professions/fishing.lua` exists.
- [ ] Oily Blackmouth, Deviate Fish and Firefin Snapper exist exactly once in Fishing.
- [ ] Fishing has a unique stable dataset ID and packaged version.
- [ ] Fishing is loaded by the addon manifest.
- [ ] Alchemy recipe refs resolve across Fishing/Misc correctly.

### Items

- [ ] Blackmouth Oil/Fire Oil are Alchemy materials with stack 20.
- [ ] Normal potions/elixirs use stack 5.
- [ ] Water Breathing and Swim Speed have no gameplay-use Spell by design.
- [ ] Firepower grants +10 generic Spell Power.
- [ ] No fake Spell is attached to the remaining blocked effects.

### Spells/Auras

- [ ] Healing Potion uses `baseHealing = 320` and the same item-use/cooldown pattern as Minor Healing Potion.
- [ ] Lesser Mana Potion restores fixed 320 Mana and follows Minor Mana Potion's pattern.
- [ ] Normal potion Spells use 10-turn shared group `potion` where applicable.
- [ ] Minor Magic Resistance uses the five existing magic-resistance stats.
- [ ] Giant Growth's +8 Strength works; cosmetic size growth is ignored.

### Recipes

- [ ] Every input ref resolves to a packaged Item.
- [ ] Book/vendor/drop recipes do not become trainer recipes.
- [ ] Reagent quantities and skill thresholds match §5.

---

## 13. Source notes

Primary source family: Classic Wowhead `/classic/` item/spell/recipe records, cross-checked against Classic database records where acquisition/history was ambiguous.

Useful source records include:

- Blackmouth Oil: https://www.wowhead.com/classic/spell=7836/blackmouth-oil
- Giant Growth recipe: https://www.wowhead.com/classic/item=6663/recipe-elixir-of-giant-growth
- Water Breathing: https://www.wowhead.com/classic/spell=7179/elixir-of-water-breathing
- Wisdom: https://www.wowhead.com/classic/spell=3171/elixir-of-wisdom
- Holy Protection recipe: https://www.wowhead.com/classic/item=6053/recipe-holy-protection-potion
- Swim Speed: https://www.wowhead.com/classic/spell=7841/swim-speed-potion
- Healing Potion: https://www.wowhead.com/classic/spell=3447/healing-potion
- Minor Magic Resistance recipe: https://www.wowhead.com/classic/item=3393/recipe-minor-magic-resistance-potion
- Lesser Mana Potion: https://www.wowhead.com/classic/spell=3173/lesser-mana-potion
- Poison Resistance recipe: https://www.wowhead.com/classic/item=3394/recipe-elixir-of-poison-resistance
- Strong Troll's Blood Potion: https://www.wowhead.com/classic/spell=3176/strong-trolls-blood-potion
- Fire Oil: https://www.wowhead.com/classic/spell=7837/fire-oil
- Defense: https://www.wowhead.com/classic/spell=3177/elixir-of-defense
- Shadow Protection recipe: https://www.wowhead.com/classic/item=6054/recipe-shadow-protection-potion
- Firepower: https://www.wowhead.com/classic/spell=7845/elixir-of-firepower
- Lesser Agility recipe: https://www.wowhead.com/classic/item=3396/recipe-elixir-of-lesser-agility
- Ogre's Strength recipe: https://www.wowhead.com/classic/item=6211/recipe-elixir-of-ogres-strength
- Free Action recipe: https://www.wowhead.com/classic/item=5642/recipe-free-action-potion

The source records establish vanilla facts. The adaptations in §2 establish how RPE intentionally represents those facts.

---

## 14. Final implementation inventory

```text
80  Blackmouth Oil
90  Elixir of Giant Growth
90  Elixir of Water Breathing
90  Elixir of Wisdom
100 Holy Protection Potion
100 Swim Speed Potion
110 Healing Potion
110 Minor Magic Resistance Potion
120 Lesser Mana Potion
120 Elixir of Poison Resistance
125 Strong Troll's Blood Potion
130 Fire Oil
130 Elixir of Defense
135 Shadow Protection Potion
140 Elixir of Firepower
140 Elixir of Lesser Agility
150 Elixir of Ogre's Strength
150 Free Action Potion
```

This list, together with the project adaptations and ownership decisions above, is the authoritative source of truth for #208–#210.