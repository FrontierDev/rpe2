# WoW Classic Trait Icon Corrections

This document lists Priest, Mage, and Rogue traits in the current RPE2 `dev` class datasets whose icons do not match the WoW Classic talents of the same name.

## Priest

| Trait | Current Icon | Correct WoW Classic Icon |
|---|---|---|
| Force of Will | `interface/icons/spell_holy_mindsooth.blp` | `interface/icons/spell_nature_slowingtotem.blp` |
| Spiritual Healing | `interface/icons/spell_holy_greaterheal.blp` | `interface/icons/spell_nature_moonglow.blp` |
| Spell Warding | `interface/icons/spell_arcane_arcaneresilience.blp` | `interface/icons/spell_holy_spellwarding.blp` |
| Shadow Focus | `interface/icons/spell_shadow_twilight.blp` | `interface/icons/spell_shadow_burningspirit.blp` |
| Mental Strength | `interface/icons/spell_shadow_focusedpower.blp` | `interface/icons/spell_nature_enchantarmor.blp` |

### Priest traits checked and already correct

- Silent Resolve — `interface/icons/spell_nature_manaregentotem.blp`
- Inspiration — `interface/icons/spell_holy_layonhands.blp`

---

## Mage

| Trait | Current Icon | Correct WoW Classic Icon |
|---|---|---|
| Arcane Focus | `interface/icons/spell_arcane_arcane01.blp` | `interface/icons/spell_holy_devotion.blp` |
| Magic Absorption | `interface/icons/spell_arcane_manashield.blp` | `interface/icons/spell_nature_astralrecalgroup.blp` |
| Arcane Mind | `interface/icons/spell_nature_enchantarmor.blp` | `interface/icons/spell_shadow_charm.blp` |
| Arcane Instability | `interface/icons/spell_arcane_arcane03.blp` | `interface/icons/spell_shadow_teleport.blp` |

---

## Rogue

| Trait | Current Icon | Correct WoW Classic Icon |
|---|---|---|
| Malice | `interface/icons/ability_rogue_focusedattacks.blp` | `interface/icons/ability_racial_bloodrage.blp` |
| Seal Fate | `interface/icons/ability_rogue_fanofknives.blp` | `interface/icons/spell_shadow_chilltouch.blp` |
| Lightning Reflexes | `interface/icons/ability_rogue_lightningreflexes.blp` | `interface/icons/spell_nature_invisibilty.blp` |
| Weapon Expertise | `interface/icons/ability_hunter_goforthethroat.blp` | `interface/icons/spell_holy_blessingofstrength.blp` |
| Master of Deception | `interface/icons/ability_rogue_masterofsubtlety.blp` | `interface/icons/spell_shadow_charm.blp` |
| Deadliness | `interface/icons/ability_rogue_sinistercalling.blp` | `interface/icons/inv_weapon_crossbow_11.blp` |
| Heightened Sense | `interface/icons/ability_rogue_heightenedsenses.blp` | `interface/icons/ability_ambush.blp` |

### Rogue naming correction

The current trait is named:

```text
Heightened Sense
```

The WoW Classic talent name is:

```text
Heightened Senses
```

This should be corrected at the same time as the icon.

### Rogue traits checked and already correct

- Deflection — `interface/icons/ability_parry.blp`

---

## Summary

Required corrections:

- Priest: 5 trait icons
- Mage: 4 trait icons
- Rogue: 7 trait icons
- Rogue naming correction: `Heightened Sense` → `Heightened Senses`

Total icon corrections: **16**
