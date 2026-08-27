local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Profile = Addon.Client.UI.Profile or {}

local Client = Addon.Client
local ProfileUI = Addon.Client.UI.Profile
local UI = Addon.UI or {}
local Runtime = Addon.Internal and Addon.Internal.Runtime or {}

local function startTiming(label, thresholdMs, context)
    local timings = Addon.Debug and Addon.Debug.Timings or nil
    if timings and type(timings.Start) == "function" then
        if type(timings.IsEnabled) == "function" and not timings:IsEnabled() then
            return nil
        end
        return timings:Start(label, {
            thresholdMs = thresholdMs,
            context = context,
        })
    end
    return nil
end

local function stopTiming(timer, cardinality)
    if not timer then
        return
    end

    local timings = Addon.Debug and Addon.Debug.Timings or nil
    if timings and type(timings.Stop) == "function" then
        timings:Stop(timer, { cardinality = cardinality })
    end
end

local ProfileWindow = ProfileUI.Window or {}
ProfileUI.Window = ProfileWindow
ProfileWindow.__index = ProfileWindow

local WINDOW_CONTENT_INSET_X = 8
local WINDOW_CONTENT_INSET_TOP = 28
local WINDOW_CONTENT_INSET_BOTTOM = 8
local PAGE_PADDING_TOP = 2
local WINDOW_WIDTH = 524
local WINDOW_HEIGHT = 420

local function refreshPageOnShow(page, refreshFn)
    if not page or type(refreshFn) ~= "function" or not page.SetScript then
        return
    end

    page:SetScript("OnShow", function()
        refreshFn()
    end)
end

local function createInstance()
    return setmetatable({
        window = nil,
        SelectedSlotKey = nil,
        equipmentStatsPage = ProfileUI.EquipmentStatsPage,
        spellbookPage = ProfileUI.SpellbookPage,
        traitsPage = ProfileUI.TraitsPage,
        skillsPage = ProfileUI.SkillsPage,
        achievementsPage = ProfileUI.AchievementsPage,
        runtimeChangeListenerHandle = nil,
    }, ProfileWindow)
end

function ProfileWindow:Get()
    if not self._singleton then
        self._singleton = createInstance()
    end

    return self._singleton
end

function ProfileWindow:SetSelectedSlotKey(slotKey, skipRefresh)
    self.SelectedSlotKey = slotKey
    if self.equipmentStatsPage and self.equipmentStatsPage.MarkDirty then
        self.equipmentStatsPage:MarkDirty()
    end
    if not skipRefresh then
        self:Refresh()
    end
end

function ProfileWindow:IsVisible()
    local frame = self.window and self.window.GetFrame and self.window:GetFrame() or nil
    return frame and frame.IsShown and frame:IsShown() == true or false
end

function ProfileWindow:GetActiveTabKey()
    local activeTab = self.window and self.window.GetActiveTab and self.window:GetActiveTab() or nil
    return tostring(activeTab and activeTab.name or "equipment")
end

function ProfileWindow:GetTabIndex(tabKey)
    local normalizedKey = tostring(tabKey or "equipment")
    local tabs = self.window and self.window.GetTabs and self.window:GetTabs() or nil
    for index = 1, #(tabs or {}) do
        local tab = tabs[index]
        if tostring(tab and tab.name or "") == normalizedKey then
            return index
        end
    end

    return 1
end

function ProfileWindow:RefreshTab(tabKey)
    local normalizedKey = tostring(tabKey or "equipment")
    local page = nil
    if normalizedKey == "equipment" then
        page = self.equipmentStatsPage
    elseif normalizedKey == "spellbook" then
        page = self.spellbookPage
    elseif normalizedKey == "traits" then
        page = self.traitsPage
    elseif normalizedKey == "skills" then
        page = self.skillsPage
    elseif normalizedKey == "achievements" then
        page = self.achievementsPage
    end

    if page then
        if page.RefreshIfDirty then
            page:RefreshIfDirty()
        elseif page.Refresh then
            page:Refresh()
        end
    end
end

function ProfileWindow:MarkPagesDirty()
    local pages = {
        self.equipmentStatsPage,
        self.spellbookPage,
        self.traitsPage,
        self.skillsPage,
        self.achievementsPage,
    }
    for index = 1, #pages do
        local page = pages[index]
        if page and page.MarkDirty then
            page:MarkDirty()
        end
    end
end

function ProfileWindow:HandleRuntimeChange(changeSet)
    if type(changeSet) ~= "table" then
        return
    end

    local profileChanges = changeSet.profile
    local revisionChanges = changeSet.revisions
    local equipmentRuntimeChanged = (type(profileChanges) == "table" and profileChanges.equipment == true)
        or (type(revisionChanges) == "table" and revisionChanges.EquipmentRevision ~= nil)
    local equipmentChanged = (type(profileChanges) == "table"
        and (profileChanges.equipment == true or profileChanges.stats == true or profileChanges.resources == true))
        or (type(revisionChanges) == "table"
        and (revisionChanges.EquipmentRevision ~= nil
            or revisionChanges.ProfileStatsRevision ~= nil
            or revisionChanges.ProfileResourcesRevision ~= nil
            or revisionChanges.ResolvedProfileRevision ~= nil))
    local skillsChanged = (type(profileChanges) == "table" and profileChanges.skills ~= nil)
        or (type(revisionChanges) == "table" and revisionChanges.SkillRevision ~= nil)
    local achievementsChanged = (type(changeSet.achievements) == "table")
        or (type(revisionChanges) == "table" and revisionChanges.AchievementRevision ~= nil)
    local spellbookChanged = type(revisionChanges) == "table"
        and revisionChanges.ActionBarBindingRevision ~= nil
    local traitsChanged = type(changeSet.inventory) == "table"
        or (type(profileChanges) == "table" and profileChanges.equipment == true)
        or (type(revisionChanges) == "table"
        and (revisionChanges.InventoryRevision ~= nil
            or revisionChanges.EquipmentRevision ~= nil))

    if equipmentRuntimeChanged and type(Client.HandleProfileEquipmentRuntimeChange) == "function" then
        Client:HandleProfileEquipmentRuntimeChange(changeSet)
    end

    if equipmentChanged and self.equipmentStatsPage and self.equipmentStatsPage.MarkDirty then
        self.equipmentStatsPage:MarkDirty()
    end
    if skillsChanged and self.skillsPage and self.skillsPage.MarkDirty then
        self.skillsPage:MarkDirty()
    end
    if achievementsChanged and self.achievementsPage and self.achievementsPage.MarkDirty then
        self.achievementsPage:MarkDirty()
    end
    if spellbookChanged and self.spellbookPage and self.spellbookPage.MarkDirty then
        self.spellbookPage:MarkDirty()
    end
    if traitsChanged and self.traitsPage and self.traitsPage.MarkDirty then
        self.traitsPage:MarkDirty()
    end

    if not self:IsVisible() then
        return
    end

    local activeTabKey = self:GetActiveTabKey()
    if (activeTabKey == "equipment" and equipmentChanged)
        or (activeTabKey == "skills" and skillsChanged)
        or (activeTabKey == "achievements" and achievementsChanged)
        or (activeTabKey == "spellbook" and spellbookChanged)
        or (activeTabKey == "traits" and traitsChanged)
    then
        self:RefreshTab(activeTabKey)
    end
end

function ProfileWindow:EnsureChangeListeners()
    if self.runtimeChangeListenerHandle
        or type(Runtime) ~= "table"
        or type(Runtime.RegisterPostCommitListener) ~= "function"
    then
        return
    end

    self.runtimeChangeListenerHandle = Runtime:RegisterPostCommitListener(function(changeSet)
        self:HandleRuntimeChange(changeSet)
    end)
end

function ProfileWindow:RefreshVisible()
    if self:IsVisible() then
        self:Refresh()
    end

    return self.window
end

function ProfileWindow:BuildWindow()
    if self.window then
        self:EnsureChangeListeners()
        local frame = self.window.GetFrame and self.window:GetFrame() or nil
        if frame and frame.SetSize then
            frame:SetSize(WINDOW_WIDTH, WINDOW_HEIGHT)
        end
        if self.equipmentStatsPage and self.equipmentStatsPage.ApplyMetrics then
            self.equipmentStatsPage:ApplyMetrics()
        end
        return self.window
    end

    self.window = UI.Window:New({
        name = "RPEProfileWindow",
        width = WINDOW_WIDTH,
        height = WINDOW_HEIGHT,
        point = "CENTER",
        relativeTo = UIParent,
        relativePoint = "CENTER",
        frameStrata = "HIGH",
        frameLevel = 25,
        movable = true,
        clampedToScreen = true,
        toplevel = true,
        hidden = true,
        contentInsetLeft = WINDOW_CONTENT_INSET_X,
        contentInsetRight = WINDOW_CONTENT_INSET_X,
        contentInsetTop = WINDOW_CONTENT_INSET_TOP,
        contentInsetBottom = WINDOW_CONTENT_INSET_BOTTOM,
        pagePaddingTop = PAGE_PADDING_TOP,
        tabs = {
            {
                name = "equipment",
                label = "Equipment & Stats",
                width = 118,
                builder = function(page)
                    self.equipmentStatsPage:Build(page, self)
                    refreshPageOnShow(page, function()
                        self:RefreshTab("equipment")
                    end)
                end,
            },
            {
                name = "spellbook",
                label = "Spellbook",
                width = 70,
                builder = function(page)
                    self.spellbookPage:Build(page, self)
                    refreshPageOnShow(page, function()
                        self:RefreshTab("spellbook")
                    end)
                end,
            },
            {
                name = "traits",
                label = "Traits",
                width = 60,
                builder = function(page)
                    self.traitsPage:Build(page, self)
                    refreshPageOnShow(page, function()
                        self:RefreshTab("traits")
                    end)
                end,
            },
            {
                name = "skills",
                label = "Skills",
                width = 60,
                builder = function(page)
                    self.skillsPage:Build(page, self)
                    refreshPageOnShow(page, function()
                        self:RefreshTab("skills")
                    end)
                end,
            },
            {
                name = "achievements",
                label = "Achievements",
                width = 96,
                builder = function(page)
                    self.achievementsPage:Build(page, self)
                    refreshPageOnShow(page, function()
                        self:RefreshTab("achievements")
                    end)
                end,
            },
        },
    })
    self.window:SetTitle("Character")
    self.window:Create()
    local frame = self.window.GetFrame and self.window:GetFrame() or nil
    if frame and frame.SetSize then
        frame:SetSize(WINDOW_WIDTH, WINDOW_HEIGHT)
    end
    self:EnsureChangeListeners()

    return self.window
end

function ProfileWindow:Refresh()
    if not self:IsVisible() then
        self:MarkPagesDirty()
        return self.window
    end

    local timer = startTiming("ProfileWindow:Refresh", 8, "profile")
    self:RefreshTab(self:GetActiveTabKey())
    if timer then
        stopTiming(timer, {
            activeTab = self:GetActiveTabKey() or "profile",
            activePage = 1,
        })
    end

    return self.window
end

function ProfileWindow:ShowTab(tabKey)
    local window = self:BuildWindow()
    local tabIndex = self:GetTabIndex(tabKey)
    if window and window.SetActiveTab then
        window:SetActiveTab(tabIndex)
    end
    if window and window.Show then
        window:Show()
    end
    self:RefreshTab(self:GetActiveTabKey())
    return window
end

function ProfileWindow:Show()
    local timer = startTiming("ProfileWindow:Show", 8, "profile")
    local window = self:BuildWindow()
    if window and window.Show then
        window:Show()
    end
    self:Refresh()
    if timer then
        local activeTab = self:GetActiveTabKey() or "profile"
        stopTiming(timer, {
            activeTab = activeTab,
            profilePages = 4,
        })
    end
    return window
end

function ProfileWindow:Hide()
    if Client.Crafting and Client.Crafting.HandleProfileWindowClosed then
        Client.Crafting:HandleProfileWindowClosed()
    end
    if self.window and self.window.Hide then
        self.window:Hide()
    end
    return self.window
end

function Client:BuildProfileWindow()
    return ProfileWindow:Get():BuildWindow()
end

function Client:ShowProfileWindow()
    return ProfileWindow:Get():Show()
end

function Client:ShowProfileWindowTab(tabKey)
    return ProfileWindow:Get():ShowTab(tabKey)
end

function Client:HideProfileWindow()
    return ProfileWindow:Get():Hide()
end

return ProfileWindow
