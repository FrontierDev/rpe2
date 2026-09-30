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

local function findUnit(units, petRef)
    for index = 1, #(units or {}) do
        local unit = units[index]
        if unit and tostring(unit.petRef or "") == petRef then
            return unit
        end
    end
    return nil
end

local function countUnitsByRegistry(units, registryID, summonedByEventID)
    local count = 0
    for index = 1, #(units or {}) do
        local unit = units[index]
        if unit
            and tostring(unit.registryID or "") == registryID
            and (summonedByEventID == nil or tonumber(unit.summonedByEventID) == summonedByEventID)
        then
            count = count + 1
        end
    end
    return count
end

local dataset
local datasetActive = true
local Addon = {
    Internal = {
        Comms = {
            Operations = {
                GetOpcode = function()
                    return 1
                end,
                Get = function()
                    return nil
                end,
            },
            ResourceSync = {
                CloneResources = function(_, resources)
                    return resources or {}
                end,
            },
        },
        Database = { Classes = {} },
        Registry = {
            GetActivatedDatasets = function()
                return datasetActive and { dataset } or {}
            end,
            ResolveUnitDefinition = function(_, unitRef)
                if not datasetActive or type(dataset) ~= "table" then
                    return nil, nil
                end
                for index = 1, #(dataset.units or {}) do
                    local unit = dataset.units[index]
                    if unit and ("test:" .. tostring(unit.id or "")) == tostring(unitRef or "") then
                        return dataset, unit
                    end
                end
                return nil, nil
            end,
        },
        Ruleset = {
            GetRulesetRuleValueByKey = function(_, _, _, fallback)
                return fallback
            end,
        },
    },
    Utils = {
        Common = {
            NormalizeName = function(value)
                return tostring(value or "")
            end,
            GetPlayerName = function()
                return "Host"
            end,
            GetNow = function()
                return 1
            end,
        },
    },
    Server = {},
    Client = {},
}

local function loadAddonFile(path)
    local chunk, loadError = loadfile(path)
    assert(chunk, loadError)
    chunk(nil, Addon)
end

loadAddonFile("core/classes/Unit.lua")
loadAddonFile("core/classes/EventUnit.lua")
loadAddonFile("core/classes/EventUnitResourcePipeline.lua")
loadAddonFile("core/classes/Event.lua")
loadAddonFile("core/classes/Spell.lua")
loadAddonFile("server/server_Event.lua")
loadAddonFile("server/server_EventVariants.lua")
loadAddonFile("server/server_EventSpellEquipmentVariants.lua")

local Classes = Addon.Internal.Database.Classes
local Unit = Classes.Unit
local Event = Classes.Event
local EventUnit = Classes.EventUnit
local Spell = Classes.Spell
local Server = Addon.Server

local wolfUnit = Unit:New({
    id = "wolf-unit",
    name = "Wolf",
    mainHandWeapon = "test:claw",
    stats = {
        { statRef = "test:power", initialValue = 10, perLevelValue = 1 },
    },
}):ToTable()
local catUnit = Unit:New({
    id = "cat-unit",
    name = "Cat",
    stats = {
        { statRef = "test:power", initialValue = 20, perLevelValue = 1 },
    },
}):ToTable()
local guardianUnit = Unit:New({
    id = "guardian-unit",
    name = "Guardian",
    stats = {
        { statRef = "test:power", initialValue = 30, perLevelValue = 1 },
    },
}):ToTable()
local impUnit = Unit:New({
    id = "imp-unit",
    name = "Imp",
    stats = {
        { statRef = "test:power", initialValue = 40, perLevelValue = 1 },
    },
}):ToTable()
local felguardUnit = Unit:New({
    id = "felguard-unit",
    name = "Felguard",
    stats = {
        { statRef = "test:power", initialValue = 50, perLevelValue = 1 },
    },
}):ToTable()

dataset = {
    id = "test",
    name = "Summon test",
    units = { wolfUnit, catUnit, guardianUnit, impUnit, felguardUnit },
    pets = {
        { id = "wolf", unitRef = "test:wolf-unit" },
        { id = "cat", unitRef = "test:cat-unit" },
        { id = "broken", unitRef = "test:missing-unit" },
    },
}

-- Keep the test focused on selected-pet materialization rather than the
-- resource/stat baseline implementation exercised by other tests.
EventUnit.BuildUnitDerivedStats = function()
    return {
        { statRef = "test:power", value = 10, currentValue = 10 },
    }
end
EventUnit.BuildUnitDerivedResources = function()
    return {}
end

Server.EventState = Event:New({
    id = "summon-test",
    name = "Summon test",
    hostName = "Host",
    active = true,
    level = 1,
    units = {
        EventUnit:New({
            eventID = 1,
            isPlayer = true,
            name = "Host",
            ownerID = "Host",
            controllerID = "Host",
            team = 1,
            petRef = "test:wolf",
            petStats = {
                -- Runtime rows are complete rows: Unit base (10) plus the
                -- selected pet's equipment/stat bonus (99).
                { statRef = "test:power", value = 109, currentValue = 109 },
            },
        }),
        EventUnit:New({
            eventID = 2,
            isPlayer = true,
            name = "Remote",
            ownerID = "Remote",
            controllerID = "Remote",
            team = 1,
            petRef = "test:cat",
            petStats = {
                { statRef = "test:power", value = 97, currentValue = 97 },
            },
        }),
        EventUnit:New({
            eventID = 3,
            name = "Old wolf",
            team = 1,
            petRef = "test:wolf",
            summonedByEventID = 1,
            controllerID = 1,
        }),
    },
})
Server.BroadcastEventDeltaBatch = function(self, entries)
    self.lastSummonDelta = entries
end

local hostPet, hostError = Server:SummonEventPetUnit(Server.EventState.units[1], nil, {
    ownerID = "Host",
})
assertTrue(hostPet ~= nil, "local player with a selected pet can summon")
assertEqual(hostError, nil, "local summon does not return an error")
assertEqual(hostPet.registryID, "test:wolf-unit", "summon resolves the selected Pet unitRef")
assertEqual(hostPet.petRef, "test:wolf", "summon carries the selected petRef")
assertEqual(hostPet.summonedByEventID, 1, "summon carries the caster event ID")
assertEqual(hostPet.controllerID, 1, "summon is controlled by the caster")
assertEqual(hostPet.ownerID, "Host", "summon carries the caster owner")
assertEqual(hostPet.isPet, true, "profile summon uses the shared pet-role representation")
assertEqual(hostPet.stats[1].value, 109, "selected pet runtime stat modifications are applied")
assertEqual(hostPet.mainHandWeapon, "test:claw", "selected pet equipment is applied")
assertEqual(findUnit(Server.EventState.units, "test:wolf"), hostPet, "re-summoning replaces the previous profile pet")

local remotePet, remoteError = Server:SummonEventPetUnit(Server.EventState.units[2], nil, {
    ownerID = "Remote",
})
assertTrue(remotePet ~= nil, "remote player with a selected pet can summon")
assertEqual(remoteError, nil, "remote summon does not return an error")
assertEqual(remotePet.registryID, "test:cat-unit", "remote summon uses the remote selected Pet unitRef")
assertEqual(remotePet.petRef, "test:cat", "remote summon carries the remote petRef")
assertEqual(remotePet.summonedByEventID, 2, "remote summon carries the remote caster event ID")
assertEqual(remotePet.controllerID, 2, "remote summon is controlled by the remote caster")
assertEqual(remotePet.ownerID, "Remote", "remote summon carries the remote owner")
assertEqual(remotePet.stats[1].value, 97, "remote runtime pet stats are applied")
assertTrue(findUnit(Server.EventState.units, "test:wolf") == hostPet, "host pet identity does not leak into remote summon")

local hostGuardianOne, hostGuardianOneError = Server:SummonEventControlledUnit(Server.EventState.units[1], "test:guardian-unit", {
    ownerID = "Host",
})
assertTrue(hostGuardianOne ~= nil, "Summon Unit resolves its explicit Unit reference")
assertEqual(hostGuardianOneError, nil, "generic summon does not return an error")
assertEqual(hostGuardianOne.registryID, "test:guardian-unit", "generic summon uses the authored Unit reference")
assertEqual(hostGuardianOne.petRef, nil, "generic summon has no profile pet identity")
assertEqual(hostGuardianOne.controllerID, 1, "generic summon is controlled by the caster's player EventUnit")
assertEqual(hostGuardianOne.ownerID, "Host", "generic summon uses the controlling player's normalized owner")
assertEqual(hostGuardianOne.summonedByEventID, 1, "generic summon records the caster EventUnit")
assertTrue(findUnit(Server.EventState.units, "test:wolf") == hostPet, "generic summon does not replace the profile pet")

local explicitImp, explicitImpError = Server:SummonEventPetUnit(Server.EventState.units[1], "test:imp-unit", {
    ownerID = "Host",
})
assertTrue(explicitImp ~= nil, "explicit Imp Unit can be summoned as a pet")
assertEqual(explicitImpError, nil, "explicit Imp summon does not return an error")
assertEqual(explicitImp.registryID, "test:imp-unit", "explicit pet summon uses the authored Unit")
assertEqual(explicitImp.petRef, nil, "explicit pet summon does not invent a profile Pet reference")
assertEqual(explicitImp.isPet, true, "explicit pet summon uses the shared pet-role representation")
assertEqual(explicitImp.controllerID, 1, "explicit pet summon uses the profile caster controller")
assertEqual(countUnitsByRegistry(Server.EventState.units, "test:imp-unit", 1), 1, "explicit Imp summon creates one pet unit")
assertTrue(findUnit(Server.EventState.units, "test:wolf") == nil, "explicit pet summon replaces the profile pet")

local explicitFelguard, explicitFelguardError = Server:SummonEventPetUnit(Server.EventState.units[1], "test:felguard-unit", {
    ownerID = "Host",
})
assertTrue(explicitFelguard ~= nil, "explicit Felguard Unit can be summoned as a pet")
assertEqual(explicitFelguardError, nil, "explicit Felguard summon does not return an error")
assertEqual(explicitFelguard.registryID, "test:felguard-unit", "explicit Felguard summon uses the authored Unit")
assertEqual(explicitFelguard.isPet, true, "explicit Felguard uses the shared pet-role representation")
assertEqual(countUnitsByRegistry(Server.EventState.units, "test:imp-unit", 1), 0, "Felguard replaces the previous explicit pet")
assertEqual(countUnitsByRegistry(Server.EventState.units, "test:felguard-unit", 1), 1, "Felguard leaves one active pet unit")
assertTrue(
    Event.IsPlayerSharedTurnPet(Server.EventState.units, explicitFelguard),
    "explicit Felguard is hidden from the independent event-unit portrait list"
)
local hostPageUnits = Event.GetUnitsForPage(Server.EventState.units, 1, 20)
for index = 1, #hostPageUnits do
    assertTrue(hostPageUnits[index] ~= explicitFelguard, "explicit Felguard is not an independent event portrait")
end

local remoteExplicitImp, remoteExplicitImpError = Server:SummonEventPetUnit(Server.EventState.units[2], "test:imp-unit", {
    ownerID = "Remote",
})
assertTrue(remoteExplicitImp ~= nil, "remote explicit pet summon succeeds")
assertEqual(remoteExplicitImpError, nil, "remote explicit pet summon does not return an error")
assertEqual(remoteExplicitImp.registryID, "test:imp-unit", "remote explicit summon uses its authored Unit")
assertEqual(remoteExplicitImp.controllerID, 2, "remote explicit summon uses the remote caster controller")
assertEqual(remoteExplicitImp.ownerID, "Remote", "remote explicit summon uses the remote caster owner")

local invalidExplicitPet, invalidExplicitPetError = Server:SummonEventPetUnit(
    Server.EventState.units[1],
    "test:missing-unit",
    {}
)
assertEqual(invalidExplicitPet, nil, "an invalid explicit pet Unit fails")
assertEqual(invalidExplicitPetError, "unit-unavailable", "an invalid explicit pet Unit reports its error")
assertEqual(countUnitsByRegistry(Server.EventState.units, "test:felguard-unit", 1), 1, "an invalid explicit pet does not replace the current pet")
local malformedExplicitPet, malformedExplicitPetError = Server:SummonEventPetUnit(
    Server.EventState.units[1],
    "felguard-unit",
    {}
)
assertEqual(malformedExplicitPet, nil, "a malformed explicit pet Unit fails")
assertEqual(malformedExplicitPetError, "unit-ref-malformed", "a malformed explicit pet Unit reports its error")
assertEqual(countUnitsByRegistry(Server.EventState.units, "test:felguard-unit", 1), 1, "a malformed explicit pet does not replace the current pet")

local hostGuardianTwo, hostGuardianTwoError = Server:SummonEventControlledUnit(Server.EventState.units[1], "test:guardian-unit", {
    ownerID = "Host",
})
assertTrue(hostGuardianTwo ~= nil, "a caster can summon a second generic Unit")
assertEqual(hostGuardianTwoError, nil, "the second generic summon does not return an error")
assertTrue(hostGuardianTwo.eventID ~= hostGuardianOne.eventID, "generic summons receive distinct EventUnit IDs")
assertEqual(countUnitsByRegistry(Server.EventState.units, "test:guardian-unit", 1), 2, "generic summons coexist for one caster")
assertTrue(findUnit(Server.EventState.units, "test:wolf") == hostPet, "coexisting generic summons leave the profile pet intact")

local remoteGuardian, remoteGuardianError = Server:SummonEventControlledUnit(Server.EventState.units[2], "test:guardian-unit", {
    ownerID = "Remote",
})
assertTrue(remoteGuardian ~= nil, "a remote player can summon a generic Unit")
assertEqual(remoteGuardianError, nil, "remote generic summon does not return an error")
assertEqual(remoteGuardian.controllerID, 2, "remote generic summon uses the remote controller")
assertEqual(remoteGuardian.ownerID, "Remote", "remote generic summon uses the remote owner")
assertEqual(remoteGuardian.summonedByEventID, 2, "remote generic summon records the remote caster")

local malformedUnit, malformedError = Server:SummonEventControlledUnit(Server.EventState.units[1], "guardian-unit", {})
assertEqual(malformedUnit, nil, "an unqualified generic Unit reference fails")
assertEqual(malformedError, "unit-ref-malformed", "an unqualified generic Unit reference reports its error")
local unresolvedUnit, unresolvedError = Server:SummonEventControlledUnit(Server.EventState.units[1], "test:missing-unit", {})
assertEqual(unresolvedUnit, nil, "an unresolved generic Unit reference fails")
assertEqual(unresolvedError, "unit-unavailable", "an unresolved generic Unit reference reports its error")

local selectedPetRef = "test:wolf"
Addon.Internal.Profile = {
    GetPetRef = function()
        return selectedPetRef
    end,
    IsPetSelectionValid = function()
        return true
    end,
}
Addon.Common = Addon.Utils.Common
Addon.Client.CanControlEventUnit = function()
    return true
end
loadAddonFile("client/ui/widgets/widget_ActionBar_Control.lua")
local actionBarWidget = Addon.Client.UI.ActionBarWidget
local actionBarInstance = setmetatable({}, actionBarWidget)
local actionBarContext = {
    eventState = Server.EventState,
    localEventUnit = Server.EventState.units[1],
}
assertEqual(
    actionBarInstance:ResolveControllablePetUnit(actionBarContext),
    explicitFelguard,
    "action bar resolves the local explicit-unit pet"
)
selectedPetRef = "test:not-summoned"
assertEqual(
    actionBarInstance:ResolveControllablePetUnit(actionBarContext),
    explicitFelguard,
    "action bar keeps resolving an authored pet when the selected profile ref is absent"
)

local invalidCaster = EventUnit:New({ eventID = 4, isPlayer = true, ownerID = "Invalid", controllerID = "Invalid" })
local invalidPet, invalidError = Server:SummonEventPetUnit(invalidCaster, nil, {})
assertEqual(invalidPet, nil, "missing selected pet fails")
assertEqual(invalidError, "selected-pet-missing", "missing selected pet reports an explicit error")

local brokenCaster = EventUnit:New({
    eventID = 4,
    isPlayer = true,
    ownerID = "Broken",
    controllerID = "Broken",
    petRef = "test:broken",
})
local brokenPet, brokenError = Server:SummonEventPetUnit(brokenCaster, nil, {})
assertEqual(brokenPet, nil, "a Pet with a missing Unit fails")
assertEqual(brokenError, "selected-pet-unit-unavailable", "missing Pet Unit reports an explicit error")

datasetActive = false
local deactivatedPet, deactivatedError = Server:SummonEventPetUnit(Server.EventState.units[1], nil, {})
assertEqual(deactivatedPet, nil, "a deactivated Pet dataset fails")
assertEqual(deactivatedError, "selected-pet-unavailable", "deactivated Pet reports an explicit error")
local deactivatedUnit, deactivatedUnitError = Server:SummonEventControlledUnit(Server.EventState.units[1], "test:guardian-unit", {})
assertEqual(deactivatedUnit, nil, "a deactivated Unit dataset fails")
assertEqual(deactivatedUnitError, "unit-unavailable", "a deactivated Unit reports an explicit error")

local summonUnitSpell = Spell:New({
    id = "summon-unit-spell",
    components = {
        {
            castPhase = "on_cast_end",
            target = { type = "caster" },
            effect = {
                type = "summon_unit",
                unitRef = "test:guardian-unit",
                targetEvents = { "damage_taken" },
            },
        },
    },
})
local serializedSummonUnitSpell = summonUnitSpell:ToTable()
assertEqual(
    serializedSummonUnitSpell.components[1].effect.unitRef,
    "test:guardian-unit",
    "Summon Unit serializes its explicit Unit reference"
)
local deserializedSummonUnitSpell = Spell:FromTable(serializedSummonUnitSpell)
assertEqual(
    deserializedSummonUnitSpell.components[1].effect.unitRef,
    "test:guardian-unit",
    "Summon Unit deserializes its explicit Unit reference"
)
local malformedSummonUnitSpell = Spell:New({
    components = {{ effect = { type = "summon_unit", unitRef = "guardian-unit" } }},
})
assertEqual(
    malformedSummonUnitSpell.components[1].effect.unitRef,
    nil,
    "Summon Unit normalization rejects an unqualified Unit reference"
)

local coreFile = assert(io.open("data/default/core.lua", "r"))
local coreText = coreFile:read("*a")
coreFile:close()
local summonPetDefinition = coreText:match('type = "summon_pet".-key = "9b68b6a9"')
assertTrue(summonPetDefinition ~= nil, "Core contains the Summon Pet definition")
assertTrue(summonPetDefinition:find("unitRef", 1, true) == nil, "Core Summon Pet has no authored Unit reference")

local explicitSummonPetSpell = Spell:New({
    id = "summon-explicit-pet-spell",
    components = {{
        effect = { type = "summon_pet", unitRef = "test:imp-unit" },
    }},
})
assertEqual(
    explicitSummonPetSpell:ToTable().components[1].effect.unitRef,
    "test:imp-unit",
    "Summon Pet serializes its optional explicit Unit reference"
)
local malformedSummonPetSpell = Spell:New({
    components = {{ effect = { type = "summon_pet", unitRef = "imp-unit" } }},
})
assertEqual(
    malformedSummonPetSpell.components[1].effect.unitRef,
    "imp-unit",
    "Summon Pet normalization preserves a malformed explicit Unit reference for server validation"
)
local legacyPetModeSpell = Spell:New({
    components = {{ effect = { type = "summon_unit", unitRef = "test:guardian-unit", summonAsPet = true } }},
})
assertEqual(
    legacyPetModeSpell.components[1].effect.summonAsPet,
    nil,
    "Summon Unit no longer serializes the removed pet mode"
)

print("SummonPetProfileTest passed")
