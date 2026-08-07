local _, Addon = ...

local UI = Addon.UI or {}
Addon.UI = UI
local BaseElement = UI.BaseElement
local Constants = UI.Constants or {}
local Font = UI.Font or {}

local MAX_MENU_DEPTH = 4
local CATEGORY_TEXTURE_PATH = "Interface\\AddOns\\RPEngine_Dev\\data\\textures\\ui\\category.png"

UI.Dropdown = UI.Dropdown or {}
local Dropdown = UI.Dropdown
Dropdown.__index = Dropdown
setmetatable(Dropdown, { __index = BaseElement })
Dropdown.SharedContextMenu = Dropdown.SharedContextMenu or nil
Dropdown.SharedContextMenuOwner = Dropdown.SharedContextMenuOwner or nil

local function NormalizeItem(item, index, depth)
    local currentDepth = depth or 1
    if type(item) ~= "table" then
        return {
            label = tostring(item),
            value = item,
            depth = currentDepth,
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
        icon = item.icon or item.texture,
        iconWidth = item.iconWidth,
        iconHeight = item.iconHeight,
        iconCoords = item.iconCoords,
        checked = item.checked,
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

local function GetItemChildren(item)
    if type(item) ~= "table" then
        return nil
    end

    local children = item.children or item.items
    if type(children) == "table" and #children > 0 then
        return children
    end

    return nil
end

local function HasSelectedDescendant(item, selectedValues)
    if type(item) ~= "table" or type(selectedValues) ~= "table" then
        return false
    end

    local selectionSet = BuildSelectionSet(selectedValues)

    if selectionSet[item.value] then
        return true
    end

    local children = GetItemChildren(item)
    if not children then
        return false
    end

    for index = 1, #children do
        if HasSelectedDescendant(children[index], selectionSet) then
            return true
        end
    end

    return false
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

local function FindRootItemIndexByValue(items, value)
    for index = 1, #(items or {}) do
        if items[index].value == value then
            return index
        end
    end

    return 0
end

local function CollectSelectedItems(items, selectedValues, output)
    local results = output or {}
    for index = 1, #(items or {}) do
        local item = items[index]
        if selectedValues[item.value] then
            results[#results + 1] = item
        end

        if item.children and #item.children > 0 then
            CollectSelectedItems(item.children, selectedValues, results)
        end
    end

    return results
end

local function CreatePanelBorder(panel, color)
    local borderColor = color or { r = 0.16, g = 0.18, b = 0.22, a = 1 }

    panel.borderTop = panel:CreateTexture(nil, "ARTWORK")
    panel.borderTop:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
    panel.borderTop:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, 0)
    panel.borderTop:SetHeight(1)
    panel.borderTop:SetColorTexture(borderColor.r or 0, borderColor.g or 0, borderColor.b or 0, borderColor.a or 1)

    panel.borderBottom = panel:CreateTexture(nil, "ARTWORK")
    panel.borderBottom:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 0, 0)
    panel.borderBottom:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0, 0)
    panel.borderBottom:SetHeight(1)
    panel.borderBottom:SetColorTexture(borderColor.r or 0, borderColor.g or 0, borderColor.b or 0, borderColor.a or 1)

    panel.borderLeft = panel:CreateTexture(nil, "ARTWORK")
    panel.borderLeft:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
    panel.borderLeft:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 0, 0)
    panel.borderLeft:SetWidth(1)
    panel.borderLeft:SetColorTexture(borderColor.r or 0, borderColor.g or 0, borderColor.b or 0, borderColor.a or 1)

    panel.borderRight = panel:CreateTexture(nil, "ARTWORK")
    panel.borderRight:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, 0)
    panel.borderRight:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0, 0)
    panel.borderRight:SetWidth(1)
    panel.borderRight:SetColorTexture(borderColor.r or 0, borderColor.g or 0, borderColor.b or 0, borderColor.a or 1)
end

local function CreatePopupBorder(panel, color)
    local borderColor = color or { r = 0.2, g = 0.22, b = 0.28, a = 1 }
    local shadowColor = { r = 0, g = 0, b = 0, a = 0.85 }

    panel.shadowTop = panel:CreateTexture(nil, "BACKGROUND")
    panel.shadowTop:SetPoint("TOPLEFT", panel, "TOPLEFT", -1, 1)
    panel.shadowTop:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 1, 1)
    panel.shadowTop:SetHeight(1)
    panel.shadowTop:SetColorTexture(shadowColor.r, shadowColor.g, shadowColor.b, shadowColor.a)

    panel.shadowBottom = panel:CreateTexture(nil, "BACKGROUND")
    panel.shadowBottom:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", -1, -1)
    panel.shadowBottom:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 1, -1)
    panel.shadowBottom:SetHeight(1)
    panel.shadowBottom:SetColorTexture(shadowColor.r, shadowColor.g, shadowColor.b, shadowColor.a)

    panel.shadowLeft = panel:CreateTexture(nil, "BACKGROUND")
    panel.shadowLeft:SetPoint("TOPLEFT", panel, "TOPLEFT", -1, 1)
    panel.shadowLeft:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", -1, -1)
    panel.shadowLeft:SetWidth(1)
    panel.shadowLeft:SetColorTexture(shadowColor.r, shadowColor.g, shadowColor.b, shadowColor.a)

    panel.shadowRight = panel:CreateTexture(nil, "BACKGROUND")
    panel.shadowRight:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 1, 1)
    panel.shadowRight:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 1, -1)
    panel.shadowRight:SetWidth(1)
    panel.shadowRight:SetColorTexture(shadowColor.r, shadowColor.g, shadowColor.b, shadowColor.a)

    CreatePanelBorder(panel, borderColor)
end

function Dropdown:New(options)
    local instance = BaseElement.New(self, options)
    instance.items = NormalizeItems(options and options.items or {})
    instance.selectedIndex = options and options.selectedIndex or 1
    instance.selectedValue = options and options.selectedValue or nil
    instance.selectedValues = BuildSelectionSet(options and (options.selectedValues or options.selectedItems) or {})
    instance.selectedValueOrder = BuildSelectionOrder(instance.items, instance.selectedValues, {})
    instance.multiSelect = options and options.multiSelect == true
    instance.button = nil
    instance.label = nil
    instance.arrow = nil
    instance.dropdownFrame = nil
    return instance
end

function Dropdown:EnsureContextMenu()
    if Dropdown.SharedContextMenu or not UI.ContextMenu then
        return Dropdown.SharedContextMenu
    end

    local popupWidth = self.options.popupWidth or self.options.width or 140
    Dropdown.SharedContextMenu = UI.ContextMenu:New({
        name = "RPEngineDropdownSharedContextMenu",
        width = popupWidth * 4,
        panelWidth = popupWidth,
        frameStrata = "TOOLTIP",
        frameLevel = 200,
        toplevel = true,
        clampedToScreen = true,
        visibleRows = self.options.visibleRows or self.options.rowCount or 10,
        rowHeight = self.options.popupRowHeight or 18,
        rowSpacing = self.options.popupRowSpacing or 0,
        items = self.items,
        multiSelect = self.multiSelect,
        showSelectionActions = self.multiSelect and self.options.showSelectionActions ~= false,
        maxSelections = self.options.maxSelections,
        selectedValue = self.selectedValue,
        selectedValues = self.selectedValues,
        border = false,
        onValueChanged = function(value, item)
            local owner = Dropdown.SharedContextMenuOwner
            if not owner then
                return
            end

            local ownerItems = owner.items or {}
            if owner.multiSelect then
                owner.selectedValues = {}
                owner.selectedValueOrder = {}
                if type(value) == "table" then
                    for index = 1, #value do
                        local selectedValue = value[index]
                        owner.selectedValues[selectedValue] = true
                        owner.selectedValueOrder[#owner.selectedValueOrder + 1] = selectedValue
                    end
                end

                owner.selectedIndex = 0
                for index = 1, #ownerItems do
                    if owner.selectedValues[ownerItems[index].value] then
                        owner.selectedIndex = index
                        break
                    end
                end
            else
                owner.selectedValue = value
                owner.selectedValues = {}
                owner.selectedValueOrder = {}
                if value ~= nil then
                    owner.selectedValues[value] = true
                    owner.selectedValueOrder[1] = value
                end

                owner.selectedIndex = FindRootItemIndexByValue(ownerItems, value)
            end

            owner:UpdateLabel()

            if owner.options.onValueChanged then
                owner.options.onValueChanged(owner:GetSelectedValue(), item or owner:GetSelectedItem(), owner)
            end
        end,
    })
    local sharedContextMenu = Dropdown.SharedContextMenu
    if sharedContextMenu and sharedContextMenu.SetParent then
        sharedContextMenu:SetParent(WorldFrame or UIParent)
    end
    if sharedContextMenu and sharedContextMenu.Create then
        sharedContextMenu:Create()
    end
    return Dropdown.SharedContextMenu
end

function Dropdown:ToggleContextMenu()
    local contextMenu = self:EnsureContextMenu()
    if not contextMenu then
        return
    end

    contextMenu:SetWidth((self.options.popupWidth or self.options.width or 140) * 4)
    contextMenu.panelWidth = self.options.popupWidth or self.options.width or 140
    contextMenu.multiSelect = self.multiSelect == true
    contextMenu.showSelectionActions = contextMenu.multiSelect and self.options.showSelectionActions ~= false
    contextMenu.maxSelections = self.options.maxSelections
    contextMenu.selectedValue = self.selectedValue
    contextMenu.selectedValues = BuildSelectionSet(self.selectedValues)
    contextMenu.selectedValueOrder = BuildSelectionOrder(contextMenu.items or self.items, contextMenu.selectedValues, {})
    contextMenu.activePath = {}
    contextMenu.hoveredItem = nil
    contextMenu.hoveredDepth = nil
    contextMenu:SetItems(self.items)
    if self.multiSelect then
        contextMenu:SetSelectedValues(self.selectedValues, true)
    else
        contextMenu:SetSelectedValue(self:GetSelectedValue(), true)
    end

    local menuFrame = contextMenu:GetFrame()
    if menuFrame and menuFrame:IsShown() and Dropdown.SharedContextMenuOwner == self then
        contextMenu:HideMenus()
        Dropdown.SharedContextMenuOwner = nil
    else
        if UI.ContextMenu and UI.ContextMenu.HideAll then
            UI.ContextMenu.HideAll(contextMenu)
        end
        Dropdown.SharedContextMenuOwner = self
        contextMenu.anchorOwner = self
        contextMenu:ShowAt(self.frame or self.dropdownFrame)
    end
end

function Dropdown:GetSelectedIndex()
    return self.selectedIndex or 1
end

function Dropdown:GetSelectedItem()
    if self.multiSelect then
        local selectedValue = self.selectedValueOrder and self.selectedValueOrder[1] or nil
        if selectedValue ~= nil then
            return FindItemByValue(self.items, selectedValue)
        end
        local selectedItems = CollectSelectedItems(self.items, self.selectedValues, {})
        return selectedItems[1]
    end

    if self.selectedValue ~= nil then
        local selectedItem = FindItemByValue(self.items, self.selectedValue)
        if selectedItem then
            return selectedItem
        end
    end

    return self.items and self.items[self:GetSelectedIndex()] or nil
end

function Dropdown:GetSelectedValue()
    if self.multiSelect then
        local values = {}
        for index = 1, #(self.selectedValueOrder or {}) do
            values[#values + 1] = self.selectedValueOrder[index]
        end
        return values
    end

    local item = self:GetSelectedItem()
    if item then
        return item.value
    end

    return self.selectedValue
end

function Dropdown:GetSelectedValues()
    if not self.multiSelect then
        local value = self:GetSelectedValue()
        return value ~= nil and { value } or {}
    end

    local values = {}
    for index = 1, #(self.selectedValueOrder or {}) do
        values[#values + 1] = self.selectedValueOrder[index]
    end
    return values
end

function Dropdown:SetItems(items)
    self.items = NormalizeItems(items or {})
    if self.multiSelect then
        self.selectedValueOrder = BuildSelectionOrder(self.items, self.selectedValues, {})
    end

    if self.selectedIndex > #self.items then
        self.selectedIndex = #self.items
    end

    if self.selectedIndex < 1 then
        self.selectedIndex = self.items[1] and 1 or 0
    end

    self:UpdateLabel()

end

function Dropdown:SetEnabled(enabled)
    self.enabled = enabled ~= false

    local frame = self.frame or self.dropdownFrame
    if not frame then
        return self.enabled
    end

    if frame.Enable then
        if self.enabled then
            frame:Enable()
        else
            frame:Disable()
        end
    elseif frame.EnableMouse then
        frame:EnableMouse(self.enabled)
    end

    if frame.SetAlpha then
        frame:SetAlpha(self.enabled and 1 or 0.45)
    end

    return self.enabled
end

function Dropdown:SetSelectedIndex(index, suppressCallback)
    if #self.items == 0 then
        self.selectedIndex = 0
        self.selectedValue = nil
        self:UpdateLabel()
        return
    end

    local clamped = math.max(1, math.min(index or 1, #self.items))
    self.selectedIndex = clamped
    self.selectedValue = self.items[clamped].value
    self.selectedValues = {}
    self.selectedValues[self.selectedValue] = true
    self.selectedValueOrder = { self.selectedValue }
    self:UpdateLabel()

    if not suppressCallback and self.options.onValueChanged then
        self.options.onValueChanged(self:GetSelectedValue(), self:GetSelectedItem(), self)
    end
end

function Dropdown:SetSelectedValue(value, suppressCallback)
    if self.multiSelect then
        if value ~= nil then
            self.selectedValues = self.selectedValues or {}
            if self.selectedValues[value] then
                self.selectedValues[value] = nil
                self.selectedValueOrder = RemoveValueFromOrder(self.selectedValueOrder or {}, value)
            else
                self.selectedValues[value] = true
                self.selectedValueOrder = self.selectedValueOrder or {}
                self.selectedValueOrder[#self.selectedValueOrder + 1] = value
            end
        end

        self.selectedIndex = 0
        for index = 1, #self.items do
            if self.selectedValues[self.items[index].value] then
                self.selectedIndex = index
                break
            end
        end

        self:UpdateLabel()
        if not suppressCallback and self.options.onValueChanged then
            self.options.onValueChanged(self:GetSelectedValue(), self:GetSelectedItem(), self)
        end
        return
    end

    local foundItem = FindItemByValue(self.items, value)
    if foundItem then
        local rootIndex = FindRootItemIndexByValue(self.items, value)
        if rootIndex > 0 then
            self:SetSelectedIndex(rootIndex, suppressCallback)
            return
        end

        self.selectedIndex = 0
        self.selectedValue = foundItem.value
        self.selectedValues = {}
        self.selectedValues[foundItem.value] = true
        self.selectedValueOrder = { foundItem.value }
        self:UpdateLabel()

        if not suppressCallback and self.options.onValueChanged then
            self.options.onValueChanged(self:GetSelectedValue(), self:GetSelectedItem(), self)
        end
    end
end

function Dropdown:SetSelectedValues(values, suppressCallback)
    if not self.multiSelect then
        local firstValue = nil
        if type(values) == "table" then
            for key, value in pairs(values) do
                firstValue = value == true and key or value
                break
            end
        end
        self:SetSelectedValue(firstValue, suppressCallback)
        return
    end

    self.selectedValues = BuildSelectionSet(values)
    self.selectedValueOrder = BuildSelectionOrder(self.items, self.selectedValues, {})
    self.selectedIndex = 0

    for index = 1, #self.items do
        if self.selectedValues[self.items[index].value] then
            self.selectedIndex = index
            break
        end
    end

    self:UpdateLabel()
    if not suppressCallback and self.options.onValueChanged then
        self.options.onValueChanged(self:GetSelectedValue(), self:GetSelectedItem(), self)
    end
end

function Dropdown:IsItemSelected(item)
    if not item then
        return false
    end

    if self.multiSelect then
        return self.selectedValues[item.value] == true
    end

    return self:GetSelectedValue() == item.value
end

function Dropdown:GetDisplayWidth()
    local frame = self.frame or self.dropdownFrame
    if frame and frame.GetWidth then
        local width = frame:GetWidth() or 0
        if width > 0 then
            return math.floor(width + 0.5)
        end
    end

    return self.options.width or 100
end

function Dropdown:UpdateLabel()
    local text = self.options.placeholder or "Select..."

    if self.multiSelect then
        local count = #CollectSelectedItems(self.items, self.selectedValues, {})

        if count == 1 then
            local item = self:GetSelectedItem()
            text = item and item.label or text
        elseif count > 1 then
            text = ("%d selected"):format(count)
        end
    else
        local item = self:GetSelectedItem()
        text = item and item.label or text
    end

    if self.label and self.label.SetText then
        self.label:SetText(text)
    end
end

function Dropdown:SelectItem(item)
    if not item then
        return
    end

    if item.children and #item.children > 0 then
        return
    end

    if self.multiSelect then
        if self.selectedValues[item.value] then
            self.selectedValues[item.value] = nil
            self.selectedValueOrder = RemoveValueFromOrder(self.selectedValueOrder or {}, item.value)
        else
            self.selectedValues[item.value] = true
            self.selectedValueOrder = self.selectedValueOrder or {}
            self.selectedValueOrder[#self.selectedValueOrder + 1] = item.value
        end

        self.selectedIndex = FindRootItemIndexByValue(self.items, item.value)
    self:UpdateLabel()

    if self.options.onValueChanged then
        self.options.onValueChanged(self:GetSelectedValue(), item, self)
    end
        return
    end

    self:SetSelectedValue(item.value)
end

function Dropdown:Create()
    if self.frame then
        return self.frame
    end

    local parentFrame = self:GetParentFrame()
    if not parentFrame then
        error("A dropdown element requires a parent frame before Create().", 2)
    end

    local frame = CreateFrame("Button", self.name, parentFrame)
    self:SetFrame(frame)
    self.dropdownFrame = frame
    self.button = frame

    local width = self.options.width or 140
    local height = self.options.height or 18
    frame:SetSize(width, height)

    if frame.RegisterForClicks then
        frame:RegisterForClicks("AnyUp")
    end

    self.background = frame:CreateTexture(nil, "BACKGROUND")
    self.background:SetAllPoints(frame)
    local backgroundColor = UI.ResolveColor(self.options.backgroundColor, "panel.background")
    self.background:SetColorTexture(backgroundColor.r or 0.08, backgroundColor.g or 0.09, backgroundColor.b or 0.12, backgroundColor.a or 0.85)
    CreatePanelBorder(frame, UI.ResolveColor(self.options.borderColor, "dropdown.border"))

    self.label = frame:CreateFontString(nil, "OVERLAY")
    self.label:SetPoint("LEFT", frame, "LEFT", 6, 0)
    self.label:SetPoint("RIGHT", frame, "RIGHT", -18, 0)
    self.label:SetJustifyH("LEFT")
    self.label:SetJustifyV("MIDDLE")
    Font:Apply(self.label, self.options, {
        fontSize = (Constants.FontSizes and Constants.FontSizes.Dropdown) or 12,
    })

    local textColor = UI.ResolveColor(self.options.textColor, "text.primary")
    if textColor and self.label.SetTextColor then
        self.label:SetTextColor(textColor.r or 1, textColor.g or 1, textColor.b or 1, textColor.a or 1)
    end

    self.arrow = frame:CreateFontString(nil, "OVERLAY")
    self.arrow:SetPoint("RIGHT", frame, "RIGHT", -6, 0)
    self.arrow:SetJustifyH("RIGHT")
    self.arrow:SetJustifyV("MIDDLE")
    Font:Apply(self.arrow, self.options, {
        fontSize = (Constants.FontSizes and Constants.FontSizes.Dropdown) or 12,
    })
    self.arrow:SetText("v")
    local arrowColor = UI.ResolveColor(self.options.arrowColor, "text.muted")
    if self.arrow.SetTextColor then
        self.arrow:SetTextColor(arrowColor.r or 1, arrowColor.g or 1, arrowColor.b or 1, arrowColor.a or 1)
    end

    frame:SetScript("OnClick", function()
        self:ToggleContextMenu()
    end)

    self:UpdateLabel()
    self:SetEnabled(self.enabled ~= false)
    self:EnsureContextMenu()
    return self.frame
end
