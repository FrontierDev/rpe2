local _, Addon = ...

Addon.Data.DefaultDatasets:Register({
    version = 36,
    dataset = {
        achievements = {},
        auras = {
            {
                description = "",
                duration = 3,
                effects = {
                    {
                        baseAmount = 10,
                        operation = "percent",
                        statRef = "f82db71a:u7b49vs9",
                        statScaling = {},
                        type = "stat"
                    },
                    {
                        baseAmount = -10,
                        operation = "flat",
                        statRef = "f82db71a:gj9wxb0x",
                        statScaling = {},
                        type = "stat"
                    },
                    {
                        baseAmount = 5,
                        operation = "flat",
                        statRef = "f82db71a:jslmczbi",
                        statScaling = {},
                        type = "stat"
                    }
                },
                events = {},
                icon = "interface/icons/spell_holy_holysmite.blp",
                id = "sotc9a2f",
                maxStacks = 1,
                name = "Seal of the Crusader",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Increases Melee Attack Power by 10%. Reduces Damage Done by 10%. Increases Melee Crit. Chance by 5%.",
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
                        baseAmount = -100,
                        operation = "flat",
                        statRef = "f82db71a:hlyrsstn",
                        statScaling = {},
                        type = "stat"
                    }
                },
                events = {},
                icon = "interface/icons/spell_holy_holysmite.blp",
                id = "jotc5d7e",
                maxStacks = 1,
                name = "Judgement of the Crusader",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Reduces Holy Resistance by {AURA_STAT_1}.",
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
                duration = 2,
                effects = {
                    {
                        amountMode = "flat",
                        baseAbsorption = 0,
                        damageSchoolRefs = {},
                        statScaling = {
                            {
                                coefficient = 8,
                                statRef = "f82db71a:ygjno50i"
                            }
                        },
                        type = "absorb"
                    }
                },
                events = {},
                icon = "interface/icons/spell_holy_sealoffury.blp",
                id = "fbar2e8d",
                maxStacks = 1,
                name = "Righteous Indignation",
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
                    },
                    {
                        chance = 100,
                        combatEventId = "on_melee_hit",
                        effects = {
                            {
                                auraRef = "b0211ab3:fbar2e8d",
                                basePower = 0,
                                duration = 2,
                                stacks = 1,
                                type = "apply_aura"
                            }
                        },
                        triggerTarget = "aura_caster"
                    }
                },
                icon = "interface/icons/spell_holy_sealoffury.blp",
                id = "sfry7c1b",
                maxStacks = 1,
                name = "Seal of Fury",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "When the affected unit hits with a basic attack, the target takes {AURA_EVENT_DAMAGE_1} Holy damage. When the affected unit hits with a melee attack, apply Righteous Indignation to yourself for 2 turns.",
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
                effects = {
                    {
                        amountMode = "flat",
                        baseDamage = 11.2667,
                        damageSchoolRefs = {
                            "f82db71a:wwctys5s"
                        },
                        statScaling = {
                            {
                                coefficient = 0.169,
                                statRef = "f82db71a:7t7xgzcx"
                            }
                        },
                        threatCoefficient = 0.49,
                        type = "damage"
                    }
                },
                events = {},
                icon = "interface/icons/spell_holy_innerfire.blp",
                id = "q7m4v2ka",
                maxStacks = 1,
                name = "Consecration",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Deals {AURA_DAMAGE_1} Holy damage each turn. Generates a low amount of threat.",
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
                        baseAmount = 5,
                        operation = "flat",
                        statRef = "f82db71a:rgnrtg01",
                        statScaling = {},
                        type = "stat"
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
                    bodyText = "Increases Resource Regeneration by 5%.",
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
                        baseAmount = 5,
                        operation = "flat",
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
                        statRef = "f82db71a:p8syz5ba",
                        statScaling = {},
                        type = "stat"
                    }
                },
                events = {},
                icon = "interface/icons/ability_defend.blp",
                id = "rdbtaura",
                maxStacks = 1,
                name = "Redoubt",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Increases Block Chance by 30%.",
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
                        baseAmount = 30,
                        operation = "flat",
                        statRef = "f82db71a:p8syz5ba",
                        statScaling = {},
                        type = "stat"
                    }
                },
                events = {
                    {
                        chance = 100,
                        combatEventId = "on_defence",
                        defenceStatRef = "f82db71a:p8syz5ba",
                        effects = {
                            {
                                amountMode = "flat",
                                baseDamage = 96,
                                damageSchoolRefs = {
                                    "f82db71a:wwctys5s"
                                },
                                statScaling = {
                                    {
                                        coefficient = 0.2,
                                        statRef = "f82db71a:7t7xgzcx"
                                    }
                                },
                                type = "damage"
                            }
                        },
                        triggerTarget = "event_source"
                    }
                },
                icon = "interface/icons/spell_holy_blessingofprotection.blp",
                id = "hlyshlda",
                maxStacks = 1,
                name = "Holy Shield",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Increases Block Chance by {AURA_STAT_1}. When you successfully block an attack, deal {AURA_EVENT_DAMAGE_1} Holy damage to the attacker.",
                    bodyTokens = {
                        {
                            applyMode = "stat_amount",
                            baseField = "baseAmount",
                            effectIndex = 1,
                            key = "AURA_STAT_1",
                            tokenType = "aura_amount"
                        },
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
                        baseDamage = 23.9417,
                        damageSchoolRefs = {
                            "f82db71a:wwctys5s"
                        },
                        statScaling = {
                            {
                                coefficient = 0.2514,
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
            },
            {
                description = "",
                duration = 2,
                effects = {
                    {
                        baseAmount = 30,
                        operation = "flat",
                        statRef = "f82db71a:gj9wxb0x",
                        statScaling = {},
                        type = "stat"
                    }
                },
                events = {},
                icon = "interface/icons/spell_holy_avenginewrath.blp",
                id = "omfso9hg",
                maxStacks = 1,
                name = "Avenging Wrath",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Increases Damage Done by 30%.",
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
                        baseAmount = 20,
                        operation = "flat",
                        statRef = "f82db71a:pu05li08",
                        statScaling = {},
                        type = "stat"
                    },
                    {
                        baseAmount = 100,
                        operation = "flat",
                        statRef = "f82db71a:0wyp78x9",
                        statScaling = {},
                        type = "stat"
                    }
                },
                events = {},
                icon = "interface/icons/spell_holy_heroism.blp",
                id = "3qs2oqf1",
                maxStacks = 1,
                name = "Guardian of Ancient Kings",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Increases Damage Reduction by 20%. Increases Defense Rating by {AURA_STAT_1}.",
                    bodyTokens = {
                        {
                            applyMode = "stat_amount",
                            baseField = "baseAmount",
                            effectIndex = 2,
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
                icon = "interface/icons/spell_holy_prayerofhealing.blp",
                id = "989cf7q9",
                maxStacks = 1,
                name = "Repentance",
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
                icon = "interface/icons/spell_holy_sealofmight.blp",
                id = "7s9prff0",
                maxStacks = 1,
                name = "Hammer of Justice",
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
                        amountMode = "flat",
                        baseAbsorption = 0,
                        damageSchoolRefs = {},
                        statScaling = {
                            {
                                coefficient = 8,
                                statRef = "f82db71a:ygjno50i"
                            }
                        },
                        type = "absorb"
                    }
                },
                events = {},
                icon = "interface/icons/ability_paladin_shieldofthetemplar.blp",
                id = "tplblw01",
                maxStacks = 1,
                name = "Templar's Bulwark",
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
                    "b0211ab3:yz6qglzv",
                    "b0211ab3:sxq460qa",
                    "b0211ab3:dvinintl",
                    "b0211ab3:holypwr3",
                    "b0211ab3:dvinstrg",
                    "b0211ab3:prcpldn1",
                    "b0211ab3:dflctpal",
                    "b0211ab3:antcpal1",
                    "b0211ab3:rdbttrait"
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
                            auraRef = "b0211ab3:sotc9a2f",
                            basePower = 0,
                            duration = 3,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "csa1f2b3",
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
                icon = "interface/icons/spell_holy_holysmite.blp",
                id = "scsp4a6c",
                cooldownChannel = 3,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Seal of the Crusader",
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
                            auraRef = "b0211ab3:sotc9a2f",
                            datasetId = "b0211ab3",
                            descriptionText = "Increases Melee Attack Power by 10%. Reduces Damage Done by 10%. Increases Melee Crit. Chance by 5%.",
                            duration = 3,
                            icon = "interface/icons/spell_holy_holysmite.blp",
                            nameText = "Seal of the Crusader",
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
                    mainText = "Apply Seal of the Crusader to yourself for 3 turns.",
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
                    "on_spell_hit"
                },
                charges = 0,
                components = {
                    {
                        castPhase = "on_cast_end",
                        castingGroup = "default",
                        effect = {
                            auraRef = "b0211ab3:sotc9a2f",
                            stacks = 1,
                            targetEvents = {},
                            type = "remove_aura"
                        },
                        key = "jca4d5e6",
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
                            auraRef = "b0211ab3:jotc5d7e",
                            basePower = 0,
                            duration = 5,
                            stacks = 1,
                            targetEvents = {
                                "on_spell_taken"
                            },
                            type = "apply_aura"
                        },
                        key = "jca7f8a9",
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
                        auraRef = "b0211ab3:sotc9a2f",
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Requires Seal of the Crusader",
                        type = "aura_requirement",
                        unit = "caster"
                    }
                },
                cooldown = 3,
                cooldownGroup = "judgement",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_holy_righteousfury.blp",
                id = "jcsp8f3a",
                cooldownChannel = 1,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Judgement of the Crusader",
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
                    auraSections = {
                        {
                            auraRef = "b0211ab3:jotc5d7e",
                            datasetId = "b0211ab3",
                            descriptionText = "Reduces Holy Resistance by {AURA_STAT_1}.",
                            duration = 5,
                            icon = "interface/icons/spell_holy_holysmite.blp",
                            nameText = "Judgement of the Crusader",
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
                                    applyMode = "stat_amount",
                                    baseField = "baseAmount",
                                    effectIndex = 1,
                                    key = "AURA_STAT_1",
                                    tokenType = "aura_amount"
                                }
                            }
                        }
                    },
                    mainText = "Apply Judgement of the Crusader to an enemy for 5 turns.",
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
                            auraRef = "b0211ab3:sfry7c1b",
                            basePower = 0,
                            duration = 3,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "sfa1b2c3",
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
                    },
                    {
                        invert = false,
                        requiresShield = true,
                        showOnTooltip = true,
                        slotKey = "offhand",
                        tooltipTextOverride = "Requires Shield",
                        type = "item_equipped",
                        weaponTypeRefs = {}
                    }
                },
                cooldown = 1,
                cooldownGroup = "seal",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_holy_sealoffury.blp",
                id = "sfsp6b2e",
                cooldownChannel = 3,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Seal of Fury",
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
                            auraRef = "b0211ab3:sfry7c1b",
                            datasetId = "b0211ab3",
                            descriptionText = "When the affected unit hits with a basic attack, the target takes {AURA_EVENT_DAMAGE_1} Holy damage. When the affected unit hits with a melee attack, apply Righteous Indignation to yourself for 2 turns.",
                            duration = 3,
                            icon = "interface/icons/spell_holy_sealoffury.blp",
                            nameText = "Seal of Fury",
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
                    mainText = "Apply Seal of Fury to yourself for 3 turns.",
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
                            baseDamage = 88.4,
                            damageSchoolRefs = {
                                "f82db71a:wwctys5s"
                            },
                            damageType = "spell",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.3094,
                                    statRef = "f82db71a:u7b49vs9"
                                }
                            },
                            targetEvents = {
                                "on_spell_taken",
                                "on_critical_hit_taken"
                            },
                            threatCoefficient = 2,
                            type = "damage",
                            usesProjectile = false,
                            weaponDamageCoefficient = 0,
                            weaponDamageMode = "none"
                        },
                        key = "jfa4d5e6",
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
                            auraRef = "b0211ab3:sfry7c1b",
                            stacks = 1,
                            targetEvents = {},
                            type = "remove_aura"
                        },
                        key = "jfa7b8c9",
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
                            duration = 1,
                            targetEvents = {},
                            type = "taunt"
                        },
                        key = "jfad1e2f",
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
                        auraRef = "b0211ab3:sfry7c1b",
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Requires Seal of Fury",
                        type = "aura_requirement",
                        unit = "caster"
                    }
                },
                cooldown = 3,
                cooldownGroup = "judgement",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_holy_righteousfury.blp",
                id = "jfsp9d4c",
                cooldownChannel = 1,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Judgement of Fury",
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
                    auraSections = {},
                    mainText = "Deal {DAMAGE_1} Holy damage to an enemy. Taunt an enemy for 1 turn. Generates a high amount of threat.",
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
                            amount = 15,
                            amountMode = "base_percent",
                            castPhase = "on_cast_end",
                            refundOnInterrupt = 0,
                            resourceRef = "f82db71a:q2ktkztt"
                        }
                    },
                    on_cast_start = {}
                },
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
                            baseHealing = 65,
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
                        key = "lma3b4c5",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = true,
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
                icon = "interface/icons/ability_paladin_lightofthemartyr.blp",
                id = "lotm7e2a",
                cooldownChannel = 2,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Light of the Martyr",
                range = 0,
                resourceCosts = {
                    {
                        amount = 15,
                        amountMode = "base_percent",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:q2ktkztt"
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
                _resourceCostsByPhase = {
                    on_cast_end = {
                        {
                            amount = 50,
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
                            baseHealing = 0,
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 10,
                                    statRef = "f82db71a:ygjno50i"
                                }
                            },
                            targetEvents = {
                                "on_heal_taken"
                            },
                            type = "heal",
                            usesProjectile = false
                        },
                        key = "loh6d7e8",
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
                icon = "interface/icons/spell_holy_layonhands.blp",
                id = "lohs3c8f",
                cooldownChannel = 1,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Lay on Hands",
                range = 0,
                resourceCosts = {
                    {
                        amount = 50,
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
                _resourceCostsByPhase = {
                    on_cast_end = {
                        {
                            amount = 12.5,
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
                            auraRef = "b0211ab3:q7m4v2ka",
                            basePower = 0,
                            duration = 3,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "s9p6x4qc",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = true,
                            maxTargets = 4,
                            minTargets = 1,
                            requiresTarget = true,
                            targetDisposition = "enemy",
                            type = "multi"
                        }
                    }
                },
                conditions = {},
                cooldown = 0,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_holy_innerfire.blp",
                id = "r8n5w3pb",
                cooldownChannel = 2,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Consecration",
                range = 0,
                resourceCosts = {
                    {
                        amount = 12.5,
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
                            auraRef = "b0211ab3:q7m4v2ka",
                            datasetId = "b0211ab3",
                            descriptionText = "Deals {AURA_DAMAGE_1} Holy damage each turn. Generates a low amount of threat.",
                            duration = 3,
                            icon = "interface/icons/spell_holy_innerfire.blp",
                            nameText = "Consecration",
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
                    mainText = "Apply Consecration to up to 4 enemies for 3 turns.",
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
                cooldownGroup = "blessing",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_holy_greaterblessingofkings.blp",
                id = "h981ofan",
                cooldownChannel = 3,
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
                                object = "all allies",
                                possessive = "all allies'",
                                reflexive = "themselves",
                                subject = "all allies"
                            },
                            tokens = {}
                        }
                    },
                    mainText = "Apply Blessing of Might to all allies for 10 turns.",
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
                cooldownGroup = "blessing",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_magic_greaterblessingofkings.blp",
                id = "wfq254qz",
                cooldownChannel = 3,
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
                                object = "all allies",
                                possessive = "all allies'",
                                reflexive = "themselves",
                                subject = "all allies"
                            },
                            tokens = {}
                        }
                    },
                    mainText = "Apply Blessing of Kings to all allies for 10 turns.",
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
                cooldownGroup = "blessing",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_holy_greaterblessingofsanctuary.blp",
                id = "zg4n0a1f",
                cooldownChannel = 3,
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
                                object = "all allies",
                                possessive = "all allies'",
                                reflexive = "themselves",
                                subject = "all allies"
                            },
                            tokens = {}
                        }
                    },
                    mainText = "Apply Blessing of Sanctuary to all allies for 10 turns.",
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
                cooldownGroup = "blessing",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_holy_greaterblessingofwisdom.blp",
                id = "xdt25qxt",
                cooldownChannel = 3,
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
                            descriptionText = "Increases Resource Regeneration by 5%.",
                            duration = 10,
                            icon = "interface/icons/spell_holy_greaterblessingofwisdom.blp",
                            nameText = "Blessing of Wisdom",
                            powerLevel = 0,
                            spellDatasetId = "b0211ab3",
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
                    mainText = "Apply Blessing of Wisdom to all allies for 10 turns.",
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
                cooldownGroup = "blessing",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_holy_greaterblessingoflight.blp",
                id = "ms0v0du4",
                cooldownChannel = 3,
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
                                object = "all allies",
                                possessive = "all allies'",
                                reflexive = "themselves",
                                subject = "all allies"
                            },
                            tokens = {}
                        }
                    },
                    mainText = "Apply Blessing of Light to all allies for 10 turns.",
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
                            type = "multi"
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
                cooldownChannel = 3,
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
                                    coefficient = 0.5525,
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
                cooldownChannel = 1,
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
                cooldownChannel = 3,
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
                            baseDamage = 82.875,
                            damageSchoolRefs = {
                                "f82db71a:wwctys5s"
                            },
                            damageType = "spell",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.3868,
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
                cooldownChannel = 1,
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
                cooldownChannel = 3,
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
                            baseHealing = 60.775,
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.3647,
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
                cooldownChannel = 1,
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
                cooldownChannel = 3,
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
                cooldownChannel = 1,
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
                cooldownChannel = 3,
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
                            baseDamage = 82.875,
                            damageSchoolRefs = {
                                "f82db71a:wwctys5s"
                            },
                            damageType = "melee",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.3868,
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
                            weaponDamageCoefficient = 1.105,
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
                cooldownChannel = 1,
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
                                    coefficient = 0.7875,
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
                cooldownChannel = 1,
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
                            baseDamage = 46.8,
                            damageSchoolRefs = {
                                "f82db71a:wwctys5s"
                            },
                            damageType = "melee",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.2184,
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
                            weaponDamageCoefficient = 0.624,
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
                            type = "raid_marker"
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
                cooldownChannel = 1,
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
                    mainText = "Deal {DAMAGE_1} Holy damage to up to 3 enemies. Generates a high amount of threat. Targets must share the same raid marker.",
                    mainText = "Deal {DAMAGE_1} Holy damage to up to 3 enemies. Generates a high amount of threat. Targets must share the same raid marker.",
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
                            baseDamage = 57.46,
                            damageSchoolRefs = {
                                "f82db71a:wwctys5s"
                            },
                            damageType = "melee",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.2011,
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
                            weaponDamageCoefficient = 0,
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
                cooldownChannel = 2,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Shield of the Righteous",
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
                            auraRef = "b0211ab3:hlyshlda",
                            basePower = 0,
                            duration = 3,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "hshld001",
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
                cooldown = 3,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_holy_blessingofprotection.blp",
                id = "hlyshlds",
                cooldownChannel = 3,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Holy Shield",
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
                            auraRef = "b0211ab3:hlyshlda",
                            datasetId = "b0211ab3",
                            descriptionText = "Increases Block Chance by {AURA_STAT_1}. When you successfully block an attack, deal {AURA_EVENT_DAMAGE_1} Holy damage to the attacker.",
                            duration = 3,
                            icon = "interface/icons/spell_holy_blessingofprotection.blp",
                            nameText = "Holy Shield",
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
                                    applyMode = "stat_amount",
                                    baseField = "baseAmount",
                                    effectIndex = 1,
                                    key = "AURA_STAT_1",
                                    tokenType = "aura_amount"
                                },
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
                    mainText = "Apply Holy Shield to yourself for 3 turns.",
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
                cooldownChannel = 5,
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
                cooldownChannel = 1,
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
                cooldownChannel = 1,
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
                cooldownChannel = 3,
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
                            weaponDamageCoefficient = 0,
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
                cooldownChannel = 1,
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
                            weaponDamageCoefficient = 0,
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
                cooldownChannel = 1,
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
                                    coefficient = 0.4725,
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
                            type = "raid_marker"
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
                cooldownChannel = 1,
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
                    mainText = "Deal {DAMAGE_1} Holy damage to up to 3 enemies. Targets must share the same raid marker.",
                    mainText = "Deal {DAMAGE_1} Holy damage to up to 3 enemies. Targets must share the same raid marker.",
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
                            applyAura = true,
                            auraRef = "b0211ab3:bgmk5vpf",
                            auraStacks = 1,
                            baseDamage = 123.25,
                            damageSchoolRefs = {
                                "f82db71a:wwctys5s"
                            },
                            damageType = "spell",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.4314,
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
                            weaponDamageCoefficient = 0,
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
                cooldownChannel = 1,
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
                            duration = 3,
                            targetEvents = {},
                            type = "taunt"
                        },
                        key = "1a2b3c4d",
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
                icon = "interface/icons/spell_holy_unyieldingfaith.blp",
                id = "hork7m2p",
                cooldownChannel = 2,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Hand of Reckoning",
                range = 0,
                resourceCosts = {
                    {
                        amount = 1,
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
                    mainText = "Taunt an enemy for 3 turns.",
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
                cooldownChannel = 5,
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
                                    coefficient = 0.675,
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
                cooldownChannel = 1,
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
                useCooldownCharges = false
            },
            {
                allowDeadTargets = false,
                canMoveWhileCasting = false,
                castTime = 0,
                casterEvents = {
                    "on_heal",
                    "on_heal_taken",
                    "on_critical_heal",
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
                            baseHealing = 37.538,
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.2252,
                                    statRef = "f82db71a:hj6d4kvy"
                                }
                            },
                            targetEvents = {},
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
                cooldownChannel = 2,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Light of the Protector",
                range = 0,
                resourceCosts = {
                    {
                        amount = 2,
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
                            auraRef = "b0211ab3:3qs2oqf1",
                            basePower = 0,
                            duration = 1,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "gak8p3v1",
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
                icon = "interface/icons/spell_holy_heroism.blp",
                id = "gak8p3v1",
                cooldownChannel = 5,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Guardian of Ancient Kings",
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
                            auraRef = "b0211ab3:3qs2oqf1",
                            datasetId = "b0211ab3",
                            descriptionText = "Increases Damage Reduction by 20%. Increases Defense Rating by {AURA_STAT_1}.",
                            duration = 1,
                            icon = "interface/icons/spell_holy_heroism.blp",
                            nameText = "Guardian of Ancient Kings",
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
                                    applyMode = "stat_amount",
                                    baseField = "baseAmount",
                                    effectIndex = 2,
                                    key = "AURA_STAT_1",
                                    tokenType = "aura_amount"
                                }
                            }
                        }
                    },
                    mainText = "Apply Guardian of Ancient Kings to yourself for 1 turn.",
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
                            auraRef = "b0211ab3:7s9prff0",
                            basePower = 0,
                            duration = 1,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "hoj2q6x4",
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
                icon = "interface/icons/spell_holy_sealofmight.blp",
                id = "hoj2q6x4",
                cooldownChannel = 2,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Hammer of Justice",
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
                            auraRef = "b0211ab3:7s9prff0",
                            datasetId = "b0211ab3",
                            descriptionText = "Prevents the affected unit from casting spells. Sets the affected unit's movement range to 0. Causes all attacks against the affected unit to automatically hit.",
                            duration = 1,
                            icon = "interface/icons/spell_holy_sealofmight.blp",
                            nameText = "Hammer of Justice",
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
                    mainText = "Apply Hammer of Justice to an enemy for 1 turn.",
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
                            auraRef = "b0211ab3:omfso9hg",
                            basePower = 0,
                            duration = 2,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "awr9m5d2",
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
                icon = "interface/icons/spell_holy_avenginewrath.blp",
                id = "awr9m5d2",
                cooldownChannel = 3,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Avenging Wrath",
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
                    auraSections = {
                        {
                            auraRef = "b0211ab3:omfso9hg",
                            datasetId = "b0211ab3",
                            descriptionText = "Increases Damage Done by 30%.",
                            duration = 2,
                            icon = "interface/icons/spell_holy_avenginewrath.blp",
                            nameText = "Avenging Wrath",
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
                    mainText = "Apply Avenging Wrath to yourself for 2 turns.",
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
                            auraRef = "b0211ab3:tplblw01",
                            basePower = 0,
                            duration = 1,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "tplblwc1",
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
                icon = "interface/icons/ability_paladin_shieldofthetemplar.blp",
                id = "tplblwsp",
                cooldownChannel = 5,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Templar's Bulwark",
                range = 0,
                resourceCosts = {},
                seedNPCSpell = false,
                spellbookCategory = "Protection",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "b0211ab3:tplblw01",
                            datasetId = "b0211ab3",
                            descriptionText = "Absorbs {AURA_ABSORB_1} damage.",
                            duration = 1,
                            icon = "interface/icons/ability_paladin_shieldofthetemplar.blp",
                            nameText = "Templar's Bulwark",
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
                                    applyMode = "absorb_amount",
                                    baseField = "baseAbsorption",
                                    effectIndex = 1,
                                    key = "AURA_ABSORB_1",
                                    tokenType = "aura_amount"
                                }
                            }
                        }
                    },
                    mainText = "Apply Templar's Bulwark to yourself for 1 turn.",
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
                            auraRef = "b0211ab3:989cf7q9",
                            basePower = 0,
                            duration = 2,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "rep7n4c8",
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
                icon = "interface/icons/spell_holy_prayerofhealing.blp",
                id = "rep7n4c8",
                cooldownChannel = 1,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Repentance",
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
                    auraSections = {
                        {
                            auraRef = "b0211ab3:989cf7q9",
                            datasetId = "b0211ab3",
                            descriptionText = "Breaks when the affected unit takes damage. Prevents the affected unit from casting spells. Sets the affected unit's movement range to 0. Causes all attacks against the affected unit to automatically hit.",
                            duration = 2,
                            icon = "interface/icons/spell_holy_prayerofhealing.blp",
                            nameText = "Repentance",
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
                    mainText = "Apply Repentance to an enemy for 2 turns.",
                    tokens = {},
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
                description = "When you take melee damage, you have a 50% chance to gain 30% Block Chance for 1 turn.",
                events = {
                    {
                        chance = 50,
                        combatEventId = "on_melee_taken",
                        effects = {
                            {
                                auraRef = "b0211ab3:rdbtaura",
                                basePower = 0,
                                duration = 1,
                                stacks = 1,
                                type = "apply_aura"
                            }
                        },
                        triggerTarget = "aura_caster"
                    }
                },
                icon = "interface/icons/ability_defend.blp",
                id = "rdbttrait",
                isEnvironmental = false,
                name = "Redoubt",
                skillBonuses = {},
                statBonuses = {},
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
                                amount = 10,
                                amountMode = "base_percent",
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
            },
            {
                automaticAuras = {},
                category = "Protection",
                conditions = {},
                description = "",
                events = {},
                icon = "interface/icons/spell_holy_devotion.blp",
                id = "sxq460qa",
                isEnvironmental = false,
                name = "Toughness",
                skillBonuses = {},
                statBonuses = {
                    {
                        operation = "percent",
                        statRef = "f82db71a:v42albuv",
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
                icon = "interface/icons/spell_nature_sleep.blp",
                id = "dvinintl",
                isEnvironmental = false,
                name = "Divine Intellect",
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
                category = "Holy",
                conditions = {},
                description = "",
                events = {},
                icon = "interface/icons/spell_holy_power.blp",
                id = "holypwr3",
                isEnvironmental = false,
                name = "Holy Power",
                skillBonuses = {},
                statBonuses = {
                    {
                        statRef = "f82db71a:69hfqhne",
                        value = 3
                    }
                },
                unlockLevel = 1
            },
            {
                automaticAuras = {},
                category = "Retribution",
                conditions = {},
                description = "",
                events = {},
                icon = "interface/icons/ability_golemthunderclap.blp",
                id = "dvinstrg",
                isEnvironmental = false,
                name = "Divine Strength",
                skillBonuses = {},
                statBonuses = {
                    {
                        operation = "percent",
                        statRef = "f82db71a:zfqm8dxp",
                        value = 10
                    }
                },
                unlockLevel = 1
            },
            {
                automaticAuras = {},
                category = "Retribution",
                conditions = {},
                description = "",
                events = {},
                icon = "interface/icons/ability_rogue_ambush.blp",
                id = "prcpldn1",
                isEnvironmental = false,
                name = "Precision",
                skillBonuses = {},
                statBonuses = {
                    {
                        statRef = "f82db71a:wbj4zuf3",
                        value = 3
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
                icon = "interface/icons/ability_parry.blp",
                id = "dflctpal",
                isEnvironmental = false,
                name = "Deflection",
                skillBonuses = {},
                statBonuses = {
                    {
                        statRef = "f82db71a:tcn0s8kx",
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
                icon = "interface/icons/spell_magic_lesserinvisibilty.blp",
                id = "antcpal1",
                isEnvironmental = false,
                name = "Anticipation",
                skillBonuses = {},
                statBonuses = {
                    {
                        statRef = "f82db71a:0wyp78x9",
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
