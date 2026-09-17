## Summary

Add the player-facing **Meters** UI described in `docs/PLAN-Damage-Healing-Threat-Meters.md`.

The Event Widget should expose damage, healing and threat views through a new `Meters` button below the event header. Damage/healing data comes from `Addon.Client.EventMeters`; threat is rendered directly from the selected NPC Event Unit's synchronized `threatTable`.

## Dependencies

Depends on #347 for the live meter runtime.

#348 should also be completed so the UI remains correct after late join/reload.

## Scope

### 1. Add the Event Widget extension

Create:

```text
client/ui/widgets/widget_Event_Meters.lua
```

Load it from `RPEngine2.toc` after:

```text
client/ui/widgets/widget_Event_CombatLogHistory.lua
```

because it should reuse the existing Event Widget utility-button row.

### 2. Add the `Meters` button

Add a normal-player-visible button to `combatLogHistoryButtonRow` using the same dimensions/style as `Combat Log`.

Normal player order should be:

```text
Combat Log | Meters
```

Host controls may continue after those shared buttons:

```text
Combat Log | Meters | DM Helper | NPC/Combat Mode
```

Do not create a second button strip.

### 3. Side-panel ownership and mutual exclusion

Meters should open as a side panel adjacent to the Event Widget.

It must not overlap the existing Combat Log / DM Helper side panel.

Required behavior:

- opening Meters hides Combat Log/DM Helper if open;
- opening Combat Log hides Meters;
- opening DM Helper hides Meters;
- hiding/ending the Event Widget hides Meters;
- switching views inside Meters does not rebuild the whole Event Widget.

Prefer explicit helper methods such as:

```lua
EventWidget:EnsureMetersUI()
EventWidget:IsMetersPanelShown()
EventWidget:ShowMetersPanel()
EventWidget:HideMetersPanel()
EventWidget:ToggleMetersPanel()
EventWidget:RefreshMetersPanel()
```

### 4. Add Damage / Healing / Threat views

The panel should have three tabs/buttons:

```text
Damage | Healing | Threat
```

Remember the currently selected meter type while the same event remains active.

#### Damage and Healing rows

Read rows from `Addon.Client.EventMeters:GetRows(eventId, meterType)`.

Each row must show:

```text
rank
unit name
total amount
percentage of total displayed damage/healing
horizontal proportional bar
```

Example:

```text
1. Player A     1,248   42.3%
2. Player B       824   27.8%
```

Rules:

- rows sorted by the runtime's deterministic ranking;
- bar width relative to the largest row value;
- percentage value relative to the sum of all rows in that meter view;
- use Event team color for name/bar when available;
- support player and NPC Event Units when they have attributable meter totals;
- preserve rows for units that have become inactive if the runtime still contains them;
- show a clean empty state when no entries exist.

Do **not** display DPS/HPS. RPE combat is turn-based, so wall-clock throughput is not meaningful here.

### 5. Threat target selector

Threat is target-specific in RPE. Add an NPC selector above the threat rows, e.g.:

```text
Target: [ Boss Name v ]
```

Eligible targets:

- active non-player Event Units;
- preferably units with non-empty `threatTable` values;
- bosses first;
- then normal NPCs in deterministic Event Unit order.

If exactly one eligible NPC exists, select it automatically.

If the previously selected NPC becomes invalid/inactive, choose the next deterministic eligible target or show an empty state.

### 6. Render current threat directly from Event Unit state

Do not create a second threat ledger.

For the selected NPC, read:

```lua
selectedNpc.threatTable[sourceEventId] = currentThreat
```

For each source:

1. resolve `sourceEventId` against `eventState.units`;
2. discard zero/negative threat;
3. sort descending by current threat, then Event Unit ID for deterministic ties;
4. show rank, unit name, current threat and percentage relative to the highest threat holder;
5. size the bar relative to the highest threat value.

Example:

```text
1. Tank      842   100%
2. Mage      611    73%
3. Priest    405    48%
```

This is **current threat against the selected NPC**, not cumulative threat generated during the event.

Taunt state must not fabricate numerical threat; render whatever the existing synchronized threat model contains.

### 7. Live refresh

Refresh the visible Meters panel when relevant state changes without rebuilding the entire Event Widget.

Damage/healing refresh triggers should include successful `EventMeters:RecordCombatLogEntry()` updates and snapshot installation.

Threat refresh should occur when existing synchronized threat/Event Unit state changes and on ordinary Event Widget refreshes.

Avoid per-frame polling.

### 8. UI primitives

Use existing RPE UI abstractions rather than Blizzard XML/templates:

```text
Panel
HorizontalLayoutGroup
TextButton
ScrollLayout
Dropdown
Text / frame textures for bars
```

Rows should fit the side panel cleanly and support scrolling when more units exist than can be shown at once.

### 9. Event lifecycle

When no active event exists:

- hide the Meters button/panel as appropriate with existing Event Widget lifecycle behavior;
- clear invalid threat target selection;
- never display totals from a previous Event ID.

When a rejoin snapshot from #348 is installed while Meters is visible, refresh immediately.

## Acceptance criteria

- All players in an active event can open `Meters` from the Event Widget.
- Damage view ranks units by current cumulative damage and displays correct totals/percentages/bars.
- Healing view ranks units by current cumulative healing and displays correct totals/percentages/bars.
- Threat view allows selecting an eligible NPC and ranks current threat against that NPC.
- Threat values come directly from the selected NPC's synchronized `threatTable`.
- Bosses appear before normal NPCs in the threat selector.
- Exactly one eligible NPC is auto-selected.
- Empty damage/healing/threat states are handled cleanly.
- Combat Log, DM Helper and Meters side panels are mutually exclusive and never overlap.
- The panel updates live without rebuilding the full Event Widget or polling every frame.
- No DPS/HPS is shown.
- Ending/changing events cannot leave the previous event's meter rows visible.
- After #348, late join and `/reload` display the same damage/healing totals as existing participants.

## Reference

`docs/PLAN-Damage-Healing-Threat-Meters.md`