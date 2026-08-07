local _, Addon = ...

local UI = Addon.UI or {}
Addon.UI = UI
local BaseElement = UI.BaseElement
local Text = UI.Text
local TextButton = UI.TextButton
local UnitPortrait = UI.UnitPortrait
local Font = UI.Font or {}
local Constants = UI.Constants or {}

UI.EditorModelField = UI.EditorModelField or {}
local EditorModelField = UI.EditorModelField
EditorModelField.__index = EditorModelField
setmetatable(EditorModelField, { __index = BaseElement })

local EMPTY_DISPLAY_TEXT = "DisplayID: -"
local EMPTY_FILE_DATA_TEXT = "FileDataID: -"
local EMPTY_PATH_TEXT = "Path: -"

local function clampNumber(value, fallback)
    local number = tonumber(value)
    if number == nil then
        return fallback
    end

    return number
end

local function normalizeModelId(value)
    local number = tonumber(value)
    if number == nil or number <= 0 then
        return nil
    end

    return number
end

function EditorModelField:New(options)
    local instance = BaseElement.New(self, options)
    instance.options.border = false
    instance.selectButton = nil
    instance.clearButton = nil
    instance.previewPortrait = nil
    instance.displayIdElement = nil
    instance.fileDataIdElement = nil
    instance.pathElement = nil
    instance.displayId = nil
    instance.fileDataId = nil
    instance.filePath = nil
    instance.cam = 1
    instance.rot = 0
    instance.z = -0.35
    return instance
end

function EditorModelField:GetButton()
    return self.selectButton
end

function EditorModelField:GetClearButton()
    return self.clearButton
end

function EditorModelField:SetModel(displayId, fileDataId, filePath)
    self.displayId = normalizeModelId(displayId)
    self.fileDataId = normalizeModelId(fileDataId)
    self.filePath = filePath ~= nil and tostring(filePath) or nil

    if self.displayIdElement and self.displayIdElement.SetText then
        self.displayIdElement:SetText(self.displayId and ("DisplayID: " .. tostring(self.displayId)) or EMPTY_DISPLAY_TEXT)
    end
    if self.fileDataIdElement and self.fileDataIdElement.SetText then
        self.fileDataIdElement:SetText(self.fileDataId and ("FileDataID: " .. tostring(self.fileDataId)) or EMPTY_FILE_DATA_TEXT)
    end
    if self.pathElement and self.pathElement.SetText then
        self.pathElement:SetText(self.filePath and self.filePath ~= "" and ("Path: " .. self.filePath) or EMPTY_PATH_TEXT)
    end

    self:RefreshPreview()
end

function EditorModelField:SetPreviewTransforms(cam, rot, z)
    self.cam = clampNumber(cam, 1)
    self.rot = clampNumber(rot, 0)
    self.z = clampNumber(z, -0.35)
    self:RefreshPreview()
end

function EditorModelField:RefreshPreview()
    if not self.previewPortrait or not self.previewPortrait.SetUnit then
        return
    end
    self.previewPortrait:SetUnit({
        isNPC = true,
        team = 1,
        modelDisplayId = self.displayId,
        fileDataId = self.fileDataId,
        cam = clampNumber(self.cam, 1),
        rot = clampNumber(self.rot, 0),
        z = clampNumber(self.z, -0.35),
    })
end

function EditorModelField:SetEnabled(enabled)
    self.enabled = enabled ~= false

    if self.selectButton and self.selectButton.SetEnabled then
        self.selectButton:SetEnabled(self.enabled)
    end
    if self.clearButton and self.clearButton.SetEnabled then
        self.clearButton:SetEnabled(self.enabled)
    end

    local alpha = self.enabled and 1 or 0.5
    if self.previewPortrait and self.previewPortrait.GetFrame and self.previewPortrait:GetFrame() and self.previewPortrait:GetFrame().SetAlpha then
        self.previewPortrait:GetFrame():SetAlpha(alpha)
    end
    if self.displayIdElement and self.displayIdElement.GetFrame and self.displayIdElement:GetFrame() and self.displayIdElement:GetFrame().SetAlpha then
        self.displayIdElement:GetFrame():SetAlpha(alpha)
    end
    if self.fileDataIdElement and self.fileDataIdElement.GetFrame and self.fileDataIdElement:GetFrame() and self.fileDataIdElement:GetFrame().SetAlpha then
        self.fileDataIdElement:GetFrame():SetAlpha(alpha)
    end
    if self.pathElement and self.pathElement.GetFrame and self.pathElement:GetFrame() and self.pathElement:GetFrame().SetAlpha then
        self.pathElement:GetFrame():SetAlpha(alpha)
    end
    if self.frame and self.frame.SetAlpha then
        self.frame:SetAlpha(alpha)
    end

    return self.enabled
end

function EditorModelField:Create()
    if self.frame then
        return self.frame
    end

    local parentFrame = self:GetParentFrame()
    if not parentFrame then
        error("An editor model field prefab requires a parent frame before Create().", 2)
    end

    local width = self.options.width or 236
    local height = self.options.height or 146
    local previewHeight = self.options.previewHeight or 120
    local previewSize = math.min(width, previewHeight)
    local buttonHeight = self.options.buttonHeight or 18
    local selectButtonWidth = self.options.buttonWidth or 96
    local clearButtonWidth = self.options.clearButtonWidth or 42
    local spacing = self.options.spacing or 6
    local metadataHeight = 12

    local frame = CreateFrame("Frame", self.name, parentFrame, self.options.template)
    self:SetFrame(frame)
    frame:SetSize(width, height)

    self.selectButton = TextButton:New({
        name = (self.name or "EditorModelField") .. "SelectButton",
        width = selectButtonWidth,
        height = buttonHeight,
        text = self.options.buttonText or "Select Model",
        fontFile = self.options.fontFile,
        fontSize = self.options.buttonFontSize or self.options.fontSize,
        labelColor = self.options.buttonLabelColor or UI.ResolveColor(nil, "text.primary"),
        backgroundColor = self.options.buttonBackgroundColor,
    })
    self.selectButton:SetParent(frame)
    self.selectButton:Create()
    self.selectButton:GetFrame():SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)

    self.clearButton = TextButton:New({
        name = (self.name or "EditorModelField") .. "ClearButton",
        width = clearButtonWidth,
        height = buttonHeight,
        text = self.options.clearButtonText or "Clear",
        fontFile = self.options.fontFile,
        fontSize = self.options.buttonFontSize or self.options.fontSize,
        labelColor = self.options.buttonLabelColor or UI.ResolveColor(nil, "text.primary"),
        backgroundColor = self.options.buttonBackgroundColor,
    })
    self.clearButton:SetParent(frame)
    self.clearButton:Create()
    self.clearButton:GetFrame():SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)

    self.previewPortrait = UnitPortrait:New({
        name = (self.name or "EditorModelField") .. "PreviewPortrait",
        portraitWidth = previewSize,
        portraitHeight = previewSize,
        width = previewSize,
        height = previewSize,
        progressHeight = 0,
        progressSpacing = 0,
        value = 0,
        progressText = "",
        unit = {
            isNPC = true,
            team = 1,
        },
    })
    self.previewPortrait:SetParent(frame)
    self.previewPortrait:Create()
    self.previewPortrait:GetFrame():SetPoint("TOP", frame, "TOP", 0, -(buttonHeight + spacing))

    self.displayIdElement = Text:New({
        name = (self.name or "EditorModelField") .. "DisplayIdText",
        width = width,
        height = metadataHeight,
        border = false,
    })
    self.displayIdElement:SetParent(frame)
    self.displayIdElement:Create()
    self.displayIdElement:GetFrame():SetPoint("TOPLEFT", self.previewPortrait:GetFrame(), "BOTTOMLEFT", 0, -spacing)
    if self.displayIdElement.textRegion and self.displayIdElement.textRegion.SetJustifyH then
        self.displayIdElement.textRegion:SetJustifyH("LEFT")
    end
    Font:Apply(self.displayIdElement.textRegion, self.options, {
        fontSize = self.options.fontSize or (Constants.FontSizes and Constants.FontSizes.Body) or 8,
    })

    self.fileDataIdElement = Text:New({
        name = (self.name or "EditorModelField") .. "FileDataIdText",
        width = width,
        height = metadataHeight,
        border = false,
    })
    self.fileDataIdElement:SetParent(frame)
    self.fileDataIdElement:Create()
    self.fileDataIdElement:GetFrame():SetPoint("TOPLEFT", self.displayIdElement:GetFrame(), "BOTTOMLEFT", 0, -2)
    if self.fileDataIdElement.textRegion and self.fileDataIdElement.textRegion.SetJustifyH then
        self.fileDataIdElement.textRegion:SetJustifyH("LEFT")
    end
    Font:Apply(self.fileDataIdElement.textRegion, self.options, {
        fontSize = self.options.fontSize or (Constants.FontSizes and Constants.FontSizes.Body) or 8,
    })

    self.pathElement = Text:New({
        name = (self.name or "EditorModelField") .. "PathText",
        width = width,
        height = metadataHeight,
        border = false,
    })
    self.pathElement:SetParent(frame)
    self.pathElement:Create()
    self.pathElement:GetFrame():SetPoint("TOPLEFT", self.fileDataIdElement:GetFrame(), "BOTTOMLEFT", 0, -2)
    if self.pathElement.textRegion and self.pathElement.textRegion.SetJustifyH then
        self.pathElement.textRegion:SetJustifyH("LEFT")
    end
    Font:Apply(self.pathElement.textRegion, self.options, {
        fontSize = self.options.pathFontSize or self.options.fontSize or (Constants.FontSizes and Constants.FontSizes.Small) or 6,
    })

    self:SetModel(self.options.displayId, self.options.fileDataId, self.options.filePath)
    self:SetPreviewTransforms(self.options.cam, self.options.rot, self.options.z)
    self:SetEnabled(self.options.enabled ~= false)

    return self.frame
end

return EditorModelField
