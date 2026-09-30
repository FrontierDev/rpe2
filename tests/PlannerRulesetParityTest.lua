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

local savedRulesetRoot = rawget(_G, "RPEngineRulesetDB")
local savedUnitFullName = UnitFullName
local savedUnitName = UnitName
local savedGetRealmName = GetRealmName

UnitFullName = function()
    return "PlannerTester", "TestRealm"
end
UnitName = nil
GetRealmName = function()
    return "TestRealm"
end

local function channelRules()
    local values = {}
    local definitions = {
        { "Main Action", true, false },
        { "Bonus Action", true, false },
        { "Buff Action", true, false },
        { "Free Action", false, false },
        { "Reaction", true, true },
    }
    for channelId = 1, #definitions do
        local definition = definitions[channelId]
        values[("cooldown_channel_%d_name"):format(channelId)] = definition[1]
        values[("cooldown_channel_%d_triggers_gcd"):format(channelId)] = definition[2]
        values[("cooldown_channel_%d_can_use_off_turn"):format(channelId)] = definition[3]
    end
    return values
end

local coreRuleset = {
    id = "core",
    name = "Core",
    rules = { action_economy = channelRules() },
}

local Addon = {
    Client = {
        AutopilotPlanner = {
            Step = function(state)
                state.observed = state.capture()
                return true
            end,
        },
    },
    Internal = { Database = { Classes = {} }, Ruleset = {} },
}

loadAddonFile("core/internal/ruleset/Rules.lua", Addon)
loadAddonFile("core/internal/database/Database.lua", Addon)
loadAddonFile("core/internal/ruleset/Ruleset.lua", Addon)

local Database = Addon.Internal.Database
local Ruleset = Addon.Internal.Ruleset
local baseGetDatasetByID = Database.GetDatasetByID
local baseListActivatedDatasetIds = Database.ListActivatedDatasetIds
local baseGetRulesetByID = Database.GetRulesetByID
local baseGetActiveRulesetId = Database.GetActiveRulesetId

loadAddonFile("client/autopilot/PlannerSnapshotUnitsPerformance.lua", Addon)

assertEqual(Database.GetDatasetByID, baseGetDatasetByID, "planner does not replace dataset lookup")
assertEqual(Database.ListActivatedDatasetIds, baseListActivatedDatasetIds, "planner does not replace dataset activation lookup")
assertEqual(Database.GetRulesetByID, baseGetRulesetByID, "planner does not replace ruleset lookup")
assertEqual(Database.GetActiveRulesetId, baseGetActiveRulesetId, "planner does not replace active ruleset selection")

local function installRoot(activeByChar)
    local root = {
        _schema = 1,
        rulesets = { core = coreRuleset },
        activeByChar = activeByChar or {},
        nextId = 2,
    }
    rawset(_G, "RPEngineRulesetDB", root)
    Database.Rulesets = root
    return root
end

local function captureRuntime()
    local result = { activeRulesetId = Database.GetActiveRulesetId(), channels = {} }
    for channelId = 1, 5 do
        local channel = Ruleset.GetCooldownChannel(channelId)
        result.channels[channelId] = {
            id = channel and channel.id,
            name = channel and channel.name,
            triggersGCD = channel and channel.triggersGCD,
            canUseOffTurn = channel and channel.canUseOffTurn,
            enabled = channel and channel.enabled,
        }
    end
    return result
end

local function capturePlanner()
    local state = { phase = "resolve-ruleset", capture = captureRuntime }
    assertTrue(Addon.Client.AutopilotPlanner.Step(state), "planner scope completes")
    return state.observed
end

local function assertParity(expected, actual, message)
    assertEqual(actual.activeRulesetId, expected.activeRulesetId, message .. " active ruleset")
    for channelId = 1, 5 do
        local expectedChannel = expected.channels[channelId]
        local actualChannel = actual.channels[channelId]
        assertEqual(actualChannel.id, expectedChannel.id, message .. " channel ID " .. channelId)
        assertEqual(actualChannel.name, expectedChannel.name, message .. " channel name " .. channelId)
        assertEqual(actualChannel.triggersGCD, expectedChannel.triggersGCD, message .. " channel GCD " .. channelId)
        assertEqual(actualChannel.canUseOffTurn, expectedChannel.canUseOffTurn, message .. " channel off-turn " .. channelId)
        assertEqual(actualChannel.enabled, expectedChannel.enabled, message .. " channel enabled " .. channelId)
    end
end

local characterKey = "PlannerTester-TestRealm"
installRoot({ [characterKey] = "core" })
local runtime = captureRuntime()
local planner = capturePlanner()
assertParity(runtime, planner, "exact current-character selection")
assertEqual(planner.channels[4].name, "Free Action", "Core channel 4 remains Free Action")
assertEqual(planner.channels[5].name, "Reaction", "Core channel 5 remains Reaction")

local migratedRoot = installRoot({ ["unknown-player"] = "core" })
local migratedPlanner = capturePlanner()
assertEqual(migratedPlanner.activeRulesetId, "core", "planner uses canonical unknown-player fallback")
assertEqual(migratedRoot.activeByChar[characterKey], "core", "planner preserves canonical unknown-player migration")
assertEqual(migratedRoot.activeByChar["unknown-player"], nil, "canonical migration clears the fallback entry")
assertParity(captureRuntime(), migratedPlanner, "unknown-player migration")

installRoot({})
assertParity(captureRuntime(), capturePlanner(), "no active ruleset")

rawset(_G, "RPEngineRulesetDB", nil)
Database.Rulesets = nil
local uninitializedPlanner = capturePlanner()
assertTrue(type(Database.Rulesets) == "table", "planner uses canonical ruleset-root initialization")
assertParity(captureRuntime(), uninitializedPlanner, "uninitialized ruleset root")

local replacedRoot = installRoot({ [characterKey] = "core" })
Database.Rulesets = { rulesets = {}, activeByChar = {} }
local replacedPlanner = capturePlanner()
assertEqual(Database.Rulesets, replacedRoot, "planner uses canonical ruleset-root replacement recovery")
assertParity(captureRuntime(), replacedPlanner, "replaced ruleset root")

rawset(_G, "RPEngineRulesetDB", savedRulesetRoot)
Database.Rulesets = savedRulesetRoot
UnitFullName = savedUnitFullName
UnitName = savedUnitName
GetRealmName = savedGetRealmName

print("PlannerRulesetParityTest passed")
