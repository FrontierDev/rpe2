local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local function assertTrue(value, message)
    if value ~= true then error(message, 2) end
end

local units = {
    ["warlock:felhnt01"] = {
        name = "Felhunter",
        spells = {},
    },
    ["core:voidw001"] = {
        name = "Voidwalker",
        spells = {
            "core:taunt",
        },
    },
}

local datasets = {
    {
        id = "warlock",
        pets = {
            {
                id = "smnfelh1",
                name = "Summoned Felhunter",
                unitRef = "warlock:felhnt01",
                spells = {
                    "warlock:petattack",
                    "warlock:spelllock",
                },
            },
        },
    },
}

local Addon = {
    Client = {
        Spellcasting = {},
        Combat = {},
    },
    Internal = {
        Database = {
            Dependecies = {},
            ListDatasets = function()
                return datasets
            end,
        },
        Comms = {
            ResourceSync = {},
        },
        Profile = {},
        Registry = {
            ResolveUnitDefinition = function(_, unitRef)
                return nil, units[unitRef]
            end,
            ResolveSpellName = function(_, spellRef)
                local names = {
                    ["warlock:petattack"] = "Pet Attack",
                    ["warlock:spelllock"] = "Spell Lock",
                    ["core:taunt"] = "Taunt",
                }
                return names[spellRef] or spellRef
            end,
        },
    },
    Utils = {
        Common = {},
    },
}

local function loadAddonFile(path)
    local chunk, loadError = loadfile(path)
    assert(chunk, loadError)
    chunk("RPEngine2", Addon)
end

loadAddonFile("client/spellcasting/TooltipTemplate.lua")
loadAddonFile("client/spellcasting/AuraDescriptionBuilder.lua")
loadAddonFile("client/spellcasting/DescriptionBuilder.lua")

local builder = Addon.Client.Spellcasting.DescriptionBuilder
local explicitPetDetail = {
    spell = {
        components = {
            {
                effect = {
                    type = "summon_pet",
                    unitRef = "warlock:felhnt01",
                },
            },
        },
    },
    casterUnit = {},
}
local expectedPetDescription = "Summon Felhunter as your pet. This replaces your current pet. Available abilities: Pet Attack, Spell Lock."
assertEqual(builder:BuildGeneratedDescription(explicitPetDetail, explicitPetDetail.casterUnit), expectedPetDescription,
    "explicit summon pet description")

local payload = builder:BuildTooltipTemplatePayload(explicitPetDetail)
assertTrue(type(payload) == "table", "explicit summon pet template payload is built")
local resolvedPayload, payloadError = builder:ResolveTooltipTemplatePayload(explicitPetDetail, payload, explicitPetDetail.casterUnit)
assertTrue(type(resolvedPayload) == "table", payloadError or "explicit summon pet template payload resolves")
assertEqual(resolvedPayload.descriptionText, expectedPetDescription, "explicit summon pet template description")

local generatedTemplateDetail = {
    spell = {
        components = explicitPetDetail.spell.components,
        tooltipTemplate = true,
    },
    casterUnit = explicitPetDetail.casterUnit,
}
local generatedTemplateData = builder:BuildTooltipData(generatedTemplateDetail, { deferGeneration = false })
assertEqual(generatedTemplateData.descriptionText, expectedPetDescription,
    "summon pet template flag generates a missing payload")

local selectedPetDetail = {
    spell = {
        components = {
            {
                effect = {
                    type = "summon_pet",
                },
            },
        },
    },
    casterUnit = {
        petRef = "warlock:smnfelh1",
    },
}
assertEqual(builder:BuildGeneratedDescription(selectedPetDetail, selectedPetDetail.casterUnit), expectedPetDescription,
    "profile-selected summon pet description")

local genericUnitDetail = {
    spell = {
        components = {
            {
                effect = {
                    type = "summon_unit",
                    unitRef = "core:voidw001",
                },
            },
        },
    },
    casterUnit = {},
}
assertEqual(builder:BuildGeneratedDescription(genericUnitDetail, genericUnitDetail.casterUnit),
    "Summon Voidwalker as a controlled unit. This is separate from your pet. Available abilities: Taunt.",
    "summon unit description")

print("SummonTooltipRegressionTest passed")
