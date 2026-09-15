local _, Addon = ...

Addon.Data.DefaultDatasets:Register({
    version = 10,
    dataset = {
        achievements = {},
        auras = {
            {
                description = "",
                duration = 10,
                effects = {
                    {
                        baseAmount = 10,
                        operation = "percent",
                        statRef = "f82db71a:u7b49vs9",
                        statScaling = {},
                        type = "stat"
                    }
                },
                events = {},
                icon = "interface/icons/spell_holy_greaterblessingofkings.blp",
                id = "rga5x8pa",
                maxStacks = 1,
                name = "Blessing of Might",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Increases Melee Attack Power by 10%.",
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
                        statRef = "f82db71a:zfqm8dxp",
                        statScaling = {},
                        type = "stat"
                    },
                    {
                        baseAmount = 10,
                        operation = "percent",
                        statRef = "f82db71a:xqz0daz2",
                        statScaling = {},
                        type = "stat"
                    },
                    {
                        baseAmount = 10,
                        operation = "percent",
                        statRef = "f82db71a:75y3a8ib",
                        statScaling = {},
                        type = "stat"
                    },
                    {
                        baseAmount = 10,
                        operation = "percent",
                        statRef = "f82db71a:kec9rhli",
                        statScaling = {},
                        type = "stat"
                    },
                    {
                        baseAmount = 10,
                        operation = "percent",
                        statRef = "f82db71a:ygjno50i",
                        statScaling = {},
                        type = "stat"
                    }
                },
                events = {},
                icon = "interface/icons/spell_magic_greaterblessingofkings.blp",
                id = "vqdsnaa2",
                maxStacks = 1,
                name = "Blessing of Kings",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Increases Strength by 10%. Increases Agility by 10%. Increases Intellect by 10%. Increases Spirit by 10%. Increases Stamina by 10%.",
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
                        statRef = "f82db71a:v42albuv",
                        statScaling = {},
                        type = "stat"
                    },
                    {
                        baseAmount = 2,
                        operation = "flat",
                        statRef = "f82db71a:p8syz5ba",
                        statScaling = {},
                        type = "stat"
                    }
                },
                events = {},
                icon = "interface/icons/spell_holy_greaterblessingofsanctuary.blp",
                id = "3ugbrrk0",
                maxStacks = 1,
                name = "Blessing of Sanctuary",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Increases Armor by 10%. Increases Block Chance by 2%.",
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
                        amount = 8,
                        amountMode = "flat",
                        resourceRef = "f82db71a:4c8mfm99",
                        type = "resource"
                    }
                },
                events = {},
                icon = "interface/icons/spell_holy_greaterblessingofwisdom.blp",
                id = "tymni65r",
                maxStacks = 1,
                name = "Blessing of Wisdom",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Restores {AURA_RESOURCE_GAIN_1} each turn.",
                    bodyTokens = {
                        {
                            applyMode = "resource_gain_amount",
                            effectIndex = 1,
                            key = "AURA_RESOURCE_GAIN_1",
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
                        baseAmount = 5,
                        operation = "percent",
                        statRef = "f82db71a:ok80ohz3",
                        statScaling = {},
                        type = "stat"
                    }
                },
                events = {},
                icon = "interface/icons/spell_holy_greaterblessingoflight.blp",
                id = "mgk0wsfy",
                maxStacks = 1,
                name = "Blessing of Light",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Increases Healing Received by 5%.",
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
                        baseAmount = -30,
                        operation = "percent",
                        statRef = "f82db71a:j8n012e6",
                        statScaling = {},
                        type = "stat"
                    }
                },
                events = {},
                icon = "interface/icons/spell_holy_greaterblessingofsalvation.blp",
                id = "r9hetkwg",
                maxStacks = 1,
                name = "Blessing of Salvation",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Reduces Threat Generated by 30%.",
                    bodyTokens = {},
                    stackingText = "",
                    stackingTokens = {},
                    version = 1
                }
            },
            {
                description = "",
                duration = 3,
                effects = {},
                events = {
                    {
                        chance = 100,
                        combatEventId = "on_auto_attack_hit",
                        effects = {
                            {
                                amountMode = "flat",
                                baseDamage = 6,
                                damageSchoolRefs = {
                                    "f82db71a:wwctys5s"
                                },
                                statScaling = {
                                    {
                                        coefficient = 1,
                                        statRef = "f82db71a:7t7xgzcx"
                                    }
                                },
                                type = "damage"
                            }
                        },
                        triggerTarget = "event_other"
                    }
                },
                icon = "interface/icons/inv_hammer_01.blp",
                id = "l2c0r71f",
                maxStacks = 1,
                name = "Seal of Righteousness",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "When the affected unit hits with a basic attack, the target takes {AURA_EVENT_DAMAGE_1} Holy damage.",
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
                description = "",
                duration = 3,
                effects = {},
                events = {
                    {
                        chance = 100,
                        combatEventId = "on_auto_attack_hit",
                        effects = {
                            {
                                amountMode = "flat",
                                baseDamage = 0,
                                damageSchoolRefs = {
                                    "f82db71a:wwctys5s"
                                },
                                statScaling = {
                                    {
                                        coefficient = 0.1,
                                        statRef = "f82db71a:u7b49vs9"
                                    }
                                },
                                type = "damage"
                            }
                        },
                        triggerTarget = "event_other"
                    }
                },
                icon = "interface/icons/ability_warrior_innerrage.blp",
                id = "1h88a5of",
                maxStacks = 1,
                name = "Seal of Command",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "When the affected unit hits with a basic attack, the target takes {AURA_EVENT_DAMAGE_1} Holy damage.",
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
                description = "",
                duration = 3,
                effects = {},
                events = {
                    {
                        chance = 100,
                        combatEventId = "on_auto_attack_hit",
                        effects = {
                            {
                                amountMode = "max_percent",
                                baseHealing = 3,
                                statScaling = {
                                    {
                                        coefficient = 0.1,
                                        statRef = "f82db71a:u7b49vs9"
                                    }
                                },
                                type = "heal"
                            }
                        },
                        triggerTarget = "aura_caster"
                    }
                },
                icon = "interface/icons/spell_holy_healingaura.blp",
                id = "gw8r1b8l",
                maxStacks = 1,
                name = "Seal of Light",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "When the affected unit hits with a basic attack, heal yourself for 3% of Max health.",
                    bodyTokens = {},
                    stackingText = "",
                    stackingTokens = {},
                    version = 1
                }
            },
            {
                description = "",
                duration = 3,
                effects = {},
                events = {
                    {
                        chance = 100,
                        combatEventId = "on_auto_attack_hit",
                        effects = {
                            {
                                amount = 3,
                                amountMode = "max_percent",
                                resourceRef = "f82db71a:4c8mfm99",
                                type = "resource"
                            }
                        },
                        triggerTarget = "aura_caster"
                    }
                },
                icon = "interface/icons/spell_holy_righteousnessaura.blp",
                id = "zwad020u",
                maxStacks = 1,
                name = "Seal of Wisdom",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "When the affected unit hits with a basic attack, restore 3% of Max Mana.",
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
                            }
                        },
                        triggerTarget = "event_source"
                    }
                },
                icon = "interface/icons/spell_holy_healingaura.blp",
                id = "3m31fk9l",
                maxStacks = 1,
                name = "Judgement of the Light",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "When the affected unit is victim of a basic attack, heal the attacker for 2% of Max health.",
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
                                amount = 2,
                                amountMode = "max_percent",
                                resourceRef = "f82db71a:4c8mfm99",
                                type = "resource"
                            }
                        },
                        triggerTarget = "event_source"
                    }
                },
                icon = "interface/icons/spell_holy_righteousnessaura.blp",
                id = "1q22o5fg",
                maxStacks = 1,
                name = "Judgement of the Wise",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "When the affected unit is victim of a basic attack, restore 2% of Max Mana to the attacker.",
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
                        baseAmount = 10,
                        operation = "percent",
                        statRef = "f82db71a:v42albuv",
                        statScaling = {},
                        type = "stat"
                    }
                },
                events = {},
                icon = "interface/icons/ability_paladin_shieldofvengeance.blp",
                id = "f532bn3k",
                maxStacks = 2,
                name = "Armor of the Righteous",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Increases Armor by 10%.",
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
                        baseAmount = 30,
                        operation = "flat",
                        statRef = "f82db71a:pu05li08",
                        statScaling = {},
                        type = "stat"
                    }
                },
                events = {},
                icon = "interface/icons/spell_holy_divineprotection.blp",
                id = "09qf269x",
                maxStacks = 1,
                name = "Divine Protection",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Increases Damage Reduction by 30%.",
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
                        baseAmount = 5,
                        operation = "percent",
                        statRef = "f82db71a:v42albuv",
                        statScaling = {},
                        type = "stat"
                    }
                },
                events = {},
                icon = "interface/icons/spell_holy_layonhands.blp",
                id = "brdg97w5",
                maxStacks = 3,
                name = "Empyrean Ward",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Increases Armor by 5%.",
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
                icon = "interface/icons/spell_holy_heal.blp",
                id = "mluorxb9",
                maxStacks = 1,
                name = "Divine Favor",
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
                duration = 3,
                effects = {
                    {
                        amountMode = "flat",
                        baseDamage = 5,
                        damageSchoolRefs = {
                            "f82db71a:wwctys5s"
                        },
                        statScaling = {
                            {
                                coefficient = 0.2,
                                statRef = "f82db71a:u7b49vs9"
                            }
                        },
                        type = "damage"
                    }
                },
                events = {},
                icon = "interface/icons/ability_paladin_bladeofjustice.blp",
                id = "bgmk5vpf",
                maxStacks = 1,
                name = "Expurgation",
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
            }
        },
        authorName = "Ortellus-ArgentDawn",
        classes = {
            {
                description = "This is the call of the Paladin: to protect the weak, to bring justice to the unjust, and to vanquish evil from the darkest corners of the world. These holy warriors are equipped with plate armor so they can confront the toughest of foes, and the blessing of the Light allows them to heal wounds and, in some cases, even restore life to the dead.",
                icon = "interface/icons/classicon_paladin.blp",
                id = "wvirv9um",
                name = "Paladin",
                armorWeights = {
                    "mail",
                    "plate",
                    "shield",
                },
                weaponTypeRefs = {
                    "f82db71a:z6nh3znw",
                    "f82db71a:i4pivdig",
                    "f82db71a:9ni3vfas",
                    "f82db71a:25s5wyry",
                },
                resourceProgressions = {
                    {
                        initialValue = 28,
                        perLevelValue = 22.93,
                        resourceRef = "f82db71a:q2ktkztt"
                    },
                    {
                        initialValue = 59,
                        perLevelValue = 24.63,
                        resourceRef = "f82db71a:4c8mfm99"
                    }
                },
                skillBonuses = {},
                statProgressions = {
                    {
                        initialValue = 2,
                        perLevelValue = 1.41,
                        statRef = "f82db71a:zfqm8dxp"
                    },
                    {
                        initialValue = 2,
                        perLevelValue = 1.32,
                        statRef = "f82db71a:ygjno50i"
                    },
                    {
                        initialValue = 1,
                        perLevelValue = 0.92,
                        statRef = "f82db71a:kec9rhli"
                    },
                    {
                        initialValue = 0,
                        perLevelValue = 0.76,
                        statRef = "f82db71a:xqz0daz2"
                    },
                    {
                        initialValue = 0,
                        perLevelValue = 0.85,
                        statRef = "f82db71a:75y3a8ib"
                    }
                },
                passiveTraitRefs = {
                    "b0211ab3:c9r5sade"
                },
                talentTraitRefs = {
                    "b0211ab3:kl2ug8kz",
                    "b0211ab3:0ditc5z7",
                    "b0211ab3:yz6qglzv"
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
        id = "b0211ab3",
        interactions = {},
        itemSlots = {},
        items = {
            {
                allowWowConversion = false,
                armorWeight = "cosmetic",
                bindingFlag = "bind_on_pickup",
                blueSockets = 1,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_helmet_74.blp",
                id = "i7f32pv7",
                isTwoHanded = false,
                itemLevel = 75,
                itemSetKey = "t2_pala_tank",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 1,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Judgement Great Helm",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {
                    {
                        color = "meta"
                    },
                    {
                        color = "blue"
                    }
                },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 696
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 21
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 34
                    },
                    {
                        sourceStatRef = "f82db71a:pg0ytacb",
                        value = 10
                    },
                    {
                        sourceStatRef = "f82db71a:jjn0my8k",
                        value = 10
                    },
                    {
                        sourceStatRef = "f82db71a:v2g0tw0o",
                        value = 1
                    },
                    {
                        sourceStatRef = "f82db71a:p8syz5ba",
                        value = 1
                    },
                    {
                        sourceStatRef = "f82db71a:0wyp78x9",
                        value = 9
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:bgvs1zx6"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
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
                        type = "level"
                    },
                    {
                        classRefs = {
                            "b0211ab3:wvirv9um"
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Paladin",
                        type = "class"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_helmet_74.blp",
                id = "22jpcak5",
                isTwoHanded = false,
                itemLevel = 75,
                itemSetKey = "t2_pala_dps",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 1,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Judgement Crown",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 1,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {
                    {
                        color = "meta"
                    },
                    {
                        color = "red"
                    }
                },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 696
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 24
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 12
                    },
                    {
                        sourceStatRef = "f82db71a:pg0ytacb",
                        value = 10
                    },
                    {
                        sourceStatRef = "f82db71a:jjn0my8k",
                        value = 10
                    },
                    {
                        sourceStatRef = "f82db71a:wbj4zuf3",
                        value = 1
                    },
                    {
                        sourceStatRef = "f82db71a:jslmczbi",
                        value = 2
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 19
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:bgvs1zx6"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
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
                        type = "level"
                    },
                    {
                        classRefs = {
                            "b0211ab3:wvirv9um"
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Paladin",
                        type = "class"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_shoulder_37.blp",
                id = "bndyxcfg",
                isTwoHanded = false,
                itemLevel = 75,
                itemSetKey = "t2_pala_dps",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Judgement Spaulders",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 1,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {
                    {
                        color = "red"
                    },
                    {
                        color = "yellow"
                    }
                },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 642
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 30
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 11
                    },
                    {
                        sourceStatRef = "f82db71a:jjn0my8k",
                        value = 10
                    },
                    {
                        sourceStatRef = "f82db71a:jslmczbi",
                        value = 1
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:66i80qm1"
                },
                yellowSockets = 1
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
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
                        type = "level"
                    },
                    {
                        classRefs = {
                            "b0211ab3:wvirv9um"
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Paladin",
                        type = "class"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_bracer_18.blp",
                id = "wvamxdny",
                isTwoHanded = false,
                itemLevel = 75,
                itemSetKey = "t2_pala_dps",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Judgement Bindings",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 375
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 20
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 10
                    },
                    {
                        sourceStatRef = "f82db71a:wbj4zuf3",
                        value = 1
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 16
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:crezt6ix"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
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
                        type = "level"
                    },
                    {
                        classRefs = {
                            "b0211ab3:wvirv9um"
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Paladin",
                        type = "class"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_gauntlets_29.blp",
                id = "t3e3wfgm",
                isTwoHanded = false,
                itemLevel = 75,
                itemSetKey = "t2_pala_dps",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Judgement Gauntlets",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {
                    {
                        color = "blue"
                    }
                },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 535
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 25
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 13
                    },
                    {
                        sourceStatRef = "f82db71a:wbj4zuf3",
                        value = 1
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 24
                    },
                    {
                        sourceStatRef = "f82db71a:pg0ytacb",
                        value = 10
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:wasvuom2"
                },
                yellowSockets = 0
            }
        },
        loot = {},
        mounts = {},
        name = "Paladin",
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
                            amount = 10,
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
                            auraRef = "b0211ab3:rga5x8pa",
                            basePower = 0,
                            duration = 10,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "4888394c",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 5,
                            minTargets = 1,
                            requiresTarget = true,
                            targetDisposition = "ally",
                            type = "single"
                        }
                    }
                },
                conditions = {},
                cooldown = 0,
                cooldownGroup = "blessing",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_holy_greaterblessingofkings.blp",
                id = "h981ofan",
                ignoreGCD = true,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Blessing of Might",
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
                spellbookCategory = "Retribution",
                tags = {
                    "blessing"
                },
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "b0211ab3:rga5x8pa",
                            datasetId = "b0211ab3",
                            descriptionText = "Increases Melee Attack Power by 10%.",
                            duration = 10,
                            icon = "interface/icons/spell_holy_greaterblessingofkings.blp",
                            nameText = "Blessing of Might",
                            powerLevel = 0,
                            spellDatasetId = "b0211ab3",
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
                    mainText = "Apply Blessing of Might to up to 5 allies for 10 turns.",
                    tokens = {},
                    version = 1
                },
                totalTicks = 0,
                triggersGCD = false,
                useCooldownCharges = false
            },
            {
                _resourceCostsByPhase = {
                    on_cast_end = {
                        {
                            amount = 10,
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
                            auraRef = "b0211ab3:vqdsnaa2",
                            basePower = 0,
                            duration = 10,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "4888394c",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 5,
                            minTargets = 1,
                            requiresTarget = true,
                            targetDisposition = "ally",
                            type = "single"
                        }
                    }
                },
                conditions = {},
                cooldown = 0,
                cooldownGroup = "blessing",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_magic_greaterblessingofkings.blp",
                id = "wfq254qz",
                ignoreGCD = true,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Blessing of Kings",
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
                spellbookCategory = "Protection",
                tags = {
                    "blessing"
                },
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "b0211ab3:vqdsnaa2",
                            datasetId = "b0211ab3",
                            descriptionText = "Increases Strength by 10%. Increases Agility by 10%. Increases Intellect by 10%. Increases Spirit by 10%. Increases Stamina by 10%.",
                            duration = 10,
                            icon = "interface/icons/spell_magic_greaterblessingofkings.blp",
                            nameText = "Blessing of Kings",
                            powerLevel = 0,
                            spellDatasetId = "b0211ab3",
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
                    mainText = "Apply Blessing of Kings to up to 5 allies for 10 turns.",
                    tokens = {},
                    version = 1
                },
                totalTicks = 0,
                triggersGCD = false,
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
                            auraRef = "b0211ab3:3ugbrrk0",
                            basePower = 0,
                            duration = 10,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "4888394c",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 5,
                            minTargets = 1,
                            requiresTarget = true,
                            targetDisposition = "ally",
                            type = "single"
                        }
                    }
                },
                conditions = {},
                cooldown = 0,
                cooldownGroup = "blessing",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_holy_greaterblessingofsanctuary.blp",
                id = "zg4n0a1f",
                ignoreGCD = true,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Blessing of Sanctuary",
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
                spellbookCategory = "Protection",
                tags = {
                    "blessing"
                },
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "b0211ab3:3ugbrrk0",
                            datasetId = "b0211ab3",
                            descriptionText = "Increases Armor by 10%. Increases Block Chance by 2%.",
                            duration = 10,
                            icon = "interface/icons/spell_holy_greaterblessingofsanctuary.blp",
                            nameText = "Blessing of Sanctuary",
                            powerLevel = 0,
                            spellDatasetId = "b0211ab3",
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
                    mainText = "Apply Blessing of Sanctuary to up to 5 allies for 10 turns.",
                    tokens = {},
                    version = 1
                },
                totalTicks = 0,
                triggersGCD = false,
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
                            auraRef = "b0211ab3:tymni65r",
                            basePower = 0,
                            duration = 10,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "4888394c",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 5,
                            minTargets = 1,
                            requiresTarget = true,
                            targetDisposition = "ally",
                            type = "single"
                        }
                    }
                },
                conditions = {},
                cooldown = 0,
                cooldownGroup = "blessing",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_holy_greaterblessingofwisdom.blp",
                id = "xdt25qxt",
                ignoreGCD = true,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Blessing of Wisdom",
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
                spellbookCategory = "Holy",
                tags = {
                    "blessing"
                },
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "b0211ab3:tymni65r",
                            datasetId = "b0211ab3",
                            descriptionText = "Restores {AURA_RESOURCE_GAIN_1} each turn.",
                            duration = 10,
                            icon = "interface/icons/spell_holy_greaterblessingofwisdom.blp",
                            nameText = "Blessing of Wisdom",
                            powerLevel = 0,
                            spellDatasetId = "b0211ab3",
                            stacks = 1,
                            targetContext = {
                                object = "the affected ally",
                                possessive = "the affected ally's",
                                reflexive = "itself",
                                subject = "the affected ally"
                            },
                            tokens = {
                                {
                                    applyMode = "resource_gain_amount",
                                    effectIndex = 1,
                                    key = "AURA_RESOURCE_GAIN_1",
                                    tokenType = "aura_amount"
                                }
                            }
                        }
                    },
                    mainText = "Apply Blessing of Wisdom to up to 5 allies for 10 turns.",
                    tokens = {},
                    version = 1
                },
                totalTicks = 0,
                triggersGCD = false,
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
                            auraRef = "b0211ab3:mgk0wsfy",
                            basePower = 0,
                            duration = 10,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "4888394c",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 5,
                            minTargets = 1,
                            requiresTarget = true,
                            targetDisposition = "ally",
                            type = "single"
                        }
                    }
                },
                conditions = {},
                cooldown = 0,
                cooldownGroup = "blessing",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_holy_greaterblessingoflight.blp",
                id = "ms0v0du4",
                ignoreGCD = true,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Blessing of Light",
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
                spellbookCategory = "Holy",
                tags = {
                    "blessing"
                },
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "b0211ab3:mgk0wsfy",
                            datasetId = "b0211ab3",
                            descriptionText = "Increases Healing Received by 5%.",
                            duration = 10,
                            icon = "interface/icons/spell_holy_greaterblessingoflight.blp",
                            nameText = "Blessing of Light",
                            powerLevel = 0,
                            spellDatasetId = "b0211ab3",
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
                    mainText = "Apply Blessing of Light to up to 5 allies for 10 turns.",
                    tokens = {},
                    version = 1
                },
                totalTicks = 0,
                triggersGCD = false,
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
                            auraRef = "b0211ab3:r9hetkwg",
                            basePower = 0,
                            duration = 10,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "4888394c",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 5,
                            minTargets = 1,
                            requiresTarget = true,
                            targetDisposition = "ally",
                            type = "single"
                        }
                    }
                },
                conditions = {},
                cooldown = 0,
                cooldownGroup = "blessing",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_holy_greaterblessingofsalvation.blp",
                id = "25j5h8f2",
                ignoreGCD = true,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Blessing of Salvation",
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
                spellbookCategory = "Protection",
                tags = {
                    "blessing"
                },
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "b0211ab3:r9hetkwg",
                            datasetId = "b0211ab3",
                            descriptionText = "Reduces Threat Generated by 30%.",
                            duration = 10,
                            icon = "interface/icons/spell_holy_greaterblessingofsalvation.blp",
                            nameText = "Blessing of Salvation",
                            powerLevel = 0,
                            spellDatasetId = "b0211ab3",
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
                    mainText = "Apply Blessing of Salvation to up to 5 allies for 10 turns.",
                    tokens = {},
                    version = 1
                },
                totalTicks = 0,
                triggersGCD = false,
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
                            baseDamage = 110.5,
                            damageSchoolRefs = {
                                "f82db71a:wwctys5s"
                            },
                            damageType = "spell",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.553,
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
                        key = "8088c3d6",
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
                            auraRef = "b0211ab3:l2c0r71f",
                            stacks = 1,
                            targetEvents = {},
                            type = "remove_aura"
                        },
                        key = "7c458546",
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
                        auraRef = "b0211ab3:l2c0r71f",
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Requires Seal of Righteousness",
                        type = "aura_requirement",
                        unit = "caster"
                    }
                },
                cooldown = 3,
                cooldownGroup = "judgement",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_holy_righteousfury.blp",
                id = "wmp0b1zn",
                ignoreGCD = false,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Judgement of the Righteous",
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
                spellbookCategory = "Holy",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {},
                    mainText = "Deal {DAMAGE_1} Holy damage to an enemy.",
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
                triggersGCD = true,
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
                            auraRef = "b0211ab3:l2c0r71f",
                            basePower = 0,
                            duration = 3,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "ccece0c2",
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
                        invert = false,
                        showOnTooltip = true,
                        slotKey = "mainhand",
                        tooltipTextOverride = "Requires main hand",
                        type = "item_equipped",
                        weaponTypeRefs = {}
                    }
                },
                cooldown = 1,
                cooldownGroup = "seal",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/inv_hammer_01.blp",
                id = "xvfmhwn2",
                ignoreGCD = true,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Seal of Righteousness",
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
                spellbookCategory = "Holy",
                tags = {
                    "seal"
                },
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "b0211ab3:l2c0r71f",
                            datasetId = "b0211ab3",
                            descriptionText = "When the affected unit hits with a basic attack, the target takes {AURA_EVENT_DAMAGE_1} Holy damage.",
                            duration = 3,
                            icon = "interface/icons/inv_hammer_01.blp",
                            nameText = "Seal of Righteousness",
                            powerLevel = 0,
                            spellDatasetId = "b0211ab3",
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
                    mainText = "Apply Seal of Righteousness to yourself for 3 turns.",
                    tokens = {},
                    version = 1
                },
                totalTicks = 0,
                triggersGCD = false,
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
                            baseDamage = 71.55,
                            damageSchoolRefs = {
                                "f82db71a:wwctys5s"
                            },
                            damageType = "spell",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.387,
                                    statRef = "f82db71a:u7b49vs9"
                                }
                            },
                            targetEvents = {
                                "on_spell_taken",
                                "on_critical_hit_taken"
                            },
                            threatCoefficient = 1,
                            type = "damage",
                            usesProjectile = false,
                            weaponDamageCoefficient = 1.105,
                            weaponDamageMode = "main_hand"
                        },
                        key = "8088c3d6",
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
                            auraRef = "b0211ab3:1h88a5of",
                            stacks = 1,
                            targetEvents = {},
                            type = "remove_aura"
                        },
                        key = "7c458546",
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
                        auraRef = "b0211ab3:1h88a5of",
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Requires Seal of Command",
                        type = "aura_requirement",
                        unit = "caster"
                    }
                },
                cooldown = 3,
                cooldownGroup = "judgement",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_holy_righteousfury.blp",
                id = "kyzga5f2",
                ignoreGCD = false,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Judgement of Command",
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
                spellbookCategory = "Retribution",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {},
                    mainText = "Deal {DAMAGE_1} Holy damage to an enemy.",
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
                triggersGCD = true,
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
                            auraRef = "b0211ab3:1h88a5of",
                            basePower = 0,
                            duration = 3,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "ccece0c2",
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
                        invert = false,
                        showOnTooltip = true,
                        slotKey = "mainhand",
                        tooltipTextOverride = "Requires main hand",
                        type = "item_equipped",
                        weaponTypeRefs = {}
                    }
                },
                cooldown = 1,
                cooldownGroup = "seal",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/ability_warrior_innerrage.blp",
                id = "uesn7obf",
                ignoreGCD = true,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Seal of Command",
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
                spellbookCategory = "Retribution",
                tags = {
                    "seal"
                },
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "b0211ab3:1h88a5of",
                            datasetId = "b0211ab3",
                            descriptionText = "When the affected unit hits with a basic attack, the target takes {AURA_EVENT_DAMAGE_1} Holy damage.",
                            duration = 3,
                            icon = "interface/icons/ability_warrior_innerrage.blp",
                            nameText = "Seal of Command",
                            powerLevel = 0,
                            spellDatasetId = "b0211ab3",
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
                    mainText = "Apply Seal of Command to yourself for 3 turns.",
                    tokens = {},
                    version = 1
                },
                totalTicks = 0,
                triggersGCD = false,
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
                            amountMode = "flat",
                            applyAura = false,
                            auraStacks = 1,
                            baseHealing = 71.5,
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.78,
                                    statRef = "f82db71a:hj6d4kvy"
                                }
                            },
                            targetEvents = {
                                "on_heal_taken"
                            },
                            type = "heal",
                            usesProjectile = false
                        },
                        key = "8088c3d6",
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
                            auraRef = "b0211ab3:gw8r1b8l",
                            stacks = 1,
                            targetEvents = {},
                            type = "remove_aura"
                        },
                        key = "7c458546",
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
                            auraRef = "b0211ab3:3m31fk9l",
                            basePower = 0,
                            duration = 5,
                            stacks = 1,
                            targetEvents = {
                                "on_spell_taken"
                            },
                            type = "apply_aura"
                        },
                        key = "60582cd4",
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
                        auraRef = "b0211ab3:gw8r1b8l",
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Requires Seal of Light",
                        type = "aura_requirement",
                        unit = "caster"
                    }
                },
                cooldown = 3,
                cooldownGroup = "judgement",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_holy_righteousfury.blp",
                id = "pb305qze",
                ignoreGCD = false,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Judgement of the Light",
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
                spellbookCategory = "Protection",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "b0211ab3:3m31fk9l",
                            datasetId = "b0211ab3",
                            descriptionText = "When the affected unit is victim of a basic attack, heal the attacker for 2% of Max health.",
                            duration = 5,
                            icon = "interface/icons/spell_holy_healingaura.blp",
                            nameText = "Judgement of the Light",
                            powerLevel = 0,
                            spellDatasetId = "b0211ab3",
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
                    mainText = "Heal yourself for {HEAL_1} health. Apply Judgement of the Light to an enemy for 5 turns.",
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
                triggersGCD = true,
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
                            auraRef = "b0211ab3:gw8r1b8l",
                            basePower = 0,
                            duration = 3,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "ccece0c2",
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
                        invert = false,
                        showOnTooltip = true,
                        slotKey = "mainhand",
                        tooltipTextOverride = "Requires main hand",
                        type = "item_equipped",
                        weaponTypeRefs = {}
                    }
                },
                cooldown = 1,
                cooldownGroup = "seal",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_holy_healingaura.blp",
                id = "25h4rwgt",
                ignoreGCD = true,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Seal of Light",
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
                spellbookCategory = "Protection",
                tags = {
                    "seal"
                },
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "b0211ab3:gw8r1b8l",
                            datasetId = "b0211ab3",
                            descriptionText = "When the affected unit hits with a basic attack, heal yourself for 3% of Max health.",
                            duration = 3,
                            icon = "interface/icons/spell_holy_healingaura.blp",
                            nameText = "Seal of Light",
                            powerLevel = 0,
                            spellDatasetId = "b0211ab3",
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
                    mainText = "Apply Seal of Light to yourself for 3 turns.",
                    tokens = {},
                    version = 1
                },
                totalTicks = 0,
                triggersGCD = false,
                useCooldownCharges = false
            },
            {
                _resourceCostsByPhase = {
                    on_cast_end = {},
                    on_cast_start = {}
                },
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
                            amount = 40,
                            amountMode = "base_percent",
                            resourceRef = "f82db71a:4c8mfm99",
                            targetEvents = {},
                            type = "resource"
                        },
                        key = "8088c3d6",
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
                            auraRef = "b0211ab3:zwad020u",
                            stacks = 1,
                            targetEvents = {},
                            type = "remove_aura"
                        },
                        key = "7c458546",
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
                            auraRef = "b0211ab3:1q22o5fg",
                            basePower = 0,
                            duration = 5,
                            stacks = 1,
                            targetEvents = {
                                "on_spell_taken"
                            },
                            type = "apply_aura"
                        },
                        key = "539106b7",
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
                        auraRef = "b0211ab3:zwad020u",
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Requires Seal of Wisdom",
                        type = "aura_requirement",
                        unit = "caster"
                    }
                },
                cooldown = 3,
                cooldownGroup = "judgement",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_holy_righteousfury.blp",
                id = "j1my2871",
                ignoreGCD = false,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Judgement of Wisdom",
                range = 0,
                resourceCosts = {},
                seedNPCSpell = false,
                spellbookCategory = "Holy",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "b0211ab3:1q22o5fg",
                            datasetId = "b0211ab3",
                            descriptionText = "When the affected unit is victim of a basic attack, restore 2% of Max Mana to the attacker.",
                            duration = 5,
                            icon = "interface/icons/spell_holy_righteousnessaura.blp",
                            nameText = "Judgement of the Wise",
                            powerLevel = 0,
                            spellDatasetId = "b0211ab3",
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
                    mainText = "Restore 40% of Base Mana to yourself. Apply Judgement of the Wise to an enemy for 5 turns.",
                    tokens = {},
                    version = 1
                },
                totalTicks = 0,
                triggersGCD = true,
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
                            auraRef = "b0211ab3:zwad020u",
                            basePower = 0,
                            duration = 3,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "ccece0c2",
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
                        invert = false,
                        showOnTooltip = true,
                        slotKey = "mainhand",
                        tooltipTextOverride = "Requires main hand",
                        type = "item_equipped",
                        weaponTypeRefs = {}
                    }
                },
                cooldown = 1,
                cooldownGroup = "seal",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_holy_righteousnessaura.blp",
                id = "vuotim0h",
                ignoreGCD = true,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Seal of Wisdom",
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
                spellbookCategory = "Holy",
                tags = {
                    "seal"
                },
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "b0211ab3:zwad020u",
                            datasetId = "b0211ab3",
                            descriptionText = "When the affected unit hits with a basic attack, restore 3% of Max Mana.",
                            duration = 3,
                            icon = "interface/icons/spell_holy_righteousnessaura.blp",
                            nameText = "Seal of Wisdom",
                            powerLevel = 0,
                            spellDatasetId = "b0211ab3",
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
                    mainText = "Apply Seal of Wisdom to yourself for 3 turns.",
                    tokens = {},
                    version = 1
                },
                totalTicks = 0,
                triggersGCD = false,
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
                    "on_melee_hit",
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
                            auraStacks = 1,
                            baseDamage = 75,
                            damageSchoolRefs = {
                                "f82db71a:wwctys5s"
                            },
                            damageType = "melee",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.35,
                                    statRef = "f82db71a:u7b49vs9"
                                }
                            },
                            targetEvents = {
                                "on_melee_taken",
                                "on_critical_hit_taken"
                            },
                            threatCoefficient = 1,
                            type = "damage",
                            usesProjectile = false,
                            weaponDamageCoefficient = 1,
                            weaponDamageMode = "main_hand"
                        },
                        key = "f83d713d",
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
                            resourceRef = "f82db71a:cbjzgaby",
                            targetEvents = {},
                            type = "resource"
                        },
                        key = "4f5db0c0",
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
                        invert = false,
                        showOnTooltip = true,
                        slotKey = "mainhand",
                        tooltipTextOverride = "Requires main hand",
                        type = "item_equipped",
                        weaponTypeRefs = {}
                    }
                },
                cooldown = 3,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_holy_crusaderstrike.blp",
                id = "27baiuv3",
                ignoreGCD = false,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Crusader Strike",
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
                spellbookCategory = "Retribution",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {},
                    mainText = "Deal {DAMAGE_1} Holy damage to an enemy. Restore {RESOURCE_AMOUNT_1} to yourself.",
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
                triggersGCD = true,
                useCooldownCharges = true
            },
            {
                _resourceCostsByPhase = {
                    on_cast_end = {
                        {
                            amount = 3,
                            amountMode = "flat",
                            castPhase = "on_cast_end",
                            refundOnInterrupt = 0,
                            resourceRef = "f82db71a:cbjzgaby"
                        }
                    },
                    on_cast_start = {}
                },
                allowDeadTargets = false,
                canMoveWhileCasting = false,
                castTime = 0,
                casterEvents = {
                    "on_melee_hit",
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
                            baseDamage = 168.75,
                            damageSchoolRefs = {
                                "f82db71a:wwctys5s"
                            },
                            damageType = "melee",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.788,
                                    statRef = "f82db71a:u7b49vs9"
                                }
                            },
                            targetEvents = {
                                "on_melee_taken",
                                "on_critical_hit_taken"
                            },
                            threatCoefficient = 1,
                            type = "damage",
                            usesProjectile = false,
                            weaponDamageCoefficient = 2.25,
                            weaponDamageMode = "main_hand"
                        },
                        key = "2cb313ab",
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
                        showOnTooltip = true,
                        slotKey = "mainhand",
                        tooltipTextOverride = "Requires main hand",
                        type = "item_equipped",
                        weaponTypeRefs = {}
                    }
                },
                cooldown = 0,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_paladin_templarsverdict.blp",
                id = "eg4gydsa",
                ignoreGCD = false,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Templar's Verdict",
                range = 0,
                resourceCosts = {
                    {
                        amount = 3,
                        amountMode = "flat",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:cbjzgaby"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Retribution",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {},
                    mainText = "Deal {DAMAGE_1} Holy damage to an enemy.",
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
                triggersGCD = true,
                useCooldownCharges = false
            },
            {
                allowDeadTargets = false,
                canMoveWhileCasting = false,
                castTime = 0,
                casterEvents = {
                    "on_melee_hit",
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
                            auraStacks = 1,
                            baseDamage = 45,
                            damageSchoolRefs = {
                                "f82db71a:wwctys5s"
                            },
                            damageType = "melee",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.21,
                                    statRef = "f82db71a:u7b49vs9"
                                }
                            },
                            targetEvents = {
                                "on_melee_taken",
                                "on_critical_hit_taken"
                            },
                            threatCoefficient = 2,
                            type = "damage",
                            usesProjectile = false,
                            weaponDamageCoefficient = 0.6,
                            weaponDamageMode = "main_hand"
                        },
                        key = "74e6d957",
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
                conditions = {
                    {
                        invert = false,
                        showOnTooltip = true,
                        slotKey = "mainhand",
                        tooltipTextOverride = "Requires main hand",
                        type = "item_equipped",
                        weaponTypeRefs = {}
                    }
                },
                cooldown = 3,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/ability_paladin_hammeroftherighteous.blp",
                id = "d1pmq58z",
                ignoreGCD = false,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Hammer of the Righteous",
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
                spellbookCategory = "Protection",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {},
                    mainText = "Deal {DAMAGE_1} Holy damage to up to 3 enemies. Generates a high amount of threat.",
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
                triggersGCD = true,
                useCooldownCharges = true
            },
            {
                allowDeadTargets = false,
                canMoveWhileCasting = false,
                castTime = 0,
                casterEvents = {
                    "on_melee_hit",
                    "on_critical_hit_taken"
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
                            auraStacks = 1,
                            baseDamage = 55.25,
                            damageSchoolRefs = {
                                "f82db71a:wwctys5s"
                            },
                            damageType = "melee",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.193,
                                    statRef = "f82db71a:u7b49vs9"
                                }
                            },
                            targetEvents = {
                                "on_melee_taken",
                                "on_critical_hit_taken"
                            },
                            threatCoefficient = 1.5,
                            type = "damage",
                            usesProjectile = false,
                            weaponDamageCoefficient = 1,
                            weaponDamageMode = "none"
                        },
                        key = "2cb313ab",
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
                            auraRef = "b0211ab3:f532bn3k",
                            basePower = 0,
                            duration = 3,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "586116e2",
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
                        invert = false,
                        showOnTooltip = true,
                        slotKey = "mainhand",
                        tooltipTextOverride = "Requires main hand",
                        type = "item_equipped",
                        weaponTypeRefs = {}
                    }
                },
                cooldown = 3,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/ability_paladin_shieldofvengeance.blp",
                id = "pz4cufo7",
                ignoreGCD = true,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Shield of the Righteous",
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
                spellbookCategory = "Protection",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "b0211ab3:f532bn3k",
                            datasetId = "b0211ab3",
                            descriptionText = "Increases Armor by 10%. Applies {AURA_APPLIED_STACKS_1} stacks. Stacks up to {AURA_MAX_STACKS_1} times.",
                            duration = 3,
                            icon = "interface/icons/ability_paladin_shieldofvengeance.blp",
                            nameText = "Armor of the Righteous",
                            powerLevel = 0,
                            spellDatasetId = "b0211ab3",
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
                    mainText = "Deal {DAMAGE_1} Holy damage to an enemy. Apply Armor of the Righteous to yourself for 3 turns. Generates a moderate amount of threat.",
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
                triggersGCD = false,
                useCooldownCharges = true
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
                            auraRef = "b0211ab3:09qf269x",
                            basePower = 0,
                            duration = 1,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "01beaae3",
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
                icon = "interface/icons/spell_holy_divineprotection.blp",
                id = "0opb1tte",
                ignoreGCD = true,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Divine Protection",
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
                spellbookCategory = "Protection",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "b0211ab3:09qf269x",
                            datasetId = "b0211ab3",
                            descriptionText = "Increases Damage Reduction by 30%.",
                            duration = 1,
                            icon = "interface/icons/spell_holy_divineprotection.blp",
                            nameText = "Divine Protection",
                            powerLevel = 0,
                            spellDatasetId = "b0211ab3",
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
                    mainText = "Apply Divine Protection to yourself for 1 turn.",
                    tokens = {},
                    version = 1
                },
                totalTicks = 0,
                triggersGCD = false,
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
                                "on_heal_taken"
                            },
                            type = "heal",
                            usesProjectile = false
                        },
                        key = "dbb40adb",
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
                icon = "interface/icons/spell_holy_holybolt.blp",
                id = "9nwvhorx",
                ignoreGCD = false,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Holy Light",
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
                triggersGCD = true,
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
                                "on_heal_taken"
                            },
                            type = "heal",
                            usesProjectile = false
                        },
                        key = "dbb40adb",
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
                id = "znfbmec8",
                ignoreGCD = false,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Flash of Light",
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
                triggersGCD = true,
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
                            auraRef = "b0211ab3:mluorxb9",
                            basePower = 0,
                            duration = 1,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "f9d45a5b",
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
                icon = "interface/icons/spell_holy_heal.blp",
                id = "bk0uyunm",
                ignoreGCD = true,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Divine Favor",
                range = 0,
                resourceCosts = {},
                seedNPCSpell = false,
                spellbookCategory = "Holy",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "b0211ab3:mluorxb9",
                            datasetId = "b0211ab3",
                            descriptionText = "Increases Spell Crit. Chance by 100%.",
                            duration = 1,
                            icon = "interface/icons/spell_holy_heal.blp",
                            nameText = "Divine Favor",
                            powerLevel = 0,
                            spellDatasetId = "b0211ab3",
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
                    mainText = "Apply Divine Favor to yourself for 1 turn.",
                    tokens = {},
                    version = 1
                },
                totalTicks = 0,
                triggersGCD = false,
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
                            baseDamage = 160,
                            damageSchoolRefs = {
                                "f82db71a:wwctys5s"
                            },
                            damageType = "spell",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.8,
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
                        key = "710f6be5",
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
                        creatureTypes = {
                            "demon",
                            "undead"
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Target must be Aberration, Demon or Undead",
                        type = "target_creature_type"
                    }
                },
                cooldown = 5,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_holy_excorcism_02.blp",
                id = "4wt3pl5q",
                ignoreGCD = false,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Exorcism",
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
                spellbookCategory = "Holy",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {},
                    mainText = "Deal {DAMAGE_1} Holy damage to an enemy.",
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
                triggersGCD = true,
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
                            baseDamage = 96,
                            damageSchoolRefs = {
                                "f82db71a:wwctys5s"
                            },
                            damageType = "spell",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.48,
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
                        key = "710f6be5",
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
                conditions = {
                    {
                        creatureTypes = {
                            "demon",
                            "undead"
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Target must be Aberration, Demon or Undead",
                        type = "target_creature_type"
                    }
                },
                cooldown = 5,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_holy_excorcism.blp",
                id = "x8ljrb7w",
                ignoreGCD = false,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Holy Wrath",
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
                spellbookCategory = "Holy",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {},
                    mainText = "Deal {DAMAGE_1} Holy damage to up to 3 enemies.",
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
                triggersGCD = true,
                useCooldownCharges = false
            },
            {
                allowDeadTargets = false,
                canMoveWhileCasting = false,
                castTime = 0,
                casterEvents = {
                    "on_melee_hit",
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
                            baseDamage = 101.25,
                            damageSchoolRefs = {
                                "f82db71a:wwctys5s"
                            },
                            damageType = "melee",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.473,
                                    statRef = "f82db71a:u7b49vs9"
                                }
                            },
                            targetEvents = {
                                "on_melee_taken",
                                "on_critical_hit_taken"
                            },
                            threatCoefficient = 1,
                            type = "damage",
                            usesProjectile = false,
                            weaponDamageCoefficient = 1.35,
                            weaponDamageMode = "main_hand"
                        },
                        key = "2cb313ab",
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
                conditions = {
                    {
                        invert = false,
                        showOnTooltip = true,
                        slotKey = "mainhand",
                        tooltipTextOverride = "Requires main hand",
                        type = "item_equipped",
                        weaponTypeRefs = {}
                    }
                },
                cooldown = 0,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/ability_paladin_divinestorm.blp",
                id = "tu5g28q8",
                ignoreGCD = false,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Divine Storm",
                range = 0,
                resourceCosts = {
                    {
                        amount = 3,
                        amountMode = "flat",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:cbjzgaby"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Retribution",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {},
                    mainText = "Deal {DAMAGE_1} Holy damage to up to 3 enemies.",
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
                triggersGCD = true,
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
                            applyAura = true,
                            auraRef = "b0211ab3:bgmk5vpf",
                            auraStacks = 1,
                            baseDamage = 130,
                            damageSchoolRefs = {
                                "f82db71a:wwctys5s"
                            },
                            damageType = "spell",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.455,
                                    statRef = "f82db71a:u7b49vs9"
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
                        key = "63e1467f",
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
                            amount = 2,
                            amountMode = "flat",
                            resourceRef = "f82db71a:cbjzgaby",
                            targetEvents = {},
                            type = "resource"
                        },
                        key = "45e8de2e",
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
                cooldown = 4,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/ability_paladin_bladeofjustice.blp",
                id = "pznrmr50",
                ignoreGCD = false,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Blade of Wrath",
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
                spellbookCategory = "Retribution",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "b0211ab3:bgmk5vpf",
                            datasetId = "b0211ab3",
                            descriptionText = "Deals {AURA_DAMAGE_1} Holy damage each turn.",
                            icon = "interface/icons/ability_paladin_bladeofjustice.blp",
                            nameText = "Expurgation",
                            powerLevel = 0,
                            spellDatasetId = "b0211ab3",
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
                    mainText = "Deal {DAMAGE_1} Holy damage to an enemy and apply Expurgation for 3 turns. Restore {RESOURCE_AMOUNT_1} to yourself.",
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
                triggersGCD = true,
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
                            targetEvents = {},
                            type = "interrupt"
                        },
                        key = "0f9549c7",
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
                cooldownGroup = "interrupt",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_holy_rebuke.blp",
                id = "kskvgnmw",
                ignoreGCD = true,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Rebuke",
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
                spellbookCategory = "Retribution",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {},
                    mainText = "Interrupt an enemy's spellcasting.",
                    tokens = {},
                    version = 1
                },
                totalTicks = 0,
                triggersGCD = false,
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
                            baseHealing = 112.5,
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 1.35,
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
                        key = "e98da61e",
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
                icon = "interface/icons/inv_helmet_96.blp",
                id = "5ouonxor",
                ignoreGCD = false,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Word of Glory",
                range = 0,
                resourceCosts = {
                    {
                        amount = 3,
                        amountMode = "flat",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:cbjzgaby"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Retribution",
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
                triggersGCD = true,
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
                            baseHealing = 35.75,
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.39,
                                    statRef = "f82db71a:hj6d4kvy"
                                }
                            },
                            targetEvents = {
                                "on_heal_taken"
                            },
                            type = "heal",
                            usesProjectile = false
                        },
                        key = "16d3bde2",
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
                icon = "interface/icons/ability_paladin_lightoftheprotector.blp",
                id = "x2qgj4wy",
                ignoreGCD = true,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Light of the Protector",
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
                spellbookCategory = "Protection",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {},
                    mainText = "Heal yourself for {HEAL_1} health.",
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
                triggersGCD = false,
                useCooldownCharges = false
            }
        },
        stats = {},
        traits = {
            {
                automaticAuras = {},
                category = "Retribution",
                conditions = {},
                description = "Increases your damage against Undead targets by 5%.",
                events = {},
                icon = "interface/icons/spell_holy_crusaderstrike.blp",
                id = "c9r5sade",
                isEnvironmental = false,
                name = "Crusade",
                skillBonuses = {},
                statBonuses = {
                    {
                        statRef = "f82db71a:qi323bx3",
                        value = 5
                    }
                },
                unlockLevel = 1
            },
            {
                automaticAuras = {},
                category = "Protection",
                conditions = {},
                description = "",
                events = {},
                icon = "interface/icons/spell_holy_sealoffury.blp",
                id = "kl2ug8kz",
                isEnvironmental = false,
                name = "Righteous Fury",
                skillBonuses = {},
                statBonuses = {
                    {
                        statRef = "f82db71a:j8n012e6",
                        value = 80
                    },
                    {
                        statRef = "f82db71a:pu05li08",
                        value = 10
                    },
                    {
                        statRef = "f82db71a:gj9wxb0x",
                        value = -10
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
                        combatEventId = "on_heal",
                        effects = {
                            {
                                auraRef = "b0211ab3:brdg97w5",
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
                id = "0ditc5z7",
                isEnvironmental = false,
                name = "Empyrean Ward",
                skillBonuses = {},
                statBonuses = {},
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
                                amount = 30,
                                resourceRef = "f82db71a:4c8mfm99",
                                type = "resource"
                            }
                        },
                        triggerTarget = "event_source"
                    }
                },
                icon = "interface/icons/spell_magic_managain.blp",
                id = "yz6qglzv",
                isEnvironmental = false,
                name = "Illumination",
                skillBonuses = {},
                statBonuses = {},
                unlockLevel = 1
            }
        },
        units = {},
        weaponTypes = {}
    },
})
