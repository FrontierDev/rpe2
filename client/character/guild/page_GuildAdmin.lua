local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Guild = Addon.Client.UI.Guild or {}

local Client = Addon.Client
local GuildUI = Addon.Client.UI.Guild
local UI = Addon.UI or {}
local Common = Addon.Utils and Addon.Utils.Common or {}

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

function AdminPage:Build(parent, owner)
    self.owner = owner
    if self.frame then
        return self.frame
    end

    self.SelectedMemberKey = nil
    self.SelectedMemberAdminState = nil
    self.SelectedMemberQueryPending = false
    self.PendingAdminAction = nil
    self.SelectedGuildRankRef = ""
    self.EligibleGuildRanks = {}
    self.AdminActionMessage = nil

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
                    self.SelectedMemberQueryPending = false
                    self.PendingAdminAction = nil
                    self.SelectedGuildRankRef = ""
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
        height = 112,
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
            return false
        end, {
            height = 20,
            fontSize = 8,
            enableMouse = false,
        })
        button:SetEnabled(false)
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

    self:Refresh()
    return self.frame
end

function AdminPage:RefreshActionControls()
    local selectedMember = self.SelectedMember
    local canAdminister = self.IsOfficer == true
        and selectedMember ~= nil
        and selectedMember.online == true
        and self.PendingAdminAction == nil
    local eligibleRanks = self.EligibleGuildRanks or {}
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

function AdminPage:SetSelectedGuildRank()
    local Guild = Client.Guild
    local selectedMember = self.SelectedMember
    local selectedRankRef = tostring(self.SelectedGuildRankRef or "")
    if not Guild or not selectedMember or selectedMember.online ~= true or self.IsOfficer ~= true
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
        self.SelectedMemberQueryPending = false
        self.PendingAdminAction = nil
        self.SelectedGuildRankRef = ""
        self.AdminActionMessage = nil
    elseif selectedMember and self.SelectedMemberWowRankIndex ~= nil and self.SelectedMemberWowRankIndex ~= wowRankIndex then
        self.SelectionGeneration = (tonumber(self.SelectionGeneration) or 0) + 1
        self.SelectedMemberAdminState = nil
        self.SelectedMemberQueryPending = false
        self.PendingAdminAction = nil
        self.SelectedGuildRankRef = ""
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
            self:Refresh()
        end
    end
    return self.frame
end

return AdminPage
