local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local Addon = {
    Internal = {
        Comms = { Operations = {} },
    },
    Client = {},
    Server = {},
}

local chunk, loadError = loadfile("core/internal/ItemTier.lua")
assert(chunk, loadError)
chunk(nil, Addon)

chunk, loadError = loadfile("core/internal/comms/LootDelivery.lua")
assert(chunk, loadError)
chunk(nil, Addon)

local Protocol = Addon.Internal.Comms.LootProtocol
local serialized = Protocol.SerializeRewards({
    { type = "item", ref = "dataset:sword", amount = 1, itemTier = "heroic" },
    { type = "currency", ref = "gold", amount = 2 },
})
local decoded, decodeError = Protocol.DeserializeRewards(serialized)
assert(decoded, decodeError)
assertEqual(decoded[1].itemTier, "heroic", "tier-bearing delivery messages retain Heroic")
assertEqual(decoded[2].itemTier, nil, "currency deliveries remain tierless")

local legacyInMemory = Protocol.SerializeRewards({
    { type = "item", ref = "dataset:sword", amount = 1 },
})
local legacyInMemoryDecoded = Protocol.DeserializeRewards(legacyInMemory)
assertEqual(legacyInMemoryDecoded[1].itemTier, "normal", "missing serializer tier defaults to Normal")

local legacy = table.concat({ "item", "dataset:sword", "1" }, Protocol.FieldSeparator)
local legacyDecoded, legacyError = Protocol.DeserializeRewards(legacy)
assert(legacyDecoded, legacyError)
assertEqual(legacyDecoded[1].itemTier, "normal", "legacy three-field item messages default to Normal")

local invalid = table.concat({ "item", "dataset:sword", "1", "invalid" }, Protocol.FieldSeparator)
local _, invalidReason = Protocol.DeserializeRewards(invalid)
assertEqual(invalidReason, "invalid-item-tier", "invalid tier-bearing messages are rejected")

local currencyTier = table.concat({ "currency", "gold", "2", "heroic" }, Protocol.FieldSeparator)
local _, currencyTierReason = Protocol.DeserializeRewards(currencyTier)
assertEqual(currencyTierReason, "invalid-item-tier", "currency messages reject tier metadata")

print("LootDeliveryItemTierTest passed")
