# Goblin Unit Import Code

Standalone `RPE_DATASET_ENTRY_V1` import code for the base Goblin and its Bruiser, Sharpshooter, Sapper, Engineer and Foreman presets in the Core dataset (`f82db71a`).

Import the supporting Goblin abilities and turret unit first, following the order in `.docs/import-codes/spells/goblin-abilities.md`.

## Base Goblin

The base Goblin is a `minor`, `small` Humanoid. It is lightly armored and mobile, with modest melee power and stronger ranged potential.

### Level-60 calibration

| Stat | Initial | Per level | Level 60 |
|---|---:|---:|---:|
| Health | 100 | 20.338983 | 1,300 |
| Rage | 0 | 0 | 0 |
| Armor | 10 | 10.000000 | 600 |
| Melee Attack Power | 30 | 3.728814 | 250 |
| Ranged Attack Power | 35 | 4.491525 | 300 |
| Spell Power | 0 | 0 | 0 |
| Healing Power | 0 | 0 | 0 |
| Melee Hit Chance | 0 | 0 | 0 |
| Ranged Hit Chance | 0 | 0 | 0 |
| Spell Hit Chance | 0 | 0 | 0 |
| Melee Crit Chance | 5 | 0 | 5 |
| Ranged Crit Chance | 5 | 0 | 5 |
| Spell Crit Chance | 0 | 0 | 0 |
| Parry Chance | 0 | 0 | 0 |
| Dodge Chance | 5 | 0 | 5 |
| Block Chance | 0 | 0 | 0 |
| Magic Resistance | 0 | 0 | 0 |
| Resource Regeneration | 0 | 0 | 0 |
| Movement Speed | 35 | 0 | 35 |

## Presets

### Bruiser — Normal

- 2,800 Health
- 1,800 Armor
- 550 Melee Attack Power
- 100 Rage
- +5 Melee Hit
- Worn Mace
- Rage Attack
- Pummel
- Slam

### Sharpshooter — Normal

- 2,300 Health
- 900 Armor
- 500 Ranged Attack Power
- +5 Ranged Hit
- 8% Ranged Crit
- Worn Shortbow
- Natural Attack
- Shoot

### Sapper — Normal

- 2,400 Health
- 1,000 Armor
- 425 Ranged Attack Power
- +5 Ranged Hit
- 8% Ranged Crit
- Throw Bomb
- Explode
- Explode has a 1-turn cast and is only usable at or below 10% Health.

### Engineer — Normal

- 2,500 Health
- 1,100 Armor
- 400 Ranged Attack Power
- +5 Ranged Hit
- Worn Shortbow
- Shoot
- Deploy Turret

### Foreman — Elite

- 9,000 Health
- 3,500 Armor
- 650 Melee Attack Power
- 500 Ranged Attack Power
- 100 Rage
- +5 Melee Hit
- +5 Ranged Hit
- +5 Parry
- Worn Axe
- Rage Attack
- Cleave
- Battle Shout
- Pummel
- Throw Bomb

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
        creatureType = "humanoid",
        id = "gobnpc01",
        name = "Goblin",
        presets = {
            {
                name = "Bruiser",
                challengeLevel = "normal",
                resourceModifiers = {
                    { resourceRef = "f82db71a:q2ktkztt", percentBonus = 115.384615, flatBonus = 0 },
                    { resourceRef = "f82db71a:e2tfklq7", percentBonus = 0, flatBonus = 100 },
                },
                statModifiers = {
                    { statRef = "f82db71a:v42albuv", percentBonus = 200, flatBonus = 0 },
                    { statRef = "f82db71a:u7b49vs9", percentBonus = 120, flatBonus = 0 },
                    { statRef = "f82db71a:v2rs9cpy", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:wbj4zuf3", percentBonus = 0, flatBonus = 5 },
                },
                spells = {
                    "f82db71a:npcrage1",
                    "7bbb4cb9:pummel01",
                    "7bbb4cb9:68qm26aq",
                },
                equipment = {
                    mainHandWeapon = "f82db71a:stwmac01",
                },
            },
            {
                name = "Sharpshooter",
                challengeLevel = "normal",
                resourceModifiers = {
                    { resourceRef = "f82db71a:q2ktkztt", percentBonus = 76.923077, flatBonus = 0 },
                },
                statModifiers = {
                    { statRef = "f82db71a:v42albuv", percentBonus = 50, flatBonus = 0 },
                    { statRef = "f82db71a:u7b49vs9", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:v2rs9cpy", percentBonus = 66.666667, flatBonus = 0 },
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
                name = "Sapper",
                challengeLevel = "normal",
                resourceModifiers = {
                    { resourceRef = "f82db71a:q2ktkztt", percentBonus = 84.615385, flatBonus = 0 },
                },
                statModifiers = {
                    { statRef = "f82db71a:v42albuv", percentBonus = 66.666667, flatBonus = 0 },
                    { statRef = "f82db71a:u7b49vs9", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:v2rs9cpy", percentBonus = 41.666667, flatBonus = 0 },
                    { statRef = "f82db71a:dd88li4c", percentBonus = 0, flatBonus = 5 },
                    { statRef = "f82db71a:fercjhm5", percentBonus = 0, flatBonus = 3 },
                },
                spells = {
                    "f82db71a:gobbomb1",
                    "f82db71a:gobexpl1",
                },
                equipment = {  },
            },
            {
                name = "Engineer",
                challengeLevel = "normal",
                resourceModifiers = {
                    { resourceRef = "f82db71a:q2ktkztt", percentBonus = 92.307692, flatBonus = 0 },
                },
                statModifiers = {
                    { statRef = "f82db71a:v42albuv", percentBonus = 83.333333, flatBonus = 0 },
                    { statRef = "f82db71a:u7b49vs9", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:v2rs9cpy", percentBonus = 33.333333, flatBonus = 0 },
                    { statRef = "f82db71a:dd88li4c", percentBonus = 0, flatBonus = 5 },
                },
                spells = {
                    "f82db71a:shoota01",
                    "f82db71a:gobdept1",
                },
                equipment = {
                    rangedWeapon = "f82db71a:stwbow01",
                },
            },
            {
                name = "Foreman",
                challengeLevel = "elite",
                resourceModifiers = {
                    { resourceRef = "f82db71a:q2ktkztt", percentBonus = 592.307692, flatBonus = 0 },
                    { resourceRef = "f82db71a:e2tfklq7", percentBonus = 0, flatBonus = 100 },
                },
                statModifiers = {
                    { statRef = "f82db71a:v42albuv", percentBonus = 483.333333, flatBonus = 0 },
                    { statRef = "f82db71a:u7b49vs9", percentBonus = 160, flatBonus = 0 },
                    { statRef = "f82db71a:v2rs9cpy", percentBonus = 66.666667, flatBonus = 0 },
                    { statRef = "f82db71a:wbj4zuf3", percentBonus = 0, flatBonus = 5 },
                    { statRef = "f82db71a:dd88li4c", percentBonus = 0, flatBonus = 5 },
                    { statRef = "f82db71a:tcn0s8kx", percentBonus = 0, flatBonus = 5 },
                },
                spells = {
                    "f82db71a:npcrage1",
                    "7bbb4cb9:e0mooybr",
                    "7bbb4cb9:9gh28pe5",
                    "7bbb4cb9:pummel01",
                    "f82db71a:gobbomb1",
                },
                equipment = {
                    mainHandWeapon = "f82db71a:stwaxe01",
                },
            },
        },
        resistances = {  },
        resources = {
            {
                initialValue = 100,
                perLevelValue = 20.338983,
                resourceRef = "f82db71a:q2ktkztt",
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
            { initialValue = 10, perLevelValue = 10, statRef = "f82db71a:v42albuv" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:wbj4zuf3" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:dd88li4c" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:v2g0tw0o" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:tcn0s8kx" },
            { initialValue = 5, perLevelValue = 0, statRef = "f82db71a:o6113cir" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:p8syz5ba" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:zs1nbz13" },
            { initialValue = 30, perLevelValue = 3.728814, statRef = "f82db71a:u7b49vs9" },
            { initialValue = 35, perLevelValue = 4.491525, statRef = "f82db71a:v2rs9cpy" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:7t7xgzcx" },
            { initialValue = 5, perLevelValue = 0, statRef = "f82db71a:jslmczbi" },
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
            { initialValue = 35, perLevelValue = 0, statRef = "f82db71a:s1mt6jh9" },
        },
        tags = {  },
    },
}
```
