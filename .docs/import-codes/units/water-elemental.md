# Water Elemental Unit Import Code

Standalone `RPE_DATASET_ENTRY_V1` import code for a **Water Elemental** in the **Mage** dataset (`d7c874c4`) on the RPEngine2 `main` branch.

The Water Elemental's four abilities **already exist** in the default datasets. Import this **single Unit entry** through the Data Editor; do not duplicate the existing spells.

## Spell references

| Ability | Existing dataset entry | Behaviour |
| --- | --- | --- |
| Natural Attack | `f82db71a:natatk01` (Core) | Physical melee/basic attack |
| Frostbolt | `d7c874c4:lywroiqu` (Mage) | Frost single-target attack |
| Frost Nova | `d7c874c4:7ha8pdoy` (Mage) | Frost multi-target control, Bonus Action, 10-turn cooldown |
| Ice Armor | `d7c874c4:icearm01` (Mage) | Self-applied Armor/Frost Resistance buff, Buff Action |

The base Unit directly owns **all four spells**; no presets are required. The existing Mage spell definitions control their mana costs, targeting, cooldowns, aura behavior, and ranks.

**Dataset placement:** Mage already depends on Core. Putting this Unit in Mage avoids a circular Core → Mage → Core dependency and means its Frost spells are present whenever the unit's dataset is activated.

## Unit design

- Creature type: `elemental`; size: `medium`; challenge: `normal`
- Role: Frost-focused caster with a viable Physical natural attack as a fallback
- Level-scaled resources, Armor, Melee Attack Power, Spell Power and Frost Resistance
- Frost Resistance is deliberately higher than other schools; the resistance row reaches 120 at level 60 (approximately 30% mitigation under the current level-scaled Core Frost mitigation model)
- No innate Damage Reduction or Damage Done bonus, no artificial Fire vulnerability, and no unconditional Ice Armor aura: **Ice Armor is a spell it can cast**
- No verified Water Elemental DisplayID/FileDataID is assumed. `appearances` remains empty until a model is explicitly selected in the editor

### Level-60 calibration

`Level-N value = initialValue + (N - 1) × perLevelValue`. Values shown at level 60 are design targets, with stored per-level increments rounded to 6 decimals.

| Property | Initial | Per level | Level 60 |
| --- | ---: | ---: | ---: |
| Health | 180 | 44.40678 | 2800 |
| Mana | 150 | 34.745763 | 2200 |
| Armor | 50 | 17.79661 | 1100 |
| Melee Hit Chance | 0 | 0 | 0 |
| Ranged Hit Chance | 0 | 0 | 0 |
| Spell Hit Chance | 5 | 0 | 5 |
| Parry Chance | 0 | 0 | 0 |
| Dodge Chance | 0 | 0 | 0 |
| Block Chance | 0 | 0 | 0 |
| Magic Resistance | 0 | 0 | 0 |
| Melee Attack Power | 35 | 4.491525 | 300 |
| Ranged Attack Power | 0 | 0 | 0 |
| Spell Power | 20 | 4.745763 | 300 |
| Melee Crit Chance | 5 | 0 | 5 |
| Ranged Crit Chance | 0 | 0 | 0 |
| Spell Crit Chance | 5 | 0 | 5 |
| Fire Resistance | 0 | 0 | 0 |
| Holy Resistance | 0 | 0 | 0 |
| Frost Resistance | 2 | 2 | 120 |
| Nature Resistance | 0 | 0 | 0 |
| Arcane Resistance | 0 | 0 | 0 |
| Shadow Resistance | 0 | 0 | 0 |
| Healing Power | 0 | 0 | 0 |
| Resource Regeneration | 0 | 0 | 0 |
| Movement Speed | 30 | 0 | 30 |

## Import code

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "units",
    datasetId = "d7c874c4",
    entry = {
        appearances = {  },
        attributes = {  },
        challengeLevel = "normal",
        creatureSize = "medium",
        creatureType = "elemental",
        id = "watere01",
        name = "Water Elemental",
        presets = {  },
        resistances = {  },
        resources = {
            { initialValue = 180, perLevelValue = 44.40678, resourceRef = "f82db71a:q2ktkztt" },
            { initialValue = 150, perLevelValue = 34.745763, resourceRef = "f82db71a:4c8mfm99" },
        },
        spells = {
            "f82db71a:natatk01",
            "d7c874c4:lywroiqu",
            "d7c874c4:7ha8pdoy",
            "d7c874c4:icearm01",
        },
        stats = {
            { initialValue = 50, perLevelValue = 17.79661, statRef = "f82db71a:v42albuv" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:wbj4zuf3" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:dd88li4c" },
            { initialValue = 5, perLevelValue = 0, statRef = "f82db71a:v2g0tw0o" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:tcn0s8kx" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:o6113cir" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:p8syz5ba" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:zs1nbz13" },
            { initialValue = 35, perLevelValue = 4.491525, statRef = "f82db71a:u7b49vs9" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:v2rs9cpy" },
            { initialValue = 20, perLevelValue = 4.745763, statRef = "f82db71a:7t7xgzcx" },
            { initialValue = 5, perLevelValue = 0, statRef = "f82db71a:jslmczbi" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:fercjhm5" },
            { initialValue = 5, perLevelValue = 0, statRef = "f82db71a:69hfqhne" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:0w7c7p09" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:hj6d4kvy" },
            { initialValue = 2, perLevelValue = 2, statRef = "f82db71a:jjn0my8k" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:pg0ytacb" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:954yunb9" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:itpo751d" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:hlyrsstn" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:rgnrtg01" },
            { initialValue = 30, perLevelValue = 0, statRef = "f82db71a:s1mt6jh9" },
        },
        tags = {
            "water",
        },
    },
}
```
