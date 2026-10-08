# Centaur Unit Import Code

Standalone `RPE_DATASET_ENTRY_V1` import code for the base Centaur and its Marauder, Archer, Geomancer, Windchaser and Khan presets in the Core dataset (`f82db71a`).

## Base Centaur

The base Centaur is a `minor`, `large` Humanoid. It has high movement, moderate durability, and balanced melee/ranged potential.

### Level-60 calibration

| Stat | Initial | Per level | Level 60 |
|---|---:|---:|---:|
| Health | 130 | 28.305085 | 1,800 |
| Mana | 0 | 0 | 0 |
| Rage | 0 | 0 | 0 |
| Armor | 20 | 16.610169 | 1,000 |
| Melee Attack Power | 45 | 5.593220 | 375 |
| Ranged Attack Power | 40 | 5.254237 | 350 |
| Spell Power | 0 | 2.542373 | 150 |
| Healing Power | 0 | 0 | 0 |
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
| Resource Regeneration | 0 | 0 | 0 |
| Movement Speed | 40 | 0 | 40 |

## Presets

### Marauder — Normal

- 3,400 Health
- 2,200 Armor
- 600 Melee Attack Power
- 100 Rage
- +5 Melee Hit
- Worn Spear
- Rage Attack
- Rend
- Knockdown

### Archer — Normal

- 2,700 Health
- 1,400 Armor
- 525 Ranged Attack Power
- +5 Ranged Hit
- 8% Ranged Crit
- Worn Shortbow
- Natural Attack
- Shoot

### Geomancer — Normal

- 2,600 Health
- 1,300 Armor
- 1,800 Mana
- 275 Spell Power
- +5 Spell Hit
- 8% Spell Crit
- Bent Staff
- Wrath
- Entangling Roots

### Windchaser — Normal

- 2,700 Health
- 1,200 Armor
- 1,900 Mana
- 300 Spell Power
- +5 Spell Hit
- 8% Spell Crit
- Bent Staff
- Cyclone
- Hurricane

### Khan — Elite

- 10,500 Health
- 4,500 Armor
- 775 Melee Attack Power
- 100 Rage
- +5 Melee Hit
- +5 Parry
- Worn Spear
- Rage Attack
- Colossus Smash
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
        creatureSize = "large",
        creatureType = "humanoid",
        id = "centaur01",
        name = "Centaur",
        presets = {
            {
                name = "Marauder",
                challengeLevel = "normal",
                resourceModifiers = {
                    { resourceRef = "f82db71a:q2ktkztt", percentBonus = 88.888889, flatBonus = 0 },
                    { resourceRef = "f82db71a:e2tfklq7", percentBonus = 0, flatBonus = 100 },
                },
                statModifiers = {
                    { statRef = "f82db71a:v42albuv", percentBonus = 120, flatBonus = 0 },
                    { statRef = "f82db71a:u7b49vs9", percentBonus = 60, flatBonus = 0 },
                    { statRef = "f82db71a:v2rs9cpy", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:7t7xgzcx", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:wbj4zuf3", percentBonus = 0, flatBonus = 5 },
                },
                spells = {
                    "f82db71a:npcrage1",
                    "7bbb4cb9:xniv44uu",
                    "7bbb4cb9:9870xnra",
                },
                equipment = {
                    mainHandWeapon = "f82db71a:stwpol01",
                },
            },
            {
                name = "Archer",
                challengeLevel = "normal",
                resourceModifiers = {
                    { resourceRef = "f82db71a:q2ktkztt", percentBonus = 50, flatBonus = 0 },
                },
                statModifiers = {
                    { statRef = "f82db71a:v42albuv", percentBonus = 40, flatBonus = 0 },
                    { statRef = "f82db71a:u7b49vs9", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:v2rs9cpy", percentBonus = 50, flatBonus = 0 },
                    { statRef = "f82db71a:7t7xgzcx", percentBonus = -100, flatBonus = 0 },
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
                name = "Geomancer",
                challengeLevel = "normal",
                resourceModifiers = {
                    { resourceRef = "f82db71a:q2ktkztt", percentBonus = 44.444444, flatBonus = 0 },
                    { resourceRef = "f82db71a:4c8mfm99", percentBonus = 0, flatBonus = 1800 },
                },
                statModifiers = {
                    { statRef = "f82db71a:v42albuv", percentBonus = 30, flatBonus = 0 },
                    { statRef = "f82db71a:u7b49vs9", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:v2rs9cpy", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:7t7xgzcx", percentBonus = 83.333333, flatBonus = 0 },
                    { statRef = "f82db71a:v2g0tw0o", percentBonus = 0, flatBonus = 5 },
                    { statRef = "f82db71a:69hfqhne", percentBonus = 0, flatBonus = 3 },
                },
                spells = {
                    "6e4d2a91:drwrth01",
                    "6e4d2a91:drroot01",
                },
                equipment = {
                    mainHandWeapon = "f82db71a:stwstf01",
                },
            },
            {
                name = "Windchaser",
                challengeLevel = "normal",
                resourceModifiers = {
                    { resourceRef = "f82db71a:q2ktkztt", percentBonus = 50, flatBonus = 0 },
                    { resourceRef = "f82db71a:4c8mfm99", percentBonus = 0, flatBonus = 1900 },
                },
                statModifiers = {
                    { statRef = "f82db71a:v42albuv", percentBonus = 20, flatBonus = 0 },
                    { statRef = "f82db71a:u7b49vs9", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:v2rs9cpy", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:7t7xgzcx", percentBonus = 100, flatBonus = 0 },
                    { statRef = "f82db71a:v2g0tw0o", percentBonus = 0, flatBonus = 5 },
                    { statRef = "f82db71a:69hfqhne", percentBonus = 0, flatBonus = 3 },
                },
                spells = {
                    "6e4d2a91:drcycl01",
                    "6e4d2a91:drhurr01",
                },
                equipment = {
                    mainHandWeapon = "f82db71a:stwstf01",
                },
            },
            {
                name = "Khan",
                challengeLevel = "elite",
                resourceModifiers = {
                    { resourceRef = "f82db71a:q2ktkztt", percentBonus = 483.333333, flatBonus = 0 },
                    { resourceRef = "f82db71a:e2tfklq7", percentBonus = 0, flatBonus = 100 },
                },
                statModifiers = {
                    { statRef = "f82db71a:v42albuv", percentBonus = 350, flatBonus = 0 },
                    { statRef = "f82db71a:u7b49vs9", percentBonus = 106.666667, flatBonus = 0 },
                    { statRef = "f82db71a:v2rs9cpy", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:7t7xgzcx", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:wbj4zuf3", percentBonus = 0, flatBonus = 5 },
                    { statRef = "f82db71a:tcn0s8kx", percentBonus = 0, flatBonus = 5 },
                },
                spells = {
                    "f82db71a:npcrage1",
                    "7bbb4cb9:colsmash",
                    "7bbb4cb9:9gh28pe5",
                    "7bbb4cb9:pummel01",
                },
                equipment = {
                    mainHandWeapon = "f82db71a:stwpol01",
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
            { initialValue = 45, perLevelValue = 5.593220, statRef = "f82db71a:u7b49vs9" },
            { initialValue = 40, perLevelValue = 5.254237, statRef = "f82db71a:v2rs9cpy" },
            { initialValue = 0, perLevelValue = 2.542373, statRef = "f82db71a:7t7xgzcx" },
            { initialValue = 5, perLevelValue = 0, statRef = "f82db71a:jslmczbi" },
            { initialValue = 5, perLevelValue = 0, statRef = "f82db71a:fercjhm5" },
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
