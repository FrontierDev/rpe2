# Ghoul Unit Import Code

Standalone `RPE_DATASET_ENTRY_V1` import code for the base Ghoul unit and its three Normal-challenge variants in the Core dataset (`f82db71a`).

Import the supporting Ghoul Auras and Spells from `.docs/import-codes/spells/ghoul-abilities.md` before importing this Unit.

## Base Ghoul calibration

| Stat | Initial | Per level | Level 60 |
|---|---:|---:|---:|
| Health | 130 | 28.305085 | 1,800 |
| Armor | 20 | 14.915254 | 900 |
| Melee Attack Power | 45 | 5.169492 | 350 |
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
| Dodge Chance | 3 | 0 | 3 |
| Block Chance | 0 | 0 | 0 |
| Magic Resistance | 0 | 0 | 0 |
| Fire Resistance | 0 | 0 | 0 |
| Frost Resistance | 0 | 0 | 0 |
| Nature Resistance | 0 | 0 | 0 |
| Arcane Resistance | 0 | 0 | 0 |
| Shadow Resistance | 0 | 0 | 0 |
| Holy Resistance | 0 | 0 | 0 |
| Resource Regeneration | 0 | 0 | 0 |
| Movement Speed | 35 | 0 | 35 |

The base Ghoul is a `minor`, `medium` Undead with Health only and the Core Natural Attack (`f82db71a:natatk01`).

## Normal variants

All three variants override the challenge level to `normal` and use the same baseline Normal-tier stat adjustment:

- Health: +50% -> 2,700 at level 60
- Armor: +66.666667% -> 1,500 at level 60
- Melee Attack Power: +28.571429% -> 450 at level 60
- Dodge Chance remains 3%
- Movement Speed remains 35

Each variant retains Natural Attack as its Free Action and gains one Main Action ability.

### Plaguebearer

- **Diseased Bite** — Main Action, Shadow melee ability.
- Direct damage budget: `85 + 0.2975 × MAP`.
- Applies **Diseased Bite** for 20 turns.
- The debuff reduces Strength and Agility by 40%.
- No spell cooldown; re-use refreshes the non-stacking debuff.

### Leaper

- **Leap** — Main Action, Shadow melee ability.
- Four-turn cooldown.
- Direct damage budget: `123.25 + 0.431375 × MAP`.
- Applies a 1-turn stun using the same control contract as Hammer of Justice: no casting, no movement, and attacks against the target automatically hit.
- The 4-turn cooldown prevents repeated turn-by-turn stun locking.

### Ravager

- **Thrash** — Main Action, Physical melee ability.
- Direct damage budget: `85 + 0.2975 × MAP`.
- Applies a 3-turn heavy bleed.
- Bleed per turn: `28.1667 + 0.15 × MAP` Physical damage.
- The bleed refreshes rather than stacking.

# Ghoul Unit

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
        id = "ghoul001",
        name = "Ghoul",
        presets = {
            {
                name = "Plaguebearer",
                challengeLevel = "normal",
                resourceModifiers = {
                    {
                        resourceRef = "f82db71a:q2ktkztt",
                        percentBonus = 50,
                        flatBonus = 0,
                    },
                },
                statModifiers = {
                    {
                        statRef = "f82db71a:v42albuv",
                        percentBonus = 66.666667,
                        flatBonus = 0,
                    },
                    {
                        statRef = "f82db71a:u7b49vs9",
                        percentBonus = 28.571429,
                        flatBonus = 0,
                    },
                },
                spells = {
                    "f82db71a:natatk01",
                    "f82db71a:ghdisbit",
                },
                equipment = {  },
            },
            {
                name = "Leaper",
                challengeLevel = "normal",
                resourceModifiers = {
                    {
                        resourceRef = "f82db71a:q2ktkztt",
                        percentBonus = 50,
                        flatBonus = 0,
                    },
                },
                statModifiers = {
                    {
                        statRef = "f82db71a:v42albuv",
                        percentBonus = 66.666667,
                        flatBonus = 0,
                    },
                    {
                        statRef = "f82db71a:u7b49vs9",
                        percentBonus = 28.571429,
                        flatBonus = 0,
                    },
                },
                spells = {
                    "f82db71a:natatk01",
                    "f82db71a:ghleap01",
                },
                equipment = {  },
            },
            {
                name = "Ravager",
                challengeLevel = "normal",
                resourceModifiers = {
                    {
                        resourceRef = "f82db71a:q2ktkztt",
                        percentBonus = 50,
                        flatBonus = 0,
                    },
                },
                statModifiers = {
                    {
                        statRef = "f82db71a:v42albuv",
                        percentBonus = 66.666667,
                        flatBonus = 0,
                    },
                    {
                        statRef = "f82db71a:u7b49vs9",
                        percentBonus = 28.571429,
                        flatBonus = 0,
                    },
                },
                spells = {
                    "f82db71a:natatk01",
                    "f82db71a:ghthrash",
                },
                equipment = {  },
            },
        },
        resistances = {  },
        resources = {
            {
                initialValue = 130,
                perLevelValue = 28.305085,
                resourceRef = "f82db71a:q2ktkztt",
            },
        },
        spells = {
            "f82db71a:natatk01",
        },
        stats = {
            {
                initialValue = 20,
                perLevelValue = 14.915254,
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
                initialValue = 3,
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
                perLevelValue = 5.169492,
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
                initialValue = 35,
                perLevelValue = 0,
                statRef = "f82db71a:s1mt6jh9",
            },
        },
        tags = {  },
    },
}
```
