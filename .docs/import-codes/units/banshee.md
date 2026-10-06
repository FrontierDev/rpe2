# Banshee Unit Import Code

Standalone `RPE_DATASET_ENTRY_V1` import code for the Banshee unit in the Core dataset (`f82db71a`).

Import the Banshee-specific abilities from `.docs/import-codes/spells/banshee-abilities.md` before importing this Unit.

## Level-60 calibration

| Stat | Initial | Per level | Level 60 |
|---|---:|---:|---:|
| Health | 150 | 133.050847 | 8,000 |
| Mana | 120 | 40.338983 | 2,500 |
| Armor | 0 | 16.949153 | 1,000 |
| Melee Attack Power | 0 | 0 | 0 |
| Ranged Attack Power | 0 | 0 | 0 |
| Spell Power | 25 | 8.050847 | 500 |
| Healing Power | 0 | 0 | 0 |
| Melee Hit Chance | 0 | 0 | 0 |
| Ranged Hit Chance | 0 | 0 | 0 |
| Spell Hit Chance | 5 | 0 | 5 |
| Melee Crit Chance | 0 | 0 | 0 |
| Ranged Crit Chance | 0 | 0 | 0 |
| Spell Crit Chance | 5 | 0 | 5 |
| Parry Chance | 0 | 0 | 0 |
| Dodge Chance | 0 | 0 | 0 |
| Block Chance | 0 | 0 | 0 |
| Magic Resistance | 10 | 0 | 10 |
| Fire Resistance | 0 | 0 | 0 |
| Frost Resistance | 0 | 0 | 0 |
| Nature Resistance | 0 | 0 | 0 |
| Arcane Resistance | 0 | 0 | 0 |
| Shadow Resistance | 20 | 0 | 20 |
| Holy Resistance | 0 | 0 | 0 |
| Resource Regeneration | 0 | 0 | 0 |
| Movement Speed | 30 | 0 | 30 |

## Authoring notes

- Creature type: `undead`
- Creature size: `medium`
- Challenge level: `elite`
- No equipment
- No basic weapon attack
- Shadow Bolt — `e8f3b2c6:wlsbolt1`
- Banshee Curse — `f82db71a:bancurse1`
- Anti-Magic Shield — `f82db71a:banams01`
- No presets are included.

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
        challengeLevel = "elite",
        creatureSize = "medium",
        creatureType = "undead",
        id = "bansh001",
        name = "Banshee",
        presets = {  },
        resistances = {  },
        resources = {
            {
                initialValue = 150,
                perLevelValue = 133.050847,
                resourceRef = "f82db71a:q2ktkztt",
            },
            {
                initialValue = 120,
                perLevelValue = 40.338983,
                resourceRef = "f82db71a:4c8mfm99",
            },
        },
        spells = {
            "e8f3b2c6:wlsbolt1",
            "f82db71a:bancurse1",
            "f82db71a:banams01",
        },
        stats = {
            { initialValue = 0, perLevelValue = 16.949153, statRef = "f82db71a:v42albuv" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:wbj4zuf3" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:dd88li4c" },
            { initialValue = 5, perLevelValue = 0, statRef = "f82db71a:v2g0tw0o" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:tcn0s8kx" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:o6113cir" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:p8syz5ba" },
            { initialValue = 10, perLevelValue = 0, statRef = "f82db71a:zs1nbz13" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:u7b49vs9" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:v2rs9cpy" },
            { initialValue = 25, perLevelValue = 8.050847, statRef = "f82db71a:7t7xgzcx" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:jslmczbi" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:fercjhm5" },
            { initialValue = 5, perLevelValue = 0, statRef = "f82db71a:69hfqhne" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:0w7c7p09" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:hj6d4kvy" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:jjn0my8k" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:pg0ytacb" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:954yunb9" },
            { initialValue = 20, perLevelValue = 0, statRef = "f82db71a:itpo751d" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:hlyrsstn" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:rgnrtg01" },
            { initialValue = 30, perLevelValue = 0, statRef = "f82db71a:s1mt6jh9" },
        },
        tags = {  },
    },
}
```
