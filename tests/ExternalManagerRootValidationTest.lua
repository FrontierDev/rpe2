local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}
    for key, nested in pairs(value) do
        copy[key] = deepCopy(nested)
    end
    return copy
end

local function assertDeepEqual(actual, expected, message)
    if type(actual) ~= type(expected) then
        error(message .. ": values have different types", 2)
    end
    if type(actual) ~= "table" then
        assertEqual(actual, expected, message)
        return
    end

    for key, value in pairs(expected) do
        assertDeepEqual(actual[key], value, message .. "." .. tostring(key))
    end
    for key in pairs(actual) do
        if expected[key] == nil then
            error(message .. ": unexpected field " .. tostring(key), 2)
        end
    end
end

local savedManagerRoot = rawget(_G, "RPEngineManagerDB")
local savedDatasetRoot = rawget(_G, "RPEngineDatasetDB")
local savedGetServerTime = rawget(_G, "GetServerTime")

local diagnostics = {}
local databaseState = { datasets = {}, importCalls = 0 }
local Database = {}
function Database.GetDatasetImportPayloadIdentity(payload)
    local prefix = "dataset:"
    if type(payload) ~= "string" or payload:sub(1, #prefix) ~= prefix then
        return nil, "Invalid test dataset payload."
    end
    return payload:sub(#prefix + 1)
end
function Database.ImportDataset(payload)
    databaseState.importCalls = databaseState.importCalls + 1
    local datasetId = Database.GetDatasetImportPayloadIdentity(payload)
    if not datasetId then
        return nil, "Invalid test dataset payload."
    end
    local dataset = { id = datasetId }
    databaseState.datasets[datasetId] = dataset
    return dataset
end
function Database.GetDatasetByID(datasetId)
    return databaseState.datasets[datasetId]
end
function Database.DeleteDataset(datasetId)
    databaseState.datasets[datasetId] = nil
    return true
end

local Addon = {
    Debug = {
        Error = function(format, message)
            diagnostics[#diagnostics + 1] = format:format(message)
        end,
    },
    Internal = { Database = Database },
}
local chunk, loadError = loadfile("core/internal/manager/ExternalManager.lua")
assert(chunk, loadError)
chunk(nil, Addon)

local manager = Addon.Internal.ExternalManager
rawset(_G, "RPEngineDatasetDB", { datasets = { untouched = { id = "untouched" } } })
rawset(_G, "GetServerTime", function()
    return 1789940000
end)

local function makeInstall(requestId)
    return {
        requestId = requestId,
        operation = "install_dataset",
        catalogueId = "phase2-test",
        datasetId = "dataset-a",
        revision = 1,
        hash = string.rep("a", 64),
        payload = "dataset:dataset-a",
    }
end

local function validRoot(operation)
    return {
        protocolVersion = 1,
        pendingOperations = operation and { operation } or {},
        installedPackages = {},
        operationResults = {},
    }
end

local function assertStartupDoesNotMutate(root, message)
    diagnostics = {}
    rawset(_G, "RPEngineManagerDB", root)
    local snapshot = deepCopy(root)
    local importsBefore = databaseState.importCalls
    assertEqual(manager.Initialize(), 0, message .. " processed count")
    assertDeepEqual(rawget(_G, "RPEngineManagerDB"), snapshot, message .. " root")
    assertEqual(databaseState.importCalls, importsBefore, message .. " import count")
    assert(
        #diagnostics > 0 and diagnostics[#diagnostics]:find("Manager protocol", 1, true),
        message .. " emits a root validation diagnostic"
    )
end

rawset(_G, "RPEngineManagerDB", nil)
assertEqual(manager.Initialize(), 0, "absent root processed count")
assertDeepEqual(rawget(_G, "RPEngineManagerDB"), {
    protocolVersion = 1,
    pendingOperations = {},
    installedPackages = {},
    operationResults = {},
}, "absent root initializes to exact v1 schema")

local unsupportedRoot = {
    protocolVersion = 2,
    pendingOperations = { makeInstall("unsupported-request") },
    installedPackages = false,
    operationResults = "untouched",
    futureField = { retained = true },
}
assertStartupDoesNotMutate(unsupportedRoot, "unsupported version")
assert(#diagnostics > 0 and diagnostics[#diagnostics]:find("Unsupported Manager protocol version", 1, true), "unsupported version diagnostic")

local malformedQueueRoot = validRoot(makeInstall("malformed-queue"))
malformedQueueRoot.pendingOperations = false
assertStartupDoesNotMutate(malformedQueueRoot, "malformed pending queue")

local malformedManifestRoot = validRoot(makeInstall("malformed-manifest"))
malformedManifestRoot.installedPackages = false
assertStartupDoesNotMutate(malformedManifestRoot, "malformed manifest map")

local malformedResultsRoot = validRoot(makeInstall("malformed-results"))
malformedResultsRoot.operationResults = false
assertStartupDoesNotMutate(malformedResultsRoot, "malformed result map")

local malformedResultEntryRoot = validRoot(makeInstall("malformed-result-entry"))
malformedResultEntryRoot.operationResults = {
    previous = { requestId = "previous", status = "succeeded" },
}
assertStartupDoesNotMutate(malformedResultEntryRoot, "malformed result entry")

local missingFieldRoot = validRoot(makeInstall("missing-field"))
missingFieldRoot.installedPackages = nil
assertStartupDoesNotMutate(missingFieldRoot, "missing root field")

local unknownFieldRoot = validRoot(makeInstall("unknown-field"))
unknownFieldRoot.newerManagerState = { mustRemain = true }
assertStartupDoesNotMutate(unknownFieldRoot, "unknown root field")

local importsBeforeNonTableRoot = databaseState.importCalls
assertStartupDoesNotMutate("not-a-table", "non-table root")
assertEqual(databaseState.importCalls, importsBeforeNonTableRoot, "non-table root does not mutate datasets")

local supportedRoot = validRoot(makeInstall("valid-v1-request"))
rawset(_G, "RPEngineManagerDB", supportedRoot)
assertEqual(manager.Initialize(), 1, "valid v1 root processes one operation")
assertEqual(#supportedRoot.pendingOperations, 0, "valid v1 queue is consumed")
assertEqual(supportedRoot.operationResults["valid-v1-request"].status, "succeeded", "valid v1 operation succeeds")
assertEqual(databaseState.importCalls, importsBeforeNonTableRoot + 1, "valid v1 operation imports once")

rawset(_G, "RPEngineManagerDB", savedManagerRoot)
rawset(_G, "RPEngineDatasetDB", savedDatasetRoot)
rawset(_G, "GetServerTime", savedGetServerTime)
print("ExternalManagerRootValidationTest passed")
