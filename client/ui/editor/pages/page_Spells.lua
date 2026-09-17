local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}
local Profile = Addon.Internal and Addon.Internal.Profile or {}
local ProfileWindow = Addon.Client and Addon.Client.UI and Addon.Client.UI.Profile and Addon.Client.UI.Profile.Window or {}

local function getSpellStatusText(spell)
    if not spell then
        return ""
    end

    if (tonumber(spell.castTime) or 0) > 0 then
        return ("Cast %.1fs"):format(tonumber(spell.castTime) or 0)
    end

    return "Instant"
end

local function getSpellDetailText(spell)
    if not spell then
        return ""
    end

    if spell.description and spell.description ~= "" then
        return spell.description
    end

    local componentCount = #(spell.components or {})
    local resourceCostCount = #(spell.resourceCosts or {})
    return ("%d component%s, %d cost%s"):format(
        componentCount,
        componentCount == 1 and "" or "s",
        resourceCostCount,
        resourceCostCount == 1 and "" or "s"
    )
end

local function spellHasEffectType(spell, effectType)
    local components = spell and spell.components or {}
    for index = 1, #components do
        local component = components[index]
        local effect = component and component.effect or nil
        if tostring(effect and effect.type or "damage") == effectType then
            return true
        end
    end

    return false
end

local function matchesSpellDropdownFilter(spell, filterValue)
    filterValue = tostring(filterValue or "all")
    if filterValue == "all" then
        return true
    end

    if filterValue == "timing:instant" then
        return spell and (tonumber(spell.castTime) or 0) <= 0
    end

    if filterValue == "timing:cast" then
        return spell and (tonumber(spell.castTime) or 0) > 0
    end

    if filterValue == "learn:always_learned" then
        return tostring(spell and spell.learnMode or "trainer") == "always_learned"
    end

    if filterValue == "learn:trainer" then
        return tostring(spell and spell.learnMode or "trainer") == "trainer"
    end

    if filterValue == "learn:book" then
        return tostring(spell and spell.learnMode or "trainer") == "book"
    end

    if filterValue == "learn:unavailable" then
        return tostring(spell and spell.learnMode or "trainer") == "unavailable"
    end

    if filterValue == "effect:damage" then
        return spellHasEffectType(spell, "damage")
    end

    if filterValue == "effect:heal" then
        return spellHasEffectType(spell, "heal")
    end

    if filterValue == "effect:apply_aura" then
        return spellHasEffectType(spell, "apply_aura")
    end

    if filterValue == "effect:resource" then
        return spellHasEffectType(spell, "resource")
    end

    if filterValue == "effect:interrupt" then
        return spellHasEffectType(spell, "interrupt")
    end

    if filterValue == "effect:taunt" then
        return spellHasEffectType(spell, "taunt")
    end

    if filterValue == "effect:revert" then
        return spellHasEffectType(spell, "revert")
    end

    if filterValue == "effect:summon_pet" then
        return spellHasEffectType(spell, "summon_pet")
    end

    return true
end

local function refreshProfileWindow()
    local window = ProfileWindow.Get and ProfileWindow:Get() or nil
    if window and window.Refresh then
        window:Refresh()
    end
end

function DataEditor:BuildSpellsPage(page)
    if self.SpellsPageRoot then
        return self.SpellsPageRoot
    end

    self.SpellsPageRoot = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorSpellsPageRoot", {
        spacing = 4,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })
    UI.Utils.AnchorFill(self.SpellsPageRoot, page, 0, 0, 0, 0)

    self.SpellsPageFilterBar, self.SpellsPageFilterInput, self.SpellsPageFilterDropdown, self.SpellsPageFilterClearButton = self:BuildDataPageFilterBar(
        self.SpellsPageRoot:GetFrame(),
        "RPEDataEditorSpellsPageFilterBar",
        "spells",
        {
            placeholder = "Search spells",
            inputWidth = 72,
            dropdownWidth = 76,
            dropdownItems = {
                { label = "All", value = "all" },
                {
                    label = "Timing",
                    value = "group:timing",
                    children = {
                        { label = "Instant", value = "timing:instant" },
                        { label = "Cast Time", value = "timing:cast" },
                    },
                },
                {
                    label = "Learn Mode",
                    value = "group:learn",
                    children = {
                        { label = "Always Learned", value = "learn:always_learned" },
                        { label = "Trainer", value = "learn:trainer" },
                        { label = "Book", value = "learn:book" },
                        { label = "Unavailable", value = "learn:unavailable" },
                    },
                },
                {
                    label = "Effect",
                    value = "group:effect",
                    children = {
                        { label = "Damage", value = "effect:damage" },
                        { label = "Heal", value = "effect:heal" },
                        { label = "Apply Aura", value = "effect:apply_aura" },
                        { label = "Resource", value = "effect:resource" },
                        { label = "Interrupt", value = "effect:interrupt" },
                        { label = "Taunt", value = "effect:taunt" },
                        { label = "Revert", value = "effect:revert" },
                        { label = "Summon Pet", value = "effect:summon_pet" },
                    },
                },
            },
        }
    )
    self.SpellsPageRoot:AddChild(self.SpellsPageFilterBar)

    local listPanel = UI.CreatePanel(self.SpellsPageRoot:GetFrame(), "RPEDataEditorSpellsListPanel", {
        width = 150,
        expandHeight = true,
        weight = 1,
        contentInset = 2,
        showBorder = false,
    })
    self.SpellsPageRoot:AddChild(listPanel)

    self.SpellsPageScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorSpellsScroll",
        width = 146,
        height = 248,
        visibleRows = 10,
        autoFitRows = true,
        rowHeight = 16,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.ScrollListEntry,
        categoryWidth = 90,
        statusWidth = 42,
        categoryInsetLeft = 4,
        statusInsetRight = 4,
    })
    self.SpellsPageScroll:SetParent(listPanel:GetContentFrame())
    self.SpellsPageScroll:SetRowRenderer(function(row, rowData)
        local spell = rowData and rowData.entry or nil
        local itemIndex = rowData and rowData.entryIndex or nil
        if row.SetCategory then
            row:SetCategory(self:GetEntryDisplayName("spells", spell))
        end
        if row.SetTestName then
            row:SetTestName("")
        end
        if row.SetStatus then
            row:SetStatus(getSpellStatusText(spell))
        end
        if row.SetDetail then
            row:SetDetail(getSpellDetailText(spell))
        end

        local frame = row.GetFrame and row:GetFrame() or nil
        if frame then
            frame:EnableMouse(true)
            frame:SetScript("OnMouseUp", function(_, button)
                if button == "LeftButton" then
                    self:SetSelectedDatasetEntryIndex("spells", itemIndex)
                    if self.SpellsContextMenu and self.SpellsContextMenu.HideMenus then
                        self.SpellsContextMenu:HideMenus()
                    end
                elseif button == "RightButton" and spell then
                    self:SetSelectedDatasetEntryIndex("spells", itemIndex)
                    self:ShowSpellsContextMenu(frame, spell)
                end
            end)

            local selectedEntry = self.SelectedEntryIndices and self.SelectedEntryIndices.spells or nil
            local isSelected = tonumber(selectedEntry) == tonumber(itemIndex)
            if row.entryBackground and row.entryBackground.SetColorTexture then
                local token = isSelected and "list.rowHover" or "list.rowBackground"
                local color = UI.ResolveColor(nil, token)
                row.entryBackground:SetColorTexture(color.r or 0.08, color.g or 0.09, color.b or 0.11, color.a or 0.85)
            end
        end
    end)
    self.SpellsPageScroll:Create()
    UI.Utils.AnchorFill(self.SpellsPageScroll, listPanel:GetContentFrame(), 0, 0, 0, 0)

    self.SpellsPageEmptyText = UI.CreateText(listPanel:GetContentFrame(), "RPEDataEditorSpellsEmptyText", "", {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = 122,
        height = 40,
        justifyH = "CENTER",
        wordWrap = true,
    })
    self.SpellsPageEmptyText:GetFrame():SetPoint("CENTER", listPanel:GetContentFrame(), "CENTER", 0, 0)

    self.SpellsPageToolbar, self.SpellsPageButtons = self:BuildDataPageToolbar(self.SpellsPageRoot:GetFrame(), "RPEDataEditorSpellsPageToolbar", "spells")
    self.SpellsPageRoot:AddChild(self.SpellsPageToolbar)

    self:RefreshSpellsDataPage()
    return self.SpellsPageRoot
end

function DataEditor:EnsureSpellsContextMenu()
    if self.SpellsContextMenu then
        return self.SpellsContextMenu
    end

    self.SpellsContextMenu = UI.ContextMenu:New({
        name = "RPEDataEditorSpellsContextMenu",
        width = 160,
        panelWidth = 160,
        visibleRows = 4,
        rowHeight = 18,
        border = false,
        onItemInvoked = function(item, menu)
            local action = item and item.value or nil
            local datasetId = self.ContextMenuSpellDatasetId
            local spellId = self.ContextMenuSpellId
            if action == "add-to-spellbook" and datasetId and spellId and Profile.AddKnownSpell then
                local added = Profile.AddKnownSpell(("%s:%s"):format(tostring(datasetId), tostring(spellId)))
                if added then
                    refreshProfileWindow()
                end
            end

            if menu and menu.HideMenus then
                menu:HideMenus()
            end
        end,
    })
    self.SpellsContextMenu:SetParent(self.Window and self.Window:GetFrame() or UIParent)
    self.SpellsContextMenu:Create()
    return self.SpellsContextMenu
end

function DataEditor:ShowSpellsContextMenu(anchorFrame, spell)
    local dataset = self:GetSelectedDataset()
    if not anchorFrame or not spell or not dataset or not dataset.id or not spell.id then
        return
    end

    local menu = self:EnsureSpellsContextMenu()
    self.ContextMenuSpellDatasetId = dataset.id
    self.ContextMenuSpellId = spell.id
    menu:SetItems({
        {
            label = "Add To Spellbook",
            value = "add-to-spellbook",
        },
    })
    menu:ShowAt(anchorFrame)
end

function DataEditor:RefreshSpellsDataPage()
    local dataset = self:GetSelectedDataset()
    local spells = dataset and dataset.spells or {}
    local filteredSpells, filterQuery = self:GetFilteredDatasetEntries("spells", spells)
    local dropdownFilter = self:GetCollectionDropdownFilterValue("spells")
    local visibleSpells = {}

    self:RefreshDataPageToolbar(self.SpellsPageButtons)

    for index = 1, #filteredSpells do
        local rowData = filteredSpells[index]
        if matchesSpellDropdownFilter(rowData and rowData.entry, dropdownFilter) then
            visibleSpells[#visibleSpells + 1] = rowData
        end
    end

    if self.SpellsPageScroll and self.SpellsPageScroll.SetItems then
        self.SpellsPageScroll:SetItems(visibleSpells)
    end

    if self.SpellsPageEmptyText and self.SpellsPageEmptyText.SetText then
        if not dataset then
            self.SpellsPageEmptyText:SetText("Create or select a dataset to view spells.")
        elseif #spells == 0 then
            self.SpellsPageEmptyText:SetText("This dataset has no spells yet.")
        elseif #visibleSpells == 0 and (filterQuery ~= "" or dropdownFilter ~= "all") then
            self.SpellsPageEmptyText:SetText("No spells match the current filters.")
        else
            self.SpellsPageEmptyText:SetText("")
        end
    end
end
