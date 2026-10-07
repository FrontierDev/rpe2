# Gnoll Unit Import Code

Standalone `RPE_DATASET_ENTRY_V1` import code for the base Gnoll and its Brute, Poacher, Shaman and Overseer presets in the Core dataset (`f82db71a`).

## Base Gnoll

The base Gnoll is a `minor`, `medium` Humanoid with a Natural Attack. Mana and Rage are defined as zero-sized resource pools so presets can enable them without requiring a separate unit.

### Level-60 calibration

| Stat | Initial | Per level | Level 60 |
|---|---:|---:|---:|
| Health | 130 | 28.305085 | 1,800 |
| Mana | 0 | 0 | 0 |
| Rage | 0 | 0 | 0 |
| Armor | 20 | 16.610169 | 1,000 |
| Melee Attack Power | 45 | 6.016949 | 400 |
| Ranged Attack Power | 40 | 5.254237 | 350 |
| Spell Power | 0 | 2.542373 | 150 |
| Healing Power | 0 | 2.542373 | 150 |
| Melee Hit Chance | 0 | 0 | 0 |
| Ranged Hit Chance | 0 | 0 | 0 |
| Spell Hit Chance | 0 | 0 | 0 |
| Melee Crit Chance | 5 | 0 | 5 |
| Ranged Crit Chance | 5 | 0 | 5 |
| Spell Crit Chance | 5 | 0 | 5 |
| Parry Chance | 0 | 0 | 0 |
| Dodge Chance | 0 | 0 | 0 |
| Block Chance | 0 | 0 | 0 |
| Magic Resistance | 0 | 0 | 0 |
| Fire Resistance | 0 | 0 | 0 |
| Frost Resistance | 0 | 0 | 0 |
| Nature Resistance | 0 | 0 | 0 |
| Arcane Resistance | 0 | 0 | 0 |
| Shadow Resistance | 0 | 0 | 0 |
| Holy Resistance | 0 | 0 | 0 |
| Resource Regeneration | 0 | 0 | 0 |
| Movement Speed | 30 | 0 | 30 |

## Presets

### Brute — Normal

- 3,200 Health
- 2,200 Armor
- 550 Melee Attack Power
- +5 Melee Hit
- 100 Rage
- Worn Axe
- Main Hand Attack
- Cleave

### Poacher — Normal

- 2,600 Health
- 1,500 Armor
- 500 Ranged Attack Power
- +5 Ranged Hit
- 8% Ranged Crit
- Worn Shortbow
- Natural Attack
- Shoot

### Shaman — Normal

- 2,500 Health
- 1,200 Armor
- 275 Spell Power
- 300 Healing Power
- +5 Spell Hit
- 8% Spell Crit
- 1,800 Mana
- Bent Staff
- Lightning Bolt
- Healing Wave
- Lightning Shield

### Overseer — Elite

- 10,000 Health
- 4,500 Armor
- 750 Melee Attack Power
- +5 Melee Hit
- +5 Parry
- 100 Rage
- Worn Axe
- Rage Attack
- Cleave
- Battle Shout
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
        id = "gnoll001",
        name = "Gnoll",
        presets = {
            {
                name = "Brute",
                challengeLevel = "normal",
                resourceModifiers = {
                    { resourceRef = "f82db71a:q2ktkztt", percentBonus = 77.777778, flatBonus = 0 },
                    { resourceRef = "f82db71a:e2tfklq7", percentBonus = 0, flatBonus = 100 },
                },
                statModifiers = {
                    { statRef = "f82db71a:v42albuv", percentBonus = 120, flatBonus = 0 },
                    { statRef = "f82db71a:u7b49vs9", percentBonus = 37.5, flatBonus = 0 },
                    { statRef = "f82db71a:v2rs9cpy", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:7t7xgzcx", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:hj6d4kvy", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:wbj4zuf3", percentBonus = 0, flatBonus = 5 },
                },
                spells = {
                    "f82db71a:z36xzk0w",
                    "7bbb4cb9:e0mooybr",
                },
                equipment = {
                    mainHandWeapon = "f82db71a:stwaxe01",
                },
            },
            {
                name = "Poacher",
                challengeLevel = "normal",
                resourceModifiers = {
                    { resourceRef = "f82db71a:q2ktkztt", percentBonus = 44.444444, flatBonus = 0 },
                },
                statModifiers = {
                    { statRef = "f82db71a:v42albuv", percentBonus = 50, flatBonus = 0 },
                    { statRef = "f82db71a:u7b49vs9", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:v2rs9cpy", percentBonus = 42.857143, flatBonus = 0 },
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
                name = "Shaman",
                challengeLevel = "normal",
                resourceModifiers = {
                    { resourceRef = "f82db71a:q2ktkztt", percentBonus = 38.888889, flatBonus = 0 },
                    { resourceRef = "f82db71a:4c8mfm99", percentBonus = 0, flatBonus = 1800 },
                },
                statModifiers = {
                    { statRef = "f82db71a:v42albuv", percentBonus = 20, flatBonus = 0 },
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
                    "c4a91e7d:shlshldt",
                },
                equipment = {
                    mainHandWeapon = "f82db71a:stwstf01",
                },
            },
            {
                name = "Overseer",
                challengeLevel = "elite",
                resourceModifiers = {
                    { resourceRef = "f82db71a:q2ktkztt", percentBonus = 455.555556, flatBonus = 0 },
                    { resourceRef = "f82db71a:e2tfklq7", percentBonus = 0, flatBonus = 100 },
                },
                statModifiers = {
                    { statRef = "f82db71a:v42albuv", percentBonus = 350, flatBonus = 0 },
                    { statRef = "f82db71a:u7b49vs9", percentBonus = 87.5, flatBonus = 0 },
                    { statRef = "f82db71a:v2rs9cpy", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:7t7xgzcx", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:hj6d4kvy", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:wbj4zuf3", percentBonus = 0, flatBonus = 5 },
                    { statRef = "f82db71a:tcn0s8kx", percentBonus = 0, flatBonus = 5 },
                },
                spells = {
                    "f82db71a:npcrage1",
                    "7bbb4cb9:e0mooybr",
                    "7bbb4cb9:9gh28pe5",
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
                initialValue = 130,
                perLevelValue = 28.305085,
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
            { initialValue = 20, perLevelValue = 16.610169, statRef = "f82db71a:v42albuv" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:wbj4zuf3" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:dd88li4c" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:v2g0tw0o" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:tcn0s8kx" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:o6113cir" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:p8syz5ba" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:zs1nbz13" },
            { initialValue = 45, perLevelValue = 6.016949, statRef = "f82db71a:u7b49vs9" },
            { initialValue = 40, perLevelValue = 5.254237, statRef = "f82db71a:v2rs9cpy" },
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
            { initialValue = 30, perLevelValue = 0, statRef = "f82db71a:s1mt6jh9" },
        },
        tags = {  },
    },
}
```
