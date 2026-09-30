# Human Unit Import Code

Standalone `RPE_DATASET_ENTRY_V1` import code for the base Human unit in the Core dataset (`f82db71a`).

## Level-60 calibration

| Stat | Base amount | Per level | Level 60 |
|---|---:|---:|---:|
| Health | 208 | 43.084746 | 2,750 |
| Armor | 25 | 33.474576 | 2,000 |
| Melee Attack Power | 65 | 9.067797 | 600 |
| Ranged Attack Power | 65 | 9.067797 | 600 |
| Spell Power | 0 | 3.389831 | 200 |
| Healing Power | 0 | 4.237288 | 250 |

The base unit is authored as a `normal` Humanoid. It retains the Worn Shortsword and the Core Main Hand Attack / Shoot spells.

## Militant variant

**Archetype:** Warrior  
**Challenge level:** Normal  
**Equipment:** one-handed sword and shield  
**Spells:** Rage Attack, Multiattack, Rend, Shield Bash

The Human base resource list includes Rage, Mana and Energy so presets can support Warrior-, caster-, Hunter- and Rogue-style resource costs without relying on an external stat profile. Unused preset resources are reduced to a zero-sized pool through explicit resource modifiers.

## Additional role variants

| Variant | Archetype | Challenge | Equipment | Primary stat emphasis |
|---|---|---|---|---|
| Cleric | Priest | Normal | Bent Staff | Healing Power, Spell Power, Holy resistance |
| Pyromancer | Mage | Normal | Worn Wand | Spell Power, Spell Hit/Crit, Fire resistance |
| Arcanist | Mage | Normal | Bent Staff | Spell Power, Spell Hit, Arcane/Magic resistance |
| Cryomancer | Mage | Normal | Worn Wand | Spell Power, Spell Hit, Frost/Magic resistance |
| Sharpshooter | Hunter | Normal | Worn Bow | Ranged Attack Power, Ranged Hit/Crit |
| Assassin | Rogue | Normal | Dual Worn Daggers | Melee Attack Power, Melee Hit/Crit, Dodge |
| Captain | Paladin | Elite | Worn Shortsword + Worn Shield | Health, Armor, mixed damage/healing, Block |

All stat and resource modifiers below are authored directly on each preset. No preset references or reuses a pre-existing stat profile.

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
        creatureSize = "medium",
        creatureType = "humanoid",
        id = "7i40epa5",
        mainHandWeapon = "f82db71a:stwswd01",
        name = "Human",
        presets = {
            {
                name = "Militant",
                challengeLevel = "normal",
                resourceModifiers = {
                    { resourceRef = "f82db71a:4c8mfm99", percentBonus = -100, flatBonus = 0 },
                    { resourceRef = "f82db71a:c3gaf7dd", percentBonus = -100, flatBonus = 0 },
                },
                statModifiers = {  },
                spells = {
                    "f82db71a:npcrage1",
                    "f82db71a:npcmulti",
                    "7bbb4cb9:xniv44uu",
                    "7bbb4cb9:ti2j4umn",
                },
                equipment = {
                    mainHandWeapon = "f82db71a:stwswd01",
                    shield = "f82db71a:stshld01",
                },
            },
            {
                name = "Cleric",
                challengeLevel = "normal",
                resourceModifiers = {
                    { resourceRef = "f82db71a:q2ktkztt", percentBonus = -20, flatBonus = 0 },
                    { resourceRef = "f82db71a:4c8mfm99", percentBonus = 20, flatBonus = 0 },
                    { resourceRef = "f82db71a:c3gaf7dd", percentBonus = -100, flatBonus = 0 },
                    { resourceRef = "f82db71a:e2tfklq7", percentBonus = -100, flatBonus = 0 },
                },
                statModifiers = {
                    { statRef = "f82db71a:v42albuv", percentBonus = -45, flatBonus = 0 },
                    { statRef = "f82db71a:u7b49vs9", percentBonus = -75, flatBonus = 0 },
                    { statRef = "f82db71a:v2rs9cpy", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:7t7xgzcx", percentBonus = 25, flatBonus = 0 },
                    { statRef = "f82db71a:hj6d4kvy", percentBonus = 50, flatBonus = 0 },
                    { statRef = "f82db71a:v2g0tw0o", percentBonus = 0, flatBonus = 5 },
                    { statRef = "f82db71a:69hfqhne", percentBonus = 0, flatBonus = 3 },
                    { statRef = "f82db71a:hlyrsstn", percentBonus = 0, flatBonus = 15 },
                    { statRef = "f82db71a:rgnrtg01", percentBonus = 0, flatBonus = 10 },
                },
                spells = {
                    "1c1038a7:qqkkenuw",
                    "1c1038a7:eet5xd4t",
                    "1c1038a7:1x1q35og",
                    "1c1038a7:pwshld01",
                },
                equipment = {
                    mainHandWeapon = "f82db71a:stwstf01",
                },
            },
            {
                name = "Pyromancer",
                challengeLevel = "normal",
                resourceModifiers = {
                    { resourceRef = "f82db71a:q2ktkztt", percentBonus = -25, flatBonus = 0 },
                    { resourceRef = "f82db71a:4c8mfm99", percentBonus = 15, flatBonus = 0 },
                    { resourceRef = "f82db71a:c3gaf7dd", percentBonus = -100, flatBonus = 0 },
                    { resourceRef = "f82db71a:e2tfklq7", percentBonus = -100, flatBonus = 0 },
                },
                statModifiers = {
                    { statRef = "f82db71a:v42albuv", percentBonus = -60, flatBonus = 0 },
                    { statRef = "f82db71a:u7b49vs9", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:v2rs9cpy", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:7t7xgzcx", percentBonus = 50, flatBonus = 0 },
                    { statRef = "f82db71a:hj6d4kvy", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:v2g0tw0o", percentBonus = 0, flatBonus = 5 },
                    { statRef = "f82db71a:69hfqhne", percentBonus = 0, flatBonus = 7 },
                    { statRef = "f82db71a:0w7c7p09", percentBonus = 0, flatBonus = 20 },
                    { statRef = "f82db71a:rgnrtg01", percentBonus = 0, flatBonus = 10 },
                },
                spells = {
                    "d7c874c4:molarm01",
                    "d7c874c4:68dy7na1",
                    "d7c874c4:zilla37l",
                },
                equipment = {
                    rangedWeapon = "f82db71a:stwwnd01",
                },
            },
            {
                name = "Arcanist",
                challengeLevel = "normal",
                resourceModifiers = {
                    { resourceRef = "f82db71a:q2ktkztt", percentBonus = -20, flatBonus = 0 },
                    { resourceRef = "f82db71a:4c8mfm99", percentBonus = 30, flatBonus = 0 },
                    { resourceRef = "f82db71a:c3gaf7dd", percentBonus = -100, flatBonus = 0 },
                    { resourceRef = "f82db71a:e2tfklq7", percentBonus = -100, flatBonus = 0 },
                },
                statModifiers = {
                    { statRef = "f82db71a:v42albuv", percentBonus = -55, flatBonus = 0 },
                    { statRef = "f82db71a:u7b49vs9", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:v2rs9cpy", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:7t7xgzcx", percentBonus = 40, flatBonus = 0 },
                    { statRef = "f82db71a:hj6d4kvy", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:v2g0tw0o", percentBonus = 0, flatBonus = 7 },
                    { statRef = "f82db71a:69hfqhne", percentBonus = 0, flatBonus = 5 },
                    { statRef = "f82db71a:zs1nbz13", percentBonus = 0, flatBonus = 10 },
                    { statRef = "f82db71a:954yunb9", percentBonus = 0, flatBonus = 20 },
                    { statRef = "f82db71a:rgnrtg01", percentBonus = 0, flatBonus = 15 },
                },
                spells = {
                    "d7c874c4:300h0gls",
                    "d7c874c4:n6jbep9e",
                    "d7c874c4:r760qxbn",
                },
                equipment = {
                    mainHandWeapon = "f82db71a:stwstf01",
                },
            },
            {
                name = "Cryomancer",
                challengeLevel = "normal",
                resourceModifiers = {
                    { resourceRef = "f82db71a:q2ktkztt", percentBonus = -15, flatBonus = 0 },
                    { resourceRef = "f82db71a:4c8mfm99", percentBonus = 20, flatBonus = 0 },
                    { resourceRef = "f82db71a:c3gaf7dd", percentBonus = -100, flatBonus = 0 },
                    { resourceRef = "f82db71a:e2tfklq7", percentBonus = -100, flatBonus = 0 },
                },
                statModifiers = {
                    { statRef = "f82db71a:v42albuv", percentBonus = -50, flatBonus = 0 },
                    { statRef = "f82db71a:u7b49vs9", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:v2rs9cpy", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:7t7xgzcx", percentBonus = 35, flatBonus = 0 },
                    { statRef = "f82db71a:hj6d4kvy", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:v2g0tw0o", percentBonus = 0, flatBonus = 5 },
                    { statRef = "f82db71a:69hfqhne", percentBonus = 0, flatBonus = 3 },
                    { statRef = "f82db71a:zs1nbz13", percentBonus = 0, flatBonus = 10 },
                    { statRef = "f82db71a:jjn0my8k", percentBonus = 0, flatBonus = 20 },
                    { statRef = "f82db71a:rgnrtg01", percentBonus = 0, flatBonus = 10 },
                },
                spells = {
                    "d7c874c4:icearm01",
                    "d7c874c4:lywroiqu",
                    "d7c874c4:4yxpy77f",
                },
                equipment = {
                    rangedWeapon = "f82db71a:stwwnd01",
                },
            },
            {
                name = "Sharpshooter",
                challengeLevel = "normal",
                resourceModifiers = {
                    { resourceRef = "f82db71a:q2ktkztt", percentBonus = -10, flatBonus = 0 },
                    { resourceRef = "f82db71a:4c8mfm99", percentBonus = 15, flatBonus = 0 },
                    { resourceRef = "f82db71a:c3gaf7dd", percentBonus = -100, flatBonus = 0 },
                    { resourceRef = "f82db71a:e2tfklq7", percentBonus = -100, flatBonus = 0 },
                },
                statModifiers = {
                    { statRef = "f82db71a:v42albuv", percentBonus = -25, flatBonus = 0 },
                    { statRef = "f82db71a:u7b49vs9", percentBonus = -50, flatBonus = 0 },
                    { statRef = "f82db71a:v2rs9cpy", percentBonus = 40, flatBonus = 0 },
                    { statRef = "f82db71a:7t7xgzcx", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:hj6d4kvy", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:dd88li4c", percentBonus = 0, flatBonus = 10 },
                    { statRef = "f82db71a:fercjhm5", percentBonus = 0, flatBonus = 10 },
                    { statRef = "f82db71a:o6113cir", percentBonus = 0, flatBonus = 5 },
                },
                spells = {
                    "f82db71a:shoota01",
                    "a93f7c12:nq9mgf7d",
                    "a93f7c12:11yx5k2d",
                    "a93f7c12:0ukabaim",
                },
                equipment = {
                    rangedWeapon = "f82db71a:stwbow01",
                },
            },
            {
                name = "Assassin",
                challengeLevel = "normal",
                resourceModifiers = {
                    { resourceRef = "f82db71a:q2ktkztt", percentBonus = -15, flatBonus = 0 },
                    { resourceRef = "f82db71a:4c8mfm99", percentBonus = -100, flatBonus = 0 },
                    { resourceRef = "f82db71a:e2tfklq7", percentBonus = -100, flatBonus = 0 },
                },
                statModifiers = {
                    { statRef = "f82db71a:v42albuv", percentBonus = -45, flatBonus = 0 },
                    { statRef = "f82db71a:u7b49vs9", percentBonus = 35, flatBonus = 0 },
                    { statRef = "f82db71a:v2rs9cpy", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:7t7xgzcx", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:hj6d4kvy", percentBonus = -100, flatBonus = 0 },
                    { statRef = "f82db71a:wbj4zuf3", percentBonus = 0, flatBonus = 10 },
                    { statRef = "f82db71a:jslmczbi", percentBonus = 0, flatBonus = 15 },
                    { statRef = "f82db71a:o6113cir", percentBonus = 0, flatBonus = 15 },
                    { statRef = "f82db71a:rgnrtg01", percentBonus = 0, flatBonus = 10 },
                },
                spells = {
                    "f82db71a:z36xzk0w",
                    "f82db71a:zd3t6feq",
                    "23d5dce2:300h0gls",
                    "23d5dce2:7x7itakn",
                    "23d5dce2:blind001",
                    "23d5dce2:kbifnqpj",
                },
                equipment = {
                    mainHandWeapon = "f82db71a:stwdgr01",
                    offHandWeapon = "f82db71a:stwdgr01",
                },
            },
            {
                name = "Captain",
                challengeLevel = "elite",
                resourceModifiers = {
                    { resourceRef = "f82db71a:q2ktkztt", percentBonus = 30, flatBonus = 0 },
                    { resourceRef = "f82db71a:4c8mfm99", percentBonus = 25, flatBonus = 0 },
                    { resourceRef = "f82db71a:c3gaf7dd", percentBonus = -100, flatBonus = 0 },
                    { resourceRef = "f82db71a:e2tfklq7", percentBonus = -100, flatBonus = 0 },
                },
                statModifiers = {
                    { statRef = "f82db71a:v42albuv", percentBonus = 40, flatBonus = 0 },
                    { statRef = "f82db71a:u7b49vs9", percentBonus = 20, flatBonus = 0 },
                    { statRef = "f82db71a:v2rs9cpy", percentBonus = -50, flatBonus = 0 },
                    { statRef = "f82db71a:7t7xgzcx", percentBonus = 25, flatBonus = 0 },
                    { statRef = "f82db71a:hj6d4kvy", percentBonus = 30, flatBonus = 0 },
                    { statRef = "f82db71a:wbj4zuf3", percentBonus = 0, flatBonus = 5 },
                    { statRef = "f82db71a:v2g0tw0o", percentBonus = 0, flatBonus = 5 },
                    { statRef = "f82db71a:p8syz5ba", percentBonus = 0, flatBonus = 10 },
                    { statRef = "f82db71a:hlyrsstn", percentBonus = 0, flatBonus = 15 },
                    { statRef = "f82db71a:j8n012e6", percentBonus = 0, flatBonus = 25 },
                    { statRef = "f82db71a:rgnrtg01", percentBonus = 0, flatBonus = 10 },
                },
                spells = {
                    "f82db71a:z36xzk0w",
                    "b0211ab3:uesn7obf",
                    "b0211ab3:h981ofan",
                    "b0211ab3:0opb1tte",
                    "b0211ab3:9nwvhorx",
                    "1c1038a7:circheal",
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
                initialValue = 208,
                perLevelValue = 43.084746,
                resourceRef = "f82db71a:q2ktkztt",
            },
            {
                initialValue = 100,
                perLevelValue = 23.5,
                resourceRef = "f82db71a:4c8mfm99",
            },
            {
                initialValue = 100,
                perLevelValue = 0,
                resourceRef = "f82db71a:c3gaf7dd",
            },
            {
                initialValue = 100,
                perLevelValue = 0,
                resourceRef = "f82db71a:e2tfklq7",
            },
        },
        spells = {
            "f82db71a:z36xzk0w",
            "f82db71a:shoota01",
        },
        stats = {
            {
                initialValue = 25,
                perLevelValue = 33.474576,
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
                initialValue = 65,
                perLevelValue = 9.067797,
                statRef = "f82db71a:u7b49vs9",
            },
            {
                initialValue = 65,
                perLevelValue = 9.067797,
                statRef = "f82db71a:v2rs9cpy",
            },
            {
                initialValue = 0,
                perLevelValue = 3.389831,
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
                perLevelValue = 4.237288,
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
        },
        tags = {  },
    },
}
```
