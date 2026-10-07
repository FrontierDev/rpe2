# Murloc Unit Import Code

Standalone `RPE_DATASET_ENTRY_V1` import code for the base Murloc and its Tidehunter, Hunter, Oracle and Chieftain presets in the Core dataset (`f82db71a`).

Import `.docs/import-codes/spells/murloc-abilities.md` before importing this Unit.

## Base Murloc

The base Murloc is a `minor`, `medium` Humanoid. It is fast, lightly armored, and uses Natural Attack.

### Level-60 calibration

| Stat | Initial | Per level | Level 60 |
|---|---:|---:|---:|
| Health | 120 | 25.084746 | 1,600 |
| Mana | 0 | 0 | 0 |
| Rage | 0 | 0 | 0 |
| Armor | 15 | 11.610169 | 700 |
| Melee Attack Power | 40 | 5.254237 | 350 |
| Ranged Attack Power | 35 | 4.491525 | 300 |
| Spell Power | 0 | 2.542373 | 150 |
| Healing Power | 0 | 2.542373 | 150 |
| Melee Hit Chance | 0 | 0 | 0 |
| Ranged Hit Chance | 0 | 0 | 0 |
| Spell Hit Chance | 0 | 0 | 0 |
| Melee Crit Chance | 5 | 0 | 5 |
| Ranged Crit Chance | 5 | 0 | 5 |
| Spell Crit Chance | 5 | 0 | 5 |
| Parry Chance | 0 | 0 | 0 |
| Dodge Chance | 3 | 0 | 3 |
| Block Chance | 0 | 0 | 0 |
| Magic Resistance | 0 | 0 | 0 |
| Resource Regeneration | 0 | 0 | 0 |
| Movement Speed | 35 | 0 | 35 |

## Presets

### Tidehunter — Normal

- 2,800 Health
- 1,600 Armor
- 500 Melee Attack Power
- +5 Melee Hit
- Worn Spear
- Main Hand Attack
- Spear Thrust

### Hunter — Normal

- 2,500 Health
- 1,200 Armor
- 475 Ranged Attack Power
- +5 Ranged Hit
- 8% Ranged Crit
- Worn Shortbow
- Natural Attack
- Shoot

### Oracle — Normal

- 2,400 Health
- 1,000 Armor
- 1,800 Mana
- 275 Spell Power
- 300 Healing Power
- +5 Spell Hit
- 8% Spell Crit
- Bent Staff
- Lightning Bolt
- Healing Wave

### Chieftain — Elite

- 9,500 Health
- 4,000 Armor
- 700 Melee Attack Power
- 100 Rage
- +5 Melee Hit
- +5 Parry
- Worn Axe
- Rage Attack
- Cleave
- Pummel

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
        id = "murloc01",
        name = "Murloc",
        presets = {
            {
                name = "Tidehunter",
                challengeLevel = "normal",
                resourceModifiers = {
                    { resourceRef = "f82db71a:q2ktkztt", percentBonus = 75, flatBonus = 0 },
                },
                statModifiers = {
                    { statRef = "f82db71a:v42albuv", percentBonus = 128.571429, flatBonus = 0 },
                    { statRef = "f82db71a:u7b49vs9", percentBonus = 42.857143, flatBonus = 0 },
                    { statRef = "f82db71a:v2rs9cpy", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:7t7xgzcx", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:hj6d4kvy", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:wbj4zuf3", percentBonus = 0, flatBonus = 5 },
                },
                spells = {
                    "f82db71a:z36xzk0w",
                    "f82db71a:murspear1",
                },
                equipment = {
                    mainHandWeapon = "f82db71a:stwpol01",
                },
            },
            {
                name = "Hunter",
                challengeLevel = "normal",
                resourceModifiers = {
                    { resourceRef = "f82db71a:q2ktkztt", percentBonus = 56.25, flatBonus = 0 },
                },
                statModifiers = {
                    { statRef = "f82db71a:v42albuv", percentBonus = 71.428571, flatBonus = 0 },
                    { statRef = "f82db71a:u7b49vs9", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:v2rs9cpy", percentBonus = 58.333333, flatBonus = 0 },
                    { statRef = "f82db71a:7t7xgzcx", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:hj6d4kvy", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:dd88li4c", percentBonus = 0, flatBonus = 5 },
                    { statRef = "f82db71a:fercjhm5", percentBonus = 0, flatBonus = 3 },
                },
                spells = {
                    "f82db71a:natatk01",
                    "f82db71a:shoota01",
                },
                equipment = {
                    rangedWeapon = "f82db71a:stwbow01",
                },
            },
            {
                name = "Oracle",
                challengeLevel = "normal",
                resourceModifiers = {
                    { resourceRef = "f82db71a:q2ktkztt", percentBonus = 50, flatBonus = 0 },
                    { resourceRef = "f82db71a:4c8mfm99", percentBonus = 0, flatBonus = 1800 },
                },
                statModifiers = {
                    { statRef = "f82db71a:v42albuv", percentBonus = 42.857143, flatBonus = 0 },
                    { statRef = "f82db71a:u7b49vs9", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:v2rs9cpy", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:7t7xgzcx", percentBonus = 83.333333, flatBonus = 0 },
                    { statRef = "f82db71a:hj6d4kvy", percentBonus = 100, flatBonus = 0 },
                    { statRef = "f82db71a:v2g0tw0o", percentBonus = 0, flatBonus = 5 },
                    { statRef = "f82db71a:69hfqhne", percentBonus = 0, flatBonus = 3 },
                },
                spells = {
                    "c4a91e7d:shlbolt1",
                    "c4a91e7d:shhealwv",
                },
                equipment = {
                    mainHandWeapon = "f82db71a:stwstf01",
                },
            },
            {
                name = "Chieftain",
                challengeLevel = "elite",
                resourceModifiers = {
                    { resourceRef = "f82db71a:q2ktkztt", percentBonus = 493.75, flatBonus = 0 },
                    { resourceRef = "f82db71a:e2tfklq7", percentBonus = 0, flatBonus = 100 },
                },
                statModifiers = {
                    { statRef = "f82db71a:v42albuv", percentBonus = 471.428571, flatBonus = 0 },
                    { statRef = "f82db71a:u7b49vs9", percentBonus = 100, flatBonus = 0 },
                    { statRef = "f82db71a:v2rs9cpy", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:7t7xgzcx", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:hj6d4kvy", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:wbj4zuf3", percentBonus = 0, flatBonus = 5 },
                    { statRef = "f82db71a:tcn0s8kx", percentBonus = 0, flatBonus = 5 },
                },
                spells = {
                    "f82db71a:npcrage1",
                    "7bbb4cb9:e0mooybr",
                    "7bbb4cb9:pummel01",
                },
                equipment = {
                    mainHandWeapon = "f82db71a:stwaxe01",
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
                resourceRef = "f82db71a:e2tfklq7",
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
            { initialValue = 3, perLevelValue = 0, statRef = "f82db71a:o6113cir" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:p8syz5ba" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:zs1nbz13" },
            { initialValue = 40, perLevelValue = 5.254237, statRef = "f82db71a:u7b49vs9" },
            { initialValue = 35, perLevelValue = 4.491525, statRef = "f82db71a:v2rs9cpy" },
            { initialValue = 0, perLevelValue = 2.542373, statRef = "f82db71a:7t7xgzcx" },
            { initialValue = 5, perLevelValue = 0, statRef = "f82db71a:jslmczbi" },
            { initialValue = 5, perLevelValue = 0, statRef = "f82db71a:fercjhm5" },
            { initialValue = 5, perLevelValue = 0, statRef = "f82db71a:69hfqhne" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:0w7c7p09" },
            { initialValue = 0, perLevelValue = 2.542373, statRef = "f82db71a:hj6d4kvy" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:jjn0my8k" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:pg0ytacb" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:954yunb9" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:itpo751d" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:hlyrsstn" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:rgnrtg01" },
            { initialValue = 35, perLevelValue = 0, statRef = "f82db71a:s1mt6jh9" },
        },
        tags = {  },
    },
}
```
