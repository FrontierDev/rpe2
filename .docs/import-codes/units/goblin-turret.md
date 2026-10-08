# Goblin Turret Unit Import Code

Standalone `RPE_DATASET_ENTRY_V1` import code for the Goblin Turret summoned by Deploy Turret.

Import **Turret Shot** from `.docs/import-codes/spells/goblin-abilities.md` before importing this Unit.

## Goblin Turret — Minor

The turret is a stationary `small` Mechanical unit. It has low Health and Armor and exists to provide ranged pressure while deployed.

### Level-60 calibration

| Stat | Initial | Per level | Level 60 |
|---|---:|---:|---:|
| Health | 80 | 15.593220 | 1,000 |
| Armor | 20 | 8.135593 | 500 |
| Ranged Attack Power | 35 | 5.338983 | 350 |
| Ranged Hit Chance | 5 | 0 | 5 |
| Ranged Crit Chance | 5 | 0 | 5 |
| Movement Speed | 0 | 0 | 0 |

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
        creatureType = "mechanical",
        id = "gobtur01",
        name = "Goblin Turret",
        presets = {  },
        resistances = {  },
        resources = {
            {
                initialValue = 80,
                perLevelValue = 15.593220,
                resourceRef = "f82db71a:q2ktkztt",
            },
        },
        spells = {
            "f82db71a:gobshot1",
        },
        stats = {
            { initialValue = 20, perLevelValue = 8.135593, statRef = "f82db71a:v42albuv" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:wbj4zuf3" },
            { initialValue = 5, perLevelValue = 0, statRef = "f82db71a:dd88li4c" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:v2g0tw0o" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:tcn0s8kx" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:o6113cir" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:p8syz5ba" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:zs1nbz13" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:u7b49vs9" },
            { initialValue = 35, perLevelValue = 5.338983, statRef = "f82db71a:v2rs9cpy" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:7t7xgzcx" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:jslmczbi" },
            { initialValue = 5, perLevelValue = 0, statRef = "f82db71a:fercjhm5" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:69hfqhne" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:hj6d4kvy" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:0w7c7p09" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:jjn0my8k" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:pg0ytacb" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:954yunb9" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:itpo751d" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:hlyrsstn" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:rgnrtg01" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:s1mt6jh9" },
        },
        tags = {
            "goblin",
            "turret",
        },
    },
}
```
