local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Tooltips = Addon.Client.UI.Tooltips or {}
Addon.Client.Traits = Addon.Client.Traits or {}

local Tooltips = Addon.Client.UI.Tooltips
local Traits = Addon.Client.Traits or {}
local Conditions = Addon.Client and Addon.Client.Conditions or {}

local TraitTooltip = Tooltips.Trait or {}
Tooltips.Trait = TraitTooltip

local function ensureString(value, fallback)
    if value == nil or value == "" then
        return fallback or ""
    end

    return tostring(value)
end

local function buildTooltipDescription(detail, owner)
    local descriptionBuilder = Traits and Traits.DescriptionBuilder or nil
    if type(descriptionBuilder) == "table" and type(descriptionBuilder.BuildTooltipData) == "function" then
        local tooltipData = descriptionBuilder:BuildTooltipData(detail, {
            tooltipOwner = owner,
        })
        if type(tooltipData) == "table" then
            tooltipData.descriptionText = ensureString(tooltipData.descriptionText, "")
            tooltipData.auraSections = type(tooltipData.auraSections) == "table" and tooltipData.auraSections or {}
            return tooltipData
        end
    end

    return {
        descriptionText = ensureString(type(detail) == "table" and detail.descriptionText or "", ""),
        auraSections = {},
    }
end

local function buildInactiveTooltip(detail)
    return {
        type = "game",
        title = ensureString(detail and detail.name, "Unknown Trait"),
        titleColor = { r = 0.7, g = 0.7, b = 0.7 },
        lines = {
            {
                text = "This trait definition is missing from its dataset.",
                r = 1,
                g = 0.25,
                b = 0.25,
                wrap = true,
            },
        },
    }
end

local function buildConditionLines(detail)
    if type(Conditions) ~= "table" or type(Conditions.BuildTooltipLines) ~= "function" then
        return {}
    end

    local payload = type(detail) == "table" and (detail.traitPayload or detail.payload or detail.trait or detail.consumableTrait) or nil
    local context = Conditions:BuildContext("trait", payload, {
        traitRef = type(detail) == "table" and detail.traitRef or nil,
        item = type(detail) == "table" and detail.item or nil,
        itemRef = type(detail) == "table" and detail.itemRef or nil,
    })
    return Conditions:BuildTooltipLines(payload and payload.conditions or nil, context)
end

function TraitTooltip:Build(detail, owner)
    if type(detail) ~= "table" then
        return nil
    end

    if detail.isMissing == true then
        return buildInactiveTooltip(detail)
    end

    local tooltipData = buildTooltipDescription(detail, owner)
    local description = ensureString(tooltipData and tooltipData.descriptionText, "")
    local lines = {}
    local conditionLines = buildConditionLines(detail)

    for index = 1, #conditionLines do
        lines[#lines + 1] = conditionLines[index]
    end

    if description ~= "" then
        lines[#lines + 1] = {
            text = description,
            r = 1,
            g = 0.82,
            b = 0,
            wrap = true,
        }
    end

    local auraSections = type(tooltipData) == "table" and tooltipData.auraSections or {}
    for index = 1, #auraSections do
        local section = auraSections[index]
        if type(section) == "table" and ensureString(section.descriptionText, "") ~= "" then
            lines[#lines + 1] = " "
            lines[#lines + 1] = {
                text = ensureString(section.name, "Aura"),
                r = 1,
                g = 1,
                b = 1,
                wrap = true,
            }
            lines[#lines + 1] = {
                text = ensureString(section.descriptionText, ""),
                r = 1,
                g = 0.82,
                b = 0,
                wrap = true,
            }
        end
    end

    return {
        type = "game",
        title = ensureString(detail.name, "Trait"),
        titleColor = { r = 1, g = 1, b = 1 },
        lines = lines,
    }
end

return TraitTooltip
