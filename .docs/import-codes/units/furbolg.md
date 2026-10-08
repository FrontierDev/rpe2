# Furbolg Unit Import Code

Standalone `RPE_DATASET_ENTRY_V1` import code for the base Furbolg and its Mauler, Shaman, Ursa Warrior and Elder presets in the Core dataset (`f82db71a`).

## Base Furbolg

The base Furbolg is a `minor`, `medium` Humanoid. It sits at the durable upper end of the Minor tier, with high Health, Armor and melee power but no innate resistances.

### Level-60 calibration

| Stat | Initial | Per level | Level 60 |
|---|---:|---:|---:|
| Health | 150 | 31.355932 | 2,000 |
| Mana | 0 | 0 | 0 |
| Rage | 0 | 0 | 0 |
| Armor | 25 | 19.915254 | 1,200 |
| Melee Attack Power | 50 | 5.084746 | 350 |
| Ranged Attack Power | 0 | 0 | 0 |
| Spell Power | 0 | 2.542373 | 150 |
| Healing Power | 0 | 2.542373 | 150 |
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
| Movement Speed | 30 | 0 | 30 |

## Presets

### Mauler — Normal

- 3,800 Health
- 2,800 Armor
- 650 Melee Attack Power
- 100 Rage
- +5 Melee Hit
- Worn Axe
- Rage Attack
- Cleave

### Shaman — Normal

- 3,000 Health
- 1,700 Armor
- 1,900 Mana
- 300 Spell Power
- 325 Healing Power
- +5 Spell Hit
- 8% Spell Crit
- Lightning Bolt
- Healing Wave

### Ursa Warrior — Normal

- 3,600 Health
- 2,500 Armor
- 650 Melee Attack Power
- 100 Rage
- +5 Melee Hit
- Worn Axe
- Rage Attack
- Concussive Blow

### Elder — Elite

- 9,500 Health
- 3,200 Armor
- 2,500 Mana
- 450 Spell Power
- 500 Healing Power
- +5 Spell Hit
- 10% Spell Crit
- +10 Magic Resistance
- Lightning Bolt
- Healing Wave
- Chain Heal
- Lightning Shield

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
        id = "furbolg01",
        name = "Furbolg",
        presets = {
            {
                name = "Mauler",
                challengeLevel = "normal",
                resourceModifiers = {
                    { resourceRef = "f82db71a:q2ktkztt", percentBonus = 90, flatBonus = 0 },
                    { resourceRef = "f82db71a:e2tfklq7", percentBonus = 0, flatBonus = 100 },
                },
                statModifiers = {
                    { statRef = "f82db71a:v42albuv", percentBonus = 133.333333, flatBonus = 0 },
                    { statRef = "f82db71a:u7b49vs9", percentBonus = 85.714286, flatBonus = 0 },
                    { statRef = "f82db71a:7t7xgzcx", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:hj6d4kvy", percentBonus = -100, flatBonus = 0 },
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
                name = "Shaman",
                challengeLevel = "normal",
                resourceModifiers = {
                    { resourceRef = "f82db71a:q2ktkztt", percentBonus = 50, flatBonus = 0 },
                    { resourceRef = "f82db71a:4c8mfm99", percentBonus = 0, flatBonus = 1900 },
                },
                statModifiers = {
                    { statRef = "f82db71a:v42albuv", percentBonus = 41.666667, flatBonus = 0 },
                    { statRef = "f82db71a:u7b49vs9", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:7t7xgzcx", percentBonus = 100, flatBonus = 0 },
                    { statRef = "f82db71a:hj6d4kvy", percentBonus = 116.666667, flatBonus = 0 },
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
                name = "Ursa Warrior",
                challengeLevel = "normal",
                resourceModifiers = {
                    { resourceRef = "f82db71a:q2ktkztt", percentBonus = 80, flatBonus = 0 },
                    { resourceRef = "f82db71a:e2tfklq7", percentBonus = 0, flatBonus = 100 },
                },
                statModifiers = {
                    { statRef = "f82db71a:v42albuv", percentBonus = 108.333333, flatBonus = 0 },
                    { statRef = "f82db71a:u7b49vs9", percentBonus = 85.714286, flatBonus = 0 },
                    { statRef = "f82db71a:7t7xgzcx", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:hj6d4kvy", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:wbj4zuf3", percentBonus = 0, flatBonus = 5 },
                },
                spells = {
                    "f82db71a:npcrage1",
                    "7bbb4cb9:cncblow1",
                },
                equipment = {
                    mainHandWeapon = "f82db71a:stwaxe01",
                },
            },
            {
                name = "Elder",
                challengeLevel = "elite",
                resourceModifiers = {
                    { resourceRef = "f82db71a:q2ktkztt", percentBonus = 375, flatBonus = 0 },
                    { resourceRef = "f82db71a:4c8mfm99", percentBonus = 0, flatBonus = 2500 },
                },
                statModifiers = {
                    { statRef = "f82db71a:v42albuv", percentBonus = 166.666667, flatBonus = 0 },
                    { statRef = "f82db71a:u7b49vs9", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:7t7xgzcx", percentBonus = 200, flatBonus = 0 },
                    { statRef = "f82db71a:hj6d4kvy", percentBonus = 233.333333, flatBonus = 0 },
                    { statRef = "f82db71a:v2g0tw0o", percentBonus = 0, flatBonus = 5 },
                    { statRef = "f82db71a:69hfqhne", percentBonus = 0, flatBonus = 5 },
                    { statRef = "f82db71a:zs1nbz13", percentBonus = 0, flatBonus = 10 },
                },
                spells = {
                    "c4a91e7d:shlbolt1",
                    "c4a91e7d:shhealwv",
                    "c4a91e7d:shchnhel",
                    "c4a91e7d:shlshldt",
                },
                equipment = {
                    mainHandWeapon = "f82db71a:stwstf01",
                },
            },
        },
        resistances = {  },
        resources = {
            {
                initialValue = 150,
                perLevelValue = 31.355932,
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
            { initialValue = 25, perLevelValue = 19.915254, statRef = "f82db71a:v42albuv" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:wbj4zuf3" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:dd88li4c" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:v2g0tw0o" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:tcn0s8kx" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:o6113cir" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:p8syz5ba" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:zs1nbz13" },
            { initialValue = 50, perLevelValue = 5.084746, statRef = "f82db71a:u7b49vs9" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:v2rs9cpy" },
            { initialValue = 0, perLevelValue = 2.542373, statRef = "f82db71a:7t7xgzcx" },
            { initialValue = 5, perLevelValue = 0, statRef = "f82db71a:jslmczbi" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:fercjhm5" },
            { initialValue = 5, perLevelValue = 0, statRef = "f82db71a:69hfqhne" },
            { initialValue = 0, perLevelValue = 2.542373, statRef = "f82db71a:hj6d4kvy" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:0w7c7p09" },
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
