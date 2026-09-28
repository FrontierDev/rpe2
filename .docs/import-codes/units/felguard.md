# Felguard Unit Import Code

Standalone `RPE_DATASET_ENTRY_V1` import code for a base Felguard unit in the Core dataset (`f82db71a`).

## Level-60 calibration

| Stat | Initial | Per level | Level 60 |
|---|---:|---:|---:|
| Health | 208 | 55.796610 | 3,500 |
| Armor | 25 | 46.186441 | 2,750 |
| Melee Attack Power | 65 | 9.491525 | 625 |
| Ranged Attack Power | 0 | 0 | 0 |
| Spell Power | 0 | 0 | 0 |
| Healing Power | 0 | 0 | 0 |
| Melee Hit Chance | 0 | 0 | 0 |
| Ranged Hit Chance | 0 | 0 | 0 |
| Spell Hit Chance | 0 | 0 | 0 |
| Melee Crit Chance | 5 | 0 | 5 |
| Ranged Crit Chance | 0 | 0 | 0 |
| Spell Crit Chance | 0 | 0 | 0 |
| Parry Chance | 3 | 0 | 3 |
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

## Variants

| Variant | Challenge | Level-60 Health | Level-60 Armor | Level-60 MAP | Role |
|---|---|---:|---:|---:|---|
| Legionnaire | Normal | 3,850 | 2,887.5 | 650 | Durable disciplined frontliner |
| Destroyer | Normal | 2,975 | 2,062.5 | 650 | Aggressive melee attacker with higher crit |
| Lieutenant | Elite | 10,500 | 3,987.5 | 750 | Elite command/frontline unit |

### Legionnaire

A tougher standard Felguard intended to hold the line without leaving the Normal challenge band.

Modifiers:

- Health: +10%
- Armor: +5%
- Melee Attack Power: +4%
- Melee Hit Chance: +3
- Parry Chance: +2

### Destroyer

A more aggressive Normal Felguard that trades survivability for offensive reliability.

Modifiers:

- Health: -15%
- Armor: -25%
- Melee Attack Power: +4%
- Melee Hit Chance: +3
- Melee Crit Chance: +5

### Lieutenant

An Elite Felguard commander. The preset changes the effective challenge level to `elite` and raises its actual resolved durability into the current Elite authoring bands rather than relying on the challenge label alone.

Modifiers:

- Health: +200%
- Armor: +45%
- Melee Attack Power: +20%
- Melee Hit Chance: +5
- Melee Crit Chance: +2
- Parry Chance: +5

At Level 60 this resolves to 10,500 authored Health, 3,987.5 Armor and 750 Melee Attack Power. With the current five-player scaling for Elite units, that is approximately 15,750 runtime Health before event difficulty modifiers.

## Authoring notes

- Creature type: `demon`
- Creature size: `large`
- Base challenge level: `normal`
- The Felguard is deliberately authored toward the upper end of the Normal melee-combatant band rather than being Elite by default.
- At Level 60, 3,500 authored Health becomes approximately 5,250 runtime Health for a five-player event under the current Normal/Elite player-count scaling.
- Level-60 Armor (2,750) and Melee Attack Power (625) remain inside the current recommended Normal bands while leaving limited headroom for role presets.
- No broad elemental or magical resistance is granted solely for being a Demon. Resistances should be added by a specific variant or encounter mechanic where required.
- Damage Done and Damage Reduction are not baseline seeded NPC stats and are not authored here.
- The Level-60 values are the balance target. The low-level curve is provisional because the current NPC survivability guide does not yet define authoritative low-level calibration.
- This base import intentionally defines no role preset, equipment package, or bespoke combat abilities. Those should be layered separately so the base creature remains reusable.

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
        creatureType = "demon",
        id = "felgrd01",
        name = "Felguard",
        presets = {
            {
                name = "Legionnaire",
                challengeLevel = "normal",
                resourceModifiers = {
                    {
                        resourceRef = "f82db71a:q2ktkztt",
                        percentBonus = 10,
                        flatBonus = 0,
                    },
                },
                statModifiers = {
                    {
                        statRef = "f82db71a:v42albuv",
                        percentBonus = 5,
                        flatBonus = 0,
                    },
                    {
                        statRef = "f82db71a:u7b49vs9",
                        percentBonus = 4,
                        flatBonus = 0,
                    },
                    {
                        statRef = "f82db71a:wbj4zuf3",
                        percentBonus = 0,
                        flatBonus = 3,
                    },
                    {
                        statRef = "f82db71a:tcn0s8kx",
                        percentBonus = 0,
                        flatBonus = 2,
                    },
                },
                spells = {  },
            },
            {
                name = "Destroyer",
                challengeLevel = "normal",
                resourceModifiers = {
                    {
                        resourceRef = "f82db71a:q2ktkztt",
                        percentBonus = -15,
                        flatBonus = 0,
                    },
                },
                statModifiers = {
                    {
                        statRef = "f82db71a:v42albuv",
                        percentBonus = -25,
                        flatBonus = 0,
                    },
                    {
                        statRef = "f82db71a:u7b49vs9",
                        percentBonus = 4,
                        flatBonus = 0,
                    },
                    {
                        statRef = "f82db71a:wbj4zuf3",
                        percentBonus = 0,
                        flatBonus = 3,
                    },
                    {
                        statRef = "f82db71a:jslmczbi",
                        percentBonus = 0,
                        flatBonus = 5,
                    },
                },
                spells = {  },
            },
            {
                name = "Lieutenant",
                challengeLevel = "elite",
                resourceModifiers = {
                    {
                        resourceRef = "f82db71a:q2ktkztt",
                        percentBonus = 200,
                        flatBonus = 0,
                    },
                },
                statModifiers = {
                    {
                        statRef = "f82db71a:v42albuv",
                        percentBonus = 45,
                        flatBonus = 0,
                    },
                    {
                        statRef = "f82db71a:u7b49vs9",
                        percentBonus = 20,
                        flatBonus = 0,
                    },
                    {
                        statRef = "f82db71a:wbj4zuf3",
                        percentBonus = 0,
                        flatBonus = 5,
                    },
                    {
                        statRef = "f82db71a:jslmczbi",
                        percentBonus = 0,
                        flatBonus = 2,
                    },
                    {
                        statRef = "f82db71a:tcn0s8kx",
                        percentBonus = 0,
                        flatBonus = 5,
                    },
                },
                spells = {  },
            },
        },
        resistances = {  },
        resources = {
            {
                initialValue = 208,
                perLevelValue = 55.796610,
                resourceRef = "f82db71a:q2ktkztt",
            },
        },
        spells = {  },
        stats = {
            {
                initialValue = 25,
                perLevelValue = 46.186441,
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
                initialValue = 3,
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
                perLevelValue = 9.491525,
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
                initialValue = 30,
                perLevelValue = 0,
                statRef = "f82db71a:s1mt6jh9",
            },
        },
        tags = {  },
    },
}
```
