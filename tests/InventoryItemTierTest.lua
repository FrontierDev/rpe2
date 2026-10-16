local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local Addon = {
    Client = {},
    Internal = {
        Database = {},
        Profile = {},
        Runtime = {},
    },
}

Addon.Internal.Database.ResolveCurrentCharacterIdentity = function()
    return "player", true, "Player"
end
Addon.Internal.Database.GetDatasetByID = function(datasetId)
    return {
        id = datasetId,
        items = {
            { id = "sword", name = "Test Sword", canStack = true, maxStackSize = 20 },
        },
    }
end
Addon.Internal.Database.ListActivatedDatasetIds = function()
    return { "dataset" }
end
Addon.Internal.Database.IsDatasetActivated = function()
    return true
end

local chunk, loadError = loadfile("core/internal/ItemTier.lua")
assert(chunk, loadError)
chunk(nil, Addon)
chunk, loadError = loadfile("client/character/inventory/Inventory.lua")
assert(chunk, loadError)
chunk(nil, Addon)

_G.RPEngineInventoryDB = nil
local Inventory = Addon.Client.Inventory
Inventory.SetItems({
    { dataset = "dataset", id = "sword", quantity = 4 },
}, "test-set")

local normal, normalIndex = Inventory.AddItem({ dataset = "dataset", id = "sword", quantity = 2, itemTier = "normal" })
assert(normal and normalIndex, "Normal item can be added")
local heroic = Inventory.AddItem({ dataset = "dataset", id = "sword", quantity = 2, itemTier = "heroic" })
local mythic = Inventory.AddItem({ dataset = "dataset", id = "sword", quantity = 2, itemTier = "mythic" })
assert(heroic and mythic, "Heroic and Mythic items can be added")

local variants = Inventory.GetItemVariants("dataset", "sword")
assertEqual(#variants, 3, "item tiers remain separate inventory variants")
assertEqual(Inventory.GetVariantQuantity({ dataset = "dataset", id = "sword", itemTier = "normal" }), 6, "Normal quantity includes only Normal copies")
assertEqual(Inventory.GetVariantQuantity({ dataset = "dataset", id = "sword", itemTier = "heroic" }), 2, "Heroic quantity is isolated")
assertEqual(Inventory.GetVariantQuantity({ dataset = "dataset", id = "sword", itemTier = "mythic" }), 2, "Mythic quantity is isolated")

assert(Inventory.RemoveVariantQuantity({ dataset = "dataset", id = "sword", itemTier = "heroic" }, 1), "Heroic variant can be removed")
assertEqual(Inventory.GetVariantQuantity({ dataset = "dataset", id = "sword", itemTier = "heroic" }), 1, "Removing Heroic does not remove Normal")
assertEqual(Inventory.GetVariantQuantity({ dataset = "dataset", id = "sword", itemTier = "normal" }), 6, "Normal quantity remains unchanged")

print("InventoryItemTierTest passed")
