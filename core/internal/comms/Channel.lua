local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Comms = Addon.Internal.Comms or {}
Addon.Utils = Addon.Utils or {}

-- Forward Declarations
local Comms = Addon.Internal.Comms
local Diagnostics = Addon.Internal.Comms.Diagnostics or {}
local Operations = Addon.Internal.Comms.Operations or {}
local Tasks = Addon.Internal.Tasks or {}
local Common = Addon.Utils.Common or {}

local function findChannelIdInList(channelName)
    if type(channelName) ~= "string" or channelName == "" or not GetChannelList then
        return nil
    end

    local channels = { GetChannelList() }
    for index = 1, #channels, 2 do
        local listedChannelId = tonumber(channels[index])
        local listedChannelName = tostring(channels[index + 1] or "")
        if listedChannelId and listedChannelId > 0 and listedChannelName == channelName then
            return listedChannelId
        end
    end

    return nil
end

-- returns the channelId if the channel is joined, otherwise nil
function Comms:ResolveChannelId(channelName)
    if type(channelName) ~= "string" or channelName == "" or not GetChannelName then
        return findChannelIdInList(channelName)
    end

    local resolvedChannelId = GetChannelName(channelName)
    local channelId = tonumber(resolvedChannelId)
    if channelId and channelId > 0 then
        return channelId
    end

    return findChannelIdInList(channelName)
end

-- joins the specified channel and returns the channelId if successful, otherwise nil
function Comms:JoinChannel(channelName)
    if type(channelName) ~= "string" or channelName == "" then
        return nil
    end

    if JoinChannelByName then
        JoinChannelByName(channelName, nil, nil, true)
    elseif ChatFrame1EditBox and ChatEdit_SendText then
        ChatFrame1EditBox:SetText("/join " .. channelName)
        ChatEdit_SendText(ChatFrame1EditBox, 0)
    end

    local channelId = self:ResolveChannelId(channelName)
    if Diagnostics.RecordChannelJoin then
        Diagnostics:RecordChannelJoin(channelName, channelId)
    end
    return channelId
end

-- leaves the specified channel and returns true if successful, otherwise false
function Comms:LeaveChannel(channelName)
    if type(channelName) ~= "string" or channelName == "" then
        return false
    end

    if LeaveChannelByName then
        LeaveChannelByName(channelName)
    elseif ChatFrame1EditBox and ChatEdit_SendText then
        ChatFrame1EditBox:SetText("/leave " .. channelName)
        ChatEdit_SendText(ChatFrame1EditBox, 0)
    else
        return false
    end

    if Diagnostics.RecordChannelLeave then
        Diagnostics:RecordChannelLeave(channelName)
    end
    return true
end

-- Immediate local echo in Core.lua intentionally performs packet parsing,
-- duplicate bookkeeping, chunk assembly, and argument deserialization before
-- Operations:Dispatch() is reached. For spellcast lifecycle opcodes only, move
-- that final handler dispatch onto the existing task queue so an outbound cast
-- does not also execute the complete inbound server/client handler stack on the
-- same frame. EVENT_START / EVENT_UNITS / EVENT_STATE remain synchronous.
local DEFERRED_LOCAL_SPELLCAST_KEYS = {
    SPELLCAST_START = true,
    SPELLCAST_COMPLETE = true,
    SPELLCAST_INTERRUPT = true,
}

local function normalizePlayerName(value)
    if type(Common.NormalizeName) == "function" then
        return Common.NormalizeName(value)
    end
    return tostring(value or "")
end

local function isDeferredLocalSpellcast(operation, sender, distribution)
    if distribution ~= "CHANNEL" or type(operation) ~= "table" then
        return false
    end
    if DEFERRED_LOCAL_SPELLCAST_KEYS[tostring(operation.key or "")] ~= true then
        return false
    end

    local localPlayerName = normalizePlayerName(
        type(Common.GetPlayerName) == "function" and Common.GetPlayerName() or nil
    )
    if localPlayerName == "" then
        return false
    end
    return normalizePlayerName(sender) == localPlayerName
end

Comms.PendingLocalSpellcastDispatchCount = math.max(
    0,
    math.floor(tonumber(Comms.PendingLocalSpellcastDispatchCount) or 0)
)

function Comms:GetPendingLocalSpellcastDispatchCount()
    return math.max(0, math.floor(tonumber(self.PendingLocalSpellcastDispatchCount) or 0))
end

function Comms:HasPendingLocalSpellcastDispatch()
    return self:GetPendingLocalSpellcastDispatchCount() > 0
end

if Operations._rpeDeferredLocalSpellcastDispatchInstalled ~= true
    and type(Operations.Dispatch) == "function"
then
    local baseDispatch = Operations.Dispatch

    function Operations:Dispatch(opcode, arguments, sender, distribution, target, message)
        local operation = type(self.Get) == "function" and self:Get(opcode) or nil
        if not isDeferredLocalSpellcast(operation, sender, distribution)
            or type(Tasks.Enqueue) ~= "function"
        then
            return baseDispatch(self, opcode, arguments, sender, distribution, target, message)
        end

        Comms.PendingLocalSpellcastDispatchCount = Comms:GetPendingLocalSpellcastDispatchCount() + 1
        Tasks:Enqueue(function(
            queuedOperations,
            queuedOpcode,
            queuedArguments,
            queuedSender,
            queuedDistribution,
            queuedTarget,
            queuedMessage
        )
            Comms.PendingLocalSpellcastDispatchCount = math.max(
                0,
                Comms:GetPendingLocalSpellcastDispatchCount() - 1
            )
            baseDispatch(
                queuedOperations,
                queuedOpcode,
                queuedArguments,
                queuedSender,
                queuedDistribution,
                queuedTarget,
                queuedMessage
            )
        end, self, opcode, arguments, sender, distribution, target, message)
        return true
    end

    Operations._rpeDeferredLocalSpellcastDispatchInstalled = true
end
