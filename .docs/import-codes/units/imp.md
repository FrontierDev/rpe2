# Imp Unit Import Code

Standalone `RPE_DATASET_ENTRY_V1` import code for a base Imp unit in the Core dataset (`f82db71a`).

## Level-60 calibration

| Stat | Initial | Per level | Level 60 |
|---|---:|---:|---:|
| Health | 120 | 23.389831 | 1,500 |
| Mana | 100 | 23.728814 | 1,500 |
| Armor | 0 | 10.169492 | 600 |
| Melee Attack Power | 35 | 3.644068 | 250 |
| Ranged Attack Power | 0 | 0 | 0 |
| Spell Power | 0 | 2.966102 | 175 |
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
| Fire Resistance | 20 | 0 | 20 |
| Frost Resistance | 0 | 0 | 0 |
| Nature Resistance | 0 | 0 | 0 |
| Arcane Resistance | 0 | 0 | 0 |
| Shadow Resistance | 0 | 0 | 0 |
| Holy Resistance | 0 | 0 | 0 |
| Resource Regeneration | 0 | 0 | 0 |
| Movement Speed | 30 | 0 | 30 |

The base Imp is authored as a `minor`, `small` Demon. It has non-zero Melee Attack Power so that the creature retains a meaningful melee fallback even though all current presets are caster archetypes.

## Variants

All three variants inherit the base Minor challenge level and base stats.

### Flamecaster

Spells:

- Fireball — `d7c874c4:68dy7na1`
- Requested **Immolation** currently maps to the existing Warlock **Immolate** spell — `e8f3b2c6:wlimmol1`

Appearances:

- FileDataID `1138493`, DisplayID `66827`
- FileDataID `1138493`, DisplayID `67920`
- FileDataID `1138493`, DisplayID `67906`

### Felcaster

Spells:

- Fireball — `d7c874c4:68dy7na1`
- **Fel Immolation** — not currently present in the repository. No fabricated spell reference is included in the import code below.

Appearances:

- FileDataID `1098889`, DisplayID `67727`
- FileDataID `1098889`, DisplayID `67735`
- FileDataID `1098889`, DisplayID `67724`

### Shadowcaster

Spells:

- Shadow Bolt — `e8f3b2c6:wlsbolt1`
- Corruption — `e8f3b2c6:wlcorru1`

Appearances:

- FileDataID `124630`, DisplayID `16889`
- FileDataID `124630`, DisplayID `19611`

### Camera settings

Every Imp appearance uses:

- camera distance: `0.60`
- rotation: `0.01`
- vertical offset: `-0.35`

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "units",
    datasetId = "f82db71a",
    entry = {
        appearances = {  },
        attributes = {  },
        challengeLevel = "minor",
        creatureSize = "small",
        creatureType = "demon",
        id = "imp00001",
        name = "Imp",
        presets = {
            {
                name = "Flamecaster",
                appearances = {
                    {
                        displayId = 66827,
                        fileDataId = 1138493,
                        cam = 0.60,
                        rot = 0.01,
                        z = -0.35,
                    },
                    {
                        displayId = 67920,
                        fileDataId = 1138493,
                        cam = 0.60,
                        rot = 0.01,
                        z = -0.35,
                    },
                    {
                        displayId = 67906,
                        fileDataId = 1138493,
                        cam = 0.60,
                        rot = 0.01,
                        z = -0.35,
                    },
                },
                resourceModifiers = {  },
                statModifiers = {  },
                spells = {
                    "d7c874c4:68dy7na1",
                    "e8f3b2c6:wlimmol1",
                },
                equipment = {  },
            },
            {
                name = "Felcaster",
                appearances = {
                    {
                        displayId = 67727,
                        fileDataId = 1098889,
                        cam = 0.60,
                        rot = 0.01,
                        z = -0.35,
                    },
                    {
                        displayId = 67735,
                        fileDataId = 1098889,
                        cam = 0.60,
                        rot = 0.01,
                        z = -0.35,
                    },
                    {
                        displayId = 67724,
                        fileDataId = 1098889,
                        cam = 0.60,
                        rot = 0.01,
                        z = -0.35,
                    },
                },
                resourceModifiers = {  },
                statModifiers = {  },
                spells = {
                    "d7c874c4:68dy7na1",
                },
                equipment = {  },
            },
            {
                name = "Shadowcaster",
                appearances = {
                    {
                        displayId = 16889,
                        fileDataId = 124630,
                        cam = 0.60,
                        rot = 0.01,
                        z = -0.35,
                    },
                    {
                        displayId = 19611,
                        fileDataId = 124630,
                        cam = 0.60,
                        rot = 0.01,
                        z = -0.35,
                    },
                },
                resourceModifiers = {  },
                statModifiers = {  },
                spells = {
                    "e8f3b2c6:wlsbolt1",
                    "e8f3b2c6:wlcorru1",
                },
                equipment = {  },
            },
        },
        resistances = {  },
        resources = {
            {
                initialValue = 120,
                perLevelValue = 23.389831,
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
                initialValue = 0,
                perLevelValue = 10.169492,
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
                initialValue = 35,
                perLevelValue = 3.644068,
                statRef = "f82db71a:u7b49vs9",
            },
            {
                initialValue = 0,
                perLevelValue = 0,
                statRef = "f82db71a:v2rs9cpy",
            },
            {
                initialValue = 0,
                perLevelValue = 2.966102,
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
                initialValue = 20,
                perLevelValue = 0,
                statRef = "f82db71a:0w7c7p09",
            },
            {
                initialValue = 0,
                perLevelValue = 0,
                statRef = "f82db71a:hj6d4kvy",
            },
            {
                initialValue = 0,
                perLevelValue = 0,
                statRef = "f82db71a:jjn0my8k",
            },
            {
                initialValue = 0,
                perLevelValue = 0,
                statRef = "f82db71a:pg0ytacb",
            },
            {
                initialValue = 0,
                perLevelValue = 0,
                statRef = "f82db71a:954yunb9",
            },
            {
                initialValue = 0,
                perLevelValue = 0,
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
