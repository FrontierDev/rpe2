local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Guild = Addon.Client.UI.Guild or {}

local GuildUI = Addon.Client.UI.Guild
local Client = Addon.Client
local UI = Addon.UI or {}
local Registry = Addon.Internal and Addon.Internal.Registry or {}

local Page = GuildUI.RequisitionsPage
if not Page then return end

local OldBuild = Page.Build
local OldBindShopEntry = Page.BindShopEntry

local SHOP_COLUMNS = 2
local SHOP_ENTRY_HEIGHT = 34
local SHOP_GRID_SPACING_X = 6
local SHOP_GRID_SPACING_Y = 4
local SHOP_PAGE_NAV_HEIGHT = 18
local SHOP_PAGE_BUTTON_WIDTH = 22
local SHOP_PAGE_TEXT_WIDTH = 96
local SHOP_PAGE_NAV_SPACING = 4
local SHOP_PAGINATION_WIDTH = (SHOP_PAGE_BUTTON_WIDTH * 2) + SHOP_PAGE_TEXT_WIDTH + (SHOP_PAGE_NAV_SPACING * 2)
local CATEGORY_NAV_HEIGHT = 20
local CATEGORY_BUTTON_WIDTH = 72
local CATEGORY_OVERFLOW_WIDTH = 112
local CATEGORY_NAV_SPACING = 4
local MAX_VISIBLE_CATEGORY_BUTTONS = 5
local TOOLBAR_HEIGHT = 22
local AVAILABILITY_ITEMS = {
    { label = "All Items", value = "all" },
    { label = "Available", value = "available" },
    { label = "Unavailable", value = "unavailable" },
}

local function trim(value)
    return tostring(value or ""):match("^%s*(.-)%s*$") or ""
end

local function normalizeCharacterLimit(value)
    local numeric = tonumber(value)
    if not numeric or numeric ~= numeric or numeric == math.huge or numeric == -math.huge then return 1 end
    if numeric == 0 then return 0 end
    return math.max(1, math.floor(numeric))
end

local function resolveItemName(requisition)
    local reference = trim(requisition and requisition.itemRef)
    if type(Registry.ResolveItemReference) == "function" then
        local ok, _, item = pcall(Registry.ResolveItemReference, Registry, reference)
        if ok and type(item) == "table" then
            local name = trim(item.name)
            if name ~= "" then return name end
        end
    end
    if type(Registry.ResolveItemName) == "function" then
        local ok, name = pcall(Registry.ResolveItemName, Registry, reference)
        if ok and trim(name) ~= "" then return trim(name) end
    end
    return reference ~= "" and reference or "Unknown item"
end

local function roleLabel(setting, roleId)
    local wanted = trim(roleId)
    for index = 1, #(setting and setting.roles or {}) do
        local role = setting.roles[index]
        if trim(role and role.id) == wanted then
            local name = trim(role and role.name)
            return name ~= "" and name or wanted
        end
    end
    return wanted ~= "" and wanted or "Unknown Role"
end

local function appendRoleRequirement(tooltip, setting, requisition, reason)
    if reason ~= "missing-required-role" then return tooltip end
    local roleIds = type(requisition and requisition.roleIds) == "table" and requisition.roleIds or {}
    if #roleIds == 0 then return tooltip end

    local names = {}
    for index = 1, #roleIds do names[#names + 1] = roleLabel(setting, roleIds[index]) end
    local line = #names == 1
        and ("Requires Role: %s"):format(names[1])
        or ("Requires one of: %s"):format(table.concat(names, ", "))

    local spec = tooltip
    if type(spec) == "function" then spec = spec() end
    if type(spec) ~= "table" then
        spec = { type = "custom", title = resolveItemName(requisition), lines = {} }
    end
    spec.lines = type(spec.lines) == "table" and spec.lines or {}
    spec.lines[#spec.lines + 1] = { left = line, colorToken = "danger" }
    return spec
end

local function buildRolesTooltip(roles)
    local lines = {}
    for index = 1, #(roles or {}) do
        lines[#lines + 1] = { left = roles[index].name or roles[index].roleId, colorToken = "text.secondary" }
    end
    if #lines == 0 then lines[1] = { left = "No effective Roles", colorToken = "text.secondary" } end
    return { type = "custom", title = "Effective Roles", lines = lines }
end

local function setFrameShown(element, shown)
    local frame = element and element.GetFrame and element:GetFrame() or nil
    if not frame then return end
    if shown and frame.Show then frame:Show() elseif not shown and frame.Hide then frame:Hide() end
end

local function setCategoryButtonState(button, category, selected)
    if not button then return end
    local name = category and category.name or ""
    button:SetText(selected and ("[ %s ]"):format(name) or name)
    local color = UI.ResolveColor(nil, selected and "text.primary" or "text.secondary")
    if button.SetLabelColor and color then
        button:SetLabelColor(color.r or 1, color.g or 1, color.b or 1, color.a or 1)
    end
end

function Page:GetActiveSettingContext()
    local Guild = Client.Guild
    if not Guild or type(Guild.GetActiveGuildSetting) ~= "function" then return nil, { status = "unavailable" } end
    local ok, setting, resolution = pcall(Guild.GetActiveGuildSetting, Guild)
    if not ok then return nil, { status = "unavailable", reason = "setting-unavailable" } end
    return setting, type(resolution) == "table" and resolution or { status = setting and "active" or "unavailable" }
end

function Page:PartitionRequisitions()
    local shopRows, limitedRows = {}, {}
    local setting = self.ActiveGuildSetting
    if type(setting) ~= "table" then setting = select(1, self:GetActiveSettingContext()) end
    for index = 1, #(setting and setting.requisitions or {}) do
        local requisition = setting.requisitions[index]
        if type(requisition) == "table" then
            if normalizeCharacterLimit(requisition.characterLimit) == 0 then shopRows[#shopRows + 1] = requisition
            else limitedRows[#limitedRows + 1] = requisition end
        end
    end
    return shopRows, limitedRows
end

function Page:GetShopEligibility(requisition)
    local Guild = Client.Guild
    local resolution = self.ActiveGuildResolution
    if not Guild or type(Guild.GetRequisitionEligibility) ~= "function" or not resolution or resolution.status ~= "active" then
        return false, "eligibility-unavailable"
    end
    local ok, eligible, reason, detail = pcall(Guild.GetRequisitionEligibility, Guild, resolution.ref, requisition and requisition.id)
    if not ok then return false, "eligibility-failed" end
    return eligible == true, reason, detail
end

function Page:TryShopRequisition(entry)
    local requisition = entry and entry.resolvedRequisition or nil
    local Guild = Client.Guild
    local resolution = self.ActiveGuildResolution
    if not requisition or not Guild or type(Guild.TryRequisition) ~= "function" or not resolution or resolution.status ~= "active" then
        return false, "requisition-unavailable"
    end
    local ok, success, reason, detail = pcall(Guild.TryRequisition, Guild, resolution.ref, requisition.id)
    self:Refresh()
    if not ok then return false, "transaction-failed" end
    return success, reason, detail
end

function Page:BindShopEntry(entry, requisition)
    OldBindShopEntry(self, entry, requisition)
    if entry.resolvedEligibilityReason == "missing-required-role" then
        local previous = entry:GetTooltip()
        entry:SetTooltip(function()
            local spec = type(previous) == "function" and previous() or previous
            return appendRoleRequirement(spec, self.ActiveGuildSetting, requisition, entry.resolvedEligibilityReason)
        end)
    end
end

function Page:BuildShopCategoryRows(baseRows)
    local setting = self.ActiveGuildSetting
    local configured, known = {}, {}
    for index = 1, #(setting and setting.shopCategories or {}) do
        local category = setting.shopCategories[index]
        local id = trim(category and category.id)
        if id ~= "" and not known[id] then
            known[id] = true
            configured[#configured + 1] = category
        end
    end
    table.sort(configured, function(left, right)
        local lo, ro = math.floor(tonumber(left and left.order) or 0), math.floor(tonumber(right and right.order) or 0)
        if lo ~= ro then return lo < ro end
        local ln = string.lower(trim(left and left.name) ~= "" and trim(left.name) or trim(left and left.id))
        local rn = string.lower(trim(right and right.name) ~= "" and trim(right.name) or trim(right and right.id))
        if ln ~= rn then return ln < rn end
        return trim(left and left.id) < trim(right and right.id)
    end)

    local rows = { { id = "__all", name = "All", kind = "all" } }
    for index = 1, #configured do
        local category = configured[index]
        rows[#rows + 1] = {
            id = trim(category.id),
            name = trim(category.name) ~= "" and trim(category.name) or trim(category.id),
            kind = "category",
        }
    end
    local hasOther = false
    for index = 1, #(baseRows or {}) do
        local categoryId = trim(baseRows[index].requisition and baseRows[index].requisition.shopCategoryId)
        if categoryId == "" or not known[categoryId] then hasOther = true break end
    end
    if hasOther then rows[#rows + 1] = { id = "__other", name = "Other", kind = "other" } end
    return rows, known
end

function Page:BuildResolvedShopRows(requisitions)
    local rows = {}
    for index = 1, #(requisitions or {}) do
        local requisition = requisitions[index]
        local eligible, reason, detail = self:GetShopEligibility(requisition)
        local name = resolveItemName(requisition)
        rows[#rows + 1] = {
            requisition = requisition,
            name = name,
            searchName = string.lower(name),
            eligible = eligible,
            reason = reason,
            detail = detail,
            authoredIndex = index,
        }
    end
    return rows
end

function Page:ApplyShopFilters(resetPage)
    local filtered = {}
    local selectedCategory = self.SelectedShopCategory or "__all"
    local search = string.lower(trim(self.ShopSearchText or ""))
    local availability = self.ShopAvailabilityFilter or "all"
    local knownCategories = self.KnownShopCategoryIds or {}

    for index = 1, #(self.ShopBaseRows or {}) do
        local row = self.ShopBaseRows[index]
        local requisition = row.requisition
        local categoryId = trim(requisition and requisition.shopCategoryId)
        local categoryMatch = selectedCategory == "__all"
            or (selectedCategory == "__other" and (categoryId == "" or not knownCategories[categoryId]))
            or categoryId == selectedCategory
        local searchMatch = search == "" or string.find(row.searchName or "", search, 1, true) ~= nil
        local availabilityMatch = availability == "all"
            or (availability == "available" and row.eligible == true)
            or (availability == "unavailable" and row.eligible ~= true)
        if categoryMatch and searchMatch and availabilityMatch then filtered[#filtered + 1] = requisition end
    end

    self.ShopItems = filtered
    if resetPage then self.CurrentShopPage = 1 end
    self:RefreshShopEntries()
end

function Page:RefreshCategoryList()
    local rows = self.ShopCategoryRows or {}
    local selected = self.SelectedShopCategory or "__all"
    local buttons = self.ShopCategoryButtons or {}
    for index = 1, MAX_VISIBLE_CATEGORY_BUTTONS do
        local button = buttons[index]
        local category = rows[index]
        if button and category then
            button._categoryId = category.id
            setCategoryButtonState(button, category, category.id == selected)
            setFrameShown(button, true)
        elseif button then
            button._categoryId = nil
            setFrameShown(button, false)
        end
    end

    local overflowItems = { { label = "More...", value = "" } }
    local selectedOverflow = ""
    for index = MAX_VISIBLE_CATEGORY_BUTTONS + 1, #rows do
        local category = rows[index]
        overflowItems[#overflowItems + 1] = { label = category.name, value = category.id }
        if category.id == selected then selectedOverflow = category.id end
    end
    if self.ShopCategoryOverflowDropdown then
        local hasOverflow = #overflowItems > 1
        self._refreshingShopCategoryOverflow = true
        self.ShopCategoryOverflowDropdown:SetItems(overflowItems)
        self.ShopCategoryOverflowDropdown:SetSelectedValue(selectedOverflow, true)
        self._refreshingShopCategoryOverflow = false
        setFrameShown(self.ShopCategoryOverflowDropdown, hasOverflow)
    end
end

function Page:SelectShopCategory(categoryId)
    self.SelectedShopCategory = categoryId or "__all"
    self:RefreshCategoryList()
    self:ApplyShopFilters(true)
end

function Page:BuildShopBrowser()
    if not self.GuildShopHost or self.ShopBrowserBuilt then return end
    self.ShopBrowserBuilt = true
    if self.ShopLayout and self.ShopLayout.Hide then self.ShopLayout:Hide() end
    if self.GuildShopHeader then setFrameShown(self.GuildShopHeader, false) end

    self.ShopBrowseLayout = UI.CreateLayout(UI.VerticalLayoutGroup, self.GuildShopHost:GetFrame(), "RPEGuildShopBrowseLayout", {
        expandWidth = true, expandHeight = true, weight = 1, spacing = 4,
        fitChildrenWidth = true, fitChildrenHeight = true,
    })
    self.GuildShopHost:AddChild(self.ShopBrowseLayout)

    self.ShopCategoryNav = UI.CreateLayout(UI.HorizontalLayoutGroup, self.ShopBrowseLayout:GetFrame(), "RPEGuildShopCategoryNav", {
        height = CATEGORY_NAV_HEIGHT, expandWidth = true, spacing = CATEGORY_NAV_SPACING,
        fitChildrenWidth = true, fitChildrenHeight = false,
    })
    self.ShopBrowseLayout:AddChild(self.ShopCategoryNav)
    self.ShopCategoryButtons = {}
    for index = 1, MAX_VISIBLE_CATEGORY_BUTTONS do
        local button
        button = UI.CreateButton(self.ShopCategoryNav:GetFrame(), "RPEGuildShopCategoryButton" .. index, "", CATEGORY_BUTTON_WIDTH, function()
            local categoryId = button and button._categoryId or nil
            if categoryId then self:SelectShopCategory(categoryId) end
        end, { height = CATEGORY_NAV_HEIGHT, fontSize = 8 })
        self.ShopCategoryButtons[index] = button
        self.ShopCategoryNav:AddChild(button)
    end
    self.ShopCategoryOverflowDropdown = UI.CreateDropdown(self.ShopCategoryNav:GetFrame(), "RPEGuildShopCategoryOverflowDropdown", {
        width = CATEGORY_OVERFLOW_WIDTH, height = CATEGORY_NAV_HEIGHT,
        items = { { label = "More...", value = "" } }, selectedValue = "",
        onValueChanged = function(value)
            if self._refreshingShopCategoryOverflow or not value or value == "" then return end
            self:SelectShopCategory(value)
        end,
    })
    self.ShopCategoryNav:AddChild(self.ShopCategoryOverflowDropdown)
    setFrameShown(self.ShopCategoryOverflowDropdown, false)

    self.ShopToolbar = UI.CreateLayout(UI.HorizontalLayoutGroup, self.ShopBrowseLayout:GetFrame(), "RPEGuildShopToolbar", {
        height = TOOLBAR_HEIGHT, expandWidth = true, spacing = 4, fitChildrenWidth = true, fitChildrenHeight = false,
    })
    self.ShopBrowseLayout:AddChild(self.ShopToolbar)
    self.ShopSearchInput = UI.CreateTextInput(self.ShopToolbar:GetFrame(), "RPEGuildShopSearchInput", {
        width = 0, height = 20, expandWidth = true, weight = 1, text = "", placeholder = "Search Guild Shop...",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.ShopSearchInput:SetScript("OnTextChanged", function()
        self.ShopSearchText = self.ShopSearchInput:GetText() or ""
        self:ApplyShopFilters(true)
    end)
    self.ShopToolbar:AddChild(self.ShopSearchInput)
    self.ShopAvailabilityDropdown = UI.CreateDropdown(self.ShopToolbar:GetFrame(), "RPEGuildShopAvailabilityDropdown", {
        width = 104, height = 20, items = AVAILABILITY_ITEMS, selectedValue = "all",
        onValueChanged = function(value)
            self.ShopAvailabilityFilter = value or "all"
            self:ApplyShopFilters(true)
        end,
    })
    self.ShopToolbar:AddChild(self.ShopAvailabilityDropdown)

    self.ShopResultsLayout = UI.CreateLayout(UI.VerticalLayoutGroup, self.ShopBrowseLayout:GetFrame(), "RPEGuildShopResultsLayout", {
        expandWidth = true, expandHeight = true, weight = 1, spacing = 4,
        fitChildrenWidth = true, fitChildrenHeight = true,
    })
    self.ShopBrowseLayout:AddChild(self.ShopResultsLayout)

    self.ShopGrid = UI.CreateLayout(UI.GridLayoutGroup, self.ShopResultsLayout:GetFrame(), "RPEGuildShopFilteredGrid", {
        columns = SHOP_COLUMNS, spacingX = SHOP_GRID_SPACING_X, spacingY = SHOP_GRID_SPACING_Y,
        cellHeight = SHOP_ENTRY_HEIGHT, expandWidth = true, expandHeight = true, weight = 1,
        fitChildrenWidth = true, fitChildrenHeight = false,
    })
    self.ShopResultsLayout:AddChild(self.ShopGrid)
    for index = 1, #(self.ShopEntries or {}) do
        local entry = self.ShopEntries[index]
        entry:SetParent(self.ShopGrid:GetFrame())
        self.ShopGrid:AddChild(entry)
    end
    self.ShopGrid:GetFrame():HookScript("OnSizeChanged", function() self:RefreshShopEntryMetrics() end)

    self.ShopPaginationHost = UI.CreatePanel(self.ShopResultsLayout:GetFrame(), "RPEGuildShopFilteredPaginationHost", {
        height = SHOP_PAGE_NAV_HEIGHT, expandWidth = true, contentInset = 0, showBorder = false,
        panelBackgroundColor = { r = 0, g = 0, b = 0, a = 0 },
    })
    self.ShopResultsLayout:AddChild(self.ShopPaginationHost)
    self.ShopPaginationLayout = UI.CreateLayout(UI.HorizontalLayoutGroup, self.ShopPaginationHost:GetContentFrame(), "RPEGuildShopFilteredPaginationLayout", {
        width = SHOP_PAGINATION_WIDTH, height = SHOP_PAGE_NAV_HEIGHT, fitChildrenWidth = true,
        fitChildrenHeight = false, spacing = SHOP_PAGE_NAV_SPACING,
    })
    self.ShopPaginationLayout:GetFrame():SetPoint("CENTER", self.ShopPaginationHost:GetContentFrame(), "CENTER", 0, 0)
    self.ShopPreviousButton = UI.TextButton:New({ name = "RPEGuildShopFilteredPreviousButton", width = SHOP_PAGE_BUTTON_WIDTH, height = SHOP_PAGE_NAV_HEIGHT, text = "<", fontSize = 11, border = false })
    self.ShopPreviousButton:SetParent(self.ShopPaginationLayout:GetFrame())
    self.ShopPreviousButton:Create()
    self.ShopPreviousButton:SetScript("OnClick", function() self:PreviousShopPage() end)
    self.ShopPaginationLayout:AddChild(self.ShopPreviousButton)
    self.ShopPageText = UI.CreateText(self.ShopPaginationLayout:GetFrame(), "RPEGuildShopFilteredPageText", "Page 0 / 0", { width = SHOP_PAGE_TEXT_WIDTH, height = SHOP_PAGE_NAV_HEIGHT, justifyH = "CENTER", textColor = UI.ResolveColor(nil, "text.secondary") })
    self.ShopPaginationLayout:AddChild(self.ShopPageText)
    self.ShopNextButton = UI.TextButton:New({ name = "RPEGuildShopFilteredNextButton", width = SHOP_PAGE_BUTTON_WIDTH, height = SHOP_PAGE_NAV_HEIGHT, text = ">", fontSize = 11, border = false })
    self.ShopNextButton:SetParent(self.ShopPaginationLayout:GetFrame())
    self.ShopNextButton:Create()
    self.ShopNextButton:SetScript("OnClick", function() self:NextShopPage() end)
    self.ShopPaginationLayout:AddChild(self.ShopNextButton)
end

function Page:Build(parent, owner)
    local frame = OldBuild(self, parent, owner)
    if not self.ShopBrowserBuilt then
        self.SelectedShopCategory = "__all"
        self.ShopSearchText = ""
        self.ShopAvailabilityFilter = "all"
        self:BuildShopBrowser()
        if self.GuildRankText then
            self.GuildRolesText = self.GuildRankText
            self.GuildRolesText:SetTooltip(function() return buildRolesTooltip(self.EffectiveRoles or {}) end)
        end
        self:Refresh()
    end
    return frame
end

function Page:Refresh()
    if not self.frame then return nil end
    local Guild = Client.Guild
    local setting, resolution = self:GetActiveSettingContext()
    self.ActiveGuildSetting, self.ActiveGuildResolution = setting, resolution

    local roles, roleState = {}, nil
    if Guild and type(Guild.GetEffectiveRoles) == "function" then
        local ok, resolvedRoles, resolvedState = pcall(Guild.GetEffectiveRoles, Guild)
        if ok and type(resolvedRoles) == "table" then roles, roleState = resolvedRoles, resolvedState end
    end
    self.EffectiveRoles, self.EffectiveRoleState = roles, roleState

    local dailyStatus = { status = "unavailable", rewards = {} }
    if Guild and type(Guild.GetDailyRewardStatus) == "function" then
        local ok, resolved = pcall(Guild.GetDailyRewardStatus, Guild)
        if ok and type(resolved) == "table" then dailyStatus = resolved end
    end
    self.DailyRewardStatus = dailyStatus
    if self.DailyRewardButton then self.DailyRewardButton:SetTooltip(self.DailyRewardTooltip) end

    if self.GuildRolesText then
        local names = {}
        for index = 1, #roles do names[#names + 1] = roles[index].name or roles[index].roleId end
        local label
        if #names == 0 then label = "Roles: None"
        elseif #names <= 3 then label = "Roles: " .. table.concat(names, ", ")
        else label = ("Roles: %d Roles"):format(#names) end
        self.GuildRolesText:SetText(label)
        self.GuildRolesText:SetTooltip(function() return buildRolesTooltip(self.EffectiveRoles or {}) end)
    end
    self:UpdateResetText(dailyStatus.resetState and dailyStatus.resetState.secondsRemaining or 0)
    self:UpdateDailyRewardVisualState()

    local shop, limited = self:PartitionRequisitions()
    self.LimitedRequisitions = limited
    self.ShopBaseRows = self:BuildResolvedShopRows(shop)
    self.ShopCategoryRows, self.KnownShopCategoryIds = self:BuildShopCategoryRows(self.ShopBaseRows)
    local categoryExists = self.SelectedShopCategory == "__all"
    for index = 1, #(self.ShopCategoryRows or {}) do
        if self.ShopCategoryRows[index].id == self.SelectedShopCategory then categoryExists = true break end
    end
    if not categoryExists then self.SelectedShopCategory = "__all" end
    self:RefreshCategoryList()
    self:ApplyShopFilters(false)
    if self.LimitedRequisitionList then self.LimitedRequisitionList:SetItems(self.LimitedRequisitions) end

    self.LastResetCycleKey = dailyStatus.resetState and dailyStatus.resetState.cycleKey or nil
    self.ResetCycleKeyInitialized = true
    if self.StartResetTicker then self:StartResetTicker() end
    return self.frame
end

return Page
