local _, Addon = ...

local DefaultDatasets = Addon.Data and Addon.Data.DefaultDatasets or nil
local definitions = DefaultDatasets and DefaultDatasets.Definitions or nil
if type(definitions) ~= "table" then
    return
end

local BLACKSMITHING_DATASET_ID = "61fdf3df"
local ENGINEERING_DATASET_ID = "af503002"

local blacksmithingDefinition = definitions[BLACKSMITHING_DATASET_ID]
local engineeringDefinition = definitions[ENGINEERING_DATASET_ID]
local blacksmithing = type(blacksmithingDefinition) == "table" and blacksmithingDefinition.dataset or nil
local engineering = type(engineeringDefinition) == "table" and engineeringDefinition.dataset or nil

local function trim(value)
    return tostring(value or ""):match("^%s*(.-)%s*$") or ""
end

local function renameBlacksmithingMaterials(dataset)
    if type(dataset) ~= "table" then
        return
    end

    local renames = {
        ["Gold Ingot"] = "Gold Bar",
        ["Truesilver Ingot"] = "Truesilver Bar",
        ["Dark Iron Ingot"] = "Dark Iron Bar",
    }

    for _, item in ipairs(type(dataset.items) == "table" and dataset.items or {}) do
        local replacement = renames[trim(item and item.name)]
        if replacement then
            item.name = replacement
        end
    end
end

local function buildBlacksmithingItemRefsByName(dataset)
    local refs = {}
    for _, item in ipairs(type(dataset) == "table" and type(dataset.items) == "table" and dataset.items or {}) do
        local name = trim(item and item.name)
        local id = trim(item and item.id)
        if name ~= "" and id ~= "" then
            refs[name] = ("%s:%s"):format(BLACKSMITHING_DATASET_ID, id)
        end
    end
    return refs
end

local function replaceReferences(value, replacements, visited)
    if type(value) ~= "table" then
        return
    end

    visited = visited or {}
    if visited[value] then
        return
    end
    visited[value] = true

    for key, nested in pairs(value) do
        if type(nested) == "string" and replacements[nested] then
            value[key] = replacements[nested]
        elseif type(nested) == "table" then
            replaceReferences(nested, replacements, visited)
        end
    end
end

renameBlacksmithingMaterials(blacksmithing)

if type(blacksmithingDefinition) == "table" then
    -- Bump the packaged version so installations containing the old duplicate
    -- material injections are replaced by the canonical Blacksmithing dataset.
    blacksmithingDefinition.version = math.max(4, math.floor(tonumber(blacksmithingDefinition.version) or 1))
end

if type(engineering) == "table" then
    engineering.name = "Engineering"

    local refsByName = buildBlacksmithingItemRefsByName(blacksmithing)
    local replacements = {
        ["61fdf3df:h4i9b6wc"] = refsByName["Steel Bar"],
        ["61fdf3df:i5m1b7xd"] = refsByName["Mithril Bar"],
        ["61fdf3df:j6g2b8ye"] = refsByName["Gold Bar"],
        ["61fdf3df:k7t3b9zf"] = refsByName["Truesilver Bar"],
    }

    for legacyRef, canonicalRef in pairs(replacements) do
        if trim(canonicalRef) == "" then
            error(("Unable to resolve canonical Blacksmithing material for legacy Engineering reference '%s'."):format(legacyRef), 2)
        end
    end

    replaceReferences(engineering, replacements)
end

if type(engineeringDefinition) == "table" then
    -- Engineering previously omitted its dataset name and referenced material
    -- records injected by blacksmithing_materials.lua.
    engineeringDefinition.version = math.max(13, math.floor(tonumber(engineeringDefinition.version) or 1))
end
