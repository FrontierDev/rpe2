local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Guild = Addon.Client.UI.Guild or {}

local GuildUI = Addon.Client.UI.Guild
local Client = Addon.Client
local UI = Addon.UI or {}

local Page = GuildUI.AdminPage
if not Page then return end

local OldBuild = Page.Build
local OldRefresh = Page.Refresh
local OldRefreshActionControls = Page.RefreshActionControls

local function trim(value)
    return tostring(value or ""):match("^%s*(.-)%s*$") or ""
end

local function roleMapsRank(role, rankIndex)
    local target = tonumber(rankIndex)
    if target == nil then return false end
    for index = 1, #(role and role.wowGuildRankIndices or {}) do
        if tonumber(role.wowGuildRankIndices[index]) == target then return true end
    end
    return false
end

local function manualSet(state)
    local result = {}
    for index = 1, #(state and state.manualRoleIds or {}) do
        local roleId = trim(state.manualRoleIds[index])
        if roleId ~= "" then result[roleId] = true end
    end
    return result
end

local function buildRoleRows(setting, state, member)
    local rows = {}
    local assigned = manualSet(state)
    local rankIndex = tonumber(state and state.guildRankIndex)
    if rankIndex == nil then rankIndex = tonumber(member and member.rankIndex) end
    for index = 1, #(setting and setting.roles or {}) do
        local role = setting.roles[index]
        local roleId = trim(role and role.id)
        if roleId ~= "" then
            local manual = assigned[roleId] == true
            local mapped = roleMapsRank(role, rankIndex)
            local source = manual and mapped and "Manual + WoW Rank"
                or (manual and "Manual" or (mapped and "WoW Rank" or "—"))
            local action = manual and "Remove Manual" or (mapped and "Mapped" or "Assign")
            rows[#rows + 1] = {
                role = role,
                roleId = roleId,
                name = trim(role.name) ~= "" and trim(role.name) or roleId,
                manual = manual,
                mapped = mapped,
                effective = manual or mapped,
                source = source,
                action = action,
                actionable = manual or not mapped,
            }
        end
    end
    return rows
end

local function rowCanMutate(page, row)
    local state = page.SelectedMemberAdminState
    local member = page.SelectedMember
    return row and row.actionable == true
        and page.IsOfficer == true
        and member ~= nil
        and member.online == true
        and page.SelectedMemberQueryPending ~= true
        and page.PendingAdminAction == nil
        and type(state) == "table"
        and state.success == true
        and trim(state.activeSettingRef) ~= ""
end

function Page:GetRoleAdminSetting()
    local Guild = Client.Guild
    if not Guild or type(Guild.GetActiveGuildSetting) ~= "function" then return nil, nil end
    local ok, setting, resolution = pcall(Guild.GetActiveGuildSetting, Guild)
    if not ok then return nil, nil end
    return setting, resolution
end

function Page:BuildRoleAdminPanel()
    if self.RoleAdminPanel or not self.AdminControlsLayout then return end
    if self.GuildRankControlsLayout then
        self.GuildRankControlsLayout.options.height = 0
        local frame = self.GuildRankControlsLayout:GetFrame()
        if frame then frame:SetHeight(0); frame:Hide() end
    end
    self.GuildRankDropdown = nil
    self.SetGuildRankButton = nil
    self.ClearGuildRankButton = nil

    self.RoleAdminPanel = UI.CreatePanel(self.AdminControlsLayout:GetFrame(), "RPEGuildAdminRolePanel", {
        width = 512, height = 78, expandWidth = true, contentInset = 0,
        showBorder = false, panelBackgroundColor = { r = 0, g = 0, b = 0, a = 0 },
    })
    self.AdminControlsLayout:AddChild(self.RoleAdminPanel)
    self.RoleAdminLayout = UI.CreateLayout(UI.VerticalLayoutGroup, self.RoleAdminPanel:GetContentFrame(), "RPEGuildAdminRoleLayout", {
        spacing = 2, fitChildrenWidth = true, fitChildrenHeight = true,
    })
    UI.Utils.AnchorFill(self.RoleAdminLayout, self.RoleAdminPanel:GetContentFrame(), 0, 0, 0, 0)
    self.RoleAdminTitle = UI.CreateText(self.RoleAdminLayout:GetFrame(), "RPEGuildAdminRoleTitle", "Roles", {
        width = 512, height = 14, expandWidth = true, justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.primary"),
    })
    self.RoleAdminLayout:AddChild(self.RoleAdminTitle)
    self.RoleAdminList = UI.ScrollLayout:New({
        name = "RPEGuildAdminRoleList", width = 512, height = 60, visibleRows = 3,
        rowHeight = 18, rowSpacing = 1, autoFitRows = true, minVisibleRows = 1,
        expandWidth = true, expandHeight = true, border = false, rowElementClass = UI.ScrollListEntry,
        categoryWidth = 150, statusWidth = 92, categoryInsetLeft = 4, statusInsetRight = 4,
    })
    self.RoleAdminList:SetParent(self.RoleAdminLayout:GetFrame())
    self.RoleAdminList:SetRowRenderer(function(row, roleRow)
        row:SetCategory(roleRow and roleRow.name or "")
        row:SetTestName("")
        row:SetDetail(roleRow and ((roleRow.source or "—") .. (roleRow.effective and " | Effective" or "")) or "")
        row:SetStatus(roleRow and roleRow.action or "")
        local frame = row.GetFrame and row:GetFrame() or nil
        if frame then
            local enabled = rowCanMutate(self, roleRow)
            frame:EnableMouse(enabled)
            if frame.SetAlpha then frame:SetAlpha((roleRow and roleRow.action == "Mapped") and 0.65 or 1) end
            frame:SetScript("OnMouseUp", function(_, button)
                if button == "LeftButton" and rowCanMutate(self, roleRow) then self:MutateSelectedMemberRole(roleRow) end
            end)
        end
    end)
    self.RoleAdminList:Create()
    self.RoleAdminLayout:AddChild(self.RoleAdminList)
    self.AdminControlsLayout:RefreshLayout()
end

function Page:MutateSelectedMemberRole(roleRow)
    if not rowCanMutate(self, roleRow) then return false end
    local Guild = Client.Guild
    local member = self.SelectedMember
    local state = self.SelectedMemberAdminState
    local settingRef = trim(state.activeSettingRef)
    local roleId = trim(roleRow.roleId)
    local selectedKey = self.SelectedMemberKey
    local generation = self.SelectionGeneration
    local operation = roleRow.manual and "remove_guild_role" or "assign_guild_role"
    self.PendingAdminAction = operation .. ":" .. roleId
    self.AdminActionMessage = roleRow.manual and ("Removing %s..."):format(roleRow.name) or ("Assigning %s..."):format(roleRow.name)
    self:Refresh()

    local function finish(response)
        if self.SelectedMemberKey ~= selectedKey or self.SelectionGeneration ~= generation then return end
        self.PendingAdminAction = nil
        local normalized = response or { success = false, reason = "unknown-error" }
        if normalized.success == true then
            self.AdminActionMessage = roleRow.manual
                and ("Role removal acknowledged: %s"):format(roleRow.name)
                or ("Role assignment acknowledged: %s"):format(roleRow.name)
            self.SelectedMemberAdminState = nil
            self.SelectedMemberProfileState = { achievements = {}, skills = {} }
            self.SelectedMemberQueryPending = false
        else
            self.AdminActionMessage = ("Role change failed: %s"):format(tostring(normalized.reason or "unknown-error"))
        end
        self:Refresh()
    end

    local sender = roleRow.manual and Guild and Guild.RemoveGuildRoleForMember or Guild and Guild.AssignGuildRoleForMember
    if type(sender) ~= "function" then finish({ success = false, reason = "incompatible-protocol" }); return false end
    return sender(Guild, member.name, settingRef, roleId, finish) == true
end

function Page:RefreshRoleAdminPanel()
    if not self.RoleAdminList then return end
    local setting, resolution = self:GetRoleAdminSetting()
    local state = self.SelectedMemberAdminState
    local member = self.SelectedMember
    local rows = {}
    if setting and resolution and resolution.status == "active" and state and state.success == true
        and trim(state.activeSettingRef) == trim(resolution.ref) then
        rows = buildRoleRows(setting, state, member)
    end
    self.RoleAdminRows = rows
    self.RoleAdminList:SetItems(rows)
end

function Page:Build(parent, owner)
    local frame = OldBuild(self, parent, owner)
    self:BuildRoleAdminPanel()
    self:RefreshRoleAdminPanel()
    return frame
end

function Page:RefreshActionControls()
    OldRefreshActionControls(self)
    self:RefreshRoleAdminPanel()
end

function Page:Refresh()
    local frame = OldRefresh(self)
    if not self.frame then return frame end
    self:RefreshRoleAdminPanel()

    local identity = Client.Guild and Client.Guild:GetLocalGuildIdentity() or { inGuild = false }
    local member = self.SelectedMember
    local state = self.SelectedMemberAdminState
    local text
    if not identity.inGuild then
        text = "Admin access requires membership in a guild."
    elseif self.IsOfficer ~= true then
        if member then
            text = ("Selected: %s | WoW Guild Rank: %s | Officer access required."):format(member.name, tostring(member.rankName or "Unknown"))
        else
            text = "Access denied: an officer rank is required for Guild administration."
        end
    elseif not member then
        text = ""
    elseif member.online ~= true then
        text = ("Selected: %s | WoW Guild Rank: %s | Offline; administration unavailable."):format(member.name, tostring(member.rankName or "Unknown"))
    else
        local selectedLine = ("Selected: %s | WoW Guild Rank: %s"):format(member.name, tostring(member.rankName or "Unknown"))
        local roleState = self.SelectedMemberQueryPending and "Roles: querying..." or "Roles: unavailable"
        if state then
            if state.success == true then
                roleState = ("Roles: %d manual"):format(#(state.manualRoleIds or {}))
            else
                roleState = "Roles query failed: " .. tostring(state.reason or "unknown-error")
            end
        end
        if self.AdminActionMessage then roleState = roleState .. " | " .. self.AdminActionMessage end
        text = selectedLine .. "\n" .. roleState
    end
    if self.AdminSectionsText then self.AdminSectionsText:SetText(text) end
    return frame
end

return Page
