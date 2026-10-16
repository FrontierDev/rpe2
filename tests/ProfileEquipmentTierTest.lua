local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local Addon = {
    Internal = {
        Database = { Classes = {} },
        Runtime = {},
    },
}

Addon.Internal.Runtime.RunTransaction = function(_, _, callback)
    return callback()
end
Addon.Internal.Runtime.MarkChanged = function() end

local function loadAddonFile(path)
    local chunk, loadError = loadfile(path)
    assert(chunk, loadError)
    chunk(nil, Addon)
end

loadAddonFile("core/internal/ItemTier.lua")
loadAddonFile("core/internal/database/Database.lua")

_G.RPEngineProfilesDB = {
    _schema = 7,
    profiles = {
        ["unknown-player"] = {
            characterKey = "unknown-player",
            name = "Unknown Author",
            equipment = {
                mainhand = { datasetId = "dataset", itemId = "sword", itemRef = "dataset:sword" },
            },
            mountEquipment = {},
            petRef = "dataset:pet",
            petEquipment = {
                ["dataset:pet"] = {},
            },
        },
    },
}

local Database = Addon.Internal.Database
assertEqual(Database.ListProfileEquipmentByScope("character").mainhand.itemTier, "normal", "legacy character equipment defaults to Normal")

local heroic = Database.SetProfileEquipmentSlotByScope("character", "mainhand", {
    datasetId = "dataset",
    itemId = "sword",
    itemRef = "dataset:sword",
    itemTier = "heroic",
})
assertEqual(heroic.itemTier, "heroic", "character equipment stores Heroic")
assertEqual(Database.ListProfileEquipmentByScope("character").mainhand.itemTier, "heroic", "character equipment round-trips Heroic")

local mythicMount = Database.SetProfileEquipmentSlotByScope("mount", "saddle", {
    datasetId = "dataset",
    itemId = "saddle",
    itemRef = "dataset:saddle",
    itemTier = "mythic",
})
assertEqual(mythicMount.itemTier, "mythic", "mount equipment stores Mythic")
assertEqual(Database.ListProfileEquipmentByScope("mount").saddle.itemTier, "mythic", "mount equipment round-trips Mythic")

local heroicPet = Database.SetProfileEquipmentSlotByScope("pet", "collar", {
    datasetId = "dataset",
    itemId = "collar",
    itemRef = "dataset:collar",
    itemTier = "heroic",
})
assertEqual(heroicPet.itemTier, "heroic", "pet equipment stores Heroic")
assertEqual(Database.ListProfileEquipmentByScope("pet").collar.itemTier, "heroic", "pet equipment round-trips Heroic")

print("ProfileEquipmentTierTest passed")
