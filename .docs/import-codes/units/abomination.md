# Abomination Unit Import Code

Standalone `RPE_DATASET_ENTRY_V1` import code for the base Abomination unit in the Core dataset (`f82db71a`).

Import the Poison Cloud Aura and Spell from `.docs/import-codes/spells/abomination-abilities.md` before importing the Unit.

## Level-60 calibration

| Stat | Initial | Per level | Level 60 |
|---|---:|---:|---:|
| Health | 200 | 166.101695 | 10,000 |
| Rage | 100 | 0 | 100 |
| Armor | 50 | 66.949153 | 4,000 |
| Melee Attack Power | 70 | 11.525424 | 750 |
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
| Fire Resistance | 0 | 0 | 0 |
| Frost Resistance | 0 | 0 | 0 |
| Nature Resistance | 0 | 0 | 0 |
| Arcane Resistance | 0 | 0 | 0 |
| Shadow Resistance | 0 | 0 | 0 |
| Holy Resistance | 0 | 0 | 0 |
| Resource Regeneration | 0 | 0 | 0 |
| Movement Speed | 20 | 0 | 20 |

## Combat package

The Abomination is always an **Elite**, **Large**, **Undead** melee unit.

It dual-wields Worn Axes so both its Rage Attack and Off Hand Attack have valid weapon slots.

Spells:

- Rage Attack — `f82db71a:npcrage1`
- Off Hand Attack — `f82db71a:zd3t6feq`
- Cleave — `7bbb4cb9:e0mooybr`
- Poison Cloud — `f82db71a:psncld01`

Poison Cloud is an instant Main Action applying a five-turn Nature DoT to up to five enemies. Cleave is the Abomination's Rage spender.

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
        creatureSize = "large",
        creatureType = "undead",
        id = "abom0001",
        mainHandWeapon = "f82db71a:stwaxe01",
        offHandWeapon = "f82db71a:stwaxe01",
        name = "Abomination",
        presets = {  },
        resistances = {  },
        resources = {
            {
                initialValue = 200,
                perLevelValue = 166.101695,
                resourceRef = "f82db71a:q2ktkztt",
            },
            {
                initialValue = 100,
                perLevelValue = 0,
                resourceRef = "f82db71a:e2tfklq7",
            },
        },
        spells = {
            "f82db71a:npcrage1",
            "f82db71a:zd3t6feq",
            "7bbb4cb9:e0mooybr",
            "f82db71a:psncld01",
        },
        stats = {
            {
                initialValue = 50,
                perLevelValue = 66.949153,
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
                initialValue = 70,
                perLevelValue = 11.525424,
                statRef = "f82db71a:u7b49vs9",
            },
            {
                initialValue = 0,
                perLevelValue = 0,
                statRef = "f82db71a:v2rs9cpy",
            },
            {
                initialValue = 0,
                perLevelValue = 0,
                statRef = "f82db71a:7t7xgzcx",
            },
            {
                initialValue = 5,
                perLevelValue = 0,
                statRef = "f82db71a:jslmczbi",
            },
            {
                initialValue = 0,
                perLevelValue = 0,
                statRef = "f82db71a:fercjhm5",
            },
            {
                initialValue = 0,
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
                initialValue = 20,
                perLevelValue = 0,
                statRef = "f82db71a:s1mt6jh9",
            },
        },
        tags = {  },
    },
}
```
