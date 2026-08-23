local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Guild = Addon.Client.UI.Guild or {}

local Client = Addon.Client
local GuildUI = Addon.Client.UI.Guild
local UI = Addon.UI or {}
local Registry = Addon.Internal and Addon.Internal.Registry or {}
local Profile = Addon.Internal and Addon.Internal.Profile or {}

local RequisitionsPage = GuildUI.RequisitionsPage or {}
GuildUI.RequisitionsPage = RequisitionsPage
RequisitionsPage.__index = RequisitionsPage

local function resolveItemName(itemRef)
    if Registry.ResolveItemName then
        return Registry:ResolveItemName(itemRef)
    end

    return tostring(itemRef or "unknown-item")
end

local function resolveCurrencyName(currencyRef)
    if Profile.ResolveCurrencyDefinition then
        local definition = Profile.ResolveCurrencyDefinition(currencyRef)
        if definition and tostring(definition.name or "") ~= "" then
            return tostring(definition.name)
        end
    end

    return tostring(currencyRef or "unknown-currency")
end

local function describeResolution(resolution)
    if not resolution or resolution.inGuild ~= true then
        return "Join a guild to view its read-only Guild Setting."
    end

    if resolution.conflict then
        local labels = {}
        for index = 1, #(resolution.matches or {}) do
            local match = resolution.matches[index]
            labels[#labels + 1] = ("%s:%s"):format(
                tostring(match and match.datasetName or "dataset"),
                tostring(match and match.settingName or "Guild Setting")
            )
        end
        return "Conflict: multiple Guild Settings match this guild. " .. table.concat(labels, ", ")
    end

    if not resolution.setting then
        if resolution.reason == "guild-loading" then
            return "Guild information is still loading."
        end
        return "No active Guild Setting matches this guild."
    end

    local match = resolution.match or {}
    local source = tostring(match.datasetName or match.datasetId or "dataset")
    return ("%s (%s, read-only)"):format(tostring(match.settingName or "Guild Setting"), source)
end

function RequisitionsPage:Build(parent, owner)
    self.owner = owner
    if self.frame then
        return self.frame
    end

    self.frame = CreateFrame("Frame", "RPEGuildRequisitionsPage", parent)
    self.frame:SetAllPoints(parent)

    self.RootLayout = UI.CreateLayout(UI.VerticalLayoutGroup, self.frame, "RPEGuildRequisitionsRootLayout", {
        spacing = 4,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })
    UI.Utils.AnchorFill(self.RootLayout, self.frame, 0, 0, 0, 0)

    self.StatusText = UI.CreateText(self.RootLayout:GetFrame(), "RPEGuildRequisitionsStatusText", "", {
        width = 520,
        height = 30,
        justifyH = "LEFT",
        wordWrap = true,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.RootLayout:AddChild(self.StatusText)

    self.DailyPanel = UI.CreatePanel(self.RootLayout:GetFrame(), "RPEGuildDailyRewardsPanel", {
        width = 520,
        height = 126,
        expandWidth = true,
        contentInset = 2,
        showBorder = false,
    })
    self.RootLayout:AddChild(self.DailyPanel)
    self.DailyTitle = UI.CreateText(self.DailyPanel:GetContentFrame(), "RPEGuildDailyRewardsTitle", "Daily Rewards", {
        width = 512,
        height = 18,
        textColor = UI.ResolveColor(nil, "text.primary"),
    })
    self.DailyList = UI.ScrollLayout:New({
        name = "RPEGuildDailyRewardsList",
        width = 512,
        height = 96,
        visibleRows = 4,
        rowHeight = 22,
        rowSpacing = 1,
        border = false,
        rowElementClass = UI.ScrollListEntry,
        categoryWidth = 72,
        statusWidth = 62,
        categoryInsetLeft = 4,
        statusInsetRight = 4,
    })
    self.DailyList:SetParent(self.DailyPanel:GetContentFrame())
    self.DailyList:SetRowRenderer(function(row, reward)
        local rewardType = tostring(reward and reward.type or "item")
        local ref = tostring(reward and reward.ref or "")
        local label = rewardType == "currency" and resolveCurrencyName(ref) or resolveItemName(ref)
        row:SetCategory(rewardType == "currency" and "Currency" or "Item")
        row:SetTestName(("%s x%d"):format(label, tonumber(reward and reward.amount) or 1))
        row:SetStatus("View")
        row:SetDetail(ref)
    end)
    self.DailyList:Create()
    UI.Utils.AnchorFill(self.DailyList, self.DailyPanel:GetContentFrame(), 0, 20, 0, 0)
    self.DailyEmptyText = UI.CreateText(self.DailyPanel:GetContentFrame(), "RPEGuildDailyRewardsEmptyText", "", {
        width = 300,
        height = 30,
        justifyH = "CENTER",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.DailyEmptyText:GetFrame():SetPoint("CENTER", self.DailyPanel:GetContentFrame(), "CENTER", 0, -10)

    self.RequisitionPanel = UI.CreatePanel(self.RootLayout:GetFrame(), "RPEGuildRequisitionsPanel", {
        width = 520,
        height = 190,
        expandWidth = true,
        expandHeight = true,
        weight = 1,
        contentInset = 2,
        showBorder = false,
    })
    self.RootLayout:AddChild(self.RequisitionPanel)
    self.RequisitionTitle = UI.CreateText(self.RequisitionPanel:GetContentFrame(), "RPEGuildRequisitionsTitle", "Requisitions", {
        width = 512,
        height = 18,
        textColor = UI.ResolveColor(nil, "text.primary"),
    })
    self.RequisitionList = UI.ScrollLayout:New({
        name = "RPEGuildRequisitionList",
        width = 512,
        height = 160,
        visibleRows = 7,
        rowHeight = 28,
        rowSpacing = 1,
        border = false,
        rowElementClass = UI.ScrollListEntry,
        categoryWidth = 82,
        statusWidth = 62,
        categoryInsetLeft = 4,
        statusInsetRight = 4,
        rowWordWrap = true,
    })
    self.RequisitionList:SetParent(self.RequisitionPanel:GetContentFrame())
    self.RequisitionList:SetRowRenderer(function(row, requisition)
        local ref = tostring(requisition and requisition.itemRef or "")
        local label = resolveItemName(ref)
        local details = { ref }
        local costs = requisition and requisition.costs or {}
        if #costs > 0 then
            local costLabels = {}
            for index = 1, #costs do
                local cost = costs[index]
                costLabels[#costLabels + 1] = ("%s x%d"):format(
                    resolveCurrencyName(cost and cost.currencyRef),
                    tonumber(cost and cost.amount) or 0
                )
            end
            details[#details + 1] = "Cost: " .. table.concat(costLabels, ", ")
        end
        if requisition and requisition.requiredGuildRankIndex ~= nil then
            details[#details + 1] = "Minimum guild rank index: " .. tostring(requisition.requiredGuildRankIndex)
        end
        row:SetCategory(tostring(requisition and requisition.id or "Requisition"))
        row:SetTestName(("%s x%d"):format(label, tonumber(requisition and requisition.quantity) or 1))
        row:SetStatus("View")
        row:SetDetail(table.concat(details, "\n"))
    end)
    self.RequisitionList:Create()
    UI.Utils.AnchorFill(self.RequisitionList, self.RequisitionPanel:GetContentFrame(), 0, 20, 0, 0)
    self.RequisitionEmptyText = UI.CreateText(self.RequisitionPanel:GetContentFrame(), "RPEGuildRequisitionsEmptyText", "", {
        width = 300,
        height = 30,
        justifyH = "CENTER",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.RequisitionEmptyText:GetFrame():SetPoint("CENTER", self.RequisitionPanel:GetContentFrame(), "CENTER", 0, 0)

    self:Refresh()
    return self.frame
end

function RequisitionsPage:Refresh()
    if not self.frame then
        return nil
    end

    local setting, resolution
    if Client.Guild and Client.Guild.GetActiveGuildSetting then
        setting, resolution = Client.Guild:GetActiveGuildSetting()
    end

    self.StatusText:SetText(describeResolution(resolution))
    local hasSetting = setting ~= nil and resolution and resolution.conflict ~= true
    local dailyRewards = hasSetting and setting.dailyRewards or {}
    local requisitions = hasSetting and setting.requisitions or {}
    self.DailyList:SetItems(dailyRewards or {})
    self.RequisitionList:SetItems(requisitions or {})
    self.DailyEmptyText:SetText(not hasSetting and "No active Guild Setting." or (#dailyRewards == 0 and "No daily rewards configured." or ""))
    self.RequisitionEmptyText:SetText(not hasSetting and "No active Guild Setting." or (#requisitions == 0 and "No requisitions configured." or ""))
    return self.frame
end

return RequisitionsPage
