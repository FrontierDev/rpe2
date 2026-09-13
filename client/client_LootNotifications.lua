local _, Addon = ...

Addon = Addon or {}
Addon.Client = Addon.Client or {}

local Client = Addon.Client
local Profile = Addon.Internal and Addon.Internal.Profile or {}
local Registry = Addon.Internal and Addon.Internal.Registry or {}
local Runtime = Addon.Internal and Addon.Internal.Runtime or {}
local Common = Addon.Utils and Addon.Utils.Common or {}

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

local function formatItemLink(itemRef, name, quality)
    local reference = trimText(itemRef)
    if reference == "" or reference:find("|", 1, true) then
        return colorItemName(name, quality)
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

function LootNotifications:NotifyItemGain(itemRef, amount)
    local quantity = normalizeQuantity(amount)
    local _, name, quality = resolveItem(itemRef)
    if quantity <= 0 or not name then
        return false
    end

    local body = quantity == 1
        and ITEM_RECEIVED:format(formatItemLink(itemRef, name, quality))
        or ITEM_RECEIVED_MULTIPLE:format(formatItemLink(itemRef, name, quality), quantity)
    local coloredBody = body:gsub("|r", "|r|cff" .. LOOT_TEXT_COLOR)
    local message = ("|cff%s%s|r"):format(
        LOOT_TEXT_COLOR,
        coloredBody
    )
    return emitChatMessage(message)
end

function LootNotifications:ShowItemTooltip(itemRef, owner)
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
        isActive = true,
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

        Runtime:QueueAfterCommit(function()
            LootNotifications:NotifyItemGain(itemRef, quantity)
        end)
    end)
end

local function installItemLinkHandler()
    if LootNotifications._itemLinkHandlerInstalled == true or type(SetItemRef) ~= "function" then
        return
    end

    local baseSetItemRef = SetItemRef
    SetItemRef = function(link, text, button, chatFrame, ...)
        local itemRef = type(link) == "string" and link:match("^rpitem:(.+)$") or nil
        if itemRef and LootNotifications:ShowItemTooltip(itemRef, chatFrame) then
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
