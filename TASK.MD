## Summary

Replace the Event Widget-attached Combat Log and Meters side panels with a standard movable RPE window.

The current implementations in:

```text
client/ui/widgets/widget_Event_CombatLogHistory.lua
client/ui/widgets/widget_Event_Meters.lua
```

create plain `UI.CreatePanel(...)` side panels anchored to the Event Widget. They therefore do not match other RPE windows and cannot be independently moved.

Use the existing `UI.Window` abstraction so the utility UI has the normal RPE chrome:

- header bar;
- title;
- close button;
- draggable/movable header;
- standard window background and border.

Observed against `dev` at `55876f93db4cdc16b7dd500f8afdc929bb96dbb2`.

## Existing UI support

`core/ui/elements/Window.lua` already provides the required behavior.

A window created with:

```lua
UI.Window:New({
    ...,
    movable = true,
})
```

receives standard RPE window chrome, a close button, and header dragging through `StartMoving()` / `StopMovingOrSizing()`.

Do not hand-build a second custom title bar or drag implementation.

## Desired architecture

Use **one shared Event utility window** for Combat Log and Meters rather than two overlapping side panels.

Conceptually:

```text
Event Widget
  ├─ Combat Log button ─┐
  └─ Meters button ─────┴─> shared movable RPE utility window
                              mode = combat-log | meters
```

When Combat Log is selected:

```text
┌──────────────────────────────┐
│ Combat Log                [X]│
├──────────────────────────────┤
│ ... history ...              │
└──────────────────────────────┘
```

When Meters is selected:

```text
┌──────────────────────────────┐
│ Meters                    [X]│
├──────────────────────────────┤
│ Damage | Healing | Threat    │
│ ...                          │
└──────────────────────────────┘
```

The Event Widget buttons remain the entry points; the content/window should no longer be physically attached to the Event Widget once opened.

## Scope

### 1. Add/reuse a shared `UI.Window`

Create the utility window with the normal RPE `UI.Window` abstraction.

Requirements:

- `movable = true`;
- normal RPE header background/border;
- normal RPE close button;
- title updated according to active mode;
- content frame hosts either Combat Log or Meters content;
- appropriate strata/level so it behaves like other RPE windows.

Use a neutral name such as:

```text
RPEClientEventUtilityWindow
```

or equivalent.

### 2. Combat Log button behavior

The existing `Combat Log` button under the Event Widget should:

- open the utility window in Combat Log mode if closed;
- switch an already-open utility window from Meters to Combat Log;
- toggle/hide it when Combat Log is already the active mode, if preserving the current toggle behavior is desirable.

Preserve the existing combat-log history model and eight-entry retention behavior unless separately changed.

Do not make the combat log depend on its old side-panel anchor.

### 3. Meters button behavior

The existing `Meters` button should:

- open the same utility window in Meters mode if closed;
- switch an already-open Combat Log window to Meters;
- retain the active Damage/Healing/Threat and Total/Per Turn selections while the same event remains active.

The meter content should resize/layout against the utility window content frame rather than `EventWidget.rootPanel`.

### 4. Positioning and movement

The window should initially open in a sensible location near the Event Widget or screen center, but after the user moves it during the session it must not snap back to the Event Widget on every refresh.

Do not call `ClearAllPoints()`/re-anchor during normal content refreshes.

No SavedVariables persistence is required for the initial implementation unless there is already a standard RPE window-position persistence mechanism that can be reused without extra architecture.

### 5. Event lifecycle

Preserve current event behavior:

- ending/hiding the active event hides the utility window;
- changing event IDs resets event-specific Combat Log history/meter state as appropriate;
- reopening during the same event shows current content;
- close button hides the window without destroying the underlying event data.

### 6. Decouple DM Helper from the Combat Log presentation panel

`widget_Event_DMHelper.lua` currently reuses and resizes `combatLogHistoryPanel`, `combatLogHistoryScroll`, title state, and `combatLogHistoryMode = "dm-helper"`.

Do **not** accidentally migrate or redesign DM Helper as part of this task unless required.

Refactor the shared pieces so:

- Combat Log history **data APIs** remain available to DM Helper, including `GetCombatLogHistory()`;
- Combat Log presentation can move into the utility window without forcing DM Helper to use that same window;
- host-only DM Helper controls continue to work as before;
- opening DM Helper does not corrupt the utility window's Combat Log/Meters mode or dimensions.

If the cleanest implementation retains a dedicated DM Helper panel, that is acceptable. The requirement is specifically that **Combat Log and Meters** use the standard movable RPE window.

### 7. Remove obsolete side-panel assumptions

After migration, remove or simplify code that exists only to:

- anchor Combat Log/Meters to `rootFrame`'s right edge;
- maintain separate overlapping side panels;
- hide one side panel solely because the other occupies the same anchor.

Keep public/helper method compatibility where other Event Widget extensions currently call those methods, or update every call site in the same change.

## Regression checks

Inspect all call sites for at least:

```lua
ShowCombatLogHistoryPanel
HideCombatLogHistoryPanel
ToggleCombatLogHistoryPanel
IsCombatLogHistoryPanelShown
EnsureCombatLogHistoryUI
ShowMetersPanel
HideMetersPanel
ToggleMetersPanel
IsMetersPanelShown
EnsureMetersUI
```

and the DM Helper mode overrides/extensions before changing their semantics.

## Acceptance criteria

- Combat Log opens in a standard RPE window with header bar and close button.
- Meters opens in the same standard RPE window.
- The window can be dragged by its header.
- Moving the window is not undone by Event Widget refreshes.
- Combat Log and Meters buttons switch the shared window's content correctly.
- The close button hides the utility window and the buttons can reopen it.
- Combat Log history continues updating while its view is open.
- Meters continue updating live while their view is open.
- Damage/Healing/Threat and scope selections are retained appropriately while switching views.
- Event end/change does not leave stale utility-window content visible.
- DM Helper remains functional and does not inherit unintended utility-window sizing/mode behavior.
- No duplicate custom window chrome is introduced; use `UI.Window`.

## References

- #349
- `client/ui/widgets/widget_Event_CombatLogHistory.lua`
- `client/ui/widgets/widget_Event_Meters.lua`
- `client/ui/widgets/widget_Event_DMHelper.lua`
- `core/ui/elements/Window.lua`