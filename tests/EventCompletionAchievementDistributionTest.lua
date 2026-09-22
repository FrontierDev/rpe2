local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local function loadAddonFile(path, addon)
    local chunk, loadError = loadfile(path)
    assert(chunk, loadError)
    chunk("RPEngine2", addon)
end

local processed = 0
local Addon = {
    Client = {
        Achievements = {},
    },
    Internal = {},
    Utils = {},
}

loadAddonFile("client/client_Achievements.lua", Addon)
local Achievements = Addon.Client.Achievements
Achievements.ProcessTrigger = function(_, trigger, context)
    processed = processed + 1
    return { trigger = trigger, context = context }
end

local skipped = Achievements:HandleRPEEventComplete({
    id = "skip-distribution",
    distributeEndRewards = false,
}, "ended")
assertEqual(processed, 0, "skipped distribution does not process event-complete criteria")
assertEqual(skipped.skipped, true, "skipped distribution is reported as skipped")

local completed = Achievements:HandleRPEEventComplete({
    id = "distributed",
    distributeEndRewards = true,
}, "ended")
assertEqual(processed, 1, "distributed event processes event-complete criteria")
assertEqual(completed.trigger, "rpe_event_complete", "normal completion uses the event-complete trigger")

print("EventCompletionAchievementDistributionTest passed")
