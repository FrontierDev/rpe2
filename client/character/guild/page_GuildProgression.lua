local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Guild = Addon.Client.UI.Guild or {}

local Client = Addon.Client
local GuildUI = Addon.Client.UI.Guild
local UI = Addon.UI or {}

local ProgressionPage = GuildUI.ProgressionPage or {}
GuildUI.ProgressionPage = ProgressionPage
ProgressionPage.__index = ProgressionPage

local function text(value)
    return tostring(value or "")
end

local function getEntryId(entry)
    return text(entry and entry.id)
end

local function getConfiguredSpell(entry, spellRef)
    local normalized = text(spellRef)
    local spellRefs = type(entry and entry.spellRefs) == "table" and entry.spellRefs or {}
    for index = 1, #spellRefs do
        if text(spellRefs[index]) == normalized then
            return normalized
        end
    end

    return nil
end

local function getEntryLabel(entry)
    local name = text(entry and entry.name)
    local entryId = getEntryId(entry)
    if name == "" then
        name = entryId
    end

    local icon = text(entry and entry.icon)
    if icon ~= "" then
        name = "|T" .. icon .. ":16:16|t " .. name
    end

    return name
end

function ProgressionPage:Build(parent, owner)
    self.owner = owner
    if self.frame then
        return self.frame
    end

    self.SelectedEntryId = ""
    self.SelectedSlot = 1
    self.SelectedSpellRef = ""

    self.frame = CreateFrame("Frame", "RPEGuildProgressionPage", parent)
    self.frame:SetAllPoints(parent)

    self.RootLayout = UI.CreateLayout(UI.VerticalLayoutGroup, self.frame, "RPEGuildProgressionRootLayout", {
        spacing = 4,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })
    UI.Utils.AnchorFill(self.RootLayout, self.frame, 0, 0, 0, 0)

    self.StatusText = UI.CreateText(self.RootLayout:GetFrame(), "RPEGuildProgressionStatusText", "", {
        width = 520,
        height = 32,
        justifyH = "LEFT",
        wordWrap = true,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.RootLayout:AddChild(self.StatusText)

    self.SummaryText = UI.CreateText(self.RootLayout:GetFrame(), "RPEGuildProgressionSummaryText", "", {
        width = 520,
        height = 20,
        textColor = UI.ResolveColor(nil, "text.primary"),
    })
    self.RootLayout:AddChild(self.SummaryText)

    self.EntryPanel = UI.CreatePanel(self.RootLayout:GetFrame(), "RPEGuildProgressionEntryPanel", {
        width = 520,
        height = 214,
        expandWidth = true,
        expandHeight = true,
        weight = 1,
        contentInset = 2,
        showBorder = false,
    })
    self.RootLayout:AddChild(self.EntryPanel)

    self.EntryList = UI.ScrollLayout:New({
        name = "RPEGuildProgressionEntryList",
        width = 512,
        height = 208,
        visibleRows = 7,
        rowHeight = 42,
        rowSpacing = 1,
        border = false,
        rowElementClass = UI.ScrollListEntry,
        categoryWidth = 82,
        statusWidth = 92,
        categoryInsetLeft = 4,
        statusInsetRight = 4,
        rowWordWrap = true,
    })
    self.EntryList:SetParent(self.EntryPanel:GetContentFrame())
    self.EntryList:SetRowRenderer(function(row, item, entryIndex)
        local entry = item and item.entry or item
        local entryId = getEntryId(entry)
        local locked = item and item.locked == true
        local assignedSlot = item and item.assignedSlot
        local selectedSpell = item and item.selectedSpell
        local details = text(entry and entry.description)
        if locked and text(entry and entry.lockedText) ~= "" then
            details = details ~= "" and (details .. "\n" .. entry.lockedText) or entry.lockedText
        end
        local icon = text(entry and entry.icon)
        if icon ~= "" then
            details = details ~= "" and ("Icon: |T" .. icon .. ":16:16|t\n" .. details)
                or ("Icon: |T" .. icon .. ":16:16|t")
        end
        local spellRefs = entry and entry.spellRefs or {}
        if #spellRefs > 0 then
            details = details ~= "" and (details .. "\n") or ""
            details = details .. "Available spells: " .. table.concat(spellRefs, ", ")
        end
        if selectedSpell then
            details = details ~= "" and (details .. "\n") or ""
            details = details .. "Selected spell: " .. selectedSpell
        end

        row:SetCategory(entryId ~= "" and entryId or ("Entry " .. tostring(entryIndex)))
        row:SetTestName(getEntryLabel(entry))
        row:SetStatus(locked and "Locked" or (assignedSlot and ("Slot " .. tostring(assignedSlot)) or "Unlocked"))
        row:SetDetail(details)

        local frame = row.GetFrame and row:GetFrame() or nil
        if frame then
            frame:EnableMouse(true)
            frame:SetScript("OnMouseUp", function(_, button)
                if button == "LeftButton" and entryId ~= "" then
                    self.SelectedEntryId = entryId
                    self.SelectedSpellRef = text(selectedSpell)
                    self:RefreshControls()
                    self:Refresh()
                end
            end)
            local selected = self.SelectedEntryId == entryId
            local color = UI.ResolveColor(nil, selected and "list.rowHover" or "list.rowBackground")
            if row.entryBackground and row.entryBackground.SetColorTexture then
                row.entryBackground:SetColorTexture(color.r or 0, color.g or 0, color.b or 0, color.a or 1)
            end
        end
    end)
    self.EntryList:Create()
    UI.Utils.AnchorFill(self.EntryList, self.EntryPanel:GetContentFrame(), 0, 0, 0, 0)

    self.EmptyText = UI.CreateText(self.EntryPanel:GetContentFrame(), "RPEGuildProgressionEmptyText", "", {
        width = 320,
        height = 40,
        justifyH = "CENTER",
        wordWrap = true,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.EmptyText:GetFrame():SetPoint("CENTER", self.EntryPanel:GetContentFrame(), "CENTER", 0, 0)

    self.ActionPanel = UI.CreatePanel(self.RootLayout:GetFrame(), "RPEGuildProgressionActionPanel", {
        width = 520,
        height = 86,
        expandWidth = true,
        contentInset = 2,
        showBorder = false,
    })
    self.RootLayout:AddChild(self.ActionPanel)
    local actionFrame = self.ActionPanel:GetContentFrame()

    self.EntryDropdown = UI.CreateDropdown(actionFrame, "RPEGuildProgressionEntryDropdown", {
        width = 220,
        height = 20,
        placeholder = "Select an entry",
        items = { { label = "Select an entry", value = "" } },
        onValueChanged = function(value)
            self.SelectedEntryId = text(value)
            self.SelectedSpellRef = ""
            self:RefreshControls()
            self:Refresh()
        end,
    })
    self.EntryDropdown:GetFrame():SetPoint("TOPLEFT", actionFrame, "TOPLEFT", 2, -2)

    self.SlotDropdown = UI.CreateDropdown(actionFrame, "RPEGuildProgressionSlotDropdown", {
        width = 66,
        height = 20,
        placeholder = "Slot",
        items = { { label = "Slot", value = "1" } },
        onValueChanged = function(value)
            self.SelectedSlot = tonumber(value) or 1
            self:RefreshControls()
        end,
    })
    self.SlotDropdown:GetFrame():SetPoint("TOPLEFT", actionFrame, "TOPLEFT", 228, -2)

    self.AssignButton = UI.CreateButton(actionFrame, "RPEGuildProgressionAssignButton", "Assign", 68, function()
        self:AssignSelectedEntry()
    end, { height = 20, fontSize = 8 })
    self.AssignButton:GetFrame():SetPoint("TOPLEFT", actionFrame, "TOPLEFT", 300, -2)

    self.UnlockButton = UI.CreateButton(actionFrame, "RPEGuildProgressionUnlockButton", "Unlock", 80, function()
        self:ToggleSelectedEntryLock()
    end, { height = 20, fontSize = 8 })
    self.UnlockButton:GetFrame():SetPoint("TOPLEFT", actionFrame, "TOPLEFT", 372, -2)

    self.SpellDropdown = UI.CreateDropdown(actionFrame, "RPEGuildProgressionSpellDropdown", {
        width = 220,
        height = 20,
        placeholder = "Select a configured spell",
        items = { { label = "Select a configured spell", value = "" } },
        onValueChanged = function(value)
            self.SelectedSpellRef = text(value)
            self:RefreshControls()
        end,
    })
    self.SpellDropdown:GetFrame():SetPoint("TOPLEFT", actionFrame, "TOPLEFT", 2, -26)

    self.SelectSpellButton = UI.CreateButton(actionFrame, "RPEGuildProgressionSelectSpellButton", "Select", 68, function()
        self:SelectSelectedSpell()
    end, { height = 20, fontSize = 8 })
    self.SelectSpellButton:GetFrame():SetPoint("TOPLEFT", actionFrame, "TOPLEFT", 228, -26)

    self.ClearSpellButton = UI.CreateButton(actionFrame, "RPEGuildProgressionClearSpellButton", "Clear", 68, function()
        self:ClearSelectedSpell()
    end, { height = 20, fontSize = 8 })
    self.ClearSpellButton:GetFrame():SetPoint("TOPLEFT", actionFrame, "TOPLEFT", 300, -26)

    self.ActionText = UI.CreateText(actionFrame, "RPEGuildProgressionActionText", "", {
        width = 200,
        height = 20,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.ActionText:GetFrame():SetPoint("TOPLEFT", actionFrame, "TOPLEFT", 372, -27)

    self:Refresh()
    return self.frame
end

function ProgressionPage:GetActiveProgression()
    local Guild = Client.Guild
    if not Guild or type(Guild.GetActiveGuildProgression) ~= "function" then
        return nil
    end

    return Guild:GetActiveGuildProgression()
end

function ProgressionPage:GetSelectedEntry(active)
    return active and active.entryById and active.entryById[self.SelectedEntryId] or nil
end

function ProgressionPage:RefreshControls()
    local active = self:GetActiveProgression()
    local entry = self:GetSelectedEntry(active)
    local canUse = active ~= nil and active.status == "valid" and entry ~= nil
    local state = active and active.state or {}
    local unlocked = canUse and state.unlocked and state.unlocked[self.SelectedEntryId] == true
    local selectedSpell = canUse and text(state.selectedSpells and state.selectedSpells[self.SelectedEntryId]) or ""
    local selectedSpellIsConfigured = getConfiguredSpell(entry, self.SelectedSpellRef) ~= nil

    if self.AssignButton then
        self.AssignButton:SetEnabled(canUse and unlocked and tonumber(self.SelectedSlot) ~= nil
            and tonumber(self.SelectedSlot) >= 1 and tonumber(self.SelectedSlot) <= active.slotCount)
    end
    if self.UnlockButton then
        self.UnlockButton:SetEnabled(canUse)
        self.UnlockButton:SetText(unlocked and "Lock" or "Unlock")
    end
    if self.SelectSpellButton then
        self.SelectSpellButton:SetEnabled(canUse and unlocked and selectedSpellIsConfigured)
    end
    if self.ClearSpellButton then
        self.ClearSpellButton:SetEnabled(canUse and selectedSpell ~= "")
    end
    if self.EntryDropdown then
        self.EntryDropdown:SetEnabled(active ~= nil and active.status == "valid")
    end
    if self.SlotDropdown then
        self.SlotDropdown:SetEnabled(active ~= nil and active.status == "valid" and active.slotCount > 0)
    end
    if self.SpellDropdown then
        self.SpellDropdown:SetEnabled(canUse == true and #((entry and entry.spellRefs) or {}) > 0)
    end
end

function ProgressionPage:AssignSelectedEntry()
    local active = self:GetActiveProgression()
    local entry = self:GetSelectedEntry(active)
    local Guild = Client.Guild
    if not active or active.status ~= "valid" or not entry or not Guild
        or type(Guild.AssignProgressionEntryToSlot) ~= "function" then
        return false
    end

    local ok, reason = Guild:AssignProgressionEntryToSlot(self.SelectedSlot, self.SelectedEntryId)
    self.ActionText:SetText(ok and "Entry assigned." or ("Assign failed: " .. text(reason)))
    self:Refresh()
    return ok == true
end

function ProgressionPage:ToggleSelectedEntryLock()
    local active = self:GetActiveProgression()
    local entry = self:GetSelectedEntry(active)
    local Guild = Client.Guild
    if not active or active.status ~= "valid" or not entry or not Guild
        or type(Guild.SetProgressionEntryUnlocked) ~= "function" then
        return false
    end

    local unlocked = active.state.unlocked and active.state.unlocked[self.SelectedEntryId] == true
    local ok, reason = Guild:SetProgressionEntryUnlocked(self.SelectedEntryId, not unlocked)
    self.ActionText:SetText(ok and (unlocked and "Entry locked." or "Entry unlocked.")
        or ("Lock change failed: " .. text(reason)))
    self:Refresh()
    return ok == true
end

function ProgressionPage:SelectSelectedSpell()
    local active = self:GetActiveProgression()
    local entry = self:GetSelectedEntry(active)
    local Guild = Client.Guild
    if not active or active.status ~= "valid" or not entry or not Guild
        or type(Guild.SelectProgressionSpell) ~= "function" then
        return false
    end

    local ok, reason = Guild:SelectProgressionSpell(self.SelectedEntryId, self.SelectedSpellRef)
    self.ActionText:SetText(ok and "Spell selected." or ("Spell selection failed: " .. text(reason)))
    self:Refresh()
    return ok == true
end

function ProgressionPage:ClearSelectedSpell()
    local active = self:GetActiveProgression()
    local entry = self:GetSelectedEntry(active)
    local Guild = Client.Guild
    if not active or active.status ~= "valid" or not entry or not Guild
        or type(Guild.ClearProgressionSpell) ~= "function" then
        return false
    end

    local ok, reason = Guild:ClearProgressionSpell(self.SelectedEntryId)
    self.ActionText:SetText(ok and "Spell cleared." or ("Spell clear failed: " .. text(reason)))
    self:Refresh()
    return ok == true
end

function ProgressionPage:Refresh()
    if not self.frame then
        return nil
    end

    local active = self:GetActiveProgression()
    local assignment, assignmentText
    if self.owner and self.owner.GetAssignedGuildRankDisplay then
        assignment, assignmentText = self.owner:GetAssignedGuildRankDisplay()
    end

    local hasActive = active and active.status == "valid"
    local entries = hasActive and active.entries or {}
    if hasActive and not active.entryById[self.SelectedEntryId] then
        self.SelectedEntryId = getEntryId(entries[1])
    end
    local selectedEntry = self:GetSelectedEntry(active)
    local state = active and active.state or { slots = {}, unlocked = {}, selectedSpells = {} }

    local inactiveText = assignmentText or "Guild Rank: No active progression"
    if active and active.status == "progression-disabled" then
        inactiveText = inactiveText .. ". Progression is disabled for this Guild Rank."
    elseif active and active.status == "progression-unavailable" then
        inactiveText = inactiveText .. ". No progression definition is configured."
    end
    self.StatusText:SetText(hasActive
        and ((assignmentText or "Guild Rank assigned") .. ". Progression is active for this rank.")
        or inactiveText)
    self.SummaryText:SetText(hasActive
        and ("Configured slots: %d | Entries: %d | Stored state is rank-scoped"):format(active.slotCount, #entries)
        or "")

    local displayEntries = {}
    for index = 1, #entries do
        local entry = entries[index]
        local entryId = getEntryId(entry)
        local assignedSlot
        for slot = 1, active.slotCount do
            if text(state.slots and state.slots[slot]) == entryId then
                assignedSlot = slot
                break
            end
        end
        displayEntries[#displayEntries + 1] = {
            entry = entry,
            locked = not (state.unlocked and state.unlocked[entryId] == true),
            assignedSlot = assignedSlot,
            selectedSpell = active.activeSelectedSpells and active.activeSelectedSpells[entryId] or nil,
        }
    end
    self.EntryList:SetItems(displayEntries)
    self.EmptyText:SetText(not hasActive and (assignmentText or "No valid assigned Guild Rank.")
        or (#entries == 0 and "No progression entries configured for this Guild Rank." or ""))

    local entryItems = { { label = "Select an entry", value = "" } }
    if hasActive then
        for index = 1, #entries do
            local entry = entries[index]
            entryItems[#entryItems + 1] = { label = getEntryLabel(entry), value = getEntryId(entry) }
        end
    end
    if self.EntryDropdown then
        self.EntryDropdown:SetItems(entryItems)
        self.EntryDropdown:SetSelectedValue(self.SelectedEntryId, true)
    end

    local slotItems = {}
    if hasActive then
        for slot = 1, active.slotCount do
            slotItems[#slotItems + 1] = { label = "Slot " .. tostring(slot), value = tostring(slot) }
        end
    end
    if #slotItems == 0 then
        slotItems[1] = { label = "Slot", value = "1" }
    end
    if self.SlotDropdown then
        self.SlotDropdown:SetItems(slotItems)
        self.SlotDropdown:SetSelectedValue(tostring(self.SelectedSlot or 1), true)
    end

    local spellItems = { { label = "Select a configured spell", value = "" } }
    if selectedEntry then
        local spellRefs = selectedEntry.spellRefs or {}
        for index = 1, #spellRefs do
            spellItems[#spellItems + 1] = { label = text(spellRefs[index]), value = text(spellRefs[index]) }
        end
        local storedSpell = text(state.selectedSpells and state.selectedSpells[self.SelectedEntryId])
        if storedSpell ~= "" and not getConfiguredSpell(selectedEntry, storedSpell) then
            spellItems[#spellItems + 1] = { label = "Current: " .. storedSpell, value = storedSpell }
        end
        if self.SelectedSpellRef == "" then
            self.SelectedSpellRef = storedSpell
        end
    else
        self.SelectedSpellRef = ""
    end
    if self.SpellDropdown then
        self.SpellDropdown:SetItems(spellItems)
        self.SpellDropdown:SetSelectedValue(self.SelectedSpellRef, true)
    end

    self:RefreshControls()
    return self.frame
end

return ProgressionPage
