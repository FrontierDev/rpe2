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

local function newFakeTexture()
    return {
        SetAllPoints = function() end,
        SetPoint = function() end,
        ClearAllPoints = function() end,
        SetHeight = function() end,
        SetWidth = function(self, width) self.width = width end,
        SetColorTexture = function(self, r, g, b)
            self.color = { r, g, b }
        end,
        SetTexture = function(self, texture)
            self.texture = texture
        end,
        Show = function(self) self.shown = true end,
        Hide = function(self) self.shown = false end,
    }
end

local function newFakeFontString()
    return {
        SetFont = function() end,
        SetPoint = function() end,
        SetJustifyH = function() end,
        SetTextColor = function() end,
        SetText = function(self, text) self.text = text end,
    }
end

local function newFakeFrame()
    return {
        SetSize = function(self, width, height) self.width, self.height = width, height end,
        SetWidth = function(self, width) self.width = width end,
        SetHeight = function(self, height) self.height = height end,
        ClearAllPoints = function() end,
        SetPoint = function(self, point, _, _, x)
            if point == "TOPLEFT" then
                self.left = x
            end
        end,
        CreateTexture = function() return newFakeTexture() end,
        CreateFontString = function() return newFakeFontString() end,
        EnableMouse = function() end,
        SetScript = function() end,
        Show = function(self) self.shown = true end,
        Hide = function(self) self.shown = false end,
    }
end

local previousCreateFrame = _G.CreateFrame
_G.CreateFrame = function()
    return newFakeFrame()
end

local auraRows = {
    { auraKey = "helpful-caster-a", name = "Helpful A", icon = "helpful-a", isHarmful = false, stacks = 1, turnsRemaining = 3, durationTurns = 6 },
    { auraKey = "helpful-caster-b", name = "Helpful B", icon = "helpful-b", isHarmful = false, stacks = 2, turnsRemaining = 6, durationTurns = 6 },
    { auraKey = "harmful-caster-a", name = "Harmful A", icon = "harmful-a", isHarmful = true, stacks = 1, turnsRemaining = 2, durationTurns = 4 },
    { auraKey = "harmful-caster-b", name = "Harmful B", icon = "harmful-b", isHarmful = true, stacks = 1, isInfinite = true },
}
local Addon = {
    Client = {
        Spellcasting = {
            AuraManager = {
                BuildUnitAuraSignature = function() return "aura-revision" end,
                GetUnitAuras = function() return auraRows end,
                BuildUnitAuraTooltipLines = function() return {} end,
            },
            AuraDescriptionBuilder = {
                BuildTooltipSection = function(_, auraRef)
                    return { descriptionText = tostring(auraRef or "") }
                end,
            },
        },
    },
    Internal = { Profile = {}, Comms = { ResourceSync = {} } },
    UI = { Panel = {}, ResourceBar = {}, CastBar = {} },
}

loadAddonFile("client/ui/widgets/widget_ActionBar_Resources.lua", Addon)
local widget = Addon.Client.UI.ActionBarWidget
local strip = newFakeFrame()
local eventState = { active = true, id = "aura-strip-event" }

widget:LayoutActionBarAuraStrip(strip, auraRows, 100, eventState, 17)
local helpfulA = widget.ActionBarAuraIconsByKey["helpful:helpful-caster-a"]
local harmfulA = widget.ActionBarAuraIconsByKey["harmful:harmful-caster-a"]
assertTrue(helpfulA ~= nil and harmfulA ~= nil, "helpful and harmful icons render in separate groups")
assertTrue(helpfulA.left + helpfulA.width <= harmfulA.left, "helpful and harmful groups do not overlap")
assertEqual(helpfulA.polarityMarker.width, 10, "finite helpful Aura duration marker reflects remaining turns")
assertEqual(harmfulA.polarityMarker.width, 10, "finite harmful Aura duration marker reflects remaining turns")
assertEqual(helpfulA.tooltipSpec.lines[2].left, "3 turns remaining", "Aura duration is left-aligned in the tooltip")
assertEqual(helpfulA.tooltipSpec.lines[2].right, nil, "Aura duration does not use the truncated right column")
assertEqual(widget.ActionBarAuraIconsByKey["harmful:harmful-caster-b"].polarityMarker.width, 20,
    "infinite Aura duration marker remains full")

local stableHelpfulA = helpfulA
widget:LayoutActionBarAuraStrip(strip, auraRows, 100, eventState, 17)
assertTrue(widget.ActionBarAuraIconsByKey["helpful:helpful-caster-a"] == stableHelpfulA, "aura icon identity remains stable across refresh")

widget:LayoutActionBarAuraStrip(strip, auraRows, 44, eventState, 17)
assertTrue(widget.ActionBarAuraIconsByKey["helpful:overflow"] ~= nil, "narrow strips expose overflow handling")

_G.CreateFrame = previousCreateFrame
print("Action Bar aura strip tests passed")
