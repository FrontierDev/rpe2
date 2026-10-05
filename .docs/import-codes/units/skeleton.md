# Skeleton Unit Import Code

Standalone `RPE_DATASET_ENTRY_V1` import code for the base Skeleton unit and its five role variants in the Core dataset (`f82db71a`).

## Base Skeleton calibration

| Stat | Initial | Per level | Level 60 |
|---|---:|---:|---:|
| Health | 110 | 21.864407 | 1,400 |
| Mana | 80 | 18.983051 | 1,200 |
| Rage | 100 | 0 | 100 |
| Armor | 25 | 16.525424 | 1,000 |
| Melee Attack Power | 45 | 4.745763 | 325 |
| Ranged Attack Power | 45 | 4.745763 | 325 |
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
| Fire Resistance | 0 | 0 | 0 |
| Frost Resistance | 0 | 0 | 0 |
| Nature Resistance | 0 | 0 | 0 |
| Arcane Resistance | 0 | 0 | 0 |
| Shadow Resistance | 0 | 0 | 0 |
| Holy Resistance | 0 | 0 | 0 |
| Resource Regeneration | 0 | 0 | 0 |
| Movement Speed | 30 | 0 | 30 |

The base Skeleton is a `minor`, `medium` Undead. It uses the Core Natural Attack when no preset is selected. Mana and Rage are present on the base unit so the role presets can use the existing class spell datasets without adding separate resources.

## Variants

Every preset explicitly equips a valid main-hand weapon and includes Core Main Hand Attack (`f82db71a:z36xzk0w`) as a melee fallback.

### Warrior — Normal

- Main hand: Worn Greatsword (`f82db71a:stw2sw01`)
- Spells:
  - Main Hand Attack
  - Rage Attack
  - Rend
  - Cleave
- Mana is disabled.
- Level-60 targets: 2,500 Health, 1,800 Armor, 500 MAP.

### Archer — Normal

- Main hand: Worn Shortsword (`f82db71a:stwswd01`)
- Ranged weapon: Worn Shortbow (`f82db71a:stwbow01`)
- Spells:
  - Main Hand Attack
  - Shoot
  - Aimed Shot
- Rage is disabled.
- Level-60 targets: 2,300 Health, 1,500 Armor, 500 RAP.

### Mage — Normal

- Main hand: Bent Staff (`f82db71a:stwstf01`)
- Spells:
  - Main Hand Attack
  - Ice Armor
  - Frostbolt
  - Frost Nova
- Rage is disabled.
- Level-60 targets: 2,300 Health, 1,500 Armor, 250 SP, 1,500 Mana.

### Shadowmage — Elite

- Main hand: Bent Staff (`f82db71a:stwstf01`)
- Spells:
  - Main Hand Attack
  - Shadow Bolt
  - Corruption
  - Curse of Agony
  - Shadow Ward
  - Fear
- Rage is disabled.
- Level-60 targets: 8,500 Health, 3,000 Armor, 250 SP, 2,500 Mana.

### Warder — Elite

- Main hand: Worn Shortsword (`f82db71a:stwswd01`)
- Shield: Worn Shield (`f82db71a:stshld01`)
- Spells:
  - Main Hand Attack
  - Rage Attack
  - Devastate
  - Shield Block
  - Shield Bash
- Mana is disabled.
- Level-60 targets: 9,000 Health, 4,500 Armor, 550 MAP, +5 Melee Hit, +5 Parry, +10 Block.

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
        creatureType = "undead",
        id = "skeleton1",
        name = "Skeleton",
        presets = {
            {
                name = "Warrior",
                challengeLevel = "normal",
                resourceModifiers = {
                    { resourceRef = "f82db71a:4c8mfm99", percentBonus = -100, flatBonus = 0 },
                },
                statModifiers = {
                    { statRef = "f82db71a:v42albuv", percentBonus = 80, flatBonus = 0 },
                    { statRef = "f82db71a:u7b49vs9", percentBonus = 53.846154, flatBonus = 0 },
                    { statRef = "f82db71a:v2rs9cpy", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:7t7xgzcx", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:wbj4zuf3", percentBonus = 0, flatBonus = 5 },
                    { statRef = "f82db71a:jslmczbi", percentBonus = 0, flatBonus = 3 },
                },
                resourceModifiers = {
                    { resourceRef = "f82db71a:q2ktkztt", percentBonus = 78.571429, flatBonus = 0 },
                    { resourceRef = "f82db71a:4c8mfm99", percentBonus = -100, flatBonus = 0 },
                },
                spells = {
                    "f82db71a:z36xzk0w",
                    "f82db71a:npcrage1",
                    "7bbb4cb9:xniv44uu",
                    "7bbb4cb9:e0mooybr",
                },
                equipment = {
                    mainHandWeapon = "f82db71a:stw2sw01",
                },
            },
            {
                name = "Archer",
                challengeLevel = "normal",
                resourceModifiers = {
                    { resourceRef = "f82db71a:q2ktkztt", percentBonus = 64.285714, flatBonus = 0 },
                    { resourceRef = "f82db71a:e2tfklq7", percentBonus = -100, flatBonus = 0 },
                },
                statModifiers = {
                    { statRef = "f82db71a:v42albuv", percentBonus = 50, flatBonus = 0 },
                    { statRef = "f82db71a:v2rs9cpy", percentBonus = 53.846154, flatBonus = 0 },
                    { statRef = "f82db71a:7t7xgzcx", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:dd88li4c", percentBonus = 0, flatBonus = 5 },
                    { statRef = "f82db71a:fercjhm5", percentBonus = 0, flatBonus = 3 },
                },
                spells = {
                    "f82db71a:z36xzk0w",
                    "f82db71a:shoota01",
                    "a93f7c12:nq9mgf7d",
                },
                equipment = {
                    mainHandWeapon = "f82db71a:stwswd01",
                    rangedWeapon = "f82db71a:stwbow01",
                },
            },
            {
                name = "Mage",
                challengeLevel = "normal",
                resourceModifiers = {
                    { resourceRef = "f82db71a:q2ktkztt", percentBonus = 64.285714, flatBonus = 0 },
                    { resourceRef = "f82db71a:4c8mfm99", percentBonus = 25, flatBonus = 0 },
                    { resourceRef = "f82db71a:e2tfklq7", percentBonus = -100, flatBonus = 0 },
                },
                statModifiers = {
                    { statRef = "f82db71a:v42albuv", percentBonus = 50, flatBonus = 0 },
                    { statRef = "f82db71a:v2rs9cpy", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:7t7xgzcx", percentBonus = 66.666667, flatBonus = 0 },
                    { statRef = "f82db71a:v2g0tw0o", percentBonus = 0, flatBonus = 5 },
                },
                spells = {
                    "f82db71a:z36xzk0w",
                    "d7c874c4:icearm01",
                    "d7c874c4:lywroiqu",
                    "d7c874c4:7ha8pdoy",
                },
                equipment = {
                    mainHandWeapon = "f82db71a:stwstf01",
                },
            },
            {
                name = "Shadowmage",
                challengeLevel = "elite",
                resourceModifiers = {
                    { resourceRef = "f82db71a:q2ktkztt", percentBonus = 507.142857, flatBonus = 0 },
                    { resourceRef = "f82db71a:4c8mfm99", percentBonus = 108.333333, flatBonus = 0 },
                    { resourceRef = "f82db71a:e2tfklq7", percentBonus = -100, flatBonus = 0 },
                },
                statModifiers = {
                    { statRef = "f82db71a:v42albuv", percentBonus = 200, flatBonus = 0 },
                    { statRef = "f82db71a:v2rs9cpy", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:7t7xgzcx", percentBonus = 66.666667, flatBonus = 0 },
                    { statRef = "f82db71a:v2g0tw0o", percentBonus = 0, flatBonus = 5 },
                },
                spells = {
                    "f82db71a:z36xzk0w",
                    "e8f3b2c6:wlsbolt1",
                    "e8f3b2c6:wlcorru1",
                    "e8f3b2c6:wlcago01",
                    "e8f3b2c6:wlshwads",
                    "e8f3b2c6:wlfear01",
                },
                equipment = {
                    mainHandWeapon = "f82db71a:stwstf01",
                },
            },
            {
                name = "Warder",
                challengeLevel = "elite",
                resourceModifiers = {
                    { resourceRef = "f82db71a:q2ktkztt", percentBonus = 542.857143, flatBonus = 0 },
                    { resourceRef = "f82db71a:4c8mfm99", percentBonus = -100, flatBonus = 0 },
                },
                statModifiers = {
                    { statRef = "f82db71a:v42albuv", percentBonus = 350, flatBonus = 0 },
                    { statRef = "f82db71a:u7b49vs9", percentBonus = 69.230769, flatBonus = 0 },
                    { statRef = "f82db71a:v2rs9cpy", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:7t7xgzcx", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:wbj4zuf3", percentBonus = 0, flatBonus = 5 },
                    { statRef = "f82db71a:tcn0s8kx", percentBonus = 0, flatBonus = 5 },
                    { statRef = "f82db71a:p8syz5ba", percentBonus = 0, flatBonus = 10 },
                },
                spells = {
                    "f82db71a:z36xzk0w",
                    "f82db71a:npcrage1",
                    "7bbb4cb9:devast01",
                    "7bbb4cb9:g36ujwt9",
                    "7bbb4cb9:ti2j4umn",
                },
                equipment = {
                    mainHandWeapon = "f82db71a:stwswd01",
                    shield = "f82db71a:stshld01",
                },
            },
        },
        resistances = {  },
        resources = {
            {
                initialValue = 110,
                perLevelValue = 21.864407,
                resourceRef = "f82db71a:q2ktkztt",
            },
            {
                initialValue = 80,
                perLevelValue = 18.983051,
                resourceRef = "f82db71a:4c8mfm99",
            },
            {
                initialValue = 100,
                perLevelValue = 0,
                resourceRef = "f82db71a:e2tfklq7",
            },
        },
        spells = {
            "f82db71a:natatk01",
        },
        stats = {
            {
                initialValue = 25,
                perLevelValue = 16.525424,
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
                initialValue = 45,
                perLevelValue = 4.745763,
                statRef = "f82db71a:u7b49vs9",
            },
            {
                initialValue = 45,
                perLevelValue = 4.745763,
                statRef = "f82db71a:v2rs9cpy",
            },
            {
                initialValue = 0,
                perLevelValue = 2.542373,
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
