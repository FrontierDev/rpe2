local _, Addon = ...

Addon.Data.DefaultDatasets:Register({
    version = 31,
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
                                coefficient = 0.624,
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
                                coefficient = 0.18,
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
                                coefficient = 0.42,
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
                                coefficient = 0.32,
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
                                coefficient = 0.221,
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
            },
            {
                description = "",
                duration = 5,
                effects = {
                    {
                        baseAmount = -10,
                        operation = "flat",
                        statRef = "f82db71a:itpo751d",
                        statScaling = {},
                        type = "stat"
                    }
                },
                events = {},
                icon = "interface/icons/spell_shadow_blackplague.blp",
                id = "shdwvau1",
                maxStacks = 5,
                name = "Shadow Weaving",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Reduces Shadow Resistance by {AURA_STAT_1}.",
                    bodyTokens = {
                        {
                            applyMode = "stat_amount",
                            baseField = "baseAmount",
                            effectIndex = 1,
                            key = "AURA_STAT_1",
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
                duration = 1,
                effects = {
                    {
                        cancelOnDamage = false,
                        forceAutoHitAgainstTarget = true,
                        movementRangeOverride = 0,
                        preventCasting = true,
                        statScaling = {},
                        type = "control"
                    }
                },
                events = {},
                icon = "interface/icons/spell_shadow_gathershadows.blp",
                id = "blckouta",
                maxStacks = 1,
                name = "Blackout",
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
            },
            {
                description = "",
                duration = 1,
                effects = {
                    {
                        cancelOnDamage = false,
                        forceAutoHitAgainstTarget = false,
                        preventCasting = true,
                        statScaling = {},
                        type = "control"
                    },
                    {
                        baseAmount = 90,
                        operation = "flat",
                        statRef = "f82db71a:pu05li08",
                        statScaling = {},
                        type = "stat"
                    }
                },
                events = {},
                icon = "interface/icons/spell_shadow_dispersion.blp",
                id = "dispersa",
                maxStacks = 1,
                name = "Dispersion",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Prevents the affected unit from casting spells. Increases Damage Reduction by 90%.",
                    bodyTokens = {},
                    stackingText = "",
                    stackingTokens = {},
                    version = 1
                }
            },
            {
                description = "",
                duration = 5,
                effects = {},
                events = {
                    {
                        chance = 100,
                        combatEventId = "on_auto_attack_taken",
                        effects = {
                            {
                                amountMode = "max_percent",
                                baseHealing = 2,
                                statScaling = {},
                                type = "heal"
                            },
                            {
                                auraRef = "1c1038a7:prmndau1",
                                stacks = 1,
                                type = "remove_aura"
                            }
                        },
                        triggerTarget = "aura_target"
                    }
                },
                icon = "interface/icons/spell_holy_prayerofmendingtga.blp",
                id = "prmndau1",
                maxStacks = 3,
                name = "Prayer of Mending",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "When the affected unit is victim of a basic attack, heal the affected unit for 2% of Max health and remove 1 stack.",
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
                    "1c1038a7:mental10",
                    "1c1038a7:shadform",
                    "1c1038a7:shdweav1",
                    "1c1038a7:blackout"
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
        items = {
            {
                allowWowConversion = false,
                armorWeight = "cloth",
                bindingFlag = "bind_on_pickup",
                blueSockets = 1,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "1c1038a7:nxlle3j6",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Priest",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_chest_cloth_03.blp",
                id = "pr2drobe",
                isTwoHanded = false,
                itemLevel = 75,
                itemSetKey = "t2_priest_healer",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Robes of Transcendence",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 1,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {
                    {
                        color = "red",
                    },
                    {
                        color = "yellow",
                    },
                    {
                        color = "blue",
                    },
                },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 116,
                    },
                    {
                        sourceStatRef = "f82db71a:75y3a8ib",
                        value = 14,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 16,
                    },
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:pg0ytacb",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:jjn0my8k",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:jslmczbi",
                        value = 1,
                    },
                    {
                        sourceStatRef = "f82db71a:69hfqhne",
                        value = 1,
                    },
                    {
                        sourceStatRef = "f82db71a:hj6d4kvy",
                        value = 70,
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 24,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:nwfvxbto",
                },
                yellowSockets = 1,
            },
            {
                allowWowConversion = false,
                armorWeight = "cloth",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "1c1038a7:nxlle3j6",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Priest",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_boots_07.blp",
                id = "pr2dboot",
                isTwoHanded = false,
                itemLevel = 75,
                itemSetKey = "t2_priest_healer",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Boots of Transcendence",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {  },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 80,
                    },
                    {
                        sourceStatRef = "f82db71a:75y3a8ib",
                        value = 14,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 12,
                    },
                    {
                        sourceStatRef = "f82db71a:pg0ytacb",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:jslmczbi",
                        value = 1,
                    },
                    {
                        sourceStatRef = "f82db71a:69hfqhne",
                        value = 1,
                    },
                    {
                        sourceStatRef = "f82db71a:hj6d4kvy",
                        value = 53,
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 18,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:raiu9t05",
                },
                yellowSockets = 0,
            },
            {
                allowWowConversion = false,
                armorWeight = "cloth",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "1c1038a7:nxlle3j6",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Priest",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_gauntlets_14.blp",
                id = "pr2dhnds",
                isTwoHanded = false,
                itemLevel = 75,
                itemSetKey = "t2_priest_healer",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Handguards of Transcendence",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {  },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 72,
                    },
                    {
                        sourceStatRef = "f82db71a:75y3a8ib",
                        value = 14,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 11,
                    },
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:pg0ytacb",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:jslmczbi",
                        value = 1,
                    },
                    {
                        sourceStatRef = "f82db71a:69hfqhne",
                        value = 1,
                    },
                    {
                        sourceStatRef = "f82db71a:hj6d4kvy",
                        value = 40,
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 14,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:wasvuom2",
                },
                yellowSockets = 0,
            },
            {
                allowWowConversion = false,
                armorWeight = "cloth",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "1c1038a7:nxlle3j6",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Priest",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_helmet_24.blp",
                id = "pr2dhalo",
                isTwoHanded = false,
                itemLevel = 75,
                itemSetKey = "t2_priest_healer",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 1,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Halo of Transcendence",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 1,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {
                    {
                        color = "meta",
                    },
                    {
                        color = "red",
                    },
                },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 94,
                    },
                    {
                        sourceStatRef = "f82db71a:75y3a8ib",
                        value = 14,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 14,
                    },
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 9,
                    },
                    {
                        sourceStatRef = "f82db71a:pg0ytacb",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:jjn0my8k",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:jslmczbi",
                        value = 1,
                    },
                    {
                        sourceStatRef = "f82db71a:69hfqhne",
                        value = 1,
                    },
                    {
                        sourceStatRef = "f82db71a:hj6d4kvy",
                        value = 77,
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 26,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:bgvs1zx6",
                },
                yellowSockets = 0,
            },
            {
                allowWowConversion = false,
                armorWeight = "cloth",
                bindingFlag = "bind_on_pickup",
                blueSockets = 1,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "1c1038a7:nxlle3j6",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Priest",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_pants_08.blp",
                id = "pr2dlegs",
                isTwoHanded = false,
                itemLevel = 75,
                itemSetKey = "t2_priest_healer",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Leggings of Transcendence",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 1,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {
                    {
                        color = "red",
                    },
                    {
                        color = "blue",
                    },
                },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 101,
                    },
                    {
                        sourceStatRef = "f82db71a:75y3a8ib",
                        value = 20,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 12,
                    },
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 18,
                    },
                    {
                        sourceStatRef = "f82db71a:pg0ytacb",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:jjn0my8k",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:hj6d4kvy",
                        value = 70,
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 24,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:obmt4ntq",
                },
                yellowSockets = 0,
            },
            {
                allowWowConversion = false,
                armorWeight = "cloth",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "1c1038a7:nxlle3j6",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Priest",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_shoulder_02.blp",
                id = "pr2dpaul",
                isTwoHanded = false,
                itemLevel = 75,
                itemSetKey = "t2_priest_healer",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Pauldrons of Transcendence",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {  },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 87,
                    },
                    {
                        sourceStatRef = "f82db71a:75y3a8ib",
                        value = 17,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 12,
                    },
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 13,
                    },
                    {
                        sourceStatRef = "f82db71a:jjn0my8k",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:hj6d4kvy",
                        value = 46,
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 16,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:66i80qm1",
                },
                yellowSockets = 0,
            },
            {
                allowWowConversion = false,
                armorWeight = "cloth",
                bindingFlag = "bind_on_pickup",
                blueSockets = 1,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "1c1038a7:nxlle3j6",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Priest",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_belt_22.blp",
                id = "pr2dbelt",
                isTwoHanded = false,
                itemLevel = 75,
                itemSetKey = "t2_priest_healer",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Belt of Transcendence",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {
                    {
                        color = "blue",
                    },
                },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 65,
                    },
                    {
                        sourceStatRef = "f82db71a:75y3a8ib",
                        value = 17,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 13,
                    },
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 13,
                    },
                    {
                        sourceStatRef = "f82db71a:jjn0my8k",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:hj6d4kvy",
                        value = 42,
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 14,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:haks0gz4",
                },
                yellowSockets = 0,
            },
            {
                allowWowConversion = false,
                armorWeight = "cloth",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "1c1038a7:nxlle3j6",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Priest",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_bracer_09.blp",
                id = "pr2dbind",
                isTwoHanded = false,
                itemLevel = 75,
                itemSetKey = "t2_priest_healer",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Bindings of Transcendence",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {  },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 51,
                    },
                    {
                        sourceStatRef = "f82db71a:75y3a8ib",
                        value = 14,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 13,
                    },
                    {
                        sourceStatRef = "f82db71a:hj6d4kvy",
                        value = 31,
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 11,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:crezt6ix",
                },
                yellowSockets = 0,
            },
            {
                allowWowConversion = false,
                armorWeight = "cloth",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "1c1038a7:nxlle3j6",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Priest",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_chest_cloth_03.blp",
                id = "pr2tgarb",
                isTwoHanded = false,
                itemLevel = 75,
                itemSetKey = "t2_priest_dps",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Garb of Transcendence",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 2,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {
                    {
                        color = "red",
                    },
                    {
                        color = "red",
                    },
                    {
                        color = "yellow",
                    },
                },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 116,
                    },
                    {
                        sourceStatRef = "f82db71a:75y3a8ib",
                        value = 17,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 14,
                    },
                    {
                        sourceStatRef = "f82db71a:pg0ytacb",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:jjn0my8k",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:jslmczbi",
                        value = 2,
                    },
                    {
                        sourceStatRef = "f82db71a:69hfqhne",
                        value = 2,
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 36,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:nwfvxbto",
                },
                yellowSockets = 1,
            },
            {
                allowWowConversion = false,
                armorWeight = "cloth",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "1c1038a7:nxlle3j6",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Priest",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_boots_07.blp",
                id = "pr2ttrds",
                isTwoHanded = false,
                itemLevel = 75,
                itemSetKey = "t2_priest_dps",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Treads of Transcendence",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {  },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 80,
                    },
                    {
                        sourceStatRef = "f82db71a:75y3a8ib",
                        value = 18,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:pg0ytacb",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 36,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:raiu9t05",
                },
                yellowSockets = 0,
            },
            {
                allowWowConversion = false,
                armorWeight = "cloth",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "1c1038a7:nxlle3j6",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Priest",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_gauntlets_14.blp",
                id = "pr2tglov",
                isTwoHanded = false,
                itemLevel = 75,
                itemSetKey = "t2_priest_dps",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Gloves of Transcendence",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {  },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 72,
                    },
                    {
                        sourceStatRef = "f82db71a:75y3a8ib",
                        value = 13,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 12,
                    },
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 13,
                    },
                    {
                        sourceStatRef = "f82db71a:pg0ytacb",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 36,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:wasvuom2",
                },
                yellowSockets = 0,
            },
            {
                allowWowConversion = false,
                armorWeight = "cloth",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "1c1038a7:nxlle3j6",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Priest",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_helmet_24.blp",
                id = "pr2tcrwn",
                isTwoHanded = false,
                itemLevel = 75,
                itemSetKey = "t2_priest_dps",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 1,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Crown of Transcendence",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 1,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {
                    {
                        color = "meta",
                    },
                    {
                        color = "red",
                    },
                },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 94,
                    },
                    {
                        sourceStatRef = "f82db71a:75y3a8ib",
                        value = 14,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 14,
                    },
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:pg0ytacb",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:jjn0my8k",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:jslmczbi",
                        value = 1,
                    },
                    {
                        sourceStatRef = "f82db71a:69hfqhne",
                        value = 1,
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 49,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:bgvs1zx6",
                },
                yellowSockets = 0,
            },
            {
                allowWowConversion = false,
                armorWeight = "cloth",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "1c1038a7:nxlle3j6",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Priest",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_pants_08.blp",
                id = "pr2tpnts",
                isTwoHanded = false,
                itemLevel = 75,
                itemSetKey = "t2_priest_dps",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Pants of Transcendence",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 1,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {
                    {
                        color = "red",
                    },
                    {
                        color = "yellow",
                    },
                },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 101,
                    },
                    {
                        sourceStatRef = "f82db71a:75y3a8ib",
                        value = 20,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 15,
                    },
                    {
                        sourceStatRef = "f82db71a:pg0ytacb",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:jjn0my8k",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:jslmczbi",
                        value = 1,
                    },
                    {
                        sourceStatRef = "f82db71a:69hfqhne",
                        value = 1,
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 50,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:obmt4ntq",
                },
                yellowSockets = 1,
            },
            {
                allowWowConversion = false,
                armorWeight = "cloth",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "1c1038a7:nxlle3j6",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Priest",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_shoulder_02.blp",
                id = "pr2tmant",
                isTwoHanded = false,
                itemLevel = 75,
                itemSetKey = "t2_priest_dps",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Mantle of Transcendence",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {  },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 87,
                    },
                    {
                        sourceStatRef = "f82db71a:75y3a8ib",
                        value = 15,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 11,
                    },
                    {
                        sourceStatRef = "f82db71a:jjn0my8k",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 37,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:66i80qm1",
                },
                yellowSockets = 0,
            },
            {
                allowWowConversion = false,
                armorWeight = "cloth",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "1c1038a7:nxlle3j6",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Priest",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_belt_22.blp",
                id = "pr2tcord",
                isTwoHanded = false,
                itemLevel = 75,
                itemSetKey = "t2_priest_dps",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Cord of Transcendence",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {
                    {
                        color = "yellow",
                    },
                },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 65,
                    },
                    {
                        sourceStatRef = "f82db71a:75y3a8ib",
                        value = 15,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 18,
                    },
                    {
                        sourceStatRef = "f82db71a:jjn0my8k",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 36,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:haks0gz4",
                },
                yellowSockets = 1,
            },
            {
                allowWowConversion = false,
                armorWeight = "cloth",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "1c1038a7:nxlle3j6",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Priest",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_bracer_09.blp",
                id = "pr2tbrac",
                isTwoHanded = false,
                itemLevel = 75,
                itemSetKey = "t2_priest_dps",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Bracers of Transcendence",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {  },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 51,
                    },
                    {
                        sourceStatRef = "f82db71a:75y3a8ib",
                        value = 11,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:jslmczbi",
                        value = 1,
                    },
                    {
                        sourceStatRef = "f82db71a:69hfqhne",
                        value = 1,
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 23,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:crezt6ix",
                },
                yellowSockets = 0,
            },
            {
                allowWowConversion = false,
                armorWeight = "cloth",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "1c1038a7:nxlle3j6",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Priest",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_chest_cloth_11.blp",
                id = "v05hrobe",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "t05_priest_virtuous",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Virtuous Robe",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {  },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 93,
                    },
                    {
                        sourceStatRef = "f82db71a:75y3a8ib",
                        value = 15,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 15,
                    },
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 14,
                    },
                    {
                        sourceStatRef = "f82db71a:hj6d4kvy",
                        value = 66,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:nwfvxbto",
                },
                yellowSockets = 0,
            },
            {
                allowWowConversion = false,
                armorWeight = "cloth",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "1c1038a7:nxlle3j6",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Priest",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_boots_05.blp",
                id = "v05hboot",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "t05_priest_virtuous",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Virtuous Sandals",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {  },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 64,
                    },
                    {
                        sourceStatRef = "f82db71a:75y3a8ib",
                        value = 13,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 12,
                    },
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 12,
                    },
                    {
                        sourceStatRef = "f82db71a:hj6d4kvy",
                        value = 29,
                    },
                    {
                        sourceStatRef = "f82db71a:rgnrtg01",
                        value = 4,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:raiu9t05",
                },
                yellowSockets = 0,
            },
            {
                allowWowConversion = false,
                armorWeight = "cloth",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "1c1038a7:nxlle3j6",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Priest",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_gauntlets_14.blp",
                id = "v05hmitt",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "t05_priest_virtuous",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Virtuous Mitts",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {  },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 54,
                    },
                    {
                        sourceStatRef = "f82db71a:75y3a8ib",
                        value = 12,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 11,
                    },
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 11,
                    },
                    {
                        sourceStatRef = "f82db71a:hj6d4kvy",
                        value = 35,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:wasvuom2",
                },
                yellowSockets = 0,
            },
            {
                allowWowConversion = false,
                armorWeight = "cloth",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "1c1038a7:nxlle3j6",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Priest",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_crown_01.blp",
                id = "v05hcrow",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "t05_priest_virtuous",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Virtuous Crown",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {  },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 75,
                    },
                    {
                        sourceStatRef = "f82db71a:75y3a8ib",
                        value = 16,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 14,
                    },
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 13,
                    },
                    {
                        sourceStatRef = "f82db71a:jslmczbi",
                        value = 1,
                    },
                    {
                        sourceStatRef = "f82db71a:69hfqhne",
                        value = 1,
                    },
                    {
                        sourceStatRef = "f82db71a:hj6d4kvy",
                        value = 51,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:bgvs1zx6",
                },
                yellowSockets = 0,
            },
            {
                allowWowConversion = false,
                armorWeight = "cloth",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "1c1038a7:nxlle3j6",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Priest",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_pants_08.blp",
                id = "v05hskrt",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "t05_priest_virtuous",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Virtuous Skirt",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {  },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 81,
                    },
                    {
                        sourceStatRef = "f82db71a:75y3a8ib",
                        value = 18,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 15,
                    },
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 13,
                    },
                    {
                        sourceStatRef = "f82db71a:hj6d4kvy",
                        value = 42,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:obmt4ntq",
                },
                yellowSockets = 0,
            },
            {
                allowWowConversion = false,
                armorWeight = "cloth",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "1c1038a7:nxlle3j6",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Priest",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_shoulder_02.blp",
                id = "v05hmant",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "t05_priest_virtuous",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Virtuous Mantle",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {  },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 69,
                    },
                    {
                        sourceStatRef = "f82db71a:75y3a8ib",
                        value = 13,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 12,
                    },
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 12,
                    },
                    {
                        sourceStatRef = "f82db71a:hj6d4kvy",
                        value = 24,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:66i80qm1",
                },
                yellowSockets = 0,
            },
            {
                allowWowConversion = false,
                armorWeight = "cloth",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "1c1038a7:nxlle3j6",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Priest",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_belt_10.blp",
                id = "v05hbelt",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "t05_priest_virtuous",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Virtuous Belt",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {  },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 52,
                    },
                    {
                        sourceStatRef = "f82db71a:75y3a8ib",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 9,
                    },
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:hj6d4kvy",
                        value = 29,
                    },
                    {
                        sourceStatRef = "f82db71a:rgnrtg01",
                        value = 4,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:haks0gz4",
                },
                yellowSockets = 0,
            },
            {
                allowWowConversion = false,
                armorWeight = "cloth",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "1c1038a7:nxlle3j6",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Priest",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_belt_31.blp",
                id = "v05hbrac",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "t05_priest_virtuous",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Virtuous Bracers",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {  },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 40,
                    },
                    {
                        sourceStatRef = "f82db71a:75y3a8ib",
                        value = 9,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 8,
                    },
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 9,
                    },
                    {
                        sourceStatRef = "f82db71a:hj6d4kvy",
                        value = 24,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:crezt6ix",
                },
                yellowSockets = 0,
            },
            {
                allowWowConversion = false,
                armorWeight = "cloth",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "1c1038a7:nxlle3j6",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Priest",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_chest_cloth_11.blp",
                id = "v05dgown",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "t05_priest_virtuous",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Virtuous Gown",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {  },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 93,
                    },
                    {
                        sourceStatRef = "f82db71a:75y3a8ib",
                        value = 20,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 16,
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 43,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:nwfvxbto",
                },
                yellowSockets = 0,
            },
            {
                allowWowConversion = false,
                armorWeight = "cloth",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "1c1038a7:nxlle3j6",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Priest",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_boots_05.blp",
                id = "v05dslip",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "t05_priest_virtuous",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Virtuous Slippers",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {  },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 64,
                    },
                    {
                        sourceStatRef = "f82db71a:75y3a8ib",
                        value = 14,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 12,
                    },
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 11,
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 29,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:raiu9t05",
                },
                yellowSockets = 0,
            },
            {
                allowWowConversion = false,
                armorWeight = "cloth",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "1c1038a7:nxlle3j6",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Priest",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_gauntlets_14.blp",
                id = "v05dhnds",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "t05_priest_virtuous",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Virtuous Hands",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {  },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 54,
                    },
                    {
                        sourceStatRef = "f82db71a:75y3a8ib",
                        value = 6,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 8,
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 36,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:wasvuom2",
                },
                yellowSockets = 0,
            },
            {
                allowWowConversion = false,
                armorWeight = "cloth",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "1c1038a7:nxlle3j6",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Priest",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_crown_01.blp",
                id = "v05dcowl",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "t05_priest_virtuous",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Virtuous Cowl",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {  },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 75,
                    },
                    {
                        sourceStatRef = "f82db71a:75y3a8ib",
                        value = 19,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 13,
                    },
                    {
                        sourceStatRef = "f82db71a:wbj4zuf3",
                        value = 1,
                    },
                    {
                        sourceStatRef = "f82db71a:v2g0tw0o",
                        value = 1,
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 43,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:bgvs1zx6",
                },
                yellowSockets = 0,
            },
            {
                allowWowConversion = false,
                armorWeight = "cloth",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "1c1038a7:nxlle3j6",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Priest",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_pants_08.blp",
                id = "v05dlegs",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "t05_priest_virtuous",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Virtuous Leggings",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {  },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 81,
                    },
                    {
                        sourceStatRef = "f82db71a:75y3a8ib",
                        value = 14,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 14,
                    },
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 13,
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 36,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:obmt4ntq",
                },
                yellowSockets = 0,
            },
            {
                allowWowConversion = false,
                armorWeight = "cloth",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "1c1038a7:nxlle3j6",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Priest",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_shoulder_02.blp",
                id = "v05depau",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "t05_priest_virtuous",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Virtuous Epaulets",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {  },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 69,
                    },
                    {
                        sourceStatRef = "f82db71a:75y3a8ib",
                        value = 12,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 13,
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 26,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:66i80qm1",
                },
                yellowSockets = 0,
            },
            {
                allowWowConversion = false,
                armorWeight = "cloth",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "1c1038a7:nxlle3j6",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Priest",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_belt_10.blp",
                id = "v05dcord",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "t05_priest_virtuous",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Virtuous Cord",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {  },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 52,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 12,
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 31,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:haks0gz4",
                },
                yellowSockets = 0,
            },
            {
                allowWowConversion = false,
                armorWeight = "cloth",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "1c1038a7:nxlle3j6",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Priest",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_belt_31.blp",
                id = "v05dwrap",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "t05_priest_virtuous",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Virtuous Wraps",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {  },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 40,
                    },
                    {
                        sourceStatRef = "f82db71a:75y3a8ib",
                        value = 7,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 8,
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 23,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:crezt6ix",
                },
                yellowSockets = 0,
            }
        },
        loot = {
            {
                conditions = {},
                description = "Equal-weight Tier 0.5 Healing Priest set-piece table.",
                drawCount = 1,
                entries = {
                    { id = "v05hrobe", maxQuantity = 1, minQuantity = 1, ref = "1c1038a7:v05hrobe", type = "item", weight = 1 },
                    { id = "v05hboot", maxQuantity = 1, minQuantity = 1, ref = "1c1038a7:v05hboot", type = "item", weight = 1 },
                    { id = "v05hmitt", maxQuantity = 1, minQuantity = 1, ref = "1c1038a7:v05hmitt", type = "item", weight = 1 },
                    { id = "v05hcrow", maxQuantity = 1, minQuantity = 1, ref = "1c1038a7:v05hcrow", type = "item", weight = 1 },
                    { id = "v05hskrt", maxQuantity = 1, minQuantity = 1, ref = "1c1038a7:v05hskrt", type = "item", weight = 1 },
                    { id = "v05hmant", maxQuantity = 1, minQuantity = 1, ref = "1c1038a7:v05hmant", type = "item", weight = 1 },
                    { id = "v05hbelt", maxQuantity = 1, minQuantity = 1, ref = "1c1038a7:v05hbelt", type = "item", weight = 1 },
                    { id = "v05hbrac", maxQuantity = 1, minQuantity = 1, ref = "1c1038a7:v05hbrac", type = "item", weight = 1 },
                },
                icon = "interface/icons/inv_crown_01.blp",
                id = "pr05heal",
                items = {},
                name = "Vestments of the Virtuous - Healing",
                tags = {},
            },
            {
                conditions = {},
                description = "Equal-weight Tier 0.5 Shadow Priest set-piece table.",
                drawCount = 1,
                entries = {
                    { id = "v05dgown", maxQuantity = 1, minQuantity = 1, ref = "1c1038a7:v05dgown", type = "item", weight = 1 },
                    { id = "v05dslip", maxQuantity = 1, minQuantity = 1, ref = "1c1038a7:v05dslip", type = "item", weight = 1 },
                    { id = "v05dhnds", maxQuantity = 1, minQuantity = 1, ref = "1c1038a7:v05dhnds", type = "item", weight = 1 },
                    { id = "v05dcowl", maxQuantity = 1, minQuantity = 1, ref = "1c1038a7:v05dcowl", type = "item", weight = 1 },
                    { id = "v05dlegs", maxQuantity = 1, minQuantity = 1, ref = "1c1038a7:v05dlegs", type = "item", weight = 1 },
                    { id = "v05depau", maxQuantity = 1, minQuantity = 1, ref = "1c1038a7:v05depau", type = "item", weight = 1 },
                    { id = "v05dcord", maxQuantity = 1, minQuantity = 1, ref = "1c1038a7:v05dcord", type = "item", weight = 1 },
                    { id = "v05dwrap", maxQuantity = 1, minQuantity = 1, ref = "1c1038a7:v05dwrap", type = "item", weight = 1 },
                },
                icon = "interface/icons/inv_crown_01.blp",
                id = "pr05shdw",
                items = {},
                name = "Vestments of the Virtuous - Shadow",
                tags = {},
            },
        },
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
                learnLevel = 16,
                usesRanks = true,
                rankInterval = 8,
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
                learnLevel = 6,
                usesRanks = true,
                rankInterval = 8,
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
                learnLevel = 40,
                usesRanks = true,
                rankInterval = 8,
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
                learnLevel = 1,
                usesRanks = true,
                rankInterval = 8,
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
                learnLevel = 52,
                usesRanks = true,
                rankInterval = 8,
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
                learnLevel = 20,
                usesRanks = true,
                rankInterval = 8,
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
                learnLevel = 8,
                usesRanks = true,
                rankInterval = 8,
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
                                    coefficient = 0.7,
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
                learnLevel = 1,
                usesRanks = true,
                rankInterval = 8,
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
                                    coefficient = 0.833,
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
                learnLevel = 20,
                usesRanks = true,
                rankInterval = 8,
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
                learnLevel = 50,
                usesRanks = false,
                rankInterval = 8,
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
                learnLevel = 30,
                usesRanks = false,
                rankInterval = 8,
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
                learnLevel = 48,
                usesRanks = false,
                rankInterval = 8,
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
                learnLevel = 56,
                usesRanks = false,
                rankInterval = 8,
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
                learnLevel = 14,
                usesRanks = false,
                rankInterval = 8,
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
                learnLevel = 50,
                usesRanks = false,
                rankInterval = 8,
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
                learnLevel = 4,
                usesRanks = true,
                rankInterval = 8,
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
                learnLevel = 50,
                usesRanks = true,
                rankInterval = 8,
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
                                    coefficient = 1.82,
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
                learnLevel = 10,
                usesRanks = true,
                rankInterval = 8,
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
                                    coefficient = 1.2496,
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
                learnLevel = 44,
                usesRanks = true,
                rankInterval = 8,
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
                                    coefficient = 1.47,
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
                learnLevel = 20,
                usesRanks = true,
                rankInterval = 8,
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
                                    coefficient = 2.25,
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
                learnLevel = 50,
                usesRanks = true,
                rankInterval = 8,
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
                            auraRef = "1c1038a7:dispersa",
                            basePower = 0,
                            duration = 1,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "dspraura",
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
                            amount = 40,
                            amountMode = "base_percent",
                            resourceRef = "f82db71a:4c8mfm99",
                            targetEvents = {},
                            type = "resource"
                        },
                        key = "dsprmana",
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
                icon = "interface/icons/spell_shadow_dispersion.blp",
                id = "dispers1",
                cooldownChannel = 5,
                learnMode = "always_learned",
                learnLevel = 1,
                usesRanks = false,
                rankInterval = 8,
                mountedCombatOnly = false,
                name = "Dispersion",
                range = 0,
                resourceCosts = {},
                seedNPCSpell = false,
                spellbookCategory = "Shadow",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "1c1038a7:dispersa",
                            datasetId = "1c1038a7",
                            descriptionText = "Prevents the affected unit from casting spells. Increases Damage Reduction by 90%.",
                            duration = 1,
                            icon = "interface/icons/spell_shadow_dispersion.blp",
                            nameText = "Dispersion",
                            powerLevel = 0,
                            spellDatasetId = "1c1038a7",
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
                    mainText = "Apply Dispersion to yourself for 1 turn. Restore {RESOURCE_AMOUNT_1} to yourself.",
                    tokens = {
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
                            baseHealing = 29.25,
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.1755,
                                    statRef = "f82db71a:hj6d4kvy"
                                }
                            },
                            targetEvents = {
                                "on_heal_taken",
                                "on_critical_heal_taken"
                            },
                            threatCoefficient = 0.375,
                            type = "heal",
                            usesProjectile = false
                        },
                        key = "cohheal1",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 5,
                            minTargets = 1,
                            requiresTarget = true,
                            targetDisposition = "ally",
                            type = "multi"
                        }
                    }
                },
                conditions = {},
                cooldown = 0,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_holy_circleofrenewal.blp",
                id = "circheal",
                cooldownChannel = 2,
                learnMode = "always_learned",
                learnLevel = 1,
                usesRanks = true,
                rankInterval = 8,
                mountedCombatOnly = false,
                name = "Circle of Healing",
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
                    auraSections = {},
                    mainText = "Heal up to 5 allies for {HEAL_1} health.",
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
                            baseHealing = 45,
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.27,
                                    statRef = "f82db71a:hj6d4kvy"
                                }
                            },
                            targetEvents = {
                                "on_heal_taken",
                                "on_critical_heal_taken"
                            },
                            threatCoefficient = 0.5,
                            type = "heal",
                            usesProjectile = false
                        },
                        key = "pohheal1",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 5,
                            minTargets = 1,
                            requiresTarget = true,
                            targetDisposition = "ally",
                            type = "multi"
                        }
                    }
                },
                conditions = {},
                cooldown = 0,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_holy_prayerofhealing02.blp",
                id = "prayheal",
                cooldownChannel = 1,
                learnMode = "always_learned",
                learnLevel = 1,
                usesRanks = true,
                rankInterval = 8,
                mountedCombatOnly = false,
                name = "Prayer of Healing",
                range = 0,
                resourceCosts = {
                    {
                        amount = 21.8,
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
                    mainText = "Heal up to 5 allies for {HEAL_1} health.",
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
                            baseHealing = 120.7125,
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.666,
                                    statRef = "f82db71a:hj6d4kvy"
                                }
                            },
                            targetEvents = {
                                "on_heal_taken",
                                "on_critical_heal_taken"
                            },
                            threatCoefficient = 0.5,
                            type = "heal",
                            usesProjectile = false
                        },
                        key = "dhymheal",
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
                icon = "interface/icons/spell_holy_divinehymn.blp",
                id = "divhymn1",
                cooldownChannel = 1,
                learnMode = "always_learned",
                learnLevel = 1,
                usesRanks = true,
                rankInterval = 8,
                mountedCombatOnly = false,
                name = "Divine Hymn",
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
                spellbookCategory = "Holy",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {},
                    mainText = "Heal all allies for {HEAL_1} health.",
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
                casterEvents = {},
                charges = 0,
                components = {
                    {
                        castPhase = "on_cast_end",
                        castingGroup = "default",
                        effect = {
                            amount = 20,
                            amountMode = "base_percent",
                            resourceRef = "f82db71a:4c8mfm99",
                            targetEvents = {},
                            type = "resource"
                        },
                        key = "symmana1",
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
                icon = "interface/icons/spell_holy_symbolofhope.blp",
                id = "symhope1",
                cooldownChannel = 1,
                learnMode = "always_learned",
                learnLevel = 1,
                usesRanks = false,
                rankInterval = 8,
                mountedCombatOnly = false,
                name = "Symbol of Hope",
                range = 0,
                resourceCosts = {},
                seedNPCSpell = false,
                spellbookCategory = "Holy",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {},
                    mainText = "Restore {RESOURCE_AMOUNT_1} to all allies.",
                    tokens = {
                        {
                            applyMode = "resource_gain_amount",
                            componentIndex = 1,
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
                            auraRef = "1c1038a7:prmndau1",
                            basePower = 0,
                            duration = 5,
                            stacks = 3,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "pomaura1",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 3,
                            minTargets = 1,
                            requiresTarget = true,
                            targetDisposition = "ally",
                            type = "multi"
                        }
                    }
                },
                conditions = {},
                cooldown = 0,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_holy_prayerofmendingtga.blp",
                id = "prmend01",
                cooldownChannel = 2,
                learnMode = "always_learned",
                learnLevel = 1,
                usesRanks = false,
                rankInterval = 8,
                mountedCombatOnly = false,
                name = "Prayer of Mending",
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
                            auraRef = "1c1038a7:prmndau1",
                            datasetId = "1c1038a7",
                            descriptionText = "When the affected unit is victim of a basic attack, heal the affected unit for 2% of Max health and remove 1 stack. Applies {AURA_APPLIED_STACKS_1} stacks. Stacks up to {AURA_MAX_STACKS_1} times.",
                            duration = 5,
                            icon = "interface/icons/spell_holy_prayerofmendingtga.blp",
                            nameText = "Prayer of Mending",
                            powerLevel = 0,
                            spellDatasetId = "1c1038a7",
                            stacks = 3,
                            targetContext = {
                                object = "the affected ally",
                                possessive = "the affected ally's",
                                reflexive = "itself",
                                subject = "the affected ally"
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
                    mainText = "Apply Prayer of Mending to up to 3 allies with 3 stacks for 5 turns.",
                    tokens = {},
                    version = 1
                },
                totalTicks = 0,
                useCooldownCharges = false
            },
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
            },
            {
                automaticAuras = {},
                category = "Shadow",
                conditions = {},
                description = "",
                events = {},
                icon = "interface/icons/spell_shadow_shadowform.blp",
                id = "shadform",
                isEnvironmental = false,
                name = "Shadowform",
                skillBonuses = {},
                statBonuses = {
                    {
                        operation = "percent",
                        statRef = "f82db71a:7t7xgzcx",
                        value = 15
                    },
                    {
                        statRef = "f82db71a:5pxmfw02",
                        value = -100
                    },
                    {
                        statRef = "f82db71a:pu05li08",
                        value = 15
                    }
                },
                unlockLevel = 1
            },
            {
                automaticAuras = {},
                category = "Shadow",
                conditions = {},
                description = "",
                events = {
                    {
                        chance = 100,
                        combatEventId = "on_damage_type",
                        damageSchoolRef = "f82db71a:1ggt4t3v",
                        effects = {
                            {
                                auraRef = "1c1038a7:shdwvau1",
                                basePower = 0,
                                duration = 5,
                                stacks = 1,
                                type = "apply_aura"
                            }
                        },
                        triggerTarget = "event_other"
                    }
                },
                icon = "interface/icons/spell_shadow_blackplague.blp",
                id = "shdweav1",
                isEnvironmental = false,
                name = "Shadow Weaving",
                skillBonuses = {},
                statBonuses = {},
                unlockLevel = 1
            },
            {
                automaticAuras = {},
                category = "Shadow",
                conditions = {},
                description = "",
                events = {
                    {
                        chance = 5,
                        combatEventId = "on_damage_type",
                        damageSchoolRef = "f82db71a:1ggt4t3v",
                        effects = {
                            {
                                auraRef = "1c1038a7:blckouta",
                                basePower = 0,
                                duration = 1,
                                stacks = 1,
                                type = "apply_aura"
                            }
                        },
                        triggerTarget = "event_other"
                    }
                },
                icon = "interface/icons/spell_shadow_gathershadows.blp",
                id = "blackout",
                isEnvironmental = false,
                name = "Blackout",
                skillBonuses = {},
                statBonuses = {},
                unlockLevel = 1
            },
        },
        units = {},
        weaponTypes = {}
    },
})
