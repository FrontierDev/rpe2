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
local SHOP_COLUMNS = 2
local SHOP_ROWS = 7
local SHOP_ENTRIES_PER_PAGE = SHOP_COLUMNS * SHOP_ROWS
local SHOP_ENTRY_HEIGHT = 34
local SHOP_GRID_SPACING_X = 6
local SHOP_GRID_SPACING_Y = 4
local SHOP_PAGE_NAV_HEIGHT = 18

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

local function normalizeNonNegativeInteger(value, defaultValue)
    local numeric = tonumber(value)
    if not numeric or numeric ~= numeric or numeric == math.huge or numeric == -math.huge then
        return defaultValue or 0
    end

    return math.max(0, math.floor(numeric))
end

local function normalizeCharacterLimit(value)
    local numeric = tonumber(value)
    if not numeric or numeric ~= numeric or numeric == math.huge or numeric == -math.huge then
        return 1
    end

    if numeric == 0 then
        return 0
    end

    return math.max(1, math.floor(numeric))
end

local function resolveCurrencyDisplayName(currencyRef)
    local normalizedRef = trimText(currencyRef)
    if type(Profile.NormalizeCurrencyKey) == "function" then
        local normalizeCallOk, resolvedRef = pcall(Profile.NormalizeCurrencyKey, currencyRef)
        if normalizeCallOk and trimText(resolvedRef) ~= "" then
            normalizedRef = trimText(resolvedRef)
        end
    end

    if type(Profile.ResolveCurrencyDefinition) == "function" then
        local resolveCallOk, definition = pcall(Profile.ResolveCurrencyDefinition, normalizedRef)
        if resolveCallOk and type(definition) == "table" and definition.isMissing ~= true then
            local name = trimText(definition.name)
            if name ~= "" then
                return name
            end
        end
    end

    return normalizedRef ~= "" and normalizedRef or "Unknown currency"
end

local function formatCompactCost(costs)
    if type(costs) ~= "table" then
        return ""
    end

    local labels = {}
    for index = 1, #costs do
        local cost = type(costs[index]) == "table" and costs[index] or {}
        local amount = normalizeNonNegativeInteger(cost.amount, 0)
        labels[#labels + 1] = ("%d %s"):format(amount, resolveCurrencyDisplayName(cost.currencyRef))
    end

    return table.concat(labels, ", ")
end

local function resolveShopItemDisplay(requisition)
    local itemRef = trimText(requisition and requisition.itemRef)
    local itemName = "Unknown item"
    local itemIcon = DEFAULT_ICON
    local resolvedItem = nil

    if type(Registry.ResolveItemReference) == "function" then
        local resolveCallOk, _, item = pcall(
            Registry.ResolveItemReference,
            Registry,
            requisition and requisition.itemRef or itemRef
        )
        if resolveCallOk and type(item) == "table" then
            resolvedItem = item
            local resolvedName = trimText(item.name)
            if resolvedName ~= "" then
                itemName = resolvedName
            end

            local hasIcon = (type(item.icon) == "number" and item.icon > 0)
                or (type(item.icon) == "string" and trimText(item.icon) ~= "")
            if hasIcon then
                itemIcon = item.icon
            end
        end
    end

    if itemName == "Unknown item" and type(Registry.ResolveItemName) == "function" then
        local resolveCallOk, resolvedName = pcall(
            Registry.ResolveItemName,
            Registry,
            requisition and requisition.itemRef or itemRef
        )
        if resolveCallOk and trimText(resolvedName) ~= "" then
            itemName = trimText(resolvedName)
        end
    end

    if itemName == "Unknown item" and itemRef ~= "" then
        itemName = itemRef
    end

    return {
        item = resolvedItem,
        itemRef = itemRef,
        name = itemName,
        icon = itemIcon,
    }
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

function RequisitionsPage:FormatCompactCost(costs)
    return formatCompactCost(costs)
end

function RequisitionsPage:GetShopPageCount(totalRows)
    local total = math.max(0, math.floor(tonumber(totalRows) or 0))
    if total == 0 then
        return 0
    end

    return math.ceil(total / SHOP_ENTRIES_PER_PAGE)
end

function RequisitionsPage:GetShopPageRows(rows, page)
    local pageRows = {}
    local sourceRows = type(rows) == "table" and rows or {}
    local pageNumber = math.max(1, math.floor(tonumber(page) or 1))
    local firstIndex = ((pageNumber - 1) * SHOP_ENTRIES_PER_PAGE) + 1
    local lastIndex = math.min(#sourceRows, firstIndex + SHOP_ENTRIES_PER_PAGE - 1)

    for index = firstIndex, lastIndex do
        pageRows[#pageRows + 1] = sourceRows[index]
    end

    return pageRows
end

function RequisitionsPage:ClampShopPage(page, pageCount)
    local currentPage = math.max(1, math.floor(tonumber(page) or 1))
    local totalPages = math.max(0, math.floor(tonumber(pageCount) or 0))
    if totalPages == 0 then
        return 1
    end

    return math.min(currentPage, totalPages)
end

function RequisitionsPage:RefreshShopPageControls(totalRows, pageCount)
    if not self.ShopPageText or not self.ShopPreviousButton or not self.ShopNextButton then
        return
    end

    local total = math.max(0, math.floor(tonumber(totalRows) or 0))
    local totalPages = math.max(0, math.floor(tonumber(pageCount) or 0))
    if totalPages == 0 or total == 0 then
        self.ShopPageText:SetText("Page 0 / 0")
        self.ShopPreviousButton:SetEnabled(false)
        self.ShopNextButton:SetEnabled(false)
        return
    end

    self.ShopPageText:SetText(("Page %d / %d"):format(self.CurrentShopPage, totalPages))
    self.ShopPreviousButton:SetEnabled(self.CurrentShopPage > 1)
    self.ShopNextButton:SetEnabled(self.CurrentShopPage < totalPages)
end

function RequisitionsPage:RefreshShopEntryMetrics()
    if not self.ShopEntries then
        return
    end

    for index = 1, SHOP_ENTRIES_PER_PAGE do
        local entry = self.ShopEntries[index]
        local entryFrame = entry and entry.GetFrame and entry:GetFrame() or nil
        if entryFrame then
            local width = tonumber(entryFrame:GetWidth()) or 0
            if width > 0 then
                entry:SetLayoutMetrics(width, SHOP_ENTRY_HEIGHT)
            end
        end
    end
end

function RequisitionsPage:PartitionRequisitions(assignment)
    local shopRows = {}
    local limitedRows = {}

    if type(assignment) ~= "table"
        or assignment.status ~= "valid"
        or type(assignment.rank) ~= "table"
        or trimText(assignment.assignedRankRef) == ""
    then
        return shopRows, limitedRows
    end

    local requisitions = assignment.rank.requisitions
    if type(requisitions) ~= "table" then
        return shopRows, limitedRows
    end

    for index = 1, #requisitions do
        local requisition = requisitions[index]
        if type(requisition) == "table" then
            if normalizeCharacterLimit(requisition.characterLimit) == 0 then
                shopRows[#shopRows + 1] = requisition
            else
                limitedRows[#limitedRows + 1] = requisition
            end
        end
    end

    return shopRows, limitedRows
end

function RequisitionsPage:GetShopRequisitions(assignment)
    local shopRows = self:PartitionRequisitions(assignment)
    return shopRows
end

function RequisitionsPage:GetLimitedRequisitions(assignment)
    local _, limitedRows = self:PartitionRequisitions(assignment)
    return limitedRows
end

function RequisitionsPage:GetShopEligibility(requisition)
    local Guild = Client.Guild
    local assignment = self.AssignedRankStatus
    if not Guild
        or type(Guild.GetRequisitionEligibility) ~= "function"
        or type(assignment) ~= "table"
        or assignment.status ~= "valid"
    then
        return false, "eligibility-unavailable"
    end

    local callOk, eligible, reason, detail = pcall(
        Guild.GetRequisitionEligibility,
        Guild,
        assignment.assignedRankRef,
        requisition and requisition.id
    )
    if not callOk then
        return false, "eligibility-failed"
    end

    return eligible == true, reason, detail
end

function RequisitionsPage:BindShopEntry(entry, requisition)
    local itemDisplay = resolveShopItemDisplay(requisition)
    local costText = self:FormatCompactCost(requisition and requisition.costs)
    local eligible, reason, detail = self:GetShopEligibility(requisition)

    entry:SetOption("keepMouseEnabled", true)
    entry.resolvedRequisition = requisition
    entry.resolvedItem = itemDisplay.item
    entry.resolvedItemRef = itemDisplay.itemRef
    entry.resolvedItemName = itemDisplay.name
    entry.resolvedCostText = costText
    entry.resolvedEligibility = eligible
    entry.resolvedEligibilityReason = reason
    entry.resolvedEligibilityDetail = detail

    entry:SetIcon(itemDisplay.icon)
    entry:SetItemName(itemDisplay.name)
    entry:SetCostText(costText)
    entry:SetEnabled(eligible)
    entry:SetTooltip(function()
        local currentName = entry.resolvedItemName or "Unknown item"
        local currentCost = entry.resolvedCostText
        return {
            type = "custom",
            title = currentName,
            lines = {
                {
                    left = currentName,
                    colorToken = "text.primary",
                },
                {
                    left = currentCost ~= "" and currentCost or "No cost",
                    colorToken = "text.secondary",
                },
            },
        }
    end)
    entry:Show()
end

function RequisitionsPage:EnsureRequisitionClickHandler(entry)
    if not entry or entry._guildRequisitionClickBound == true then
        return
    end

    local entryFrame = entry.GetFrame and entry:GetFrame() or nil
    if not entryFrame or not entryFrame.HookScript then
        return
    end

    entryFrame:HookScript("OnMouseUp", function(_, button)
        if button == "LeftButton" then
            self:TryShopRequisition(entry)
        end
    end)
    entry._guildRequisitionClickBound = true
end

function RequisitionsPage:BindLimitedRequisitionEntry(entry, requisition)
    self:BindShopEntry(entry, requisition)
    self:EnsureRequisitionClickHandler(entry)

    local entryFrame = entry and entry.GetFrame and entry:GetFrame() or nil
    local width = entryFrame and tonumber(entryFrame:GetWidth()) or 0
    if width <= 0 and self.LimitedRequisitionList then
        local listFrame = self.LimitedRequisitionList:GetFrame()
        width = listFrame and tonumber(listFrame:GetWidth()) or 0
    end
    if width > 0 then
        entry:SetLayoutMetrics(width, SHOP_ENTRY_HEIGHT)
    end
end

function RequisitionsPage:HideShopEntry(entry)
    if not entry then
        return
    end

    entry.resolvedRequisition = nil
    entry.resolvedItem = nil
    entry.resolvedItemRef = nil
    entry.resolvedItemName = nil
    entry.resolvedCostText = nil
    entry.resolvedEligibility = false
    entry.resolvedEligibilityReason = nil
    entry.resolvedEligibilityDetail = nil
    entry:SetTooltip(nil)
    entry:SetIcon(DEFAULT_ICON)
    entry:SetItemName("")
    entry:SetCostText("")
    entry:SetEnabled(false)
    entry:Hide()
end

function RequisitionsPage:RefreshShopEntries()
    if not self.ShopEntries then
        return
    end

    local rows = type(self.ShopItems) == "table" and self.ShopItems or {}
    local pageCount = self:GetShopPageCount(#rows)
    self.CurrentShopPage = self:ClampShopPage(self.CurrentShopPage, pageCount)
    local pageRows = self:GetShopPageRows(rows, self.CurrentShopPage)

    self:RefreshShopPageControls(#rows, pageCount)
    for index = 1, SHOP_ENTRIES_PER_PAGE do
        local entry = self.ShopEntries[index]
        local requisition = pageRows[index]
        if requisition then
            self:BindShopEntry(entry, requisition)
        else
            self:HideShopEntry(entry)
        end
    end

    if self.ShopGrid then
        self.ShopGrid:RefreshLayout()
    end
    self:RefreshShopEntryMetrics()
end

function RequisitionsPage:PreviousShopPage()
    if self.CurrentShopPage <= 1 then
        return
    end

    self.CurrentShopPage = self.CurrentShopPage - 1
    self:RefreshShopEntries()
end

function RequisitionsPage:NextShopPage()
    local pageCount = self:GetShopPageCount(self.ShopItems and #self.ShopItems or 0)
    if self.CurrentShopPage >= pageCount then
        return
    end

    self.CurrentShopPage = self.CurrentShopPage + 1
    self:RefreshShopEntries()
end

function RequisitionsPage:TryShopRequisition(entry)
    local requisition = entry and entry.resolvedRequisition or nil
    local Guild = Client.Guild
    local assignment = self.AssignedRankStatus
    if not requisition
        or not Guild
        or type(Guild.TryRequisition) ~= "function"
        or type(assignment) ~= "table"
    then
        return false, "requisition-unavailable"
    end

    local callOk, success, reason, detail = pcall(
        Guild.TryRequisition,
        Guild,
        assignment.assignedRankRef,
        requisition.id
    )
    self:Refresh()

    if not callOk then
        return false, "transaction-failed"
    end

    return success, reason, detail
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
    self.CurrentShopPage = 1
    self.ShopItems = {}
    self.ShopEntries = {}
    self.LimitedRequisitions = {}

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

    self.ShopLayout = UI.CreateLayout(UI.VerticalLayoutGroup, self.GuildShopHost:GetFrame(), "RPEGuildShopLayout", {
        expandWidth = true,
        expandHeight = true,
        weight = 1,
        spacing = 4,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })
    self.GuildShopHost:AddChild(self.ShopLayout)

    self.ShopGrid = UI.CreateLayout(UI.GridLayoutGroup, self.ShopLayout:GetFrame(), "RPEGuildShopGrid", {
        columns = SHOP_COLUMNS,
        spacingX = SHOP_GRID_SPACING_X,
        spacingY = SHOP_GRID_SPACING_Y,
        cellHeight = SHOP_ENTRY_HEIGHT,
        expandWidth = true,
        expandHeight = true,
        weight = 1,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    self.ShopLayout:AddChild(self.ShopGrid)

    self.ShopPaginationLayout = UI.CreateLayout(
        UI.HorizontalLayoutGroup,
        self.ShopLayout:GetFrame(),
        "RPEGuildShopPaginationLayout",
        {
            height = SHOP_PAGE_NAV_HEIGHT,
            expandWidth = true,
            fitChildrenWidth = false,
            fitChildrenHeight = false,
            spacing = 4,
        }
    )
    self.ShopLayout:AddChild(self.ShopPaginationLayout)

    self.ShopPreviousButton = UI.TextButton:New({
        name = "RPEGuildShopPreviousButton",
        width = 22,
        height = SHOP_PAGE_NAV_HEIGHT,
        text = "<",
        fontSize = 11,
        border = false,
        expandWidth = false,
    })
    self.ShopPreviousButton:SetParent(self.ShopPaginationLayout:GetFrame())
    self.ShopPreviousButton:Create()
    self.ShopPreviousButton:SetScript("OnClick", function()
        self:PreviousShopPage()
    end)
    self.ShopPaginationLayout:AddChild(self.ShopPreviousButton)

    self.ShopPageText = UI.CreateText(self.ShopPaginationLayout:GetFrame(), "RPEGuildShopPageText", "Page 0 / 0", {
        width = 96,
        height = SHOP_PAGE_NAV_HEIGHT,
        justifyH = "CENTER",
        expandWidth = false,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.ShopPaginationLayout:AddChild(self.ShopPageText)

    self.ShopNextButton = UI.TextButton:New({
        name = "RPEGuildShopNextButton",
        width = 22,
        height = SHOP_PAGE_NAV_HEIGHT,
        text = ">",
        fontSize = 11,
        border = false,
        expandWidth = false,
    })
    self.ShopNextButton:SetParent(self.ShopPaginationLayout:GetFrame())
    self.ShopNextButton:Create()
    self.ShopNextButton:SetScript("OnClick", function()
        self:NextShopPage()
    end)
    self.ShopPaginationLayout:AddChild(self.ShopNextButton)

    for index = 1, SHOP_ENTRIES_PER_PAGE do
        local entry = UI.ShopEntry:New({
            name = ("RPEGuildShopEntry%d"):format(index),
            width = 160,
            height = SHOP_ENTRY_HEIGHT,
            expandHeight = false,
            keepMouseEnabled = true,
        })
        entry:SetParent(self.ShopGrid:GetFrame())
        entry:Create()
        self:EnsureRequisitionClickHandler(entry)
        self.ShopGrid:AddChild(entry)
        self.ShopEntries[index] = entry
    end

    self.ShopGrid:GetFrame():HookScript("OnSizeChanged", function()
        self:RefreshShopEntryMetrics()
    end)

    self.LimitedRequisitionHost = UI.CreateLayout(UI.VerticalLayoutGroup, self.MainContentLayout:GetFrame(), "RPEGuildLimitedRequisitionHost", {
        expandWidth = true,
        expandHeight = true,
        weight = 3,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })
    self.MainContentLayout:AddChild(self.LimitedRequisitionHost)

    self.LimitedRequisitionList = UI.ScrollLayout:New({
        name = "RPEGuildLimitedRequisitionList",
        rowElementClass = UI.ShopEntry,
        rowWidth = 160,
        rowHeight = SHOP_ENTRY_HEIGHT,
        rowSpacing = SHOP_GRID_SPACING_Y,
        autoFitRows = true,
        minVisibleRows = 1,
        expandWidth = true,
        expandHeight = true,
        weight = 1,
        border = false,
    })
    self.LimitedRequisitionList:SetParent(self.LimitedRequisitionHost:GetFrame())
    self.LimitedRequisitionList:SetRowRenderer(function(row, requisition)
        self:BindLimitedRequisitionEntry(row, requisition)
    end)
    self.LimitedRequisitionList:Create()
    self.LimitedRequisitionHost:AddChild(self.LimitedRequisitionList)

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
    self.ShopItems, self.LimitedRequisitions = self:PartitionRequisitions(assignment)
    self:RefreshShopEntries()
    self.LimitedRequisitionList:SetItems(self.LimitedRequisitions)

    self.LastResetCycleKey = dailyStatus.resetState and dailyStatus.resetState.cycleKey or nil
    self.ResetCycleKeyInitialized = true

    if isEffectivelyVisible(self.TabPageFrame or self.frame) then
        self:StartResetTicker()
    end

    return self.frame
end

return RequisitionsPage
