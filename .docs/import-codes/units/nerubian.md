# Nerubian Unit Import Code

Standalone `RPE_DATASET_ENTRY_V1` import code for the base Nerubian unit and its Fiend, Stalker, Vizier and Lord presets in the Core dataset (`f82db71a`).

Import the Nerubian-specific abilities from `.docs/import-codes/spells/nerubian-abilities.md` before importing this Unit.

## Base Nerubian calibration

| Stat | Initial | Per level | Level 60 |
|---|---:|---:|---:|
| Health | 180 | 47.796610 | 3,000 |
| Mana | 100 | 23.728814 | 1,500 |
| Rage | 100 | 0 | 100 |
| Armor | 30 | 33.389831 | 2,000 |
| Melee Attack Power | 50 | 6.779661 | 450 |
| Ranged Attack Power | 50 | 6.779661 | 450 |
| Spell Power | 0 | 3.389831 | 200 |
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

The base Nerubian is a **Normal**, **Large**, **Undead** chassis. The presets define the actual combat role.

## Variants

### Fiend — Normal

Ranged Shadow attacker.

- Natural Attack
- Crypt Scarabs
- Level-60 target: 3,000 Health, 2,000 Armor, 250 Spell Power
- Mana retained; Rage disabled

### Stalker — Normal

Fast melee poison attacker.

- Natural Attack
- Venomous Strike
- Level-60 target: 3,200 Health, 1,800 Armor, 550 MAP
- Mana and Rage disabled
- +5 Melee Hit, +3 Melee Crit, +5 Dodge, +5 Movement Speed

### Vizier — Elite

Shadow/debuff caster.

- Natural Attack
- Shadow Bolt
- Curse of Tongues
- Curse of Shadows
- Drain Mana
- Shadow Nova
- Level-60 target: 8,500 Health, 3,000 Armor, 450 Spell Power, 2,500 Mana
- Rage disabled
- +5 Spell Hit, +3 Spell Crit, +10 Resource Regeneration

### Lord — Elite

Heavy melee/control Nerubian.

- Worn Axe main hand
- Rage Attack
- Cleave
- Colossus Smash
- Battle Shout
- Demoralizing Shout
- Pummel
- Level-60 target: 11,000 Health, 4,500 Armor, 750 MAP
- Mana disabled
- +5 Melee Hit, +5 Parry

No Overlord preset is included.

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
        challengeLevel = "normal",
        creatureSize = "large",
        creatureType = "undead",
        id = "nerub001",
        name = "Nerubian",
        presets = {
            {
                name = "Fiend",
                challengeLevel = "normal",
                resourceModifiers = {
                    { resourceRef = "f82db71a:e2tfklq7", percentBonus = -100, flatBonus = 0 },
                },
                statModifiers = {
                    { statRef = "f82db71a:u7b49vs9", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:v2rs9cpy", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:7t7xgzcx", percentBonus = 25, flatBonus = 0 },
                    { statRef = "f82db71a:v2g0tw0o", percentBonus = 0, flatBonus = 5 },
                },
                spells = {
                    "f82db71a:natatk01",
                    "f82db71a:nrbscrb1",
                },
                equipment = {  },
            },
            {
                name = "Stalker",
                challengeLevel = "normal",
                resourceModifiers = {
                    { resourceRef = "f82db71a:q2ktkztt", percentBonus = 6.666667, flatBonus = 0 },
                    { resourceRef = "f82db71a:4c8mfm99", percentBonus = -100, flatBonus = 0 },
                    { resourceRef = "f82db71a:e2tfklq7", percentBonus = -100, flatBonus = 0 },
                },
                statModifiers = {
                    { statRef = "f82db71a:v42albuv", percentBonus = -10, flatBonus = 0 },
                    { statRef = "f82db71a:u7b49vs9", percentBonus = 22.222222, flatBonus = 0 },
                    { statRef = "f82db71a:v2rs9cpy", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:7t7xgzcx", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:wbj4zuf3", percentBonus = 0, flatBonus = 5 },
                    { statRef = "f82db71a:jslmczbi", percentBonus = 0, flatBonus = 3 },
                    { statRef = "f82db71a:o6113cir", percentBonus = 0, flatBonus = 5 },
                    { statRef = "f82db71a:s1mt6jh9", percentBonus = 0, flatBonus = 5 },
                },
                spells = {
                    "f82db71a:natatk01",
                    "f82db71a:nrbven01",
                },
                equipment = {  },
            },
            {
                name = "Vizier",
                challengeLevel = "elite",
                resourceModifiers = {
                    { resourceRef = "f82db71a:q2ktkztt", percentBonus = 183.333333, flatBonus = 0 },
                    { resourceRef = "f82db71a:4c8mfm99", percentBonus = 66.666667, flatBonus = 0 },
                    { resourceRef = "f82db71a:e2tfklq7", percentBonus = -100, flatBonus = 0 },
                },
                statModifiers = {
                    { statRef = "f82db71a:v42albuv", percentBonus = 50, flatBonus = 0 },
                    { statRef = "f82db71a:u7b49vs9", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:v2rs9cpy", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:7t7xgzcx", percentBonus = 125, flatBonus = 0 },
                    { statRef = "f82db71a:v2g0tw0o", percentBonus = 0, flatBonus = 5 },
                    { statRef = "f82db71a:69hfqhne", percentBonus = 0, flatBonus = 3 },
                    { statRef = "f82db71a:rgnrtg01", percentBonus = 0, flatBonus = 10 },
                },
                spells = {
                    "f82db71a:natatk01",
                    "e8f3b2c6:wlsbolt1",
                    "e8f3b2c6:wlctngs1",
                    "e8f3b2c6:wlcshads",
                    "e8f3b2c6:wldrman1",
                    "f82db71a:nrbnova1",
                },
                equipment = {  },
            },
            {
                name = "Lord",
                challengeLevel = "elite",
                resourceModifiers = {
                    { resourceRef = "f82db71a:q2ktkztt", percentBonus = 266.666667, flatBonus = 0 },
                    { resourceRef = "f82db71a:4c8mfm99", percentBonus = -100, flatBonus = 0 },
                },
                statModifiers = {
                    { statRef = "f82db71a:v42albuv", percentBonus = 125, flatBonus = 0 },
                    { statRef = "f82db71a:u7b49vs9", percentBonus = 66.666667, flatBonus = 0 },
                    { statRef = "f82db71a:v2rs9cpy", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:7t7xgzcx", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:wbj4zuf3", percentBonus = 0, flatBonus = 5 },
                    { statRef = "f82db71a:tcn0s8kx", percentBonus = 0, flatBonus = 5 },
                },
                spells = {
                    "f82db71a:npcrage1",
                    "7bbb4cb9:e0mooybr",
                    "7bbb4cb9:colsmash",
                    "7bbb4cb9:9gh28pe5",
                    "7bbb4cb9:demoshot",
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
                initialValue = 180,
                perLevelValue = 47.796610,
                resourceRef = "f82db71a:q2ktkztt",
            },
            {
                initialValue = 100,
                perLevelValue = 23.728814,
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
            { initialValue = 30, perLevelValue = 33.389831, statRef = "f82db71a:v42albuv" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:wbj4zuf3" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:dd88li4c" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:v2g0tw0o" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:tcn0s8kx" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:o6113cir" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:p8syz5ba" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:zs1nbz13" },
            { initialValue = 50, perLevelValue = 6.779661, statRef = "f82db71a:u7b49vs9" },
            { initialValue = 50, perLevelValue = 6.779661, statRef = "f82db71a:v2rs9cpy" },
            { initialValue = 0, perLevelValue = 3.389831, statRef = "f82db71a:7t7xgzcx" },
            { initialValue = 5, perLevelValue = 0, statRef = "f82db71a:jslmczbi" },
            { initialValue = 5, perLevelValue = 0, statRef = "f82db71a:fercjhm5" },
            { initialValue = 5, perLevelValue = 0, statRef = "f82db71a:69hfqhne" },
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
