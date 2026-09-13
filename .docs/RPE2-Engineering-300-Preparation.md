# RPE2 Classic Engineering 300 Preparation

## Purpose and authority

This document is the implementation source of truth for the final **vanilla Classic Engineering recipes requiring exactly 300 Engineering skill**.

```text
required Engineering skill == 300
```

The same output scope used by the earlier Engineering preparation work applies:

- bombs and grenades;
- armour and wearable equipment;
- trinkets;
- weapons;
- potion-like consumables.

Classic Wowhead is authoritative for Classic recipe/item identity, source reagents, item metadata and active effects. Current RPE2 `dev` is authoritative for schema, packaged material ownership, runtime representability, existing item/spell abstractions and trainer-cost rules.

Primary source:

```text
https://www.wowhead.com/classic/guide/engineering-leveling-1-300-wow-classic
```

Individual Classic Wowhead recipe/item pages cited in the tables below are the detailed recipe sources.

## Scope result

The selected exact-300 inventory contains **8 outputs**:

1. Arcane Bomb
2. Arcanite Dragonling
3. Ultra-Flash Shadow Reflector
4. Core Marksman Rifle
5. Force Reactive Disk
6. Bloodvine Goggles
7. Bloodvine Lens
8. Flawless Arcanite Rifle

The following exact-300 recipes are intentionally excluded by the established scope:

| Output | Reason |
| --- | --- |
| Biznicks 247x128 Accurascope | Scope/modification |
| Field Repair Bot 74A | Standalone utility device |
| Any ammo/component/reagent output | Explicitly outside final-item scope |

Do not interpret this document as admitting TBC Engineering recipes that also start at 300. The boundary is **vanilla Classic recipes whose Classic recipe itself requires 300**.

## Current RPE implementation rules

- Engineering dataset: `af503002`.
- Engineering packaged version at preparation time: `17`.
- Engineering skill: `f82db71a:xprqs3y1`.
- Every eventual Recipe uses `learnMode = "trainer"`; original drop/vendor/reputation acquisition remains provenance only.
- Trainer cost at skill 300 uses the current RPE formula and is `152475` copper.
- Recursively flatten every Engineering intermediate to existing packaged external material leaves.
- Stop expansion at an existing canonical material Item owned by another packaged dataset; do not recursively decompose cross-dataset materials merely because WoW itself has a transmute/crafting source for them.
- Aggregate duplicate leaves after expansion.
- Preserve source output batch quantities exactly.
- Do not create missing shared/raw materials merely to make a recipe resolve. Report the recipe blocked instead.
- Blacksmith Hammer `61fdf3df:518sbr8g` remains the only supported reusable Engineering Recipe tool.
- Ignore source Arclight Spanner and Gyromatic Micro-Adjustor requirements as RPE `tool` inputs under the established Engineering rule.
- An Engineering-finished item used as a higher-tier source ingredient must be flattened through the **canonical RPE recipe already implemented for that item**, not preserved as an Engineering input.
- Item-use spells use the existing `Item.useSpellRef -> Spell` path only. Do not create bespoke item-use runtime code.

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

Current `dev` confirms the following relevant external packaged materials exist:

```text
Bloodvine               Misc
Fiery Core              Misc
Lava Core               Misc
Souldarite               Jewelcrafting
Dark Iron Bar            Blacksmithing
Thorium Bar              Blacksmithing
Truesilver Bar           Blacksmithing
Gold Bar                 Blacksmithing
Runecloth                Tailoring
Azerothian Diamond       Jewelcrafting
Large Opal               Jewelcrafting
Star Ruby                Jewelcrafting
Enchanted Thorium Bar    Enchanting
Enchanted Leather        Enchanting
Elemental Earth          Enchanting
Elemental Air            Enchanting
Living Essence           Enchanting
Essence of Undeath       Enchanting
Essence of Fire          Enchanting
Essence of Earth         Enchanting
```

Known qualified refs already established by the current Engineering preparation/implementation work include:

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

Implementation should resolve the live qualified refs for Souldarite, Enchanted Thorium Bar, Living Essence, Essence of Fire and Essence of Earth directly from their current owner datasets rather than copying stale IDs from older preparation files.

## Missing material blockers on current `dev`

The current packaged material audit does **not** resolve these required leaves:

- `Arcanite Bar`;
- `Ironweb Spider Silk`;
- `Powerful Mojo`.

Do not silently substitute them. The affected recipes are identified below.

`Arcanite Bar` is a final external material leaf for this Engineering preparation even though Classic obtains it through Alchemy transmutation. If a canonical packaged Arcanite Bar is later added, Engineering recipes should consume that item directly rather than flattening the transmute to Thorium Bar + Arcane Crystal.

## Component expansion rules

The prior Engineering component rules remain authoritative:

| Engineering intermediate | External-leaf expansion |
| --- | --- |
| Delicate Arcanite Converter x1 | Arcanite Bar x1; Ironweb Spider Silk x1 |
| Thorium Widget x1 | Thorium Bar x3; Runecloth x1 |
| Thorium Tube x1 | Thorium Bar x6 |
| Truesilver Transformer x1 | Truesilver Bar x2; Elemental Earth x2; Elemental Air x1 |
| Gold Power Core x1 | Gold Bar x1 |

### Mithril Mechanical Dragonling as an input

Arcanite Dragonling consumes one Mithril Mechanical Dragonling. Do **not** preserve that Engineering item as a Recipe input.

Use the canonical RPE flattened recipe already implemented for Mithril Mechanical Dragonling:

```text
Mithril Bar x19
Truesilver Bar x5
Gold Bar x1
Star Ruby x2
Goblin Rocket Fuel x2
Elemental Fire x4
Blacksmith Hammer tool
```

When incorporated into Arcanite Dragonling, aggregate its leaves with the higher-tier component expansions.

## Included inventory and item representation

| Skill | Output | WoW item ID | Category | Classic source | RPE representation status |
| ---: | --- | ---: | --- | --- | --- |
| 300 | Arcane Bomb | 16040 | Bomb | World-drop schematic | Item can be represented; exact active is only partially representable; Recipe blocked by missing Arcanite Bar + Ironweb Spider Silk |
| 300 | Arcanite Dragonling | 16022 | Trinket | World-drop schematic | Item/recipe metadata representable; summon active blocked pending canonical Unit; Recipe blocked by missing Arcanite Bar + Ironweb Spider Silk |
| 300 | Ultra-Flash Shadow Reflector | 18639 | Trinket | Stratholme drop schematic | Item + resistance abstraction + Recipe implementable |
| 300 | Core Marksman Rifle | 18282 | Weapon | Molten Core drop schematic | Weapon metadata representable; Recipe blocked by missing Arcanite Bar + Ironweb Spider Silk |
| 300 | Force Reactive Disk | 18168 | Armour/shield | Molten Core drop schematic | Base shield item representable; reactive-on-block proc blocked by current event model; Recipe blocked by missing Arcanite Bar + Ironweb Spider Silk |
| 300 | Bloodvine Goggles | 19999 | Armour/head | Zandalar Tribe Honored schematic | Most passive item metadata representable; Recipe blocked by missing Arcanite Bar + Ironweb Spider Silk + Powerful Mojo |
| 300 | Bloodvine Lens | 19998 | Armour/head | Zandalar Tribe Friendly schematic | Base armour/Stamina/crit representable; stealth detection blocked; Recipe blocked by missing Arcanite Bar + Ironweb Spider Silk + Powerful Mojo |
| 300 | Flawless Arcanite Rifle | 16007 | Weapon | World-drop schematic | Weapon metadata mostly representable; Recipe blocked by missing Arcanite Bar |

## Item details

### Arcane Bomb

Classic source:

```text
https://www.wowhead.com/classic/item=16055/schematic-arcane-bomb
https://www.wowhead.com/classic/item=16040/arcane-bomb
```

Source behavior:

- Item Level 60;
- Engineering 300;
- output batch: 3;
- drains 675–1125 mana from targets in the blast;
- deals damage equal to 50% of mana actually drained;
- silences targets for 5 seconds;
- 1 minute cooldown.

RPE representation decision:

- use the normal Engineering explosive multi-target pattern; no geometry/radius simulation;
- a silence Aura can be represented with generic control (`preventCasting = true`);
- current generic `resource` components are fixed/percentage changes and current damage components cannot derive their amount dynamically from the actual resource removed by a sibling component;
- therefore the **exact coupled random mana-drain -> 50%-of-drain damage effect is blocked** rather than approximated as a fixed value;
- do not encode a misleading fixed damage/drain spell without a later explicit design decision.

### Arcanite Dragonling

Classic source:

```text
https://www.wowhead.com/classic/item=16054/schematic-arcanite-dragonling
https://www.wowhead.com/classic/item=16022/arcanite-dragonling
```

Source metadata:

- Item Level 60;
- BoE, Unique Trinket;
- requires level 50;
- requires Engineering 300;
- use summons the dragonling for 1 minute;
- Classic cooldown: 1 hour.

RPE representation decision:

- represent as `itemType = "armor"`, cosmetic weight, Trinket slot, as with previous Engineering trinkets;
- preserve uniqueness through the existing item uniqueness mechanism;
- active summon remains blocked because `summon_pet` requires a canonical Unit ref and Engineering currently has no prepared Arcanite Dragonling Unit;
- do not create a dummy summon or approximate the guardian as direct damage.

### Ultra-Flash Shadow Reflector

Classic source:

```text
https://www.wowhead.com/classic/item=18658/schematic-ultra-flash-shadow-reflector
https://www.wowhead.com/classic/item=18639/ultra-flash-shadow-reflector
```

Source metadata:

- Item Level 60;
- BoE Trinket;
- +20 Shadow Resistance;
- requires level 55;
- requires Engineering 300;
- use reflects Shadow spells for 5 sec;
- 5 minute cooldown.

RPE representation decision:

- mirror the already-established Gyrofreeze/Hyper-Radiant abstraction;
- preserve passive +20 Shadow Resistance;
- active spell applies a 3-turn self Aura granting +100 Shadow Resistance;
- `learnMode = "unavailable"` for the item-use Spell;
- self-targeted, 5-turn cooldown, `ignoreGCD = true`;
- literal spell reflection remains unsupported and is intentionally not simulated.

### Core Marksman Rifle

Classic source:

```text
https://www.wowhead.com/classic/item=18292/schematic-core-marksman-rifle
https://www.wowhead.com/classic/item=18282/core-marksman-rifle
```

Source metadata:

- Item Level 65;
- BoE ranged gun;
- 64–120 damage;
- speed 2.50;
- requires level 60;
- +22 ranged Attack Power;
- +1% hit.

RPE representation decision:

- normal ranged gun item using the current Core ranged slot / gun weapon type;
- preserve source weapon damage range and passive ranged AP/hit using existing generic stat refs where available;
- no active spell.

### Force Reactive Disk

Classic source:

```text
https://www.wowhead.com/classic/item=18291/schematic-force-reactive-disk
https://www.wowhead.com/classic/item=18168/force-reactive-disk
```

Source metadata:

- Item Level 65;
- BoE off-hand Shield;
- 2548 Armor;
- 44 Block;
- +11 Stamina;
- requires level 60;
- on block, damages nearby enemies; 1-second internal cooldown; source also allows durability damage to the shield.

RPE representation decision:

- base shield equipment metadata can use existing item/equipment systems;
- preserve Stamina and supported armour/block stats where current Core refs exist;
- current generic Spell/Aura event keys do not include a block event, so the reactive electrical proc cannot be tied faithfully to a successful block;
- durability self-damage is likewise outside the generic trait/effect model;
- do not attach the proc to a broader `on_*_taken` event because that would trigger when no block occurred.

### Bloodvine Goggles

Classic source:

```text
https://www.wowhead.com/classic/item=20000/schematic-bloodvine-goggles
https://www.wowhead.com/classic/item=19999/bloodvine-goggles
```

Source metadata:

- Item Level 65;
- BoE Cloth Head;
- 75 Armor;
- requires level 60;
- +2% spell hit;
- +1% spell critical strike;
- restores 9 mana per 5 sec.

RPE representation decision:

- armour, spell-hit and spell-crit bonuses should use existing Core stats if present;
- mana-per-5 must not be converted to an arbitrary combat-turn value unless an existing canonical mana-regeneration stat/semantics already maps it consistently;
- if no such generic stat exists at implementation time, omit that unsupported passive and record it as incomplete rather than adding bespoke regeneration logic.

### Bloodvine Lens

Classic source:

```text
https://www.wowhead.com/classic/item=20001/schematic-bloodvine-lens
https://www.wowhead.com/classic/item=19998/bloodvine-lens
```

Source metadata:

- Item Level 65;
- BoE Leather Head;
- 147 Armor;
- +12 Stamina;
- requires level 60;
- +2% critical strike chance;
- slightly increases stealth detection.

RPE representation decision:

- armour, Stamina and generic critical chance are representable through normal item stats if the current Core stat mapping matches;
- stealth detection has no generic item-stat/runtime representation in the current Engineering architecture and remains unsupported;
- do not approximate stealth detection as hit or perception unless a canonical Core stat explicitly exists for that behavior at implementation time.

### Flawless Arcanite Rifle

Classic source:

```text
https://www.wowhead.com/classic/item=16056/schematic-flawless-arcanite-rifle
https://www.wowhead.com/classic/item=16007/flawless-arcanite-rifle
```

Source metadata:

- Item Level 61;
- BoE ranged gun;
- 65–122 damage;
- speed 3.00;
- requires level 56;
- +4 Guns;
- +10 ranged Attack Power.

RPE representation decision:

- normal ranged gun item;
- +10 ranged AP uses the existing stat if available;
- +4 Guns should use `skillBonuses` only if a canonical Guns skill exists in Core; otherwise leave only that bonus incomplete rather than mapping it to generic ranged hit.

## Final normalized recipe BOM

`Hammer` means Blacksmith Hammer `61fdf3df:518sbr8g` as a non-consumed `tool` input.

| Skill | Output | Final normalized external inputs | Output qty | Material status |
| ---: | --- | --- | ---: | --- |
| 300 | Arcane Bomb | Arcanite Bar x1; Ironweb Spider Silk x1; Thorium Bar x3; Runecloth x1; Hammer | 3 | **Blocked:** Arcanite Bar, Ironweb Spider Silk |
| 300 | Arcanite Dragonling | Mithril Bar x19; Truesilver Bar x5; Gold Bar x5; Star Ruby x2; Goblin Rocket Fuel x2; Elemental Fire x4; Arcanite Bar x8; Ironweb Spider Silk x8; Enchanted Thorium Bar x10; Thorium Bar x18; Runecloth x6; Enchanted Leather x6; Hammer | 1 | **Blocked:** Arcanite Bar, Ironweb Spider Silk |
| 300 | Ultra-Flash Shadow Reflector | Dark Iron Bar x8; Truesilver Bar x8; Elemental Earth x8; Elemental Air x4; Living Essence x6; Essence of Undeath x4; Azerothian Diamond x2; Large Opal x2; Hammer | 1 | **Complete** |
| 300 | Core Marksman Rifle | Fiery Core x4; Lava Core x2; Arcanite Bar x8; Ironweb Spider Silk x2; Thorium Bar x12; Hammer | 1 | **Blocked:** Arcanite Bar, Ironweb Spider Silk |
| 300 | Force Reactive Disk | Arcanite Bar x8; Ironweb Spider Silk x2; Essence of Air x8; Living Essence x12; Essence of Earth x8; Hammer | 1 | **Blocked:** Arcanite Bar, Ironweb Spider Silk |
| 300 | Bloodvine Goggles | Bloodvine x4; Souldarite x5; Arcanite Bar x2; Ironweb Spider Silk x2; Powerful Mojo x8; Enchanted Leather x4 | 1 | **Blocked:** Arcanite Bar, Ironweb Spider Silk, Powerful Mojo |
| 300 | Bloodvine Lens | Bloodvine x5; Souldarite x5; Arcanite Bar x1; Ironweb Spider Silk x1; Powerful Mojo x8; Enchanted Leather x4 | 1 | **Blocked:** Arcanite Bar, Ironweb Spider Silk, Powerful Mojo |
| 300 | Flawless Arcanite Rifle | Arcanite Bar x10; Thorium Bar x12; Essence of Fire x2; Essence of Earth x2; Azerothian Diamond x2; Enchanted Leather x2; Hammer | 1 | **Blocked:** Arcanite Bar |

### Tool provenance

Classic source tools are:

- Arcane Bomb: Blacksmith Hammer;
- Arcanite Dragonling: Blacksmith Hammer + Arclight Spanner;
- Ultra-Flash Shadow Reflector: Blacksmith Hammer + Arclight Spanner;
- Core Marksman Rifle: Blacksmith Hammer + Arclight Spanner;
- Force Reactive Disk: Blacksmith Hammer + Arclight Spanner;
- Bloodvine Goggles: Gyromatic Micro-Adjustor + Arclight Spanner;
- Bloodvine Lens: Gyromatic Micro-Adjustor + Arclight Spanner;
- Flawless Arcanite Rifle: Blacksmith Hammer + Arclight Spanner.

Under the RPE Engineering tool rule this becomes:

- retain Blacksmith Hammer only where the source requires it;
- Bloodvine Goggles and Bloodvine Lens receive **no RPE tool input**, because neither source recipe requires the Hammer and the Engineering-crafted tools are intentionally not modeled as reusable RPE tools.

## Spell / Aura preparation

### Ultra-Flash Shadow Reflector

Prepare one item-use Spell plus one Aura using the same pattern as the existing two reflectors:

```text
Spell:
- learnMode = unavailable
- item-only use
- caster/self target
- cooldown = 5 turns
- ignoreGCD = true
- applies Ultra-Flash Shadow Reflector aura

Aura:
- duration = 3 turns
- +100 Shadow Resistance
- refresh_duration
```

The source +20 Shadow Resistance remains a permanent item stat independent of the active Aura.

### Arcane Bomb

The source spell is not exactly representable with the current generic components:

```text
675-1125 mana drained
50% of actual mana drained -> damage
5 sec silence
multi-target
1 minute cooldown
```

The silence portion alone is representable, but the drain/damage coupling is not. Keep the active blocked as a whole until either:

1. a generic resource-drain component gains min/max amount plus an output/result value that a damage component can reference; or
2. the project explicitly approves a simplified approximation.

Do not add Arcane Bomb as a damage-only or silence-only active without that decision.

### Arcanite Dragonling

The item-use Spell cannot be completed until a canonical Arcanite Dragonling Unit exists. `summon_pet` requires `unitRef`; no unit should be invented as part of item/spell preparation alone.

### Force Reactive Disk

Do not create a proc Aura/trait until the generic event model has a successful-block trigger. The closest current events (`on_*_taken`) are semantically too broad.

## Item metadata summary

| Output | Item level | Required level | Binding | Key item data |
| --- | ---: | ---: | --- | --- |
| Arcane Bomb | 60 | — | Consumable | Stack 10; use effect above |
| Arcanite Dragonling | 60 | 50 | BoE, Unique | Trinket; 1-hour summon active |
| Ultra-Flash Shadow Reflector | 60 | 55 | BoE | Trinket; +20 Shadow Resistance |
| Core Marksman Rifle | 65 | 60 | BoE | Gun 64–120, speed 2.50; +22 ranged AP; +1% hit |
| Force Reactive Disk | 65 | 60 | BoE | Shield; 2548 Armor; 44 Block; +11 Stamina |
| Bloodvine Goggles | 65 | 60 | BoE | Cloth Head; 75 Armor; +2% spell hit; +1% spell crit; 9 mana/5 sec |
| Bloodvine Lens | 65 | 60 | BoE | Leather Head; 147 Armor; +12 Stamina; +2% crit; stealth detection |
| Flawless Arcanite Rifle | 61 | 56 | BoE | Gun 65–122, speed 3.00; +4 Guns; +10 ranged AP |

## Original acquisition provenance

All future RPE Recipe records still use `learnMode = "trainer"`.

| Output | Classic acquisition provenance |
| --- | --- |
| Arcane Bomb | World-drop schematic |
| Arcanite Dragonling | World-drop schematic |
| Ultra-Flash Shadow Reflector | Drop from Crimson/Risen Inquisitors in Stratholme |
| Core Marksman Rifle | Molten Core schematic drop |
| Force Reactive Disk | Molten Core schematic drop |
| Bloodvine Goggles | Zandalar Tribe Honored schematic |
| Bloodvine Lens | Zandalar Tribe Friendly schematic |
| Flawless Arcanite Rifle | World-drop schematic / Mossflayer Shadowhunter source |

Provenance must not be converted into `book`, faction or vendor learning behavior for the RPE Recipe implementation.

## Incomplete / Blocked Items and Recipes

| Entry | Complete | Missing / blocker | Type | Smallest follow-up |
| --- | --- | --- | --- | --- |
| Arcane Bomb | Source metadata, item shape, flattened BOM, silence representation | Arcanite Bar; Ironweb Spider Silk; exact variable drain -> dependent damage semantics | Missing materials + Spell semantics | Add/approve canonical leaves; add generic coupled resource/damage support or approve simplification |
| Arcanite Dragonling | Item metadata, flattened BOM | Arcanite Bar; Ironweb Spider Silk; canonical summon Unit | Missing materials + Unit dependency | Add/approve leaves and prepare Arcanite Dragonling Unit |
| Ultra-Flash Shadow Reflector | Item, spell abstraction, Aura plan, BOM | None for prepared scope | None | Ready for implementation |
| Core Marksman Rifle | Item metadata, flattened BOM | Arcanite Bar; Ironweb Spider Silk | Missing materials | Add/approve canonical leaves |
| Force Reactive Disk | Base item metadata, flattened BOM | Arcanite Bar; Ironweb Spider Silk; block-triggered proc event | Missing materials + runtime event semantics | Add/approve leaves; add generic successful-block event before proc implementation |
| Bloodvine Goggles | Item metadata, flattened BOM | Arcanite Bar; Ironweb Spider Silk; Powerful Mojo; possibly canonical mana-per-5 mapping | Missing materials + possible stat semantics | Add/approve leaves; verify generic mana regeneration stat before item implementation |
| Bloodvine Lens | Item metadata, flattened BOM | Arcanite Bar; Ironweb Spider Silk; Powerful Mojo; stealth detection | Missing materials + unsupported passive | Add/approve leaves; leave stealth detection omitted unless generic perception support is added |
| Flawless Arcanite Rifle | Weapon metadata, flattened BOM | Arcanite Bar; verify canonical Guns skill for +4 Guns | Missing material + possible skill ref | Add/approve Arcanite Bar; resolve Guns skill or omit only that bonus |

## Implementation sequencing

When implementation is requested, use the same staged pattern as the previous Engineering tier:

1. **Spell/Aura support** — Ultra-Flash Shadow Reflector and any newly-approved generic support only. Do not approximate blocked mechanics.
2. **Items** — all eight source items may be authored even when their recipes/actives remain blocked, provided unsupported behavior is not falsely represented.
3. **Recipes** — implement only those whose final flattened external leaves resolve at implementation time.

Do not add Engineering component Items/Recipes as a shortcut to satisfy the final recipes.

## Validation checklist

Before closing any implementation issue derived from this document, verify:

- every selected recipe has `requiredSkillLevel = 300`;
- no TBC 300+ recipe is introduced;
- all eventual recipes use `learnMode = "trainer"`;
- trainer cost is `152475` copper unless the live formula changes before implementation;
- every consumed input is an existing external packaged material or the supported Blacksmith Hammer tool;
- no Engineering intermediate/final lower-tier item remains as a consumed input after recursive flattening;
- Arclight Spanner and Gyromatic Micro-Adjustor are not RPE tool inputs;
- output quantities match Classic source data, including Arcane Bomb x3;
- Ultra-Flash Shadow Reflector follows the same abstraction as the existing frost/fire reflectors;
- blocked mechanics are not silently approximated;
- item IDs/names remain unique;
- Recipe IDs are collision-checked;
- Engineering packaged version increments monotonically from the live version;
- re-registration/reload does not duplicate records;
- the final implementation report lists any still-blocked entries explicitly.
