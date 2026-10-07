# Kobold Unit Import Code

Standalone `RPE_DATASET_ENTRY_V1` import code for the base Kobold and its Tunneler, Geomancer and Taskmaster presets in the Core dataset (`f82db71a`).

Import the supporting abilities from `.docs/import-codes/spells/kobold-abilities.md` before importing this Unit.

## Base Kobold

The base Kobold is a `minor`, `small` Humanoid. Its Mana and Rage pools are defined at zero so role presets can enable those resources without affecting the base unit.

### Level-60 calibration

| Stat | Initial | Per level | Level 60 |
|---|---:|---:|---:|
| Health | 100 | 22.033898 | 1,400 |
| Mana | 0 | 0 | 0 |
| Rage | 0 | 0 | 0 |
| Armor | 20 | 11.525424 | 700 |
| Melee Attack Power | 35 | 4.491525 | 300 |
| Ranged Attack Power | 0 | 0 | 0 |
| Spell Power | 0 | 0 | 0 |
| Healing Power | 0 | 0 | 0 |
| Melee Hit Chance | 0 | 0 | 0 |
| Ranged Hit Chance | 0 | 0 | 0 |
| Spell Hit Chance | 0 | 0 | 0 |
| Melee Crit Chance | 5 | 0 | 5 |
| Ranged Crit Chance | 0 | 0 | 0 |
| Spell Crit Chance | 0 | 0 | 0 |
| Parry Chance | 0 | 0 | 0 |
| Dodge Chance | 0 | 0 | 0 |
| Block Chance | 0 | 0 | 0 |
| Magic Resistance | 0 | 0 | 0 |
| Resource Regeneration | 0 | 0 | 0 |
| Movement Speed | 30 | 0 | 30 |

## Presets

### Tunneler — Normal

- 2,800 Health
- 1,800 Armor
- 450 Melee Attack Power
- +5 Melee Hit
- Worn Mace
- Main Hand Attack
- Puncture Armor

### Geomancer — Normal

- 2,400 Health
- 1,000 Armor
- 1,500 Mana
- 250 Spell Power
- +5 Spell Hit
- +5 Spell Crit
- Natural Attack
- Fireball
- Fire Shield

### Taskmaster — Elite

- 9,000 Health
- 3,500 Armor
- 650 Melee Attack Power
- 100 Rage
- +5 Melee Hit
- +5 Parry
- Worn Axe
- Rage Attack
- Cleave
- Pummel
- Does **not** use Demoralizing Shout.

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
        id = "kobold01",
        name = "Kobold",
        presets = {
            {
                name = "Tunneler",
                challengeLevel = "normal",
                resourceModifiers = {
                    { resourceRef = "f82db71a:q2ktkztt", percentBonus = 100, flatBonus = 0 },
                },
                statModifiers = {
                    { statRef = "f82db71a:v42albuv", percentBonus = 157.142857, flatBonus = 0 },
                    { statRef = "f82db71a:u7b49vs9", percentBonus = 50, flatBonus = 0 },
                    { statRef = "f82db71a:wbj4zuf3", percentBonus = 0, flatBonus = 5 },
                },
                spells = {
                    "f82db71a:z36xzk0w",
                    "f82db71a:kobpun01",
                },
                equipment = {
                    mainHandWeapon = "f82db71a:stwmac01",
                },
            },
            {
                name = "Geomancer",
                challengeLevel = "normal",
                resourceModifiers = {
                    { resourceRef = "f82db71a:q2ktkztt", percentBonus = 71.428571, flatBonus = 0 },
                    { resourceRef = "f82db71a:4c8mfm99", percentBonus = 0, flatBonus = 1500 },
                },
                statModifiers = {
                    { statRef = "f82db71a:v42albuv", percentBonus = 42.857143, flatBonus = 0 },
                    { statRef = "f82db71a:u7b49vs9", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:7t7xgzcx", percentBonus = 0, flatBonus = 250 },
                    { statRef = "f82db71a:v2g0tw0o", percentBonus = 0, flatBonus = 5 },
                    { statRef = "f82db71a:69hfqhne", percentBonus = 0, flatBonus = 5 },
                },
                spells = {
                    "f82db71a:natatk01",
                    "d7c874c4:68dy7na1",
                    "f82db71a:kobfire1",
                },
                equipment = {  },
            },
            {
                name = "Taskmaster",
                challengeLevel = "elite",
                resourceModifiers = {
                    { resourceRef = "f82db71a:q2ktkztt", percentBonus = 542.857143, flatBonus = 0 },
                    { resourceRef = "f82db71a:e2tfklq7", percentBonus = 0, flatBonus = 100 },
                },
                statModifiers = {
                    { statRef = "f82db71a:v42albuv", percentBonus = 400, flatBonus = 0 },
                    { statRef = "f82db71a:u7b49vs9", percentBonus = 116.666667, flatBonus = 0 },
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
                initialValue = 100,
                perLevelValue = 22.033898,
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
            { initialValue = 20, perLevelValue = 11.525424, statRef = "f82db71a:v42albuv" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:wbj4zuf3" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:dd88li4c" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:v2g0tw0o" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:tcn0s8kx" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:o6113cir" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:p8syz5ba" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:zs1nbz13" },
            { initialValue = 35, perLevelValue = 4.491525, statRef = "f82db71a:u7b49vs9" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:v2rs9cpy" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:7t7xgzcx" },
            { initialValue = 5, perLevelValue = 0, statRef = "f82db71a:jslmczbi" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:fercjhm5" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:69hfqhne" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:0w7c7p09" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:hj6d4kvy" },
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
