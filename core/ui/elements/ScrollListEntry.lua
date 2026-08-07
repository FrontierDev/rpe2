local _, Addon = ...

local UI = Addon.UI or {}
Addon.UI = UI
local BaseElement = UI.BaseElement
local Debug = Addon.Debug or {}
local Constants = UI.Constants or {}
local Font = UI.Font or {}

UI.ScrollListEntry = UI.ScrollListEntry or {}
local ScrollListEntry = UI.ScrollListEntry
ScrollListEntry.__index = ScrollListEntry
setmetatable(ScrollListEntry, { __index = BaseElement })

function ScrollListEntry:New(options)
    local instance = BaseElement.New(self, options)
    instance.categoryText = options and options.categoryText or ""
    instance.nameText = options and options.nameText or ""
    instance.statusText = options and options.statusText or ""
    instance.detailText = options and options.detailText or ""
    instance.categoryRegion = nil
    instance.nameRegion = nil
    instance.statusRegion = nil
    instance.entryBackground = nil
    return instance
end

local function ApplyRegionFont(region, options, fontSize)
    Font:Apply(region, options, {
        fontFile = options and options.fontFile,
        fontSize = fontSize,
        fontFlags = options and options.fontFlags,
        fontObject = options and options.fontObject,
    })
end

function ScrollListEntry:SetCategory(text)
    self.categoryText = text or ""

    if self.categoryRegion and self.categoryRegion.SetText then
        self.categoryRegion:SetText(self.categoryText)
    end

    self:RefreshTooltip()
end

function ScrollListEntry:SetTestName(text)
    self.nameText = text or ""

    if self.nameRegion and self.nameRegion.SetText then
        self.nameRegion:SetText(self.nameText)
    end

    self:RefreshTooltip()
end

function ScrollListEntry:SetStatus(text)
    self.statusText = text or ""

    if self.statusRegion and self.statusRegion.SetText then
        self.statusRegion:SetText(self.statusText)
    end

    self:RefreshTooltip()
end

function ScrollListEntry:SetStatusColor(r, g, b, a)
    self:SetOption("statusColor", { r = r, g = g, b = b, a = a })

    if self.statusRegion and self.statusRegion.SetTextColor then
        self.statusRegion:SetTextColor(r, g, b, a)
    end
end

function ScrollListEntry:SetDetail(text)
    self.detailText = text or ""
    self:RefreshTooltip()
end

function ScrollListEntry:RefreshTooltip()
    local title = self.categoryText or ""
    local name = self.nameText or ""
    local detail = self.detailText or ""

    local header = title
    if header ~= "" and name ~= "" then
        header = header .. " - " .. name
    elseif name ~= "" then
        header = name
    end

    local lines = {}
    if detail ~= "" then
        lines[#lines + 1] = detail
    end

    self:SetTooltip({
        type = "custom",
        title = header,
        lines = lines,
    })
end

function ScrollListEntry:Create()
    if self.frame then
        return self.frame
    end

    local parentFrame = self:GetParentFrame()
    if not parentFrame then
        if Debug.Internal then
            Debug.Internal("Addon.UI.ScrollListEntry requires a parent frame before Create().")
        end

        error("A scroll list entry requires a parent frame before Create().", 2)
    end

    local frame = CreateFrame("Frame", self.name, parentFrame, self.options.template)
    self:SetFrame(frame)

    local backgroundColor = UI.ResolveColor(self.options.backgroundColor, "list.rowBackground")
    self.entryBackground = frame:CreateTexture(nil, "BACKGROUND")
    self.entryBackground:SetAllPoints(frame)
    self.entryBackground:SetColorTexture(backgroundColor.r or 0, backgroundColor.g or 0, backgroundColor.b or 0, backgroundColor.a or 1)

    local compact = self.options.compact == true
    local categoryWidth = self.options.categoryWidth or 92
    local statusWidth = self.options.statusWidth or 58
    local primaryTop = self.options.primaryInsetTop or 2
    local categoryInsetLeft = self.options.categoryInsetLeft or 6
    local nameInsetLeft = self.options.nameInsetLeft or 8
    local statusInsetRight = self.options.statusInsetRight or 8

    if compact then
        categoryWidth = self.options.compactCategoryWidth or 0
        statusWidth = self.options.compactStatusWidth or statusWidth
        primaryTop = self.options.compactPrimaryInsetTop or primaryTop
        categoryInsetLeft = self.options.compactCategoryInsetLeft or categoryInsetLeft
        nameInsetLeft = self.options.compactNameInsetLeft or nameInsetLeft
        statusInsetRight = self.options.compactStatusInsetRight or statusInsetRight
    end

    self.categoryRegion = frame:CreateFontString(nil, "OVERLAY")
    self.categoryRegion:SetPoint("TOPLEFT", frame, "TOPLEFT", categoryInsetLeft, -primaryTop)
    self.categoryRegion:SetPoint("RIGHT", frame, "LEFT", categoryInsetLeft + categoryWidth, 0)
    self.categoryRegion:SetJustifyH("LEFT")
    self.categoryRegion:SetJustifyV(compact and "MIDDLE" or "TOP")
    ApplyRegionFont(self.categoryRegion, {
        fontFile = self.options.categoryFontFile or self.options.fontFile,
        fontFlags = self.options.categoryFontFlags or self.options.fontFlags,
        fontObject = self.options.categoryFontObject or self.options.fontObject,
    }, (Constants.FontSizes and Constants.FontSizes.ScrollCategory) or 10)

    self.nameRegion = frame:CreateFontString(nil, "OVERLAY")
    if compact then
        self.nameRegion:SetPoint("TOPLEFT", frame, "TOPLEFT", categoryInsetLeft + categoryWidth + nameInsetLeft, -primaryTop)
        self.nameRegion:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -(statusWidth + statusInsetRight), primaryTop)
    else
        self.nameRegion:SetPoint("TOPLEFT", frame, "TOPLEFT", categoryInsetLeft + categoryWidth + nameInsetLeft, -primaryTop)
        self.nameRegion:SetPoint("RIGHT", frame, "RIGHT", -(statusWidth + statusInsetRight), 0)
    end
    self.nameRegion:SetJustifyH("LEFT")
    self.nameRegion:SetJustifyV(compact and "MIDDLE" or "TOP")
    if self.nameRegion.SetWordWrap then
        self.nameRegion:SetWordWrap(compact ~= true)
    end
    ApplyRegionFont(self.nameRegion, {
        fontFile = self.options.nameFontFile or self.options.fontFile,
        fontFlags = self.options.nameFontFlags or self.options.fontFlags,
        fontObject = self.options.nameFontObject or self.options.fontObject,
    }, (Constants.FontSizes and Constants.FontSizes.ScrollName) or 10)

    self.statusRegion = frame:CreateFontString(nil, "OVERLAY")
    self.statusRegion:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -statusInsetRight, -primaryTop)
    self.statusRegion:SetJustifyH("RIGHT")
    self.statusRegion:SetJustifyV(compact and "MIDDLE" or "TOP")
    if compact and self.statusRegion.SetWidth then
        self.statusRegion:SetWidth(statusWidth)
    end
    if self.statusRegion.SetWordWrap then
        self.statusRegion:SetWordWrap(false)
    end
    ApplyRegionFont(self.statusRegion, {
        fontFile = self.options.statusFontFile or self.options.fontFile,
        fontFlags = self.options.statusFontFlags or self.options.fontFlags,
        fontObject = self.options.statusFontObject or self.options.fontObject,
    }, (Constants.FontSizes and Constants.FontSizes.ScrollStatus) or 10)

    local categoryColor = UI.ResolveColor(self.options.categoryColor, "text.secondary")
    if categoryColor and self.categoryRegion.SetTextColor then
        local c = categoryColor
        self.categoryRegion:SetTextColor(c.r or 1, c.g or 1, c.b or 1, c.a or 1)
    end
    if compact and self.categoryRegion.Hide then
        self.categoryRegion:Hide()
    end

    local nameColor = UI.ResolveColor(self.options.nameColor, "text.primary")
    if nameColor and self.nameRegion.SetTextColor then
        local c = nameColor
        self.nameRegion:SetTextColor(c.r or 1, c.g or 1, c.b or 1, c.a or 1)
    end

    local statusColor = UI.ResolveColor(self.options.statusColor, "text.muted")
    if statusColor and self.statusRegion.SetTextColor then
        local c = statusColor
        self.statusRegion:SetTextColor(c.r or 1, c.g or 1, c.b or 1, c.a or 1)
    end

    self:SetCategory(self.categoryText)
    self:SetTestName(self.nameText)
    self:SetStatus(self.statusText)
    self:SetDetail(self.detailText)
    self:RefreshTooltip()
    return self.frame
end
