local _, Addon = ...

local UI = Addon.UI or {}
Addon.UI = UI
local BaseElement = UI.BaseElement

local MAX_MENU_DEPTH = 4
local CATEGORY_TEXTURE_PATH = "Interface\\AddOns\\RPEngine2\\data\\textures\\ui\\category.png"

UI.ContextMenu = UI.ContextMenu or {}
local ContextMenu = UI.ContextMenu
ContextMenu.__index = ContextMenu
setmetatable(ContextMenu, { __index = BaseElement })
ContextMenu.ActiveMenus = ContextMenu.ActiveMenus or {}

local function NormalizeItem(item, index, depth)
    local currentDepth = depth or 1
    if type(item) ~= "table" then
        return {
            label = tostring(item),
            value = item,
            depth = currentDepth,
            enabled = true,
            hasArrow = false,
        }
    end

    local tooltip = item.tooltip
    local tooltipTitle = item.tooltipTitle
    local tooltipText = item.tooltipText
    local tooltipLines = item.tooltipLines
    local tooltipType = item.tooltipType

    if type(tooltip) == "string" then
        tooltipText = tooltipText or tooltip
    elseif type(tooltip) == "table" then
        tooltipTitle = tooltipTitle or tooltip.title
        tooltipText = tooltipText or tooltip.text
        tooltipLines = tooltipLines or tooltip.lines
        tooltipType = tooltipType or tooltip.type
    end

    local children = item.children or item.items
    local normalizedChildren = nil
    if type(children) == "table" and currentDepth < MAX_MENU_DEPTH then
        normalizedChildren = {}
        for childIndex = 1, #children do
            normalizedChildren[#normalizedChildren + 1] = NormalizeItem(children[childIndex], childIndex, currentDepth + 1)
        end
    end

    return {
        label = item.label or item.text or tostring(item.value or item.id or index),
        value = item.value ~= nil and item.value or item.id ~= nil and item.id or item.label or item.text or index,
        depth = currentDepth,
        data = item.data,
        assignmentType = item.assignmentType,
        icon = item.icon or item.texture or (normalizedChildren ~= nil and #normalizedChildren > 0 and CATEGORY_TEXTURE_PATH or nil),
        iconWidth = item.iconWidth,
        iconHeight = item.iconHeight,
        iconCoords = item.iconCoords,
        checked = item.checked,
        baseEnabled = item.enabled ~= false,
        enabled = item.enabled ~= false,
        isTitle = item.isTitle == true,
        hasArrow = normalizedChildren ~= nil and #normalizedChildren > 0,
        keepShownOnClick = item.keepShownOnClick,
        notCheckable = item.notCheckable,
        children = normalizedChildren,
        tooltip = tooltip,
        tooltipTitle = tooltipTitle,
        tooltipText = tooltipText,
        tooltipLines = tooltipLines,
        tooltipType = tooltipType,
        tooltipOnButton = item.tooltipOnButton,
    }
end

local function NormalizeItems(items)
    local normalized = {}
    for index = 1, #(items or {}) do
        normalized[#normalized + 1] = NormalizeItem(items[index], index, 1)
    end
    return normalized
end

local function CountSelectedValues(selectedValues)
    local count = 0
    for _, isSelected in pairs(selectedValues or {}) do
        if isSelected == true then
            count = count + 1
        end
    end
    return count
end

local function BuildSelectionSet(values)
    local set = {}
    if type(values) == "table" then
        for key, value in pairs(values) do
            if value == true then
                set[key] = true
            elseif value ~= nil then
                set[value] = true
            end
        end
    end
    return set
end

local function BuildSelectionOrder(items, selectedValues, output)
    local order = output or {}
    for index = 1, #(items or {}) do
        local item = items[index]
        if selectedValues[item.value] then
            order[#order + 1] = item.value
        end

        if item.children and #item.children > 0 then
            BuildSelectionOrder(item.children, selectedValues, order)
        end
    end

    return order
end

local function RemoveValueFromOrder(order, value)
    if type(order) ~= "table" then
        return order
    end

    for index = #order, 1, -1 do
        if order[index] == value then
            table.remove(order, index)
        end
    end

    return order
end

local function FindItemByValue(items, value)
    for index = 1, #(items or {}) do
        local item = items[index]
        if item.value == value then
            return item
        end

        local found = FindItemByValue(item.children, value)
        if found then
            return found
        end
    end

    return nil
end

local function HasSelectedDescendant(item, selectedValues)
    if type(item) ~= "table" or type(selectedValues) ~= "table" then
        return false
    end

    if selectedValues[item.value] then
        return true
    end

    local children = item.children
    if type(children) ~= "table" then
        return false
    end

    for index = 1, #children do
        if HasSelectedDescendant(children[index], selectedValues) then
            return true
        end
    end

    return false
end

local function CollectSelectableLeafValues(items, output)
    local values = output or {}
    for index = 1, #(items or {}) do
        local item = items[index]
        if item.baseEnabled ~= false then
            if item.children and #item.children > 0 then
                CollectSelectableLeafValues(item.children, values)
            else
                values[#values + 1] = item.value
            end
        end
    end

    return values
end

local function HasEnabledLeaf(item)
    if not item or item.enabled == false then
        return false
    end

    if not item.children or #item.children == 0 then
        return true
    end

    for index = 1, #item.children do
        if HasEnabledLeaf(item.children[index]) then
            return true
        end
    end

    return false
end

local function FindDirectItemByValue(items, value)
    for index = 1, #(items or {}) do
        local item = items[index]
        if item.value == value then
            return item
        end
    end

    return nil
end

local function FindItemPath(items, pathSpec, depth, output)
    depth = depth or 1
    output = output or {}
    local token = pathSpec and pathSpec[depth]

    if token == nil then
        return output
    end

    local matched = nil
    if type(token) == "number" then
        matched = items and items[token] or nil
    else
        matched = FindDirectItemByValue(items, token)
    end

    if not matched then
        return output
    end

    output[depth] = matched
    if matched.children and #matched.children > 0 then
        return FindItemPath(matched.children, pathSpec, depth + 1, output)
    end

    return output
end

local function ResolveAnchorTarget(anchor)
    if type(anchor) ~= "table" then
        return anchor
    end

    if anchor.GetFrame then
        return anchor:GetFrame() or anchor.frame
    end

    return anchor.frame or anchor
end

local function GetMenuRootFrame()
    return UIParent or WorldFrame
end

local function Clamp(value, minimum, maximum)
    local numericValue = tonumber(value) or 0
    local minValue = tonumber(minimum)
    local maxValue = tonumber(maximum)

    if minValue and numericValue < minValue then
        numericValue = minValue
    end
    if maxValue and numericValue > maxValue then
        numericValue = maxValue
    end

    return numericValue
end

function ContextMenu:New(options)
    local instance = BaseElement.New(self, options)
    local floating = not (options and options.floating == false)
    if floating then
        instance.options.frameStrata = instance.options.frameStrata or "TOOLTIP"
        instance.options.frameLevel = instance.options.frameLevel or 200
        if instance.options.toplevel == nil then
            instance.options.toplevel = true
        end
        if instance.options.clampedToScreen == nil then
            instance.options.clampedToScreen = true
        end
    end
    instance.items = NormalizeItems(options and options.items or {})
    instance.multiSelect = options and options.multiSelect == true
    instance.selectedValues = BuildSelectionSet(options and (options.selectedValues or options.selectedItems) or {})
    instance.selectedValueOrder = BuildSelectionOrder(instance.items, instance.selectedValues, {})
    instance.selectedValue = options and options.selectedValue or nil
    if not instance.multiSelect and instance.selectedValue ~= nil then
        instance.selectedValues = {}
        instance.selectedValues[instance.selectedValue] = true
        instance.selectedValueOrder = { instance.selectedValue }
    end

    instance.visibleRows = options and options.visibleRows or 10
    instance.rowHeight = options and options.rowHeight or 20
    instance.rowSpacing = options and options.rowSpacing or 0
    instance.panelWidth = options and options.panelWidth or 140
    instance.panelSpacing = options and options.panelSpacing or 0
    instance.panelHeight = instance.visibleRows * instance.rowHeight + math.max(0, instance.visibleRows - 1) * instance.rowSpacing + 2
    instance.rootLayout = nil
    instance.panels = {}
    instance.scrollLayouts = {}
    instance.activePath = {}
    instance.hoveredItem = nil
    instance.hoveredDepth = nil
    instance.panelItems = {}
    instance.panelVisible = { false, false, false, false }
    instance.showSelectionActions = options and options.showSelectionActions == true
    instance.maxSelections = options and options.maxSelections or nil
    return instance
end

function ContextMenu:CanSelectMore()
    local maxSelections = tonumber(self.maxSelections)
    if not maxSelections or maxSelections <= 0 then
        return true
    end

    return CountSelectedValues(self.selectedValues) < maxSelections
end

function ContextMenu:UpdateItemAvailability(items)
    for index = 1, #(items or {}) do
        local item = items[index]
        local baseEnabled = item.baseEnabled ~= false

        if item.children and #item.children > 0 then
            self:UpdateItemAvailability(item.children)
            item.enabled = baseEnabled and HasEnabledLeaf(item)
        else
            local isSelected = self.selectedValues[item.value] == true
            item.enabled = baseEnabled and (isSelected or self:CanSelectMore())
        end
    end
end

function ContextMenu:BuildRootItems()
    local rootItems = {}

    if self.multiSelect and self.showSelectionActions then
        local selectedCount = CountSelectedValues(self.selectedValues)
        local canSelectMore = self:CanSelectMore()
        local allSelectableValues = CollectSelectableLeafValues(self.items, {})
        local hasUnselectedSelectable = false

        for index = 1, #allSelectableValues do
            if not self.selectedValues[allSelectableValues[index]] then
                hasUnselectedSelectable = true
                break
            end
        end

        rootItems[#rootItems + 1] = {
            label = "Select All",
            value = "__context_menu_select_all",
            enabled = hasUnselectedSelectable and canSelectMore,
            baseEnabled = hasUnselectedSelectable and canSelectMore,
            isAction = true,
            action = "select_all",
            keepShownOnClick = true,
            hasArrow = false,
            depth = 1,
        }
        rootItems[#rootItems + 1] = {
            label = "Clear",
            value = "__context_menu_clear_selection",
            enabled = selectedCount > 0,
            baseEnabled = selectedCount > 0,
            isAction = true,
            action = "clear_selection",
            keepShownOnClick = true,
            hasArrow = false,
            depth = 1,
        }
    end

    for index = 1, #self.items do
        rootItems[#rootItems + 1] = self.items[index]
    end

    return rootItems
end

function ContextMenu:GetSelectedValue()
    if self.multiSelect then
        return self:GetSelectedValues()
    end

    return self.selectedValue
end

function ContextMenu:GetSelectedValues()
    local values = {}
    for index = 1, #(self.selectedValueOrder or {}) do
        values[#values + 1] = self.selectedValueOrder[index]
    end
    return values
end

function ContextMenu:IsItemSelected(item)
    return item ~= nil and self.selectedValues[item.value] == true
end

function ContextMenu:IsItemSelectionHighlighted(item)
    return item ~= nil and HasSelectedDescendant(item, self.selectedValues)
end

function ContextMenu:SetSelectedValue(value, suppressCallback)
    if self.multiSelect then
        if value ~= nil then
            if self.selectedValues[value] then
                self.selectedValues[value] = nil
                self.selectedValueOrder = RemoveValueFromOrder(self.selectedValueOrder or {}, value)
            else
                self.selectedValues[value] = true
                self.selectedValueOrder = self.selectedValueOrder or {}
                self.selectedValueOrder[#self.selectedValueOrder + 1] = value
            end
        end
    else
        self.selectedValue = value
        self.selectedValues = {}
        self.selectedValueOrder = {}
        if value ~= nil then
            self.selectedValues[value] = true
            self.selectedValueOrder[1] = value
        end
    end

    self:RefreshVisiblePanels()

    if not suppressCallback and self.options.onValueChanged then
        self.options.onValueChanged(self:GetSelectedValue(), FindItemByValue(self.items, value), self)
    end
end

function ContextMenu:SetSelectedValues(values, suppressCallback)
    if not self.multiSelect then
        local firstValue = nil
        if type(values) == "table" then
            for key, value in pairs(values) do
                firstValue = value == true and key or value
                break
            end
        else
            firstValue = values
        end

        self:SetSelectedValue(firstValue, suppressCallback)
        return
    end

    self.selectedValues = BuildSelectionSet(values)
    self.selectedValueOrder = BuildSelectionOrder(self.items, self.selectedValues, {})
    self:RefreshVisiblePanels()

    if not suppressCallback and self.options.onValueChanged then
        local selectedItem = nil
        if #self.selectedValueOrder > 0 then
            selectedItem = FindItemByValue(self.items, self.selectedValueOrder[#self.selectedValueOrder])
        end
        self.options.onValueChanged(self:GetSelectedValues(), selectedItem, self)
    end
end

function ContextMenu:SetItems(items)
    self.items = NormalizeItems(items or {})
    if self.multiSelect then
        self.selectedValueOrder = BuildSelectionOrder(self.items, self.selectedValues, {})
    elseif self.selectedValue ~= nil and not FindItemByValue(self.items, self.selectedValue) then
        self.selectedValue = nil
        self.selectedValues = {}
        self.selectedValueOrder = {}
    end

    self.activePath = {}
    self:RefreshVisiblePanels()
end

function ContextMenu:SetPanelWidth(width)
    local resolvedWidth = math.floor(Clamp(width, 1, nil) + 0.5)
    self.panelWidth = resolvedWidth

    for depth = 1, MAX_MENU_DEPTH do
        local panel = self.panels[depth]
        if panel and panel.SetWidth then
            panel:SetWidth(resolvedWidth)
        end

        local scroll = self.scrollLayouts[depth]
        if scroll and scroll.SetWidth then
            scroll:SetWidth(resolvedWidth)
        end
    end

    if self.rootLayout and self.rootLayout.RefreshLayout then
        self.rootLayout:RefreshLayout()
    end
    self:UpdateVisibleWidth()
end

function ContextMenu:SetPanelVisible(depth, isVisible)
    local panel = self.panels[depth]
    if not panel or not panel.GetFrame then
        return
    end

    self.panelVisible[depth] = isVisible == true
    local panelFrame = panel:GetFrame()
    if isVisible then
        panelFrame:Show()
    else
        panelFrame:Hide()
    end
end

function ContextMenu:RefreshPanel(depth, items, isVisible)
    local scroll = self.scrollLayouts[depth]
    if not scroll then
        return
    end

    local resolvedItems = items or {}
    self.panelItems[depth] = resolvedItems
    scroll:SetItems(resolvedItems)
    self:SetPanelVisible(depth, isVisible)
end

function ContextMenu:UpdateVisibleWidth()
    local frame = self.frame
    if not frame then
        return
    end

    local visibleCount = 0
    for depth = 1, MAX_MENU_DEPTH do
        if self.panelVisible[depth] == true then
            visibleCount = visibleCount + 1
        end
    end

    if visibleCount <= 0 then
        visibleCount = 1
    end

    local totalWidth = (self.panelWidth * visibleCount) + (self.panelSpacing * math.max(0, visibleCount - 1))
    frame:SetWidth(totalWidth)

    if self.rootLayout and self.rootLayout.SetWidth then
        self.rootLayout:SetWidth(totalWidth)
    end
end

function ContextMenu:RefreshVisiblePanels()
    self:UpdateItemAvailability(self.items)
    self:RefreshPanel(1, self:BuildRootItems(), self.frame and self.frame:IsShown())

    local parentItem = self.activePath[1]
    for depth = 2, MAX_MENU_DEPTH do
        if parentItem and parentItem.children and #parentItem.children > 0 then
            self:RefreshPanel(depth, parentItem.children, self.frame and self.frame:IsShown())
            parentItem = self.activePath[depth]
        else
            self.activePath[depth] = nil
            self:RefreshPanel(depth, {}, false)
            parentItem = nil
        end
    end

    self:UpdateVisibleWidth()

    if self.rootLayout and self.rootLayout.RefreshLayout then
        self.rootLayout:RefreshLayout()
    end
end

function ContextMenu:ApplyItemPath(depth, item)
    self.activePath[depth] = item
    for clearDepth = depth + 1, MAX_MENU_DEPTH do
        self.activePath[clearDepth] = nil
    end
    self:RefreshVisiblePanels()
end

function ContextMenu:HandleItemHover(depth, item)
    if not item or item.enabled == false then
        return
    end

    self.hoveredItem = item
    self.hoveredDepth = depth

    if item.isAction == true then
        return
    end

    self:ApplyItemPath(depth, item)
end

function ContextMenu:HandleItemClick(depth, item)
    if not item or item.enabled == false or item.isTitle == true then
        return
    end

    if item.isAction == true then
        if item.action == "select_all" then
            local values = {}
            local allSelectableValues = CollectSelectableLeafValues(self.items, {})
            local maxSelections = tonumber(self.maxSelections)
            local limit = maxSelections and maxSelections > 0 and maxSelections or #allSelectableValues

            for index = 1, #allSelectableValues do
                if #values >= limit then
                    break
                end
                values[#values + 1] = allSelectableValues[index]
            end

            self:SetSelectedValues(values)
        elseif item.action == "clear_selection" then
            self:SetSelectedValues({})
        end
        return
    end

    self:ApplyItemPath(depth, item)

    if item.children and #item.children > 0 then
        return
    end

    if not item.notCheckable then
        self:SetSelectedValue(item.value)
    end

    if self.options.onItemInvoked then
        self.options.onItemInvoked(item, self)
    end

    if not self.multiSelect and item.keepShownOnClick ~= true then
        self:HideMenus()
    end
end

function ContextMenu:OpenPath(pathSpec)
    self.activePath = {}
    if type(pathSpec) ~= "table" then
        self:RefreshVisiblePanels()
        return
    end

    local matchedPath = FindItemPath(self.items, pathSpec, 1, {})
    for depth = 1, MAX_MENU_DEPTH do
        self.activePath[depth] = matchedPath[depth]
    end

    self:RefreshVisiblePanels()
end

function ContextMenu:HideMenus()
    self.activePath = {}
    self.anchorOwner = nil
    self:Hide()
    self:RefreshVisiblePanels()
end

function ContextMenu.HideAll(excludedMenu)
    local activeMenus = ContextMenu.ActiveMenus or {}
    for index = #activeMenus, 1, -1 do
        local menu = activeMenus[index]
        if menu == nil then
            table.remove(activeMenus, index)
        elseif menu ~= excludedMenu and menu.HideMenus then
            menu:HideMenus()
        end
    end
end

function ContextMenu:ShowAt(anchor)
    local frame = self:GetFrame()
    if not frame then
        return
    end

    local isFloating = not (self.options and self.options.floating == false)
    if isFloating then
        local rootFrame = GetMenuRootFrame()
        if rootFrame and frame:GetParent() ~= rootFrame then
            frame:SetParent(rootFrame)
        end
    end

    frame:ClearAllPoints()

    if type(anchor) == "table" and not anchor.GetObjectType and not anchor.GetFrame and anchor.frame == nil then
        frame:SetPoint(
            anchor.point or "TOPLEFT",
            ResolveAnchorTarget(anchor.relativeTo or anchor.frame) or GetMenuRootFrame(),
            anchor.relativePoint or "TOPLEFT",
            anchor.x or 0,
            anchor.y or 0
        )
    elseif anchor then
        frame:SetPoint("TOPLEFT", ResolveAnchorTarget(anchor), "BOTTOMLEFT", 0, 0)
    else
        frame:SetPoint("CENTER", GetMenuRootFrame(), "CENTER", 0, 0)
    end

    frame:Show()
    local activeMenus = ContextMenu.ActiveMenus or {}
    for index = #activeMenus, 1, -1 do
        if activeMenus[index] == self then
            table.remove(activeMenus, index)
        end
    end
    activeMenus[#activeMenus + 1] = self
    self:RefreshVisiblePanels()
end

function ContextMenu:Hide()
    if self.frame and self.frame.Hide then
        self.frame:Hide()
    end

    self.anchorOwner = nil

    for depth = 1, MAX_MENU_DEPTH do
        self:SetPanelVisible(depth, false)
    end

    local activeMenus = ContextMenu.ActiveMenus or {}
    for index = #activeMenus, 1, -1 do
        if activeMenus[index] == self then
            table.remove(activeMenus, index)
        end
    end
end

function ContextMenu:CreatePanel(depth)
    local panel = UI.Panel:New({
        name = (self.name or "ContextMenu") .. "Panel" .. depth,
        width = self.panelWidth,
        height = self.panelHeight,
        border = false,
        contentInset = 1,
        panelBackgroundColor = UI.ResolveColor(self.options.panelBackgroundColor, "dropdown.background"),
        panelBorderColor = UI.ResolveColor(self.options.panelBorderColor, "dropdown.border"),
    })
    panel:SetParent(self.rootLayout:GetFrame())
    panel:Create()

    local scroll = UI.ScrollLayout:New({
        name = (self.name or "ContextMenu") .. "Scroll" .. depth,
        width = self.panelWidth,
        height = self.panelHeight,
        visibleRows = self.visibleRows,
        rowHeight = self.rowHeight,
        rowSpacing = self.rowSpacing,
        border = false,
        rowElementClass = UI.ContextMenuEntry,
    })
    scroll:SetParent(panel:GetContentFrame())
    scroll:SetRowRenderer(function(row, item, absoluteIndex)
        if row.SetItem then
            row:SetSelected(self:IsItemSelected(item))
            row:SetSelectionHighlighted(self:IsItemSelectionHighlighted(item))
            row:SetHighlighted(self.activePath[depth] == item)
            row:SetItem(item, self, depth, absoluteIndex)
            if self.hoveredItem == item and self.hoveredDepth == depth and row.GetTooltip and row:GetTooltip() then
                row:ShowTooltip()
            end
        end
    end)
    scroll:Create()
    scroll:SetPoint("TOPLEFT", panel:GetContentFrame(), "TOPLEFT", 0, 0)
    scroll:SetPoint("TOPRIGHT", panel:GetContentFrame(), "TOPRIGHT", 0, 0)
    scroll:SetPoint("BOTTOMLEFT", panel:GetContentFrame(), "BOTTOMLEFT", 0, 0)
    scroll:SetPoint("BOTTOMRIGHT", panel:GetContentFrame(), "BOTTOMRIGHT", 0, 0)

    self.panels[depth] = panel
    self.scrollLayouts[depth] = scroll
    self.rootLayout:AddChild(panel)
end

function ContextMenu:Create()
    if self.frame then
        return self.frame
    end

    local totalWidth = self.options.width or (self.panelWidth * MAX_MENU_DEPTH) + (self.panelSpacing * (MAX_MENU_DEPTH - 1))
    local parentFrame = self:GetParentFrame()
    if not (self.options and self.options.floating == false) then
        parentFrame = GetMenuRootFrame()
    end
    local frame = CreateFrame("Frame", self.name, parentFrame, self.options.template)
    self:SetFrame(frame)
    frame:SetSize(totalWidth, self.panelHeight)
    frame:Hide()

    self.rootLayout = UI.HorizontalLayoutGroup:New({
        name = (self.name or "ContextMenu") .. "Layout",
        width = totalWidth,
        height = self.panelHeight,
        spacing = self.panelSpacing,
        fitChildrenWidth = false,
        fitChildrenHeight = true,
        border = false,
    })
    self.rootLayout:SetParent(frame)
    self.rootLayout:Create()
    self.rootLayout:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    self.rootLayout:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    self.rootLayout:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    self.rootLayout:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)

    for depth = 1, MAX_MENU_DEPTH do
        self:CreatePanel(depth)
    end

    self:RefreshVisiblePanels()
    self:Hide()
    return self.frame
end
