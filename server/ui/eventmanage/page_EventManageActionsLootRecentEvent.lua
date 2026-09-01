local _, Addon = ...

Addon.Server = Addon.Server or {}
Addon.Server.UI = Addon.Server.UI or {}

local Server = Addon.Server
local EventManage = Addon.Server.UI.EventManage
local Loot = Server.Loot or {}

if type(EventManage) ~= "table" or EventManage._actionsLootRecentEventInstalled == true then
    return
end

local function trim(value)
    return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function normalizeToken(value)
    return string.lower(trim(value))
end

local function deepCopy(value, seen)
    if type(value) ~= "table" then
        return value
    end
    seen = seen or {}
    if seen[value] then
        return seen[value]
    end
    local copy = {}
    seen[value] = copy
    for key, child in pairs(value) do
        copy[key] = deepCopy(child, seen)
    end
    return copy
end

local function pack(...)
    return { n = select("#", ...), ... }
end

local function setEnabled(control, enabled)
    if control and type(control.SetEnabled) == "function" then
        control:SetEnabled(enabled == true)
    end
end

local function resolveLootContext()
    if type(Loot.GetEventManagerLootContext) ~= "function" then
        return nil, "loot-coordinator-unavailable"
    end
    return Loot:GetEventManagerLootContext()
end

local function contextLabel(context)
    local label = trim(context and context.eventName)
    if label == "" then
        label = trim(context and context.eventSessionId)
    end
    return label ~= "" and label or "Previous Event"
end

local function refreshRecentContextIndicator(self, context)
    local text = self.ActionsLootDiagnosticText
    if not text or type(text.SetText) ~= "function" then
        return
    end
    if type(context) ~= "table" or context.mode ~= "recent" then
        return
    end

    local prefix = "Loot — Last Event: " .. contextLabel(context)
    local current = type(text.GetText) == "function" and trim(text:GetText()) or ""
    if current == "" then
        text:SetText(prefix)
    elseif not current:find(prefix, 1, true) then
        text:SetText(prefix .. " — " .. current)
    end
end

function Server:GetEventManagerLootEligiblePlayers()
    local context, reason, detail = resolveLootContext()
    if type(context) ~= "table" then
        return nil, reason, detail
    end
    if #(context.players or {}) == 0 then
        return nil, "empty-eligibility", {}
    end
    return deepCopy(context.players), nil, deepCopy(context)
end

function Server:ExecuteEventManagerLootGrant(grant, selectedPlayers)
    local context, reason, detail = resolveLootContext()
    if type(context) ~= "table" then
        return nil, reason, detail
    end
    if type(Loot.ValidateEligiblePlayers) ~= "function"
        or type(Loot.GenerateGrantId) ~= "function"
        or type(Loot.ExecuteGrant) ~= "function"
    then
        return nil, "loot-coordinator-unavailable"
    end

    local players = nil
    players, reason, detail = Loot:ValidateEligiblePlayers(context.eventState, selectedPlayers)
    if not players then
        return nil, reason, detail
    end

    local grantId = nil
    grantId, reason = Loot:GenerateGrantId(context.eventSessionId, "event-manager")
    if not grantId then
        return nil, reason or "loot-grant-id-unavailable"
    end

    local summary = nil
    summary, reason, detail = Loot:ExecuteGrant(grant, players, {
        eventSessionId = context.eventSessionId,
        grantId = grantId,
        hostName = context.hostName,
        source = "event-manager",
    })
    if type(summary) ~= "table" then
        return nil, reason, detail
    end
    return summary, nil, nil, grantId
end

local baseRefreshActionLootSection = EventManage.RefreshActionLootSection
if type(baseRefreshActionLootSection) == "function" then
    function EventManage:RefreshActionLootSection(...)
        local previousPlayers = deepCopy(self.ActionsLootSelectedPlayers or {})
        local previousSessionId = tostring(self.ActionsLootSelectionEventId or "")
        local results = pack(baseRefreshActionLootSection(self, ...))

        local context = resolveLootContext()
        if type(context) ~= "table" or context.mode ~= "recent" then
            return unpack(results, 1, results.n)
        end

        local eligiblePlayers = deepCopy(context.players or {})
        if previousSessionId == tostring(context.eventSessionId or "") then
            self.ActionsLootSelectedPlayers = previousPlayers
            self.ActionsLootSelectionEventId = tostring(context.eventSessionId or "")
        else
            self:ReconcileActionLootPlayers(eligiblePlayers, context.eventSessionId)
        end

        local targetItems = self:BuildActionLootTargetItems(eligiblePlayers)
        if self.ActionsLootTargetsDropdown and type(self.ActionsLootTargetsDropdown.SetItems) == "function" then
            self.ActionsLootTargetsDropdown:SetItems(targetItems)
        end
        if self.ActionsLootTargetsDropdown and type(self.ActionsLootTargetsDropdown.SetSelectedValues) == "function" then
            self.ActionsLootTargetsDropdown:SetSelectedValues(self.ActionsLootSelectedPlayers or {}, true)
        end

        self.ActionsLootQuantity = trim(
            self.ActionsLootQuantityInput and self.ActionsLootQuantityInput:GetText()
                or self.ActionsLootQuantity
                or "1"
        )
        local grant, validationReason = self:ValidateActionLootControls(eligiblePlayers)
        local valid = type(grant) == "table"
        local sourceType = normalizeToken(self.ActionsLootSourceType or "direct")
        local rewardType = normalizeToken(self.ActionsLootRewardType or "item")
        local needsDataset = sourceType == "loot_table" or (sourceType == "direct" and rewardType == "item")

        setEnabled(self.ActionsLootSourceDropdown, true)
        setEnabled(self.ActionsLootDistributionDropdown, true)
        setEnabled(self.ActionsLootRewardTypeDropdown, sourceType == "direct")
        setEnabled(self.ActionsLootQuantityInput, sourceType == "direct")
        setEnabled(self.ActionsLootDatasetDropdown, needsDataset)
        setEnabled(self.ActionsLootRefDropdown, true)
        setEnabled(self.ActionsLootTargetsDropdown, #eligiblePlayers > 0)
        setEnabled(self.ActionsLootDistributeButton, valid and self.ActionsLootClickInFlight ~= true)

        self.ActionsLootValidationReason = validationReason
        self:RefreshActionLootResult()
        refreshRecentContextIndicator(self, context)
        return unpack(results, 1, results.n)
    end
end

EventManage._actionsLootRecentEventInstalled = true
return true
