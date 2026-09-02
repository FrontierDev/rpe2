local _, Addon = ...

Addon.UI = Addon.UI or {}
Addon.Internal = Addon.Internal or {}
Addon.Internal.Database = Addon.Internal.Database or {}
Addon.Internal.Database.Classes = Addon.Internal.Database.Classes or {}

local UI = Addon.UI
local UnitPortrait = UI.UnitPortrait
local Classes = Addon.Internal.Database.Classes
local EventUnit = Classes.EventUnit
local Unit = Classes.Unit

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

local function normalizeIdentityIndex(value)
    local numericValue = tonumber(value)
    if numericValue == nil
        or numericValue ~= numericValue
        or numericValue == math.huge
        or numericValue == -math.huge
    then
        return 0
    end
    return math.floor(numericValue)
end

local function buildResolution(unit, status, reason, appearance, appearanceCount, resolvedPresetIndex)
    return {
        status = tostring(status or "unresolved"),
        reason = reason ~= nil and tostring(reason) or nil,
        eventID = tonumber(type(unit) == "table" and unit.eventID or nil) or 0,
        registryID = tostring(type(unit) == "table" and unit.registryID or ""),
        presetIndex = normalizeIdentityIndex(type(unit) == "table" and unit.presetIndex or 0),
        appearanceIndex = normalizeIdentityIndex(type(unit) == "table" and unit.appearanceIndex or 0),
        resolvedPresetIndex = tonumber(resolvedPresetIndex) or 0,
        appearanceCount = math.max(0, math.floor(tonumber(appearanceCount) or 0)),
        displayId = tonumber(type(appearance) == "table" and appearance.displayId or nil),
        fileDataId = tonumber(type(appearance) == "table" and appearance.fileDataId or nil),
    }
end

local function resolveRuntimeAppearance(unit)
    if type(unit) ~= "table" then
        return nil, buildResolution(unit, "not-unit", "unit-unavailable")
    end
    if unit.isPlayer == true then
        return nil, buildResolution(unit, "player", nil)
    end
    if type(unit.GetResolvedUnit) ~= "function" or type(unit.GetResolvedAppearance) ~= "function" then
        return nil, buildResolution(unit, "unresolved", "appearance-resolver-unavailable")
    end

    local okBase, baseUnit = pcall(unit.GetResolvedUnit, unit)
    if not okBase or type(baseUnit) ~= "table" then
        return nil, buildResolution(unit, "unresolved", "definition-unavailable")
    end

    if type(Unit) ~= "table"
        or type(Unit.NormalizePresetIndex) ~= "function"
        or type(Unit.ResolveEffectiveAppearances) ~= "function"
    then
        return nil, buildResolution(unit, "unresolved", "appearance-api-unavailable")
    end

    local requestedPresetIndex = normalizeIdentityIndex(unit.presetIndex)
    local resolvedPresetIndex = Unit.NormalizePresetIndex(baseUnit, requestedPresetIndex)
    if requestedPresetIndex > 0 and resolvedPresetIndex ~= requestedPresetIndex then
        return nil, buildResolution(
            unit,
            "invalid",
            "preset-index-out-of-range",
            nil,
            0,
            resolvedPresetIndex
        )
    end

    local okAppearances, resolvedAppearances = pcall(Unit.ResolveEffectiveAppearances, baseUnit, resolvedPresetIndex)
    if not okAppearances then
        return nil, buildResolution(
            unit,
            "unresolved",
            "appearance-pool-resolution-error",
            nil,
            0,
            resolvedPresetIndex
        )
    end
    local appearances = type(resolvedAppearances) == "table" and resolvedAppearances or {}

    local requestedAppearanceIndex = tonumber(unit.appearanceIndex)
    if requestedAppearanceIndex == nil
        or requestedAppearanceIndex ~= requestedAppearanceIndex
        or requestedAppearanceIndex == math.huge
        or requestedAppearanceIndex == -math.huge
        or requestedAppearanceIndex <= 0
    then
        -- appearanceIndex=0 is the documented legacy/base identity. Keep the
        -- previous base Unit renderer for that case rather than turning older
        -- EventUnits into question marks.
        return nil, buildResolution(
            unit,
            "legacy-base",
            "appearance-unselected",
            nil,
            #appearances,
            resolvedPresetIndex
        )
    end
    if math.floor(requestedAppearanceIndex) ~= requestedAppearanceIndex then
        return nil, buildResolution(
            unit,
            "invalid",
            "appearance-index-invalid",
            nil,
            #appearances,
            resolvedPresetIndex
        )
    end
    if #appearances == 0 then
        return nil, buildResolution(unit, "unresolved", "appearance-pool-empty", nil, 0, resolvedPresetIndex)
    end
    if requestedAppearanceIndex > #appearances then
        return nil, buildResolution(
            unit,
            "invalid",
            "appearance-index-out-of-range",
            nil,
            #appearances,
            resolvedPresetIndex
        )
    end

    local ok, appearance = pcall(unit.GetResolvedAppearance, unit)
    if not ok then
        return nil, buildResolution(
            unit,
            "unresolved",
            "appearance-resolution-error",
            nil,
            #appearances,
            resolvedPresetIndex
        )
    end
    if type(appearance) ~= "table" then
        return nil, buildResolution(
            unit,
            "unresolved",
            "appearance-unavailable",
            nil,
            #appearances,
            resolvedPresetIndex
        )
    end

    return appearance, buildResolution(
        unit,
        "resolved",
        nil,
        appearance,
        #appearances,
        resolvedPresetIndex
    )
end

function UnitPortrait.ResolveRuntimeAppearance(unit)
    return resolveRuntimeAppearance(unit)
end

function UnitPortrait.ResolveRuntimeAppearanceDiagnostic(unit)
    local _, diagnostic = resolveRuntimeAppearance(unit)
    return diagnostic
end

-- Some presentation caches still inspect model-like fields on EventUnit objects.
-- Route those reads through the same EventUnit appearance resolver rather than
-- maintaining a second fixed-model source of truth. Invalid positive runtime
-- indices deliberately resolve to nil here, so caches cannot mistake appearance
-- #1 for the requested identity.
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

local function invokeBaseWithResolvedUnit(self, baseRefreshPortrait, portraitUnit, resolvedUnit)
    local rawResolver = rawget(portraitUnit, "GetResolvedUnit")
    rawset(portraitUnit, "GetResolvedUnit", function()
        return resolvedUnit
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

local function shouldForceExplicitFallback(diagnostic)
    local status = type(diagnostic) == "table" and tostring(diagnostic.status or "") or ""
    return status == "invalid" or status == "unresolved"
end

if UnitPortrait._variantPresentationRefreshInstalled ~= true then
    local baseRefreshPortrait = UnitPortrait.RefreshPortrait

    function UnitPortrait:RefreshPortrait()
        local portraitUnit = self.portraitUnit
        local appearance, diagnostic = resolveRuntimeAppearance(portraitUnit)
        self.lastVariantPortraitResolution = diagnostic

        if type(portraitUnit) ~= "table"
            or portraitUnit.isPlayer == true
            or type(portraitUnit.GetResolvedUnit) ~= "function"
            or type(baseRefreshPortrait) ~= "function"
        then
            return baseRefreshPortrait and baseRefreshPortrait(self) or nil
        end

        if not appearance then
            if shouldForceExplicitFallback(diagnostic) then
                -- Do not let an invalid/stale EventUnit identity drop through to
                -- the Base Unit's primary model. Force the existing generic
                -- texture fallback while leaving all non-visual slot state on
                -- the original EventUnit.
                local result = invokeBaseWithResolvedUnit(self, baseRefreshPortrait, portraitUnit, nil)
                if type(self.lastVariantPortraitResolution) == "table" then
                    self.lastVariantPortraitResolution.renderMode = "fallback"
                end
                return result
            end

            local result = baseRefreshPortrait(self)
            if type(self.lastVariantPortraitResolution) == "table" then
                self.lastVariantPortraitResolution.renderMode = "base"
            end
            return result
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

        local result = invokeBaseWithResolvedUnit(self, baseRefreshPortrait, portraitUnit, presentationUnit)
        if type(self.lastVariantPortraitResolution) == "table" then
            self.lastVariantPortraitResolution.renderMode = "appearance"
        end
        return result
    end

    UnitPortrait._variantPresentationRefreshInstalled = true
end
