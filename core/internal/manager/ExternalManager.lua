local _, Addon = ...

Addon.Internal = Addon.Internal or {}

local ExternalManager = Addon.Internal.ExternalManager or {}
Addon.Internal.ExternalManager = ExternalManager
local Database = Addon.Internal.Database or {}

ExternalManager.ProtocolVersion = 1
ExternalManager.ErrorCodes = {
    InvalidOperation = "invalid_operation",
    UnsupportedOperation = "unsupported_operation",
    UnsupportedProtocolVersion = "unsupported_protocol_version",
    InvalidPackageMetadata = "invalid_package_metadata",
    InvalidPayload = "invalid_payload",
    DatasetIdMismatch = "dataset_id_mismatch",
    DatasetImportFailed = "dataset_import_failed",
    PackageNotInstalled = "package_not_installed",
    InvalidManifestEntry = "invalid_manifest_entry",
    DatasetNotFound = "dataset_not_found",
    DatasetDeleteFailed = "dataset_delete_failed",
    ProcessingFailed = "operation_processing_failed",
}

local TERMINAL_STATUSES = {
    succeeded = true,
    failed = true,
}

local function isValidRequestId(requestId)
    return type(requestId) == "string" and requestId:match("%S") ~= nil
end

local function ensureRoot()
    local globalEnvironment = _G or getfenv(0)
    local root = rawget(globalEnvironment, "RPEngineManagerDB")

    if type(root) ~= "table" then
        root = {}
    end

    if root.protocolVersion == nil then
        root.protocolVersion = ExternalManager.ProtocolVersion
    end

    if type(root.pendingOperations) ~= "table" then
        root.pendingOperations = {}
    end
    if type(root.installedPackages) ~= "table" then
        root.installedPackages = {}
    end
    if type(root.operationResults) ~= "table" then
        root.operationResults = {}
    end

    rawset(globalEnvironment, "RPEngineManagerDB", root)
    return root
end

ExternalManager.EnsureRoot = ensureRoot

function ExternalManager.HasCompletedRequest(requestId)
    if not isValidRequestId(requestId) then
        return false
    end

    local root = ensureRoot()
    local result = root.operationResults[requestId]
    return type(result) == "table" and TERMINAL_STATUSES[result.status] == true
end

function ExternalManager.WriteOperationResult(requestId, status, errorCode, detail)
    if not isValidRequestId(requestId) or not TERMINAL_STATUSES[status] then
        return false
    end

    local root = ensureRoot()
    local existingResult = root.operationResults[requestId]
    if type(existingResult) == "table" and TERMINAL_STATUSES[existingResult.status] == true then
        return existingResult
    end

    local result = {
        requestId = requestId,
        status = status,
    }

    if status == "failed" then
        result.error = {
            code = type(errorCode) == "string" and errorCode or "operation_failed",
            detail = type(detail) == "string" and detail or "The operation failed.",
        }
    end

    root.operationResults[requestId] = result
    return result
end

local function compareKeys(left, right)
    local leftType = type(left)
    local rightType = type(right)

    if leftType ~= rightType then
        return leftType < rightType
    end

    if leftType == "number" then
        return left < right
    end

    return tostring(left) < tostring(right)
end

local function keyOrderValue(key)
    return type(key) .. ":" .. tostring(key)
end

local function resultKeyForMalformedOperation(key)
    return "__rpe_invalid_operation__:" .. keyOrderValue(key)
end

local function collectPendingOperations(pendingOperations)
    local entries = {}
    for key, operation in pairs(pendingOperations) do
        local requestId = type(operation) == "table" and operation.requestId or nil
        local resultKey = isValidRequestId(requestId) and requestId or resultKeyForMalformedOperation(key)

        entries[#entries + 1] = {
            key = key,
            operation = operation,
            requestId = requestId,
            resultKey = resultKey,
            sortKey = key,
        }
    end

    table.sort(entries, function(left, right)
        return compareKeys(left.sortKey, right.sortKey)
    end)

    return entries
end

local function failOperation(requestId, errorCode, detail)
    ExternalManager.WriteOperationResult(requestId, "failed", errorCode, detail)
end

local function isNonEmptyString(value)
    return type(value) == "string" and value:match("%S") ~= nil
end

local function isValidRevision(value)
    if isNonEmptyString(value) then
        return true
    end

    return type(value) == "number"
        and value == value
        and value ~= math.huge
        and value ~= -math.huge
        and value >= 0
        and value == math.floor(value)
end

local function getInstallationTimestamp()
    if type(GetServerTime) == "function" then
        local timestamp = tonumber(GetServerTime())
        if timestamp and timestamp == timestamp and timestamp ~= math.huge and timestamp ~= -math.huge then
            return timestamp
        end
    end

    if type(time) == "function" then
        local timestamp = tonumber(time())
        if timestamp and timestamp == timestamp and timestamp ~= math.huge and timestamp ~= -math.huge then
            return timestamp
        end
    end

    return nil
end

local function processInstallDataset(root, operation, requestId)
    local catalogueId = operation.catalogueId
    local datasetId = operation.datasetId
    local revision = operation.revision
    local packageHash = operation.hash
    local payload = operation.payload

    if not isNonEmptyString(catalogueId)
        or not isNonEmptyString(datasetId)
        or not isValidRevision(revision)
        or not isNonEmptyString(packageHash)
    then
        failOperation(
            requestId,
            ExternalManager.ErrorCodes.InvalidPackageMetadata,
            "install_dataset requires non-empty catalogueId, datasetId, and hash values plus a valid revision."
        )
        return
    end

    if type(payload) ~= "string" then
        failOperation(
            requestId,
            ExternalManager.ErrorCodes.InvalidPayload,
            "install_dataset requires a string RPE_DATASET_V1 payload."
        )
        return
    end

    if type(Database.GetDatasetImportPayloadIdentity) ~= "function" then
        failOperation(
            requestId,
            ExternalManager.ErrorCodes.ProcessingFailed,
            "Dataset payload identity validation is unavailable."
        )
        return
    end

    local payloadDatasetId, identityError = Database.GetDatasetImportPayloadIdentity(payload)
    if not payloadDatasetId then
        failOperation(
            requestId,
            ExternalManager.ErrorCodes.InvalidPayload,
            identityError or "Payload is not a valid RPE_DATASET_V1 dataset export."
        )
        return
    end

    if payloadDatasetId ~= datasetId then
        failOperation(
            requestId,
            ExternalManager.ErrorCodes.DatasetIdMismatch,
            "Declared datasetId does not match the dataset ID in the payload."
        )
        return
    end

    if type(Database.ImportDataset) ~= "function" then
        failOperation(
            requestId,
            ExternalManager.ErrorCodes.DatasetImportFailed,
            "The canonical dataset importer is unavailable."
        )
        return
    end

    local importOk, importedDataset, importError = pcall(Database.ImportDataset, payload)
    if not importOk or type(importedDataset) ~= "table" then
        local detail = importOk and importError or importedDataset
        failOperation(
            requestId,
            ExternalManager.ErrorCodes.DatasetImportFailed,
            tostring(detail or "Dataset import failed.")
        )
        return
    end

    local manifestEntry = {
        packageType = "dataset",
        catalogueId = catalogueId,
        datasetId = datasetId,
        revision = revision,
        hash = packageHash,
    }
    local installedAt = getInstallationTimestamp()
    if installedAt then
        manifestEntry.installedAt = installedAt
    end

    -- Write manifest metadata only after the canonical import has succeeded.
    -- It remains separate from the authored dataset and its exported payload.
    root.installedPackages[catalogueId] = manifestEntry
    ExternalManager.WriteOperationResult(requestId, "succeeded")
end

local function processRemoveDataset(root, operation, requestId)
    local catalogueId = operation.catalogueId
    local datasetId = operation.datasetId

    if not isNonEmptyString(catalogueId) or not isNonEmptyString(datasetId) then
        failOperation(
            requestId,
            ExternalManager.ErrorCodes.InvalidPackageMetadata,
            "remove_dataset requires non-empty catalogueId and datasetId values."
        )
        return
    end

    local manifestEntry = root.installedPackages[catalogueId]
    if manifestEntry == nil then
        failOperation(
            requestId,
            ExternalManager.ErrorCodes.PackageNotInstalled,
            "No installed package manifest entry exists for catalogueId " .. catalogueId .. "."
        )
        return
    end

    if type(manifestEntry) ~= "table"
        or manifestEntry.packageType ~= "dataset"
        or (manifestEntry.catalogueId ~= nil and manifestEntry.catalogueId ~= catalogueId)
        or not isNonEmptyString(manifestEntry.datasetId)
        or not isValidRevision(manifestEntry.revision)
        or not isNonEmptyString(manifestEntry.hash)
    then
        failOperation(
            requestId,
            ExternalManager.ErrorCodes.InvalidManifestEntry,
            "Installed package manifest entry is malformed or does not identify a dataset package."
        )
        return
    end

    if manifestEntry.datasetId ~= datasetId then
        failOperation(
            requestId,
            ExternalManager.ErrorCodes.DatasetIdMismatch,
            "Declared datasetId does not match the dataset ID recorded for this catalogue package."
        )
        return
    end

    if type(Database.GetDatasetByID) ~= "function" or type(Database.DeleteDataset) ~= "function" then
        failOperation(
            requestId,
            ExternalManager.ErrorCodes.DatasetDeleteFailed,
            "The canonical dataset deletion API is unavailable."
        )
        return
    end

    if not Database.GetDatasetByID(datasetId) then
        -- Keep the manifest so a missing local dataset is reported explicitly
        -- and can be reconciled by the Manager or the user.
        failOperation(
            requestId,
            ExternalManager.ErrorCodes.DatasetNotFound,
            "The installed package manifest identifies this dataset, but the dataset is already absent."
        )
        return
    end

    local deleteOk, deleted = pcall(Database.DeleteDataset, datasetId)
    if not deleteOk or deleted ~= true then
        local detail = deleteOk and "The canonical dataset deletion did not succeed." or tostring(deleted)
        failOperation(
            requestId,
            ExternalManager.ErrorCodes.DatasetDeleteFailed,
            detail
        )
        return
    end

    root.installedPackages[catalogueId] = nil
    ExternalManager.WriteOperationResult(requestId, "succeeded")
end

local function processOperation(root, entry)
    local operation = entry.operation
    local requestId = entry.requestId

    if not isValidRequestId(requestId) then
        failOperation(
            entry.resultKey,
            ExternalManager.ErrorCodes.InvalidOperation,
            "Pending operation must be a table with a non-empty string requestId."
        )
        return
    end

    if ExternalManager.HasCompletedRequest(requestId) then
        return
    end

    if root.protocolVersion ~= ExternalManager.ProtocolVersion then
        failOperation(
            requestId,
            ExternalManager.ErrorCodes.UnsupportedProtocolVersion,
            "RPEngine supports Manager protocol version 1; received " .. tostring(root.protocolVersion) .. "."
        )
        return
    end

    if type(operation) ~= "table" then
        failOperation(
            requestId,
            ExternalManager.ErrorCodes.InvalidOperation,
            "Pending operation must be a table."
        )
        return
    end

    if not isNonEmptyString(operation.type) then
        failOperation(
            requestId,
            ExternalManager.ErrorCodes.InvalidOperation,
            "Pending operation must declare a non-empty type."
        )
        return
    end

    if operation.type == "install_dataset" then
        processInstallDataset(root, operation, requestId)
        return
    end

    if operation.type == "remove_dataset" then
        processRemoveDataset(root, operation, requestId)
        return
    end

    failOperation(
        requestId,
        ExternalManager.ErrorCodes.UnsupportedOperation,
        "RPEngine does not support Manager operation type " .. tostring(operation.type) .. "."
    )
end

function ExternalManager.ProcessPendingOperations()
    local root = ensureRoot()
    local pendingOperations = root.pendingOperations
    local entries = collectPendingOperations(pendingOperations)
    local processed = 0

    for index = 1, #entries do
        local entry = entries[index]
        local ok, err = pcall(processOperation, root, entry)

        if not ok then
            failOperation(
                entry.resultKey,
                ExternalManager.ErrorCodes.ProcessingFailed,
                "RPEngine could not process the pending operation: " .. tostring(err)
            )
        end

        -- A terminal result is stored before the pending entry is removed. This
        -- makes completed request IDs durable across reloads and restarts.
        if ExternalManager.HasCompletedRequest(entry.requestId)
            or (not isValidRequestId(entry.requestId) and ExternalManager.HasCompletedRequest(entry.resultKey))
        then
            pendingOperations[entry.key] = nil
            processed = processed + 1
        end
    end

    return processed
end

function ExternalManager.Initialize()
    ensureRoot()
    return ExternalManager.ProcessPendingOperations()
end
