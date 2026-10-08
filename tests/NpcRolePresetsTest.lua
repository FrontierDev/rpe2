local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local function assertNear(actual, expected, message)
    if type(actual) ~= "number" or math.abs(actual - expected) > 0.000001 then
        error(("%s: expected %.9f, got %s"):format(message, expected, tostring(actual)), 2)
    end
end

local function deepCopy(value)
    if type(value) ~= "table" then return value end
    local copy = {}
    for key, nestedValue in pairs(value) do copy[key] = deepCopy(nestedValue) end
    return copy
end

local function deepEqual(left, right)
    if type(left) ~= type(right) then return false end
    if type(left) ~= "table" then return left == right end
    for key, value in pairs(left) do
        if not deepEqual(value, right[key]) then return false end
    end
    for key in pairs(right) do
        if left[key] == nil then return false end
    end
    return true
end

local function findRow(rows, refKey, ref)
    for index = 1, #(rows or {}) do
        if rows[index][refKey] == ref then return rows[index] end
    end
end

local TestSupport = dofile("tests/support/RuntimeStubs.lua")

local definitions = {}
local Addon = {
    Internal = { Database = { Classes = {} } },
    Data = {
        DefaultDatasets = {
            Register = function(_, definition)
                definitions[definition.dataset.id] = definition.dataset
                return definition
            end,
        },
    },
}

local function loadAddonFile(path)
    TestSupport.LoadAddonFile(path, Addon, "RPEngine2")
end

loadAddonFile("core/classes/Unit.lua")
loadAddonFile("core/classes/UnitPresetSpellEquipment.lua")
loadAddonFile("data/default/core.lua")
loadAddonFile("data/default/classes/warrior.lua")
loadAddonFile("data/default/classes/rogue.lua")
loadAddonFile("data/default/classes/priest.lua")
loadAddonFile("data/default/classes/mage.lua")
loadAddonFile("data/default/classes/warlock.lua")
loadAddonFile("data/default/classes/hunter.lua")
loadAddonFile("data/default/classes/death_knight.lua")
loadAddonFile("data/default/classes/demon_hunter.lua")
loadAddonFile("data/default/classes/druid.lua")
loadAddonFile("data/default/classes/evoker.lua")
loadAddonFile("data/default/classes/monk.lua")
loadAddonFile("data/default/classes/paladin.lua")
loadAddonFile("data/default/classes/shaman.lua")

local Unit = Addon.Internal.Database.Classes.Unit
local core = definitions["f82db71a"]
assert(core, "Core dataset loaded")

local function findUnit(id)
    for index = 1, #(core.units or {}) do
        if core.units[index].id == id then return core.units[index] end
    end
end

local human = findUnit("7i40epa5")
assert(human, "Human Unit exists in Core")
local felguard = findUnit("felgrd01")
assert(felguard, "Felguard Unit exists in Core")
assertEqual(felguard.name, "Felguard", "Felguard unit name")
assertEqual(felguard.creatureType, "demon", "Felguard creature type")
assertEqual(felguard.challengeLevel, "normal", "Felguard challenge level")
assert(#(felguard.presets or {}) > 0, "Felguard has role presets")
assertEqual(felguard.resources[1].initialValue, 208, "Felguard base Health")
assertEqual(felguard.resources[2].resourceRef, "f82db71a:e2tfklq7", "Felguard uses Rage")

local entityRefs = { stats = {}, resources = {}, items = {}, spells = {} }
for datasetId, dataset in pairs(definitions) do
    for _, collection in ipairs({ "stats", "resources", "items", "spells" }) do
        for index = 1, #(dataset[collection] or {}) do
            local entity = dataset[collection][index]
            entityRefs[collection][datasetId .. ":" .. tostring(entity.id)] = true
        end
    end
end

local voidwalker = findUnit("voidw001")
assert(voidwalker, "Voidwalker Unit exists in Core")

local abomination = findUnit("abom0001")
assert(abomination, "Abomination Unit exists in Core")
assertEqual(abomination.name, "Abomination", "Abomination unit name")
assertEqual(abomination.challengeLevel, "elite", "Abomination challenge level")
assertEqual(abomination.creatureSize, "large", "Abomination creature size")
assertEqual(abomination.creatureType, "undead", "Abomination creature type")
assertEqual(abomination.mainHandWeapon, "f82db71a:stwaxe01", "Abomination main-hand weapon")
assertEqual(abomination.offHandWeapon, "f82db71a:stwaxe01", "Abomination off-hand weapon")
assertEqual(abomination.resources[1].initialValue, 200, "Abomination base Health")
assertEqual(abomination.resources[2].resourceRef, "f82db71a:e2tfklq7", "Abomination uses Rage")
for index = 1, #(abomination.spells or {}) do
    assert(entityRefs.spells[abomination.spells[index]], "Abomination spell ref resolves: " .. abomination.spells[index])
end

local banshee = findUnit("bansh001")
assert(banshee, "Banshee Unit exists in Core")
assertEqual(banshee.name, "Banshee", "Banshee unit name")
assertEqual(banshee.challengeLevel, "elite", "Banshee challenge level")
assertEqual(banshee.creatureSize, "medium", "Banshee creature size")
assertEqual(banshee.creatureType, "undead", "Banshee creature type")
assertEqual(banshee.resources[1].initialValue, 150, "Banshee base Health")
assertEqual(banshee.resources[2].resourceRef, "f82db71a:4c8mfm99", "Banshee uses Mana")
for index = 1, #(banshee.spells or {}) do
    assert(entityRefs.spells[banshee.spells[index]], "Banshee spell ref resolves: " .. banshee.spells[index])
end

local gargoyle = findUnit("garg0001")
assert(gargoyle, "Gargoyle Unit exists in Core")
assertEqual(gargoyle.name, "Gargoyle", "Gargoyle unit name")
assertEqual(gargoyle.challengeLevel, "normal", "Gargoyle challenge level")
assertEqual(gargoyle.creatureSize, "medium", "Gargoyle creature size")
assertEqual(gargoyle.creatureType, "undead", "Gargoyle creature type")
assertEqual(gargoyle.attributes[1], "flying", "Gargoyle flying attribute")
assertEqual(gargoyle.resources[1].initialValue, 160, "Gargoyle base Health")
assertEqual(gargoyle.resources[2].resourceRef, "f82db71a:4c8mfm99", "Gargoyle uses Mana")
for index = 1, #(gargoyle.spells or {}) do
    assert(entityRefs.spells[gargoyle.spells[index]], "Gargoyle spell ref resolves: " .. gargoyle.spells[index])
end

local geist = findUnit("geist001")
assert(geist, "Geist Unit exists in Core")
assertEqual(geist.name, "Geist", "Geist unit name")
assertEqual(geist.challengeLevel, "normal", "Geist challenge level")
assertEqual(geist.creatureSize, "medium", "Geist creature size")
assertEqual(geist.creatureType, "undead", "Geist creature type")
assertEqual(geist.resources[1].initialValue, 140, "Geist base Health")
assertEqual(geist.stats[6].initialValue, 8, "Geist Dodge Chance")
assertEqual(geist.stats[8].initialValue, 0, "Geist Magic Resistance")
assertEqual(geist.stats[12].initialValue, 8, "Geist Melee Crit Chance")
assertEqual(geist.stats[23].initialValue, 40, "Geist Movement Speed")
for index = 1, #(geist.spells or {}) do
    assert(entityRefs.spells[geist.spells[index]], "Geist spell ref resolves: " .. geist.spells[index])
end

local ghost = findUnit("ghost001")
assert(ghost, "Ghost Unit exists in Core")
assertEqual(ghost.name, "Ghost", "Ghost unit name")
assertEqual(ghost.challengeLevel, "normal", "Ghost challenge level")
assertEqual(ghost.creatureSize, "medium", "Ghost creature size")
assertEqual(ghost.creatureType, "undead", "Ghost creature type")
assertEqual(ghost.resources[1].initialValue, 140, "Ghost base Health")
assertEqual(ghost.resources[2].resourceRef, "f82db71a:4c8mfm99", "Ghost uses Mana")
assertEqual(ghost.stats[8].initialValue, 10, "Ghost Magic Resistance")
assertEqual(ghost.stats[20].initialValue, 25, "Ghost Shadow Resistance")
assertEqual(ghost.stats[23].initialValue, 30, "Ghost Movement Speed")
assertEqual(#(ghost.presets or {}), 3, "Ghost variant preset count")
assertEqual(ghost.presets[1].name, "Wraith", "Ghost Wraith preset")
assertEqual(ghost.presets[2].name, "Spectre", "Ghost Spectre preset")
assertEqual(ghost.presets[3].name, "Shade", "Ghost Shade preset")
for index = 1, #(ghost.spells or {}) do
    assert(entityRefs.spells[ghost.spells[index]], "Ghost spell ref resolves: " .. ghost.spells[index])
end
for presetIndex = 1, #(ghost.presets or {}) do
    local preset = ghost.presets[presetIndex]
    for spellIndex = 1, #(preset.spells or {}) do
        assert(entityRefs.spells[preset.spells[spellIndex]], "Ghost preset spell ref resolves: " .. preset.spells[spellIndex])
    end
end

local ghoul = findUnit("ghoul001")
assert(ghoul, "Ghoul Unit exists in Core")
assertEqual(ghoul.name, "Ghoul", "Ghoul unit name")
assertEqual(ghoul.challengeLevel, "minor", "Ghoul challenge level")
assertEqual(ghoul.creatureSize, "medium", "Ghoul creature size")
assertEqual(ghoul.creatureType, "undead", "Ghoul creature type")
assertEqual(ghoul.resources[1].initialValue, 130, "Ghoul base Health")
assertEqual(ghoul.resources[1].resourceRef, "f82db71a:q2ktkztt", "Ghoul uses Health")
assertEqual(ghoul.stats[1].initialValue, 20, "Ghoul base Armor")
assertEqual(ghoul.stats[6].initialValue, 3, "Ghoul Dodge Chance")
assertEqual(ghoul.stats[9].initialValue, 45, "Ghoul Melee Attack Power")
assertEqual(ghoul.stats[23].initialValue, 35, "Ghoul Movement Speed")
assertEqual(#(ghoul.presets or {}), 3, "Ghoul variant preset count")
assertEqual(ghoul.presets[1].name, "Plaguebearer", "Ghoul Plaguebearer preset")
assertEqual(ghoul.presets[2].name, "Leaper", "Ghoul Leaper preset")
assertEqual(ghoul.presets[3].name, "Ravager", "Ghoul Ravager preset")
for index = 1, #(ghoul.spells or {}) do
    assert(entityRefs.spells[ghoul.spells[index]], "Ghoul spell ref resolves: " .. ghoul.spells[index])
end
for presetIndex = 1, #(ghoul.presets or {}) do
    local preset = ghoul.presets[presetIndex]
    for spellIndex = 1, #(preset.spells or {}) do
        assert(entityRefs.spells[preset.spells[spellIndex]], "Ghoul preset spell ref resolves: " .. preset.spells[spellIndex])
    end
end

local gnoll = findUnit("gnoll001")
assert(gnoll, "Gnoll Unit exists in Core")
assertEqual(gnoll.name, "Gnoll", "Gnoll unit name")
assertEqual(gnoll.challengeLevel, "minor", "Gnoll challenge level")
assertEqual(gnoll.creatureSize, "medium", "Gnoll creature size")
assertEqual(gnoll.creatureType, "humanoid", "Gnoll creature type")
assertEqual(gnoll.resources[1].initialValue, 130, "Gnoll base Health")
assertEqual(gnoll.resources[2].resourceRef, "f82db71a:4c8mfm99", "Gnoll Mana pool")
assertEqual(gnoll.resources[3].resourceRef, "f82db71a:e2tfklq7", "Gnoll Rage pool")
assertEqual(gnoll.stats[1].initialValue, 20, "Gnoll base Armor")
assertEqual(gnoll.stats[9].initialValue, 45, "Gnoll Melee Attack Power")
assertEqual(gnoll.stats[10].initialValue, 40, "Gnoll Ranged Attack Power")
assertEqual(gnoll.stats[23].initialValue, 30, "Gnoll Movement Speed")
assertEqual(#(gnoll.presets or {}), 4, "Gnoll variant preset count")
assertEqual(gnoll.presets[1].name, "Brute", "Gnoll Brute preset")
assertEqual(gnoll.presets[2].name, "Poacher", "Gnoll Poacher preset")
assertEqual(gnoll.presets[3].name, "Shaman", "Gnoll Shaman preset")
assertEqual(gnoll.presets[4].name, "Overseer", "Gnoll Overseer preset")
assertEqual(gnoll.presets[4].challengeLevel, "elite", "Gnoll Overseer challenge level")
for index = 1, #(gnoll.spells or {}) do
    assert(entityRefs.spells[gnoll.spells[index]], "Gnoll spell ref resolves: " .. gnoll.spells[index])
end
for presetIndex = 1, #(gnoll.presets or {}) do
    local preset = gnoll.presets[presetIndex]
    for spellIndex = 1, #(preset.spells or {}) do
        assert(entityRefs.spells[preset.spells[spellIndex]], "Gnoll preset spell ref resolves: " .. preset.spells[spellIndex])
    end
end

local kobold = findUnit("kobold01")
assert(kobold, "Kobold Unit exists in Core")
assertEqual(kobold.name, "Kobold", "Kobold unit name")
assertEqual(kobold.challengeLevel, "minor", "Kobold challenge level")
assertEqual(kobold.creatureSize, "small", "Kobold creature size")
assertEqual(kobold.creatureType, "humanoid", "Kobold creature type")
assertEqual(kobold.resources[1].initialValue, 100, "Kobold base Health")
assertEqual(kobold.resources[2].resourceRef, "f82db71a:4c8mfm99", "Kobold Mana pool")
assertEqual(kobold.resources[3].resourceRef, "f82db71a:e2tfklq7", "Kobold Rage pool")
assertEqual(kobold.stats[1].initialValue, 20, "Kobold base Armor")
assertEqual(kobold.stats[9].initialValue, 35, "Kobold Melee Attack Power")
assertEqual(kobold.stats[12].initialValue, 5, "Kobold Melee Crit Chance")
assertEqual(kobold.stats[23].initialValue, 30, "Kobold Movement Speed")
assertEqual(#(kobold.presets or {}), 3, "Kobold variant preset count")
assertEqual(kobold.presets[1].name, "Tunneler", "Kobold Tunneler preset")
assertEqual(kobold.presets[2].name, "Geomancer", "Kobold Geomancer preset")
assertEqual(kobold.presets[3].name, "Taskmaster", "Kobold Taskmaster preset")
assertEqual(kobold.presets[3].challengeLevel, "elite", "Kobold Taskmaster challenge level")
for index = 1, #(kobold.spells or {}) do
    assert(entityRefs.spells[kobold.spells[index]], "Kobold spell ref resolves: " .. kobold.spells[index])
end
for presetIndex = 1, #(kobold.presets or {}) do
    local preset = kobold.presets[presetIndex]
    for spellIndex = 1, #(preset.spells or {}) do
        assert(entityRefs.spells[preset.spells[spellIndex]], "Kobold preset spell ref resolves: " .. preset.spells[spellIndex])
    end
end

local murloc = findUnit("murloc01")
assert(murloc, "Murloc Unit exists in Core")
assertEqual(murloc.name, "Murloc", "Murloc unit name")
assertEqual(murloc.challengeLevel, "minor", "Murloc challenge level")
assertEqual(murloc.creatureSize, "medium", "Murloc creature size")
assertEqual(murloc.creatureType, "humanoid", "Murloc creature type")
assertEqual(murloc.resources[1].initialValue, 120, "Murloc base Health")
assertEqual(murloc.stats[1].initialValue, 15, "Murloc base Armor")
assertEqual(murloc.stats[9].initialValue, 40, "Murloc Melee Attack Power")
assertEqual(murloc.stats[10].initialValue, 35, "Murloc Ranged Attack Power")
assertEqual(murloc.stats[23].initialValue, 35, "Murloc Movement Speed")
assertEqual(#(murloc.presets or {}), 4, "Murloc variant preset count")
assertEqual(murloc.presets[1].name, "Tidehunter", "Murloc Tidehunter preset")
assertEqual(murloc.presets[2].name, "Hunter", "Murloc Hunter preset")
assertEqual(murloc.presets[3].name, "Oracle", "Murloc Oracle preset")
assertEqual(murloc.presets[4].name, "Chieftain", "Murloc Chieftain preset")
assertEqual(murloc.presets[4].challengeLevel, "elite", "Murloc Chieftain challenge level")
for index = 1, #(murloc.spells or {}) do
    assert(entityRefs.spells[murloc.spells[index]], "Murloc spell ref resolves: " .. murloc.spells[index])
end
for presetIndex = 1, #(murloc.presets or {}) do
    local preset = murloc.presets[presetIndex]
    for spellIndex = 1, #(preset.spells or {}) do
        assert(entityRefs.spells[preset.spells[spellIndex]], "Murloc preset spell ref resolves: " .. preset.spells[spellIndex])
    end
end

local nerubian = findUnit("nerub001")
assert(nerubian, "Nerubian Unit exists in Core")
assertEqual(nerubian.name, "Nerubian", "Nerubian unit name")
assertEqual(nerubian.challengeLevel, "normal", "Nerubian challenge level")
assertEqual(nerubian.creatureSize, "large", "Nerubian creature size")
assertEqual(nerubian.creatureType, "undead", "Nerubian creature type")
assertEqual(nerubian.resources[1].initialValue, 180, "Nerubian base Health")
assertEqual(nerubian.resources[2].initialValue, 100, "Nerubian base Mana")
assertEqual(nerubian.resources[3].initialValue, 100, "Nerubian base Rage")
assertEqual(nerubian.stats[1].initialValue, 30, "Nerubian base Armor")
assertEqual(nerubian.stats[9].initialValue, 50, "Nerubian Melee Attack Power")
assertEqual(nerubian.stats[10].initialValue, 50, "Nerubian Ranged Attack Power")
assertEqual(nerubian.stats[23].initialValue, 30, "Nerubian Movement Speed")
assertEqual(#(nerubian.presets or {}), 4, "Nerubian variant preset count")
assertEqual(nerubian.presets[1].name, "Fiend", "Nerubian Fiend preset")
assertEqual(nerubian.presets[2].name, "Stalker", "Nerubian Stalker preset")
assertEqual(nerubian.presets[3].name, "Vizier", "Nerubian Vizier preset")
assertEqual(nerubian.presets[4].name, "Lord", "Nerubian Lord preset")
assertEqual(nerubian.presets[3].challengeLevel, "elite", "Nerubian Vizier challenge level")
assertEqual(nerubian.presets[4].challengeLevel, "elite", "Nerubian Lord challenge level")
for index = 1, #(nerubian.spells or {}) do
    assert(entityRefs.spells[nerubian.spells[index]], "Nerubian spell ref resolves: " .. nerubian.spells[index])
end
for presetIndex = 1, #(nerubian.presets or {}) do
    local preset = nerubian.presets[presetIndex]
    for spellIndex = 1, #(preset.spells or {}) do
        assert(entityRefs.spells[preset.spells[spellIndex]], "Nerubian preset spell ref resolves: " .. preset.spells[spellIndex])
    end
end

local skeletalHound = findUnit("skhound1")
assert(skeletalHound, "Skeletal Hound Unit exists in Core")
assertEqual(skeletalHound.name, "Skeletal Hound", "Skeletal Hound unit name")
assertEqual(skeletalHound.challengeLevel, "minor", "Skeletal Hound challenge level")
assertEqual(skeletalHound.creatureSize, "medium", "Skeletal Hound creature size")
assertEqual(skeletalHound.creatureType, "undead", "Skeletal Hound creature type")
assertEqual(skeletalHound.resources[1].initialValue, 125, "Skeletal Hound base Health")
assertEqual(skeletalHound.resources[1].perLevelValue, 25, "Skeletal Hound health progression")
assertEqual(skeletalHound.stats[1].initialValue, 20, "Skeletal Hound base Armor")
assertEqual(skeletalHound.stats[6].initialValue, 5, "Skeletal Hound Dodge Chance")
assertEqual(skeletalHound.stats[9].initialValue, 45, "Skeletal Hound Melee Attack Power")
assertEqual(skeletalHound.stats[12].initialValue, 5, "Skeletal Hound Melee Crit Chance")
assertEqual(skeletalHound.stats[23].initialValue, 40, "Skeletal Hound Movement Speed")
assertEqual(#(skeletalHound.presets or {}), 0, "Skeletal Hound has no presets")
assertEqual(#(skeletalHound.spells or {}), 1, "Skeletal Hound natural attack only")
for index = 1, #(skeletalHound.spells or {}) do
    assert(entityRefs.spells[skeletalHound.spells[index]], "Skeletal Hound spell ref resolves: " .. skeletalHound.spells[index])
end

local skeleton = findUnit("skeleton1")
assert(skeleton, "Skeleton Unit exists in Core")
assertEqual(skeleton.name, "Skeleton", "Skeleton unit name")
assertEqual(skeleton.challengeLevel, "minor", "Skeleton challenge level")
assertEqual(skeleton.creatureSize, "medium", "Skeleton creature size")
assertEqual(skeleton.creatureType, "undead", "Skeleton creature type")
assertEqual(skeleton.resources[1].initialValue, 110, "Skeleton base Health")
assertEqual(skeleton.resources[2].initialValue, 80, "Skeleton base Mana")
assertEqual(skeleton.resources[3].initialValue, 100, "Skeleton base Rage")
assertEqual(skeleton.stats[1].initialValue, 25, "Skeleton base Armor")
assertEqual(skeleton.stats[9].initialValue, 45, "Skeleton Melee Attack Power")
assertEqual(skeleton.stats[10].initialValue, 45, "Skeleton Ranged Attack Power")
assertEqual(skeleton.stats[11].perLevelValue, 2.542373, "Skeleton Spell Power progression")
assertEqual(skeleton.stats[23].initialValue, 30, "Skeleton Movement Speed")
assertEqual(#(skeleton.presets or {}), 5, "Skeleton variant preset count")
assertEqual(skeleton.presets[1].name, "Warrior", "Skeleton Warrior preset")
assertEqual(skeleton.presets[2].name, "Archer", "Skeleton Archer preset")
assertEqual(skeleton.presets[3].name, "Mage", "Skeleton Mage preset")
assertEqual(skeleton.presets[4].name, "Shadowmage", "Skeleton Shadowmage preset")
assertEqual(skeleton.presets[5].name, "Warder", "Skeleton Warder preset")
assertEqual(skeleton.presets[4].challengeLevel, "elite", "Skeleton Shadowmage challenge level")
assertEqual(skeleton.presets[5].challengeLevel, "elite", "Skeleton Warder challenge level")
for index = 1, #(skeleton.spells or {}) do
    assert(entityRefs.spells[skeleton.spells[index]], "Skeleton spell ref resolves: " .. skeleton.spells[index])
end
for presetIndex = 1, #(skeleton.presets or {}) do
    local preset = skeleton.presets[presetIndex]
    for spellIndex = 1, #(preset.spells or {}) do
        assert(entityRefs.spells[preset.spells[spellIndex]], "Skeleton preset spell ref resolves: " .. preset.spells[spellIndex])
    end
    for slot, itemRef in pairs(preset.equipment or {}) do
        assert(entityRefs.items[itemRef], "Skeleton equipment ref resolves for " .. slot .. ": " .. itemRef)
    end
end

local zombie = findUnit("zombie01")
assert(zombie, "Zombie Unit exists in Core")
assertEqual(zombie.name, "Zombie", "Zombie unit name")
assertEqual(zombie.challengeLevel, "minor", "Zombie challenge level")
assertEqual(zombie.creatureSize, "medium", "Zombie creature size")
assertEqual(zombie.creatureType, "undead", "Zombie creature type")
assertEqual(zombie.resources[1].initialValue, 120, "Zombie base Health")
assertEqual(zombie.resources[1].perLevelValue, 23.389831, "Zombie health progression")
assertEqual(zombie.stats[1].initialValue, 25, "Zombie base Armor")
assertEqual(zombie.stats[9].initialValue, 40, "Zombie Melee Attack Power")
assertEqual(zombie.stats[12].initialValue, 5, "Zombie Melee Crit Chance")
assertEqual(zombie.stats[23].initialValue, 20, "Zombie Movement Speed")
assertEqual(#(zombie.presets or {}), 0, "Zombie has no presets")
assertEqual(#(zombie.resources or {}), 1, "Zombie has Health only")
assertEqual(#(zombie.spells or {}), 1, "Zombie natural attack only")
for index = 1, #(zombie.spells or {}) do
    assert(entityRefs.spells[zombie.spells[index]], "Zombie spell ref resolves: " .. zombie.spells[index])
end

local furbolg = findUnit("furbolg01")
assert(furbolg, "Furbolg Unit exists in Core")
assertEqual(furbolg.name, "Furbolg", "Furbolg unit name")
assertEqual(furbolg.challengeLevel, "minor", "Furbolg challenge level")
assertEqual(furbolg.creatureSize, "medium", "Furbolg creature size")
assertEqual(furbolg.creatureType, "humanoid", "Furbolg creature type")
assertEqual(furbolg.resources[1].initialValue, 150, "Furbolg base Health")
assertEqual(furbolg.stats[1].initialValue, 25, "Furbolg base Armor")
assertEqual(furbolg.stats[9].initialValue, 50, "Furbolg Melee Attack Power")
assertEqual(furbolg.stats[11].perLevelValue, 2.542373, "Furbolg Spell Power progression")
assertEqual(furbolg.stats[14].initialValue, 5, "Furbolg Spell Crit Chance")
assertEqual(furbolg.stats[23].initialValue, 30, "Furbolg Movement Speed")
assertEqual(#(furbolg.presets or {}), 4, "Furbolg variant preset count")
assertEqual(furbolg.presets[1].name, "Mauler", "Furbolg Mauler preset")
assertEqual(furbolg.presets[2].name, "Shaman", "Furbolg Shaman preset")
assertEqual(furbolg.presets[3].name, "Ursa Warrior", "Furbolg Ursa Warrior preset")
assertEqual(furbolg.presets[4].name, "Elder", "Furbolg Elder preset")
assertEqual(furbolg.presets[4].challengeLevel, "elite", "Furbolg Elder challenge level")
for index = 1, #(furbolg.spells or {}) do
    assert(entityRefs.spells[furbolg.spells[index]], "Furbolg spell ref resolves: " .. furbolg.spells[index])
end
for presetIndex = 1, #(furbolg.presets or {}) do
    local preset = furbolg.presets[presetIndex]
    for spellIndex = 1, #(preset.spells or {}) do
        assert(entityRefs.spells[preset.spells[spellIndex]], "Furbolg preset spell ref resolves: " .. preset.spells[spellIndex])
    end
    for slot, itemRef in pairs(preset.equipment or {}) do
        assert(entityRefs.items[itemRef], "Furbolg equipment ref resolves for " .. slot .. ": " .. itemRef)
    end
end

local quilboar = findUnit("quilbr01")
assert(quilboar, "Quilboar Unit exists in Core")
assertEqual(quilboar.name, "Quilboar", "Quilboar unit name")
assertEqual(quilboar.challengeLevel, "minor", "Quilboar challenge level")
assertEqual(quilboar.creatureSize, "medium", "Quilboar creature size")
assertEqual(quilboar.creatureType, "humanoid", "Quilboar creature type")
assertEqual(quilboar.resources[1].initialValue, 135, "Quilboar base Health")
assertEqual(quilboar.stats[1].initialValue, 20, "Quilboar base Armor")
assertEqual(quilboar.stats[9].initialValue, 45, "Quilboar Melee Attack Power")
assertEqual(quilboar.stats[11].perLevelValue, 2.542373, "Quilboar Spell Power progression")
assertEqual(quilboar.stats[14].initialValue, 5, "Quilboar Spell Crit Chance")
assertEqual(quilboar.stats[23].initialValue, 30, "Quilboar Movement Speed")
assertEqual(#(quilboar.presets or {}), 5, "Quilboar variant preset count")
assertEqual(quilboar.presets[1].name, "Thornweaver", "Quilboar Thornweaver preset")
assertEqual(quilboar.presets[2].name, "Geomancer", "Quilboar Geomancer preset")
assertEqual(quilboar.presets[3].name, "Spiritcaller", "Quilboar Spiritcaller preset")
assertEqual(quilboar.presets[4].name, "Berserker", "Quilboar Berserker preset")
assertEqual(quilboar.presets[5].name, "Warlord", "Quilboar Warlord preset")
assertEqual(quilboar.presets[5].challengeLevel, "elite", "Quilboar Warlord challenge level")
for index = 1, #(quilboar.spells or {}) do
    assert(entityRefs.spells[quilboar.spells[index]], "Quilboar spell ref resolves: " .. quilboar.spells[index])
end
for presetIndex = 1, #(quilboar.presets or {}) do
    local preset = quilboar.presets[presetIndex]
    for spellIndex = 1, #(preset.spells or {}) do
        assert(entityRefs.spells[preset.spells[spellIndex]], "Quilboar preset spell ref resolves: " .. preset.spells[spellIndex])
    end
    for slot, itemRef in pairs(preset.equipment or {}) do
        assert(entityRefs.items[itemRef], "Quilboar equipment ref resolves for " .. slot .. ": " .. itemRef)
    end
end

local trogg = findUnit("trogg001")
assert(trogg, "Trogg Unit exists in Core")
assertEqual(trogg.name, "Trogg", "Trogg unit name")
assertEqual(trogg.challengeLevel, "minor", "Trogg challenge level")
assertEqual(trogg.creatureSize, "medium", "Trogg creature size")
assertEqual(trogg.creatureType, "humanoid", "Trogg creature type")
assertEqual(trogg.resources[1].initialValue, 140, "Trogg base Health")
assertEqual(trogg.stats[1].initialValue, 25, "Trogg base Armor")
assertEqual(trogg.stats[9].initialValue, 50, "Trogg Melee Attack Power")
assertEqual(trogg.stats[11].perLevelValue, 2.542373, "Trogg Spell Power progression")
assertEqual(trogg.stats[14].initialValue, 5, "Trogg Spell Crit Chance")
assertEqual(trogg.stats[23].initialValue, 30, "Trogg Movement Speed")
assertEqual(#(trogg.presets or {}), 5, "Trogg variant preset count")
assertEqual(trogg.presets[1].name, "Stonebreaker", "Trogg Stonebreaker preset")
assertEqual(trogg.presets[2].name, "Brawler", "Trogg Brawler preset")
assertEqual(trogg.presets[3].name, "Geomancer", "Trogg Geomancer preset")
assertEqual(trogg.presets[4].name, "Seer", "Trogg Seer preset")
assertEqual(trogg.presets[5].name, "Chieftain", "Trogg Chieftain preset")
assertEqual(trogg.presets[5].challengeLevel, "elite", "Trogg Chieftain challenge level")
for index = 1, #(trogg.spells or {}) do
    assert(entityRefs.spells[trogg.spells[index]], "Trogg spell ref resolves: " .. trogg.spells[index])
end
for presetIndex = 1, #(trogg.presets or {}) do
    local preset = trogg.presets[presetIndex]
    for spellIndex = 1, #(preset.spells or {}) do
        assert(entityRefs.spells[preset.spells[spellIndex]], "Trogg preset spell ref resolves: " .. preset.spells[spellIndex])
    end
    for slot, itemRef in pairs(preset.equipment or {}) do
        assert(entityRefs.items[itemRef], "Trogg equipment ref resolves for " .. slot .. ": " .. itemRef)
    end
end

local ogre = findUnit("ogre001")
assert(ogre, "Ogre Unit exists in Core")
assertEqual(ogre.name, "Ogre", "Ogre unit name")
assertEqual(ogre.challengeLevel, "minor", "Ogre challenge level")
assertEqual(ogre.creatureSize, "large", "Ogre creature size")
assertEqual(ogre.creatureType, "humanoid", "Ogre creature type")
assertEqual(ogre.resources[1].initialValue, 160, "Ogre base Health")
assertEqual(ogre.stats[1].initialValue, 30, "Ogre base Armor")
assertEqual(ogre.stats[9].initialValue, 55, "Ogre Melee Attack Power")
assertEqual(ogre.stats[11].perLevelValue, 2.542373, "Ogre Spell Power progression")
assertEqual(ogre.stats[14].initialValue, 5, "Ogre Spell Crit Chance")
assertEqual(ogre.stats[23].initialValue, 25, "Ogre Movement Speed")
assertEqual(#(ogre.presets or {}), 4, "Ogre variant preset count")
assertEqual(ogre.presets[1].name, "Bruiser", "Ogre Bruiser preset")
assertEqual(ogre.presets[2].name, "Warlock", "Ogre Warlock preset")
assertEqual(ogre.presets[3].name, "Magus", "Ogre Magus preset")
assertEqual(ogre.presets[4].name, "Enforcer", "Ogre Enforcer preset")
assertEqual(ogre.presets[3].challengeLevel, "elite", "Ogre Magus challenge level")
assertEqual(ogre.presets[4].challengeLevel, "elite", "Ogre Enforcer challenge level")
for index = 1, #(ogre.spells or {}) do
    assert(entityRefs.spells[ogre.spells[index]], "Ogre spell ref resolves: " .. ogre.spells[index])
end
for presetIndex = 1, #(ogre.presets or {}) do
    local preset = ogre.presets[presetIndex]
    for spellIndex = 1, #(preset.spells or {}) do
        assert(entityRefs.spells[preset.spells[spellIndex]], "Ogre preset spell ref resolves: " .. preset.spells[spellIndex])
    end
    for slot, itemRef in pairs(preset.equipment or {}) do
        assert(entityRefs.items[itemRef], "Ogre equipment ref resolves for " .. slot .. ": " .. itemRef)
    end
end

local centaur = findUnit("centaur01")
assert(centaur, "Centaur Unit exists in Core")
assertEqual(centaur.name, "Centaur", "Centaur unit name")
assertEqual(centaur.challengeLevel, "minor", "Centaur challenge level")
assertEqual(centaur.creatureSize, "large", "Centaur creature size")
assertEqual(centaur.creatureType, "humanoid", "Centaur creature type")
assertEqual(centaur.resources[1].initialValue, 130, "Centaur base Health")
assertEqual(centaur.stats[1].initialValue, 20, "Centaur base Armor")
assertEqual(centaur.stats[9].initialValue, 45, "Centaur Melee Attack Power")
assertEqual(centaur.stats[10].initialValue, 40, "Centaur Ranged Attack Power")
assertEqual(centaur.stats[23].initialValue, 40, "Centaur Movement Speed")
assertEqual(#(centaur.presets or {}), 5, "Centaur variant preset count")
assertEqual(centaur.presets[1].name, "Marauder", "Centaur Marauder preset")
assertEqual(centaur.presets[2].name, "Archer", "Centaur Archer preset")
assertEqual(centaur.presets[3].name, "Geomancer", "Centaur Geomancer preset")
assertEqual(centaur.presets[4].name, "Windchaser", "Centaur Windchaser preset")
assertEqual(centaur.presets[5].name, "Khan", "Centaur Khan preset")
assertEqual(centaur.presets[5].challengeLevel, "elite", "Centaur Khan challenge level")
for index = 1, #(centaur.spells or {}) do
    assert(entityRefs.spells[centaur.spells[index]], "Centaur spell ref resolves: " .. centaur.spells[index])
end
for presetIndex = 1, #(centaur.presets or {}) do
    local preset = centaur.presets[presetIndex]
    for spellIndex = 1, #(preset.spells or {}) do
        assert(entityRefs.spells[preset.spells[spellIndex]], "Centaur preset spell ref resolves: " .. preset.spells[spellIndex])
    end
    for slot, itemRef in pairs(preset.equipment or {}) do
        assert(entityRefs.items[itemRef], "Centaur equipment ref resolves for " .. slot .. ": " .. itemRef)
    end
end

local satyr = findUnit("satyr01")
assert(satyr, "Satyr Unit exists in Core")
assertEqual(satyr.name, "Satyr", "Satyr unit name")
assertEqual(satyr.challengeLevel, "minor", "Satyr challenge level")
assertEqual(satyr.creatureSize, "medium", "Satyr creature size")
assertEqual(satyr.creatureType, "humanoid", "Satyr creature type")
assertEqual(satyr.resources[1].initialValue, 120, "Satyr base Health")
assertEqual(satyr.stats[1].initialValue, 15, "Satyr base Armor")
assertEqual(satyr.stats[6].initialValue, 8, "Satyr base Dodge Chance")
assertEqual(satyr.stats[9].initialValue, 40, "Satyr Melee Attack Power")
assertEqual(satyr.stats[20].initialValue, 10, "Satyr base Shadow Resistance")
assertEqual(satyr.stats[23].initialValue, 35, "Satyr Movement Speed")
assertEqual(#(satyr.presets or {}), 4, "Satyr variant preset count")
assertEqual(satyr.presets[1].name, "Trickster", "Satyr Trickster preset")
assertEqual(satyr.presets[2].name, "Hellcaller", "Satyr Hellcaller preset")
assertEqual(satyr.presets[3].name, "Shadowstalker", "Satyr Shadowstalker preset")
assertEqual(satyr.presets[4].name, "Soulstealer", "Satyr Soulstealer preset")
assertEqual(satyr.presets[4].challengeLevel, "elite", "Satyr Soulstealer challenge level")
for index = 1, #(satyr.spells or {}) do
    assert(entityRefs.spells[satyr.spells[index]], "Satyr spell ref resolves: " .. satyr.spells[index])
end
for presetIndex = 1, #(satyr.presets or {}) do
    local preset = satyr.presets[presetIndex]
    for spellIndex = 1, #(preset.spells or {}) do
        assert(entityRefs.spells[preset.spells[spellIndex]], "Satyr preset spell ref resolves: " .. preset.spells[spellIndex])
    end
    for slot, itemRef in pairs(preset.equipment or {}) do
        assert(entityRefs.items[itemRef], "Satyr equipment ref resolves for " .. slot .. ": " .. itemRef)
    end
end

local harpy = findUnit("harpy001")
assert(harpy, "Harpy Unit exists in Core")
assertEqual(harpy.name, "Harpy", "Harpy unit name")
assertEqual(harpy.challengeLevel, "minor", "Harpy challenge level")
assertEqual(harpy.creatureSize, "medium", "Harpy creature size")
assertEqual(harpy.creatureType, "humanoid", "Harpy creature type")
assertEqual(harpy.attributes[1], "flying", "Harpy flying attribute")
assertEqual(harpy.resources[1].initialValue, 120, "Harpy base Health")
assertEqual(harpy.stats[1].initialValue, 10, "Harpy base Armor")
assertEqual(harpy.stats[6].initialValue, 10, "Harpy base Dodge Chance")
assertEqual(harpy.stats[9].initialValue, 40, "Harpy Melee Attack Power")
assertEqual(harpy.stats[23].initialValue, 40, "Harpy Movement Speed")
assertEqual(#(harpy.presets or {}), 4, "Harpy variant preset count")
assertEqual(harpy.presets[1].name, "Windcaller", "Harpy Windcaller preset")
assertEqual(harpy.presets[2].name, "Stormwitch", "Harpy Stormwitch preset")
assertEqual(harpy.presets[3].name, "Screecher", "Harpy Screecher preset")
assertEqual(harpy.presets[4].name, "Matriarch", "Harpy Matriarch preset")
assertEqual(harpy.presets[4].challengeLevel, "elite", "Harpy Matriarch challenge level")
for index = 1, #(harpy.spells or {}) do
    assert(entityRefs.spells[harpy.spells[index]], "Harpy spell ref resolves: " .. harpy.spells[index])
end
for presetIndex = 1, #(harpy.presets or {}) do
    local preset = harpy.presets[presetIndex]
    for spellIndex = 1, #(preset.spells or {}) do
        assert(entityRefs.spells[preset.spells[spellIndex]], "Harpy preset spell ref resolves: " .. preset.spells[spellIndex])
    end
    for slot, itemRef in pairs(preset.equipment or {}) do
        assert(entityRefs.items[itemRef], "Harpy equipment ref resolves for " .. slot .. ": " .. itemRef)
    end
end

local goblinTurret = findUnit("gobtur01")
assert(goblinTurret, "Goblin Turret Unit exists in Core")
assertEqual(goblinTurret.name, "Goblin Turret", "Goblin Turret unit name")
assertEqual(goblinTurret.challengeLevel, "minor", "Goblin Turret challenge level")
assertEqual(goblinTurret.creatureSize, "small", "Goblin Turret creature size")
assertEqual(goblinTurret.creatureType, "mechanical", "Goblin Turret creature type")
assertEqual(goblinTurret.resources[1].initialValue, 80, "Goblin Turret base Health")
assertEqual(goblinTurret.stats[1].initialValue, 20, "Goblin Turret base Armor")
assertEqual(goblinTurret.stats[3].initialValue, 5, "Goblin Turret base Ranged Hit")
assertEqual(goblinTurret.stats[10].initialValue, 35, "Goblin Turret base Ranged Attack Power")
assertEqual(goblinTurret.stats[13].initialValue, 5, "Goblin Turret base Ranged Crit Chance")
assertEqual(#(goblinTurret.presets or {}), 0, "Goblin Turret preset count")
assertEqual(#(goblinTurret.spells or {}), 1, "Goblin Turret spell count")
for index = 1, #(goblinTurret.spells or {}) do
    assert(entityRefs.spells[goblinTurret.spells[index]], "Goblin Turret spell ref resolves: " .. goblinTurret.spells[index])
end

local goblin = findUnit("gobnpc01")
assert(goblin, "Goblin Unit exists in Core")
assertEqual(goblin.name, "Goblin", "Goblin unit name")
assertEqual(goblin.challengeLevel, "minor", "Goblin challenge level")
assertEqual(goblin.creatureSize, "small", "Goblin creature size")
assertEqual(goblin.creatureType, "humanoid", "Goblin creature type")
assertEqual(goblin.resources[1].initialValue, 100, "Goblin base Health")
assertEqual(goblin.stats[1].initialValue, 10, "Goblin base Armor")
assertEqual(goblin.stats[6].initialValue, 5, "Goblin base Dodge Chance")
assertEqual(goblin.stats[9].initialValue, 30, "Goblin base Melee Attack Power")
assertEqual(goblin.stats[10].initialValue, 35, "Goblin base Ranged Attack Power")
assertEqual(goblin.stats[23].initialValue, 35, "Goblin Movement Speed")
assertEqual(#(goblin.presets or {}), 5, "Goblin variant preset count")
assertEqual(goblin.presets[1].name, "Bruiser", "Goblin Bruiser preset")
assertEqual(goblin.presets[2].name, "Sharpshooter", "Goblin Sharpshooter preset")
assertEqual(goblin.presets[3].name, "Sapper", "Goblin Sapper preset")
assertEqual(goblin.presets[4].name, "Engineer", "Goblin Engineer preset")
assertEqual(goblin.presets[5].name, "Foreman", "Goblin Foreman preset")
assertEqual(goblin.presets[5].challengeLevel, "elite", "Goblin Foreman challenge level")
for index = 1, #(goblin.spells or {}) do
    assert(entityRefs.spells[goblin.spells[index]], "Goblin spell ref resolves: " .. goblin.spells[index])
end
for presetIndex = 1, #(goblin.presets or {}) do
    local preset = goblin.presets[presetIndex]
    for spellIndex = 1, #(preset.spells or {}) do
        assert(entityRefs.spells[preset.spells[spellIndex]], "Goblin preset spell ref resolves: " .. preset.spells[spellIndex])
    end
    for slot, itemRef in pairs(preset.equipment or {}) do
        assert(entityRefs.items[itemRef], "Goblin equipment ref resolves for " .. slot .. ": " .. itemRef)
    end
end

local naga = findUnit("naga001")
assert(naga, "Naga Unit exists in Core")
assertEqual(naga.name, "Naga", "Naga unit name")
assertEqual(naga.challengeLevel, "minor", "Naga challenge level")
assertEqual(naga.creatureSize, "medium", "Naga creature size")
assertEqual(naga.creatureType, "humanoid", "Naga creature type")
assertEqual(naga.resources[1].initialValue, 130, "Naga base Health")
assertEqual(naga.stats[1].initialValue, 20, "Naga base Armor")
assertEqual(naga.stats[9].initialValue, 40, "Naga Melee Attack Power")
assertEqual(naga.stats[11].perLevelValue, 2.542373, "Naga Spell Power progression")
assertEqual(naga.stats[14].initialValue, 5, "Naga Spell Crit Chance")
assertEqual(naga.stats[18].initialValue, 10, "Naga Nature Resistance")
assertEqual(naga.stats[23].initialValue, 30, "Naga Movement Speed")
assertEqual(#(naga.presets or {}), 6, "Naga variant preset count")
assertEqual(naga.presets[1].name, "Tidehunter", "Naga Tidehunter preset")
assertEqual(naga.presets[2].name, "Priestess", "Naga Priestess preset")
assertEqual(naga.presets[3].name, "Enchantress", "Naga Enchantress preset")
assertEqual(naga.presets[4].name, "Siren", "Naga Siren preset")
assertEqual(naga.presets[5].name, "Sea Witch", "Naga Sea Witch preset")
assertEqual(naga.presets[6].name, "Myrmidon", "Naga Myrmidon preset")
assertEqual(naga.presets[5].challengeLevel, "elite", "Naga Sea Witch challenge level")
assertEqual(naga.presets[6].challengeLevel, "elite", "Naga Myrmidon challenge level")
for index = 1, #(naga.spells or {}) do
    assert(entityRefs.spells[naga.spells[index]], "Naga spell ref resolves: " .. naga.spells[index])
end
for presetIndex = 1, #(naga.presets or {}) do
    local preset = naga.presets[presetIndex]
    for spellIndex = 1, #(preset.spells or {}) do
        assert(entityRefs.spells[preset.spells[spellIndex]], "Naga preset spell ref resolves: " .. preset.spells[spellIndex])
    end
    for slot, itemRef in pairs(preset.equipment or {}) do
        assert(entityRefs.items[itemRef], "Naga equipment ref resolves for " .. slot .. ": " .. itemRef)
    end
end

local corruptor
for index = 1, #(voidwalker.presets or {}) do
    if voidwalker.presets[index].name == "Corruptor" then
        corruptor = voidwalker.presets[index]
        break
    end
end
assert(corruptor, "Voidwalker Corruptor preset exists")
for index = 1, #(corruptor.spells or {}) do
    assert(entityRefs.spells[corruptor.spells[index]], "Voidwalker Corruptor Spell ref resolves: " .. corruptor.spells[index])
end

assert(#(human.presets or {}) > 0, "Human has role presets")
local originalHuman = deepCopy(human)
local presetNames = {}
for index = 1, #human.presets do
    local preset = human.presets[index]
    assert(type(preset.name) == "string" and preset.name ~= "", "Preset has a display name")
    assert(not presetNames[preset.name], "Preset names are unique: " .. preset.name)
    presetNames[preset.name] = true

    local function verifyModifiers(actual, refKey, collection, label)
        local seen = {}
        for modifierIndex = 1, #(actual or {}) do
            local modifier = actual[modifierIndex]
            local ref = modifier[refKey]
            assert(type(ref) == "string" and ref ~= "", label .. " ref is present for " .. preset.name)
            assert(not seen[ref], label .. " refs are unique for " .. preset.name)
            seen[ref] = true
            assert(entityRefs[collection][ref], label .. " ref resolves: " .. ref)
            assert(type(modifier.percentBonus) == "number", label .. " percent bonus is numeric")
            assert(type(modifier.flatBonus) == "number", label .. " flat bonus is numeric")
        end
    end
    verifyModifiers(preset.statModifiers, "statRef", "stats", "stat")
    verifyModifiers(preset.resourceModifiers, "resourceRef", "resources", "resource")

    local effectiveSpells = Unit.ResolveEffectiveSpells(human, index)
    for spellIndex = 1, #effectiveSpells do
        assert(entityRefs.spells[effectiveSpells[spellIndex]], "Spell ref resolves: " .. effectiveSpells[spellIndex])
    end
    local effectiveEquipment = Unit.ResolveEffectiveEquipment(human, index)
    for slot, itemRef in pairs(effectiveEquipment) do
        assert(entityRefs.items[itemRef], "Equipment ref resolves for " .. slot .. ": " .. itemRef)
    end

    local resolvedPreset = Unit.ResolvePreset(human, index)
    for _, level in ipairs({ 1, 60 }) do
        local baseStats = Unit.ResolveStatValues(human, level)
        local baseResources = Unit.ResolveResourceValues(human, level)
        local actualStats = Unit.ApplyStatModifiers(baseStats, resolvedPreset)
        local actualResources = Unit.ApplyResourceModifiers(baseResources, resolvedPreset)
        for modifierIndex = 1, #(resolvedPreset.statModifiers or {}) do
            local modifier = resolvedPreset.statModifiers[modifierIndex]
            local baseRow = findRow(baseStats, "statRef", modifier.statRef)
            local actualRow = findRow(actualStats, "statRef", modifier.statRef)
            if baseRow and actualRow then
                local expected = baseRow.value * (1 + modifier.percentBonus / 100) + modifier.flatBonus
                assertNear(actualRow.value, expected, preset.name .. " stat modifier at level " .. level)
            end
        end
        for modifierIndex = 1, #(resolvedPreset.resourceModifiers or {}) do
            local modifier = resolvedPreset.resourceModifiers[modifierIndex]
            local baseRow = findRow(baseResources, "resourceRef", modifier.resourceRef)
            local actualRow = findRow(actualResources, "resourceRef", modifier.resourceRef)
            if baseRow and actualRow then
                local expected = math.max(0, baseRow.value * (1 + modifier.percentBonus / 100) + modifier.flatBonus)
                assertNear(actualRow.value, expected, preset.name .. " resource modifier at level " .. level)
            end
        end
    end
    assert(deepEqual(human, originalHuman), "Resolving presets does not mutate the base Human")
end

local noPresetStats = Unit.ResolveStatValues(human, 60)
local noPresetResources = Unit.ResolveResourceValues(human, 60)
local noPreset = Unit.ResolvePreset(human, 0)
assert(deepEqual(Unit.ApplyStatModifiers(noPresetStats, noPreset), noPresetStats), "No preset keeps base Human stats")
assert(deepEqual(Unit.ApplyResourceModifiers(noPresetResources, noPreset), noPresetResources), "No preset keeps base Human resources")
assert(deepEqual(Unit.ResolveEffectiveSpells(human, 0), human.spells), "No preset keeps base Human spells")
assert(deepEqual(Unit.ResolveEffectiveEquipment(human, 0), {
    mainHandWeapon = "f82db71a:stwswd01",
}), "No preset keeps base Human equipment")

local serialized = Unit.FromTable(human):ToTable()
assertEqual(#serialized.presets, #human.presets, "Preset count survives serialization")
for index = 1, #serialized.presets do
    assert(deepEqual(serialized.presets[index].spells, human.presets[index].spells), "Preset spells survive serialization at index " .. index)
    assert(deepEqual(serialized.presets[index].equipment, human.presets[index].equipment), "Preset equipment survives serialization at index " .. index)
end

print("NpcRolePresetsTest passed")
