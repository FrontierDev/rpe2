# Naga Unit Import Code

Standalone `RPE_DATASET_ENTRY_V1` import code for the base Naga and its Tidehunter, Priestess, Enchantress, Siren, Sea Witch and Myrmidon presets in the Core dataset (`f82db71a`).

The Tidehunter uses **Spear Thrust** (`f82db71a:murspear1`), so import that ability from `.docs/import-codes/spells/murloc-abilities.md` first if it is not already present in the target Core dataset.

## Base Naga

The base Naga is a `minor`, `medium` Humanoid with moderate durability and a small innate Nature Resistance.

### Level-60 calibration

| Stat | Initial | Per level | Level 60 |
|---|---:|---:|---:|
| Health | 130 | 28.305085 | 1,800 |
| Mana | 0 | 0 | 0 |
| Rage | 0 | 0 | 0 |
| Armor | 20 | 16.610169 | 1,000 |
| Melee Attack Power | 40 | 5.677966 | 375 |
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
| Nature Resistance | 10 | 0 | 10 |
| Resource Regeneration | 0 | 0 | 0 |
| Movement Speed | 30 | 0 | 30 |

## Presets

### Tidehunter — Normal

- 3,000 Health
- 1,900 Armor
- 525 Melee Attack Power
- +5 Melee Hit
- Worn Spear
- Main Hand Attack
- Spear Thrust

### Priestess — Normal

- 2,500 Health
- 1,000 Armor
- 1,900 Mana
- 250 Spell Power
- 325 Healing Power
- +5 Spell Hit
- 8% Spell Crit
- Bent Staff
- Smite
- Flash Heal
- Shadow Word: Pain

### Enchantress — Normal

- 2,500 Health
- 900 Armor
- 2,000 Mana
- 325 Spell Power
- +5 Spell Hit
- 8% Spell Crit
- Worn Wand
- Arcane Blast
- Arcane Explosion
- Polymorph

### Siren — Normal

- 2,600 Health
- 1,000 Armor
- 1,900 Mana
- 300 Spell Power
- +5 Spell Hit
- 8% Spell Crit
- Worn Wand
- Frostbolt
- Frost Nova
- Ice Lance

### Sea Witch — Elite

- 9,000 Health
- 3,000 Armor
- 2,600 Mana
- 475 Spell Power
- +5 Spell Hit
- 10% Spell Crit
- +10 Magic Resistance
- 20 Nature Resistance
- Bent Staff
- Chain Lightning
- Earth Shock
- Hurricane
- Lightning Shield

### Myrmidon — Elite

- 11,000 Health
- 5,000 Armor
- 825 Melee Attack Power
- 100 Rage
- +5 Melee Hit
- +5 Parry
- Worn Spear
- Rage Attack
- Slam
- Cleave
- Colossus Smash
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
        id = "naga001",
        name = "Naga",
        presets = {
            {
                name = "Tidehunter",
                challengeLevel = "normal",
                resourceModifiers = {
                    { resourceRef = "f82db71a:q2ktkztt", percentBonus = 66.666667, flatBonus = 0 },
                },
                statModifiers = {
                    { statRef = "f82db71a:v42albuv", percentBonus = 90, flatBonus = 0 },
                    { statRef = "f82db71a:u7b49vs9", percentBonus = 40, flatBonus = 0 },
                    { statRef = "f82db71a:7t7xgzcx", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:hj6d4kvy", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:wbj4zuf3", percentBonus = 0, flatBonus = 5 },
                },
                spells = {
                    "f82db71a:z36xzk0w",
                    "f82db71a:murspear1",
                },
                equipment = {
                    mainHandWeapon = "f82db71a:stwpol01",
                },
            },
            {
                name = "Priestess",
                challengeLevel = "normal",
                resourceModifiers = {
                    { resourceRef = "f82db71a:q2ktkztt", percentBonus = 38.888889, flatBonus = 0 },
                    { resourceRef = "f82db71a:4c8mfm99", percentBonus = 0, flatBonus = 1900 },
                },
                statModifiers = {
                    { statRef = "f82db71a:u7b49vs9", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:7t7xgzcx", percentBonus = 66.666667, flatBonus = 0 },
                    { statRef = "f82db71a:hj6d4kvy", percentBonus = 116.666667, flatBonus = 0 },
                    { statRef = "f82db71a:v2g0tw0o", percentBonus = 0, flatBonus = 5 },
                    { statRef = "f82db71a:69hfqhne", percentBonus = 0, flatBonus = 3 },
                },
                spells = {
                    "1c1038a7:rm9rekvj",
                    "1c1038a7:5yht8j0f",
                    "1c1038a7:drza38ax",
                },
                equipment = {
                    mainHandWeapon = "f82db71a:stwstf01",
                },
            },
            {
                name = "Enchantress",
                challengeLevel = "normal",
                resourceModifiers = {
                    { resourceRef = "f82db71a:q2ktkztt", percentBonus = 38.888889, flatBonus = 0 },
                    { resourceRef = "f82db71a:4c8mfm99", percentBonus = 0, flatBonus = 2000 },
                },
                statModifiers = {
                    { statRef = "f82db71a:v42albuv", percentBonus = -10, flatBonus = 0 },
                    { statRef = "f82db71a:u7b49vs9", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:7t7xgzcx", percentBonus = 116.666667, flatBonus = 0 },
                    { statRef = "f82db71a:hj6d4kvy", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:v2g0tw0o", percentBonus = 0, flatBonus = 5 },
                    { statRef = "f82db71a:69hfqhne", percentBonus = 0, flatBonus = 3 },
                },
                spells = {
                    "d7c874c4:n6jbep9e",
                    "d7c874c4:1s5lq169",
                    "d7c874c4:polymr01",
                },
                equipment = {
                    rangedWeapon = "f82db71a:stwwnd01",
                },
            },
            {
                name = "Siren",
                challengeLevel = "normal",
                resourceModifiers = {
                    { resourceRef = "f82db71a:q2ktkztt", percentBonus = 44.444444, flatBonus = 0 },
                    { resourceRef = "f82db71a:4c8mfm99", percentBonus = 0, flatBonus = 1900 },
                },
                statModifiers = {
                    { statRef = "f82db71a:u7b49vs9", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:7t7xgzcx", percentBonus = 100, flatBonus = 0 },
                    { statRef = "f82db71a:hj6d4kvy", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:v2g0tw0o", percentBonus = 0, flatBonus = 5 },
                    { statRef = "f82db71a:69hfqhne", percentBonus = 0, flatBonus = 3 },
                },
                spells = {
                    "d7c874c4:lywroiqu",
                    "d7c874c4:7ha8pdoy",
                    "d7c874c4:4yxpy77f",
                },
                equipment = {
                    rangedWeapon = "f82db71a:stwwnd01",
                },
            },
            {
                name = "Sea Witch",
                challengeLevel = "elite",
                resourceModifiers = {
                    { resourceRef = "f82db71a:q2ktkztt", percentBonus = 400, flatBonus = 0 },
                    { resourceRef = "f82db71a:4c8mfm99", percentBonus = 0, flatBonus = 2600 },
                },
                statModifiers = {
                    { statRef = "f82db71a:v42albuv", percentBonus = 200, flatBonus = 0 },
                    { statRef = "f82db71a:u7b49vs9", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:7t7xgzcx", percentBonus = 216.666667, flatBonus = 0 },
                    { statRef = "f82db71a:hj6d4kvy", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:v2g0tw0o", percentBonus = 0, flatBonus = 5 },
                    { statRef = "f82db71a:69hfqhne", percentBonus = 0, flatBonus = 5 },
                    { statRef = "f82db71a:zs1nbz13", percentBonus = 0, flatBonus = 10 },
                    { statRef = "f82db71a:pg0ytacb", percentBonus = 0, flatBonus = 10 },
                },
                spells = {
                    "c4a91e7d:shchnltn",
                    "c4a91e7d:sherthsk",
                    "6e4d2a91:drhurr01",
                    "c4a91e7d:shlshldt",
                },
                equipment = {
                    mainHandWeapon = "f82db71a:stwstf01",
                },
            },
            {
                name = "Myrmidon",
                challengeLevel = "elite",
                resourceModifiers = {
                    { resourceRef = "f82db71a:q2ktkztt", percentBonus = 511.111111, flatBonus = 0 },
                    { resourceRef = "f82db71a:e2tfklq7", percentBonus = 0, flatBonus = 100 },
                },
                statModifiers = {
                    { statRef = "f82db71a:v42albuv", percentBonus = 400, flatBonus = 0 },
                    { statRef = "f82db71a:u7b49vs9", percentBonus = 120, flatBonus = 0 },
                    { statRef = "f82db71a:7t7xgzcx", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:hj6d4kvy", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:wbj4zuf3", percentBonus = 0, flatBonus = 5 },
                    { statRef = "f82db71a:tcn0s8kx", percentBonus = 0, flatBonus = 5 },
                },
                spells = {
                    "f82db71a:npcrage1",
                    "7bbb4cb9:68qm26aq",
                    "7bbb4cb9:e0mooybr",
                    "7bbb4cb9:colsmash",
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
            { initialValue = 40, perLevelValue = 5.677966, statRef = "f82db71a:u7b49vs9" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:v2rs9cpy" },
            { initialValue = 0, perLevelValue = 2.542373, statRef = "f82db71a:7t7xgzcx" },
            { initialValue = 5, perLevelValue = 0, statRef = "f82db71a:jslmczbi" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:fercjhm5" },
            { initialValue = 5, perLevelValue = 0, statRef = "f82db71a:69hfqhne" },
            { initialValue = 0, perLevelValue = 2.542373, statRef = "f82db71a:hj6d4kvy" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:0w7c7p09" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:jjn0my8k" },
            { initialValue = 10, perLevelValue = 0, statRef = "f82db71a:pg0ytacb" },
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
