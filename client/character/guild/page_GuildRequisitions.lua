local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Guild = Addon.Client.UI.Guild or {}

local GuildUI = Addon.Client.UI.Guild
local Client = Addon.Client
local UI = Addon.UI or {}
local Registry = Addon.Internal and Addon.Internal.Registry or {}
local Profile = Addon.Internal and Addon.Internal.Profile or {}

local RequisitionsPage = GuildUI.RequisitionsPage or {}
GuildUI.RequisitionsPage = RequisitionsPage
RequisitionsPage.__index = RequisitionsPage

local DEFAULT_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"
local DAILY_REWARD_ICON = "Interface\\Icons\\INV_Misc_Gift_01"
local HEADER_HEIGHT = 42
local DAILY_REWARD_BUTTON_SIZE = HEADER_HEIGHT

local function isEffectivelyVisible(frame)
    if not frame then
        return false
    end

    if type(frame.IsVisible) == "function" then
        return frame:IsVisible() == true
    end

    return type(frame.IsShown) == "function" and frame:IsShown() == true
end

local function text(value)
    if value == nil then
        return ""
    end

    return tostring(value)
end

local function trimText(value)
    return text(value):match("^%s*(.-)%s*$") or ""
end

local function resolveRankName(status)
    local rank = status and status.rank or nil
    local rankName = trimText(rank and rank.name)
    if rankName ~= "" then
        return rankName
    end

    local rankId = trimText(rank and rank.id)
    if rankId ~= "" then
        return rankId
    end

    local assignedRankRef = trimText(status and status.assignedRankRef)
    return assignedRankRef ~= "" and assignedRankRef or "Unavailable"
end

local function normalizeRewardAmount(amount)
    local normalized = tonumber(amount) or 1
    if normalized ~= normalized or normalized == math.huge or normalized == -math.huge then
        return 1
    end

    return math.max(1, math.floor(normalized))
end

local function formatDailyReset(secondsRemaining)
    local seconds = tonumber(secondsRemaining) or 0
    if seconds ~= seconds or seconds == math.huge or seconds == -math.huge then
        seconds = 0
    end

    seconds = math.max(0, math.floor(seconds))
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local remainder = seconds % 60
    return ("Daily Reset in %02d:%02d:%02d"):format(hours, minutes, remainder)
end

local function resolveRewardDisplay(reward)
    local rewardType = trimText(reward and reward.type):lower()
    local ref = trimText(reward and reward.ref)
    local name = rewardType == "currency" and "Unknown currency" or "Unknown item"
    local icon = DEFAULT_ICON

    if rewardType == "currency" then
        local currencyRef = reward and reward.ref or ref
        if type(Profile.NormalizeCurrencyKey) == "function" then
            local normalizeOk, normalizedRef = pcall(Profile.NormalizeCurrencyKey, currencyRef)
            if normalizeOk and trimText(normalizedRef) ~= "" then
                currencyRef = normalizedRef
            end
        end

        if type(Profile.ResolveCurrencyDefinition) == "function" then
            local resolveOk, definition = pcall(Profile.ResolveCurrencyDefinition, currencyRef)
            if resolveOk and type(definition) == "table" and definition.isMissing ~= true then
                name = trimText(definition.name) ~= "" and trimText(definition.name) or name
                icon = trimText(definition.icon) ~= "" and definition.icon or icon
            end
        end

        if name == "Unknown currency" and ref ~= "" then
            name = ref
        end
    else
        local item = nil
        if type(Registry.ResolveItemReference) == "function" then
            local resolveOk, _, resolvedItem = pcall(Registry.ResolveItemReference, Registry, reward and reward.ref or ref)
            if resolveOk and type(resolvedItem) == "table" then
                item = resolvedItem
            end
        end

        if item then
            name = trimText(item.name) ~= "" and trimText(item.name) or name
            icon = trimText(item.icon) ~= "" and item.icon or icon
        end

        if name == "Unknown item" and type(Registry.ResolveItemName) == "function" then
            local resolveOk, resolvedName = pcall(Registry.ResolveItemName, Registry, reward and reward.ref or ref)
            if resolveOk and trimText(resolvedName) ~= "" then
                name = trimText(resolvedName)
            end
        end

        if name == "Unknown item" and ref ~= "" then
            name = ref
        end
    end

    return {
        name = name,
        icon = icon,
        amount = normalizeRewardAmount(reward and reward.amount),
    }
end

function RequisitionsPage:BuildDailyRewardTooltip()
    local spec = {
        type = "custom",
        title = "Daily Rewards",
        lines = {},
    }
    local status = self.DailyRewardStatus
    local rewards = status and status.rewards or nil
    if type(rewards) ~= "table" or #rewards == 0 then
        local rank = status and status.rank or nil
        rewards = rank and rank.dailyRewards or rewards
    end

    if type(rewards) == "table" then
        for index = 1, #rewards do
            local display = resolveRewardDisplay(rewards[index])
            local line = {
                left = display.name,
                right = ("x%d"):format(display.amount),
                colorToken = "text.secondary",
                rightColorToken = "text.primary",
            }
            if type(display.icon) == "number" then
                line.left = ("|T%d:16:16|t %s"):format(display.icon, display.name)
            else
                line.icon = display.icon
            end
            spec.lines[#spec.lines + 1] = line
        end
    end

    return spec
end

function RequisitionsPage:UpdateDailyRewardVisualState()
    if not self.DailyRewardButton then
        return
    end

    local alpha = self:GetDailyRewardVisualAlpha()

    local buttonFrame = self.DailyRewardButton:GetFrame()
    if buttonFrame then
        -- Keep the button enabled and hoverable so its tooltip remains available
        -- after claiming; click handling gates unavailable and pending states.
        if buttonFrame.EnableMouse then
            buttonFrame:EnableMouse(true)
        end
        if buttonFrame.SetAlpha then
            buttonFrame:SetAlpha(alpha)
        end
    end
end

function RequisitionsPage:GetDailyRewardVisualAlpha()
    local status = self.DailyRewardStatus and self.DailyRewardStatus.status or "unavailable"
    if self.DailyRewardPending == true then
        return 0.7
    elseif status == "available-today" then
        return 1
    end

    return 0.5
end

function RequisitionsPage:UpdateResetText(secondsRemaining)
    if self.DailyResetText then
        self.DailyResetText:SetText(formatDailyReset(secondsRemaining))
    end
end

function RequisitionsPage:StopResetTicker()
    self.ResetTicker = nil
    if self.frame and self.frame.SetScript then
        self.frame:SetScript("OnUpdate", nil)
    end
end

function RequisitionsPage:StartResetTicker()
    local visibilityFrame = self.TabPageFrame or self.frame
    if not self.frame or self.ResetTicker or not isEffectivelyVisible(visibilityFrame) then
        return
    end

    local ticker = {
        elapsed = 0,
    }
    self.ResetTicker = ticker
    self.frame:SetScript("OnUpdate", function(_, elapsed)
        if self.ResetTicker ~= ticker then
            return
        end

        ticker.elapsed = ticker.elapsed + (tonumber(elapsed) or 0)
        if ticker.elapsed < 1 then
            return
        end
        ticker.elapsed = ticker.elapsed - 1

        if not isEffectivelyVisible(self.TabPageFrame or self.frame) then
            self:StopResetTicker()
            return
        end

        local Guild = Client.Guild
        local resetState = nil
        if Guild and type(Guild.GetDailyRewardResetState) == "function" then
            local resetCallOk, resolvedResetState = pcall(Guild.GetDailyRewardResetState, Guild)
            if resetCallOk and type(resolvedResetState) == "table" then
                resetState = resolvedResetState
            end
        end

        local cycleKey = resetState and resetState.cycleKey or nil
        if self.ResetCycleKeyInitialized == true and cycleKey ~= self.LastResetCycleKey then
            self:Refresh()
            return
        end

        self:UpdateResetText(resetState and resetState.secondsRemaining or 0)
    end)
end

function RequisitionsPage:TryClaimDailyReward()
    if self.DailyRewardPending == true then
        return false, "pending"
    end

    local status = self.DailyRewardStatus
    if not status or status.status ~= "available-today" then
        return false, status and status.status or "unavailable"
    end

    local Guild = Client.Guild
    if not Guild or type(Guild.TryClaimDailyReward) ~= "function" then
        return false, "claim-api-unavailable"
    end

    self.DailyRewardPending = true
    self:UpdateDailyRewardVisualState()

    local callOk, success, reason, result = pcall(Guild.TryClaimDailyReward, Guild)
    self.DailyRewardPending = false
    self:Refresh()

    if not callOk then
        return false, "claim-failed"
    end

    return success, reason, result
end

function RequisitionsPage:Build(parent, owner)
    self.owner = owner
    if self.frame then
        return self.frame
    end

    self.DailyRewardPending = false
    self.ResetTicker = nil
    self.LastResetCycleKey = nil
    self.ResetCycleKeyInitialized = false
    self.AssignedRankStatus = nil
    self.DailyRewardStatus = nil

    self.frame = CreateFrame("Frame", "RPEGuildRequisitionsPage", parent)
    self.frame:SetAllPoints(parent)

    self.RootLayout = UI.CreateLayout(UI.VerticalLayoutGroup, self.frame, "RPEGuildRequisitionsRootLayout", {
        spacing = 4,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })
    UI.Utils.AnchorFill(self.RootLayout, self.frame, 0, 0, 0, 0)

    self.HeaderLayout = UI.CreateLayout(UI.HorizontalLayoutGroup, self.RootLayout:GetFrame(), "RPEGuildRequisitionsHeaderLayout", {
        height = HEADER_HEIGHT,
        expandWidth = true,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
        spacing = 6,
    })
    self.RootLayout:AddChild(self.HeaderLayout)

    self.DailyRewardButton = UI.ImageButton:New({
        name = "RPEGuildDailyRewardButton",
        width = DAILY_REWARD_BUTTON_SIZE,
        height = DAILY_REWARD_BUTTON_SIZE,
        border = false,
        normalTexture = DAILY_REWARD_ICON,
        highlightTexture = DAILY_REWARD_ICON,
        pushedTexture = DAILY_REWARD_ICON,
        disabledTexture = DAILY_REWARD_ICON,
    })
    self.DailyRewardButton:SetParent(self.HeaderLayout:GetFrame())
    self.DailyRewardTooltip = function()
        return self:BuildDailyRewardTooltip()
    end
    self.DailyRewardButton:SetTooltip(self.DailyRewardTooltip)
    self.DailyRewardButton:SetScript("OnEnter", function(button)
        if button and button.SetAlpha then
            button:SetAlpha(self:GetDailyRewardVisualAlpha())
        end
    end)
    self.DailyRewardButton:SetScript("OnLeave", function(button)
        if button and button.SetAlpha then
            button:SetAlpha(self:GetDailyRewardVisualAlpha())
        end
    end)
    self.DailyRewardButton:SetScript("OnMouseDown", function(button)
        if button and button.SetAlpha then
            button:SetAlpha(self:GetDailyRewardVisualAlpha())
        end
    end)
    self.DailyRewardButton:SetScript("OnMouseUp", function(button)
        if button and button.SetAlpha then
            button:SetAlpha(self:GetDailyRewardVisualAlpha())
        end
    end)
    self.DailyRewardButton:Create()
    self.DailyRewardButton:SetScript("OnClick", function()
        self:TryClaimDailyReward()
    end)
    self.HeaderLayout:AddChild(self.DailyRewardButton)

    self.RankResetLayout = UI.CreateLayout(UI.VerticalLayoutGroup, self.HeaderLayout:GetFrame(), "RPEGuildRankResetLayout", {
        expandWidth = true,
        expandHeight = true,
        weight = 1,
        spacing = 0,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })
    self.HeaderLayout:AddChild(self.RankResetLayout)

    self.GuildRankText = UI.CreateText(self.RankResetLayout:GetFrame(), "RPEGuildRankText", "", {
        height = 20,
        expandWidth = true,
        textColor = UI.ResolveColor(nil, "text.primary"),
    })
    self.RankResetLayout:AddChild(self.GuildRankText)

    self.DailyResetText = UI.CreateText(self.RankResetLayout:GetFrame(), "RPEGuildDailyResetText", "", {
        height = 20,
        expandWidth = true,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.RankResetLayout:AddChild(self.DailyResetText)

    self.MainContentLayout = UI.CreateLayout(UI.HorizontalLayoutGroup, self.RootLayout:GetFrame(), "RPEGuildMainContentLayout", {
        expandWidth = true,
        expandHeight = true,
        weight = 1,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
        spacing = 6,
    })
    self.RootLayout:AddChild(self.MainContentLayout)

    self.GuildShopHost = UI.CreateLayout(UI.VerticalLayoutGroup, self.MainContentLayout:GetFrame(), "RPEGuildShopHost", {
        expandWidth = true,
        expandHeight = true,
        weight = 7,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })
    self.MainContentLayout:AddChild(self.GuildShopHost)

    self.LimitedRequisitionHost = UI.CreateLayout(UI.VerticalLayoutGroup, self.MainContentLayout:GetFrame(), "RPEGuildLimitedRequisitionHost", {
        expandWidth = true,
        expandHeight = true,
        weight = 3,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })
    self.MainContentLayout:AddChild(self.LimitedRequisitionHost)

    self.TabPageFrame = parent
    local contentFrame = parent and parent.GetParent and parent:GetParent() or nil
    self.WindowFrame = contentFrame and contentFrame.GetParent and contentFrame:GetParent() or nil

    if self.TabPageFrame and self.TabPageFrame.HookScript then
        self.TabPageFrame:HookScript("OnShow", function()
            self:StartResetTicker()
        end)
        self.TabPageFrame:HookScript("OnHide", function()
            self:StopResetTicker()
        end)
    end
    if self.WindowFrame and self.WindowFrame.HookScript then
        self.WindowFrame:HookScript("OnShow", function()
            self:StartResetTicker()
        end)
        self.WindowFrame:HookScript("OnHide", function()
            self:StopResetTicker()
        end)
    end
    self.frame:HookScript("OnShow", function()
        self:StartResetTicker()
    end)
    self.frame:HookScript("OnHide", function()
        self:StopResetTicker()
    end)

    self:Refresh()
    return self.frame
end

function RequisitionsPage:Refresh()
    if not self.frame then
        return nil
    end

    local Guild = Client.Guild
    local assignment = {
        status = "unavailable",
    }
    if Guild and type(Guild.GetAssignedGuildRankStatus) == "function" then
        local assignmentCallOk, resolvedAssignment = pcall(Guild.GetAssignedGuildRankStatus, Guild)
        if assignmentCallOk and type(resolvedAssignment) == "table" then
            assignment = resolvedAssignment
        end
    end

    local dailyStatus = {
        status = "unavailable",
        rewards = {},
    }
    if Guild and type(Guild.GetDailyRewardStatus) == "function" then
        local dailyCallOk, resolvedDailyStatus = pcall(Guild.GetDailyRewardStatus, Guild)
        if dailyCallOk and type(resolvedDailyStatus) == "table" then
            dailyStatus = resolvedDailyStatus
        end
    end

    self.AssignedRankStatus = assignment
    self.DailyRewardStatus = dailyStatus
    self.DailyRewardButton:SetTooltip(self.DailyRewardTooltip)
    self.GuildRankText:SetText("Guild Rank: " .. resolveRankName(assignment))
    self:UpdateResetText(dailyStatus.resetState and dailyStatus.resetState.secondsRemaining or 0)
    self:UpdateDailyRewardVisualState()

    self.LastResetCycleKey = dailyStatus.resetState and dailyStatus.resetState.cycleKey or nil
    self.ResetCycleKeyInitialized = true

    if isEffectivelyVisible(self.TabPageFrame or self.frame) then
        self:StartResetTicker()
    end

    return self.frame
end

return RequisitionsPage
