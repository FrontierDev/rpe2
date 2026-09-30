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

local function loadAddonFile(path, addon)
    local chunk, loadError = loadfile(path)
    assert(chunk, loadError)
    chunk("RPEngine2", addon)
end

local Addon = { Data = {} }
loadAddonFile("data/default/Datasets.lua", Addon)
for _, path in ipairs({
    "data/default/classes/hunter.lua",
    "data/default/classes/mage.lua",
    "data/default/classes/paladin.lua",
    "data/default/classes/priest.lua",
    "data/default/classes/rogue.lua",
    "data/default/classes/warrior.lua",
}) do
    loadAddonFile(path, Addon)
end

local canonical = {
    a93f7c12 = "a93f7c12:h7n4t2er",
    d7c874c4 = "d7c874c4:02p0r8a2",
    b0211ab3 = "b0211ab3:wvirv9um",
    ["1c1038a7"] = "1c1038a7:nxlle3j6",
    ["23d5dce2"] = "23d5dce2:ta9uh9xw",
    ["7bbb4cb9"] = "7bbb4cb9:wvirv9um",
}

local classRegistry = {}
for datasetId, definition in pairs(Addon.Data.DefaultDatasets.Definitions) do
    for _, classEntry in ipairs(definition.dataset.classes or {}) do
        classRegistry[datasetId .. ":" .. tostring(classEntry.id)] = classEntry
    end
end

local function isTierSet(itemSetKey)
    return type(itemSetKey) == "string"
        and (itemSetKey:sub(1, 3) == "t05" or itemSetKey:sub(1, 3) == "t2_")
end

local function evaluateClassCondition(condition, profileClassRef)
    for _, classRef in ipairs(condition.classRefs or {}) do
        if tostring(classRef) == tostring(profileClassRef) then
            return true
        end
    end
    return false
end

local itemCount = 0
for datasetId, definition in pairs(Addon.Data.DefaultDatasets.Definitions) do
    local expectedClassRef = canonical[datasetId]
    for _, item in ipairs(definition.dataset.items or {}) do
        if isTierSet(item.itemSetKey) then
            itemCount = itemCount + 1
            assertTrue(expectedClassRef ~= nil, item.name .. " belongs to an unrecognized class dataset")
            local classConditions = {}
            for _, condition in ipairs(item.conditions or {}) do
                if condition.type == "class" then
                    classConditions[#classConditions + 1] = condition
                end
            end

            assertEqual(#classConditions, 1, item.name .. " has exactly one class condition")
            local condition = classConditions[1]
            assertEqual(#(condition.classRefs or {}), 1, item.name .. " has exactly one class ref")
            assertEqual(condition.classRefs[1], expectedClassRef, item.name .. " uses its canonical class ref")
            assertEqual(condition.invert, false, item.name .. " class condition is not inverted")
            assertEqual(condition.showOnTooltip, true, item.name .. " class condition is visible")
            assertEqual(condition.tooltipTextOverride, "Classes: " .. (definition.dataset.classes[1].name or ""), item.name .. " class tooltip")
            assertEqual(condition.type, "class", item.name .. " class condition type")
            assertTrue(classRegistry[expectedClassRef] ~= nil, item.name .. " class ref resolves through the class registry")
            assertTrue(evaluateClassCondition(condition, expectedClassRef), item.name .. " passes for its intended class")
            local otherClassRef = expectedClassRef == canonical.a93f7c12
                and canonical.d7c874c4
                or canonical.a93f7c12
            assertTrue(not evaluateClassCondition(condition, otherClassRef), item.name .. " fails for a different class")
        end
    end
end

assertTrue(itemCount > 0, "Tier 0.5/Tier 2 item regression found no items")
print("ClassSetRestrictionTest passed")
