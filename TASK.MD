## Context

Regression in the absorption presentation added in the latest `dev` absorption update. This follows #326.

Observed behaviour:

- an incoming hit is absorbed partially or fully;
- shield capacity is consumed;
- there is no combat-log entry;
- there is no event-widget ticker entry.

Expected partial example:

```text
Incoming post-mitigation damage: 116
Absorbed: 65
Health damage: 51
```

The resulting damage presentation should report the actual health damage and append the absorbed amount, e.g.:

```text
... 51 Fire damage (Absorbed 65)
```

The same emitted combat-log entry should populate both combat-log history and the event-widget ticker through the existing combat-log presentation queue.

## Root cause traced on current `dev`

The absorption-aware formatter itself exists.

`client/combat/Helpers.lua` already aggregates:

```lua
amount = damageResult.amount
absorbedAmount = damageResult.absorbedAmount
```

and `buildAggregateDamageDetailText()` appends the absorbed amount.

The problem is earlier in the remote-defender reaction path.

`Combat:HandleDamageHitCheckRequest()` in `client/combat/Reaction.lua` reconstructs the defender-side damage entry from the combat whisper. Its context currently contains:

```lua
{
    spellRef = spellRef,
    eventState = eventState,
    sessionState = sessionState,
    healthResourceRef = ...,
    immediate = true,
    pendingScope = "reaction",
}
```

but it does **not** contain the attacker's original `castEntry`, `spell`, or action combat-event aggregate state.

Later, defender-side finalization calls:

```lua
Combat:RegisterActionDamageCombatLog(entry, damageResult)
```

which internally does:

```lua
local castEntry = context and context.castEntry
local spell = context and context.spell
local state = self:GetOrCreateActionCombatEventState(castEntry, spell)
```

`GetOrCreateActionCombatEventState()` returns `nil` when `castEntry` is absent. Therefore registration silently returns false and no aggregate exists to flush.

This explains why damage resolved by the remote defending player can consume absorption but produce no combat-log/ticker entry.

## Required architectural fix

Do not make defender-side damage presentation depend on possessing the attacker's in-memory `castEntry` object.

The remote defender cannot and should not share Lua object identity with the attacker's local cast state.

Introduce a stable presentation/action identity that survives the hit-check request/response boundary. Reuse an existing stable combat/cast/action identifier if one already exists; otherwise extend the hit-check payload minimally with the required identity.

A suitable contract is conceptually:

```lua
{
    spellRef = "...",
    componentKey = "...",
    combatEventId = "...", -- or other stable cast/action id
}
```

Then make damage combat-log registration capable of one of the following clean behaviours:

1. associate the remote defender's result with an existing stable action aggregate by ID; or
2. directly emit a complete single-target damage combat-log entry when no local aggregate object exists.

Prefer preserving the current aggregation behaviour for multi-target casts where possible, but do not require an impossible cross-client `castEntry` pointer.

## Avoid duplicate emission

There are two clients involved in a remote-player hit:

- attacker owns the original spell/cast action;
- defender owns authoritative reaction/damage resolution.

Only one authoritative damage result should be emitted for the target.

Audit both:

- `HandleDamageHitCheckRequest()` / defender `FinalizeLocalDamageResult()`;
- `HandleDamageHitCheckResponse()` / attacker preview/finalization path.

Do not fix the missing entry by independently emitting the same final damage line from both clients.

The chosen authority must have the final post-absorption result:

```lua
preAbsorbAmount
absorbedAmount
amount
```

so the line cannot be generated from the attacker's pre-reaction/pre-runtime preview if that preview is not authoritative.

## Combat-log data contract

For partial absorption:

```lua
amountMin = 51
amountMax = 51
absorbedAmount = 65
```

Presentation text should be equivalent to:

```text
51 Fire (Absorbed 65)
```

For full absorption:

```lua
amountMin = 0
amountMax = 0
absorbedAmount = 80
```

A zero-health-damage entry is valid and must still be emitted.

The current `Client:NormalizeCombatLogEntry()` already accepts non-negative damage values, including zero. Do not reintroduce a positive-only gate.

## Event-widget ticker

Do not create a separate absorption ticker system.

The existing path is:

```text
EmitCombatLogEntry
-> HandleCombatLog / QueueCombatLogEntry
-> EventWidget:QueueCombatLogEntry
-> combat-log presentation queue
```

Fix the missing damage emission so the existing event-widget ticker receives the same entry automatically.

This preserves:

- history/ticker consistency;
- team colours;
- spell icon;
- damage-school colour/icon;
- existing queue/coalescing behaviour.

## Triggered / aura damage

Audit `AuraManager.lua`'s triggered damage emission as well. It already has absorb-aware formatting and must remain consistent with direct spell damage.

Avoid ending up with one format for normal attacks and another for aura-triggered damage.

## Primary files / call paths

At minimum inspect current `dev` versions of:

- `client/combat/Reaction.lua`
  - `HandleDamageHitCheckRequest()`
  - `HandleDamageHitCheckResponse()`
  - `FinalizeLocalDamageResult()`
  - `finalizeDamageCombatEvents()`
- `client/combat/Helpers.lua`
  - `GetOrCreateActionCombatEventState()`
  - `RegisterActionDamageCombatLog()`
  - `CompleteActionDamageResolution()`
  - `FlushActionDamageCombatLog()`
  - `buildAggregateDamageDetailText()`
- `client/combat/effects/Damage.lua`
  - hit-check request payload and stable identifiers
- `client/client_CombatLog.lua`
  - normalization
  - emission/broadcast
  - ticker queue path
- `client/ui/widgets/widget_Event.lua`
  - `QueueCombatLogEntry()`
- `client/spellcasting/AuraManager.lua`
  - triggered absorb-aware damage log path

## Acceptance criteria

- [ ] A remote-player hit that deals post-absorb health damage emits exactly one damage combat-log entry.
- [ ] That same entry appears in the event-widget ticker.
- [ ] Partial absorption reports post-absorb health damage, not pre-absorb damage.
- [ ] Partial absorption appends the absorbed amount.
- [ ] A fully absorbed hit still produces a combat-log/ticker entry with zero health damage or equivalent full-absorb wording.
- [ ] Damage-school icon/label/colour remain intact.
- [ ] Spell icon remains intact.
- [ ] Attacker/target display names and team colouring remain intact.
- [ ] Local-target, remote-target and NPC-target attack paths do not duplicate entries.
- [ ] Existing multi-target aggregation still works.
- [ ] Triggered/aura damage uses equivalent absorption wording.
- [ ] No new independent ticker mechanism is introduced.

## Deterministic regression tests

1. Local attacker -> local/NPC defender, 116 damage, 65 absorbed -> one `51 ... (Absorbed 65)` entry.
2. Player A attacks Player B remotely, 116 damage, 65 absorbed -> exactly one identical entry visible to the group.
3. Player A attacks Player B, 80 damage, 80 absorbed -> exactly one zero-damage/full-absorb entry.
4. Remote hit with no absorption -> existing damage log behaviour unchanged.
5. Multi-target spell where one target absorbs and one does not -> aggregation remains valid and no target resolution disappears.
6. Triggered aura damage with partial absorption -> one absorb-aware entry.
7. Physical self-copy/group transport does not duplicate the host/local ticker entry.