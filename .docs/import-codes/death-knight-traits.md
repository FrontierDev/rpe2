# Death Knight Trait Import Codes

Standalone `RPE_DATASET_ENTRY_V1` import codes for Wrath of the Lich King-era Death Knight traits in dataset `dknight1`.

Import the supporting Auras before any Trait that references them.

## Authoring rules applied

- These entries follow the existing Paladin/Warrior RPE trait model: static stat bonuses use `statBonuses`; proc passives use trait `events`; persistent group/self effects use `automaticAuras`; mutually exclusive stance-like mechanics use `mutuallyExclusiveTraitRefs`.
- **Blood Presence, Frost Presence, and Unholy Presence are Traits**, not spells. They are mutually exclusive.
- Maximum-rank Wrath values are used where the mechanic maps directly onto an existing RPE stat/event.
- The three Presence entries implement only the portions RPE can represent faithfully:
  - Blood Presence: +15 Damage Done. The 4% healing from non-periodic damage dealt is not representable because trait healing cannot scale from the triggering damage amount.
  - Frost Presence: +8% Stamina, +60% Armor, +8 Damage Reduction, plus the established RPE tank-stance value of +80 Threat Generated.
  - Unholy Presence: +15 Movement Speed. Attack speed and sub-turn GCD reduction are not represented.
- **Bladed Armor** is represented with an automatic self aura whose Melee Attack Power scales by `5 / 180` of current Armor, matching the max-rank Wrath relationship.
- **Scent of Blood** uses the max-rank three-charge behavior: a 15% proc after a defence or direct-damage event applies three charges; each melee hit consumes one charge and grants 10 Runic Power. RPE does not distinguish direct from periodic spell damage in `on_spell_taken`, so that trigger is slightly broader than Wrath.
- **Abomination's Might** gives the Death Knight +2% Strength and applies +10% Melee Attack Power to self and allies.
- **Improved Blood Presence** implements its supported Blood-Presence component: +10 Healing Received while Blood Presence is selected. Retained Blood-Presence self-healing in the other Presences is not representable.
- **Improved Frost Presence** implements its supported Frost-Presence component: +2 Damage Reduction while Frost Presence is selected. Retaining Frost Presence Stamina while in the other Presences would require conditional per-bonus logic that the current Trait schema does not have.
- **Endless Winter** implements +4% Strength; its Mind Freeze cost reduction is spell-specific and not represented.
- **Ravenous Dead** implements +3% Strength; Ghoul scaling is intentionally omitted.
- **Magic Suppression** implements +6 Magic Resistance; its Anti-Magic Shell-specific absorption modifier is not represented.
- **Ebon Plaguebringer** implements the passive +3 Melee/Spell Crit. Chance; its target-side disease/magic-damage amplification is not representable by the current Trait schema.
- **On a Pale Horse** implements +20 Movement Speed while mounted; stun/fear-duration reduction is not represented.
- Active WotLK talent abilities already authored as spells (for example Rune Tap, Mark of Blood, Vampiric Blood, Heart Strike, Hungering Cold, Unbreakable Armor, Frost Strike, Howling Blast, Bone Shield, Anti-Magic Zone, and Scourge Strike) are not duplicated as Trait entries.

## Not authored because the defining mechanic is unsupported

The following passive WotLK talents are intentionally omitted rather than generalized into inaccurate global bonuses:

- **Blood:** Butchery, Subversion, Blade Barrier, Two-Handed Weapon Specialization, Death Rune Mastery, Improved Rune Tap, Spell Deflection, Vendetta, Bloody Strikes, Bloody Vengeance, Bloodworms, Improved Death Strike, Sudden Doom, Will of the Necropolis, Might of Mograine, Blood Gorged.
- **Frost:** Improved Icy Touch, Runic Power Mastery, Icy Reach, Black Ice, Nerves of Cold Steel, Icy Talons, Annihilation, Killing Machine, Chill of the Grave, Frigid Dreadplate, Glacier Rot, Improved Icy Talons, Merciless Combat, Rime, Chilblains, Threat of Thassarian, Blood of the North, Acclimation, Guile of Gorefiend, Tundra Stalker.
- **Unholy:** Vicious Strikes, Epidemic, Morbidity, Unholy Command, Outbreak, Necrosis, Blood-Caked Blade, Night of the Dead, Unholy Blight, Impurity, Dirge, Desecration, Reaping, Master of Ghouls, Desolation, Improved Unholy Presence, Crypt Fever, Wandering Plague, Rage of Rivendare.

## Supporting Auras

### Bladed Armor

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "dknight1",
    entry = {
        description = "",
        duration = 9999,
        effects = {
            {
                baseAmount = 0,
                operation = "flat",
                scaleWithRank = false,
                statRef = "f82db71a:u7b49vs9",
                statScaling = {
                    {
                        coefficient = 0.027777777777777776,
                        statRef = "f82db71a:v42albuv",
                    },
                },
                type = "stat",
            },
        },
        events = { },
        icon = "interface/icons/inv_shoulder_36.blp",
        id = "dkbladaa",
        maxStacks = 1,
        name = "Bladed Armor",
        stackBehavior = "refresh_duration",
        tags = { },
        tooltipTemplate = false,
    },
}
```

### Scent of Blood

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "dknight1",
    entry = {
        description = "",
        duration = 5,
        effects = { },
        events = {
            {
                chance = 100,
                combatEventId = "on_melee_hit",
                triggerTarget = "aura_caster",
                effects = {
                    {
                        amount = 10,
                        amountMode = "flat",
                        resourceRef = "f82db71a:jolh6o6e",
                        scaleWithRank = false,
                        type = "resource",
                    },
                    {
                        auraRef = "dknight1:dkscenta",
                        stacks = 1,
                        type = "remove_aura",
                    },
                },
            },
        },
        icon = "interface/icons/ability_rogue_bloodyeye.blp",
        id = "dkscenta",
        maxStacks = 3,
        name = "Scent of Blood",
        stackBehavior = "refresh_duration",
        tags = { },
        tooltipTemplate = false,
    },
}
```

### Abomination's Might

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "dknight1",
    entry = {
        description = "",
        duration = 9999,
        effects = {
            {
                baseAmount = 10,
                operation = "percent",
                scaleWithRank = false,
                statRef = "f82db71a:u7b49vs9",
                statScaling = { },
                type = "stat",
            },
        },
        events = { },
        icon = "interface/icons/ability_warrior_intensifyrage.blp",
        id = "dkaboma1",
        maxStacks = 1,
        name = "Abomination's Might",
        stackBehavior = "refresh_duration",
        tags = { },
        tooltipTemplate = false,
    },
}
```

# Presences

## Blood Presence

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "dknight1",
    entry = {
        automaticAuras = { },
        category = "Blood",
        conditions = { },
        description = "",
        events = { },
        icon = "interface/icons/spell_deathknight_bloodpresence.blp",
        id = "dkbloodp",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {
            "dknight1:dkfrostp",
            "dknight1:dkunholy",
        },
        name = "Blood Presence",
        skillBonuses = { },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:gj9wxb0x",
                value = 15,
            },
        },
        unlockLevel = 1,
    },
}
```

## Frost Presence

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "dknight1",
    entry = {
        automaticAuras = { },
        category = "Frost",
        conditions = { },
        description = "",
        events = { },
        icon = "interface/icons/spell_deathknight_frostpresence.blp",
        id = "dkfrostp",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {
            "dknight1:dkbloodp",
            "dknight1:dkunholy",
        },
        name = "Frost Presence",
        skillBonuses = { },
        statBonuses = {
            {
                operation = "percent",
                statRef = "f82db71a:ygjno50i",
                value = 8,
            },
            {
                operation = "percent",
                statRef = "f82db71a:v42albuv",
                value = 60,
            },
            {
                operation = "flat",
                statRef = "f82db71a:pu05li08",
                value = 8,
            },
            {
                operation = "flat",
                statRef = "f82db71a:j8n012e6",
                value = 80,
            },
        },
        unlockLevel = 1,
    },
}
```

## Unholy Presence

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "dknight1",
    entry = {
        automaticAuras = { },
        category = "Unholy",
        conditions = { },
        description = "",
        events = { },
        icon = "interface/icons/spell_deathknight_unholypresence.blp",
        id = "dkunholy",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {
            "dknight1:dkbloodp",
            "dknight1:dkfrostp",
        },
        name = "Unholy Presence",
        skillBonuses = { },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:s1mt6jh9",
                value = 15,
            },
        },
        unlockLevel = 1,
    },
}
```

# Blood

## Bladed Armor

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "dknight1",
    entry = {
        automaticAuras = {
            {
                auraRef = "dknight1:dkbladaa",
                powerLevel = 0,
                stacks = 1,
                targetScope = "self",
                turns = 9999,
            },
        },
        category = "Blood",
        conditions = { },
        description = "",
        events = { },
        icon = "interface/icons/inv_shoulder_36.blp",
        id = "dkbladad",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = { },
        name = "Bladed Armor",
        skillBonuses = { },
        statBonuses = { },
        unlockLevel = 1,
    },
}
```

## Scent of Blood

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "dknight1",
    entry = {
        automaticAuras = { },
        category = "Blood",
        conditions = { },
        description = "",
        events = {
            {
                chance = 15,
                combatEventId = "on_defence",
                effects = {
                    {
                        auraRef = "dknight1:dkscenta",
                        basePower = 0,
                        duration = 5,
                        stacks = 3,
                        type = "apply_aura",
                    },
                },
                triggerTarget = "aura_caster",
            },
            {
                chance = 15,
                combatEventId = "on_melee_taken",
                effects = {
                    {
                        auraRef = "dknight1:dkscenta",
                        basePower = 0,
                        duration = 5,
                        stacks = 3,
                        type = "apply_aura",
                    },
                },
                triggerTarget = "aura_caster",
            },
            {
                chance = 15,
                combatEventId = "on_ranged_taken",
                effects = {
                    {
                        auraRef = "dknight1:dkscenta",
                        basePower = 0,
                        duration = 5,
                        stacks = 3,
                        type = "apply_aura",
                    },
                },
                triggerTarget = "aura_caster",
            },
            {
                chance = 15,
                combatEventId = "on_spell_taken",
                effects = {
                    {
                        auraRef = "dknight1:dkscenta",
                        basePower = 0,
                        duration = 5,
                        stacks = 3,
                        type = "apply_aura",
                    },
                },
                triggerTarget = "aura_caster",
            },
        },
        icon = "interface/icons/ability_rogue_bloodyeye.blp",
        id = "dkscentb",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = { },
        name = "Scent of Blood",
        skillBonuses = { },
        statBonuses = { },
        unlockLevel = 1,
    },
}
```

## Dark Conviction

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "dknight1",
    entry = {
        automaticAuras = { },
        category = "Blood",
        conditions = { },
        description = "",
        events = { },
        icon = "interface/icons/spell_deathknight_darkconviction.blp",
        id = "dkdarkcv",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = { },
        name = "Dark Conviction",
        skillBonuses = { },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:jslmczbi",
                value = 5,
            },
            {
                operation = "flat",
                statRef = "f82db71a:fercjhm5",
                value = 5,
            },
            {
                operation = "flat",
                statRef = "f82db71a:69hfqhne",
                value = 5,
            },
        },
        unlockLevel = 1,
    },
}
```

## Veteran of the Third War

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "dknight1",
    entry = {
        automaticAuras = { },
        category = "Blood",
        conditions = { },
        description = "",
        events = { },
        icon = "interface/icons/spell_misc_warsongfocus.blp",
        id = "dkvet3rd",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = { },
        name = "Veteran of the Third War",
        skillBonuses = { },
        statBonuses = {
            {
                operation = "percent",
                statRef = "f82db71a:zfqm8dxp",
                value = 6,
            },
            {
                operation = "percent",
                statRef = "f82db71a:ygjno50i",
                value = 3,
            },
        },
        unlockLevel = 1,
    },
}
```

## Abomination's Might

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "dknight1",
    entry = {
        automaticAuras = {
            {
                auraRef = "dknight1:dkaboma1",
                powerLevel = 0,
                stacks = 1,
                targetScope = "self",
                turns = 9999,
            },
            {
                auraRef = "dknight1:dkaboma1",
                powerLevel = 0,
                stacks = 1,
                targetScope = "all_allies",
                turns = 9999,
            },
        },
        category = "Blood",
        conditions = { },
        description = "",
        events = { },
        icon = "interface/icons/ability_warrior_intensifyrage.blp",
        id = "dkabomgt",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = { },
        name = "Abomination's Might",
        skillBonuses = { },
        statBonuses = {
            {
                operation = "percent",
                statRef = "f82db71a:zfqm8dxp",
                value = 2,
            },
        },
        unlockLevel = 1,
    },
}
```

## Improved Blood Presence

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "dknight1",
    entry = {
        automaticAuras = { },
        category = "Blood",
        conditions = {
            {
                invert = false,
                showOnTooltip = true,
                tooltipTextOverride = "Requires Blood Presence",
                traitRef = "dknight1:dkbloodp",
                type = "trait_requirement",
                unit = "caster",
            },
        },
        description = "",
        events = { },
        icon = "interface/icons/spell_deathknight_bloodpresence.blp",
        id = "dkimpblp",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = { },
        name = "Improved Blood Presence",
        skillBonuses = { },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:ok80ohz3",
                value = 10,
            },
        },
        unlockLevel = 1,
    },
}
```

# Frost

## Toughness

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "dknight1",
    entry = {
        automaticAuras = { },
        category = "Frost",
        conditions = { },
        description = "",
        events = { },
        icon = "interface/icons/spell_holy_devotion.blp",
        id = "dktoughn",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = { },
        name = "Toughness",
        skillBonuses = { },
        statBonuses = {
            {
                operation = "percent",
                statRef = "f82db71a:v42albuv",
                value = 10,
            },
        },
        unlockLevel = 1,
    },
}
```

## Endless Winter

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "dknight1",
    entry = {
        automaticAuras = { },
        category = "Frost",
        conditions = { },
        description = "",
        events = { },
        icon = "interface/icons/spell_shadow_twilight.blp",
        id = "dkendwin",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = { },
        name = "Endless Winter",
        skillBonuses = { },
        statBonuses = {
            {
                operation = "percent",
                statRef = "f82db71a:zfqm8dxp",
                value = 4,
            },
        },
        unlockLevel = 1,
    },
}
```

## Improved Frost Presence

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "dknight1",
    entry = {
        automaticAuras = { },
        category = "Frost",
        conditions = {
            {
                invert = false,
                showOnTooltip = true,
                tooltipTextOverride = "Requires Frost Presence",
                traitRef = "dknight1:dkfrostp",
                type = "trait_requirement",
                unit = "caster",
            },
        },
        description = "",
        events = { },
        icon = "interface/icons/spell_deathknight_frostpresence.blp",
        id = "dkimpfrp",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = { },
        name = "Improved Frost Presence",
        skillBonuses = { },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:pu05li08",
                value = 2,
            },
        },
        unlockLevel = 1,
    },
}
```

# Unholy

## Virulence

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "dknight1",
    entry = {
        automaticAuras = { },
        category = "Unholy",
        conditions = { },
        description = "",
        events = { },
        icon = "interface/icons/spell_shadow_burningspirit.blp",
        id = "dkviruln",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = { },
        name = "Virulence",
        skillBonuses = { },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:v2g0tw0o",
                value = 3,
            },
        },
        unlockLevel = 1,
    },
}
```

## Anticipation

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "dknight1",
    entry = {
        automaticAuras = { },
        category = "Unholy",
        conditions = { },
        description = "",
        events = { },
        icon = "interface/icons/spell_nature_mirrorimage.blp",
        id = "dkantici",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = { },
        name = "Anticipation",
        skillBonuses = { },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:o6113cir",
                value = 5,
            },
        },
        unlockLevel = 1,
    },
}
```

## Ravenous Dead

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "dknight1",
    entry = {
        automaticAuras = { },
        category = "Unholy",
        conditions = { },
        description = "",
        events = { },
        icon = "interface/icons/spell_shadow_animatedead.blp",
        id = "dkravend",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = { },
        name = "Ravenous Dead",
        skillBonuses = { },
        statBonuses = {
            {
                operation = "percent",
                statRef = "f82db71a:zfqm8dxp",
                value = 3,
            },
        },
        unlockLevel = 1,
    },
}
```

## Magic Suppression

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "dknight1",
    entry = {
        automaticAuras = { },
        category = "Unholy",
        conditions = { },
        description = "",
        events = { },
        icon = "interface/icons/spell_shadow_antimagicshell.blp",
        id = "dkmagsup",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = { },
        name = "Magic Suppression",
        skillBonuses = { },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:zs1nbz13",
                value = 6,
            },
        },
        unlockLevel = 1,
    },
}
```

## Ebon Plaguebringer

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "dknight1",
    entry = {
        automaticAuras = { },
        category = "Unholy",
        conditions = { },
        description = "",
        events = { },
        icon = "interface/icons/ability_creature_cursed_03.blp",
        id = "dkebonpl",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = { },
        name = "Ebon Plaguebringer",
        skillBonuses = { },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:jslmczbi",
                value = 3,
            },
            {
                operation = "flat",
                statRef = "f82db71a:69hfqhne",
                value = 3,
            },
        },
        unlockLevel = 1,
    },
}
```

## On a Pale Horse

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "dknight1",
    entry = {
        automaticAuras = { },
        category = "Unholy",
        conditions = {
            {
                invert = false,
                showOnTooltip = true,
                tooltipTextOverride = "Requires Mounted",
                type = "mounted",
                unit = "caster",
            },
        },
        description = "",
        events = { },
        icon = "interface/icons/spell_deathknight_classicon.blp",
        id = "dkpalhrs",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = { },
        name = "On a Pale Horse",
        skillBonuses = { },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:s1mt6jh9",
                value = 20,
            },
        },
        unlockLevel = 1,
    },
}
```

