local _, Addon = ...

Addon.Server = Addon.Server or {}
Addon.Server.UI = Addon.Server.UI or {}
Addon.Internal = Addon.Internal or {}
Addon.Internal.Database = Addon.Internal.Database or {}
Addon.Internal.Database.Classes = Addon.Internal.Database.Classes or {}

local Server = Addon.Server
local ServerUI = Addon.Server.UI
local UI = Addon.UI or {}
local UnitClass = Addon.Internal.Database.Classes.Unit
local EventUnitWindow = ServerUI.EventUnit

if type(EventUnitWindow) ~= "table" then
    return
end

local PRESET_ROW_HEIGHT = 22
local PRESET_LABEL_WIDTH = 48
local PRESET_DROPDOWN_WIDTH = 264

local function normalizePresetIndex(unit, value)
    if UnitClass and UnitClass.NormalizePresetIndex then
        return UnitClass.NormalizePresetIndex(unit, value)
    end
    return 0
end

function EventUnitWindow:BuildPresetItems(unit)
    local items = {
        { label = "Base", value = 0 },
    }

    for index = 1, #(unit and unit.presets or {}) do
        local preset = unit.presets[index]
        local name = tostring(preset and preset.name or ""):gsub("^%s+", ""):gsub("%s+$", "")
        items[#items + 1] = {
            label = name ~= "" and name or ("Preset %d"):format(index),
            value = index,
        }
    end

    return items
end

function EventUnitWindow:HandlePresetSelection(value)
    self.selectedPresetIndex = normalizePresetIndex(self.selectedUnit, value)
    self:Refresh()
end

function EventUnitWindow:ResolveSelectedVariantPreview()
    if not self.selectedUnit or not self.selectedRegistryId or self.selectedRegistryId == "" then
        return nil
    end

    if Server and Server.BuildResolvedNpcVariant then
        return Server:BuildResolvedNpcVariant(self.selectedRegistryId, {
            presetIndex = self.selectedPresetIndex,
            selectRandomAppearance = false,
        })
    end

    return nil
end

local baseBuildWindow = EventUnitWindow.BuildWindow
function EventUnitWindow:BuildWindow()
    local window = baseBuildWindow and baseBuildWindow(self) or self.window
    if not window or self.presetRow then
        return window
    end

    local content = window.GetContentFrame and window:GetContentFrame() or nil
    if not content or not self.rootLayout then
        return window
    end

    local windowFrame = window.GetFrame and window:GetFrame() or nil
    if windowFrame and windowFrame.GetHeight and windowFrame.SetHeight then
        windowFrame:SetHeight((windowFrame:GetHeight() or 196) + PRESET_ROW_HEIGHT + 4)
    end

    self.presetRow = UI.CreateLayout(UI.HorizontalLayoutGroup, content, "RPEServerEventUnitPresetRow", {
        width = 320,
        height = PRESET_ROW_HEIGHT,
        spacing = 8,
        autoSize = false,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })

    self.presetLabel = UI.CreateText(self.presetRow:GetFrame(), "RPEServerEventUnitPresetLabel", "Preset", {
        width = PRESET_LABEL_WIDTH,
        height = PRESET_ROW_HEIGHT,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.presetRow:AddChild(self.presetLabel)

    self.presetDropdown = UI.CreateDropdown(content, "RPEServerEventUnitPresetDropdown", {
        width = PRESET_DROPDOWN_WIDTH,
        height = 18,
        items = self:BuildPresetItems(self.selectedUnit),
        selectedValue = 0,
        placeholder = "Base",
        onValueChanged = function(value)
            self:HandlePresetSelection(value)
        end,
    })
    self.presetRow:AddChild(self.presetDropdown)

    self.rootLayout:AddChild(self.presetRow)
    local children = self.rootLayout.children or {}
    for index = #children, 1, -1 do
        if children[index] == self.presetRow then
            table.remove(children, index)
            break
        end
    end
    table.insert(children, 2, self.presetRow)
    self.rootLayout:SetChildren(children)
    self.rootLayout:RefreshLayout()

    return window
end

local baseRefresh = EventUnitWindow.Refresh
function EventUnitWindow:Refresh()
    if baseRefresh then
        baseRefresh(self)
    end

    local addMode = self.mode == "add"
    local hasUnit = self.selectedUnit ~= nil
    self.selectedPresetIndex = normalizePresetIndex(self.selectedUnit, self.selectedPresetIndex)

    if self.presetDropdown then
        self.presetDropdown:SetItems(self:BuildPresetItems(self.selectedUnit))
        self.presetDropdown:SetSelectedValue(self.selectedPresetIndex, true)
        if self.presetDropdown.SetEnabled then
            self.presetDropdown:SetEnabled(addMode and hasUnit and #(self.selectedUnit and self.selectedUnit.presets or {}) > 0)
        end
    end

    local variant = addMode and self:ResolveSelectedVariantPreview() or nil
    if variant then
        local appearance = variant.appearance
        if self.previewPortrait and self.previewPortrait.SetUnit then
            self.previewPortrait:SetUnit({
                isNPC = true,
                team = tonumber(self.selectedTeam) or 1,
                modelDisplayId = appearance and appearance.displayId or nil,
                fileDataId = appearance and appearance.fileDataId or nil,
                cam = appearance and appearance.cam or nil,
                rot = appearance and appearance.rot or nil,
                z = appearance and appearance.z or nil,
            })
        end
        if self.previewNameText and self.previewNameText.SetText then
            self.previewNameText:SetText(variant.name ~= "" and variant.name or "Unnamed Unit")
        end
        if self.previewHealthText and self.previewHealthText.SetText then
            self.previewHealthText:SetText(self:BuildUnitHealthText({ resources = variant.resources or {} }))
        end
        self:RefreshSpellPreview({ spells = variant.spells or {} })
    end

    if self.presetRow and self.presetRow.RefreshLayout then
        self.presetRow:RefreshLayout()
    end
    if self.rootLayout and self.rootLayout.RefreshLayout then
        self.rootLayout:RefreshLayout()
    end
end

local baseHandleUnitSelection = EventUnitWindow.HandleUnitSelection
function EventUnitWindow:HandleUnitSelection(registryId)
    self.selectedPresetIndex = 0
    if baseHandleUnitSelection then
        return baseHandleUnitSelection(self, registryId)
    end
end

function EventUnitWindow:ApplySelection()
    if self.mode ~= "add" or not self.selectedUnit then
        return false
    end

    local presetIndex = normalizePresetIndex(self.selectedUnit, self.selectedPresetIndex)
    if type(self.callback) == "function" then
        self.callback(self.selectedRegistryId, nil, {
            presetIndex = presetIndex,
            team = tonumber(self.selectedTeam) or 1,
            active = self.selectedActive ~= false,
            hidden = self.selectedHidden == true,
            boss = self.selectedBoss == true,
            raidMarker = math.max(0, math.floor(tonumber(self.selectedRaidMarker) or 0)),
        })
    end

    return true
end

local baseOpenForAdd = EventUnitWindow.OpenForAdd
function EventUnitWindow:OpenForAdd(callback)
    self.selectedPresetIndex = 0
    return baseOpenForAdd and baseOpenForAdd(self, callback) or nil
end
