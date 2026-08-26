local _, Addon = ...

local UI = Addon.UI or {}
Addon.UI = UI

local BaseElement = UI.BaseElement
local Common = Addon.Utils and Addon.Utils.Common or {}
local Runtime = Addon.Internal and Addon.Internal.Runtime or {}

UI.CurrencyPanel = UI.CurrencyPanel or {}
local CurrencyPanel = UI.CurrencyPanel
CurrencyPanel.__index = CurrencyPanel
setmetatable(CurrencyPanel, { __index = BaseElement })

local function ensureString(value)
    if value == nil then
        return ""
    end

    return tostring(value)
end

local function buildIconMarkup(icon)
    local normalized = icon
    if normalized == nil or normalized == "" then
        normalized = "Interface\\Icons\\INV_Misc_QuestionMark"
    end

    return ("|T%s:14:14:0:0|t"):format(tostring(normalized))
end

local function getRuntimeRevision(domain)
    if type(Runtime) == "table" and type(Runtime.GetRevision) == "function" then
        return math.max(0, math.floor(tonumber(Runtime:GetRevision(domain)) or 0))
    end

    return 0
end

local function getConfigurationRevision()
    return math.max(0, math.floor(tonumber(Addon.Internal and Addon.Internal.ConfigurationRevision) or 0))
end

local function buildTooltip(definition, amount, amountText)
    local lines = {}
    local description = ensureString(definition and definition.description)
    if description ~= "" then
        lines[#lines + 1] = { text = description }
    end

    lines[#lines + 1] = { text = ("Current: %s"):format(amountText) }
    local maxAmount = definition and definition.max
    if maxAmount == nil then
        lines[#lines + 1] = { text = "Max: Unknown" }
    else
        lines[#lines + 1] = { text = ("Max: %d"):format(math.max(0, math.floor(tonumber(maxAmount) or 0))) }
    end

    if definition and definition.builtin ~= true then
        local datasetName = ensureString(definition.datasetName)
        if datasetName ~= "" then
            lines[#lines + 1] = { text = ("Dataset: %s"):format(datasetName) }
        end

        local stateText = "Inactive"
        if definition.isMissing == true then
            stateText = "Missing"
        elseif definition.isActive == true then
            stateText = "Active"
        end
        lines[#lines + 1] = { text = ("Source: %s"):format(stateText) }
    end

    return {
        type = "custom",
        title = ensureString(definition and definition.name) ~= "" and definition.name or "Currency",
        lines = lines,
    }
end

local function getDefaultProvider()
    local Profile = Addon.Internal and Addon.Internal.Profile or {}
    return function()
        local definitions = Profile.ListCurrencyDefinitions and Profile.ListCurrencyDefinitions({
            includeBuiltins = true,
            includeCustom = true,
            includeInactive = true,
            includeMissingBalances = true,
        }) or {}
        local items = {}
        local copperDefinition = Profile.ResolveCurrencyDefinition and Profile.ResolveCurrencyDefinition("copper") or nil
        local copperAmount = Profile.GetCurrencyAmount and Profile.GetCurrencyAmount("copper") or 0

        for index = 1, #definitions do
            local definition = definitions[index]
            local amount = Profile.GetCurrencyAmount and Profile.GetCurrencyAmount(definition.key) or 0
            if amount > 0 then
                items[#items + 1] = {
                    definition = definition,
                    amount = amount,
                    amountText = Profile.FormatCurrencyAmount and Profile.FormatCurrencyAmount(definition, amount) or tostring(amount),
                }
            end
        end

        return {
            items = items,
            summaryDefinition = copperDefinition,
            summaryAmount = copperAmount,
            summaryAmountText = Profile.FormatCurrencyAmount and Profile.FormatCurrencyAmount(copperDefinition or "copper", copperAmount) or tostring(copperAmount),
        }
    end
end

function CurrencyPanel:New(options)
    local instance = BaseElement.New(self, options)
    instance.options.border = false
    instance.panel = nil
    instance.summaryButton = nil
    instance.summaryTitleText = nil
    instance.summaryAmountText = nil
    instance.summaryArrowText = nil
    instance.scroll = nil
    instance.emptyText = nil
    instance.items = {}
    instance.provider = (options and options.provider) or getDefaultProvider()
    instance.summaryDefinition = nil
    instance.summaryAmount = 0
    instance.summaryAmountTextValue = "0"
    instance.isExpanded = options and options.defaultExpanded == true or false
    instance.collapsedHeight = tonumber(options and options.collapsedHeight) or 22
    instance.expandedHeight = tonumber(options and options.height) or 108
    instance.summaryRowHeight = tonumber(options and options.summaryRowHeight) or 18
    instance.onHeightChanged = options and options.onHeightChanged or nil
    instance.currencyRevision = -1
    instance.configurationRevision = -1
    instance.dirty = true
    return instance
end

function CurrencyPanel:SetProvider(provider)
    if type(provider) == "function" then
        self.provider = provider
    else
        self.provider = getDefaultProvider()
    end
    self.dirty = true
end

function CurrencyPanel:SetItems(items)
    self.items = type(items) == "table" and items or {}
    if self.scroll and self.scroll.SetItems then
        self.scroll:SetItems(self.items)
    end
end

function CurrencyPanel:GetCurrentHeight()
    if self.isExpanded then
        return self.expandedHeight
    end

    return self.collapsedHeight
end

function CurrencyPanel:SetExpanded(isExpanded, options)
    local nextExpanded = isExpanded == true
    local previousHeight = self:GetCurrentHeight()
    self.isExpanded = nextExpanded

    if self.summaryArrowText and self.summaryArrowText.SetText then
        self.summaryArrowText:SetText(self.isExpanded and "^" or "v")
    end

    if self.scroll and self.scroll.GetFrame then
        local scrollFrame = self.scroll:GetFrame()
        if scrollFrame and scrollFrame.Show and scrollFrame.Hide then
            if self.isExpanded then
                scrollFrame:Show()
            else
                scrollFrame:Hide()
            end
        end
    end

    local currentHeight = self:GetCurrentHeight()
    if self.frame and self.frame.SetHeight then
        self.frame:SetHeight(currentHeight)
    end
    if self.panel and self.panel.GetFrame and self.panel:GetFrame() and self.panel:GetFrame().SetHeight then
        self.panel:GetFrame():SetHeight(currentHeight)
    end

    if self.scroll and self.scroll.UpdateGeometry then
        self.scroll:UpdateGeometry()
    end

    if not (type(options) == "table" and options.skipRefresh == true) then
        self:RefreshIfDirty()
    end

    if previousHeight ~= currentHeight and type(self.onHeightChanged) == "function" then
        self.onHeightChanged(self, currentHeight, previousHeight)
    end

    return self.isExpanded
end

function CurrencyPanel:ToggleExpanded()
    return self:SetExpanded(not self.isExpanded)
end

function CurrencyPanel:UpdateSummaryDisplay()
    local summaryDefinition = self.summaryDefinition or {}
    local amountText = ensureString(self.summaryAmountTextValue)
    if amountText == "" then
        amountText = tostring(math.max(0, math.floor(tonumber(self.summaryAmount) or 0)))
    end

    if self.summaryAmountText and self.summaryAmountText.SetText then
        if summaryDefinition.key == "copper" then
            self.summaryAmountText:SetText(amountText)
        else
            self.summaryAmountText:SetText(("%s %s"):format(buildIconMarkup(summaryDefinition.icon), amountText))
        end
    end

    if self.summaryButton and self.summaryButton.SetTooltip then
        self.summaryButton:SetTooltip(buildTooltip(
            summaryDefinition,
            math.max(0, math.floor(tonumber(self.summaryAmount) or 0)),
            amountText
        ))
    end
end

function CurrencyPanel:Refresh()
    local provider = self.provider or getDefaultProvider()
    local provided = provider()
    local items = provided

    self.summaryDefinition = nil
    self.summaryAmount = 0
    self.summaryAmountTextValue = ""

    if type(provided) == "table" and provided.items ~= nil then
        items = provided.items
        self.summaryDefinition = provided.summaryDefinition
        self.summaryAmount = math.max(0, math.floor(tonumber(provided.summaryAmount) or 0))
        self.summaryAmountTextValue = ensureString(provided.summaryAmountText)
    end

    self:SetItems(items)

    if self.summaryDefinition == nil then
        local Profile = Addon.Internal and Addon.Internal.Profile or {}
        self.summaryDefinition = Profile.ResolveCurrencyDefinition and Profile.ResolveCurrencyDefinition("copper") or {
            key = "copper",
            name = "Copper",
            icon = "Interface\\Icons\\INV_Misc_Coin_01",
        }
        self.summaryAmount = Profile.GetCurrencyAmount and Profile.GetCurrencyAmount("copper") or 0
        self.summaryAmountTextValue = Profile.FormatCurrencyAmount and Profile.FormatCurrencyAmount(self.summaryDefinition, self.summaryAmount) or tostring(self.summaryAmount)
    end

    self:UpdateSummaryDisplay()

    if self.emptyText and self.emptyText.SetText and self.emptyText.GetFrame then
        if self.isExpanded and #(self.items or {}) == 0 then
            self.emptyText:SetText("No currencies available.")
            self.emptyText:GetFrame():Show()
        else
            self.emptyText:SetText("")
            self.emptyText:GetFrame():Hide()
        end
    end

    if self.scroll and self.scroll.GetFrame then
        local scrollFrame = self.scroll:GetFrame()
        if scrollFrame and scrollFrame.Show and scrollFrame.Hide then
            if self.isExpanded then
                scrollFrame:Show()
            else
                scrollFrame:Hide()
            end
        end
    end

    self.currencyRevision = getRuntimeRevision("CurrencyRevision")
    self.configurationRevision = getConfigurationRevision()
    self.dirty = false

    return self.frame
end

function CurrencyPanel:RefreshIfDirty()
    local currencyRevision = getRuntimeRevision("CurrencyRevision")
    local configurationRevision = getConfigurationRevision()
    if not self.dirty
        and self.currencyRevision == currencyRevision
        and self.configurationRevision == configurationRevision
    then
        return self.frame, false
    end

    return self:Refresh(), true
end

function CurrencyPanel:Create()
    if self.frame then
        return self.frame
    end

    local parentFrame = self:GetParentFrame()
    if not parentFrame then
        error("A currency panel prefab requires a parent frame before Create().", 2)
    end

    local width = tonumber(self.options.width) or 252
    local height = tonumber(self.options.height) or 108
    local rowHeight = tonumber(self.options.rowHeight) or 16
    local visibleRows = tonumber(self.options.visibleRows) or 6

    local frame = CreateFrame("Frame", self.name, parentFrame, self.options.template)
    self:SetFrame(frame)
    frame:SetSize(width, self:GetCurrentHeight())

    self.panel = UI.CreatePanel(frame, (self.name or "CurrencyPanel") .. "Panel", {
        width = width,
        height = self:GetCurrentHeight(),
        contentInset = 2,
        showBorder = false,
    })
    self.panel:GetFrame():SetAllPoints(frame)

    self.summaryButton = UI.CreateButton(
        self.panel:GetContentFrame(),
        (self.name or "CurrencyPanel") .. "ToggleButton",
        "",
        width - 4,
        function()
            self:ToggleExpanded()
        end,
        {
            height = self.summaryRowHeight,
            fontSize = 8,
            backgroundColor = UI.ResolveColor(nil, "panel.background"),
            hoverColor = UI.ResolveColor(nil, "dropdown.background"),
            pressedColor = UI.ResolveColor(nil, "tab.bar"),
        }
    )
    self.summaryButton:GetFrame():SetPoint("TOPLEFT", self.panel:GetContentFrame(), "TOPLEFT", 0, 0)
    self.summaryButton:GetFrame():SetPoint("TOPRIGHT", self.panel:GetContentFrame(), "TOPRIGHT", 0, 0)

    self.summaryTitleText = UI.CreateText(self.summaryButton:GetFrame(), (self.name or "CurrencyPanel") .. "SummaryTitle", "Currencies", {
        width = width - 96,
        height = self.summaryRowHeight,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
        textInsetLeft = 6,
        textInsetRight = 4,
        textInsetTop = 0,
        textInsetBottom = 0,
    })
    self.summaryTitleText:GetFrame():SetPoint("TOPLEFT", self.summaryButton:GetFrame(), "TOPLEFT", 0, 0)
    self.summaryTitleText:GetFrame():SetPoint("BOTTOMLEFT", self.summaryButton:GetFrame(), "BOTTOMLEFT", 0, 0)

    self.summaryArrowText = UI.CreateText(self.summaryButton:GetFrame(), (self.name or "CurrencyPanel") .. "SummaryArrow", self.isExpanded and "^" or "v", {
        width = 12,
        height = self.summaryRowHeight,
        justifyH = "RIGHT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
        textInsetLeft = 0,
        textInsetRight = 0,
        textInsetTop = 0,
        textInsetBottom = 0,
    })
    self.summaryArrowText:GetFrame():SetPoint("TOPRIGHT", self.summaryButton:GetFrame(), "TOPRIGHT", -6, 0)
    self.summaryArrowText:GetFrame():SetPoint("BOTTOMRIGHT", self.summaryButton:GetFrame(), "BOTTOMRIGHT", -6, 0)

    self.summaryAmountText = UI.CreateText(self.summaryButton:GetFrame(), (self.name or "CurrencyPanel") .. "SummaryAmount", "", {
        width = 72,
        height = self.summaryRowHeight,
        justifyH = "RIGHT",
        textColor = UI.ResolveColor(nil, "text.primary"),
        textInsetLeft = 4,
        textInsetRight = 0,
        textInsetTop = 0,
        textInsetBottom = 0,
    })
    self.summaryAmountText:GetFrame():SetPoint("TOPRIGHT", self.summaryArrowText:GetFrame(), "TOPLEFT", -8, 0)
    self.summaryAmountText:GetFrame():SetPoint("BOTTOMRIGHT", self.summaryArrowText:GetFrame(), "BOTTOMLEFT", -8, 0)

    self.summaryTitleText:GetFrame():SetPoint("TOPRIGHT", self.summaryAmountText:GetFrame(), "TOPLEFT", -8, 0)
    self.summaryTitleText:GetFrame():SetPoint("BOTTOMRIGHT", self.summaryAmountText:GetFrame(), "BOTTOMLEFT", -8, 0)

    self.scroll = UI.ScrollLayout:New({
        name = (self.name or "CurrencyPanel") .. "Scroll",
        width = width - 4,
        height = math.max(0, height - self.summaryRowHeight - 2),
        visibleRows = visibleRows,
        autoFitRows = true,
        rowHeight = rowHeight,
        rowSpacing = 0,
        border = false,
        compact = true,
        rowElementClass = UI.ScrollListEntry,
        compactCategoryWidth = 0,
        compactStatusWidth = 96,
        compactNameInsetLeft = 2,
        compactStatusInsetRight = 2,
    })
    self.scroll:SetParent(self.panel:GetContentFrame())
    self.scroll:SetRowRenderer(function(row, item)
        local definition = item and item.definition or {}
        local amount = math.max(0, math.floor(tonumber(item and item.amount) or 0))
        local amountText = ensureString(item and item.amountText)
        local nameText = ("%s %s"):format(buildIconMarkup(definition.icon), ensureString(definition.name) ~= "" and definition.name or "Currency")
        row:SetCategory("")
        row:SetTestName(nameText)
        row:SetStatus(amountText ~= "" and amountText or tostring(amount))
        row:SetDetail(ensureString(definition.description))
        row:SetTooltip(buildTooltip(definition, amount, amountText ~= "" and amountText or tostring(amount)))

        local isMuted = definition.builtin ~= true and (definition.isMissing == true or definition.isActive ~= true)
        local frameHandle = row.GetFrame and row:GetFrame() or nil
        if frameHandle and frameHandle.SetAlpha then
            frameHandle:SetAlpha(isMuted and 0.55 or 1)
        end

        if row.SetStatusColor then
            local colorToken = isMuted and "text.secondary" or "text.primary"
            local color = UI.ResolveColor(nil, colorToken)
            row:SetStatusColor(color.r or 1, color.g or 1, color.b or 1, color.a or 1)
        end
    end)
    self.scroll:Create()
    self.scroll:SetPoint("TOPLEFT", self.summaryButton:GetFrame(), "BOTTOMLEFT", 0, -2)
    self.scroll:SetPoint("BOTTOMRIGHT", self.panel:GetContentFrame(), "BOTTOMRIGHT", 0, 0)

    self.emptyText = UI.CreateText(self.panel:GetContentFrame(), (self.name or "CurrencyPanel") .. "EmptyText", "", {
        width = width - 8,
        height = 16,
        justifyH = "CENTER",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.emptyText:GetFrame():SetPoint("CENTER", self.panel:GetContentFrame(), "CENTER", 0, -6)

    self:SetExpanded(self.isExpanded, { skipRefresh = true })
    return self.frame
end
