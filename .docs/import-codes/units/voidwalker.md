# Voidwalker Unit Import Code

Standalone `RPE_DATASET_ENTRY_V1` import code for a base Voidwalker unit in the Core dataset (`f82db71a`).

## Level-60 calibration

| Stat | Initial | Per level | Level 60 |
|---|---:|---:|---:|
| Health | 180 | 47.796610 | 3,000 |
| Mana | 100 | 23.728814 | 1,500 |
| Armor | 100 | 44.915254 | 2,750 |
| Melee Attack Power | 40 | 4.406780 | 300 |
| Ranged Attack Power | 0 | 0 | 0 |
| Spell Power | 20 | 2.203390 | 150 |
| Healing Power | 0 | 0 | 0 |
| Melee Hit Chance | 0 | 0 | 0 |
| Ranged Hit Chance | 0 | 0 | 0 |
| Spell Hit Chance | 0 | 0 | 0 |
| Melee Crit Chance | 5 | 0 | 5 |
| Ranged Crit Chance | 0 | 0 | 0 |
| Spell Crit Chance | 5 | 0 | 5 |
| Parry Chance | 0 | 0 | 0 |
| Dodge Chance | 0 | 0 | 0 |
| Block Chance | 0 | 0 | 0 |
| Magic Resistance | 0 | 0 | 0 |
| Fire Resistance | 1.333333 | 1.333333 | 80 |
| Frost Resistance | 1.333333 | 1.333333 | 80 |
| Nature Resistance | 1.333333 | 1.333333 | 80 |
| Arcane Resistance | 1.333333 | 1.333333 | 80 |
| Shadow Resistance | 1.333333 | 1.333333 | 80 |
| Holy Resistance | 0 | 0 | 0 |
| Resource Regeneration | 0 | 0 | 0 |
| Movement Speed | 30 | 0 | 30 |

Under the current Core `level_scaled_percent` mitigation model, a school-resistance rating of approximately `1.333333 × level` corresponds to approximately **20% damage mitigation**. The five percentage-based school resistances therefore remain at approximately 20% from level 1 through level 60.

Holy Resistance is left at 0. Under the active global `level_scaled_percent` mitigation path, Holy has no percentage-reference amount/percent configured, so its current effective school mitigation is 0%.

## Base appearances

The base Voidwalker has two authored appearances:

- DisplayID `1132` — canonical summoned Voidwalker.
- DisplayID `1131` — alternate classic Voidwalker appearance used by Arugal's Voidwalker.

No FileDataID is authored here because a current FileDataID for these display records has not been verified. DisplayID-only appearances are valid in the Unit appearance schema.

## Presets

Both presets inherit the base challenge level, stats, resources and appearances.

### Corruptor

A Shadow-oriented caster/debuffer.

Spells:

- Corruption — `e8f3b2c6:wlcorru1`
- Curse of Shadows — `e8f3b2c6:wlcshads`

### Tormenter

A melee pressure variant.

Spells:

- Multiattack — `f82db71a:npcmulti`

## Authoring notes

- Creature type: `demon`
- Creature size: `medium`
- Base challenge level: `normal`
- The Voidwalker is intentionally more defensive than the Imp and less offensively powerful than the Felguard.
- The base unit carries meaningful Melee Attack Power and modest Spell Power so either preset can use the same underlying unit without needing stat overrides.
- Fire, Frost, Nature, Arcane and Shadow Resistance use level-scaled stat rows rather than fixed values.
- Damage Done and Damage Reduction are not seeded on the base unit.
- Preset spell lists are explicit replacements under the current Unit preset spell-resolution implementation.

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "units",
    datasetId = "f82db71a",
    entry = {
        appearances = {
            {
                displayId = 1132,
            },
            {
                displayId = 1131,
            },
        },
        attributes = {  },
        challengeLevel = "normal",
        creatureSize = "medium",
        creatureType = "demon",
        id = "voidw001",
        name = "Voidwalker",
        presets = {
            {
                name = "Corruptor",
                resourceModifiers = {  },
                statModifiers = {  },
                spells = {
                    "e8f3b2c6:wlcorru1",
                    "e8f3b2c6:wlcshads",
                },
                equipment = {  },
            },
            {
                name = "Tormenter",
                resourceModifiers = {  },
                statModifiers = {  },
                spells = {
                    "f82db71a:npcmulti",
                },
                equipment = {  },
            },
        },
        resistances = {  },
        resources = {
            {
                initialValue = 180,
                perLevelValue = 47.796610,
                resourceRef = "f82db71a:q2ktkztt",
            },
            {
                initialValue = 100,
                perLevelValue = 23.728814,
                resourceRef = "f82db71a:4c8mfm99",
            },
        },
        spells = {  },
        stats = {
            {
                initialValue = 100,
                perLevelValue = 44.915254,
                statRef = "f82db71a:v42albuv",
            },
            {
                initialValue = 0,
                perLevelValue = 0,
                statRef = "f82db71a:wbj4zuf3",
            },
            {
                initialValue = 0,
                perLevelValue = 0,
                statRef = "f82db71a:dd88li4c",
            },
            {
                initialValue = 0,
                perLevelValue = 0,
                statRef = "f82db71a:v2g0tw0o",
            },
            {
                initialValue = 0,
                perLevelValue = 0,
                statRef = "f82db71a:tcn0s8kx",
            },
            {
                initialValue = 0,
                perLevelValue = 0,
                statRef = "f82db71a:o6113cir",
            },
            {
                initialValue = 0,
                perLevelValue = 0,
                statRef = "f82db71a:p8syz5ba",
            },
            {
                initialValue = 0,
                perLevelValue = 0,
                statRef = "f82db71a:zs1nbz13",
            },
            {
                initialValue = 40,
                perLevelValue = 4.406780,
                statRef = "f82db71a:u7b49vs9",
            },
            {
                initialValue = 0,
                perLevelValue = 0,
                statRef = "f82db71a:v2rs9cpy",
            },
            {
                initialValue = 20,
                perLevelValue = 2.203390,
                statRef = "f82db71a:7t7xgzcx",
            },
            {
                initialValue = 5,
                perLevelValue = 0,
                statRef = "f82db71a:jslmczbi",
            },
            {
                initialValue = 0,
                perLevelValue = 0,
                statRef = "f82db71a:fercjhm5",
            },
            {
                initialValue = 5,
                perLevelValue = 0,
                statRef = "f82db71a:69hfqhne",
            },
            {
                initialValue = 1.333333,
                perLevelValue = 1.333333,
                statRef = "f82db71a:0w7c7p09",
            },
            {
                initialValue = 0,
                perLevelValue = 0,
                statRef = "f82db71a:hj6d4kvy",
            },
            {
                initialValue = 1.333333,
                perLevelValue = 1.333333,
                statRef = "f82db71a:jjn0my8k",
            },
            {
                initialValue = 1.333333,
                perLevelValue = 1.333333,
                statRef = "f82db71a:pg0ytacb",
            },
            {
                initialValue = 1.333333,
                perLevelValue = 1.333333,
                statRef = "f82db71a:954yunb9",
            },
            {
                initialValue = 1.333333,
                perLevelValue = 1.333333,
                statRef = "f82db71a:itpo751d",
            },
            {
                initialValue = 0,
                perLevelValue = 0,
                statRef = "f82db71a:hlyrsstn",
            },
            {
                initialValue = 0,
                perLevelValue = 0,
                statRef = "f82db71a:rgnrtg01",
            },
            {
                initialValue = 30,
                perLevelValue = 0,
                statRef = "f82db71a:s1mt6jh9",
            },
        },
        tags = {  },
    },
}
```
