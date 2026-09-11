# RPE 2 — First-Run Help System and Minimap Launcher

**Status:** Draft  
**Target:** RPEngine 2.0 (`FrontierDev/rpe2`)  
**Scope:** Minimap launcher button, first-run contextual help tips, persistent tutorial acknowledgement state  
**Out of scope:** Full guided tutorial scenarios, gameplay automation, replacing existing tooltips, Blizzard `TutorialManager`

---

# 1. Purpose

RPE 2 has grown into a multi-window addon with several important interaction surfaces:

- the RPE launcher menu;
- the Profile window;
- the Event widget;
- the Action Bar;
- the Event Manager and other authoring tools.

A new user currently has no lightweight in-game introduction to these systems. The addon should provide a small, contextual first-run help system using Blizzard's native `HelpTip` presentation rather than creating another custom tutorial-frame implementation.

This project has two related goals:

1. add a persistent RPE minimap icon which opens the RPE launcher menu when left-clicked;
2. add contextual HelpTips which appear the first time the player reaches important addon surfaces.

The help system must remain unobtrusive. Tips should explain controls at the moment those controls become relevant, should normally appear only once, and should not block gameplay.

---

# 2. Existing RPE Architecture Relevant to This Feature

## 2.1 The launcher menu already exposes the correct open/close API

`client/ui/windows/window_LauncherMenu.lua` owns the RPE main menu.

It already exposes:

```lua
Client:BuildLauncherMenu()
Client:ShowLauncherMenu()
Client:HideLauncherMenu()
Client:ToggleLauncherMenu()
```

The minimap button therefore does not need to duplicate launcher logic. Its left-click handler should call:

```lua
Client:ToggleLauncherMenu()
```

The launcher also retains its generated buttons in:

```lua
self.buttons[entry.label]
```

and its section layouts in:

```lua
self.groupLayouts[group.key]
```

These provide stable anchors for menu HelpTips after `BuildWindow()` has run.

---

## 2.2 `/rpe` already opens the same launcher menu

`Commands.lua` routes an empty `/rpe` command to:

```lua
Client:ToggleLauncherMenu()
```

The minimap icon should use that same public launcher entry point. There should be only one implementation of launcher visibility behavior.

---

## 2.3 RPE already has account-wide/global persisted settings

The TOC already declares:

```text
RPEngineGlobalSettingsDB
```

`core/internal/database/Database.lua` exposes global settings storage through:

```lua
Database.GetGlobalSetting(...)
Database.SetGlobalSetting(...)
```

This is the correct location for help acknowledgement state and minimap-button state.

First-run HelpTips are an addon/UI preference, not character progression, so they should **not** be stored on the character Profile.

---

## 2.4 The Profile window centralizes all page selection

`client/character/profile/window_Profile.lua` owns these tabs:

```text
Equipment & Stats
Spellbook
Traits
Skills
Achievements
```

Each page is constructed from the central `tabs` table and refreshed from `RefreshTab()` / `ShowTab()`.

This makes `window_Profile.lua` the correct coordination point for page-level HelpTips. Individual pages should expose useful anchor frames, but should not each implement their own tutorial persistence or lifecycle.

---

## 2.5 Event startup already has an explicit readiness boundary

`client/client_Event.lua` has a staged startup pipeline and tracks:

```lua
eventState.unitsReady
eventState.startupReady
eventState.startupPhase
```

Normal event actions are rejected until:

```lua
eventState.startupReady == true
```

The first-event HelpTip should therefore be triggered only after the event is fully ready, not directly when `HandleEventStart()` first receives the start message.

This avoids showing help while portraits/action-bar metadata are still loading and avoids coupling tutorial behavior to an intermediate network state.

---

## 2.6 The Action Bar already owns the player's active-turn controls

`client/ui/widgets/widget_ActionBar_Control.lua` creates and owns:

```lua
self.endTurnButton
self.movementRangeBar
self.controlLabel
```

The `End Turn` button directly calls:

```lua
Client:EndTurn()
```

and the control refresh path already decides when the event/action state permits that control to be visible.

The first-player-turn HelpTip should be emitted from the same Action Bar control-state transition that makes the player's turn controls usable. This is more reliable than separately reimplementing turn ownership detection inside the help system.

---

# 3. Blizzard HelpTip Integration

RPE should use Blizzard's native `HelpTip` API.

Typical Blizzard usage is conceptually:

```lua
local helpTipInfo = {
    text = "...",
    buttonStyle = HelpTip.ButtonStyle.Close,
    targetPoint = HelpTip.Point.RightEdgeCenter,
    system = "RPE",
    onAcknowledgeCallback = function()
        -- persist acknowledgement
    end,
}

HelpTip:Show(UIParent, helpTipInfo, targetFrame)
```

RPE should use Blizzard's presentation component but own its own tutorial state.

Do **not** use Blizzard's `closedInfoFrames` bitfield or Blizzard tutorial IDs. Those are Blizzard-owned global UI state and should not be consumed by an addon.

Do **not** integrate with Blizzard's `TutorialManager`. RPE only needs contextual presentation and acknowledgement, not Blizzard's tutorial lifecycle.

The TOC targets Interface `120100`, so the primary implementation may use the current retail HelpTip system directly. The wrapper should still fail safely if `HelpTip` is unexpectedly unavailable.

---

# 4. Design Principles

The help system should follow these rules:

1. **Contextual, not front-loaded.** A user should not receive a chain of unrelated tips immediately after login.
2. **Show a tip only when its target exists and is visible.**
3. **Each concept is independently acknowledged.** Closing one tip must not suppress unrelated future tips.
4. **Gameplay is never blocked.** No modal dialog is required to continue.
5. **Use stable UI ownership points.** The Help system should react to launcher/profile/event/action-bar lifecycle calls instead of polling arbitrary frame state.
6. **Persistence is account-wide.** A user who understands the Profile window on one character should not receive the same basic Profile tips on every alt.
7. **The system must be resettable for testing and for users who want to replay help.**
8. **Tips should describe what to do, not document every feature.** Existing item/spell/stat tooltips remain responsible for detailed information.

---

# 5. Minimap Launcher Button

## 5.1 Implementation approach

No LibDataBroker/LibDBIcon integration exists in the current repository. Adding those libraries solely for one launcher button would introduce a new external dependency for behavior that can be implemented locally with a normal Blizzard `Button` parented to `Minimap`.

Create a native RPE minimap-button module.

Proposed file:

```text
client/ui/minimap/button_Minimap.lua
```

Proposed namespace:

```lua
Addon.Client.UI.MinimapButton
```

---

## 5.2 Appearance

Use the existing RPE icon:

```text
Interface\AddOns\RPEngine_Dev\data\textures\ui\rpe.png
```

The button should use a conventional circular minimap-button presentation:

- approximately 31–32 px square;
- RPE icon centered inside;
- Blizzard minimap button border/overlay where suitable;
- highlight on hover;
- tooltip on hover.

Tooltip:

```text
RPE
Left-click to open the RPE menu.
```

---

## 5.3 Click behavior

Required behavior:

```text
Left Click
    -> Client:ToggleLauncherMenu()
```

No separate launcher state should be kept by the minimap module.

Right-click behavior is not required by this project and should be left unused rather than inventing a second menu.

---

## 5.4 Dragging

The icon should be draggable around the edge of the minimap.

Store only its angular position, or an equivalent normalized minimap position, in global settings.

Example:

```lua
Database.SetGlobalSetting("minimapButton", {
    angle = 220,
    hidden = false,
})
```

The button should remain clamped to the minimap perimeter and restore its position on reload/login.

A hidden setting may be included now even if no UI toggle is initially exposed, so future settings integration does not require changing the storage shape.

---

# 6. Help System Runtime

Create one central manager.

Proposed file:

```text
client/client_Help.lua
```

Proposed namespace:

```lua
Addon.Client.Help
```

Responsibilities:

```text
register tip definitions
check whether a tip is acknowledged
validate a target frame
show a Blizzard HelpTip
persist acknowledgement
hide active RPE HelpTips
reset all RPE help state
coordinate simple sequencing within the same surface
```

No Profile page, Event widget, launcher, or minimap module should directly write help persistence state.

---

# 7. Persistent Help State

Use one global-setting record.

Recommended shape:

```lua
{
    schema = 1,

    acknowledged = {
        ["minimap.open-menu"] = true,
        ["launcher.profile"] = true,
        ["profile.equipment"] = true,
        ["event.first-start"] = true,
        ["event.first-player-turn"] = true,
    },
}
```

Storage key:

```text
help
```

Access through:

```lua
Database.GetGlobalSetting("help", {})
Database.SetGlobalSetting("help", state)
```

Tip IDs must be stable strings and must never depend on array position.

This allows future releases to add new tips without resetting already-acknowledged tips.

---

# 8. Acknowledgement Semantics

A tip becomes acknowledged when either:

1. the user explicitly closes the HelpTip; or
2. the user performs the action the tip was teaching.

For example:

```text
minimap.open-menu
```

is acknowledged when the user either closes the tip or left-clicks the minimap button to open the RPE menu.

Likewise:

```text
launcher.profile
```

may be acknowledged when the user opens one of the Profile destinations.

This prevents a user from performing the correct action and then receiving the same instruction again because they did not separately click the HelpTip close button.

The central manager should provide helpers similar to:

```lua
Help:IsAcknowledged(id)
Help:Acknowledge(id)
Help:Show(id, targetFrame, overrides)
Help:Hide(id)
Help:HideAll()
Help:Reset()
```

---

# 9. Tip Scheduling

Only one RPE HelpTip should normally be visible at once.

The manager should maintain one active RPE HelpTip identity and use one HelpTip system name, for example:

```text
RPE First Run
```

Before showing a different RPE tip:

```lua
HelpTip:HideAllSystem("RPE First Run")
```

This avoids several overlapping callouts when a window opens and multiple eligible tips become available simultaneously.

A tip which cannot currently be displayed because its target is absent/hidden remains unacknowledged and is retried the next time the relevant surface is shown.

---

# 10. Initial HelpTip Set

The first implementation should include the following tips.

---

## 10.1 Minimap — Open the RPE menu

**ID**

```text
minimap.open-menu
```

**Trigger**

First login/reload after the Help system is introduced, once the minimap button exists.

**Anchor**

RPE minimap button.

**Suggested text**

> Click the RPE icon to open the RPE menu.

**Purpose**

Teach the permanent entry point into the addon.

**Acknowledge additionally when**

The player left-clicks the minimap button.

This is the only tip that should proactively appear during ordinary login.

---

# 11. Launcher Menu Help

Tips in this group should only appear once the user opens the RPE launcher menu.

The existing launcher already exposes its section layouts and generated buttons, so no frame discovery should be necessary.

The initial menu tutorial should explain the three conceptual groups rather than every individual button.

---

## 11.1 Profile section

**ID**

```text
launcher.profile
```

**Anchor**

The Profile group, preferably the `Equipment` button or Profile group heading frame.

**Suggested text**

> Character tools are here. View your equipment, spells, skills, inventory, setup and guild features.

---

## 11.2 Event section

**ID**

```text
launcher.event
```

**Anchor**

`Event Manager` button.

**Suggested text**

> Event tools are here. Event hosts can configure and manage RPE events, and you can show or hide your Action Bar.

---

## 11.3 Settings/content section

**ID**

```text
launcher.content
```

**Anchor**

`Data Editor` button.

**Suggested text**

> Create or import RPE data and rules here. These tools are mainly for campaign and ruleset authors.

---

## 11.4 Launcher sequencing

Do not display all three at once.

Recommended sequence:

```text
launcher.profile
    -> acknowledge
launcher.event
    -> acknowledge
launcher.content
```

If the launcher is closed mid-sequence, stop displaying launcher HelpTips. Resume from the first unacknowledged launcher tip the next time the launcher opens.

`LauncherMenu:Show()` is the correct lifecycle hook to request the next launcher HelpTip after the window is visible.

`LauncherMenu:Hide()` should hide the active launcher tip but must not acknowledge it merely because the menu closed.

---

# 12. Profile Window Help

Profile help should be page-specific and triggered when a page is actually shown for the first time.

`window_Profile.lua` already centralizes tab builders and tab activation, so after `RefreshTab(tabKey)` / `ShowTab(tabKey)` the window can call:

```lua
Help:ShowProfileTip(tabKey)
```

The page modules should expose stable primary anchor frames/elements where necessary.

The Help manager should not inspect arbitrary child-frame names.

---

## 12.1 Equipment & Stats

**ID**

```text
profile.equipment
```

**Primary anchor**

The equipment-slot area or first equipment slot.

**Suggested text**

> Equip RPE items here. Your resolved health, resources and combat stats are shown alongside your equipment.

The current page already owns explicit equipment slot widgets, equipment scope controls, health/resource presentation and the stats panel, so this is a natural single summary tip rather than several micro-tips.

---

## 12.2 Spellbook

**ID**

```text
profile.spellbook
```

**Primary anchor**

The spell list/grid area.

**Suggested text**

> Your available RPE spells are listed here. Spells can be placed on the RPE Action Bar for use during events.

If the page has no spells, anchor to the page's empty-state/container frame rather than suppressing the tip permanently.

---

## 12.3 Traits

**ID**

```text
profile.traits
```

**Primary anchor**

The trait list/grid.

**Suggested text**

> Traits provide passive character effects. Active traits and their effects are shown here.

---

## 12.4 Skills

**ID**

```text
profile.skills
```

**Primary anchor**

The skills list.

**Suggested text**

> Skills determine your modifiers for RPE skill rolls. Skills may also be placed on the Action Bar when using the skills bar mode.

---

## 12.5 Achievements

**ID**

```text
profile.achievements
```

**Primary anchor**

The achievement list.

**Suggested text**

> Your RPE achievements and their progress are tracked here.

---

# 13. First Event Start Help

## 13.1 Trigger boundary

**ID**

```text
event.first-start
```

Do not trigger this from the initial `EVENT_START`/`HandleEventStart()` receipt.

Trigger only after the client's staged startup pipeline reaches:

```lua
eventState.startupReady == true
```

and the Event widget has refreshed into its normal ready state.

This guarantees that the UI being explained is actually present and interactive.

---

## 13.2 Anchor

Anchor to the Event widget's main header/banner or primary event container.

If the Event widget's build module does not currently expose a stable header frame publicly, add a small accessor such as:

```lua
EventWidget:GetHelpAnchor("event")
```

rather than having the help system reach into private frame structure.

---

## 13.3 Suggested text

> This is the Event display. It shows the current event, participating units, turn order and recent event activity.

The purpose of this first event tip is orientation, not a full combat tutorial.

---

## 13.4 Host-specific follow-up

An optional second first-run tip may be shown only for the event host.

**ID**

```text
event.host-controls
```

**Anchor**

The Event widget's host control row (`Manage Event`, advance/stop controls).

**Suggested text**

> As the event host, you can manage the event and advance its turn state from these controls.

This tip should never appear for ordinary participants.

---

# 14. First Player Turn Help

## 14.1 Trigger boundary

**ID**

```text
event.first-player-turn
```

The Action Bar should trigger this tip at the point where its control refresh determines that the player's active-turn controls are available.

The recommended integration point is `ActionBarWidget:RefreshControlState(...)` in:

```text
client/ui/widgets/widget_ActionBar_Control.lua
```

When the `End Turn` button transitions from not usable/hidden to usable/visible for the player's own turn, request the HelpTip.

This deliberately avoids duplicating turn ownership calculations in `client_Help.lua`.

---

## 14.2 Anchor

Anchor to the Action Bar, preferably the `End Turn` button for the initial tip.

**Suggested text**

> It is your turn. Use your Action Bar to cast spells or perform actions, then click End Turn when you are finished.

If a movement range bar is active, the same tip is sufficient; a separate movement tutorial can be added later if user testing shows it is needed.

---

## 14.3 Action acknowledgement

The tip should also be acknowledged when the user successfully ends their turn.

Closing the tip manually also acknowledges it.

It must not appear on every later turn.

---

# 15. Proposed Help Definition Model

Keep tip content declarative where possible.

Example:

```lua
local HELP_TIPS = {
    ["minimap.open-menu"] = {
        text = "Click the RPE icon to open the RPE menu.",
        targetPoint = HelpTip.Point.RightEdgeCenter,
    },

    ["launcher.profile"] = {
        text = "Character tools are here. View your equipment, spells, skills, inventory, setup and guild features.",
        targetPoint = HelpTip.Point.RightEdgeCenter,
    },

    ["event.first-player-turn"] = {
        text = "It is your turn. Use your Action Bar to cast spells or perform actions, then click End Turn when you are finished.",
        targetPoint = HelpTip.Point.BottomEdgeCenter,
    },
}
```

Trigger rules and frame resolution should remain code because they depend on live RPE UI state.

Do not embed executable callbacks in data files or datasets.

---

# 16. Help Anchor Contract

For reusable/complex UI modules, expose explicit help anchors instead of making `client_Help.lua` depend on internal widget fields.

Recommended convention:

```lua
function SomeUI:GetHelpAnchor(key)
    ...
end
```

Example keys:

```text
launcher.profile
launcher.event
launcher.content
profile.primary
event.primary
event.host-controls
actionbar.end-turn
```

For very simple components, passing the frame directly when notifying the Help manager is also acceptable.

The critical rule is that the Help manager should not duplicate layout knowledge.

---

# 17. Reset / Replay Support

Add a command for development and user recovery:

```text
/rpe help reset
```

Behavior:

```text
clear RPE help acknowledgement map
hide any active RPE HelpTip
print confirmation
```

Optionally also add:

```text
/rpe help status
```

for development diagnostics, listing acknowledged/unacknowledged tip IDs.

The reset command is especially important because HelpTips are one-time behavior and otherwise difficult to repeatedly test.

A future general Settings window may expose a `Reset Help Tips` button, but that is not required for this implementation.

---

# 18. Minimap Help State vs. Minimap Configuration

Keep these separate.

Example:

```lua
Database.SetGlobalSetting("minimapButton", {
    angle = 220,
    hidden = false,
})

Database.SetGlobalSetting("help", {
    schema = 1,
    acknowledged = {
        ["minimap.open-menu"] = true,
    },
})
```

Moving or hiding the button must never reset tutorial state.

Resetting tutorials must never reset the button position.

---

# 19. Login Lifecycle

The intended initial login flow is:

```text
addon loads
    ↓
Database/global settings available
    ↓
create minimap button
    ↓
minimap button positioned from saved settings
    ↓
if minimap.open-menu is unacknowledged
    ↓
show HelpTip on minimap button
```

Do not automatically open the RPE launcher menu on first login.

The player's first interaction with the minimap icon should open it naturally.

---

# 20. Launcher Lifecycle

```text
LauncherMenu:Show()
    ↓
window visible
    ↓
Help:OnLauncherShown(launcher)
    ↓
show first unacknowledged launcher tip
```

When an entry is clicked:

```text
acknowledge the relevant launcher concept if applicable
    ↓
normal launcher action
    ↓
launcher hides
```

The launcher remains responsible only for navigation; the Help manager owns which help tip comes next.

---

# 21. Profile Lifecycle

```text
ProfileWindow:Show()/ShowTab(tabKey)
    ↓
active tab selected
    ↓
page built/refreshed
    ↓
Help:OnProfileTabShown(tabKey, page)
```

The help request should occur after the page is built so its anchor exists.

Switching tabs should hide a HelpTip anchored to a page that is no longer visible.

An unacknowledged page tip may then be displayed the next time that page is selected.

---

# 22. Event Lifecycle

```text
HandleEventStart(...)
    ↓
staged event startup
    ↓
units ready
    ↓
action bar metadata / traits / auras / resources ready
    ↓
startupReady = true
    ↓
Event widget normal refresh
    ↓
Help:OnEventReady(eventState)
```

On event end:

```text
Help:OnEventEnded()
    ↓
hide event/action-bar HelpTips without acknowledging them automatically
```

This matters if an event is aborted immediately after a help callout appears.

---

# 23. Player Turn Lifecycle

```text
ActionBarWidget:RefreshControlState(...)
    ↓
normal RPE turn/control resolution
    ↓
End Turn control becomes available for local player's turn
    ↓
Help:OnLocalTurnAvailable(actionBar)
    ↓
show event.first-player-turn if unacknowledged
```

The Help manager should not poll `eventState.turnNumber` or inspect event-unit ownership every frame.

---

# 24. Proposed Module Layout

```text
client/
  client_Help.lua                         [new]

  ui/
    minimap/
      button_Minimap.lua                  [new]

    windows/
      window_LauncherMenu.lua             [modify]

    widgets/
      widget_Event.lua                    [modify: help anchor / ready callback]
      widget_ActionBar_Control.lua        [modify: local-turn help callback]

  character/
    profile/
      window_Profile.lua                  [modify: tab help lifecycle]
      page_ProfileEquipmentStats.lua      [minor: expose anchor if required]
      page_ProfileSpellbook.lua           [minor: expose anchor if required]
      page_ProfileTraits.lua              [minor: expose anchor if required]
      page_ProfileSkills.lua              [minor: expose anchor if required]
      page_ProfileAchievements.lua        [minor: expose anchor if required]

Commands.lua                              [modify: /rpe help reset]
RPEngine_Dev.toc                          [modify: load new modules]
```

No new SavedVariables declaration is required because `RPEngineGlobalSettingsDB` already exists.

---

# 25. Loading Order

The Help runtime must load after:

```text
Database.lua
```

so global settings accessors exist.

It must load before UI modules which call into it.

Recommended TOC order conceptually:

```text
...
core/internal/database/Database.lua
...
client/client_Help.lua
...
core/ui/...
client/ui/minimap/button_Minimap.lua
client/ui/widgets/...
client/ui/windows/window_LauncherMenu.lua
...
```

If the minimap button requires UI primitives from `core/ui`, place the minimap module after those primitives instead; `client_Help.lua` itself need not build custom RPE UI.

---

# 26. Failure Handling

The Help system is optional UX and must never prevent addon functionality.

If Blizzard `HelpTip` is unavailable:

```text
Help:Show(...)
    -> return false
    -> do not throw
    -> normal RPE UI continues
```

The minimap button itself must still work.

If a requested help anchor is missing:

```text
return without acknowledgement
```

so the tip can be retried later after the relevant UI is correctly built.

---

# 27. Performance Constraints

The system should be effectively event-driven.

Do not add:

- per-frame help polling;
- event-state scanning loops;
- repeated profile refresh work;
- repeated HelpTip construction every frame.

Tip eligibility checks are trivial map lookups and should occur only at existing UI lifecycle boundaries.

The only existing updater involved in turn behavior is the Action Bar's own control updater; the help integration should piggy-back on the resolved transition rather than add another updater.

---

# 28. Accessibility / UX Constraints

- Keep tip text short enough to read without obscuring the RPE UI.
- Prefer edge anchors which keep the target control visible.
- Never cover the button the tip is asking the user to click if an alternative HelpTip point is available.
- Closing a HelpTip should not perform the underlying action.
- HelpTips should remain dismissible through Blizzard's standard close affordance.
- Do not play repeated sounds for HelpTips unless Blizzard's own component does so automatically.
- Only one RPE HelpTip should normally be visible at a time.

---

# 29. Acceptance Criteria

## Minimap button

```text
An RPE icon appears on the minimap after login.

Left-clicking the icon toggles the existing RPE launcher menu.

The icon is draggable around the minimap edge.

Its position survives /reload and relogging.

Opening the menu from /rpe and opening it from the minimap use the same launcher implementation.
```

## First-run Help system

```text
A fresh global settings state shows the minimap HelpTip.

Closing or using the minimap tip records acknowledgement.

Reloading does not show an acknowledged tip again.

Opening the launcher presents launcher tips one at a time.

Closing the launcher does not falsely acknowledge an unfinished launcher tip.

Opening each Profile tab for the first time can show its corresponding HelpTip.

Profile tips are anchored only after their page exists.

The first event tip does not appear while event startup is still waiting for units/resources/UI readiness.

The first event tip appears once startupReady is true and the Event widget is usable.

The first-player-turn tip appears when the Action Bar exposes the player's usable turn controls.

The player-turn tip does not appear on every subsequent turn.

Ending an event hides event-related HelpTips cleanly.

Only one RPE HelpTip is normally visible at once.

/rpe help reset causes the first-run tips to become eligible again.
```

## Persistence

```text
Help state is stored in RPEngineGlobalSettingsDB.

Help acknowledgement is account-wide rather than character Profile state.

Minimap position is independent from help acknowledgement state.

No Blizzard closedInfoFrames bits are used for RPE state.
```

## Robustness

```text
Missing HelpTip APIs do not break RPE.

Missing/hidden target frames do not cause Lua errors.

No new OnUpdate loop exists solely for tutorial handling.

The help system does not duplicate event-turn ownership logic.
```

---

# 30. Explicit Non-Goals

This project does not implement:

```text
A mandatory step-by-step tutorial campaign
A modal tutorial wizard
Blizzard TutorialManager integration
Blizzard closedInfoFrames allocation
Video tutorials
Automatic opening of RPE windows on login
A new custom HelpTip visual system
Documentation for every Data Editor field
Tutorial synchronization between players
Character-specific tutorial progression
LibDataBroker or LibDBIcon solely for the minimap button
```

---

# 31. Principal Architectural Decisions

**The minimap icon calls the existing `Client:ToggleLauncherMenu()` API rather than introducing a second menu path.**

**The minimap button is implemented natively because the repository currently has no LibDataBroker/LibDBIcon dependency.**

**Blizzard `HelpTip` supplies presentation; RPE owns acknowledgement and sequencing.**

**RPE help state is persisted through `RPEngineGlobalSettingsDB`, not Profile state and not Blizzard's tutorial CVars.**

**Each HelpTip has a stable independent ID, allowing new tips to be added in later versions without resetting old ones.**

**The launcher window is the insertion point for launcher help because it already owns stable section/button frames.**

**The Profile window coordinates page tips because it already owns tab activation and refresh lifecycle.**

**The first-event tip triggers only at the existing `startupReady` boundary.**

**The first-player-turn tip is driven by the Action Bar's existing control-state transition, avoiding a second implementation of turn ownership logic.**

**The help runtime is event-driven and adds no new polling loop.**
