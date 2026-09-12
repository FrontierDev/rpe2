local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}
local Database = Addon.Internal and Addon.Internal.Database or {}
local Dependecies = Database.Dependecies or {}
local Contributions = Addon.Internal and Addon.Internal.GuildShopContributions or {}

local OldGetEntryDefinition = DataEditor.GetEntryDefinition
local OldGetContentPageDefinitions = DataEditor.GetContentPageDefinitions
local OldBuildRequisitionsPage = DataEditor.BuildGuildSettingInspectorRequisitionsPage

local GUILD_SETTING_ENTRY_DEFINITION = {
    className = "GuildSetting", singular = "Guild Setting", buttonLabel = "New Guild Setting",
    emptyName = "Unnamed Guild Setting", assignsId = true,
}

local function trim(value)
    return tostring(value or ""):match("^%s*(.-)%s*$") or ""
end

local function isContribution(setting)
    if type(Contributions.IsContribution) == "function" then return Contributions.IsContribution(setting) end
    return type(setting) == "table" and trim(setting.shopContributionTargetRef) ~= ""
end

local function datasets()
    return type(Database.ListDatasets) == "function" and Database.ListDatasets() or {}
end

local function datasetName(dataset)
    if type(Database.GetDatasetDisplayName) == "function" then
        local ok, value = pcall(Database.GetDatasetDisplayName, dataset)
        if ok and trim(value) ~= "" then return trim(value) end
    end
    return trim(dataset and dataset.name) ~= "" and trim(dataset.name) or trim(dataset and dataset.id)
end

local function resolveTarget(ref)
    local datasetId, settingId = trim(ref):match("^([^:]+):([^:]+)$")
    if not datasetId then return nil, nil end
    for _, dataset in ipairs(datasets()) do
        if trim(dataset.id) == datasetId then
            for index = 1, #(dataset.guildSettings or {}) do
                local setting = dataset.guildSettings[index]
                if not isContribution(setting) and trim(setting.id) == settingId then return dataset, setting end
            end
        end
    end
    return nil, nil
end

local function targetItems(current)
    local items, seen = {}, {}
    for _, dataset in ipairs(datasets()) do
        for index = 1, #(dataset.guildSettings or {}) do
            local setting = dataset.guildSettings[index]
            if not isContribution(setting) and trim(dataset.id) ~= "" and trim(setting.id) ~= "" then
                local ref = trim(dataset.id) .. ":" .. trim(setting.id)
                local name = trim(setting.name) ~= "" and trim(setting.name) or trim(setting.id)
                items[#items + 1] = { label = datasetName(dataset) .. " / " .. name, value = ref }
                seen[ref] = true
            end
        end
    end
    table.sort(items, function(a, b) return string.lower(a.label) < string.lower(b.label) end)
    current = trim(current)
    if current ~= "" and not seen[current] then table.insert(items, 1, { label = "Missing target: " .. current, value = current }) end
    if #items == 0 then items[1] = { label = "No Guild Settings available", value = "" } end
    return items
end

local function roleItems(targetRef, selected)
    local _, setting = resolveTarget(targetRef)
    local items, seen = { { label = "Select Role...", value = "" } }, {}
    for index = 1, #(setting and setting.roles or {}) do
        local role = setting.roles[index]
        local id = trim(role.id)
        if id ~= "" then items[#items + 1] = { label = trim(role.name) ~= "" and trim(role.name) or id, value = id }; seen[id] = true end
    end
    for index = 1, #(selected or {}) do
        local id = trim(selected[index])
        if id ~= "" and not seen[id] then items[#items + 1] = { label = "Missing Role: " .. id, value = id }; seen[id] = true end
    end
    return items
end

local function categoryItems(targetRef, current)
    local _, setting = resolveTarget(targetRef)
    local items, seen = { { label = "Other / uncategorised", value = "" } }, { [""] = true }
    for index = 1, #(setting and setting.shopCategories or {}) do
        local category = setting.shopCategories[index]
        local id = trim(category.id)
        if id ~= "" then items[#items + 1] = { label = trim(category.name) ~= "" and trim(category.name) or id, value = id }; seen[id] = true end
    end
    current = trim(current)
    if current ~= "" and not seen[current] then items[#items + 1] = { label = "Missing Category: " .. current, value = current } end
    return items
end

local function nextId(entries, prefix)
    local seen = {}
    for index = 1, #(entries or {}) do seen[trim(entries[index] and entries[index].id)] = true end
    local number = 1
    while seen[prefix .. number] do number = number + 1 end
    return prefix .. number
end

local function contributionRows(dataset)
    local rows = {}
    for index = 1, #(dataset and dataset.guildSettings or {}) do
        if isContribution(dataset.guildSettings[index]) then rows[#rows + 1] = { setting = dataset.guildSettings[index], rawIndex = index } end
    end
    return rows
end

local function selectedContribution(self)
    local dataset = self:GetSelectedDataset()
    local rows = contributionRows(dataset)
    local selected = rows[tonumber(self.SelectedGuildShopContributionIndex) or 0]
    return dataset, selected and selected.setting or nil, selected and selected.rawIndex or nil, rows
end

local function selectedRequisition(self)
    local _, contribution = selectedContribution(self)
    local index = tonumber(self.SelectedGuildShopContributionRequisitionIndex)
    return contribution, index and contribution and contribution.requisitions and contribution.requisitions[index] or nil, index
end

local function changed(self, reason)
    local dataset = self:GetSelectedDataset()
    if not dataset then return end
    if type(self.QueuePendingDatasetEntryChanged) == "function" then self:QueuePendingDatasetEntryChanged(dataset.id, "guildSettings", { reason = reason }) end
    if type(Dependecies.RecomputeDatasetDependencies) == "function" then pcall(Dependecies.RecomputeDatasetDependencies, dataset.id) end
end

local function inputRow(root, name, label)
    local row = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), name .. "Row", { height = 20, expandWidth = true, spacing = 4, fitChildrenWidth = true })
    root:AddChild(row)
    row:AddChild(UI.CreateText(row:GetFrame(), name .. "Label", label, { width = 90, height = 20, justifyH = "LEFT" }))
    local input = UI.CreateTextInput(row:GetFrame(), name .. "Input", { width = 0, height = 20, expandWidth = true, weight = 1 })
    row:AddChild(input)
    return input
end

function DataEditor:GetEntryDefinition(collectionKey)
    if collectionKey == "guildSettings" then return GUILD_SETTING_ENTRY_DEFINITION end
    return OldGetEntryDefinition(self, collectionKey)
end

function DataEditor:GetContentPageDefinitions()
    local definitions = OldGetContentPageDefinitions(self)
    local found = false
    for index = 1, #(definitions or {}) do
        if definitions[index].key == "guildSettings" then definitions[index].label = "Guild Settings" end
        if definitions[index].key == "guildShopContributions" then found = true end
    end
    if not found then definitions[#definitions + 1] = { key = "guildShopContributions", label = "Shop Contributions", builder = "BuildGuildShopContributionsPage" } end
    return definitions
end

function DataEditor:RefreshGuildShopContributionsPage()
    if not self.GuildShopContributionsPageRoot then return end
    local _, contribution, _, rows = selectedContribution(self)
    if (tonumber(self.SelectedGuildShopContributionIndex) or 0) > #rows then self.SelectedGuildShopContributionIndex = nil; contribution = nil end
    local displayRows = {}
    for index = 1, #rows do displayRows[index] = rows[index].setting end
    self.GuildShopContributionList:SetItems(displayRows)

    self.GuildShopContributionNameInput:SetText(contribution and contribution.name or "")
    self.GuildShopContributionTargetDropdown:SetItems(targetItems(contribution and contribution.shopContributionTargetRef))
    self.GuildShopContributionTargetDropdown:SetSelectedValue(contribution and contribution.shopContributionTargetRef or "", true)

    local requisitions = contribution and contribution.requisitions or {}
    if (tonumber(self.SelectedGuildShopContributionRequisitionIndex) or 0) > #requisitions then self.SelectedGuildShopContributionRequisitionIndex = nil end
    self.GuildShopContributionRequisitionList:SetItems(requisitions)
    local _, req = selectedRequisition(self)
    self.GuildShopContributionReqIdInput:SetText(req and req.id or "")
    self.GuildShopContributionItemRefInput:SetText(req and req.itemRef or "")
    self.GuildShopContributionQuantityInput:SetText(req and tostring(req.quantity or 1) or "")
    self.GuildShopContributionCategoryDropdown:SetItems(categoryItems(contribution and contribution.shopContributionTargetRef, req and req.shopCategoryId))
    self.GuildShopContributionCategoryDropdown:SetSelectedValue(req and req.shopCategoryId or "", true)
    self.GuildShopContributionRoleDropdown:SetItems(roleItems(contribution and contribution.shopContributionTargetRef, req and req.roleIds))
    self.GuildShopContributionRoleDropdown:SetSelectedValue("", true)

    local roles = {}
    for index = 1, #(req and req.roleIds or {}) do roles[index] = { id = req.roleIds[index] } end
    self.GuildShopContributionRoleList:SetItems(roles)
    self.GuildShopContributionCostList:SetItems(req and req.costs or {})
end

function DataEditor:BuildGuildShopContributionsPage(page)
    if self.GuildShopContributionsPageRoot then self:RefreshGuildShopContributionsPage(); return self.GuildShopContributionsPageRoot end
    local root = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEGuildShopContributionsPageRoot", { spacing = 4, fitChildrenWidth = true, fitChildrenHeight = true })
    UI.Utils.AnchorFill(root, page, 0, 0, 0, 0)
    self.GuildShopContributionsPageRoot = root

    self.GuildShopContributionList = UI.ScrollLayout:New({ name = "RPEGuildShopContributionList", height = 54, visibleRows = 3, rowHeight = 18, border = true, rowElementClass = UI.ScrollListEntry, categoryWidth = 130, statusWidth = 160 })
    self.GuildShopContributionList:SetParent(root:GetFrame())
    self.GuildShopContributionList:SetRowRenderer(function(row, value, index)
        row:SetCategory(trim(value.name) ~= "" and value.name or value.id or "Contribution"); row:SetStatus(value.shopContributionTargetRef or "")
        local frame = row:GetFrame(); frame:EnableMouse(true); frame:SetScript("OnMouseUp", function(_, button) if button == "LeftButton" then self.SelectedGuildShopContributionIndex = index; self.SelectedGuildShopContributionRequisitionIndex = nil; self:RefreshGuildShopContributionsPage() end end)
    end)
    self.GuildShopContributionList:Create(); root:AddChild(self.GuildShopContributionList)

    local buttons = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEGuildShopContributionButtons", { height = 20, spacing = 4 }); root:AddChild(buttons)
    buttons:AddChild(UI.CreateButton(buttons:GetFrame(), "RPEGuildShopContributionNew", "New Contribution", 106, function()
        local dataset = self:GetSelectedDataset(); if not dataset then return end
        dataset.guildSettings = dataset.guildSettings or {}
        local setting = { id = nextId(dataset.guildSettings, "shop_contribution_"), name = "New Shop Contribution", guildName = Contributions.SentinelGuildName or "__RPE_SHOP_CONTRIBUTION__", shopContributionTargetRef = "__missing_target__", general = { enableRequisitions = false, enableDailyRewards = false }, roles = {}, shopCategories = {}, requisitions = {}, dailyRewards = {}, tags = {} }
        dataset.guildSettings[#dataset.guildSettings + 1] = setting
        self.SelectedGuildShopContributionIndex = #contributionRows(dataset); self.SelectedGuildShopContributionRequisitionIndex = nil
        changed(self, "shop-contribution-create"); self:RefreshGuildShopContributionsPage()
    end, { height = 20, fontSize = 8 }))
    buttons:AddChild(UI.CreateButton(buttons:GetFrame(), "RPEGuildShopContributionDelete", "Delete", 58, function()
        local dataset, _, rawIndex = selectedContribution(self); if not dataset or not rawIndex then return end
        table.remove(dataset.guildSettings, rawIndex); self.SelectedGuildShopContributionIndex = nil; self.SelectedGuildShopContributionRequisitionIndex = nil
        changed(self, "shop-contribution-delete"); self:RefreshGuildShopContributionsPage()
    end, { height = 20, fontSize = 8 }))

    self.GuildShopContributionNameInput = inputRow(root, "RPEGuildShopContributionName", "Name")
    self.GuildShopContributionNameInput:SetScript("OnEditFocusLost", function() local _, c = selectedContribution(self); if c then c.name = self.GuildShopContributionNameInput:GetText() or ""; changed(self, "shop-contribution-name"); self:RefreshGuildShopContributionsPage() end end)

    local targetRow = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEGuildShopContributionTargetRow", { height = 20, expandWidth = true, spacing = 4, fitChildrenWidth = true }); root:AddChild(targetRow)
    targetRow:AddChild(UI.CreateText(targetRow:GetFrame(), "RPEGuildShopContributionTargetLabel", "Target Setting", { width = 90, height = 20, justifyH = "LEFT" }))
    self.GuildShopContributionTargetDropdown = UI.CreateDropdown(targetRow:GetFrame(), "RPEGuildShopContributionTargetDropdown", { width = 0, height = 20, expandWidth = true, weight = 1, items = {}, onValueChanged = function(value)
        local _, c = selectedContribution(self); if c and trim(value) ~= "" then c.shopContributionTargetRef = value; c.guildName = Contributions.SentinelGuildName or "__RPE_SHOP_CONTRIBUTION__"; changed(self, "shop-contribution-target"); self:RefreshGuildShopContributionsPage() end
    end }); targetRow:AddChild(self.GuildShopContributionTargetDropdown)

    self.GuildShopContributionRequisitionList = UI.ScrollLayout:New({ name = "RPEGuildShopContributionRequisitionList", height = 54, visibleRows = 3, rowHeight = 18, border = true, rowElementClass = UI.ScrollListEntry, categoryWidth = 110, statusWidth = 180 })
    self.GuildShopContributionRequisitionList:SetParent(root:GetFrame()); self.GuildShopContributionRequisitionList:SetRowRenderer(function(row, req, index)
        row:SetCategory(req.id or ""); row:SetStatus(req.itemRef or ""); local frame = row:GetFrame(); frame:EnableMouse(true); frame:SetScript("OnMouseUp", function(_, button) if button == "LeftButton" then self.SelectedGuildShopContributionRequisitionIndex = index; self:RefreshGuildShopContributionsPage() end end)
    end); self.GuildShopContributionRequisitionList:Create(); root:AddChild(self.GuildShopContributionRequisitionList)

    local reqButtons = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEGuildShopContributionReqButtons", { height = 20, spacing = 4 }); root:AddChild(reqButtons)
    reqButtons:AddChild(UI.CreateButton(reqButtons:GetFrame(), "RPEGuildShopContributionReqNew", "Add Shop Item", 88, function()
        local _, c = selectedContribution(self); if not c then return end; c.requisitions = c.requisitions or {}
        c.requisitions[#c.requisitions + 1] = { id = nextId(c.requisitions, "shop_item_"), itemRef = "", quantity = 1, costs = {}, characterLimit = 0, roleIds = {}, shopCategoryId = "" }
        self.SelectedGuildShopContributionRequisitionIndex = #c.requisitions; changed(self, "shop-contribution-item-create"); self:RefreshGuildShopContributionsPage()
    end, { height = 20, fontSize = 8 }))
    reqButtons:AddChild(UI.CreateButton(reqButtons:GetFrame(), "RPEGuildShopContributionReqDelete", "Delete Item", 72, function()
        local c, _, index = selectedRequisition(self); if c and index then table.remove(c.requisitions, index); self.SelectedGuildShopContributionRequisitionIndex = nil; changed(self, "shop-contribution-item-delete"); self:RefreshGuildShopContributionsPage() end
    end, { height = 20, fontSize = 8 }))

    self.GuildShopContributionReqIdInput = inputRow(root, "RPEGuildShopContributionReqId", "Item ID")
    self.GuildShopContributionItemRefInput = inputRow(root, "RPEGuildShopContributionItemRef", "Item Ref")
    self.GuildShopContributionQuantityInput = inputRow(root, "RPEGuildShopContributionQuantity", "Quantity")
    self.GuildShopContributionReqIdInput:SetScript("OnEditFocusLost", function() local _, r = selectedRequisition(self); if r and trim(self.GuildShopContributionReqIdInput:GetText()) ~= "" then r.id = trim(self.GuildShopContributionReqIdInput:GetText()); changed(self, "shop-contribution-item-id"); self:RefreshGuildShopContributionsPage() end end)
    self.GuildShopContributionItemRefInput:SetScript("OnEditFocusLost", function() local _, r = selectedRequisition(self); if r then r.itemRef = trim(self.GuildShopContributionItemRefInput:GetText()); changed(self, "shop-contribution-item-ref"); self:RefreshGuildShopContributionsPage() end end)
    self.GuildShopContributionQuantityInput:SetScript("OnEditFocusLost", function() local _, r = selectedRequisition(self); if r then r.quantity = math.max(1, math.floor(tonumber(self.GuildShopContributionQuantityInput:GetText()) or 1)); r.characterLimit = 0; changed(self, "shop-contribution-quantity"); self:RefreshGuildShopContributionsPage() end end)

    local categoryRow = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEGuildShopContributionCategoryRow", { height = 20, expandWidth = true, spacing = 4, fitChildrenWidth = true }); root:AddChild(categoryRow)
    categoryRow:AddChild(UI.CreateText(categoryRow:GetFrame(), "RPEGuildShopContributionCategoryLabel", "Shop Category", { width = 90, height = 20, justifyH = "LEFT" }))
    self.GuildShopContributionCategoryDropdown = UI.CreateDropdown(categoryRow:GetFrame(), "RPEGuildShopContributionCategoryDropdown", { width = 0, height = 20, expandWidth = true, weight = 1, items = {}, onValueChanged = function(value) local _, r = selectedRequisition(self); if r then r.shopCategoryId = value or ""; changed(self, "shop-contribution-category") end end }); categoryRow:AddChild(self.GuildShopContributionCategoryDropdown)

    local roleRow = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEGuildShopContributionRoleRow", { height = 20, spacing = 4, fitChildrenWidth = true }); root:AddChild(roleRow)
    self.GuildShopContributionRoleDropdown = UI.CreateDropdown(roleRow:GetFrame(), "RPEGuildShopContributionRoleDropdown", { width = 180, height = 20, items = {} }); roleRow:AddChild(self.GuildShopContributionRoleDropdown)
    roleRow:AddChild(UI.CreateButton(roleRow:GetFrame(), "RPEGuildShopContributionRoleAdd", "Add Role", 62, function()
        local _, r = selectedRequisition(self); if not r then return end
        local getter = self.GuildShopContributionRoleDropdown.GetSelectedValue
        local roleId = trim(type(getter) == "function" and getter(self.GuildShopContributionRoleDropdown) or "")
        if roleId == "" then return end; r.roleIds = r.roleIds or {}; for i = 1, #r.roleIds do if r.roleIds[i] == roleId then return end end
        r.roleIds[#r.roleIds + 1] = roleId; changed(self, "shop-contribution-role-add"); self:RefreshGuildShopContributionsPage()
    end, { height = 20, fontSize = 8 }))
    self.GuildShopContributionRoleList = UI.ScrollLayout:New({ name = "RPEGuildShopContributionRoleList", height = 34, visibleRows = 2, rowHeight = 17, border = true, rowElementClass = UI.ScrollListEntry, categoryWidth = 220, statusWidth = 0 }); self.GuildShopContributionRoleList:SetParent(root:GetFrame())
    self.GuildShopContributionRoleList:SetRowRenderer(function(row, value, index) row:SetCategory(value.id or ""); local frame = row:GetFrame(); frame:EnableMouse(true); frame:SetScript("OnMouseUp", function(_, button) if button == "RightButton" then local _, r = selectedRequisition(self); if r and r.roleIds then table.remove(r.roleIds, index); changed(self, "shop-contribution-role-remove"); self:RefreshGuildShopContributionsPage() end end end) end); self.GuildShopContributionRoleList:Create(); root:AddChild(self.GuildShopContributionRoleList)

    local costRow = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEGuildShopContributionCostRow", { height = 20, spacing = 4, fitChildrenWidth = true }); root:AddChild(costRow)
    self.GuildShopContributionCostRefInput = UI.CreateTextInput(costRow:GetFrame(), "RPEGuildShopContributionCostRefInput", { width = 150, height = 20, placeholder = "Currency ref" }); costRow:AddChild(self.GuildShopContributionCostRefInput)
    self.GuildShopContributionCostAmountInput = UI.CreateTextInput(costRow:GetFrame(), "RPEGuildShopContributionCostAmountInput", { width = 54, height = 20, placeholder = "Amount" }); costRow:AddChild(self.GuildShopContributionCostAmountInput)
    costRow:AddChild(UI.CreateButton(costRow:GetFrame(), "RPEGuildShopContributionCostAdd", "Add Cost", 62, function() local _, r = selectedRequisition(self); if not r then return end; local ref = trim(self.GuildShopContributionCostRefInput:GetText()); if ref == "" then return end; r.costs = r.costs or {}; r.costs[#r.costs + 1] = { currencyRef = ref, amount = math.max(0, math.floor(tonumber(self.GuildShopContributionCostAmountInput:GetText()) or 0)) }; changed(self, "shop-contribution-cost-add"); self:RefreshGuildShopContributionsPage() end, { height = 20, fontSize = 8 }))
    self.GuildShopContributionCostList = UI.ScrollLayout:New({ name = "RPEGuildShopContributionCostList", height = 34, visibleRows = 2, rowHeight = 17, border = true, rowElementClass = UI.ScrollListEntry, categoryWidth = 160, statusWidth = 80 }); self.GuildShopContributionCostList:SetParent(root:GetFrame())
    self.GuildShopContributionCostList:SetRowRenderer(function(row, value, index) row:SetCategory(value.currencyRef or ""); row:SetStatus(tostring(value.amount or 0)); local frame = row:GetFrame(); frame:EnableMouse(true); frame:SetScript("OnMouseUp", function(_, button) if button == "RightButton" then local _, r = selectedRequisition(self); if r and r.costs then table.remove(r.costs, index); changed(self, "shop-contribution-cost-remove"); self:RefreshGuildShopContributionsPage() end end end) end); self.GuildShopContributionCostList:Create(); root:AddChild(self.GuildShopContributionCostList)

    self:RefreshGuildShopContributionsPage()
    return root
end

-- #272: refresh Shop Category visibility immediately when Character Limit changes.
if type(OldBuildRequisitionsPage) == "function" then
    function DataEditor:BuildGuildSettingInspectorRequisitionsPage(parent)
        local page = OldBuildRequisitionsPage(self, parent)
        local input = self.GuildSettingInspectorRequisitionLimitInput
        if input and input._guildSettingLimitRefreshWrapped ~= true and type(input.SetScript) == "function" then
            input._guildSettingLimitRefreshWrapped = true
            for _, scriptName in ipairs({ "OnEnterPressed", "OnEditFocusLost" }) do
                local original = input.scripts and input.scripts[scriptName] or nil
                if type(original) == "function" then input:SetScript(scriptName, function(...) original(...); if type(self.RefreshGuildSettingRequisitionsPage) == "function" then self:RefreshGuildSettingRequisitionsPage() end end) end
            end
        end
        return page
    end
end

return DataEditor
