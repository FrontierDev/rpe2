# RPE 2 — All Units Event View

**Status:** Approved design  
**Target:** RPEngine 2.0 (`FrontierDev/rpe2`)  
**Branch:** `main`  
**Scope:** Client event UI only

---

# 1. Purpose

RPE currently emphasizes the units participating in the current event step through the event portrait area. This keeps the active-turn interface compact, but it makes it unnecessarily difficult for players to answer a basic encounter-state question:

> What units are still present in the event, and how much health do they have?

Add a compact **All Units** view to the existing event utility window used by **Combat Log** and **Meters**.

The view is read-only. It is intended for rapid encounter awareness rather than targeting, inspection, threat analysis, or unit administration.

---

# 2. Product Decision

The existing event utility window becomes a three-mode container:

```text
Combat Log
Meters
All Units
```

The new view must reuse the existing movable `RPEClientEventUtilityWindow`. It must not create another permanent event window or another independent control strip.

The existing utility buttons remain immediately below the event header:

```text
[ Combat Log ] [ Meters ] [ All Units ]
```

Selecting **All Units** opens the same movable utility window and switches its content to the All Units panel.

---

# 3. Presentation

The view is deliberately compact.

Example:

```text
┌─────────────────────────────────────────┐
│ ALL UNITS                               │
│                                         │
│ TEAM 1 — Players                        │
│ ◆  Ortellus #1     ███████████░  82%    │
│ ●  Alaric   #4     █████████████ 100%   │
│    Elaina   #7     ███████░░░░░  58%    │
│                                         │
│ TEAM 2 — Enemies                        │
│ ★  Commander #12   ████████░░░░  67%    │
│ ★  Guard     #14   ███░░░░░░░░░  24%    │
│ ■  Mage      #16   ██████████░░  85%    │
└─────────────────────────────────────────┘
```

Each normal unit row contains only:

1. raid marker icon, when present;
2. unit name;
3. Event Unit ID;
4. health bar;
5. health value or percentage.

Do not add portraits, auras, cast state, resources other than health, threat, action buttons, spell information, or detailed tooltips to the initial implementation.

The purpose is immediate encounter-state visibility, not a second unit-frame system.

---

# 4. Grouping and Ordering

Rows are grouped by **team**, then ordered by **raid marker**, then by **Event Unit ID**.

## 4.1 Team grouping

Use the event's configured team names through the existing Event helpers rather than hard-coding `Team 1`, `Team 2`, etc.

Each team begins with a compact team heading.

The heading may use the configured team color where appropriate, but readability takes precedence.

## 4.2 Raid marker ordering

Within a team:

1. raid marker 1;
2. raid marker 2;
3. raid marker 3;
4. raid marker 4;
5. raid marker 5;
6. raid marker 6;
7. raid marker 7;
8. raid marker 8;
9. unmarked units.

Do not add a separate heading for every raid marker. The marker icon on each unit row is sufficient.

Units sharing a marker naturally appear together.

## 4.3 Stable ordering

If multiple units share the same team and raid marker, order them by numeric `eventID`.

The resulting list must be deterministic and must not jump between refreshes merely because Lua table iteration order changed.

---

# 5. Included Units

The view represents the whole active event roster, not only the current event page/step.

It therefore includes:

- current-turn units;
- units whose turn is not current;
- bosses;
- normal NPCs;
- player characters;
- active pets/summons represented as normal Event Units;
- dead units that remain part of the event.

Inactive/removed units should follow the existing Event Unit active-state semantics. The view must not invent a second definition of whether a unit belongs to the active event roster.

---

# 6. Current-Turn Indication

Current-turn units remain in the All Units list.

They should receive a subtle visual indication so the player can distinguish them without removing them from their team/marker grouping.

Use existing turn/event semantics rather than attempting to infer current-turn membership from row position.

The indicator should be lightweight, for example:

- a subtle row border;
- a small turn indicator;
- slightly stronger row emphasis.

Do not reorder current-turn units to the top.

---

# 7. Dead Units

Dead units remain visible.

Their health is shown as zero and the row is visually muted/desaturated.

Dead units must remain in their normal team/raid-marker position so the view remains a stable representation of the encounter roster.

Do not remove a row simply because the health resource reaches zero.

---

# 8. Hidden Units

The All Units view must not leak hidden-unit information to ordinary clients.

The existing event portrait implementation already distinguishes host and non-host hidden-unit presentation and builds a masked display unit for non-host clients. The All Units view must follow the same privacy model.

For the event host, hidden units may be displayed normally.

For non-host clients, a hidden unit must not expose:

- real name;
- health;
- resources;
- raid marker if that would reveal concealed identity/state;
- other detailed unit metadata.

The implementation should reuse or centralize the existing hidden-unit masking policy instead of defining a conflicting All Units-only rule.

A concealed placeholder row is acceptable if preserving roster position is necessary, but it must not expose hidden details.

---

# 9. Health Resolution

Health must be resolved from the active ruleset's configured health resource, consistent with the rest of RPE.

Do not assume that:

- the first resource is health;
- health always uses a hard-coded resource ID;
- all units have identical resource arrays.

Where possible, reuse the existing health/resource resolution logic already used by event portraits or targeting displays rather than creating another health interpretation path.

The row should use current and maximum health values from the authoritative client event state.

Recommended display:

```text
████████░░░░  67%
```

or:

```text
████████░░░░  402 / 600
```

The implementation may show both if this remains visually compact.

Health bars should use the existing RPE `ProgressBar`/resource-bar abstractions rather than raw Blizzard StatusBar construction where practical.

---

# 10. Live Refresh

The All Units panel is a view over the existing client Event State. It does not own encounter state.

No new networking protocol, SavedVariables storage, event snapshot format, or server-side unit list is required.

While the All Units view is visible, it must update when relevant client event state changes, including:

- health/resource changes;
- unit death;
- event-step/turn changes;
- hidden-state changes;
- unit activation/deactivation;
- raid marker changes;
- team changes;
- event start/end;
- event rejoin/state restoration.

The implementation should use the existing EventWidget refresh lifecycle and targeted refresh mechanisms where appropriate.

Do not introduce polling or an OnUpdate loop solely for this view.

---

# 11. Utility Window Integration

The current `widget_Event_CombatLogHistory.lua` owns the movable event utility window and currently normalizes the utility mode to either:

```text
combat-log
meters
```

Generalize this to explicitly support:

```text
combat-log
meters
all-units
```

The mode switch must:

- set the correct window title;
- show only the selected panel;
- hide the other utility panels;
- preserve the utility window's movable position;
- keep the window clamped to screen;
- maintain the existing close behaviour;
- preserve Combat Log and Meters behaviour.

Avoid mode logic where every new utility panel requires another nested binary branch.

A small explicit mode-to-panel/title dispatch structure is preferred.

---

# 12. Proposed Module

Add:

```text
client/ui/widgets/widget_Event_AllUnits.lua
```

and load it after the base Event widget and the utility-window implementation in `RPEngine2.toc`.

Suggested responsibilities:

```lua
EventWidget:EnsureAllUnitsUI()
EventWidget:BuildAllUnitsRows(eventState)
EventWidget:RefreshAllUnitsPanel()
EventWidget:IsAllUnitsPanelShown()
EventWidget:ShowAllUnitsPanel()
EventWidget:HideAllUnitsPanel()
EventWidget:ToggleAllUnitsPanel()
```

Exact method names may vary, but the All Units module should own row construction and rendering while the shared utility-window module owns generic mode switching.

---

# 13. Row Model

Build a presentation-only row model from the active Event State.

Conceptually:

```lua
{
    rowType = "unit",
    team = 2,
    teamName = "Enemies",
    raidMarker = 8,
    eventID = 12,
    name = "Commander",
    currentHealth = 402,
    maxHealth = 600,
    healthPercent = 67,
    currentTurn = false,
    dead = false,
    hidden = false,
}
```

Team headings may use:

```lua
{
    rowType = "team",
    team = 2,
    teamName = "Enemies",
}
```

The row model must contain presentation data only. It must not become a second mutable unit-state cache.

---

# 14. UI Construction

Use existing RPE UI abstractions.

Expected building blocks include:

- `UI.Panel`;
- `UI.ScrollLayout`;
- `UI.Text`;
- `UI.Image` or existing inline raid-marker support;
- `UI.ProgressBar`;
- existing layout groups where helpful.

A custom lightweight row element/prefab is acceptable if `ScrollLayout` cannot render the mixed text + progress-bar row cleanly.

If a new prefab is needed, keep it generic enough to represent an event-unit summary row without embedding All Units window behaviour into the prefab.

---

# 15. Interaction

Initial implementation is read-only.

Clicking an All Units row does not:

- select a spell target;
- alter the current controlled unit;
- open Event Manage;
- change initiative;
- change raid markers;
- open another window.

This keeps the feature low-effort and prevents the overview from acquiring unrelated interaction semantics.

Additional interaction can be considered separately if actual use demonstrates a need.

---

# 16. Empty and Transitional States

The panel must fail cleanly.

Recommended empty-state text:

```text
No event units available.
```

During event startup/rejoin while units are not yet ready, use the existing event readiness state rather than rendering partial/stale rows as authoritative.

When the event ends:

- clear/hide the All Units panel;
- do not leave stale unit rows visible from the previous event.

---

# 17. Performance

The view is small enough that rebuilding the presentation rows during a normal EventWidget refresh is acceptable, but unnecessary work should still be avoided.

Recommended approach:

1. build a compact deterministic signature from fields relevant to this view;
2. skip row reconstruction if the signature has not changed;
3. refresh only while the All Units panel is visible, except for state reset/cleanup.

Relevant signature fields include:

- event ID;
- event turn/tick state required for the current-turn indicator;
- eventID;
- team;
- raidMarker;
- active/hidden state;
- health current/max values.

Do not add a continuous update loop.

---

# 18. Files Expected to Change

Primary files:

```text
client/ui/widgets/widget_Event_CombatLogHistory.lua
client/ui/widgets/widget_Event_AllUnits.lua        [new]
RPEngine2.toc
```

Likely supporting changes, only if required to avoid duplicated logic:

```text
client/ui/widgets/widget_Event.lua
client/client_Targeting.lua
core/classes/Event.lua
core/classes/EventUnit.lua
core/ui/prefabs/...                                [only if a reusable row prefab is justified]
```

The implementation should prefer extracting a small shared helper over copying existing hidden-unit or health-resolution logic into a third location.

---

# 19. Non-Goals

This feature does not add:

- another event synchronization protocol;
- another event-state cache;
- persistent UI settings;
- unit targeting;
- unit inspection;
- aura lists;
- threat per unit;
- resource displays other than health;
- DM controls;
- event-unit editing;
- portrait rendering;
- filters/search;
- sorting controls;
- collapsible teams.

These may be considered later if real usage justifies them.

---

# 20. Acceptance Criteria

The feature is complete when all of the following are true:

1. **All Units** appears alongside **Combat Log** and **Meters** in the event utility controls.
2. Selecting it reuses the existing movable utility window.
3. Switching among Combat Log, Meters and All Units never leaves overlapping panels visible.
4. All active event units are represented, including units outside the current turn/page.
5. Units are grouped by configured team name.
6. Units within a team are sorted by raid marker and then Event Unit ID.
7. Unmarked units appear after marked units.
8. Current-turn units remain in the list and receive a subtle indication.
9. Dead units remain visible at zero health and are visually muted.
10. Health values update without reopening the panel.
11. Hidden units do not expose concealed information to non-host clients.
12. The host retains appropriate visibility of hidden units.
13. Event end clears/hides stale All Units state.
14. Event rejoin/reload produces the same All Units state as a continuously connected client.
15. No new comms opcode or SavedVariables storage is introduced.
16. Combat Log and Meters retain their current behaviour.
17. The implementation does not add an OnUpdate/polling loop for unit-state refresh.

---

# 21. Implementation Order

Implement in three focused stages:

1. generalize the event utility window from binary Combat Log/Meters switching to explicit multi-mode panel switching;
2. implement the All Units panel, row model, grouping, sorting, health display and hidden-unit handling;
3. wire live refresh/reset behaviour and regression validation across event lifecycle, death, hidden state and rejoin.

This keeps the shared utility-window change separate from the unit presentation logic and makes regressions in the existing Combat Log/Meters UI easier to isolate.
