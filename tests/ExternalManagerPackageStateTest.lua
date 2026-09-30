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
local savedChatFrame = rawget(_G, "DEFAULT_CHAT_FRAME")
local chatMessages = {}
rawset(_G, "DEFAULT_CHAT_FRAME", {
    AddMessage = function(_, message, red, green, blue)
        chatMessages[#chatMessages + 1] = {
            message = message,
            red = red,
            green = green,
            blue = blue,
        }
    end,
})

local databaseState = {
    datasets = {},
    importCalls = 0,
    deleteCalls = 0,
    rejectNextImport = false,
    rejectNextDelete = false,
}

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
    if databaseState.rejectNextImport then
        databaseState.rejectNextImport = false
        return nil, "Test import rejection."
    end

    local datasetId = Database.GetDatasetImportPayloadIdentity(payload)
    if not datasetId then
        return nil, "Invalid test dataset payload."
    end

    local dataset = { id = datasetId, name = "Dataset " .. datasetId }
    databaseState.datasets[datasetId] = dataset
    return dataset
end

function Database.GetDatasetByID(datasetId)
    return databaseState.datasets[datasetId]
end

function Database.DeleteDataset(datasetId)
    databaseState.deleteCalls = databaseState.deleteCalls + 1
    if databaseState.rejectNextDelete then
        databaseState.rejectNextDelete = false
        return false
    end
    if not databaseState.datasets[datasetId] then
        return false
    end
    databaseState.datasets[datasetId] = nil
    return true
end

local Addon = { Internal = { Database = Database } }
local chunk, loadError = loadfile("core/internal/manager/ExternalManager.lua")
assert(chunk, loadError)
chunk(nil, Addon)

local manager = Addon.Internal.ExternalManager
local unchangedDatasetRoot = { datasets = { untouched = { id = "untouched" } } }
rawset(_G, "RPEngineDatasetDB", unchangedDatasetRoot)
local timestampCalls = 0
rawset(_G, "GetServerTime", function()
    timestampCalls = timestampCalls + 1
    return 1789940000 + timestampCalls - 1
end)

local function resetManagerRoot()
    rawset(_G, "RPEngineManagerDB", {
        protocolVersion = 1,
        pendingOperations = {},
        installedPackages = {},
        operationResults = {},
    })
    return rawget(_G, "RPEngineManagerDB")
end

local root = resetManagerRoot()
local requestNumber = 0
local function process(fields)
    requestNumber = requestNumber + 1
    fields.requestId = "package-state-" .. requestNumber
    root.pendingOperations[#root.pendingOperations + 1] = fields
    assertEqual(manager.ProcessPendingOperations(), 1, "one queued operation is consumed")
    return root.operationResults[fields.requestId]
end

local function install(catalogueId, datasetId, revision, hash)
    return process({
        operation = "install_dataset",
        catalogueId = catalogueId,
        datasetId = datasetId,
        revision = revision,
        hash = hash,
        payload = "dataset:" .. datasetId,
    })
end

local function remove(catalogueId, datasetId, revision, hash)
    return process({
        operation = "remove_dataset",
        catalogueId = catalogueId,
        datasetId = datasetId,
        revision = revision,
        hash = hash,
    })
end

local function assertFailure(result, errorCode, message)
    assertEqual(result.status, "failed", message .. " status")
    assertEqual(result.error.code, errorCode, message .. " error code")
end

local hashA = string.rep("a", 64)
local hashB = string.rep("b", 64)
local hashC = string.rep("c", 64)

local firstResult = install("phase2-test", "dataset-a", 1, hashA)
assertEqual(firstResult.status, "succeeded", "first install succeeds")
assertEqual(chatMessages[1].message, "|TInterface\\AddOns\\RPEngine2\\data\\textures\\ui\\rpe.png:14:14|t Dataset dataset-a was installed.", "first install announces the dataset")
assertEqual(chatMessages[1].red, 0, "first install announcement is green red channel")
assertEqual(chatMessages[1].green, 1, "first install announcement is green green channel")
assertEqual(chatMessages[1].blue, 0, "first install announcement is green blue channel")
local initialManifest = deepCopy(root.installedPackages["phase2-test"])
assertEqual(initialManifest.datasetId, "dataset-a", "new manifest identifies the dataset")
assertEqual(initialManifest.revision, 1, "new manifest stores the revision")
assertEqual(initialManifest.hash, hashA, "new manifest stores the hash")
assertEqual(initialManifest.catalogueId, nil, "manifest does not duplicate catalogueId")
assertEqual(initialManifest.installedAt, 1789940000, "new manifest stores installedAt")
assertEqual(databaseState.importCalls, 1, "first install imports once")
assertEqual(timestampCalls, 1, "first install obtains one timestamp")

local importsBeforeNoOp = databaseState.importCalls
local noOpResult = install("phase2-test", "dataset-a", 1, hashA)
assertEqual(noOpResult.status, "succeeded", "same revision and hash succeeds")
assertEqual(databaseState.importCalls, importsBeforeNoOp, "same revision and hash does not re-import")
assertDeepEqual(root.installedPackages["phase2-test"], initialManifest, "no-op leaves manifest unchanged")
assertEqual(timestampCalls, 1, "no-op does not obtain a new installedAt")

local importsBeforeConflicts = databaseState.importCalls
assertFailure(install("phase2-test", "dataset-a", 1, hashB), "revision_hash_conflict", "same revision with a different hash")
assertEqual(databaseState.importCalls, importsBeforeConflicts, "hash conflict does not import")
assertDeepEqual(root.installedPackages["phase2-test"], initialManifest, "hash conflict leaves manifest unchanged")

assertFailure(install("phase2-test", "dataset-b", 2, hashB), "catalogue_dataset_id_conflict", "catalogue ID reused for another dataset")
assertEqual(databaseState.importCalls, importsBeforeConflicts, "catalogue identity conflict does not import")
assertDeepEqual(root.installedPackages["phase2-test"], initialManifest, "catalogue identity conflict leaves manifest unchanged")

local updatedResult = install("phase2-test", "dataset-a", 2, hashB)
assertEqual(updatedResult.status, "succeeded", "higher revision succeeds")
assertEqual(chatMessages[2].message, "|TInterface\\AddOns\\RPEngine2\\data\\textures\\ui\\rpe.png:14:14|t Dataset dataset-a was updated to version 2.", "update announces the dataset version")
assertEqual(databaseState.importCalls, importsBeforeConflicts + 1, "higher revision imports once")
local updatedManifest = deepCopy(root.installedPackages["phase2-test"])
assertEqual(updatedManifest.revision, 2, "higher revision advances the manifest")
assertEqual(updatedManifest.hash, hashB, "higher revision updates the manifest hash")
assertEqual(updatedManifest.installedAt, 1789940001, "higher revision records its timestamp")

local importsBeforeStale = databaseState.importCalls
assertFailure(install("phase2-test", "dataset-a", 1, hashA), "stale_revision", "lower revision")
assertEqual(databaseState.importCalls, importsBeforeStale, "stale revision does not import")
assertDeepEqual(root.installedPackages["phase2-test"], updatedManifest, "stale revision leaves manifest unchanged")
assertFailure(install("phase2-test", "dataset-a", 2, hashC), "revision_hash_conflict", "updated revision with a different hash")
assertEqual(databaseState.importCalls, importsBeforeStale, "updated hash conflict does not import")
assertDeepEqual(root.installedPackages["phase2-test"], updatedManifest, "updated hash conflict leaves manifest unchanged")

databaseState.rejectNextImport = true
local rejectedInstall = install("phase2-rejected", "dataset-b", 1, hashC)
assertFailure(rejectedInstall, "import_rejected", "canonical importer rejection")
assertEqual(root.installedPackages["phase2-rejected"], nil, "rejected install creates no manifest")
assertFailure(remove("phase2-rejected", "dataset-b", 1, hashC), "package_not_installed", "removal without a manifest entry")

databaseState.rejectNextImport = true
assertFailure(install("phase2-test", "dataset-a", 3, hashC), "import_rejected", "rejected higher revision")
assertDeepEqual(root.installedPackages["phase2-test"], updatedManifest, "rejected update leaves the manifest unchanged")

local deleteCallsBeforeMismatch = databaseState.deleteCalls
assertFailure(remove("phase2-test", "dataset-b", 2, hashB), "installed_package_mismatch", "removal with wrong dataset ID")
assertDeepEqual(root.installedPackages["phase2-test"], updatedManifest, "wrong dataset removal leaves manifest unchanged")
assertFailure(remove("phase2-test", "dataset-a", 1, hashB), "installed_package_mismatch", "removal with wrong revision")
assertDeepEqual(root.installedPackages["phase2-test"], updatedManifest, "wrong revision removal leaves manifest unchanged")
assertFailure(remove("phase2-test", "dataset-a", 2, hashC), "installed_package_mismatch", "removal with wrong hash")
assertDeepEqual(root.installedPackages["phase2-test"], updatedManifest, "wrong hash removal leaves manifest unchanged")
assertEqual(databaseState.deleteCalls, deleteCallsBeforeMismatch, "identity mismatches do not delete")

databaseState.datasets["dataset-a"] = nil
local deleteCallsBeforeMissing = databaseState.deleteCalls
assertFailure(remove("phase2-test", "dataset-a", 2, hashB), "remove_rejected", "removal when local dataset is absent")
assertDeepEqual(root.installedPackages["phase2-test"], updatedManifest, "missing local dataset leaves manifest unchanged")
assertEqual(databaseState.deleteCalls, deleteCallsBeforeMissing, "missing local dataset does not call delete")
databaseState.datasets["dataset-a"] = { id = "dataset-a" }

databaseState.rejectNextDelete = true
assertFailure(remove("phase2-test", "dataset-a", 2, hashB), "remove_rejected", "canonical deletion rejection")
assertDeepEqual(root.installedPackages["phase2-test"], updatedManifest, "failed deletion leaves manifest unchanged")

local deleteCallsBeforeSuccess = databaseState.deleteCalls
local removedResult = remove("phase2-test", "dataset-a", 2, hashB)
assertEqual(removedResult.status, "succeeded", "exact removal succeeds")
assertEqual(databaseState.deleteCalls, deleteCallsBeforeSuccess + 1, "exact removal uses canonical DeleteDataset once")
assertEqual(databaseState.datasets["dataset-a"], nil, "exact removal deletes the local dataset")
assertEqual(root.installedPackages["phase2-test"], nil, "exact removal clears the manifest")

assertDeepEqual(rawget(_G, "RPEngineDatasetDB"), unchangedDatasetRoot, "manager does not write dataset SavedVariables directly")

rawset(_G, "RPEngineManagerDB", savedManagerRoot)
rawset(_G, "RPEngineDatasetDB", savedDatasetRoot)
rawset(_G, "GetServerTime", savedGetServerTime)
rawset(_G, "DEFAULT_CHAT_FRAME", savedChatFrame)
print("ExternalManagerPackageStateTest passed")
