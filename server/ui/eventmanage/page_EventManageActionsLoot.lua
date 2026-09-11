local _, Addon = ...

Addon.Server = Addon.Server or {}
Addon.Server.UI = Addon.Server.UI or {}
Addon.Client = Addon.Client or {}
Addon.Internal = Addon.Internal or {}
Addon.Utils = Addon.Utils or {}

local Server = Addon.Server
local Client = Addon.Client
local EventManage = Addon.Server.UI.EventManage
local Registry = Addon.Internal.Registry or {}
local Profile = Addon.Internal.Profile or {}
local Common = Addon.Utils.Common or {}
local UI = Addon.UI or {}
local C = UI.Constants or {}
local Loot = Server.Loot or {}

if type(EventManage) ~= "table" or EventManage._actionsLootInstalled == true then
    return
end

local CONTENT_WIDTH = 480
local CONTROL_HEIGHT = 20
local DROPDOWN_HEIGHT = 18
local COMPACT_ROOT_SPACING = 2

local SOURCE_ITEMS = {
    { label = "Direct Loot", value = "direct" },
    { label = "Loot Table", value = "loot_table" },
}
local DISTRIBUTION_ITEMS = {
    {
        label = "Personal",
        value = "personal",
        tooltip = "Each selected player receives or resolves loot independently.",
    },
    {
        label = "Group",
        value = "group",
        tooltip = "Each resolved reward can be assigned to only one selected player.",
    },
}
local REWARD_TYPE_ITEMS = {
    { label = "Item", value = "item" },
    { label = "Currency", value = "currency" },
}

local FRIENDLY_REASONS = {
    ["server-inactive"] = "The RPE server is not active.",
    ["event-inactive"] = "The Event is no longer active.",
    ["event-not-ready"] = "The Event roster is not ready.",
    ["client-inactive"] = "The local Event client is not active.",
    ["event-state-mismatch"] = "The Event state changed. Refresh and try again.",
    ["not-host"] = "You are no longer the Event host.",
    ["event-action-blocked"] = "Event actions are currently blocked.",
    ["empty-eligibility"] = "No eligible players are selected.",
    ["ineligible-player"] = "A selected player is no longer participating in the Event.",
    ["invalid-amount"] = "Quantity must be a positive whole number.",
    ["invalid-item"] = "The selected Item is unavailable.",
    ["unknown-item"] = "The selected Item is unavailable.",
    ["invalid-currency"] = "The selected Currency is unavailable.",
    ["unknown-currency"] = "The selected Currency is unavailable.",
    ["invalid-loot-table"] = "The selected Loot Table is unavailable.",
    ["unknown-loot-table"] = "The selected Loot Table is unavailable.",
    ["no-loot-entries"] = "The Loot Table contains no entries.",
    ["invalid-loot-table-entry"] = "The Loot Table contains an invalid entry.",
    ["invalid-entry"] = "The Loot Table contains an invalid entry.",
    ["invalid-weight"] = "The Loot Table contains an invalid weight.",
    ["invalid-quantity-range"] = "The Loot Table contains an invalid quantity range.",
    ["unsupported-source"] = "The Loot source is invalid.",
    ["unsupported-distribution"] = "The Loot distribution mode is invalid.",
    ["loot-coordinator-unavailable"] = "The Loot coordinator is unavailable.",
    ["loot-grant-id-unavailable"] = "A Loot grant ID could not be created.",
    ["send-failed"] = "The delivery could not be sent.",
    ["unknown-delivery"] = "The selected delivery is no longer retained.",
}

local function trim(value)
    return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function normalizeToken(value)
    return string.lower(trim(value))
end

local function normalizeName(value)
    local text = trim(value)
    if text == "" then
        return ""
    end
    if type(Common.NormalizeName) == "function" then
        return trim(Common.NormalizeName(text))
    end
    return text
end

local function positiveInteger(value)
    local numeric = tonumber(value)
    if numeric == nil
        or numeric ~= numeric
        or numeric == math.huge
        or numeric == -math.huge
        or numeric < 1
        or numeric ~= math.floor(numeric)
    then
        return nil
    end
    return math.floor(numeric)
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

local function friendlyReason(reason)
    local key = tostring(reason or "unknown")
    return FRIENDLY_REASONS[key] or key
end

local function setEnabled(control, enabled)
    if control and type(control.SetEnabled) == "function" then
        control:SetEnabled(enabled == true)
    end
end

local function hasDropdownValue(items, value)
    local wanted = tostring(value or "")
    for index = 1, #(items or {}) do
        if tostring(items[index] and items[index].value or "") == wanted then
            return true
        end
    end
    return false
end

local function syncDropdown(dropdown, items, value, fallback)
    local selected = tostring(value or "")
    if not hasDropdownValue(items, selected) then
        selected = tostring(fallback or "")
    end
    if dropdown and type(dropdown.SetItems) == "function" then
        dropdown:SetItems(items)
    end
    if dropdown and type(dropdown.SetSelectedValue) == "function" then
        dropdown:SetSelectedValue(selected, true)
    end
    return selected
end

local function getActivatedDatasets()
    return type(Registry.GetActivatedDatasets) == "function" and Registry:GetActivatedDatasets() or {}
end

local function findActivatedDataset(datasetId)
    local wanted = trim(datasetId)
    if wanted == "" then
        return nil
    end
    local datasets = getActivatedDatasets()
    for index = 1, #datasets do
        local dataset = datasets[index]
        if type(dataset) == "table" and tostring(dataset.id or "") == wanted then
            return dataset
        end
    end
    return nil
end

local function parseDatasetQualifiedRef(value)
    local text = trim(value)
    local separator = string.find(text, ":", 1, true)
    if not separator then
        return "", ""
    end
    return string.sub(text, 1, separator - 1), string.sub(text, separator + 1)
end

local function findActivatedEntry(ref, collectionKey)
    local datasetId, entryId = parseDatasetQualifiedRef(ref)
    if datasetId == "" or entryId == "" then
        return nil, nil
    end
    local dataset = findActivatedDataset(datasetId)
    for index = 1, #(dataset and dataset[collectionKey] or {}) do
        local entry = dataset[collectionKey][index]
        if type(entry) == "table" and tostring(entry.id or "") == entryId then
            return dataset, entry
        end
    end
    return dataset, nil
end

local function buildDatasetItems(collectionKey)
    local rows = {}
    local datasets = getActivatedDatasets()
    for index = 1, #datasets do
        local dataset = datasets[index]
        if type(dataset) == "table" and type(dataset[collectionKey]) == "table" and #dataset[collectionKey] > 0 then
            rows[#rows + 1] = {
                label = trim(dataset.name) ~= "" and trim(dataset.name) or tostring(dataset.id or ""),
                value = tostring(dataset.id or ""),
            }
        end
    end
    table.sort(rows, function(left, right)
        return string.lower(tostring(left.label or "")) < string.lower(tostring(right.label or ""))
    end)
    local items = { { label = "Dataset", value = "" } }
    for index = 1, #rows do
        items[#items + 1] = rows[index]
    end
    return items
end

local function buildEntryItems(datasetId, collectionKey, emptyLabel)
    local dataset = findActivatedDataset(datasetId)
    local rows = {}
    for index = 1, #(dataset and dataset[collectionKey] or {}) do
        local entry = dataset[collectionKey][index]
        if type(entry) == "table" and trim(entry.id) ~= "" then
            rows[#rows + 1] = {
                label = trim(entry.name) ~= "" and trim(entry.name) or tostring(entry.id),
                value = ("%s:%s"):format(tostring(dataset.id), tostring(entry.id)),
                icon = entry.icon,
            }
        end
    end
    table.sort(rows, function(left, right)
        return string.lower(tostring(left.label or "")) < string.lower(tostring(right.label or ""))
    end)
    local items = { { label = emptyLabel or "Select", value = "" } }
    for index = 1, #rows do
        items[#items + 1] = rows[index]
    end
    return items
end

local function buildCurrencyItems()
    local items = { { label = "Currency", value = "" } }
    local definitions = type(Profile.ListCurrencyDefinitions) == "function" and Profile.ListCurrencyDefinitions({
        includeBuiltins = true,
        includeCustom = true,
        includeInactive = false,
        includeMissingBalances = false,
    }) or {}
    local rows = {}
    for index = 1, #definitions do
        local definition = definitions[index]
        local available = type(definition) == "table"
            and definition.isMissing ~= true
            and (definition.builtin == true or definition.isActive == true)
        local ref = available and trim(definition.key or definition.ref or definition.id) or ""
        if ref ~= "" then
            local label = trim(definition.name) ~= "" and trim(definition.name) or ref
            if definition.builtin ~= true and trim(definition.datasetName) ~= "" then
                label = trim(definition.datasetName) .. " — " .. label
            end
            rows[#rows + 1] = { label = label, value = ref }
        end
    end
    table.sort(rows, function(left, right)
        return string.lower(tostring(left.label or "")) < string.lower(tostring(right.label or ""))
    end)
    for index = 1, #rows do
        items[#items + 1] = rows[index]
    end
    return items
end

local function resolveActiveCurrency(ref)
    if type(Profile.ResolveCurrencyDefinition) ~= "function" then
        return nil
    end
    local ok, definition = pcall(Profile.ResolveCurrencyDefinition, ref)
    if not ok or type(definition) ~= "table" or definition.isMissing == true then
        return nil
    end
    if definition.builtin ~= true and definition.isActive ~= true then
        return nil
    end
    return definition
end

local function resolveActiveItem(ref)
    local dataset, item = findActivatedEntry(ref, "items")
    if type(dataset) ~= "table" or type(item) ~= "table" or type(Registry.ResolveItemReference) ~= "function" then
        return nil, nil
    end
    local ok, resolvedDataset, resolvedItem = pcall(Registry.ResolveItemReference, Registry, ref)
    if not ok or type(resolvedDataset) ~= "table" or type(resolvedItem) ~= "table" then
        return nil, nil
    end
    return resolvedDataset, resolvedItem
end

local function resolveActiveLoot(ref)
    local dataset, loot = findActivatedEntry(ref, "loot")
    if type(dataset) ~= "table" or type(loot) ~= "table" or type(Registry.ResolveLootReference) ~= "function" then
        return nil, nil
    end
    local ok, resolvedDataset, resolvedLoot = pcall(Registry.ResolveLootReference, Registry, ref)
    if not ok or type(resolvedDataset) ~= "table" or type(resolvedLoot) ~= "table" then
        return nil, nil
    end
    return resolvedDataset, resolvedLoot
end

local function currentServerEvent()
    return type(Server.GetEventState) == "function" and Server:GetEventState() or Server.EventState
end

local function buildStandaloneLootContext()
    local state = type(Server.GetState) == "function" and Server:GetState() or Server.State
    if type(state) ~= "table" or state.active ~= true then
        return nil, "server-inactive"
    end

    local channelName = trim(state.channelName)
    local hostName = normalizeName(type(Common.GetPlayerName) == "function" and Common.GetPlayerName() or "")
    if channelName == "" or hostName == "" then
        return nil, "loot-coordinator-unavailable"
    end

    local players, seen, units = {}, {}, {}
    for index = 1, #(state.clientOrder or {}) do
        local player = normalizeName(state.clientOrder[index])
        if player ~= "" and not seen[player] then
            seen[player] = true
            players[#players + 1] = player
            units[#units + 1] = { isPlayer = true, name = player, ownerID = player, controllerID = player }
        end
    end

    return {
        standalone = true,
        eventSessionId = "server:" .. channelName,
        hostName = hostName,
        players = players,
        eventState = { units = units },
    }
end

local function canUseActions()
    if type(Server.CanUseEventManagerActions) ~= "function" then
        return false, "event-action-blocked"
    end
    return Server:CanUseEventManagerActions()
end

function Server:GetEventManagerLootEligiblePlayers()
    local eventState = currentServerEvent()
    if type(self.Loot) ~= "table" or type(self.Loot.GetEligiblePlayers) ~= "function" then
        return nil, "loot-coordinator-unavailable"
    end
    if type(eventState) == "table" and eventState.active == true then
        local allowed, reason = canUseActions()
        if allowed ~= true then
            return nil, reason
        end
        return self.Loot:GetEligiblePlayers(eventState)
    end

    local context, reason = buildStandaloneLootContext()
    if not context then
        return nil, reason
    end
    return deepCopy(context.players)
end

function Server:ExecuteEventManagerLootGrant(grant, selectedPlayers)
    local eventState = currentServerEvent()
    local loot = self.Loot
    if type(loot) ~= "table"
        or type(loot.ValidateEligiblePlayers) ~= "function"
        or type(loot.GenerateGrantId) ~= "function"
        or type(loot.ExecuteGrant) ~= "function"
    then
        return nil, "loot-coordinator-unavailable"
    end

    if type(eventState) ~= "table" or eventState.active ~= true then
        local context, reason = buildStandaloneLootContext()
        if not context then
            return nil, reason
        end
        local players, playerReason, playerDetail = loot:ValidateEligiblePlayers(context.eventState, selectedPlayers)
        if not players then
            return nil, playerReason, playerDetail
        end
        local grantId, grantIdReason = loot:GenerateGrantId(context.eventSessionId, "event-manager")
        if not grantId then
            return nil, grantIdReason or "loot-grant-id-unavailable"
        end
        local summary, executeReason, executeDetail = loot:ExecuteGrant(grant, players, {
            eventSessionId = context.eventSessionId,
            grantId = grantId,
            hostName = context.hostName,
            source = "event-manager",
            standalone = true,
            eventState = context.eventState,
        })
        if type(summary) ~= "table" then
            return nil, executeReason, executeDetail
        end
        return summary, nil, nil, grantId
    end

    local allowed, reason = canUseActions()
    if allowed ~= true then
        return nil, reason
    end

    local players, playerReason, playerDetail = loot:ValidateEligiblePlayers(eventState, selectedPlayers)
    if not players then
        return nil, playerReason, playerDetail
    end

    local grantId, grantIdReason = loot:GenerateGrantId(eventState.id, "event-manager")
    if not grantId then
        return nil, grantIdReason or "loot-grant-id-unavailable"
    end

    local summary, executeReason, executeDetail = loot:ExecuteGrant(grant, players, {
        eventSessionId = tostring(eventState.id or ""),
        grantId = grantId,
        hostName = eventState.hostName,
        source = "event-manager",
    })
    if type(summary) ~= "table" then
        return nil, executeReason, executeDetail
    end
    return summary, nil, nil, grantId
end

function Server:RetryEventManagerLootDelivery(deliveryId)
    local loot = self.Loot
    if type(loot) ~= "table" or type(loot.RetryDelivery) ~= "function" then
        return nil, "loot-coordinator-unavailable"
    end
    return loot:RetryDelivery(deliveryId)
end

function EventManage:ReconcileActionLootPlayers(eligiblePlayers, eventSessionId)
    local eventId = tostring(eventSessionId or "")
    local eligible = {}
    local eligibleSet = {}
    for index = 1, #(eligiblePlayers or {}) do
        local player = normalizeName(eligiblePlayers[index])
        if player ~= "" and not eligibleSet[player] then
            eligibleSet[player] = true
            eligible[#eligible + 1] = player
        end
    end

    local selected = {}
    if tostring(self.ActionsLootSelectionEventId or "") ~= eventId then
        for index = 1, #eligible do
            selected[#selected + 1] = eligible[index]
        end
        self.ActionsLootSelectionEventId = eventId
    else
        local previousSet = {}
        for index = 1, #(self.ActionsLootSelectedPlayers or {}) do
            previousSet[normalizeName(self.ActionsLootSelectedPlayers[index])] = true
        end
        for index = 1, #eligible do
            if previousSet[eligible[index]] then
                selected[#selected + 1] = eligible[index]
            end
        end
    end

    self.ActionsLootSelectedPlayers = selected
    return deepCopy(selected)
end

function EventManage:SetActionLootSelectedPlayers(values)
    local selected = {}
    local seen = {}
    for index = 1, #(values or {}) do
        local player = normalizeName(values[index])
        if player ~= "" and not seen[player] then
            seen[player] = true
            selected[#selected + 1] = player
        end
    end
    self.ActionsLootSelectedPlayers = selected
    return deepCopy(selected)
end

function EventManage:BuildActionLootGrant()
    local sourceType = normalizeToken(self.ActionsLootSourceType or "direct")
    local distribution = normalizeToken(self.ActionsLootDistribution or "personal")
    if distribution ~= "group" and distribution ~= "personal" then
        return nil, "unsupported-distribution"
    end

    if sourceType == "direct" then
        local rewardType = normalizeToken(self.ActionsLootRewardType or "item")
        local ref = trim(self.ActionsLootRef)
        local amount = positiveInteger(self.ActionsLootQuantity)
        if not amount then
            return nil, "invalid-amount"
        end
        if rewardType == "item" then
            if not resolveActiveItem(ref) then
                return nil, "unknown-item"
            end
        elseif rewardType == "currency" then
            if not resolveActiveCurrency(ref) then
                return nil, "unknown-currency"
            end
        else
            return nil, "unsupported-source"
        end
        return {
            sourceType = "direct",
            distribution = distribution,
            reward = {
                type = rewardType,
                ref = ref,
                amount = amount,
            },
        }
    end

    if sourceType == "loot_table" then
        local lootRef = trim(self.ActionsLootRef)
        if not resolveActiveLoot(lootRef) then
            return nil, "unknown-loot-table"
        end
        return {
            sourceType = "loot_table",
            distribution = distribution,
            lootRef = lootRef,
        }
    end

    return nil, "unsupported-source"
end

function EventManage:ValidateActionLootControls(eligiblePlayers)
    local grant, reason = self:BuildActionLootGrant()
    if not grant then
        return nil, reason
    end
    local selected = self.ActionsLootSelectedPlayers or {}
    local eligibleSet = {}
    for index = 1, #(eligiblePlayers or {}) do
        eligibleSet[normalizeName(eligiblePlayers[index])] = true
    end
    if #selected == 0 then
        return nil, "empty-eligibility"
    end
    for index = 1, #selected do
        if not eligibleSet[normalizeName(selected[index])] then
            return nil, "ineligible-player"
        end
    end
    return grant, nil, deepCopy(selected)
end

local function resolveRewardName(reward)
    if type(reward) ~= "table" then
        return "Reward"
    end
    local rewardType = normalizeToken(reward.type)
    if rewardType == "item" and type(Registry.ResolveItemReference) == "function" then
        local ok, _, item = pcall(Registry.ResolveItemReference, Registry, reward.ref)
        if ok and type(item) == "table" and trim(item.name) ~= "" then
            return trim(item.name)
        end
    elseif rewardType == "currency" and type(Profile.ResolveCurrencyDefinition) == "function" then
        local ok, definition = pcall(Profile.ResolveCurrencyDefinition, reward.ref)
        if ok and type(definition) == "table" and trim(definition.name) ~= "" then
            return trim(definition.name)
        end
    end
    return trim(reward.ref) ~= "" and trim(reward.ref) or "Reward"
end

local function formatRewardResult(reward, deliveryStatus)
    local name = resolveRewardName(reward)
    local requested = positiveInteger(reward and reward.requestedAmount) or positiveInteger(reward and reward.amount) or 0
    local applied = tonumber(reward and reward.appliedAmount)
    local reason = trim(reward and reward.reason)

    if deliveryStatus == "success" and applied ~= nil then
        applied = math.max(0, math.floor(applied))
        if requested > 0 and applied < requested and reason == "currency-capped" then
            return ("%s %d/%d (currency cap)"):format(name, applied, requested)
        end
        return ("%s x%d"):format(name, applied)
    end
    if requested > 0 then
        return ("%s x%d"):format(name, requested)
    end
    return name
end

function EventManage:BuildActionLootResultItems(summary)
    local items = {}
    for index = 1, #(type(summary) == "table" and summary.deliveries or {}) do
        local delivery = summary.deliveries[index]
        local status = tostring(delivery and delivery.status or "pending")
        local statusLabel = status == "success" and "Delivered" or status == "failed" and "Failed" or "Pending"
        local rewards = {}
        for rewardIndex = 1, #(delivery and delivery.rewards or {}) do
            rewards[#rewards + 1] = formatRewardResult(delivery.rewards[rewardIndex], status)
        end
        local reason = trim(delivery and delivery.reason)
        local suffix = #rewards > 0 and table.concat(rewards, ", ") or "No rewards"
        if status == "failed" and reason ~= "" then
            suffix = suffix .. " — " .. friendlyReason(reason)
        end
        items[#items + 1] = {
            label = ("%s — %s — %s"):format(tostring(delivery and delivery.recipientName or "Unknown"), statusLabel, suffix),
            value = tostring(delivery and delivery.deliveryId or ""),
            status = status,
            reason = reason,
            delivery = deepCopy(delivery),
        }
    end
    if #items == 0 then
        return { { label = "No Loot delivery selected", value = "" } }
    end
    return items
end

local function selectedResultItem(items, deliveryId)
    local wanted = tostring(deliveryId or "")
    for index = 1, #(items or {}) do
        if tostring(items[index] and items[index].value or "") == wanted then
            return items[index]
        end
    end
    return nil
end

local function chooseResultDelivery(items)
    for index = 1, #(items or {}) do
        if items[index].status == "failed" then
            return items[index].value
        end
    end
    for index = 1, #(items or {}) do
        if items[index].status == "pending" then
            return items[index].value
        end
    end
    return items[1] and items[1].value or ""
end

local function createText(parent, name, value, width, color)
    return UI.CreateText(parent, name, value, {
        width = width or CONTENT_WIDTH,
        height = 18,
        fontFile = (C.FontFiles and C.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (C.FontSizes and C.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, color or "text.secondary"),
        justifyH = "LEFT",
        justifyV = "MIDDLE",
        wordWrap = false,
    })
end

local function createRow(parent, name)
    return UI.CreateLayout(UI.HorizontalLayoutGroup, parent, name, {
        width = CONTENT_WIDTH,
        height = CONTROL_HEIGHT,
        spacing = 5,
        autoSize = false,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
end

function EventManage:BuildActionLootTargetItems(players)
    local items = {}
    for index = 1, #(players or {}) do
        items[#items + 1] = {
            label = tostring(players[index]),
            value = tostring(players[index]),
            keepShownOnClick = true,
        }
    end
    return items
end

function EventManage:RefreshActionLootResult()
    if not self.ActionsLootResultDropdown then
        return false
    end
    local summary = nil
    local sessionId = tostring(self.ActionsLootResultEventSessionId or "")
    local grantId = tostring(self.ActionsLootResultGrantId or "")
    if sessionId ~= "" and grantId ~= "" and type(Loot.GetGrantExecutionSummary) == "function" then
        summary = Loot:GetGrantExecutionSummary(sessionId, grantId)
    end
    local items = self:BuildActionLootResultItems(summary)
    local selected = tostring(self.ActionsLootSelectedDeliveryId or "")
    if not selectedResultItem(items, selected) then
        selected = chooseResultDelivery(items)
    end
    self.ActionsLootSelectedDeliveryId = syncDropdown(self.ActionsLootResultDropdown, items, selected, chooseResultDelivery(items))
    local item = selectedResultItem(items, self.ActionsLootSelectedDeliveryId)
    setEnabled(self.ActionsLootResultDropdown, #items > 0 and trim(items[1] and items[1].value) ~= "")
    setEnabled(self.ActionsLootRetryButton, item ~= nil and item.status ~= "success" and trim(item.value) ~= "")
    return true
end

function EventManage:RefreshActionLootSection()
    if not self.ActionsLootSourceDropdown then
        return false
    end

    local ready = type(Server.IsActive) == "function" and Server:IsActive() == true
    local actionReason = ready and nil or "server-inactive"
    local eventState = currentServerEvent()
    local eventSessionId = tostring(type(eventState) == "table" and eventState.id or "")

    self.ActionsLootSourceType = syncDropdown(self.ActionsLootSourceDropdown, SOURCE_ITEMS, self.ActionsLootSourceType, "direct")
    self.ActionsLootDistribution = syncDropdown(self.ActionsLootDistributionDropdown, DISTRIBUTION_ITEMS, self.ActionsLootDistribution, "personal")
    self.ActionsLootRewardType = syncDropdown(self.ActionsLootRewardTypeDropdown, REWARD_TYPE_ITEMS, self.ActionsLootRewardType, "item")

    local collectionKey = self.ActionsLootSourceType == "loot_table" and "loot"
        or self.ActionsLootRewardType == "item" and "items"
        or nil
    local datasetItems = collectionKey and buildDatasetItems(collectionKey) or { { label = "Dataset", value = "" } }
    self.ActionsLootDatasetId = syncDropdown(self.ActionsLootDatasetDropdown, datasetItems, self.ActionsLootDatasetId, "")

    local refItems = nil
    if self.ActionsLootSourceType == "loot_table" then
        refItems = buildEntryItems(self.ActionsLootDatasetId, "loot", "Loot Table")
    elseif self.ActionsLootRewardType == "item" then
        refItems = buildEntryItems(self.ActionsLootDatasetId, "items", "Item")
    else
        refItems = buildCurrencyItems()
    end
    self.ActionsLootRef = syncDropdown(self.ActionsLootRefDropdown, refItems, self.ActionsLootRef, "")

    local eligiblePlayers, eligibilityReason = nil, nil
    if ready == true then
        eligiblePlayers, eligibilityReason = Server:GetEventManagerLootEligiblePlayers()
    end
    eligiblePlayers = type(eligiblePlayers) == "table" and eligiblePlayers or {}
    self:ReconcileActionLootPlayers(eligiblePlayers, eventSessionId)
    local targetItems = self:BuildActionLootTargetItems(eligiblePlayers)
    if type(self.ActionsLootTargetsDropdown.SetItems) == "function" then
        self.ActionsLootTargetsDropdown:SetItems(targetItems)
    end
    if type(self.ActionsLootTargetsDropdown.SetSelectedValues) == "function" then
        self.ActionsLootTargetsDropdown:SetSelectedValues(self.ActionsLootSelectedPlayers or {}, true)
    end

    self.ActionsLootQuantity = trim(self.ActionsLootQuantityInput and self.ActionsLootQuantityInput:GetText() or self.ActionsLootQuantity or "1")
    local _, validationReason = self:ValidateActionLootControls(eligiblePlayers)
    local configuredGrant = self:BuildActionLootGrant()
    local valid = ready == true and type(configuredGrant) == "table"

    setEnabled(self.ActionsLootSourceDropdown, ready == true)
    setEnabled(self.ActionsLootDistributionDropdown, ready == true)
    setEnabled(self.ActionsLootRewardTypeDropdown, ready == true and self.ActionsLootSourceType == "direct")
    setEnabled(self.ActionsLootQuantityInput, ready == true and self.ActionsLootSourceType == "direct")
    setEnabled(self.ActionsLootDatasetDropdown, ready == true and collectionKey ~= nil)
    setEnabled(self.ActionsLootRefDropdown, ready == true)
    setEnabled(self.ActionsLootTargetsDropdown, ready == true and #eligiblePlayers > 0)
    setEnabled(self.ActionsLootDistributeButton, valid and self.ActionsLootClickInFlight ~= true)

    if ready ~= true then
        self.ActionsLootValidationReason = actionReason
    elseif eligibilityReason and #eligiblePlayers == 0 then
        self.ActionsLootValidationReason = eligibilityReason
    else
        self.ActionsLootValidationReason = validationReason
    end

    self:RefreshActionLootResult()
    return true
end

function EventManage:DistributeActionLoot()
    if self.ActionsLootClickInFlight == true then
        return nil, "loot-action-in-flight"
    end
    self.ActionsLootClickInFlight = true

    local eligiblePlayers, eligibilityReason = Server:GetEventManagerLootEligiblePlayers()
    eligiblePlayers = type(eligiblePlayers) == "table" and eligiblePlayers or {}
    local grant, validationReason, selectedPlayers = self:ValidateActionLootControls(eligiblePlayers)
    if not grant then
        self.ActionsLootClickInFlight = false
        local reason = validationReason or eligibilityReason or "invalid-loot-action"
        self:SetActionsStatus("Distribute Loot failed: " .. friendlyReason(reason))
        self:RefreshActionLootSection()
        return nil, reason
    end

    local summary, reason, detail, grantId = Server:ExecuteEventManagerLootGrant(grant, selectedPlayers)
    self.ActionsLootClickInFlight = false
    if type(summary) ~= "table" then
        local failure = reason or "loot-execution-failed"
        self:SetActionsStatus("Distribute Loot failed: " .. friendlyReason(failure))
        self:RefreshActionLootSection()
        return nil, failure, detail
    end

    self.ActionsLootResultEventSessionId = tostring(summary.eventSessionId or (currentServerEvent() and currentServerEvent().id) or "")
    self.ActionsLootResultGrantId = tostring(summary.grantId or grantId or "")
    self.ActionsLootSelectedDeliveryId = ""
    local status = tostring(summary.status or "pending")
    self:SetActionsStatus(status == "success" and "Loot delivered."
        or status == "failed" and "Loot delivery failed."
        or "Loot assigned; awaiting acknowledgement.")
    self:RefreshActionLootSection()
    return summary
end

function EventManage:RetrySelectedActionLootDelivery()
    local deliveryId = trim(self.ActionsLootSelectedDeliveryId)
    if deliveryId == "" then
        return nil, "unknown-delivery"
    end
    local summary, reason = Server:RetryEventManagerLootDelivery(deliveryId)
    if type(summary) ~= "table" then
        self:SetActionsStatus("Retry failed: " .. friendlyReason(reason))
        self:RefreshActionLootResult()
        return nil, reason
    end
    self:SetActionsStatus(reason == "already-successful" and "Delivery already completed." or "Loot delivery retried.")
    self:RefreshActionLootResult()
    return summary, reason
end

function EventManage:BuildActionLootSection(root)
    if self.ActionsLootSourceDropdown or not root then
        return root
    end

    root:AddChild(createText(root:GetFrame(), "RPEServerEventManageActionsLootHeader", "Loot", CONTENT_WIDTH, "warning"))

    local controlsRow = createRow(root:GetFrame(), "RPEServerEventManageActionsLootControlsRow")
    self.ActionsLootSourceDropdown = UI.CreateDropdown(controlsRow:GetFrame(), "RPEServerEventManageActionsLootSourceDropdown", {
        width = 92,
        height = DROPDOWN_HEIGHT,
        items = SOURCE_ITEMS,
        selectedValue = "direct",
        tooltip = "Choose a Direct reward or resolve a Loot Table.",
        onValueChanged = function(value)
            self.ActionsLootSourceType = tostring(value or "direct")
            self.ActionsLootDatasetId = ""
            self.ActionsLootRef = ""
            self:RefreshActionLootSection()
        end,
    })
    controlsRow:AddChild(self.ActionsLootSourceDropdown)

    self.ActionsLootDistributionDropdown = UI.CreateDropdown(controlsRow:GetFrame(), "RPEServerEventManageActionsLootDistributionDropdown", {
        width = 92,
        height = DROPDOWN_HEIGHT,
        items = DISTRIBUTION_ITEMS,
        selectedValue = "personal",
        tooltip = "Personal resolves independently per selected player. Group resolves once for the selected group and assigns each reward to one player.",
        onValueChanged = function(value)
            self.ActionsLootDistribution = tostring(value or "personal")
            self:RefreshActionLootSection()
        end,
    })
    controlsRow:AddChild(self.ActionsLootDistributionDropdown)

    self.ActionsLootRewardTypeDropdown = UI.CreateDropdown(controlsRow:GetFrame(), "RPEServerEventManageActionsLootRewardTypeDropdown", {
        width = 76,
        height = DROPDOWN_HEIGHT,
        items = REWARD_TYPE_ITEMS,
        selectedValue = "item",
        onValueChanged = function(value)
            self.ActionsLootRewardType = tostring(value or "item")
            self.ActionsLootDatasetId = ""
            self.ActionsLootRef = ""
            self:RefreshActionLootSection()
        end,
    })
    controlsRow:AddChild(self.ActionsLootRewardTypeDropdown)

    self.ActionsLootQuantityInput = UI.CreateTextInput(controlsRow:GetFrame(), "RPEServerEventManageActionsLootQuantityInput", {
        width = 44,
        height = CONTROL_HEIGHT,
        text = "1",
        justifyH = "CENTER",
        tooltip = "Direct Loot quantity. Must be a positive whole number.",
    })
    self.ActionsLootQuantityInput:SetScript("OnTextChanged", function(input)
        self.ActionsLootQuantity = trim(input:GetText())
        self:RefreshActionLootSection()
    end)
    controlsRow:AddChild(self.ActionsLootQuantityInput)

    self.ActionsLootDistributeButton = UI.CreateButton(controlsRow:GetFrame(), "RPEServerEventManageActionsLootDistributeButton", "Distribute Loot", 120, function()
        self:DistributeActionLoot()
    end)
    controlsRow:AddChild(self.ActionsLootDistributeButton)
    root:AddChild(controlsRow)

    local sourceRow = createRow(root:GetFrame(), "RPEServerEventManageActionsLootSourceRow")
    self.ActionsLootDatasetDropdown = UI.CreateDropdown(sourceRow:GetFrame(), "RPEServerEventManageActionsLootDatasetDropdown", {
        width = 125,
        height = DROPDOWN_HEIGHT,
        items = {},
        selectedValue = "",
        onValueChanged = function(value)
            self.ActionsLootDatasetId = tostring(value or "")
            self.ActionsLootRef = ""
            self:RefreshActionLootSection()
        end,
    })
    sourceRow:AddChild(self.ActionsLootDatasetDropdown)

    self.ActionsLootRefDropdown = UI.CreateDropdown(sourceRow:GetFrame(), "RPEServerEventManageActionsLootRefDropdown", {
        width = 190,
        height = DROPDOWN_HEIGHT,
        items = {},
        selectedValue = "",
        onValueChanged = function(value)
            self.ActionsLootRef = tostring(value or "")
            self:RefreshActionLootSection()
        end,
    })
    sourceRow:AddChild(self.ActionsLootRefDropdown)

    self.ActionsLootTargetsDropdown = UI.CreateDropdown(sourceRow:GetFrame(), "RPEServerEventManageActionsLootTargetsDropdown", {
        width = 155,
        height = DROPDOWN_HEIGHT,
        items = {},
        multiSelect = true,
        selectedValues = {},
        popupWidth = 210,
        tooltip = "Choose one or more event players, or connected server clients when no event is active.",
        onValueChanged = function(values)
            self:SetActionLootSelectedPlayers(values)
            self:RefreshActionLootSection()
        end,
    })
    sourceRow:AddChild(self.ActionsLootTargetsDropdown)
    root:AddChild(sourceRow)

    local resultRow = createRow(root:GetFrame(), "RPEServerEventManageActionsLootResultRow")
    self.ActionsLootResultDropdown = UI.CreateDropdown(resultRow:GetFrame(), "RPEServerEventManageActionsLootResultDropdown", {
        width = 355,
        height = DROPDOWN_HEIGHT,
        items = { { label = "No Loot delivery selected", value = "" } },
        selectedValue = "",
        popupWidth = 460,
        onValueChanged = function(value)
            self.ActionsLootSelectedDeliveryId = tostring(value or "")
            self:RefreshActionLootResult()
        end,
    })
    resultRow:AddChild(self.ActionsLootResultDropdown)

    self.ActionsLootRetryButton = UI.CreateButton(resultRow:GetFrame(), "RPEServerEventManageActionsLootRetryButton", "Retry Delivery", 120, function()
        self:RetrySelectedActionLootDelivery()
    end, {
        tooltip = "Resend the exact frozen delivery. This does not reroll or reassign Loot.",
    })
    resultRow:AddChild(self.ActionsLootRetryButton)
    root:AddChild(resultRow)

    self.ActionsLootSourceType = self.ActionsLootSourceType or "direct"
    self.ActionsLootDistribution = self.ActionsLootDistribution or "personal"
    self.ActionsLootRewardType = self.ActionsLootRewardType or "item"
    self.ActionsLootQuantity = self.ActionsLootQuantity or "1"
    self.ActionsLootDatasetId = self.ActionsLootDatasetId or ""
    self.ActionsLootRef = self.ActionsLootRef or ""
    self.ActionsLootSelectedPlayers = type(self.ActionsLootSelectedPlayers) == "table" and self.ActionsLootSelectedPlayers or {}

    if root.options then
        root.options.spacing = COMPACT_ROOT_SPACING
        root.options.spacingY = COMPACT_ROOT_SPACING
    end
    if type(root.RefreshLayout) == "function" then
        root:RefreshLayout()
    end
    return root
end

local baseBuildActionsPage = EventManage.BuildActionsPage
if type(baseBuildActionsPage) == "function" then
    function EventManage:BuildActionsPage(page)
        local root = baseBuildActionsPage(self, page)
        self:BuildActionLootSection(root)
        return root
    end
end

local baseRefreshActionsPage = EventManage.RefreshActionsPage
if type(baseRefreshActionsPage) == "function" then
    function EventManage:RefreshActionsPage(...)
        local result = baseRefreshActionsPage(self, ...)
        if self.ActionsLootSourceDropdown then
            self:RefreshActionLootSection()
        end
        return result
    end
end

local function refreshVisibleActionsPage()
    if type(EventManage.IsWindowVisible) == "function"
        and EventManage:IsWindowVisible()
        and type(EventManage.IsActionsPageActive) == "function"
        and EventManage:IsActionsPageActive()
        and type(EventManage.RefreshActionsPage) == "function"
    then
        EventManage:RefreshActionsPage()
        return true
    end
    return false
end

if Loot._eventManagerActionsResponseRefreshInstalled ~= true and type(Loot.HandleDeliveryResponse) == "function" then
    local baseHandleDeliveryResponse = Loot.HandleDeliveryResponse
    function Loot:HandleDeliveryResponse(...)
        local results = pack(baseHandleDeliveryResponse(self, ...))
        if results[1] == true then
            refreshVisibleActionsPage()
        end
        return unpack(results, 1, results.n)
    end
    Loot._eventManagerActionsResponseRefreshInstalled = true
end

EventManage._actionsLootInstalled = true
return true
