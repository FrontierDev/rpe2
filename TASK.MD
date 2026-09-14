## Objective

Allow the event host to make the NPC they are currently controlling speak immediately through the talking-head system.

Depends on: #292.

#293 is not a functional dependency; DM Helper queued speech and direct controlled-NPC speech are separate authoring surfaces using the same canonical runtime API.

Source document:

```text
.docs/RPE2-NPC-Talking-Heads-PDD.md
```

Target branch: `dev`.

## Current architecture to inspect

Before editing, re-read the current `dev` versions of at least:

```text
client/client_Event.lua
client/ui/widgets/widget_ActionBar.lua
client/ui/widgets/widget_ActionBar_Control.lua
client/ui/widgets/widget_Event.lua
core/ui/elements/ClipboardTextArea.lua
core/ui/elements/TextButton.lua
core/ui/elements/Panel.lua
core/ui/Popup.lua
RPEngine_Dev.toc
```

Also inspect the final NPC speech emitter/API implemented by #292.

Do not assume the PDD's suggested function/file names if #292 implemented an equivalent with different names.

## Existing control path

The Event Widget currently allows the host to take control of an NPC from its portrait, reaching the existing client control state:

```text
Event Widget portrait right-click
    -> Client:TakeControlOfEventUnit(eventUnit)
    -> Client.ControlledEventUnitId
    -> Client:GetActionBarControlContext()
    -> ActionBar controlled-NPC rows/chrome
```

`widget_ActionBar_Control.lua` already renders the controlled-unit label using:

- raid marker;
- unit name;
- EventUnit ID;

and handles release/end-turn/control chrome.

Extend this existing controlled-unit surface. Do not introduce a second NPC-control window.

## Required changes

### 1. Add a host-only `Speak` control to controlled-NPC chrome

When the local player is the active event host and the current action-bar control context represents a non-player EventUnit, show a `Speak` control near the existing controlled-unit label/buttons.

Conceptually:

```text
Controlling {skull} Defias Captain (#12)             [Speak] [X]
```

The button must not appear for:

- ordinary player action-bar mode;
- a participant controlling their own pet/companion where they are not the event host;
- inactive/ending event state;
- missing/stale controlled unit;
- any context that fails the current control/host checks.

Do not infer authority from the button being visible: the send path must still validate through #292's canonical speech API.

### 2. Add a compact freeform speech editor

Clicking `Speak` should open a small editor anchored to the Action Bar/control chrome or another existing RPE popup convention.

Required UI:

- speaker context showing raid marker + name + EventUnit ID;
- multiline editable text area;
- `Send` button;
- `Cancel`/close behavior;
- visible validation/error feedback for rejected/empty/too-long/stale speech.

Do not use Blizzard chat edit boxes or send `/say`, `/yell`, PARTY, or RAID chat. This is an RPE NPC talking-head message.

Use existing RPE UI primitives (`Panel`, `ClipboardTextArea`, `TextButton`, `Popup`, etc.) rather than a new XML/template subsystem.

### 3. Send through #292's canonical runtime API

On Send:

1. re-resolve the current controlled-unit context;
2. confirm the same EventUnit is still controlled and valid;
3. confirm local host authority/current active event;
4. trim/validate text through the canonical NPC speech path;
5. call the canonical emitter from #292 using the controlled EventUnit ID;
6. only clear/close the editor after a successful local emission, unless current UX conventions favor keeping it open for repeated lines.

The UI must not:

- call `Comms:SendMessage()` directly;
- construct its own `speechId` if #292 owns speech identity generation;
- resolve or serialize portrait/team/name metadata itself;
- directly queue the Event Widget presentation.

### 4. Speech is not a gameplay action

Immediate NPC speech must not affect combat/action state.

Sending speech must not:

- consume an action;
- end the controlled NPC's turn;
- start/finish a Spell;
- spend resources;
- trigger GCD/cooldown;
- change movement state;
- create a pending Autopilot action;
- write to combat-log history.

It is host-authored presentation only.

### 5. Controlled-unit changes and editor lifecycle

The editor must be bound to the controlled EventUnit identity that opened it.

If any of the following occurs while it is open:

```text
Client:ReleaseControl(...)
host takes control of a different EventUnit
event ends/starts ending
controlled unit becomes invalid/inactive
Event Widget/control context is rebuilt
```

then the old editor must close or invalidate its draft. It must never send the text as whichever NPC happens to be controlled later.

If the implementation keeps a draft while the same NPC remains controlled, key it by event ID + EventUnit ID, not by a generic global text field.

No draft persistence is required across `/reload` or event teardown.

### 6. Repeated immediate speech

The host must be able to send multiple dialogue messages from the same controlled NPC during the event.

Each successful send should become a separate #292 speech emission and therefore enter the shared FIFO presentation queue normally.

Do not replace the currently displayed talking head in-place simply because the same NPC speaks again.

### 7. Layout integration

Preserve existing controlled action-bar behavior:

- controlled NPC spell rows remain usable;
- release-control button remains usable;
- existing control label remains readable;
- end-turn behavior remains unchanged;
- action-bar sizing/positioning must not jump significantly when Speak is shown/hidden.

If the existing control label's reserved-right-width calculation is used to avoid button overlap, include Speak in that same layout accounting rather than hard-coded overlapping anchors.

## Expected file scope

Primary file:

```text
client/ui/widgets/widget_ActionBar_Control.lua
```

Potentially:

```text
client/ui/widgets/widget_ActionBar.lua
```

Only modify #292 runtime files if a narrowly required public helper is missing. Do not duplicate NPC speech logic inside Action Bar code.

## Deterministic validation

Exercise with mocked control/event contexts where possible:

1. active host controlling NPC -> Speak visible;
2. host not controlling an NPC -> Speak hidden;
3. non-host participant controlled-pet context -> Speak hidden;
4. controlled unit becomes stale/inactive -> Speak/editor invalidated;
5. opening editor shows exact current speaker marker/name/EventUnit ID;
6. empty/whitespace text cannot send;
7. valid text calls #292 emitter exactly once with current `speakerEventId`;
8. failed emitter response does not falsely report success;
9. release control while editor is open prevents later Send;
10. switch control from NPC A to NPC B while A editor is open cannot send A draft as B;
11. two successful sends from one NPC create two distinct queued speech emissions;
12. sending speech does not mutate turn/action/resource/cooldown/movement state;
13. controlled NPC Spell buttons still function normally after adding the Speak control;
14. event teardown closes the editor and leaves no stale runtime draft.

## In-game regression checks

Verify:

```text
right-click NPC portrait -> control still works
controlled action bar -> spells still cast normally
Speak -> talking head appears for host and participants
rapid two-line speech -> both messages queue rather than overlap
release control -> normal action bar state returns
participant pet control -> no host NPC Speak UI leaks in
```

## Acceptance criteria

- [ ] Host sees a `Speak` control while directly controlling a valid NPC EventUnit.
- [ ] Speak opens a compact freeform dialogue editor showing the exact controlled speaker identity.
- [ ] Sending uses #292's canonical NPC speech API and produces the normal synchronized talking head.
- [ ] The UI revalidates the controlled EventUnit immediately before sending.
- [ ] Stale control/editor state cannot make another NPC speak the old draft.
- [ ] Multiple immediate speech messages queue normally through the shared presentation scheduler.
- [ ] NPC speech consumes no action economy/resources/cooldowns and does not enter combat-log history.
- [ ] Existing controlled-NPC action-bar behavior has no regression.

## Non-goals

- DM Helper queued speech cues (#293).
- NPC speech macros/presets.
- AI-generated dialogue.
- Voice/audio playback.
- Player-character speech.
- Persistent dialogue history or replay.