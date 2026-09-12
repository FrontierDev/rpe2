local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}
local Database = Addon.Internal and Addon.Internal.Database or {}
local Dependecies = Database.Dependecies or {}
local Contributions = Addon.Internal and Addon.Internal.GuildShopContributions or {}

local GetEntryDefinition = DataEditor.GetEntryDefinition
local GetContentPageDefinitions = DataEditor.GetContentPageDefinitions
local BuildGuildSettingInspectorRequisitionsPage = DataEditor.BuildGuildSettingInspectorRequisitionsPage

local GUILD_SETTING_ENTRY_DEFINITION = {
    className = "GuildSetting",
    singular = "Guild Setting",
    buttonLabel = "New Guild Setting",
    emptyName = "Unnamed Guild Setting",
    assignsId = true,
}

local function trim(value)
    return tostring(value or ""):match("^%s*(.-)%s*$") or ""
end

local function isContribution(setting)
    if type(Contributions.IsContribution) == "function" then return Contributions.IsContribution(setting) end
    return type(setting) == "table" and trim(setting.shopContributionTargetRef) ~= ""
end

local function uniqueId(entries, prefix)
    local seen = {}
    for index = 1, #(entries or {}) do
        local id = trim(entries[index] and entries[index].id)
        if id ~= "" then seen[id] = true end
    end
    local index = 1
    while seen[prefix .. index] do index = index + 1 end
    return prefix .. index
end

local function getDatasetList()
    return type(Database.ListDatasets) == "function" and Database.ListDatasets() or {}
end

local function getDatasetName(dataset)
    if type(Database.GetDatasetDisplayName) == "function" then
        local ok, value = pcall(Database.GetDatasetDisplayName, dataset)
        if ok and trim(value) ~= "" then return trim(value) end
    end
    return trim(dataset and dataset.name) ~= "" and trim(dataset.name) or trim(dataset and dataset.id)
end

local function resolveTargetSetting(targetRef)
    local datasetId, settingId = trim(targetRef):match("^([^:]+):([^:]+)$")
    if not datasetId then return nil, nil end
    for _, dataset in ipairs(getDatasetList()) do
        if trim(dataset and dataset.id) == datasetId then
            for index = 1, #(dataset.guildSettings or {}) do
                local setting = dataset.guildSettings[index]
                if not isContribution(setting) and trim(setting and setting.id) == settingId then
                    return dataset, setting
                end
            end
        end
    end
    return nil, nil
end

local function buildTargetItems(currentRef)
    local items = {}
    local seen = {}
    for _, dataset in ipairs(getDatasetList()) do
        for index = 1, #(dataset.guildSettings or {}) do
            local setting = dataset.guildSettings[index]
            if not isContribution(setting) then
                local ref = trim(dataset.id) .. ":" .. trim(setting.id)
                if trim(dataset.id) ~= "" and trim(setting.id) ~= "" then
                    local settingName = trim(setting.name) ~= "" and trim(setting.name) or trim(setting.id)
                    items[#items + 1] = { label = getDatasetName(dataset) .. " / " .. settingName, value = ref }
                    seen[ref] = true
                end
            end
        end
    end
    table.sort(items, function(a, b) return string.lower(a.label) < string.lower(b.label) end)
    if trim(currentRef) ~= "" and not seen[trim(currentRef)] then
        table.insert(items, 1, { label = "Missing target: " .. trim(currentRef), value = trim(currentRef) })
    end
    if #items == 0 then items[1] = { label = "No Guild Settings available", value = "" } end
    return items
end

local function buildRoleItems(targetRef, selectedRoleIds)
    local _, setting = resolveTargetSetting(targetRef)
    local items, seen = {}, {}
    for index = 1, #(setting and setting.roles or {}) do
        local role = setting.roles[index]
        local id = trim(role and role.id)
        if id ~= "" then
            items[#items + 1] = { label = trim(role.name) ~= "" and trim(role.name) or id, value = id }
            seen[id] = true
        end
    end
    for index = 1, #(selectedRoleIds or {}) do
        local id = trim(selectedRoleIds[index])
        if id ~= "" and not seen[id] then
            items[#items + 1] = { label = "Missing Role: " .. id, value = id }
            seen[id] = true
        end
    end
    if #items == 0 then items[1] = { label = "No target Roles", value = "" } end
    return items
end

local function buildCategoryItems(targetRef, currentCategoryId)
    local _, setting = resolveTargetSetting(targetRef)
    local items = { { label = "Other / uncategorised", value = "" } }
    local seen = { [""] = true }
    for index = 1, #(setting and setting.shopCategories or {}) do
        local category = setting.shopCategories[index]
        local id = trim(category and category.id)
        if id ~= "" then
            items[#items + 1] = { label = trim(category.name) ~= "" and trim(category.name) or id, value = id }
            seen[id] = true
        end
    end
    local current = trim(currentCategoryId)
    if current ~= "" and not seen[current] then
        items[#items + 1] = { label = "Missing Category: " .. current, value = current }
    end
    return items
end

local function getSelectedContribution(self)
    local dataset = self:GetSelectedDataset()
    local wanted = tonumber(self.SelectedGuildShopContributionIndex)
    if not dataset or not wanted then return dataset, nil, nil end
    local count = 0
    for index = 1, #(dataset.guildSettings or {}) do
        local setting = dataset.guildSettings[index]
        if isContribution(setting) then
            count = count + 1
            if count == wanted then return dataset, setting, index end
        end
    end
    return dataset, nil, nil
end

local function getSelectedRequisition(self)
    local _, contribution = getSelectedContribution(self)
    local index = tonumber(self.SelectedGuildShopContributionRequisitionIndex)
    return contribution, index and contribution and contribution.requisitions and contribution.requisitions[index] or nil, index
end

local function markChanged(self, reason)
    local dataset = self:GetSelectedDataset()
    if not dataset then return end
    if type(self.QueuePendingDatasetEntryChanged) == "function" then
        self:QueuePendingDatasetEntryChanged(dataset.id, "guildSettings", { reason = reason or "shop-contribution" })
    end
    if type(Dependecies.RecomputeDatasetDependencies) == "function" then
        pcall(Dependecies.RecomputeDatasetDependencies, dataset.id)
    end
end

function DataEditor:GetEntryDefinition(collectionKey)
    if collectionKey == "guildSettings" then return GUILD_SETTING_ENTRY_DEFINITION end
    return GetEntryDefinition(self, collectionKey)
end

function DataEditor:GetContentPageDefinitions()
    local definitions = GetContentPageDefinitions(self)
    local foundContributions = false
    for index = 1, #(definitions or {}) do
        local definition = definitions[index]
        if definition and definition.key == "guildSettings" then definition.label = "Guild Settings" end
        if definition and definition.key == "guildShopContributions" then foundContributions = true end
    end
    if not foundContributions then
        definitions[#definitions + 1] = { key = "guildShopContributions", label = "Shop Contributions", builder = "BuildGuildShopContributionsPage" }
    end
    return definitions
end

function DataEditor:RefreshGuildShopContributionsPage()
    if not self.GuildShopContributionsPageRoot then return end
    local dataset = self:GetSelectedDataset()
    local contributions = {}
    for index = 1, #(dataset and dataset.guildSettings or {}) do
        local setting = dataset.guildSettings[index]
        if isContribution(setting) then contributions[#contributions + 1] = setting end
    end
    if (tonumber(self.SelectedGuildShopContributionIndex) or 0) > #contributions then
        self.SelectedGuildShopContributionIndex = #contributions > 0 and #contributions or nil
    end
    if self.GuildShopContributionList then self.GuildShopContributionList:SetItems(contributions) end

    local _, contribution = getSelectedContribution(self)
    local enabled = contribution ~= nil
    if self.GuildShopContributionNameInput then self.GuildShopContributionNameInput:SetText(enabled and (contribution.name or "") or "") end
    if self.GuildShopContributionTargetDropdown then
        self.GuildShopContributionTargetDropdown:SetItems(buildTargetItems(contribution and contribution.shopContributionTargetRef))
        self.GuildShopContributionTargetDropdown:SetSelectedValue(contribution and contribution.shopContributionTargetRef or "", true)
    end

    local requisitions = contribution and contribution.requisitions or {}
    if (tonumber(self.SelectedGuildShopContributionRequisitionIndex) or 0) > #requisitions then
        self.SelectedGuildShopContributionRequisitionIndex = #requisitions > 0 and #requisitions or nil
    end
    if self.GuildShopContributionRequisitionList then self.GuildShopContributionRequisitionList:SetItems(requisitions) end

    local _, requisition = getSelectedRequisition(self)
    if self.GuildShopContributionRequisitionIdInput then self.GuildShopContributionRequisitionIdInput:SetText(requisition and requisition.id or "") end
    if self.GuildShopContributionItemRefInput then self.GuildShopContributionItemRefInput:SetText(requisition and requisition.itemRef or "") end
    if self.GuildShopContributionQuantityInput then self.GuildShopContributionQuantityInput:SetText(requisition and tostring(requisition.quantity or 1) or "") end
    if self.GuildShopContributionCategoryDropdown then
        self.GuildShopContributionCategoryDropdown:SetItems(buildCategoryItems(contribution and contribution.shopContributionTargetRef, requisition and requisition.shopCategoryId))
        self.GuildShopContributionCategoryDropdown:SetSelectedValue(requisition and requisition.shopCategoryId or "", true)
    end
    if self.GuildShopContributionRoleDropdown then
        self.GuildShopContributionRoleDropdown:SetItems(buildRoleItems(contribution and contribution.shopContributionTargetRef, requisition and requisition.roleIds))
        self.GuildShopContributionRoleDropdown:SetSelectedValue("", true)
    end
    if self.GuildShopContributionRoleList then
        local roleRows = {}
        for index = 1, #(requisition and requisition.roleIds or {}) do roleRows[index] = { id = requisition.roleIds[index] } end
        self.GuildShopContributionRoleList:SetItems(roleRows)
    end
    if self.GuildShopContributionCostList then self.GuildShopContributionCostList:SetItems(requisition and requisition.costs or {}) end
end

local function addLabeledInput(self, root, key, label, width)
    local row = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEGuildShopContribution" .. key .. "Row", { height = 20, expandWidth = true, spacing = 4, fitChildrenWidth = true })
    root:AddChild(row)
    row:AddChild(UI.CreateText(row:GetFrame(), "RPEGuildShopContribution" .. key .. "Label", label, { width = 92, height = 20, justifyH = "LEFT" }))
    local input = UI.CreateTextInput(row:GetFrame(), "RPEGuildShopContribution" .. key .. "Input", { width = width or 220, height = 20, expandWidth = true, weight = 1 })
    row:AddChild(input)
    return input, row
end

function DataEditor:BuildGuildShopContributionsPage(page)
    if self.GuildShopContributionsPageRoot then
        self:RefreshGuildShopContributionsPage()
        return self.GuildShopContributionsPageRoot
    end

    local root = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEGuildShopContributionsPageRoot", { spacing = 4, fitChildrenWidth = true, fitChildrenHeight = true })
    UI.Utils.AnchorFill(root, page, 0, 0, 0, 0)
    self.GuildShopContributionsPageRoot = root

    self.GuildShopContributionList = UI.ScrollLayout:New({ name = "RPEGuildShopContributionList", height = 58, rowHeight = 18, visibleRows = 3, border = true, rowElementClass = UI.ScrollListEntry, categoryWidth = 140, statusWidth = 140 })
    self.GuildShopContributionList:SetParent(root:GetFrame())
    self.GuildShopContributionList:SetRowRenderer(function(row, contribution, itemIndex)
        row:SetCategory(trim(contribution and contribution.name) ~= "" and contribution.name or contribution.id or "Shop Contribution")
        row:SetStatus(contribution and contribution.shopContributionTargetRef or "Missing target")
        local frame = row:GetFrame()
        frame:EnableMouse(true)
        frame:SetScript("OnMouseUp", function(_, button)
            if button == "LeftButton" then
                self.SelectedGuildShopContributionIndex = itemIndex
                self.SelectedGuildShopContributionRequisitionIndex = nil
                self:RefreshGuildShopContributionsPage()
            end
        end)
    end)
    self.GuildShopContributionList:Create()
    root:AddChild(self.GuildShopContributionList)

    local contributionButtons = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEGuildShopContributionButtons", { height = 20, spacing = 4 })
    root:AddChild(contributionButtons)
    contributionButtons:AddChild(UI.CreateButton(contributionButtons:GetFrame(), "RPEGuildShopContributionAdd", "New Contribution", 110, function()
        local dataset = self:GetSelectedDataset()
        if not dataset then return end
        dataset.guildSettings = dataset.guildSettings or {}
        local id = uniqueId(dataset.guildSettings, "shop_contribution_")
        dataset.guildSettings[#dataset.guildSettings + 1] = {
            id = id, name = "New Shop Contribution", description = "", guildName = Contributions.SentinelGuildName or "__RPE_SHOP_CONTRIBUTION__",
            shopContributionTargetRef = "", general = { enableRequisitions = false, enableDailyRewards = false }, roles = {}, shopCategories = {}, requisitions = {}, dailyRewards = {}, tags = {},
        }
        self.SelectedGuildShopContributionIndex = nil
        local count = 0
        for index = 1, #dataset.guildSettings do if isContribution(dataset.guildSettings[index]) or dataset.guildSettings[index] == dataset.guildSettings[#dataset.guildSettings] then count = count + 1 end end
        -- The target is initially blank, so the new row is identified explicitly here.
        dataset.guildSettings[#dataset.guildSettings].shopContributionTargetRef = "__missing_target__"
        self.SelectedGuildShopContributionIndex = count
        markChanged(self, "shop-contribution-create")
        self:RefreshGuildShopContributionsPage()
    end, { height = 20, fontSize = 8 }))
    contributionButtons:AddChild(UI.CreateButton(contributionButtons:GetFrame(), "RPEGuildShopContributionDelete", "Delete", 60, function()
        local dataset, _, rawIndex = getSelectedContribution(self)
        if not dataset or not rawIndex then return end
        table.remove(dataset.guildSettings, rawIndex)
        self.SelectedGuildShopContributionIndex = nil
        self.SelectedGuildShopContributionRequisitionIndex = nil
        markChanged(self, "shop-contribution-delete")
        self:RefreshGuildShopContributionsPage()
    end, { height = 20, fontSize = 8 }))

    self.GuildShopContributionNameInput = addLabeledInput(self, root, "Name", "Name")
    self.GuildShopContributionNameInput:SetScript("OnEditFocusLost", function()
        local _, contribution = getSelectedContribution(self)
        if contribution then contribution.name = self.GuildShopContributionNameInput:GetText() or "" markChanged(self, "shop-contribution-name") self:RefreshGuildShopContributionsPage() end
    end)

    local targetRow = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEGuildShopContributionTargetRow", { height = 20, expandWidth = true, spacing = 4, fitChildrenWidth = true })
    root:AddChild(targetRow)
    targetRow:AddChild(UI.CreateText(targetRow:GetFrame(), "RPEGuildShopContributionTargetLabel", "Target Setting", { width = 92, height = 20, justifyH = "LEFT" }))
    self.GuildShopContributionTargetDropdown = UI.CreateDropdown(targetRow:GetFrame(), "RPEGuildShopContributionTargetDropdown", {
        width = 220, height = 20, expandWidth = true, weight = 1, items = {},
        onValueChanged = function(value)
            local _, contribution = getSelectedContribution(self)
            if contribution and trim(value) ~= "" then
                contribution.shopContributionTargetRef = value
                contribution.guildName = Contributions.SentinelGuildName or "__RPE_SHOP_CONTRIBUTION__"
                markChanged(self, "shop-contribution-target")
                self:RefreshGuildShopContributionsPage()
            end
        end,
    })
    targetRow:AddChild(self.GuildShopContributionTargetDropdown)

    self.GuildShopContributionRequisitionList = UI.ScrollLayout:New({ name = "RPEGuildShopContributionRequisitionList", height = 54, rowHeight = 18, visibleRows = 3, border = true, rowElementClass = UI.ScrollListEntry, categoryWidth = 120, statusWidth = 150 })
    self.GuildShopContributionRequisitionList:SetParent(root:GetFrame())
    self.GuildShopContributionRequisitionList:SetRowRenderer(function(row, requisition, itemIndex)
        row:SetCategory(requisition and requisition.id or "")
        row:SetStatus(requisition and requisition.itemRef or "")
        local frame = row:GetFrame(); frame:EnableMouse(true)
        frame:SetScript("OnMouseUp", function(_, button)
            if button == "LeftButton" then self.SelectedGuildShopContributionRequisitionIndex = itemIndex self:RefreshGuildShopContributionsPage() end
        end)
    end)
    self.GuildShopContributionRequisitionList:Create()
    root:AddChild(self.GuildShopContributionRequisitionList)

    local reqButtons = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEGuildShopContributionReqButtons", { height = 20, spacing = 4 })
    root:AddChild(reqButtons)
    reqButtons:AddChild(UI.CreateButton(reqButtons:GetFrame(), "RPEGuildShopContributionReqAdd", "Add Shop Item", 90, function()
        local _, contribution = getSelectedContribution(self)
        if not contribution then return end
        contribution.requisitions = contribution.requisitions or {}
        contribution.requisitions[#contribution.requisitions + 1] = { id = uniqueId(contribution.requisitions, "shop_item_"), itemRef = "", quantity = 1, costs = {}, characterLimit = 0, roleIds = {}, shopCategoryId = "" }
        self.SelectedGuildShopContributionRequisitionIndex = #contribution.requisitions
        markChanged(self, "shop-contribution-requisition-create")
        self:RefreshGuildShopContributionsPage()
    end, { height = 20, fontSize = 8 }))
    reqButtons:AddChild(UI.CreateButton(reqButtons:GetFrame(), "RPEGuildShopContributionReqDelete", "Delete Item", 76, function()
        local contribution, _, index = getSelectedRequisition(self)
        if contribution and index then table.remove(contribution.requisitions, index) self.SelectedGuildShopContributionRequisitionIndex = nil markChanged(self, "shop-contribution-requisition-delete") self:RefreshGuildShopContributionsPage() end
    end, { height = 20, fontSize = 8 }))

    self.GuildShopContributionRequisitionIdInput = addLabeledInput(self, root, "ReqId", "Item ID")
    self.GuildShopContributionItemRefInput = addLabeledInput(self, root, "ItemRef", "Item Ref")
    self.GuildShopContributionQuantityInput = addLabeledInput(self, root, "Quantity", "Quantity")
    local function commitReqField(field, transform, reason)
        local _, requisition = getSelectedRequisition(self)
        if not requisition then return end
        local value = field:GetText() or ""
        requisition[reason] = transform and transform(value) or value
        requisition.characterLimit = 0
        markChanged(self, "shop-contribution-requisition")
        self:RefreshGuildShopContributionsPage()
    end
    self.GuildShopContributionRequisitionIdInput:SetScript("OnEditFocusLost", function()
        local contribution, requisition, index = getSelectedRequisition(self)
        if requisition then requisition.id = uniqueId(contribution.requisitions, "shop_item_") if trim(self.GuildShopContributionRequisitionIdInput:GetText()) ~= "" then requisition.id = trim(self.GuildShopContributionRequisitionIdInput:GetText()) end markChanged(self, "shop-contribution-requisition-id") self:RefreshGuildShopContributionsPage() end
    end)
    self.GuildShopContributionItemRefInput:SetScript("OnEditFocusLost", function() local _, r = getSelectedRequisition(self); if r then r.itemRef = trim(self.GuildShopContributionItemRefInput:GetText()); markChanged(self, "shop-contribution-item") self:RefreshGuildShopContributionsPage() end end)
    self.GuildShopContributionQuantityInput:SetScript("OnEditFocusLost", function() local _, r = getSelectedRequisition(self); if r then r.quantity = math.max(1, math.floor(tonumber(self.GuildShopContributionQuantityInput:GetText()) or 1)); markChanged(self, "shop-contribution-quantity") self:RefreshGuildShopContributionsPage() end end)

    local categoryRow = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEGuildShopContributionCategoryRow", { height = 20, expandWidth = true, spacing = 4, fitChildrenWidth = true })
    root:AddChild(categoryRow)
    categoryRow:AddChild(UI.CreateText(categoryRow:GetFrame(), "RPEGuildShopContributionCategoryLabel", "Shop Category", { width = 92, height = 20, justifyH = "LEFT" }))
    self.GuildShopContributionCategoryDropdown = UI.CreateDropdown(categoryRow:GetFrame(), "RPEGuildShopContributionCategoryDropdown", { width = 220, height = 20, expandWidth = true, weight = 1, items = {}, onValueChanged = function(value) local _, r = getSelectedRequisition(self); if r then r.shopCategoryId = value or "" markChanged(self, "shop-contribution-category") end end })
    categoryRow:AddChild(self.GuildShopContributionCategoryDropdown)

    local roleRow = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEGuildShopContributionRoleRow", { height = 20, expandWidth = true, spacing = 4, fitChildrenWidth = true })
    root:AddChild(roleRow)
    self.GuildShopContributionRoleDropdown = UI.CreateDropdown(roleRow:GetFrame(), "RPEGuildShopContributionRoleDropdown", { width = 180, height = 20, items = {} })
    roleRow:AddChild(self.GuildShopContributionRoleDropdown)
    roleRow:AddChild(UI.CreateButton(roleRow:GetFrame(), "RPEGuildShopContributionRoleAdd", "Add Role", 64, function()
        local _, r = getSelectedRequisition(self); if not r then return end
        local roleId = self.GuildShopContributionRoleDropdown:GetSelectedValue and self.GuildShopContributionRoleDropdown:GetSelectedValue() or ""
        roleId = trim(roleId); if roleId == "" then return end
        r.roleIds = r.roleIds or {}; for i = 1, #r.roleIds do if r.roleIds[i] == roleId then return end end
        r.roleIds[#r.roleIds + 1] = roleId; markChanged(self, "shop-contribution-role") self:RefreshGuildShopContributionsPage()
    end, { height = 20, fontSize = 8 }))
    self.GuildShopContributionRoleList = UI.ScrollLayout:New({ name = "RPEGuildShopContributionRoleList", height = 36, rowHeight = 18, visibleRows = 2, border = true, rowElementClass = UI.ScrollListEntry, categoryWidth = 210, statusWidth = 0 })
    self.GuildShopContributionRoleList:SetParent(root:GetFrame())
    self.GuildShopContributionRoleList:SetRowRenderer(function(row, roleRowValue, itemIndex)
        row:SetCategory(roleRowValue and roleRowValue.id or "")
        local frame = row:GetFrame(); frame:EnableMouse(true); frame:SetScript("OnMouseUp", function(_, button)
            if button == "RightButton" then local _, r = getSelectedRequisition(self); if r and r.roleIds then table.remove(r.roleIds, itemIndex) markChanged(self, "shop-contribution-role-remove") self:RefreshGuildShopContributionsPage() end end
        end)
    end)
    self.GuildShopContributionRoleList:Create(); root:AddChild(self.GuildShopContributionRoleList)

    local costRow = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEGuildShopContributionCostRow", { height = 20, expandWidth = true, spacing = 4, fitChildrenWidth = true })
    root:AddChild(costRow)
    self.GuildShopContributionCostCurrencyInput = UI.CreateTextInput(costRow:GetFrame(), "RPEGuildShopContributionCostCurrencyInput", { width = 150, height = 20, placeholder = "Currency ref" }); costRow:AddChild(self.GuildShopContributionCostCurrencyInput)
    self.GuildShopContributionCostAmountInput = UI.CreateTextInput(costRow:GetFrame(), "RPEGuildShopContributionCostAmountInput", { width = 56, height = 20, placeholder = "Amount" }); costRow:AddChild(self.GuildShopContributionCostAmountInput)
    costRow:AddChild(UI.CreateButton(costRow:GetFrame(), "RPEGuildShopContributionCostAdd", "Add Cost", 64, function()
        local _, r = getSelectedRequisition(self); if not r then return end
        local currencyRef = trim(self.GuildShopContributionCostCurrencyInput:GetText()); if currencyRef == "" then return end
        r.costs = r.costs or {}; r.costs[#r.costs + 1] = { currencyRef = currencyRef, amount = math.max(0, math.floor(tonumber(self.GuildShopContributionCostAmountInput:GetText()) or 0)) }
        markChanged(self, "shop-contribution-cost") self:RefreshGuildShopContributionsPage()
    end, { height = 20, fontSize = 8 }))
    self.GuildShopContributionCostList = UI.ScrollLayout:New({ name = "RPEGuildShopContributionCostList", height = 36, rowHeight = 18, visibleRows = 2, border = true, rowElementClass = UI.ScrollListEntry, categoryWidth = 150, statusWidth = 80 })
    self.GuildShopContributionCostList:SetParent(root:GetFrame())
    self.GuildShopContributionCostList:SetRowRenderer(function(row, cost, itemIndex)
        row:SetCategory(cost and cost.currencyRef or "")
        row:SetStatus(cost and tostring(cost.amount or 0) or "0")
        local frame = row:GetFrame(); frame:EnableMouse(true); frame:SetScript("OnMouseUp", function(_, button)
            if button == "RightButton" then local _, r = getSelectedRequisition(self); if r and r.costs then table.remove(r.costs, itemIndex) markChanged(self, "shop-contribution-cost-remove") self:RefreshGuildShopContributionsPage() end end
        end)
    end)
    self.GuildShopContributionCostList:Create(); root:AddChild(self.GuildShopContributionCostList)

    self:RefreshGuildShopContributionsPage()
    return root
end

-- #272: the Role inspector owns the final Shop Category visibility state, but
-- the base Character Limit commit previously did not request an immediate page
-- refresh. Wrap only that input's two commit handlers after the complete Guild
-- Setting inspector stack has loaded so 0 <-> positive transitions repaint in
-- the same interaction without changing quantity or other numeric fields.
if type(BuildGuildSettingInspectorRequisitionsPage) == "function" then
    function DataEditor:BuildGuildSettingInspectorRequisitionsPage(parent)
        local page = BuildGuildSettingInspectorRequisitionsPage(self, parent)
        local input = self.GuildSettingInspectorRequisitionLimitInput
        if input and input._guildSettingLimitRefreshWrapped ~= true and type(input.SetScript) == "function" then
            input._guildSettingLimitRefreshWrapped = true
            for _, scriptName in ipairs({ "OnEnterPressed", "OnEditFocusLost" }) do
                local original = input.scripts and input.scripts[scriptName] or nil
                if type(original) == "function" then
                    input:SetScript(scriptName, function(...)
                        original(...)
                        if type(self.RefreshGuildSettingRequisitionsPage) == "function" then self:RefreshGuildSettingRequisitionsPage() end
                    end)
                end
            end
        end
        return page
    end
end

return DataEditor
