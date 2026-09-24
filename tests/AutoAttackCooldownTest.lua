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

local eventState
local activeCaster
local spells = {}
local Addon = {
    Client = {
        Spellcasting = {
            NormalizeTurnCount = function(value)
                local turns = tonumber(value)
                return turns and math.max(0, math.floor(turns)) or nil
            end,
            ResolveSpellCooldownChannel = function()
                return 4, { enabled = true, name = "Free Action", triggersGCD = false, canUseOffTurn = true }
            end,
            ResolveSpellRankContext = function()
                return { eligible = true, multiplier = 1, usesRanks = false }
            end,
            IsCasterTurnOnTick = function() return true end,
        },
        GetState = function() return { active = true } end,
        GetEventState = function() return eventState end,
        GetSpellcastEntry = function() return nil end,
        ResolveSpellActivation = function(_, spellRef)
            local spell = spells[spellRef]
            if not spell then return nil end
            return {
                eventState = eventState,
                casterUnit = activeCaster,
                spell = spell,
                spellRef = spellRef,
                policy = { type = "caster", requiresTarget = false, maxTargets = 1 },
                targetUnit = activeCaster,
                targetGroups = {},
            }
        end,
    },
    Internal = { Database = { Classes = {} }, Ruleset = {}, Registry = {} },
}

local function autoSpell(damageType, cooldown)
    return {
        cooldown = cooldown or 0,
        cooldownChannel = 4,
        components = { {
            effect = { type = "damage", hitType = "auto", damageType = damageType },
        } },
    }
end

spells.main = autoSpell("melee")
spells.offhand = autoSpell("melee")
spells.ranged = autoSpell("ranged")
spells.wand = autoSpell("spell")
spells.long = autoSpell("melee", 3)
spells.charged = autoSpell("melee")
spells.charged.useCooldownCharges = true
spells.charged.charges = 2
spells.nonAuto = { cooldown = 0, cooldownChannel = 4, components = { { effect = { type = "damage", hitType = "ability", damageType = "melee" } } } }

loadAddonFile("client/spellcasting/Cooldowns.lua", Addon)
loadAddonFile("client/spellcasting/ExplicitCasterActivation.lua", Addon)

local Client = Addon.Client
local Spellcasting = Client.Spellcasting
local player = { eventID = 1, isPlayer = true, resources = {} }
local npc = { eventID = 2, isPlayer = false, active = true, resources = {}, spells = { "main", "offhand", "ranged", "wand" } }
eventState = { active = true, id = "auto-cooldown", turnNumber = 1, tickNumber = 1, units = { player, npc } }

activeCaster = player
assertEqual(Spellcasting.GetEffectivePersonalCooldownTurns(spells.main), 1, "zero-cooldown auto attacks have a one-turn personal cooldown")
assertEqual(Spellcasting.GetEffectivePersonalCooldownTurns(spells.long), 3, "authored auto cooldowns above one are retained")
assertEqual(Spellcasting.GetEffectivePersonalCooldownTurns(spells.nonAuto), 0, "non-auto zero cooldowns are unchanged")

assertTrue(Client:ApplyLocalSpellCooldown(eventState, player, "main", spells.main), "main-hand cooldown is recorded")
local mainState = Spellcasting.BuildSpellActivationSnapshot(Client, "main")
assertEqual(mainState.canCast, false, "main hand cannot be used twice on the same turn")
assertEqual(mainState.reason, "cooldown", "same auto attack uses its personal cooldown")
assertEqual(Spellcasting.BuildSpellActivationSnapshot(Client, "offhand").canCast, true, "different same-type auto attack is allowed")
assertEqual(Spellcasting.BuildSpellActivationSnapshot(Client, "ranged").reason, "basic-attack-type", "melee blocks ranged auto attacks")
assertEqual(Spellcasting.BuildSpellActivationSnapshot(Client, "wand").reason, "basic-attack-type", "melee blocks spell auto attacks")

assertTrue(Client:ApplyLocalSpellCooldown(eventState, player, "long", spells.long), "long auto cooldown is recorded")
local unitState = Spellcasting.GetUnitCooldownState(Client, eventState.id, player.eventID, false)
assertEqual(unitState.spells.long.remainingTurns, 3, "authored long auto cooldown remains greater than one")
Client:ApplyLocalSpellCooldown(eventState, player, "nonAuto", spells.nonAuto)
assertEqual(unitState.spells.nonAuto, nil, "non-auto zero-cooldown spell has no personal cooldown")
Client:ApplyLocalSpellCooldown(eventState, player, "charged", spells.charged)
assertEqual(Spellcasting.BuildSpellActivationSnapshot(Client, "charged").canCast, false, "charged auto attack still cannot be repeated on the same turn")

eventState.turnNumber = 2
Spellcasting.AdvanceCooldownState(Client, 1, 1)
assertEqual(Spellcasting.BuildSpellActivationSnapshot(Client, "main").canCast, true, "auto attack is available after cooldown advancement")

eventState.id = "auto-cooldown-ranged"
eventState.turnNumber = 1
activeCaster = player
Client.CooldownsByEventId = {}
Client:ApplyLocalSpellCooldown(eventState, player, "ranged", spells.ranged)
assertEqual(Spellcasting.BuildSpellActivationSnapshot(Client, "main").reason, "basic-attack-type", "ranged blocks melee auto attacks")
assertEqual(Spellcasting.BuildSpellActivationSnapshot(Client, "wand").reason, "basic-attack-type", "ranged blocks spell auto attacks")

eventState.id = "auto-cooldown-npc"
activeCaster = npc
Client.CooldownsByEventId = {}
assertTrue(Client:ApplyLocalSpellCooldown(eventState, npc, "main", spells.main), "explicit NPC auto cooldown is recorded")
local npcMain = Spellcasting.BuildSpellActivationSnapshot(Client, "main", { casterEventId = npc.eventID })
assertEqual(npcMain.canCast, false, "explicit NPC cannot repeat the same auto attack")
assertEqual(Spellcasting.BuildSpellActivationSnapshot(Client, "offhand", { casterEventId = npc.eventID }).canCast, true, "explicit NPC can use a distinct same-type auto attack")

print("AutoAttackCooldownTest passed")
