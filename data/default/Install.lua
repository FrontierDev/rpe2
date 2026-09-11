local addonName, Addon = ...

local function logInstallDiagnostic(message)
    local debug = Addon.Debug or nil
    if debug and type(debug.Internal) == "function" then
        debug.Internal(
            "Packaged default dataset installation skipped: %s",
            tostring(message or "unknown error")
        )
    end
end

local function applyPackagedVersionCorrections(definitions)
    -- Leatherworking v2 contents were briefly packaged with version 1, so
    -- clients that had already recorded v1 would otherwise skip the rewrite.
    -- Keep this as a version floor so future packaged versions remain authoritative.
    local leatherworking = definitions["538a54a0"]
    if type(leatherworking) == "table"
        and type(leatherworking.version) == "number"
        and leatherworking.version < 2
    then
        leatherworking.version = 2
    end
end

local function syncDefaultDatasets()
    local Database = Addon.Internal and Addon.Internal.Database or nil
    local DefaultDatasets = Addon.Data and Addon.Data.DefaultDatasets or nil

    if type(Database) ~= "table" then
        logInstallDiagnostic("database module is unavailable")
        return false
    end
    if type(Database.SyncDefaultDatasets) ~= "function" then
        logInstallDiagnostic("default dataset synchronization API is unavailable")
        return false
    end
    if type(DefaultDatasets) ~= "table" or type(DefaultDatasets.Definitions) ~= "table" then
        logInstallDiagnostic("packaged default dataset definitions are unavailable")
        return false
    end

    -- SavedVariables become authoritative at ADDON_LOADED. Database.lua also
    -- listens for that event, so do not depend on frame-handler ordering: if its
    -- cached root still points at the pre-SavedVariables table, rebind through
    -- the canonical EnsureDatasets() path before synchronizing packages.
    local globalEnvironment = _G or {}
    local savedRoot = rawget(globalEnvironment, "RPEngineDatasetDB")
    if type(savedRoot) ~= "table" or Database.Datasets ~= savedRoot then
        if type(Database.EnsureDatasets) ~= "function" then
            logInstallDiagnostic("dataset SavedVariables root is not initialized")
            return false
        end
        Database.EnsureDatasets()
        savedRoot = rawget(globalEnvironment, "RPEngineDatasetDB")
    end

    if type(savedRoot) ~= "table" or Database.Datasets ~= savedRoot then
        logInstallDiagnostic("dataset SavedVariables root is not authoritative")
        return false
    end

    applyPackagedVersionCorrections(DefaultDatasets.Definitions)
    Database.SyncDefaultDatasets(DefaultDatasets.Definitions)
    return true
end

local installer = CreateFrame and CreateFrame("Frame")
if not installer then
    logInstallDiagnostic("ADDON_LOADED event frame is unavailable")
    return
end

installer:RegisterEvent("ADDON_LOADED")
installer:SetScript("OnEvent", function(self, event, loadedAddonName)
    if event ~= "ADDON_LOADED" or loadedAddonName ~= addonName then
        return
    end

    self:UnregisterEvent("ADDON_LOADED")
    syncDefaultDatasets()
end)
