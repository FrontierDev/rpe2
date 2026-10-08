# Trogg Unit Import Code

Standalone `RPE_DATASET_ENTRY_V1` import code for the base Trogg and its Stonebreaker, Brawler, Geomancer, Seer and Chieftain presets in the Core dataset (`f82db71a`).

Import the Core Puncture Armor entries from `.docs/import-codes/spells/kobold-abilities.md` before importing this Unit.

## Base Trogg

The base Trogg is a `minor`, `medium` Humanoid. It is tougher and more physically powerful than most minor Humanoids, but has no innate resistances.

### Level-60 calibration

| Stat | Initial | Per level | Level 60 |
|---|---:|---:|---:|
| Health | 140 | 29.830508 | 1,900 |
| Mana | 0 | 0 | 0 |
| Rage | 0 | 0 | 0 |
| Armor | 25 | 18.220339 | 1,100 |
| Melee Attack Power | 50 | 6.355932 | 425 |
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

### Stonebreaker — Normal

- 3,400 Health
- 2,500 Armor
- 575 Melee Attack Power
- +5 Melee Hit
- Worn Mace
- Main Hand Attack
- Puncture Armor

### Brawler — Normal

- 3,200 Health
- 2,000 Armor
- 600 Melee Attack Power
- 100 Rage
- +5 Melee Hit
- Worn Mace
- Rage Attack
- Concussive Blow

### Geomancer — Normal

- 2,700 Health
- 1,300 Armor
- 1,800 Mana
- 275 Spell Power
- +5 Spell Hit
- 8% Spell Crit
- Lightning Bolt
- Earth Shock

### Seer — Normal

- 2,600 Health
- 1,200 Armor
- 1,900 Mana
- 250 Spell Power
- 325 Healing Power
- +5 Spell Hit
- 8% Spell Crit
- Lightning Bolt
- Healing Wave

### Chieftain — Elite

- 10,500 Health
- 4,500 Armor
- 775 Melee Attack Power
- 100 Rage
- +5 Melee Hit
- +5 Parry
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
        id = "trogg001",
        name = "Trogg",
        presets = {
            {
                name = "Stonebreaker",
                challengeLevel = "normal",
                resourceModifiers = {
                    { resourceRef = "f82db71a:q2ktkztt", percentBonus = 78.947368, flatBonus = 0 },
                },
                statModifiers = {
                    { statRef = "f82db71a:v42albuv", percentBonus = 127.272727, flatBonus = 0 },
                    { statRef = "f82db71a:u7b49vs9", percentBonus = 35.294118, flatBonus = 0 },
                    { statRef = "f82db71a:7t7xgzcx", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:hj6d4kvy", percentBonus = -100, flatBonus = 0 },
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
                name = "Brawler",
                challengeLevel = "normal",
                resourceModifiers = {
                    { resourceRef = "f82db71a:q2ktkztt", percentBonus = 68.421053, flatBonus = 0 },
                    { resourceRef = "f82db71a:e2tfklq7", percentBonus = 0, flatBonus = 100 },
                },
                statModifiers = {
                    { statRef = "f82db71a:v42albuv", percentBonus = 81.818182, flatBonus = 0 },
                    { statRef = "f82db71a:u7b49vs9", percentBonus = 41.176471, flatBonus = 0 },
                    { statRef = "f82db71a:7t7xgzcx", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:hj6d4kvy", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:wbj4zuf3", percentBonus = 0, flatBonus = 5 },
                },
                spells = {
                    "f82db71a:npcrage1",
                    "7bbb4cb9:cncblow1",
                },
                equipment = {
                    mainHandWeapon = "f82db71a:stwmac01",
                },
            },
            {
                name = "Geomancer",
                challengeLevel = "normal",
                resourceModifiers = {
                    { resourceRef = "f82db71a:q2ktkztt", percentBonus = 42.105263, flatBonus = 0 },
                    { resourceRef = "f82db71a:4c8mfm99", percentBonus = 0, flatBonus = 1800 },
                },
                statModifiers = {
                    { statRef = "f82db71a:v42albuv", percentBonus = 18.181818, flatBonus = 0 },
                    { statRef = "f82db71a:u7b49vs9", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:7t7xgzcx", percentBonus = 83.333333, flatBonus = 0 },
                    { statRef = "f82db71a:hj6d4kvy", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:v2g0tw0o", percentBonus = 0, flatBonus = 5 },
                    { statRef = "f82db71a:69hfqhne", percentBonus = 0, flatBonus = 3 },
                },
                spells = {
                    "c4a91e7d:shlbolt1",
                    "c4a91e7d:sherthsk",
                },
                equipment = {
                    mainHandWeapon = "f82db71a:stwstf01",
                },
            },
            {
                name = "Seer",
                challengeLevel = "normal",
                resourceModifiers = {
                    { resourceRef = "f82db71a:q2ktkztt", percentBonus = 36.842105, flatBonus = 0 },
                    { resourceRef = "f82db71a:4c8mfm99", percentBonus = 0, flatBonus = 1900 },
                },
                statModifiers = {
                    { statRef = "f82db71a:v42albuv", percentBonus = 9.090909, flatBonus = 0 },
                    { statRef = "f82db71a:u7b49vs9", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:7t7xgzcx", percentBonus = 66.666667, flatBonus = 0 },
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
                name = "Chieftain",
                challengeLevel = "elite",
                resourceModifiers = {
                    { resourceRef = "f82db71a:q2ktkztt", percentBonus = 452.631579, flatBonus = 0 },
                    { resourceRef = "f82db71a:e2tfklq7", percentBonus = 0, flatBonus = 100 },
                },
                statModifiers = {
                    { statRef = "f82db71a:v42albuv", percentBonus = 309.090909, flatBonus = 0 },
                    { statRef = "f82db71a:u7b49vs9", percentBonus = 82.352941, flatBonus = 0 },
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
                initialValue = 140,
                perLevelValue = 29.830508,
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
            { initialValue = 25, perLevelValue = 18.220339, statRef = "f82db71a:v42albuv" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:wbj4zuf3" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:dd88li4c" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:v2g0tw0o" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:tcn0s8kx" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:o6113cir" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:p8syz5ba" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:zs1nbz13" },
            { initialValue = 50, perLevelValue = 6.355932, statRef = "f82db71a:u7b49vs9" },
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
