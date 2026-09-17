## Summary

The current meter implementation on `dev` has two separate problems:

1. **Total** is not displaying accumulated values even though damage/healing/threat are being recorded.
2. **Per Turn** currently means “amount generated during the current turn”, but the intended meaning is simply:

```text
Per Turn = Total / Number of Turns
```

This issue should fix both behaviors without maintaining separate per-turn meter ledgers.

## Root cause of empty Total view

In `client/client_EventMeters.lua`, event data is stored under:

```lua
bucket.total[meterType]
```

but `getRowsMap()` currently does:

```lua
local source = bucket
if scope == "turn" then
    source = bucket.turns[...]
end
return type(source) == "table" and source[meterType] or nil
```

For `scope == "total"`, this attempts to read:

```lua
bucket.damage
bucket.healing
bucket.threat
```

instead of:

```lua
bucket.total.damage
bucket.total.healing
bucket.total.threat
```

As a result, Total can appear empty despite `RecordCombatLogEntry()` and `RecordThreatUpdate()` accumulating into `bucket.total` correctly.

Fix the total lookup so all Total meter queries read the cumulative event totals from `bucket.total`.

## Correct meaning of Per Turn

Do **not** treat Per Turn as a separate current-turn bucket.

The intended metric is an event-wide average:

```text
perTurnAmount = totalAmount / numberOfTurns
```

For example:

```text
Total damage = 1,200
Event turnNumber = 6
Per Turn = 200
```

This applies identically to:

- Damage
- Healing
- Threat

Threat remains target-specific, so for a selected NPC:

```text
player threat per turn = total threat generated against that NPC / number of turns
```

## Turn divisor

Use the active event's turn count/number as the divisor.

At minimum:

```lua
turnCount = math.max(1, tonumber(eventState.turnNumber) or 1)
```

so turn 1 never divides by zero.

If the event model already exposes a more precise completed/current turn count, use that existing canonical value, but do not count only turns where a player generated meter activity.

The denominator is the number of event turns elapsed/currently reached, not the number of non-empty meter buckets.

## Simplify `EventMeters`

The current implementation introduced:

```lua
bucket.turns[turnNumber]
```

for damage/healing/threat.

That storage is unnecessary for the intended feature.

Refactor the runtime so the authoritative meter state is cumulative event totals only:

```lua
byEventId[eventId] = {
    total = {
        damage = {},
        healing = {},
        threat = {},
    },
}
```

or an equivalent simpler shape.

`RecordCombatLogEntry()` should only increment event totals.

`RecordThreatUpdate()` should only increment event-total target-specific threat.

`GetRows()` should return:

- **Total**: stored cumulative amount;
- **Per Turn**: a derived copy of Total rows with `amount = total / turnCount`.

Do not mutate stored totals when producing Per Turn rows.

## Snapshot/rejoin behavior

Because Per Turn is derived, snapshots only need to preserve cumulative totals.

Update the meter snapshot/rejoin code so it does not depend on restoring current-turn buckets.

A reload or late join should restore:

```text
cumulative damage totals
cumulative healing totals
cumulative target-specific threat totals
```

and then derive Per Turn from the current event turn number locally.

Retain compatibility with the currently supported meter snapshot formats where practical, but do not continue carrying redundant per-turn state merely for compatibility.

## UI behavior

The existing `Total | Per Turn` toggle can remain.

When `Per Turn` is selected:

- rank using the derived per-turn values;
- bar widths use the derived per-turn values;
- percentages remain mathematically identical to Total because every row is divided by the same turn count;
- changing/advancing the event turn should refresh the displayed averages automatically.

Do not rename the toggle.

## Acceptance criteria

- Total Damage accumulates continuously throughout the event and remains visible after multiple turns.
- Total Healing accumulates continuously throughout the event.
- Total Threat accumulates continuously per selected NPC target.
- Total no longer returns an empty list because of the `bucket.total` lookup bug.
- Per Turn is **not** current-turn activity.
- Per Turn equals `Total / event turn count` for every player row.
- Example: 1,200 total damage on turn 6 displays 200 Per Turn.
- Example: 600 total healing on turn 3 displays 200 Per Turn.
- Example: 900 total threat against NPC A on turn 3 displays 300 Per Turn for NPC A.
- Advancing from turn 3 to turn 4 changes a 900 total value from 300/turn to 225/turn without changing Total.
- No separate turn ledger is required to calculate Per Turn.
- Reload/late join restores cumulative totals and derives the same Per Turn values from the current event turn count.
- Existing player-only filtering remains intact.
- Existing damage/healing/threat recording paths continue to accumulate exactly once.

## Primary file

`client/client_EventMeters.lua`

Also inspect/update the current meter snapshot/rejoin code and `client/ui/widgets/widget_Event_Meters.lua` where needed so the UI derives Per Turn from cumulative totals rather than current-turn buckets.