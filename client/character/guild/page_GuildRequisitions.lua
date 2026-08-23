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

local function setSelectedRow(row, selected)
    if not row or not row.entryBackground or not row.entryBackground.SetColorTexture then
        return
    end

    local color = UI.ResolveColor(nil, selected and "list.rowHover" or "list.rowBackground")
    row.entryBackground:SetColorTexture(color.r or 0, color.g or 0, color.b or 0, color.a or 1)
end

local function describeEligibilityFailure(reason, detail)
    reason = tostring(reason or "unavailable")
    if reason == "not-in-guild" then
        return "Not in a guild"
    elseif reason == "guild-loading" then
        return "Guild information is still loading"
    elseif reason == "no-assigned-rank" then
        return "No RPE Guild Rank assigned"
    elseif reason == "invalid-assigned-rank" then
        return "Assigned RPE Guild Rank is no longer valid"
    elseif reason == "rank-mismatch" then
        return "This requisition is not in the assigned RPE Guild Rank"
    elseif reason == "requisitions-disabled" then
        return "Requisitions disabled for this Guild Rank"
    elseif reason == "requisition-unavailable" then
        return "Requisition unavailable"
    elseif reason == "item-unavailable" then
        return "Item unavailable"
    elseif reason == "character-limit-reached" then
        return "Character limit reached"
    elseif reason == "insufficient-currency" then
        return "Insufficient " .. resolveCurrencyName(detail and detail.currencyRef)
    elseif reason == "currency-unavailable" or reason == "currency-api-unavailable" then
        return "Currency unavailable"
    elseif reason == "inventory-unavailable" or reason == "inventory-award-failed" then
        return "Inventory award unavailable"
    elseif reason == "ledger-unavailable" or reason == "ledger-update-failed" then
        return "Requisition usage could not be recorded"
    end

    return "Requisition unavailable"
end

local function describeDailyStatus(status)
    status = tostring(status or "unavailable")
    if status == "not-in-guild" then
        return "Not eligible: not in a guild"
    elseif status == "guild-loading" then
        return "Not eligible: guild information is still loading"
    elseif status == "no-assigned-rank" then
        return "Not eligible: no RPE Guild Rank assigned"
    elseif status == "invalid-assigned-rank" then
        return "Not eligible: assigned RPE Guild Rank is no longer valid"
    elseif status == "daily-rewards-disabled" then
        return "Daily rewards disabled"
    elseif status == "available-today" then
        return "Available today"
    elseif status == "received-today" then
        return "Received today"
    elseif status == "transaction-recovery-required" then
        return "Daily reward transaction requires recovery"
    elseif status == "invalid-reward-definition"
        or status == "item-unavailable"
        or status == "currency-unavailable" then
        return "Daily rewards unavailable"
    end

    return "Daily rewards unavailable"
end

function RequisitionsPage:Build(parent, owner)
    self.owner = owner
    if self.frame then
        return self.frame
    end

    self.SelectedRequisitionIndex = nil
    self.SelectedRequisitionItems = {}
    self.RequisitionActionMessage = nil
    self.RequisitionPending = false
    self.DailyRewardStateLabel = "Info"

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
        row:SetStatus(self.DailyRewardStateLabel or "Info")
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
    self.RequisitionList:SetRowRenderer(function(row, requisition, requisitionIndex)
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
        row:SetCategory(tostring(requisition and requisition.id or "Requisition"))
        row:SetTestName(("%s x%d"):format(label, tonumber(requisition and requisition.quantity) or 1))
        row:SetStatus(tonumber(self.SelectedRequisitionIndex) == tonumber(requisitionIndex) and "Selected" or "Select")
        row:SetDetail(table.concat(details, "\n"))

        local frame = row.GetFrame and row:GetFrame() or nil
        if frame then
            frame:EnableMouse(true)
            frame:SetScript("OnMouseUp", function(_, button)
                if button == "LeftButton" then
                    self.SelectedRequisitionIndex = requisitionIndex
                    self.RequisitionActionMessage = nil
                    self:Refresh()
                end
            end)
            setSelectedRow(row, tonumber(self.SelectedRequisitionIndex) == tonumber(requisitionIndex))
        end
    end)
    self.RequisitionList:Create()
    UI.Utils.AnchorFill(self.RequisitionList, self.RequisitionPanel:GetContentFrame(), 0, 20, 0, 30)
    self.RequisitionEmptyText = UI.CreateText(self.RequisitionPanel:GetContentFrame(), "RPEGuildRequisitionsEmptyText", "", {
        width = 300,
        height = 30,
        justifyH = "CENTER",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.RequisitionEmptyText:GetFrame():SetPoint("CENTER", self.RequisitionPanel:GetContentFrame(), "CENTER", 0, 0)

    self.RequisitionButton = UI.CreateButton(self.RequisitionPanel:GetContentFrame(), "RPEGuildRequisitionActionButton", "Requisition", 96, function()
        self:TrySelectedRequisition()
    end, {
        height = 22,
        fontSize = 8,
    })
    self.RequisitionButton:GetFrame():SetPoint("BOTTOMLEFT", self.RequisitionPanel:GetContentFrame(), "BOTTOMLEFT", 4, 2)
    self.RequisitionActionStatus = UI.CreateText(self.RequisitionPanel:GetContentFrame(), "RPEGuildRequisitionActionStatus", "", {
        width = 402,
        height = 24,
        justifyH = "LEFT",
        wordWrap = true,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.RequisitionActionStatus:GetFrame():SetPoint("BOTTOMLEFT", self.RequisitionPanel:GetContentFrame(), "BOTTOMLEFT", 108, 1)

    self:Refresh()
    return self.frame
end

function RequisitionsPage:TrySelectedRequisition()
    if self.RequisitionPending == true then
        return false, "pending"
    end

    local Guild = Client.Guild
    local index = tonumber(self.SelectedRequisitionIndex)
    local requisition = index and self.SelectedRequisitionItems[index] or nil
    if not Guild or type(Guild.TryRequisition) ~= "function" or not requisition then
        return false, "requisition-unavailable"
    end

    local assignment = type(Guild.GetAssignedGuildRankStatus) == "function"
        and Guild:GetAssignedGuildRankStatus()
        or nil
    if not assignment or assignment.status ~= "valid" then
        self.RequisitionActionMessage = describeEligibilityFailure(
            assignment and assignment.status or "invalid-assigned-rank"
        )
        self:Refresh()
        return false, assignment and assignment.status or "invalid-assigned-rank"
    end

    self.RequisitionPending = true
    self.RequisitionActionMessage = "Requisition pending..."
    self:Refresh()

    local success, reason, result = Guild:TryRequisition(assignment.assignedRankRef, requisition.id)
    self.RequisitionPending = false
    if success then
        self.RequisitionActionMessage = ("Requisition succeeded: %s x%d."):format(
            resolveItemName(result and result.itemRef or requisition.itemRef),
            tonumber(result and result.quantity or requisition.quantity) or 1
        )
    else
        self.RequisitionActionMessage = describeEligibilityFailure(reason, result)
    end
    self:Refresh()
    return success, reason, result
end

function RequisitionsPage:Refresh()
    if not self.frame then
        return nil
    end

    local assignment, assignmentText
    if self.owner and self.owner.GetAssignedGuildRankDisplay then
        assignment, assignmentText = self.owner:GetAssignedGuildRankDisplay()
    end

    local Guild = Client.Guild
    local dailyStatus = Guild and type(Guild.GetDailyRewardStatus) == "function"
        and Guild:GetDailyRewardStatus()
        or { status = "unavailable", rewards = {} }
    local dailyStateText = describeDailyStatus(dailyStatus.status)
    if dailyStatus.status == "available-today" then
        self.DailyRewardStateLabel = "Available"
    elseif dailyStatus.status == "received-today" then
        self.DailyRewardStateLabel = "Received"
    elseif dailyStatus.status == "daily-rewards-disabled" then
        self.DailyRewardStateLabel = "Disabled"
    else
        self.DailyRewardStateLabel = "Info"
    end

    local assignedRank = assignment and assignment.status == "valid" and assignment.rank or nil
    local hasAssignedRank = assignedRank ~= nil
    self.StatusText:SetText(hasAssignedRank
        and (assignmentText .. ". " .. dailyStateText .. ". Daily Rewards are shown below; Requisitions can be claimed below.")
        or (assignmentText or "Guild Rank: Unavailable"))
    local dailyRewards = hasAssignedRank
        and (dailyStatus.rewards or assignedRank.dailyRewards)
        or {}
    local requisitions = hasAssignedRank and assignedRank.requisitions or {}
    self.SelectedRequisitionItems = requisitions or {}
    if not self.SelectedRequisitionIndex
        or self.SelectedRequisitionIndex < 1
        or self.SelectedRequisitionIndex > #self.SelectedRequisitionItems then
        self.SelectedRequisitionIndex = nil
    end
    self.DailyList:SetItems(dailyRewards or {})
    self.RequisitionList:SetItems(requisitions or {})
    self.DailyEmptyText:SetText(not hasAssignedRank and dailyStateText
        or (#dailyRewards == 0 and (dailyStateText .. "; no rewards configured.") or ""))
    self.RequisitionEmptyText:SetText(not hasAssignedRank and (assignmentText or "Guild Rank unavailable.")
        or (#requisitions == 0 and "No requisitions configured." or ""))

    local selectedRequisition = self.SelectedRequisitionIndex
        and self.SelectedRequisitionItems[self.SelectedRequisitionIndex]
        or nil
    local eligible = false
    local reason = nil
    local detail = nil
    if selectedRequisition and hasAssignedRank then
        local Guild = Client.Guild
        if Guild and type(Guild.GetRequisitionEligibility) == "function" then
            eligible, reason, detail = Guild:GetRequisitionEligibility(
                assignment.assignedRankRef,
                selectedRequisition.id
            )
        else
            reason = "inventory-unavailable"
        end
    elseif not hasAssignedRank then
        reason = assignment and assignment.status or "invalid-assigned-rank"
    elseif #self.SelectedRequisitionItems == 0 then
        reason = "requisition-unavailable"
    else
        reason = "select-requisition"
    end

    if self.RequisitionButton then
        self.RequisitionButton:SetEnabled(eligible == true and self.RequisitionPending ~= true)
    end
    if self.RequisitionActionStatus then
        local actionMessage = self.RequisitionActionMessage
        if not actionMessage then
            if reason == "select-requisition" then
                actionMessage = "Select a requisition to continue."
            elseif eligible then
                actionMessage = "Ready to requisition."
            elseif reason == "requisition-unavailable" and #self.SelectedRequisitionItems == 0 and hasAssignedRank then
                actionMessage = "No requisitions configured."
            else
                actionMessage = describeEligibilityFailure(reason, detail)
            end
        end
        self.RequisitionActionStatus:SetText(actionMessage)
    end
    return self.frame
end

return RequisitionsPage
