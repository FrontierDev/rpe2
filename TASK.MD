## Context

**Implement this issue last.** It depends on #355, #356, #357, #358, #359, #360 and the regression gate #361.

See `docs/PDD-Cooldown-Channels.md`.

All runtime/UI/autopilot behavior must already be channel-native before this issue begins. This issue is the deliberate data migration and final schema cutover. Do not start it while any earlier cooldown-channel issue remains incomplete/unvalidated.

## Goal

1. Give **every current default Spell entry** an explicit `cooldownChannel` assignment.
2. Remove spell-level `triggersGCD` / `ignoreGCD` fields from the migrated default dataset records.
3. Make new Spell serialization use `cooldownChannel` as the sole action-economy field.
4. Retain a narrow legacy **input/import** compatibility path for older third-party/user datasets that still contain old GCD flags.
5. Remove the obsolete basic-attack ruleset GCD override now that basic attacks have explicit channel assignments.

## Channel meanings

Use the default channel identities from #355:

| ID | Default name | Channel GCD | Meaning |
|---:|---|---|---|
| 1 | Main Action | yes | Primary attacks, direct heals, primary control/actions |
| 2 | Bonus Action | yes | Auxiliary/off-action attacks, control, reactions and item-use actions |
| 3 | Buff Action | yes | Beneficial aura/buff/defensive setup actions |
| 4 | Free Action | no | Actions intentionally not limited by a channel GCD; current defaults use this for basic auto-attacks with their separate basic-attack restriction |

**Do not mechanically infer final assignments from the old flags. Use the explicit inventory below.** In particular, buffs are deliberately moved to Channel 3, and basic auto-attacks to Channel 4.

## Source-first requirements

Before editing:

- re-read every affected `data/default/**` file from current `dev`;
- enumerate its actual `dataset.spells` entries and compare them with the inventory below;
- inspect any commits made by #355-#361 so the final schema/serializer cleanup matches the implemented compatibility boundary;
- search the entire repository for remaining spell-level `triggersGCD` / `ignoreGCD` use;
- do not assume IDs/names below are the only changes made to these files since this issue was written.

If the current default spell inventory differs from this issue because new spells were added after issue creation, **do not silently omit them**: explicitly assign every newly added default spell according to the same channel semantics and document the extra entries in the implementation notes.

Expected inventory at issue creation: **185 default Spell entries** across Core, Mage, Paladin, Priest, Rogue, Warrior, Alchemy and Engineering.

---

# Required default spell assignments

## `data/default/core.lua` — 8 spells

| ID | Spell | Channel |
|---|---|---:|
| `z36xzk0w` | Main Hand Attack | **4 — Free Action** |
| `wydraqj8` | Mounted Attack | **4 — Free Action** |
| `6uix049h` | Pet Attack | **1 — Main Action** |
| `gn37lpvz` | Summon Pet | **2 — Bonus Action** |
| `shoota01` | Shoot | **4 — Free Action** |
| `throwa01` | Throw | **4 — Free Action** |
| `wandauto` | Wand | **4 — Free Action** |
| `zd3t6feq` | Off Hand Attack | **4 — Free Action** |

The Channel 4 assignments above replace the old `basic_attacks_do_not_consume_gcd` behavior for basic auto-attacks. Their separate basic-attack per-turn/damage-type restriction from #359 remains in force.

`Pet Attack` is not to be reclassified as a basic auto attack merely because it is in Core; retain Channel 1 unless current source inspection shows its existing `hitType` was explicitly part of the basic-auto restriction.

---

## `data/default/classes/mage.lua` — 22 spells

### Channel 1 — Main Action

| ID | Spell |
|---|---|
| `68dy7na1` | Fireball |
| `kwn6xary` | Pyroblast |
| `hsr88j7d` | Scorch |
| `zilla37l` | Flamestrike |
| `1s5lq169` | Arcane Explosion |
| `n6jbep9e` | Arcane Blast |
| `s9nxh61d` | Evocation |
| `lywroiqu` | Frostbolt |
| `apgdbmji` | Cone of Cold |
| `jg39ti4j` | Glacial Spike |

### Channel 2 — Bonus Action

| ID | Spell |
|---|---|
| `96ygwvhq` | Fire Blast |
| `r760qxbn` | Arcane Barrage |
| `1e8l0iyi` | Arcane Missiles |
| `300h0gls` | Counterspell |
| `7ha8pdoy` | Frost Nova |
| `5p4lvyfy` | Deep Freeze |
| `4yxpy77f` | Ice Lance |

### Channel 3 — Buff Action

| ID | Spell |
|---|---|
| `m3u708kt` | Combustion |
| `fireward` | Fire Ward |
| `frostwrd` | Frost Ward |
| `7r260xa0` | Arcane Surge |
| `7ldwq2a9` | Arcane Intellect |

---

## `data/default/classes/paladin.lua` — 35 spells

### Channel 1 — Main Action

| ID | Spell |
|---|---|
| `wmp0b1zn` | Judgement of the Righteous |
| `kyzga5f2` | Judgement of Command |
| `pb305qze` | Judgement of the Light |
| `j1my2871` | Judgement of Wisdom |
| `27baiuv3` | Crusader Strike |
| `eg4gydsa` | Templar's Verdict |
| `d1pmq58z` | Hammer of the Righteous |
| `9nwvhorx` | Holy Light |
| `znfbmec8` | Flash of Light |
| `4wt3pl5q` | Exorcism |
| `x8ljrb7w` | Holy Wrath |
| `tu5g28q8` | Divine Storm |
| `pznrmr50` | Blade of Wrath |
| `hork7m2p` | Hand of Reckoning |
| `5ouonxor` | Word of Glory |

### Channel 2 — Bonus Action

| ID | Spell |
|---|---|
| `pz4cufo7` | Shield of the Righteous |
| `kskvgnmw` | Rebuke |
| `x2qgj4wy` | Light of the Protector |
| `hoj2q6x4` | Hammer of Justice |
| `rep7n4c8` | Repentance |

### Channel 3 — Buff Action

All Blessings intentionally share the Buff Action channel while their existing `blessing` cooldown-group behavior remains independent.

| ID | Spell |
|---|---|
| `h981ofan` | Blessing of Might |
| `wfq254qz` | Blessing of Kings |
| `zg4n0a1f` | Blessing of Sanctuary |
| `xdt25qxt` | Blessing of Wisdom |
| `ms0v0du4` | Blessing of Light |
| `25j5h8f2` | Blessing of Salvation |
| `xvfmhwn2` | Seal of Righteousness |
| `uesn7obf` | Seal of Command |
| `25h4rwgt` | Seal of Light |
| `vuotim0h` | Seal of Wisdom |
| `0opb1tte` | Divine Protection |
| `bk0uyunm` | Divine Favor |
| `gak8p3v1` | Guardian of Ancient Kings |
| `awr9m5d2` | Avenging Wrath |
| `tplblwsp` | Templar's Bulwark |

---

## `data/default/classes/priest.lua` — 21 spells

### Channel 1 — Main Action

| ID | Spell |
|---|---|
| `eet5xd4t` | Heal |
| `dbk3frh2` | Greater Heal |
| `b7dot26a` | Binding Heal |
| `5yht8j0f` | Flash Heal |
| `rm9rekvj` | Smite |
| `1x1q35og` | Holy Fire |
| `3ctxnb99` | Psychic Scream |
| `k71jmcz0` | Vampiric Touch |
| `oe32yzws` | Mind Blast |
| `vmtnl0y4` | Mind Spike |
| `u8dvti6t` | Mind Flay |
| `3z4hi35b` | Shadow Word: Death |

### Channel 2 — Bonus Action

| ID | Spell |
|---|---|
| `h3n22bv2` | Lesser Heal |
| `5q7jx4c1` | Psychic Horror |
| `drza38ax` | Shadow Word: Pain |

### Channel 3 — Buff Action

| ID | Spell |
|---|---|
| `hhxhszcv` | Prayer of Fortitude |
| `pwshld01` | Power Word: Shield |
| `qqkkenuw` | Renew |
| `mnuc5di4` | Pain Suppression |
| `lg9aex8t` | Divine Spirit |
| `ilkjmlyk` | Prayer of Shadow Protection |

---

## `data/default/classes/rogue.lua` — 17 spells

### Channel 1 — Main Action

| ID | Spell |
|---|---|
| `g9o4t7uj` | Sinister Strike |
| `pfskjkhi` | Ambush |
| `3yvu5lwf` | Backstab |
| `7scy4qhi` | Mutilate |
| `i2uuda23` | Ghostly Strike |
| `7x7itakn` | Hemmorhage |
| `v0mihgpd` | Garrote |

`Hemmorhage` is intentionally spelled as it currently appears in the dataset; do not opportunistically rename content in this migration.

### Channel 2 — Bonus Action

| ID | Spell |
|---|---|
| `am7ew5wl` | Eviscerate |
| `ugc0mlrz` | Rupture |
| `300h0gls` | Kick |
| `i8x4n8kh` | Gouge |
| `yql2eonk` | Kidney Shot |

### Channel 3 — Buff Action

| ID | Spell |
|---|---|
| `stealth01` | Stealth |
| `kbifnqpj` | Evasion |
| `wf9orqz9` | Adrenaline Rush |
| `gp51edzy` | Slice and Dice |
| `t7gns8bg` | Cold Blood |

---

## `data/default/classes/warrior.lua` — 22 spells

### Channel 1 — Main Action

| ID | Spell |
|---|---|
| `e0mooybr` | Cleave |
| `0jiq0uoc` | Mortal Strike |
| `68qm26aq` | Slam |
| `etsuhe6x` | Sunder Armor |
| `kejakdxo` | Shield Slam |
| `tntwar01` | Taunt |
| `k7ndyn09` | Whirlwind |
| `bblnsvg2` | Bladestorm |
| `05yeh7qb` | Bloodthirst |

### Channel 2 — Bonus Action

| ID | Spell |
|---|---|
| `c1s93sif` | Heroic Strike |
| `ti2j4umn` | Shield Bash |
| `xniv44uu` | Rend |
| `9870xnra` | Knockdown |
| `s4nfrf2l` | Intimidating Shout |
| `mn1ltzeo` | Revenge |
| `0ttffa47` | Intervene |

### Channel 3 — Buff Action

| ID | Spell |
|---|---|
| `yn5l4xkq` | Bloodrage |
| `g36ujwt9` | Shield Block |
| `9gh28pe5` | Battle Shout |
| `c6j8zcqx` | Commanding Shout |
| `lzan8taw` | Inner Rage |
| `tkb4huco` | Shield Wall |

---

## `data/default/professions/alchemy.lua` — 35 spells

All current Alchemy Spell entries are item-use actions. Assign **every spell below to Channel 2 — Bonus Action**.

This deliberately preserves a one-per-Bonus-Action action-economy limit rather than converting every potion into unlimited Free Actions. Their own cooldowns and potion cooldown groups remain unchanged.

1. Minor Healing Potion — **2**
2. Minor Mana Potion — **2**
3. Minor Rejuvenation Potion — **2**
4. Discolored Healing Potion — **2**
5. Lesser Healing Potion — **2**
6. Rage Potion — **2**
7. Healing Potion — **2**
8. Lesser Mana Potion — **2**
9. Elixir of Giant Growth — **2**
10. Minor Magic Resistance Potion — **2**
11. Greater Healing Potion — **2**
12. Mana Potion — **2**
13. Great Rage Potion — **2**
14. Greater Mana Potion — **2**
15. Superior Healing Potion — **2**
16. Wildvine Potion — **2**
17. Magic Resistance Potion — **2**
18. Lesser Stoneshield Potion — **2**
19. Mighty Rage Potion — **2**
20. Superior Mana Potion — **2**
21. Major Healing Potion — **2**
22. Major Mana Potion — **2**
23. Shadow Protection Potion — **2**
24. Fire Protection Potion — **2**
25. Frost Protection Potion — **2**
26. Nature Protection Potion — **2**
27. Greater Arcane Protection Potion — **2**
28. Greater Fire Protection Potion — **2**
29. Greater Frost Protection Potion — **2**
30. Greater Nature Protection Potion — **2**
31. Greater Shadow Protection Potion — **2**
32. Greater Stoneshield Potion (`qn3x6yta`) — **2**
33. Limited Invulnerability Potion (`li100drs`) — **2**
34. Mageblood Potion — **2**
35. Major Rejuvenation Potion — **2**

Match by the actual Spell entry under `dataset.spells`, not recipe/item entries with the same display name.

---

## `data/default/professions/engineering.lua` — 25 spells

All current Engineering Spell entries are item/equipment-use actions. Assign **every spell below to Channel 2 — Bonus Action**.

This preserves a bounded action-economy cost for bombs, explosives and devices. Do not turn these into Channel 4 merely because the old records used `triggersGCD=false`.

1. Rough Dynamite — **2**
2. Rough Copper Bomb — **2**
3. Coarse Dynamite — **2**
4. EZ-Thro Dynamite — **2**
5. Large Copper Bomb — **2**
6. Small Bronze Bomb — **2**
7. Heavy Dynamite — **2**
8. Big Bronze Bomb — **2**
9. Flame Deflector — **2**
10. Ice Deflector — **2**
11. Solid Dynamite — **2**
12. Iron Grenade — **2**
13. Big Iron Bomb — **2**
14. EZ-Thro Dynamite II — **2**
15. Goblin Sapper Charge — **2**
16. Mithril Frag Bomb — **2**
17. Flash Bomb — **2**
18. Hi-Explosive Bomb — **2**
19. Thorium Grenade — **2**
20. Dark Iron Bomb — **2**
21. Gyrofreeze Ice Reflector — **2**
22. Hyper-Radiant Flame Reflector (`b43cd027`) — **2**
23. Major Recombobulator — **2**
24. Ultra-Flash Shadow Reflector — **2**
25. Arcane Bomb — **2**

Match by `dataset.spells`, not item/recipe/aura entries with similar names.

---

# Data migration requirements

For every affected default Spell record:

```lua
cooldownChannel = <explicit ID>
```

Remove the spell-level legacy fields:

```lua
triggersGCD = ...
ignoreGCD = ...
```

Do **not** alter unrelated Spell properties while doing this migration. In particular preserve:

- `cooldown`;
- `cooldownGroup`;
- charges/useCooldownCharges;
- resource costs;
- components/effects;
- conditions;
- targeters;
- cast/channel timing;
- names/IDs/icons;
- tooltip templates.

Increment each affected default dataset version according to the current default-dataset update convention so installed default records are updated correctly.

Affected default datasets expected at issue creation:

```text
data/default/core.lua
data/default/classes/mage.lua
data/default/classes/paladin.lua
data/default/classes/priest.lua
data/default/classes/rogue.lua
data/default/classes/warrior.lua
data/default/professions/alchemy.lua
data/default/professions/engineering.lua
```

Do not increment unrelated default datasets that contain no Spell entries.

# Final Spell serialization cutover

After default records are explicit:

- new/updated Spell serialization must write `cooldownChannel`;
- do not serialize `triggersGCD` / `ignoreGCD` as current fields;
- keep a narrow legacy **read/import** fallback that maps older datasets via #356;
- when an old legacy Spell is explicitly edited/saved/exported through the current model, prefer canonical `cooldownChannel` output rather than perpetuating old flags;
- runtime/UI/autopilot must never need the old fields after normalization.

Do not maintain two canonical action-economy representations.

# Remove obsolete basic-attack GCD rule

Once Core auto-attacks explicitly use Channel 4, remove the obsolete ruleset behavior/key:

```text
basic_attacks_do_not_consume_gcd
```

and its user-facing `Basic Attacks Do Not Consume Global Cooldown` control if it still exists.

The basic-attack per-turn/damage-type restriction retained in #359 stays. Only the old GCD-bypass configuration is obsolete because action economy is now expressed by each spell's channel.

If old imported rulesets contain the removed key, ignore it safely; do not fail import.

# Migration validation

## Inventory validation

Before committing, programmatically or deterministically enumerate every `dataset.spells` entry in all current default datasets.

At the issue-creation baseline:

```text
Core          8
Mage         22
Paladin      35
Priest       21
Rogue        17
Warrior      22
Alchemy      35
Engineering  25
----------------
Total       185
```

Required assertions:

- every default Spell has an explicit valid `cooldownChannel` 1-10;
- none of the migrated default Spell entries contains `triggersGCD` or `ignoreGCD`;
- no Spell is omitted because it is `learnMode="unavailable"` or invoked only by an Item;
- default datasets with no spells remain untouched except where another required migration path genuinely references them.

If the current source contains more than 185 spells, list the additional names/IDs in implementation notes and assign them deliberately.

## Behavioral validation

At minimum verify:

1. A Main Action blocks another Main Action for the turn but not Bonus/Buff/Free.
2. A Bonus Action blocks another Bonus Action but not Main/Buff/Free.
3. A Buff Action blocks another Buff Action but not Main/Bonus/Free.
4. Core basic auto-attacks on Channel 4 do not consume Main/Bonus/Buff channel state.
5. Basic-attack type/per-turn rules from #359 still apply to Channel 4 attacks.
6. Blessing of Might on Channel 3 applies the full `blessing` cooldown-group lockout to the other Blessings while applying only the one-turn Channel 3 cooldown to unrelated Buff Action spells.
7. A Blessing cooldown group still works if a test copy is placed on another channel.
8. A potion consumes Channel 2 and retains its potion cooldown-group/own cooldown behavior.
9. An Engineering bomb consumes Channel 2 and retains its existing cooldown group.
10. Multiple arbitrary test Channel-4 spells can be used in one turn when no own/group/resource/condition restriction blocks them.
11. Autopilot can plan one Main + one Bonus + one Buff action together when useful/legal.
12. Autopilot does not plan two Bonus item-use actions in the same turn.
13. Old imported spell data with only legacy flags still loads through the compatibility fallback.
14. Exporting a canonical migrated spell does not reintroduce legacy flags.
15. Default dataset update/versioning replaces the shipped default records without reactivating datasets that the user deliberately disabled, preserving existing default-dataset update semantics.

# Repository-wide final audit

Search for:

```text
spell.triggersGCD
spell.ignoreGCD
triggersGCD =
ignoreGCD =
SpellUsesGlobalCooldown
SpellIgnoresGlobalCooldown
globalCooldownRemaining
ignoreGCDSpellRefs
ignoreGCDCommitted
primaryGCDCommitted
basic_attacks_do_not_consume_gcd
```

After this issue:

- no live runtime/UI/autopilot behavior should depend on the old spell flags;
- no shipped default Spell should contain them;
- only narrowly documented legacy import compatibility/tests may reference them.

Do not remove the channel-level `triggersGCD` setting: that is a property of the **ruleset cooldown channel**, not a Spell flag.

# Acceptance criteria

- [ ] All current default Spell entries have explicit cooldown channels.
- [ ] The issue inventory has been reconciled against current `dev`; additions are documented rather than omitted.
- [ ] Default Spell records no longer contain `triggersGCD` / `ignoreGCD`.
- [ ] New serialization is channel-only.
- [ ] Older imported legacy spell records still normalize safely.
- [ ] Core basic auto-attacks use Free Action without a GCD-bypass rule.
- [ ] Alchemy and Engineering item-use spells use Bonus Action.
- [ ] Buff spells listed above use Buff Action.
- [ ] Cooldown groups are unchanged and remain independent of channels.
- [ ] Dataset versions are incremented only for affected shipped datasets.
- [ ] Full manual/NPC/item/autopilot regression matrix passes.

## Handoff

This is the final issue in the cooldown-channel implementation sequence. Do not expand it into unrelated spell balancing/content cleanup.