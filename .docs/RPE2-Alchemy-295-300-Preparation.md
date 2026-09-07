# RPE 2 — Classic Alchemy 295–300 Preparation

**Issue:** #219  
**Target branch:** `dev`  
**Canonical Alchemy dataset:** `data/default/professions/alchemy.lua`  
**Alchemy dataset ID:** `d6ffc4e2`  
**Prepared against Alchemy dataset version:** 22  
**Range:** **`(295,300]`** — skill 295 excluded; skill 300 included.

## 1. Purpose and scope

This document is the authoritative implementation source of truth for the final vanilla Classic Alchemy slice: recipes requiring **Alchemy >295 and <=300**.

The validated vanilla set contains **7 recipes**, all at skill **300**:

1. Flask of Petrification
2. Flask of the Titans
3. Flask of Distilled Wisdom
4. Flask of Supreme Power
5. Flask of Chromatic Resistance
6. Major Rejuvenation Potion
7. Transmute: Elemental Fire

No valid vanilla recipe was identified at skill 296–299. The historical 1.12-era Alchemy table jumps from Major Mana Potion at 295 directly to the seven skill-300 entries above.

Implementation remains split across:

- #220 — item-use Spells and supporting Auras;
- #221 — Items and any genuinely missing shared material;
- #222 — Recipes.

No canonical Item, Spell, Aura, Recipe, or runtime implementation belongs in #219 itself. Alchemy remains version **22** after this preparation issue.

---

## 2. Source/version discipline

### 2.1 Vanilla Classic is authoritative

The skill-300 boundary is unusually vulnerable to expansion drift because Burning Crusade also contains recipes with a minimum skill of 300.

Use vanilla-era identity, skill requirement, reagents, quantities, output quantity, item metadata, and source effect. TBC/modern records are useful only to identify drift and must not replace vanilla values.

Primary evidence used for this preparation:

- historical pre-TBC Alchemy table dated 2006-01-10: <https://www.hellspark.com/dm/wow/Crafting/pre-WOTLK/old/Alchemy.pdf>
- Wowhead Classic spell/item records: <https://www.wowhead.com/classic/>
- ClassicDB legacy records: <https://classicdb.ch/>
- WoW Classic Database: <https://wowclassicdatabase.com/>
- WoWClassicDB spell records: <https://wowclassicdb.com/>
- Warcraft Wiki patch history where availability/version changes require reconciliation: <https://warcraft.wiki.gg/>

The 2006 Alchemy table is particularly useful at this boundary because it lists the final pre-TBC entries in order: skill 295 Major Mana Potion, followed by the five flasks, Major Rejuvenation Potion, and Transmute: Elemental Fire at 300.

### 2.2 Excluded: Alchemists' Stone

`Recipe: Alchemists' Stone` / `Alchemists' Stone` exists in Classic database data, but it was **not available to players in vanilla**.

Evidence:

- Wowhead Classic marks the item as unavailable to players: <https://www.wowhead.com/classic/item=13503/alchemists-stone>
- Warcraft Wiki records **Patch 2.0.3 (2007-01-09): Made available**: <https://warcraft.wiki.gg/wiki/Alchemist_Stone>

Therefore it is deliberately excluded from the vanilla `(295,300]` implementation despite appearing beside the valid skill-300 recipes in some database result sets.

### 2.3 TBC/seasonal contamination

Do not include recipes merely because they say `Requires Alchemy (300)` in a TBC or modern dataset. Examples of out-of-scope skill-300 TBC recipes include later Outland potions/elixirs such as Volatile Healing Potion, Onslaught Elixir, and Adept's Elixir.

Also exclude Season of Discovery, Anniversary-only, beta/test, and modern additions.

### 2.4 Current RPE learning-mode rule

Record the original vanilla acquisition source for provenance, but current project semantics override source acquisition for learnability:

```text
all recipes above skill 1 -> learnMode = "trainer"
```

Therefore **all 7 recipes in this slice must use `learnMode = "trainer"`** in #222, regardless of their original world-drop, boss-drop, or reputation-vendor source.

This supersedes the older source-based `trainer`/`book` mapping in earlier preparation documents.

---

## 3. Current RPE architecture inspected

This preparation was checked against current `dev` at Alchemy v22, not against assumptions from #215–#218.

### 3.1 Item-use path

`client/client_ItemUse.lua` still uses:

```text
Item.useSpellRef -> generic Spell activation -> components / Auras
```

A consumable exposes the direct Use path only when it is a consumable with a non-empty `useSpellRef`. Inventory consumption occurs only after the item-use cast is accepted.

Manual-use effects should therefore remain Spell-owned rather than duplicated inside Item data.

### 3.2 Consumable/flask model

`core/classes/Item.lua` currently supports these consumable types:

```text
potion | flask | elixir | scroll | rune | enhancement
```

`client/client_Traits.lua` has a dedicated `flask` selection category. The current default rules allow **one flask**, and event-phase `consumableTrait` data can supply event-scoped stat bonuses.

For representable vanilla flasks, the clean RPE model is therefore:

```text
itemType = "consumable"
consumableType = "flask"
consumableTrait.phase = "event_start"
```

This gives the existing one-flask selection semantics and an event-scoped effect that naturally survives unit death within the event. It is a better match for vanilla flask persistence than a short item-use Aura.

A flask is not an `elixir` in current schema terms, so `consumableElixirType` is not required for these records.

### 3.3 Recipe model

`core/classes/Recipe.lua` currently supports:

```text
learnMode = always_learned | trainer | book | unavailable
input.kind = rpe_item | tool
```

It does **not** expose a native recipe/transmute cooldown field or an Alchemy-Lab/workstation requirement.

`client/client_Crafting.lua` currently calculates trainer price as:

```text
floor(75 + requiredSkillLevel * 28 + requiredSkillLevel^2 * 1.6)
```

For every skill-300 recipe in this slice:

```text
trainerCostCopper = 152475
```

That is **15g 24s 75c** in RPE trainer-cost terms. Do not substitute the original recipe/vendor price.

### 3.4 Dependency limitation

Current dependency recomputation derives dependencies from Items, Traits, Spells, Auras, Stats, Resources and other runtime definitions, but the inspected path still does not provide Recipe input/output refs as a complete dependency source.

#222 must re-check live behavior. Do not broaden the final recipe implementation into a generic dependency-system redesign if the active packaged datasets already make these refs usable.

### 3.5 Relevant Core refs

| Meaning | Ref | Note |
|---|---|---|
| Alchemy | `f82db71a:pdyzyudy` | Recipe skill |
| Stamina | `f82db71a:ygjno50i` | Health source stat |
| Intellect | `f82db71a:75y3a8ib` | Mana source stat; approved Distilled Wisdom approximation despite derived side effects |
| Spell Power | `f82db71a:7t7xgzcx` | Generic damaging-spell power |
| Fire Resistance | `f82db71a:0w7c7p09` | |
| Frost Resistance | `f82db71a:jjn0my8k` | |
| Nature Resistance | `f82db71a:pg0ytacb` | |
| Arcane Resistance | `f82db71a:954yunb9` | |
| Shadow Resistance | `f82db71a:itpo751d` | |
| Damage Reduction | `f82db71a:pu05li08` | Percent semantics |
| Health | `f82db71a:q2ktkztt` | Derived from Stamina, multiplier 10 |
| Mana | `f82db71a:4c8mfm99` | Derived from Intellect, multiplier 10 |

There is no Holy Resistance stat in current Core. Do not invent one.

---

## 4. Complete vanilla recipe inventory

All seven recipes require Alchemy 300 and must use RPE `learnMode = "trainer"`.

| Recipe | Recipe item ID | Vanilla acquisition | Inputs | Output | Special source requirement | RPE trainer cost |
|---|---:|---|---|---|---|---:|
| Flask of Petrification | 13518 | Rare world drop | 30 Stonescale Oil; 10 Mountain Silversage; 1 Black Lotus; 1 Crystal Vial; Philosopher's Stone tool | 1 Flask of Petrification | Alchemy Lab | 152475 |
| Flask of the Titans | 13519 | General Drakkisath, Blackrock Spire | 30 Gromsblood; 10 Stonescale Oil; 1 Black Lotus; 1 Crystal Vial | 1 Flask of the Titans | Alchemy Lab | 152475 |
| Flask of Distilled Wisdom | 13520 | Stratholme drop; historically associated with Balnazzar | 30 Dreamfoil; 10 Icecap; 1 Black Lotus; 1 Crystal Vial | 1 Flask of Distilled Wisdom | Alchemy Lab | 152475 |
| Flask of Supreme Power | 13521 | Ras Frostwhisper, Scholomance | 30 Dreamfoil; 10 Mountain Silversage; 1 Black Lotus; 1 Crystal Vial | 1 Flask of Supreme Power | Alchemy Lab | 152475 |
| Flask of Chromatic Resistance | 13522 | Gyth, Upper Blackrock Spire | 30 Icecap; 10 Mountain Silversage; 1 Black Lotus; 1 Crystal Vial | 1 Flask of Chromatic Resistance | Alchemy Lab | 152475 |
| Major Rejuvenation Potion | 18257 | Molten Core boss drop | 1 Heart of the Wild; 4 Golden Sansam; 4 Dreamfoil; 1 Imbued Vial | 1 Major Rejuvenation Potion | none | 152475 |
| Transmute: Elemental Fire | 20761 | Lokhtos Darkbargainer, Blackrock Depths; Thorium Brotherhood Friendly | 1 Heart of Fire; Philosopher's Stone tool | 3 Elemental Fire | source 10-minute transmute cooldown | 152475 |

### 4.1 Acquisition evidence

- Flask of Petrification: <https://wowclassicdatabase.com/item/recipe-flask-of-petrification>
- Flask of the Titans: <https://wowclassicdatabase.com/item/recipe-flask-of-the-titans>
- Flask of Distilled Wisdom: <https://wowclassicdatabase.com/item/recipe-flask-of-distilled-wisdom>
- Flask of Supreme Power: <https://wowclassicdatabase.com/item/recipe-flask-of-supreme-power>
- Flask of Chromatic Resistance: <https://wowclassicdatabase.com/item/recipe-flask-of-chromatic-resistance>
- Major Rejuvenation Potion: <https://wowclassicdatabase.com/item/recipe-major-rejuvenation-potion>
- Transmute Elemental Fire: <https://wowclassicdatabase.com/item/recipe-transmute-elemental-fire>

For Major Rejuvenation Potion, legacy Classic data lists the Molten Core bosses Garr, Gehennas, Magmadar, Lucifron, Shazzrah, Golemagg the Incinerator and Baron Geddon as sources: <https://classicdb.ch/?item=18257>.

### 4.2 Alchemy Lab requirement

Vanilla flask creation requires an Alchemy Lab. The Classic crafting spell records expose that requirement directly, for example:

- Petrification: <https://wowclassicdb.com/spell/17634>
- Titans: <https://www.wowhead.com/classic/spell=17635/flask-of-the-titans>
- Distilled Wisdom: <https://wowclassicdb.com/spell/17636>
- Supreme Power: <https://wowclassicdb.com/spell/17637>
- Chromatic Resistance: <https://wowclassicdb.com/spell/17638>

Current RPE Recipe data has no workstation/Alchemy-Lab condition. #222 should preserve the recipe inputs that are representable and record this source restriction as unsupported. **Do not add a fake Alchemy-Lab reagent/tool.**

---

## 5. Output item metadata

| Output | WoW item ID | Item level | Required level | Quality | Classic stack | Icon | RPE type |
|---|---:|---:|---:|---|---:|---|---|
| Flask of Petrification | 13506 | 60 | 50 | common | 5 | `interface/icons/inv_potion_26.blp` | consumable / flask |
| Flask of the Titans | 13510 | 60 | 50 | common | 5 | `interface/icons/inv_potion_62.blp` | consumable / flask |
| Flask of Distilled Wisdom | 13511 | 60 | 50 | common | 5 | `interface/icons/inv_potion_97.blp` | consumable / flask |
| Flask of Supreme Power | 13512 | 60 | 50 | common | 5 | `interface/icons/inv_potion_41.blp` | consumable / flask |
| Flask of Chromatic Resistance | 13513 | 60 | 50 | common | 5 | `interface/icons/inv_potion_48.blp` | consumable / flask |
| Major Rejuvenation Potion | 18253 | 60 | 50 | common | 5 | `interface/icons/inv_potion_47.blp` | consumable / potion |
| Elemental Fire | 7068 | 25 | — | common | 10 | existing packaged record | material |

Representative output metadata sources:

- Petrification: <https://wowclassicdatabase.com/item/flask-of-petrification>
- Titans: <https://wowclassicdatabase.com/item/flask-of-the-titans>
- Distilled Wisdom: <https://wowclassicdatabase.com/item/flask-of-distilled-wisdom>
- Supreme Power: <https://wowclassicdatabase.com/item/flask-of-supreme-power>
- Chromatic Resistance: <https://wowclassicdatabase.com/item/flask-of-chromatic-resistance>
- Major Rejuvenation: <https://wowclassicdatabase.com/item/major-rejuvenation-potion>

The exact flask icons are also confirmed by the vanilla crafting-spell records linked in §4.2. Major Rejuvenation uses `inv_potion_47` in spell 22732 / legacy item data.

---

## 6. RPE gameplay representation decisions

### 6.1 Flask of Petrification — blocked exact effect

**Vanilla effect:** for 1 minute, turn to stone and become protected from physical attacks and spells, while unable to attack, move, or cast. One flask effect at a time.

Source: <https://www.wowhead.com/classic/spell=17634/flask-of-petrification>

Current RPE can represent pieces of this through Damage Reduction and control fields such as `preventCasting` / `movementRangeOverride`, but no verified generic Aura control cleanly suppresses **attacking** as well as casting and movement while also giving the full source immunity semantics.

Decision:

- Item metadata/classification: implement later as `consumableType = "flask"`.
- Do **not** attach a misleading partial Spell/Aura in #220/#221.
- Mark the gameplay effect blocked until a generic self-control/invulnerability capability can express all required action suppression and immunity semantics.
- Do not approximate this merely as +100% Damage Reduction, because the vanilla text protects against attacks/spells and also disables the user's actions.

Smallest missing generic capability: a complete control/invulnerability state that can suppress attack, movement and casting together with the intended incoming-effect immunity semantics.

### 6.2 Flask of the Titans — event-start Stamina trait

**Vanilla effect:** +1200 maximum health for 2 hours; one flask; persists through death.

Current Core Health is derived from Stamina at a multiplier of 10. Therefore the clean project adaptation is:

```text
consumableType = "flask"
consumableTrait.phase = "event_start"
+120 Stamina (f82db71a:ygjno50i)
```

This yields +1200 maximum Health in the current Core model and uses the existing one-flask/event-scoped trait system.

This is an explicit RPE adaptation: the source effect modifies maximum health directly, while RPE reaches the same health increase through its canonical source stat.

No `useSpellRef` is required.

### 6.3 Flask of Distilled Wisdom — event-start Intellect approximation

**Vanilla effect:** +2000 maximum mana for 2 hours; one flask; persists through death.

Current Core Mana is derived from Intellect at a multiplier of 10. The approved RPE approximation is therefore:

```text
consumableType = "flask"
consumableTrait.phase = "event_start"
+200 Intellect (f82db71a:75y3a8ib)
```

This yields +2000 maximum Mana in the current Core model and uses the existing one-flask/event-scoped trait system.

This is a deliberate approximation rather than an exact semantic match: Intellect also contributes to other Intellect-derived values such as Spell Critical Strike and derived skills. That side effect is accepted for this implementation.

No `useSpellRef` is required.

### 6.4 Flask of Supreme Power — event-start Spell Power trait

**Vanilla effect:** +150 damage from magical spells/effects for 2 hours; one flask; persists through death.

RPE representation:

```text
consumableType = "flask"
consumableTrait.phase = "event_start"
+150 Spell Power (f82db71a:7t7xgzcx)
```

This maps directly to the current generic damaging-spell stat. No `useSpellRef` is required.

### 6.5 Flask of Chromatic Resistance — event-start resistance trait

**Vanilla effect:** +25 resistance to all schools of magic for 2 hours; one flask; persists through death and stacks with other resistance effects.

RPE representation:

```text
consumableType = "flask"
consumableTrait.phase = "event_start"
+25 Fire Resistance
+25 Frost Resistance
+25 Nature Resistance
+25 Arcane Resistance
+25 Shadow Resistance
```

Refs:

```text
Fire   f82db71a:0w7c7p09
Frost  f82db71a:jjn0my8k
Nature f82db71a:pg0ytacb
Arcane f82db71a:954yunb9
Shadow f82db71a:itpo751d
```

Current Core has no Holy Resistance stat, so do not invent one.

No `useSpellRef` is required.

### 6.6 Major Rejuvenation Potion — direct dual restore Spell

**Vanilla effect:** restore **1440–1760 health and mana**, with a source 2-minute potion cooldown.

Source: <https://wowclassicdatabase.com/item/major-rejuvenation-potion>.

Use the established RPE midpoint adaptation:

```text
midpoint = 1600
```

#220 should implement one item-only self-use Spell with:

- direct heal: `baseHealing = 1600` using the current healing behavior;
- direct Mana restore: fixed `1600`, `resourceRef = "f82db71a:4c8mfm99"`;
- `castTime = 0`;
- `learnMode = "unavailable"`;
- `ignoreGCD = true`;
- `triggersGCD = false`;
- `cooldownGroup = "potion"`;
- current project potion cooldown = **10 turns**;
- no supporting Aura.

Do not set an Aura duration just because the potion cooldown is 10 turns.

### 6.7 Transmute: Elemental Fire — Recipe only

**Vanilla effect:** transmute 1 Heart of Fire into **3 Elemental Fire**, requiring a Philosopher's Stone.

Original source:

- Recipe item 20761;
- Lokhtos Darkbargainer in Blackrock Depths;
- Thorium Brotherhood Friendly;
- source recipe price 12g;
- source transmute cooldown **10 minutes**.

Sources:

- <https://wowclassicdatabase.com/item/recipe-transmute-elemental-fire>
- <https://www.wowhead.com/classic/spell=25146/transmute-elemental-fire>

RPE representation:

```text
learnMode = "trainer"
requiredSkillLevel = 300
input: 1 Heart of Fire, kind = "rpe_item"
input: Philosopher's Stone, kind = "tool"
output: 3 Elemental Fire
trainerCostCopper = 152475
```

No Item-use Spell is required.

Current Recipe schema cannot enforce the source 10-minute transmute cooldown. Preserve the recipe/tool/output data and document the cooldown limitation; do not fake it through unrelated Spell cooldown behavior.

---

## 7. Material ownership and canonical refs

### 7.1 Existing Alchemy-owned materials

All of these already exist in `data/default/professions/alchemy.lua` at v22:

| Material | Canonical ref |
|---|---|
| Gromsblood | `d6ffc4e2:rerdartb` |
| Stonescale Oil | `d6ffc4e2:d4sw4y04` |
| Dreamfoil | `d6ffc4e2:usfyk84u` |
| Mountain Silversage | `d6ffc4e2:dvzvvc52` |
| Icecap | `d6ffc4e2:irt83rqo` |
| Golden Sansam | `d6ffc4e2:m1cdfomm` |
| Crystal Vial | `d6ffc4e2:804x8qak` |
| Imbued Vial | `d6ffc4e2:5b2vp7y0` |
| Black Lotus | `d6ffc4e2:151j6hkf` |
| Philosopher's Stone | `d6ffc4e2:y9p4s8nt` |

No duplicate records should be added.

### 7.2 Existing Misc material

`Heart of the Wild` already exists in the Misc dataset:

```text
3eb7e9bb:w2plwren
```

Reuse it for Major Rejuvenation Potion.

### 7.3 Existing Enchanting elemental material

`Elemental Fire` already exists in the Enchanting dataset:

```text
732368d4:sclalidn
```

Reuse it as the 3-unit output of Transmute: Elemental Fire. Do not create an Alchemy duplicate.

### 7.4 Missing shared material: Heart of Fire

`Heart of Fire` is required by Transmute: Elemental Fire but is **not currently present** in the searched Alchemy, Misc, or Enchanting packaged data.

Vanilla metadata:

- WoW item ID: **7077**
- item level: **45**
- quality: **common**
- vanilla maximum stack: **10**
- icon: `interface/icons/spell_fire_lavaspawn.blp`
- type: shared elemental crafting material

Sources:

- <https://www.wowhead.com/classic/item=7077/heart-of-fire>
- <https://wowclassicdatabase.com/item/heart-of-fire>
- <https://warcraft.wiki.gg/wiki/Heart_of_Fire>

Ownership decision for #221:

- add Heart of Fire to **Enchanting** dataset `732368d4`, because the current project already owns shared elemental/essence materials there;
- preserve the exact vanilla metadata above;
- bump Enchanting's packaged version independently when the canonical file is modified;
- do not duplicate it in Alchemy or Misc.

No other new shared material is required by this slice.

---

## 8. Unsupported source mechanics / downstream constraints

### 8.1 Alchemy Lab

All five vanilla flasks require an Alchemy Lab. Current RPE Recipe schema has no workstation condition.

Decision: document only. Do not create a fake reagent/tool or generic runtime redesign under #222 unless separately scoped.

### 8.2 Transmute cooldown

Transmute: Elemental Fire has a vanilla 10-minute cooldown. Current Recipe schema has no crafting cooldown.

Decision: preserve source data in documentation, implement the representable recipe, and do not fake the cooldown.

### 8.3 Flask of Petrification

Blocked because the current generic control model does not cleanly provide the complete vanilla combination of incoming immunity and inability to attack/move/cast.

### 8.4 Flask of Distilled Wisdom approximation

The source effect is +2000 maximum Mana. RPE intentionally approximates that as +200 Intellect because Mana is derived at ×10. The resulting additional Intellect-derived bonuses are accepted as part of this approximation.

### 8.5 Recipe dependency discovery

Current dependency recomputation does not appear to derive complete cross-dataset dependencies from Recipe input/output refs. Re-check in #222, but keep the implementation data-focused unless this makes the actual recipes non-functional.

---

## 9. Downstream implementation inventory

### #220 — Spells/Auras

Implement only:

- Major Rejuvenation Potion self-use Spell: 1600 heal + 1600 Mana restore, potion cooldown 10.

Do not create Spells/Auras for:

- Titans — Trait-based;
- Distilled Wisdom — Trait-based;
- Supreme Power — Trait-based;
- Chromatic Resistance — Trait-based;
- Petrification — blocked;
- Transmute Elemental Fire — Recipe only.

### #221 — Items / shared outputs

Add the five flask Items and Major Rejuvenation Potion using §5 metadata.

Apply the exact representations from §6:

- Titans: +120 Stamina event-start flask Trait;
- Distilled Wisdom: +200 Intellect event-start flask Trait, accepting Intellect-derived side effects;
- Supreme Power: +150 Spell Power event-start flask Trait;
- Chromatic Resistance: +25 five Core resistances event-start flask Trait;
- Petrification: flask classification, no fake partial effect;
- Major Rejuvenation: `useSpellRef` to the exact #220 Spell.

Also add missing `Heart of Fire` to Enchanting `732368d4` with the §7.4 metadata and bump Enchanting independently.

Do not duplicate Elemental Fire; reuse `732368d4:sclalidn`.

### #222 — Recipes

Implement all seven recipes exactly once.

Every recipe uses:

```text
skillRef = "f82db71a:pdyzyudy"
learnMode = "trainer"
requiredSkillLevel = 300
trainerCostCopper = 152475
```

Use exact quantities from §4. Use `kind = "tool"` for Philosopher's Stone where required. Preserve output quantity 3 for Elemental Fire.

Document, but do not fake, Alchemy Lab and transmute cooldown restrictions.

---

## 10. Deterministic validation for downstream work

Before the final Classic Alchemy slice is considered complete, verify:

- exactly **7** vanilla `(295,300]` recipes are implemented;
- there are no 296–299 recipes to add;
- skill-295 Major Mana Potion is not duplicated;
- Alchemists' Stone remains excluded as unavailable until patch 2.0.3;
- no TBC/SoD/modern skill-300 recipe is introduced;
- every recipe is `learnMode = "trainer"` under current project semantics;
- every recipe uses Alchemy skill 300 and trainer cost 152475;
- exact vanilla reagents and quantities are preserved;
- all five flask recipes preserve the source Alchemy-Lab note without inventing a fake requirement;
- Petrification alone requires Philosopher's Stone among the five flask recipes;
- Transmute: Elemental Fire requires Philosopher's Stone as a reusable `tool` and outputs exactly 3 Elemental Fire;
- its source 10-minute cooldown is documented as unsupported;
- Major Rejuvenation uses **Imbued Vial**, not Crystal Vial;
- Major Rejuvenation uses midpoint 1600 for both health and Mana in the approved RPE Spell representation;
- Titans uses +120 Stamina as the deliberate +1200-Health adaptation;
- Distilled Wisdom uses the approved +200 Intellect approximation, with its additional Intellect-derived bonuses explicitly accepted;
- Supreme Power uses +150 Spell Power;
- Chromatic Resistance uses +25 to the five existing Core resistance stats and does not invent Holy Resistance;
- Petrification is not reduced to a misleading partial invulnerability effect;
- Heart of the Wild resolves to `3eb7e9bb:w2plwren`;
- Elemental Fire resolves to `732368d4:sclalidn`;
- Heart of Fire is added once to Enchanting, not duplicated across datasets;
- existing Alchemy/shared-material IDs are reused;
- packaged dataset versions increase only in implementation issues that actually modify those datasets.

---

## 11. Preparation result

The final vanilla Classic `(295,300]` implementation set is fixed at **7 recipes**, all skill 300.

The data is ready for sequential implementation through #220, #221, and #222 without re-researching recipe identity or re-deciding gameplay representation.

The one explicit gameplay blocker is:

1. **Flask of Petrification** — complete immunity/action-lock semantics are not cleanly expressible by the current generic Aura control model.

Flask of Distilled Wisdom is no longer blocked: it uses the approved **+200 Intellect** approximation for +2000 maximum Mana, accepting the extra Intellect-derived effects in RPE.

The two source crafting restrictions not currently expressible by Recipe data are:

1. **Alchemy Lab** for all five flasks.
2. **10-minute transmute cooldown** for Transmute: Elemental Fire.

These source restrictions are documented rather than approximated with incorrect crafting mechanics.