local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local Event = {}
Event.__index = Event
function Event:New(data)
    local value = setmetatable({}, self)
    for key, nestedValue in pairs(data or {}) do value[key] = nestedValue end
    return value
end
function Event:Merge(data)
    for key, value in pairs(data or {}) do self[key] = value end
    return self
end
function Event:ToTable()
    return { endLootGrants = self.endLootGrants }
end
function Event:ToStartArguments()
    return {}
end
function Event.FromStartArguments()
    return Event:New({})
end

local Addon = {
    Internal = {
        Database = { Classes = { Event = Event } },
    },
    Utils = { Common = {} },
}

local chunk, loadError = loadfile("core/internal/ItemTier.lua")
assert(chunk, loadError)
chunk(nil, Addon)
chunk, loadError = loadfile("core/classes/EventEndLoot.lua")
assert(chunk, loadError)
chunk(nil, Addon)

local grants = {
    { sourceType = "direct", distribution = "personal", reward = { type = "item", ref = "dataset:sword", amount = 1, itemTier = "mythic" } },
    { sourceType = "loot_table", distribution = "group", lootRef = "dataset:table", itemTier = "heroic" },
    { sourceType = "direct", distribution = "personal", reward = { type = "currency", ref = "gold", amount = 5 } },
}

local serialized = Event.SerializeEndLootGrantsForNetwork(grants)
local decoded = Event.DeserializeEndLootGrantsFromNetwork(serialized)
assertEqual(decoded[1].reward.itemTier, "mythic", "direct item tier survives end-loot serialization")
assertEqual(decoded[2].itemTier, "heroic", "loot-table grant tier survives end-loot serialization")
assertEqual(decoded[3].reward.itemTier, nil, "currency remains tierless")

local legacyRecord = table.concat({ "direct", "personal", "item", "dataset:sword", "1", "" }, string.char(15))
local legacyDecoded = Event.DeserializeEndLootGrantsFromNetwork(legacyRecord)
assertEqual(legacyDecoded[1].reward.itemTier, "normal", "legacy six-field end-loot records default to Normal")

local legacyTable = Event.DeserializeEndLootGrantsFromNetwork(
    Event.SerializeEndLootGrantsForNetwork({
        { sourceType = "loot_table", distribution = "group", lootRef = "dataset:table" },
    })
)
assertEqual(legacyTable[1].itemTier, "normal", "legacy loot-table grants default to Normal")

print("EventEndLootTierSerializationTest passed")
