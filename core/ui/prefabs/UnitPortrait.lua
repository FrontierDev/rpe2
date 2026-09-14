local _, Addon = ...

local UI = Addon.UI or {}
Addon.UI = UI
local BaseElement = UI.BaseElement
local Panel = UI.Panel
local Image = UI.Image
local ProgressBar = UI.ProgressBar
local Utils = UI.Utils or {}
local Constants = UI.Constants or {}
local Common = Addon.Utils and Addon.Utils.Common or {}
local Database = Addon.Internal and Addon.Internal.Database or {}
local RulesetLogic = Addon.Internal and Addon.Internal.Ruleset or {}
local Client = Addon.Client or {}

UI.UnitPortrait = UI.UnitPortrait or {}
local UnitPortrait = UI.UnitPortrait
UnitPortrait.__index = UnitPortrait
setmetatable(UnitPortrait, { __index = BaseElement })

local DEFAULT_TEXTURE = "Interface\\Icons\\INV_Misc_QuestionMark"
local DEFAULT_HIDDEN_OVERLAY_TEXTURE = "Interface\\AddOns\\RPEngine_Dev\\data\\textures\\ui\\hidden_portrait_overlay.png"
local DEFAULT_HEALTH_ICON = "Interface\\Icons\\Spell_Holy_SealOfSacrifice"
local DEFAULT_PET_ICON = 132161
local DEFAULT_TARGET_ICON = 132177
local DEFAULT_PROGRESS_BAR_HEIGHT = 10
local DEFAULT_STATUS_BAR_SPACING = 2
local DEFAULT_CAST_ICON_SIZE = 14
local DEFAULT_RAID_MARKER_ICON_SIZE = 14
local DEFAULT_CORNER_BADGE_ICON_SIZE = 21
local DEFAULT_TURN_COMPLETE_ICON = "Interface\\RaidFrame\\ReadyCheck-Ready"

local function getMaxFrameLevel(...)
    local maxLevel = 0
    for index = 1, select("#", ...) do
        local frame = select(index, ...)
        if frame and frame.GetFrameLevel then
            maxLevel = math.max(maxLevel, frame:GetFrameLevel() or 0)
        end
    end

    return maxLevel
end

local function normalizeModelId(value)
    local number = tonumber(value)
    if number == nil or number <= 0 then
        return nil
    end

    return number
end

local function parseResourceRef(resourceRef)
    if type(resourceRef) ~= "string" or resourceRef == "" then
        return nil, nil
    end

    local separatorIndex = string.find(resourceRef, ":", 1, true)
    if not separatorIndex then
        return nil, nil
    end

    local datasetId = string.sub(resourceRef, 1, separatorIndex - 1)
    local resourceId = string.sub(resourceRef, separatorIndex + 1)
    if datasetId == "" or resourceId == "" then
        return nil, nil
    end

    return datasetId, resourceId
end

local function resolveResourceDefinition(resourceRef)
    local datasetId, resourceId = parseResourceRef(resourceRef)
    if not datasetId or not resourceId or not Database.GetDatasetByID then
        return nil
    end

    local dataset = Database.GetDatasetByID(datasetId)
    for index = 1, #((dataset and dataset.resources) or {}) do
        local resource = dataset.resources[index]
        if resource and resource.id == resourceId then
            return resource
        end
    end

    return nil
end

local function normalizeHealthLabel(text)
    local normalized = tostring(text or ""):lower()
    normalized = normalized:gsub("[%s_%-]", "")
    return normalized
end

local function resolveHealthResourceEntry(portraitUnit)
    local resources = type(portraitUnit) == "table" and portraitUnit.resources or nil
    local activeRuleset = RulesetLogic and RulesetLogic.GetActiveRuleset and RulesetLogic.GetActiveRuleset() or nil
    local healthRuleDefinition = RulesetLogic and RulesetLogic.GetRulesetRuleDefinition and RulesetLogic.GetRulesetRuleDefinition("resources", "health_stat") or nil
    local healthResourceRef = RulesetLogic and RulesetLogic.GetRulesetRuleValue and RulesetLogic.GetRulesetRuleValue(activeRuleset, "resources", healthRuleDefinition) or nil

    if type(healthResourceRef) == "string" and healthResourceRef ~= "" then
        for index = 1, #((resources) or {}) do
            local entry = resources[index]
            if entry and entry.resourceRef == healthResourceRef then
                return entry, resolveResourceDefinition(entry.resourceRef)
            end
        end
    end

    for index = 1, #((resources) or {}) do
        local entry = resources[index]
        local resource = resolveResourceDefinition(entry and entry.resourceRef or nil)
        local normalizedName = normalizeHealthLabel(resource and resource.name or "")
        if normalizedName == "health" or normalizedName == "hp" or normalizedName == "hitpoints" then
            return entry, resource
        end
    end

    for index = 1, #((resources) or {}) do
        local entry = resources[index]
        if entry and (entry.currentValue ~= nil or entry.maxValue ~= nil or entry.value ~= nil) then
            return entry, resolveResourceDefinition(entry.resourceRef)
        end
    end

    return nil, nil
end

local function buildHealthTooltipLine(portraitUnit)
    local resourceEntry = resolveHealthResourceEntry(portraitUnit)
    if not resourceEntry then
        return nil
    end

    local currentValue = tonumber(resourceEntry.currentValue)
    local maxValue = tonumber(resourceEntry.maxValue)
    if currentValue == nil and maxValue ~= nil then
        currentValue = maxValue
    end
    if maxValue == nil and currentValue ~= nil then
        maxValue = currentValue
    end

    if currentValue == nil or maxValue == nil then
        return nil
    end

    return {
        icon = DEFAULT_HEALTH_ICON,
        text = ("%d / %d"):format(currentValue, maxValue),
        justifyH = "CENTER",
    }
end

local function buildPortraitTooltip(portraitUnit)
    if type(portraitUnit) ~= "table" then
        return nil
    end

    local title = tostring(portraitUnit.name or "")
    if title == "" then
        return nil
    end

    local lines = {}
    local healthLine = buildHealthTooltipLine(portraitUnit)
    if healthLine then
        lines[#lines + 1] = healthLine
    end

    local eventState = type(Client.GetEventState) == "function" and Client:GetEventState() or Client.EventState
    local auraManager = Client.Spellcasting and Client.Spellcasting.AuraManager or nil
    local unitEventId = tonumber(portraitUnit and portraitUnit.eventID) or 0
    if auraManager
        and type(auraManager.BuildUnitAuraTooltipLines) == "function"
        and type(eventState) == "table"
        and eventState.active == true
        and unitEventId > 0
    then
        local auraLines = auraManager:BuildUnitAuraTooltipLines(Client, eventState, unitEventId)
        for index = 1, #auraLines do
            lines[#lines + 1] = auraLines[index]
        end
    end

    local description = ""
    if portraitUnit.GetResolvedValue then
        description = tostring(portraitUnit:GetResolvedValue("description", portraitUnit.description or "") or "")
    else
        description = tostring(portraitUnit.description or "")
    end
    if description ~= "" then
        lines[#lines + 1] = description
    end

    if #lines == 0 then
        return {
            type = "custom",
            title = title,
            titleFontSize = 12,
        }
    end

    return {
        type = "custom",
        title = title,
        titleFontSize = 12,
        lines = lines,
    }
end

function UnitPortrait.BuildTooltipSpec(portraitUnit)
    return buildPortraitTooltip(portraitUnit)
end

local function ResolveModelPortraitState(portraitUnit)
    local resolvedUnit = type(portraitUnit) == "table" and portraitUnit.GetResolvedUnit and portraitUnit:GetResolvedUnit() or nil
    local sourceUnit = resolvedUnit or portraitUnit
    local displayId = normalizeModelId(sourceUnit and (sourceUnit.modelDisplayId or sourceUnit.displayId or sourceUnit.ModelID) or nil)
    local fileDataId = normalizeModelId(sourceUnit and sourceUnit.fileDataId or nil)
    local isModelPortrait = type(portraitUnit) == "table" and (displayId ~= nil or fileDataId ~= nil)

    if not isModelPortrait then
        return nil
    end

    return {
        displayId = displayId,
        fileDataId = fileDataId,
        cam = tonumber(sourceUnit and sourceUnit.cam or nil) or 1,
        rot = tonumber(sourceUnit and sourceUnit.rot or nil) or 0,
        z = tonumber(sourceUnit and sourceUnit.z or nil) or -0.35,
    }
end

local function NormalizePortraitPlayerName(name)
    local normalized = type(Common.NormalizeName) == "function" and Common.NormalizeName(name) or tostring(name or "")
    normalized = tostring(normalized or ""):lower()
    normalized = normalized:gsub("%s+", "")
    return normalized
end

local function GetFullUnitName(unitToken)
    if type(unitToken) ~= "string" or unitToken == "" then
        return nil
    end

    local name, realm = nil, nil
    if UnitFullName then
        name, realm = UnitFullName(unitToken)
    end

    if not name or name == "" then
        name = GetUnitName and GetUnitName(unitToken, true) or UnitName and UnitName(unitToken) or nil
    end

    if not name or name == "" then
        return nil
    end

    if realm and realm ~= "" and not string.find(name, "-", 1, true) then
        name = name .. "-" .. realm
    end

    return NormalizePortraitPlayerName(name)
end

local function ResolvePlayerPortraitToken(portraitUnit)
    if type(portraitUnit) ~= "table" or portraitUnit.isPlayer ~= true then
        return nil
    end

    local candidateNames = {}
    local seenNames = {}

    local function addCandidate(name)
        local normalized = NormalizePortraitPlayerName(name)
        if normalized == "" or seenNames[normalized] then
            return
        end

        seenNames[normalized] = true
        candidateNames[#candidateNames + 1] = normalized
    end

    addCandidate(portraitUnit.controllerID)
    addCandidate(portraitUnit.ownerID)
    addCandidate(portraitUnit.name)

    if #candidateNames == 0 then
        return nil
    end

    local function tokenMatches(unitToken)
        local normalizedUnitName = GetFullUnitName(unitToken)
        if not normalizedUnitName then
            return false
        end

        for index = 1, #candidateNames do
            if candidateNames[index] == normalizedUnitName then
                return true
            end
        end

        return false
    end

    if UnitExists and UnitExists("player") and tokenMatches("player") then
        return "player"
    end

    local partyCount = GetNumSubgroupMembers and GetNumSubgroupMembers() or 0
    for index = 1, partyCount do
        local unitToken = "party" .. index
        if UnitExists and UnitExists(unitToken) and tokenMatches(unitToken) then
            return unitToken
        end
    end

    local raidCount = GetNumGroupMembers and GetNumGroupMembers() or 0
    for index = 1, raidCount do
        local unitToken = "raid" .. index
        if UnitExists and UnitExists(unitToken) and tokenMatches(unitToken) then
            return unitToken
        end
    end

    return nil
end

function UnitPortrait:New(options)
    local instance = BaseElement.New(self, options)
    instance.options.border = false
    instance.portraitPanel = nil
    instance.portraitFrame = nil
    instance.portraitImage = nil
    instance.portraitTexture = nil
    instance.model = nil
    instance.hiddenOverlayFrame = nil
    instance.hiddenOverlayTexture = nil
    instance.progressBar = nil
    instance.secondaryProgressBar = nil
    instance.castIcon = nil
    instance.raidMarker = nil
    instance.raidMarkerTexture = nil
    instance.petIndicator = nil
    instance.targetIndicator = nil
    instance.turnCompleteIndicator = nil
    instance.portraitUnit = options and options.unit or nil
    instance.portraitUpdater = nil
    instance.portraitWidthValue = 0
    instance.portraitHeightValue = 0
    instance.progressHeightValue = 0
    instance.secondaryProgressHeightValue = 0
    instance.progressSpacingValue = 0
    instance.secondaryProgressSpacingValue = 0
    instance.castIconSizeValue = 0
    instance.castIconSpacingValue = 0
    instance.overlayTopPaddingValue = 0
    return instance
end

local function getDimmedBarColor(color)
    if type(color) ~= "table" then
        return { r = 0.16, g = 0.18, b = 0.22, a = 1 }
    end

    return {
        r = math.max(0, math.min(1, (tonumber(color.r) or 0.5) * 0.35)),
        g = math.max(0, math.min(1, (tonumber(color.g) or 0.5) * 0.35)),
        b = math.max(0, math.min(1, (tonumber(color.b) or 0.5) * 0.35)),
        a = tonumber(color.a) or 1,
    }
end

local function applyProgressBarState(bar, state)
    local frame = bar and bar.GetFrame and bar:GetFrame() or nil
    if not bar or not frame then
        return false
    end

    if type(state) ~= "table" then
        frame:Hide()
        return false
    end

    bar:SetOption("primaryColor", state.color)
    bar:SetOption("secondaryColor", state.secondaryColor or getDimmedBarColor(state.color))
    if bar.ApplyColors then
        bar:ApplyColors()
    end
    if bar.SetMinMax then
        bar:SetMinMax(0, math.max(1, tonumber(state.maxValue) or 1))
    end
    if bar.SetValue then
        bar:SetValue(math.max(0, tonumber(state.currentValue) or 0))
    end
    if bar.SetText then
        bar:SetText("")
    end
    if bar.label and bar.label.Hide then
        bar.label:Hide()
    end
    frame:Show()
    return true
end

function UnitPortrait:RefreshStatusLayout()
    if not self.frame or not self.portraitFrame then
        return false
    end

    local currentAnchor = self.portraitFrame
    local currentOffset = -(self.progressSpacingValue or 0)
    local totalHeight = (self.overlayTopPaddingValue or 0) + (self.portraitHeightValue or 0)

    local primaryFrame = self.progressBar and self.progressBar.GetFrame and self.progressBar:GetFrame() or nil
    if primaryFrame and primaryFrame.IsShown and primaryFrame:IsShown() then
        primaryFrame:ClearAllPoints()
        primaryFrame:SetPoint("TOPLEFT", currentAnchor, "BOTTOMLEFT", 0, currentOffset)
        primaryFrame:SetPoint("TOPRIGHT", currentAnchor, "BOTTOMRIGHT", 0, currentOffset)
        primaryFrame:SetHeight(self.progressHeightValue or 0)
        currentAnchor = primaryFrame
        currentOffset = -(self.secondaryProgressSpacingValue or DEFAULT_STATUS_BAR_SPACING)
        totalHeight = totalHeight + (self.progressSpacingValue or 0) + (self.progressHeightValue or 0)
    end

    local secondaryFrame = self.secondaryProgressBar and self.secondaryProgressBar.GetFrame and self.secondaryProgressBar:GetFrame() or nil
    if secondaryFrame and secondaryFrame.IsShown and secondaryFrame:IsShown() then
        secondaryFrame:ClearAllPoints()
        secondaryFrame:SetPoint("TOPLEFT", currentAnchor, "BOTTOMLEFT", 0, currentOffset)
        secondaryFrame:SetPoint("TOPRIGHT", currentAnchor, "BOTTOMRIGHT", 0, currentOffset)
        secondaryFrame:SetHeight(self.secondaryProgressHeightValue or 0)
        currentAnchor = secondaryFrame
        currentOffset = -(self.castIconSpacingValue or DEFAULT_STATUS_BAR_SPACING)
        totalHeight = totalHeight + (self.secondaryProgressSpacingValue or DEFAULT_STATUS_BAR_SPACING) + (self.secondaryProgressHeightValue or 0)
    elseif primaryFrame and primaryFrame.IsShown and primaryFrame:IsShown() then
        currentOffset = -(self.castIconSpacingValue or DEFAULT_STATUS_BAR_SPACING)
    end

    local castFrame = self.castIcon and self.castIcon.GetFrame and self.castIcon:GetFrame() or nil
    if castFrame and castFrame.IsShown and castFrame:IsShown() then
        castFrame:ClearAllPoints()
        castFrame:SetPoint("TOP", currentAnchor, "BOTTOM", 0, currentOffset)
        castFrame:SetSize(self.castIconSizeValue or DEFAULT_CAST_ICON_SIZE, self.castIconSizeValue or DEFAULT_CAST_ICON_SIZE)
        totalHeight = totalHeight + math.abs(currentOffset) + (self.castIconSizeValue or DEFAULT_CAST_ICON_SIZE)
    end

    if self.frame.SetHeight then
        self.frame:SetHeight(totalHeight)
    end

    return true
end

local function applyModelTransform(model, displayId, fileDataId, cam, rot, z, shouldResetModel)
    if not model then
        return
    end

    if shouldResetModel then
        if model.ClearModel then
            model:ClearModel()
        end
        if normalizeModelId(fileDataId) and model.SetModel then
            model:SetModel(fileDataId)
        end
        if normalizeModelId(displayId) and model.SetDisplayInfo then
            model:SetDisplayInfo(displayId)
        end
    end

    if model.ClearTransform then
        model:ClearTransform()
    end

    if model.SetCamDistanceScale then
        model:SetCamDistanceScale(math.max(0.1, cam))
    end
    if model.SetRotation then
        model:SetRotation(rot)
    end
    if model.SetPosition then
        model:SetPosition(0, 0, z)
    end
    if model.Show then
        model:Show()
    end
end

function UnitPortrait:SetPortraitTexture(texturePath)
    self:SetOption("portraitTexture", texturePath)
    self.portraitUnit = nil

    if self.portraitImage and self.portraitImage.SetTexture then
        self.portraitImage:SetTexture(texturePath)
    elseif self.portraitTexture and self.portraitTexture.SetTexture then
        self.portraitTexture:SetTexture(texturePath)
    end
end

function UnitPortrait:SetUnit(unit)
    self.portraitUnit = unit
    self:SetOption("unit", unit)
    self:RefreshPortrait()
end

function UnitPortrait:SetBorderColor(r, g, b, a)
    self:SetOption("portraitBorderColor", { r = r, g = g, b = b, a = a })

    if self.portraitPanel then
        self.portraitPanel:SetOption("panelBorderColor", { r = r, g = g, b = b, a = a })
        self.portraitPanel:ApplyPanelBorders()
    end
end

function UnitPortrait:SetHiddenPresentation(hidden, hideDetails)
    local isHidden = hidden == true
    local shouldHideDetails = isHidden and hideDetails == true
    local overlayFrame = self.hiddenOverlayFrame
    if overlayFrame then
        if isHidden then
            overlayFrame:Show()
        else
            overlayFrame:Hide()
        end
    end

    if self.portraitPanel then
        self.portraitPanel:SetOption("showBorder", not shouldHideDetails)
        self.portraitPanel:ApplyPanelBorders()
    end

    local progressFrame = self.progressBar and self.progressBar.GetFrame and self.progressBar:GetFrame() or nil
    if progressFrame and shouldHideDetails then
        progressFrame:Hide()
    end

    local secondaryProgressFrame = self.secondaryProgressBar and self.secondaryProgressBar.GetFrame and self.secondaryProgressBar:GetFrame() or nil
    if secondaryProgressFrame and shouldHideDetails then
        secondaryProgressFrame:Hide()
    end

    self:RefreshStatusLayout()
    return isHidden
end

function UnitPortrait:SetProgressValue(value)
    if self.progressBar and self.progressBar.SetValue then
        self.progressBar:SetValue(value)
    end
end

function UnitPortrait:SetProgressState(state)
    applyProgressBarState(self.progressBar, state)
    self:RefreshStatusLayout()
    return state
end

function UnitPortrait:SetSecondaryProgressState(state)
    applyProgressBarState(self.secondaryProgressBar, state)
    self:RefreshStatusLayout()
    return state
end

function UnitPortrait:SetRaidMarker(raidMarker)
    local texture = self.raidMarkerTexture
    if not texture then
        return false
    end

    local markerIndex = math.floor(tonumber(raidMarker) or 0)
    if markerIndex > 0 then
        if texture.SetTexture then
            texture:SetTexture(("Interface\\TargetingFrame\\UI-RaidTargetingIcon_%d"):format(markerIndex))
        end
        if texture.SetTexCoord then
            texture:SetTexCoord(4 / 64, 60 / 64, 4 / 64, 60 / 64)
        end
        texture._raidMarkerIndex = markerIndex
        texture:Show()
        return true
    end

    texture._raidMarkerIndex = nil
    texture:Hide()
    return false
end

function UnitPortrait:SetPetIndicatorVisible(visible)
    local frame = self.petIndicator and self.petIndicator.GetFrame and self.petIndicator:GetFrame() or nil
    if not frame then
        return false
    end

    if visible == true then
        frame:Show()
    else
        frame:Hide()
    end
    return visible == true
end

function UnitPortrait:SetTargetIndicatorVisible(visible)
    local frame = self.targetIndicator and self.targetIndicator.GetFrame and self.targetIndicator:GetFrame() or nil
    if not frame then
        return false
    end

    if visible == true then
        frame:Show()
    else
        frame:Hide()
    end
    return visible == true
end

function UnitPortrait:SetTargetIndicatorAlpha(alpha)
    local frame = self.targetIndicator and self.targetIndicator.GetFrame and self.targetIndicator:GetFrame() or nil
    if not frame then
        return false
    end

    local normalizedAlpha = tonumber(alpha)
    if normalizedAlpha == nil then
        normalizedAlpha = 1
    end
    normalizedAlpha = math.max(0, math.min(1, normalizedAlpha))
    if frame.SetAlpha then
        frame:SetAlpha(normalizedAlpha)
    end
    return true
end

function UnitPortrait:SetTurnCompleteIndicatorVisible(visible)
    local frame = self.turnCompleteIndicator and self.turnCompleteIndicator.GetFrame and self.turnCompleteIndicator:GetFrame() or nil
    if not frame then
        return false
    end

    if visible == true then
        frame:Show()
    else
        frame:Hide()
    end
    return visible == true
end

function UnitPortrait:SetCastIcon(texturePath)
    local frame = self.castIcon and self.castIcon.GetFrame and self.castIcon:GetFrame() or nil
    if not self.castIcon or not frame then
        return false
    end

    local resolvedTexture = type(texturePath) == "string" and texturePath or ""
    if resolvedTexture ~= "" then
        self.castIcon:SetTexture(resolvedTexture)
        frame:Show()
    else
        frame:Hide()
    end
    self:RefreshStatusLayout()
    return resolvedTexture ~= ""
end

function UnitPortrait:RefreshOverlayFrameLevels()
    local rootFrame = self.frame
    if not rootFrame then
        return false
    end

    local portraitImageFrame = self.portraitImage and self.portraitImage.GetFrame and self.portraitImage:GetFrame() or nil
    local overlayLevel = getMaxFrameLevel(rootFrame, self.portraitFrame, portraitImageFrame, self.model) + 10
    local overlayStrata = rootFrame.GetFrameStrata and rootFrame:GetFrameStrata() or nil
    local overlayFrames = {
        self.hiddenOverlayFrame,
        self.raidMarker and self.raidMarker.GetFrame and self.raidMarker:GetFrame() or nil,
        self.petIndicator and self.petIndicator.GetFrame and self.petIndicator:GetFrame() or nil,
        self.targetIndicator and self.targetIndicator.GetFrame and self.targetIndicator:GetFrame() or nil,
        self.turnCompleteIndicator and self.turnCompleteIndicator.GetFrame and self.turnCompleteIndicator:GetFrame() or nil,
    }

    for index = 1, #overlayFrames do
        local frame = overlayFrames[index]
        if frame then
            if overlayStrata and frame.SetFrameStrata then
                frame:SetFrameStrata(overlayStrata)
            end
            if frame.SetFrameLevel then
                frame:SetFrameLevel(overlayLevel + index)
            end
        end
    end

    return true
end

function UnitPortrait:RefreshPortrait()
    if not self.portraitTexture then
        return
    end

    local tooltip = buildPortraitTooltip(self.portraitUnit)
    self:SetTooltip(tooltip)
    if self.portraitPanel and self.portraitPanel.SetTooltip then
        self.portraitPanel:SetTooltip(tooltip)
    end
    if UI.Tooltip and UI.Tooltip.RefreshForElement then
        UI.Tooltip:RefreshForElement(self.frame, tooltip)
        if self.portraitPanel and self.portraitPanel.GetFrame then
            UI.Tooltip:RefreshForElement(self.portraitPanel:GetFrame(), tooltip)
        end
    end

    local portraitUnit = self.portraitUnit
    local modelState = ResolveModelPortraitState(portraitUnit)
    local playerToken = ResolvePlayerPortraitToken(portraitUnit)
    local portraitImageFrame = self.portraitImage and self.portraitImage.GetFrame and self.portraitImage:GetFrame() or nil

    if playerToken and SetPortraitTexture then
        if self.model and self.model.Hide then
            self.model:Hide()
        end
        if portraitImageFrame and portraitImageFrame.Show then
            portraitImageFrame:Show()
        end

        SetPortraitTexture(self.portraitTexture, playerToken)
        self:RefreshOverlayFrameLevels()
        return
    end

    if modelState and self.model then
        if portraitImageFrame and portraitImageFrame.Hide then
            portraitImageFrame:Hide()
        end

        applyModelTransform(self.model, modelState.displayId, modelState.fileDataId, modelState.cam, modelState.rot, modelState.z, true)
        self:RefreshOverlayFrameLevels()
        return
    end

    if self.model and self.model.Hide then
        self.model:Hide()
    end
    if portraitImageFrame and portraitImageFrame.Show then
        portraitImageFrame:Show()
    end

    if self.portraitUnit and type(self.portraitUnit) ~= "table" and SetPortraitTexture then
        SetPortraitTexture(self.portraitTexture, self.portraitUnit)
        self:RefreshOverlayFrameLevels()
        return
    end

    local texturePath = self.options.portraitTexture or DEFAULT_TEXTURE
    if self.portraitImage and self.portraitImage.SetTexture then
        self.portraitImage:SetTexture(texturePath)
    elseif self.portraitTexture and self.portraitTexture.SetTexture then
        self.portraitTexture:SetTexture(texturePath)
    end
    self:RefreshOverlayFrameLevels()
end

function UnitPortrait:Create()
    if self.frame then
        return self.frame
    end

    local parentFrame = self:GetParentFrame()
    if not parentFrame then
        error("A unit portrait prefab requires a parent frame before Create().", 2)
    end

    local defaults = (Constants.Prefabs and Constants.Prefabs.UnitPortrait) or {}
    local portraitWidth = self.options.portraitWidth or self.options.width or self.options.portraitSize or defaults.PortraitSize or 32
    local portraitHeight = self.options.portraitHeight or self.options.height or self.options.portraitSize or defaults.PortraitSize or 32
    local borderSize = self.options.portraitBorderSize or defaults.PortraitBorderSize or 4
    local progressHeight = self.options.progressHeight or defaults.ProgressHeight or DEFAULT_PROGRESS_BAR_HEIGHT
    local secondaryProgressHeight = self.options.secondaryProgressHeight or 0
    local spacing = self.options.progressSpacing or defaults.ProgressSpacing or 4
    local secondarySpacing = self.options.secondaryProgressSpacing or DEFAULT_STATUS_BAR_SPACING
    local castIconSize = self.options.castIconSize or DEFAULT_CAST_ICON_SIZE
    local castIconSpacing = self.options.castIconSpacing or DEFAULT_STATUS_BAR_SPACING
    local overlayTopPadding = math.max(0, tonumber(self.options.overlayTopPadding) or 0)

    local frame = CreateFrame("Frame", self.name, parentFrame, self.options.template)
    self:SetFrame(frame)
    self.portraitWidthValue = portraitWidth
    self.portraitHeightValue = portraitHeight
    self.progressHeightValue = progressHeight
    self.secondaryProgressHeightValue = secondaryProgressHeight
    self.progressSpacingValue = spacing
    self.secondaryProgressSpacingValue = secondarySpacing
    self.castIconSizeValue = castIconSize
    self.castIconSpacingValue = castIconSpacing
    self.overlayTopPaddingValue = overlayTopPadding
    frame:SetSize(portraitWidth, overlayTopPadding + portraitHeight + spacing + progressHeight)

    self.portraitPanel = Panel:New({
        name = (self.name or "UnitPortrait") .. "PortraitPanel",
        width = portraitWidth,
        height = portraitHeight,
        border = false,
        panelBorderSize = borderSize,
        panelBorderColor = self.options.portraitBorderColor or defaults.PortraitBorderColor or { r = 0.85, g = 0.24, b = 0.24, a = 1 },
        panelBackgroundColor = self.options.portraitBackgroundColor,
    })
    self.portraitPanel:SetParent(frame)
    self.portraitPanel:Create()
    self.portraitFrame = self.portraitPanel:GetFrame()
    self.portraitFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -overlayTopPadding)

    self.raidMarker = Image:New({
        name = (self.name or "UnitPortrait") .. "RaidMarker",
        width = DEFAULT_RAID_MARKER_ICON_SIZE,
        height = DEFAULT_RAID_MARKER_ICON_SIZE,
        border = false,
        layer = "OVERLAY",
        frameStrata = self.options.frameStrata,
        textureInsetLeft = 0,
        textureInsetTop = 0,
        textureInsetRight = 0,
        textureInsetBottom = 0,
    })
    self.raidMarker:SetParent(frame)
    self.raidMarker:Create()
    self.raidMarker:GetFrame():SetPoint("CENTER", self.portraitFrame, "TOP", 0, 0)
    self.raidMarkerTexture = self.raidMarker.textureRegion
    self.raidMarkerTexture:Hide()

    self.portraitImage = Image:New({
        name = (self.name or "UnitPortrait") .. "PortraitImage",
        textureInsetLeft = 0,
        textureInsetTop = 0,
        textureInsetRight = 0,
        textureInsetBottom = 0,
        border = false,
    })
    self.portraitImage:SetParent(self.portraitPanel:GetContentFrame())
    self.portraitImage:Create()
    Utils.AnchorFill(self.portraitImage, self.portraitPanel:GetContentFrame())
    self.portraitTexture = self.portraitImage.textureRegion
    Utils.ApplyTexture(
        self.portraitTexture,
        self.options.portraitTexture or defaults.PortraitTexture or DEFAULT_TEXTURE,
        Utils.ResolveTexCoord(self.options.portraitTexCoord, defaults.PortraitTexCoord)
    )

    self.model = CreateFrame("PlayerModel", (self.name or "UnitPortrait") .. "Model", self.portraitPanel:GetContentFrame())
    self.model:SetAllPoints(self.portraitPanel:GetContentFrame())
    if self.model.SetKeepModelOnHide then
        self.model:SetKeepModelOnHide(true)
    end
    if self.model.Hide then
        self.model:Hide()
    end

    self.hiddenOverlayFrame = CreateFrame("Frame", (self.name or "UnitPortrait") .. "HiddenOverlay", self.portraitPanel:GetContentFrame())
    self.hiddenOverlayFrame:SetAllPoints(self.portraitPanel:GetContentFrame())
    self.hiddenOverlayTexture = self.hiddenOverlayFrame:CreateTexture(nil, "OVERLAY")
    self.hiddenOverlayTexture:SetAllPoints(self.hiddenOverlayFrame)
    self.hiddenOverlayTexture:SetTexture(self.options.hiddenOverlayTexture or DEFAULT_HIDDEN_OVERLAY_TEXTURE)
    self.hiddenOverlayTexture:SetAlpha(tonumber(self.options.hiddenOverlayAlpha) or 0.85)
    self.hiddenOverlayFrame:Hide()

    self.petIndicator = Image:New({
        name = (self.name or "UnitPortrait") .. "PetIndicator",
        width = DEFAULT_CORNER_BADGE_ICON_SIZE,
        height = DEFAULT_CORNER_BADGE_ICON_SIZE,
        texture = DEFAULT_PET_ICON,
        border = false,
        layer = "OVERLAY",
        frameStrata = self.options.frameStrata,
        textureInsetLeft = 0,
        textureInsetTop = 0,
        textureInsetRight = 0,
        textureInsetBottom = 0,
    })
    self.petIndicator:SetParent(frame)
    self.petIndicator:Create()
    self.petIndicator:GetFrame():SetPoint("CENTER", self.portraitFrame, "TOPLEFT", 0, 0)
    self.petIndicator:GetFrame():Hide()

    self.targetIndicator = Image:New({
        name = (self.name or "UnitPortrait") .. "TargetIndicator",
        width = DEFAULT_CORNER_BADGE_ICON_SIZE,
        height = DEFAULT_CORNER_BADGE_ICON_SIZE,
        texture = DEFAULT_TARGET_ICON,
        border = false,
        layer = "OVERLAY",
        frameStrata = self.options.frameStrata,
        textureInsetLeft = 0,
        textureInsetTop = 0,
        textureInsetRight = 0,
        textureInsetBottom = 0,
    })
    self.targetIndicator:SetParent(frame)
    self.targetIndicator:Create()
    self.targetIndicator:GetFrame():SetPoint("CENTER", self.portraitFrame, "TOPRIGHT", 0, 0)
    self.targetIndicator:GetFrame():Hide()

    self.turnCompleteIndicator = Image:New({
        name = (self.name or "UnitPortrait") .. "TurnCompleteIndicator",
        width = DEFAULT_CORNER_BADGE_ICON_SIZE,
        height = DEFAULT_CORNER_BADGE_ICON_SIZE,
        texture = DEFAULT_TURN_COMPLETE_ICON,
        border = false,
        layer = "OVERLAY",
        frameStrata = self.options.frameStrata,
        textureInsetLeft = 0,
        textureInsetTop = 0,
        textureInsetRight = 0,
        textureInsetBottom = 0,
    })
    self.turnCompleteIndicator:SetParent(frame)
    self.turnCompleteIndicator:Create()
    self.turnCompleteIndicator:GetFrame():SetPoint("CENTER", self.portraitFrame, "BOTTOMRIGHT", 0, 0)
    self.turnCompleteIndicator:GetFrame():Hide()

    self.portraitUnit = self.options.unit or defaults.Unit or self.portraitUnit
    local tooltip = buildPortraitTooltip(self.portraitUnit)
    self:SetTooltip(tooltip)
    self.portraitPanel:SetTooltip(tooltip)

    self.progressBar = ProgressBar:New({
        name = (self.name or "UnitPortrait") .. "Progress",
        width = portraitWidth,
        height = progressHeight,
        minValue = self.options.minValue or defaults.MinValue or 0,
        maxValue = self.options.maxValue or defaults.MaxValue or 100,
        value = self.options.value or defaults.Value or 72,
        text = self.options.progressText ~= nil and self.options.progressText or "",
        backgroundColor = self.options.progressBackgroundColor or defaults.ProgressBackgroundColor,
        borderColor = self.options.progressBorderColor or defaults.ProgressBorderColor,
        primaryColor = self.options.progressPrimaryColor or defaults.ProgressPrimaryColor,
        secondaryColor = self.options.progressSecondaryColor or defaults.ProgressSecondaryColor,
        textColor = self.options.progressTextColor or defaults.ProgressTextColor,
        border = false,
    })
    self.progressBar:SetParent(frame)
    self.progressBar:Create()
    self.progressBar:SetPoint("TOPLEFT", self.portraitFrame, "BOTTOMLEFT", 0, -spacing)

    if secondaryProgressHeight > 0 then
        self.secondaryProgressBar = ProgressBar:New({
            name = (self.name or "UnitPortrait") .. "SecondaryProgress",
            width = portraitWidth,
            height = secondaryProgressHeight,
            minValue = 0,
            maxValue = 100,
            value = 0,
            text = "",
            backgroundColor = self.options.progressBackgroundColor or defaults.ProgressBackgroundColor,
            borderColor = self.options.progressBorderColor or defaults.ProgressBorderColor,
            primaryColor = self.options.secondaryProgressPrimaryColor or self.options.progressPrimaryColor or defaults.ProgressPrimaryColor,
            secondaryColor = self.options.secondaryProgressSecondaryColor or self.options.progressSecondaryColor or defaults.ProgressSecondaryColor,
            textColor = self.options.progressTextColor or defaults.ProgressTextColor,
            border = false,
        })
        self.secondaryProgressBar:SetParent(frame)
        self.secondaryProgressBar:Create()
        self.secondaryProgressBar:GetFrame():Hide()
    end

    self.castIcon = Image:New({
        name = (self.name or "UnitPortrait") .. "CastIcon",
        width = castIconSize,
        height = castIconSize,
        texture = DEFAULT_TEXTURE,
        border = false,
    })
    self.castIcon:SetParent(frame)
    self.castIcon:Create()
    self.castIcon:GetFrame():Hide()

    self:RefreshPortrait()
    self:RefreshOverlayFrameLevels()
    self:RefreshStatusLayout()
    self.portraitUpdater = CreateFrame("Frame", nil, frame)
    self.portraitUpdater:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.portraitUpdater:RegisterEvent("UNIT_PORTRAIT_UPDATE")
    self.portraitUpdater:SetScript("OnEvent", function(_, event, unit)
        local playerToken = ResolvePlayerPortraitToken(self.portraitUnit)
        if event == "PLAYER_ENTERING_WORLD" or unit == self.portraitUnit or (playerToken and unit == playerToken) then
            self:RefreshPortrait()
        end
    end)

    return self.frame
end

return UnitPortrait
