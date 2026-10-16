local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local Addon = {
    Internal = {
        Comms = { Operations = {} },
        Registry = {},
        Profile = {},
    },
}

local chunk, loadError = loadfile("core/internal/ItemTier.lua")
assert(chunk, loadError)
chunk(nil, Addon)

chunk, loadError = loadfile("core/internal/Loot.lua")
assert(chunk, loadError)
chunk(nil, Addon)

Addon.Internal.Registry.ResolveItemReference = function(_, ref)
    local datasetId, itemId = tostring(ref):match("^([^:]+):(.+)$")
    return { id = datasetId }, { id = itemId }
end
Addon.Internal.Profile.NormalizeCurrencyKey = function(ref) return tostring(ref or "") end
Addon.Internal.Profile.ResolveCurrencyDefinition = function(ref) return { key = tostring(ref or "") } end

local Loot = Addon.Internal.Loot
local merged, mergeError = Loot.MergeConcreteRewards({
    { type = "item", ref = "dataset:sword", amount = 1 },
    { type = "item", ref = "dataset:sword", amount = 2, itemTier = "normal" },
    { type = "item", ref = "dataset:sword", amount = 3, itemTier = "heroic" },
    { type = "currency", ref = "gold", amount = 4 },
    { type = "currency", ref = "gold", amount = 5 },
})
assert(merged, mergeError)
assertEqual(#merged, 3, "Normal, Heroic and currency rewards remain distinct")
assertEqual(merged[1].amount, 3, "Normal rewards merge only with Normal rewards")
assertEqual(merged[2].itemTier, "heroic", "Heroic tier survives reward merging")
assertEqual(merged[2].amount, 3, "Heroic reward quantity is preserved")
assertEqual(merged[3].amount, 9, "currency rewards still merge")

local _, invalidReason = Loot.ResolveDirectReward({
    type = "item",
    ref = "dataset:sword",
    amount = 1,
    itemTier = "legendary",
})
assertEqual(invalidReason, "invalid-item-tier", "invalid direct reward tiers are rejected")

Addon.Internal.Registry.ResolveLootReference = function(_, ref)
    return {}, {
        id = ref,
        drawCount = 1,
        entries = {
            { id = "sword", type = "item", ref = "dataset:sword", minQuantity = 1, maxQuantity = 1, weight = 1 },
        },
    }
end

local assignments, assignmentError = Loot.BuildAssignments(
    { type = "table", lootRef = "dataset:table", itemTier = "mythic" },
    "personal",
    { "Player" },
    function() return 0 end
)
assert(assignments, assignmentError)
assertEqual(assignments[1].rewards[1].itemTier, "mythic", "loot-table grant tier applies to rolled items")

print("LootItemTierTest passed")
