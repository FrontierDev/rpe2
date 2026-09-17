local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Tooltips = Addon.Client.UI.Tooltips or {}

local Tooltips = Addon.Client.UI.Tooltips
local Client = Addon.Client or {}
local Profile = Addon.Internal and Addon.Internal.Profile or {}
local Registry = Addon.Internal and Addon.Internal.Registry or {}
local Ruleset = Addon.Internal and Addon.Internal.Ruleset or {}
local ResourceSync = Addon.Internal and Addon.Internal.Comms and Addon.Internal.Comms.ResourceSync or {}
local Spellcasting = Addon.Client and Addon.Client.Spellcasting or {}
local Conditions = Addon.Client and Addon.Client.Conditions or {}
local SpellTooltip = Tooltips.Spell or {}
Tooltips.Spell = SpellTooltip

local function ensureString(value, fallback)
    if value == nil or value == "" then
        return fallback or ""
    end

    return tostring(value)
end

local function trimText(value)
    return ensureString(value):gsub("^%s+", ""):gsub("%s+$", "")
end

local function resolveCooldownChannel(detail)
    if type(detail) ~= "table" then
        return nil
    end

    local resolvedChannelId = detail.cooldownChannelId
    if resolvedChannelId ~= nil and type(Ruleset.GetCooldownChannel) == "function" then
        local channel = Ruleset.GetCooldownChannel(resolvedChannelId)
        local channelName = trimText(channel and channel.name)
        if channel and channel.enabled == true and channelName ~= "" then
            return channel
        end

        return nil
    end

    local resolvedChannelName = trimText(detail.cooldownChannelName)
    if resolvedChannelName ~= "" then
        return {
            name = resolvedChannelName,
            enabled = true,
            triggersGCD = detail.cooldownChannelTriggersGCD == true,
            canUseOffTurn = detail.cooldownChannelCanUseOffTurn == true,
        }
    end

    local spell = detail.spell
    if type(spell) ~= "table" or type(Spellcasting.ResolveSpellCooldownChannel) ~= "function" then
        return nil
    end

    local channelId, channel = Spellcasting.ResolveSpellCooldownChannel(spell)
    local channelName = trimText(channel and channel.name)
    if channelId ~= nil and channel and channel.enabled == true and channelName ~= "" then
        return channel
    end

    return nil
end

local function resolveScalingStatName(statRef)
    local normalizedRef = trimText(statRef)
    if normalizedRef == "" then
        return nil
    end

    if type(Profile.GetResolvedStatRow) == "function" then
        local resolvedRow = Profile.GetResolvedStatRow(normalizedRef)
        local resolvedName = trimText(resolvedRow and resolvedRow.name)
        if resolvedName ~= "" then
            return string.lower(resolvedName)
        end
    end

    if type(Registry.ResolveStatReference) == "function" then
        local _, stat = Registry:ResolveStatReference(normalizedRef)
        local statName = trimText(stat and stat.name)
        if statName ~= "" then
            return string.lower(statName)
        end
    end

    return nil
end

local function getSpellScalingStatNames(spell)
    if type(spell) ~= "table" then
        return {}
    end

    local names = {}
    local seenRefs = {}
    local components = type(spell.components) == "table" and spell.components or {}
    for componentIndex = 1, #components do
        local component = components[componentIndex]
        local effect = type(component) == "table" and component.effect or nil
        local statScaling = type(effect) == "table" and type(effect.statScaling) == "table" and effect.statScaling or {}
        for scalingIndex = 1, #statScaling do
            local scaling = statScaling[scalingIndex]
            local statRef = trimText(scaling and scaling.statRef)
            if statRef ~= "" and not seenRefs[statRef] then
                local statName = resolveScalingStatName(statRef)
                if statName then
                    names[#names + 1] = statName
                    seenRefs[statRef] = true
                end
            end
        end
    end

    return names
end

local function buildAuraHeaderText(section)
    local name = ensureString(type(section) == "table" and section.name, "Aura")
    local icon = ensureString(type(section) == "table" and section.icon, "")
    if icon == "" then
        return name
    end

    return ("|T%s:14|t %s"):format(icon, name)
end

local function formatTurnLabel(turns, suffix)
    local numericTurns = math.max(0, math.floor(tonumber(turns) or 0))
    if numericTurns == 1 then
        return ("1 turn %s"):format(suffix)
    end
    return ("%d turns %s"):format(numericTurns, suffix)
end

local function resolveResourceName(resourceRef)
    local resolvedRow = Profile.GetResolvedResourceRow and Profile.GetResolvedResourceRow(resourceRef) or nil
    local resolvedName = resolvedRow and resolvedRow.name or nil
    if type(resolvedName) == "string" and resolvedName ~= "" then
        return resolvedName
    end

    if type(ResourceSync.ResolveResourceName) == "function" then
        return ensureString(ResourceSync.ResolveResourceName(resourceRef), "Resource")
    end

    return ensureString(resourceRef, "Resource")
end

local function formatTurnCount(turns)
    local numericTurns = math.max(0, math.floor(tonumber(turns) or 0))
    if numericTurns == 1 then
        return "1 turn"
    end

    return ("%d turns"):format(numericTurns)
end

local function buildCostSegment(cost, includePhaseSuffix)
    if type(cost) ~= "table" then
        return nil
    end

    local amount = math.max(0, tonumber(cost.amount) or 0)
    if amount <= 0 then
        return nil
    end

    local resourceName = resolveResourceName(tostring(cost.resourceRef or ""))
    local amountMode = tostring(cost.amountMode or "flat")
    local amountText = ""
    
    if amountMode == "base_percent" then
        amountText = ("%g%% of Base %s"):format(amount, resourceName)
    elseif amountMode == "max_percent" then
        amountText = ("%g%% of Max %s"):format(amount, resourceName)
    else
        amountText = ("%g %s"):format(amount, resourceName)
    end

    if not includePhaseSuffix then
        return amountText
    end

    local phase = tostring(cost.castPhase or "on_cast_end")
    local phaseSuffix = phase == "on_cast_start" and "Start" or "End"
    return ("%s (%s)"):format(amountText, phaseSuffix)
end

local function buildTooltipCasterUnit(detail)
    if type(detail) == "table" and type(detail.casterUnit) == "table" then
        return detail.casterUnit
    end

    local descriptionBuilder = Spellcasting and Spellcasting.DescriptionBuilder or nil
    if type(descriptionBuilder) == "table" and type(descriptionBuilder.ResolveCasterUnit) == "function" then
        return descriptionBuilder.ResolveCasterUnit(detail)
    end

    return {
        isPlayer = true,
        resources = {},
    }
end

local function buildTooltipDescription(detail, owner)
    local descriptionBuilder = Spellcasting and Spellcasting.DescriptionBuilder or nil
    if type(descriptionBuilder) == "table" and type(descriptionBuilder.BuildTooltipData) == "function" then
        return descriptionBuilder:BuildTooltipData(detail, {
            tooltipOwner = owner,
            deferGeneration = false,
        }) or {
            descriptionText = "",
            auraSections = {},
        }
    end

    local spell = type(detail) == "table" and detail.spell or nil
    local authoredDescriptionText = trimText(type(detail) == "table" and detail.authoredDescriptionText or spell and spell.description or "")
    if authoredDescriptionText ~= "" then
        return {
            descriptionText = authoredDescriptionText,
            descriptionSource = "authored",
            auraSections = {},
        }
    end

    return {
        descriptionText = "",
        descriptionSource = "summary",
        auraSections = {},
    }
end

local function buildRuntimeActivationState(detail)
    if type(detail) ~= "table" then
        return nil
    end

    local cooldownRemaining = tonumber(detail.cooldownRemaining)
    local currentCharges = tonumber(detail.currentCharges)
    local maxCharges = tonumber(detail.maxCharges)
    local hasChannelState = detail.cooldownChannelId ~= nil or detail.channelCooldownRemaining ~= nil
    local hasSpellRef = type(detail.spellRef) == "string" and detail.spellRef ~= ""
    if hasChannelState
        or ((cooldownRemaining ~= nil or currentCharges ~= nil or maxCharges ~= nil) and not hasSpellRef)
    then
        return {
            cooldownRemaining = cooldownRemaining,
            currentCharges = currentCharges,
            maxCharges = maxCharges,
            cooldownChannelId = detail.cooldownChannelId,
            cooldownChannelName = detail.cooldownChannelName,
            cooldownChannelTriggersGCD = detail.cooldownChannelTriggersGCD == true,
            cooldownChannelCanUseOffTurn = detail.cooldownChannelCanUseOffTurn == true,
            channelCooldownRemaining = tonumber(detail.channelCooldownRemaining),
        }
    end

    if type(detail.spellRef) == "string" and detail.spellRef ~= "" and type(Client.ResolveSpellActivationState) == "function" then
        local activationState = Client:ResolveSpellActivationState(detail.spellRef, {
            includeTargetCandidates = false,
        })
        if type(activationState) == "table" then
            return activationState
        end
    end

    return nil
end

local function buildConditionLines(detail)
    if type(Conditions) ~= "table" or type(Conditions.BuildTooltipLines) ~= "function" then
        return {}
    end

    local spell = type(detail) == "table" and detail.spell or nil
    local activationState = type(detail) == "table" and detail.activationState or nil
    if type(activationState) ~= "table" and type(detail) == "table" and type(detail.spellRef) == "string" and detail.spellRef ~= "" and type(Client.ResolveSpellActivationState) == "function" then
        activationState = Client:ResolveSpellActivationState(detail.spellRef, {
            includeTargetCandidates = false,
        })
    end
    local context = Conditions:BuildContext("spell", spell, {
        spellRef = type(detail) == "table" and detail.spellRef or nil,
        casterUnit = buildTooltipCasterUnit(detail),
        eventState = activationState and activationState.eventState or nil,
        targetUnit = activationState and activationState.targetUnit or nil,
    })
    return Conditions:BuildTooltipLines(spell and spell.conditions or nil, context)
end

local function buildCostLine(detail)
    local spell = type(detail) == "table" and detail.spell or nil
    local costs = type(spell) == "table" and spell.resourceCosts or nil
    if type(costs) ~= "table" or #costs == 0 then
        return nil
    end

    local spellcasting = Spellcasting or {}
    local casterUnit = buildTooltipCasterUnit(detail)
    local segments = {}
    local includePhaseSuffix = #costs > 1
    for index = 1, #costs do
        local cost = costs[index]
        if type(cost) == "table" and type(spellcasting.ResolveSpellResourceCostAmount) == "function" then
            local resolvedAmount = spellcasting.ResolveSpellResourceCostAmount(casterUnit, cost)
            local resolvedCost = {
                resourceRef = cost.resourceRef,
                castPhase = cost.castPhase,
                amountMode = "flat",
                amount = resolvedAmount,
            }
            local segment = buildCostSegment(resolvedCost, includePhaseSuffix)
            if segment then
                segments[#segments + 1] = segment
            end
        else
            local segment = buildCostSegment(cost, includePhaseSuffix)
            if segment then
                segments[#segments + 1] = segment
            end
        end
    end

    if #segments == 0 then
        return nil
    end

    return table.concat(segments, ", ")
end

local function buildChargesText(detail, runtimeState)
    local spell = type(detail) == "table" and detail.spell or nil
    local usesCooldownCharges = type(spell) == "table" and spell.useCooldownCharges == true
    local maxCharges = tonumber(runtimeState and runtimeState.maxCharges)
    if maxCharges == nil then
        if not usesCooldownCharges then
            return nil
        end
        maxCharges = tonumber(spell and spell.charges)
    end
    maxCharges = math.max(0, math.floor(maxCharges or 0))
    if maxCharges <= 1 then
        return nil
    end

    local currentCharges = tonumber(runtimeState and runtimeState.currentCharges)
    if currentCharges == nil then
        currentCharges = maxCharges
    end
    currentCharges = math.max(0, math.min(maxCharges, math.floor(currentCharges)))
    return ("Charges: %d"):format(currentCharges)
end

local function buildCastTimeText(detail)
    local spellcasting = Spellcasting or {}
    local spell = type(detail) == "table" and detail.spell or nil
    if type(spell) ~= "table" then
        return "Instant"
    end

    local castTurns = type(spellcasting.NormalizeTurnCount) == "function"
        and spellcasting.NormalizeTurnCount(spell.castTime)
        or math.max(0, math.floor(tonumber(spell.castTime) or 0))
    if castTurns and castTurns > 0 then
        return formatTurnLabel(castTurns, "cast")
    end

    return "Instant"
end

local function buildCooldownText(detail)
    local spell = type(detail) == "table" and detail.spell or nil
    local spellcasting = Spellcasting or {}
    local cooldownTurns = type(spell) == "table"
        and (type(spellcasting.NormalizeTurnCount) == "function"
            and spellcasting.NormalizeTurnCount(spell.cooldown)
            or math.max(0, math.floor(tonumber(spell.cooldown) or 0)))
        or 0
    cooldownTurns = math.max(0, math.floor(tonumber(cooldownTurns) or 0))
    if cooldownTurns <= 0 then
        return ""
    end

    return formatTurnLabel(cooldownTurns, "cooldown")
end

local function buildCooldownRemainingText(runtimeState)
    local cooldownRemaining = math.max(0, math.floor(tonumber(runtimeState and runtimeState.cooldownRemaining) or 0))
    if cooldownRemaining <= 0 then
        return nil
    end

    return ("Cooldown Remaining: %s"):format(formatTurnCount(cooldownRemaining))
end

local function isBasicAttack(spell)
    if type(spell) ~= "table" then
        return false
    end

    for index = 1, #(spell.components or {}) do
        local component = spell.components[index]
        local effect = type(component) == "table" and component.effect or nil
        if type(effect) == "table"
            and tostring(effect.type or "") == "damage"
            and string.lower(tostring(effect.hitType or "")) == "auto"
        then
            return true
        end
    end

    return false
end

local function buildInactiveTooltip(detail)
    return {
        type = "game",
        title = ensureString(detail and detail.name, detail and detail.spellRef or "Unknown Spell"),
        titleColor = { r = 0.7, g = 0.7, b = 0.7 },
        lines = {
            {
                text = "This spell definition is missing from its dataset.",
                r = 1,
                g = 0.25,
                b = 0.25,
                wrap = true,
            },
        },
    }
end

function SpellTooltip:Build(detail, owner)
    if type(detail) ~= "table" then
        return nil
    end

    if detail.isMissing == true then
        return buildInactiveTooltip(detail)
    end

    local tooltipData = buildTooltipDescription(detail, owner)
    local runtimeState = buildRuntimeActivationState(detail)
    local description = ensureString(tooltipData and tooltipData.descriptionText, "")
    local errorText = ensureString(tooltipData and tooltipData.errorText, "")
    local lines = {}
    local costLine = buildCostLine(detail)
    local chargesText = buildChargesText(detail, runtimeState)
    if (costLine and costLine ~= "") or chargesText then
        lines[#lines + 1] = {
            left = ensureString(costLine, ""),
            right = ensureString(chargesText, ""),
            r = 1,
            g = 1,
            b = 1,
            rightR = 1,
            rightG = 1,
            rightB = 1,
            wrap = false,
        }
    end

    lines[#lines + 1] = {
            left = buildCastTimeText(detail),
            right = buildCooldownText(detail),
            r = 1,
            g = 1,
            b = 1,
            rightR = 1,
            rightG = 1,
            rightB = 1,
            wrap = false,
        }

    local conditionLines = buildConditionLines(detail)
    for index = 1, #conditionLines do
        lines[#lines + 1] = conditionLines[index]
    end

    local cooldownRemainingText = buildCooldownRemainingText(runtimeState)
    if cooldownRemainingText then
        lines[#lines + 1] = {
            text = cooldownRemainingText,
            r = 1,
            g = 1,
            b = 1,
            wrap = true,
        }
    end

    if description ~= "" then
        lines[#lines + 1] = {
            text = description,
            r = 1,
            g = 0.82,
            b = 0,
            wrap = true,
        }
    elseif errorText ~= "" then
        lines[#lines + 1] = {
            text = errorText,
            r = 0.6,
            g = 0.6,
            b = 0.6,
            wrap = true,
        }
    else
        lines[#lines + 1] = {
            text = "A tooltip has not been generated for this spell.",
            r = 0.6,
            g = 0.6,
            b = 0.6,
            wrap = true,
        }
    end

    local auraSections = type(tooltipData) == "table" and tooltipData.auraSections or {}
    for index = 1, #auraSections do
        local section = auraSections[index]
        if type(section) == "table" and ensureString(section.descriptionText, "") ~= "" then
            lines[#lines + 1] = {
                text = " ",
                wrap = false,
            }
            lines[#lines + 1] = {
                text = buildAuraHeaderText(section),
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

    if isBasicAttack(detail.spell) then
        lines[#lines + 1] = {
            text = " ",
            wrap = false,
        }
        lines[#lines + 1] = {
            text = "Right-click to toggle auto-cast.",
            r = 0.6,
            g = 0.6,
            b = 0.6,
            wrap = true,
        }
    end

    local cooldownChannel = resolveCooldownChannel(detail)
    if cooldownChannel then
        lines[#lines + 1] = {
            text = "",
            wrap = false,
        }

        if type(IsShiftKeyDown) == "function" and IsShiftKeyDown() then
            local channelText = ("This spell is considered a %s."):format(cooldownChannel.name)
            if cooldownChannel.triggersGCD == true then
                channelText = channelText:gsub("%.$", "")
                    .. " and triggers the global cooldown for all other spells of this type."
            end

            lines[#lines + 1] = {
                text = ("· %s"):format(channelText),
                r = 0.6,
                g = 0.6,
                b = 0.6,
                wrap = true,
            }
            if cooldownChannel.canUseOffTurn == true then
                lines[#lines + 1] = {
                    text = "· This spell can be used when it is not your turn.",
                    r = 0.6,
                    g = 0.6,
                    b = 0.6,
                    wrap = true,
                }
            end

            local scalingStatNames = getSpellScalingStatNames(detail.spell)
            for index = 1, #scalingStatNames do
                lines[#lines + 1] = {
                    text = ("· This spell scales with %s."):format(scalingStatNames[index]),
                    r = 0.6,
                    g = 0.6,
                    b = 0.6,
                    wrap = true,
                }
            end
        else
            lines[#lines + 1] = {
                text = "<Hold shift to expand>",
                r = 0.6,
                g = 0.6,
                b = 0.6,
                wrap = true,
            }
        end
    end

    return {
        type = "game",
        rpeTooltipKind = "spell",
        title = ensureString(detail.name, "Unknown Spell"),
        titleColor = { r = 1, g = 1, b = 1 },
        lines = lines,
    }
end

return SpellTooltip
