local _, Addon = ...

local Combat = Addon.Client and Addon.Client.Combat or nil
if not Combat then
    return
end

function Combat:ExecuteInterruptEffect(context, effect, component)
    local targetUnit = type(context) == "table" and (context.targetUnit or context.target) or nil
    local client = Addon.Client or nil
    local spellcasting = client and client.Spellcasting or nil
    local eventState = type(context) == "table" and context.eventState or nil
    local spellRef = nil
    if type(client) == "table" and type(client.GetSpellcastEntry) == "function" and type(eventState) == "table" then
        local activeCast = client:GetSpellcastEntry(eventState.id, tonumber(targetUnit and targetUnit.eventID) or 0)
        spellRef = activeCast and activeCast.spellRef or nil
    end

    if type(targetUnit) ~= "table"
        or type(client) ~= "table"
        or type(spellcasting) ~= "table"
        or type(spellcasting.InterruptUnitSpellcast) ~= "function"
    then
        return false, {
            effectType = "interrupt",
            resultType = "invalid",
            amount = 0,
        }
    end

    local applied, removedEntry = spellcasting.InterruptUnitSpellcast(client, eventState, targetUnit, {
        reason = "spell-effect",
        sourceContext = context,
    })
    local interruptedSpellRef = type(removedEntry) == "table" and removedEntry.spellRef or spellRef
    local interruptedSpellName = type(removedEntry) == "table" and removedEntry.spellName or nil
    return applied, {
        effectType = "interrupt",
        resultType = applied and "applied" or "noop",
        applied = applied,
        spellRef = interruptedSpellRef or spellRef,
        interruptedSpellRef = interruptedSpellRef,
        interruptedSpellName = interruptedSpellName,
        component = component,
    }
end

local InterruptEffect = Combat:CreateEffectContract({
    type = "interrupt",
    label = "Interrupt",
    description = "Stops the target's current spell cast.",
    defaults = {
        type = "interrupt",
        targetEvents = {},
    },
    fields = {
        "targetEvents",
    },
    Execute = function(self, context, effect, component)
        return Combat:ExecuteInterruptEffect(context, effect or self.defaults, component)
    end,
})

return InterruptEffect
