local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}

local Client = Addon.Client
local UI = Addon.UI or {}
local ModelData = Addon.Data and Addon.Data.ModelData or nil

local ModelFinder = Addon.Client.UI.ModelFinder or {}
Addon.Client.UI.ModelFinder = ModelFinder
ModelFinder.__index = ModelFinder

local GRID_COLS = 4
local GRID_ROWS = 4
local CELL_SIZE = 96
local CELL_SPACING = 8
local GRID_PAD = 10
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
local GRID_WIDTH = GRID_PAD + ((GRID_COLS - 1) * (CELL_SIZE + CELL_SPACING)) + CELL_SIZE + GRID_PAD
local GRID_HEIGHT = GRID_PAD + ((GRID_ROWS - 1) * (CELL_SIZE + CELL_SPACING)) + CELL_SIZE + GRID_PAD
local WINDOW_WIDTH = math.max(GRID_WIDTH + (2 * SIDE_PAD), 460)
local FOOTER_HEIGHT = META_HEIGHT + VERTICAL_SPACING + NAV_HEIGHT + 8
local WINDOW_HEIGHT = HEADER_HEIGHT + HEADER_CONTENT_SPACING + GRID_HEIGHT + CONTENT_FOOTER_SPACING + FOOTER_HEIGHT + 10
local EMPTY_META_LINE_ONE = "DisplayID: -    FileDataID: -"
local EMPTY_META_LINE_TWO = "Path: -"

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
        metaLineOne = nil,
        metaLineTwo = nil,
        pageText = nil,
        previousButton = nil,
        nextButton = nil,
        applyButton = nil,
        cancelButton = nil,
        cells = {},
        allModels = {},
        filteredModels = {},
        selectedModel = nil,
        callback = nil,
        currentPage = 1,
        totalPages = 1,
    }, ModelFinder)
end

function ModelFinder:Get()
    if not self._singleton then
        self._singleton = createInstance()
    end

    return self._singleton
end

function ModelFinder:GetModelDataTable()
    if type(ModelData) == "table" and type(ModelData.GetTable) == "function" then
        return ModelData:GetTable()
    end

    return ModelData or {}
end

function ModelFinder:BuildModelIndex()
    self.allModels = {}

    for displayId, value in pairs(self:GetModelDataTable()) do
        if type(value) == "table" then
            local fileDataId = tonumber(value.FileDataID or value.fileDataID) or nil
            local filePath = value.FilePath or value.filePath
            if fileDataId and type(filePath) == "string" and filePath ~= "" then
                self.allModels[#self.allModels + 1] = {
                    displayId = tonumber(displayId) or 0,
                    fileDataId = fileDataId,
                    filePath = filePath,
                    pathLower = normalizePath(filePath),
                }
            end
        end
    end

    table.sort(self.allModels, function(left, right)
        if (left.displayId or 0) ~= (right.displayId or 0) then
            return (left.displayId or 0) < (right.displayId or 0)
        end

        return (left.fileDataId or 0) < (right.fileDataId or 0)
    end)

    return self.allModels
end

function ModelFinder:GetModelIndex()
    if not self.allModels or #self.allModels == 0 then
        self:BuildModelIndex()
    end

    return self.allModels
end

function ModelFinder:RefilterModels(filterText)
    local query = tostring(filterText or "")
    local queryLower = normalizePath(query)
    local queryNumericPrefix = tonumber(query) and tostring(math.floor(tonumber(query))) or nil
    local source = self:GetModelIndex()

    if query == "" then
        self.filteredModels = shallowCopy(source)
    else
        local filtered = {}
        for index = 1, #source do
            local entry = source[index]
            local matches = false

            if entry.pathLower and queryLower ~= "" and string.find(entry.pathLower, queryLower, 1, true) then
                matches = true
            elseif queryNumericPrefix then
                local displayIdText = tostring(entry.displayId or 0)
                matches = string.sub(displayIdText, 1, string.len(queryNumericPrefix)) == queryNumericPrefix
            end

            if matches then
                filtered[#filtered + 1] = entry
            end
        end
        self.filteredModels = filtered
    end

    self.currentPage = 1
    return self.filteredModels
end

function ModelFinder:ClearSelection()
    self.selectedModel = nil

    for index = 1, #self.cells do
        local cell = self.cells[index]
        if cell and cell.selectionTexture and cell.selectionTexture.Hide then
            cell.selectionTexture:Hide()
        end
    end

    if self.metaLineOne and self.metaLineOne.SetText then
        self.metaLineOne:SetText(EMPTY_META_LINE_ONE)
    end
    if self.metaLineTwo and self.metaLineTwo.SetText then
        self.metaLineTwo:SetText(EMPTY_META_LINE_TWO)
    end
end

function ModelFinder:SelectModelEntry(entry, cell)
    self.selectedModel = entry

    for index = 1, #self.cells do
        local currentCell = self.cells[index]
        if currentCell and currentCell.selectionTexture then
            if currentCell == cell then
                currentCell.selectionTexture:Show()
            else
                currentCell.selectionTexture:Hide()
            end
        end
    end

    if self.metaLineOne and self.metaLineOne.SetText then
        self.metaLineOne:SetText(("DisplayID: %d    FileDataID: %d"):format(entry and entry.displayId or 0, entry and entry.fileDataId or 0))
    end
    if self.metaLineTwo and self.metaLineTwo.SetText then
        self.metaLineTwo:SetText(entry and ("Path: " .. tostring(entry.filePath or "-")) or EMPTY_META_LINE_TWO)
    end
end

function ModelFinder:UpdatePager()
    local totalModels = #(self.filteredModels or {})
    self.totalPages = math.max(1, math.ceil(totalModels / ITEMS_PER_PAGE))
    self.currentPage = math.max(1, math.min(self.currentPage or 1, self.totalPages))

    if self.pageText and self.pageText.SetText then
        self.pageText:SetText(("Page %d / %d  (%d models)"):format(self.currentPage, self.totalPages, totalModels))
    end
    if self.previousButton and self.previousButton.SetEnabled then
        self.previousButton:SetEnabled(self.currentPage > 1)
    end
    if self.nextButton and self.nextButton.SetEnabled then
        self.nextButton:SetEnabled(self.currentPage < self.totalPages)
    end
end

function ModelFinder:CreateModelCell(index)
    local parent = self.gridPanel and self.gridPanel.GetContentFrame and self.gridPanel:GetContentFrame() or nil
    if not parent then
        return nil
    end

    local holder = CreateFrame("Button", ("RPEModelFinderCell%d"):format(index), parent)
    holder:SetSize(CELL_SIZE, CELL_SIZE)
    holder:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    local background = holder:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints(holder)
    local backgroundColor = UI.ResolveColor(nil, "panel.background")
    background:SetColorTexture(backgroundColor.r or 0.08, backgroundColor.g or 0.09, backgroundColor.b or 0.12, 0.9)

    local borderColor = UI.ResolveColor(nil, "panel.border")
    local borderTop = holder:CreateTexture(nil, "ARTWORK")
    borderTop:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, 0)
    borderTop:SetPoint("TOPRIGHT", holder, "TOPRIGHT", 0, 0)
    borderTop:SetHeight(1)
    borderTop:SetColorTexture(borderColor.r or 0.16, borderColor.g or 0.18, borderColor.b or 0.22, borderColor.a or 1)

    local borderBottom = holder:CreateTexture(nil, "ARTWORK")
    borderBottom:SetPoint("BOTTOMLEFT", holder, "BOTTOMLEFT", 0, 0)
    borderBottom:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", 0, 0)
    borderBottom:SetHeight(1)
    borderBottom:SetColorTexture(borderColor.r or 0.16, borderColor.g or 0.18, borderColor.b or 0.22, borderColor.a or 1)

    local borderLeft = holder:CreateTexture(nil, "ARTWORK")
    borderLeft:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, 0)
    borderLeft:SetPoint("BOTTOMLEFT", holder, "BOTTOMLEFT", 0, 0)
    borderLeft:SetWidth(1)
    borderLeft:SetColorTexture(borderColor.r or 0.16, borderColor.g or 0.18, borderColor.b or 0.22, borderColor.a or 1)

    local borderRight = holder:CreateTexture(nil, "ARTWORK")
    borderRight:SetPoint("TOPRIGHT", holder, "TOPRIGHT", 0, 0)
    borderRight:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", 0, 0)
    borderRight:SetWidth(1)
    borderRight:SetColorTexture(borderColor.r or 0.16, borderColor.g or 0.18, borderColor.b or 0.22, borderColor.a or 1)

    local model = CreateFrame("PlayerModel", ("RPEModelFinderCell%dModel"):format(index), holder)
    model:SetPoint("TOPLEFT", holder, "TOPLEFT", 2, -2)
    model:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", -2, 2)
    if model.SetKeepModelOnHide then
        model:SetKeepModelOnHide(true)
    end
    if model.SetCamDistanceScale then
        model:SetCamDistanceScale(1)
    end
    if model.SetCustomCamera then
        model:SetCustomCamera(1)
    end
    if model.SetPosition then
        model:SetPosition(0, 0, 0)
    end

    local selectionTexture = holder:CreateTexture(nil, "OVERLAY")
    selectionTexture:SetAllPoints(holder)
    selectionTexture:SetColorTexture(0.82, 0.66, 0.24, 0.28)
    selectionTexture:Hide()

    local cell = {
        frame = holder,
        model = model,
        selectionTexture = selectionTexture,
    }
    self.cells[index] = cell
    return cell
end

function ModelFinder:EnsureModelCells()
    for index = #self.cells + 1, ITEMS_PER_PAGE do
        self:CreateModelCell(index)
    end

    return self.cells
end

function ModelFinder:BindModelCell(cell, entry)
    local frame = cell and cell.frame or nil
    local model = cell and cell.model or nil
    if not frame or not model then
        return
    end

    if model.ClearModel then
        model:ClearModel()
    end
    if model.ClearTransform then
        model:ClearTransform()
    end
    if model.SetModel then
        model:SetModel(entry.fileDataId)
    end
    if model.SetDisplayInfo then
        model:SetDisplayInfo(entry.displayId)
    end
    if model.SetCamDistanceScale then
        model:SetCamDistanceScale(1)
    end
    if model.SetRotation then
        model:SetRotation(0)
    end
    if model.SetPosition then
        model:SetPosition(0, 0, 0)
    end

    frame:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "RightButton" then
            return
        end

        self:SelectModelEntry(entry, cell)

        local now = GetTime and GetTime() or 0
        if frame._lastClickTime and (now - frame._lastClickTime) < 0.25 then
            self:ApplySelection()
        end
        frame._lastClickTime = now
    end)
    frame:SetScript("OnEnter", function()
        if not GameTooltip or not GameTooltip.SetOwner then
            return
        end

        GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("Model")
        GameTooltip:AddLine(("DisplayID: %d"):format(entry.displayId or 0))
        GameTooltip:AddLine(("FileDataID: %d"):format(entry.fileDataId or 0))
        GameTooltip:AddLine(("Path: %s"):format(tostring(entry.filePath or "-")))
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function()
        if GameTooltip and GameTooltip.Hide then
            GameTooltip:Hide()
        end
    end)
end

function ModelFinder:LayoutModelCells()
    self:EnsureModelCells()

    local parent = self.gridPanel and self.gridPanel.GetContentFrame and self.gridPanel:GetContentFrame() or nil
    if not parent then
        return
    end

    for index = 1, ITEMS_PER_PAGE do
        local cell = self.cells[index]
        local frame = cell and cell.frame or nil
        if frame then
            frame:ClearAllPoints()
            local row = math.floor((index - 1) / GRID_COLS)
            local column = (index - 1) % GRID_COLS
            frame:SetPoint(
                "TOPLEFT",
                parent,
                "TOPLEFT",
                GRID_PAD + (column * (CELL_SIZE + CELL_SPACING)),
                -(GRID_PAD + (row * (CELL_SIZE + CELL_SPACING)))
            )
        end
    end
end

function ModelFinder:FillPage()
    self:UpdatePager()

    local filtered = self.filteredModels or {}
    if #filtered == 0 then
        for index = 1, #self.cells do
            local cell = self.cells[index]
            local frame = cell and cell.frame or nil
            if frame and frame.Hide then
                frame:Hide()
            end
        end
        self:ClearSelection()
        return
    end

    self:LayoutModelCells()

    local startIndex = ((self.currentPage - 1) * ITEMS_PER_PAGE) + 1
    local endIndex = math.min(startIndex + ITEMS_PER_PAGE - 1, #filtered)

    for cellIndex = 1, ITEMS_PER_PAGE do
        local cell = self.cells[cellIndex]
        local frame = cell and cell.frame or nil
        local entry = filtered[startIndex + cellIndex - 1]

        if frame then
            if entry then
                self:BindModelCell(cell, entry)
                frame:Show()
                if cell.selectionTexture then
                    if self.selectedModel and self.selectedModel.displayId == entry.displayId and self.selectedModel.fileDataId == entry.fileDataId then
                        cell.selectionTexture:Show()
                    else
                        cell.selectionTexture:Hide()
                    end
                end
            else
                frame:Hide()
                if cell.selectionTexture then
                    cell.selectionTexture:Hide()
                end
            end
        end
    end

    if self.selectedModel then
        local selectedVisible = false
        for index = startIndex, endIndex do
            local entry = filtered[index]
            if entry and self.selectedModel.displayId == entry.displayId and self.selectedModel.fileDataId == entry.fileDataId then
                selectedVisible = true
                break
            end
        end

        if not selectedVisible then
            self:ClearSelection()
        end
    end
end

function ModelFinder:ApplySelection()
    if not self.selectedModel then
        return false
    end

    if type(self.callback) == "function" then
        self.callback(self.selectedModel.displayId, self.selectedModel.fileDataId, self.selectedModel.filePath)
    end

    self:Hide()
    return true
end

function ModelFinder:BuildWindow()
    if self.window then
        return self.window
    end

    self:BuildModelIndex()
    self.filteredModels = shallowCopy(self.allModels)

    self.window = UI.Window:New({
        name = "RPEModelFinderWindow",
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
    self.window:SetTitle("Model Finder")
    self.window:Create()

    local content = self.window:GetContentFrame()

    self.headerPanel = UI.CreatePanel(content, "RPEModelFinderHeaderPanel", {
        width = WINDOW_WIDTH - 16,
        height = HEADER_HEIGHT,
        contentInset = 0,
        showBorder = false,
    })
    self.headerPanel:GetFrame():SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
    self.headerPanel:GetFrame():SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, 0)

    self.footerPanel = UI.CreatePanel(content, "RPEModelFinderFooterPanel", {
        width = WINDOW_WIDTH - 16,
        height = FOOTER_HEIGHT,
        contentInset = 0,
        showBorder = false,
    })
    self.footerPanel:GetFrame():SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", 0, 0)
    self.footerPanel:GetFrame():SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 0, 0)

    self.contentPanel = UI.CreatePanel(content, "RPEModelFinderContentPanel", {
        width = GRID_WIDTH,
        height = GRID_HEIGHT,
        contentInset = 0,
        showBorder = false,
    })
    self.contentPanel:GetFrame():SetPoint("TOP", self.headerPanel:GetFrame(), "BOTTOM", 0, -HEADER_CONTENT_SPACING)
    self.contentPanel:GetFrame():SetPoint("BOTTOM", self.footerPanel:GetFrame(), "TOP", 0, CONTENT_FOOTER_SPACING)

    self.gridPanel = UI.CreatePanel(self.contentPanel:GetContentFrame(), "RPEModelFinderGridPanel", {
        width = GRID_WIDTH,
        height = GRID_HEIGHT,
        contentInset = 0,
        showBorder = false,
    })
    self.gridPanel:GetFrame():SetAllPoints(self.contentPanel:GetContentFrame())

    self.filterLabel = UI.CreateText(self.headerPanel:GetContentFrame(), "RPEModelFinderFilterLabel", "Filter:", {
        width = 48,
        height = 18,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.filterLabel:GetFrame():SetPoint("LEFT", self.headerPanel:GetContentFrame(), "LEFT", SIDE_PAD, 0)

    self.searchInput = UI.CreateTextInput(self.headerPanel:GetContentFrame(), "RPEModelFinderSearchInput", {
        width = 260,
        height = CONTROL_HEIGHT,
        text = "",
    })
    self.searchInput:GetFrame():SetPoint("LEFT", self.filterLabel:GetFrame(), "RIGHT", 8, 0)
    self.searchInput:SetScript("OnTextChanged", function(_, text)
        self:RefilterModels(text or "")
        self:FillPage()
    end)

    self.clearButton = UI.CreateButton(self.headerPanel:GetContentFrame(), "RPEModelFinderClearButton", "Clear", 60, function()
        self.searchInput:SetText("")
        self:RefilterModels("")
        self:FillPage()
    end, {
        height = CONTROL_HEIGHT,
        fontSize = 8,
    })
    self.clearButton:GetFrame():SetPoint("RIGHT", self.headerPanel:GetContentFrame(), "RIGHT", -SIDE_PAD, 0)

    self.metaLineOne = UI.CreateText(self.footerPanel:GetContentFrame(), "RPEModelFinderMetaLineOne", EMPTY_META_LINE_ONE, {
        width = WINDOW_WIDTH - 16,
        height = 18,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.primary"),
    })
    self.metaLineOne:GetFrame():SetPoint("TOPLEFT", self.footerPanel:GetContentFrame(), "TOPLEFT", SIDE_PAD, -8)

    self.metaLineTwo = UI.CreateText(self.footerPanel:GetContentFrame(), "RPEModelFinderMetaLineTwo", EMPTY_META_LINE_TWO, {
        width = WINDOW_WIDTH - 16,
        height = 18,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.metaLineTwo:GetFrame():SetPoint("TOPLEFT", self.metaLineOne:GetFrame(), "BOTTOMLEFT", 0, -2)

    self.previousButton = UI.CreateButton(self.footerPanel:GetContentFrame(), "RPEModelFinderPreviousButton", "Prev", NAV_BUTTON_WIDTH, function()
        if self.currentPage > 1 then
            self.currentPage = self.currentPage - 1
            self:FillPage()
        end
    end, {
        height = CONTROL_HEIGHT,
        fontSize = 8,
    })
    self.previousButton:GetFrame():SetPoint("BOTTOMLEFT", self.footerPanel:GetContentFrame(), "BOTTOMLEFT", SIDE_PAD, 8)

    self.pageText = UI.CreateText(self.footerPanel:GetContentFrame(), "RPEModelFinderPageText", "Page 1 / 1  (0 models)", {
        width = 120,
        height = 18,
        justifyH = "CENTER",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })

    self.nextButton = UI.CreateButton(self.footerPanel:GetContentFrame(), "RPEModelFinderNextButton", "Next", NAV_BUTTON_WIDTH, function()
        if self.currentPage < self.totalPages then
            self.currentPage = self.currentPage + 1
            self:FillPage()
        end
    end, {
        height = CONTROL_HEIGHT,
        fontSize = 8,
    })

    self.cancelButton = UI.CreateButton(self.footerPanel:GetContentFrame(), "RPEModelFinderCancelButton", "Cancel", ACTION_BUTTON_WIDTH, function()
        self:Hide()
    end, {
        height = CONTROL_HEIGHT,
        fontSize = 8,
    })
    self.cancelButton:GetFrame():SetPoint("BOTTOMRIGHT", self.footerPanel:GetContentFrame(), "BOTTOMRIGHT", -SIDE_PAD, 8)

    self.applyButton = UI.CreateButton(self.footerPanel:GetContentFrame(), "RPEModelFinderApplyButton", "Apply", ACTION_BUTTON_WIDTH, function()
        self:ApplySelection()
    end, {
        height = CONTROL_HEIGHT,
        fontSize = 8,
    })
    self.applyButton:GetFrame():SetPoint("RIGHT", self.cancelButton:GetFrame(), "LEFT", -8, 0)

    self.nextButton:GetFrame():SetPoint("RIGHT", self.applyButton:GetFrame(), "LEFT", -8, 0)
    self.pageText:GetFrame():SetPoint("LEFT", self.previousButton:GetFrame(), "RIGHT", 10, 0)
    self.pageText:GetFrame():SetPoint("RIGHT", self.nextButton:GetFrame(), "LEFT", -10, 0)

    self:EnsureModelCells()
    self:LayoutModelCells()
    self:ClearSelection()
    self:FillPage()
    return self.window
end

function ModelFinder:Open(callback, options)
    self.callback = callback
    self:BuildWindow()

    local filter = type(options) == "table" and tostring(options.filter or "") or ""
    if self.searchInput then
        self.searchInput:SetText(filter)
    end

    self:ClearSelection()
    self:RefilterModels(filter)
    self:FillPage()
    self:Show()
    return self.window
end

function ModelFinder:Show()
    local window = self:BuildWindow()
    if window and window.Show then
        window:Show()
    end
    return window
end

function ModelFinder:Hide()
    if self.window and self.window.Hide then
        self.window:Hide()
    end
    return self.window
end

function Client:BuildModelFinderWindow()
    return ModelFinder:Get():BuildWindow()
end

function Client:ShowModelFinderWindow()
    return ModelFinder:Get():Show()
end

function Client:HideModelFinderWindow()
    return ModelFinder:Get():Hide()
end

function Client:OpenModelFinder(callback, options)
    return ModelFinder:Get():Open(callback, options)
end
