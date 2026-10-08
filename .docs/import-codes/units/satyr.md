# Satyr Unit Import Code

Standalone `RPE_DATASET_ENTRY_V1` import code for the base Satyr and its Trickster, Hellcaller, Shadowstalker and Soulstealer presets in the Core dataset (`f82db71a`).

## Base Satyr

The base Satyr is a `minor`, `medium` Humanoid. It is lightly armored, evasive, relatively mobile, and has a small innate Shadow Resistance.

### Level-60 calibration

| Stat | Initial | Per level | Level 60 |
|---|---:|---:|---:|
| Health | 120 | 25.084746 | 1,600 |
| Mana | 0 | 0 | 0 |
| Energy | 0 | 0 | 0 |
| Armor | 15 | 11.610169 | 700 |
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
| Dodge Chance | 8 | 0 | 8 |
| Block Chance | 0 | 0 | 0 |
| Magic Resistance | 0 | 0 | 0 |
| Shadow Resistance | 10 | 0 | 10 |
| Resource Regeneration | 0 | 0 | 0 |
| Movement Speed | 35 | 0 | 35 |

## Presets

### Trickster — Normal

- 2,500 Health
- 1,100 Armor
- 1,800 Mana
- 275 Spell Power
- +5 Spell Hit
- 8% Spell Crit
- 10 Shadow Resistance
- Bent Staff
- Shadow Bolt
- Corruption

### Hellcaller — Normal

- 2,600 Health
- 1,200 Armor
- 1,800 Mana
- 300 Spell Power
- +5 Spell Hit
- 8% Spell Crit
- 10 Shadow Resistance
- Bent Staff
- Fireball
- Immolate

### Shadowstalker — Normal

- 2,800 Health
- 1,400 Armor
- 500 Melee Attack Power
- 100 Energy
- +5 Melee Hit
- 10% Melee Crit
- 12% Dodge
- 10 Shadow Resistance
- Worn Dagger
- Main Hand Attack
- Cheap Shot

### Soulstealer — Elite

- 8,500 Health
- 2,500 Armor
- 2,500 Mana
- 450 Spell Power
- +5 Spell Hit
- 10% Spell Crit
- 20 Shadow Resistance
- Bent Staff
- Shadow Bolt
- Corruption
- Drain Life
- Fear

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
        creatureSize = "medium",
        creatureType = "humanoid",
        id = "satyr01",
        name = "Satyr",
        presets = {
            {
                name = "Trickster",
                challengeLevel = "normal",
                resourceModifiers = {
                    { resourceRef = "f82db71a:q2ktkztt", percentBonus = 56.25, flatBonus = 0 },
                    { resourceRef = "f82db71a:4c8mfm99", percentBonus = 0, flatBonus = 1800 },
                },
                statModifiers = {
                    { statRef = "f82db71a:v42albuv", percentBonus = 57.142857, flatBonus = 0 },
                    { statRef = "f82db71a:u7b49vs9", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:7t7xgzcx", percentBonus = 83.333333, flatBonus = 0 },
                    { statRef = "f82db71a:v2g0tw0o", percentBonus = 0, flatBonus = 5 },
                    { statRef = "f82db71a:69hfqhne", percentBonus = 0, flatBonus = 3 },
                },
                spells = {
                    "e8f3b2c6:wlsbolt1",
                    "e8f3b2c6:wlcorru1",
                },
                equipment = {
                    mainHandWeapon = "f82db71a:stwstf01",
                },
            },
            {
                name = "Hellcaller",
                challengeLevel = "normal",
                resourceModifiers = {
                    { resourceRef = "f82db71a:q2ktkztt", percentBonus = 62.5, flatBonus = 0 },
                    { resourceRef = "f82db71a:4c8mfm99", percentBonus = 0, flatBonus = 1800 },
                },
                statModifiers = {
                    { statRef = "f82db71a:v42albuv", percentBonus = 71.428571, flatBonus = 0 },
                    { statRef = "f82db71a:u7b49vs9", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:7t7xgzcx", percentBonus = 100, flatBonus = 0 },
                    { statRef = "f82db71a:v2g0tw0o", percentBonus = 0, flatBonus = 5 },
                    { statRef = "f82db71a:69hfqhne", percentBonus = 0, flatBonus = 3 },
                },
                spells = {
                    "d7c874c4:68dy7na1",
                    "e8f3b2c6:wlimmol1",
                },
                equipment = {
                    mainHandWeapon = "f82db71a:stwstf01",
                },
            },
            {
                name = "Shadowstalker",
                challengeLevel = "normal",
                resourceModifiers = {
                    { resourceRef = "f82db71a:q2ktkztt", percentBonus = 75, flatBonus = 0 },
                    { resourceRef = "f82db71a:c3gaf7dd", percentBonus = 0, flatBonus = 100 },
                },
                statModifiers = {
                    { statRef = "f82db71a:v42albuv", percentBonus = 100, flatBonus = 0 },
                    { statRef = "f82db71a:u7b49vs9", percentBonus = 53.846154, flatBonus = 0 },
                    { statRef = "f82db71a:7t7xgzcx", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:wbj4zuf3", percentBonus = 0, flatBonus = 5 },
                    { statRef = "f82db71a:jslmczbi", percentBonus = 0, flatBonus = 5 },
                    { statRef = "f82db71a:o6113cir", percentBonus = 0, flatBonus = 4 },
                },
                spells = {
                    "f82db71a:z36xzk0w",
                    "23d5dce2:chpsht01",
                },
                equipment = {
                    mainHandWeapon = "f82db71a:stwdgr01",
                },
            },
            {
                name = "Soulstealer",
                challengeLevel = "elite",
                resourceModifiers = {
                    { resourceRef = "f82db71a:q2ktkztt", percentBonus = 431.25, flatBonus = 0 },
                    { resourceRef = "f82db71a:4c8mfm99", percentBonus = 0, flatBonus = 2500 },
                },
                statModifiers = {
                    { statRef = "f82db71a:v42albuv", percentBonus = 257.142857, flatBonus = 0 },
                    { statRef = "f82db71a:u7b49vs9", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:7t7xgzcx", percentBonus = 200, flatBonus = 0 },
                    { statRef = "f82db71a:v2g0tw0o", percentBonus = 0, flatBonus = 5 },
                    { statRef = "f82db71a:69hfqhne", percentBonus = 0, flatBonus = 5 },
                    { statRef = "f82db71a:itpo751d", percentBonus = 0, flatBonus = 10 },
                },
                spells = {
                    "e8f3b2c6:wlsbolt1",
                    "e8f3b2c6:wlcorru1",
                    "e8f3b2c6:wldrlif1",
                    "e8f3b2c6:wlfear01",
                },
                equipment = {
                    mainHandWeapon = "f82db71a:stwstf01",
                },
            },
        },
        resistances = {  },
        resources = {
            {
                initialValue = 120,
                perLevelValue = 25.084746,
                resourceRef = "f82db71a:q2ktkztt",
            },
            {
                initialValue = 0,
                perLevelValue = 0,
                resourceRef = "f82db71a:4c8mfm99",
            },
            {
                initialValue = 0,
                perLevelValue = 0,
                resourceRef = "f82db71a:c3gaf7dd",
            },
        },
        spells = {
            "f82db71a:natatk01",
        },
        stats = {
            { initialValue = 15, perLevelValue = 11.610169, statRef = "f82db71a:v42albuv" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:wbj4zuf3" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:dd88li4c" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:v2g0tw0o" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:tcn0s8kx" },
            { initialValue = 8, perLevelValue = 0, statRef = "f82db71a:o6113cir" },
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
            { initialValue = 10, perLevelValue = 0, statRef = "f82db71a:itpo751d" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:hlyrsstn" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:rgnrtg01" },
            { initialValue = 35, perLevelValue = 0, statRef = "f82db71a:s1mt6jh9" },
        },
        tags = {  },
    },
}
```
