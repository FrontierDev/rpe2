# Ogre Unit Import Code

Standalone `RPE_DATASET_ENTRY_V1` import code for the base Ogre and its Bruiser, Warlock, Magus and Enforcer presets in the Core dataset (`f82db71a`).

The **Magus** uses the existing NPC-only Fire Shield from `.docs/import-codes/spells/kobold-abilities.md`; import those Fire Shield entries before importing this Unit.

## Base Ogre

The base Ogre is a `minor`, `large` Humanoid. It sits at the upper edge of the Minor tier for raw durability and melee power, with slow movement and no innate resistances.

### Level-60 calibration

| Stat | Initial | Per level | Level 60 |
|---|---:|---:|---:|
| Health | 160 | 31.186441 | 2,000 |
| Mana | 0 | 0 | 0 |
| Rage | 0 | 0 | 0 |
| Armor | 30 | 19.830508 | 1,200 |
| Melee Attack Power | 55 | 5.000000 | 350 |
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
| Dodge Chance | 0 | 0 | 0 |
| Block Chance | 0 | 0 | 0 |
| Magic Resistance | 0 | 0 | 0 |
| Resource Regeneration | 0 | 0 | 0 |
| Movement Speed | 25 | 0 | 25 |

## Presets

### Bruiser — Normal

- 3,800 Health
- 2,800 Armor
- 650 Melee Attack Power
- 100 Rage
- +5 Melee Hit
- Worn Axe
- Rage Attack
- Cleave

### Warlock — Normal

- 3,200 Health
- 1,500 Armor
- 1,900 Mana
- 300 Spell Power
- +5 Spell Hit
- 8% Spell Crit
- Bent Staff
- Shadow Bolt
- Corruption

### Magus — Elite

- 9,000 Health
- 3,000 Armor
- 2,500 Mana
- 500 Spell Power
- +5 Spell Hit
- 10% Spell Crit
- +10 Magic Resistance
- Worn Wand
- Fireball
- Fire Shield
- Arcane Explosion
- Ice Armor

### Enforcer — Elite

- 12,000 Health
- 5,000 Armor
- 850 Melee Attack Power
- 100 Rage
- +5 Melee Hit
- +5 Parry
- Worn Greatsword
- Rage Attack
- Concussive Blow
- Slam
- Colossus Smash

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
        id = "ogre001",
        name = "Ogre",
        presets = {
            {
                name = "Bruiser",
                challengeLevel = "normal",
                resourceModifiers = {
                    { resourceRef = "f82db71a:q2ktkztt", percentBonus = 90, flatBonus = 0 },
                    { resourceRef = "f82db71a:e2tfklq7", percentBonus = 0, flatBonus = 100 },
                },
                statModifiers = {
                    { statRef = "f82db71a:v42albuv", percentBonus = 133.333333, flatBonus = 0 },
                    { statRef = "f82db71a:u7b49vs9", percentBonus = 85.714286, flatBonus = 0 },
                    { statRef = "f82db71a:7t7xgzcx", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:wbj4zuf3", percentBonus = 0, flatBonus = 5 },
                },
                spells = {
                    "f82db71a:npcrage1",
                    "7bbb4cb9:e0mooybr",
                },
                equipment = {
                    mainHandWeapon = "f82db71a:stwaxe01",
                },
            },
            {
                name = "Warlock",
                challengeLevel = "normal",
                resourceModifiers = {
                    { resourceRef = "f82db71a:q2ktkztt", percentBonus = 60, flatBonus = 0 },
                    { resourceRef = "f82db71a:4c8mfm99", percentBonus = 0, flatBonus = 1900 },
                },
                statModifiers = {
                    { statRef = "f82db71a:v42albuv", percentBonus = 25, flatBonus = 0 },
                    { statRef = "f82db71a:u7b49vs9", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:7t7xgzcx", percentBonus = 100, flatBonus = 0 },
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
                name = "Magus",
                challengeLevel = "elite",
                resourceModifiers = {
                    { resourceRef = "f82db71a:q2ktkztt", percentBonus = 350, flatBonus = 0 },
                    { resourceRef = "f82db71a:4c8mfm99", percentBonus = 0, flatBonus = 2500 },
                },
                statModifiers = {
                    { statRef = "f82db71a:v42albuv", percentBonus = 150, flatBonus = 0 },
                    { statRef = "f82db71a:u7b49vs9", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:7t7xgzcx", percentBonus = 233.333333, flatBonus = 0 },
                    { statRef = "f82db71a:v2g0tw0o", percentBonus = 0, flatBonus = 5 },
                    { statRef = "f82db71a:69hfqhne", percentBonus = 0, flatBonus = 5 },
                    { statRef = "f82db71a:zs1nbz13", percentBonus = 0, flatBonus = 10 },
                },
                spells = {
                    "d7c874c4:68dy7na1",
                    "f82db71a:kobfire1",
                    "d7c874c4:1s5lq169",
                    "d7c874c4:icearm01",
                },
                equipment = {
                    rangedWeapon = "f82db71a:stwwnd01",
                },
            },
            {
                name = "Enforcer",
                challengeLevel = "elite",
                resourceModifiers = {
                    { resourceRef = "f82db71a:q2ktkztt", percentBonus = 500, flatBonus = 0 },
                    { resourceRef = "f82db71a:e2tfklq7", percentBonus = 0, flatBonus = 100 },
                },
                statModifiers = {
                    { statRef = "f82db71a:v42albuv", percentBonus = 316.666667, flatBonus = 0 },
                    { statRef = "f82db71a:u7b49vs9", percentBonus = 142.857143, flatBonus = 0 },
                    { statRef = "f82db71a:7t7xgzcx", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:wbj4zuf3", percentBonus = 0, flatBonus = 5 },
                    { statRef = "f82db71a:tcn0s8kx", percentBonus = 0, flatBonus = 5 },
                },
                spells = {
                    "f82db71a:npcrage1",
                    "7bbb4cb9:cncblow1",
                    "7bbb4cb9:68qm26aq",
                    "7bbb4cb9:colsmash",
                },
                equipment = {
                    mainHandWeapon = "f82db71a:stw2sw01",
                },
            },
        },
        resistances = {  },
        resources = {
            {
                initialValue = 160,
                perLevelValue = 31.186441,
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
            { initialValue = 30, perLevelValue = 19.830508, statRef = "f82db71a:v42albuv" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:wbj4zuf3" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:dd88li4c" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:v2g0tw0o" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:tcn0s8kx" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:o6113cir" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:p8syz5ba" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:zs1nbz13" },
            { initialValue = 55, perLevelValue = 5, statRef = "f82db71a:u7b49vs9" },
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
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:itpo751d" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:hlyrsstn" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:rgnrtg01" },
            { initialValue = 25, perLevelValue = 0, statRef = "f82db71a:s1mt6jh9" },
        },
        tags = {  },
    },
}
```
