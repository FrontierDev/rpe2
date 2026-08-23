local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Guild = Addon.Client.UI.Guild or {}

local Client = Addon.Client
local GuildUI = Addon.Client.UI.Guild
local UI = Addon.UI or {}

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

function AdminPage:Build(parent, owner)
    self.owner = owner
    if self.frame then
        return self.frame
    end

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

    self.RosterTitle = UI.CreateText(self.RosterPanel:GetContentFrame(), "RPEGuildRosterTitle", "Guild Roster (select a member for read-only details)", {
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
        height = 92,
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
        local button = UI.CreateButton(self.AdminSectionsLayout:GetFrame(), "RPEGuildAdminPlanned" .. section .. "Button", section, 116, function()
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
    self.AdminSectionsText = UI.CreateText(self.AdminSectionsPanel:GetContentFrame(), "RPEGuildAdminSectionsText", "", {
        width = 512,
        height = 62,
        justifyH = "LEFT",
        wordWrap = true,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.AdminSectionsText:GetFrame():SetPoint("TOPLEFT", self.AdminSectionsPanel:GetContentFrame(), "TOPLEFT", 2, -2)

    self:Refresh()
    return self.frame
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

    if not identity.inGuild then
        self.StatusText:SetText("Admin access requires membership in a guild.")
    elseif isOfficer then
        self.StatusText:SetText(("Officer access detected for %s. Roster data is read-only in Phase 1."):format(identity.guildName))
    else
        self.StatusText:SetText("Access denied: an officer rank is required for Guild administration.")
    end

    if selectedMember then
        self.RosterTitle:SetText(("Guild Roster | Selected: %s"):format(selectedMember.name))
    else
        self.RosterTitle:SetText("Guild Roster (select a member for read-only details)")
    end
    self.RosterList:SetItems(roster)
    self.RosterEmptyText:SetText(identity.inGuild and #roster == 0 and "No guild roster data is available yet." or "")

    if isOfficer then
        self.AdminSectionsText:SetText("Planned officer sections (disabled in Phase 1):\nAchievements\nSkills\nItems")
    else
        self.AdminSectionsText:SetText("Admin controls are unavailable.\nAchievements, Skills, and Items require officer access in a later phase.")
    end
    return self.frame
end

return AdminPage
