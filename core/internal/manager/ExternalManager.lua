local _, Addon = ...

Addon.Internal = Addon.Internal or {}

local ExternalManager = Addon.Internal.ExternalManager or {}
Addon.Internal.ExternalManager = ExternalManager
local Database = Addon.Internal.Database or {}

ExternalManager.ProtocolVersion = 1
ExternalManager.ErrorCodes = {
    InvalidField = "invalid_field",
    UnsupportedOperation = "unsupported_operation",
    InvalidPayloadFormat = "invalid_payload_format",
    DatasetIdMismatch = "dataset_id_mismatch",
    CatalogueDatasetIdConflict = "catalogue_dataset_id_conflict",
    StaleRevision = "stale_revision",
    RevisionHashConflict = "revision_hash_conflict",
    PackageNotInstalled = "package_not_installed",
    InstalledPackageMismatch = "installed_package_mismatch",
    ImportRejected = "import_rejected",
    RemoveRejected = "remove_rejected",
    InternalError = "internal_error",
}

local ALLOWED_ERROR_CODES = {}
for _, errorCode in pairs(ExternalManager.ErrorCodes) do
    ALLOWED_ERROR_CODES[errorCode] = true
end

local TERMINAL_STATUSES = {
    succeeded = true,
    failed = true,
}

local function isValidRequestId(value)
    if type(value) ~= "string" or #value < 1 or #value > 128 then
        return false
    end

    for index = 1, #value do
        local byte = string.byte(value, index)
        local isAlphaNumeric = (byte >= 48 and byte <= 57)
            or (byte >= 65 and byte <= 90)
            or (byte >= 97 and byte <= 122)
        if index == 1 then
            if not isAlphaNumeric then
                return false
            end
        elseif not isAlphaNumeric
            and byte ~= 46
            and byte ~= 95
            and byte ~= 58
            and byte ~= 45
        then
            return false
        end
    end

    return true
end

local function isValidCatalogueId(value)
    if type(value) ~= "string" or #value < 1 or #value > 128 then
        return false
    end

    for index = 1, #value do
        local byte = string.byte(value, index)
        local isLowerAlphaNumeric = (byte >= 48 and byte <= 57) or (byte >= 97 and byte <= 122)
        if index == 1 then
            if not isLowerAlphaNumeric then
                return false
            end
        elseif not isLowerAlphaNumeric and byte ~= 46 and byte ~= 95 and byte ~= 45 then
            return false
        end
    end

    return true
end

local function isWhitespaceCodePoint(codePoint)
    return (codePoint >= 0x0009 and codePoint <= 0x000D)
        or codePoint == 0x0020
        or codePoint == 0x00A0
        or codePoint == 0x1680
        or (codePoint >= 0x2000 and codePoint <= 0x200A)
        or codePoint == 0x2028
        or codePoint == 0x2029
        or codePoint == 0x202F
        or codePoint == 0x205F
        or codePoint == 0x3000
        or codePoint == 0xFEFF
end

local function decodeUtf8CodePoint(value, index)
    local first = string.byte(value, index)
    if not first then
        return nil
    end

    if first <= 0x7F then
        return first, index + 1
    end

    local second = string.byte(value, index + 1)
    if first >= 0xC2 and first <= 0xDF then
        if not second or second < 0x80 or second > 0xBF then
            return nil
        end
        return (first - 0xC0) * 0x40 + (second - 0x80), index + 2
    end

    local third = string.byte(value, index + 2)
    if first >= 0xE0 and first <= 0xEF then
        local validSecond = second and second >= 0x80 and second <= 0xBF
        if first == 0xE0 then
            validSecond = second and second >= 0xA0 and second <= 0xBF
        elseif first == 0xED then
            validSecond = second and second >= 0x80 and second <= 0x9F
        end
        if not validSecond or not third or third < 0x80 or third > 0xBF then
            return nil
        end
        local codePoint = (first - 0xE0) * 0x1000
            + (second - 0x80) * 0x40
            + (third - 0x80)
        return codePoint, index + 3
    end

    local fourth = string.byte(value, index + 3)
    if first >= 0xF0 and first <= 0xF4 then
        local validSecond = second and second >= 0x80 and second <= 0xBF
        if first == 0xF0 then
            validSecond = second and second >= 0x90 and second <= 0xBF
        elseif first == 0xF4 then
            validSecond = second and second >= 0x80 and second <= 0x8F
        end
        if not validSecond
            or not third or third < 0x80 or third > 0xBF
            or not fourth or fourth < 0x80 or fourth > 0xBF
        then
            return nil
        end
        local codePoint = (first - 0xF0) * 0x40000
            + (second - 0x80) * 0x1000
            + (third - 0x80) * 0x40
            + (fourth - 0x80)
        return codePoint, index + 4
    end

    return nil
end

local function isValidDatasetId(value)
    if type(value) ~= "string" or #value < 1 or #value > 128 then
        return false
    end

    local index = 1
    local firstCodePoint, lastCodePoint
    while index <= #value do
        local codePoint, nextIndex = decodeUtf8CodePoint(value, index)
        if not codePoint
            or codePoint <= 0x001F
            or (codePoint >= 0x007F and codePoint <= 0x009F)
        then
            return false
        end

        firstCodePoint = firstCodePoint or codePoint
        lastCodePoint = codePoint
        index = nextIndex
    end

    return not isWhitespaceCodePoint(firstCodePoint) and not isWhitespaceCodePoint(lastCodePoint)
end

local function isValidRevision(value)
    return type(value) == "number"
        and value == value
        and value ~= math.huge
        and value ~= -math.huge
        and value >= 1
        and value <= 2147483647
        and value == math.floor(value)
end

local function isValidHash(value)
    if type(value) ~= "string" or #value ~= 64 then
        return false
    end

    for index = 1, #value do
        local byte = string.byte(value, index)
        if not ((byte >= 48 and byte <= 57) or (byte >= 97 and byte <= 102)) then
            return false
        end
    end

    return true
end

local function getGlobalEnvironment()
    return _G or getfenv(0)
end

local function initializeAbsentRoot()
    local globalEnvironment = getGlobalEnvironment()
    local root = rawget(globalEnvironment, "RPEngineManagerDB")

    if root ~= nil then
        return root, false
    end

    root = {
        protocolVersion = 1,
        pendingOperations = {},
        installedPackages = {},
        operationResults = {},
    }
    rawset(globalEnvironment, "RPEngineManagerDB", root)
    return root, true
end

local validateExistingRoot
local reportDiagnostic

local function reportRootValidationFailure(reason, detail)
    if reason == "unsupported_version" then
        reportDiagnostic(("Unsupported Manager protocol version %s; protocol-v1 state was left unchanged."):format(
            tostring(detail)
        ))
        return
    end

    reportDiagnostic("Malformed Manager protocol-v1 root; state was left unchanged. " .. tostring(detail))
end

function ExternalManager.HasCompletedRequest(requestId)
    if not isValidRequestId(requestId) then
        return false
    end

    local root = rawget(getGlobalEnvironment(), "RPEngineManagerDB")
    if type(root) ~= "table" or not validateExistingRoot then
        return false
    end
    local validRoot = validateExistingRoot(root)
    if not validRoot then
        return false
    end

    local result = root.operationResults[requestId]
    return type(result) == "table" and TERMINAL_STATUSES[result.status] == true
end

local function getOperationName(operation)
    if type(operation) == "table"
        and (operation.operation == "install_dataset" or operation.operation == "remove_dataset")
    then
        return operation.operation
    end

    return "unknown"
end

local function getOperationIdentity(operation)
    local identity = {}
    if type(operation) ~= "table" then
        return identity
    end

    if isValidCatalogueId(operation.catalogueId) then
        identity.catalogueId = operation.catalogueId
    end
    if isValidDatasetId(operation.datasetId) then
        identity.datasetId = operation.datasetId
    end
    if isValidRevision(operation.revision) then
        identity.revision = operation.revision
    end
    if isValidHash(operation.hash) then
        identity.hash = operation.hash
    end

    return identity
end

local function copyValidOperationIdentity(identity)
    local copied = {}
    if type(identity) ~= "table" then
        return copied
    end

    if isValidCatalogueId(identity.catalogueId) then
        copied.catalogueId = identity.catalogueId
    end
    if isValidDatasetId(identity.datasetId) then
        copied.datasetId = identity.datasetId
    end
    if isValidRevision(identity.revision) then
        copied.revision = identity.revision
    end
    if isValidHash(identity.hash) then
        copied.hash = identity.hash
    end

    return copied
end

function ExternalManager.WriteOperationResult(requestId, operationName, status, identity, errorCode, detail)
    if not isValidRequestId(requestId) then
        return false
    end

    local root = rawget(getGlobalEnvironment(), "RPEngineManagerDB")
    if type(root) ~= "table" or not validateExistingRoot then
        return false
    end
    local validRoot, validationReason, validationDetail = validateExistingRoot(root)
    if not validRoot then
        reportRootValidationFailure(validationReason, validationDetail)
        return false
    end

    local existingResult = root.operationResults[requestId]
    if type(existingResult) == "table" and TERMINAL_STATUSES[existingResult.status] == true then
        return existingResult
    end

    if (operationName ~= "install_dataset"
            and operationName ~= "remove_dataset"
            and operationName ~= "unknown")
        or not TERMINAL_STATUSES[status]
    then
        return false
    end

    local resultIdentity = copyValidOperationIdentity(identity)
    if status == "succeeded"
        and (operationName == "unknown"
            or not resultIdentity.catalogueId
            or not resultIdentity.datasetId
            or not resultIdentity.revision
            or not resultIdentity.hash)
    then
        return false
    end

    local result = {
        requestId = requestId,
        operation = operationName,
        status = status,
    }

    for fieldName, value in pairs(resultIdentity) do
        result[fieldName] = value
    end

    if status == "failed" then
        result.error = {
            code = ALLOWED_ERROR_CODES[errorCode] and errorCode or ExternalManager.ErrorCodes.InternalError,
            detail = type(detail) == "string" and detail or "The operation failed.",
        }
    end

    root.operationResults[requestId] = result
    return result
end

local function failOperation(requestId, operationName, identity, errorCode, detail)
    ExternalManager.WriteOperationResult(requestId, operationName, "failed", identity, errorCode, detail)
end

reportDiagnostic = function(message)
    local debug = Addon.Debug
    local logger = debug and (debug.Error or debug.Internal) or nil
    if type(logger) == "function" then
        pcall(logger, "External Manager: %s", tostring(message))
    end
end

local function getDenseQueueLength(queue)
    local count = 0
    local maximumIndex = 0

    for key in pairs(queue) do
        if type(key) ~= "number"
            or key ~= key
            or key == math.huge
            or key == -math.huge
            or key < 1
            or key ~= math.floor(key)
        then
            return nil
        end

        count = count + 1
        if key > maximumIndex then
            maximumIndex = key
        end
    end

    if count ~= maximumIndex then
        return nil
    end

    return count
end

local function validateClosedSchema(operation, expectedFields)
    local allowedFields = {}
    for index = 1, #expectedFields do
        allowedFields[expectedFields[index]] = true
    end

    for key in pairs(operation) do
        if type(key) ~= "string" or not allowedFields[key] then
            return false, "Operation contains a field that is not defined for protocol v1."
        end
    end

    for index = 1, #expectedFields do
        local fieldName = expectedFields[index]
        if rawget(operation, fieldName) == nil then
            return false, "Operation is missing required field " .. fieldName .. "."
        end
    end

    return true
end

local function getInstallationTimestamp()
    if type(GetServerTime) == "function" then
        local callOk, timestamp = pcall(GetServerTime)
        if callOk
            and type(timestamp) == "number"
            and timestamp == timestamp
            and timestamp ~= math.huge
            and timestamp ~= -math.huge
            and timestamp == math.floor(timestamp)
        then
            return timestamp
        end
    end

    if type(time) == "function" then
        local callOk, timestamp = pcall(time)
        if callOk
            and type(timestamp) == "number"
            and timestamp == timestamp
            and timestamp ~= math.huge
            and timestamp ~= -math.huge
            and timestamp == math.floor(timestamp)
        then
            return timestamp
        end
    end

    return nil
end

local function escapeChatMarkup(value)
    return tostring(value or ""):gsub("|", "||")
end

local function getRPEIconMarkup()
    local inline = Addon.UI and Addon.UI.Inline or nil
    if type(inline) == "table" and type(inline.Get) == "function" then
        local callOk, iconMarkup = pcall(inline.Get, inline, "RPE", 14, 14)
        if callOk and type(iconMarkup) == "string" and iconMarkup ~= "" then
            return iconMarkup
        end
    end

    return "|TInterface\\AddOns\\RPEngine2\\data\\textures\\ui\\rpe.png:14:14|t"
end

local function announceDatasetImport(dataset, revision, wasUpdate)
    if not (DEFAULT_CHAT_FRAME and type(DEFAULT_CHAT_FRAME.AddMessage) == "function") then
        return false
    end

    local datasetName = type(Database.GetDatasetDisplayName) == "function"
        and Database.GetDatasetDisplayName(dataset)
        or (type(dataset) == "table" and dataset.name)
        or "Unnamed Dataset"
    local message = wasUpdate
        and ("%s was updated to version %d."):format(escapeChatMarkup(datasetName), revision)
        or ("%s was installed."):format(escapeChatMarkup(datasetName))

    DEFAULT_CHAT_FRAME:AddMessage(("%s %s"):format(getRPEIconMarkup(), message), 0, 1, 0)
    return true
end

local INSTALL_FIELDS = {
    "requestId",
    "operation",
    "catalogueId",
    "datasetId",
    "revision",
    "hash",
    "payload",
}

local REMOVE_FIELDS = {
    "requestId",
    "operation",
    "catalogueId",
    "datasetId",
    "revision",
    "hash",
}

local MANIFEST_FIELDS = {
    packageType = true,
    datasetId = true,
    revision = true,
    hash = true,
    installedAt = true,
}

local function isValidUnixTimestamp(value)
    return type(value) == "number"
        and value == value
        and value ~= math.huge
        and value ~= -math.huge
        and value == math.floor(value)
end

local function validateManifestEntry(entry)
    if type(entry) ~= "table" then
        return false
    end

    for key in pairs(entry) do
        if type(key) ~= "string" or not MANIFEST_FIELDS[key] then
            return false
        end
    end

    return rawget(entry, "packageType") == "dataset"
        and isValidDatasetId(rawget(entry, "datasetId"))
        and isValidRevision(rawget(entry, "revision"))
        and isValidHash(rawget(entry, "hash"))
        and isValidUnixTimestamp(rawget(entry, "installedAt"))
end

local ROOT_FIELDS = {
    protocolVersion = true,
    pendingOperations = true,
    installedPackages = true,
    operationResults = true,
}

local ROOT_FIELD_NAMES = {
    "protocolVersion",
    "pendingOperations",
    "installedPackages",
    "operationResults",
}

local SUCCESS_RESULT_FIELDS = {
    requestId = true,
    operation = true,
    status = true,
    catalogueId = true,
    datasetId = true,
    revision = true,
    hash = true,
}

local FAILURE_RESULT_FIELDS = {
    requestId = true,
    operation = true,
    status = true,
    catalogueId = true,
    datasetId = true,
    revision = true,
    hash = true,
    error = true,
}

local OPERATION_IDENTITY_FIELDS = {
    "catalogueId",
    "datasetId",
    "revision",
    "hash",
}

local function hasOnlyFields(record, allowedFields)
    for key in pairs(record) do
        if type(key) ~= "string" or not allowedFields[key] then
            return false
        end
    end
    return true
end

local function validateOperationResultRecord(requestId, result)
    if type(result) ~= "table"
        or rawget(result, "requestId") ~= requestId
        or not isValidRequestId(requestId)
    then
        return false
    end

    local status = rawget(result, "status")
    local operationName = rawget(result, "operation")
    if status == "succeeded" then
        return operationName ~= "unknown"
            and (operationName == "install_dataset" or operationName == "remove_dataset")
            and hasOnlyFields(result, SUCCESS_RESULT_FIELDS)
            and isValidCatalogueId(rawget(result, "catalogueId"))
            and isValidDatasetId(rawget(result, "datasetId"))
            and isValidRevision(rawget(result, "revision"))
            and isValidHash(rawget(result, "hash"))
    end

    if status ~= "failed"
        or (operationName ~= "install_dataset"
            and operationName ~= "remove_dataset"
            and operationName ~= "unknown")
        or not hasOnlyFields(result, FAILURE_RESULT_FIELDS)
    then
        return false
    end

    for index = 1, #OPERATION_IDENTITY_FIELDS do
        local fieldName = OPERATION_IDENTITY_FIELDS[index]
        local value = rawget(result, fieldName)
        if value ~= nil then
            if fieldName == "catalogueId" and not isValidCatalogueId(value) then
                return false
            elseif fieldName == "datasetId" and not isValidDatasetId(value) then
                return false
            elseif fieldName == "revision" and not isValidRevision(value) then
                return false
            elseif fieldName == "hash" and not isValidHash(value) then
                return false
            end
        end
    end

    local errorRecord = rawget(result, "error")
    return type(errorRecord) == "table"
        and hasOnlyFields(errorRecord, { code = true, detail = true })
        and ALLOWED_ERROR_CODES[rawget(errorRecord, "code")] == true
        and type(rawget(errorRecord, "detail")) == "string"
end

validateExistingRoot = function(root)
    if type(root) ~= "table" then
        return false, "malformed_root", "RPEngineManagerDB must be a table."
    end

    local protocolVersion = rawget(root, "protocolVersion")
    if type(protocolVersion) == "number" and protocolVersion ~= ExternalManager.ProtocolVersion then
        return false, "unsupported_version", protocolVersion
    end
    if protocolVersion ~= ExternalManager.ProtocolVersion then
        return false, "malformed_root", "protocolVersion is missing or has the wrong type."
    end

    if not hasOnlyFields(root, ROOT_FIELDS) then
        return false, "malformed_root", "RPEngineManagerDB contains an unknown field."
    end
    for index = 1, #ROOT_FIELD_NAMES do
        local fieldName = ROOT_FIELD_NAMES[index]
        if rawget(root, fieldName) == nil then
            return false, "malformed_root", "RPEngineManagerDB is missing " .. fieldName .. "."
        end
    end

    local pendingOperations = rawget(root, "pendingOperations")
    if type(pendingOperations) ~= "table" then
        return false, "malformed_root", "pendingOperations must be a table."
    end
    local queueLength = getDenseQueueLength(pendingOperations)
    if queueLength == nil then
        return false, "malformed_root", "pendingOperations must be a dense 1-based FIFO array."
    end
    for index = 1, queueLength do
        local operation = rawget(pendingOperations, index)
        if type(operation) ~= "table" or not isValidRequestId(rawget(operation, "requestId")) then
            return false, "malformed_root", "pendingOperations contains an entry without a valid requestId."
        end
    end

    local installedPackages = rawget(root, "installedPackages")
    if type(installedPackages) ~= "table" then
        return false, "malformed_root", "installedPackages must be a table."
    end
    for catalogueId, entry in pairs(installedPackages) do
        if not isValidCatalogueId(catalogueId) or not validateManifestEntry(entry) then
            return false, "malformed_root", "installedPackages contains a malformed package entry."
        end
    end

    local operationResults = rawget(root, "operationResults")
    if type(operationResults) ~= "table" then
        return false, "malformed_root", "operationResults must be a table."
    end
    for requestId, result in pairs(operationResults) do
        if not isValidRequestId(requestId) or not validateOperationResultRecord(requestId, result) then
            return false, "malformed_root", "operationResults contains a malformed result entry."
        end
    end

    return true
end

ExternalManager.ValidateRoot = validateExistingRoot

local function processInstallDataset(root, operation, requestId, operationName, identity)
    local function fail(errorCode, detail)
        failOperation(requestId, operationName, identity, errorCode, detail)
    end

    local validSchema, schemaError = validateClosedSchema(operation, INSTALL_FIELDS)
    if not validSchema then
        fail(ExternalManager.ErrorCodes.InvalidField, schemaError)
        return
    end

    local catalogueId = operation.catalogueId
    local datasetId = operation.datasetId
    local revision = operation.revision
    local packageHash = operation.hash
    local payload = operation.payload

    if not isValidCatalogueId(catalogueId)
        or not isValidDatasetId(datasetId)
        or not isValidRevision(revision)
        or not isValidHash(packageHash)
    then
        fail(
            ExternalManager.ErrorCodes.InvalidField,
            "install_dataset contains a catalogueId, datasetId, revision, or hash outside the protocol-v1 constraints."
        )
        return
    end

    if type(payload) ~= "string" then
        fail(
            ExternalManager.ErrorCodes.InvalidPayloadFormat,
            "install_dataset payload must be a string using the RPE_DATASET_V1 format."
        )
        return
    end

    if type(Database.GetDatasetImportPayloadIdentity) ~= "function" then
        fail(
            ExternalManager.ErrorCodes.InternalError,
            "Dataset payload identity validation is unavailable."
        )
        return
    end

    local identityCallOk, payloadDatasetId, identityError = pcall(
        Database.GetDatasetImportPayloadIdentity,
        payload
    )
    if not identityCallOk then
        fail(
            ExternalManager.ErrorCodes.InternalError,
            tostring(payloadDatasetId)
        )
        return
    end
    if not payloadDatasetId then
        fail(
            ExternalManager.ErrorCodes.InvalidPayloadFormat,
            identityError or "Payload is not a valid RPE_DATASET_V1 dataset export."
        )
        return
    end

    if payloadDatasetId ~= datasetId then
        fail(
            ExternalManager.ErrorCodes.DatasetIdMismatch,
            "Declared datasetId does not match the dataset ID in the payload."
        )
        return
    end

    local existingEntry = root.installedPackages[catalogueId]
    local wasUpdate = existingEntry ~= nil
    if existingEntry ~= nil then
        if not validateManifestEntry(existingEntry) then
            fail(
                ExternalManager.ErrorCodes.InstalledPackageMismatch,
                "Existing package manifest entry is malformed."
            )
            return
        end

        if existingEntry.datasetId ~= datasetId then
            fail(
                ExternalManager.ErrorCodes.CatalogueDatasetIdConflict,
                "catalogueId is already associated with a different datasetId."
            )
            return
        end

        if revision < existingEntry.revision then
            fail(
                ExternalManager.ErrorCodes.StaleRevision,
                "Requested package revision is older than the installed revision."
            )
            return
        end

        if revision == existingEntry.revision and packageHash ~= existingEntry.hash then
            fail(
                ExternalManager.ErrorCodes.RevisionHashConflict,
                "The same package revision is already installed with a different hash."
            )
            return
        end

        if revision == existingEntry.revision then
            local result = ExternalManager.WriteOperationResult(requestId, operationName, "succeeded", identity)
            if not result then
                error("Could not persist a complete install_dataset result.")
            end
            return
        end
    end

    if type(Database.ImportDataset) ~= "function" then
        fail(
            ExternalManager.ErrorCodes.InternalError,
            "The canonical dataset importer is unavailable."
        )
        return
    end

    local installedAt = getInstallationTimestamp()
    if not installedAt then
        fail(
            ExternalManager.ErrorCodes.InternalError,
            "A valid Unix installation timestamp is unavailable."
        )
        return
    end

    local importOk, importedDataset, importError = pcall(Database.ImportDataset, payload)
    if not importOk then
        fail(ExternalManager.ErrorCodes.InternalError, tostring(importedDataset))
        return
    end
    if type(importedDataset) ~= "table" then
        fail(
            ExternalManager.ErrorCodes.ImportRejected,
            tostring(importError or "The canonical dataset importer rejected the payload.")
        )
        return
    end

    local manifestEntry = {
        packageType = "dataset",
        datasetId = datasetId,
        revision = revision,
        hash = packageHash,
        installedAt = installedAt,
    }

    root.installedPackages[catalogueId] = manifestEntry
    local result = ExternalManager.WriteOperationResult(requestId, operationName, "succeeded", identity)
    if not result then
        error("Could not persist a complete install_dataset result.")
    end

    announceDatasetImport(importedDataset, revision, wasUpdate)
end

local function processRemoveDataset(root, operation, requestId, operationName, identity)
    local function fail(errorCode, detail)
        failOperation(requestId, operationName, identity, errorCode, detail)
    end

    local validSchema, schemaError = validateClosedSchema(operation, REMOVE_FIELDS)
    if not validSchema then
        fail(ExternalManager.ErrorCodes.InvalidField, schemaError)
        return
    end

    local catalogueId = operation.catalogueId
    local datasetId = operation.datasetId
    local revision = operation.revision
    local packageHash = operation.hash

    if not isValidCatalogueId(catalogueId)
        or not isValidDatasetId(datasetId)
        or not isValidRevision(revision)
        or not isValidHash(packageHash)
    then
        fail(
            ExternalManager.ErrorCodes.InvalidField,
            "remove_dataset contains a catalogueId, datasetId, revision, or hash outside the protocol-v1 constraints."
        )
        return
    end

    local manifestEntry = root.installedPackages[catalogueId]
    if manifestEntry == nil then
        fail(
            ExternalManager.ErrorCodes.PackageNotInstalled,
            "No installed package manifest entry exists for catalogueId " .. catalogueId .. "."
        )
        return
    end

    if not validateManifestEntry(manifestEntry)
        or manifestEntry.datasetId ~= datasetId
        or manifestEntry.revision ~= revision
        or manifestEntry.hash ~= packageHash
    then
        fail(
            ExternalManager.ErrorCodes.InstalledPackageMismatch,
            "Request package identity does not match the installed manifest entry."
        )
        return
    end

    if type(Database.GetDatasetByID) ~= "function" then
        fail(
            ExternalManager.ErrorCodes.InternalError,
            "The canonical dataset lookup API is unavailable."
        )
        return
    end

    local lookupOk, dataset = pcall(Database.GetDatasetByID, datasetId)
    if not lookupOk then
        fail(ExternalManager.ErrorCodes.InternalError, tostring(dataset))
        return
    end
    if not dataset then
        fail(
            ExternalManager.ErrorCodes.RemoveRejected,
            "The installed dataset is already absent, so canonical removal cannot succeed."
        )
        return
    end

    if type(Database.DeleteDataset) ~= "function" then
        fail(
            ExternalManager.ErrorCodes.InternalError,
            "The canonical dataset deletion API is unavailable."
        )
        return
    end

    local deleteOk, deleted = pcall(Database.DeleteDataset, datasetId)
    if not deleteOk then
        fail(
            ExternalManager.ErrorCodes.RemoveRejected,
            "The canonical dataset deletion failed: " .. tostring(deleted)
        )
        return
    end
    if deleted ~= true then
        fail(
            ExternalManager.ErrorCodes.RemoveRejected,
            "The canonical dataset deletion did not succeed."
        )
        return
    end

    root.installedPackages[catalogueId] = nil
    local result = ExternalManager.WriteOperationResult(requestId, operationName, "succeeded", identity)
    if not result then
        error("Could not persist a complete remove_dataset result.")
    end
end

local function processOperation(root, operation, requestId, operationName, identity)
    local function fail(errorCode, detail)
        failOperation(requestId, operationName, identity, errorCode, detail)
    end

    if root.protocolVersion ~= ExternalManager.ProtocolVersion then
        fail(
            ExternalManager.ErrorCodes.InvalidField,
            "RPEngine supports Manager protocol version 1; received " .. tostring(root.protocolVersion) .. "."
        )
        return
    end

    if type(operation.operation) ~= "string" or operation.operation == "" then
        fail(
            ExternalManager.ErrorCodes.InvalidField,
            "Operation must contain a non-empty protocol-v1 operation field."
        )
        return
    end

    if operationName == "install_dataset" then
        processInstallDataset(root, operation, requestId, operationName, identity)
        return
    end

    if operationName == "remove_dataset" then
        processRemoveDataset(root, operation, requestId, operationName, identity)
        return
    end

    fail(ExternalManager.ErrorCodes.UnsupportedOperation,
        "RPEngine does not support Manager operation " .. tostring(operation.operation) .. ".")
end

local function processValidRoot(root)
    local queue = root.pendingOperations
    local queueLength = getDenseQueueLength(queue)
    if queueLength == nil then
        reportDiagnostic("Malformed pendingOperations queue; processing stopped without consuming operations.")
        return 0
    end

    local consumed = 0
    while consumed < queueLength do
        local operation = queue[1]
        if type(operation) ~= "table" then
            reportDiagnostic(("pendingOperations entry %d is not a table; queue processing stopped."):format(consumed + 1))
            break
        end

        local requestId = operation.requestId
        if not isValidRequestId(requestId) then
            reportDiagnostic(("pendingOperations entry %d has a missing or invalid requestId; queue processing stopped."):format(consumed + 1))
            break
        end

        local existingResult = root.operationResults[requestId]
        if not (type(existingResult) == "table" and TERMINAL_STATUSES[existingResult.status] == true) then
            local operationName = getOperationName(operation)
            local identity = getOperationIdentity(operation)
            local ok, err = pcall(processOperation, root, operation, requestId, operationName, identity)
            if not ok then
                failOperation(
                    requestId,
                    operationName,
                    identity,
                    ExternalManager.ErrorCodes.InternalError,
                    tostring(err)
                )
            end
        end

        local terminalResult = root.operationResults[requestId]
        if not (type(terminalResult) == "table" and TERMINAL_STATUSES[terminalResult.status] == true) then
            reportDiagnostic(("pendingOperations entry %d did not produce a terminal result; queue processing stopped."):format(consumed + 1))
            break
        end

        table.remove(queue, 1)
        consumed = consumed + 1
    end

    return consumed
end

function ExternalManager.ProcessPendingOperations()
    local root = rawget(getGlobalEnvironment(), "RPEngineManagerDB")
    if root == nil then
        reportDiagnostic("RPEngineManagerDB is absent; call Initialize before processing operations.")
        return 0
    end

    local validRoot, validationReason, validationDetail = validateExistingRoot(root)
    if not validRoot then
        reportRootValidationFailure(validationReason, validationDetail)
        return 0
    end

    return processValidRoot(root)
end

function ExternalManager.Initialize()
    local root = rawget(getGlobalEnvironment(), "RPEngineManagerDB")
    if root == nil then
        root = initializeAbsentRoot()
    end

    local validRoot, validationReason, validationDetail = validateExistingRoot(root)
    if not validRoot then
        reportRootValidationFailure(validationReason, validationDetail)
        return 0
    end

    return processValidRoot(root)
end
