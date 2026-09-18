local _, Addon = ...

Addon.Data.DefaultDatasets:Register({
    version = 19,
    dataset = {
        achievements = {},
        auras = {
            {
                description = "",
                duration = 10,
                effects = {
                    {
                        baseAmount = 5,
                        operation = "percent",
                        statRef = "f82db71a:ygjno50i",
                        statScaling = {},
                        type = "stat"
                    }
                },
                events = {},
                icon = "interface/icons/spell_holy_wordfortitude.blp",
                id = "cqblzgiw",
                maxStacks = 1,
                name = "Prayer of Fortitude",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Increases Stamina by 5%.",
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
                        baseAmount = 60,
                        operation = "flat",
                        statRef = "f82db71a:itpo751d",
                        statScaling = {},
                        type = "stat"
                    }
                },
                events = {},
                icon = "interface/icons/spell_holy_prayerofshadowprotection.blp",
                id = "sjzm0cbf",
                maxStacks = 1,
                name = "Prayer of Shadow Protection",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Increases Shadow Resistance by {AURA_STAT_1}.",
                    bodyTokens = {
                        {
                            applyMode = "stat_amount",
                            baseField = "baseAmount",
                            effectIndex = 1,
                            key = "AURA_STAT_1",
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
                duration = 10,
                effects = {
                    {
                        baseAmount = 10,
                        operation = "percent",
                        statRef = "f82db71a:kec9rhli",
                        statScaling = {},
                        type = "stat"
                    }
                },
                events = {},
                icon = "interface/icons/spell_holy_divinespirit.blp",
                id = "nihyfz0x",
                maxStacks = 1,
                name = "Divine Spirit",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Increases Spirit by 10%.",
                    bodyTokens = {},
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
                        baseHealing = 20.8,
                        statScaling = {
                            {
                                coefficient = 0.1248,
                                statRef = "f82db71a:hj6d4kvy"
                            }
                        },
                        type = "heal"
                    }
                },
                events = {},
                icon = "interface/icons/spell_holy_renew.blp",
                id = "a84ux6v9",
                maxStacks = 1,
                name = "Renew",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Heals for {AURA_HEAL_1} health each turn.",
                    bodyTokens = {
                        {
                            applyMode = "heal_amount",
                            baseField = "baseHealing",
                            effectIndex = 1,
                            key = "AURA_HEAL_1",
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
                        baseAbsorption = 104,
                        damageSchoolRefs = {},
                        statScaling = {
                            {
                                coefficient = 0.624,
                                statRef = "f82db71a:hj6d4kvy"
                            }
                        },
                        type = "absorb"
                    }
                },
                events = {},
                icon = "interface/icons/spell_holy_powerwordshield.blp",
                id = "pwrshld1",
                maxStacks = 1,
                name = "Power Word: Shield",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Absorbs {AURA_ABSORB_1} damage.",
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
                duration = 3,
                effects = {
                    {
                        amountMode = "flat",
                        baseDamage = 16.7592,
                        damageSchoolRefs = {
                            "f82db71a:wwctys5s"
                        },
                        statScaling = {
                            {
                                coefficient = 0.0838,
                                statRef = "f82db71a:7t7xgzcx"
                            }
                        },
                        type = "damage"
                    }
                },
                events = {},
                icon = "interface/icons/spell_holy_searinglight.blp",
                id = "bgmk5vpf",
                maxStacks = 1,
                name = "Holy Fire",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Deals {AURA_DAMAGE_1} Holy damage each turn.",
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
                duration = 1,
                effects = {
                    {
                        baseAmount = 40,
                        operation = "flat",
                        statRef = "f82db71a:pu05li08",
                        statScaling = {},
                        type = "stat"
                    }
                },
                events = {},
                icon = "interface/icons/spell_holy_painsupression.blp",
                id = "tx866rqz",
                maxStacks = 1,
                name = "Pain Suppression",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Increases Damage Reduction by 40%.",
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
                        cancelOnDamage = true,
                        forceAutoHitAgainstTarget = false,
                        preventCasting = true,
                        type = "control"
                    }
                },
                events = {},
                icon = "interface/icons/spell_shadow_psychicscream.blp",
                id = "1hbbqcre",
                maxStacks = 1,
                name = "Psychic Scream",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Breaks when the affected unit takes damage. Prevents the affected unit from casting spells.",
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
                        preventCasting = true,
                        type = "control"
                    }
                },
                events = {},
                icon = "interface/icons/spell_shadow_psychicscream.blp",
                id = "20ll5azr",
                maxStacks = 1,
                name = "Psychic Horror",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Breaks when the affected unit takes damage. Prevents the affected unit from casting spells. Sets the affected unit's movement range to 0. Causes all attacks against the affected unit to automatically hit.",
                    bodyTokens = {},
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
                        baseDamage = 20.8,
                        damageSchoolRefs = {
                            "f82db71a:1ggt4t3v"
                        },
                        statScaling = {
                            {
                                coefficient = 0.104,
                                statRef = "f82db71a:7t7xgzcx"
                            }
                        },
                        type = "damage"
                    }
                },
                events = {},
                icon = "interface/icons/spell_shadow_shadowwordpain.blp",
                id = "gtvlr7ou",
                maxStacks = 1,
                name = "Shadow Word: Pain",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Deals {AURA_DAMAGE_1} Shadow damage each turn.",
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
                        baseDamage = 17.68,
                        damageSchoolRefs = {
                            "f82db71a:1ggt4t3v"
                        },
                        statScaling = {
                            {
                                coefficient = 0.0884,
                                statRef = "f82db71a:7t7xgzcx"
                            }
                        },
                        type = "damage"
                    }
                },
                events = {},
                icon = "interface/icons/spell_holy_stoicism.blp",
                id = "zoaii4k5",
                maxStacks = 1,
                name = "Vampiric Touch",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Deals {AURA_DAMAGE_1} Shadow damage each turn.",
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
                        baseHealing = 8.84,
                        statScaling = {
                            {
                                coefficient = 0.0442,
                                statRef = "f82db71a:7t7xgzcx"
                            }
                        },
                        type = "heal"
                    }
                },
                events = {},
                icon = "interface/icons/spell_holy_stoicism.blp",
                id = "9tx50vf4",
                maxStacks = 3,
                name = "Vampiric Regeneration",
                stackBehavior = "independent_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Heals for {AURA_HEAL_1} health each turn.",
                    bodyTokens = {
                        {
                            applyMode = "heal_amount",
                            baseField = "baseHealing",
                            effectIndex = 1,
                            key = "AURA_HEAL_1",
                            tokenType = "aura_amount"
                        }
                    },
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
                duration = 2,
                effects = {
                    {
                        baseAmount = -10,
                        operation = "percent",
                        statRef = "f82db71a:itpo751d",
                        statScaling = {},
                        type = "stat"
                    }
                },
                events = {},
                icon = "interface/icons/spell_priest_mindspike.blp",
                id = "u8wmuosy",
                maxStacks = 3,
                name = "Mind Spike",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Reduces Shadow Resistance by 10%.",
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
                duration = 3,
                effects = {
                    {
                        baseAmount = 25,
                        operation = "percent",
                        statRef = "f82db71a:v42albuv",
                        statScaling = {},
                        type = "stat"
                    }
                },
                events = {},
                icon = "interface/icons/spell_holy_layonhands.blp",
                id = "inspirat",
                maxStacks = 1,
                name = "Inspiration",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Increases Armor by 25%.",
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
                description = "Priests are devoted to the spiritual, and express their unwavering faith by serving the people. For millennia they have left behind the confines of their temples and the comfort of their shrines so they can support their allies in war-torn lands. In the midst of terrible conflict, no hero questions the value of the priestly orders.",
                icon = "interface/icons/classicon_priest.blp",
                id = "nxlle3j6",
                name = "Priest",
                armorWeights = {
                    "cloth",
                },
                weaponTypeRefs = {
                    "f82db71a:i4pivdig",
                    "f82db71a:y0dnlo8g",
                    "f82db71a:3y1v01e4",
                    "f82db71a:s4q9t5f3",
                },
                resourceProgressions = {
                    {
                        initialValue = 31,
                        perLevelValue = 22.98,
                        resourceRef = "f82db71a:q2ktkztt"
                    },
                    {
                        initialValue = 110,
                        perLevelValue = 22.47,
                        resourceRef = "f82db71a:4c8mfm99"
                    }
                },
                skillBonuses = {},
                statProgressions = {
                    {
                        initialValue = 2,
                        perLevelValue = 1.66,
                        statRef = "f82db71a:75y3a8ib"
                    },
                    {
                        initialValue = 3,
                        perLevelValue = 1.73,
                        statRef = "f82db71a:kec9rhli"
                    },
                    {
                        initialValue = 0,
                        perLevelValue = 0.25,
                        statRef = "f82db71a:zfqm8dxp"
                    },
                    {
                        initialValue = 0,
                        perLevelValue = 0.34,
                        statRef = "f82db71a:xqz0daz2"
                    },
                    {
                        initialValue = 0,
                        perLevelValue = 0.51,
                        statRef = "f82db71a:ygjno50i"
                    }
                },
                passiveTraitRefs = {
                    "1c1038a7:icnfaith"
                },
                talentTraitRefs = {
                    "1c1038a7:silres20",
                    "1c1038a7:frcwill5",
                    "1c1038a7:sprheal1",
                    "1c1038a7:splward5",
                    "1c1038a7:shdfocus",
                    "1c1038a7:inspirit",
                    "1c1038a7:mental10"
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
        id = "1c1038a7",
        interactions = {},
        itemSlots = {},
        items = {},
        loot = {},
        mounts = {},
        name = "Priest",
        pets = {},
        races = {},
        recipes = {},
        resources = {},
        skills = {},
        spells = {
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
                    "on_heal",
                    "on_critical_heal"
                },
                charges = 0,
                components = {
                    {
                        castPhase = "on_cast_end",
                        castingGroup = "default",
                        effect = {
                            amountMode = "flat",
                            applyAura = false,
                            auraStacks = 1,
                            baseHealing = 145,
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.8,
                                    statRef = "f82db71a:hj6d4kvy"
                                }
                            },
                            targetEvents = {
                                "on_heal_taken",
                                "on_critical_heal_taken"
                            },
                            type = "heal",
                            usesProjectile = false
                        },
                        key = "04ce561a",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 1,
                            minTargets = 1,
                            requiresTarget = true,
                            targetDisposition = "ally",
                            type = "single"
                        }
                    }
                },
                conditions = {},
                cooldown = 0,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_holy_heal.blp",
                id = "eet5xd4t",
                cooldownChannel = 1,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Heal",
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
                spellbookCategory = "Holy",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {},
                    mainText = "Heal an ally for {HEAL_1} health.",
                    tokens = {
                        {
                            applyMode = "heal_range",
                            componentIndex = 1,
                            key = "HEAL_1",
                            tokenType = "spell_heal_range"
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
                            auraRef = "1c1038a7:pwrshld1",
                            basePower = 0,
                            duration = 5,
                            stacks = 1,
                            targetEvents = {},
                            threatCoefficient = 0.375,
                            type = "apply_aura"
                        },
                        key = "pwshldc1",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 1,
                            minTargets = 1,
                            requiresTarget = true,
                            targetDisposition = "ally",
                            type = "single"
                        }
                    }
                },
                conditions = {},
                cooldown = 0,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_holy_powerwordshield.blp",
                id = "pwshld01",
                cooldownChannel = 2,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Power Word: Shield",
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
                spellbookCategory = "Discipline",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "1c1038a7:pwrshld1",
                            datasetId = "1c1038a7",
                            descriptionText = "Absorbs {AURA_ABSORB_1} damage.",
                            duration = 5,
                            icon = "interface/icons/spell_holy_powerwordshield.blp",
                            nameText = "Power Word: Shield",
                            powerLevel = 0,
                            spellDatasetId = "1c1038a7",
                            stacks = 1,
                            targetContext = {
                                object = "the affected ally",
                                possessive = "the affected ally's",
                                reflexive = "itself",
                                subject = "the affected ally"
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
                    mainText = "Apply Power Word: Shield to an ally for 5 turns.",
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
                    "on_heal",
                    "on_critical_heal"
                },
                charges = 0,
                components = {
                    {
                        castPhase = "on_cast_end",
                        castingGroup = "default",
                        effect = {
                            amountMode = "flat",
                            applyAura = false,
                            auraStacks = 1,
                            baseHealing = 326.25,
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 1.8,
                                    statRef = "f82db71a:hj6d4kvy"
                                }
                            },
                            targetEvents = {
                                "on_heal_taken",
                                "on_critical_heal_taken"
                            },
                            type = "heal",
                            usesProjectile = false
                        },
                        key = "04ce561a",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 1,
                            minTargets = 1,
                            requiresTarget = true,
                            targetDisposition = "ally",
                            type = "single"
                        }
                    }
                },
                conditions = {},
                cooldown = 0,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_holy_greaterheal.blp",
                id = "dbk3frh2",
                cooldownChannel = 1,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Greater Heal",
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
                spellbookCategory = "Holy",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {},
                    mainText = "Heal an ally for {HEAL_1} health.",
                    tokens = {
                        {
                            applyMode = "heal_range",
                            componentIndex = 1,
                            key = "HEAL_1",
                            tokenType = "spell_heal_range"
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
                    "on_heal",
                    "on_critical_heal"
                },
                charges = 0,
                components = {
                    {
                        castPhase = "on_cast_end",
                        castingGroup = "default",
                        effect = {
                            amountMode = "flat",
                            applyAura = false,
                            auraStacks = 1,
                            baseHealing = 94.25,
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.52,
                                    statRef = "f82db71a:hj6d4kvy"
                                }
                            },
                            targetEvents = {
                                "on_heal_taken",
                                "on_critical_heal_taken"
                            },
                            type = "heal",
                            usesProjectile = false
                        },
                        key = "04ce561a",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 1,
                            minTargets = 1,
                            requiresTarget = true,
                            targetDisposition = "ally",
                            type = "single"
                        }
                    }
                },
                conditions = {},
                cooldown = 0,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_holy_lesserheal.blp",
                id = "h3n22bv2",
                cooldownChannel = 2,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Lesser Heal",
                range = 0,
                resourceCosts = {
                    {
                        amount = 4.3,
                        amountMode = "base_percent",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:4c8mfm99"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Holy",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {},
                    mainText = "Heal an ally for {HEAL_1} health.",
                    tokens = {
                        {
                            applyMode = "heal_range",
                            componentIndex = 1,
                            key = "HEAL_1",
                            tokenType = "spell_heal_range"
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
                    "on_heal",
                    "on_critical_heal",
                    "on_heal_taken",
                    "on_critical_heal_taken"
                },
                charges = 0,
                components = {
                    {
                        castPhase = "on_cast_end",
                        castingGroup = "default",
                        effect = {
                            amountMode = "flat",
                            applyAura = false,
                            auraStacks = 1,
                            baseHealing = 123.25,
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.68,
                                    statRef = "f82db71a:hj6d4kvy"
                                }
                            },
                            targetEvents = {
                                "on_heal_taken",
                                "on_critical_heal_taken"
                            },
                            type = "heal",
                            usesProjectile = false
                        },
                        key = "04ce561a",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 1,
                            minTargets = 1,
                            requiresTarget = true,
                            targetDisposition = "ally",
                            type = "single"
                        }
                    },
                    {
                        castPhase = "on_cast_end",
                        castingGroup = "default",
                        effect = {
                            amountMode = "flat",
                            applyAura = false,
                            auraStacks = 1,
                            baseHealing = 55.25,
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.3315,
                                    statRef = "f82db71a:hj6d4kvy"
                                }
                            },
                            targetEvents = {},
                            type = "heal",
                            usesProjectile = false
                        },
                        key = "d301422a",
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
                icon = "interface/icons/spell_holy_blindingheal.blp",
                id = "b7dot26a",
                cooldownChannel = 1,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Binding Heal",
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
                spellbookCategory = "Holy",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {},
                    mainText = "Heal an ally for {HEAL_1} health. Heal yourself for {HEAL_2} health.",
                    tokens = {
                        {
                            applyMode = "heal_range",
                            componentIndex = 1,
                            key = "HEAL_1",
                            tokenType = "spell_heal_range"
                        },
                        {
                            applyMode = "heal_range",
                            componentIndex = 2,
                            key = "HEAL_2",
                            tokenType = "spell_heal_range"
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
                    "on_heal",
                    "on_critical_heal"
                },
                charges = 0,
                components = {
                    {
                        castPhase = "on_cast_end",
                        castingGroup = "default",
                        effect = {
                            amountMode = "flat",
                            applyAura = false,
                            auraStacks = 1,
                            baseHealing = 100,
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.6,
                                    statRef = "f82db71a:hj6d4kvy"
                                }
                            },
                            targetEvents = {
                                "on_heal_taken",
                                "on_critical_heal_taken"
                            },
                            type = "heal",
                            usesProjectile = false
                        },
                        key = "04ce561a",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 1,
                            minTargets = 1,
                            requiresTarget = true,
                            targetDisposition = "ally",
                            type = "single"
                        }
                    }
                },
                conditions = {},
                cooldown = 0,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_holy_flashheal.blp",
                id = "5yht8j0f",
                cooldownChannel = 1,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Flash Heal",
                range = 0,
                resourceCosts = {
                    {
                        amount = 12,
                        amountMode = "base_percent",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:4c8mfm99"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Holy",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {},
                    mainText = "Heal an ally for {HEAL_1} health.",
                    tokens = {
                        {
                            applyMode = "heal_range",
                            componentIndex = 1,
                            key = "HEAL_1",
                            tokenType = "spell_heal_range"
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
                            auraRef = "1c1038a7:a84ux6v9",
                            basePower = 0,
                            duration = 5,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "813aa64d",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 1,
                            minTargets = 1,
                            requiresTarget = true,
                            targetDisposition = "ally",
                            type = "single"
                        }
                    }
                },
                conditions = {},
                cooldown = 0,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_holy_renew.blp",
                id = "qqkkenuw",
                cooldownChannel = 2,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Renew",
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
                spellbookCategory = "Holy",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "1c1038a7:a84ux6v9",
                            datasetId = "1c1038a7",
                            descriptionText = "Heals for {AURA_HEAL_1} health each turn.",
                            duration = 5,
                            icon = "interface/icons/spell_holy_renew.blp",
                            nameText = "Renew",
                            powerLevel = 0,
                            spellDatasetId = "1c1038a7",
                            stacks = 1,
                            targetContext = {
                                object = "the affected ally",
                                possessive = "the affected ally's",
                                reflexive = "itself",
                                subject = "the affected ally"
                            },
                            tokens = {
                                {
                                    applyMode = "heal_amount",
                                    baseField = "baseHealing",
                                    effectIndex = 1,
                                    key = "AURA_HEAL_1",
                                    tokenType = "aura_amount"
                                }
                            }
                        }
                    },
                    mainText = "Apply Renew to an ally for 5 turns.",
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
                            baseDamage = 70,
                            damageSchoolRefs = {
                                "f82db71a:wwctys5s"
                            },
                            damageType = "spell",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.35,
                                    statRef = "f82db71a:7t7xgzcx"
                                }
                            },
                            targetEvents = {
                                "on_spell_taken",
                                "on_critical_hit_taken"
                            },
                            threatCoefficient = 0.5,
                            type = "damage",
                            usesProjectile = false,
                            weaponDamageCoefficient = 0,
                            weaponDamageMode = "none"
                        },
                        key = "98a6b74a",
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
                icon = "interface/icons/spell_holy_holysmite.blp",
                id = "rm9rekvj",
                cooldownChannel = 1,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Smite",
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
                spellbookCategory = "Discipline",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {},
                    mainText = "Deal {DAMAGE_1} Holy damage to an enemy. Generates a low amount of threat.",
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
                charges = 0,
                components = {
                    {
                        castPhase = "on_cast_end",
                        castingGroup = "default",
                        effect = {
                            alwaysHits = false,
                            amountMode = "flat",
                            applyAura = true,
                            auraRef = "1c1038a7:bgmk5vpf",
                            auraStacks = 1,
                            baseDamage = 80.325,
                            damageSchoolRefs = {
                                "f82db71a:wwctys5s"
                            },
                            damageType = "spell",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.4165,
                                    statRef = "f82db71a:7t7xgzcx"
                                }
                            },
                            targetEvents = {
                                "on_spell_taken",
                                "on_critical_hit_taken"
                            },
                            threatCoefficient = 0.5,
                            type = "damage",
                            usesProjectile = false,
                            weaponDamageCoefficient = 0,
                            weaponDamageMode = "none"
                        },
                        key = "98a6b74a",
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
                icon = "interface/icons/spell_holy_searinglight.blp",
                id = "1x1q35og",
                cooldownChannel = 1,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Holy Fire",
                range = 0,
                resourceCosts = {
                    {
                        amount = 3.4,
                        amountMode = "base_percent",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:4c8mfm99"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Discipline",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "1c1038a7:bgmk5vpf",
                            datasetId = "1c1038a7",
                            descriptionText = "Deals {AURA_DAMAGE_1} Holy damage each turn.",
                            icon = "interface/icons/spell_holy_searinglight.blp",
                            nameText = "Holy Fire",
                            powerLevel = 0,
                            spellDatasetId = "1c1038a7",
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
                    mainText = "Deal {DAMAGE_1} Holy damage to an enemy and apply Holy Fire for 3 turns. Generates a low amount of threat.",
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
                            auraRef = "1c1038a7:tx866rqz",
                            basePower = 0,
                            duration = 1,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "3eecce7b",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 1,
                            minTargets = 1,
                            requiresTarget = true,
                            targetDisposition = "ally",
                            type = "single"
                        }
                    }
                },
                conditions = {},
                cooldown = 10,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_holy_painsupression.blp",
                id = "mnuc5di4",
                cooldownChannel = 5,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Pain Suppression",
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
                spellbookCategory = "Discipline",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "1c1038a7:tx866rqz",
                            datasetId = "1c1038a7",
                            descriptionText = "Increases Damage Reduction by 40%.",
                            duration = 1,
                            icon = "interface/icons/spell_holy_painsupression.blp",
                            nameText = "Pain Suppression",
                            powerLevel = 0,
                            spellDatasetId = "1c1038a7",
                            stacks = 1,
                            targetContext = {
                                object = "the affected ally",
                                possessive = "the affected ally's",
                                reflexive = "itself",
                                subject = "the affected ally"
                            },
                            tokens = {}
                        }
                    },
                    mainText = "Apply Pain Suppression to an ally for 1 turn.",
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
                            auraRef = "1c1038a7:nihyfz0x",
                            basePower = 0,
                            duration = 10,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "3eecce7b",
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
                cooldown = 10,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_holy_divinespirit.blp",
                id = "lg9aex8t",
                cooldownChannel = 3,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Divine Spirit",
                range = 0,
                resourceCosts = {
                    {
                        amount = 10,
                        amountMode = "base_percent",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:4c8mfm99"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Discipline",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "1c1038a7:nihyfz0x",
                            datasetId = "1c1038a7",
                            descriptionText = "Increases Spirit by 10%.",
                            duration = 10,
                            icon = "interface/icons/spell_holy_divinespirit.blp",
                            nameText = "Divine Spirit",
                            powerLevel = 0,
                            spellDatasetId = "1c1038a7",
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
                    mainText = "Apply Divine Spirit to all allies for 10 turns.",
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
                            auraRef = "1c1038a7:cqblzgiw",
                            basePower = 0,
                            duration = 10,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "3eecce7b",
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
                cooldown = 10,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_holy_wordfortitude.blp",
                id = "hhxhszcv",
                cooldownChannel = 3,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Prayer of Fortitude",
                range = 0,
                resourceCosts = {
                    {
                        amount = 10,
                        amountMode = "base_percent",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:4c8mfm99"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Discipline",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "1c1038a7:cqblzgiw",
                            datasetId = "1c1038a7",
                            descriptionText = "Increases Stamina by 5%.",
                            duration = 10,
                            icon = "interface/icons/spell_holy_wordfortitude.blp",
                            nameText = "Prayer of Fortitude",
                            powerLevel = 0,
                            spellDatasetId = "1c1038a7",
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
                    mainText = "Apply Prayer of Fortitude to all allies for 10 turns.",
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
                            auraRef = "1c1038a7:sjzm0cbf",
                            basePower = 0,
                            duration = 10,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "3eecce7b",
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
                cooldown = 10,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_holy_prayerofshadowprotection.blp",
                id = "ilkjmlyk",
                cooldownChannel = 3,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Prayer of Shadow Protection",
                range = 0,
                resourceCosts = {
                    {
                        amount = 10,
                        amountMode = "base_percent",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:4c8mfm99"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Shadow",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "1c1038a7:sjzm0cbf",
                            datasetId = "1c1038a7",
                            descriptionText = "Increases Shadow Resistance by {AURA_STAT_1}.",
                            duration = 10,
                            icon = "interface/icons/spell_holy_prayerofshadowprotection.blp",
                            nameText = "Prayer of Shadow Protection",
                            powerLevel = 0,
                            spellDatasetId = "1c1038a7",
                            stacks = 1,
                            targetContext = {
                                object = "all allies",
                                possessive = "all allies'",
                                reflexive = "themselves",
                                subject = "all allies"
                            },
                            tokens = {
                                {
                                    applyMode = "stat_amount",
                                    baseField = "baseAmount",
                                    effectIndex = 1,
                                    key = "AURA_STAT_1",
                                    tokenType = "aura_amount"
                                }
                            }
                        }
                    },
                    mainText = "Apply Prayer of Shadow Protection to all allies for 10 turns.",
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
                            auraRef = "1c1038a7:1hbbqcre",
                            basePower = 0,
                            duration = 2,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "434b2cd4",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 3,
                            minTargets = 1,
                            requiresTarget = true,
                            targetDisposition = "enemy",
                            type = "multi"
                        }
                    }
                },
                conditions = {},
                cooldown = 10,
                cooldownGroup = "fear",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_shadow_psychicscream.blp",
                id = "3ctxnb99",
                cooldownChannel = 1,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Psychic Scream",
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
                spellbookCategory = "Discipline",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "1c1038a7:1hbbqcre",
                            datasetId = "1c1038a7",
                            descriptionText = "Breaks when the affected unit takes damage. Prevents the affected unit from casting spells.",
                            duration = 2,
                            icon = "interface/icons/spell_shadow_psychicscream.blp",
                            nameText = "Psychic Scream",
                            powerLevel = 0,
                            spellDatasetId = "1c1038a7",
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
                    mainText = "Apply Psychic Scream to up to 3 enemies for 2 turns.",
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
                            auraRef = "1c1038a7:20ll5azr",
                            basePower = 0,
                            duration = 1,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "434b2cd4",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 1,
                            minTargets = 1,
                            requiresTarget = true,
                            targetDisposition = "enemy",
                            type = "multi"
                        }
                    }
                },
                conditions = {},
                cooldown = 10,
                cooldownGroup = "stun",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_shadow_psychichorrors.blp",
                id = "5q7jx4c1",
                cooldownChannel = 2,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Psychic Horror",
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
                spellbookCategory = "Shadow",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "1c1038a7:20ll5azr",
                            datasetId = "1c1038a7",
                            descriptionText = "Breaks when the affected unit takes damage. Prevents the affected unit from casting spells. Sets the affected unit's movement range to 0. Causes all attacks against the affected unit to automatically hit.",
                            duration = 1,
                            icon = "interface/icons/spell_shadow_psychicscream.blp",
                            nameText = "Psychic Horror",
                            powerLevel = 0,
                            spellDatasetId = "1c1038a7",
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
                    mainText = "Apply Psychic Horror to an enemy for 1 turn.",
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
                            amount = 6.3,
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
                            auraRef = "1c1038a7:gtvlr7ou",
                            basePower = 0,
                            duration = 5,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "72e862ab",
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
                icon = "interface/icons/spell_shadow_shadowwordpain.blp",
                id = "drza38ax",
                cooldownChannel = 2,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Shadow Word: Pain",
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
                spellbookCategory = "Shadow",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "1c1038a7:gtvlr7ou",
                            datasetId = "1c1038a7",
                            descriptionText = "Deals {AURA_DAMAGE_1} Shadow damage each turn.",
                            duration = 5,
                            icon = "interface/icons/spell_shadow_shadowwordpain.blp",
                            nameText = "Shadow Word: Pain",
                            powerLevel = 0,
                            spellDatasetId = "1c1038a7",
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
                    mainText = "Apply Shadow Word: Pain to an enemy for 5 turns.",
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
                casterEvents = {},
                charges = 0,
                components = {
                    {
                        castPhase = "on_cast_end",
                        castingGroup = "default",
                        effect = {
                            auraRef = "1c1038a7:zoaii4k5",
                            basePower = 0,
                            duration = 5,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "72e862ab",
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
                            auraRef = "1c1038a7:9tx50vf4",
                            basePower = 0,
                            duration = 5,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "772ff72e",
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
                icon = "interface/icons/spell_holy_stoicism.blp",
                id = "k71jmcz0",
                cooldownChannel = 1,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Vampiric Touch",
                range = 0,
                resourceCosts = {
                    {
                        amount = 3.4,
                        amountMode = "base_percent",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:4c8mfm99"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Shadow",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "1c1038a7:zoaii4k5",
                            datasetId = "1c1038a7",
                            descriptionText = "Deals {AURA_DAMAGE_1} Shadow damage each turn.",
                            duration = 5,
                            icon = "interface/icons/spell_holy_stoicism.blp",
                            nameText = "Vampiric Touch",
                            powerLevel = 0,
                            spellDatasetId = "1c1038a7",
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
                        },
                        {
                            auraRef = "1c1038a7:9tx50vf4",
                            datasetId = "1c1038a7",
                            descriptionText = "Heals for {AURA_HEAL_1} health each turn. Applies {AURA_APPLIED_STACKS_1} stacks. Stacks up to {AURA_MAX_STACKS_1} times.",
                            duration = 5,
                            icon = "interface/icons/spell_holy_stoicism.blp",
                            nameText = "Vampiric Regeneration",
                            powerLevel = 0,
                            spellDatasetId = "1c1038a7",
                            stacks = 1,
                            targetContext = {
                                object = "you",
                                possessive = "your",
                                reflexive = "yourself",
                                subject = "you"
                            },
                            tokens = {
                                {
                                    applyMode = "heal_amount",
                                    baseField = "baseHealing",
                                    effectIndex = 1,
                                    key = "AURA_HEAL_1",
                                    tokenType = "aura_amount"
                                },
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
                    mainText = "Apply Vampiric Touch to an enemy for 5 turns. Apply Vampiric Regeneration to yourself for 5 turns.",
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
                            applyAura = false,
                            auraStacks = 1,
                            baseDamage = 175.5,
                            damageSchoolRefs = {
                                "f82db71a:1ggt4t3v"
                            },
                            damageType = "spell",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.91,
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
                            weaponDamageCoefficient = 0,
                            weaponDamageMode = "none"
                        },
                        key = "0152ac53",
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
                cooldown = 3,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_shadow_unholyfrenzy.blp",
                id = "oe32yzws",
                cooldownChannel = 1,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Mind Blast",
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
                spellbookCategory = "Shadow",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {},
                    mainText = "Deal {DAMAGE_1} Shadow damage to an enemy.",
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
                            auraRef = "1c1038a7:u8wmuosy",
                            auraStacks = 1,
                            baseDamage = 120.488,
                            damageSchoolRefs = {
                                "f82db71a:1ggt4t3v"
                            },
                            damageType = "spell",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.6248,
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
                            weaponDamageCoefficient = 0,
                            weaponDamageMode = "none"
                        },
                        key = "0152ac53",
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
                icon = "interface/icons/spell_priest_mindspike.blp",
                id = "vmtnl0y4",
                cooldownChannel = 1,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Mind Spike",
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
                spellbookCategory = "Shadow",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "1c1038a7:u8wmuosy",
                            datasetId = "1c1038a7",
                            descriptionText = "Reduces Shadow Resistance by 10%. Applies {AURA_APPLIED_STACKS_1} stacks. Stacks up to {AURA_MAX_STACKS_1} times.",
                            icon = "interface/icons/spell_priest_mindspike.blp",
                            nameText = "Mind Spike",
                            powerLevel = 0,
                            spellDatasetId = "1c1038a7",
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
                    mainText = "Deal {DAMAGE_1} Shadow damage to an enemy and apply Mind Spike for 2 turns.",
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
                            auraStacks = 1,
                            baseDamage = 141.75,
                            damageSchoolRefs = {
                                "f82db71a:1ggt4t3v"
                            },
                            damageType = "spell",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.735,
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
                            weaponDamageCoefficient = 0,
                            weaponDamageMode = "none"
                        },
                        key = "0152ac53",
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
                icon = "interface/icons/spell_shadow_siphonmana.blp",
                id = "u8dvti6t",
                cooldownChannel = 1,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Mind Flay",
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
                spellbookCategory = "Shadow",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {},
                    mainText = "Deal {DAMAGE_1} Shadow damage to an enemy.",
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
                            alwaysHits = false,
                            amountMode = "flat",
                            applyAura = false,
                            auraStacks = 1,
                            baseDamage = 225,
                            damageSchoolRefs = {
                                "f82db71a:1ggt4t3v"
                            },
                            damageType = "spell",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 1.125,
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
                            weaponDamageCoefficient = 0,
                            weaponDamageMode = "none"
                        },
                        key = "62408d39",
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
                        invert = false,
                        maximumValue = 20,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "target_health_percent"
                    }
                },
                cooldown = 0,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_shadow_demonicfortitude.blp",
                id = "3z4hi35b",
                cooldownChannel = 1,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Shadow Word: Death",
                range = 0,
                resourceCosts = {
                    {
                        amount = 13.6,
                        amountMode = "base_percent",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:4c8mfm99"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Shadow",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {},
                    mainText = "Deal {DAMAGE_1} Shadow damage to an enemy.",
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
                category = "Discipline",
                conditions = {},
                description = "Increases your damage against Aberrations by 5%.",
                events = {},
                icon = "interface/icons/spell_holy_innerfire.blp",
                id = "icnfaith",
                isEnvironmental = false,
                name = "Icon of Faith",
                skillBonuses = {},
                statBonuses = {
                    {
                        statRef = "f82db71a:i52j0tj3",
                        value = 5
                    }
                },
                unlockLevel = 1
            },
            {
                automaticAuras = {},
                category = "Discipline",
                conditions = {},
                description = "",
                events = {},
                icon = "interface/icons/spell_holy_innerfire.blp",
                id = "kau90anf",
                isEnvironmental = false,
                name = "Inner Fire",
                skillBonuses = {},
                statBonuses = {
                    {
                        statRef = "f82db71a:pu05li08",
                        value = 10
                    }
                },
                unlockLevel = 1
            },
            {
                automaticAuras = {},
                category = "Discipline",
                conditions = {},
                description = "",
                events = {},
                icon = "interface/icons/spell_nature_manaregentotem.blp",
                id = "silres20",
                isEnvironmental = false,
                name = "Silent Resolve",
                skillBonuses = {},
                statBonuses = {
                    {
                        statRef = "f82db71a:j8n012e6",
                        value = -20
                    }
                },
                unlockLevel = 1
            },
            {
                automaticAuras = {},
                category = "Discipline",
                conditions = {},
                description = "",
                events = {},
                icon = "interface/icons/spell_nature_slowingtotem.blp",
                id = "frcwill5",
                isEnvironmental = false,
                name = "Force of Will",
                skillBonuses = {},
                statBonuses = {
                    {
                        operation = "percent",
                        statRef = "f82db71a:7t7xgzcx",
                        value = 5
                    },
                    {
                        statRef = "f82db71a:69hfqhne",
                        value = 5
                    }
                },
                unlockLevel = 1
            },
            {
                automaticAuras = {},
                category = "Holy",
                conditions = {},
                description = "",
                events = {},
                icon = "interface/icons/spell_nature_moonglow.blp",
                id = "sprheal1",
                isEnvironmental = false,
                name = "Spiritual Healing",
                skillBonuses = {},
                statBonuses = {
                    {
                        operation = "percent",
                        statRef = "f82db71a:hj6d4kvy",
                        value = 10
                    }
                },
                unlockLevel = 1
            },
            {
                automaticAuras = {},
                category = "Holy",
                conditions = {},
                description = "",
                events = {},
                icon = "interface/icons/spell_holy_spellwarding.blp",
                id = "splward5",
                isEnvironmental = false,
                name = "Spell Warding",
                skillBonuses = {},
                statBonuses = {
                    {
                        statRef = "f82db71a:zs1nbz13",
                        value = 5
                    }
                },
                unlockLevel = 1
            },
            {
                automaticAuras = {},
                category = "Shadow",
                conditions = {},
                description = "",
                events = {},
                icon = "interface/icons/spell_shadow_burningspirit.blp",
                id = "shdfocus",
                isEnvironmental = false,
                name = "Shadow Focus",
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
                category = "Holy",
                conditions = {},
                description = "",
                events = {
                    {
                        combatEventId = "on_critical_heal",
                        effects = {
                            {
                                auraRef = "1c1038a7:inspirat",
                                basePower = 0,
                                duration = 3,
                                stacks = 1,
                                type = "apply_aura"
                            }
                        },
                        triggerTarget = "event_other"
                    }
                },
                icon = "interface/icons/spell_holy_layonhands.blp",
                id = "inspirit",
                isEnvironmental = false,
                name = "Inspiration",
                skillBonuses = {},
                statBonuses = {},
                unlockLevel = 1
            },
            {
                automaticAuras = {},
                category = "Discipline",
                conditions = {},
                description = "",
                events = {},
                icon = "interface/icons/spell_nature_enchantarmor.blp",
                id = "mental10",
                isEnvironmental = false,
                name = "Mental Strength",
                skillBonuses = {},
                statBonuses = {
                    {
                        operation = "percent",
                        statRef = "f82db71a:75y3a8ib",
                        value = 10
                    }
                },
                unlockLevel = 1
            }
        },
        units = {},
        weaponTypes = {}
    },
})
