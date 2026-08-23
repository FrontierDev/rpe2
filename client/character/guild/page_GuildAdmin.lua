local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Guild = Addon.Client.UI.Guild or {}

local Client = Addon.Client
local GuildUI = Addon.Client.UI.Guild
local UI = Addon.UI or {}
local Common = Addon.Utils and Addon.Utils.Common or {}
local Registry = Addon.Internal and Addon.Internal.Registry or {}

local AdminPage = GuildUI.AdminPage or {}
GuildUI.AdminPage = AdminPage
AdminPage.__index = AdminPage

local function setSelectedRow(row, selected)
    if not row or not row.entryBackground or not row.entryBackground.SetColorTexture then
        return
    end

    local color = UI.ResolveColor(nil, selected and "list.rowHover" or "list.rowBackground")
    row.entryBackground:SetColorTexture(color.r or 0, color.g or 0, color.b or 0, color.a or 1)
end

local function normalizeMemberName(name)
    local value = tostring(name or "")
    if type(Common.NormalizeName) == "function" then
        return tostring(Common.NormalizeName(value) or "")
    end

    return value
end

local function getRankLabel(match)
    local settingName = tostring(match and match.settingName or "")
    local datasetName = tostring(match and match.datasetName or "")
    local ref = tostring(match and match.ref or "")

    if settingName == "" then
        settingName = ref
    end
    if datasetName ~= "" and settingName ~= "" then
        return ("%s (%s)"):format(settingName, datasetName)
    end

    return settingName
end

local function getAdminReason(response)
    local reason = tostring(response and response.reason or "unknown-error")
    if reason == "" then
        return "unknown-error"
    end

    return reason
end

local function getDatasetEntryLabel(dataset, entry, reference)
    local entryName = tostring(entry and entry.name or "")
    local entryId = tostring(entry and entry.id or "")
    local datasetName = tostring(dataset and dataset.name or dataset and dataset.id or "")
    local label = entryName ~= "" and entryName or entryId
    if label == "" then
        label = tostring(reference or "")
    end
    if datasetName ~= "" and label ~= "" then
        return ("%s (%s)"):format(label, datasetName)
    end

    return label
end

local function buildReferenceItems(collectionKey)
    local items = {
        { label = "Select a " .. collectionKey .. " reference", value = "" },
    }
    local seen = {}
    local datasets = type(Registry.GetActivatedDatasets) == "function"
        and Registry:GetActivatedDatasets()
        or {}
    for datasetIndex = 1, #(datasets or {}) do
        local dataset = datasets[datasetIndex]
        local entries = type(dataset and dataset[collectionKey]) == "table" and dataset[collectionKey] or {}
        for entryIndex = 1, #entries do
            local entry = entries[entryIndex]
            local datasetId = tostring(dataset and dataset.id or "")
            local entryId = tostring(entry and entry.id or "")
            local reference = datasetId ~= "" and entryId ~= "" and (datasetId .. ":" .. entryId) or ""
            if reference ~= "" and not seen[reference] then
                seen[reference] = true
                items[#items + 1] = {
                    label = getDatasetEntryLabel(dataset, entry, reference),
                    value = reference,
                }
            end
        end
    end

    return items
end

local function normalizeInteger(value, minimum, maximum)
    local numeric = tonumber(tostring(value or ""))
    if not numeric or numeric ~= numeric or numeric == math.huge or numeric == -math.huge then
        return nil
    end

    local integer = math.floor(numeric)
    if numeric ~= integer or (minimum ~= nil and integer < minimum) or (maximum ~= nil and integer > maximum) then
        return nil
    end

    return integer
end

local function getSelectedAchievementState(page)
    local profileState = page.SelectedMemberProfileState or {}
    local achievements = type(profileState.achievements) == "table" and profileState.achievements or {}
    return achievements[tostring(page.SelectedAchievementRef or "")]
end

local function getSelectedSkillLevel(page)
    local profileState = page.SelectedMemberProfileState or {}
    local skills = type(profileState.skills) == "table" and profileState.skills or {}
    return tonumber(skills[tostring(page.SelectedSkillRef or "")]) or 0
end

function AdminPage:Build(parent, owner)
    self.owner = owner
    if self.frame then
        return self.frame
    end

    self.SelectedMemberKey = nil
    self.SelectedMemberAdminState = nil
    self.SelectedMemberProfileState = { achievements = {}, skills = {} }
    self.SelectedMemberQueryPending = false
    self.PendingAdminAction = nil
    self.SelectedGuildRankRef = ""
    self.EligibleGuildRanks = {}
    self.AdminActionMessage = nil
    self.AdminSection = "Achievements"
    self.SelectedAchievementRef = ""
    self.SelectedSkillRef = ""
    self.SelectedItemRef = ""

    self.frame = CreateFrame("Frame", "RPEGuildAdminPage", parent)
    self.frame:SetAllPoints(parent)

    self.RootLayout = UI.CreateLayout(UI.VerticalLayoutGroup, self.frame, "RPEGuildAdminRootLayout", {
        spacing = 4,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })
    UI.Utils.AnchorFill(self.RootLayout, self.frame, 0, 0, 0, 0)

    self.StatusText = UI.CreateText(self.RootLayout:GetFrame(), "RPEGuildAdminStatusText", "", {
        width = 520,
        height = 30,
        justifyH = "LEFT",
        wordWrap = true,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.RootLayout:AddChild(self.StatusText)

    self.RosterPanel = UI.CreatePanel(self.RootLayout:GetFrame(), "RPEGuildRosterPanel", {
        width = 520,
        height = 250,
        expandWidth = true,
        expandHeight = true,
        weight = 1,
        contentInset = 2,
        showBorder = false,
    })
    self.RootLayout:AddChild(self.RosterPanel)

    self.RosterTitle = UI.CreateText(self.RosterPanel:GetContentFrame(), "RPEGuildRosterTitle", "Guild Roster (select a member for Guild Admin)", {
        width = 512,
        height = 18,
        textColor = UI.ResolveColor(nil, "text.primary"),
    })
    self.RosterList = UI.ScrollLayout:New({
        name = "RPEGuildRosterList",
        width = 512,
        height = 216,
        visibleRows = 9,
        rowHeight = 22,
        rowSpacing = 1,
        border = false,
        rowElementClass = UI.ScrollListEntry,
        categoryWidth = 120,
        statusWidth = 94,
        categoryInsetLeft = 4,
        statusInsetRight = 4,
    })
    self.RosterList:SetParent(self.RosterPanel:GetContentFrame())
    self.RosterList:SetRowRenderer(function(row, member, memberIndex)
        local name = tostring(member and member.name or ("Member " .. tostring(memberIndex)))
        local details = tostring(member and member.rankName or "")
        if member and member.zone ~= "" then
            details = details ~= "" and (details .. " - " .. member.zone) or member.zone
        end
        row:SetCategory(name)
        row:SetTestName(details)
        row:SetStatus(member and member.online and "Online" or "Offline")
        row:SetDetail(("Level %d\nClass: %s"):format(
            tonumber(member and member.level) or 0,
            tostring(member and member.className or "Unknown")
        ))

        local frame = row.GetFrame and row:GetFrame() or nil
        if frame then
            frame:EnableMouse(true)
            frame:SetScript("OnMouseUp", function(_, button)
                if button == "LeftButton" then
                    self.SelectedMemberIndex = memberIndex
                    self.SelectedMemberKey = nil
                    self.SelectedMemberAdminState = nil
                    self.SelectedMemberProfileState = { achievements = {}, skills = {} }
                    self.SelectedMemberQueryPending = false
                    self.PendingAdminAction = nil
                    self.SelectedGuildRankRef = ""
                    self.SelectedAchievementRef = ""
                    self.SelectedSkillRef = ""
                    self.SelectedItemRef = ""
                    self.EligibleGuildRanks = {}
                    self.AdminActionMessage = nil
                    self:Refresh()
                end
            end)
            setSelectedRow(row, tonumber(self.SelectedMemberIndex) == tonumber(memberIndex))
        end
    end)
    self.RosterList:Create()
    UI.Utils.AnchorFill(self.RosterList, self.RosterPanel:GetContentFrame(), 0, 20, 0, 0)
    self.RosterEmptyText = UI.CreateText(self.RosterPanel:GetContentFrame(), "RPEGuildRosterEmptyText", "", {
        width = 320,
        height = 30,
        justifyH = "CENTER",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.RosterEmptyText:GetFrame():SetPoint("CENTER", self.RosterPanel:GetContentFrame(), "CENTER", 0, -10)

    self.AdminSectionsPanel = UI.CreatePanel(self.RootLayout:GetFrame(), "RPEGuildAdminSectionsPanel", {
        width = 520,
        height = 190,
        expandWidth = true,
        contentInset = 2,
        showBorder = false,
    })
    self.RootLayout:AddChild(self.AdminSectionsPanel)
    self.AdminSectionsLayout = UI.CreateLayout(UI.HorizontalLayoutGroup, self.AdminSectionsPanel:GetContentFrame(), "RPEGuildAdminSectionsLayout", {
        width = 512,
        spacing = 4,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
        height = 22,
    })
    self.AdminSectionsLayout:GetFrame():SetPoint("BOTTOMLEFT", self.AdminSectionsPanel:GetContentFrame(), "BOTTOMLEFT", 2, 2)
    local plannedSections = { "Achievements", "Skills", "Items" }
    self.AdminSectionButtons = {}
    for index = 1, #plannedSections do
        local section = plannedSections[index]
        local button = UI.CreateButton(self.AdminSectionsLayout:GetFrame(), "RPEGuildAdminPlanned" .. section .. "Button", section, 104, function()
            self.AdminSection = section
            self.AdminActionMessage = nil
            self:Refresh()
        end, {
            height = 20,
            fontSize = 8,
        })
        self.AdminSectionsLayout:AddChild(button)
        self.AdminSectionButtons[#self.AdminSectionButtons + 1] = button
    end

    self.SetGuildRankButton = UI.CreateButton(self.AdminSectionsLayout:GetFrame(), "RPEGuildAdminSetGuildRankButton", "Set Rank", 86, function()
        self:SetSelectedGuildRank()
    end, {
        height = 20,
        fontSize = 8,
    })
    self.AdminSectionsLayout:AddChild(self.SetGuildRankButton)

    self.ClearGuildRankButton = UI.CreateButton(self.AdminSectionsLayout:GetFrame(), "RPEGuildAdminClearGuildRankButton", "Clear Rank", 86, function()
        self:ClearSelectedGuildRank()
    end, {
        height = 20,
        fontSize = 8,
    })

    self.AdminSectionsLayout:AddChild(self.ClearGuildRankButton)
    self.AdminSectionsText = UI.CreateText(self.AdminSectionsPanel:GetContentFrame(), "RPEGuildAdminSectionsText", "", {
        width = 512,
        height = 30,
        justifyH = "LEFT",
        wordWrap = true,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.AdminSectionsText:GetFrame():SetPoint("TOPLEFT", self.AdminSectionsPanel:GetContentFrame(), "TOPLEFT", 2, -2)

    self.GuildRankDropdown = UI.CreateDropdown(self.AdminSectionsPanel:GetContentFrame(), "RPEGuildAdminGuildRankDropdown", {
        width = 300,
        height = 20,
        placeholder = "Select an eligible RPE Guild Rank",
        items = {
            { label = "Select an eligible RPE Guild Rank", value = "" },
        },
        onValueChanged = function(value)
            self.SelectedGuildRankRef = tostring(value or "")
            self.AdminActionMessage = nil
            self:RefreshActionControls()
        end,
    })
    self.GuildRankDropdown:GetFrame():SetPoint("TOPLEFT", self.AdminSectionsPanel:GetContentFrame(), "TOPLEFT", 2, -35)

    self.AchievementDropdown = UI.CreateDropdown(self.AdminSectionsPanel:GetContentFrame(), "RPEGuildAdminAchievementDropdown", {
        width = 250,
        height = 18,
        placeholder = "Select an Achievement",
        items = {
            { label = "Select an Achievement", value = "" },
        },
        onValueChanged = function(value)
            self.SelectedAchievementRef = tostring(value or "")
            self.AdminActionMessage = nil
            self:RefreshActionControls()
        end,
    })
    self.AchievementDropdown:GetFrame():SetPoint("TOPLEFT", self.AdminSectionsPanel:GetContentFrame(), "TOPLEFT", 2, -58)

    self.AchievementStateText = UI.CreateText(self.AdminSectionsPanel:GetContentFrame(), "RPEGuildAdminAchievementStateText", "", {
        width = 150,
        height = 18,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.AchievementStateText:GetFrame():SetPoint("TOPLEFT", self.AdminSectionsPanel:GetContentFrame(), "TOPLEFT", 258, -58)

    self.GrantAchievementButton = UI.CreateButton(self.AdminSectionsPanel:GetContentFrame(), "RPEGuildAdminGrantAchievementButton", "Grant", 70, function()
        self:GrantSelectedAchievement()
    end, {
        height = 18,
        fontSize = 8,
    })
    self.GrantAchievementButton:GetFrame():SetPoint("TOPLEFT", self.AdminSectionsPanel:GetContentFrame(), "TOPLEFT", 412, -58)

    self.SkillDropdown = UI.CreateDropdown(self.AdminSectionsPanel:GetContentFrame(), "RPEGuildAdminSkillDropdown", {
        width = 250,
        height = 18,
        placeholder = "Select a Skill",
        items = {
            { label = "Select a Skill", value = "" },
        },
        onValueChanged = function(value)
            self.SelectedSkillRef = tostring(value or "")
            self.AdminActionMessage = nil
            self:RefreshActionControls()
        end,
    })
    self.SkillDropdown:GetFrame():SetPoint("TOPLEFT", self.AdminSectionsPanel:GetContentFrame(), "TOPLEFT", 2, -80)

    self.SkillLevelText = UI.CreateText(self.AdminSectionsPanel:GetContentFrame(), "RPEGuildAdminSkillLevelText", "Level: --", {
        width = 74,
        height = 18,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.SkillLevelText:GetFrame():SetPoint("TOPLEFT", self.AdminSectionsPanel:GetContentFrame(), "TOPLEFT", 258, -80)

    self.DecreaseSkillButton = UI.CreateButton(self.AdminSectionsPanel:GetContentFrame(), "RPEGuildAdminDecreaseSkillButton", "-1", 42, function()
        self:AdjustSelectedSkill(-1)
    end, {
        height = 18,
        fontSize = 8,
    })
    self.DecreaseSkillButton:GetFrame():SetPoint("TOPLEFT", self.AdminSectionsPanel:GetContentFrame(), "TOPLEFT", 334, -80)

    self.IncreaseSkillButton = UI.CreateButton(self.AdminSectionsPanel:GetContentFrame(), "RPEGuildAdminIncreaseSkillButton", "+1", 42, function()
        self:AdjustSelectedSkill(1)
    end, {
        height = 18,
        fontSize = 8,
    })
    self.IncreaseSkillButton:GetFrame():SetPoint("TOPLEFT", self.AdminSectionsPanel:GetContentFrame(), "TOPLEFT", 380, -80)

    self.ItemDropdown = UI.CreateDropdown(self.AdminSectionsPanel:GetContentFrame(), "RPEGuildAdminItemDropdown", {
        width = 250,
        height = 18,
        placeholder = "Select an Item",
        items = {
            { label = "Select an Item", value = "" },
        },
        onValueChanged = function(value)
            self.SelectedItemRef = tostring(value or "")
            self.AdminActionMessage = nil
            self:RefreshActionControls()
        end,
    })
    self.ItemDropdown:GetFrame():SetPoint("TOPLEFT", self.AdminSectionsPanel:GetContentFrame(), "TOPLEFT", 2, -102)

    self.ItemQuantityInput = UI.CreateTextInput(self.AdminSectionsPanel:GetContentFrame(), "RPEGuildAdminItemQuantityInput", {
        width = 62,
        height = 18,
        text = "1",
        placeholder = "Qty",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.ItemQuantityInput:SetScript("OnTextChanged", function()
        self:RefreshActionControls()
    end)
    self.ItemQuantityInput:GetFrame():SetPoint("TOPLEFT", self.AdminSectionsPanel:GetContentFrame(), "TOPLEFT", 258, -102)

    self.GiveItemButton = UI.CreateButton(self.AdminSectionsPanel:GetContentFrame(), "RPEGuildAdminGiveItemButton", "Give", 70, function()
        self:GiveSelectedItem()
    end, {
        height = 18,
        fontSize = 8,
    })
    self.GiveItemButton:GetFrame():SetPoint("TOPLEFT", self.AdminSectionsPanel:GetContentFrame(), "TOPLEFT", 326, -102)

    self:Refresh()
    return self.frame
end

function AdminPage:RefreshActionControls()
    local selectedMember = self.SelectedMember
    local canAdminister = self.IsOfficer == true
        and selectedMember ~= nil
        and selectedMember.online == true
        and self.SelectedMemberQueryPending ~= true
        and self.SelectedMemberAdminState ~= nil
        and self.SelectedMemberAdminState.success == true
        and self.PendingAdminAction == nil
    local eligibleRanks = self.EligibleGuildRanks or {}
    local selectedAchievementState = getSelectedAchievementState(self)
    local selectedSkillRef = tostring(self.SelectedSkillRef or "")
    local selectedItemRef = tostring(self.SelectedItemRef or "")
    local itemQuantity = self.ItemQuantityInput and normalizeInteger(self.ItemQuantityInput:GetText(), 1) or nil
    local canUseAdminControls = canAdminister
    local selectedRankIsEligible = false
    for index = 1, #eligibleRanks do
        if tostring(eligibleRanks[index] and eligibleRanks[index].ref or "") == tostring(self.SelectedGuildRankRef or "")
            and tostring(self.SelectedGuildRankRef or "") ~= "" then
            selectedRankIsEligible = true
            break
        end
    end

    if self.GuildRankDropdown then
        self.GuildRankDropdown:SetEnabled(canAdminister and #eligibleRanks > 0)
    end
    if self.SetGuildRankButton then
        self.SetGuildRankButton:SetEnabled(canAdminister and selectedRankIsEligible)
    end

    local assignedRankRef = self.SelectedMemberAdminState
        and self.SelectedMemberAdminState.success == true
        and tostring(self.SelectedMemberAdminState.assignedRankRef or "")
        or ""
    if self.ClearGuildRankButton then
        self.ClearGuildRankButton:SetEnabled(canAdminister and assignedRankRef ~= "")
    end

    for index = 1, #(self.AdminSectionButtons or {}) do
        self.AdminSectionButtons[index]:SetEnabled(
            self.IsOfficer == true
                and selectedMember ~= nil
                and selectedMember.online == true
        )
    end
    if self.AchievementDropdown then
        self.AchievementDropdown:SetEnabled(canUseAdminControls)
    end
    if self.GrantAchievementButton then
        self.GrantAchievementButton:SetEnabled(
            canUseAdminControls
                and tostring(self.SelectedAchievementRef or "") ~= ""
                and selectedAchievementState == nil
        )
    end
    if self.SkillDropdown then
        self.SkillDropdown:SetEnabled(canUseAdminControls)
    end
    if self.DecreaseSkillButton then
        self.DecreaseSkillButton:SetEnabled(canUseAdminControls and selectedSkillRef ~= "")
    end
    if self.IncreaseSkillButton then
        self.IncreaseSkillButton:SetEnabled(canUseAdminControls and selectedSkillRef ~= "")
    end
    if self.ItemDropdown then
        self.ItemDropdown:SetEnabled(canUseAdminControls)
    end
    if self.ItemQuantityInput then
        self.ItemQuantityInput:SetEnabled(canUseAdminControls)
    end
    if self.GiveItemButton then
        self.GiveItemButton:SetEnabled(canUseAdminControls and selectedItemRef ~= "" and itemQuantity ~= nil)
    end
end

local function containsRankRef(ranks, rankRef)
    local normalizedRef = tostring(rankRef or "")
    if normalizedRef == "" then
        return false
    end

    for index = 1, #(ranks or {}) do
        if tostring(ranks[index] and ranks[index].ref or "") == normalizedRef then
            return true
        end
    end

    return false
end

local function getSelectedMutationContext(page)
    local selectedMember = page.SelectedMember
    if not selectedMember or selectedMember.online ~= true or page.IsOfficer ~= true
        or page.SelectedMemberQueryPending == true
        or not page.SelectedMemberAdminState
        or page.SelectedMemberAdminState.success ~= true
        or page.PendingAdminAction ~= nil then
        return nil, nil
    end

    return selectedMember, page.SelectionGeneration
end

local function preserveSelectedRankState(page, response)
    local previous = page.SelectedMemberAdminState or {}
    local normalizedResponse = response or { success = false, reason = "unknown-error" }
    if tostring(normalizedResponse.assignedRankRef or "") == "" then
        normalizedResponse.assignedRankRef = tostring(previous.assignedRankRef or "")
    end
    page.SelectedMemberAdminState = normalizedResponse
    return normalizedResponse
end

function AdminPage:GrantSelectedAchievement()
    local Guild = Client.Guild
    local selectedMember, selectionGeneration = getSelectedMutationContext(self)
    local achievementRef = tostring(self.SelectedAchievementRef or "")
    if not Guild or not selectedMember or achievementRef == "" or getSelectedAchievementState(self) ~= nil then
        return false
    end

    local selectedKey = self.SelectedMemberKey
    self.PendingAdminAction = "grant_achievement"
    self.AdminActionMessage = "Grant pending..."
    self:Refresh()

    local function finish(response)
        if self.SelectedMemberKey ~= selectedKey or self.SelectionGeneration ~= selectionGeneration then
            return
        end

        self.PendingAdminAction = nil
        local normalizedResponse = preserveSelectedRankState(self, response)
        if normalizedResponse.success == true then
            self.SelectedMemberProfileState = self.SelectedMemberProfileState or { achievements = {}, skills = {} }
            self.SelectedMemberProfileState.achievements = self.SelectedMemberProfileState.achievements or {}
            self.SelectedMemberProfileState.achievements[achievementRef] = {
                completedAt = tostring(normalizedResponse.value or "") ~= ""
                    and normalizedResponse.value
                    or true,
            }
            self.AdminActionMessage = "Grant acknowledged by target client."
        else
            self.AdminActionMessage = ("Grant failed: %s"):format(getAdminReason(normalizedResponse))
        end
        self:Refresh()
    end

    if type(Guild.GrantAchievementForMember) ~= "function" then
        finish({ success = false, reason = "incompatible-protocol" })
        return false
    end

    return Guild:GrantAchievementForMember(selectedMember.name, achievementRef, finish) == true
end

function AdminPage:AdjustSelectedSkill(delta)
    local Guild = Client.Guild
    local selectedMember, selectionGeneration = getSelectedMutationContext(self)
    local skillRef = tostring(self.SelectedSkillRef or "")
    local normalizedDelta = normalizeInteger(delta)
    if not Guild or not selectedMember or skillRef == "" or not normalizedDelta or normalizedDelta == 0 then
        return false
    end

    local selectedKey = self.SelectedMemberKey
    self.PendingAdminAction = "adjust_skill"
    self.AdminActionMessage = normalizedDelta > 0 and "Skill increase pending..." or "Skill decrease pending..."
    self:Refresh()

    local function finish(response)
        if self.SelectedMemberKey ~= selectedKey or self.SelectionGeneration ~= selectionGeneration then
            return
        end

        self.PendingAdminAction = nil
        local normalizedResponse = preserveSelectedRankState(self, response)
        if normalizedResponse.success == true then
            self.SelectedMemberProfileState = self.SelectedMemberProfileState or { achievements = {}, skills = {} }
            self.SelectedMemberProfileState.skills = self.SelectedMemberProfileState.skills or {}
            self.SelectedMemberProfileState.skills[skillRef] = tonumber(normalizedResponse.value)
                or (getSelectedSkillLevel(self) + normalizedDelta)
            self.AdminActionMessage = "Skill adjustment acknowledged by target client."
        else
            self.AdminActionMessage = ("Skill adjustment failed: %s"):format(getAdminReason(normalizedResponse))
        end
        self:Refresh()
    end

    if type(Guild.AdjustSkillForMember) ~= "function" then
        finish({ success = false, reason = "incompatible-protocol" })
        return false
    end

    return Guild:AdjustSkillForMember(selectedMember.name, skillRef, normalizedDelta, finish) == true
end

function AdminPage:GiveSelectedItem()
    local Guild = Client.Guild
    local selectedMember, selectionGeneration = getSelectedMutationContext(self)
    local itemRef = tostring(self.SelectedItemRef or "")
    local quantity = self.ItemQuantityInput and normalizeInteger(self.ItemQuantityInput:GetText(), 1) or nil
    if not Guild or not selectedMember or itemRef == "" or quantity == nil then
        return false
    end

    local selectedKey = self.SelectedMemberKey
    self.PendingAdminAction = "give_item"
    self.AdminActionMessage = "Item award pending..."
    self:Refresh()

    local function finish(response)
        if self.SelectedMemberKey ~= selectedKey or self.SelectionGeneration ~= selectionGeneration then
            return
        end

        self.PendingAdminAction = nil
        local normalizedResponse = preserveSelectedRankState(self, response)
        if normalizedResponse.success == true then
            self.AdminActionMessage = "Item award acknowledged by target client."
        else
            self.AdminActionMessage = ("Item award failed: %s"):format(getAdminReason(normalizedResponse))
        end
        self:Refresh()
    end

    if type(Guild.GiveItemToMember) ~= "function" then
        finish({ success = false, reason = "incompatible-protocol" })
        return false
    end

    return Guild:GiveItemToMember(selectedMember.name, itemRef, quantity, finish) == true
end

function AdminPage:SetSelectedGuildRank()
    local Guild = Client.Guild
    local selectedMember = self.SelectedMember
    local selectedRankRef = tostring(self.SelectedGuildRankRef or "")
    if not Guild or not selectedMember or selectedMember.online ~= true or self.IsOfficer ~= true
        or self.SelectedMemberQueryPending == true
        or not self.SelectedMemberAdminState or self.SelectedMemberAdminState.success ~= true
        or selectedRankRef == "" or not containsRankRef(self.EligibleGuildRanks, selectedRankRef)
        or self.PendingAdminAction ~= nil then
        return false
    end

    local selectedKey = self.SelectedMemberKey
    local selectionGeneration = self.SelectionGeneration
    self.PendingAdminAction = "set_guild_rank"
    self.AdminActionMessage = "Set pending..."
    self:Refresh()

    local function finish(response)
        if self.SelectedMemberKey ~= selectedKey or self.SelectionGeneration ~= selectionGeneration then
            return
        end

        self.PendingAdminAction = nil
        self.SelectedMemberAdminState = response or { success = false, reason = "unknown-error" }
        if self.SelectedMemberAdminState.success == true then
            self.SelectedGuildRankRef = tostring(self.SelectedMemberAdminState.assignedRankRef or selectedRankRef)
            self.AdminActionMessage = "Set succeeded; target client acknowledged the assignment."
        else
            self.AdminActionMessage = ("Set failed: %s"):format(getAdminReason(self.SelectedMemberAdminState))
        end
        self:Refresh()
    end

    if type(Guild.SetGuildRankForMember) ~= "function" then
        finish({ success = false, reason = "incompatible-protocol" })
        return false
    end

    local sent = Guild:SetGuildRankForMember(selectedMember.name, selectedRankRef, finish)
    return sent == true
end

function AdminPage:ClearSelectedGuildRank()
    local Guild = Client.Guild
    local selectedMember = self.SelectedMember
    if not Guild or not selectedMember or selectedMember.online ~= true or self.IsOfficer ~= true
        or self.SelectedMemberQueryPending == true
        or self.PendingAdminAction ~= nil then
        return false
    end

    local assignedRankRef = self.SelectedMemberAdminState
        and self.SelectedMemberAdminState.success == true
        and tostring(self.SelectedMemberAdminState.assignedRankRef or "")
        or ""
    if assignedRankRef == "" then
        return false
    end

    local selectedKey = self.SelectedMemberKey
    local selectionGeneration = self.SelectionGeneration
    self.PendingAdminAction = "clear_guild_rank"
    self.AdminActionMessage = "Clear pending..."
    self:Refresh()

    local function finish(response)
        if self.SelectedMemberKey ~= selectedKey or self.SelectionGeneration ~= selectionGeneration then
            return
        end

        self.PendingAdminAction = nil
        self.SelectedMemberAdminState = response or { success = false, reason = "unknown-error" }
        if self.SelectedMemberAdminState.success == true then
            self.SelectedGuildRankRef = ""
            self.AdminActionMessage = "Clear succeeded; target client acknowledged the removal."
        else
            self.AdminActionMessage = ("Clear failed: %s"):format(getAdminReason(self.SelectedMemberAdminState))
        end
        self:Refresh()
    end

    if type(Guild.ClearGuildRankForMember) ~= "function" then
        finish({ success = false, reason = "incompatible-protocol" })
        return false
    end

    local sent = Guild:ClearGuildRankForMember(selectedMember.name, finish)
    return sent == true
end

function AdminPage:Refresh()
    if not self.frame then
        return nil
    end

    local Guild = Client.Guild
    local identity = Guild and Guild:GetLocalGuildIdentity() or { inGuild = false }
    local isOfficer = Guild and Guild:IsLocalPlayerOfficer() == true or false
    local roster = Guild and Guild:GetRoster() or {}
    local selectedMember = roster[self.SelectedMemberIndex]
    local selectedMemberKey = normalizeMemberName(selectedMember and selectedMember.name)
    local wowRankIndex = tonumber(selectedMember and selectedMember.rankIndex)

    if selectedMemberKey ~= self.SelectedMemberKey then
        self.SelectionGeneration = (tonumber(self.SelectionGeneration) or 0) + 1
        self.SelectedMemberKey = selectedMemberKey ~= "" and selectedMemberKey or nil
        self.SelectedMemberAdminState = nil
        self.SelectedMemberProfileState = { achievements = {}, skills = {} }
        self.SelectedMemberQueryPending = false
        self.PendingAdminAction = nil
        self.SelectedGuildRankRef = ""
        self.SelectedAchievementRef = ""
        self.SelectedSkillRef = ""
        self.SelectedItemRef = ""
        self.AdminActionMessage = nil
    elseif selectedMember and self.SelectedMemberWowRankIndex ~= nil and self.SelectedMemberWowRankIndex ~= wowRankIndex then
        self.SelectionGeneration = (tonumber(self.SelectionGeneration) or 0) + 1
        self.SelectedMemberAdminState = nil
        self.SelectedMemberProfileState = { achievements = {}, skills = {} }
        self.SelectedMemberQueryPending = false
        self.PendingAdminAction = nil
        self.SelectedGuildRankRef = ""
        self.SelectedAchievementRef = ""
        self.SelectedSkillRef = ""
        self.SelectedItemRef = ""
        self.AdminActionMessage = nil
    end
    self.SelectedMemberWowRankIndex = wowRankIndex
    self.SelectedMember = selectedMember
    self.IsOfficer = isOfficer

    local eligibleRanks = {}
    if Guild and isOfficer and selectedMember and selectedMember.online == true
        and type(Guild.GetEligibleGuildRanksForWoWRank) == "function" then
        eligibleRanks = Guild:GetEligibleGuildRanksForWoWRank(wowRankIndex) or {}
    end
    self.EligibleGuildRanks = eligibleRanks

    local rankItems = {
        { label = "Select an eligible RPE Guild Rank", value = "" },
    }
    for index = 1, #eligibleRanks do
        local match = eligibleRanks[index]
        rankItems[#rankItems + 1] = {
            label = getRankLabel(match),
            value = tostring(match and match.ref or ""),
        }
    end
    if self.GuildRankDropdown then
        self.GuildRankDropdown:SetItems(rankItems)
        if not containsRankRef(eligibleRanks, self.SelectedGuildRankRef) then
            self.SelectedGuildRankRef = ""
        end
        self.GuildRankDropdown:SetSelectedValue(self.SelectedGuildRankRef, true)
    end

    local achievementItems = buildReferenceItems("achievements")
    local skillItems = buildReferenceItems("skills")
    local itemItems = buildReferenceItems("items")
    if self.AchievementDropdown then
        self.AchievementDropdown:SetItems(achievementItems)
        local achievementFound = false
        for index = 1, #achievementItems do
            if tostring(achievementItems[index].value or "") == tostring(self.SelectedAchievementRef or "") then
                achievementFound = true
                break
            end
        end
        if not achievementFound then
            self.SelectedAchievementRef = ""
        end
        self.AchievementDropdown:SetSelectedValue(self.SelectedAchievementRef, true)
    end
    if self.SkillDropdown then
        self.SkillDropdown:SetItems(skillItems)
        local skillFound = false
        for index = 1, #skillItems do
            if tostring(skillItems[index].value or "") == tostring(self.SelectedSkillRef or "") then
                skillFound = true
                break
            end
        end
        if not skillFound then
            self.SelectedSkillRef = ""
        end
        self.SkillDropdown:SetSelectedValue(self.SelectedSkillRef, true)
    end
    if self.ItemDropdown then
        self.ItemDropdown:SetItems(itemItems)
        local itemFound = false
        for index = 1, #itemItems do
            if tostring(itemItems[index].value or "") == tostring(self.SelectedItemRef or "") then
                itemFound = true
                break
            end
        end
        if not itemFound then
            self.SelectedItemRef = ""
        end
        self.ItemDropdown:SetSelectedValue(self.SelectedItemRef, true)
    end
    if self.AchievementStateText then
        self.AchievementStateText:SetText(
            self.SelectedAchievementRef == ""
                and "Earned: --"
                or (getSelectedAchievementState(self) and "Earned" or "Not earned")
        )
    end
    if self.SkillLevelText then
        self.SkillLevelText:SetText(
            self.SelectedSkillRef == ""
                and "Level: --"
                or ("Level: %d"):format(getSelectedSkillLevel(self))
        )
    end
    if self.AchievementDropdown then
        self.AchievementDropdown:SetEnabled(self.IsOfficer == true and selectedMember ~= nil and selectedMember.online == true)
    end

    if not identity.inGuild then
        self.StatusText:SetText("Admin access requires membership in a guild.")
    elseif isOfficer then
        self.StatusText:SetText(("Officer access detected for %s. Select an online member to administer RPE Guild Rank."):format(identity.guildName))
    else
        self.StatusText:SetText("Access denied: an officer rank is required for Guild administration.")
    end

    if selectedMember then
        self.RosterTitle:SetText(("Guild Roster | Selected: %s"):format(selectedMember.name))
    else
        self.RosterTitle:SetText("Guild Roster (select a member for Guild Admin)")
    end
    self.RosterList:SetItems(roster)
    self.RosterEmptyText:SetText(identity.inGuild and #roster == 0 and "No guild roster data is available yet." or "")

    local adminText
    if not selectedMember then
        adminText = "Select a guild member to query their RPE Guild Rank."
    else
        local wowRankName = tostring(selectedMember.rankName or "Unknown")
        local selectedLine = ("Selected: %s | WoW Guild Rank: %s"):format(selectedMember.name, wowRankName)
        if not isOfficer then
            adminText = selectedLine .. " | Officer access required."
        elseif selectedMember.online ~= true then
            adminText = selectedLine .. " | Offline; administration unavailable."
        else
            local rankState = "querying..."
            if self.SelectedMemberQueryPending then
                rankState = "query pending..."
            elseif self.SelectedMemberAdminState then
                if self.SelectedMemberAdminState.success == true then
                    local assignedRankRef = tostring(self.SelectedMemberAdminState.assignedRankRef or "")
                    rankState = assignedRankRef ~= "" and ("assigned: " .. assignedRankRef) or "not assigned"
                else
                    rankState = "query failed: " .. getAdminReason(self.SelectedMemberAdminState)
                end
            end

            local detailLine = ("RPE Guild Rank: %s | Eligible ranks: %d"):format(rankState, #eligibleRanks)
            if self.PendingAdminAction then
                detailLine = detailLine .. " | " .. self.AdminActionMessage
            elseif self.AdminActionMessage then
                detailLine = detailLine .. " | " .. self.AdminActionMessage
            end
            adminText = selectedLine .. "\n" .. detailLine
        end
    end
    self.AdminSectionsText:SetText(adminText)

    self:RefreshActionControls()

    if isOfficer and selectedMember and selectedMember.online == true
        and not self.SelectedMemberQueryPending and not self.SelectedMemberAdminState
        and not self.PendingAdminAction then
        local selectedKey = self.SelectedMemberKey
        local selectionGeneration = self.SelectionGeneration
        self.SelectedMemberQueryPending = true
        self:Refresh()
        if Guild and type(Guild.QueryGuildAdminMember) == "function" then
            Guild:QueryGuildAdminMember(selectedMember.name, function(response)
                if self.SelectedMemberKey ~= selectedKey or self.SelectionGeneration ~= selectionGeneration then
                    return
                end

                self.SelectedMemberQueryPending = false
                self.SelectedMemberAdminState = response or { success = false, reason = "no-response" }
                self.SelectedMemberProfileState = self.SelectedMemberAdminState.profileState
                    or { achievements = {}, skills = {} }
                if self.SelectedMemberAdminState.success == true then
                    self.SelectedGuildRankRef = tostring(self.SelectedMemberAdminState.assignedRankRef or "")
                else
                    self.SelectedGuildRankRef = ""
                end
                self:Refresh()
            end)
        else
            self.SelectedMemberQueryPending = false
            self.SelectedMemberAdminState = { success = false, reason = "incompatible-protocol" }
            self.SelectedMemberProfileState = { achievements = {}, skills = {} }
            self:Refresh()
        end
    end
    return self.frame
end

return AdminPage
