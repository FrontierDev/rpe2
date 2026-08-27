## Static validation: FAIL — host event-step advancement bypasses the transition readiness gate

Validated commit `bffcec9c169dadad6970f5ab207cdaef200bb69f` (`Issue #66`). `TASK.MD` is intentionally ignored.

The transition/state-machine work is substantially present: `Client:CanPerformEventAction(...)` centrally rejects actions while the matching event is starting/ending, and the implementation wires that gate into local spell activation/lifecycle, targeting mutation/confirmation, reactions, `Client:EndTurn()`, pending-turn flush, and companion control. Startup/end phases are also represented explicitly and the content-scaled trait/aura/resolved-state work uses the #65 continuation/sliceable infrastructure.

### Blocking defect

The **host authoritative advance path is not gated through `Client:CanPerformEventAction(...)`**.

There are two concrete entry points:

1. `client/ui/widgets/widget_Event.lua`

`advanceEventStepFromWidget()` calls `Server:AdvanceEventStep()` directly. The widget's refresh logic only disables the button using local `state.unitsReady` / `state.startupReady`; the click handler itself does not re-check the central transition gate. Because transition visual refresh is deferred/coalesced, a previously-enabled button can remain clickable briefly after `HandleEventEnd()` synchronously marks the local event as ending / not-ready.

2. `server/ui/eventmanage/page_EventManageDashboard.lua`

`AdvanceEventStepButton` calls `Server:AdvanceEventStep()` directly with no client-transition check at all. The dashboard enablement in `page_EventManageShared.lua` is based on the **server** event being active and `unitsReady`; it does not know whether the matching local client event is still in `EventTransition.kind == "starting"` or `"ending"`.

This creates a larger deterministic failure case during high-content startup: server `unitsReady` can already be true while the client is still slicing trait runtime, automatic/event aura sync, resolved-state work, resource sync, or consumable prompts. The host can press **Next Tick / Turn** from Event Manager and advance authoritative event state while the local startup transition is incomplete.

That violates #66's explicit requirements:

- conflicting end-turn/advance-related actions must be rejected while authoritative transition work is incomplete;
- use the central transition/readiness check rather than scattered UI flags;
- no partial authoritative mutation during starting/ending state.

### Required fix

Route every local-host event-step advance entry point through the existing central readiness gate before calling `Server:AdvanceEventStep()`.

At minimum:

- `client/ui/widgets/widget_Event.lua`: `advanceEventStepFromWidget()` must resolve the matching client event state and require `Client:CanPerformEventAction(eventState, "advance-event-step") == true` immediately before the server call.
- `server/ui/eventmanage/page_EventManageDashboard.lua`: the `AdvanceEventStepButton` handler must perform the same authoritative click-time check before calling `Server:AdvanceEventStep()`.
- Update Event Manager dashboard enablement so the button is visibly disabled while the matching local event is starting/ending/not `startupReady`, but **do not rely on enablement alone**; retain the click-time gate to protect against stale UI state.
- Prefer reusing `Client:CanPerformEventAction(...)` (or a single thin host-advance wrapper around it) rather than adding another transition flag/readiness implementation.
- This does not require changing server transition semantics; the local host UI entry points can enforce the gate before invoking the authoritative server advance.

### Revalidation after fix

1. Start a simple event: advance remains blocked until the client transition reaches ready, then works normally.
2. Start a high-content event: while startup phases are still slicing, both the event widget and Event Manager **Next Tick / Turn** remain disabled; forced/stale click attempts do not advance server `turnNumber`/`tickNumber`.
3. End an event while either advance control was previously enabled: neither control can advance the event during the ending transition.
4. Re-run static checks for the existing spell/targeting/reaction/end-turn/companion gates and startup/end stale-generation handling.
5. If static validation then passes, proceed to the issue's mandatory in-game start/end performance gate rather than closing immediately.

No configured commit-status checks are present. #66 remains open.