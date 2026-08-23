local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}
Addon.Debug = Addon.Debug or {}
Addon.Debug.Clipboard = Addon.Debug.Clipboard or {}

local Client = Addon.Client
local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}

local function getClipboard()
    return Addon.Debug and Addon.Debug.Clipboard or nil
end

DataEditor.__index = DataEditor
DataEditor.Database = Addon.Internal and Addon.Internal.Database or {}
DataEditor.Registry = Addon.Internal and Addon.Internal.Registry or {}

local ENTRY_DEFINITIONS = {
    units = { className = "Unit", singular = "Unit", buttonLabel = "New Unit", emptyName = "Unnamed Unit", assignsId = true },
    mounts = { className = "Mount", singular = "Mount", buttonLabel = "New Mount", emptyName = "Unnamed Mount", assignsId = true },
    pets = { className = "Pet", singular = "Pet", buttonLabel = "New Pet", emptyName = "Unnamed Pet", assignsId = true },
    items = { className = "Item", singular = "Item", buttonLabel = "New Item", emptyName = "Unnamed Item", assignsId = true },
    spells = { className = "Spell", singular = "Spell", buttonLabel = "New Spell", emptyName = "Unnamed Spell", assignsId = true },
    traits = { className = "Trait", singular = "Trait", buttonLabel = "New Trait", emptyName = "Unnamed Trait", assignsId = true },
    skills = { className = "Skill", singular = "Skill", buttonLabel = "New Skill", emptyName = "Unnamed Skill", assignsId = true },
    stats = { className = "Stat", singular = "Stat", buttonLabel = "New Stat", emptyName = "Unnamed Stat", assignsId = true },
    resources = { className = "Resource", singular = "Resource", buttonLabel = "New Resource", emptyName = "Unnamed Resource", assignsId = true },
    races = { className = "Race", singular = "Race", buttonLabel = "New Race", emptyName = "Unnamed Race", assignsId = true },
    classes = { className = "Class", singular = "Class", buttonLabel = "New Class", emptyName = "Unnamed Class", assignsId = true },
    itemSlots = { className = "ItemSlot", singular = "Item Slot", buttonLabel = "New Item Slot", emptyName = "Unnamed Item Slot", assignsId = true },
    weaponTypes = { className = "WeaponType", singular = "Weapon Type", buttonLabel = "New Weapon Type", emptyName = "Unnamed Weapon Type", assignsId = true },
    damageSchools = { className = "DamageSchool", singular = "Damage School", buttonLabel = "New Damage School", emptyName = "Unnamed Damage School", assignsId = true },
    loot = { className = "Loot", singular = "Loot", buttonLabel = "New Loot", emptyName = "Unnamed Loot", assignsId = true },
    recipes = { className = "Recipe", singular = "Recipe", buttonLabel = "New Recipe", emptyName = "Unnamed Recipe", assignsId = true },
    auras = { className = "Aura", singular = "Aura", buttonLabel = "New Aura", emptyName = "Unnamed Aura", assignsId = true },
    interactions = { className = "Interaction", singular = "Interaction", buttonLabel = "New Interaction", emptyName = "Unnamed Interaction", assignsId = true },
    achievements = { className = "Achievement", singular = "Achievement", buttonLabel = "New Achievement", emptyName = "Unnamed Achievement", assignsId = true },
    currencies = { className = "Currency", singular = "Currency", buttonLabel = "New Currency", emptyName = "Unnamed Currency", assignsId = true },
}

local INSPECTOR_PAGE_BY_COLLECTION = {
    units = "unit",
    mounts = "mount",
    pets = "pet",
    items = "item",
    spells = "spell",
    traits = "trait",
    skills = "skill",
    recipes = "recipe",
    auras = "aura",
    itemSlots = "itemSlot",
    weaponTypes = "weaponType",
    damageSchools = "damageSchool",
    stats = "stat",
    resources = "resource",
    achievements = "achievement",
    currencies = "currency",
    races = "race",
    classes = "class",
}

local DATA_PAGE_REFRESHER_BY_COLLECTION = {
    units = "RefreshUnitsDataPage",
    mounts = "RefreshMountsDataPage",
    pets = "RefreshPetsDataPage",
    items = "RefreshItemsDataPage",
    spells = "RefreshSpellsDataPage",
    traits = "RefreshTraitsDataPage",
    skills = "RefreshSkillsDataPage",
    stats = "RefreshStatsDataPage",
    resources = "RefreshResourcesDataPage",
    races = "RefreshRacesDataPage",
    classes = "RefreshClassesDataPage",
    itemSlots = "RefreshItemSlotsDataPage",
    weaponTypes = "RefreshWeaponTypesDataPage",
    damageSchools = "RefreshDamageSchoolsDataPage",
    loot = "RefreshLootDataPage",
    recipes = "RefreshRecipeDataPage",
    auras = "RefreshAuraDataPage",
    interactions = "RefreshInteractionDataPage",
    achievements = "RefreshAchievementDataPage",
    currencies = "RefreshCurrencyDataPage",
}

local INSPECTOR_REFRESHER_BY_PAGE = {
    dataset = "RefreshDatasetInspectorPage",
    unit = "RefreshUnitInspectorPage",
    mount = "RefreshMountInspectorPage",
    pet = "RefreshPetInspectorPage",
    item = "RefreshItemInspectorPage",
    spell = "RefreshSpellInspectorPage",
    trait = "RefreshTraitInspectorPage",
    skill = "RefreshSkillInspectorPage",
    recipe = "RefreshRecipeInspectorPage",
    aura = "RefreshAuraInspectorPage",
    itemSlot = "RefreshItemSlotInspectorPage",
    weaponType = "RefreshWeaponTypeInspectorPage",
    damageSchool = "RefreshDamageSchoolInspectorPage",
    stat = "RefreshStatInspectorPage",
    resource = "RefreshResourceInspectorPage",
    achievement = "RefreshAchievementInspectorPage",
    currency = "RefreshCurrencyInspectorPage",
    race = "RefreshRaceInspectorPage",
    class = "RefreshClassInspectorPage",
}

local INSPECTOR_SELECTION_GETTER_BY_PAGE = {
    unit = "GetSelectedUnit",
    mount = "GetSelectedMount",
    pet = "GetSelectedPet",
    item = "GetSelectedItem",
    spell = "GetSelectedSpell",
    trait = "GetSelectedTrait",
    skill = "GetSelectedSkill",
    recipe = "GetSelectedRecipe",
    aura = "GetSelectedAura",
    itemSlot = "GetSelectedItemSlot",
    weaponType = "GetSelectedWeaponType",
    damageSchool = "GetSelectedDamageSchool",
    stat = "GetSelectedStat",
    resource = "GetSelectedResource",
    achievement = "GetSelectedAchievement",
    currency = "GetSelectedCurrency",
    race = "GetSelectedRace",
    class = "GetSelectedClass",
}

local function collectionQueuesDependencyRecompute(collectionKey)
    return collectionKey == "units"
        or collectionKey == "mounts"
        or collectionKey == "stats"
        or collectionKey == "resources"
        or collectionKey == "items"
        or collectionKey == "spells"
        or collectionKey == "traits"
        or collectionKey == "skills"
        or collectionKey == "races"
        or collectionKey == "classes"
        or collectionKey == "itemSlots"
        or collectionKey == "weaponTypes"
        or collectionKey == "damageSchools"
        or collectionKey == "auras"
        or collectionKey == "achievements"
end

function DataEditor:GetEntryDefinition(collectionKey)
    return ENTRY_DEFINITIONS[collectionKey]
end

function DataEditor:GetInspectorPageKeyForCollection(collectionKey)
    return INSPECTOR_PAGE_BY_COLLECTION[collectionKey]
end

function DataEditor:GetEntryDisplayName(collectionKey, entry)
    local definition = self:GetEntryDefinition(collectionKey) or {}
    local name = entry and entry.name or nil
    if name == nil or name == "" then
        return definition.emptyName or "Unnamed Entry"
    end

    return tostring(name)
end

local function normalizeFilterText(text)
    text = tostring(text or "")
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    return string.lower(text)
end

local function appendFilterValue(buffer, value)
    local text = tostring(value or "")
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    if text ~= "" then
        buffer[#buffer + 1] = string.lower(text)
    end
end

local function appendFilterValues(buffer, values)
    if type(values) ~= "table" then
        return
    end

    for index = 1, #values do
        appendFilterValue(buffer, values[index])
    end
end

function DataEditor:GetCollectionFilterText(collectionKey)
    self.CollectionFilterTexts = self.CollectionFilterTexts or {}
    return tostring(self.CollectionFilterTexts[collectionKey] or "")
end

function DataEditor:SetCollectionFilterText(collectionKey, text)
    self.CollectionFilterTexts = self.CollectionFilterTexts or {}
    self.CollectionFilterTexts[collectionKey] = tostring(text or "")
end

function DataEditor:GetCollectionDropdownFilterValue(collectionKey)
    self.CollectionDropdownFilterValues = self.CollectionDropdownFilterValues or {}
    return self.CollectionDropdownFilterValues[collectionKey] or "all"
end

function DataEditor:SetCollectionDropdownFilterValue(collectionKey, value)
    self.CollectionDropdownFilterValues = self.CollectionDropdownFilterValues or {}
    self.CollectionDropdownFilterValues[collectionKey] = value or "all"
end

function DataEditor:BuildCollectionFilterIndex(collectionKey, entry)
    local values = {}

    appendFilterValue(values, self:GetEntryDisplayName(collectionKey, entry))
    appendFilterValue(values, entry and entry.id or nil)
    appendFilterValue(values, entry and entry.description or nil)
    appendFilterValues(values, entry and entry.tags or nil)

    if collectionKey == "items" then
        appendFilterValue(values, entry and entry.itemType or nil)
        appendFilterValue(values, entry and entry.quality or nil)
        appendFilterValue(values, entry and entry.itemSetKey or nil)
    elseif collectionKey == "spells" then
        appendFilterValue(values, entry and entry.spellbookCategory or nil)
        appendFilterValue(values, entry and entry.castType or nil)
        appendFilterValue(values, entry and entry.castTime or nil)
    elseif collectionKey == "auras" then
        appendFilterValue(values, entry and entry.duration or nil)
        appendFilterValue(values, entry and entry.maxStacks or nil)
        appendFilterValue(values, entry and entry.icon or nil)
    end

    return table.concat(values, "\n")
end

function DataEditor:GetFilteredDatasetEntries(collectionKey, entries)
    local filtered = {}
    local query = normalizeFilterText(self:GetCollectionFilterText(collectionKey))

    for index = 1, #(entries or {}) do
        local entry = entries[index]
        if query == "" or string.find(self:BuildCollectionFilterIndex(collectionKey, entry), query, 1, true) ~= nil then
            filtered[#filtered + 1] = {
                entry = entry,
                entryIndex = index,
            }
        end
    end

    return filtered, query
end

function DataEditor:BuildDataPageFilterBar(parent, name, collectionKey, config)
    config = type(config) == "table" and config or {}
    local bar = UI.CreateLayout(UI.HorizontalLayoutGroup, parent, name, {
        spacing = 4,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
        height = 20,
    })

    local input = UI.CreateTextInput(bar:GetFrame(), name .. "Input", {
        width = config.inputWidth or 88,
        height = 20,
        text = self:GetCollectionFilterText(collectionKey),
    })
    input:SetScript("OnTextChanged", function(_, text)
        self:SetCollectionFilterText(collectionKey, text)
        self:RefreshContentPageByKey(collectionKey)
    end)
    input:SetScript("OnEscapePressed", function()
        self:SetCollectionFilterText(collectionKey, "")
        input:SetText("")
        self:RefreshContentPageByKey(collectionKey)
    end)
    if input.GetEditBox and input:GetEditBox() and config.placeholder and input:GetEditBox().SetTextInsets then
        input:GetEditBox():SetTextInsets(6, 6, 0, 0)
    end
    bar:AddChild(input)

    local dropdown = nil
    if type(config.dropdownItems) == "table" and #config.dropdownItems > 0 then
        dropdown = UI.CreateDropdown(bar:GetFrame(), name .. "Dropdown", {
            width = config.dropdownWidth or 72,
            height = 20,
            popupWidth = config.dropdownPopupWidth or config.dropdownWidth or 72,
            visibleRows = config.dropdownVisibleRows or 8,
            placeholder = config.dropdownPlaceholder or "Filter",
            items = config.dropdownItems,
            selectedValue = self:GetCollectionDropdownFilterValue(collectionKey),
            onValueChanged = function(value)
                self:SetCollectionDropdownFilterValue(collectionKey, value)
                self:RefreshContentPageByKey(collectionKey)
            end,
        })
        bar:AddChild(dropdown)
    end

    local clearButton = UI.CreateButton(bar:GetFrame(), name .. "ClearButton", "Clear", 36, function()
        self:SetCollectionFilterText(collectionKey, "")
        self:SetCollectionDropdownFilterValue(collectionKey, "all")
        if input.SetText then
            input:SetText("")
        end
        if dropdown and dropdown.SetSelectedValue then
            dropdown:SetSelectedValue("all", true)
        end
        self:RefreshContentPageByKey(collectionKey)
    end, {
        height = 20,
        fontSize = 7,
    })
    bar:AddChild(clearButton)

    return bar, input, dropdown, clearButton
end

function DataEditor:GetSelectedDatasetEntry(collectionKey)
    local dataset = self:GetSelectedDataset()
    local entries = dataset and dataset[collectionKey] or nil
    local selectedEntries = self.SelectedEntryIndices or {}
    local index = tonumber(selectedEntries[collectionKey])
    if not entries or not index or not entries[index] then
        return nil, nil
    end

    return entries[index], index
end

function DataEditor:SetSelectedDatasetEntryIndex(collectionKey, index)
    self.SelectedEntryIndices = self.SelectedEntryIndices or {}
    if collectionKey == "auras" then
        self.SelectedAuraEffectIndex = nil
        self.SelectedAuraScalingIndex = nil
    end
    local dataset = self:GetSelectedDataset()
    local entries = dataset and dataset[collectionKey] or nil
    index = tonumber(index)
    local inspectorPageKey = self:GetInspectorPageKeyForCollection(collectionKey)

    if not entries or not index or not entries[index] then
        self.SelectedEntryIndices[collectionKey] = nil
        if inspectorPageKey then
            self.ActiveInspectorPageKey = "dataset"
        end
        if collectionKey == "units" then
            self.SelectedUnitIndex = nil
        end
    else
        self.SelectedEntryIndices[collectionKey] = index
        if inspectorPageKey then
            self.ActiveInspectorPageKey = inspectorPageKey
        end
        if collectionKey == "units" then
            self.SelectedUnitIndex = index
        end
    end

    self:RefreshVisibleSelectionState({
        contentPageKey = collectionKey,
    })
end

function DataEditor:CreateDatasetEntry(collectionKey)
    local dataset = self:GetSelectedDataset()
    if not dataset or not (self.Database and self.Database.CreateDatasetEntry) then
        return nil
    end

    local entry = self.Database.CreateDatasetEntry(dataset.id, collectionKey)
    local entries = dataset and dataset[collectionKey] or nil
    if entries and entry then
        self.SelectedEntryIndices = self.SelectedEntryIndices or {}
        self.SelectedEntryIndices[collectionKey] = #entries
        if collectionKey == "units" then
            self.SelectedUnitIndex = #entries
            self.ActiveInspectorPageKey = "unit"
        elseif collectionKey == "mounts" then
            self.ActiveInspectorPageKey = "mount"
        elseif collectionKey == "pets" then
            self.ActiveInspectorPageKey = "pet"
        elseif collectionKey == "items" then
            self.ActiveInspectorPageKey = "item"
        elseif collectionKey == "spells" then
            self.ActiveInspectorPageKey = "spell"
        elseif collectionKey == "traits" then
            self.ActiveInspectorPageKey = "trait"
        elseif collectionKey == "skills" then
            self.ActiveInspectorPageKey = "skill"
        elseif collectionKey == "recipes" then
            self.ActiveInspectorPageKey = "recipe"
        elseif collectionKey == "auras" then
            self.ActiveInspectorPageKey = "aura"
        elseif collectionKey == "itemSlots" then
            self.ActiveInspectorPageKey = "itemSlot"
        elseif collectionKey == "weaponTypes" then
            self.ActiveInspectorPageKey = "weaponType"
        elseif collectionKey == "damageSchools" then
            self.ActiveInspectorPageKey = "damageSchool"
        elseif collectionKey == "stats" then
            self.ActiveInspectorPageKey = "stat"
        elseif collectionKey == "resources" then
            self.ActiveInspectorPageKey = "resource"
        elseif collectionKey == "achievements" then
            self.ActiveInspectorPageKey = "achievement"
        elseif collectionKey == "currencies" then
            self.ActiveInspectorPageKey = "currency"
        elseif collectionKey == "races" then
            self.ActiveInspectorPageKey = "race"
        elseif collectionKey == "classes" then
            self.ActiveInspectorPageKey = "class"
        end
    end
    self:RefreshAll()
    return entry
end

function DataEditor:CloneSelectedDatasetEntry(collectionKey)
    local dataset = self:GetSelectedDataset()
    local _, entryIndex = self:GetSelectedDatasetEntry(collectionKey)
    if not dataset or not entryIndex or not (self.Database and self.Database.CloneDatasetEntry) then
        return nil
    end

    local entry, newIndex = self.Database.CloneDatasetEntry(dataset.id, collectionKey, entryIndex)
    if entry and newIndex then
        self.SelectedEntryIndices = self.SelectedEntryIndices or {}
        self.SelectedEntryIndices[collectionKey] = newIndex
        if collectionKey == "units" then
            self.SelectedUnitIndex = newIndex
            self.ActiveInspectorPageKey = "unit"
        elseif collectionKey == "mounts" then
            self.ActiveInspectorPageKey = "mount"
        elseif collectionKey == "pets" then
            self.ActiveInspectorPageKey = "pet"
        elseif collectionKey == "items" then
            self.ActiveInspectorPageKey = "item"
        elseif collectionKey == "spells" then
            self.ActiveInspectorPageKey = "spell"
        elseif collectionKey == "traits" then
            self.ActiveInspectorPageKey = "trait"
        elseif collectionKey == "skills" then
            self.ActiveInspectorPageKey = "skill"
        elseif collectionKey == "recipes" then
            self.ActiveInspectorPageKey = "recipe"
        elseif collectionKey == "auras" then
            self.ActiveInspectorPageKey = "aura"
        elseif collectionKey == "itemSlots" then
            self.ActiveInspectorPageKey = "itemSlot"
        elseif collectionKey == "weaponTypes" then
            self.ActiveInspectorPageKey = "weaponType"
        elseif collectionKey == "damageSchools" then
            self.ActiveInspectorPageKey = "damageSchool"
        elseif collectionKey == "stats" then
            self.ActiveInspectorPageKey = "stat"
        elseif collectionKey == "resources" then
            self.ActiveInspectorPageKey = "resource"
        elseif collectionKey == "achievements" then
            self.ActiveInspectorPageKey = "achievement"
        elseif collectionKey == "currencies" then
            self.ActiveInspectorPageKey = "currency"
        elseif collectionKey == "races" then
            self.ActiveInspectorPageKey = "race"
        elseif collectionKey == "classes" then
            self.ActiveInspectorPageKey = "class"
        end
    end
    self:RefreshAll()
    return entry
end

function DataEditor:DeleteSelectedDatasetEntry(collectionKey)
    local dataset = self:GetSelectedDataset()
    local _, entryIndex = self:GetSelectedDatasetEntry(collectionKey)
    if not dataset or not entryIndex or not (self.Database and self.Database.DeleteDatasetEntry) then
        return false
    end

    local deleted = self.Database.DeleteDatasetEntry(dataset.id, collectionKey, entryIndex)
    if deleted then
        local entries = dataset and dataset[collectionKey] or {}
        local nextIndex = nil
        if #entries > 0 then
            nextIndex = math.min(entryIndex, #entries)
        end

        self.SelectedEntryIndices = self.SelectedEntryIndices or {}
        self.SelectedEntryIndices[collectionKey] = nextIndex
        if collectionKey == "units" then
            self.SelectedUnitIndex = nextIndex
            self.ActiveInspectorPageKey = nextIndex and "unit" or "dataset"
        elseif collectionKey == "mounts" then
            self.ActiveInspectorPageKey = nextIndex and "mount" or "dataset"
        elseif collectionKey == "pets" then
            self.ActiveInspectorPageKey = nextIndex and "pet" or "dataset"
        elseif collectionKey == "items" then
            self.ActiveInspectorPageKey = nextIndex and "item" or "dataset"
        elseif collectionKey == "spells" then
            self.ActiveInspectorPageKey = nextIndex and "spell" or "dataset"
        elseif collectionKey == "traits" then
            self.ActiveInspectorPageKey = nextIndex and "trait" or "dataset"
        elseif collectionKey == "skills" then
            self.ActiveInspectorPageKey = nextIndex and "skill" or "dataset"
        elseif collectionKey == "recipes" then
            self.ActiveInspectorPageKey = nextIndex and "recipe" or "dataset"
        elseif collectionKey == "auras" then
            self.ActiveInspectorPageKey = nextIndex and "aura" or "dataset"
        elseif collectionKey == "itemSlots" then
            self.ActiveInspectorPageKey = nextIndex and "itemSlot" or "dataset"
        elseif collectionKey == "weaponTypes" then
            self.ActiveInspectorPageKey = nextIndex and "weaponType" or "dataset"
        elseif collectionKey == "damageSchools" then
            self.ActiveInspectorPageKey = nextIndex and "damageSchool" or "dataset"
        elseif collectionKey == "stats" then
            self.ActiveInspectorPageKey = nextIndex and "stat" or "dataset"
        elseif collectionKey == "resources" then
            self.ActiveInspectorPageKey = nextIndex and "resource" or "dataset"
        elseif collectionKey == "achievements" then
            self.ActiveInspectorPageKey = nextIndex and "achievement" or "dataset"
        elseif collectionKey == "currencies" then
            self.ActiveInspectorPageKey = nextIndex and "currency" or "dataset"
        elseif collectionKey == "races" then
            self.ActiveInspectorPageKey = nextIndex and "race" or "dataset"
        elseif collectionKey == "classes" then
            self.ActiveInspectorPageKey = nextIndex and "class" or "dataset"
        end
    end
    self:RefreshAll()
    return deleted
end

function DataEditor:BuildDataPageToolbar(parent, name, collectionKey)
    local definition = self:GetEntryDefinition(collectionKey) or {}
    local toolbar = UI.CreateLayout(UI.HorizontalLayoutGroup, parent, name, {
        spacing = 2,
        autoSize = true,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })

    local buttons = {}

    buttons.add = UI.CreateButton(toolbar:GetFrame(), name .. "AddButton", "Add", 38, function()
        self:CreateDatasetEntry(collectionKey)
    end, {
        height = 20,
        fontSize = 7,
    })
    toolbar:AddChild(buttons.add)

    buttons.clone = UI.CreateButton(toolbar:GetFrame(), name .. "CloneButton", "Clone", 38, function()
        self:CloneSelectedDatasetEntry(collectionKey)
    end, {
        height = 20,
        fontSize = 7,
    })
    toolbar:AddChild(buttons.clone)

    buttons.import = UI.CreateButton(toolbar:GetFrame(), name .. "ImportButton", "Import", 38, function()
        self:ShowDatasetEntryImportWindow(collectionKey)
    end, {
        height = 20,
        fontSize = 7,
    })
    toolbar:AddChild(buttons.import)

    buttons.export = UI.CreateButton(toolbar:GetFrame(), name .. "ExportButton", "Export", 38, function()
        self:ExportSelectedDatasetEntryToClipboard(collectionKey)
    end, {
        height = 20,
        fontSize = 7,
    })
    toolbar:AddChild(buttons.export)

    buttons.delete = UI.CreateButton(toolbar:GetFrame(), name .. "DeleteButton", "Delete", 38, function()
        self:DeleteSelectedDatasetEntry(collectionKey)
    end, {
        height = 20,
        fontSize = 7,
    })
    toolbar:AddChild(buttons.delete)

    buttons.definition = definition
    buttons.collectionKey = collectionKey
    return toolbar, buttons
end

function DataEditor:RefreshDataPageToolbar(buttons)
    local hasDataset = self:GetSelectedDataset() ~= nil
    local collectionKey = buttons and buttons.collectionKey or nil
    local hasSelection = collectionKey and self:GetSelectedDatasetEntry(collectionKey) ~= nil or false

    if buttons and buttons.add and buttons.add.SetEnabled then
        buttons.add:SetEnabled(hasDataset)
    end

    if buttons and buttons.clone and buttons.clone.SetEnabled then
        buttons.clone:SetEnabled(hasSelection)
    end

    if buttons and buttons.import and buttons.import.SetEnabled then
        buttons.import:SetEnabled(hasDataset)
    end

    if buttons and buttons.export and buttons.export.SetEnabled then
        buttons.export:SetEnabled(hasSelection)
    end

    if buttons and buttons.delete and buttons.delete.SetEnabled then
        buttons.delete:SetEnabled(hasSelection)
    end
end

local CONTENT_PAGE_DEFINITIONS = {
    { key = "units", label = "Units", builder = "BuildUnitsPage" },
    { key = "mounts", label = "Mounts", builder = "BuildMountsPage" },
    { key = "pets", label = "Pets", builder = "BuildPetsPage" },
    { key = "items", label = "Items", builder = "BuildItemsPage" },
    { key = "spells", label = "Spells", builder = "BuildSpellsPage" },
    { key = "traits", label = "Traits", builder = "BuildTraitsPage" },
    { key = "skills", label = "Skills", builder = "BuildSkillsPage" },
    { key = "stats", label = "Stats", builder = "BuildStatsPage" },
    { key = "resources", label = "Resources", builder = "BuildResourcesPage" },
    { key = "races", label = "Races", builder = "BuildRacesPage" },
    { key = "classes", label = "Classes", builder = "BuildClassesPage" },
    { key = "itemSlots", label = "Item Slots", builder = "BuildItemSlotsPage" },
    { key = "weaponTypes", label = "Weapon Types", builder = "BuildWeaponTypesPage" },
    { key = "damageSchools", label = "Damage Schools", builder = "BuildDamageSchoolsPage" },
    { key = "loot", label = "Loot", builder = "BuildLootPage" },
    { key = "recipes", label = "Recipe", builder = "BuildRecipePage" },
    { key = "auras", label = "Aura", builder = "BuildAuraPage" },
    { key = "interactions", label = "Interaction", builder = "BuildInteractionPage" },
    { key = "achievements", label = "Achievement", builder = "BuildAchievementPage" },
    { key = "currencies", label = "Currency", builder = "BuildCurrencyPage" },
}

function DataEditor:GetContentPageDefinitions()
    return CONTENT_PAGE_DEFINITIONS
end

function DataEditor:GetContentPageIndexByKey(key)
    local pages = self:GetContentPageDefinitions()
    for index = 1, #pages do
        if pages[index].key == key then
            return index
        end
    end

    return 1
end

function DataEditor:BuildContentPageSelectorItems()
    local items = {}
    local pages = self:GetContentPageDefinitions()

    for index = 1, #pages do
        items[#items + 1] = {
            label = pages[index].label,
            value = pages[index].key,
        }
    end

    return items
end

function DataEditor:EnsureContentPageBuilt(index)
    if not self.ContentPageHost then
        return nil
    end

    self.ContentPageFrames = self.ContentPageFrames or {}
    local page = self.ContentPageFrames[index]
    if page then
        return page
    end

    local definition = self:GetContentPageDefinitions()[index]
    if not definition then
        return nil
    end

    page = CreateFrame("Frame", "RPEDataEditorContentPage" .. index, self.ContentPageHost)
    UI.Utils.AnchorFill(page, self.ContentPageHost, 0, 0, 0, 0)
    self.ContentPageFrames[index] = page

    local builder = definition.builder and self[definition.builder] or nil
    if builder then
        builder(self, page)
    end

    return page
end

function DataEditor:RefreshContentPageSelector()
    local pages = self:GetContentPageDefinitions()
    local pageCount = #pages
    local activeIndex = math.max(1, math.min(self.ActiveContentPageIndex or 1, pageCount))
    self.ActiveContentPageIndex = activeIndex

    local activeDefinition = pages[activeIndex]
    if self.ContentPageDropdown and activeDefinition then
        self._refreshingContentPageSelector = true
        self.ContentPageDropdown:SetSelectedValue(activeDefinition.key, true)
        self._refreshingContentPageSelector = false
    end

    if self.ContentPreviousButton and self.ContentPreviousButton.SetEnabled then
        self.ContentPreviousButton:SetEnabled(activeIndex > 1)
    end

    if self.ContentNextButton and self.ContentNextButton.SetEnabled then
        self.ContentNextButton:SetEnabled(activeIndex < pageCount)
    end
end

function DataEditor:GetActiveContentPageKey()
    local pages = self:GetContentPageDefinitions()
    if #pages == 0 then
        return nil
    end

    local activeIndex = math.max(1, math.min(self.ActiveContentPageIndex or 1, #pages))
    local definition = pages[activeIndex]
    return definition and definition.key or nil
end

function DataEditor:RefreshContentPageByKey(pageKey)
    local refresherName = DATA_PAGE_REFRESHER_BY_COLLECTION[pageKey]
    if refresherName and self[refresherName] then
        self[refresherName](self)
    end
end

function DataEditor:RefreshInspectorPageByKey(pageKey)
    local refresherName = INSPECTOR_REFRESHER_BY_PAGE[pageKey]
    if refresherName and self[refresherName] then
        self[refresherName](self)
    end
end

function DataEditor:RefreshActiveInspectorPage()
    local activeInspectorPageKey = self:NormalizeActiveInspectorPageKey()
    self:ShowInspectorPage(activeInspectorPageKey)
    self:RefreshInspectorPageByKey(activeInspectorPageKey)
    return activeInspectorPageKey
end

function DataEditor:RefreshVisibleSelectionState(options)
    options = type(options) == "table" and options or {}
    self:GetSelectedDataset()

    if options.refreshDatasetsPane == true and self.RefreshDatasetsPane then
        self:RefreshDatasetsPane()
    end

    if options.refreshContentSelector == true then
        self:RefreshContentPageSelector()
    end

    local contentPageKey = options.contentPageKey
    if contentPageKey == nil and options.refreshActiveContentPage == true then
        contentPageKey = self:GetActiveContentPageKey()
    end
    if contentPageKey then
        self:RefreshContentPageByKey(contentPageKey)
    end

    if options.refreshInspectorPage ~= false then
        self:RefreshActiveInspectorPage()
    end
end

function DataEditor:NormalizeActiveInspectorPageKey()
    local activePageKey = self.ActiveInspectorPageKey or "dataset"
    local getterName = INSPECTOR_SELECTION_GETTER_BY_PAGE[activePageKey]

    if getterName and self[getterName] and not self[getterName](self) then
        activePageKey = "dataset"
    end

    self.ActiveInspectorPageKey = activePageKey
    return activePageKey
end

function DataEditor:RefreshAfterDatasetEntryChanged(collectionKey)
    return collectionKey
end

function DataEditor:SetActiveContentPage(index)
    local pages = self:GetContentPageDefinitions()
    if #pages == 0 then
        self.ActiveContentPageIndex = 0
        return 0
    end

    local clamped = math.max(1, math.min(index or 1, #pages))
    self.ActiveContentPageIndex = clamped
    self:EnsureContentPageBuilt(clamped)

    for pageIndex = 1, #pages do
        local page = self.ContentPageFrames and self.ContentPageFrames[pageIndex] or nil
        if page then
            if pageIndex == clamped then
                page:Show()
            else
                page:Hide()
            end
        end
    end

    self:RefreshContentPageSelector()
    local activeDefinition = pages[clamped]
    if activeDefinition then
        self:RefreshContentPageByKey(activeDefinition.key)
    end
    return clamped
end

function DataEditor:BuildContentSelectorBar(parent)
    local bar = UI.CreateLayout(UI.HorizontalLayoutGroup, parent, "RPEDataEditorContentSelectorBar", {
        spacing = 4,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
        height = 20,
    })

    self.ContentPreviousButton = UI.CreateButton(bar:GetFrame(), "RPEDataEditorContentPreviousButton", "Prev", 40, function()
        self:SetActiveContentPage((self.ActiveContentPageIndex or 1) - 1)
    end, {
        height = 20,
        fontSize = 7,
    })
    bar:AddChild(self.ContentPreviousButton)

    self.ContentPageDropdown = UI.CreateDropdown(bar:GetFrame(), "RPEDataEditorContentPageDropdown", {
        width = 118,
        height = 18,
        expandWidth = true,
        weight = 1,
        items = self:BuildContentPageSelectorItems(),
        onValueChanged = function(value)
            if self._refreshingContentPageSelector then
                return
            end

            self:SetActiveContentPage(self:GetContentPageIndexByKey(value))
        end,
    })
    bar:AddChild(self.ContentPageDropdown)

    self.ContentNextButton = UI.CreateButton(bar:GetFrame(), "RPEDataEditorContentNextButton", "Next", 40, function()
        self:SetActiveContentPage((self.ActiveContentPageIndex or 1) + 1)
    end, {
        height = 20,
        fontSize = 7,
    })
    bar:AddChild(self.ContentNextButton)

    return bar
end

function DataEditor:GetDatasets()
    if self.Database and self.Database.ListDatasets then
        return self.Database.ListDatasets()
    end

    return {}
end

function DataEditor:GetDatasetDisplayName(dataset)
    if self.Database and self.Database.GetDatasetDisplayName then
        return self.Database.GetDatasetDisplayName(dataset)
    end

    local name = dataset and dataset.name or nil
    if name == nil or name == "" then
        return "Unnamed Dataset"
    end

    return tostring(name)
end

function DataEditor:DeepCopyValue(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}
    for key, nestedValue in pairs(value) do
        copy[key] = self:DeepCopyValue(nestedValue)
    end

    return copy
end

function DataEditor:DeepEqualValues(left, right)
    local leftType = type(left)
    local rightType = type(right)
    if leftType ~= rightType then
        return false
    end

    if leftType ~= "table" then
        return left == right
    end

    for key, leftValue in pairs(left) do
        if not self:DeepEqualValues(leftValue, right[key]) then
            return false
        end
    end

    for key in pairs(right) do
        if left[key] == nil then
            return false
        end
    end

    return true
end

function DataEditor:IsWindowVisible()
    local frame = self.Window and self.Window.GetFrame and self.Window:GetFrame() or nil
    return frame and frame.IsShown and frame:IsShown() or false
end

function DataEditor:ShouldDeferConfigurationRefresh()
    return self:IsWindowVisible()
end

function DataEditor:MarkConfigurationDirty(reason)
    self.HasDeferredConfigurationChanges = true
    self.DeferredConfigurationRefreshReason = reason or self.DeferredConfigurationRefreshReason or "configuration-changed"
    self:UpdateRefreshButtonState()
    return true
end

function DataEditor:ApplyDeferredConfigurationPreview(reason, datasetIds)
    local normalizedReason = reason or self.DeferredConfigurationRefreshReason or "configuration-changed"
    local dependencies = self.Database and self.Database.Dependecies or nil
    local recomputed = {}

    for index = 1, #(datasetIds or {}) do
        local datasetId = tostring(datasetIds[index] or "")
        if datasetId ~= ""
            and recomputed[datasetId] ~= true
            and type(dependencies) == "table"
            and type(dependencies.RecomputeDatasetDependencies) == "function"
        then
            recomputed[datasetId] = true
            dependencies.RecomputeDatasetDependencies(datasetId)
        end
    end

    Addon.Internal = Addon.Internal or {}
    Addon.Internal.ConfigurationRevision = math.max(0, math.floor(tonumber(Addon.Internal.ConfigurationRevision) or 0)) + 1

    local client = Addon.Client or nil
    if client and type(client.HandleLocalConfigurationChanged) == "function" then
        client:HandleLocalConfigurationChanged(normalizedReason)
    end

    self:RefreshAll()
    self:UpdateRefreshButtonState()
    return true
end

function DataEditor:QueuePendingDatasetEntryChanged(datasetId, collectionKey, options)
    if datasetId == nil or collectionKey == nil or collectionKey == "" then
        return false
    end

    self.PendingDatasetEntryNotifications = self.PendingDatasetEntryNotifications or {}
    local datasetKey = tostring(datasetId)
    local entry = self.PendingDatasetEntryNotifications[datasetKey]
    if type(entry) ~= "table" then
        entry = {
            collectionKeys = {},
            requiresDependencyRecompute = false,
        }
        self.PendingDatasetEntryNotifications[datasetKey] = entry
    end

    entry.collectionKeys[collectionKey] = true
    if collectionQueuesDependencyRecompute(collectionKey) then
        entry.requiresDependencyRecompute = true
    end

    local delta = math.max(1, math.floor(tonumber(options and options.changeCount) or 1))
    self.PendingChangeCount = math.max(0, math.floor(tonumber(self.PendingChangeCount) or 0)) + delta
    return self:MarkConfigurationDirty(options and options.reason or "dataset-entry")
end

function DataEditor:CommitPendingChanges()
    local pendingChangeCount = math.max(0, math.floor(tonumber(self.PendingChangeCount) or 0))
    if pendingChangeCount <= 0 then
        self:UpdateRefreshButtonState()
        return false
    end

    local reason = self.DeferredConfigurationRefreshReason or "configuration-changed"
    local notifications = self.PendingDatasetEntryNotifications or {}
    local dependencies = self.Database and self.Database.Dependecies or nil

    for datasetId, notification in pairs(notifications) do
        if type(notification) == "table"
            and notification.requiresDependencyRecompute == true
            and type(dependencies) == "table"
            and type(dependencies.RecomputeDatasetDependencies) == "function"
        then
            dependencies.RecomputeDatasetDependencies(datasetId)
        end
    end

    local nextRevision = math.max(0, math.floor(tonumber(Addon.Internal and Addon.Internal.ConfigurationRevision) or 0)) + 1
    local crafting = Addon.Client and Addon.Client.Crafting or nil
    if crafting and type(crafting.RebuildRecipeSkillIndex) == "function" then
        crafting:RebuildRecipeSkillIndex(nextRevision)
    end

    Addon.Internal = Addon.Internal or {}
    Addon.Internal.ConfigurationRevision = math.max(0, math.floor(tonumber(Addon.Internal.ConfigurationRevision) or 0)) + 1

    self.HasDeferredConfigurationChanges = false
    self.DeferredConfigurationRefreshReason = nil
    self.PendingDatasetEntryNotifications = {}
    self.PendingChangeCount = 0
    self:UpdateRefreshButtonState()

    local client = Addon.Client or nil
    if client and type(client.HandleLocalConfigurationChanged) == "function" then
        client:HandleLocalConfigurationChanged(reason)
    end

    self:RefreshAll()
    return true
end

function DataEditor:UpdateRefreshButtonState()
    local button = self.RefreshHeaderButton
    local statusText = self.RefreshHeaderStatusText
    local pendingChangeCount = math.max(0, math.floor(tonumber(self.PendingChangeCount) or 0))

    if button and button.SetText then
        button:SetText("Commit Changes")
    end
    if button and button.SetEnabled then
        button:SetEnabled(pendingChangeCount > 0)
    end

    if statusText and statusText.SetText then
        if pendingChangeCount == 1 then
            statusText:SetText("1 pending change")
        else
            statusText:SetText(("%d pending changes"):format(pendingChangeCount))
        end
    end

    if not button and not statusText then
        return
    end
end

function DataEditor:BuildRefreshHeaderButton()
    if self.RefreshHeaderButton or not self.Window or not self.Window.headerFrame then
        return self.RefreshHeaderButton
    end

    self.RefreshHeaderButton = UI.CreateButton(self.Window.headerFrame, "RPEDataEditorRefreshHeaderButton", "Commit Changes", 88, function()
        self:CommitPendingChanges()
    end, {
        height = 14,
        fontSize = 7,
    })
    self.RefreshHeaderStatusText = UI.CreateText(self.Window.headerFrame, "RPEDataEditorRefreshHeaderStatusText", "0 pending changes", {
        width = 120,
        height = 14,
        fontSize = 8,
        justifyH = "RIGHT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.RefreshHeaderStatusText:SetParent(self.Window.headerFrame)
    self.RefreshHeaderStatusText:Create()

    local buttonFrame = self.RefreshHeaderButton.GetFrame and self.RefreshHeaderButton:GetFrame() or nil
    local statusFrame = self.RefreshHeaderStatusText and self.RefreshHeaderStatusText.GetFrame and self.RefreshHeaderStatusText:GetFrame() or nil
    local closeFrame = self.Window.closeButton and self.Window.closeButton.GetFrame and self.Window.closeButton:GetFrame() or nil
    if buttonFrame then
        buttonFrame:ClearAllPoints()
        if closeFrame then
            buttonFrame:SetPoint("RIGHT", closeFrame, "LEFT", -6, 0)
        else
            buttonFrame:SetPoint("RIGHT", self.Window.headerFrame, "RIGHT", -24, 0)
        end
        buttonFrame:SetPoint("TOP", self.Window.headerFrame, "TOP", 0, -1)
        buttonFrame:SetPoint("BOTTOM", self.Window.headerFrame, "BOTTOM", 0, 1)
    end

    if statusFrame and buttonFrame then
        statusFrame:ClearAllPoints()
        statusFrame:SetPoint("RIGHT", buttonFrame, "LEFT", -6, 0)
        statusFrame:SetPoint("TOP", self.Window.headerFrame, "TOP", 0, -1)
        statusFrame:SetPoint("BOTTOM", self.Window.headerFrame, "BOTTOM", 0, 1)
    end

    if self.Window.titleRegion and buttonFrame then
        self.Window.titleRegion:ClearAllPoints()
        self.Window.titleRegion:SetPoint("LEFT", self.Window.headerFrame, "LEFT", 8, 0)
        if statusFrame then
            self.Window.titleRegion:SetPoint("RIGHT", statusFrame, "LEFT", -6, 0)
        else
            self.Window.titleRegion:SetPoint("RIGHT", buttonFrame, "LEFT", -6, 0)
        end
    end

    self:UpdateRefreshButtonState()
    return self.RefreshHeaderButton
end

function DataEditor:GetSelectedDataset()
    if self.SelectedDatasetId and self.Database and self.Database.GetDatasetByID then
        local selected = self.Database.GetDatasetByID(self.SelectedDatasetId)
        if selected then
            return selected
        end
    end

    local active = self.Database and self.Database.GetActiveDataset and self.Database.GetActiveDataset() or nil
    if active then
        self.SelectedDatasetId = active.id
        return active
    end

    local datasets = self:GetDatasets()
    local firstDataset = datasets[1]
    if firstDataset then
        self.SelectedDatasetId = firstDataset.id
        if self.Database and self.Database.SetActiveDatasetId then
            self.Database.SetActiveDatasetId(firstDataset.id)
        end
    end

    return firstDataset
end

function DataEditor:GetSelectedUnit()
    return self:GetSelectedDatasetEntry("units")
end

function DataEditor:GetSelectedMount()
    return self:GetSelectedDatasetEntry("mounts")
end

function DataEditor:GetSelectedPet()
    return self:GetSelectedDatasetEntry("pets")
end

function DataEditor:GetSelectedStat()
    return self:GetSelectedDatasetEntry("stats")
end

function DataEditor:GetSelectedItem()
    return self:GetSelectedDatasetEntry("items")
end

function DataEditor:GetSelectedSpell()
    return self:GetSelectedDatasetEntry("spells")
end

function DataEditor:GetSelectedTrait()
    return self:GetSelectedDatasetEntry("traits")
end

function DataEditor:GetSelectedAura()
    return self:GetSelectedDatasetEntry("auras")
end

function DataEditor:GetSelectedResource()
    return self:GetSelectedDatasetEntry("resources")
end

function DataEditor:GetSelectedAchievement()
    return self:GetSelectedDatasetEntry("achievements")
end

function DataEditor:GetSelectedCurrency()
    return self:GetSelectedDatasetEntry("currencies")
end

function DataEditor:GetSelectedRace()
    return self:GetSelectedDatasetEntry("races")
end

function DataEditor:GetSelectedClass()
    return self:GetSelectedDatasetEntry("classes")
end

function DataEditor:GetSelectedItemSlot()
    return self:GetSelectedDatasetEntry("itemSlots")
end

function DataEditor:GetSelectedDamageSchool()
    return self:GetSelectedDatasetEntry("damageSchools")
end

function DataEditor:GetSelectedWeaponType()
    return self:GetSelectedDatasetEntry("weaponTypes")
end

function DataEditor:GetSelectedSkill()
    return self:GetSelectedDatasetEntry("skills")
end

function DataEditor:SetSelectedDatasetId(datasetId)
    self.SelectedDatasetId = datasetId
    self.SelectedUnitIndex = nil
    self.SelectedEntryIndices = {}
    self.SelectedAuraEffectIndex = nil
    self.SelectedAuraScalingIndex = nil
    self.ActiveInspectorPageKey = "dataset"
    if self.Database and self.Database.SetActiveDatasetId then
        self.Database.SetActiveDatasetId(datasetId)
    end

    self:RefreshVisibleSelectionState({
        refreshDatasetsPane = true,
        refreshActiveContentPage = true,
    })
end

function DataEditor:SetSelectedUnitIndex(index)
    self:SetSelectedDatasetEntryIndex("units", index)
end

function DataEditor:CreateDatasetAndSelect()
    if not (self.Database and self.Database.CreateDataset) then
        return nil
    end

    local dataset = self.Database.CreateDataset("New Dataset")
    if dataset then
        self:SetSelectedDatasetId(dataset.id)
    end

    return dataset
end

function DataEditor:ExportDatasetToClipboard(datasetId)
    if not (self.Database and self.Database.ExportDataset) then
        return nil
    end

    local targetDatasetId = datasetId or self.SelectedDatasetId
    if not targetDatasetId then
        return nil
    end

    local exportText = self.Database.ExportDataset(targetDatasetId)
    if not exportText then
        return nil
    end

    local clipboard = getClipboard()
    if clipboard and clipboard.Show then
        clipboard:Show(exportText)
    end

    return exportText
end

function DataEditor:ExportSelectedDatasetEntryToClipboard(collectionKey)
    if not (self.Database and self.Database.ExportDatasetEntry) then
        return nil
    end

    local dataset = self:GetSelectedDataset()
    local entry, entryIndex = self:GetSelectedDatasetEntry(collectionKey)
    if not dataset or not entry or not entryIndex then
        return nil
    end

    local exportText = self.Database.ExportDatasetEntry(dataset.id, collectionKey, entryIndex)
    if not exportText then
        return nil
    end

    local clipboard = getClipboard()
    if clipboard and clipboard.Show then
        clipboard:Show(exportText)
    end

    return exportText
end

function DataEditor:ImportDatasetFromText(text)
    if not (self.Database and self.Database.ImportDataset) then
        return nil, "Dataset import is unavailable."
    end

    local dataset, err = self.Database.ImportDataset(text)
    if not dataset then
        return nil, err or "Dataset import failed."
    end

    self:SetSelectedDatasetId(dataset.id)
    return dataset
end

function DataEditor:ImportDatasetEntryFromText(collectionKey, text)
    if not (self.Database and self.Database.ImportDatasetEntry) then
        return nil, "Dataset entry import is unavailable."
    end

    local dataset = self:GetSelectedDataset()
    if not dataset or not dataset.id then
        return nil, "Select a dataset before importing."
    end

    local entry, entryIndexOrError = self.Database.ImportDatasetEntry(dataset.id, collectionKey, text)
    if not entry then
        return nil, entryIndexOrError or "Dataset entry import failed."
    end

    self:SetSelectedDatasetEntryIndex(collectionKey, entryIndexOrError)
    return entry, entryIndexOrError
end

function DataEditor:BuildDatasetImportWindow()
    if self.DatasetImportWindow then
        return self.DatasetImportWindow
    end

    local window = UI.Window:New({
        name = "RPEDataEditorDatasetImportWindow",
        width = 540,
        height = 360,
        point = "CENTER",
        relativeTo = UIParent,
        relativePoint = "CENTER",
        frameStrata = "HIGH",
        frameLevel = 30,
        movable = true,
        clampedToScreen = true,
        toplevel = true,
        hidden = true,
        contentInsetLeft = 10,
        contentInsetRight = 10,
        contentInsetTop = 28,
        contentInsetBottom = 10,
    })
    window:SetTitle("Import Dataset")
    window:Create()
    self.DatasetImportWindow = window

    local root = UI.CreateLayout(UI.VerticalLayoutGroup, window:GetContentFrame(), "RPEDataEditorDatasetImportRoot", {
        spacing = 8,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })
    UI.Utils.AnchorFill(root, window:GetContentFrame(), 0, 0, 0, 0)

    self.DatasetImportInstructionText = UI.CreateText(root:GetFrame(), "RPEDataEditorDatasetImportInstructionText",
        "Paste a dataset export string below and click Import.", {
            width = 500,
            height = 14,
            justifyH = "LEFT",
            textColor = UI.ResolveColor(nil, "text.secondary"),
        }
    )
    root:AddChild(self.DatasetImportInstructionText)

    self.DatasetImportTextArea = UI.CreateTextArea(root:GetFrame(), "RPEDataEditorDatasetImportTextArea", {
        width = 500,
        height = 260,
        expandWidth = true,
        expandHeight = true,
        weight = 1,
        text = "",
        readOnly = false,
        borderColor = UI.ResolveColor(nil, "panel.border"),
        backgroundColor = UI.ResolveColor(nil, "window.background"),
        textColor = UI.ResolveColor(nil, "text.primary"),
    })
    root:AddChild(self.DatasetImportTextArea)

    self.DatasetImportStatusText = UI.CreateText(root:GetFrame(), "RPEDataEditorDatasetImportStatusText", "", {
        width = 500,
        height = 12,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    root:AddChild(self.DatasetImportStatusText)

    local actions = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEDataEditorDatasetImportActions", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
        height = 20,
    })
    root:AddChild(actions)

    self.DatasetImportConfirmButton = UI.CreateButton(actions:GetFrame(), "RPEDataEditorDatasetImportConfirmButton", "Import", 60, function()
        local importText = self.DatasetImportTextArea and self.DatasetImportTextArea.GetText and self.DatasetImportTextArea:GetText() or ""
        local dataset, err = self:ImportDatasetFromText(importText)
        if not dataset then
            if self.DatasetImportStatusText and self.DatasetImportStatusText.SetText then
                self.DatasetImportStatusText:SetText(tostring(err or "Import failed."))
            end
            return
        end

        if self.DatasetImportStatusText and self.DatasetImportStatusText.SetText then
            self.DatasetImportStatusText:SetText("")
        end
        if self.DatasetImportWindow and self.DatasetImportWindow.Hide then
            self.DatasetImportWindow:Hide()
        end
    end, {
        height = 20,
        fontSize = 7,
    })
    actions:AddChild(self.DatasetImportConfirmButton)

    self.DatasetImportCancelButton = UI.CreateButton(actions:GetFrame(), "RPEDataEditorDatasetImportCancelButton", "Cancel", 60, function()
        if self.DatasetImportWindow and self.DatasetImportWindow.Hide then
            self.DatasetImportWindow:Hide()
        end
    end, {
        height = 20,
        fontSize = 7,
    })
    actions:AddChild(self.DatasetImportCancelButton)

    return window
end

function DataEditor:ShowDatasetImportWindow()
    local window = self:BuildDatasetImportWindow()
    if self.DatasetImportTextArea and self.DatasetImportTextArea.SetText then
        self.DatasetImportTextArea:SetText("")
    end
    if self.DatasetImportStatusText and self.DatasetImportStatusText.SetText then
        self.DatasetImportStatusText:SetText("")
    end
    if window and window.Show then
        window:Show()
    end
    if self.DatasetImportTextArea and self.DatasetImportTextArea.Focus then
        self.DatasetImportTextArea:Focus()
    end
    return window
end

function DataEditor:BuildDatasetEntryImportWindow()
    if self.DatasetEntryImportWindow then
        return self.DatasetEntryImportWindow
    end

    local window = UI.Window:New({
        name = "RPEDataEditorDatasetEntryImportWindow",
        width = 540,
        height = 360,
        point = "CENTER",
        relativeTo = UIParent,
        relativePoint = "CENTER",
        frameStrata = "HIGH",
        frameLevel = 30,
        movable = true,
        clampedToScreen = true,
        toplevel = true,
        hidden = true,
        contentInsetLeft = 10,
        contentInsetRight = 10,
        contentInsetTop = 28,
        contentInsetBottom = 10,
    })
    window:SetTitle("Import Entry")
    window:Create()
    self.DatasetEntryImportWindow = window

    local root = UI.CreateLayout(UI.VerticalLayoutGroup, window:GetContentFrame(), "RPEDataEditorDatasetEntryImportRoot", {
        spacing = 8,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })
    UI.Utils.AnchorFill(root, window:GetContentFrame(), 0, 0, 0, 0)

    self.DatasetEntryImportInstructionText = UI.CreateText(root:GetFrame(), "RPEDataEditorDatasetEntryImportInstructionText",
        "Paste an entry export string below and click Import.", {
            width = 500,
            height = 14,
            justifyH = "LEFT",
            textColor = UI.ResolveColor(nil, "text.secondary"),
        }
    )
    root:AddChild(self.DatasetEntryImportInstructionText)

    self.DatasetEntryImportTextArea = UI.CreateTextArea(root:GetFrame(), "RPEDataEditorDatasetEntryImportTextArea", {
        width = 500,
        height = 260,
        expandWidth = true,
        expandHeight = true,
        weight = 1,
        text = "",
        readOnly = false,
        borderColor = UI.ResolveColor(nil, "panel.border"),
        backgroundColor = UI.ResolveColor(nil, "window.background"),
        textColor = UI.ResolveColor(nil, "text.primary"),
    })
    root:AddChild(self.DatasetEntryImportTextArea)

    self.DatasetEntryImportStatusText = UI.CreateText(root:GetFrame(), "RPEDataEditorDatasetEntryImportStatusText", "", {
        width = 500,
        height = 12,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    root:AddChild(self.DatasetEntryImportStatusText)

    local actions = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEDataEditorDatasetEntryImportActions", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
        height = 20,
    })
    root:AddChild(actions)

    self.DatasetEntryImportConfirmButton = UI.CreateButton(actions:GetFrame(), "RPEDataEditorDatasetEntryImportConfirmButton", "Import", 60, function()
        local collectionKey = self.CurrentDatasetEntryImportCollectionKey
        local importText = self.DatasetEntryImportTextArea and self.DatasetEntryImportTextArea.GetText and self.DatasetEntryImportTextArea:GetText() or ""
        local entry, err = self:ImportDatasetEntryFromText(collectionKey, importText)
        if not entry then
            if self.DatasetEntryImportStatusText and self.DatasetEntryImportStatusText.SetText then
                self.DatasetEntryImportStatusText:SetText(tostring(err or "Import failed."))
            end
            return
        end

        if self.DatasetEntryImportStatusText and self.DatasetEntryImportStatusText.SetText then
            self.DatasetEntryImportStatusText:SetText("")
        end
        if self.DatasetEntryImportWindow and self.DatasetEntryImportWindow.Hide then
            self.DatasetEntryImportWindow:Hide()
        end
    end, {
        height = 20,
        fontSize = 7,
    })
    actions:AddChild(self.DatasetEntryImportConfirmButton)

    self.DatasetEntryImportCancelButton = UI.CreateButton(actions:GetFrame(), "RPEDataEditorDatasetEntryImportCancelButton", "Cancel", 60, function()
        if self.DatasetEntryImportWindow and self.DatasetEntryImportWindow.Hide then
            self.DatasetEntryImportWindow:Hide()
        end
    end, {
        height = 20,
        fontSize = 7,
    })
    actions:AddChild(self.DatasetEntryImportCancelButton)

    return window
end

function DataEditor:ShowDatasetEntryImportWindow(collectionKey)
    local definition = self:GetEntryDefinition(collectionKey)
    if not definition then
        return nil
    end

    local window = self:BuildDatasetEntryImportWindow()
    self.CurrentDatasetEntryImportCollectionKey = collectionKey

    local singular = definition.singular or "Entry"
    if window and window.SetTitle then
        window:SetTitle(("Import %s"):format(singular))
    end
    if self.DatasetEntryImportInstructionText and self.DatasetEntryImportInstructionText.SetText then
        self.DatasetEntryImportInstructionText:SetText(("Paste a %s export string below and click Import."):format(string.lower(singular)))
    end
    if self.DatasetEntryImportTextArea and self.DatasetEntryImportTextArea.SetText then
        self.DatasetEntryImportTextArea:SetText("")
    end
    if self.DatasetEntryImportStatusText and self.DatasetEntryImportStatusText.SetText then
        self.DatasetEntryImportStatusText:SetText("")
    end
    if window and window.Show then
        window:Show()
    end
    if self.DatasetEntryImportTextArea and self.DatasetEntryImportTextArea.Focus then
        self.DatasetEntryImportTextArea:Focus()
    end

    return window
end

function DataEditor:IsDatasetActivated(datasetId)
    return self.Registry and self.Registry.IsDatasetActivated and self.Registry:IsDatasetActivated(datasetId) or false
end

function DataEditor:SetDatasetActivated(datasetId, isActivated)
    if not (self.Registry and datasetId) then
        return false
    end

    local changed = nil
    if isActivated then
        changed = self.Registry.ActivateDataset and self.Registry:ActivateDataset(datasetId) or false
    else
        changed = self.Registry.DeactivateDataset and self.Registry:DeactivateDataset(datasetId) or false
    end

    if changed then
        self:RefreshAll()
    end

    return changed
end

function DataEditor:DeleteDataset(datasetId)
    if not datasetId or not (self.Database and self.Database.DeleteDataset) then
        return false
    end

    local selectedId = self.SelectedDatasetId
    local datasets = self:GetDatasets()
    local fallbackId = nil

    for index = 1, #datasets do
        local candidateId = datasets[index] and datasets[index].id or nil
        if candidateId == datasetId then
            local nextDataset = datasets[index + 1] or datasets[index - 1]
            fallbackId = nextDataset and nextDataset.id or nil
            break
        end
    end

    local deleted = self.Database.DeleteDataset(datasetId)
    if not deleted then
        return false
    end

    if selectedId == datasetId then
        self.SelectedDatasetId = fallbackId
    end

    self.SelectedUnitIndex = nil
    self.SelectedEntryIndices = {}
    self.ActiveInspectorPageKey = "dataset"

    if self.Database and self.Database.SetActiveDatasetId then
        self.Database.SetActiveDatasetId(self.SelectedDatasetId)
    end

    self:RefreshAll()
    return true
end

function DataEditor:ConfirmDeleteDataset(datasetId)
    if not datasetId or not (UI.Popup and UI.Popup.ShowConfirmation) then
        return false
    end

    local dataset = self.Database and self.Database.GetDatasetByID and self.Database.GetDatasetByID(datasetId) or nil
    local datasetName = dataset and dataset.name or nil
    local displayName = datasetName ~= nil and datasetName ~= "" and tostring(datasetName) or "Unnamed Dataset"

    return UI.Popup:ShowConfirmation({
        title = "Delete Dataset",
        message = ('Delete dataset "%s"? This cannot be undone.'):format(displayName),
        confirmText = "Delete",
        cancelText = "Cancel",
        onConfirm = function()
            return self:DeleteDataset(datasetId)
        end,
    })
end

function DataEditor:ShowInspectorPage(pageKey)
    self.InspectorPages = self.InspectorPages or {}

    local builders = {
        dataset = "BuildDatasetInspectorPage",
        unit = "BuildUnitInspectorPage",
        mount = "BuildMountInspectorPage",
        pet = "BuildPetInspectorPage",
        item = "BuildItemInspectorPage",
        itemSlot = "BuildItemSlotInspectorPage",
        weaponType = "BuildWeaponTypeInspectorPage",
        damageSchool = "BuildDamageSchoolInspectorPage",
        spell = "BuildSpellInspectorPage",
        trait = "BuildTraitInspectorPage",
        skill = "BuildSkillInspectorPage",
        recipe = "BuildRecipeInspectorPage",
        aura = "BuildAuraInspectorPage",
        stat = "BuildStatInspectorPage",
        resource = "BuildResourceInspectorPage",
        achievement = "BuildAchievementInspectorPage",
        currency = "BuildCurrencyInspectorPage",
        race = "BuildRaceInspectorPage",
        class = "BuildClassInspectorPage",
    }

    for key, _ in pairs(builders) do
        if self.InspectorPages[key] and self.InspectorPages[key].Hide then
            self.InspectorPages[key]:Hide()
        end
    end

    local builderName = builders[pageKey] or builders.dataset
    local page = self.InspectorPages[pageKey]
    if not page and self[builderName] then
        page = self[builderName](self, self.InspectorHost)
        self.InspectorPages[pageKey] = page
        if page then
            UI.Utils.AnchorFill(page, self.InspectorHost, 0, 0, 0, 0)
        end
    end

    if page and page.Show then
        page:Show()
    end
end

function DataEditor:RefreshAll()
    self:GetSelectedDataset()
    self.ReferenceItemsCache = {}

    if self.RefreshDatasetsPane then
        self:RefreshDatasetsPane()
    end
    if self.RefreshUnitsDataPage then
        self:RefreshUnitsDataPage()
    end
    if self.RefreshMountsDataPage then
        self:RefreshMountsDataPage()
    end
    if self.RefreshPetsDataPage then
        self:RefreshPetsDataPage()
    end
    if self.RefreshItemsDataPage then
        self:RefreshItemsDataPage()
    end
    if self.RefreshSpellsDataPage then
        self:RefreshSpellsDataPage()
    end
    if self.RefreshTraitsDataPage then
        self:RefreshTraitsDataPage()
    end
    if self.RefreshSkillsDataPage then
        self:RefreshSkillsDataPage()
    end
    if self.RefreshStatsDataPage then
        self:RefreshStatsDataPage()
    end
    if self.RefreshResourcesDataPage then
        self:RefreshResourcesDataPage()
    end
    if self.RefreshRacesDataPage then
        self:RefreshRacesDataPage()
    end
    if self.RefreshClassesDataPage then
        self:RefreshClassesDataPage()
    end
    if self.RefreshItemSlotsDataPage then
        self:RefreshItemSlotsDataPage()
    end
    if self.RefreshWeaponTypesDataPage then
        self:RefreshWeaponTypesDataPage()
    end
    if self.RefreshDamageSchoolsDataPage then
        self:RefreshDamageSchoolsDataPage()
    end
    if self.RefreshLootDataPage then
        self:RefreshLootDataPage()
    end
    if self.RefreshRecipeDataPage then
        self:RefreshRecipeDataPage()
    end
    if self.RefreshAuraDataPage then
        self:RefreshAuraDataPage()
    end
    if self.RefreshInteractionDataPage then
        self:RefreshInteractionDataPage()
    end
    if self.RefreshAchievementDataPage then
        self:RefreshAchievementDataPage()
    end
    if self.RefreshCurrencyDataPage then
        self:RefreshCurrencyDataPage()
    end
    if self.RefreshDatasetInspectorPage then
        self:RefreshDatasetInspectorPage()
    end
    if self.RefreshUnitInspectorPage then
        self:RefreshUnitInspectorPage()
    end
    if self.RefreshMountInspectorPage then
        self:RefreshMountInspectorPage()
    end
    if self.RefreshPetInspectorPage then
        self:RefreshPetInspectorPage()
    end
    if self.RefreshItemInspectorPage then
        self:RefreshItemInspectorPage()
    end
    if self.RefreshSpellInspectorPage then
        self:RefreshSpellInspectorPage()
    end
    if self.RefreshTraitInspectorPage then
        self:RefreshTraitInspectorPage()
    end
    if self.RefreshSkillInspectorPage then
        self:RefreshSkillInspectorPage()
    end
    if self.RefreshRecipeInspectorPage then
        self:RefreshRecipeInspectorPage()
    end
    if self.RefreshAuraInspectorPage then
        self:RefreshAuraInspectorPage()
    end
    if self.RefreshItemSlotInspectorPage then
        self:RefreshItemSlotInspectorPage()
    end
    if self.RefreshWeaponTypeInspectorPage then
        self:RefreshWeaponTypeInspectorPage()
    end
    if self.RefreshDamageSchoolInspectorPage then
        self:RefreshDamageSchoolInspectorPage()
    end
    if self.RefreshStatInspectorPage then
        self:RefreshStatInspectorPage()
    end
    if self.RefreshResourceInspectorPage then
        self:RefreshResourceInspectorPage()
    end
    if self.RefreshCurrencyInspectorPage then
        self:RefreshCurrencyInspectorPage()
    end
    if self.RefreshAchievementInspectorPage then
        self:RefreshAchievementInspectorPage()
    end
    if self.RefreshRaceInspectorPage then
        self:RefreshRaceInspectorPage()
    end
    if self.RefreshClassInspectorPage then
        self:RefreshClassInspectorPage()
    end

    self:ShowInspectorPage(self:NormalizeActiveInspectorPageKey())
end

function DataEditor:BuildWindow()
    if self.Window then
        return self.Window
    end

    local window = UI.Window:New({
        name = "RPEDataEditorWindow",
        width = 660,
        height = 400,
        point = "CENTER",
        relativeTo = UIParent,
        relativePoint = "CENTER",
        frameStrata = "HIGH",
        frameLevel = 20,
        movable = true,
        clampedToScreen = true,
        toplevel = true,
        hidden = false,
        titleFontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        titleFontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Heading1) or 18,
        titleOffsetY = (UI.Constants and UI.Constants.Window and UI.Constants.Window.TitleOffsetY) or 16,
        contentInsetLeft = 8,
        contentInsetRight = 8,
        contentInsetTop = 28,
        contentInsetBottom = 8,
        borderSize = (UI.Constants and UI.Constants.Window and UI.Constants.Window.BorderSize) or 2,
    })

    window:SetTitle("Data Editor")
    window:Create()

    self.Window = window
    self:BuildRefreshHeaderButton()

    local content = window:GetContentFrame()
    self.RootLayout = UI.CreateLayout(UI.HorizontalLayoutGroup, content, "RPEDataEditorRootLayout", {
        spacing = 10,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })
    UI.Utils.AnchorFill(self.RootLayout, content, 0, 0, 0, 0)

    self.RootLayout:AddChild(self:BuildDatasetsPane(self.RootLayout:GetFrame()))

    self.ContentPanel = UI.CreatePanel(self.RootLayout:GetFrame(), "RPEDataEditorContentPanel", {
        width = 210,
        height = 332,
        expandWidth = true,
        weight = 210,
        contentInset = 0,
        showBorder = false,
    })
    self.RootLayout:AddChild(self.ContentPanel)

    self.ContentPanelLayout = UI.CreateLayout(UI.VerticalLayoutGroup, self.ContentPanel:GetContentFrame(), "RPEDataEditorContentPanelLayout", {
        spacing = 4,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })
    UI.Utils.AnchorFill(self.ContentPanelLayout, self.ContentPanel:GetContentFrame(), 0, 0, 0, 0)

    self.ContentSelectorBar = self:BuildContentSelectorBar(self.ContentPanelLayout:GetFrame())
    self.ContentPanelLayout:AddChild(self.ContentSelectorBar)

    self.ContentPageHostPanel = UI.CreatePanel(self.ContentPanelLayout:GetFrame(), "RPEDataEditorContentPageHostPanel", {
        width = 150,
        expandHeight = true,
        weight = 1,
        contentInset = 0,
        showBorder = false,
    })
    self.ContentPanelLayout:AddChild(self.ContentPageHostPanel)
    self.ContentPageHost = self.ContentPageHostPanel:GetContentFrame()
    self.ContentPageFrames = {}
    self.ActiveContentPageIndex = self.ActiveContentPageIndex or 1

    self.InspectorPanel = UI.CreatePanel(self.RootLayout:GetFrame(), "RPEDataEditorInspectorPanel", {
        width = 288,
        height = 332,
        expandWidth = true,
        weight = 288,
        contentInset = 0,
        showBorder = false,
    })
    self.RootLayout:AddChild(self.InspectorPanel)

    self.InspectorHost = CreateFrame("Frame", "RPEDataEditorInspectorHost", self.InspectorPanel:GetContentFrame())
    UI.Utils.AnchorFill(self.InspectorHost, self.InspectorPanel:GetContentFrame(), 0, 0, 0, 0)

    self:SetActiveContentPage(self.ActiveContentPageIndex or 1)
    self:RefreshActiveInspectorPage()
    self:UpdateRefreshButtonState()
    return window
end

function DataEditor:ShowWindow()
    local hadWindow = self.Window ~= nil
    local window = self:BuildWindow()
    if window and window.Show then
        window:Show()
    end

    self:UpdateRefreshButtonState()
    if hadWindow then
        self:RefreshVisibleSelectionState({
            refreshDatasetsPane = true,
            refreshActiveContentPage = true,
        })
    end
    return window
end

function DataEditor:HideWindow()
    if self.Window and self.Window.Hide then
        self.Window:Hide()
    end

    return self.Window
end

function Client:BuildDataEditorWindow()
    return DataEditor:BuildWindow()
end

function Client:ShowDataEditorWindow()
    return DataEditor:ShowWindow()
end

function Client:HideDataEditorWindow()
    return DataEditor:HideWindow()
end
