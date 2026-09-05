# RPE 2 — Classic Alchemy 75–150 Preparation

**Issue:** #207  
**Target branch:** `dev`  
**Canonical dataset:** `data/default/professions/alchemy.lua`  
**Dataset ID:** `d6ffc4e2`  
**Prepared against dataset version:** 7

## 1. Purpose and scope

This document is the implementation source of truth for the next Classic Alchemy slice. The included skill interval is **`(75,150]`**: recipes requiring Alchemy 76 through 150, with skill-150 recipes included.

The validated live-vanilla set contains **18 recipes/outputs**. It includes trainer recipes, world-drop/vendor recipe books, two crafted intermediate oils, direct-use potions, and long-duration elixirs. It deliberately excludes later-era/removed records even when current database indexes surface them beside Classic Alchemy data.

Implementation is split across:

- #208 — Spells/supporting Auras;
- #209 — Items/intermediate outputs/material ownership;
- #210 — Recipes.

No implementation data belongs in #207 itself.

---

## 2. Current RPE architecture inspected

The preparation was checked against the current `dev` implementation rather than the older design notes.

### 2.1 Item use

`client/client_ItemUse.lua` accepts inventory `itemType = "consumable"` items with a valid `useSpellRef`, resolves the referenced Spell through the Registry, passes the cast through the generic `ActivateSpellReference()` flow, and removes exactly one inventory item only after the cast is accepted.

Therefore manual potion effects should use `Item.useSpellRef` where the current Spell/Aura model can faithfully represent the effect.

### 2.2 Spell effects

`core/classes/Spell.lua` currently supports:

- `heal`;
- `resource`;
- `apply_aura`;
- `remove_aura` by an exact Aura ref;
- `damage`;
- `interrupt`;
- `revert`;
- `summon_pet`.

There is no generic absorb/shield component, no tag/category-wide Aura cleanse, and no future-control-immunity component.

### 2.3 Aura effects

`core/classes/Aura.lua` supports:

- flat/percent stat changes;
- skill changes;
- heal/resource/damage effects;
- nested Aura application;
- control fields `cancelOnDamage`, `preventCasting`, absolute `movementRangeOverride`, and `forceAutoHitAgainstTarget`.

It does **not** provide:

- school-specific absorb pools;
- immunity to future stun/root/snare effects;
- percentage movement/swim-speed modifiers;
- environmental water-breathing state.

### 2.4 Recipe semantics

`core/classes/Recipe.lua` supports `always_learned`, `trainer`, `book`, and `unavailable` learn modes. Consumed RPE materials use `inputs = { { kind = "rpe_item", itemRef = ..., quantity = ... } }`; one normalized output uses `output.itemRef/minQuantity/maxQuantity`.

Current trainer-cost calculation in `client/client_Crafting.lua` is:

```text
floor(75 + requiredSkillLevel * 28 + requiredSkillLevel^2 * 1.6)
```

Relevant values are:

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

For consistency with current packaged recipes, the serialized `trainerCostCopper` field may retain the calculated value even for `book` recipes; the `learnMode` remains authoritative and must not make a book recipe trainer-learnable.

### 2.5 Existing refs used by this range

Core refs already available:

| Meaning | Ref |
|---|---|
| Alchemy | `f82db71a:pdyzyudy` |
| Armor | `f82db71a:v42albuv` |
| Strength | `f82db71a:zfqm8dxp` |
| Agility | `f82db71a:xqz0daz2` |
| Spirit | `f82db71a:kec9rhli` |
| Intellect | `f82db71a:75y3a8ib` |
| Spell Power (all schools) | `f82db71a:7t7xgzcx` |
| Health resource | `f82db71a:q2ktkztt` |
| Mana resource | `f82db71a:4c8mfm99` |
| Fire resistance stat | `f82db71a:0w7c7p09` |
| Frost resistance stat | `f82db71a:jjn0my8k` |
| Nature resistance stat | `f82db71a:pg0ytacb` |
| Arcane resistance stat | `f82db71a:954yunb9` |
| Shadow resistance stat | `f82db71a:itpo751d` |

The current Core dataset has no school-scoped **Fire Spell Power** stat. `f82db71a:7t7xgzcx` is generic Spell Power and must not be substituted for a Fire-only bonus.

---

## 3. Version/source decisions

### 3.1 Vanilla Classic data is authoritative

Use the `/classic/` Classic-era records where they differ from modern/TBC/Cata current records. In particular, later database pages often substitute `Crystal Vial` or alter stack sizes/effects. Those changes must not leak into this slice.

Classic Wowhead and classic database records were used to resolve the recipe data below. Important examples:

- Healing Potion: https://www.wowhead.com/classic/spell=3447/healing-potion
- Minor Magic Resistance Potion: https://www.wowhead.com/classic/spell=3172/minor-magic-resistance-potion
- Elixir of Poison Resistance: https://www.wowhead.com/classic/item=3394/recipe-elixir-of-poison-resistance
- Shadow Protection Potion: https://www.wowhead.com/classic/item=6054/recipe-shadow-protection-potion
- Free Action Potion: https://www.wowhead.com/classic/item=5642/recipe-free-action-potion
- Giant Growth: https://www.wowhead.com/classic/item=6663/recipe-elixir-of-giant-growth
- Fire Oil: https://www.wowhead.com/classic/spell=7837/fire-oil
- Elixir of Firepower: https://www.wowhead.com/classic/spell=7845/elixir-of-firepower

### 3.2 Vial rules for this slice

The validated vanilla recipes use **Empty Vial** or **Leaded Vial**, not later Crystal-Vial substitutions.

Examples:

- Blackmouth Oil — Empty Vial;
- Healing Potion — Leaded Vial;
- Lesser Mana Potion — Empty Vial;
- Elixir of Firepower — Leaded Vial;
- Free Action Potion — Leaded Vial.

Both canonical vial refs already exist in Alchemy:

- Empty Vial: `d6ffc4e2:cycq8tn6`
- Leaded Vial: `d6ffc4e2:jdxdj7eh`

### 3.3 Poison-resistance naming

For vanilla Classic the canonical crafted item and recipe are **Elixir of Poison Resistance**. Later data/API presentations may expose `Potion of Curing`; do not rename the Classic output to that later name.

### 3.4 Excluded database records

Do **not** add:

- **Cowardly Flight Potion** — database/beta residue; historical Classic comments explicitly report it was not live;
- **Elixir of Minor Accuracy** — later-era/WotLK-era recipe, not a vanilla Classic `(75,150]` output;
- any SoD/Anniversary-only or TBC+ addition;
- anything requiring Alchemy >150.

### 3.5 Skill 150

Skill-150 recipes are part of this slice. Therefore **Elixir of Ogre's Strength** and **Free Action Potion** are included.

---

## 4. Authoritative recipe inventory

All recipes output quantity **1**.

| Skill | Recipe/output | Acquisition | RPE learnMode | Exact vanilla inputs | External/new material? | Cost field |
|---:|---|---|---|---|---|---:|
| 80 | Blackmouth Oil | Trainer | `trainer` | 2 Oily Blackmouth; 1 Empty Vial | Oily Blackmouth | 12555 |
| 90 | Elixir of Giant Growth | World-drop recipe | `book` | 1 Deviate Fish; 1 Earthroot; 1 Empty Vial | Deviate Fish | 15555 |
| 90 | Elixir of Water Breathing | Trainer | `trainer` | 1 Stranglekelp; 2 Blackmouth Oil; 1 Empty Vial | no; Blackmouth Oil is output in this slice | 15555 |
| 90 | Elixir of Wisdom | Trainer | `trainer` | 1 Mageroyal; 2 Briarthorn; 1 Empty Vial | no | 15555 |
| 100 | Holy Protection Potion | Vendor recipe | `book` | 1 Bruiseweed; 1 Swiftthistle; 1 Empty Vial | no | 18875 |
| 100 | Swim Speed Potion | Trainer | `trainer` | 1 Swiftthistle; 1 Blackmouth Oil; 1 Empty Vial | no | 18875 |
| 110 | Healing Potion | Trainer | `trainer` | 1 Bruiseweed; 1 Briarthorn; 1 Leaded Vial | no | 22515 |
| 110 | Minor Magic Resistance Potion | World-drop recipe | `book` | 3 Mageroyal; 1 Wild Steelbloom; 1 Empty Vial | no | 22515 |
| 120 | Lesser Mana Potion | Trainer | `trainer` | 1 Mageroyal; 1 Stranglekelp; 1 Empty Vial | no | 26475 |
| 120 | Elixir of Poison Resistance | World-drop recipe | `book` | 1 Large Venom Sac; 1 Bruiseweed; 1 Leaded Vial | Large Venom Sac | 26475 |
| 125 | Strong Troll's Blood Potion | Trainer | `trainer` | 2 Bruiseweed; 2 Briarthorn; 1 Leaded Vial | no | 28575 |
| 130 | Fire Oil | Trainer | `trainer` | 2 Firefin Snapper; 1 Empty Vial | Firefin Snapper | 30755 |
| 130 | Elixir of Defense | Trainer | `trainer` | 1 Wild Steelbloom; 1 Stranglekelp; 1 Leaded Vial | no | 30755 |
| 135 | Shadow Protection Potion | Vendor recipe | `book` | 1 Grave Moss; 1 Kingsblood; 1 Leaded Vial | no | 33015 |
| 140 | Elixir of Firepower | Trainer | `trainer` | 2 Fire Oil; 1 Kingsblood; 1 Leaded Vial | no; Fire Oil is output in this slice | 35355 |
| 140 | Elixir of Lesser Agility | World-drop recipe | `book` | 1 Wild Steelbloom; 1 Swiftthistle; 1 Leaded Vial | no | 35355 |
| 150 | Elixir of Ogre's Strength | World-drop recipe | `book` | 1 Earthroot; 1 Kingsblood; 1 Leaded Vial | no | 40275 |
| 150 | Free Action Potion | Vendor recipe | `book` | 2 Blackmouth Oil; 1 Stranglekelp; 1 Leaded Vial | no | 40275 |

### 4.1 Acquisition evidence/notes

- Giant Growth, Minor Magic Resistance, Poison Resistance, Lesser Agility and Ogre's Strength are recipe-item/world-drop recipes: use `book`.
- Holy Protection, Shadow Protection and Free Action are vendor-sold recipe items: also use `book`; the vendor source does not make them trainer recipes.
- The remaining entries above are profession-trainer recipes.

---

## 5. Authoritative item inventory

The icon column uses the Classic item/crafting-spell icon path. Serialize using the repository convention `interface/icons/<icon>.blp`.

| Output | WoW item ID | Icon | ilvl | Req. level | Quality / stack | Intended RPE type | Exact Classic effect / representation |
|---|---:|---|---:|---:|---|---|---|
| Blackmouth Oil | 6370 | `inv_drink_12` | 15 | — | common / 20 | material | Intermediate reagent; no `useSpellRef` |
| Elixir of Giant Growth | 6662 | `inv_potion_10` | 18 | 8 | common / 5 | consumable/elixir, battle | Size increase +8 Strength for 2 min. Implement +8 Strength through a 10-turn applied Aura; visual size change is unsupported cosmetic behavior |
| Elixir of Water Breathing | 5996 | `inv_potion_17` | 18 | 8 | common / 5 | consumable/elixir, generic | Breathe water for 30 min. **Blocked:** RPE has no underwater/breath state |
| Elixir of Wisdom | 3383 | `inv_potion_06` | 20 | 10 | common / 5 | consumable/elixir, guardian | +6 Intellect for 1 hour; use existing embedded consumable Trait with `f82db71a:75y3a8ib` +6 |
| Holy Protection Potion | 6051 | `inv_potion_09` | 20 | 10 | common / 5 | consumable/potion | Absorb 300–500 Holy damage; 1 hour; 2-min cooldown. **Blocked:** no school-specific absorb pool |
| Swim Speed Potion | 6372 | `inv_potion_13` | 20 | 10 | common / 5 | consumable/potion | +100% swim speed for 20 sec; 2-min cooldown. **Blocked:** no swim domain or percentage movement modifier |
| Healing Potion | 929 | `inv_potion_51` | 22 | 12 | common / 5 | consumable/potion | Restore 280–360 Health; 2-min cooldown. **Blocked for exact mechanics:** current heal amount uses fixed ±10% variance and cannot encode this exact 280–360 interval |
| Minor Magic Resistance Potion | 3384 | `inv_potion_08` | 22 | 12 | common / 5 | consumable/potion | +25 Fire/Frost/Nature/Arcane/Shadow resistance for 3 min; 2-min cooldown. Use Spell → 15-turn Aura with five +25 stat effects |
| Lesser Mana Potion | 3385 | `inv_potion_71` | 24 | 14 | common / 5 | consumable/potion | Restore 280–360 Mana; 2-min cooldown. **Blocked:** current `resource` effect applies one fixed amount and has no range/roll support |
| Elixir of Poison Resistance | 3386 | `inv_potion_12` | 55 | 14 | common / 5 | consumable/elixir, generic | Cure up to four poisons up to level 60; 3-sec cooldown. **Blocked:** `remove_aura` only removes an exact `auraRef`; no poison-category cleanse/level filtering/multi-aura selection |
| Strong Troll's Blood Potion | 3388 | `inv_potion_78` | 25 | 15 | common / 5 | consumable/elixir, guardian | Regenerate 6 Health/5 sec for 1 hour. Follow existing Troll's Blood mapping: +6 Spirit (`f82db71a:kec9rhli`) gives +1.2 Health/sec under Core regen multiplier 0.2 = 6/5 sec |
| Fire Oil | 6371 | `inv_potion_38` | 25 | — | common / 20 | material | Intermediate reagent; no `useSpellRef` |
| Elixir of Defense | 3389 | `inv_potion_64` | 26 | 16 | common / 5 | consumable/elixir, guardian | +150 Armor for 1 hour; embedded consumable Trait using `f82db71a:v42albuv` +150 |
| Shadow Protection Potion | 6048 | `inv_potion_44` | 27 | 17 | common / 5 | consumable/potion | Absorb 675–1125 Shadow damage; 1 hour; 2-min cooldown. **Blocked:** no school-specific absorb pool |
| Elixir of Firepower | 6373 | `inv_potion_33` | 28 | 18 | common / 5 | consumable/elixir, battle | +10 Fire spell damage for 30 min. **Blocked:** Core only has generic Spell Power; using it would incorrectly buff every spell school |
| Elixir of Lesser Agility | 3390 | `inv_potion_92` | 28 | 18 | common / 5 | consumable/elixir, battle | +8 Agility for 1 hour; embedded consumable Trait using `f82db71a:xqz0daz2` +8 |
| Elixir of Ogre's Strength | 3391 | `inv_potion_57` | 30 | 20 | common / 5 | consumable/elixir, battle | +8 Strength for 1 hour; embedded consumable Trait using `f82db71a:zfqm8dxp` +8 |
| Free Action Potion | 5634 | `inv_potion_04` | 30 | 20 | common / 5 | consumable/potion | Immune to Stun and movement-impairing effects for 30 sec; does not remove existing effects; 2-min cooldown. **Blocked:** current Aura control state cannot prevent future stun/root/snare applications |

### 5.1 Stack-size rule

Use the vanilla Classic stack sizes above: normal potions/elixirs stack to **5** and the two oils stack to **20**. Do not copy later TBC/modern stack sizes of 20/200/etc.

---

## 6. Spell inventory for #208

### 6.1 Shared potion-use convention

The current apprentice potion implementation maps the normal Classic 2-minute potion cooldown to:

```lua
cooldown = 10
cooldownGroup = "potion"
triggersGCD = false
ignoreGCD = true
```

Continue that convention for normal 2-minute-cooldown potions in this range.

Item-use spells are item-only definitions and should not become trainer/spellbook abilities. Use current item-only learn semantics (`unavailable`) unless current #208 source review establishes a more specific existing convention.

### 6.2 Implementable Spell/Aura definitions

#### Elixir of Giant Growth

**Status:** mechanically implementable for Strength; cosmetic growth unsupported.

Spell design:

- target: caster/self;
- cast time: 0;
- no resource cost;
- no normal potion cooldown required by the Classic item itself (its displayed cooldown is 3 sec, not 2 min); RPE turn granularity cannot meaningfully model 3 sec, so use no turn cooldown;
- component: `apply_aura`;
- supporting Aura duration: **10 turns** (2 minutes at the established 12 sec/turn mapping);
- Aura effect: flat +8 Strength, `f82db71a:zfqm8dxp`;
- generated tooltip must state the +8 Strength and 10-turn duration;
- note unsupported cosmetic size increase in #208/#209 validation; do not invent character-scale behavior.

#### Minor Magic Resistance Potion

**Status:** implementable.

Spell design:

- target: caster/self;
- cast time: 0;
- cooldown: 10 turns;
- cooldown group: `potion`;
- no resource cost; no GCD;
- component: `apply_aura`;
- supporting Aura duration: **15 turns** (3 minutes);
- five flat stat effects, +25 each:
  - Fire resistance `f82db71a:0w7c7p09`;
  - Frost resistance `f82db71a:jjn0my8k`;
  - Nature resistance `f82db71a:pg0ytacb`;
  - Arcane resistance `f82db71a:954yunb9`;
  - Shadow resistance `f82db71a:itpo751d`.

Classic does not expose a player Holy-resistance stat; do not fabricate one.

Expected generated meaning: increase all represented magic resistances by 25 for 15 turns.

### 6.3 Blocked manual-use Spells

The following should **not** receive fake `useSpellRef` values until their underlying gap is implemented:

| Item | Required engine capability |
|---|---|
| Elixir of Water Breathing | environmental underwater/breathing state |
| Holy Protection Potion | school-specific absorb/shield pool with remaining absorb amount |
| Swim Speed Potion | percentage swim-speed modifier distinct from absolute movement range |
| Healing Potion | exact min/max healing roll or per-effect variance bounds |
| Lesser Mana Potion | ranged/random `resource` restoration |
| Elixir of Poison Resistance | remove multiple Auras by poison category/level, capped at four |
| Shadow Protection Potion | school-specific absorb/shield pool |
| Elixir of Firepower | school-scoped Fire spell-power modifier/stat |
| Free Action Potion | immunity predicate that rejects future stun/root/snare movement-impair effects without removing existing ones |

### 6.4 Cooldown exceptions

Elixir of Poison Resistance has a **3-second** Classic cooldown and historical Classic comments explicitly distinguish it from the normal healing/mana potion timer. If/when its cleanse mechanic is implemented, do **not** put it in `cooldownGroup = "potion"`; RPE's turn granularity should treat the 3-second cooldown as no turn cooldown unless sub-turn cooldown support is later added.

Long-duration stat elixirs represented through the existing embedded `consumableTrait` system do not need synthetic `useSpellRef` spells merely to display the WoW 3-second use throttle.

---

## 7. Embedded Trait inventory for #209

These can use the established Alchemy consumable-Trait approach without new Spells:

| Item | Elixir type | Trait effect |
|---|---|---|
| Elixir of Wisdom | guardian | +6 Intellect `f82db71a:75y3a8ib` |
| Strong Troll's Blood Potion | guardian | +6 Spirit `f82db71a:kec9rhli` to reproduce 6 Health/5 sec under current derived regen |
| Elixir of Defense | guardian | +150 Armor `f82db71a:v42albuv` |
| Elixir of Lesser Agility | battle | +8 Agility `f82db71a:xqz0daz2` |
| Elixir of Ogre's Strength | battle | +8 Strength `f82db71a:zfqm8dxp` |

Elixir of Firepower must **not** use generic Spell Power because its source effect is Fire-only.

---

## 8. Supporting material inventory

### 8.1 New external ingredients

Repository search found no packaged definitions for these Classic ingredients:

| Material | Used by | Ownership decision |
|---|---|---|
| Oily Blackmouth | Blackmouth Oil | shared external/fishing material; add to canonical Misc/shared materials dataset, not Alchemy |
| Deviate Fish | Elixir of Giant Growth | shared external/fishing material; add to Misc/shared materials dataset |
| Large Venom Sac | Elixir of Poison Resistance | shared creature-drop material; add to Misc/shared materials dataset |
| Firefin Snapper | Fire Oil | shared external/fishing material; add to Misc/shared materials dataset |

#209 must re-run the packaged-data search immediately before writing in case another issue adds one of these first. If an exact canonical material now exists, reuse its qualified ref instead of duplicating it.

### 8.2 Intermediate Alchemy outputs

These belong in `d6ffc4e2` as crafted materials:

- Blackmouth Oil;
- Fire Oil.

They are then consumed by later recipes in the same range.

### 8.3 Existing inputs already available

All herbs and vials referenced by the inventory are already present in the canonical Alchemy dataset, including:

- Earthroot;
- Mageroyal;
- Briarthorn;
- Swiftthistle;
- Stranglekelp;
- Bruiseweed;
- Wild Steelbloom;
- Grave Moss;
- Kingsblood;
- Empty Vial;
- Leaded Vial.

---

## 9. Required engine follow-ups/blockers

The implementation issues should remain data-only where the current runtime already supports the source effect. The following capabilities are explicitly outside the current schema and should be split into generic engine issues rather than approximated inside Alchemy data:

1. **School absorb shields** — Aura state with remaining absorb amount, restricted to one/more damage schools, consumed as matching damage is absorbed.
2. **Ranged resource restoration** — `resource` effects need a deterministic min/max/random amount mechanism comparable to a real potion roll.
3. **Exact ranged healing** — heal effects currently derive their range from fixed ±10% variance; add explicit min/max or configurable variance where source effects require other intervals.
4. **Aura-category cleansing** — remove matching Auras by category/tag/dispel type with count/level limits; needed for poison resistance.
5. **Control immunity** — prevent future applications of stun/root/snare/movement-impair effects while allowing already-active effects to remain; needed for Free Action Potion.
6. **Percentage swim/movement modifiers** — current `movementRangeOverride` is an absolute override and cannot stand in for +100% swim speed.
7. **Environmental water breathing** — no current underwater breath state.
8. **School-scoped spell-power bonuses** — Firepower must affect Fire spell damage only, not generic Spell Power.

Until those capabilities exist, #208/#209 should implement the canonical item metadata but leave the relevant manual-use `useSpellRef` absent and cite the blocker.

---

## 10. Implementation order

### #208 — Spells/Auras

Implement only currently representable manual-use behavior:

- Giant Growth Strength Aura/Spell (with cosmetic-size limitation documented);
- Minor Magic Resistance Aura/Spell.

Do not approximate the blocker items listed above.

### #209 — Items/materials

- add/complete all 18 output Items;
- add four external shared materials to the correct shared dataset if still absent;
- add exact icons/levels/stack sizes from §5;
- wire `useSpellRef` only to Spells actually implemented by #208;
- apply the embedded Trait mappings from §7;
- preserve blocker items as complete item records without fake effects.

### #210 — Recipes

- implement all 18 recipe records from §4;
- preserve `trainer` vs `book` acquisition exactly;
- use Empty vs Leaded Vial exactly as listed;
- reference the canonical shared external ingredients and intermediate oils;
- use the current RPE trainer-cost formula/serialization convention;
- do not add excluded/beta/later-era recipes.

---

## 11. Validation checklist for downstream issues

### Dataset/inventory

- [ ] Exactly 18 `(75,150]` recipes are represented.
- [ ] No Cowardly Flight Potion.
- [ ] No Elixir of Minor Accuracy.
- [ ] Skill 150 is included; >150 is excluded.
- [ ] Classic names remain exact, including Strong Troll's Blood **Potion** and Elixir of Poison Resistance.
- [ ] No Crystal-Vial substitution enters the vanilla recipe records.

### Items

- [ ] Vanilla icon paths, item levels, required levels and stack sizes match §5.
- [ ] Blackmouth Oil/Fire Oil are material outputs with stack 20.
- [ ] Normal potions/elixirs use stack 5.
- [ ] No fake use Spell is attached to a blocked effect.

### Spells/Auras

- [ ] Normal 2-minute potion cooldowns use 10 turns and shared group `potion` where implemented.
- [ ] Elixir of Poison Resistance is not put on the normal potion cooldown group.
- [ ] Minor Magic Resistance uses the five existing magic-resistance stats and does not invent Holy resistance.
- [ ] Firepower does not use generic Spell Power.
- [ ] Percentage movement/swim effects do not use absolute `movementRangeOverride` as an approximation.

### Recipes

- [ ] Every input ref resolves to a packaged Item.
- [ ] Book/vendor/drop recipes do not become trainer recipes.
- [ ] Recipe quantities and skill thresholds match §4 exactly.

---

## 12. Source notes

Primary source family: Classic Wowhead `/classic/` item/spell/recipe records, cross-checked against Classic database records where acquisition/history was ambiguous.

Useful records include:

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

Icon spell data was cross-checked against the spell records/Classic API data; implementation should use the paths in §5, not modern replacement icons.

---

## 13. Final implementation inventory

The authoritative `(75,150]` vanilla Classic output list is:

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

This list, together with the exact recipe/item/effect decisions above, is the source of truth for #208–#210.