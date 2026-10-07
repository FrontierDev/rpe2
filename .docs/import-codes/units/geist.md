# Geist Unit Import Code

Standalone `RPE_DATASET_ENTRY_V1` import code for the base Geist unit in the Core dataset (`f82db71a`).

## Level-60 calibration

| Stat | Initial | Per level | Level 60 |
|---|---:|---:|---:|
| Health | 140 | 45.084746 | 2,800 |
| Armor | 10 | 20.169492 | 1,200 |
| Melee Attack Power | 50 | 7.627119 | 500 |
| Ranged Attack Power | 0 | 0 | 0 |
| Spell Power | 0 | 0 | 0 |
| Healing Power | 0 | 0 | 0 |
| Melee Hit Chance | 5 | 0 | 5 |
| Ranged Hit Chance | 0 | 0 | 0 |
| Spell Hit Chance | 0 | 0 | 0 |
| Melee Crit Chance | 8 | 0 | 8 |
| Ranged Crit Chance | 0 | 0 | 0 |
| Spell Crit Chance | 0 | 0 | 0 |
| Parry Chance | 0 | 0 | 0 |
| Dodge Chance | 8 | 0 | 8 |
| Block Chance | 0 | 0 | 0 |
| Magic Resistance | 0 | 0 | 0 |
| Fire Resistance | 0 | 0 | 0 |
| Frost Resistance | 0 | 0 | 0 |
| Nature Resistance | 0 | 0 | 0 |
| Arcane Resistance | 0 | 0 | 0 |
| Shadow Resistance | 0 | 0 | 0 |
| Holy Resistance | 0 | 0 | 0 |
| Resource Regeneration | 0 | 0 | 0 |
| Movement Speed | 40 | 0 | 40 |

## Authoring notes

- Creature type: `undead`
- Creature size: `medium`
- Challenge level: `normal`
- Health only
- No equipment
- Natural Attack — `f82db71a:natatk01`
- No presets or bespoke abilities are included in the base unit.
- The Geist is intentionally lightly armored for a Normal unit, trading durability for high movement, Dodge, accuracy and melee pressure.

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
        challengeLevel = "normal",
        creatureSize = "medium",
        creatureType = "undead",
        id = "geist001",
        name = "Geist",
        presets = {  },
        resistances = {  },
        resources = {
            {
                initialValue = 140,
                perLevelValue = 45.084746,
                resourceRef = "f82db71a:q2ktkztt",
            },
        },
        spells = {
            "f82db71a:natatk01",
        },
        stats = {
            {
                initialValue = 10,
                perLevelValue = 20.169492,
                statRef = "f82db71a:v42albuv",
            },
            {
                initialValue = 5,
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
                initialValue = 8,
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
                initialValue = 50,
                perLevelValue = 7.627119,
                statRef = "f82db71a:u7b49vs9",
            },
            {
                initialValue = 0,
                perLevelValue = 0,
                statRef = "f82db71a:v2rs9cpy",
            },
            {
                initialValue = 0,
                perLevelValue = 0,
                statRef = "f82db71a:7t7xgzcx",
            },
            {
                initialValue = 8,
                perLevelValue = 0,
                statRef = "f82db71a:jslmczbi",
            },
            {
                initialValue = 0,
                perLevelValue = 0,
                statRef = "f82db71a:fercjhm5",
            },
            {
                initialValue = 0,
                perLevelValue = 0,
                statRef = "f82db71a:69hfqhne",
            },
            {
                initialValue = 0,
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
                initialValue = 40,
                perLevelValue = 0,
                statRef = "f82db71a:s1mt6jh9",
            },
        },
        tags = {  },
    },
}
```
