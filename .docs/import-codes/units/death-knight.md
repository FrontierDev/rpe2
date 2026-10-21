# Death Knight NPC — Elite Unit Import Code

Standalone `RPE_DATASET_ENTRY_V1` import code for the **Death Knight** base NPC unit in the **Death Knight** dataset (`dknight1`).

## Unit definition

- **Name:** Death Knight
- **Unit ID:** `dkunit01`
- **Challenge:** `elite`
- **Creature type:** `undead`
- **Size:** `medium`
- **Equipment:** Core Worn Greatsword (`f82db71a:stw2sw01`) in the main hand
- **Presets:** none; this is a directly usable elite base unit
- **Appearances:** empty; select a verified appropriate model in the Data Editor as needed

## Spell package

| Spell | Existing reference | Notes |
| --- | --- | --- |
| Main Hand Attack | `f82db71a:z36xzk0w` | Basic attack, free-action channel; weapon equipped |
| Scourge Strike | `dknight1:dkss0001` | Main Action, uses main-hand weapon, costs 2 Runes, 2-turn cooldown |
| Death and Decay | `dknight1:dkdnd001` | Bonus Action, costs 3 Runes, 3-turn cooldown; applies existing damage aura |

All three spells are already defined on `main`. The base unit references the **spells**, not the Death and Decay aura (`dknight1:dkdnda01`). Scourge Strike and Death and Decay share the existing `dk_unholy` cooldown group; no copied or modified abilities are introduced.

The unit has **6 Runes** and **100 maximum Runic Power** (the existing Runic Power definition starts at zero). The selected spells spend Runes, not Runic Power. Resource consumption, regeneration and cooldown-group behavior remain governed by the existing game systems.

**Dataset placement:** `dknight1` already depends on Core (`f82db71a`), so the unit's cross-dataset attack, resource, weapon, and stat references follow the existing dependency direction.

## Level-60 stat calibration

These are proposed RPE Elite balance targets, not claimed Blizzard NPC attributes. In line with existing Elite Undead unit import codes, the base Death Knight is a durable melee attacker with high Melee Attack Power. Both Death Knight abilities use Melee Attack Power, so no independent Spell Power is required for their damage scaling.

`Level N = initialValue + (N - 1) × perLevelValue` (per-level values stored to six decimals). The values in the final column are the intended authored **level-60 baselines**, before event-specific modifiers or party-size scaling.

| Resource / stat | Initial | Per level | Level 60 |
| --- | ---: | ---: | ---: |
| Health | 200 | 149.152542 | 9000 |
| Runes | 6 | 0 | 6 |
| Runic Power | 100 | 0 | 100 |
| Armor | 60 | 60 | 3600 |
| Melee Hit Chance | 5 | 0 | 5 |
| Ranged Hit Chance | 0 | 0 | 0 |
| Spell Hit Chance | 0 | 0 | 0 |
| Parry Chance | 5 | 0 | 5 |
| Dodge Chance | 0 | 0 | 0 |
| Block Chance | 0 | 0 | 0 |
| Magic Resistance | 0 | 0 | 0 |
| Melee Attack Power | 60 | 10.423729 | 675 |
| Ranged Attack Power | 0 | 0 | 0 |
| Spell Power | 0 | 0 | 0 |
| Melee Crit Chance | 7 | 0 | 7 |
| Ranged Crit Chance | 0 | 0 | 0 |
| Spell Crit Chance | 0 | 0 | 0 |
| Fire Resistance | 0 | 0 | 0 |
| Holy Resistance | 0 | 0 | 0 |
| Frost Resistance | 0 | 0 | 0 |
| Nature Resistance | 0 | 0 | 0 |
| Arcane Resistance | 0 | 0 | 0 |
| Shadow Resistance | 0 | 0 | 0 |
| Healing Power | 0 | 0 | 0 |
| Resource Regeneration | 0 | 0 | 0 |
| Movement Speed | 30 | 0 | 30 |

No initial `Damage Done` or `Damage Reduction` is added. No innate magic-school resistances are assumed for being Undead.

## Import code

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "units",
    datasetId = "dknight1",
    entry = {
        appearances = {  },
        attributes = {  },
        challengeLevel = "elite",
        creatureSize = "medium",
        creatureType = "undead",
        id = "dkunit01",
        mainHandWeapon = "f82db71a:stw2sw01",
        name = "Death Knight",
        presets = {  },
        resistances = {  },
        resources = {
            { initialValue = 200, perLevelValue = 149.152542, resourceRef = "f82db71a:q2ktkztt" },
            { initialValue = 6, perLevelValue = 0, resourceRef = "f82db71a:runes001" },
            { initialValue = 100, perLevelValue = 0, resourceRef = "f82db71a:jolh6o6e" },
        },
        spells = {
            "f82db71a:z36xzk0w",
            "dknight1:dkss0001",
            "dknight1:dkdnd001",
        },
        stats = {
            { initialValue = 60, perLevelValue = 60, statRef = "f82db71a:v42albuv" },
            { initialValue = 5, perLevelValue = 0, statRef = "f82db71a:wbj4zuf3" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:dd88li4c" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:v2g0tw0o" },
            { initialValue = 5, perLevelValue = 0, statRef = "f82db71a:tcn0s8kx" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:o6113cir" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:p8syz5ba" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:zs1nbz13" },
            { initialValue = 60, perLevelValue = 10.423729, statRef = "f82db71a:u7b49vs9" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:v2rs9cpy" },
            { initialValue = 0, perLevelValue = 0, statRef = "f82db71a:7t7xgzcx" },
            { initialValue = 7, perLevelValue = 0, statRef = "f82db71a:jslmczbi" },
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
