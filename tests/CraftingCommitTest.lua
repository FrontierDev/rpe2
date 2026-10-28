local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local function assertTrue(value, message)
    if value ~= true then
        error(message, 2)
    end
end

local TestSupport = dofile("tests/support/RuntimeStubs.lua")
local scheduled = {}
local scheduledIndex = 0
local profileKey = "crafting-commit-test"
local rejectOutput = false
local inventoryItems = {}

local function countItem(itemRef)
    local datasetId, itemId = itemRef:match("^([^:]+):(.+)$")
    local total = 0
    for index = 1, #inventoryItems do
        local item = inventoryItems[index]
        if item.dataset == datasetId and item.id == itemId then
            total = total + (tonumber(item.quantity) or 0)
        end
    end
    return total
end

local Inventory = {
    GetItems = function()
        return inventoryItems
    end,
    RegisterChangeListener = function()
        return 1
    end,
    RemoveItem = function(slotIndex, quantity)
        local item = inventoryItems[slotIndex]
        if not item then
            return nil, "missing-item"
        end
        local removedQuantity = math.min(item.quantity, quantity)
        local removed = {
            dataset = item.dataset,
            id = item.id,
            itemTier = item.itemTier,
            quantity = removedQuantity,
        }
        item.quantity = item.quantity - removedQuantity
        if item.quantity <= 0 then
            table.remove(inventoryItems, slotIndex)
        end
        return removed
    end,
    AddItem = function(itemRecord)
        if itemRecord.id == "output" and rejectOutput then
            return nil, "inventory-full"
        end
        inventoryItems[#inventoryItems + 1] = {
            dataset = itemRecord.dataset,
            id = itemRecord.id,
            itemTier = itemRecord.itemTier,
            quantity = itemRecord.quantity,
        }
        return inventoryItems[#inventoryItems], #inventoryItems
    end,
}

local Addon = TestSupport.CreateAddon({
    Client = {
        Inventory = Inventory,
    },
    Internal = {
        Database = {
            GetActiveProfile = function()
                return { characterKey = profileKey }
            end,
        },
        Profile = {},
        Registry = {},
        Tasks = {
            Enqueue = function(_, callback)
                scheduled[#scheduled + 1] = callback
                return callback
            end,
        },
    },
    Utils = {
        Common = {},
    },
})

TestSupport.LoadAddonFile("client/client_Crafting.lua", Addon)
local Crafting = Addon.Client.Crafting

function Crafting:BuildRecipeDetails(recipeRef)
    return {
        recipeRef = recipeRef,
        isKnown = true,
        isSkillMet = true,
        skillName = "Crafting",
        requiredSkillLevel = 1,
        output = {
            itemRef = "items:output",
            item = {},
            name = "Output",
            minQuantity = 1,
            maxQuantity = 1,
        },
        tools = {},
        materials = {
            {
                itemRef = "items:material",
                itemTier = "normal",
                name = "Material",
                quantity = 1,
                owned = countItem("items:material"),
                hasEnough = countItem("items:material") > 0,
            },
        },
        canCraft = countItem("items:material") > 0,
    }
end

local function flushNextTask()
    scheduledIndex = scheduledIndex + 1
    local callback = scheduled[scheduledIndex]
    assertTrue(type(callback) == "function", "crafting operation was scheduled")
    callback()
end

inventoryItems = {
    { dataset = "items", id = "material", itemTier = "normal", quantity = 1 },
}
assertTrue(Crafting:QueueRecipe("recipes:one", 1), "successful craft queues")
flushNextTask()
assertEqual(countItem("items:material"), 0, "successful craft consumes materials once")
assertEqual(countItem("items:output"), 1, "successful craft grants output once")
local successfulState = Crafting:GetState()
assertEqual(successfulState.status, "complete", "successful craft reports complete")
assertEqual(successfulState.lastError, "", "successful craft has no failure status")
assertEqual(successfulState.lastOutcome.completedCount, 1, "successful craft records committed count")

inventoryItems = {
    { dataset = "items", id = "material", itemTier = "normal", quantity = 1 },
}
rejectOutput = true
assertTrue(Crafting:QueueRecipe("recipes:one", 1), "rejected output craft queues")
flushNextTask()
local rejectedState = Crafting:GetState()
assertEqual(countItem("items:material"), 1, "rejected output restores consumed materials")
assertEqual(countItem("items:output"), 0, "rejected output is not reported as crafted")
assertEqual(rejectedState.status, "blocked", "rejected output blocks the queue")
assertTrue(string.find(rejectedState.lastError, "Failed to grant", 1, true) ~= nil, "rejected output reports the grant failure")
assertEqual(rejectedState.lastOutcome, nil, "rejected output records no completed outcome")

rejectOutput = false
assertTrue(Crafting:QueueRecipe("recipes:one", 1), "retry after rejected output queues")
flushNextTask()
assertEqual(countItem("items:output"), 1, "retry after rejection grants exactly one output")

inventoryItems = {
    { dataset = "items", id = "material", itemTier = "normal", quantity = 1 },
}
Addon.Client.SkillProgression = {
    TryGain = function()
        error("forced skill progression failure")
    end,
}
assertTrue(Crafting:QueueRecipe("recipes:one", 1), "craft with ancillary failure queues")
flushNextTask()
local warningState = Crafting:GetState()
assertEqual(countItem("items:output"), 1, "ancillary failure does not duplicate output")
assertEqual(warningState.status, "complete", "ancillary failure preserves craft completion")
assertEqual(warningState.lastError, "", "ancillary failure does not mark craft failed")
assertTrue(string.find(warningState.lastWarning, "skill progression", 1, true) ~= nil,
    "ancillary failure is exposed as a separate warning")

local listenerId = Crafting:RegisterListener(function()
    error("forced inventory listener failure")
end)
inventoryItems = {
    { dataset = "items", id = "material", itemTier = "normal", quantity = 1 },
}
Addon.Client.SkillProgression = nil
assertTrue(Crafting:QueueRecipe("recipes:one", 1), "craft with listener failure queues")
flushNextTask()
local listenerState = Crafting:GetState()
assertEqual(listenerState.status, "complete", "listener failure preserves craft completion")
assertEqual(listenerState.lastError, "", "listener failure does not mark craft failed")
assertTrue(string.find(listenerState.lastWarning, "crafting listener", 1, true) ~= nil,
    "listener failure is exposed as a separate warning")
Crafting:UnregisterListener(listenerId)

Addon.Client.UI = {
    Profile = {
        Window = {
            Get = function()
                return {
                    RefreshVisible = function()
                        error("forced profile refresh failure")
                    end,
                }
            end,
        },
    },
}
inventoryItems = {
    { dataset = "items", id = "material", itemTier = "normal", quantity = 1 },
}
assertTrue(Crafting:QueueRecipe("recipes:one", 1), "craft with profile refresh failure queues")
flushNextTask()
local refreshState = Crafting:GetState()
assertEqual(refreshState.status, "complete", "profile refresh failure preserves craft completion")
assertEqual(refreshState.lastError, "", "profile refresh failure does not mark craft failed")
assertTrue(string.find(refreshState.lastWarning, "UI refresh", 1, true) ~= nil,
    "profile refresh failure is exposed as a separate warning")

print("CraftingCommitTest passed")
