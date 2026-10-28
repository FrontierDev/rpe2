local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local scheduled = 0
local chatLines = 0

DEFAULT_CHAT_FRAME = {
    AddMessage = function()
        chatLines = chatLines + 1
    end,
}
C_Timer = {
    After = function(_, callback)
        scheduled = scheduled + 1
        callback()
    end,
}

local Addon = {
    Name = "RPEngine2",
    Debug = {},
    Client = {
        UI = {},
        HideTargetingWidget = function() end,
        InvalidatePendingSpellTargetingDisplayState = function() end,
    },
    Internal = {
        Registry = {},
    },
    Utils = {
        Common = {},
        Lookup = {},
    },
}
local chunk, loadError = loadfile("core/debug/FormattedDebug.lua")
assert(chunk, loadError)
chunk("RPEngine2", Addon)

assertEqual(Addon.Debug.IsLevelEnabled("info"), false, "INFO diagnostics are disabled by default")
assertEqual(Addon.Debug.IsLevelEnabled("warn"), true, "WARN diagnostics remain enabled by default")
assertEqual(Addon.Debug.IsLevelEnabled("error"), true, "ERROR diagnostics remain enabled by default")
assertEqual(Addon.Debug.Info("hidden"), false, "disabled INFO diagnostics do not emit")
assertEqual(scheduled, 0, "disabled INFO diagnostics do not schedule chat work")
assertEqual(chatLines, 0, "disabled INFO diagnostics do not write chat")

assertEqual(Addon.Debug.SetLevelEnabled("info", true), true, "INFO can be enabled explicitly")
assertEqual(Addon.Debug.Info("visible"), true, "explicit INFO diagnostics emit")
assertEqual(scheduled, 1, "enabled INFO diagnostics schedule one chat line")
assertEqual(chatLines, 1, "enabled INFO diagnostics write one chat line")

assertEqual(Addon.Debug.SetLevelEnabled("info", false), true, "INFO can be disabled explicitly")
assertEqual(Addon.Debug.Info("hidden again"), false, "disabled INFO diagnostics stop immediately")
assertEqual(scheduled, 1, "disabled INFO diagnostics do not schedule more chat work")

local targetingChunk, targetingError = loadfile("client/client_Targeting.lua")
assert(targetingChunk, targetingError)
targetingChunk("RPEngine2", Addon)
Addon.Client.PendingSpellTargeting = { spellRef = "test:spell" }
Addon.Client:CancelSpellTargeting("cancelled")
assertEqual(Addon.Client.PendingSpellTargeting, nil, "targeting cancellation still clears pending state")
assertEqual(chatLines, 1, "targeting cancellation does not emit a debug chat line")

print("DebugOutputPolicyTest passed")
