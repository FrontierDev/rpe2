local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local function assertTrue(value, message)
    if value ~= true then error(message, 2) end
end

local function loadAddonFile(path, addon)
    local chunk, loadError = loadfile(path)
    assert(chunk, loadError)
    chunk("RPEngine2", addon)
end

local profileRows = {
    { slotKey = "mainhand", entry = { itemRef = "profile:weapon" } },
}
local itemDefinitions = {
    ["npc:sword"] = { weaponTypeRef = "sword" },
    ["npc:two-handed"] = { isTwoHanded = true, weaponTypeRef = "axe" },
    ["npc:shield"] = { armorWeight = "shield" },
}

local Addon = {
    Client = { Conditions = {} },
    Internal = {
        Database = { Classes = {} },
        Profile = {
            Equipment = {
                ListEquippedSlots = function()
                    return profileRows
                end,
                ResolveItemDefinition = function(itemRef)
                    return itemDefinitions[itemRef]
                end,
            },
        },
    },
}

loadAddonFile("client/conditions/Core.lua", Addon)
local Conditions = Addon.Client.Conditions

local npc = {
    isPlayer = false,
    mainHandWeapon = "npc:sword",
    shield = "npc:shield",
}

assertTrue(
    Conditions:ResolveItemEquippedMatch({ casterUnit = npc }, { slotKey = "mainhand", weaponTypeRefs = {} }),
    "NPC main-hand conditions use the NPC authored weapon"
)
assertTrue(
    Conditions:ResolveItemEquippedMatch({ casterUnit = npc }, { slotKey = "offhand", requiresShield = true }),
    "NPC shield conditions use the NPC authored shield"
)
assertTrue(
    not Conditions:ResolveItemEquippedMatch({ casterUnit = npc }, { slotKey = "mainhand", requiresTwoHanded = true }),
    "NPC one-handed weapons do not satisfy two-handed conditions"
)

npc.mainHandWeapon = "npc:two-handed"
assertTrue(
    Conditions:ResolveItemEquippedMatch({ casterUnit = npc }, { slotKey = "mainhand", requiresTwoHanded = true }),
    "NPC two-handed weapons satisfy two-handed conditions"
)

local rows = Conditions:ResolveEquippedItemRows({ casterUnit = npc })
assertEqual(rows[1].entry.itemRef, "npc:two-handed", "NPC equipment rows retain main-hand reference")
assertEqual(rows[1].item.weaponTypeRef, "axe", "NPC equipment rows resolve item definitions")

local playerRows = Conditions:ResolveEquippedItemRows({ casterUnit = { isPlayer = true } })
assertEqual(playerRows, profileRows, "player conditions continue to use profile equipment")

print("NpcEquipmentConditionTest passed")
