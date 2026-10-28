local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local function assertTrue(value, message)
    if value ~= true then
        error(message, 2)
    end
end

local function loadAddonFile(path, addon)
    local chunk, loadError = loadfile(path)
    assert(chunk, loadError)
    chunk("RPEngine2", addon)
end

local eventState = { active = true, id = "resource-layout-event", turnNumber = 1, tickNumber = 1 }
local eventUnit = {
    eventID = 17,
    isPlayer = false,
    resources = {
        { resourceRef = "health", currentValue = 80, maxValue = 100 },
        { resourceRef = "primary", currentValue = 30, maxValue = 50 },
        { resourceRef = "special", currentValue = 2, maxValue = 5 },
    },
}

local Addon = {
    Client = {
        Spellcasting = {
            AuraManager = {
                BuildUnitAuraSignature = function()
                    return "aura-layout-test"
                end,
                GetUnitAuras = function()
                    local actionBarWidget = Addon.Client.UI and Addon.Client.UI.ActionBarWidget
                    return actionBarWidget and actionBarWidget.testAuras and {
                        { auraKey = "aura-layout-test", name = "Aura", icon = "aura", isHarmful = false, stacks = 1 },
                    } or {}
                end,
            },
        },
    },
    Internal = {
        Profile = {},
        Comms = { ResourceSync = {} },
    },
    UI = {
        Panel = {},
        ResourceBar = {},
        CastBar = {},
    },
}
local Client = Addon.Client

function Client:GetActionBarControlContext()
    return {
        eventState = eventState,
        activeEventUnit = eventUnit,
    }
end

local rootWidth = 240
local contentInset = 0
local rootFrame = {
    GetWidth = function()
        return rootWidth
    end,
    IsShown = function()
        return true
    end,
}

local containerHeight = nil
local containerFrame = {
    SetHeight = function(_, height)
        containerHeight = height
    end,
    ClearAllPoints = function() end,
    SetPoint = function() end,
}
local container = {
    GetFrame = function()
        return containerFrame
    end,
    Show = function(self)
        self.shown = true
    end,
}

local widgetRows = {}
local layoutCalls = {}
local hiddenRows = {}
local auraStrip = {
    ClearAllPoints = function() end,
    SetPoint = function() end,
    SetWidth = function(self, width) self.width = width end,
    SetHeight = function(self, height) self.height = height end,
    Show = function(self) self.shown = true end,
    Hide = function(self) self.shown = false end,
}

loadAddonFile("client/ui/widgets/widget_ActionBar_Resources.lua", Addon)
local widget = Addon.Client.UI.ActionBarWidget
local productionLayoutStatusRow = widget.LayoutStatusRow
widget.rootPanel = { GetFrame = function() return rootFrame end }
widget.GetContentInset = function() return contentInset end
widget.GetContentWidth = function(_, width) return math.max(0, width - (contentInset * 2)) end
widget.BuildActionBarResourceContext = function()
    return {
        eventState = eventState,
        resolvedByRef = {},
        localTrackedResources = nil,
        localActiveResources = nil,
        profileResourceSnapshot = nil,
        healthResourceRef = "health",
        primaryResourceRef = "primary",
        specialResourceRef = widget.testSpecial and "special" or nil,
        localEventUnitId = 0,
    }
end
widget.BuildActionBarResourceStates = function()
    local health = { kind = "resource", resourceRef = "health", currentText = "80", progressText = "80" }
    local primary = { kind = "resource", resourceRef = "primary", currentText = "30", progressText = "30" }
    local special = widget.testSpecial
        and { kind = "resource", resourceRef = "special", currentText = "2", progressText = "2" }
        or nil
    return { health = health, primary = primary, special = special }
end
widget.ResolveActionBarCastState = function()
    return widget.testCast
end
widget.EnsureActionBarStatusContainer = function()
    return container
end
widget.EnsureActionBarAuraStrip = function()
    widget.ActionBarAuraStrip = auraStrip
    return auraStrip
end
widget.LayoutActionBarAuraStrip = function(_, strip)
    strip:Show()
end
widget.EnsureActionBarStatusRow = function(_, index, kind)
    local row = widgetRows[index]
    if not row or row.barKind ~= kind then
        row = {
            barKind = kind,
            GetFrame = function(self)
                return self.frame
            end,
            frame = {
                ClearAllPoints = function() end,
                SetPoint = function(self, point, _, _, x, y)
                    if point == "TOPLEFT" then
                        self.leftOffset = x
                        self.topOffset = y
                    end
                end,
                Hide = function(self)
                    self.hidden = true
                    hiddenRows[index] = true
                end,
                Show = function(self)
                    self.hidden = false
                end,
            },
            SetOption = function(self, key, value)
                self[key] = value
            end,
        }
        widgetRows[index] = row
    end
    return row
end
widget.LayoutStatusRow = function(_, row, state, leftOffset, rightOffset, width, height)
    row.state = state
    layoutCalls[#layoutCalls + 1] = {
        row = row,
        resourceRef = state.resourceRef,
        leftOffset = leftOffset,
        rightOffset = rightOffset,
        width = width,
        height = height,
        topOffset = row.frame.topOffset,
    }
end
widget.HideActionBarCompanionBars = function(self)
    self.lastCompanionRefreshSignature = nil
    self.hidden = true
    return true
end

local function refresh(special, cast, aura)
    widget.testSpecial = special == true
    widget.testCast = cast == true and { kind = "cast", spellRef = "test:spell" } or nil
    widget.testAuras = aura == true
    layoutCalls = {}
    containerHeight = nil
    hiddenRows = {}
    widget.lastCompanionRefreshSignature = nil
    assertEqual(widget:RefreshActionBarCompanionBars("layout-test"), true, "companion layout refresh succeeds")
end

refresh(false, false)
assertEqual(#layoutCalls, 2, "two resources share one row")
assertEqual(layoutCalls[1].width, 118, "two-resource first width reserves the gap")
assertEqual(layoutCalls[2].width, 118, "two-resource second width reserves the gap")
assertEqual(layoutCalls[1].leftOffset, 0, "two-resource first bar starts at row origin")
assertEqual(layoutCalls[2].leftOffset, 122, "two-resource second bar follows the gap")
assertEqual(layoutCalls[2].rightOffset, 240, "two-resource row fills its content width")
assertEqual(containerHeight, 16, "resource-only layout has one row")

refresh(true, false)
assertEqual(#layoutCalls, 3, "special resource joins the base resource row")
assertEqual(layoutCalls[1].width, 92, "three-resource first width uses forty percent of usable width")
assertEqual(layoutCalls[2].width, 92, "three-resource second width uses forty percent of usable width")
assertEqual(layoutCalls[3].width, 48, "three-resource remainder goes to the last bar")
assertEqual(layoutCalls[3].resourceRef, "special", "special resource remains last in the row")
assertEqual(layoutCalls[3].rightOffset, 240, "three-resource row fills its content width")
assertEqual(layoutCalls[1].topOffset, layoutCalls[2].topOffset, "three resources share one horizontal row")
assertEqual(layoutCalls[2].topOffset, layoutCalls[3].topOffset, "special resource shares the base row")
assertEqual(containerHeight, 16, "three resources still occupy one row")

refresh(true, true)
assertEqual(#layoutCalls, 4, "cast and resources render as two rows")
assertEqual(layoutCalls[1].resourceRef, nil, "cast remains the first row")
assertEqual(layoutCalls[4].resourceRef, "special", "special remains last after the cast row")
assertEqual(containerHeight, 36, "cast plus resource rows preserve vertical spacing")

refresh(true, false, true)
assertEqual(#layoutCalls, 3, "Aura strip and resources render as separate rows")
assertTrue(widgetRows[1].hidden == true, "reserved Aura row hides the stale status bar")
assertEqual(containerHeight, 40, "Aura strip plus resource rows preserve vertical spacing")

refresh(false, false)
assertEqual(#layoutCalls, 2, "special removal returns to two bars")
assertTrue(hiddenRows[3] == true or widgetRows[3] == nil, "removed third bar is hidden")

contentInset = 8
refresh(true, false)
assertEqual(layoutCalls[3].rightOffset, 224, "resource row respects action bar content insets")

contentInset = 0
rootWidth = 301
refresh(true, false)
assertEqual(layoutCalls[1].width + layoutCalls[2].width + layoutCalls[3].width + 8, 301,
    "wide rows keep all integer remainder pixels")
assertEqual(layoutCalls[3].rightOffset, 301, "wide rows do not overflow the content width")

local narrowRow = {
    barKind = "resource",
    GetFrame = function(self) return self.frame end,
    frame = {
        SetHeight = function() end,
        Show = function() end,
    },
    SetOption = function(self, key, value) self[key] = value end,
    progressBar = {
        label = {
            ClearAllPoints = function() end,
            SetPoint = function(self, point, _, _, x)
                self[point:lower() .. "Offset"] = x
            end,
            SetJustifyH = function(self, justify)
                self.justify = justify
            end,
        },
    },
}
productionLayoutStatusRow(widget, narrowRow, { kind = "resource", resourceRef = "special" }, 0, 48, 48, 16)
assertEqual(narrowRow.progressFontSize, 8, "narrow resource bars reduce the progress font size")
assertEqual(narrowRow.progressBar.label.justify, "RIGHT", "resource labels are right-aligned")
assertEqual(narrowRow.progressBar.label.leftOffset, 22, "resource labels stay clear of the icon")
assertEqual(narrowRow.progressBar.label.rightOffset, -4, "resource labels keep padding from the bar's right edge")

print("Action Bar resource layout tests passed")
