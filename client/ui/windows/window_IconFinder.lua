local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}

local Client = Addon.Client
local UI = Addon.UI or {}
local IconData = Addon.Data and Addon.Data.IconData or {}

local IconFinder = Addon.Client.UI.IconFinder or {}
Addon.Client.UI.IconFinder = IconFinder
IconFinder.__index = IconFinder

local GRID_COLS = 10
local GRID_ROWS = 10
local ICON_SIZE = 32
local ICON_SPACING = 6
local GRID_PAD = 8
local HEADER_HEIGHT = 36
local META_HEIGHT = 48
local NAV_HEIGHT = 30
local VERTICAL_SPACING = 6
local SIDE_PAD = 8
local HEADER_CONTENT_SPACING = 8
local CONTENT_FOOTER_SPACING = 12
local CONTROL_HEIGHT = 20
local NAV_BUTTON_WIDTH = 56
local ACTION_BUTTON_WIDTH = 72
local ITEMS_PER_PAGE = GRID_COLS * GRID_ROWS
local GRID_WIDTH = GRID_PAD + ((GRID_COLS - 1) * (ICON_SIZE + ICON_SPACING)) + ICON_SIZE + GRID_PAD
local GRID_HEIGHT = GRID_PAD + ((GRID_ROWS - 1) * (ICON_SIZE + ICON_SPACING)) + ICON_SIZE + GRID_PAD
local WINDOW_WIDTH = math.max(GRID_WIDTH + (2 * SIDE_PAD), 480)
local FOOTER_HEIGHT = META_HEIGHT + VERTICAL_SPACING + NAV_HEIGHT + 8
local WINDOW_HEIGHT = HEADER_HEIGHT + HEADER_CONTENT_SPACING + GRID_HEIGHT + CONTENT_FOOTER_SPACING + FOOTER_HEIGHT + 10
local DEFAULT_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"
local EMPTY_PATH_TEXT = "Path: -"
local EMPTY_ID_TEXT = "FileDataID: -"

local function normalizePath(value)
    local text = tostring(value or "")
    text = text:gsub("\\", "/")
    return string.lower(text)
end

local function shallowCopy(values)
    local output = {}
    for index = 1, #(values or {}) do
        output[index] = values[index]
    end
    return output
end

local function createInstance()
    return setmetatable({
        window = nil,
        headerPanel = nil,
        contentPanel = nil,
        gridPanel = nil,
        footerPanel = nil,
        filterLabel = nil,
        searchInput = nil,
        clearButton = nil,
        previewSlot = nil,
        metaPathText = nil,
        metaIdText = nil,
        pageText = nil,
        previousButton = nil,
        nextButton = nil,
        applyButton = nil,
        cancelButton = nil,
        iconButtons = {},
        allIcons = {},
        filteredIcons = {},
        selectedIcon = nil,
        callback = nil,
        currentPage = 1,
        totalPages = 1,
    }, IconFinder)
end

function IconFinder:Get()
    if not self._singleton then
        self._singleton = createInstance()
    end

    return self._singleton
end

function IconFinder:GetIconDataTable()
    if type(IconData) == "table" and type(IconData.GetTable) == "function" then
        return IconData:GetTable()
    end

    return IconData or {}
end

function IconFinder:BuildIconIndex()
    self.allIcons = {}

    for fileDataID, path in pairs(self:GetIconDataTable()) do
        if type(path) == "string" then
            local normalizedPath = normalizePath(path)
            if string.find(normalizedPath, "interface/icons/", 1, true) == 1 then
                self.allIcons[#self.allIcons + 1] = {
                    id = tonumber(fileDataID) or 0,
                    path = path,
                    pathLower = normalizedPath,
                }
            end
        end
    end

    table.sort(self.allIcons, function(left, right)
        return (left.id or 0) < (right.id or 0)
    end)

    return self.allIcons
end

function IconFinder:GetIconIndex()
    if not self.allIcons or #self.allIcons == 0 then
        self:BuildIconIndex()
    end

    return self.allIcons
end

function IconFinder:RefilterIcons(filterText)
    local query = normalizePath(filterText)
    local source = self:GetIconIndex()

    if query == "" then
        self.filteredIcons = shallowCopy(source)
    else
        local filtered = {}
        for index = 1, #source do
            local entry = source[index]
            if entry.pathLower and string.find(entry.pathLower, query, 1, true) then
                filtered[#filtered + 1] = entry
            end
        end
        self.filteredIcons = filtered
    end

    self.currentPage = 1
    return self.filteredIcons
end

function IconFinder:GetFilteredIcons()
    return self.filteredIcons or {}
end

function IconFinder:ClearSelection()
    self.selectedIcon = nil

    for index = 1, #self.iconButtons do
        local button = self.iconButtons[index]
        if button and button.selectionTexture and button.selectionTexture.Hide then
            button.selectionTexture:Hide()
        end
    end

    if self.previewSlot and self.previewSlot.SetIcon then
        self.previewSlot:SetIcon(DEFAULT_ICON)
    end

    if self.metaPathText and self.metaPathText.SetText then
        self.metaPathText:SetText(EMPTY_PATH_TEXT)
    end

    if self.metaIdText and self.metaIdText.SetText then
        self.metaIdText:SetText(EMPTY_ID_TEXT)
    end
end

function IconFinder:SelectIconEntry(entry, button)
    self.selectedIcon = entry

    for index = 1, #self.iconButtons do
        local iconButton = self.iconButtons[index]
        if iconButton and iconButton.selectionTexture then
            if iconButton == button then
                iconButton.selectionTexture:Show()
            else
                iconButton.selectionTexture:Hide()
            end
        end
    end

    if self.previewSlot and self.previewSlot.SetIcon then
        self.previewSlot:SetIcon((entry and entry.path) or DEFAULT_ICON)
    end

    if self.metaPathText and self.metaPathText.SetText then
        self.metaPathText:SetText(entry and ("Path: " .. tostring(entry.path or "")) or EMPTY_PATH_TEXT)
    end

    if self.metaIdText and self.metaIdText.SetText then
        self.metaIdText:SetText(entry and ("FileDataID: " .. tostring(entry.id or 0)) or EMPTY_ID_TEXT)
    end
end

function IconFinder:UpdatePager()
    local totalIcons = #(self.filteredIcons or {})
    self.totalPages = math.max(1, math.ceil(totalIcons / ITEMS_PER_PAGE))
    self.currentPage = math.max(1, math.min(self.currentPage or 1, self.totalPages))

    if self.pageText and self.pageText.SetText then
        self.pageText:SetText(("Page %d / %d  (%d icons)"):format(self.currentPage, self.totalPages, totalIcons))
    end

    if self.previousButton and self.previousButton.SetEnabled then
        self.previousButton:SetEnabled(self.currentPage > 1)
    end

    if self.nextButton and self.nextButton.SetEnabled then
        self.nextButton:SetEnabled(self.currentPage < self.totalPages)
    end
end

function IconFinder:CreateIconButton(index)
    local parent = self.gridPanel and self.gridPanel.GetContentFrame and self.gridPanel:GetContentFrame() or nil
    if not parent then
        parent = self.contentPanel and self.contentPanel.GetContentFrame and self.contentPanel:GetContentFrame() or nil
    end
    if not parent then
        return nil
    end

    local button = UI.ObjectSlot:New({
        name = ("RPEIconFinderIconButton%d"):format(index),
        width = ICON_SIZE,
        height = ICON_SIZE,
        size = ICON_SIZE,
        iconTexture = DEFAULT_ICON,
    })
    button:SetParent(parent)
    button:Create()

    local frame = button.GetFrame and button:GetFrame() or nil
    if frame and frame.RegisterForClicks then
        frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    end

    button.selectionTexture = frame and frame:CreateTexture(nil, "OVERLAY") or nil
    if button.selectionTexture then
        button.selectionTexture:SetAllPoints(frame)
        button.selectionTexture:SetColorTexture(0.82, 0.66, 0.24, 0.28)
        button.selectionTexture:Hide()
    end

    self.iconButtons[index] = button
    return button
end

function IconFinder:EnsureIconButtons()
    for index = #self.iconButtons + 1, ITEMS_PER_PAGE do
        self:CreateIconButton(index)
    end

    return self.iconButtons
end

function IconFinder:BindIconButton(button, entry)
    button.entry = entry
    button:SetIcon(entry and entry.path or DEFAULT_ICON)

    button:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "RightButton" then
            return
        end

        self:SelectIconEntry(entry, button)

        local now = GetTime and GetTime() or 0
        if button._lastClickTime and (now - button._lastClickTime) < 0.25 then
            self:ApplySelection()
        end
        button._lastClickTime = now
    end)

    local frame = button.GetFrame and button:GetFrame() or nil
    if not frame then
        return
    end

    button:SetScript("OnEnter", function()
        if not GameTooltip or not GameTooltip.SetOwner then
            return
        end

        GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("Icon")
        GameTooltip:AddLine(("FileDataID: %s"):format(tostring(entry and entry.id or "-")))
        GameTooltip:AddLine(("Path: %s"):format(tostring(entry and entry.path or "-")))
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        if GameTooltip and GameTooltip.Hide then
            GameTooltip:Hide()
        end
    end)
end

function IconFinder:LayoutIconButtons()
    self:EnsureIconButtons()

    local parent = self.gridPanel and self.gridPanel.GetContentFrame and self.gridPanel:GetContentFrame() or nil
    if not parent then
        parent = self.contentPanel and self.contentPanel.GetContentFrame and self.contentPanel:GetContentFrame() or nil
    end
    if not parent then
        return
    end

    for index = 1, ITEMS_PER_PAGE do
        local button = self.iconButtons[index]
        local frame = button and button.GetFrame and button:GetFrame() or nil
        if frame then
            frame:ClearAllPoints()
            local row = math.floor((index - 1) / GRID_COLS)
            local column = (index - 1) % GRID_COLS
            frame:SetPoint(
                "TOPLEFT",
                parent,
                "TOPLEFT",
                GRID_PAD + (column * (ICON_SIZE + ICON_SPACING)),
                -(GRID_PAD + (row * (ICON_SIZE + ICON_SPACING)))
            )
        end
    end
end

function IconFinder:FillPage()
    self:UpdatePager()

    local filtered = self.filteredIcons or {}
    if #filtered == 0 then
        for index = 1, #self.iconButtons do
            local button = self.iconButtons[index]
            local frame = button and button.GetFrame and button:GetFrame() or nil
            if frame and frame.Hide then
                frame:Hide()
            end
        end
        self:ClearSelection()
        return
    end

    self:LayoutIconButtons()

    local startIndex = ((self.currentPage - 1) * ITEMS_PER_PAGE) + 1
    local endIndex = math.min(startIndex + ITEMS_PER_PAGE - 1, #filtered)

    for buttonIndex = 1, ITEMS_PER_PAGE do
        local button = self.iconButtons[buttonIndex]
        local frame = button and button.GetFrame and button:GetFrame() or nil
        local entry = filtered[startIndex + buttonIndex - 1]

        if frame then
            if entry then
                self:BindIconButton(button, entry)
                frame:Show()
                if button.selectionTexture then
                    if self.selectedIcon and self.selectedIcon.id == entry.id and self.selectedIcon.path == entry.path then
                        button.selectionTexture:Show()
                    else
                        button.selectionTexture:Hide()
                    end
                end
            else
                frame:Hide()
                if button.selectionTexture then
                    button.selectionTexture:Hide()
                end
            end
        end
    end

    if self.selectedIcon then
        local selectedVisible = false
        for index = startIndex, endIndex do
            local entry = filtered[index]
            if entry and self.selectedIcon.id == entry.id and self.selectedIcon.path == entry.path then
                selectedVisible = true
                break
            end
        end

        if not selectedVisible then
            self:ClearSelection()
        end
    end
end

function IconFinder:ApplySelection()
    if not self.selectedIcon then
        return false
    end

    if type(self.callback) == "function" then
        self.callback(self.selectedIcon.id, self.selectedIcon.path)
    end

    self:Hide()
    return true
end

function IconFinder:BuildWindow()
    if self.window then
        return self.window
    end

    self:BuildIconIndex()
    self.filteredIcons = shallowCopy(self.allIcons)

    self.window = UI.Window:New({
        name = "RPEIconFinderWindow",
        width = WINDOW_WIDTH,
        height = WINDOW_HEIGHT,
        point = "TOPLEFT",
        relativeTo = UIParent,
        relativePoint = "TOPLEFT",
        x = 10,
        y = -10,
        frameStrata = "HIGH",
        frameLevel = 25,
        movable = true,
        clampedToScreen = true,
        toplevel = true,
        hidden = true,
        contentInsetLeft = 8,
        contentInsetRight = 8,
        contentInsetTop = 28,
        contentInsetBottom = 8,
        borderSize = (UI.Constants and UI.Constants.Window and UI.Constants.Window.BorderSize) or 2,
    })
    self.window:SetTitle("Icon Finder")
    self.window:Create()

    local content = self.window:GetContentFrame()

    self.headerPanel = UI.CreatePanel(content, "RPEIconFinderHeaderPanel", {
        width = WINDOW_WIDTH - 16,
        height = HEADER_HEIGHT,
        contentInset = 0,
        showBorder = false,
    })
    self.headerPanel:GetFrame():SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
    self.headerPanel:GetFrame():SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, 0)

    self.footerPanel = UI.CreatePanel(content, "RPEIconFinderFooterPanel", {
        width = WINDOW_WIDTH - 16,
        height = FOOTER_HEIGHT,
        contentInset = 0,
        showBorder = false,
    })
    self.footerPanel:GetFrame():SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", 0, 0)
    self.footerPanel:GetFrame():SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 0, 0)

    self.contentPanel = UI.CreatePanel(content, "RPEIconFinderContentPanel", {
        width = GRID_WIDTH,
        height = GRID_HEIGHT,
        contentInset = 0,
        showBorder = false,
    })
    self.contentPanel:GetFrame():SetPoint("TOP", self.headerPanel:GetFrame(), "BOTTOM", 0, -HEADER_CONTENT_SPACING)
    self.contentPanel:GetFrame():SetPoint("BOTTOM", self.footerPanel:GetFrame(), "TOP", 0, CONTENT_FOOTER_SPACING)

    self.gridPanel = UI.CreatePanel(self.contentPanel:GetContentFrame(), "RPEIconFinderGridPanel", {
        width = GRID_WIDTH,
        height = GRID_HEIGHT,
        contentInset = 0,
        showBorder = false,
    })
    self.gridPanel:GetFrame():SetAllPoints(self.contentPanel:GetContentFrame())

    self.filterLabel = UI.CreateText(self.headerPanel:GetContentFrame(), "RPEIconFinderFilterLabel", "Path contains:", {
        width = 82,
        height = 18,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.filterLabel:GetFrame():SetPoint("LEFT", self.headerPanel:GetContentFrame(), "LEFT", SIDE_PAD, 0)

    self.searchInput = UI.CreateTextInput(self.headerPanel:GetContentFrame(), "RPEIconFinderSearchInput", {
        width = 260,
        height = CONTROL_HEIGHT,
        text = "",
    })
    self.searchInput:GetFrame():SetPoint("LEFT", self.filterLabel:GetFrame(), "RIGHT", 8, 0)
    self.searchInput:SetScript("OnTextChanged", function(_, text)
        self:RefilterIcons(text or "")
        self:FillPage()
    end)

    self.clearButton = UI.CreateButton(self.headerPanel:GetContentFrame(), "RPEIconFinderClearButton", "Clear", 60, function()
        self.searchInput:SetText("")
        self:RefilterIcons("")
        self:FillPage()
    end, {
        height = CONTROL_HEIGHT,
        fontSize = 8,
    })
    self.clearButton:GetFrame():SetPoint("RIGHT", self.headerPanel:GetContentFrame(), "RIGHT", -SIDE_PAD, 0)

    self.previewSlot = UI.ObjectSlot:New({
        name = "RPEIconFinderPreviewSlot",
        width = 40,
        height = 40,
        size = 40,
        iconTexture = DEFAULT_ICON,
    })
    self.previewSlot:SetParent(self.footerPanel:GetContentFrame())
    self.previewSlot:Create()
    self.previewSlot:GetFrame():SetPoint("TOPLEFT", self.footerPanel:GetContentFrame(), "TOPLEFT", SIDE_PAD, -8)

    self.metaPathText = UI.CreateText(self.footerPanel:GetContentFrame(), "RPEIconFinderMetaPath", EMPTY_PATH_TEXT, {
        width = WINDOW_WIDTH - 90,
        height = 18,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.primary"),
    })
    self.metaPathText:GetFrame():SetPoint("TOPLEFT", self.previewSlot:GetFrame(), "TOPRIGHT", 8, -2)

    self.metaIdText = UI.CreateText(self.footerPanel:GetContentFrame(), "RPEIconFinderMetaId", EMPTY_ID_TEXT, {
        width = WINDOW_WIDTH - 90,
        height = 18,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.metaIdText:GetFrame():SetPoint("TOPLEFT", self.metaPathText:GetFrame(), "BOTTOMLEFT", 0, -2)

    self.previousButton = UI.CreateButton(self.footerPanel:GetContentFrame(), "RPEIconFinderPreviousButton", "Prev", NAV_BUTTON_WIDTH, function()
        if self.currentPage > 1 then
            self.currentPage = self.currentPage - 1
            self:FillPage()
        end
    end, {
        height = CONTROL_HEIGHT,
        fontSize = 8,
    })
    self.previousButton:GetFrame():SetPoint("BOTTOMLEFT", self.footerPanel:GetContentFrame(), "BOTTOMLEFT", SIDE_PAD, 8)

    self.pageText = UI.CreateText(self.footerPanel:GetContentFrame(), "RPEIconFinderPageText", "Page 1 / 1  (0 icons)", {
        width = 96,
        height = 18,
        justifyH = "CENTER",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })

    self.nextButton = UI.CreateButton(self.footerPanel:GetContentFrame(), "RPEIconFinderNextButton", "Next", NAV_BUTTON_WIDTH, function()
        if self.currentPage < self.totalPages then
            self.currentPage = self.currentPage + 1
            self:FillPage()
        end
    end, {
        height = CONTROL_HEIGHT,
        fontSize = 8,
    })

    self.cancelButton = UI.CreateButton(self.footerPanel:GetContentFrame(), "RPEIconFinderCancelButton", "Cancel", ACTION_BUTTON_WIDTH, function()
        self:Hide()
    end, {
        height = CONTROL_HEIGHT,
        fontSize = 8,
    })
    self.cancelButton:GetFrame():SetPoint("BOTTOMRIGHT", self.footerPanel:GetContentFrame(), "BOTTOMRIGHT", -SIDE_PAD, 8)

    self.applyButton = UI.CreateButton(self.footerPanel:GetContentFrame(), "RPEIconFinderApplyButton", "Apply", ACTION_BUTTON_WIDTH, function()
        self:ApplySelection()
    end, {
        height = CONTROL_HEIGHT,
        fontSize = 8,
    })
    self.applyButton:GetFrame():SetPoint("RIGHT", self.cancelButton:GetFrame(), "LEFT", -8, 0)

    self.nextButton:GetFrame():ClearAllPoints()
    self.nextButton:GetFrame():SetPoint("RIGHT", self.applyButton:GetFrame(), "LEFT", -8, 0)
    self.pageText:GetFrame():SetPoint("LEFT", self.previousButton:GetFrame(), "RIGHT", 10, 0)
    self.pageText:GetFrame():SetPoint("RIGHT", self.nextButton:GetFrame(), "LEFT", -10, 0)

    self:EnsureIconButtons()
    self:LayoutIconButtons()
    self:ClearSelection()
    self:FillPage()
    return self.window
end

function IconFinder:Open(callback, options)
    self.callback = callback
    self:BuildWindow()

    local filter = type(options) == "table" and tostring(options.filter or "") or ""
    if self.searchInput then
        self.searchInput:SetText(filter)
    end

    self:ClearSelection()
    self:RefilterIcons(filter)
    self:FillPage()
    self:Show()
    return self.window
end

function IconFinder:Show()
    local window = self:BuildWindow()
    if window and window.Show then
        window:Show()
    end
    return window
end

function IconFinder:Hide()
    if self.window and self.window.Hide then
        self.window:Hide()
    end
    return self.window
end

function Client:BuildIconFinderWindow()
    return IconFinder:Get():BuildWindow()
end

function Client:ShowIconFinderWindow()
    return IconFinder:Get():Show()
end

function Client:HideIconFinderWindow()
    return IconFinder:Get():Hide()
end

function Client:OpenIconFinder(callback, options)
    return IconFinder:Get():Open(callback, options)
end
