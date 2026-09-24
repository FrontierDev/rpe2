local _, Addon = ...

Addon.Data.DefaultDatasets:Register({
    version = 36,
    dataset = {
        achievements = {},
        auras = {
            {
                description = "",
                duration = 5,
                effects = {
                    {
                        amountMode = "flat",
                        baseDamage = 17.68,
                        damageSchoolRefs = {
                            "f82db71a:esjguw6d"
                        },
                        statScaling = {
                            {
                                coefficient = 0.884,
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
                duration = 3,
                effects = {
                    {
                        amountMode = "flat",
                        baseDamage = 28.1667,
                        damageSchoolRefs = {
                            "f82db71a:esjguw6d"
                        },
                        statScaling = {
                            {
                                coefficient = 0.845,
                                statRef = "f82db71a:7t7xgzcx"
                            }
                        },
                        type = "damage"
                    }
                },
                events = {},
                icon = "interface/icons/spell_fire_incinerate.blp",
                id = "ignite01",
                maxStacks = 1,
                name = "Ignite",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
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
                icon = "interface/icons/spell_fire_meteorstorm.blp",
                id = "impact01",
                maxStacks = 1,
                name = "Impact",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
            },
            {
                description = "",
                duration = 5,
                effects = {
                    {
                        amountMode = "flat",
                        baseDamage = 17.68,
                        damageSchoolRefs = {
                            "f82db71a:esjguw6d"
                        },
                        statScaling = {
                            {
                                coefficient = 0.884,
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
                                coefficient = 0.52,
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
                                coefficient = 0.52,
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
            },
            {
                description = "Increases Armor and Frost Resistance. On melee hit taken, apply Chilled to the attacker.",
                duration = 10,
                effects = {
                    {
                        baseAmount = 30,
                        operation = "percent",
                        scaleWithRank = true,
                        statRef = "f82db71a:v42albuv",
                        statScaling = {},
                        type = "stat"
                    },
                    {
                        baseAmount = 30,
                        operation = "flat",
                        scaleWithRank = false,
                        statRef = "f82db71a:jjn0my8k",
                        statScaling = {},
                        type = "stat"
                    }
                },
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
                id = "icearmra",
                maxStacks = 1,
                name = "Ice Armor",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Increases Armor by {AURA_STAT_1}% and Frost Resistance by {AURA_STAT_2}. On melee hit taken, apply Chilled to the attacker.",
                    bodyTokens = {
                        {
                            applyMode = "stat_amount",
                            baseField = "baseAmount",
                            effectIndex = 1,
                            key = "AURA_STAT_1",
                            tokenType = "aura_amount"
                        },
                        {
                            applyMode = "stat_amount",
                            baseField = "baseAmount",
                            effectIndex = 2,
                            key = "AURA_STAT_2",
                            tokenType = "aura_amount"
                        }
                    },
                    stackingText = "",
                    stackingTokens = {},
                    version = 1
                }
            },
            {
                description = "Increases Spell Crit. Chance by 5%. On melee hit taken, deal Fire damage to the attacker.",
                duration = 10,
                effects = {
                    {
                        baseAmount = 5,
                        operation = "flat",
                        scaleWithRank = false,
                        statRef = "f82db71a:69hfqhne",
                        statScaling = {},
                        type = "stat"
                    }
                },
                events = {
                    {
                        combatEventId = "on_melee_taken",
                        effects = {
                            {
                                amountMode = "flat",
                                baseDamage = 28.1667,
                                damageSchoolRefs = {
                                    "f82db71a:esjguw6d"
                                },
                                scaleWithRank = true,
                                statScaling = {
                                    {
                                        coefficient = 0.845,
                                        statRef = "f82db71a:7t7xgzcx"
                                    }
                                },
                                type = "damage"
                            }
                        },
                        triggerTarget = "event_source"
                    }
                },
                icon = "interface/icons/ability_mage_moltenarmor.blp",
                id = "molarmra",
                maxStacks = 1,
                name = "Molten Armor",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Increases Spell Crit. Chance by 5%. On melee hit taken, deal {AURA_EVENT_DAMAGE_1} Fire damage to the attacker.",
                    bodyTokens = {
                        {
                            applyMode = "damage_amount",
                            baseField = "baseDamage",
                            effectIndex = 1,
                            eventIndex = 1,
                            key = "AURA_EVENT_DAMAGE_1",
                            tokenType = "aura_amount"
                        }
                    },
                    stackingText = "",
                    stackingTokens = {},
                    version = 1
                }
            },
            {
                description = "Increases Magic Resistance by 2% and Resource Regeneration by 30%.",
                duration = 10,
                effects = {
                    {
                        baseAmount = 2,
                        operation = "flat",
                        statRef = "f82db71a:zs1nbz13",
                        statScaling = {},
                        type = "stat"
                    },
                    {
                        baseAmount = 30,
                        operation = "flat",
                        statRef = "f82db71a:rgnrtg01",
                        statScaling = {},
                        type = "stat"
                    }
                },
                events = {},
                icon = "interface/icons/spell_magearmor.blp",
                id = "mgarmaur",
                maxStacks = 1,
                name = "Mage Armor",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Increases Magic Resistance by 2% and Resource Regeneration by 30%.",
                    bodyTokens = {},
                    stackingText = "",
                    stackingTokens = {},
                    version = 1
                }
            },
            {
                description = "Breaks when the affected unit takes damage. Prevents the affected unit from casting spells. Sets the affected unit's movement range to 0. Causes all attacks against the affected unit to automatically hit.",
                duration = 2,
                effects = {
                    {
                        cancelOnDamage = true,
                        forceAutoHitAgainstTarget = true,
                        movementRangeOverride = 0,
                        preventCasting = true,
                        statScaling = {},
                        type = "control"
                    }
                },
                events = {},
                icon = "interface/icons/spell_nature_polymorph.blp",
                id = "polymrph",
                maxStacks = 1,
                name = "Polymorph",
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
                    "d7c874c4:mastelms",
                    "d7c874c4:ignite20",
                    "d7c874c4:impact05"
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
        items = {
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
                            "vtrjl3l2:02p0r8a2",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Mage",
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
                id = "mg2drobe",
                isTwoHanded = false,
                itemLevel = 75,
                itemSetKey = "t2_mage_dps",
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
                name = "Netherwind Robes",
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
                        value = 8,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 7,
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
                        sourceStatRef = "f82db71a:69hfqhne",
                        value = 2,
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
                            "vtrjl3l2:02p0r8a2",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Mage",
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
                id = "mg2dboot",
                isTwoHanded = false,
                itemLevel = 75,
                itemSetKey = "t2_mage_dps",
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
                name = "Netherwind Boots",
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
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 8,
                    },
                    {
                        sourceStatRef = "f82db71a:pg0ytacb",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:69hfqhne",
                        value = 1,
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 30,
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
                            "vtrjl3l2:02p0r8a2",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Mage",
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
                id = "mg2dglov",
                isTwoHanded = false,
                itemLevel = 75,
                itemSetKey = "t2_mage_dps",
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
                name = "Netherwind Gloves",
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
                        value = 10,
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
                        sourceStatRef = "f82db71a:69hfqhne",
                        value = 1,
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 32,
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
                            "vtrjl3l2:02p0r8a2",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Mage",
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
                icon = "interface/icons/inv_helmet_70.blp",
                id = "mg2dcrwn",
                isTwoHanded = false,
                itemLevel = 75,
                itemSetKey = "t2_mage_dps",
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
                name = "Netherwind Crown",
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
                        value = 17,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 13,
                    },
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 8,
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
                        sourceStatRef = "f82db71a:69hfqhne",
                        value = 1,
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 39,
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
                            "vtrjl3l2:02p0r8a2",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Mage",
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
                id = "mg2dpant",
                isTwoHanded = false,
                itemLevel = 75,
                itemSetKey = "t2_mage_dps",
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
                name = "Netherwind Pants",
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
                        value = 18,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 17,
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
                        sourceStatRef = "f82db71a:69hfqhne",
                        value = 1,
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 40,
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
                            "vtrjl3l2:02p0r8a2",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Mage",
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
                icon = "interface/icons/inv_shoulder_32.blp",
                id = "mg2dmant",
                isTwoHanded = false,
                itemLevel = 75,
                itemSetKey = "t2_mage_dps",
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
                name = "Netherwind Mantle",
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
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 8,
                    },
                    {
                        sourceStatRef = "f82db71a:jjn0my8k",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:69hfqhne",
                        value = 1,
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
                            "vtrjl3l2:02p0r8a2",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Mage",
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
                icon = "interface/icons/inv_belt_30.blp",
                id = "mg2dbelt",
                isTwoHanded = false,
                itemLevel = 75,
                itemSetKey = "t2_mage_dps",
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
                name = "Netherwind Belt",
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
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:jjn0my8k",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:v2g0tw0o",
                        value = 1,
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 34,
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
                            "vtrjl3l2:02p0r8a2",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Mage",
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
                id = "mg2dbind",
                isTwoHanded = false,
                itemLevel = 75,
                itemSetKey = "t2_mage_dps",
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
                name = "Netherwind Bindings",
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
                        value = 8,
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
                    "f82db71a:crezt6ix",
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
                            "vtrjl3l2:02p0r8a2",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Mage",
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
                id = "mg2hvest",
                isTwoHanded = false,
                itemLevel = 75,
                itemSetKey = "t2_mage_healer",
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
                name = "Netherwind Vestments",
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
                        value = 15,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 15,
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
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 44,
                    },
                    {
                        sourceStatRef = "f82db71a:hj6d4kvy",
                        value = 44,
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
                            "vtrjl3l2:02p0r8a2",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Mage",
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
                id = "mg2hslip",
                isTwoHanded = false,
                itemLevel = 75,
                itemSetKey = "t2_mage_healer",
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
                name = "Netherwind Slippers",
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
                        value = 15,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 8,
                    },
                    {
                        sourceStatRef = "f82db71a:pg0ytacb",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 33,
                    },
                    {
                        sourceStatRef = "f82db71a:hj6d4kvy",
                        value = 33,
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
                            "vtrjl3l2:02p0r8a2",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Mage",
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
                id = "mg2hmitt",
                isTwoHanded = false,
                itemLevel = 75,
                itemSetKey = "t2_mage_healer",
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
                name = "Netherwind Mitts",
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
                        value = 11,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 11,
                    },
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 6,
                    },
                    {
                        sourceStatRef = "f82db71a:pg0ytacb",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 35,
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
                            "vtrjl3l2:02p0r8a2",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Mage",
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
                icon = "interface/icons/inv_helmet_70.blp",
                id = "mg2hmask",
                isTwoHanded = false,
                itemLevel = 75,
                itemSetKey = "t2_mage_healer",
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
                name = "Netherwind Mask",
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
                        value = 15,
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
                        sourceStatRef = "f82db71a:pg0ytacb",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:jjn0my8k",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 44,
                    },
                    {
                        sourceStatRef = "f82db71a:hj6d4kvy",
                        value = 44,
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
                            "vtrjl3l2:02p0r8a2",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Mage",
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
                id = "mg2hlegs",
                isTwoHanded = false,
                itemLevel = 75,
                itemSetKey = "t2_mage_healer",
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
                name = "Netherwind Leggings",
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
                        value = 13,
                    },
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 8,
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
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 44,
                    },
                    {
                        sourceStatRef = "f82db71a:hj6d4kvy",
                        value = 44,
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
                            "vtrjl3l2:02p0r8a2",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Mage",
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
                icon = "interface/icons/inv_shoulder_32.blp",
                id = "mg2hshld",
                isTwoHanded = false,
                itemLevel = 75,
                itemSetKey = "t2_mage_healer",
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
                name = "Netherwind Shoulders",
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
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 8,
                    },
                    {
                        sourceStatRef = "f82db71a:jjn0my8k",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 35,
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
                            "vtrjl3l2:02p0r8a2",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Mage",
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
                icon = "interface/icons/inv_belt_30.blp",
                id = "mg2hsash",
                isTwoHanded = false,
                itemLevel = 75,
                itemSetKey = "t2_mage_healer",
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
                name = "Netherwind Sash",
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
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 8,
                    },
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 8,
                    },
                    {
                        sourceStatRef = "f82db71a:jjn0my8k",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 36,
                    },
                    {
                        sourceStatRef = "f82db71a:hj6d4kvy",
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
                            "vtrjl3l2:02p0r8a2",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Mage",
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
                id = "mg2hwrap",
                isTwoHanded = false,
                itemLevel = 75,
                itemSetKey = "t2_mage_healer",
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
                name = "Netherwind Wraps",
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
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 8,
                    },
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 8,
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 27,
                    },
                    {
                        sourceStatRef = "f82db71a:hj6d4kvy",
                        value = 27,
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
                            "vtrjl3l2:02p0r8a2",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Mage",
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
                icon = "interface/icons/inv_chest_cloth_25.blp",
                id = "m05drobe",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "t05_mage_sorcerers",
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
                name = "Sorcerer's Robes",
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
                        value = 12,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 11,
                    },
                    {
                        sourceStatRef = "f82db71a:69hfqhne",
                        value = 1,
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 35,
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
                            "vtrjl3l2:02p0r8a2",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Mage",
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
                icon = "interface/icons/inv_boots_02.blp",
                id = "m05dsand",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "t05_mage_sorcerers",
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
                name = "Sorcerer's Sandals",
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
                        value = 11,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 8,
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
                            "vtrjl3l2:02p0r8a2",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Mage",
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
                icon = "interface/icons/inv_gauntlets_17.blp",
                id = "m05dgaun",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "t05_mage_sorcerers",
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
                name = "Sorcerer's Gauntlets",
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
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 27,
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
                            "vtrjl3l2:02p0r8a2",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Mage",
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
                icon = "interface/icons/inv_crown_02.blp",
                id = "m05dcrow",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "t05_mage_sorcerers",
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
                name = "Sorcerer's Crown",
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
                        value = 18,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 12,
                    },
                    {
                        sourceStatRef = "f82db71a:69hfqhne",
                        value = 1,
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 33,
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
                            "vtrjl3l2:02p0r8a2",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Mage",
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
                icon = "interface/icons/inv_pants_06.blp",
                id = "m05dlegs",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "t05_mage_sorcerers",
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
                name = "Sorcerer's Leggings",
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
                        value = 17,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 11,
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 32,
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
                            "vtrjl3l2:02p0r8a2",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Mage",
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
                icon = "interface/icons/inv_shoulder_23.blp",
                id = "m05dmant",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "t05_mage_sorcerers",
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
                name = "Sorcerer's Mantle",
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
                        value = 8,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 6,
                    },
                    {
                        sourceStatRef = "f82db71a:69hfqhne",
                        value = 1,
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 19,
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
                            "vtrjl3l2:02p0r8a2",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Mage",
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
                icon = "interface/icons/inv_belt_08.blp",
                id = "m05dbelt",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "t05_mage_sorcerers",
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
                name = "Sorcerer's Belt",
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
                        value = 14,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 8,
                    },
                    {
                        sourceStatRef = "f82db71a:v2g0tw0o",
                        value = 1,
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
                            "vtrjl3l2:02p0r8a2",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Mage",
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
                icon = "interface/icons/inv_jewelry_ring_23.blp",
                id = "m05dbind",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "t05_mage_sorcerers",
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
                name = "Sorcerer's Bindings",
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
                        value = 8,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 6,
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 19,
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
                            "vtrjl3l2:02p0r8a2",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Mage",
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
                icon = "interface/icons/inv_chest_cloth_25.blp",
                id = "m05hchst",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "t05_mage_sorcerers",
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
                name = "Sorcerer's Chest",
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
                        value = 25,
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
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 16,
                    },
                    {
                        sourceStatRef = "f82db71a:hj6d4kvy",
                        value = 16,
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
                            "vtrjl3l2:02p0r8a2",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Mage",
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
                icon = "interface/icons/inv_boots_02.blp",
                id = "m05hboot",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "t05_mage_sorcerers",
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
                name = "Sorcerer's Boots",
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
                        value = 16,
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
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 21,
                    },
                    {
                        sourceStatRef = "f82db71a:hj6d4kvy",
                        value = 21,
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
                            "vtrjl3l2:02p0r8a2",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Mage",
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
                icon = "interface/icons/inv_gauntlets_17.blp",
                id = "m05hglov",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "t05_mage_sorcerers",
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
                name = "Sorcerer's Gloves",
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
                        value = 14,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 12,
                    },
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:v2g0tw0o",
                        value = 1,
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 12,
                    },
                    {
                        sourceStatRef = "f82db71a:hj6d4kvy",
                        value = 12,
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
                            "vtrjl3l2:02p0r8a2",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Mage",
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
                icon = "interface/icons/inv_crown_02.blp",
                id = "m05hhelm",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "t05_mage_sorcerers",
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
                name = "Sorcerer's Helm",
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
                        value = 25,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 16,
                    },
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 14,
                    },
                    {
                        sourceStatRef = "f82db71a:69hfqhne",
                        value = 1,
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 11,
                    },
                    {
                        sourceStatRef = "f82db71a:hj6d4kvy",
                        value = 11,
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
                            "vtrjl3l2:02p0r8a2",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Mage",
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
                icon = "interface/icons/inv_pants_06.blp",
                id = "m05hlegs",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "t05_mage_sorcerers",
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
                name = "Sorcerer's Legs",
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
                        value = 22,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 17,
                    },
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 16,
                    },
                    {
                        sourceStatRef = "f82db71a:hj6d4kvy",
                        value = 16,
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
                            "vtrjl3l2:02p0r8a2",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Mage",
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
                icon = "interface/icons/inv_shoulder_23.blp",
                id = "m05hshld",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "t05_mage_sorcerers",
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
                name = "Sorcerer's Shoulders",
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
                        value = 17,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 11,
                    },
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 7,
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 9,
                    },
                    {
                        sourceStatRef = "f82db71a:hj6d4kvy",
                        value = 9,
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
                            "vtrjl3l2:02p0r8a2",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Mage",
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
                icon = "interface/icons/inv_belt_08.blp",
                id = "m05hwais",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "t05_mage_sorcerers",
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
                name = "Sorcerer's Waist",
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
                        value = 14,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 12,
                    },
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 7,
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 14,
                    },
                    {
                        sourceStatRef = "f82db71a:hj6d4kvy",
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
                            "vtrjl3l2:02p0r8a2",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Mage",
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
                icon = "interface/icons/inv_jewelry_ring_23.blp",
                id = "m05hwris",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "t05_mage_sorcerers",
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
                name = "Sorcerer's Wrists",
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
                        value = 12,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 8,
                    },
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 5,
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 8,
                    },
                    {
                        sourceStatRef = "f82db71a:hj6d4kvy",
                        value = 8,
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
                description = "Equal-weight Tier 0.5 DPS Mage set-piece table.",
                drawCount = 1,
                entries = {
                    { id = "m05drobe", maxQuantity = 1, minQuantity = 1, ref = "d7c874c4:m05drobe", type = "item", weight = 1 },
                    { id = "m05dsand", maxQuantity = 1, minQuantity = 1, ref = "d7c874c4:m05dsand", type = "item", weight = 1 },
                    { id = "m05dgaun", maxQuantity = 1, minQuantity = 1, ref = "d7c874c4:m05dgaun", type = "item", weight = 1 },
                    { id = "m05dcrow", maxQuantity = 1, minQuantity = 1, ref = "d7c874c4:m05dcrow", type = "item", weight = 1 },
                    { id = "m05dlegs", maxQuantity = 1, minQuantity = 1, ref = "d7c874c4:m05dlegs", type = "item", weight = 1 },
                    { id = "m05dmant", maxQuantity = 1, minQuantity = 1, ref = "d7c874c4:m05dmant", type = "item", weight = 1 },
                    { id = "m05dbelt", maxQuantity = 1, minQuantity = 1, ref = "d7c874c4:m05dbelt", type = "item", weight = 1 },
                    { id = "m05dbind", maxQuantity = 1, minQuantity = 1, ref = "d7c874c4:m05dbind", type = "item", weight = 1 },
                },
                icon = "interface/icons/inv_crown_02.blp",
                id = "mg05dps1",
                items = {},
                name = "Sorcerer's Regalia - DPS",
                tags = {},
            },
            {
                conditions = {},
                description = "Equal-weight Tier 0.5 Healing Mage set-piece table.",
                drawCount = 1,
                entries = {
                    { id = "m05hchst", maxQuantity = 1, minQuantity = 1, ref = "d7c874c4:m05hchst", type = "item", weight = 1 },
                    { id = "m05hboot", maxQuantity = 1, minQuantity = 1, ref = "d7c874c4:m05hboot", type = "item", weight = 1 },
                    { id = "m05hglov", maxQuantity = 1, minQuantity = 1, ref = "d7c874c4:m05hglov", type = "item", weight = 1 },
                    { id = "m05hhelm", maxQuantity = 1, minQuantity = 1, ref = "d7c874c4:m05hhelm", type = "item", weight = 1 },
                    { id = "m05hlegs", maxQuantity = 1, minQuantity = 1, ref = "d7c874c4:m05hlegs", type = "item", weight = 1 },
                    { id = "m05hshld", maxQuantity = 1, minQuantity = 1, ref = "d7c874c4:m05hshld", type = "item", weight = 1 },
                    { id = "m05hwais", maxQuantity = 1, minQuantity = 1, ref = "d7c874c4:m05hwais", type = "item", weight = 1 },
                    { id = "m05hwris", maxQuantity = 1, minQuantity = 1, ref = "d7c874c4:m05hwris", type = "item", weight = 1 },
                },
                icon = "interface/icons/inv_crown_02.blp",
                id = "mg05heal",
                items = {},
                name = "Sorcerer's Regalia - Healing",
                tags = {},
            },
        },
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
                            baseDamage = 120.488,
                            damageSchoolRefs = {
                                "f82db71a:esjguw6d"
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
                                "on_critical_heal_taken"
                            },
                            threatCoefficient = 1,
                            type = "damage",
                            usesProjectile = false,
                            weaponDamageCoefficient = 0,
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
                learnLevel = 1,
                usesRanks = true,
                rankInterval = 8,
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
                                    coefficient = 2.6776,
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
                            weaponDamageCoefficient = 0,
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
                learnLevel = 20,
                usesRanks = true,
                rankInterval = 8,
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
                            baseDamage = 104,
                            damageSchoolRefs = {
                                "f82db71a:esjguw6d"
                            },
                            damageType = "spell",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 1.04,
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
                            weaponDamageCoefficient = 0,
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
                learnLevel = 6,
                usesRanks = true,
                rankInterval = 8,
                mountedCombatOnly = false,
                name = "Fire Blast",
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
                            baseDamage = 89.25,
                            damageSchoolRefs = {
                                "f82db71a:esjguw6d"
                            },
                            damageType = "spell",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.8926,
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
                            weaponDamageCoefficient = 0,
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
                learnLevel = 22,
                usesRanks = true,
                rankInterval = 8,
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
                learnLevel = 40,
                usesRanks = false,
                rankInterval = 8,
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
                                    coefficient = 0.63,
                                    statRef = "f82db71a:7t7xgzcx"
                                }
                            },
                            targetEvents = {
                                "on_spell_taken"
                            },
                            threatCoefficient = 1,
                            type = "damage",
                            usesProjectile = false,
                            weaponDamageCoefficient = 0,
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
                learnLevel = 16,
                usesRanks = true,
                rankInterval = 8,
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
                    mainText = "Deal {DAMAGE_1} Fire damage to up to 5 enemies. Targets must share the same raid marker.",
                    mainText = "Deal {DAMAGE_1} Fire damage to up to 5 enemies. Targets must share the same raid marker.",
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
                            baseDamage = 40.163,
                            damageSchoolRefs = {
                                "f82db71a:dtxhglqg"
                            },
                            damageType = "spell",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.4016,
                                    statRef = "f82db71a:7t7xgzcx"
                                }
                            },
                            targetEvents = {
                                "on_spell_taken"
                            },
                            threatCoefficient = 1,
                            type = "damage",
                            usesProjectile = false,
                            weaponDamageCoefficient = 0,
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
                learnLevel = 14,
                usesRanks = true,
                rankInterval = 8,
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
                            threatCoefficient = 0.375,
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
                learnLevel = 20,
                usesRanks = true,
                rankInterval = 8,
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
                            threatCoefficient = 0.375,
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
                learnLevel = 22,
                usesRanks = true,
                rankInterval = 8,
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
                            baseDamage = 120.488,
                            damageSchoolRefs = {
                                "f82db71a:dtxhglqg"
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
                                "on_critical_heal_taken"
                            },
                            threatCoefficient = 1,
                            type = "damage",
                            usesProjectile = false,
                            weaponDamageCoefficient = 0,
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
                learnLevel = 52,
                usesRanks = true,
                rankInterval = 8,
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
                            baseDamage = 191.25,
                            damageSchoolRefs = {
                                "f82db71a:dtxhglqg"
                            },
                            damageType = "spell",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 1.9126,
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
                learnLevel = 60,
                usesRanks = true,
                rankInterval = 8,
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
                            baseDamage = 55.25,
                            damageSchoolRefs = {
                                "f82db71a:dtxhglqg"
                            },
                            damageType = "spell",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.5526,
                                    statRef = "f82db71a:7t7xgzcx"
                                }
                            },
                            targetEvents = {
                                "on_spell_taken",
                                "on_critical_hit_taken"
                            },
                            threatCoefficient = 0.75,
                            type = "damage",
                            usesProjectile = false,
                            weaponDamageCoefficient = 0,
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
                cooldownChannel = 4,
                learnMode = "always_learned",
                learnLevel = 8,
                usesRanks = true,
                rankInterval = 8,
                mountedCombatOnly = false,
                name = "Arcane Missiles",
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
                            baseDamage = 353.813,
                            damageSchoolRefs = {
                                "f82db71a:dtxhglqg"
                            },
                            damageType = "spell",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 3.5382,
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
                learnLevel = 60,
                usesRanks = true,
                rankInterval = 8,
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
                learnLevel = 20,
                usesRanks = false,
                rankInterval = 8,
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
                learnLevel = 24,
                usesRanks = false,
                rankInterval = 8,
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
                learnLevel = 1,
                usesRanks = false,
                rankInterval = 8,
                mountedCombatOnly = false,
                name = "Arcane Intellect",
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
                                    coefficient = 1.19,
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
                learnLevel = 4,
                usesRanks = true,
                rankInterval = 8,
                mountedCombatOnly = false,
                name = "Frostbolt",
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
                            baseDamage = 45.996,
                            damageSchoolRefs = {
                                "f82db71a:hx7pnwv4"
                            },
                            damageType = "spell",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.46,
                                    statRef = "f82db71a:7t7xgzcx"
                                }
                            },
                            targetEvents = {
                                "on_spell_taken"
                            },
                            threatCoefficient = 0.75,
                            type = "damage",
                            usesProjectile = false,
                            weaponDamageCoefficient = 0,
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
                learnLevel = 10,
                usesRanks = true,
                rankInterval = 8,
                mountedCombatOnly = false,
                name = "Frost Nova",
                range = 0,
                resourceCosts = {
                    {
                        amount = 22.7,
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
                learnLevel = 60,
                usesRanks = false,
                rankInterval = 8,
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
                            baseDamage = 68.25,
                            damageSchoolRefs = {
                                "f82db71a:hx7pnwv4"
                            },
                            damageType = "spell",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.6826,
                                    statRef = "f82db71a:7t7xgzcx"
                                }
                            },
                            targetEvents = {
                                "on_spell_taken",
                                "on_critical_hit_taken"
                            },
                            threatCoefficient = 0.75,
                            type = "damage",
                            usesProjectile = false,
                            weaponDamageCoefficient = 0,
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
                learnLevel = 54,
                usesRanks = true,
                rankInterval = 8,
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
                                    coefficient = 0.612,
                                    statRef = "f82db71a:7t7xgzcx"
                                }
                            },
                            targetEvents = {
                                "on_spell_taken"
                            },
                            threatCoefficient = 1,
                            type = "damage",
                            usesProjectile = false,
                            weaponDamageCoefficient = 0,
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
                learnLevel = 26,
                usesRanks = true,
                rankInterval = 8,
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
                            baseDamage = 271.097,
                            damageSchoolRefs = {
                                "f82db71a:hx7pnwv4"
                            },
                            damageType = "spell",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 2.8114,
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
                learnLevel = 58,
                usesRanks = true,
                rankInterval = 8,
                mountedCombatOnly = false,
                name = "Glacial Spike",
                range = 0,
                resourceCosts = {
                    {
                        amount = 9.2,
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
                casterEvents = {},
                charges = 0,
                components = {
                    {
                        castPhase = "on_cast_end",
                        castingGroup = "default",
                        effect = {
                            auraRef = "d7c874c4:icearmra",
                            basePower = 0,
                            duration = 10,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "icearm01",
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
                cooldownGroup = "magearmor",
                cooldownScalesWithHaste = false,
                description = "Increases Armor and Frost Resistance. On melee hit taken, apply Chilled to the attacker.",
                icon = "interface/icons/spell_frost_frostarmor02.blp",
                id = "icearm01",
                cooldownChannel = 3,
                learnMode = "always_learned",
                learnLevel = 30,
                usesRanks = true,
                rankInterval = 8,
                mountedCombatOnly = false,
                name = "Ice Armor",
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
                            auraRef = "d7c874c4:icearmra",
                            datasetId = "d7c874c4",
                            descriptionText = "Increases Armor by {AURA_STAT_1}% and Frost Resistance by {AURA_STAT_2}. On melee hit taken, apply Chilled to the attacker.",
                            duration = 10,
                            icon = "interface/icons/spell_frost_frostarmor02.blp",
                            nameText = "Ice Armor",
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
                                    applyMode = "stat_amount",
                                    baseField = "baseAmount",
                                    effectIndex = 1,
                                    key = "AURA_STAT_1",
                                    tokenType = "aura_amount"
                                },
                                {
                                    applyMode = "stat_amount",
                                    baseField = "baseAmount",
                                    effectIndex = 2,
                                    key = "AURA_STAT_2",
                                    tokenType = "aura_amount"
                                }
                            }
                        }
                    },
                    mainText = "Apply Ice Armor to yourself for 10 turns.",
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
                            auraRef = "d7c874c4:molarmra",
                            basePower = 0,
                            duration = 10,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "molarm01",
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
                cooldownGroup = "magearmor",
                cooldownScalesWithHaste = false,
                description = "Increases Spell Crit. Chance by 5%. On melee hit taken, deal Fire damage to the attacker.",
                icon = "interface/icons/ability_mage_moltenarmor.blp",
                id = "molarm01",
                cooldownChannel = 3,
                learnMode = "always_learned",
                learnLevel = 50,
                usesRanks = true,
                rankInterval = 8,
                mountedCombatOnly = false,
                name = "Molten Armor",
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
                            auraRef = "d7c874c4:molarmra",
                            datasetId = "d7c874c4",
                            descriptionText = "Increases Spell Crit. Chance by 5%. On melee hit taken, deal {AURA_EVENT_DAMAGE_1} Fire damage to the attacker.",
                            duration = 10,
                            icon = "interface/icons/ability_mage_moltenarmor.blp",
                            nameText = "Molten Armor",
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
                                    applyMode = "damage_amount",
                                    baseField = "baseDamage",
                                    effectIndex = 1,
                                    eventIndex = 1,
                                    key = "AURA_EVENT_DAMAGE_1",
                                    tokenType = "aura_amount"
                                }
                            }
                        }
                    },
                    mainText = "Apply Molten Armor to yourself for 10 turns.",
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
                            auraRef = "d7c874c4:mgarmaur",
                            basePower = 0,
                            duration = 10,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "mgarma01",
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
                cooldownGroup = "magearmor",
                cooldownScalesWithHaste = false,
                description = "Increases Magic Resistance by 2% and Resource Regeneration by 30%.",
                icon = "interface/icons/spell_magearmor.blp",
                id = "mgarma01",
                cooldownChannel = 3,
                learnMode = "always_learned",
                learnLevel = 34,
                usesRanks = false,
                rankInterval = 8,
                mountedCombatOnly = false,
                name = "Mage Armor",
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
                            auraRef = "d7c874c4:mgarmaur",
                            datasetId = "d7c874c4",
                            descriptionText = "Increases Magic Resistance by 2% and Resource Regeneration by 30%.",
                            duration = 10,
                            icon = "interface/icons/spell_magearmor.blp",
                            nameText = "Mage Armor",
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
                    mainText = "Apply Mage Armor to yourself for 10 turns.",
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
                            auraRef = "d7c874c4:polymrph",
                            basePower = 0,
                            duration = 2,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "polymr01",
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
                cooldown = 6,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_nature_polymorph.blp",
                id = "polymr01",
                cooldownChannel = 1,
                learnMode = "always_learned",
                learnLevel = 8,
                usesRanks = false,
                rankInterval = 8,
                mountedCombatOnly = false,
                name = "Polymorph",
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
                            auraRef = "d7c874c4:polymrph",
                            datasetId = "d7c874c4",
                            descriptionText = "Breaks when the affected unit takes damage. Prevents the affected unit from casting spells. Sets the affected unit's movement range to 0. Causes all attacks against the affected unit to automatically hit.",
                            duration = 2,
                            icon = "interface/icons/spell_nature_polymorph.blp",
                            nameText = "Polymorph",
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
                    mainText = "Apply Polymorph to an enemy for 2 turns.",
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
                category = "Fire",
                conditions = {},
                description = "",
                events = {
                    {
                        chance = 20,
                        combatEventId = "on_damage_type",
                        damageSchoolRef = "f82db71a:esjguw6d",
                        effects = {
                            {
                                auraRef = "d7c874c4:ignite01",
                                basePower = 0,
                                duration = 3,
                                stacks = 1,
                                type = "apply_aura"
                            }
                        },
                        triggerTarget = "event_other"
                    }
                },
                icon = "interface/icons/spell_fire_incinerate.blp",
                id = "ignite20",
                isEnvironmental = false,
                name = "Ignite",
                skillBonuses = {},
                statBonuses = {},
                unlockLevel = 1
            },
            {
                automaticAuras = {},
                category = "Fire",
                conditions = {},
                description = "",
                events = {
                    {
                        chance = 5,
                        combatEventId = "on_damage_type",
                        damageSchoolRef = "f82db71a:esjguw6d",
                        effects = {
                            {
                                auraRef = "d7c874c4:impact01",
                                basePower = 0,
                                duration = 1,
                                stacks = 1,
                                type = "apply_aura"
                            }
                        },
                        triggerTarget = "event_other"
                    }
                },
                icon = "interface/icons/spell_fire_meteorstorm.blp",
                id = "impact05",
                isEnvironmental = false,
                name = "Impact",
                skillBonuses = {},
                statBonuses = {},
                unlockLevel = 1
            },
        },
        units = {},
        weaponTypes = {}
    },
})
