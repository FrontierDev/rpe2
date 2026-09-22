local addonName, Addon = ...

-- The old cross-dataset Shop Contribution authoring page is no longer part of
-- the Data Editor. Keep the runtime compatibility code for already-authored
-- data, but do not expose the obsolete container as an author-facing data type.
local DataEditor = Addon.Client
    and Addon.Client.UI
    and Addon.Client.UI.Editor
    or nil
if type(DataEditor) == "table" and type(DataEditor.GetContentPageDefinitions) == "function" then
    local getContentPageDefinitions = DataEditor.GetContentPageDefinitions
    function DataEditor:GetContentPageDefinitions(...)
        local definitions = getContentPageDefinitions(self, ...) or {}
        local visible = {}
        for index = 1, #definitions do
            local definition = definitions[index]
            if type(definition) ~= "table" or definition.key ~= "guildShopContributions" then
                visible[#visible + 1] = definition
            end
        end
        return visible
    end
end

-- Guild Setting reward authoring: direct Items or Loot Table rolls.
if type(DataEditor) == "table" then
local UI = Addon.UI or {}
local Registry = Addon.Internal and Addon.Internal.Registry or {}
local Profile = Addon.Internal and Addon.Internal.Profile or {}
local InspectorShared = DataEditor.ItemInspectorShared

local FIELD_WIDTH = InspectorShared and InspectorShared.FIELD_WIDTH or 320
local CONTROL_HEIGHT = InspectorShared and InspectorShared.CONTROL_HEIGHT or 18
local DEFAULT_LOOT_ICON = "Interface\\Icons\\INV_Misc_Chest_04"

local REQUISITION_SOURCE_ITEMS = {
    { label = "Item", value = "item" },
    { label = "Loot Table", value = "loot_table" },
}
local DAILY_REWARD_TYPE_ITEMS = {
    { label = "Item", value = "item" },
    { label = "Currency", value = "currency" },
    { label = "Loot Table", value = "loot_table" },
}
local QUALITY_COLORS = {
    poor = { r = 0.62, g = 0.62, b = 0.62, a = 1 },
    common = { r = 1.0, g = 1.0, b = 1.0, a = 1 },
    uncommon = { r = 0.12, g = 1.0, b = 0.0, a = 1 },
    rare = { r = 0.0, g = 0.44, b = 0.87, a = 1 },
    epic = { r = 0.64, g = 0.21, b = 0.93, a = 1 },
    legendary = { r = 1.0, g = 0.50, b = 0.0, a = 1 },
}

local BaseBuildGuildSettingInspectorPage = DataEditor.BuildGuildSettingInspectorPage
local BaseRefreshGuildSettingRequisitionsPage = DataEditor.RefreshGuildSettingRequisitionsPage
local BaseRefreshGuildSettingDailyRewardsPage = DataEditor.RefreshGuildSettingDailyRewardsPage
local BaseRefreshGuildSettingInspectorPage = DataEditor.RefreshGuildSettingInspectorPage

local function trim(value)
    return tostring(value or ""):match("^%s*(.-)%s*$") or ""
end

local function normalizeInteger(value, fallback, minimum)
    local numeric = tonumber(value)
    if not numeric or numeric ~= numeric or numeric == math.huge or numeric == -math.huge then numeric = fallback end
    numeric = math.floor(tonumber(numeric) or 0)
    if minimum ~= nil then numeric = math.max(minimum, numeric) end
    return numeric
end

local function requisitionSourceType(requisition)
    local sourceType = string.lower(trim(requisition and requisition.sourceType))
    if sourceType == "loot" or sourceType == "table" or sourceType == "loot_table" then return "loot_table" end
    if trim(requisition and requisition.lootRef) ~= "" and trim(requisition and requisition.itemRef) == "" then return "loot_table" end
    return "item"
end

local function dailyRewardType(reward)
    local rewardType = string.lower(trim(reward and reward.type))
    if rewardType == "loot" or rewardType == "table" or rewardType == "loot_table" then return "loot_table" end
    if rewardType == "currency" then return "currency" end
    return "item"
end

local function parseQualifiedRef(reference)
    local datasetId, entryId = trim(reference):match("^([^:]+):(.+)$")
    return datasetId and trim(datasetId) or nil, entryId and trim(entryId) or nil
end

local function getSelectedRequisition(self)
    local setting = self:GetSelectedGuildSetting()
    local index = tonumber(self.SelectedGuildSettingRequisitionIndex)
    return setting, index and setting and setting.requisitions and setting.requisitions[index] or nil, index
end

local function getSelectedDailyReward(self)
    local setting = self:GetSelectedGuildSetting()
    local index = tonumber(self.SelectedGuildSettingDailyRewardIndex)
    return setting, index and setting and setting.dailyRewards and setting.dailyRewards[index] or nil, index
end

local function datasetDisplayName(self, dataset)
    if type(self.GetDatasetDisplayName) == "function" then
        local ok, name = pcall(self.GetDatasetDisplayName, self, dataset)
        if ok and trim(name) ~= "" then return trim(name) end
    end
    local name = trim(dataset and dataset.name)
    return name ~= "" and name or trim(dataset and dataset.id)
end

local function entryDisplayName(self, collectionKey, entry)
    if type(self.GetEntryDisplayName) == "function" then
        local ok, name = pcall(self.GetEntryDisplayName, self, collectionKey, entry)
        if ok and trim(name) ~= "" then return trim(name) end
    end
    local name = trim(entry and entry.name)
    return name ~= "" and name or trim(entry and entry.id)
end

local function getDatasets(self)
    return type(self.GetDatasets) == "function" and self:GetDatasets() or {}
end

local function findDataset(self, datasetId)
    local wanted = trim(datasetId)
    local datasets = getDatasets(self)
    for index = 1, #datasets do
        local dataset = datasets[index]
        if trim(dataset and dataset.id) == wanted then return dataset end
    end
    return nil
end

local function buildLootDatasetItems(self, currentDatasetId)
    local items, seen = { { label = "None", value = "" } }, { [""] = true }
    for _, dataset in ipairs(getDatasets(self)) do
        local datasetId = trim(dataset and dataset.id)
        if datasetId ~= "" and #(dataset and dataset.loot or {}) > 0 then
            items[#items + 1] = { label = datasetDisplayName(self, dataset), value = datasetId }
            seen[datasetId] = true
        end
    end
    table.sort(items, function(left, right)
        if left.value == "" then return true end
        if right.value == "" then return false end
        return string.lower(tostring(left.label or "")) < string.lower(tostring(right.label or ""))
    end)
    local current = trim(currentDatasetId)
    if current ~= "" and not seen[current] then items[#items + 1] = { label = "Missing Dataset", value = current } end
    return items
end

local function buildLootReferenceItems(self, datasetId, currentReference)
    local items, seen = { { label = "None", value = "" } }, { [""] = true }
    local dataset = findDataset(self, datasetId)
    for index = 1, #(dataset and dataset.loot or {}) do
        local lootTable = dataset.loot[index]
        local lootId = trim(lootTable and lootTable.id)
        if lootId ~= "" then
            local reference = trim(datasetId) .. ":" .. lootId
            items[#items + 1] = {
                label = entryDisplayName(self, "loot", lootTable),
                value = reference,
                icon = lootTable.icon or DEFAULT_LOOT_ICON,
            }
            seen[reference] = true
        end
    end
    table.sort(items, function(left, right)
        if left.value == "" then return true end
        if right.value == "" then return false end
        return string.lower(tostring(left.label or "")) < string.lower(tostring(right.label or ""))
    end)
    local current = trim(currentReference)
    if current ~= "" and not seen[current] then items[#items + 1] = { label = "Missing Loot Table", value = current } end
    return items
end

local function findChildRecursive(element, wantedName)
    if not element then return nil end
    local frame = element.GetFrame and element:GetFrame() or nil
    local name = element.name or (frame and frame.GetName and frame:GetName())
    if name == wantedName then return element end
    for index = 1, #(element.children or {}) do
        local found = findChildRecursive(element.children[index], wantedName)
        if found then return found end
    end
    return nil
end

local function rememberVisibleMetrics(element)
    if not element or element._guildLootVisibleHeight ~= nil then return end
    local frame = element.GetFrame and element:GetFrame() or nil
    local height = element.options and tonumber(element.options.height) or nil
    if not height or height <= 0 then height = frame and frame.GetHeight and tonumber(frame:GetHeight()) or nil end
    element._guildLootVisibleHeight = height and height > 0 and height or 38
    element._guildLootVisibleWeight = element.options and element.options.weight or nil
end

local function setLayoutElementVisible(element, visible)
    if not element then return end
    rememberVisibleMetrics(element)
    local frame = element.GetFrame and element:GetFrame() or nil
    element.options = element.options or {}
    if visible then
        element.options.height = element._guildLootVisibleHeight
        element.options.weight = element._guildLootVisibleWeight
        if element.SetHeight then element:SetHeight(element._guildLootVisibleHeight) end
        if frame then
            if frame.SetHeight then frame:SetHeight(element._guildLootVisibleHeight) end
            if frame.Show then frame:Show() end
        end
    else
        element.options.height = 0
        element.options.weight = 0
        if element.SetHeight then element:SetHeight(0) end
        if frame then
            if frame.SetHeight then frame:SetHeight(0) end
            if frame.Hide then frame:Hide() end
        end
    end
end

local function setDropdownEnabled(dropdown, enabled)
    local frame = dropdown and dropdown.GetFrame and dropdown:GetFrame() or nil
    if not frame then return end
    if frame.EnableMouse then frame:EnableMouse(enabled == true) end
    if frame.SetAlpha then frame:SetAlpha(enabled and 1 or 0.5) end
end

local function moveChildrenBefore(root, targetName, children)
    if not root or type(root.children) ~= "table" then return end
    local moving = {}
    for _, child in ipairs(children or {}) do if child then moving[child] = true end end
    local retained = {}
    for index = 1, #root.children do
        local child = root.children[index]
        if not moving[child] then retained[#retained + 1] = child end
    end
    root.children = retained
    local targetIndex = #root.children + 1
    for index = 1, #root.children do
        local child = root.children[index]
        local frame = child and child.GetFrame and child:GetFrame() or nil
        local name = child and (child.name or (frame and frame.GetName and frame:GetName()))
        if name == targetName then targetIndex = index break end
    end
    for offset, child in ipairs(children or {}) do
        if child then table.insert(root.children, targetIndex + offset - 1, child) end
    end
    if root.RefreshLayout then root:RefreshLayout() end
end

local function createFieldGroup(root, name, label)
    return InspectorShared.createEquipmentFieldGroup(root, name, label)
end

local function resolveItemDisplay(requisition)
    local itemRef = trim(requisition and requisition.itemRef)
    if itemRef == "" then return nil, "Unassigned Item" end
    if type(Registry.ResolveItemReference) == "function" then
        local ok, _, item = pcall(Registry.ResolveItemReference, Registry, itemRef)
        if ok and type(item) == "table" then
            local name = trim(item.name)
            return item, name ~= "" and name or "Unnamed Item"
        end
    end
    return nil, "Missing Item"
end

local function resolveLootDisplay(reference)
    local lootRef = trim(reference)
    if lootRef == "" then return nil, "Unassigned Loot Table" end
    if type(Registry.ResolveLootReference) == "function" then
        local ok, _, lootTable = pcall(Registry.ResolveLootReference, Registry, lootRef)
        if ok and type(lootTable) == "table" then
            local name = trim(lootTable.name)
            return lootTable, name ~= "" and name or "Unnamed Loot Table"
        end
    end
    return nil, "Missing Loot Table"
end

local function qualityColor(item)
    local quality = type(item) == "table" and tostring(item.quality or "common") or ""
    if type(ITEM_QUALITY_COLORS) == "table" and ITEM_QUALITY_COLORS[quality] then
        local color = ITEM_QUALITY_COLORS[quality]
        return color.r or 1, color.g or 1, color.b or 1, color.a or 1
    end
    local color = QUALITY_COLORS[quality]
    if color then return color.r, color.g, color.b, color.a end
    local fallback = UI.ResolveColor(nil, "text.primary") or {}
    return fallback.r or 1, fallback.g or 1, fallback.b or 1, fallback.a or 1
end

local function primaryTextColor()
    local color = UI.ResolveColor(nil, "text.primary") or {}
    return color.r or 1, color.g or 1, color.b or 1, color.a or 1
end

local function setRowSelection(row, selected)
    if not row or not row.entryBackground or not row.entryBackground.SetColorTexture then return end
    local color = UI.ResolveColor(nil, selected and "list.rowHover" or "list.rowBackground") or {}
    row.entryBackground:SetColorTexture(color.r or 0.08, color.g or 0.09, color.b or 0.11, color.a or 0.85)
end

function DataEditor:InstallGuildSettingRequisitionRowRenderer()
    local scroll = self.GuildSettingInspectorRequisitionScroll
    if not scroll then return end
    scroll:SetRowRenderer(function(row, requisition, visibleIndex)
        local sourceType = requisitionSourceType(requisition)
        local name, item = nil, nil
        if sourceType == "loot_table" then _, name = resolveLootDisplay(requisition and requisition.lootRef)
        else item, name = resolveItemDisplay(requisition) end
        row:SetCategory(name)
        row:SetTestName("")
        local quantity = normalizeInteger(requisition and requisition.quantity, 1, 1)
        local characterLimit = normalizeInteger(requisition and requisition.characterLimit, 1, 0)
        row:SetStatus(("%s%d / %s"):format(sourceType == "loot_table" and "rolls " or "x", quantity, characterLimit == 0 and "∞" or tostring(characterLimit)))
        row:SetDetail("")
        if row.categoryRegion and row.categoryRegion.SetTextColor then
            if sourceType == "loot_table" then row.categoryRegion:SetTextColor(primaryTextColor())
            else row.categoryRegion:SetTextColor(qualityColor(item)) end
        end
        local rawIndex = self.GuildSettingRequisitionVisibleRawIndices and self.GuildSettingRequisitionVisibleRawIndices[visibleIndex] or visibleIndex
        local frame = row.GetFrame and row:GetFrame() or nil
        if frame then
            frame:EnableMouse(true)
            frame:SetScript("OnMouseUp", function(_, button)
                if button == "LeftButton" then
                    self.SelectedGuildSettingRequisitionIndex = rawIndex
                    self.SelectedGuildSettingCostIndex = nil
                    self:RefreshGuildSettingRequisitionsPage()
                end
            end)
        end
        setRowSelection(row, tonumber(self.SelectedGuildSettingRequisitionIndex) == tonumber(rawIndex))
    end)
end

function DataEditor:InstallGuildSettingDailyRewardRowRenderer()
    local scroll = self.GuildSettingInspectorDailyRewardScroll
    if not scroll then return end
    scroll:SetRowRenderer(function(row, reward, index)
        local rewardType = dailyRewardType(reward)
        local name = "Unassigned Reward"
        if rewardType == "loot_table" then
            _, name = resolveLootDisplay(reward and reward.ref)
        elseif rewardType == "currency" then
            local ref = trim(reward and reward.ref)
            local key = type(Profile.NormalizeCurrencyKey) == "function" and trim(Profile.NormalizeCurrencyKey(ref)) or ref
            if type(Profile.ResolveCurrencyDefinition) == "function" then
                local ok, definition = pcall(Profile.ResolveCurrencyDefinition, key)
                if ok and type(definition) == "table" and definition.isMissing ~= true then
                    name = trim(definition.name) ~= "" and trim(definition.name) or ref
                elseif ref ~= "" then name = "Missing Currency" end
            elseif ref ~= "" then name = ref end
        else
            local _, itemName = resolveItemDisplay({ itemRef = reward and reward.ref })
            name = itemName
        end
        local amount = normalizeInteger(reward and reward.amount, 1, 1)
        row:SetCategory(name)
        row:SetTestName("")
        row:SetStatus(rewardType == "loot_table" and "Loot Table" or (rewardType == "currency" and "Currency" or "Item"))
        row:SetDetail(rewardType == "loot_table" and ("%d roll%s"):format(amount, amount == 1 and "" or "s") or ("x%d"):format(amount))
        if row.categoryRegion and row.categoryRegion.SetTextColor then row.categoryRegion:SetTextColor(primaryTextColor()) end
        local frame = row.GetFrame and row:GetFrame() or nil
        if frame then
            frame:EnableMouse(true)
            frame:SetScript("OnMouseUp", function(_, button)
                if button == "LeftButton" then
                    self.SelectedGuildSettingDailyRewardIndex = index
                    self:RefreshGuildSettingDailyRewardsPage()
                end
            end)
        end
        setRowSelection(row, tonumber(self.SelectedGuildSettingDailyRewardIndex) == tonumber(index))
    end)
end

function DataEditor:BuildGuildSettingRequisitionLootTableEditor()
    if self.GuildSettingInspectorRequisitionSourceTypeDropdown then return end
    local page = self.GuildSettingInspectorRequisitionsPage
    local shell = page and page._guildSettingPageScrollShell or nil
    local root = shell and shell.root or nil
    if not root then return end

    local sourceGroup = createFieldGroup(root, "RPEDataEditorGuildSettingInspectorRequisitionSourceTypeGroup", "Reward Type")
    self.GuildSettingInspectorRequisitionSourceTypeDropdown = UI.CreateDropdown(sourceGroup:GetFrame(), "RPEDataEditorGuildSettingInspectorRequisitionSourceTypeDropdown", {
        width = FIELD_WIDTH, height = CONTROL_HEIGHT, items = REQUISITION_SOURCE_ITEMS,
        onValueChanged = function(value)
            if self._refreshingGuildSettingLootEditor then return end
            local _, _, index = getSelectedRequisition(self)
            self:CommitSelectedGuildSetting(function(setting)
                local requisition = setting.requisitions and setting.requisitions[index]
                if requisition then requisition.sourceType = value == "loot_table" and "loot_table" or "item" end
            end)
            self:RefreshGuildSettingRequisitionsPage()
        end,
    })
    sourceGroup:AddChild(self.GuildSettingInspectorRequisitionSourceTypeDropdown)
    root:AddChild(sourceGroup)

    local lootDatasetGroup = createFieldGroup(root, "RPEDataEditorGuildSettingInspectorRequisitionLootDatasetGroup", "Loot Dataset")
    self.GuildSettingInspectorRequisitionLootDatasetDropdown = UI.CreateDropdown(lootDatasetGroup:GetFrame(), "RPEDataEditorGuildSettingInspectorRequisitionLootDatasetDropdown", {
        width = FIELD_WIDTH, height = CONTROL_HEIGHT, items = { { label = "None", value = "" } },
        onValueChanged = function(value)
            if self._refreshingGuildSettingLootEditor then return end
            local _, _, index = getSelectedRequisition(self)
            self:CommitSelectedGuildSetting(function(setting)
                local requisition = setting.requisitions and setting.requisitions[index]
                if requisition then requisition.lootRef = "" end
            end)
            if self.GuildSettingInspectorRequisitionLootDropdown then
                self.GuildSettingInspectorRequisitionLootDropdown:SetItems(buildLootReferenceItems(self, value, ""))
                self.GuildSettingInspectorRequisitionLootDropdown:SetSelectedValue("", true)
            end
            self:RefreshGuildSettingRequisitionsPage()
        end,
    })
    lootDatasetGroup:AddChild(self.GuildSettingInspectorRequisitionLootDatasetDropdown)
    root:AddChild(lootDatasetGroup)

    local lootGroup = createFieldGroup(root, "RPEDataEditorGuildSettingInspectorRequisitionLootGroup", "Loot Table")
    self.GuildSettingInspectorRequisitionLootDropdown = UI.CreateDropdown(lootGroup:GetFrame(), "RPEDataEditorGuildSettingInspectorRequisitionLootDropdown", {
        width = FIELD_WIDTH, height = CONTROL_HEIGHT, items = { { label = "None", value = "" } },
        onValueChanged = function(value)
            if self._refreshingGuildSettingLootEditor then return end
            local _, _, index = getSelectedRequisition(self)
            self:CommitSelectedGuildSetting(function(setting)
                local requisition = setting.requisitions and setting.requisitions[index]
                if requisition then requisition.lootRef = trim(value) end
            end)
            self:RefreshGuildSettingRequisitionsPage()
        end,
    })
    lootGroup:AddChild(self.GuildSettingInspectorRequisitionLootDropdown)
    root:AddChild(lootGroup)

    self.GuildSettingInspectorRequisitionSourceTypeGroup = sourceGroup
    self.GuildSettingInspectorRequisitionLootDatasetGroup = lootDatasetGroup
    self.GuildSettingInspectorRequisitionLootGroup = lootGroup
    moveChildrenBefore(root, "RPEDataEditorGuildSettingInspectorRequisitionItemDatasetGroup", { sourceGroup, lootDatasetGroup, lootGroup })
end

function DataEditor:BuildGuildSettingDailyRewardLootTableEditor()
    if self.GuildSettingInspectorDailyRewardLootDatasetDropdown then return end
    local page = self.GuildSettingInspectorDailyRewardsPage
    local shell = page and page._guildSettingPageScrollShell or nil
    local root = shell and shell.root or nil
    if not root then return end
    if self.GuildSettingInspectorDailyRewardTypeDropdown then self.GuildSettingInspectorDailyRewardTypeDropdown:SetItems(DAILY_REWARD_TYPE_ITEMS) end

    local lootDatasetGroup = createFieldGroup(root, "RPEDataEditorGuildSettingInspectorDailyRewardLootDatasetGroup", "Loot Dataset")
    self.GuildSettingInspectorDailyRewardLootDatasetDropdown = UI.CreateDropdown(lootDatasetGroup:GetFrame(), "RPEDataEditorGuildSettingInspectorDailyRewardLootDatasetDropdown", {
        width = FIELD_WIDTH, height = CONTROL_HEIGHT, items = { { label = "None", value = "" } },
        onValueChanged = function(value)
            if self._refreshingGuildSettingLootEditor then return end
            local _, _, index = getSelectedDailyReward(self)
            self:CommitSelectedGuildSetting(function(setting)
                local reward = setting.dailyRewards and setting.dailyRewards[index]
                if reward then reward.ref = "" end
            end)
            if self.GuildSettingInspectorDailyRewardLootDropdown then
                self.GuildSettingInspectorDailyRewardLootDropdown:SetItems(buildLootReferenceItems(self, value, ""))
                self.GuildSettingInspectorDailyRewardLootDropdown:SetSelectedValue("", true)
            end
            self:RefreshGuildSettingDailyRewardsPage()
        end,
    })
    lootDatasetGroup:AddChild(self.GuildSettingInspectorDailyRewardLootDatasetDropdown)
    root:AddChild(lootDatasetGroup)

    local lootGroup = createFieldGroup(root, "RPEDataEditorGuildSettingInspectorDailyRewardLootGroup", "Loot Table")
    self.GuildSettingInspectorDailyRewardLootDropdown = UI.CreateDropdown(lootGroup:GetFrame(), "RPEDataEditorGuildSettingInspectorDailyRewardLootDropdown", {
        width = FIELD_WIDTH, height = CONTROL_HEIGHT, items = { { label = "None", value = "" } },
        onValueChanged = function(value)
            if self._refreshingGuildSettingLootEditor then return end
            local _, _, index = getSelectedDailyReward(self)
            self:CommitSelectedGuildSetting(function(setting)
                local reward = setting.dailyRewards and setting.dailyRewards[index]
                if reward then reward.ref = trim(value) end
            end)
            self:RefreshGuildSettingDailyRewardsPage()
        end,
    })
    lootGroup:AddChild(self.GuildSettingInspectorDailyRewardLootDropdown)
    root:AddChild(lootGroup)

    self.GuildSettingInspectorDailyRewardLootDatasetGroup = lootDatasetGroup
    self.GuildSettingInspectorDailyRewardLootGroup = lootGroup
    moveChildrenBefore(root, "RPEDataEditorGuildSettingInspectorDailyRewardItemDatasetGroup", { lootDatasetGroup, lootGroup })
end

function DataEditor:SetupGuildSettingLootTableEditors()
    self:BuildGuildSettingRequisitionLootTableEditor()
    self:BuildGuildSettingDailyRewardLootTableEditor()
    self:InstallGuildSettingRequisitionRowRenderer()
    self:InstallGuildSettingDailyRewardRowRenderer()
end

function DataEditor:RefreshGuildSettingRequisitionLootTableControls()
    self:BuildGuildSettingRequisitionLootTableEditor()
    local _, requisition = getSelectedRequisition(self)
    local sourceType = requisitionSourceType(requisition)
    local lootRef = trim(requisition and requisition.lootRef)
    local lootDatasetId = select(1, parseQualifiedRef(lootRef)) or ""

    self._refreshingGuildSettingLootEditor = true
    if self.GuildSettingInspectorRequisitionSourceTypeDropdown then
        self.GuildSettingInspectorRequisitionSourceTypeDropdown:SetItems(REQUISITION_SOURCE_ITEMS)
        self.GuildSettingInspectorRequisitionSourceTypeDropdown:SetSelectedValue(sourceType, true)
        setDropdownEnabled(self.GuildSettingInspectorRequisitionSourceTypeDropdown, requisition ~= nil)
    end
    if self.GuildSettingInspectorRequisitionLootDatasetDropdown then
        self.GuildSettingInspectorRequisitionLootDatasetDropdown:SetItems(buildLootDatasetItems(self, lootDatasetId))
        self.GuildSettingInspectorRequisitionLootDatasetDropdown:SetSelectedValue(lootDatasetId, true)
        setDropdownEnabled(self.GuildSettingInspectorRequisitionLootDatasetDropdown, requisition ~= nil and sourceType == "loot_table")
    end
    if self.GuildSettingInspectorRequisitionLootDropdown then
        self.GuildSettingInspectorRequisitionLootDropdown:SetItems(buildLootReferenceItems(self, lootDatasetId, lootRef))
        self.GuildSettingInspectorRequisitionLootDropdown:SetSelectedValue(lootRef, true)
        setDropdownEnabled(self.GuildSettingInspectorRequisitionLootDropdown, requisition ~= nil and sourceType == "loot_table" and lootDatasetId ~= "")
    end
    self._refreshingGuildSettingLootEditor = false

    setLayoutElementVisible(self.GuildSettingInspectorRequisitionLootDatasetGroup, requisition ~= nil and sourceType == "loot_table")
    setLayoutElementVisible(self.GuildSettingInspectorRequisitionLootGroup, requisition ~= nil and sourceType == "loot_table")
    local page = self.GuildSettingInspectorRequisitionsPage
    local root = page and page._guildSettingPageScrollShell and page._guildSettingPageScrollShell.root or nil
    setLayoutElementVisible(findChildRecursive(root, "RPEDataEditorGuildSettingInspectorRequisitionItemDatasetGroup"), requisition ~= nil and sourceType == "item")
    setLayoutElementVisible(findChildRecursive(root, "RPEDataEditorGuildSettingInspectorRequisitionItemGroup"), requisition ~= nil and sourceType == "item")
    local quantityLabel = findChildRecursive(root, "RPEDataEditorGuildSettingInspectorQuantityLabel")
    if quantityLabel and quantityLabel.SetText then quantityLabel:SetText(sourceType == "loot_table" and "Rolls" or "Quantity") end
    if root and root.RefreshLayout then root:RefreshLayout() end
    self:InstallGuildSettingRequisitionRowRenderer()
end

function DataEditor:RefreshGuildSettingDailyRewardLootTableControls()
    self:BuildGuildSettingDailyRewardLootTableEditor()
    local _, reward = getSelectedDailyReward(self)
    local rewardType = dailyRewardType(reward)
    local rewardRef = trim(reward and reward.ref)
    local lootRef = rewardType == "loot_table" and rewardRef or ""
    local lootDatasetId = select(1, parseQualifiedRef(lootRef)) or ""

    self._refreshingGuildSettingLootEditor = true
    if self.GuildSettingInspectorDailyRewardTypeDropdown then
        self.GuildSettingInspectorDailyRewardTypeDropdown:SetItems(DAILY_REWARD_TYPE_ITEMS)
        self.GuildSettingInspectorDailyRewardTypeDropdown:SetSelectedValue(rewardType, true)
        setDropdownEnabled(self.GuildSettingInspectorDailyRewardTypeDropdown, reward ~= nil)
    end
    if self.GuildSettingInspectorDailyRewardLootDatasetDropdown then
        self.GuildSettingInspectorDailyRewardLootDatasetDropdown:SetItems(buildLootDatasetItems(self, lootDatasetId))
        self.GuildSettingInspectorDailyRewardLootDatasetDropdown:SetSelectedValue(lootDatasetId, true)
        setDropdownEnabled(self.GuildSettingInspectorDailyRewardLootDatasetDropdown, reward ~= nil and rewardType == "loot_table")
    end
    if self.GuildSettingInspectorDailyRewardLootDropdown then
        self.GuildSettingInspectorDailyRewardLootDropdown:SetItems(buildLootReferenceItems(self, lootDatasetId, lootRef))
        self.GuildSettingInspectorDailyRewardLootDropdown:SetSelectedValue(lootRef, true)
        setDropdownEnabled(self.GuildSettingInspectorDailyRewardLootDropdown, reward ~= nil and rewardType == "loot_table" and lootDatasetId ~= "")
    end
    self._refreshingGuildSettingLootEditor = false

    setLayoutElementVisible(self.GuildSettingInspectorDailyRewardLootDatasetGroup, reward ~= nil and rewardType == "loot_table")
    setLayoutElementVisible(self.GuildSettingInspectorDailyRewardLootGroup, reward ~= nil and rewardType == "loot_table")
    setLayoutElementVisible(self.GuildSettingInspectorDailyRewardItemDatasetGroup, reward ~= nil and rewardType == "item")
    setLayoutElementVisible(self.GuildSettingInspectorDailyRewardItemGroup, reward ~= nil and rewardType == "item")
    setLayoutElementVisible(self.GuildSettingInspectorDailyRewardCurrencyGroup, reward ~= nil and rewardType == "currency")
    local page = self.GuildSettingInspectorDailyRewardsPage
    local root = page and page._guildSettingPageScrollShell and page._guildSettingPageScrollShell.root or nil
    local amountLabel = findChildRecursive(root, "RPEDataEditorGuildSettingInspectorDailyRewardAmountLabel")
    if amountLabel and amountLabel.SetText then amountLabel:SetText(rewardType == "loot_table" and "Rolls" or "Amount") end
    if root and root.RefreshLayout then root:RefreshLayout() end
    self:InstallGuildSettingDailyRewardRowRenderer()
end

if type(BaseBuildGuildSettingInspectorPage) == "function" then
    function DataEditor:BuildGuildSettingInspectorPage(parent)
        local page = BaseBuildGuildSettingInspectorPage(self, parent)
        self:SetupGuildSettingLootTableEditors()
        self:RefreshGuildSettingRequisitionLootTableControls()
        self:RefreshGuildSettingDailyRewardLootTableControls()
        return page
    end
end

if type(BaseRefreshGuildSettingRequisitionsPage) == "function" then
    function DataEditor:RefreshGuildSettingRequisitionsPage(...)
        local result = BaseRefreshGuildSettingRequisitionsPage(self, ...)
        self:RefreshGuildSettingRequisitionLootTableControls()
        return result
    end
end

if type(BaseRefreshGuildSettingDailyRewardsPage) == "function" then
    function DataEditor:RefreshGuildSettingDailyRewardsPage(...)
        local result = BaseRefreshGuildSettingDailyRewardsPage(self, ...)
        self:RefreshGuildSettingDailyRewardLootTableControls()
        return result
    end
end

if type(BaseRefreshGuildSettingInspectorPage) == "function" then
    function DataEditor:RefreshGuildSettingInspectorPage(...)
        local result = BaseRefreshGuildSettingInspectorPage(self, ...)
        self:SetupGuildSettingLootTableEditors()
        self:RefreshGuildSettingRequisitionLootTableControls()
        self:RefreshGuildSettingDailyRewardLootTableControls()
        return result
    end
end
end

-- Defaults are stored in SavedVariables. This migration replaces older copies
-- that were installed from packages whose contents changed without a matching
-- per-dataset version bump, so all clients converge on this release's data.
-- Revision 2 installs the role-gated profession loot-table requisitions into
-- the saved Core dataset, including installations with stale per-dataset
-- version metadata from earlier Core package updates.
local PACKAGED_DEFAULT_SYNC_REVISION = 2

local function logInstallDiagnostic(message)
    local debug = Addon.Debug or nil
    if debug and type(debug.Internal) == "function" then
        debug.Internal(
            "Packaged default dataset installation skipped: %s",
            tostring(message or "unknown error")
        )
    end
end

local function applyPackagedVersionCorrections(definitions)
    -- Leatherworking v2 contents were briefly packaged with version 1, so
    -- clients that had already recorded v1 would otherwise skip the rewrite.
    -- Keep this as a version floor so future packaged versions remain authoritative.
    local leatherworking = definitions["538a54a0"]
    if type(leatherworking) == "table"
        and type(leatherworking.version) == "number"
        and leatherworking.version < 2
    then
        leatherworking.version = 2
    end
end

local function syncDefaultDatasets()
    local Database = Addon.Internal and Addon.Internal.Database or nil
    local DefaultDatasets = Addon.Data and Addon.Data.DefaultDatasets or nil

    if type(Database) ~= "table" then
        logInstallDiagnostic("database module is unavailable")
        return false
    end
    if type(Database.SyncDefaultDatasets) ~= "function" then
        logInstallDiagnostic("default dataset synchronization API is unavailable")
        return false
    end
    if type(DefaultDatasets) ~= "table" or type(DefaultDatasets.Definitions) ~= "table" then
        logInstallDiagnostic("packaged default dataset definitions are unavailable")
        return false
    end

    -- SavedVariables become authoritative at ADDON_LOADED. Database.lua also
    -- listens for that event, so do not depend on frame-handler ordering: if its
    -- cached root still points at the pre-SavedVariables table, rebind through
    -- the canonical EnsureDatasets() path before synchronizing packages.
    local globalEnvironment = _G or {}
    local savedRoot = rawget(globalEnvironment, "RPEngineDatasetDB")
    if type(savedRoot) ~= "table" or Database.Datasets ~= savedRoot then
        if type(Database.EnsureDatasets) ~= "function" then
            logInstallDiagnostic("dataset SavedVariables root is not initialized")
            return false
        end
        Database.EnsureDatasets()
        savedRoot = rawget(globalEnvironment, "RPEngineDatasetDB")
    end

    if type(savedRoot) ~= "table" or Database.Datasets ~= savedRoot then
        logInstallDiagnostic("dataset SavedVariables root is not authoritative")
        return false
    end

    applyPackagedVersionCorrections(DefaultDatasets.Definitions)
    if type(DefaultDatasets.ValidateTraitOwnership) == "function" then
        local valid, message = DefaultDatasets:ValidateTraitOwnership()
        if valid ~= true then
            logInstallDiagnostic(message or "default trait ownership validation failed")
            return false
        end
    end

    local installedRevision = math.max(0, math.floor(tonumber(savedRoot.defaultDatasetSyncRevision) or 0))
    local forceSync = installedRevision < PACKAGED_DEFAULT_SYNC_REVISION
    local _, skippedDefinitions = Database.SyncDefaultDatasets(DefaultDatasets.Definitions, {
        force = forceSync,
    })
    if skippedDefinitions ~= 0 then
        logInstallDiagnostic(("%d packaged default dataset definition(s) failed validation."):format(skippedDefinitions))
        return false
    end

    savedRoot.defaultDatasetSyncRevision = PACKAGED_DEFAULT_SYNC_REVISION
    return true
end

-- Runtime owns ADDON_LOADED sequencing. Expose the canonical installer there
-- so it rebinds SavedVariables and synchronizes defaults before Manager work.
Addon.Data.SyncDefaultDatasets = syncDefaultDatasets
