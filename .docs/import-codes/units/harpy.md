# Harpy Unit Import Code

Standalone `RPE_DATASET_ENTRY_V1` import code for the base Harpy and its Windcaller, Stormwitch, Screecher and Matriarch presets in the Core dataset (`f82db71a`).

Import `.docs/import-codes/spells/harpy-abilities.md` before importing this Unit.

## Base Harpy

The base Harpy is a `minor`, `medium` flying Humanoid. It is lightly armored, evasive and fast, relying on mobility rather than durability.

### Level-60 calibration

| Stat | Initial | Per level | Level 60 |
|---|---:|---:|---:|
| Health | 120 | 23.389831 | 1,500 |
| Mana | 0 | 0 | 0 |
| Armor | 10 | 8.305085 | 500 |
| Melee Attack Power | 40 | 4.830508 | 325 |
| Ranged Attack Power | 0 | 0 | 0 |
| Spell Power | 0 | 2.542373 | 150 |
| Healing Power | 0 | 0 | 0 |
| Melee Hit Chance | 0 | 0 | 0 |
| Ranged Hit Chance | 0 | 0 | 0 |
| Spell Hit Chance | 0 | 0 | 0 |
| Melee Crit Chance | 5 | 0 | 5 |
| Ranged Crit Chance | 0 | 0 | 0 |
| Spell Crit Chance | 5 | 0 | 5 |
| Parry Chance | 0 | 0 | 0 |
| Dodge Chance | 10 | 0 | 10 |
| Block Chance | 0 | 0 | 0 |
| Magic Resistance | 0 | 0 | 0 |
| Resource Regeneration | 0 | 0 | 0 |
| Movement Speed | 40 | 0 | 40 |

## Presets

### Windcaller — Normal

- 2,500 Health
- 800 Armor
- 1,800 Mana
- 275 Spell Power
- +5 Spell Hit
- 8% Spell Crit
- Cyclone
- Earth Shock

### Stormwitch — Normal

- 2,600 Health
- 900 Armor
- 1,900 Mana
- 300 Spell Power
- +5 Spell Hit
- 8% Spell Crit
- Hurricane
- Chain Lightning

### Screecher — Normal

- 2,700 Health
- 1,000 Armor
- 475 Melee Attack Power
- +5 Melee Hit
- 8% Melee Crit
- 12% Dodge
- Natural Attack
- Screech

### Matriarch — Elite

- 8,500 Health
- 2,500 Armor
- 2,500 Mana
- 450 Spell Power
- 450 Healing Power
- +5 Spell Hit
- 10% Spell Crit
- Lightning Bolt
- Chain Lightning
- Healing Wave
- Lightning Shield

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "units",
    datasetId = "f82db71a",
    entry = {
        appearances = {  },
        attributes = {
            "flying",
        },
        challengeLevel = "minor",
        creatureSize = "medium",
        creatureType = "humanoid",
        id = "harpy001",
        name = "Harpy",
        presets = {
            {
                name = "Windcaller",
                challengeLevel = "normal",
                resourceModifiers = {
                    { resourceRef = "f82db71a:q2ktkztt", percentBonus = 66.666667, flatBonus = 0 },
                    { resourceRef = "f82db71a:4c8mfm99", percentBonus = 0, flatBonus = 1800 },
                },
                statModifiers = {
                    { statRef = "f82db71a:v42albuv", percentBonus = 60, flatBonus = 0 },
                    { statRef = "f82db71a:u7b49vs9", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:7t7xgzcx", percentBonus = 83.333333, flatBonus = 0 },
                    { statRef = "f82db71a:v2g0tw0o", percentBonus = 0, flatBonus = 5 },
                    { statRef = "f82db71a:69hfqhne", percentBonus = 0, flatBonus = 3 },
                },
                spells = {
                    "6e4d2a91:drcycl01",
                    "c4a91e7d:sherthsk",
                },
                equipment = {  },
            },
            {
                name = "Stormwitch",
                challengeLevel = "normal",
                resourceModifiers = {
                    { resourceRef = "f82db71a:q2ktkztt", percentBonus = 73.333333, flatBonus = 0 },
                    { resourceRef = "f82db71a:4c8mfm99", percentBonus = 0, flatBonus = 1900 },
                },
                statModifiers = {
                    { statRef = "f82db71a:v42albuv", percentBonus = 80, flatBonus = 0 },
                    { statRef = "f82db71a:u7b49vs9", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:7t7xgzcx", percentBonus = 100, flatBonus = 0 },
                    { statRef = "f82db71a:v2g0tw0o", percentBonus = 0, flatBonus = 5 },
                    { statRef = "f82db71a:69hfqhne", percentBonus = 0, flatBonus = 3 },
                },
                spells = {
                    "6e4d2a91:drhurr01",
                    "c4a91e7d:shchnltn",
                },
                equipment = {  },
            },
            {
                name = "Screecher",
                challengeLevel = "normal",
                resourceModifiers = {
                    { resourceRef = "f82db71a:q2ktkztt", percentBonus = 80, flatBonus = 0 },
                },
                statModifiers = {
                    { statRef = "f82db71a:v42albuv", percentBonus = 100, flatBonus = 0 },
                    { statRef = "f82db71a:u7b49vs9", percentBonus = 46.153846, flatBonus = 0 },
                    { statRef = "f82db71a:7t7xgzcx", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:wbj4zuf3", percentBonus = 0, flatBonus = 5 },
                    { statRef = "f82db71a:jslmczbi", percentBonus = 0, flatBonus = 3 },
                    { statRef = "f82db71a:o6113cir", percentBonus = 0, flatBonus = 2 },
                },
                spells = {
                    "f82db71a:natatk01",
                    "f82db71a:harscr01",
                },
                equipment = {  },
            },
            {
                name = "Matriarch",
                challengeLevel = "elite",
                resourceModifiers = {
                    { resourceRef = "f82db71a:q2ktkztt", percentBonus = 466.666667, flatBonus = 0 },
                    { resourceRef = "f82db71a:4c8mfm99", percentBonus = 0, flatBonus = 2500 },
                },
                statModifiers = {
                    { statRef = "f82db71a:v42albuv", percentBonus = 400, flatBonus = 0 },
                    { statRef = "f82db71a:u7b49vs9", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:7t7xgzcx", percentBonus = 200, flatBonus = 0 },
                    { statRef = "f82db71a:hj6d4kvy", percentBonus = 0, flatBonus = 450 },
                    { statRef = "f82db71a:v2g0tw0o", percentBonus = 0, flatBonus = 5 },
                    { statRef = "f82db71a:69hfqhne", percentBonus = 0, flatBonus = 5 },
                },
                spells = {
                    "c4a91e7d:shlbolt1",
                    "c4a91e7d:shchnltn",
                    "c4a91e7d:shhealwv",
                    "c4a91e7d:shlshldt",
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
                initialValue = 0,
                perLevelValue = 0,
                resourceRef = "f82db71a:4c8mfm99",
            },
        },
        spells = {
            "f82db71a:natatk01",
        },
        stats = {
            { initialValue = 10, perLevelValue = 8.305085, statRef = "f82db71a:v42albuv" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:wbj4zuf3" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:dd88li4c" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:v2g0tw0o" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:tcn0s8kx" },
            { initialValue = 10, perLevelValue = 0, statRef = "f82db71a:o6113cir" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:p8syz5ba" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:zs1nbz13" },
            { initialValue = 40, perLevelValue = 4.830508, statRef = "f82db71a:u7b49vs9" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:v2rs9cpy" },
            { initialValue = 0, perLevelValue = 2.542373, statRef = "f82db71a:7t7xgzcx" },
            { initialValue = 5, perLevelValue = 0, statRef = "f82db71a:jslmczbi" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:fercjhm5" },
            { initialValue = 5, perLevelValue = 0, statRef = "f82db71a:69hfqhne" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:hj6d4kvy" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:0w7c7p09" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:jjn0my8k" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:pg0ytacb" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:954yunb9" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:itpo751d" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:hlyrsstn" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:rgnrtg01" },
            { initialValue = 40, perLevelValue = 0, statRef = "f82db71a:s1mt6jh9" },
        },
        tags = {  },
    },
}
```
