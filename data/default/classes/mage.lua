local _, Addon = ...

Addon.Data.DefaultDatasets:Register({
    version = 18,
    dataset = {
        achievements = {},
        auras = {
            {
                description = "",
                duration = 5,
                effects = {
                    {
                        amountMode = "flat",
                        baseDamage = 20.8,
                        damageSchoolRefs = {
                            "f82db71a:esjguw6d"
                        },
                        statScaling = {
                            {
                                coefficient = 0.52,
                                statRef = "f82db71a:7t7xgzcx"
                            }
                        },
                        type = "damage"
                    }
                },
                events = {},
                icon = "interface/icons/spell_fire_firebolt02.blp",
                id = "vtrjl3l2",
                maxStacks = 1,
                name = "Fireball",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Deals {AURA_DAMAGE_1} Fire damage each turn.",
                    bodyTokens = {
                        {
                            applyMode = "damage_amount",
                            baseField = "baseDamage",
                            effectIndex = 1,
                            key = "AURA_DAMAGE_1",
                            tokenType = "aura_amount"
                        }
                    },
                    stackingText = "",
                    stackingTokens = {},
                    version = 1
                }
            },
            {
                description = "",
                duration = 5,
                effects = {
                    {
                        amountMode = "flat",
                        baseDamage = 72,
                        damageSchoolRefs = {
                            "f82db71a:esjguw6d"
                        },
                        statScaling = {
                            {
                                coefficient = 1.8,
                                statRef = "f82db71a:7t7xgzcx"
                            }
                        },
                        type = "damage"
                    }
                },
                events = {},
                icon = "interface/icons/spell_fire_fireball02.blp",
                id = "ghe969oh",
                maxStacks = 1,
                name = "Pyroblast",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Deals {AURA_DAMAGE_1} Fire damage each turn.",
                    bodyTokens = {
                        {
                            applyMode = "damage_amount",
                            baseField = "baseDamage",
                            effectIndex = 1,
                            key = "AURA_DAMAGE_1",
                            tokenType = "aura_amount"
                        }
                    },
                    stackingText = "",
                    stackingTokens = {},
                    version = 1
                }
            },
            {
                description = "",
                duration = 5,
                effects = {
                    {
                        baseAmount = -5,
                        operation = "percent",
                        statRef = "f82db71a:0w7c7p09",
                        statScaling = {},
                        type = "stat"
                    }
                },
                events = {},
                icon = "interface/icons/spell_fire_soulburn.blp",
                id = "yxha70sc",
                maxStacks = 5,
                name = "Scorch",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Reduces Fire Resistance by 5%.",
                    bodyTokens = {},
                    stackingText = "Applies {AURA_APPLIED_STACKS_1} stacks. Stacks up to {AURA_MAX_STACKS_1} times.",
                    stackingTokens = {
                        {
                            applyMode = "applied_stacks",
                            key = "AURA_APPLIED_STACKS_1",
                            tokenType = "aura_stacks"
                        },
                        {
                            applyMode = "max_stacks",
                            key = "AURA_MAX_STACKS_1",
                            tokenType = "aura_stacks"
                        }
                    },
                    version = 1
                }
            },
            {
                description = "",
                duration = 1,
                effects = {
                    {
                        baseAmount = 100,
                        operation = "flat",
                        statRef = "f82db71a:69hfqhne",
                        statScaling = {},
                        type = "stat"
                    }
                },
                events = {},
                icon = "interface/icons/spell_fire_sealoffire.blp",
                id = "ppxho9hn",
                maxStacks = 1,
                name = "Combustion",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Increases Spell Crit. Chance by 100%.",
                    bodyTokens = {},
                    stackingText = "",
                    stackingTokens = {},
                    version = 1
                }
            },
            {
                description = "",
                duration = 2,
                effects = {
                    {
                        amountMode = "flat",
                        baseAbsorption = 104,
                        damageSchoolRefs = {
                            "f82db71a:esjguw6d"
                        },
                        statScaling = {
                            {
                                coefficient = 0.520,
                                statRef = "f82db71a:7t7xgzcx"
                            }
                        },
                        type = "absorb"
                    }
                },
                events = {},
                icon = "interface/icons/spell_fire_firearmor.blp",
                id = "frwdau01",
                maxStacks = 1,
                name = "Fire Ward",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Absorbs {AURA_ABSORB_1} Fire damage.",
                    bodyTokens = {
                        {
                            applyMode = "absorb_amount",
                            baseField = "baseAbsorption",
                            effectIndex = 1,
                            key = "AURA_ABSORB_1",
                            tokenType = "aura_amount"
                        }
                    },
                    stackingText = "",
                    stackingTokens = {},
                    version = 1
                }
            },
            {
                description = "",
                duration = 2,
                effects = {
                    {
                        amountMode = "flat",
                        baseAbsorption = 104,
                        damageSchoolRefs = {
                            "f82db71a:hx7pnwv4"
                        },
                        statScaling = {
                            {
                                coefficient = 0.520,
                                statRef = "f82db71a:7t7xgzcx"
                            }
                        },
                        type = "absorb"
                    }
                },
                events = {},
                icon = "interface/icons/spell_frost_frostward.blp",
                id = "fowdau01",
                maxStacks = 1,
                name = "Frost Ward",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Absorbs {AURA_ABSORB_1} Frost damage.",
                    bodyTokens = {
                        {
                            applyMode = "absorb_amount",
                            baseField = "baseAbsorption",
                            effectIndex = 1,
                            key = "AURA_ABSORB_1",
                            tokenType = "aura_amount"
                        }
                    },
                    stackingText = "",
                    stackingTokens = {},
                    version = 1
                }
            },
            {
                description = "Enables the use of Arcane Missiles.",
                duration = 5,
                effects = {},
                events = {},
                icon = "interface/icons/spell_arcane_arcane04.blp",
                id = "xq18639s",
                maxStacks = 3,
                name = "Arcane Missiles",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Enables the use of Arcane Missiles.",
                    bodyTokens = {},
                    stackingText = "Applies {AURA_APPLIED_STACKS_1} stacks. Stacks up to {AURA_MAX_STACKS_1} times.",
                    stackingTokens = {
                        {
                            applyMode = "applied_stacks",
                            key = "AURA_APPLIED_STACKS_1",
                            tokenType = "aura_stacks"
                        },
                        {
                            applyMode = "max_stacks",
                            key = "AURA_MAX_STACKS_1",
                            tokenType = "aura_stacks"
                        }
                    },
                    version = 1
                }
            },
            {
                description = "",
                duration = 10,
                effects = {
                    {
                        amount = 8,
                        amountMode = "max_percent",
                        resourceRef = "f82db71a:4c8mfm99",
                        type = "resource"
                    }
                },
                events = {},
                icon = "interface/icons/spell_arcane_arcanetorrent.blp",
                id = "ezq64q0p",
                maxStacks = 1,
                name = "Arcane Surge",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Restores 8% of Max Mana each turn.",
                    bodyTokens = {},
                    stackingText = "",
                    stackingTokens = {},
                    version = 1
                }
            },
            {
                description = "",
                duration = 10,
                effects = {
                    {
                        baseAmount = 10,
                        operation = "percent",
                        statRef = "f82db71a:75y3a8ib",
                        statScaling = {},
                        type = "stat"
                    }
                },
                events = {},
                icon = "interface/icons/spell_holy_magicalsentry.blp",
                id = "ie5e25kl",
                maxStacks = 1,
                name = "Arcane Intellect",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Increases Intellect by 10%.",
                    bodyTokens = {},
                    stackingText = "",
                    stackingTokens = {},
                    version = 1
                }
            },
            {
                description = "",
                duration = 1,
                effects = {
                    {
                        cancelOnDamage = true,
                        forceAutoHitAgainstTarget = true,
                        movementRangeOverride = 0,
                        preventCasting = false,
                        type = "control"
                    }
                },
                events = {},
                icon = "interface/icons/spell_frost_freezingbreath.blp",
                id = "hlax2ypw",
                maxStacks = 1,
                name = "Frost Nova",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Breaks when the affected unit takes damage. Sets the affected unit's movement range to 0. Causes all attacks against the affected unit to automatically hit.",
                    bodyTokens = {},
                    stackingText = "",
                    stackingTokens = {},
                    version = 1
                }
            },
            {
                description = "",
                duration = 3,
                effects = {
                    {
                        baseAmount = -3,
                        operation = "flat",
                        statRef = "f82db71a:wbj4zuf3",
                        statScaling = {
                            {
                                coefficient = 0.01,
                                statRef = "f82db71a:7t7xgzcx"
                            }
                        },
                        type = "stat"
                    },
                    {
                        baseAmount = 3,
                        operation = "flat",
                        statRef = "f82db71a:dd88li4c",
                        statScaling = {
                            {
                                coefficient = 0.01,
                                statRef = "f82db71a:7t7xgzcx"
                            }
                        },
                        type = "stat"
                    }
                },
                events = {},
                icon = "interface/icons/spell_frost_frostbolt02.blp",
                id = "ddtdgrqi",
                maxStacks = 1,
                name = "Frostbolt",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Reduces Melee Hit Chance by 3%. Increases Ranged Hit Chance by 3%.",
                    bodyTokens = {},
                    stackingText = "",
                    stackingTokens = {},
                    version = 1
                }
            },
            {
                description = "The target can be frozen solid.",
                duration = 2,
                effects = {},
                events = {},
                icon = "interface/icons/spell_frost_iceshock.blp",
                id = "m5d3gzpj",
                maxStacks = 1,
                name = "Chilled",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "The target can be frozen solid.",
                    bodyTokens = {},
                    stackingText = "",
                    stackingTokens = {},
                    version = 1
                }
            },
            {
                description = "",
                duration = 1,
                effects = {
                    {
                        cancelOnDamage = false,
                        forceAutoHitAgainstTarget = true,
                        movementRangeOverride = 0,
                        preventCasting = true,
                        type = "control"
                    }
                },
                events = {},
                icon = "interface/icons/ability_mage_deepfreeze.blp",
                id = "2yaerkrk",
                maxStacks = 1,
                name = "Deep Freeze",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Prevents the affected unit from casting spells. Sets the affected unit's movement range to 0. Causes all attacks against the affected unit to automatically hit.",
                    bodyTokens = {},
                    stackingText = "",
                    stackingTokens = {},
                    version = 1
                }
            }
        },
        authorName = "Ortellus-ArgentDawn",
        classes = {
            {
                description = "Students gifted with a keen intellect and unwavering discipline may walk the path of the Mage. The arcane magic available to magi is both great and dangerous, and thus is revealed only to the most devoted practitioners. To avoid interference with their spellcasting, magi wear only cloth armor, but arcane shields and enchantments give them additional protection. To keep enemies at bay, magi can summon bursts of fire to incinerate distant targets and cause entire areas to erupt, setting groups of foes ablaze.",
                icon = "interface/icons/classicon_mage.blp",
                id = "02p0r8a2",
                name = "Mage",
                armorWeights = {
                    "cloth",
                },
                weaponTypeRefs = {
                    "f82db71a:z6nh3znw",
                    "f82db71a:y0dnlo8g",
                    "f82db71a:3y1v01e4",
                    "f82db71a:s4q9t5f3",
                },
                resourceProgressions = {
                    {
                        initialValue = 31,
                        perLevelValue = 22.53,
                        resourceRef = "f82db71a:q2ktkztt"
                    },
                    {
                        initialValue = 100,
                        perLevelValue = 19.88,
                        resourceRef = "f82db71a:4c8mfm99"
                    }
                },
                skillBonuses = {},
                statProgressions = {
                    {
                        initialValue = 0,
                        perLevelValue = 0.17,
                        statRef = "f82db71a:zfqm8dxp"
                    },
                    {
                        initialValue = 0,
                        perLevelValue = 0.25,
                        statRef = "f82db71a:xqz0daz2"
                    },
                    {
                        initialValue = 3,
                        perLevelValue = 1.73,
                        statRef = "f82db71a:75y3a8ib"
                    },
                    {
                        initialValue = 2,
                        perLevelValue = 1.66,
                        statRef = "f82db71a:kec9rhli"
                    },
                    {
                        initialValue = 0,
                        perLevelValue = 0.42,
                        statRef = "f82db71a:ygjno50i"
                    }
                },
                passiveTraitRefs = {
                    "d7c874c4:arcdecon"
                },
                talentTraitRefs = {
                    "d7c874c4:arcfocus",
                    "d7c874c4:magabsrb",
                    "d7c874c4:arcmind1",
                    "d7c874c4:arcinst3",
                    "d7c874c4:misbarge",
                    "d7c874c4:arcconc1",
                    "d7c874c4:mastelms"
                }
            }
        },
        currencies = {},
        damageSchools = {},
        datasetType = "class",
        dependencies = {
            "f82db71a"
        },
        description = "",
        groupName = "Core",
        guildSettings = {},
        id = "d7c874c4",
        interactions = {},
        itemSlots = {},
        items = {},
        loot = {},
        mounts = {},
        name = "Mage",
        pets = {},
        races = {},
        recipes = {},
        resources = {},
        skills = {},
        spells = {
            {
                allowDeadTargets = false,
                canMoveWhileCasting = false,
                castTime = 1,
                casterEvents = {
                    "on_spell_hit",
                    "on_critical_hit"
                },
                charges = 2,
                components = {
                    {
                        castPhase = "on_cast_end",
                        castingGroup = "default",
                        effect = {
                            alwaysHits = false,
                            amountMode = "flat",
                            applyAura = true,
                            auraRef = "d7c874c4:vtrjl3l2",
                            auraStacks = 1,
                            baseDamage = 114.75,
                            damageSchoolRefs = {
                                "f82db71a:esjguw6d"
                            },
                            damageType = "spell",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.595,
                                    statRef = "f82db71a:7t7xgzcx"
                                }
                            },
                            targetEvents = {
                                "on_spell_taken",
                                "on_critical_heal_taken"
                            },
                            threatCoefficient = 1,
                            type = "damage",
                            usesProjectile = false,
                            weaponDamageCoefficient = 1,
                            weaponDamageMode = "none"
                        },
                        key = "cc50e341",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 1,
                            minTargets = 1,
                            requiresTarget = true,
                            targetDisposition = "enemy",
                            type = "single"
                        }
                    }
                },
                conditions = {},
                cooldown = 1,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_fire_firebolt02.blp",
                id = "68dy7na1",
                cooldownChannel = 1,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Fireball",
                range = 0,
                resourceCosts = {
                    {
                        amount = 6.8,
                        amountMode = "base_percent",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:4c8mfm99"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Fire",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "d7c874c4:vtrjl3l2",
                            datasetId = "d7c874c4",
                            descriptionText = "Deals {AURA_DAMAGE_1} Fire damage each turn.",
                            icon = "interface/icons/spell_fire_firebolt02.blp",
                            nameText = "Fireball",
                            powerLevel = 0,
                            spellDatasetId = "d7c874c4",
                            stacks = 1,
                            targetContext = {
                                object = "the affected enemy",
                                possessive = "the affected enemy's",
                                reflexive = "itself",
                                subject = "the affected enemy"
                            },
                            tokens = {
                                {
                                    applyMode = "damage_amount",
                                    baseField = "baseDamage",
                                    effectIndex = 1,
                                    key = "AURA_DAMAGE_1",
                                    tokenType = "aura_amount"
                                }
                            }
                        }
                    },
                    mainText = "Deal {DAMAGE_1} Fire damage to an enemy and apply Fireball for 5 turns.",
                    tokens = {
                        {
                            applyMode = "damage_range",
                            componentIndex = 1,
                            key = "DAMAGE_1",
                            tokenType = "spell_damage_range"
                        }
                    },
                    version = 1
                },
                totalTicks = 0,
                useCooldownCharges = false
            },
            {
                allowDeadTargets = false,
                canMoveWhileCasting = false,
                castTime = 1,
                casterEvents = {
                    "on_spell_hit",
                    "on_critical_hit"
                },
                charges = 0,
                components = {
                    {
                        castPhase = "on_cast_end",
                        castingGroup = "default",
                        effect = {
                            alwaysHits = false,
                            amountMode = "flat",
                            applyAura = true,
                            auraRef = "d7c874c4:ghe969oh",
                            auraStacks = 1,
                            baseDamage = 258.188,
                            damageSchoolRefs = {
                                "f82db71a:esjguw6d"
                            },
                            damageType = "spell",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 1.339,
                                    statRef = "f82db71a:7t7xgzcx"
                                }
                            },
                            targetEvents = {
                                "on_spell_taken",
                                "on_critical_heal_taken"
                            },
                            threatCoefficient = 1,
                            type = "damage",
                            usesProjectile = false,
                            weaponDamageCoefficient = 1,
                            weaponDamageMode = "none"
                        },
                        key = "cc50e341",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 1,
                            minTargets = 1,
                            requiresTarget = true,
                            targetDisposition = "enemy",
                            type = "single"
                        }
                    }
                },
                conditions = {},
                cooldown = 0,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_fire_fireball02.blp",
                id = "kwn6xary",
                cooldownChannel = 1,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Pyroblast",
                range = 0,
                resourceCosts = {
                    {
                        amount = 31.8,
                        amountMode = "base_percent",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:4c8mfm99"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Fire",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "d7c874c4:ghe969oh",
                            datasetId = "d7c874c4",
                            descriptionText = "Deals {AURA_DAMAGE_1} Fire damage each turn.",
                            icon = "interface/icons/spell_fire_fireball02.blp",
                            nameText = "Pyroblast",
                            powerLevel = 0,
                            spellDatasetId = "d7c874c4",
                            stacks = 1,
                            targetContext = {
                                object = "the affected enemy",
                                possessive = "the affected enemy's",
                                reflexive = "itself",
                                subject = "the affected enemy"
                            },
                            tokens = {
                                {
                                    applyMode = "damage_amount",
                                    baseField = "baseDamage",
                                    effectIndex = 1,
                                    key = "AURA_DAMAGE_1",
                                    tokenType = "aura_amount"
                                }
                            }
                        }
                    },
                    mainText = "Deal {DAMAGE_1} Fire damage to an enemy and apply Pyroblast for 5 turns.",
                    tokens = {
                        {
                            applyMode = "damage_range",
                            componentIndex = 1,
                            key = "DAMAGE_1",
                            tokenType = "spell_damage_range"
                        }
                    },
                    version = 1
                },
                totalTicks = 0,
                useCooldownCharges = false
            },
            {
                allowDeadTargets = false,
                canMoveWhileCasting = false,
                castTime = 0,
                casterEvents = {
                    "on_spell_hit",
                    "on_critical_hit"
                },
                charges = 2,
                components = {
                    {
                        castPhase = "on_cast_end",
                        castingGroup = "default",
                        effect = {
                            alwaysHits = false,
                            amountMode = "flat",
                            applyAura = false,
                            auraRef = "d7c874c4:vtrjl3l2",
                            auraStacks = 1,
                            baseDamage = 65,
                            damageSchoolRefs = {
                                "f82db71a:esjguw6d"
                            },
                            damageType = "spell",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.325,
                                    statRef = "f82db71a:7t7xgzcx"
                                }
                            },
                            targetEvents = {
                                "on_spell_taken",
                                "on_critical_heal_taken"
                            },
                            threatCoefficient = 0.75,
                            type = "damage",
                            usesProjectile = false,
                            weaponDamageCoefficient = 1,
                            weaponDamageMode = "none"
                        },
                        key = "cc50e341",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 1,
                            minTargets = 1,
                            requiresTarget = true,
                            targetDisposition = "enemy",
                            type = "single"
                        }
                    }
                },
                conditions = {},
                cooldown = 5,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_fire_fireball.blp",
                id = "96ygwvhq",
                cooldownChannel = 2,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Fire Blast",
                range = 0,
                resourceCosts = {
                    {
                        amount = 6.8,
                        amountMode = "base_percent",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:4c8mfm99"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Fire",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {},
                    mainText = "Deal {DAMAGE_1} Fire damage to an enemy.",
                    tokens = {
                        {
                            applyMode = "damage_range",
                            componentIndex = 1,
                            key = "DAMAGE_1",
                            tokenType = "spell_damage_range"
                        }
                    },
                    version = 1
                },
                totalTicks = 0,
                useCooldownCharges = true
            },
            {
                allowDeadTargets = false,
                canMoveWhileCasting = false,
                castTime = 0,
                casterEvents = {
                    "on_spell_hit",
                    "on_critical_hit"
                },
                charges = 2,
                components = {
                    {
                        castPhase = "on_cast_end",
                        castingGroup = "default",
                        effect = {
                            alwaysHits = false,
                            amountMode = "flat",
                            applyAura = true,
                            auraRef = "d7c874c4:yxha70sc",
                            auraStacks = 1,
                            baseDamage = 85,
                            damageSchoolRefs = {
                                "f82db71a:esjguw6d"
                            },
                            damageType = "spell",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.425,
                                    statRef = "f82db71a:7t7xgzcx"
                                }
                            },
                            targetEvents = {
                                "on_spell_taken",
                                "on_critical_heal_taken"
                            },
                            threatCoefficient = 1,
                            type = "damage",
                            usesProjectile = false,
                            weaponDamageCoefficient = 1,
                            weaponDamageMode = "none"
                        },
                        key = "cc50e341",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 1,
                            minTargets = 1,
                            requiresTarget = true,
                            targetDisposition = "enemy",
                            type = "single"
                        }
                    }
                },
                conditions = {},
                cooldown = 1,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_fire_soulburn.blp",
                id = "hsr88j7d",
                cooldownChannel = 1,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Scorch",
                range = 0,
                resourceCosts = {
                    {
                        amount = 5,
                        amountMode = "base_percent",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:4c8mfm99"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Fire",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "d7c874c4:yxha70sc",
                            datasetId = "d7c874c4",
                            descriptionText = "Reduces Fire Resistance by 5%. Applies {AURA_APPLIED_STACKS_1} stacks. Stacks up to {AURA_MAX_STACKS_1} times.",
                            icon = "interface/icons/spell_fire_soulburn.blp",
                            nameText = "Scorch",
                            powerLevel = 0,
                            spellDatasetId = "d7c874c4",
                            stacks = 1,
                            targetContext = {
                                object = "the affected enemy",
                                possessive = "the affected enemy's",
                                reflexive = "itself",
                                subject = "the affected enemy"
                            },
                            tokens = {
                                {
                                    applyMode = "applied_stacks",
                                    key = "AURA_APPLIED_STACKS_1",
                                    tokenType = "aura_stacks"
                                },
                                {
                                    applyMode = "max_stacks",
                                    key = "AURA_MAX_STACKS_1",
                                    tokenType = "aura_stacks"
                                }
                            }
                        }
                    },
                    mainText = "Deal {DAMAGE_1} Fire damage to an enemy and apply Scorch for 5 turns.",
                    tokens = {
                        {
                            applyMode = "damage_range",
                            componentIndex = 1,
                            key = "DAMAGE_1",
                            tokenType = "spell_damage_range"
                        }
                    },
                    version = 1
                },
                totalTicks = 0,
                useCooldownCharges = false
            },
            {
                allowDeadTargets = false,
                canMoveWhileCasting = false,
                castTime = 0,
                casterEvents = {},
                charges = 0,
                components = {
                    {
                        castPhase = "on_cast_end",
                        castingGroup = "default",
                        effect = {
                            auraRef = "d7c874c4:ppxho9hn",
                            basePower = 0,
                            duration = 1,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "3f4493a0",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 0,
                            minTargets = 0,
                            requiresTarget = false,
                            targetDisposition = "ally",
                            type = "caster"
                        }
                    }
                },
                conditions = {},
                cooldown = 10,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_fire_sealoffire.blp",
                id = "m3u708kt",
                cooldownChannel = 3,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Combustion",
                range = 0,
                resourceCosts = {
                    {
                        amount = 5,
                        amountMode = "base_percent",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:4c8mfm99"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Fire",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "d7c874c4:ppxho9hn",
                            datasetId = "d7c874c4",
                            descriptionText = "Increases Spell Crit. Chance by 100%.",
                            duration = 1,
                            icon = "interface/icons/spell_fire_sealoffire.blp",
                            nameText = "Combustion",
                            powerLevel = 0,
                            spellDatasetId = "d7c874c4",
                            stacks = 1,
                            targetContext = {
                                object = "you",
                                possessive = "your",
                                reflexive = "yourself",
                                subject = "you"
                            },
                            tokens = {}
                        }
                    },
                    mainText = "Apply Combustion to yourself for 1 turn.",
                    tokens = {},
                    version = 1
                },
                totalTicks = 0,
                useCooldownCharges = false
            },
            {
                allowDeadTargets = false,
                canMoveWhileCasting = false,
                castTime = 1,
                casterEvents = {
                    "on_spell_hit"
                },
                charges = 0,
                components = {
                    {
                        castPhase = "on_cast_end",
                        castingGroup = "default",
                        effect = {
                            alwaysHits = false,
                            amountMode = "flat",
                            applyAura = false,
                            auraStacks = 1,
                            baseDamage = 60.75,
                            damageSchoolRefs = {
                                "f82db71a:esjguw6d"
                            },
                            damageType = "spell",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.315,
                                    statRef = "f82db71a:7t7xgzcx"
                                }
                            },
                            targetEvents = {
                                "on_spell_taken"
                            },
                            threatCoefficient = 1,
                            type = "damage",
                            usesProjectile = false,
                            weaponDamageCoefficient = 1,
                            weaponDamageMode = "none"
                        },
                        key = "acb2579e",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 5,
                            minTargets = 1,
                            requiresTarget = true,
                            targetDisposition = "enemy",
                            type = "raid_marker"
                        }
                    }
                },
                conditions = {},
                cooldown = 0,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_fire_selfdestruct.blp",
                id = "zilla37l",
                cooldownChannel = 1,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Flamestrike",
                range = 0,
                resourceCosts = {
                    {
                        amount = 12.3,
                        amountMode = "base_percent",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:4c8mfm99"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Fire",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {},
                    mainText = "Deal {DAMAGE_1} Fire damage to up to 5 enemies.\n|cff999999Targets must share the same raid marker.|r",
                    tokens = {
                        {
                            applyMode = "damage_range",
                            componentIndex = 1,
                            key = "DAMAGE_1",
                            tokenType = "spell_damage_range"
                        }
                    },
                    version = 1
                },
                totalTicks = 0,
                useCooldownCharges = false
            },
            {
                allowDeadTargets = false,
                canMoveWhileCasting = false,
                castTime = 0,
                casterEvents = {
                    "on_spell_hit"
                },
                charges = 0,
                components = {
                    {
                        castPhase = "on_cast_end",
                        castingGroup = "default",
                        effect = {
                            alwaysHits = false,
                            amountMode = "flat",
                            applyAura = false,
                            auraStacks = 1,
                            baseDamage = 45,
                            damageSchoolRefs = {
                                "f82db71a:dtxhglqg"
                            },
                            damageType = "spell",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.225,
                                    statRef = "f82db71a:7t7xgzcx"
                                }
                            },
                            targetEvents = {
                                "on_spell_taken"
                            },
                            threatCoefficient = 1,
                            type = "damage",
                            usesProjectile = false,
                            weaponDamageCoefficient = 1,
                            weaponDamageMode = "none"
                        },
                        key = "acb2579e",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 5,
                            minTargets = 1,
                            requiresTarget = true,
                            targetDisposition = "enemy",
                            type = "multi"
                        }
                    },
                    {
                        castPhase = "on_cast_end",
                        castingGroup = "default",
                        effect = {
                            amount = 1,
                            amountMode = "flat",
                            resourceRef = "f82db71a:v7uxqb9z",
                            targetEvents = {},
                            type = "resource"
                        },
                        key = "12ae1eda",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 0,
                            minTargets = 0,
                            requiresTarget = false,
                            targetDisposition = "ally",
                            type = "caster"
                        }
                    }
                },
                conditions = {},
                cooldown = 1,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_nature_wispsplode.blp",
                id = "1s5lq169",
                cooldownChannel = 1,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Arcane Explosion",
                range = 0,
                resourceCosts = {
                    {
                        amount = 18.1,
                        amountMode = "base_percent",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:4c8mfm99"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Arcane",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {},
                    mainText = "Deal {DAMAGE_1} Arcane damage to up to 5 enemies. Restore {RESOURCE_AMOUNT_1} to yourself.",
                    tokens = {
                        {
                            applyMode = "damage_range",
                            componentIndex = 1,
                            key = "DAMAGE_1",
                            tokenType = "spell_damage_range"
                        },
                        {
                            applyMode = "resource_gain_amount",
                            componentIndex = 2,
                            key = "RESOURCE_AMOUNT_1",
                            tokenType = "spell_resource_amount"
                        }
                    },
                    version = 1
                },
                totalTicks = 0,
                useCooldownCharges = false
            },
            {
                allowDeadTargets = false,
                canMoveWhileCasting = false,
                castTime = 0,
                casterEvents = {},
                charges = 0,
                components = {
                    {
                        castPhase = "on_cast_end",
                        castingGroup = "default",
                        effect = {
                            auraRef = "d7c874c4:frwdau01",
                            basePower = 0,
                            duration = 2,
                            stacks = 1,
                            targetEvents = {},
                            threatCoefficient = 0.38,
                            type = "apply_aura"
                        },
                        key = "fward001",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 0,
                            minTargets = 0,
                            requiresTarget = false,
                            targetDisposition = "ally",
                            type = "caster"
                        }
                    }
                },
                conditions = {},
                cooldown = 5,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_fire_firearmor.blp",
                id = "fireward",
                cooldownChannel = 3,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Fire Ward",
                range = 0,
                resourceCosts = {
                    {
                        amount = 15,
                        amountMode = "base_percent",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:4c8mfm99"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Fire",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "d7c874c4:frwdau01",
                            datasetId = "d7c874c4",
                            descriptionText = "Absorbs {AURA_ABSORB_1} Fire damage.",
                            duration = 2,
                            icon = "interface/icons/spell_fire_firearmor.blp",
                            nameText = "Fire Ward",
                            powerLevel = 0,
                            spellDatasetId = "d7c874c4",
                            stacks = 1,
                            targetContext = {
                                object = "you",
                                possessive = "your",
                                reflexive = "yourself",
                                subject = "you"
                            },
                            tokens = {
                                {
                                    applyMode = "absorb_amount",
                                    baseField = "baseAbsorption",
                                    effectIndex = 1,
                                    key = "AURA_ABSORB_1",
                                    tokenType = "aura_amount"
                                }
                            }
                        }
                    },
                    mainText = "Apply Fire Ward to yourself for 2 turns.",
                    tokens = {},
                    version = 1
                },
                totalTicks = 0,
                useCooldownCharges = false
            },
            {
                allowDeadTargets = false,
                canMoveWhileCasting = false,
                castTime = 0,
                casterEvents = {},
                charges = 0,
                components = {
                    {
                        castPhase = "on_cast_end",
                        castingGroup = "default",
                        effect = {
                            auraRef = "d7c874c4:fowdau01",
                            basePower = 0,
                            duration = 2,
                            stacks = 1,
                            targetEvents = {},
                            threatCoefficient = 0.38,
                            type = "apply_aura"
                        },
                        key = "fward002",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 0,
                            minTargets = 0,
                            requiresTarget = false,
                            targetDisposition = "ally",
                            type = "caster"
                        }
                    }
                },
                conditions = {},
                cooldown = 5,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_frost_frostward.blp",
                id = "frostwrd",
                cooldownChannel = 3,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Frost Ward",
                range = 0,
                resourceCosts = {
                    {
                        amount = 15,
                        amountMode = "base_percent",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:4c8mfm99"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Frost",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "d7c874c4:fowdau01",
                            datasetId = "d7c874c4",
                            descriptionText = "Absorbs {AURA_ABSORB_1} Frost damage.",
                            duration = 2,
                            icon = "interface/icons/spell_frost_frostward.blp",
                            nameText = "Frost Ward",
                            powerLevel = 0,
                            spellDatasetId = "d7c874c4",
                            stacks = 1,
                            targetContext = {
                                object = "you",
                                possessive = "your",
                                reflexive = "yourself",
                                subject = "you"
                            },
                            tokens = {
                                {
                                    applyMode = "absorb_amount",
                                    baseField = "baseAbsorption",
                                    effectIndex = 1,
                                    key = "AURA_ABSORB_1",
                                    tokenType = "aura_amount"
                                }
                            }
                        }
                    },
                    mainText = "Apply Frost Ward to yourself for 2 turns.",
                    tokens = {},
                    version = 1
                },
                totalTicks = 0,
                useCooldownCharges = false
            },
            {
                _resourceCostsByPhase = {
                    on_cast_end = {
                        {
                            amount = 6.8,
                            amountMode = "base_percent",
                            castPhase = "on_cast_end",
                            refundOnInterrupt = 0,
                            resourceRef = "f82db71a:4c8mfm99"
                        }
                    },
                    on_cast_start = {}
                },
                allowDeadTargets = false,
                canMoveWhileCasting = false,
                castTime = 1,
                casterEvents = {
                    "on_spell_hit",
                    "on_critical_hit"
                },
                charges = 2,
                components = {
                    {
                        castPhase = "on_cast_end",
                        castingGroup = "default",
                        effect = {
                            alwaysHits = false,
                            amountMode = "flat",
                            applyAura = false,
                            auraRef = "d7c874c4:vtrjl3l2",
                            auraStacks = 1,
                            baseDamage = 135,
                            damageSchoolRefs = {
                                "f82db71a:dtxhglqg"
                            },
                            damageType = "spell",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.7,
                                    statRef = "f82db71a:7t7xgzcx"
                                }
                            },
                            targetEvents = {
                                "on_spell_taken",
                                "on_critical_heal_taken"
                            },
                            threatCoefficient = 1,
                            type = "damage",
                            usesProjectile = false,
                            weaponDamageCoefficient = 1,
                            weaponDamageMode = "none"
                        },
                        key = "cc50e341",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 1,
                            minTargets = 1,
                            requiresTarget = true,
                            targetDisposition = "enemy",
                            type = "single"
                        }
                    },
                    {
                        castPhase = "on_cast_end",
                        castingGroup = "default",
                        effect = {
                            amount = 1,
                            amountMode = "flat",
                            resourceRef = "f82db71a:v7uxqb9z",
                            targetEvents = {},
                            type = "resource"
                        },
                        key = "5eb082d6",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 0,
                            minTargets = 0,
                            requiresTarget = false,
                            targetDisposition = "ally",
                            type = "caster"
                        }
                    }
                },
                conditions = {},
                cooldown = 1,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_arcane_blast.blp",
                id = "n6jbep9e",
                cooldownChannel = 1,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Arcane Blast",
                range = 0,
                resourceCosts = {
                    {
                        amount = 6.8,
                        amountMode = "base_percent",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:4c8mfm99"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Arcane",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {},
                    mainText = "Deal {DAMAGE_1} Arcane damage to an enemy. Restore {RESOURCE_AMOUNT_1} to yourself.",
                    tokens = {
                        {
                            applyMode = "damage_range",
                            componentIndex = 1,
                            key = "DAMAGE_1",
                            tokenType = "spell_damage_range"
                        },
                        {
                            applyMode = "resource_gain_amount",
                            componentIndex = 2,
                            key = "RESOURCE_AMOUNT_1",
                            tokenType = "spell_resource_amount"
                        }
                    },
                    version = 1
                },
                totalTicks = 0,
                useCooldownCharges = false
            },
            {
                allowDeadTargets = false,
                canMoveWhileCasting = false,
                castTime = 0,
                casterEvents = {
                    "on_spell_hit",
                    "on_critical_hit"
                },
                charges = 0,
                components = {
                    {
                        castPhase = "on_cast_end",
                        castingGroup = "default",
                        effect = {
                            alwaysHits = false,
                            amountMode = "flat",
                            applyAura = false,
                            auraStacks = 1,
                            baseDamage = 326.25,
                            damageSchoolRefs = {
                                "f82db71a:dtxhglqg"
                            },
                            damageType = "spell",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 1.631,
                                    statRef = "f82db71a:7t7xgzcx"
                                }
                            },
                            targetEvents = {
                                "on_spell_taken",
                                "on_critical_hit_taken"
                            },
                            threatCoefficient = 1,
                            type = "damage",
                            usesProjectile = false,
                            weaponDamageCoefficient = 1,
                            weaponDamageMode = "none"
                        },
                        key = "acb2579e",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 1,
                            minTargets = 1,
                            requiresTarget = true,
                            targetDisposition = "enemy",
                            type = "multi"
                        }
                    },
                    {
                        castPhase = "on_cast_end",
                        castingGroup = "default",
                        effect = {
                            auraRef = "d7c874c4:xq18639s",
                            basePower = 0,
                            duration = 5,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "de39115e",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 0,
                            minTargets = 0,
                            requiresTarget = false,
                            targetDisposition = "ally",
                            type = "caster"
                        }
                    }
                },
                conditions = {},
                cooldown = 0,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/ability_mage_arcanebarrage.blp",
                id = "r760qxbn",
                cooldownChannel = 2,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Arcane Barrage",
                range = 0,
                resourceCosts = {
                    {
                        amount = 4,
                        amountMode = "flat",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:v7uxqb9z"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Arcane",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "d7c874c4:xq18639s",
                            datasetId = "d7c874c4",
                            descriptionText = "Enables the use of Arcane Missiles. Applies {AURA_APPLIED_STACKS_1} stacks. Stacks up to {AURA_MAX_STACKS_1} times.",
                            duration = 5,
                            icon = "interface/icons/spell_arcane_arcane04.blp",
                            nameText = "Arcane Missiles",
                            powerLevel = 0,
                            spellDatasetId = "d7c874c4",
                            stacks = 1,
                            targetContext = {
                                object = "you",
                                possessive = "your",
                                reflexive = "yourself",
                                subject = "you"
                            },
                            tokens = {
                                {
                                    applyMode = "applied_stacks",
                                    key = "AURA_APPLIED_STACKS_1",
                                    tokenType = "aura_stacks"
                                },
                                {
                                    applyMode = "max_stacks",
                                    key = "AURA_MAX_STACKS_1",
                                    tokenType = "aura_stacks"
                                }
                            }
                        }
                    },
                    mainText = "Deal {DAMAGE_1} Arcane damage to an enemy. Apply Arcane Missiles to yourself for 5 turns.",
                    tokens = {
                        {
                            applyMode = "damage_range",
                            componentIndex = 1,
                            key = "DAMAGE_1",
                            tokenType = "spell_damage_range"
                        }
                    },
                    version = 1
                },
                totalTicks = 0,
                useCooldownCharges = false
            },
            {
                allowDeadTargets = false,
                canMoveWhileCasting = false,
                castTime = 0,
                casterEvents = {
                    "on_spell_hit",
                    "on_critical_hit"
                },
                charges = 0,
                components = {
                    {
                        castPhase = "on_cast_end",
                        castingGroup = "default",
                        effect = {
                            alwaysHits = true,
                            amountMode = "flat",
                            applyAura = false,
                            auraStacks = 1,
                            baseDamage = 100,
                            damageSchoolRefs = {
                                "f82db71a:dtxhglqg"
                            },
                            damageType = "spell",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.5,
                                    statRef = "f82db71a:7t7xgzcx"
                                }
                            },
                            targetEvents = {
                                "on_spell_taken",
                                "on_critical_hit_taken"
                            },
                            threatCoefficient = 0.49,
                            type = "damage",
                            usesProjectile = false,
                            weaponDamageCoefficient = 1,
                            weaponDamageMode = "none"
                        },
                        key = "0b4f975a",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 1,
                            minTargets = 1,
                            requiresTarget = true,
                            targetDisposition = "enemy",
                            type = "single"
                        }
                    },
                    {
                        castPhase = "on_cast_end",
                        castingGroup = "default",
                        effect = {
                            amount = 1,
                            amountMode = "flat",
                            resourceRef = "f82db71a:v7uxqb9z",
                            targetEvents = {},
                            type = "resource"
                        },
                        key = "f4c8b8d5",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 0,
                            minTargets = 0,
                            requiresTarget = false,
                            targetDisposition = "ally",
                            type = "caster"
                        }
                    },
                    {
                        castPhase = "on_cast_end",
                        castingGroup = "default",
                        effect = {
                            auraRef = "d7c874c4:xq18639s",
                            stacks = 1,
                            targetEvents = {},
                            type = "remove_aura"
                        },
                        key = "565c0715",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 0,
                            minTargets = 0,
                            requiresTarget = false,
                            targetDisposition = "ally",
                            type = "caster"
                        }
                    }
                },
                conditions = {
                    {
                        auraRef = "d7c874c4:xq18639s",
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Requires Arcane Missiles",
                        type = "aura_requirement",
                        unit = "caster"
                    }
                },
                cooldown = 0,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_arcane_arcane04.blp",
                id = "1e8l0iyi",
                cooldownChannel = 2,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Arcane Missiles",
                range = 0,
                resourceCosts = {
                    {
                        amount = 5,
                        amountMode = "base_percent",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:4c8mfm99"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Arcane",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {},
                    mainText = "Deal {DAMAGE_1} Arcane damage to an enemy. Restore {RESOURCE_AMOUNT_1} to yourself. Generates a low amount of threat.",
                    tokens = {
                        {
                            applyMode = "damage_range",
                            componentIndex = 1,
                            key = "DAMAGE_1",
                            tokenType = "spell_damage_range"
                        },
                        {
                            applyMode = "resource_gain_amount",
                            componentIndex = 2,
                            key = "RESOURCE_AMOUNT_1",
                            tokenType = "spell_resource_amount"
                        }
                    },
                    version = 1
                },
                totalTicks = 0,
                useCooldownCharges = false
            },
            {
                allowDeadTargets = false,
                canMoveWhileCasting = false,
                castTime = 0,
                casterEvents = {
                    "on_spell_hit",
                    "on_critical_hit"
                },
                charges = 0,
                components = {
                    {
                        castPhase = "on_cast_end",
                        castingGroup = "default",
                        effect = {
                            alwaysHits = false,
                            amountMode = "flat",
                            applyAura = false,
                            auraStacks = 1,
                            baseDamage = 416.5,
                            damageSchoolRefs = {
                                "f82db71a:dtxhglqg"
                            },
                            damageType = "spell",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 2.081,
                                    statRef = "f82db71a:7t7xgzcx"
                                }
                            },
                            targetEvents = {
                                "on_spell_taken",
                                "on_critical_hit_taken"
                            },
                            threatCoefficient = 1,
                            type = "damage",
                            usesProjectile = false,
                            weaponDamageCoefficient = 1,
                            weaponDamageMode = "none"
                        },
                        key = "c7a73068",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 1,
                            minTargets = 1,
                            requiresTarget = true,
                            targetDisposition = "enemy",
                            type = "single"
                        }
                    },
                    {
                        castPhase = "on_cast_end",
                        castingGroup = "default",
                        effect = {
                            auraRef = "d7c874c4:ezq64q0p",
                            basePower = 0,
                            duration = 10,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "d3b6656b",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 0,
                            minTargets = 0,
                            requiresTarget = false,
                            targetDisposition = "ally",
                            type = "caster"
                        }
                    }
                },
                conditions = {},
                cooldown = 10,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_arcane_arcanetorrent.blp",
                id = "7r260xa0",
                cooldownChannel = 3,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Arcane Surge",
                range = 0,
                resourceCosts = {
                    {
                        amount = 100,
                        amountMode = "max_percent",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:4c8mfm99"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Arcane",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "d7c874c4:ezq64q0p",
                            datasetId = "d7c874c4",
                            descriptionText = "Restores 8% of Max Mana each turn.",
                            duration = 10,
                            icon = "interface/icons/spell_arcane_arcanetorrent.blp",
                            nameText = "Arcane Surge",
                            powerLevel = 0,
                            spellDatasetId = "d7c874c4",
                            stacks = 1,
                            targetContext = {
                                object = "you",
                                possessive = "your",
                                reflexive = "yourself",
                                subject = "you"
                            },
                            tokens = {}
                        }
                    },
                    mainText = "Deal {DAMAGE_1} Arcane damage to an enemy. Apply Arcane Surge to yourself for 10 turns.",
                    tokens = {
                        {
                            applyMode = "damage_range",
                            componentIndex = 1,
                            key = "DAMAGE_1",
                            tokenType = "spell_damage_range"
                        }
                    },
                    version = 1
                },
                totalTicks = 0,
                useCooldownCharges = false
            },
            {
                allowDeadTargets = false,
                canMoveWhileCasting = false,
                castTime = 1,
                casterEvents = {},
                charges = 0,
                components = {
                    {
                        castPhase = "on_cast_end",
                        castingGroup = "default",
                        effect = {
                            amount = 100,
                            amountMode = "base_percent",
                            resourceRef = "f82db71a:4c8mfm99",
                            targetEvents = {},
                            type = "resource"
                        },
                        key = "e387f510",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 0,
                            minTargets = 0,
                            requiresTarget = false,
                            targetDisposition = "ally",
                            type = "caster"
                        }
                    }
                },
                conditions = {},
                cooldown = 10,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_nature_purge.blp",
                id = "s9nxh61d",
                cooldownChannel = 1,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Evocation",
                range = 0,
                resourceCosts = {},
                seedNPCSpell = false,
                spellbookCategory = "Arcane",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {},
                    mainText = "Restore 100% of Base Mana to yourself.",
                    tokens = {},
                    version = 1
                },
                totalTicks = 0,
                useCooldownCharges = false
            },
            {
                _resourceCostsByPhase = {
                    on_cast_end = {
                        {
                            amount = 5,
                            amountMode = "base_percent",
                            castPhase = "on_cast_end",
                            refundOnInterrupt = 0,
                            resourceRef = "f82db71a:4c8mfm99"
                        }
                    },
                    on_cast_start = {}
                },
                allowDeadTargets = false,
                canMoveWhileCasting = false,
                castTime = 0,
                casterEvents = {},
                charges = 0,
                components = {
                    {
                        castPhase = "on_cast_end",
                        castingGroup = "default",
                        effect = {
                            targetEvents = {},
                            type = "interrupt"
                        },
                        key = "b88a1052",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 1,
                            minTargets = 1,
                            requiresTarget = true,
                            targetDisposition = "enemy",
                            type = "single"
                        }
                    }
                },
                conditions = {},
                cooldown = 10,
                cooldownGroup = "interrupt",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_frost_iceshock.blp",
                id = "300h0gls",
                cooldownChannel = 5,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Counterspell",
                range = 0,
                resourceCosts = {
                    {
                        amount = 5,
                        amountMode = "base_percent",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:4c8mfm99"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Arcane",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {},
                    mainText = "Interrupt an enemy's spellcasting.",
                    tokens = {},
                    version = 1
                },
                totalTicks = 0,
                useCooldownCharges = false
            },
            {
                allowDeadTargets = false,
                canMoveWhileCasting = false,
                castTime = 0,
                casterEvents = {},
                charges = 0,
                components = {
                    {
                        castPhase = "on_cast_end",
                        castingGroup = "default",
                        effect = {
                            auraRef = "d7c874c4:ie5e25kl",
                            basePower = 0,
                            duration = 10,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "b5ee2467",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 0,
                            minTargets = 1,
                            requiresTarget = true,
                            targetDisposition = "ally",
                            type = "all_allies"
                        }
                    }
                },
                conditions = {},
                cooldown = 0,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_holy_magicalsentry.blp",
                id = "7ldwq2a9",
                cooldownChannel = 3,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Arcane Intellect",
                range = 0,
                resourceCosts = {
                    {
                        amount = 5,
                        amountMode = "base_percent",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:4c8mfm99"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Arcane",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "d7c874c4:ie5e25kl",
                            datasetId = "d7c874c4",
                            descriptionText = "Increases Intellect by 10%.",
                            duration = 10,
                            icon = "interface/icons/spell_holy_magicalsentry.blp",
                            nameText = "Arcane Intellect",
                            powerLevel = 0,
                            spellDatasetId = "d7c874c4",
                            stacks = 1,
                            targetContext = {
                                object = "all allies",
                                possessive = "all allies'",
                                reflexive = "themselves",
                                subject = "all allies"
                            },
                            tokens = {}
                        }
                    },
                    mainText = "Apply Arcane Intellect to all allies for 10 turns.",
                    tokens = {},
                    version = 1
                },
                totalTicks = 0,
                useCooldownCharges = false
            },
            {
                allowDeadTargets = false,
                canMoveWhileCasting = false,
                castTime = 1,
                casterEvents = {
                    "on_spell_hit",
                    "on_critical_hit"
                },
                charges = 0,
                components = {
                    {
                        castPhase = "on_cast_end",
                        castingGroup = "default",
                        effect = {
                            alwaysHits = false,
                            amountMode = "flat",
                            applyAura = true,
                            auraRef = "d7c874c4:ddtdgrqi",
                            auraStacks = 1,
                            baseDamage = 114.75,
                            damageSchoolRefs = {
                                "f82db71a:hx7pnwv4"
                            },
                            damageType = "spell",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.595,
                                    statRef = "f82db71a:7t7xgzcx"
                                }
                            },
                            targetEvents = {
                                "on_spell_taken",
                                "on_critical_hit_taken"
                            },
                            threatCoefficient = 1,
                            type = "damage",
                            usesProjectile = false,
                            weaponDamageCoefficient = 1,
                            weaponDamageMode = "none"
                        },
                        key = "1d9655af",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 1,
                            minTargets = 1,
                            requiresTarget = true,
                            targetDisposition = "enemy",
                            type = "single"
                        }
                    },
                    {
                        castPhase = "on_cast_end",
                        castingGroup = "default",
                        effect = {
                            auraRef = "d7c874c4:m5d3gzpj",
                            basePower = 0,
                            duration = 2,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "1b502bff",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 1,
                            minTargets = 1,
                            requiresTarget = true,
                            targetDisposition = "enemy",
                            type = "single"
                        }
                    }
                },
                conditions = {},
                cooldown = 0,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_frost_frostbolt02.blp",
                id = "lywroiqu",
                cooldownChannel = 1,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Frostbolt",
                range = 0,
                resourceCosts = {
                    {
                        amount = 6.8,
                        amountMode = "base_percent",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:4c8mfm99"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Frost",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "d7c874c4:ddtdgrqi",
                            datasetId = "d7c874c4",
                            descriptionText = "Reduces Melee Hit Chance by 3%. Increases Ranged Hit Chance by 3%.",
                            icon = "interface/icons/spell_frost_frostbolt02.blp",
                            nameText = "Frostbolt",
                            powerLevel = 0,
                            spellDatasetId = "d7c874c4",
                            stacks = 1,
                            targetContext = {
                                object = "the affected enemy",
                                possessive = "the affected enemy's",
                                reflexive = "itself",
                                subject = "the affected enemy"
                            },
                            tokens = {}
                        },
                        {
                            auraRef = "d7c874c4:m5d3gzpj",
                            datasetId = "d7c874c4",
                            descriptionText = "The target can be frozen solid.",
                            duration = 2,
                            icon = "interface/icons/spell_frost_iceshock.blp",
                            nameText = "Chilled",
                            powerLevel = 0,
                            spellDatasetId = "d7c874c4",
                            stacks = 1,
                            targetContext = {
                                object = "the affected enemy",
                                possessive = "the affected enemy's",
                                reflexive = "itself",
                                subject = "the affected enemy"
                            },
                            tokens = {}
                        }
                    },
                    mainText = "Deal {DAMAGE_1} Frost damage to an enemy and apply Frostbolt for 3 turns. Apply Chilled to an enemy for 2 turns.",
                    tokens = {
                        {
                            applyMode = "damage_range",
                            componentIndex = 1,
                            key = "DAMAGE_1",
                            tokenType = "spell_damage_range"
                        }
                    },
                    version = 1
                },
                totalTicks = 0,
                useCooldownCharges = false
            },
            {
                allowDeadTargets = false,
                canMoveWhileCasting = false,
                castTime = 0,
                casterEvents = {
                    "on_spell_hit"
                },
                charges = 0,
                components = {
                    {
                        castPhase = "on_cast_end",
                        castingGroup = "default",
                        effect = {
                            alwaysHits = false,
                            amountMode = "flat",
                            applyAura = true,
                            auraRef = "d7c874c4:hlax2ypw",
                            auraStacks = 1,
                            baseDamage = 32.321,
                            damageSchoolRefs = {
                                "f82db71a:hx7pnwv4"
                            },
                            damageType = "spell",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.162,
                                    statRef = "f82db71a:7t7xgzcx"
                                }
                            },
                            targetEvents = {
                                "on_spell_taken"
                            },
                            threatCoefficient = 0.75,
                            type = "damage",
                            usesProjectile = false,
                            weaponDamageCoefficient = 1,
                            weaponDamageMode = "none"
                        },
                        key = "acb2579e",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 5,
                            minTargets = 1,
                            requiresTarget = true,
                            targetDisposition = "enemy",
                            type = "multi"
                        }
                    }
                },
                conditions = {},
                cooldown = 10,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_frost_freezingbreath.blp",
                id = "7ha8pdoy",
                cooldownChannel = 2,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Frost Nova",
                range = 0,
                resourceCosts = {
                    {
                        amount = 12.3,
                        amountMode = "base_percent",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:4c8mfm99"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Frost",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "d7c874c4:hlax2ypw",
                            datasetId = "d7c874c4",
                            descriptionText = "Breaks when the affected unit takes damage. Sets the affected unit's movement range to 0. Causes all attacks against the affected unit to automatically hit.",
                            icon = "interface/icons/spell_frost_freezingbreath.blp",
                            nameText = "Frost Nova",
                            powerLevel = 0,
                            spellDatasetId = "d7c874c4",
                            stacks = 1,
                            targetContext = {
                                object = "the affected enemy",
                                possessive = "the affected enemy's",
                                reflexive = "itself",
                                subject = "the affected enemy"
                            },
                            tokens = {}
                        }
                    },
                    mainText = "Deal {DAMAGE_1} Frost damage to up to 5 enemies and apply Frost Nova for 1 turn.",
                    tokens = {
                        {
                            applyMode = "damage_range",
                            componentIndex = 1,
                            key = "DAMAGE_1",
                            tokenType = "spell_damage_range"
                        }
                    },
                    version = 1
                },
                totalTicks = 0,
                useCooldownCharges = false
            },
            {
                allowDeadTargets = false,
                canMoveWhileCasting = false,
                castTime = 0,
                casterEvents = {},
                charges = 0,
                components = {
                    {
                        castPhase = "on_cast_end",
                        castingGroup = "default",
                        effect = {
                            auraRef = "d7c874c4:2yaerkrk",
                            basePower = 0,
                            duration = 1,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "20f41d9c",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 1,
                            minTargets = 1,
                            requiresTarget = true,
                            targetDisposition = "enemy",
                            type = "single"
                        }
                    }
                },
                conditions = {
                    {
                        auraRef = "d7c874c4:m5d3gzpj",
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Target must be Chilled",
                        type = "aura_requirement",
                        unit = "target"
                    }
                },
                cooldown = 10,
                cooldownGroup = "stun",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/ability_mage_deepfreeze.blp",
                id = "5p4lvyfy",
                cooldownChannel = 2,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Deep Freeze",
                range = 0,
                resourceCosts = {
                    {
                        amount = 5,
                        amountMode = "base_percent",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:4c8mfm99"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Frost",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "d7c874c4:2yaerkrk",
                            datasetId = "d7c874c4",
                            descriptionText = "Prevents the affected unit from casting spells. Sets the affected unit's movement range to 0. Causes all attacks against the affected unit to automatically hit.",
                            duration = 1,
                            icon = "interface/icons/ability_mage_deepfreeze.blp",
                            nameText = "Deep Freeze",
                            powerLevel = 0,
                            spellDatasetId = "d7c874c4",
                            stacks = 1,
                            targetContext = {
                                object = "the affected enemy",
                                possessive = "the affected enemy's",
                                reflexive = "itself",
                                subject = "the affected enemy"
                            },
                            tokens = {}
                        }
                    },
                    mainText = "Apply Deep Freeze to an enemy for 1 turn.",
                    tokens = {},
                    version = 1
                },
                totalTicks = 0,
                useCooldownCharges = false
            },
            {
                allowDeadTargets = false,
                canMoveWhileCasting = false,
                castTime = 0,
                casterEvents = {
                    "on_spell_hit",
                    "on_critical_hit"
                },
                charges = 0,
                components = {
                    {
                        castPhase = "on_cast_end",
                        castingGroup = "default",
                        effect = {
                            alwaysHits = false,
                            amountMode = "flat",
                            applyAura = false,
                            auraStacks = 1,
                            baseDamage = 104,
                            damageSchoolRefs = {
                                "f82db71a:hx7pnwv4"
                            },
                            damageType = "spell",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.52,
                                    statRef = "f82db71a:7t7xgzcx"
                                }
                            },
                            targetEvents = {
                                "on_spell_taken",
                                "on_critical_hit_taken"
                            },
                            threatCoefficient = 1,
                            type = "damage",
                            usesProjectile = false,
                            weaponDamageCoefficient = 1,
                            weaponDamageMode = "none"
                        },
                        key = "20f41d9c",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 1,
                            minTargets = 1,
                            requiresTarget = true,
                            targetDisposition = "enemy",
                            type = "single"
                        }
                    }
                },
                conditions = {
                    {
                        auraRef = "d7c874c4:m5d3gzpj",
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Target must be Chilled",
                        type = "aura_requirement",
                        unit = "target"
                    }
                },
                cooldown = 1,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_frost_chillingblast.blp",
                id = "4yxpy77f",
                cooldownChannel = 2,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Ice Lance",
                range = 0,
                resourceCosts = {
                    {
                        amount = 6.3,
                        amountMode = "base_percent",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:4c8mfm99"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Frost",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {},
                    mainText = "Deal {DAMAGE_1} Frost damage to an enemy.",
                    tokens = {
                        {
                            applyMode = "damage_range",
                            componentIndex = 1,
                            key = "DAMAGE_1",
                            tokenType = "spell_damage_range"
                        }
                    },
                    version = 1
                },
                totalTicks = 0,
                useCooldownCharges = false
            },
            {
                allowDeadTargets = false,
                canMoveWhileCasting = false,
                castTime = 0,
                casterEvents = {
                    "on_spell_hit"
                },
                charges = 0,
                components = {
                    {
                        castPhase = "on_cast_end",
                        castingGroup = "default",
                        effect = {
                            alwaysHits = false,
                            amountMode = "flat",
                            applyAura = true,
                            auraRef = "d7c874c4:m5d3gzpj",
                            auraStacks = 1,
                            baseDamage = 61.2,
                            damageSchoolRefs = {
                                "f82db71a:hx7pnwv4"
                            },
                            damageType = "spell",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.306,
                                    statRef = "f82db71a:7t7xgzcx"
                                }
                            },
                            targetEvents = {
                                "on_spell_taken"
                            },
                            threatCoefficient = 1,
                            type = "damage",
                            usesProjectile = false,
                            weaponDamageCoefficient = 1,
                            weaponDamageMode = "none"
                        },
                        key = "acb2579e",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 5,
                            minTargets = 1,
                            requiresTarget = true,
                            targetDisposition = "enemy",
                            type = "multi"
                        }
                    }
                },
                conditions = {},
                cooldown = 5,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_frost_glacier.blp",
                id = "apgdbmji",
                cooldownChannel = 1,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Cone of Cold",
                range = 0,
                resourceCosts = {
                    {
                        amount = 18.1,
                        amountMode = "base_percent",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:4c8mfm99"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Frost",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "d7c874c4:m5d3gzpj",
                            datasetId = "d7c874c4",
                            descriptionText = "The target can be frozen solid.",
                            icon = "interface/icons/spell_frost_iceshock.blp",
                            nameText = "Chilled",
                            powerLevel = 0,
                            spellDatasetId = "d7c874c4",
                            stacks = 1,
                            targetContext = {
                                object = "the affected enemy",
                                possessive = "the affected enemy's",
                                reflexive = "itself",
                                subject = "the affected enemy"
                            },
                            tokens = {}
                        }
                    },
                    mainText = "Deal {DAMAGE_1} Frost damage to up to 5 enemies and apply Chilled for 2 turns.",
                    tokens = {
                        {
                            applyMode = "damage_range",
                            componentIndex = 1,
                            key = "DAMAGE_1",
                            tokenType = "spell_damage_range"
                        }
                    },
                    version = 1
                },
                totalTicks = 0,
                useCooldownCharges = false
            },
            {
                allowDeadTargets = false,
                canMoveWhileCasting = false,
                castTime = 1,
                casterEvents = {
                    "on_spell_hit",
                    "on_critical_hit"
                },
                charges = 0,
                components = {
                    {
                        castPhase = "on_cast_end",
                        castingGroup = "default",
                        effect = {
                            alwaysHits = false,
                            amountMode = "flat",
                            applyAura = false,
                            auraRef = "d7c874c4:ddtdgrqi",
                            auraStacks = 1,
                            baseDamage = 486,
                            damageSchoolRefs = {
                                "f82db71a:hx7pnwv4"
                            },
                            damageType = "spell",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 2.52,
                                    statRef = "f82db71a:7t7xgzcx"
                                }
                            },
                            targetEvents = {
                                "on_spell_taken",
                                "on_critical_hit_taken"
                            },
                            threatCoefficient = 1,
                            type = "damage",
                            usesProjectile = false,
                            weaponDamageCoefficient = 1,
                            weaponDamageMode = "none"
                        },
                        key = "1d9655af",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 1,
                            minTargets = 1,
                            requiresTarget = true,
                            targetDisposition = "enemy",
                            type = "single"
                        }
                    }
                },
                conditions = {
                    {
                        auraRef = "d7c874c4:m5d3gzpj",
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Target must be Chilled",
                        type = "aura_requirement",
                        unit = "target"
                    }
                },
                cooldown = 1,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/ability_mage_glacialspike.blp",
                id = "jg39ti4j",
                cooldownChannel = 1,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Glacial Spike",
                range = 0,
                resourceCosts = {
                    {
                        amount = 31.8,
                        amountMode = "base_percent",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:4c8mfm99"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Frost",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {},
                    mainText = "Deal {DAMAGE_1} Frost damage to an enemy.",
                    tokens = {
                        {
                            applyMode = "damage_range",
                            componentIndex = 1,
                            key = "DAMAGE_1",
                            tokenType = "spell_damage_range"
                        }
                    },
                    version = 1
                },
                totalTicks = 0,
                useCooldownCharges = false
            }
        },
        stats = {},
        traits = {
            {
                automaticAuras = {},
                category = "",
                conditions = {},
                description = "Increases your damage against Elementals by 5%.",
                events = {},
                icon = "interface/icons/spell_arcane_arcane04.blp",
                id = "arcdecon",
                isEnvironmental = false,
                name = "Arcane Deconstruction",
                skillBonuses = {},
                statBonuses = {
                    {
                        statRef = "f82db71a:bh4yvi9u",
                        value = 5
                    }
                },
                unlockLevel = 1
            },
            {
                automaticAuras = {},
                category = "",
                conditions = {},
                description = "",
                events = {
                    {
                        combatEventId = "on_critical_hit",
                        effects = {
                            {
                                auraRef = "d7c874c4:xq18639s",
                                basePower = 0,
                                duration = 5,
                                stacks = 1,
                                type = "apply_aura"
                            }
                        },
                        triggerTarget = "aura_caster"
                    }
                },
                icon = "interface/icons/spell_arcane_arcane04.blp",
                id = "0ih4ypms",
                isEnvironmental = false,
                name = "Arcane Attunement",
                skillBonuses = {},
                statBonuses = {},
                unlockLevel = 1
            },
            {
                automaticAuras = {},
                category = "Arcane",
                conditions = {},
                description = "",
                events = {},
                icon = "interface/icons/spell_holy_devotion.blp",
                id = "arcfocus",
                isEnvironmental = false,
                name = "Arcane Focus",
                skillBonuses = {},
                statBonuses = {
                    {
                        statRef = "f82db71a:v2g0tw0o",
                        value = 3
                    }
                },
                unlockLevel = 1
            },
            {
                automaticAuras = {},
                category = "Arcane",
                conditions = {},
                description = "",
                events = {
                    {
                        combatEventId = "on_critical_hit",
                        effects = {
                            {
                                amount = 10,
                                amountMode = "base_percent",
                                resourceRef = "f82db71a:4c8mfm99",
                                type = "resource"
                            }
                        },
                        triggerTarget = "event_source"
                    }
                },
                icon = "interface/icons/spell_fire_masterofelements.blp",
                id = "mastelms",
                isEnvironmental = false,
                name = "Master of Elements",
                skillBonuses = {},
                statBonuses = {},
                unlockLevel = 1
            },
            {
                automaticAuras = {},
                category = "Arcane",
                conditions = {
                    {
                        invert = true,
                        showOnTooltip = true,
                        tooltipTextOverride = "Does not have Arcane Concentration",
                        traitRef = "d7c874c4:arcconc1",
                        type = "trait_requirement",
                        unit = "caster"
                    }
                },
                description = "When you hit with a spell, you have a 25% chance to gain Arcane Missiles for 5 turns.",
                events = {
                    {
                        chance = 25,
                        combatEventId = "on_spell_hit",
                        effects = {
                            {
                                auraRef = "d7c874c4:xq18639s",
                                basePower = 0,
                                duration = 5,
                                stacks = 1,
                                type = "apply_aura"
                            }
                        },
                        triggerTarget = "aura_caster"
                    }
                },
                icon = "interface/icons/ability_mage_missilebarrage.blp",
                id = "misbarge",
                isEnvironmental = false,
                name = "Missile Barrage",
                skillBonuses = {},
                statBonuses = {},
                unlockLevel = 1
            },
            {
                automaticAuras = {},
                category = "Arcane",
                conditions = {
                    {
                        invert = true,
                        showOnTooltip = true,
                        tooltipTextOverride = "Does not have Missile Barrage",
                        traitRef = "d7c874c4:misbarge",
                        type = "trait_requirement",
                        unit = "caster"
                    }
                },
                description = "When you hit with a spell, you have a 20% chance to gain 1 Arcane Charge.",
                events = {
                    {
                        chance = 20,
                        combatEventId = "on_spell_hit",
                        effects = {
                            {
                                amount = 1,
                                amountMode = "flat",
                                resourceRef = "f82db71a:v7uxqb9z",
                                type = "resource"
                            }
                        },
                        triggerTarget = "aura_caster"
                    }
                },
                icon = "interface/icons/spell_shadow_manaburn.blp",
                id = "arcconc1",
                isEnvironmental = false,
                name = "Arcane Concentration",
                skillBonuses = {},
                statBonuses = {},
                unlockLevel = 1
            },
            {
                automaticAuras = {},
                category = "Arcane",
                conditions = {},
                description = "",
                events = {
                    {
                        combatEventId = "on_spell_taken",
                        effects = {
                            {
                                amount = 5,
                                amountMode = "base_percent",
                                resourceRef = "f82db71a:4c8mfm99",
                                type = "resource"
                            }
                        },
                        triggerTarget = "aura_caster"
                    }
                },
                icon = "interface/icons/spell_nature_astralrecalgroup.blp",
                id = "magabsrb",
                isEnvironmental = false,
                name = "Magic Absorption",
                skillBonuses = {},
                statBonuses = {
                    {
                        statRef = "f82db71a:zs1nbz13",
                        value = 3
                    }
                },
                unlockLevel = 1
            },
            {
                automaticAuras = {},
                category = "Arcane",
                conditions = {},
                description = "",
                events = {},
                icon = "interface/icons/spell_shadow_charm.blp",
                id = "arcmind1",
                isEnvironmental = false,
                name = "Arcane Mind",
                skillBonuses = {},
                statBonuses = {
                    {
                        operation = "percent",
                        statRef = "f82db71a:75y3a8ib",
                        value = 10
                    }
                },
                unlockLevel = 1
            },
            {
                automaticAuras = {},
                category = "Arcane",
                conditions = {},
                description = "",
                events = {},
                icon = "interface/icons/spell_shadow_teleport.blp",
                id = "arcinst3",
                isEnvironmental = false,
                name = "Arcane Instability",
                skillBonuses = {},
                statBonuses = {
                    {
                        statRef = "f82db71a:69hfqhne",
                        value = 3
                    },
                    {
                        operation = "percent",
                        statRef = "f82db71a:7t7xgzcx",
                        value = 3
                    }
                },
                unlockLevel = 1
            },
            {
                automaticAuras = {},
                category = "Frost",
                conditions = {},
                description = "Increases armor by 100% and Frost Resistance by 30. On melee hit taken, apply Chilled to the attacker.",
                events = {
                    {
                        combatEventId = "on_melee_taken",
                        effects = {
                            {
                                auraRef = "d7c874c4:m5d3gzpj",
                                basePower = 0,
                                duration = 2,
                                stacks = 1,
                                type = "apply_aura"
                            }
                        },
                        triggerTarget = "event_source"
                    }
                },
                icon = "interface/icons/spell_frost_frostarmor02.blp",
                id = "icearm01",
                isEnvironmental = false,
                name = "Ice Armor",
                skillBonuses = {},
                statBonuses = {
                    {
                        operation = "percent",
                        statRef = "f82db71a:v42albuv",
                        value = 100
                    },
                    {
                        statRef = "f82db71a:jjn0my8k",
                        value = 30
                    }
                },
                unlockLevel = 1
            }
        },
        units = {},
        weaponTypes = {}
    },
})
