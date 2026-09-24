# Human Unit Import Code

Standalone `RPE_DATASET_ENTRY_V1` import code for the base Human unit in the Core dataset (`f82db71a`).

## Level-60 calibration

| Stat | Base amount | Per level | Level 60 |
|---|---:|---:|---:|
| Health | 208 | 43.084746 | 2,750 |
| Armor | 25 | 33.474576 | 2,000 |
| Melee Attack Power | 65 | 9.067797 | 600 |
| Ranged Attack Power | 65 | 9.067797 | 600 |
| Spell Power | 0 | 3.389831 | 200 |
| Healing Power | 0 | 4.237288 | 250 |

The unit is authored as a `normal` Humanoid with no role variants or presets. It retains the Worn Shortsword and the Core Main Hand Attack / Shoot spells.

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
        creatureType = "humanoid",
        id = "7i40epa5",
        mainHandWeapon = "f82db71a:stwswd01",
        name = "Human",
        presets = {  },
        resistances = {  },
        resources = {
            {
                initialValue = 208,
                perLevelValue = 43.084746,
                resourceRef = "f82db71a:q2ktkztt",
            },
        },
        spells = {
            "f82db71a:z36xzk0w",
            "f82db71a:shoota01",
        },
        stats = {
            {
                initialValue = 25,
                perLevelValue = 33.474576,
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
                initialValue = 65,
                perLevelValue = 9.067797,
                statRef = "f82db71a:u7b49vs9",
            },
            {
                initialValue = 65,
                perLevelValue = 9.067797,
                statRef = "f82db71a:v2rs9cpy",
            },
            {
                initialValue = 0,
                perLevelValue = 3.389831,
                statRef = "f82db71a:7t7xgzcx",
            },
            {
                initialValue = 5,
                perLevelValue = 0,
                statRef = "f82db71a:jslmczbi",
            },
            {
                initialValue = 5,
                perLevelValue = 0,
                statRef = "f82db71a:fercjhm5",
            },
            {
                initialValue = 5,
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
                perLevelValue = 4.237288,
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
        },
        tags = {  },
    },
}
```
