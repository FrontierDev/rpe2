local _, Addon = ...

Addon.UI = Addon.UI or {}
Addon.Internal = Addon.Internal or {}
Addon.Internal.Database = Addon.Internal.Database or {}
Addon.Internal.Database.Classes = Addon.Internal.Database.Classes or {}

local UI = Addon.UI
local UnitPortrait = UI.UnitPortrait
local EventUnit = Addon.Internal.Database.Classes.EventUnit

if type(UnitPortrait) ~= "table" then
    return
end

local APPEARANCE_FIELD_MAP = {
    modelDisplayId = "displayId",
    displayId = "displayId",
    fileDataId = "fileDataId",
    cam = "cam",
    rot = "rot",
    z = "z",
}

local function resolveRuntimeAppearance(unit)
    if type(unit) ~= "table" or unit.isPlayer == true or type(unit.GetResolvedAppearance) ~= "function" then
        return nil
    end

    local ok, appearance = pcall(unit.GetResolvedAppearance, unit)
    if not ok or type(appearance) ~= "table" then
        return nil
    end

    return appearance
end

function UnitPortrait.ResolveRuntimeAppearance(unit)
    return resolveRuntimeAppearance(unit)
end

-- Some presentation caches still inspect model-like fields on EventUnit objects.
-- Route those reads through the same EventUnit appearance resolver rather than
-- maintaining a second fixed-model source of truth.
if type(EventUnit) == "table"
    and EventUnit._variantPresentationIndexInstalled ~= true
    and type(EventUnit.__index) == "table"
then
    local baseEventUnitIndex = EventUnit.__index

    EventUnit.__index = function(instance, key)
        local classValue = baseEventUnitIndex[key]
        if classValue ~= nil then
            return classValue
        end

        local appearanceField = APPEARANCE_FIELD_MAP[key]
        if appearanceField then
            local appearance = resolveRuntimeAppearance(instance)
            return appearance and appearance[appearanceField] or nil
        end

        return nil
    end

    EventUnit._variantPresentationIndexInstalled = true
end

if UnitPortrait._variantPresentationRefreshInstalled ~= true then
    local baseRefreshPortrait = UnitPortrait.RefreshPortrait

    function UnitPortrait:RefreshPortrait()
        local portraitUnit = self.portraitUnit
        local appearance = resolveRuntimeAppearance(portraitUnit)
        if not appearance
            or type(portraitUnit) ~= "table"
            or type(portraitUnit.GetResolvedUnit) ~= "function"
            or type(baseRefreshPortrait) ~= "function"
        then
            return baseRefreshPortrait and baseRefreshPortrait(self) or nil
        end

        local baseResolver = portraitUnit.GetResolvedUnit
        local okBase, baseUnit = pcall(baseResolver, portraitUnit)
        if not okBase then
            baseUnit = nil
        end

        -- The existing UnitPortrait renderer already owns model-frame setup,
        -- transforms, player portraits, tooltips, and fallback textures. Give it
        -- a read-only definition proxy whose model fields are the exact resolved
        -- runtime Appearance, while all other definition fields still fall back
        -- to the Base Unit.
        local presentationUnit = {
            modelDisplayId = appearance.displayId,
            displayId = appearance.displayId,
            fileDataId = appearance.fileDataId,
            cam = appearance.cam,
            rot = appearance.rot,
            z = appearance.z,
        }
        if type(baseUnit) == "table" then
            setmetatable(presentationUnit, { __index = baseUnit })
        end

        local rawResolver = rawget(portraitUnit, "GetResolvedUnit")
        rawset(portraitUnit, "GetResolvedUnit", function()
            return presentationUnit
        end)

        local ok, result = pcall(baseRefreshPortrait, self)

        if rawResolver ~= nil then
            rawset(portraitUnit, "GetResolvedUnit", rawResolver)
        else
            rawset(portraitUnit, "GetResolvedUnit", nil)
        end

        if not ok then
            error(result, 0)
        end

        return result
    end

    UnitPortrait._variantPresentationRefreshInstalled = true
end
