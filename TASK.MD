## Objective

Implement the actual Event Widget/runtime behavior for NPC Mode using the synchronized `eventMode` and `showInNpcMode` state from #298 and the host controls from #299.

NPC Mode is explicitly a **presentation mode**, not a combat-turn mode:

- the Event Widget shows only selected NPC EventUnits;
- player frames are never shown;
- combat turn/tick paging is not used to decide which frames are visible;
- there is no way to advance the event turn/tick while NPC Mode is active;
- switching back to Combat Mode resumes the existing combat turn/tick state.

Depends on #298. The Dashboard portions of the UX are implemented by #299.

Target branch: `dev`. Re-read the current implementation before editing.

## Current Event Widget behavior

`client/ui/widgets/widget_Event.lua` currently derives the normal portrait set from combat turn state:

```text
BuildPortraitRefreshContext(state)
  -> pageNumber = state.tickNumber
  -> getWidgetUnitsForPage(units, pageNumber, maxEventUnits)
```

`getWidgetUnitsForPage()` filters active non-boss units and pages them according to the current tick. Boss units are gathered separately by `collectBossUnits()` and rendered in the boss row.

The Event Widget also exposes a host `advanceEventStepFromWidget()` path, while the Event Manager has its own `Next Tick / Turn` control. The client-wide action gate is `Client:CanPerformEventAction(...)`, and the server owns the final `Server:AdvanceEventStep()` mutation.

NPC Mode must bypass the turn-page selection logic without damaging it for Combat Mode.

## Required changes

### 1. Add one canonical NPC-mode portrait selector

When:

```lua
eventState.eventMode == "npc"
```

derive the visible Event Widget unit set from the synchronized EventUnit flag introduced by #298.

Eligibility must be:

```text
unit.isPlayer ~= true
AND
unit.showInNpcMode == true
```

Do not use `tickNumber` or turn schedule membership to decide whether an eligible NPC is visible in NPC Mode.

The selection flag is explicit host presentation state. Therefore an NPC which is flagged for NPC Mode should not disappear merely because it is not on the current combat tick. Existing unit state such as `active`, dead/alive state, resources, cast state, etc. may still affect how its portrait is rendered, but not whether the explicitly selected NPC has a frame.

Player EventUnits must never appear in NPC Mode even if malformed/legacy data sets the flag true.

### 2. Apply the filter to both normal and boss portrait paths

The current boss path bypasses `getWidgetUnitsForPage()`. In NPC Mode:

- an unflagged boss must not appear merely because `boss == true`;
- a flagged boss may continue to use the existing boss portrait presentation/row;
- flagged non-boss NPCs use the normal portrait presentation.

Do not change boss behavior in Combat Mode.

`showInNpcMode` and `hidden` remain orthogonal. The new flag controls whether the frame exists; preserve the current hidden-unit presentation/masking rules rather than mutating `hidden` as a side effect.

### 3. Do not silently drop selected NPCs because there is no combat paging

NPC Mode has no turn/tick advance mechanism, so it cannot rely on the current combat page number to reveal additional selected units.

If the number of flagged NPCs exceeds the current normal portrait pool/capacity, the Event Widget must handle that as presentation state rather than silently hiding later flagged units behind nonexistent combat pages.

Use the narrowest layout change compatible with the current widget architecture, for example growing/wrapping portrait slots or another bounded multi-row presentation. Do not reintroduce a fake combat tick just to page the display.

The host-side `showInNpcMode` flag is intended to keep this list curated and normally small, but the client must still behave deterministically if too many are selected.

### 4. Remove turn-order presentation from NPC Mode

While NPC Mode is active, hide/neutralize Event Widget UI which only makes sense for combat turn progression, including:

- host `Next`/advance control;
- turn/tick progress indicators which imply a current combat page;
- current-turn-only portrait emphasis/turn-complete presentation where it would misleadingly imply that the displayed NPCs are the current combat actors.

Keep presentation that is still useful for the talking-head reference use case:

- portrait/model;
- name/raid marker/team presentation;
- health/resource bars;
- current cast/aura/resource visuals where already supported;
- host right-click NPC control, including the existing immediate `Speak` workflow.

Talking Head speech itself must **not** require `showInNpcMode == true`; the flag controls persistent Event Widget reference frames, not whether an NPC is allowed to speak.

### 5. Hard-block turn advancement outside the UI

NPC Mode must have no alternate path which can advance combat state.

Add a client action-gate check in `Client:CanPerformEventAction(eventState, actionKind)` so:

```lua
actionKind == "advance-event-step"
```

returns false with a specific reason such as:

```text
npc-mode
```

when `eventMode == "npc"`.

Also add a server-side guard at the start of `Server:AdvanceEventStep()` so direct/internal callers cannot bypass the client UI guard.

The rejected call must not change:

```text
turnNumber
tickNumber
totalTicks
turn completion state
pending turn state
resources/cooldowns/auras/casts
```

#299 will hide the Event Manager Dashboard button, but this issue owns the authoritative runtime protection.

### 6. Preserve combat state across mode switches

A live transition:

```text
Combat Mode -> NPC Mode -> Combat Mode
```

must resume the same combat position.

Do not reset or normalize the event onto tick 1 merely because NPC Mode was entered. The Event Widget should simply stop using combat paging while NPC Mode is active and resume using the stored `turnNumber`/`tickNumber` when Combat Mode returns.

The inbound `EVENT_STATE` mode change must cause an immediate structural Event Widget refresh on clients so players do not need to wait for another unit/resource/turn event to see the correct portrait set.

## Primary files to inspect

At minimum:

```text
client/ui/widgets/widget_Event.lua
client/client_Event.lua
server/server_Event.lua
core/classes/Event.lua
core/classes/EventUnit.lua
```

Also inspect the final implementation of #298 rather than assuming helper names.

Before changing `widget_Event.lua`, trace:

```text
BuildPortraitRefreshContext
getWidgetUnitsForPage
collectBossUnits
EnsurePortraitPool
EnsureBossPortraitPool
LayoutPortraitRow
Refresh / targeted refresh paths
host control-button visibility
turn-progress rendering
```

Do not create a second Event Widget or a separate NPC-frame window.

## Acceptance criteria

1. Combat Mode renders exactly as before.
2. NPC Mode shows no player EventUnit portraits.
3. NPC Mode shows only non-player units whose `showInNpcMode` value is true.
4. Flagged NPCs are not filtered by current combat tick/page.
5. Unflagged bosses do not leak through the separate boss portrait path; flagged bosses still render correctly.
6. Existing hidden-unit presentation semantics are preserved and the visibility flag never mutates `hidden`.
7. More flagged NPCs than the normal single-row capacity are handled deterministically without relying on turn advancement or silently making selected units unreachable.
8. Event Widget turn/tick advance controls and misleading turn-progress UI are absent/neutral in NPC Mode.
9. `Client:CanPerformEventAction(..., "advance-event-step")` rejects advancement in NPC Mode.
10. `Server:AdvanceEventStep()` independently rejects advancement in NPC Mode even if called directly.
11. Switching `combat -> npc -> combat` leaves the stored turn/tick state unchanged and Combat Mode resumes where it left off.
12. A live mode switch refreshes the Event Widget immediately on all clients.
13. Right-click NPC control and immediate Talking Head speech still work from NPC Mode frames.
14. An NPC may still produce a Talking Head even if it is not selected for persistent NPC Mode display.

## Non-goals

- Do not change spellcasting, NPC AI, threat, target selection, loot, or turn scheduling rules.
- Do not make NPC Mode a new `turnMode` value.
- Do not automatically set/clear `showInNpcMode` when an NPC speaks.
- Do not alter EventUnit `hidden` state when entering/leaving NPC Mode.