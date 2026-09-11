local _, Addon = ...

local Server = Addon.Server or {}
local Client = Addon.Client or {}
local Comms = Addon.Internal and Addon.Internal.Comms or {}
local EventSync = Comms.EventSync or {}
local Operations = Comms.Operations or {}
local Spellcasting = Client.Spellcasting or {}

local SPELLCAST_START_OPCODE = Operations.GetOpcode and Operations:GetOpcode("SPELLCAST_START") or nil
local SPELLCAST_COMPLETE_OPCODE = Operations.GetOpcode and Operations:GetOpcode("SPELLCAST_COMPLETE") or nil
local SPELLCAST_INTERRUPT_OPCODE = Operations.GetOpcode and Operations:GetOpcode("SPELLCAST_INTERRUPT") or nil

local spellOpcodes = {
    [SPELLCAST_START_OPCODE or -1] = true,
    [SPELLCAST_COMPLETE_OPCODE or -2] = true,
    [SPELLCAST_INTERRUPT_OPCODE or -3] = true,
}

-- The host's UI-side spell cache may lag an already committed remote mutation.
-- Before applying another spell proposal, rebuild that cache from the canonical
-- host mirror. The normal proposal handler then mutates exactly one cast and its
-- cooldown state, so the subsequent domain merge cannot erase another caster's
-- newer state.
local baseHandleEventMutationRequest = Server.HandleEventMutationRequest
if type(baseHandleEventMutationRequest) == "function" then
    function Server:HandleEventMutationRequest(payload, sender)
        local request = type(EventSync.DeserializeMutationRequest) == "function"
            and EventSync.DeserializeMutationRequest(payload) or nil
        if type(request) ~= "table" or spellOpcodes[request.opcode] ~= true
            or type(self.EventRuntime) ~= "table"
            or type(self.EventState) ~= "table"
            or self.EventState.active ~= true
        then
            return baseHandleEventMutationRequest(self, payload, sender)
        end

        if type(Spellcasting.ReplaceEventCastState) == "function" then
            Spellcasting.ReplaceEventCastState(
                Client,
                self.EventState.id,
                self.EventRuntime.spellcasts or {},
                { refresh = false }
            )
        end
        if type(Spellcasting.ReplaceEventCooldownState) == "function" then
            Spellcasting.ReplaceEventCooldownState(
                Client,
                self.EventState.id,
                self.EventRuntime.cooldowns or {},
                { refresh = false }
            )
        end

        return baseHandleEventMutationRequest(self, payload, sender)
    end
end

return Server
