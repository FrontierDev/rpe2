local _, Addon = ...

local DefaultDatasets = Addon.Data and Addon.Data.DefaultDatasets or nil
local definitions = DefaultDatasets and DefaultDatasets.Definitions or nil
local inscription = type(definitions) == "table" and definitions["072d4851"] or nil
local dataset = type(inscription) == "table" and inscription.dataset or nil

if type(dataset) == "table" then
    dataset.loot = type(dataset.loot) == "table" and dataset.loot or {}

    local lootId = "i7n3k5qx"
    local definition = {
        conditions = {},
        description = "Daily Inscription material cache. Guarantees one ink reward, weighted toward ordinary inks with uncommon inks as rarer outcomes.",
        drawCount = 1,
        entries = {
            { id = "ivory_ink", maxQuantity = 10, minQuantity = 6, ref = "072d4851:xw2qgag7", type = "item", weight = 20 },
            { id = "moonglow_ink", maxQuantity = 10, minQuantity = 6, ref = "072d4851:fd20vdnh", type = "item", weight = 18 },
            { id = "midnight_ink", maxQuantity = 8, minQuantity = 5, ref = "072d4851:salwlg09", type = "item", weight = 16 },
            { id = "lions_ink", maxQuantity = 7, minQuantity = 4, ref = "072d4851:3de4p55q", type = "item", weight = 14 },
            { id = "jadefire_ink", maxQuantity = 7, minQuantity = 4, ref = "072d4851:1u7ff1td", type = "item", weight = 12 },
            { id = "celestial_ink", maxQuantity = 6, minQuantity = 3, ref = "072d4851:ssxvp92d", type = "item", weight = 10 },
            { id = "shimmering_ink", maxQuantity = 5, minQuantity = 3, ref = "072d4851:bbw5xuid", type = "item", weight = 8 },
            { id = "hunters_ink", maxQuantity = 2, minQuantity = 1, ref = "072d4851:u4dmb3cq", type = "item", weight = 4 },
            { id = "dawnstar_ink", maxQuantity = 2, minQuantity = 1, ref = "072d4851:wptnvpoj", type = "item", weight = 3 },
            { id = "royal_ink", maxQuantity = 2, minQuantity = 1, ref = "072d4851:v3jffcqa", type = "item", weight = 2 },
            { id = "fiery_ink", maxQuantity = 1, minQuantity = 1, ref = "072d4851:0et3ciw9", type = "item", weight = 1 },
            { id = "ink_of_the_sky", maxQuantity = 1, minQuantity = 1, ref = "072d4851:3qte1prl", type = "item", weight = 1 },
        },
        icon = "interface/icons/inv_inscription_inkpurple03.blp",
        id = lootId,
        items = {},
        name = "Inscription Daily Ink Cache",
        tags = {},
    }

    local replaced = false
    for index = 1, #dataset.loot do
        local loot = dataset.loot[index]
        if type(loot) == "table" and tostring(loot.id or "") == lootId then
            dataset.loot[index] = definition
            replaced = true
            break
        end
    end

    if not replaced then
        dataset.loot[#dataset.loot + 1] = definition
    end

    inscription.version = math.max(4, math.floor(tonumber(inscription.version) or 1))
end
