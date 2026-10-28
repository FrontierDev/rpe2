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
local materialCounts = {
    ["recipes:one"] = 7,
    ["recipes:two"] = 2,
    ["recipes:nomaterial"] = 0,
}
local toolAvailable = true
local outputCounts = {}
local profileKey = "crafting-test"

local Addon = TestSupport.CreateAddon({
    Client = {
        Inventory = {
            GetItems = function()
                return {}
            end,
            RegisterChangeListener = function()
                return 1
            end,
        },
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
    local normalizedRef = tostring(recipeRef or "")
    local isNoMaterial = normalizedRef == "recipes:nomaterial"
    local available = math.max(0, tonumber(materialCounts[normalizedRef]) or 0)
    local tools = {
        {
            name = "Crafting Tool",
            hasEnough = toolAvailable,
        },
    }
    local canCraft = toolAvailable and (isNoMaterial or available > 0)
    return {
        recipeRef = normalizedRef,
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
        tools = tools,
        materials = isNoMaterial and {} or {
            {
                itemRef = "items:material",
                name = "Material",
                quantity = 1,
                owned = available,
                hasEnough = available > 0,
            },
        },
        canCraft = canCraft,
        isSkillMet = true,
    }
end

function Crafting:ConsumeRecipeInputsOnce(detail)
    local recipeRef = detail.recipeRef
    if detail.materials and #detail.materials > 0 then
        materialCounts[recipeRef] = math.max(0, materialCounts[recipeRef] - 1)
    end
    return true
end

function Crafting:GrantRecipeOutputOnce(detail)
    outputCounts[detail.recipeRef] = (outputCounts[detail.recipeRef] or 0) + 1
    return true
end

local function flushNextTask()
    scheduledIndex = scheduledIndex + 1
    local callback = scheduled[scheduledIndex]
    assertTrue(type(callback) == "function", "queue scheduled one task per craft")
    callback()
end

assertEqual(Crafting:GetMaxCraftableCount("recipes:one"), 7, "max count includes all consumable materials")
assertTrue(Crafting:QueueAll("recipes:one"), "QueueAll accepts a craftable recipe")
local queuedState = Crafting:GetState()
assertEqual(queuedState.status, "active", "QueueAll starts the active job immediately")
assertEqual(queuedState.active.totalCount, 7, "QueueAll queues the available count")
assertEqual(outputCounts["recipes:one"], nil, "QueueAll does not craft synchronously")
assertTrue(not Crafting:QueueRecipe("recipes:one", "not-a-number"), "invalid Craft X quantity is rejected")

for expectedCount = 1, 7 do
    flushNextTask()
    assertEqual(outputCounts["recipes:one"], expectedCount, "one queued craft completes per task")
    assertEqual(materialCounts["recipes:one"], 7 - expectedCount, "one material is consumed per task")
end
local completeState = Crafting:GetState()
assertEqual(completeState.status, "complete", "queue reaches complete state")
assertEqual(completeState.active, nil, "completed queue has no active job")
assertEqual(completeState.queuedCount, 0, "completed queue has no pending work")

toolAvailable = false
assertEqual(Crafting:GetMaxCraftableCount("recipes:two"), 0, "missing tool blocks Craft All")
assertEqual(Crafting:GetCraftingAvailability("recipes:two").reason, "Missing required tool: Crafting Tool.", "missing tool reports the canonical reason")
assertTrue(not Crafting:QueueRecipe("recipes:two", 1), "missing tool blocks Craft X")
toolAvailable = true

assertEqual(Crafting:GetMaxCraftableCount("recipes:nomaterial"), 1, "no-material recipe has a finite Craft All limit")
assertTrue(Crafting:QueueAll("recipes:nomaterial"), "no-material recipe can queue safely")
assertEqual(Crafting:GetState().active.totalCount, 1, "no-material Craft All queues one unit")
flushNextTask()
assertEqual(outputCounts["recipes:nomaterial"], 1, "no-material recipe crafts once")

materialCounts["recipes:two"] = 2
assertTrue(Crafting:QueueRecipe("recipes:two", 2), "second recipe can be queued")
local duplicateState = Crafting:GetState()
assertTrue(not Crafting:QueueRecipe("recipes:two", 1), "duplicate recipe queue is rejected")
assertEqual(Crafting:GetState().queuedCount, duplicateState.queuedCount, "duplicate rejection preserves the queue")
flushNextTask()
assertEqual(outputCounts["recipes:two"], 1, "queued second recipe starts after the active job")

materialCounts["recipes:one"] = 3
assertTrue(Crafting:QueueRecipe("recipes:one", 3), "cancellable recipe queues")
flushNextTask()
flushNextTask()
assertEqual(outputCounts["recipes:one"], 8, "cancellable queue completes its first unit")
assertTrue(Crafting:CancelCrafting("manual"), "CancelCrafting cancels active work")
local cancelledState = Crafting:GetState()
assertEqual(cancelledState.status, "cancelled", "cancelled queue reports cancelled state")
assertEqual(cancelledState.active, nil, "cancelled queue clears active work")
flushNextTask()
assertEqual(outputCounts["recipes:one"], 8, "stale scheduled callback cannot craft after cancellation")

materialCounts["recipes:one"] = 1
assertTrue(Crafting:QueueRecipe("recipes:one", 1), "profile-switch queue can be started")
profileKey = "crafting-other"
assertEqual(Crafting:GetState().status, "cancelled", "profile switch cancels active crafting")
flushNextTask()
assertEqual(outputCounts["recipes:one"], 8, "profile switch prevents stale crafting")

print("CraftingQueueTest passed")
