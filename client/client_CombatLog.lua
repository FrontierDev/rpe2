local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Internal = Addon.Internal or {}
Addon.Utils = Addon.Utils or {}
Addon.UI = Addon.UI or {}

local Client = Addon.Client
local Comms = Addon.Internal.Comms or {}
local Operations = Comms.Operations or {}
local Common = Addon.Utils.Common or {}
local ResourceSync = Comms.ResourceSync or {}
local Profile = Addon.Internal.Profile or {}
local Database = Addon.Internal.Database or {}
local Dependencies = Database.Dependecies or {}
local Registry = Addon.Internal.Registry or {}
local EventClass = Database.Classes and Database.Classes.Event or nil

local COMBAT_LOG_OPCODE = Operations.GetOpcode and Operations:GetOpcode("COMBAT_LOG") or nil
local DEFAULT_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"
local encodeColorHex

local function getTasks()
    return Addon.Internal and Addon.Internal.Tasks or nil
end

local function normalizeEntryType(value)
    local entryType = string.lower(tostring(value or ""))
    if entryType ~= "damage" and entryType ~= "heal" and entryType ~= "status" then
        return nil
    end

    return entryType
end

local COMBAT_LOG_KINDS = {
    spellcast_start = true,
    aura_gain = true,
    aura_loss = true,
    interrupt = true,
}

local function normalizeLogKind(value)
    local kind = tostring(value or "")
    return COMBAT_LOG_KINDS[kind] == true and kind or nil
end

local function normalizePositiveInteger(value)
    local number = math.floor(tonumber(value) or 0)
    if number <= 0 then
        return nil
    end

    return number
end

local function normalizeNonNegativeInteger(value)
    local number = math.floor(tonumber(value) or 0)
    if number < 0 then
        return nil
    end

    return number
end

local function normalizeTargetCount(value)
    return math.max(1, math.floor(tonumber(value) or 1))
end

local function normalizeColorHex(value)
    if type(value) == "table" then
        return encodeColorHex(value)
    end

    local normalized = tostring(value or "")
    normalized = normalized:gsub("^|c", ""):gsub("|r", ""):gsub("#", "")
    normalized = normalized:gsub("[^0-9a-fA-F]", "")
    if #normalized == 6 then
        normalized = "ff" .. normalized
    end
    if #normalized ~= 8 then
        return nil
    end

    return string.lower(normalized)
end

encodeColorHex = function(color)
    if type(color) ~= "table" then
        return nil
    end

    local function toByte(value, fallback)
        local number = tonumber(value)
        if number == nil then
            number = fallback
        end
        if number <= 1 then
            number = number * 255
        end
        number = math.max(0, math.min(255, math.floor(number + 0.5)))
        return number
    end

    return ("%02x%02x%02x%02x"):format(
        toByte(color.a, 1),
        toByte(color.r, 1),
        toByte(color.g, 1),
        toByte(color.b, 1)
    )
end

local function wrapTextWithColor(text, colorHex)
    local normalized = normalizeColorHex(colorHex)
    if normalized == nil or tostring(text or "") == "" then
        return tostring(text or "")
    end

    return ("|c%s%s|r"):format(normalized, tostring(text))
end

local function resolveSendMetadata(opcode)
    local spellcasting = Client.Spellcasting or nil
    if type(spellcasting) == "table" and type(spellcasting.BuildSendMetadata) == "function" then
        return spellcasting.BuildSendMetadata(opcode)
    end

    return {
        opcode = opcode,
        scope = "client",
    }
end

local function buildTargetDisplayName(targetDisplayName, targetCount)
    if targetCount > 1 then
        return ("%d targets"):format(targetCount)
    end

    local normalized = tostring(targetDisplayName or "")
    if normalized == "" then
        return "Unknown"
    end

    return normalized
end

local function buildTextureMarkup(texture, width, height, fallbackText)
    local normalized = tostring(texture or "")
    if normalized == "" then
        return fallbackText or ""
    end

    local inline = Addon.UI and Addon.UI.Inline or nil
    if type(inline) == "table" and type(inline.Build) == "function" then
        local markup = inline:Build({
            texture = normalized,
            coords = {
                left = 0,
                right = 1,
                top = 0,
                bottom = 1,
            },
        }, width, height)
        if type(markup) == "string" and markup ~= "" then
            return markup
        end
    end

    return ("|T%s:%d:%d:0:0|t"):format(normalized, width, height)
end

local function buildIconMarkup(texture)
    local normalized = tostring(texture or "")
    if normalized == "" then
        normalized = DEFAULT_ICON
    end

    return buildTextureMarkup(normalized, 14, 14, "")
end

local function resolveSpellIconTexture(spell, spellRef)
    if type(spell) == "table" and tostring(spell.icon or "") ~= "" then
        return tostring(spell.icon)
    end

    if type(spellRef) == "string" and spellRef ~= "" and type(Registry.ResolveSpellReference) == "function" then
        local _, resolvedSpell = Registry:ResolveSpellReference(spellRef)
        if type(resolvedSpell) == "table" and tostring(resolvedSpell.icon or "") ~= "" then
            return tostring(resolvedSpell.icon)
        end
    end

    return DEFAULT_ICON
end

local function resolveEventUnitByDisplayName(eventState, displayName)
    local normalizedName = type(Common.NormalizeName) == "function"
        and Common.NormalizeName(displayName)
        or tostring(displayName or "")
    if normalizedName == "" then
        return nil
    end

    for index = 1, #((eventState and eventState.units) or {}) do
        local eventUnit = eventState.units[index]
        local candidateName = type(Common.NormalizeName) == "function"
            and Common.NormalizeName(eventUnit and eventUnit.name)
            or tostring(eventUnit and eventUnit.name or "")
        if candidateName == normalizedName then
            return eventUnit
        end
    end

    return nil
end

local function resolveTeamColorHex(eventState, displayName)
    local eventUnit = resolveEventUnitByDisplayName(eventState, displayName)
    local color = EventClass and EventClass.GetTeamColor and EventClass.GetTeamColor(eventState, tonumber(eventUnit and eventUnit.team) or 0) or nil
    return encodeColorHex(color)
end

local function resolveDatasetResource(resourceRef)
    if type(resourceRef) ~= "string" or resourceRef == ""
        or type(Dependencies.ParseSourceStatRef) ~= "function"
        or type(Database.GetDatasetByID) ~= "function"
    then
        return nil
    end

    local datasetId, resourceId = Dependencies.ParseSourceStatRef(resourceRef)
    local dataset = datasetId and Database.GetDatasetByID(datasetId) or nil
    for index = 1, #((dataset and dataset.resources) or {}) do
        local candidate = dataset.resources[index]
        if tostring(candidate and candidate.id or "") == tostring(resourceId or "") then
            return candidate
        end
    end

    return nil
end

local DAMAGE_SCHOOL_COLOR_FALLBACKS = {
    physical = { token = "text.secondary" },
    ["true"] = { color = { r = 0.92, g = 0.94, b = 0.98, a = 1 } },
    fire = { color = { r = 0.9, g = 0.62, b = 0.4, a = 1 } },
    frost = { color = { r = 0.62, g = 0.78, b = 0.96, a = 1 } },
    shadow = { color = { r = 0.74, g = 0.66, b = 0.92, a = 1 } },
    arcane = { color = { r = 0.7, g = 0.74, b = 0.98, a = 1 } },
    nature = { color = { r = 0.52, g = 0.84, b = 0.58, a = 1 } },
    holy = { color = { r = 0.96, g = 0.88, b = 0.62, a = 1 } },
    lightning = { color = { r = 0.9, g = 0.82, b = 0.52, a = 1 } },
    storm = { color = { r = 0.9, g = 0.82, b = 0.52, a = 1 } },
    poison = { color = { r = 0.56, g = 0.78, b = 0.44, a = 1 } },
    disease = { color = { r = 0.7, g = 0.76, b = 0.5, a = 1 } },
    bleed = { color = { r = 0.86, g = 0.5, b = 0.46, a = 1 } },
}

local function resolveCombatLogPaletteColor(entry)
    if type(entry) ~= "table" then
        return nil
    end

    if type(entry.color) == "table" then
        return entry.color
    end
    if type(entry.token) == "string" and entry.token ~= "" and Addon.UI and type(Addon.UI.ResolveColor) == "function" then
        return Addon.UI.ResolveColor(nil, entry.token)
    end

    return nil
end

local function findDatasetDamageSchool(schoolRef)
    if type(schoolRef) ~= "string" or schoolRef == ""
        or type(Dependencies.ParseSourceStatRef) ~= "function"
        or type(Database.GetDatasetByID) ~= "function"
    then
        return nil
    end

    local datasetId, damageSchoolId = Dependencies.ParseSourceStatRef(schoolRef)
    local dataset = datasetId and Database.GetDatasetByID(datasetId) or nil
    for index = 1, #((dataset and dataset.damageSchools) or {}) do
        local candidate = dataset.damageSchools[index]
        if tostring(candidate and candidate.id or "") == tostring(damageSchoolId or "") then
            return candidate
        end
    end

    return nil
end

local function tokenizeDamageSchoolTerms(...)
    local tokens = {}
    local seen = {}
    for valueIndex = 1, select("#", ...) do
        local value = tostring(select(valueIndex, ...) or ""):lower()
        for token in string.gmatch(value, "[%a]+") do
            if token ~= "" and not seen[token] then
                seen[token] = true
                tokens[#tokens + 1] = token
            end
        end
    end

    return tokens
end

function Client:GetCombatLogFallbackIcon()
    return DEFAULT_ICON
end

function Client:ResolveCombatLogResourcePresentation(resourceRef)
    local label = type(ResourceSync.ResolveResourceName) == "function"
        and tostring(ResourceSync.ResolveResourceName(resourceRef) or "")
        or tostring(resourceRef or "")
    local icon = nil
    local color = nil

    local row = type(Profile.GetResolvedResourceRow) == "function" and Profile.GetResolvedResourceRow(resourceRef) or nil
    if type(row) == "table" then
        label = tostring(row.name or label or "")
        if tostring(row.icon or "") ~= "" then
            icon = tostring(row.icon)
        end
        color = encodeColorHex(row.color)
    end

    if not icon then
        local resource = resolveDatasetResource(resourceRef)
        if type(resource) == "table" and tostring(resource.icon or "") ~= "" then
            icon = tostring(resource.icon)
        end
        if type(resource) == "table" and tostring(resource.name or "") ~= "" then
            label = tostring(resource.name)
        end
    end

    if label == "" then
        label = "Resource"
    end

    return icon or DEFAULT_ICON, label, color
end

function Client:ResolveCombatLogDamageSchoolPresentation(schoolRef, schoolName, schoolIcon)
    local resolvedName = tostring(schoolName or "")
    local resolvedIcon = tostring(schoolIcon or "")
    local resolvedColor = nil

    local school = findDatasetDamageSchool(schoolRef)
    if type(school) == "table" then
        if resolvedName == "" and tostring(school.name or "") ~= "" then
            resolvedName = tostring(school.name)
        end
        if resolvedIcon == "" and tostring(school.icon or "") ~= "" then
            resolvedIcon = tostring(school.icon)
        end
        resolvedColor = encodeColorHex(school.color)
    end

    local schoolTokens = tokenizeDamageSchoolTerms(
        schoolRef,
        resolvedName,
        type(school) == "table" and school.id or nil
    )
    if resolvedColor == nil then
        for index = 1, #schoolTokens do
            local fallback = DAMAGE_SCHOOL_COLOR_FALLBACKS[schoolTokens[index]]
            local color = resolveCombatLogPaletteColor(fallback)
            if type(color) == "table" then
                resolvedColor = encodeColorHex(color)
                if resolvedColor ~= nil then
                    break
                end
            end
        end
    end

    if resolvedColor == nil then
        resolvedColor = encodeColorHex(Addon.UI and type(Addon.UI.ResolveColor) == "function" and Addon.UI.ResolveColor(nil, "accent") or nil)
    end

    if resolvedName == "" then
        resolvedName = "True"
    end
    if resolvedIcon == "" then
        resolvedIcon = DEFAULT_ICON
    end

    return resolvedIcon, resolvedName, resolvedColor
end

function Client:ResolveCombatLogSpellIcon(spell, spellRef)
    return resolveSpellIconTexture(spell, spellRef)
end

function Client:ResolveCombatLogTeamColors(entry, eventState)
    local state = type(eventState) == "table" and eventState or self.GetEventState and self:GetEventState() or self.EventState
    if type(state) ~= "table" or state.active ~= true then
        return nil, nil
    end

    return resolveTeamColorHex(state, entry and entry.casterDisplayName), resolveTeamColorHex(state, entry and entry.targetDisplayName)
end

function Client:NormalizeCombatLogEntry(entry)
    if type(entry) ~= "table" then
        return nil
    end

    local eventId = tostring(entry.eventId or "")
    local entryType = normalizeEntryType(entry.entryType)
    local targetCount = normalizeTargetCount(entry.targetCount)
    local amountMin = nil
    local amountMax = nil
    if entryType == "damage" or entryType == "heal" then
        amountMin = normalizeNonNegativeInteger(entry.amountMin)
        amountMax = normalizeNonNegativeInteger(entry.amountMax)
    else
        amountMin = normalizePositiveInteger(entry.amountMin)
        amountMax = normalizePositiveInteger(entry.amountMax)
    end
    local casterDisplayName = tostring(entry.casterDisplayName or "")
    local labelText = tostring(entry.labelText or "")
    local detailText = tostring(entry.detailText or "")
    local spellIconTexture = tostring(entry.spellIconTexture or "")
    local logKind = normalizeLogKind(entry.logKind)
    local spellRef = tostring(entry.spellRef or "")
    if entryType == "status" then
        if detailText == "" then
            detailText = labelText
        end
        if eventId == ""
            or casterDisplayName == ""
            or detailText == ""
        then
            return nil
        end
    elseif eventId == ""
        or entryType == nil
        or casterDisplayName == ""
        or amountMin == nil
        or amountMax == nil
        or labelText == ""
    then
        return nil
    end

    if amountMin ~= nil and amountMax ~= nil and amountMax < amountMin then
        amountMin, amountMax = amountMax, amountMin
    end

    return {
        eventId = eventId,
        entryType = entryType,
        casterDisplayName = casterDisplayName,
        targetDisplayName = buildTargetDisplayName(entry.targetDisplayName, targetCount),
        targetCount = targetCount,
        amountMin = amountMin,
        amountMax = amountMax,
        iconTexture = tostring(entry.iconTexture or "") ~= "" and tostring(entry.iconTexture) or DEFAULT_ICON,
        spellIconTexture = spellIconTexture ~= "" and spellIconTexture or DEFAULT_ICON,
        labelText = labelText,
        detailText = detailText,
        logKind = logKind,
        spellRef = spellRef ~= "" and spellRef or nil,
        accentColor = normalizeColorHex(entry.accentColor),
        casterColor = normalizeColorHex(entry.casterColor),
        targetColor = normalizeColorHex(entry.targetColor),
    }
end

function Client:BuildCombatLogEntry(entry)
    return self:NormalizeCombatLogEntry(entry)
end

function Client:BuildCombatLogArguments(entry)
    local normalized = self:NormalizeCombatLogEntry(entry)
    if not normalized then
        return nil
    end

    return {
        normalized.eventId,
        normalized.entryType,
        normalized.casterDisplayName,
        normalized.targetDisplayName,
        normalized.targetCount,
        normalized.amountMin ~= nil and normalized.amountMin or 1,
        normalized.amountMax ~= nil and normalized.amountMax or (normalized.amountMin ~= nil and normalized.amountMin or 1),
        normalized.iconTexture,
        normalized.labelText ~= "" and normalized.labelText or normalized.detailText,
        normalized.spellIconTexture,
        normalized.accentColor or "",
        normalized.casterColor or "",
        normalized.targetColor or "",
        normalized.detailText ~= "" and normalized.detailText or "",
        "",
        normalized.logKind or "",
        normalized.spellRef or "",
    }
end

function Client:BuildCombatLogDisplayText(entry)
    local normalized = self:NormalizeCombatLogEntry(entry)
    if not normalized then
        return ""
    end

    local detailText = tostring(normalized.detailText or "")
    if detailText == "" then
        local amountText = nil
        if normalized.amountMin == normalized.amountMax then
            amountText = tostring(normalized.amountMin)
        else
            amountText = ("%d-%d"):format(normalized.amountMin, normalized.amountMax)
        end
        if normalized.entryType == "heal" then
            amountText = "+" .. amountText
        end
        detailText = ("%s %s"):format(amountText, normalized.labelText)
    end

    local casterText = wrapTextWithColor(normalized.casterDisplayName, normalized.casterColor)
    local targetText = wrapTextWithColor(normalized.targetDisplayName, normalized.targetColor)
    if string.find(detailText, "|c", 1, true) == nil then
        detailText = wrapTextWithColor(detailText, normalized.accentColor)
    end

    if normalized.logKind == "spellcast_start" then
        return ("%s begins casting %s %s"):format(
            casterText,
            buildIconMarkup(normalized.spellIconTexture),
            wrapTextWithColor(normalized.labelText, normalized.accentColor)
        )
    end

    return ("%s %s %s    %s"):format(
        casterText,
        buildIconMarkup(normalized.spellIconTexture),
        targetText,
        detailText
    )
end

function Client:QueueCombatLogEntry(entry)
    local normalized = self:NormalizeCombatLogEntry(entry)
    if not normalized then
        return false
    end

    local widgetNamespace = self.UI and self.UI.EventWidget or nil
    local widget = widgetNamespace and widgetNamespace.Get and widgetNamespace:Get() or nil
    if type(widget) ~= "table" or type(widget.QueueCombatLogEntry) ~= "function" then
        return false
    end

    return widget:QueueCombatLogEntry(normalized)
end

function Client:QueueCombatLogEntryEmission(entry)
    local normalized = self:NormalizeCombatLogEntry(entry)
    if not normalized then
        return false
    end

    local tasks = getTasks()
    if tasks and type(tasks.Enqueue) == "function" then
        tasks:Enqueue(function(targetClient, queuedEntry)
            if type(targetClient) ~= "table" or type(targetClient.EmitCombatLogEntry) ~= "function" then
                return
            end

            targetClient:EmitCombatLogEntry(queuedEntry)
        end, self, normalized)
        return true
    end

    return self:EmitCombatLogEntry(normalized)
end

function Client:ClearEventWidgetCombatLog(reason)
    local widgetNamespace = self.UI and self.UI.EventWidget or nil
    local widget = widgetNamespace and widgetNamespace.Get and widgetNamespace:Get() or nil
    if type(widget) ~= "table" or type(widget.ClearCombatLogTicker) ~= "function" then
        return false
    end

    return widget:ClearCombatLogTicker(reason)
end

function Client:HandleCombatLog(arguments, sender, distribution, target, message)
    local eventState = self.GetEventState and self:GetEventState() or self.EventState
    if type(eventState) ~= "table" or eventState.active ~= true then
        return false
    end

    local localPlayerName = Common.NormalizeName and Common.NormalizeName(Common.GetPlayerName and Common.GetPlayerName() or "")
        or tostring(Common.GetPlayerName and Common.GetPlayerName() or "")
    local normalizedSender = Common.NormalizeName and Common.NormalizeName(sender) or tostring(sender or "")
    if (distribution == "PARTY" or distribution == "RAID")
        and localPlayerName ~= ""
        and normalizedSender == localPlayerName
    then
        -- EmitCombatLogEntry already queues the host-local ticker entry before broadcasting.
        -- Ignore the transport's physical self-copy so the ticker/history only receive it once.
        return true
    end

    local entryType = normalizeEntryType(arguments and arguments[2])
    local normalized = self:NormalizeCombatLogEntry({
        eventId = arguments and arguments[1],
        entryType = entryType,
        casterDisplayName = arguments and arguments[3],
        targetDisplayName = arguments and arguments[4],
        targetCount = arguments and arguments[5],
        amountMin = arguments and arguments[6],
        amountMax = arguments and arguments[7],
        iconTexture = arguments and arguments[8],
        labelText = arguments and arguments[9],
        spellIconTexture = arguments and arguments[10],
        accentColor = arguments and arguments[11],
        casterColor = arguments and arguments[12],
        targetColor = arguments and arguments[13],
        detailText = arguments and arguments[14],
        logKind = normalizeLogKind(arguments and arguments[16]),
        spellRef = arguments and (normalizeLogKind(arguments and arguments[16]) and arguments[17] or ""),
        -- Argument 15 is the turn number for turn-tagged payloads. Payloads
        -- without a semantic kind may still contain the legacy turn there.
        turnNumber = arguments and (
            arguments[15]
        ),
    })
    if not normalized or normalized.eventId ~= tostring(eventState.id or "") then
        return false
    end

    return self:QueueCombatLogEntry(normalized)
end

function Client:EmitCombatLogEntry(entry)
    local normalized = self:NormalizeCombatLogEntry(entry)
    if not normalized then
        return false
    end

    local eventState = self.GetEventState and self:GetEventState() or self.EventState
    if type(eventState) ~= "table" or eventState.active ~= true or tostring(eventState.id or "") ~= normalized.eventId then
        return false
    end

    local arguments = self:BuildCombatLogArguments(normalized)
    if not arguments then
        return false
    end

    local casterColor, targetColor = self:ResolveCombatLogTeamColors(normalized, eventState)
    arguments[11] = normalized.accentColor or arguments[11] or ""
    arguments[12] = normalized.casterColor or casterColor or ""
    arguments[13] = normalized.targetColor or targetColor or ""

    local localHandled = self:HandleCombatLog(arguments, Common.GetPlayerName and Common.GetPlayerName() or nil, "LOCAL")

    local distribution = Common.GetGroupType and Common.GetGroupType() or nil
    if (distribution ~= "PARTY" and distribution ~= "RAID")
        or type(Comms.SendMessage) ~= "function"
        or not COMBAT_LOG_OPCODE
    then
        return localHandled == true
    end

    Comms:SendMessage(distribution, COMBAT_LOG_OPCODE, arguments, nil, resolveSendMetadata(COMBAT_LOG_OPCODE))
    return true
end

return true
