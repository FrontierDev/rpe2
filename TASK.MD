## Goal
Advance `rpe_event_started` criteria exactly once from the accepted authoritative RPE Event-start path.

Depends on: #23, #24

## Primary files
- `client/client_Event.lua`
- `client/client_Achievements.lua`

## Authoritative integration point
Use the existing accepted:

```lua
Client:HandleEventStart(...)
```

path only after the incoming Event-start message/session has passed current validation and a real active Event state has been established.

Do not emit Achievement progress from:
- Event Manager preview/opening;
- local Event construction;
- Event widget refresh;
- repeated presentation/startup refresh.

## Idempotency
The same Event instance must not advance `rpe_event_started` more than once even if the Event-start path is replayed/reprocessed.

Use a transient marker associated with the current active Event instance or existing Event startup runtime. Do not persist this delivery marker into Dataset or character Profile state.

Inspect the current Event identity/session fields before choosing the marker key; do not assume `eventState.id` alone uniquely identifies repeated runs if the runtime already has a stronger event-instance/session identity.

## Trigger context
Conceptually:

```lua
{
    eventId = eventState.id,
    eventName = eventState.name,
    source = "rpe-event-start",
    authoritative = true,
}
```

If `filters.eventId` is configured, require exact match.

## Constraints
- Do not change Event startup/synchronization semantics.
- Do not change `rpe_event_complete` behavior.
- Do not add another Event frame or message path.
- Do not trigger from UI/previews.
- Do not implement Damage/Healing/Boss Kill here.

## Acceptance criteria
- [ ] One accepted authoritative Event start advances matching criteria once.
- [ ] Duplicate/replayed handling of the same Event instance does not double-count.
- [ ] Event Manager/UI preview/open does not count.
- [ ] `eventId` filter is respected.
- [ ] Existing Event startup/readiness synchronization remains unchanged.
- [ ] Existing `rpe_event_complete` progression remains unchanged.

## Coding-agent instructions
Read the PDD and issues #23–#24, then inspect `Client:HandleEventStart`, Event startup runtime/idempotency state, message/session validation, and the current Achievement dispatch API before editing. Implement Task 5 only. Attach the trigger only after authoritative Event acceptance and reuse existing Event-instance state for idempotency; do not infer authority from UI or local construction. Review every acceptance criterion and report changed files, validation performed, and deviations.