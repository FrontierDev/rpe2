local _, Addon = ...

local ResourceSync = Addon.Internal
    and Addon.Internal.Comms
    and Addon.Internal.Comms.ResourceSync
    or nil
local Profile = Addon.Internal and Addon.Internal.Profile or nil

if type(ResourceSync) ~= "table"
    or type(Profile) ~= "table"
    or type(ResourceSync.BuildProfileResourceSnapshot) ~= "function"
    or ResourceSync.PrimaryResourceOrderingInstalled == true
then
    return
end

ResourceSync.PrimaryResourceOrderingInstalled = true
local nativeBuildProfileResourceSnapshot = ResourceSync.BuildProfileResourceSnapshot

local function normalizeRef(value)
    return type(value) == "string" and value ~= "" and value or nil
end

function ResourceSync.BuildProfileResourceSnapshot(...)
    local resources = nativeBuildProfileResourceSnapshot(...)
    if type(resources) ~= "table" or #resources <= 1 then
        return resources
    end

    local healthRef = normalizeRef(type(Profile.GetHealthResourceRef) == "function" and Profile.GetHealthResourceRef() or nil)
    local primaryRef = normalizeRef(type(Profile.GetPrimaryResourceRef) == "function" and Profile.GetPrimaryResourceRef() or nil)
    local specialRef = normalizeRef(type(Profile.GetSpecialResourceRef) == "function" and Profile.GetSpecialResourceRef() or nil)
    local rankByRef = {}
    if healthRef then
        rankByRef[healthRef] = 1
    end
    if primaryRef then
        rankByRef[primaryRef] = 2
    end
    if specialRef then
        rankByRef[specialRef] = 3
    end

    local ordered = {}
    for index = 1, #resources do
        ordered[index] = {
            index = index,
            rank = rankByRef[resources[index] and resources[index].resourceRef] or 4,
            entry = resources[index],
        }
    end
    table.sort(ordered, function(left, right)
        if left.rank ~= right.rank then
            return left.rank < right.rank
        end
        return left.index < right.index
    end)
    for index = 1, #ordered do
        resources[index] = ordered[index].entry
    end
    return resources
end
