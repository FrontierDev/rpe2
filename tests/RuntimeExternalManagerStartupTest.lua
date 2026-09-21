local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local Addon = {
    Name = "RPEngine2",
    Internal = { Database = {} },
}
local savedManagerRoot = rawget(_G, "RPEngineManagerDB")

local chunk, loadError = loadfile("core/internal/Runtime.lua")
assert(chunk, loadError)
chunk(nil, Addon)

local managerChunk, managerLoadError = loadfile("core/internal/manager/ExternalManager.lua")
assert(managerChunk, managerLoadError)
managerChunk(nil, Addon)

local managerCalls = 0
local lateLoadedManager = Addon.Internal.ExternalManager
local initializeManager = lateLoadedManager.Initialize
lateLoadedManager.Initialize = function(self)
    assertEqual(self, lateLoadedManager, "runtime passes the loaded manager module")
    managerCalls = managerCalls + 1
    return initializeManager(self)
end

-- Runtime loads before ExternalManager in the TOC. Assign the manager after
-- Runtime to reproduce that load order, then dispatch normal startup.
rawset(_G, "RPEngineManagerDB", nil)
Addon.Internal.DispatchEvent("ADDON_LOADED", Addon.Name)
assertEqual(managerCalls, 1, "late-loaded external manager initializes once at addon startup")
local root = rawget(_G, "RPEngineManagerDB")
assert(type(root) == "table", "startup creates the absent Manager root")
assertEqual(root.protocolVersion, 1, "startup initializes protocol version 1")
assert(type(root.pendingOperations) == "table", "startup initializes the pending queue")
assert(type(root.installedPackages) == "table", "startup initializes the manifest map")
assert(type(root.operationResults) == "table", "startup initializes the result map")

Addon.Internal.DispatchEvent("ADDON_LOADED", "OtherAddon")
assertEqual(managerCalls, 1, "other addon load events do not initialize the manager")

rawset(_G, "RPEngineManagerDB", savedManagerRoot)
print("RuntimeExternalManagerStartupTest passed")
