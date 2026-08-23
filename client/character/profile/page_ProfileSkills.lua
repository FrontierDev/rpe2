local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Profile = Addon.Client.UI.Profile or {}

local ProfileUI = Addon.Client.UI.Profile
local UI = Addon.UI or {}
local TooltipBuilders = Addon.Client.UI and Addon.Client.UI.Tooltips or {}
local Database = Addon.Internal and Addon.Internal.Database or {}
local Dependencies = Database.Dependecies or {}
local Profile = Addon.Internal and Addon.Internal.Profile or {}
local Equipment = Profile and Profile.Equipment or {}
local Registry = Addon.Internal and Addon.Internal.Registry or {}
local Common = Addon.Utils and Addon.Utils.Common or {}
local Debug = Addon.Debug or {}
local Client = Addon.Client or {}
local Crafting = Client and Client.Crafting or nil
local Tasks = Addon.Internal and Addon.Internal.Tasks or {}
local SkillsPage = ProfileUI.SkillsPage or {}
ProfileUI.SkillsPage = SkillsPage

local NAV_PANEL_WIDTH = 168
local ENTRY_HEIGHT = 28
local ENTRY_SPACING = 4
local ENTRY_ROWS = 8
local GRID_PADDING = 8
local SKILL_LIST_SYNC_OVERSCAN = 4
local SKILL_LIST_ASYNC_BATCH_SIZE = 12
local TRAINER_BUTTON_TEXTURE = "Interface\\Icons\\Ability_Hunter_BeastTraining"
local CRAFTING_RECIPE_SYNC_OVERSCAN = 4
local CRAFTING_RECIPE_ASYNC_BATCH_SIZE = 12
local CRAFTING_TRAINER_SYNC_OVERSCAN = 4
local CRAFTING_TRAINER_ASYNC_BATCH_SIZE = 12
local CRAFTING_UI_INTERNAL_TRACE = false

local CATEGORY_DEFINITIONS = {
    { key = "weapon", label = "Weapon Skills" },
    { key = "noncombat", label = "Non-Combat Skills" },
    { key = "crafting", label = "Crafting Skills" },
    { key = "language", label = "Language Skills" },
}

local function ensureString(value)
    if value == nil then
        return ""
    end

    return tostring(value)
end

local function normalizeSearchToken(value)
    return string.lower(ensureString(value)):gsub("^%s+", ""):gsub("%s+$", "")
end

local function setElementVisibility(element, visible, height)
    if not element then
        return
    end

    local frame = element.GetFrame and element:GetFrame() or nil
    if element.SetHeight and height ~= nil then
        element:SetHeight(visible and height or 0)
    elseif element.options and height ~= nil then
        element.options.height = visible and height or 0
    end

    if frame then
        if height ~= nil and frame.SetHeight then
            frame:SetHeight(visible and height or 0)
        end
        if visible then
            frame:Show()
        else
            frame:Hide()
        end
    end
end

local function setWeightedVisibility(element, visible, height, expandHeight, weight)
    if not element then
        return
    end

    element.options = element.options or {}
    if visible then
        if height ~= nil then
            element.options.height = height
        end
        element.options.expandHeight = expandHeight == true
        element.options.weight = weight
    else
        element.options.height = 0
        element.options.expandHeight = false
        element.options.weight = 0
    end

    setElementVisibility(element, visible, height)
end

local function logSkillsInfo(message, ...)
    if Debug and type(Debug.Info) == "function" then
        Debug.Info(message, ...)
    end
end

local function getTimingMilliseconds()
    if type(debugprofilestop) == "function" then
        return tonumber(debugprofilestop()) or 0
    end
    if type(GetTimePreciseSec) == "function" then
        return (tonumber(GetTimePreciseSec()) or 0) * 1000
    end
    return 0
end

local function getElapsedMilliseconds(startedAt)
    local started = tonumber(startedAt) or 0
    return math.max(0, getTimingMilliseconds() - started)
end

local function logSkillsInternal(message, ...)
    if CRAFTING_UI_INTERNAL_TRACE ~= true then
        return
    end
    if Debug and type(Debug.SetLevelEnabled) == "function" and type(Debug.IsLevelEnabled) == "function" and not Debug.IsLevelEnabled("internal") then
        Debug.SetLevelEnabled("internal", true)
    end
    if Debug and type(Debug.Internal) == "function" then
        Debug.Internal(message, ...)
    end
end

local function getSkillRuleValue(ruleKey, fallback)
    local ruleset = Addon.Internal and Addon.Internal.Ruleset and Addon.Internal.Ruleset.GetActiveRuleset and Addon.Internal.Ruleset.GetActiveRuleset() or nil
    local rulesetLogic = Addon.Internal and Addon.Internal.Ruleset or nil
    local value = nil
    if rulesetLogic and rulesetLogic.GetRulesetRuleDefinition and rulesetLogic.GetRulesetRuleValue then
        local ruleDefinition = rulesetLogic.GetRulesetRuleDefinition("skills", ruleKey)
        value = rulesetLogic.GetRulesetRuleValue(ruleset, "skills", ruleDefinition)
    end
    if value == nil then
        return fallback
    end

    return value
end

local function isCategoryEnabled(categoryKey)
    if categoryKey == "weapon" then
        return getSkillRuleValue("use_weapon_skills", true) ~= false
    end
    if categoryKey == "crafting" then
        return getSkillRuleValue("use_crafting_skills", true) ~= false
    end
    if categoryKey == "language" then
        return getSkillRuleValue("use_language_skills", true) ~= false
    end

    return getSkillRuleValue("use_noncombat_skills", true) ~= false
end

local function normalizeSkillCategoryKey(skill)
    local skillType = ensureString(type(skill) == "table" and skill.skillType or "")
    if skillType == "" then
        return "noncombat"
    end
    return skillType
end

local function composeSkillRef(datasetId, skillId)
    local normalizedDatasetId = ensureString(datasetId)
    local normalizedSkillId = ensureString(skillId)
    if normalizedDatasetId == "" or normalizedSkillId == "" then
        return ""
    end
    if Dependencies and Dependencies.ComposeSourceStatRef then
        return ensureString(Dependencies.ComposeSourceStatRef(normalizedDatasetId, normalizedSkillId))
    end
    return ("%s:%s"):format(normalizedDatasetId, normalizedSkillId)
end

local function compareSkillRows(left, right)
    local leftName = string.lower(ensureString(left and left.name))
    local rightName = string.lower(ensureString(right and right.name))
    if leftName == rightName then
        return ensureString(left and left.skillId) < ensureString(right and right.skillId)
    end
    return leftName < rightName
end

local function buildResolvedRowsForCategory(categoryKey, skillRefsByCategory)
    local normalizedCategory = ensureString(categoryKey)
    local skillRefs = skillRefsByCategory and skillRefsByCategory[normalizedCategory] or {}
    if Profile.GetResolvedSkillRowsByRefs then
        local rows = Profile.GetResolvedSkillRowsByRefs(skillRefs) or {}
        table.sort(rows, compareSkillRows)
        return rows
    end

    local rows = Profile.ListResolvedSkills and Profile.ListResolvedSkills() or {}
    local filtered = {}
    for index = 1, #rows do
        local row = rows[index]
        if ensureString(row and row.skillType) == normalizedCategory then
            filtered[#filtered + 1] = row
        end
    end
    table.sort(filtered, compareSkillRows)
    return filtered
end

local function buildNavigationRows()
    local rows = {}
    local counts = { weapon = 0, noncombat = 0, crafting = 0, language = 0 }
    local skillRefsByCategory = {
        weapon = {},
        noncombat = {},
        crafting = {},
        language = {},
    }
    local skillEntriesByCategory = {
        weapon = {},
        noncombat = {},
        crafting = {},
        language = {},
    }
    local authoredCount = 0

    local datasets = Registry.GetActivatedDatasets and Registry:GetActivatedDatasets() or {}
    for datasetIndex = 1, #datasets do
        local dataset = datasets[datasetIndex]
        authoredCount = authoredCount + #(dataset and dataset.skills or {})
        local datasetId = ensureString(dataset and dataset.id)
        for skillIndex = 1, #(dataset and dataset.skills or {}) do
            local skill = dataset.skills[skillIndex]
            local skillType = normalizeSkillCategoryKey(skill)
            if counts[skillType] ~= nil then
                local skillRef = composeSkillRef(datasetId, skill and skill.id)
                if skillRef ~= "" then
                    skillEntriesByCategory[skillType][#skillEntriesByCategory[skillType] + 1] = {
                        ref = skillRef,
                        skillId = ensureString(skill and skill.id),
                        skillType = skillType,
                        name = ensureString(skill and skill.name) ~= "" and ensureString(skill and skill.name) or ensureString(skill and skill.id),
                        icon = ensureString(skill and skill.icon),
                    }
                end
            end
        end
    end

    for categoryKey, entries in pairs(skillEntriesByCategory) do
        table.sort(entries, compareSkillRows)
        counts[categoryKey] = #entries
        local refs = skillRefsByCategory[categoryKey]
        for index = 1, #entries do
            refs[index] = entries[index].ref
        end
    end

    for index = 1, #CATEGORY_DEFINITIONS do
        local definition = CATEGORY_DEFINITIONS[index]
        if isCategoryEnabled(definition.key) then
            rows[#rows + 1] = {
                key = definition.key,
                name = definition.label,
                count = counts[definition.key] or 0,
            }
        end
    end

    return rows, skillRefsByCategory, skillEntriesByCategory, authoredCount
end

local function refreshNavListVisualRows(page, navRows)
    local navList = page and page.NavList or nil
    local rows = navList and navList.rows or nil
    if not rows then
        return
    end

    for index = 1, #rows do
        local row = rows[index]
        local item = navRows and navRows[index] or nil
        local frame = row and row.GetFrame and row:GetFrame() or nil

        if item then
            if row.SetCategory then
                row:SetCategory(item.name or "")
            end
            if row.SetTestName then
                row:SetTestName("")
            end
            if row.SetStatus then
                row:SetStatus(tostring(item.count or 0))
            end
            if row.SetDetail then
                row:SetDetail("")
            end

            if frame then
                if frame.Show then
                    frame:Show()
                end
                frame:EnableMouse(true)
            end

            local isSelected = tostring(item.key or "") == tostring(page.SelectedCategoryKey or "")
            if row.entryBackground and row.entryBackground.SetColorTexture then
                local token = isSelected and "list.rowHover" or "list.rowBackground"
                local color = UI.ResolveColor(nil, token)
                row.entryBackground:SetColorTexture(color.r or 0.08, color.g or 0.09, color.b or 0.11, color.a or 0.85)
            end
        else
            if row.SetCategory then
                row:SetCategory("")
            end
            if row.SetTestName then
                row:SetTestName("")
            end
            if row.SetStatus then
                row:SetStatus("")
            end
            if row.SetDetail then
                row:SetDetail("")
            end
            if frame and frame.Hide then
                frame:Hide()
            end
        end
    end
end

local function resolveDerivedStatLabel(statRef)
    if type(Registry.ResolveStatName) == "function" then
        return Registry:ResolveStatName(statRef)
    end

    local text = tostring(statRef or "")
    local _, statId = text:match("^([^:]+):(.+)$")
    return statId or text
end

local function resolveSkillDescription(row)
    local text = tostring(row and row.description or "")
    if text ~= "" then
        return text
    end

    return "No description provided for this skill."
end

local function formatFooterLevelText(row)
    if not row then
        return "Level -- / --"
    end

    local text = ("Level %d / %d"):format(tonumber(row.value) or 0, tonumber(row.maxValue) or 0)
    local bonusValue = tonumber(row.bonusValue) or 0
    if bonusValue > 0 then
        text = text .. (" |cff55ff55(+%d)|r"):format(bonusValue)
    end

    return text
end

local function getQualityColor(item)
    local quality = type(item) == "table" and tostring(item.quality or "common") or "common"
    if type(ITEM_QUALITY_COLORS) == "table" and ITEM_QUALITY_COLORS[quality] then
        local color = ITEM_QUALITY_COLORS[quality]
        return color.r or 1, color.g or 1, color.b or 1
    end

    local fallback = {
        poor = { 0.62, 0.62, 0.62 },
        common = { 1, 1, 1 },
        uncommon = { 0.12, 1, 0 },
        rare = { 0, 0.44, 0.87 },
        epic = { 0.64, 0.21, 0.93 },
        legendary = { 1, 0.5, 0 },
    }
    local row = fallback[quality] or fallback.common
    return row[1], row[2], row[3]
end

local function colorizeText(text, item)
    local r, g, b = getQualityColor(item)
    return ("|cff%02x%02x%02x%s|r"):format(
        math.floor((r or 1) * 255),
        math.floor((g or 1) * 255),
        math.floor((b or 1) * 255),
        tostring(text or "")
    )
end

local function getCraftingRecipeLevelColor(detail)
    local skillLevel = math.max(0, tonumber(detail and detail.skillLevel) or 0)
    local requiredLevel = math.max(0, tonumber(detail and detail.requiredSkillLevel) or 0)
    local delta = skillLevel - requiredLevel

    if delta < 0 then
        return { r = 0.95, g = 0.4, b = 0.4, a = 1 }
    end
    if delta <= 4 then
        return { r = 1.0, g = 0.82, b = 0.25, a = 1 }
    end
    if delta <= 14 then
        return { r = 0.33, g = 0.9, b = 0.45, a = 1 }
    end

    local mutedColor = UI.ResolveColor(nil, "text.muted")
    return {
        r = mutedColor.r or 0.65,
        g = mutedColor.g or 0.65,
        b = mutedColor.b or 0.65,
        a = mutedColor.a or 1,
    }
end

local function getCraftingSkillUpChance(detail)
    local skillLevel = math.max(0, tonumber(detail and detail.skillLevel) or 0)
    local requiredLevel = math.max(0, tonumber(detail and detail.requiredSkillLevel) or 0)
    local delta = skillLevel - requiredLevel

    if delta < 0 then
        return 100
    end
    if delta <= 4 then
        return 75
    end
    if delta <= 14 then
        return 35
    end

    return 0
end

local function buildCraftingOutputTooltip(detail)
    if type(detail) ~= "table" or type(detail.output) ~= "table" then
        return nil
    end

    local item = detail.output.item
    local dataset = detail.dataset

    if type(item) ~= "table" and type(Equipment.ResolveItemDefinition) == "function" then
        item, dataset = Equipment.ResolveItemDefinition(ensureString(detail.output.itemRef))
    end

    if type(item) ~= "table" then
        return nil
    end

    local builder = TooltipBuilders and TooltipBuilders.Item or nil
    local datasetName = dataset and Database.GetDatasetDisplayName and Database.GetDatasetDisplayName(dataset) or "Unknown Dataset"

    if builder and builder.Build then
        local tooltip = builder:Build(item, {
            dataset = dataset,
            datasetId = dataset and dataset.id or nil,
            datasetName = datasetName,
            itemId = item.id,
            itemRef = detail.output.itemRef,
            isActive = true,
            isMissing = false,
            soulbound = false,
            modifications = nil,
        })
        if tooltip then
            return tooltip
        end
    end

    return {
        type = "custom",
        title = ensureString(item.name, detail.name or "Item"),
        lines = {
            ("Dataset: %s"):format(datasetName),
        },
    }
end

local function buildCraftingConversionItemTooltip(rowData)
    if type(rowData) ~= "table" or type(rowData.item) ~= "table" then
        return nil
    end

    local builder = TooltipBuilders and TooltipBuilders.Item or nil
    local dataset = rowData.dataset
    local datasetName = dataset and Database.GetDatasetDisplayName and Database.GetDatasetDisplayName(dataset) or "Unknown Dataset"
    if builder and builder.Build then
        local tooltip = builder:Build(rowData.item, {
            dataset = dataset,
            datasetId = dataset and dataset.id or nil,
            datasetName = datasetName,
            itemId = rowData.item.id,
            itemRef = rowData.itemRef,
            isActive = true,
            isMissing = false,
            soulbound = false,
            modifications = nil,
        })
        if tooltip then
            return tooltip
        end
    end

    return {
        type = "custom",
        title = ensureString(rowData.name, rowData.item.id or "Item"),
        lines = {
            ("Dataset: %s"):format(datasetName),
        },
    }
end

local function showCraftCountPopup(page, detail)
    if not detail then
        return
    end

    if not Crafting or not (UI.Popup and UI.Popup.ShowConfirmation) then
        return
    end

    local recipeName = detail.output and detail.output.name or detail.name or "recipe"
    return UI.Popup:ShowConfirmation({
        title = "Craft Items",
        width = 280,
        message = ("Craft how many %s?"):format(tostring(recipeName)),
        confirmText = "Craft",
        cancelText = "Cancel",
        inputLabel = "Quantity",
        inputText = "1",
        requireInput = true,
        onConfirm = function(spec)
            local count = math.max(1, math.floor(tonumber(spec and spec.inputText or "1") or 1))
            Crafting:QueueRecipe(detail.recipeRef, count)
        end,
    })
end

function SkillsPage:GetSelectedRows()
    return self.AllSkillRows or {}
end

function SkillsPage:FindSkillRow(skillRef, rows)
    local normalizedRef = tostring(skillRef or "")
    if normalizedRef == "" then
        return nil
    end

    local activeSession = self.SkillListSession
    if activeSession and tostring(activeSession.categoryKey or "") == tostring(self.SelectedCategoryKey or "") then
        local loadedRow = activeSession.loadedRowsByRef and activeSession.loadedRowsByRef[normalizedRef] or nil
        if loadedRow then
            return loadedRow
        end
    end

    local sourceRows = rows or self.AllSkillRows or {}
    for index = 1, #sourceRows do
        local row = sourceRows[index]
        if tostring(row and row.ref or "") == normalizedRef then
            return row
        end
    end

    return nil
end

function SkillsPage:GetSelectedSkillRow()
    return self:FindSkillRow(self.SelectedSkillRef, self.AllSkillRows)
end

function SkillsPage:EnsureSelection(rows)
    local selectedKey = tostring(self.SelectedCategoryKey or "")
    for index = 1, #rows do
        if tostring(rows[index] and rows[index].key or "") == selectedKey then
            return
        end
    end

    self.SelectedCategoryKey = rows[1] and rows[1].key or nil
end

function SkillsPage:BuildCraftingSkillItems()
    local categoryKey = tostring(self.SelectedCategoryKey or "")
    local rows = self.SkillEntriesByCategory and self.SkillEntriesByCategory[categoryKey] or self:GetSelectedRows()
    local items = {}
    for index = 1, #rows do
        local row = rows[index]
        items[#items + 1] = {
            label = row.name or row.ref or ("Skill " .. index),
            value = row.ref,
        }
    end
    return items
end

function SkillsPage:GetSkillListInitialBatchSize()
    local visibleRows = self.EntryScroll and tonumber(self.EntryScroll.visibleRows) or ENTRY_ROWS
    return math.max(1, math.floor(visibleRows) + SKILL_LIST_SYNC_OVERSCAN)
end

function SkillsPage:IsSkillListSessionCurrent(session)
    return session ~= nil
        and self.SkillListSession == session
        and tostring(self.SelectedCategoryKey or "") == tostring(session.categoryKey or "")
end

function SkillsPage:LoadResolvedSkillRowsIntoSession(session, rows)
    if not session or type(rows) ~= "table" then
        return false
    end

    session.loadedRows = session.loadedRows or {}
    session.loadedRowsByRef = session.loadedRowsByRef or {}
    session.loadedRefSet = session.loadedRefSet or {}
    session.items = session.items or {}

    for index = 1, #rows do
        local row = rows[index]
        local skillRef = tostring(row and row.ref or "")
        if skillRef ~= "" then
            session.loadedRowsByRef[skillRef] = row
            local itemIndex = session.orderedIndexByRef and session.orderedIndexByRef[skillRef] or nil
            if itemIndex then
                session.items[itemIndex] = row
            end
            if session.loadedRefSet[skillRef] ~= true then
                session.loadedRefSet[skillRef] = true
                session.loadedRows[#session.loadedRows + 1] = row
            end
        end
    end

    return true
end

function SkillsPage:ApplySkillListSessionRows(session, replaceItems)
    if not self:IsSkillListSessionCurrent(session) then
        return false
    end

    self.AllSkillRows = session.loadedRows or {}
    if self.EntryScroll then
        if replaceItems == true and self.EntryScroll.SetItems then
            self.EntryScroll:SetItems(session.items or {})
        else
            if self.EntryScroll.UpdateGeometry then
                self.EntryScroll:UpdateGeometry()
            end
            if self.EntryScroll.RefreshScrollBar then
                self.EntryScroll:RefreshScrollBar()
            end
            if self.EntryScroll.RefreshRows then
                self.EntryScroll:RefreshRows()
            end
        end
    end

    return true
end

function SkillsPage:QueueSkillListSessionBatch(session)
    if not self:IsSkillListSessionCurrent(session) or session.pendingBatch == true then
        return false
    end
    if (tonumber(session.loadedPrefixCount) or 0) >= (tonumber(session.totalCount) or 0) then
        session.pendingBatch = false
        return false
    end

    session.pendingBatch = true
    local batchStart = (tonumber(session.loadedPrefixCount) or 0) + 1
    local batchSize = math.max(1, SKILL_LIST_ASYNC_BATCH_SIZE)
    local worker = function(page, sessionId, categoryKey, startIndex, requestedCount)
        local activeSession = page and page.SkillListSession or nil
        if not activeSession or tonumber(activeSession.id) ~= tonumber(sessionId) then
            return
        end
        if tostring(activeSession.categoryKey or "") ~= tostring(categoryKey or "") then
            activeSession.pendingBatch = false
            return
        end

        local orderedRefs = activeSession.orderedSkillRefs or {}
        local rangeEnd = math.min(#orderedRefs, math.max(1, math.floor(tonumber(startIndex) or 1)) + math.max(0, math.floor(tonumber(requestedCount) or 0)) - 1)
        local requestedRefs = {}
        for index = math.max(1, math.floor(tonumber(startIndex) or 1)), rangeEnd do
            requestedRefs[#requestedRefs + 1] = orderedRefs[index]
        end

        local rows = Profile.GetResolvedSkillRowsByRefs and Profile.GetResolvedSkillRowsByRefs(requestedRefs) or {}
        activeSession.pendingBatch = false
        if not page:IsSkillListSessionCurrent(activeSession) then
            return
        end

        page:LoadResolvedSkillRowsIntoSession(activeSession, rows)
        activeSession.loadedPrefixCount = rangeEnd
        page:ApplySkillListSessionRows(activeSession, false)
        page:QueueSkillListSessionBatch(activeSession)
    end

    if Tasks and Tasks.Enqueue then
        Tasks:Enqueue(worker, self, session.id, session.categoryKey, batchStart, batchSize)
        return true
    end

    worker(self, session.id, session.categoryKey, batchStart, batchSize)
    return true
end

function SkillsPage:BeginSkillListSession(restartSession)
    local categoryKey = tostring(self.SelectedCategoryKey or "")
    local skillEntries = self.SkillEntriesByCategory and self.SkillEntriesByCategory[categoryKey] or {}
    local activeSession = self.SkillListSession
    if restartSession ~= true and self:IsSkillListSessionCurrent(activeSession) and (tonumber(activeSession.totalCount) or 0) == #skillEntries then
        return activeSession
    end

    self.SkillListSessionId = math.max(0, tonumber(self.SkillListSessionId) or 0) + 1
    local session = {
        id = self.SkillListSessionId,
        categoryKey = categoryKey,
        totalCount = #skillEntries,
        orderedSkillRefs = {},
        orderedIndexByRef = {},
        skillEntriesByRef = {},
        loadedRows = {},
        loadedRowsByRef = {},
        loadedRefSet = {},
        items = {},
        loadedPrefixCount = 0,
        pendingBatch = false,
    }

    for index = 1, #skillEntries do
        local entry = skillEntries[index]
        local skillRef = tostring(entry and entry.ref or "")
        session.orderedSkillRefs[index] = skillRef
        session.orderedIndexByRef[skillRef] = index
        session.skillEntriesByRef[skillRef] = entry
        session.items[index] = {
            loading = true,
            ref = skillRef,
            icon = entry and entry.icon or nil,
            name = entry and entry.name or "Loading...",
            skillType = entry and entry.skillType or categoryKey,
        }
    end

    local hasSelected = false
    for index = 1, #skillEntries do
        if tostring(skillEntries[index] and skillEntries[index].ref or "") == tostring(self.SelectedSkillRef or "") then
            hasSelected = true
            break
        end
    end
    if not hasSelected then
        self.SelectedSkillRef = skillEntries[1] and skillEntries[1].ref or nil
    end

    self.SkillListSession = session
    self.AllSkillRows = {}

    local initialCount = math.min(#session.orderedSkillRefs, self:GetSkillListInitialBatchSize())
    local requestedRefs = {}
    local requestedSet = {}
    for index = 1, initialCount do
        local skillRef = session.orderedSkillRefs[index]
        if skillRef and requestedSet[skillRef] ~= true then
            requestedSet[skillRef] = true
            requestedRefs[#requestedRefs + 1] = skillRef
        end
    end
    local selectedSkillRef = tostring(self.SelectedSkillRef or "")
    if selectedSkillRef ~= "" and requestedSet[selectedSkillRef] ~= true and session.orderedIndexByRef[selectedSkillRef] then
        requestedSet[selectedSkillRef] = true
        requestedRefs[#requestedRefs + 1] = selectedSkillRef
    end

    local rows = Profile.GetResolvedSkillRowsByRefs and Profile.GetResolvedSkillRowsByRefs(requestedRefs) or {}
    self:LoadResolvedSkillRowsIntoSession(session, rows)
    session.loadedPrefixCount = initialCount
    self:ApplySkillListSessionRows(session, true)
    self:QueueSkillListSessionBatch(session)
    return session
end

function SkillsPage:RefreshSelectedSkillState()
    if not self.frame then
        return nil
    end

    local rows = self:GetSelectedRows()
    local selectedRow = self:FindSkillRow(self.SelectedSkillRef, rows)
    if not selectedRow then
        self.SelectedSkillRef = rows[1] and rows[1].ref or nil
        selectedRow = rows[1] or nil
    end

    if self.EntryScroll and self.EntryScroll.RefreshRows then
        self.EntryScroll:RefreshRows()
    end

    local showCraftingUI = self.ShowCraftingUI == true
        and tostring(self.SelectedCategoryKey or "") == "crafting"
        and selectedRow ~= nil
        and tostring(selectedRow.skillType or "") == "crafting"

    if not showCraftingUI then
        self.ShowCraftingUI = false
        self:RefreshFooter()
    else
        local shouldRefreshCraftingList = self.CraftingRecipeListDirty == true
            or self.CraftingTrainerListDirty == true
            or self.CraftingConversionListDirty == true
            or tostring(self.CraftingRecipeListSkillRef or "") ~= tostring(selectedRow and selectedRow.ref or "")
            or tostring(self.CraftingTrainerListSkillRef or "") ~= tostring(selectedRow and selectedRow.ref or "")
        self:RefreshCraftingView(selectedRow, shouldRefreshCraftingList)
    end

    return self.frame
end

function SkillsPage:GetCraftingRecipeSessionSignature()
    local collapsedCategories = self.CraftingCollapsedCategories or {}
    local keys = {}
    for category, collapsed in pairs(collapsedCategories) do
        if collapsed == true then
            keys[#keys + 1] = tostring(category)
        end
    end
    table.sort(keys)
    return table.concat(keys, "|")
end

function SkillsPage:GetCraftingRecipeInitialBatchSize()
    local visibleRows = self.CraftingRecipeScroll and tonumber(self.CraftingRecipeScroll.visibleRows) or 10
    return math.max(1, math.floor(visibleRows) + CRAFTING_RECIPE_SYNC_OVERSCAN)
end

function SkillsPage:IsCraftingRecipeSessionCurrent(session)
    if not session or self.CraftingRecipeSession ~= session then
        return false
    end
    if self.ShowCraftingUI ~= true or self.ShowCraftingConversionMode == true or self.ShowCraftingTrainerMode == true then
        return false
    end
    if tostring(self.SelectedSkillRef or "") ~= tostring(session.skillRef or "") then
        return false
    end
    if tostring(self:GetCraftingRecipeSessionSignature()) ~= tostring(session.collapseSignature or "") then
        return false
    end
    if Crafting and Crafting.GetConfigurationRevisionToken then
        return tonumber(Crafting:GetConfigurationRevisionToken()) == tonumber(session.configRevision)
    end
    return true
end

function SkillsPage:GetCraftingRecipeDetails()
    local session = self.CraftingRecipeSession
    if session and tostring(session.skillRef or "") == tostring(self.SelectedSkillRef or "") then
        return session.details or {}
    end

    if tostring(self.CraftingRecipeListSkillRef or "") ~= tostring(self.SelectedSkillRef or "") then
        return {}
    end

    return self.CraftingRecipeDetails or {}
end

function SkillsPage:BuildCraftingRecipeListRows(details, totalRecipeCount)
    details = details or self:GetCraftingRecipeDetails()
    self.CraftingRecipeDetails = details
    self.CraftingCollapsedCategories = self.CraftingCollapsedCategories or {}

    local selectedRecipeRef = tostring(self.SelectedRecipeRef or "")
    if selectedRecipeRef == "" and details[1] and details[1].recipeRef then
        self.SelectedRecipeRef = details[1].recipeRef
        selectedRecipeRef = tostring(self.SelectedRecipeRef or "")
    end

    local rows = {}
    local currentCategory = nil
    local recipeFound = false
    for index = 1, #details do
        local detail = details[index]
        local category = tostring(detail.category ~= "" and detail.category or "General")
        if category ~= currentCategory then
            currentCategory = category
            rows[#rows + 1] = {
                rowType = "header",
                category = category,
                collapsed = self.CraftingCollapsedCategories[category] == true,
            }
        end

        if self.CraftingCollapsedCategories[category] ~= true then
            rows[#rows + 1] = {
                rowType = "recipe",
                recipeRef = detail.recipeRef,
                detail = detail,
            }
            if tostring(detail.recipeRef or "") == selectedRecipeRef then
                recipeFound = true
            end
        end
    end

    if not recipeFound and selectedRecipeRef == "" then
        self.SelectedRecipeRef = details[1] and details[1].recipeRef or nil
    end

    if (tonumber(totalRecipeCount) or 0) > #details then
        rows[#rows + 1] = {
            rowType = "loading",
            loadedCount = #details,
            totalCount = tonumber(totalRecipeCount) or #details,
        }
    end

    return rows
end

function SkillsPage:ApplyCraftingRecipeSessionRows(session, replaceItems)
    if not self:IsCraftingRecipeSessionCurrent(session) then
        return false
    end

    local builtRows = self:BuildCraftingRecipeListRows(session.details or {}, session.totalCount or 0)
    self.CraftingRecipeDetails = session.details or {}
    self.CraftingRecipeListSkillRef = tostring(session.skillRef or "")
    self.CraftingRecipeListDirty = false
    self.CraftingRecipeItemsDirty = false

    if self.CraftingRecipeScroll then
        if replaceItems == true and self.CraftingRecipeScroll.SetItems then
            session.items = builtRows
            self.CraftingRecipeScroll:SetItems(session.items)
        elseif self.CraftingRecipeScroll.UpdateGeometry then
            local currentItems = self.CraftingRecipeScroll.GetItems and self.CraftingRecipeScroll:GetItems() or session.items or {}
            for index = #currentItems, 1, -1 do
                currentItems[index] = nil
            end
            for index = 1, #builtRows do
                currentItems[index] = builtRows[index]
            end
            session.items = currentItems
            self.CraftingRecipeScroll:UpdateGeometry()
        end
    end

    return true
end

function SkillsPage:QueueCraftingRecipeSessionBatch(session)
    if not self:IsCraftingRecipeSessionCurrent(session) or session.pendingBatch == true then
        return false
    end
    if (tonumber(session.loadedCount) or 0) >= (tonumber(session.totalCount) or 0) then
        session.pendingBatch = false
        return false
    end

    session.pendingBatch = true
    local batchStart = (tonumber(session.loadedCount) or 0) + 1
    local batchSize = math.max(1, CRAFTING_RECIPE_ASYNC_BATCH_SIZE)
    local worker = function(page, sessionId, skillRef, collapseSignature, configRevision, startIndex, requestedCount)
        local startedAt = getTimingMilliseconds()
        local activeSession = page and page.CraftingRecipeSession or nil
        if not activeSession or tonumber(activeSession.id) ~= tonumber(sessionId) then
            return
        end
        if tostring(activeSession.skillRef or "") ~= tostring(skillRef or "") then
            activeSession.pendingBatch = false
            return
        end
        if tostring(activeSession.collapseSignature or "") ~= tostring(collapseSignature or "")
            or tonumber(activeSession.configRevision) ~= tonumber(configRevision)
        then
            activeSession.pendingBatch = false
            return
        end

        local batchRows, totalCount = Crafting:GetRecipeSummaryRangeForSkill(skillRef, startIndex, requestedCount, {
            knownOnly = true,
        })

        activeSession.pendingBatch = false
        if not page:IsCraftingRecipeSessionCurrent(activeSession) then
            return
        end

        for index = 1, #batchRows do
            activeSession.details[#activeSession.details + 1] = batchRows[index]
        end
        activeSession.loadedCount = #activeSession.details
        activeSession.totalCount = tonumber(totalCount) or activeSession.totalCount or activeSession.loadedCount
        logSkillsInternal(
            "SkillsPage: Crafting batch session=%d skill=%s start=%d requested=%d loaded=%d total=%d took=%.2fms",
            tonumber(sessionId) or 0,
            tostring(skillRef or ""),
            tonumber(startIndex) or 0,
            tonumber(requestedCount) or 0,
            tonumber(activeSession.loadedCount) or 0,
            tonumber(activeSession.totalCount) or 0,
            getElapsedMilliseconds(startedAt)
        )
        page:ApplyCraftingRecipeSessionRows(activeSession, false)
        page:QueueCraftingRecipeSessionBatch(activeSession)
    end

    if Addon.Internal and Addon.Internal.Tasks and Addon.Internal.Tasks.Enqueue then
        Addon.Internal.Tasks:Enqueue(
            worker,
            self,
            session.id,
            session.skillRef,
            session.collapseSignature,
            session.configRevision,
            batchStart,
            batchSize
        )
        return true
    end

    worker(self, session.id, session.skillRef, session.collapseSignature, session.configRevision, batchStart, batchSize)
    return true
end

function SkillsPage:BeginCraftingRecipeSession(row)
    if not (Crafting and Crafting.GetRecipeSummaryRangeForSkill and Crafting.GetOrderedRecipeRefsForSkill) then
        return nil
    end

    local startedAt = getTimingMilliseconds()
    self.CraftingRecipeSessionId = math.max(0, tonumber(self.CraftingRecipeSessionId) or 0) + 1
    local session = {
        id = self.CraftingRecipeSessionId,
        skillRef = tostring(row and row.ref or ""),
        collapseSignature = self:GetCraftingRecipeSessionSignature(),
        configRevision = Crafting.GetConfigurationRevisionToken and Crafting:GetConfigurationRevisionToken() or 0,
        details = {},
        items = {},
        loadedCount = 0,
        totalCount = 0,
        pendingBatch = false,
    }

    self.CraftingRecipeSession = session
    local initialRows, totalCount = Crafting:GetRecipeSummaryRangeForSkill(session.skillRef, 1, self:GetCraftingRecipeInitialBatchSize(), {
        knownOnly = true,
        skillRow = row,
    })
    session.totalCount = tonumber(totalCount) or 0
    for index = 1, #initialRows do
        session.details[#session.details + 1] = initialRows[index]
    end
    session.loadedCount = #session.details
    self:ApplyCraftingRecipeSessionRows(session, true)
    logSkillsInternal(
        "SkillsPage: BeginCraftingRecipeSession session=%d skill=%s initial=%d total=%d took=%.2fms",
        tonumber(session.id) or 0,
        tostring(session.skillRef or ""),
        tonumber(session.loadedCount) or 0,
        tonumber(session.totalCount) or 0,
        getElapsedMilliseconds(startedAt)
    )
    self:QueueCraftingRecipeSessionBatch(session)
    return session
end

function SkillsPage:GetCraftingTrainerInitialBatchSize()
    local visibleRows = self.CraftingTrainerScroll and tonumber(self.CraftingTrainerScroll.visibleRows) or 10
    return math.max(1, math.floor(visibleRows) + CRAFTING_TRAINER_SYNC_OVERSCAN)
end

function SkillsPage:IsCraftingTrainerSessionCurrent(session)
    if not session or self.CraftingTrainerSession ~= session then
        return false
    end
    if self.ShowCraftingUI ~= true or self.ShowCraftingTrainerMode ~= true then
        return false
    end
    if tostring(self.SelectedSkillRef or "") ~= tostring(session.skillRef or "") then
        return false
    end
    if Crafting and Crafting.GetConfigurationRevisionToken then
        return tonumber(Crafting:GetConfigurationRevisionToken()) == tonumber(session.configRevision)
    end
    return true
end

function SkillsPage:BuildCraftingTrainerItems(details, totalCount)
    details = details or {}
    local items = {}
    local selectedRef = tostring(self.SelectedTrainerRecipeRef or "")
    local hasSelected = false

    for index = 1, #details do
        local detail = details[index]
        items[#items + 1] = detail
        if tostring(detail and detail.recipeRef or "") == selectedRef then
            hasSelected = true
        end
    end

    if not hasSelected then
        self.SelectedTrainerRecipeRef = details[1] and details[1].recipeRef or nil
    end

    if (tonumber(totalCount) or 0) > #details then
        items[#items + 1] = {
            loading = true,
            loadedCount = #details,
            totalCount = tonumber(totalCount) or #details,
        }
    end

    return items
end

function SkillsPage:ApplyCraftingTrainerSessionRows(session, replaceItems)
    if not self:IsCraftingTrainerSessionCurrent(session) then
        return false
    end

    local builtItems = self:BuildCraftingTrainerItems(session.details or {}, session.totalCount or 0)
    self.CraftingTrainerDetails = session.details or {}
    self.CraftingTrainerListSkillRef = tostring(session.skillRef or "")
    self.CraftingTrainerListDirty = false
    self.CraftingTrainerItemsDirty = false
    self.CraftingTrainerListApplied = true
    self.CraftingTrainerAppliedSkillRef = tostring(session.skillRef or "")

    if self.CraftingTrainerScroll then
        if replaceItems == true and self.CraftingTrainerScroll.SetItems then
            session.items = builtItems
            self.CraftingTrainerScroll:SetItems(session.items)
        elseif self.CraftingTrainerScroll.UpdateGeometry then
            local currentItems = self.CraftingTrainerScroll.GetItems and self.CraftingTrainerScroll:GetItems() or session.items or {}
            for index = #currentItems, 1, -1 do
                currentItems[index] = nil
            end
            for index = 1, #builtItems do
                currentItems[index] = builtItems[index]
            end
            session.items = currentItems
            self.CraftingTrainerScroll:UpdateGeometry()
        end
    end

    return true
end

function SkillsPage:QueueCraftingTrainerSessionBatch(session)
    if not self:IsCraftingTrainerSessionCurrent(session) or session.pendingBatch == true then
        return false
    end
    if (tonumber(session.loadedCount) or 0) >= (tonumber(session.totalCount) or 0) then
        session.pendingBatch = false
        return false
    end

    session.pendingBatch = true
    local batchStart = (tonumber(session.loadedCount) or 0) + 1
    local batchSize = math.max(1, CRAFTING_TRAINER_ASYNC_BATCH_SIZE)
    local worker = function(page, sessionId, skillRef, configRevision, startIndex, requestedCount)
        local startedAt = getTimingMilliseconds()
        local activeSession = page and page.CraftingTrainerSession or nil
        if not activeSession or tonumber(activeSession.id) ~= tonumber(sessionId) then
            return
        end
        if tostring(activeSession.skillRef or "") ~= tostring(skillRef or "")
            or tonumber(activeSession.configRevision) ~= tonumber(configRevision)
        then
            activeSession.pendingBatch = false
            return
        end

        local batchRows, totalCount = Crafting:GetRecipeSummaryRangeForSkill(skillRef, startIndex, requestedCount, {
            trainerOnly = true,
        })

        activeSession.pendingBatch = false
        if not page:IsCraftingTrainerSessionCurrent(activeSession) then
            return
        end

        for index = 1, #batchRows do
            activeSession.details[#activeSession.details + 1] = batchRows[index]
        end
        activeSession.loadedCount = #activeSession.details
        activeSession.totalCount = tonumber(totalCount) or activeSession.totalCount or activeSession.loadedCount
        logSkillsInternal(
            "SkillsPage: Trainer batch session=%d skill=%s start=%d requested=%d loaded=%d total=%d took=%.2fms",
            tonumber(sessionId) or 0,
            tostring(skillRef or ""),
            tonumber(startIndex) or 0,
            tonumber(requestedCount) or 0,
            tonumber(activeSession.loadedCount) or 0,
            tonumber(activeSession.totalCount) or 0,
            getElapsedMilliseconds(startedAt)
        )
        page:ApplyCraftingTrainerSessionRows(activeSession, false)
        page:QueueCraftingTrainerSessionBatch(activeSession)
    end

    if Addon.Internal and Addon.Internal.Tasks and Addon.Internal.Tasks.Enqueue then
        Addon.Internal.Tasks:Enqueue(
            worker,
            self,
            session.id,
            session.skillRef,
            session.configRevision,
            batchStart,
            batchSize
        )
        return true
    end

    worker(self, session.id, session.skillRef, session.configRevision, batchStart, batchSize)
    return true
end

function SkillsPage:BeginCraftingTrainerSession()
    if not (Crafting and Crafting.GetRecipeSummaryRangeForSkill and Crafting.GetOrderedRecipeRefsForSkill) then
        return nil
    end

    local startedAt = getTimingMilliseconds()
    self.CraftingTrainerSessionId = math.max(0, tonumber(self.CraftingTrainerSessionId) or 0) + 1
    local session = {
        id = self.CraftingTrainerSessionId,
        skillRef = tostring(self.SelectedSkillRef or ""),
        configRevision = Crafting.GetConfigurationRevisionToken and Crafting:GetConfigurationRevisionToken() or 0,
        details = {},
        items = {},
        loadedCount = 0,
        totalCount = 0,
        pendingBatch = false,
    }

    self.CraftingTrainerSession = session
    local initialRows, totalCount = Crafting:GetRecipeSummaryRangeForSkill(session.skillRef, 1, self:GetCraftingTrainerInitialBatchSize(), {
        trainerOnly = true,
        skillRow = self:GetSelectedSkillRow(),
    })
    session.totalCount = tonumber(totalCount) or 0
    for index = 1, #initialRows do
        session.details[#session.details + 1] = initialRows[index]
    end
    session.loadedCount = #session.details
    self:ApplyCraftingTrainerSessionRows(session, true)
    logSkillsInternal(
        "SkillsPage: BeginCraftingTrainerSession session=%d skill=%s initial=%d total=%d took=%.2fms",
        tonumber(session.id) or 0,
        tostring(session.skillRef or ""),
        tonumber(session.loadedCount) or 0,
        tonumber(session.totalCount) or 0,
        getElapsedMilliseconds(startedAt)
    )
    self:QueueCraftingTrainerSessionBatch(session)
    return session
end

function SkillsPage:GetSelectedCraftingRecipeDetail()
    if Crafting and Crafting.BuildRecipeDetails and self.SelectedRecipeRef then
        local detail = Crafting:BuildRecipeDetails(self.SelectedRecipeRef)
        if detail then
            return detail
        end
    end

    local details = self.CraftingRecipeDetails or self:GetCraftingRecipeDetails()
    for index = 1, #details do
        if tostring(details[index].recipeRef or "") == tostring(self.SelectedRecipeRef or "") then
            return details[index]
        end
    end
    return details[1]
end

function SkillsPage:GetTrainerRecipeRows()
    local session = self.CraftingTrainerSession
    if session and tostring(session.skillRef or "") == tostring(self.SelectedSkillRef or "") then
        local rows = session.details or {}
        local selectedRef = tostring(self.SelectedTrainerRecipeRef or "")
        local hasSelected = false
        for index = 1, #rows do
            if tostring(rows[index].recipeRef or "") == selectedRef then
                hasSelected = true
                break
            end
        end
        if not hasSelected then
            self.SelectedTrainerRecipeRef = rows[1] and rows[1].recipeRef or nil
        end
        return rows
    end

    if tostring(self.CraftingTrainerListSkillRef or "") ~= tostring(self.SelectedSkillRef or "") then
        return {}
    end
    local rows = self.CraftingTrainerDetails or {}

    local selectedRef = tostring(self.SelectedTrainerRecipeRef or "")
    local hasSelected = false
    for index = 1, #rows do
        if tostring(rows[index].recipeRef or "") == selectedRef then
            hasSelected = true
            break
        end
    end
    if not hasSelected then
        self.SelectedTrainerRecipeRef = rows[1] and rows[1].recipeRef or nil
    end

    return rows
end

function SkillsPage:QueueRecipeDetailPriming(recipeRefs)
    if not (Crafting and Crafting.PrimeRecipeDetails) then
        return false
    end

    local queued = {}
    local uniqueRefs = {}
    for index = 1, #(recipeRefs or {}) do
        local recipeRef = tostring(recipeRefs[index] or "")
        if recipeRef ~= "" and not queued[recipeRef] then
            uniqueRefs[#uniqueRefs + 1] = recipeRef
            queued[recipeRef] = true
        end
    end

    if #uniqueRefs <= 0 then
        return false
    end

    return Crafting:PrimeRecipeDetails(uniqueRefs)
end

function SkillsPage:GetSelectedTrainerRecipeDetail()
    local rows = self.CraftingTrainerDetails or self:GetTrainerRecipeRows()
    for index = 1, #rows do
        if tostring(rows[index].recipeRef or "") == tostring(self.SelectedTrainerRecipeRef or "") then
            return rows[index]
        end
    end

    return rows[1]
end

function SkillsPage:GetConvertibleMaterialRows()
    local rows = {}
    local query = normalizeSearchToken(self.CraftingConversionSearchQuery)
    local materials = Crafting and Crafting.GetConvertibleMaterialDefinitionsForSkill and Crafting:GetConvertibleMaterialDefinitionsForSkill(self.SelectedSkillRef) or {}

    for index = 1, #materials do
        local row = materials[index]
        local searchIndex = normalizeSearchToken(table.concat({
            ensureString(row.name),
            ensureString(row.itemRef),
            row.dataset and Database.GetDatasetDisplayName and Database.GetDatasetDisplayName(row.dataset) or "",
        }, " "))
        if query == "" or string.find(searchIndex, query, 1, true) ~= nil then
            rows[#rows + 1] = {
                itemRef = row.itemRef,
                item = row.item,
                dataset = row.dataset,
                name = ensureString(row.name),
                icon = ensureString(row.item and row.item.icon),
            }
        end
    end

    return rows
end

function SkillsPage:ResetCraftingConversionDialogValidation()
    self.CraftingConversionDialogValidatedCount = nil
    self.CraftingConversionDialogAvailableCount = nil
    self.CraftingConversionDialogIsValid = false
end

function SkillsPage:UpdateCraftingConversionDialogState()
    local rowData = self.CraftingConversionDialogRowData
    local hasRow = type(rowData) == "table"
    local rowName = hasRow and ensureString(rowData.name, "Material") or "Material"
    local requestedCount = math.max(1, math.floor(tonumber(self.CraftingConversionDialogRequestedCount) or 1))
    self.CraftingConversionDialogRequestedCount = requestedCount

    if self.CraftingConversionDialogTitle and self.CraftingConversionDialogTitle.SetText then
        self.CraftingConversionDialogTitle:SetText(rowName)
    end
    if self.CraftingConversionDialogIcon and self.CraftingConversionDialogIcon.SetTexture then
        self.CraftingConversionDialogIcon:SetTexture(hasRow and (rowData.icon ~= "" and rowData.icon or "Interface\\Icons\\INV_Misc_QuestionMark") or "Interface\\Icons\\INV_Misc_QuestionMark")
    end
    if self.CraftingConversionDialogQuantityInput and self.CraftingConversionDialogQuantityInput.SetText then
        local currentText = self.CraftingConversionDialogQuantityInput:GetText()
        local desiredText = tostring(requestedCount)
        if currentText ~= desiredText then
            self.CraftingConversionDialogQuantityInput:SetText(desiredText)
        end
    end

    local statusText = "Choose an amount, then search your bags."
    if self.CraftingConversionDialogAvailableCount ~= nil then
        if self.CraftingConversionDialogIsValid == true then
            statusText = ("Found %d item%s. Ready to convert %d."):format(
                tonumber(self.CraftingConversionDialogAvailableCount) or 0,
                (tonumber(self.CraftingConversionDialogAvailableCount) or 0) == 1 and "" or "s",
                tonumber(self.CraftingConversionDialogValidatedCount) or requestedCount
            )
        else
            statusText = ("Found %d item%s. Requested %d."):format(
                tonumber(self.CraftingConversionDialogAvailableCount) or 0,
                (tonumber(self.CraftingConversionDialogAvailableCount) or 0) == 1 and "" or "s",
                requestedCount
            )
        end
    end
    if self.CraftingConversionDialogStatusText and self.CraftingConversionDialogStatusText.SetText then
        self.CraftingConversionDialogStatusText:SetText(statusText)
    end

    if self.CraftingConversionDialogSearchButton and self.CraftingConversionDialogSearchButton.SetEnabled then
        self.CraftingConversionDialogSearchButton:SetEnabled(hasRow)
    end
    if self.CraftingConversionDialogApplyButton and self.CraftingConversionDialogApplyButton.SetEnabled then
        self.CraftingConversionDialogApplyButton:SetEnabled(hasRow and self.CraftingConversionDialogIsValid == true)
    end
end

function SkillsPage:BuildCraftingConversionDialog()
    if self.CraftingConversionDialog then
        return self.CraftingConversionDialog
    end

    local window = UI.Window:New({
        name = "RPEProfileSkillsCraftingConversionDialog",
        width = 320,
        height = 182,
        point = "CENTER",
        relativeTo = UIParent,
        relativePoint = "CENTER",
        frameStrata = "HIGH",
        frameLevel = 40,
        movable = true,
        clampedToScreen = true,
        toplevel = true,
        hidden = true,
        contentInsetLeft = 10,
        contentInsetRight = 10,
        contentInsetTop = 28,
        contentInsetBottom = 10,
        onClose = function()
            self.CraftingConversionDialogRowData = nil
            self:ResetCraftingConversionDialogValidation()
        end,
    })
    window:SetTitle("Convert Materials")
    window:Create()
    self.CraftingConversionDialog = window

    local root = UI.CreateLayout(UI.VerticalLayoutGroup, window:GetContentFrame(), "RPEProfileSkillsCraftingConversionDialogRoot", {
        spacing = 8,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, window:GetContentFrame(), 0, 0, 0, 0)

    local header = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEProfileSkillsCraftingConversionDialogHeader", {
        spacing = 8,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
        height = 30,
    })
    root:AddChild(header)

    self.CraftingConversionDialogIconPanel = UI.CreatePanel(header:GetFrame(), "RPEProfileSkillsCraftingConversionDialogIconPanel", {
        width = 28,
        height = 28,
        contentInset = 1,
        showBorder = true,
    })
    header:AddChild(self.CraftingConversionDialogIconPanel)

    self.CraftingConversionDialogIcon = UI.Image:New({
        name = "RPEProfileSkillsCraftingConversionDialogIcon",
        width = 26,
        height = 26,
        texture = "Interface\\Icons\\INV_Misc_QuestionMark",
        border = false,
        textureInsetLeft = 0,
        textureInsetTop = 0,
        textureInsetRight = 0,
        textureInsetBottom = 0,
    })
    self.CraftingConversionDialogIcon:SetParent(self.CraftingConversionDialogIconPanel:GetContentFrame())
    self.CraftingConversionDialogIcon:Create()
    self.CraftingConversionDialogIcon:GetFrame():SetAllPoints(self.CraftingConversionDialogIconPanel:GetContentFrame())

    self.CraftingConversionDialogTitle = UI.CreateText(header:GetFrame(), "RPEProfileSkillsCraftingConversionDialogTitle", "Material", {
        width = 252,
        height = 28,
        justifyH = "LEFT",
        justifyV = "MIDDLE",
        textColor = UI.ResolveColor(nil, "text.primary"),
    })
    header:AddChild(self.CraftingConversionDialogTitle)

    self.CraftingConversionDialogQuantityLabel = UI.CreateText(root:GetFrame(), "RPEProfileSkillsCraftingConversionDialogQuantityLabel", "Quantity", {
        width = 280,
        height = 12,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    root:AddChild(self.CraftingConversionDialogQuantityLabel)

    self.CraftingConversionDialogQuantityInput = UI.CreateTextInput(root:GetFrame(), "RPEProfileSkillsCraftingConversionDialogQuantityInput", {
        width = 280,
        height = 20,
        text = "1",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.CraftingConversionDialogQuantityInput:SetScript("OnTextChanged", function()
        self.CraftingConversionDialogRequestedCount = math.max(1, math.floor(tonumber(self.CraftingConversionDialogQuantityInput:GetText()) or 1))
        self:ResetCraftingConversionDialogValidation()
        self:UpdateCraftingConversionDialogState()
    end)
    root:AddChild(self.CraftingConversionDialogQuantityInput)

    self.CraftingConversionDialogStatusText = UI.CreateText(root:GetFrame(), "RPEProfileSkillsCraftingConversionDialogStatusText", "", {
        width = 280,
        height = 28,
        justifyH = "LEFT",
        wordWrap = true,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    root:AddChild(self.CraftingConversionDialogStatusText)

    local actions = CreateFrame("Frame", "RPEProfileSkillsCraftingConversionDialogActions", root:GetFrame())
    actions:SetSize(280, 20)
    root:AddChild({
        GetFrame = function()
            return actions
        end,
        options = {
            width = 280,
            height = 20,
        },
    })

    self.CraftingConversionDialogSearchButton = UI.CreateButton(actions, "RPEProfileSkillsCraftingConversionDialogSearchButton", "Search Bags", 84, function()
        local rowData = self.CraftingConversionDialogRowData
        if not rowData or not Crafting or not Crafting.ValidateMaterialConversionRequest then
            return
        end

        local result = Crafting:ValidateMaterialConversionRequest(rowData.itemRef, self.CraftingConversionDialogRequestedCount or 1)
        self.CraftingConversionDialogAvailableCount = tonumber(result and result.availableCount) or 0
        self.CraftingConversionDialogValidatedCount = tonumber(result and result.validatedCount) or 0
        self.CraftingConversionDialogIsValid = result and result.isValid == true or false
        self:UpdateCraftingConversionDialogState()
    end, {
        height = 20,
        fontSize = 8,
    })
    local searchButtonFrame = self.CraftingConversionDialogSearchButton.GetFrame and self.CraftingConversionDialogSearchButton:GetFrame() or nil
    if searchButtonFrame then
        searchButtonFrame:ClearAllPoints()
        searchButtonFrame:SetPoint("LEFT", actions, "LEFT", 0, 0)
    end

    self.CraftingConversionDialogApplyButton = UI.CreateButton(actions, "RPEProfileSkillsCraftingConversionDialogApplyButton", "Apply", 64, function()
        local rowData = self.CraftingConversionDialogRowData
        local convertCount = math.max(1, math.floor(tonumber(self.CraftingConversionDialogValidatedCount) or 0))
        if not rowData or convertCount <= 0 or self.CraftingConversionDialogIsValid ~= true then
            return
        end
        if Crafting and Crafting.ConvertMaterialItemFromBags then
            Crafting:ConvertMaterialItemFromBags(rowData.itemRef, convertCount)
        end
        if self.CraftingConversionDialog and self.CraftingConversionDialog.Hide then
            self.CraftingConversionDialog:Hide()
        end
    end, {
        height = 20,
        fontSize = 8,
    })
    local applyButtonFrame = self.CraftingConversionDialogApplyButton.GetFrame and self.CraftingConversionDialogApplyButton:GetFrame() or nil
    if applyButtonFrame then
        applyButtonFrame:ClearAllPoints()
        applyButtonFrame:SetPoint("CENTER", actions, "CENTER", 0, 0)
    end

    self.CraftingConversionDialogCancelButton = UI.CreateButton(actions, "RPEProfileSkillsCraftingConversionDialogCancelButton", "Cancel", 64, function()
        if self.CraftingConversionDialog and self.CraftingConversionDialog.Hide then
            self.CraftingConversionDialog:Hide()
        end
    end, {
        height = 20,
        fontSize = 8,
    })
    local cancelButtonFrame = self.CraftingConversionDialogCancelButton.GetFrame and self.CraftingConversionDialogCancelButton:GetFrame() or nil
    if cancelButtonFrame then
        cancelButtonFrame:ClearAllPoints()
        cancelButtonFrame:SetPoint("RIGHT", actions, "RIGHT", 0, 0)
    end

    self:ResetCraftingConversionDialogValidation()
    self:UpdateCraftingConversionDialogState()
    return window
end

function SkillsPage:ShowCraftingConversionDialog(rowData)
    if type(rowData) ~= "table" then
        return nil
    end

    local window = self:BuildCraftingConversionDialog()
    self.CraftingConversionDialogRowData = rowData
    self.CraftingConversionDialogRequestedCount = 1
    self:ResetCraftingConversionDialogValidation()
    self:UpdateCraftingConversionDialogState()

    if window and window.Show then
        window:Show()
    end
    if self.CraftingConversionDialogQuantityInput and self.CraftingConversionDialogQuantityInput.Focus then
        self.CraftingConversionDialogQuantityInput:Focus()
    end
    return window
end

function SkillsPage:RefreshCraftingConversionWindow()
    if not (self.CraftingConversionPanel and self.CraftingConversionPanel.GetFrame and self.CraftingConversionPanel:GetFrame()) then
        return
    end

    local query = normalizeSearchToken(self.CraftingConversionSearchQuery)
    local rows = self:GetConvertibleMaterialRows()
    self.CraftingConversionRows = rows

    local selectedRef = tostring(self.SelectedConversionMaterialRef or "")
    if selectedRef ~= "" then
        local hasSelectedRow = false
        for index = 1, #rows do
            if tostring(rows[index].itemRef or "") == selectedRef then
                hasSelectedRow = true
                break
            end
        end
        if not hasSelectedRow then
            self.SelectedConversionMaterialRef = nil
        end
    end

    if self.CraftingConversionSearchInput and self.CraftingConversionSearchInput.GetText then
        local currentText = self.CraftingConversionSearchInput:GetText()
        local desiredText = ensureString(self.CraftingConversionSearchQuery)
        if currentText ~= desiredText then
            self.CraftingConversionSearchInput:SetText(desiredText)
        end
    end
    if self.CraftingConversionScroll and self.CraftingConversionScroll.SetItems then
        self.CraftingConversionScroll:SetItems(rows)
    end
    if self.CraftingConversionEmptyText and self.CraftingConversionEmptyText.SetText then
        if #rows == 0 and query ~= "" then
            self.CraftingConversionEmptyText:SetText("No materials match the current search.")
        elseif #rows == 0 then
            self.CraftingConversionEmptyText:SetText("No materials use this crafting skill for conversion.")
        else
            self.CraftingConversionEmptyText:SetText("")
        end
    end
end

function SkillsPage:ShowCraftingConversionWindow()
    self.ShowCraftingConversionMode = true
    self.ShowCraftingTrainerMode = false
    self:Refresh()
end

function SkillsPage:ShowCraftingRecipeWindow()
    self.ShowCraftingConversionMode = false
    self.ShowCraftingTrainerMode = false
    self:Refresh()
end

function SkillsPage:ShowCraftingTrainerWindow()
    self.ShowCraftingConversionMode = false
    self.ShowCraftingTrainerMode = true
    logSkillsInternal("SkillsPage: ShowCraftingTrainerWindow skill=%s", tostring(self.SelectedSkillRef or ""))
    self:Refresh()
end

function SkillsPage:ToggleCraftingConversionMode()
    if self.ShowCraftingConversionMode == true then
        self:ShowCraftingRecipeWindow()
    else
        self:ShowCraftingConversionWindow()
    end
end

function SkillsPage:RefreshCraftingTrainerWindow()
    if not (self.CraftingTrainerPanel and self.CraftingTrainerPanel.GetFrame and self.CraftingTrainerPanel:GetFrame()) then
        return
    end

    local startedAt = getTimingMilliseconds()
    local trainerSkillRef = tostring(self.SelectedSkillRef or "")
    local trainerListNeedsRefresh = self.CraftingTrainerListApplied ~= true
        or self.CraftingTrainerItemsDirty == true
        or self.CraftingTrainerListDirty == true
        or tostring(self.CraftingTrainerAppliedSkillRef or "") ~= trainerSkillRef
        or tostring(self.CraftingTrainerListSkillRef or "") ~= trainerSkillRef

    if trainerListNeedsRefresh then
        self:BeginCraftingTrainerSession()
    elseif self.CraftingTrainerScroll and self.CraftingTrainerScroll.RefreshRows then
        self.CraftingTrainerScroll:RefreshRows()
    end

    local rows = self:GetTrainerRecipeRows()
    if self.CraftingTrainerEmptyText and self.CraftingTrainerEmptyText.SetText then
        local totalRows = self.CraftingTrainerSession and tonumber(self.CraftingTrainerSession.totalCount) or #rows
        self.CraftingTrainerEmptyText:SetText(totalRows > 0 and "" or "No trainer recipes available for this crafting skill.")
    end

    local detail = self:GetSelectedTrainerRecipeDetail()
    if self.CraftingTrainerDetailText and self.CraftingTrainerDetailText.SetText then
        if detail then
            local affordabilityText = detail.canAffordTrainerCost == true and "|cff55ff55Affordable|r" or "|cffff5555Not enough copper|r"
            local lockedText = detail.isLockedByLevel == true
                and ("|cffff5555Locked until %d|r"):format(tonumber(detail.requiredSkillLevel) or 0)
                or "|cff55ff55Ready to learn|r"
            self.CraftingTrainerDetailText:SetText(("%s\n%s | %s"):format(
                tostring(detail.name or "Recipe"),
                tostring(detail.trainerCostText or ""),
                detail.isLockedByLevel == true and lockedText or affordabilityText
            ))
        else
            self.CraftingTrainerDetailText:SetText("Select a recipe to learn from the trainer.")
        end
    end
    if self.CraftingTrainerLearnButton and self.CraftingTrainerLearnButton.SetEnabled then
        self.CraftingTrainerLearnButton:SetEnabled(detail ~= nil and detail.canLearnFromTrainer == true and detail.canAffordTrainerCost == true)
    end
    logSkillsInternal(
        "SkillsPage: RefreshCraftingTrainerWindow skill=%s needsRefresh=%s rows=%d total=%d selected=%s took=%.2fms",
        trainerSkillRef,
        tostring(trainerListNeedsRefresh == true),
        #rows,
        tonumber(self.CraftingTrainerSession and self.CraftingTrainerSession.totalCount) or #rows,
        tostring(self.SelectedTrainerRecipeRef or ""),
        getElapsedMilliseconds(startedAt)
    )
end

function SkillsPage:EnsureCraftingMaterialContextMenu()
    if self.CraftingMaterialContextMenu then
        return self.CraftingMaterialContextMenu
    end

    self.CraftingMaterialContextMenu = UI.ContextMenu:New({
        name = "RPEProfileSkillsCraftingMaterialContextMenu",
        width = 140,
        panelWidth = 140,
        visibleRows = 1,
        rowHeight = 18,
        border = false,
        onItemInvoked = function(item, menu)
            local rowData = self.ContextMenuCraftingMaterialRow
            if not rowData or not item or item.value ~= "convert-material" or not Crafting or not Crafting.ConvertMaterialItemFromBags then
                return
            end

            local missingCount = math.max(0, (tonumber(rowData.required) or 0) - (tonumber(rowData.owned) or 0))
            local bagCount = tonumber(rowData.convertibleCount) or 0
            local convertCount = math.min(missingCount, bagCount)
            if convertCount > 0 then
                Crafting:ConvertMaterialItemFromBags(rowData.itemRef, convertCount)
            end

            if menu and menu.HideMenus then
                menu:HideMenus()
            end
        end,
    })
    self.CraftingMaterialContextMenu:SetParent(self.frame or UIParent)
    self.CraftingMaterialContextMenu:Create()
    return self.CraftingMaterialContextMenu
end

function SkillsPage:ShowCraftingMaterialContextMenu(anchorFrame, rowData)
    if not anchorFrame or not rowData then
        return
    end

    local missingCount = math.max(0, (tonumber(rowData.required) or 0) - (tonumber(rowData.owned) or 0))
    local conversion = Crafting and Crafting.GetMaterialConversionInfo and Crafting:GetMaterialConversionInfo(rowData.itemRef) or nil
    local bagCount = tonumber(conversion and conversion.bagCount) or 0
    if missingCount <= 0 or bagCount <= 0 then
        return
    end

    local menu = self:EnsureCraftingMaterialContextMenu()
    self.ContextMenuCraftingMaterialRow = rowData
    menu:SetItems({
        {
            label = ("Convert %d"):format(math.min(missingCount, bagCount)),
            value = "convert-material",
        },
    })
    menu:ShowAt(anchorFrame)
end

function SkillsPage:RefreshCraftingMaterialsTable(detail)
    local rows = {}
    for index = 1, #(detail and detail.materials or {}) do
        local row = detail.materials[index]
        rows[#rows + 1] = {
            rowIndex = index,
            itemRef = row.itemRef,
            name = colorizeText(row.name or "Unknown", row.item),
            required = tonumber(row.quantity) or 0,
            owned = tonumber(row.owned) or 0,
            status = row.hasEnough == true and "|cff55ff55Ready|r" or "|cffff5555Missing|r",
        }
    end

    self.CraftingMaterialRows = rows
    if self.CraftingMaterialsTable and self.CraftingMaterialsTable.SetRows then
        self.CraftingMaterialsTable:SetRows(rows)
    end
end

function SkillsPage:RefreshCraftingView(row, refreshRecipeList)
    if not row or tostring(row.skillType or "") ~= "crafting" then
        return
    end

    local startedAt = getTimingMilliseconds()
    local shouldRefreshRecipeList = refreshRecipeList == true
    local detail = nil
    local craftState = Crafting and Crafting.GetState and Crafting:GetState() or { queue = {}, queuedCount = 0 }
    local isConversionMode = self.ShowCraftingConversionMode == true
    local isTrainerMode = self.ShowCraftingTrainerMode == true

    if self.ContentLayout and self.ContentLayout.GetFrame then
        self.ContentLayout:GetFrame():Hide()
    end
    if self.CraftingRoot and self.CraftingRoot.GetFrame then
        self.CraftingRoot:GetFrame():Show()
    end

    if self.CraftingSkillDropdown then
        local items = self:BuildCraftingSkillItems()
        self.CraftingSkillDropdown:SetItems(items)
        self.CraftingSkillDropdown:SetSelectedValue(row.ref or "", true)
        if self.CraftingSkillDropdown.SetEnabled then
            self.CraftingSkillDropdown:SetEnabled(#items > 1)
        end
    end
    if self.CraftingConvertButton and self.CraftingConvertButton.SetText then
        self.CraftingConvertButton:SetText(isConversionMode and "Crafting" or "Convert Materials")
    end
    if self.CraftingConvertButton and self.CraftingConvertButton.SetEnabled then
        self.CraftingConvertButton:SetEnabled(row ~= nil and row.ref ~= nil)
    end
    if self.CraftingTrainerButton and self.CraftingTrainerButton.SetEnabled then
        self.CraftingTrainerButton:SetEnabled(row ~= nil and row.ref ~= nil)
    end
    if self.CraftingSkillProgressBar then
        self.CraftingSkillProgressBar:SetMinMax(0, math.max(1, tonumber(row.maxValue) or 1))
        self.CraftingSkillProgressBar:SetValue(tonumber(row.value) or 0)
        self.CraftingSkillProgressBar:SetText(formatFooterLevelText(row))
    end
    setWeightedVisibility(self.CraftingRecipePanel, not isConversionMode and not isTrainerMode, 0, not isConversionMode and not isTrainerMode, 2)
    setWeightedVisibility(self.CraftingDetailPanel, not isConversionMode and not isTrainerMode, 0, not isConversionMode and not isTrainerMode, 3)
    setWeightedVisibility(self.CraftingConversionPanel, isConversionMode, 0, isConversionMode, 1)
    setWeightedVisibility(self.CraftingTrainerPanel, isTrainerMode, 0, isTrainerMode, 1)
    if self.CraftingRoot and self.CraftingRoot.RefreshLayout then
        self.CraftingRoot:RefreshLayout()
    end
    if isConversionMode then
        if self.CraftingConversionLayout and self.CraftingConversionLayout.RefreshLayout then
            self.CraftingConversionLayout:RefreshLayout()
        end
        if self.CraftingConversionScroll and self.CraftingConversionScroll.UpdateGeometry then
            self.CraftingConversionScroll:UpdateGeometry()
        end
        if self.CraftingConversionScroll and self.CraftingConversionScroll.RefreshScrollBar then
            self.CraftingConversionScroll:RefreshScrollBar()
        end
        if self.CraftingConversionScroll and self.CraftingConversionScroll.RefreshRows then
            self.CraftingConversionScroll:RefreshRows()
        end
        self:RefreshCraftingConversionWindow()
        logSkillsInternal(
            "SkillsPage: RefreshCraftingView mode=conversion skill=%s refresh=%s took=%.2fms",
            tostring(row.ref or ""),
            tostring(shouldRefreshRecipeList == true),
            getElapsedMilliseconds(startedAt)
        )
        return
    end

    if isTrainerMode then
        if self.CraftingTrainerLayout and self.CraftingTrainerLayout.RefreshLayout then
            self.CraftingTrainerLayout:RefreshLayout()
        end
        if self.CraftingTrainerScroll and self.CraftingTrainerScroll.UpdateGeometry then
            self.CraftingTrainerScroll:UpdateGeometry()
        end
        if self.CraftingTrainerScroll and self.CraftingTrainerScroll.RefreshScrollBar then
            self.CraftingTrainerScroll:RefreshScrollBar()
        end
        if self.CraftingTrainerScroll and self.CraftingTrainerScroll.RefreshRows then
            self.CraftingTrainerScroll:RefreshRows()
        end
        self:RefreshCraftingTrainerWindow()
        logSkillsInternal(
            "SkillsPage: RefreshCraftingView mode=trainer skill=%s refresh=%s took=%.2fms",
            tostring(row.ref or ""),
            tostring(shouldRefreshRecipeList == true),
            getElapsedMilliseconds(startedAt)
        )
        return
    end

    if self.CraftingDetailLayout and self.CraftingDetailLayout.RefreshLayout then
        self.CraftingDetailLayout:RefreshLayout()
    end

    if self.CraftingRecipeScroll and self.CraftingRecipeScroll.UpdateGeometry then
        self.CraftingRecipeScroll:UpdateGeometry()
    end
    if self.CraftingRecipeScroll and self.CraftingRecipeScroll.RefreshScrollBar then
        self.CraftingRecipeScroll:RefreshScrollBar()
    end

    local recipeListNeedsRefresh = shouldRefreshRecipeList
        or self.CraftingRecipeListDirty == true
        or tostring(self.CraftingRecipeListSkillRef or "") ~= tostring(row.ref or "")
        or self.CraftingRecipeItemsDirty == true

    if recipeListNeedsRefresh then
        self:BeginCraftingRecipeSession(row)
        detail = self:GetSelectedCraftingRecipeDetail()
    else
        if Crafting and Crafting.BuildRecipeDetails and self.SelectedRecipeRef then
            detail = Crafting:BuildRecipeDetails(self.SelectedRecipeRef)
        end
        if not detail then
            detail = self:GetSelectedCraftingRecipeDetail()
        end
        if self.CraftingRecipeScroll and self.CraftingRecipeScroll.RefreshRows then
            self.CraftingRecipeScroll:RefreshRows()
        end
    end
    if self.CraftingRecipeEmptyText and self.CraftingRecipeEmptyText.SetText then
        local loadedRecipeCount = self.CraftingRecipeDetails and #self.CraftingRecipeDetails or 0
        local totalRecipeCount = self.CraftingRecipeSession and tonumber(self.CraftingRecipeSession.totalCount) or loadedRecipeCount
        self.CraftingRecipeEmptyText:SetText(totalRecipeCount > 0 and "" or "No known recipes for this crafting skill.")
    end
    if self.CraftingDetailIcon and self.CraftingDetailIcon.SetTexture then
        self.CraftingDetailIcon:SetTexture(detail and detail.output and detail.output.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    end
    if self.CraftingDetailIcon and self.CraftingDetailIcon.SetTooltip then
        self.CraftingDetailIcon:SetTooltip(buildCraftingOutputTooltip(detail))
    end
    if self.CraftingDetailTitle and self.CraftingDetailTitle.SetText then
        local outputName = detail and detail.output and detail.output.name or detail and detail.name or nil
        if detail then
            self.CraftingDetailTitle:SetText(colorizeText(outputName or "Recipe", detail.output and detail.output.item))
        elseif (self.CraftingRecipeSession and (tonumber(self.CraftingRecipeSession.totalCount) or 0) > 0) then
            self.CraftingDetailTitle:SetText("Loading recipes...")
        else
            self.CraftingDetailTitle:SetText("Recipe Details")
        end
    end
    if self.CraftingDetailHint and self.CraftingDetailHint.SetText then
        if detail then
            local parts = {}
            for index = 1, #(detail.tools or {}) do
                local tool = detail.tools[index]
                parts[#parts + 1] = colorizeText(tool.name or "Tool", tool.item)
            end
            local skillName = tostring(detail.skillName or "Skill")
            local requiredLevel = math.max(0, tonumber(detail.requiredSkillLevel) or 0)
            local requirementText = ("Requires: %s (%d)"):format(skillName, requiredLevel)
            if #parts > 0 then
                requirementText = requirementText .. ", " .. table.concat(parts, ", ")
            end
            self.CraftingDetailHint:SetText(requirementText)
        elseif (self.CraftingRecipeSession and (tonumber(self.CraftingRecipeSession.totalCount) or 0) > 0) then
            self.CraftingDetailHint:SetText("Preparing recipe list...")
        else
            self.CraftingDetailHint:SetText("")
        end
    end
    if self.CraftingQueueText and self.CraftingQueueText.SetText then
        if detail then
            local skillUpChance = getCraftingSkillUpChance(detail)
            self.CraftingQueueText:SetText(("Skill-Up Chance: %d%%"):format(skillUpChance))
        else
            self.CraftingQueueText:SetText("Skill-Up Chance: --")
        end
    end

    self:RefreshCraftingMaterialsTable(detail)

    local canCraft = detail and detail.canCraft == true
    if self.CraftingCraftOneButton and self.CraftingCraftOneButton.SetEnabled then
        self.CraftingCraftOneButton:SetEnabled(canCraft)
    end
    if self.CraftingCraftAllButton and self.CraftingCraftAllButton.SetEnabled then
        local canCraftAll = Crafting and Crafting.GetMaxCraftableCount and detail and Crafting:GetMaxCraftableCount(detail.recipeRef) > 0 or false
        self.CraftingCraftAllButton:SetEnabled(canCraftAll)
    end
    if self.CraftingCancelButton and self.CraftingCancelButton.SetEnabled then
        self.CraftingCancelButton:SetEnabled((craftState.active ~= nil) or ((tonumber(craftState.queuedCount) or 0) > 0))
    end
    logSkillsInternal(
        "SkillsPage: RefreshCraftingView mode=crafting skill=%s refresh=%s detail=%s total=%d took=%.2fms",
        tostring(row.ref or ""),
        tostring(recipeListNeedsRefresh == true),
        tostring(detail and detail.recipeRef or ""),
        tonumber(self.CraftingRecipeSession and self.CraftingRecipeSession.totalCount) or #(self.CraftingRecipeDetails or {}),
        getElapsedMilliseconds(startedAt)
    )
end

function SkillsPage:BuildSkillEntryRenderer()
    return function(entry, row)
        if entry.SetEnabled then
            entry:SetEnabled(row and row.loading ~= true)
        end
        if row and row.loading == true then
            entry:SetIcon(row.icon ~= "" and row.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
            entry:SetSkillName(row.name or "Loading...")
            entry:SetValueText("...")
            entry:SetProgress(0, 1, "")
            entry:SetSelected(false)
            entry:SetBorderColor(0.24, 0.24, 0.28, 1)
            entry.skillRow = nil

            local loadingFrame = entry.GetFrame and entry:GetFrame() or nil
            if loadingFrame then
                loadingFrame:EnableMouse(false)
                loadingFrame:SetScript("OnMouseUp", nil)
            end
            return
        end

        entry:SetIcon(row.icon ~= "" and row.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        entry:SetSkillName(row.name or "Unnamed Skill")
        entry:SetValueText(("%d / %d"):format(tonumber(row.value) or 0, tonumber(row.maxValue) or 0))
        entry:SetProgress(row.progressValue, row.maxValue, "")
        entry:SetSelected(tostring(row.ref or "") == tostring(self.SelectedSkillRef or ""))
        if tostring(row.ref or "") == tostring(self.SelectedSkillRef or "") then
            entry:SetBorderColor(0.94, 0.74, 0.22, 1)
        else
            entry:SetBorderColor(0.42, 0.46, 0.52, 1)
        end
        entry.skillRow = row

        local frame = entry.GetFrame and entry:GetFrame() or nil
        if frame then
            frame:EnableMouse(true)
            frame:SetScript("OnMouseUp", function(_, button)
                if button == "LeftButton" and row and row.ref then
                    if tostring(row.ref or "") == tostring(self.SelectedSkillRef or "") then
                        return
                    end
                    self.SelectedSkillRef = row.ref
                    if self.ShowCraftingUI and tostring(row.skillType or "") == "crafting" then
                        self.SelectedRecipeRef = nil
                    end
                    self:RefreshSelectedSkillState()
                end
            end)
        end
    end
end

function SkillsPage:RefreshEntries(restartSession)
    local categoryKey = tostring(self.SelectedCategoryKey or "")
    local skillEntries = self.SkillEntriesByCategory and self.SkillEntriesByCategory[categoryKey] or {}
    local hasSelection = false

    for index = 1, #skillEntries do
        if tostring(skillEntries[index] and skillEntries[index].ref or "") == tostring(self.SelectedSkillRef or "") then
            hasSelection = true
            break
        end
    end

    if not hasSelection then
        self.SelectedSkillRef = skillEntries[1] and skillEntries[1].ref or nil
    end

    self:BeginSkillListSession(restartSession == true)

    if self.GridEmptyText and self.GridEmptyText.SetText then
        if #skillEntries > 0 then
            self.GridEmptyText:SetText("")
        elseif (tonumber(self.AuthoredSkillCount) or 0) <= 0 then
            self.GridEmptyText:SetText("No skills are authored in active datasets.")
        else
            self.GridEmptyText:SetText("No enabled skills in this category.")
        end
    end
end

function SkillsPage:RefreshFooter()
    local row = self:GetSelectedSkillRow()
    local isCraftingSkill = row ~= nil and tostring(row.skillType or "") == "crafting"
    local canBindToActionBar = row ~= nil
        and tostring(row.skillType or "") == "noncombat"
        and row.rollable == true
    local boundSlot = canBindToActionBar and Profile.FindActionBarSlotBySkill and Profile.FindActionBarSlotBySkill(row.ref) or nil

    if self.CraftingRoot and self.CraftingRoot.GetFrame then
        self.CraftingRoot:GetFrame():Hide()
    end
    if self.ContentLayout and self.ContentLayout.GetFrame then
        self.ContentLayout:GetFrame():Show()
    end

    if self.FooterIcon and self.FooterIcon.SetTexture then
        self.FooterIcon:SetTexture(row and row.icon ~= "" and row.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    end
    if self.FooterTitle and self.FooterTitle.SetText then
        self.FooterTitle:SetText(row and (row.name or "Skill") or "Skill Details")
    end
    if self.FooterHint and self.FooterHint.SetText then
        self.FooterHint:SetText(formatFooterLevelText(row))
    end
    if self.FooterDescriptionText and self.FooterDescriptionText.SetText then
        self.FooterDescriptionText:SetText(row and resolveSkillDescription(row) or "Select a skill to inspect it.")
    end

    if self.FooterValueText and self.FooterValueText.SetText then
        self.FooterValueText:SetText(row and ("Current Level: %d"):format(tonumber(row.value) or 0) or "Current Level: --")
    end
    if self.FooterProgressText and self.FooterProgressText.SetText then
        self.FooterProgressText:SetText(row and ("Progress: %d / %d"):format(tonumber(row.progressValue) or 0, tonumber(row.maxValue) or 0) or "Progress: --")
    end
    if self.FooterBaseText and self.FooterBaseText.SetText then
        if not row then
            self.FooterBaseText:SetText("Base Value: --")
        elseif row.isDerived == true then
            local statName = resolveDerivedStatLabel(row.derivedStatRef)
            local derivedAmount = tonumber(row.derivedValue) or 0
            local storedAmount = tonumber(row.storedValue) or 0
            local sourceText = ("%d from %s x %s"):format(
                derivedAmount,
                statName ~= "" and statName or "stat",
                tostring(tonumber(row.derivedMultiplier) or 0)
            )
            if storedAmount > 0 then
                sourceText = ("%s, stored +%d"):format(sourceText, storedAmount)
            end
            self.FooterBaseText:SetText(("Base Value: %d (%s)"):format(
                tonumber(row.baseValue) or 0,
                sourceText
            ))
        else
            self.FooterBaseText:SetText(("Base Value: %d"):format(tonumber(row.baseValue) or 0))
        end
    end
    if self.FooterBonusText and self.FooterBonusText.SetText then
        self.FooterBonusText:SetText(row and ("Total Bonuses: %+d"):format(tonumber(row.bonusValue) or 0) or "Total Bonuses: --")
    end
    if self.FooterCapText and self.FooterCapText.SetText then
        self.FooterCapText:SetText(row and ("Maximum Level: %d"):format(tonumber(row.maxValue) or 0) or "Maximum Level: --")
    end
    if self.FooterActionButton and self.FooterActionButton.SetText then
        if isCraftingSkill then
            self.FooterActionButton:SetText("Show Crafting")
        else
            self.FooterActionButton:SetText(boundSlot and "Remove From Action Bar" or "Add to Action Bar")
        end
    end
    if self.FooterActionButton and self.FooterActionButton.SetEnabled then
        self.FooterActionButton:SetEnabled(isCraftingSkill or canBindToActionBar)
    end
end

function SkillsPage:RefreshActionBarWidget(reason)
    if Client.BuildActionBarWidget then
        Client:BuildActionBarWidget()
    end
    if Client.ShowActionBarWidget then
        Client:ShowActionBarWidget()
    end
    if Client.RefreshActionBarWidget then
        Client:RefreshActionBarWidget(reason or "skills-action-bar")
    end
end

function SkillsPage:HandleFooterAction(skillRef)
    local row = self:FindSkillRow(skillRef, self.AllSkillRows)
    if not row and Profile.GetResolvedSkillRow then
        row = Profile.GetResolvedSkillRow(skillRef)
    end
    if row and tostring(row.skillType or "") == "crafting" then
        self.ShowCraftingUI = true
        self.SelectedRecipeRef = nil
        self:Refresh()
        return true
    end

    if not skillRef or not Profile.ToggleSkillActionBarBinding then
        return false
    end

    local action = Profile.ToggleSkillActionBarBinding(skillRef)
    if not action then
        return false
    end

    self:RefreshActionBarWidget("skills-footer-toggle")
    if self.owner and self.owner.Refresh then
        self.owner:Refresh()
    else
        self:Refresh()
    end
    return true
end

function SkillsPage:Build(parent, owner)
    self.owner = owner
    if self.frame then
        return self.frame
    end

    self.frame = CreateFrame("Frame", "RPEProfileSkillsPage", parent)
    self.frame:SetAllPoints(parent)

    self.RootLayout = UI.CreateLayout(UI.HorizontalLayoutGroup, self.frame, "RPEProfileSkillsRootLayout", {
        spacing = 8,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })
    UI.Utils.AnchorFill(self.RootLayout, self.frame, 0, 0, 0, 0)

    self.NavPanel = UI.CreatePanel(self.RootLayout:GetFrame(), "RPEProfileSkillsNavPanel", {
        width = NAV_PANEL_WIDTH,
        height = 304,
        contentInset = 2,
        showBorder = false,
    })
    self.RootLayout:AddChild(self.NavPanel)

    self.ContentPanel = UI.CreatePanel(self.RootLayout:GetFrame(), "RPEProfileSkillsContentPanel", {
        width = 340,
        height = 304,
        expandWidth = true,
        weight = 1,
        contentInset = 0,
        showBorder = false,
    })
    self.RootLayout:AddChild(self.ContentPanel)

    self.NavList = UI.ScrollLayout:New({
        name = "RPEProfileSkillsNavList",
        width = NAV_PANEL_WIDTH - 4,
        height = 300,
        visibleRows = 8,
        rowHeight = 18,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.ScrollListEntry,
        categoryWidth = 108,
        statusWidth = 26,
        categoryInsetLeft = 4,
        statusInsetRight = 4,
    })
    self.NavList:SetParent(self.NavPanel:GetContentFrame())
    self.NavList:SetRowRenderer(function(row, item)
        if row.SetCategory then
            row:SetCategory(item and item.name or "")
        end
        if row.SetTestName then
            row:SetTestName("")
        end
        if row.SetStatus then
            row:SetStatus(tostring(item and item.count or 0))
        end
        if row.SetDetail then
            row:SetDetail("")
        end

        local frame = row.GetFrame and row:GetFrame() or nil
        if frame then
            frame:EnableMouse(true)
            frame:SetScript("OnMouseUp", function(_, button)
                if button == "LeftButton" and item and item.key then
                    self.SelectedCategoryKey = item.key
                    self.SelectedSkillRef = nil
                    self.ShowCraftingUI = false
                    self.SelectedRecipeRef = nil
                    if self.EntryScroll and self.EntryScroll.SetScrollOffset then
                        self.EntryScroll:SetScrollOffset(0)
                    end
                    self:Refresh()
                end
            end)

            local isSelected = tostring(item and item.key or "") == tostring(self.SelectedCategoryKey or "")
            if row.entryBackground and row.entryBackground.SetColorTexture then
                local token = isSelected and "list.rowHover" or "list.rowBackground"
                local color = UI.ResolveColor(nil, token)
                row.entryBackground:SetColorTexture(color.r or 0.08, color.g or 0.09, color.b or 0.11, color.a or 0.85)
            end
        end
    end)
    self.NavList:Create()
    UI.Utils.AnchorFill(self.NavList, self.NavPanel:GetContentFrame(), 0, 0, 0, 0)

    self.NavEmptyText = UI.CreateText(self.NavPanel:GetContentFrame(), "RPEProfileSkillsNavEmptyText", "", {
        width = 140,
        height = 40,
        justifyH = "CENTER",
        wordWrap = true,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.NavEmptyText:GetFrame():SetPoint("CENTER", self.NavPanel:GetContentFrame(), "CENTER", 0, 0)

    self.ContentLayout = UI.CreateLayout(UI.VerticalLayoutGroup, self.ContentPanel:GetContentFrame(), "RPEProfileSkillsContentLayout", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })
    UI.Utils.AnchorFill(self.ContentLayout, self.ContentPanel:GetContentFrame(), GRID_PADDING, 0, GRID_PADDING, 0)

    self.GridTitle = UI.CreateText(self.ContentLayout:GetFrame(), "RPEProfileSkillsGridTitle", "Skills", {
        width = 320,
        height = 18,
        justifyH = "LEFT",
    })
    self.ContentLayout:AddChild(self.GridTitle)

    self.EntryScrollPanel = UI.CreatePanel(self.ContentLayout:GetFrame(), "RPEProfileSkillsEntryScrollPanel", {
        width = 320,
        height = (ENTRY_HEIGHT * ENTRY_ROWS) + (ENTRY_SPACING * (ENTRY_ROWS - 1)),
        contentInset = 0,
        showBorder = false,
        expandWidth = true,
    })
    self.ContentLayout:AddChild(self.EntryScrollPanel)

    self.EntryScroll = UI.ScrollLayout:New({
        name = "RPEProfileSkillsEntryScroll",
        width = 320,
        height = (ENTRY_HEIGHT * ENTRY_ROWS) + (ENTRY_SPACING * (ENTRY_ROWS - 1)),
        visibleRows = ENTRY_ROWS,
        rowHeight = ENTRY_HEIGHT,
        rowSpacing = ENTRY_SPACING,
        rowInsetLeft = 0,
        rowInsetRight = 2,
        rowInsetTop = 0,
        rowInsetBottom = 0,
        contentInsetLeft = 0,
        contentInsetRight = 0,
        contentInsetTop = 0,
        contentInsetBottom = 0,
        scrollBarInsetRight = 0,
        rowElementClass = UI.SkillEntry,
        rowWidth = 320,
    })
    self.EntryScroll:SetParent(self.EntryScrollPanel:GetContentFrame())
    self.EntryScroll:SetRowRenderer(self:BuildSkillEntryRenderer())
    self.EntryScroll:Create()
    UI.Utils.AnchorFill(self.EntryScroll, self.EntryScrollPanel:GetContentFrame(), 0, 0, 0, 0)

    self.GridEmptyText = UI.CreateText(self.EntryScrollPanel:GetContentFrame(), "RPEProfileSkillsGridEmptyText", "", {
        width = 200,
        height = 40,
        justifyH = "CENTER",
        wordWrap = true,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.GridEmptyText:GetFrame():SetPoint("CENTER", self.EntryScrollPanel:GetContentFrame(), "CENTER", 0, 0)

    self.FooterPanel = UI.CreatePanel(self.ContentLayout:GetFrame(), "RPEProfileSkillsFooterPanel", {
        width = 320,
        height = 120,
        contentInset = 8,
        showBorder = true,
        expandWidth = true,
        expandHeight = true,
        weight = 1,
    })
    self.ContentLayout:AddChild(self.FooterPanel)

    self.FooterLayout = UI.CreateLayout(UI.VerticalLayoutGroup, self.FooterPanel:GetContentFrame(), "RPEProfileSkillsFooterLayout", {
        spacing = 8,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(self.FooterLayout, self.FooterPanel:GetContentFrame(), 0, 0, 0, 0)

    self.FooterHeaderRow = UI.CreateLayout(UI.HorizontalLayoutGroup, self.FooterLayout:GetFrame(), "RPEProfileSkillsFooterHeaderRow", {
        height = 32,
        spacing = 10,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    self.FooterLayout:AddChild(self.FooterHeaderRow)

    self.FooterIconPanel = UI.CreatePanel(self.FooterHeaderRow:GetFrame(), "RPEProfileSkillsFooterIconPanel", {
        width = 32,
        height = 32,
        contentInset = 1,
        showBorder = true,
    })
    self.FooterHeaderRow:AddChild(self.FooterIconPanel)

    self.FooterIcon = UI.Image:New({
        name = "RPEProfileSkillsFooterIcon",
        width = 30,
        height = 30,
        texture = "Interface\\Icons\\INV_Misc_QuestionMark",
        border = false,
        textureInsetLeft = 0,
        textureInsetTop = 0,
        textureInsetRight = 0,
        textureInsetBottom = 0,
    })
    self.FooterIcon:SetParent(self.FooterIconPanel:GetContentFrame())
    self.FooterIcon:Create()
    self.FooterIcon:GetFrame():SetAllPoints(self.FooterIconPanel:GetContentFrame())

    self.FooterHeaderTextLayout = UI.CreateLayout(UI.VerticalLayoutGroup, self.FooterHeaderRow:GetFrame(), "RPEProfileSkillsFooterHeaderTextLayout", {
        width = 250,
        height = 32,
        spacing = 2,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
        expandWidth = true,
        weight = 1,
    })
    self.FooterHeaderRow:AddChild(self.FooterHeaderTextLayout)

    self.FooterTitle = UI.CreateText(self.FooterHeaderTextLayout:GetFrame(), "RPEProfileSkillsFooterTitle", "Skill Details", {
        width = 300,
        height = 14,
        justifyH = "LEFT",
    })
    self.FooterHeaderTextLayout:AddChild(self.FooterTitle)

    self.FooterHint = UI.CreateText(self.FooterHeaderTextLayout:GetFrame(), "RPEProfileSkillsFooterHint", "Level -- / --", {
        width = 300,
        height = 14,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.FooterHeaderTextLayout:AddChild(self.FooterHint)

    self.FooterActionButton = UI.TextButton:New({
        name = "RPEProfileSkillsFooterActionButton",
        width = 96,
        height = 18,
        text = "Add",
        fontSize = 8,
        border = false,
    })
    self.FooterActionButton:SetParent(self.FooterHeaderRow:GetFrame())
    self.FooterActionButton:Create()
    self.FooterActionButton:SetScript("OnClick", function()
        self:HandleFooterAction(self.SelectedSkillRef)
    end)
    self.FooterHeaderRow:AddChild(self.FooterActionButton)

    self.FooterDescriptionText = UI.CreateText(self.FooterLayout:GetFrame(), "RPEProfileSkillsFooterDescriptionText", "", {
        width = 300,
        height = 28,
        justifyH = "LEFT",
        wordWrap = true,
        textColor = UI.ResolveColor(nil, "text.primary"),
    })
    self.FooterLayout:AddChild(self.FooterDescriptionText)

    self.FooterStatsLayout = UI.CreateLayout(UI.VerticalLayoutGroup, self.FooterLayout:GetFrame(), "RPEProfileSkillsFooterStatsLayout", {
        spacing = 3,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    self.FooterLayout:AddChild(self.FooterStatsLayout)

    self.FooterValueText = UI.CreateText(self.FooterStatsLayout:GetFrame(), "RPEProfileSkillsFooterValueText", "Current Level: --", {
        width = 300,
        height = 14,
        justifyH = "LEFT",
    })
    self.FooterStatsLayout:AddChild(self.FooterValueText)

    self.FooterProgressText = UI.CreateText(self.FooterStatsLayout:GetFrame(), "RPEProfileSkillsFooterProgressText", "Progress: --", {
        width = 300,
        height = 14,
        justifyH = "LEFT",
    })
    self.FooterStatsLayout:AddChild(self.FooterProgressText)

    self.FooterBaseText = UI.CreateText(self.FooterStatsLayout:GetFrame(), "RPEProfileSkillsFooterBaseText", "Base Value: --", {
        width = 300,
        height = 14,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.FooterStatsLayout:AddChild(self.FooterBaseText)

    self.FooterBonusText = UI.CreateText(self.FooterStatsLayout:GetFrame(), "RPEProfileSkillsFooterBonusText", "Total Bonuses: --", {
        width = 300,
        height = 14,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.FooterStatsLayout:AddChild(self.FooterBonusText)

    self.FooterCapText = UI.CreateText(self.FooterStatsLayout:GetFrame(), "RPEProfileSkillsFooterCapText", "Maximum Level: --", {
        width = 300,
        height = 14,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.FooterStatsLayout:AddChild(self.FooterCapText)

    self.CraftingRoot = UI.CreateLayout(UI.VerticalLayoutGroup, self.ContentPanel:GetContentFrame(), "RPEProfileSkillsCraftingRoot", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })
    UI.Utils.AnchorFill(self.CraftingRoot, self.ContentPanel:GetContentFrame(), GRID_PADDING, 0, GRID_PADDING, 0)
    self.CraftingRoot:GetFrame():Hide()

    self.CraftingHeaderRow = UI.CreateLayout(UI.HorizontalLayoutGroup, self.CraftingRoot:GetFrame(), "RPEProfileSkillsCraftingHeaderRow", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
        height = 18,
    })
    self.CraftingRoot:AddChild(self.CraftingHeaderRow)

    self.CraftingBackButton = UI.TextButton:New({
        name = "RPEProfileSkillsCraftingBackButton",
        width = 48,
        height = 18,
        text = "Back",
        fontSize = 8,
        border = false,
    })
    self.CraftingBackButton:SetParent(self.CraftingHeaderRow:GetFrame())
    self.CraftingBackButton:Create()
    self.CraftingBackButton:SetScript("OnClick", function()
        self.ShowCraftingUI = false
        self:Refresh()
    end)
    self.CraftingHeaderRow:AddChild(self.CraftingBackButton)

    self.CraftingSkillDropdown = UI.CreateDropdown(self.CraftingHeaderRow:GetFrame(), "RPEProfileSkillsCraftingSkillDropdown", {
        width = 220,
        height = 18,
        expandWidth = true,
        weight = 1,
        items = {},
        onValueChanged = function(value)
            if value and value ~= "" and tostring(value) ~= tostring(self.SelectedSkillRef or "") then
                self.SelectedSkillRef = value
                self.SelectedRecipeRef = nil
                self.SelectedTrainerRecipeRef = nil
                self:Refresh()
            end
        end,
    })
    self.CraftingHeaderRow:AddChild(self.CraftingSkillDropdown)

    self.CraftingTrainerButton = UI.ImageButton:New({
        name = "RPEProfileSkillsCraftingTrainerButton",
        width = 18,
        height = 18,
        normalTexture = TRAINER_BUTTON_TEXTURE,
        highlightTexture = TRAINER_BUTTON_TEXTURE,
        pushedTexture = TRAINER_BUTTON_TEXTURE,
        disabledTexture = TRAINER_BUTTON_TEXTURE,
        suppressHighlight = true,
    })
    self.CraftingTrainerButton:SetParent(self.CraftingHeaderRow:GetFrame())
    self.CraftingTrainerButton:Create()
    self.CraftingTrainerButton:SetScript("OnClick", function()
        if self.ShowCraftingTrainerMode == true then
            self:ShowCraftingRecipeWindow()
            return
        end
        self:ShowCraftingTrainerWindow()
    end)
    self.CraftingHeaderRow:AddChild(self.CraftingTrainerButton)

    self.CraftingConvertButton = UI.TextButton:New({
        name = "RPEProfileSkillsCraftingConvertButton",
        width = 96,
        height = 18,
        text = "Convert Materials",
        fontSize = 8,
        border = false,
    })
    self.CraftingConvertButton:SetParent(self.CraftingHeaderRow:GetFrame())
    self.CraftingConvertButton:Create()
    self.CraftingConvertButton:SetScript("OnClick", function()
        self:ToggleCraftingConversionMode()
    end)
    self.CraftingHeaderRow:AddChild(self.CraftingConvertButton)

    self.CraftingRefreshButton = UI.TextButton:New({
        name = "RPEProfileSkillsCraftingRefreshButton",
        width = 72,
        height = 18,
        text = "Refresh",
        fontSize = 8,
        border = false,
    })
    self.CraftingRefreshButton:SetParent(self.CraftingHeaderRow:GetFrame())
    self.CraftingRefreshButton:Create()
    self.CraftingRefreshButton:SetScript("OnClick", function()
        self.CraftingRecipeListDirty = true
        self.CraftingTrainerListDirty = true
        self.CraftingConversionListDirty = true
        self.CraftingRecipeItemsDirty = true
        self.CraftingTrainerItemsDirty = true
        self.CraftingTrainerListApplied = false

        local selectedRow = self.GetSelectedSkillRow and self:GetSelectedSkillRow() or nil
        if selectedRow and tostring(selectedRow.skillType or "") == "crafting" then
            self:RefreshCraftingView(selectedRow, true)
        else
            self:Refresh()
        end
    end)
    self.CraftingHeaderRow:AddChild(self.CraftingRefreshButton)

    self.CraftingSkillProgressBar = UI.ProgressBar:New({
        name = "RPEProfileSkillsCraftingSkillProgressBar",
        width = 320,
        height = 16,
        minValue = 0,
        maxValue = 100,
        value = 0,
        text = "",
        fontSize = 8,
        fontFlags = "OUTLINE",
        primaryColor = { r = 0.36, g = 0.2, b = 0.62, a = 1 },
        textColor = { r = 1, g = 1, b = 1, a = 1 },
    })
    self.CraftingSkillProgressBar:SetParent(self.CraftingRoot:GetFrame())
    self.CraftingSkillProgressBar:Create()
    self.CraftingRoot:AddChild(self.CraftingSkillProgressBar)

    self.CraftingRecipePanel = UI.CreatePanel(self.CraftingRoot:GetFrame(), "RPEProfileSkillsCraftingRecipePanel", {
        width = 320,
        height = 196,
        contentInset = 0,
        showBorder = false,
        expandWidth = true,
        expandHeight = true,
        weight = 2,
    })
    self.CraftingRoot:AddChild(self.CraftingRecipePanel)

    self.CraftingRecipeScroll = UI.ScrollLayout:New({
        name = "RPEProfileSkillsCraftingRecipeScroll",
        width = 320,
        height = 1,
        visibleRows = 10,
        autoFitRows = true,
        minVisibleRows = 1,
        maxVisibleRows = 10,
        rowHeight = 18,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.ScrollListEntry,
        categoryWidth = 304,
        statusWidth = 0,
        categoryInsetLeft = 6,
        statusInsetRight = 4,
    })
    self.CraftingRecipeScroll:SetParent(self.CraftingRecipePanel:GetContentFrame())
    self.CraftingRecipeScroll:SetRowRenderer(function(recipeRow, item)
        local defaultNameColor = UI.ResolveColor(nil, "text.primary")

        if item.rowType == "header" then
            recipeRow:SetCategory((item.collapsed and "+ " or "- ") .. tostring(item.category or "General"))
            recipeRow:SetTestName("")
            recipeRow:SetStatus("")
            recipeRow:SetDetail("")
            if recipeRow.categoryRegion and recipeRow.categoryRegion.SetTextColor then
                local color = UI.ResolveColor(nil, "text.secondary")
                recipeRow.categoryRegion:SetTextColor(color.r or 1, color.g or 1, color.b or 1, color.a or 1)
            end
            if recipeRow.nameRegion and recipeRow.nameRegion.SetTextColor then
                recipeRow.nameRegion:SetTextColor(defaultNameColor.r or 1, defaultNameColor.g or 1, defaultNameColor.b or 1, defaultNameColor.a or 1)
            end
        elseif item.rowType == "loading" then
            local mutedColor = UI.ResolveColor(nil, "text.secondary")
            recipeRow:SetCategory(("Loading recipes... (%d/%d)"):format(
                math.max(0, tonumber(item.loadedCount) or 0),
                math.max(0, tonumber(item.totalCount) or 0)
            ))
            recipeRow:SetTestName("")
            recipeRow:SetStatus("")
            recipeRow:SetDetail("")
            if recipeRow.categoryRegion and recipeRow.categoryRegion.SetTextColor then
                recipeRow.categoryRegion:SetTextColor(mutedColor.r or 1, mutedColor.g or 1, mutedColor.b or 1, mutedColor.a or 1)
            end
            if recipeRow.nameRegion and recipeRow.nameRegion.SetTextColor then
                recipeRow.nameRegion:SetTextColor(mutedColor.r or 1, mutedColor.g or 1, mutedColor.b or 1, mutedColor.a or 1)
            end
        else
            local recipeName = tostring(item.detail and item.detail.name or "Recipe")
            local nameColor = UI.ResolveColor(nil, "text.primary")

            recipeRow:SetCategory(recipeName)
            recipeRow:SetTestName("")
            recipeRow:SetStatus("")
            recipeRow:SetDetail("")
            if recipeRow.categoryRegion and recipeRow.categoryRegion.SetTextColor then
                recipeRow.categoryRegion:SetTextColor(nameColor.r or 1, nameColor.g or 1, nameColor.b or 1, nameColor.a or 1)
            end
            if recipeRow.nameRegion and recipeRow.nameRegion.SetTextColor then
                recipeRow.nameRegion:SetTextColor(nameColor.r or 1, nameColor.g or 1, nameColor.b or 1, nameColor.a or 1)
            end
            if recipeRow.SetStatusColor then
                local mutedColor = UI.ResolveColor(nil, "text.muted")
                recipeRow:SetStatusColor(mutedColor.r or 1, mutedColor.g or 1, mutedColor.b or 1, mutedColor.a or 1)
            end
        end

        local frame = recipeRow.GetFrame and recipeRow:GetFrame() or nil
        if frame then
            if recipeRow.categoryRegion and recipeRow.categoryRegion.ClearAllPoints then
                recipeRow.categoryRegion:ClearAllPoints()
                recipeRow.categoryRegion:SetPoint("TOPLEFT", frame, "TOPLEFT", 6, -2)
                recipeRow.categoryRegion:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -2)
            end
            frame:EnableMouse(item.rowType ~= "loading")
            if recipeRow.entryBackground and recipeRow.entryBackground.SetColorTexture then
                local isSelectedRecipe = item.rowType == "recipe" and tostring(item.recipeRef or "") == tostring(self.SelectedRecipeRef or "")
                local isHeader = item.rowType == "header"
                local isLoading = item.rowType == "loading"
                if isSelectedRecipe then
                    local color = UI.ResolveColor(nil, "list.rowHover")
                    recipeRow.entryBackground:SetColorTexture(color.r or 0.12, color.g or 0.13, color.b or 0.16, color.a or 0.65)
                elseif isHeader then
                    recipeRow.entryBackground:SetColorTexture(0.09, 0.1, 0.13, 0.95)
                elseif isLoading then
                    recipeRow.entryBackground:SetColorTexture(0.07, 0.08, 0.1, 0.7)
                else
                    local color = UI.ResolveColor(nil, "list.rowBackground")
                    recipeRow.entryBackground:SetColorTexture(color.r or 0.08, color.g or 0.09, color.b or 0.11, color.a or 0.85)
                end
            end
            frame:SetScript("OnMouseUp", function(_, button)
                if button ~= "LeftButton" then
                    return
                end
                if item.rowType == "header" then
                    self.CraftingCollapsedCategories = self.CraftingCollapsedCategories or {}
                    self.CraftingCollapsedCategories[item.category] = not self.CraftingCollapsedCategories[item.category]
                    self:RefreshCraftingView(self:GetSelectedSkillRow(), true)
                elseif item.rowType == "recipe" then
                    self.SelectedRecipeRef = item.recipeRef
                    self:RefreshCraftingView(self:GetSelectedSkillRow(), false)
                end
            end)
        end
    end)
    self.CraftingRecipeScroll:Create()
    UI.Utils.AnchorFill(self.CraftingRecipeScroll, self.CraftingRecipePanel:GetContentFrame(), 0, 0, 0, 0)

    self.CraftingRecipeEmptyText = UI.CreateText(self.CraftingRecipePanel:GetContentFrame(), "RPEProfileSkillsCraftingRecipeEmptyText", "", {
        width = 220,
        height = 32,
        justifyH = "CENTER",
        wordWrap = true,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.CraftingRecipeEmptyText:GetFrame():SetPoint("CENTER", self.CraftingRecipePanel:GetContentFrame(), "CENTER", 0, 0)
    if self.CraftingRecipeEmptyText.GetFrame and self.CraftingRecipeEmptyText:GetFrame() and self.CraftingRecipeEmptyText:GetFrame().EnableMouse then
        self.CraftingRecipeEmptyText:GetFrame():EnableMouse(false)
    end

    self.CraftingDetailPanel = UI.CreatePanel(self.CraftingRoot:GetFrame(), "RPEProfileSkillsCraftingDetailPanel", {
        width = 320,
        height = 196,
        contentInset = 6,
        showBorder = true,
        expandWidth = true,
        expandHeight = true,
        weight = 3,
    })
    self.CraftingRoot:AddChild(self.CraftingDetailPanel)

    self.CraftingDetailLayout = UI.CreateLayout(UI.VerticalLayoutGroup, self.CraftingDetailPanel:GetContentFrame(), "RPEProfileSkillsCraftingDetailLayout", {
        spacing = 4,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })
    UI.Utils.AnchorFill(self.CraftingDetailLayout, self.CraftingDetailPanel:GetContentFrame(), 0, 0, 0, 0)

    self.CraftingDetailHeader = UI.CreateLayout(UI.HorizontalLayoutGroup, self.CraftingDetailLayout:GetFrame(), "RPEProfileSkillsCraftingDetailHeader", {
        spacing = 8,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
        height = 34,
    })
    self.CraftingDetailLayout:AddChild(self.CraftingDetailHeader)

    self.CraftingDetailIcon = UI.Image:New({
        name = "RPEProfileSkillsCraftingDetailIcon",
        width = 30,
        height = 30,
        texture = "Interface\\Icons\\INV_Misc_QuestionMark",
        border = false,
    })
    self.CraftingDetailIcon:SetParent(self.CraftingDetailHeader:GetFrame())
    self.CraftingDetailIcon:Create()
    self.CraftingDetailHeader:AddChild(self.CraftingDetailIcon)

    self.CraftingDetailHeaderText = UI.CreateLayout(UI.VerticalLayoutGroup, self.CraftingDetailHeader:GetFrame(), "RPEProfileSkillsCraftingDetailHeaderText", {
        height = 30,
        spacing = 2,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
        expandWidth = true,
        weight = 1,
    })
    self.CraftingDetailHeader:AddChild(self.CraftingDetailHeaderText)

    self.CraftingDetailTitle = UI.CreateText(self.CraftingDetailHeaderText:GetFrame(), "RPEProfileSkillsCraftingDetailTitle", "Recipe Details", {
        width = 252,
        height = 14,
        justifyH = "LEFT",
    })
    self.CraftingDetailHeaderText:AddChild(self.CraftingDetailTitle)

    self.CraftingDetailHint = UI.CreateText(self.CraftingDetailHeaderText:GetFrame(), "RPEProfileSkillsCraftingDetailHint", "", {
        width = 252,
        height = 14,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.CraftingDetailHeaderText:AddChild(self.CraftingDetailHint)

    self.CraftingMaterialsTable = UI.Table:New({
        name = "RPEProfileSkillsCraftingMaterialsTable",
        width = 300,
        height = 92,
        visibleRows = 4,
        rowHeight = 20,
        expandHeight = true,
        weight = 1,
        columns = {
            { key = "name", label = "Item", width = 160 },
            { key = "required", label = "Need", width = 40, justifyH = "RIGHT" },
            { key = "owned", label = "Owned", width = 40, justifyH = "RIGHT" },
            { key = "status", label = "Status", width = 56, justifyH = "RIGHT" },
        },
    })
    self.CraftingMaterialsTable:SetParent(self.CraftingDetailLayout:GetFrame())
    self.CraftingMaterialsTable:Create()
    self.CraftingMaterialsTable.bodyScroll:SetRowRenderer(function(row, item, itemIndex)
        if row.SetColumns then
            row:SetColumns(self.CraftingMaterialsTable:GetResolvedColumns())
        end
        if row.SetRowData then
            row:SetRowData(item and item.rowData or nil, item and item.sourceIndex or itemIndex)
        end
        if row.SetRowMouseUpHandler then
            row:SetRowMouseUpHandler(function(tableRow, button, rowData)
                if button == "RightButton" then
                    local anchor = tableRow and tableRow.GetFrame and tableRow:GetFrame() or nil
                    self:ShowCraftingMaterialContextMenu(anchor, rowData)
                end
            end)
        end
    end)
    self.CraftingDetailLayout:AddChild(self.CraftingMaterialsTable)

    self.CraftingQueueText = UI.CreateText(self.CraftingDetailLayout:GetFrame(), "RPEProfileSkillsCraftingQueueText", "Crafting: Idle", {
        width = 300,
        height = 14,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.CraftingDetailLayout:AddChild(self.CraftingQueueText)

    self.CraftingActions = UI.CreateLayout(UI.HorizontalLayoutGroup, self.CraftingDetailLayout:GetFrame(), "RPEProfileSkillsCraftingActions", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
        height = 18,
    })
    self.CraftingDetailLayout:AddChild(self.CraftingActions)

    self.CraftingCraftOneButton = UI.TextButton:New({
        name = "RPEProfileSkillsCraftingCraftOneButton",
        width = 60,
        height = 18,
        text = "Craft X",
        fontSize = 8,
        border = false,
        expandWidth = true,
        weight = 1,
    })
    self.CraftingCraftOneButton:SetParent(self.CraftingActions:GetFrame())
    self.CraftingCraftOneButton:Create()
    self.CraftingCraftOneButton:SetScript("OnClick", function()
        local detail = self:GetSelectedCraftingRecipeDetail()
        if Crafting and detail then
            showCraftCountPopup(self, detail)
        end
    end)
    self.CraftingActions:AddChild(self.CraftingCraftOneButton)

    self.CraftingCraftAllButton = UI.TextButton:New({
        name = "RPEProfileSkillsCraftingCraftAllButton",
        width = 60,
        height = 18,
        text = "Craft All",
        fontSize = 8,
        border = false,
        expandWidth = true,
        weight = 1,
    })
    self.CraftingCraftAllButton:SetParent(self.CraftingActions:GetFrame())
    self.CraftingCraftAllButton:Create()
    self.CraftingCraftAllButton:SetScript("OnClick", function()
        local detail = self:GetSelectedCraftingRecipeDetail()
        if Crafting and detail then
            Crafting:QueueAll(detail.recipeRef)
        end
    end)
    self.CraftingActions:AddChild(self.CraftingCraftAllButton)

    self.CraftingCancelButton = UI.TextButton:New({
        name = "RPEProfileSkillsCraftingCancelButton",
        width = 60,
        height = 18,
        text = "Cancel",
        fontSize = 8,
        border = false,
        expandWidth = true,
        weight = 1,
    })
    self.CraftingCancelButton:SetParent(self.CraftingActions:GetFrame())
    self.CraftingCancelButton:Create()
    self.CraftingCancelButton:SetScript("OnClick", function()
        if Crafting and Crafting.CancelCrafting then
            Crafting:CancelCrafting("manual")
        end
    end)
    self.CraftingActions:AddChild(self.CraftingCancelButton)

    self.CraftingConversionPanel = UI.CreatePanel(self.CraftingRoot:GetFrame(), "RPEProfileSkillsCraftingConversionPanel", {
        width = 320,
        height = 0,
        contentInset = 0,
        showBorder = false,
        expandWidth = true,
        expandHeight = true,
        weight = 5,
    })
    self.CraftingRoot:AddChild(self.CraftingConversionPanel)

    self.CraftingConversionLayout = UI.CreateLayout(UI.VerticalLayoutGroup, self.CraftingConversionPanel:GetContentFrame(), "RPEProfileSkillsCraftingConversionLayout", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })
    UI.Utils.AnchorFill(self.CraftingConversionLayout, self.CraftingConversionPanel:GetContentFrame(), 0, 0, 0, 0)

    self.CraftingConversionSearchRow = UI.CreateLayout(UI.HorizontalLayoutGroup, self.CraftingConversionLayout:GetFrame(), "RPEProfileSkillsCraftingConversionSearchRow", {
        spacing = 4,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
        height = 18,
    })
    self.CraftingConversionLayout:AddChild(self.CraftingConversionSearchRow)

    self.CraftingConversionSearchInput = UI.CreateTextInput(self.CraftingConversionSearchRow:GetFrame(), "RPEProfileSkillsCraftingConversionSearchInput", {
        width = 240,
        height = 18,
        text = "",
        placeholder = "Search materials",
        expandWidth = true,
        weight = 1,
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.CraftingConversionSearchInput:SetScript("OnTextChanged", function()
        self.CraftingConversionSearchQuery = self.CraftingConversionSearchInput:GetText()
        self:RefreshCraftingConversionWindow()
    end)
    self.CraftingConversionSearchRow:AddChild(self.CraftingConversionSearchInput)

    self.CraftingConversionSearchClearButton = UI.CreateButton(self.CraftingConversionSearchRow:GetFrame(), "RPEProfileSkillsCraftingConversionSearchClearButton", "Clear", 40, function()
        self.CraftingConversionSearchQuery = ""
        if self.CraftingConversionSearchInput then
            self.CraftingConversionSearchInput:SetText("")
        end
        self:RefreshCraftingConversionWindow()
    end, {
        height = 18,
        fontSize = 8,
    })
    self.CraftingConversionSearchRow:AddChild(self.CraftingConversionSearchClearButton)

    self.CraftingConversionListPanel = UI.CreatePanel(self.CraftingConversionLayout:GetFrame(), "RPEProfileSkillsCraftingConversionListPanel", {
        width = 300,
        height = 0,
        contentInset = 2,
        showBorder = false,
        expandWidth = true,
        expandHeight = true,
        weight = 1,
    })
    self.CraftingConversionLayout:AddChild(self.CraftingConversionListPanel)

    self.CraftingConversionScroll = UI.ScrollLayout:New({
        name = "RPEProfileSkillsCraftingConversionScroll",
        width = 296,
        height = 1,
        visibleRows = 10,
        autoFitRows = true,
        rowHeight = 24,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.SpellbookEntry,
        rowWidth = 296,
    })
    self.CraftingConversionScroll:SetParent(self.CraftingConversionListPanel:GetContentFrame())
    self.CraftingConversionScroll:SetRowRenderer(function(row, item)
        if row.SetIcon then
            row:SetIcon(item and item.icon ~= "" and item.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        end
        if row.SetSpellName then
            row:SetSpellName(item and item.name or "")
        end
        if row.nameRegion and row.nameRegion.SetTextColor then
            local r, g, b = 1, 1, 1
            if item and item.item then
                r, g, b = getQualityColor(item.item)
            end
            row.nameRegion:SetTextColor(r or 1, g or 1, b or 1, 1)
        end

        local frame = row.GetFrame and row:GetFrame() or nil
        if frame then
            frame:EnableMouse(true)
            if row.SetTooltip then
                row:SetTooltip(buildCraftingConversionItemTooltip(item))
            end
            frame:SetScript("OnMouseUp", function(_, button)
                if button ~= "LeftButton" or not item then
                    return
                end

                self.SelectedConversionMaterialRef = item.itemRef
                self:RefreshCraftingConversionWindow()
                self:ShowCraftingConversionDialog(item)
            end)
        end
    end)
    self.CraftingConversionScroll:Create()
    UI.Utils.AnchorFill(self.CraftingConversionScroll, self.CraftingConversionListPanel:GetContentFrame(), 0, 0, 0, 0)

    self.CraftingConversionEmptyText = UI.CreateText(self.CraftingConversionListPanel:GetContentFrame(), "RPEProfileSkillsCraftingConversionEmptyText", "", {
        width = 220,
        height = 32,
        justifyH = "CENTER",
        wordWrap = true,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.CraftingConversionEmptyText:GetFrame():SetPoint("CENTER", self.CraftingConversionListPanel:GetContentFrame(), "CENTER", 0, 0)
    if self.CraftingConversionEmptyText.GetFrame and self.CraftingConversionEmptyText:GetFrame() and self.CraftingConversionEmptyText:GetFrame().EnableMouse then
        self.CraftingConversionEmptyText:GetFrame():EnableMouse(false)
    end

    self.CraftingTrainerPanel = UI.CreatePanel(self.CraftingRoot:GetFrame(), "RPEProfileSkillsCraftingTrainerPanel", {
        width = 320,
        height = 0,
        contentInset = 4,
        showBorder = true,
        expandWidth = true,
        expandHeight = true,
        weight = 5,
    })
    self.CraftingRoot:AddChild(self.CraftingTrainerPanel)

    self.CraftingTrainerLayout = UI.CreateLayout(UI.VerticalLayoutGroup, self.CraftingTrainerPanel:GetContentFrame(), "RPEProfileSkillsCraftingTrainerLayout", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })
    UI.Utils.AnchorFill(self.CraftingTrainerLayout, self.CraftingTrainerPanel:GetContentFrame(), 0, 0, 0, 0)

    self.CraftingTrainerListPanel = UI.CreatePanel(self.CraftingTrainerLayout:GetFrame(), "RPEProfileSkillsCraftingTrainerListPanel", {
        width = 300,
        height = 0,
        contentInset = 2,
        showBorder = false,
        expandWidth = true,
        expandHeight = true,
        weight = 1,
    })
    self.CraftingTrainerLayout:AddChild(self.CraftingTrainerListPanel)

    self.CraftingTrainerScroll = UI.ScrollLayout:New({
        name = "RPEProfileSkillsCraftingTrainerScroll",
        width = 296,
        height = 1,
        visibleRows = 10,
        autoFitRows = true,
        minVisibleRows = 1,
        maxVisibleRows = 10,
        rowHeight = 24,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.TrainerEntry,
        rowWidth = 296,
    })
    self.CraftingTrainerScroll:SetParent(self.CraftingTrainerListPanel:GetContentFrame())
    self.CraftingTrainerScroll:SetRowRenderer(function(row, item)
        local detail = item
        local frame = row.GetFrame and row:GetFrame() or nil
        local isLoading = detail and detail.loading == true
        local isSelected = not isLoading and tostring(detail and detail.recipeRef or "") == tostring(self.SelectedTrainerRecipeRef or "")
        local statusText = ""
        if isLoading then
            statusText = ("%d/%d ready"):format(
                math.max(0, tonumber(detail.loadedCount) or 0),
                math.max(0, tonumber(detail.totalCount) or 0)
            )
        elseif detail then
            statusText = detail.isLockedByLevel == true
                and ("Locked until %d"):format(tonumber(detail.requiredSkillLevel) or 0)
                or tostring(detail.trainerCostText or "")
        end

        if row.SetIcon then
            row:SetIcon(not isLoading and detail and detail.output and detail.output.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        end
        if row.SetRecipeName then
            row:SetRecipeName(isLoading and "Loading trainer recipes..." or detail and tostring(detail.name or "Recipe") or "")
        end
        if row.SetStatusText then
            row:SetStatusText(statusText)
        end
        if row.SetEnabled then
            row:SetEnabled(isLoading ~= true and detail ~= nil and detail.isLockedByLevel ~= true)
        end
        if row.SetSelected then
            row:SetSelected(isSelected)
        end
        if row.SetBorderColor then
            if isSelected then
                row:SetBorderColor(0.94, 0.74, 0.22, 1)
            else
                local color = UI.ResolveColor(nil, "panel.border")
                row:SetBorderColor(color.r or 0.42, color.g or 0.46, color.b or 0.52, color.a or 1)
            end
        end
        if row.SetNameColor then
            local color = isLoading and UI.ResolveColor(nil, "text.secondary")
                or detail and detail.isLockedByLevel ~= true and UI.ResolveColor(nil, "text.primary")
                or UI.ResolveColor(nil, "text.secondary")
            row:SetNameColor(color.r or 1, color.g or 1, color.b or 1, color.a or 1)
        end
        if row.SetStatusColor then
            local color = isLoading and UI.ResolveColor(nil, "text.secondary")
                or detail and detail.isLockedByLevel ~= true and UI.ResolveColor(nil, "text.secondary") or {
                r = 1,
                g = 0.33,
                b = 0.33,
                a = 1,
            }
            row:SetStatusColor(color.r or 1, color.g or 1, color.b or 1, color.a or 1)
        end
        if row.SetTooltip then
            if not isLoading and detail then
                row:SetTooltip(function()
                    return buildCraftingOutputTooltip(detail)
                end)
            else
                row:SetTooltip(nil)
            end
        end
        if frame then
            frame:EnableMouse(isLoading ~= true)
            frame:SetScript("OnMouseUp", function(_, button)
                if button ~= "LeftButton" or not detail or isLoading == true or detail.isLockedByLevel == true then
                    return
                end
                self.SelectedTrainerRecipeRef = detail.recipeRef
                self:RefreshCraftingTrainerWindow()
            end)
        end
    end)
    self.CraftingTrainerScroll:Create()
    UI.Utils.AnchorFill(self.CraftingTrainerScroll, self.CraftingTrainerListPanel:GetContentFrame(), 0, 0, 0, 0)

    self.CraftingTrainerEmptyText = UI.CreateText(self.CraftingTrainerListPanel:GetContentFrame(), "RPEProfileSkillsCraftingTrainerEmptyText", "", {
        width = 220,
        height = 32,
        justifyH = "CENTER",
        wordWrap = true,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.CraftingTrainerEmptyText:GetFrame():SetPoint("CENTER", self.CraftingTrainerListPanel:GetContentFrame(), "CENTER", 0, 0)
    if self.CraftingTrainerEmptyText.GetFrame and self.CraftingTrainerEmptyText:GetFrame() and self.CraftingTrainerEmptyText:GetFrame().EnableMouse then
        self.CraftingTrainerEmptyText:GetFrame():EnableMouse(false)
    end

    self.CraftingTrainerDetailText = UI.CreateText(self.CraftingTrainerLayout:GetFrame(), "RPEProfileSkillsCraftingTrainerDetailText", "Select a recipe to learn from the trainer.", {
        width = 296,
        height = 32,
        justifyH = "LEFT",
        wordWrap = true,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.CraftingTrainerLayout:AddChild(self.CraftingTrainerDetailText)

    self.CraftingTrainerLearnButton = UI.TextButton:New({
        name = "RPEProfileSkillsCraftingTrainerLearnButton",
        width = 80,
        height = 18,
        text = "Learn",
        fontSize = 8,
        border = false,
    })
    self.CraftingTrainerLearnButton:SetParent(self.CraftingTrainerLayout:GetFrame())
    self.CraftingTrainerLearnButton:Create()
    self.CraftingTrainerLearnButton:SetScript("OnClick", function()
        local detail = self:GetSelectedTrainerRecipeDetail()
        if Crafting and detail and Crafting.LearnRecipeFromTrainer then
            Crafting:LearnRecipeFromTrainer(detail.recipeRef)
        end
    end)
    self.CraftingTrainerLayout:AddChild(self.CraftingTrainerLearnButton)

    if Crafting and Crafting.RegisterListener then
        self.CraftingListenerId = Crafting:RegisterListener(function()
            if self.frame then
                self.CraftingRecipeListDirty = true
                self.CraftingTrainerListDirty = true
                self.CraftingConversionListDirty = true
                self.CraftingRecipeItemsDirty = true
                self.CraftingTrainerItemsDirty = true
                self.CraftingTrainerListApplied = false
                self:Refresh()
            end
        end)
    end

    self:Refresh()
    return self.frame
end

function SkillsPage:Refresh()
    if not self.frame then
        return nil
    end

    local navRows, skillRefsByCategory, skillEntriesByCategory, authoredCount = buildNavigationRows()
    self.NavRows = navRows
    self.SkillRefsByCategory = skillRefsByCategory
    self.SkillEntriesByCategory = skillEntriesByCategory
    self.AuthoredSkillCount = authoredCount or 0
    self:EnsureSelection(navRows)
    self.AllSkillRows = {}

    if self.NavList and self.NavList.SetItems then
        if self.NavList.SetScrollOffset then
            self.NavList:SetScrollOffset(0)
        end
        self.NavList:SetItems(navRows)
        refreshNavListVisualRows(self, navRows)
    end
    if self.NavEmptyText and self.NavEmptyText.SetText then
        self.NavEmptyText:SetText(#navRows == 0 and "No enabled skill groups available." or "")
    end

    local title = "Skills"
    for index = 1, #navRows do
        local row = navRows[index]
        if tostring(row.key or "") == tostring(self.SelectedCategoryKey or "") then
            title = row.name or title
            break
        end
    end

    if self.GridTitle and self.GridTitle.SetText then
        self.GridTitle:SetText(title)
    end

    self:RefreshEntries(true)

    local selectedRow = self:GetSelectedSkillRow()
    local showCraftingUI = self.ShowCraftingUI == true
        and tostring(self.SelectedCategoryKey or "") == "crafting"
        and selectedRow ~= nil
        and tostring(selectedRow.skillType or "") == "crafting"

    if not showCraftingUI then
        self.ShowCraftingUI = false
        self:RefreshFooter()
    else
        self:RefreshCraftingView(selectedRow)
    end

    return self.frame
end

return SkillsPage
