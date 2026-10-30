local _, Addon = ...

Addon = Addon or {}
Addon.Client = Addon.Client or {}

local Client = Addon.Client
local Profile = Addon.Internal and Addon.Internal.Profile or {}
local Registry = Addon.Internal and Addon.Internal.Registry or {}
local ItemTier = Addon.Internal and Addon.Internal.ItemTier or {}
local Runtime = Addon.Internal and Addon.Internal.Runtime or {}
local Common = Addon.Utils and Addon.Utils.Common or {}
local Comms = Addon.Internal and Addon.Internal.Comms or {}
local Operations = Comms.Operations or {}

local LootNotifications = Client.LootNotifications or {}
Client.LootNotifications = LootNotifications

local QUALITY_COLORS = {
    poor = "9d9d9d",
    common = "ffffff",
    uncommon = "1eff00",
    rare = "0070dd",
    epic = "a335ee",
    legendary = "ff8000",
    artifact = "e6cc80",
    heirloom = "00ccff",
}

local ITEM_RECEIVED = "You receive loot: %s."
local ITEM_RECEIVED_MULTIPLE = "You receive loot: %s x%d."
local CURRENCY_RECEIVED = "You receive currency: %s."
local CURRENCY_RECEIVED_MULTIPLE = "You receive currency: %s x%d."
local MONEY_RECEIVED = "You receive %s."
local LOOT_TEXT_COLOR = "00ff00"
local ACHIEVEMENT_TEXT_COLOR = "ffff00"
local GUILD_TEXT_COLOR = "40ff40"
local ACHIEVEMENT_EARNED = "You have earned the achievement %s!"
local GUILD_ACHIEVEMENT_EARNED = "%s has earned the achievement %s!"
local ITEM_GAIN_ANNOUNCEMENT_OPCODE = type(Operations.GetOpcode) == "function"
    and Operations:GetOpcode("ITEM_GAIN_ANNOUNCEMENT") or nil
local ITEM_GAIN_CATEGORIES = {
    crafted = true,
    received = true,
    looted = true,
}

local function trimText(value)
    return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function normalizeQuantity(value)
    return math.max(0, math.floor(tonumber(value) or 0))
end

local function colorItemName(name, quality)
    local color = QUALITY_COLORS[string.lower(trimText(quality))] or QUALITY_COLORS.common
    return ("|cff%s[%s]|r"):format(color, name)
end

local function formatItemLink(itemRef, name, quality, itemTier)
    local reference = trimText(itemRef)
    if reference == "" or reference:find("|", 1, true) then
        return colorItemName(name, quality)
    end

    local normalizedTier = ItemTier.Normalize(itemTier) or "normal"
    if normalizedTier ~= "normal" then
        reference = reference .. "?tier=" .. normalizedTier
    end
    local color = QUALITY_COLORS[string.lower(trimText(quality))] or QUALITY_COLORS.common
    return ("|Hrpitem:%s|h|cff%s[%s]|r|h"):format(reference, color, name)
end

local function resolveItem(itemRef)
    local reference = trimText(itemRef)
    if reference == "" or type(Registry.ResolveItemReference) ~= "function" then
        return nil, nil
    end

    local ok, _, item = pcall(Registry.ResolveItemReference, Registry, reference)
    if not ok or type(item) ~= "table" then
        return nil, nil
    end

    local name = trimText(item.name)
    if name == "" then
        return nil, nil
    end
    return item, name, item.quality
end

local function resolveAchievement(achievementRef)
    local reference = trimText(achievementRef)
    if reference == "" or type(Registry.ResolveAchievementReference) ~= "function" then
        return nil, nil
    end

    local ok, _, achievement = pcall(Registry.ResolveAchievementReference, Registry, reference)
    if not ok or type(achievement) ~= "table" then
        return nil, nil
    end

    local name = trimText(achievement.name)
    if name == "" then
        return nil, nil
    end
    return achievement, name
end

local function formatAchievementLink(achievementRef, name)
    local reference = trimText(achievementRef)
    if reference == "" or reference:find("|", 1, true) then
        return ("|cff%s[%s]|r"):format(ACHIEVEMENT_TEXT_COLOR, name)
    end

    return ("|Hrpachievement:%s|h|cff%s[%s]|r|h"):format(reference, ACHIEVEMENT_TEXT_COLOR, name)
end

local function formatCurrency(definition)
    local name = trimText(definition and definition.name)
    if name == "" then
        return nil
    end

    local icon = definition and definition.icon
    local iconMarkup = ""
    if icon ~= nil and tostring(icon) ~= "" then
        iconMarkup = ("|T%s:12:12:0:0|t"):format(tostring(icon))
    end
    return ("%s[%s]"):format(iconMarkup, name)
end

local function emitChatMessage(message)
    if not (DEFAULT_CHAT_FRAME and type(DEFAULT_CHAT_FRAME.AddMessage) == "function") then
        return false
    end

    DEFAULT_CHAT_FRAME:AddMessage(message)
    return true
end

function LootNotifications:NotifyItemGain(itemRef, amount, itemTier)
    local quantity = normalizeQuantity(amount)
    local _, name, quality = resolveItem(itemRef)
    if quantity <= 0 or not name then
        return false
    end

    quality = ItemTier.GetEffectiveQuality(quality, itemTier)
    local body = quantity == 1
        and ITEM_RECEIVED:format(formatItemLink(itemRef, name, quality, itemTier))
        or ITEM_RECEIVED_MULTIPLE:format(formatItemLink(itemRef, name, quality, itemTier), quantity)
    local coloredBody = body:gsub("|r", "|r|cff" .. LOOT_TEXT_COLOR)
    local message = ("|cff%s%s|r"):format(
        LOOT_TEXT_COLOR,
        coloredBody
    )
    return emitChatMessage(message)
end

function LootNotifications:ShowItemTooltip(itemRef, owner, itemTier)
    local item = select(1, resolveItem(itemRef))
    local clientUI = Addon.Client and Addon.Client.UI or nil
    local itemTooltip = clientUI and clientUI.Tooltips and clientUI.Tooltips.Item or nil
    local tooltipUI = Addon.UI or nil
    local tooltipService = tooltipUI and tooltipUI.Tooltip or nil
    if type(item) ~= "table"
        or type(itemTooltip) ~= "table"
        or type(itemTooltip.Build) ~= "function"
        or type(tooltipService) ~= "table"
        or type(tooltipService.ShowForElement) ~= "function"
    then
        return false
    end

    local tooltip = itemTooltip:Build(item, {
        itemId = item.id,
        itemRef = itemRef,
        isActive = true,
        itemTier = itemTier,
    })
    if type(tooltip) ~= "table" then
        return false
    end

    return tooltipService:ShowForElement(owner or UIParent, tooltip) ~= nil
end

function LootNotifications:NotifyAchievementEarned(achievementRef, achievement)
    local reference = trimText(achievementRef)
    local name = trimText(type(achievement) == "table" and achievement.name)
    if name == "" then
        name = select(2, resolveAchievement(reference)) or ""
    end
    if reference == "" or name == "" then
        return false
    end

    local body = ACHIEVEMENT_EARNED:format(formatAchievementLink(reference, name))
    local coloredBody = body:gsub("|r", "|r|cff" .. ACHIEVEMENT_TEXT_COLOR)
    local message = ("|cff%s%s|r"):format(
        ACHIEVEMENT_TEXT_COLOR,
        coloredBody
    )
    return emitChatMessage(message)
end

function LootNotifications:NotifyGuildAchievementEarned(playerName, achievementRef, achievement)
    local player = trimText(playerName)
    local reference = trimText(achievementRef)
    local name = trimText(type(achievement) == "table" and achievement.name)
    if name == "" then
        name = select(2, resolveAchievement(reference)) or ""
    end
    if player == "" or reference == "" or name == "" then
        return false
    end

    local body = GUILD_ACHIEVEMENT_EARNED:format(player, formatAchievementLink(reference, name))
    local coloredBody = body:gsub("|r", "|r|cff" .. GUILD_TEXT_COLOR)
    local message = ("|cff%s%s|r"):format(
        GUILD_TEXT_COLOR,
        coloredBody
    )
    return emitChatMessage(message)
end

function LootNotifications:ShowAchievementTooltip(achievementRef, owner)
    local achievement = select(1, resolveAchievement(achievementRef))
    local clientUI = Addon.Client and Addon.Client.UI or nil
    local achievementTooltip = clientUI and clientUI.Tooltips and clientUI.Tooltips.Achievement or nil
    local tooltipUI = Addon.UI or nil
    local tooltipService = tooltipUI and tooltipUI.Tooltip or nil
    if type(achievement) ~= "table"
        or type(achievementTooltip) ~= "table"
        or type(achievementTooltip.Build) ~= "function"
        or type(tooltipService) ~= "table"
        or type(tooltipService.ShowForElement) ~= "function"
    then
        return false
    end

    local state = type(Profile.GetAchievementState) == "function"
        and Profile.GetAchievementState(achievementRef)
        or nil
    local tooltip = achievementTooltip:Build({
        achievement = achievement,
        achievementRef = achievementRef,
        state = state,
    })
    if type(tooltip) ~= "table" then
        return false
    end

    return tooltipService:ShowForElement(owner or UIParent, tooltip) ~= nil
end

function LootNotifications:NotifyCurrencyGain(currencyRef, amount)
    local quantity = normalizeQuantity(amount)
    if quantity <= 0 or type(Profile.ResolveCurrencyDefinition) ~= "function" then
        return false
    end

    local definition = Profile.ResolveCurrencyDefinition(currencyRef)
    if type(definition) == "table" and definition.key == "copper" then
        local body = MONEY_RECEIVED:format(Common:FormatCopper(quantity))
        local message = ("|cff%s%s|r"):format(LOOT_TEXT_COLOR, body)
        return emitChatMessage(message)
    end

    local display = formatCurrency(definition)
    if not display then
        return false
    end
    local body = quantity == 1
        and CURRENCY_RECEIVED:format(display)
        or CURRENCY_RECEIVED_MULTIPLE:format(display, quantity)
    local message = ("|cff%s%s|r"):format(LOOT_TEXT_COLOR, body)
    return emitChatMessage(message)
end

local function normalizePlayerName(value)
    local name = type(Common.NormalizeName) == "function"
        and Common.NormalizeName(value)
        or trimText(value)
    if name == "" or name:find("|", 1, true) or name:find("%c") then
        return ""
    end
    return name
end

local function isSafeEventId(value)
    local eventId = trimText(value)
    return eventId ~= ""
        and #eventId <= 128
        and eventId:match("^[%w%._:%-]+$") ~= nil
end

local function normalizeItemGainCategory(source)
    local normalized = string.lower(trimText(source))
    if normalized == "craft-recipe" then
        return "crafted"
    elseif normalized == "loot-delivery" then
        return "looted"
    end
    return "received"
end

local function buildAcquisitionMessage(event)
    local _, name, quality = resolveItem(event.itemRef)
    if not name then
        return nil
    end

    quality = ItemTier.GetEffectiveQuality(quality, event.itemTier)
    local body = ("[%s] %s %s x%d."):format(
        event.playerName,
        event.category,
        formatItemLink(event.itemRef, name, quality, event.itemTier),
        event.quantity
    )
    local coloredBody = body:gsub("|r", "|r|cff" .. LOOT_TEXT_COLOR)
    return ("|cff%s%s|r"):format(LOOT_TEXT_COLOR, coloredBody)
end

local function normalizeAcquisitionEvent(event)
    if type(event) ~= "table" then
        return nil
    end

    local itemRef = trimText(event.itemRef)
    local datasetId, itemId = itemRef:match("^([^:]+):([^:]+)$")
    local itemTier
    if type(ItemTier.Validate) == "function" then
        itemTier = select(1, ItemTier.Validate(event.itemTier))
    elseif type(ItemTier.Normalize) == "function" then
        itemTier = ItemTier.Normalize(event.itemTier)
    end
    local numericQuantity = tonumber(event.quantity)
    local quantity = normalizeQuantity(event.quantity)
    local playerName = normalizePlayerName(event.playerName)
    local category = string.lower(trimText(event.category))
    local eventId = trimText(event.eventId)
    if not datasetId or not itemId
        or datasetId:find("[^%w%._%-]") or itemId:find("[^%w%._%-]")
        or itemRef == "" or itemRef:find("|", 1, true)
        or numericQuantity == nil or numericQuantity ~= math.floor(numericQuantity)
        or quantity <= 0 or quantity > 1000000
        or playerName == "" or not ITEM_GAIN_CATEGORIES[category]
        or not itemTier or not isSafeEventId(eventId)
    then
        return nil
    end

    return {
        itemRef = itemRef,
        itemTier = itemTier,
        quantity = quantity,
        category = category,
        eventId = eventId,
        playerName = playerName,
    }
end

local function acquisitionKey(event)
    return event.playerName .. ":" .. event.eventId
end

function LootNotifications:RememberAcquisition(event)
    self._seenAcquisitionEvents = type(self._seenAcquisitionEvents) == "table"
        and self._seenAcquisitionEvents or {}
    self._seenAcquisitionOrder = type(self._seenAcquisitionOrder) == "table"
        and self._seenAcquisitionOrder or {}
    local key = acquisitionKey(event)
    if self._seenAcquisitionEvents[key] then
        return false
    end

    self._seenAcquisitionEvents[key] = true
    self._seenAcquisitionOrder[#self._seenAcquisitionOrder + 1] = key
    while #self._seenAcquisitionOrder > 256 do
        local oldest = table.remove(self._seenAcquisitionOrder, 1)
        self._seenAcquisitionEvents[oldest] = nil
    end
    return true
end

function LootNotifications:RenderAcquisition(event)
    local normalized = normalizeAcquisitionEvent(event)
    if not normalized or not resolveItem(normalized.itemRef) then
        return false
    end
    local message = buildAcquisitionMessage(normalized)
    return message and emitChatMessage(message) or false
end

function LootNotifications:IsConnectedToActiveServer()
    local state = Client.State
    return type(state) == "table"
        and state.active == true
        and normalizePlayerName(state.hostName) ~= ""
        and state.channelId ~= nil and state.channelId ~= ""
end

function LootNotifications:SendAcquisitionAnnouncement(event)
    local state = Client.State
    if not self:IsConnectedToActiveServer()
        or not ITEM_GAIN_ANNOUNCEMENT_OPCODE
        or type(Comms.SendToChannel) ~= "function"
    then
        return false
    end

    local sender = state._sendToChannel or Comms.SendToChannel
    if type(sender) ~= "function" then
        return false
    end

    local playerName = normalizePlayerName(type(Common.GetPlayerName) == "function" and Common.GetPlayerName() or "")
    if playerName == "" then
        return false
    end

    local sent = sender(Comms, state.channelId, ITEM_GAIN_ANNOUNCEMENT_OPCODE, {
        playerName,
        event.eventId,
        event.itemRef,
        event.itemTier,
        event.quantity,
        event.category,
    }, {
        opcode = ITEM_GAIN_ANNOUNCEMENT_OPCODE,
        scope = "client",
        onFailed = function()
            if self:RememberAcquisition(event) then
                self:RenderAcquisition(event)
            end
        end,
    })
    return sent == true
end

function LootNotifications:HandleCommittedAcquisition(event)
    local normalized = normalizeAcquisitionEvent(event)
    if not normalized or not resolveItem(normalized.itemRef) then
        return false
    end

    if not self:IsConnectedToActiveServer() then
        if self:RememberAcquisition(normalized) then
            return self:NotifyItemGain(normalized.itemRef, normalized.quantity, normalized.itemTier)
        end
        return false
    end

    if self:SendAcquisitionAnnouncement(normalized) then
        if self:RememberAcquisition(normalized) then
            self:RenderAcquisition(normalized)
        end
        return true
    end

    if self:RememberAcquisition(normalized) then
        return self:RenderAcquisition(normalized)
    end
    return false
end

function LootNotifications:PublishCommittedItemGain(itemRef, quantity, itemTier, source, eventId)
    self._nextManualEventId = (tonumber(self._nextManualEventId) or 0) + 1
    local normalizedEventId = trimText(eventId)
    if normalizedEventId == "" then
        normalizedEventId = ("manual:%d"):format(self._nextManualEventId)
    end
    normalizedEventId = normalizedEventId:gsub("[^%w%._:%-]", "_")
    return self:HandleCommittedAcquisition({
        itemRef = itemRef,
        quantity = quantity,
        itemTier = itemTier,
        category = normalizeItemGainCategory(source),
        eventId = normalizedEventId,
        playerName = normalizePlayerName(type(Common.GetPlayerName) == "function" and Common.GetPlayerName() or ""),
    })
end

function LootNotifications:ConfirmLootDelivery(deliveryId)
    local key = trimText(deliveryId)
    local pending = self._pendingLootAcquisitions and self._pendingLootAcquisitions[key]
    if key == "" or type(pending) ~= "table" then
        return false
    end

    self._pendingLootAcquisitions[key] = nil
    for index = 1, #pending do
        self:HandleCommittedAcquisition(pending[index])
    end
    return true
end

function LootNotifications:RejectLootDelivery(deliveryId)
    local key = trimText(deliveryId)
    if key == "" or type(self._pendingLootAcquisitions) ~= "table" then
        return false
    end
    self._pendingLootAcquisitions[key] = nil
    return true
end

function Client:HandleItemGainAnnouncement(arguments, sender, distribution, target)
    local state = self.State
    local senderName = normalizePlayerName(sender)
    if type(state) ~= "table" or state.active ~= true
        or distribution ~= "CHANNEL"
        or tonumber(target) ~= tonumber(state.channelId)
        or senderName == ""
    then
        return false
    end

    local event = normalizeAcquisitionEvent({
        playerName = arguments and arguments[1],
        eventId = arguments and arguments[2],
        itemRef = arguments and arguments[3],
        itemTier = arguments and arguments[4],
        quantity = arguments and arguments[5],
        category = arguments and arguments[6],
    })
    if not event
        or senderName ~= event.playerName
        or not resolveItem(event.itemRef)
        or not LootNotifications:RememberAcquisition(event)
    then
        return false
    end
    return LootNotifications:RenderAcquisition(event)
end

local function registerItemGainNotifications()
    if LootNotifications._itemGainProcessorId ~= nil
        or type(Runtime.RegisterBeforeCommitProcessor) ~= "function"
    then
        return
    end

    LootNotifications._itemGainProcessorId = Runtime:RegisterBeforeCommitProcessor("item_gain", function(mutation)
        if type(mutation) ~= "table"
            or mutation.changeType ~= "add"
            or mutation.isCanonicalAdd ~= true
            or mutation.suppressLootNotification == true
        then
            return
        end

        local quantity = normalizeQuantity(mutation.settledQuantity)
        local itemRef = trimText(mutation.itemRef)
        if quantity <= 0 or itemRef == "" then
            return
        end

        local event = {
            itemRef = itemRef,
            itemTier = mutation.itemTier,
            quantity = quantity,
            category = normalizeItemGainCategory(mutation.source),
            eventId = trimText(mutation.eventId),
            playerName = normalizePlayerName(type(Common.GetPlayerName) == "function" and Common.GetPlayerName() or ""),
        }
        if not isSafeEventId(event.eventId) or event.playerName == "" then
            return
        end

        Runtime:QueueAfterCommit(function()
            if event.category == "looted" and trimText(mutation.deliveryId) ~= "" then
                LootNotifications._pendingLootAcquisitions = type(LootNotifications._pendingLootAcquisitions) == "table"
                    and LootNotifications._pendingLootAcquisitions or {}
                local deliveryId = trimText(mutation.deliveryId)
                local pending = LootNotifications._pendingLootAcquisitions[deliveryId]
                if type(pending) ~= "table" then
                    pending = {}
                    LootNotifications._pendingLootAcquisitions[deliveryId] = pending
                end
                pending[#pending + 1] = event
                return
            end
            LootNotifications:HandleCommittedAcquisition(event)
        end)
    end)
end

local function installItemLinkHandler()
    if LootNotifications._itemLinkHandlerInstalled == true or type(SetItemRef) ~= "function" then
        return
    end

    local baseSetItemRef = SetItemRef
    SetItemRef = function(link, text, button, chatFrame, ...)
        local itemRef, itemTier
        if type(link) == "string" then
            itemRef, itemTier = link:match("^rpitem:(.-)%?tier=(normal|heroic|mythic)$")
            if not itemRef then
                itemRef = link:match("^rpitem:(.+)$")
            end
        end
        if itemRef and LootNotifications:ShowItemTooltip(itemRef, chatFrame, itemTier) then
            return
        end
        local achievementRef = type(link) == "string" and link:match("^rpachievement:(.+)$") or nil
        if achievementRef and LootNotifications:ShowAchievementTooltip(achievementRef, chatFrame) then
            return
        end
        return baseSetItemRef(link, text, button, chatFrame, ...)
    end
    LootNotifications._itemLinkHandlerInstalled = true
end

registerItemGainNotifications()
installItemLinkHandler()

return LootNotifications
