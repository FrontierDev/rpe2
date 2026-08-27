## Goal
Refactor client event **startup and teardown** into explicit, deterministic transition state machines whose expensive phases can be cooperatively sliced without freezing WoW.

Authoritative documents:

- `.docs/RPE2-Runtime-Performance-Hitch-Elimination-PDD.md`
- `.docs/RPE2-Runtime-Performance-Hitch-Elimination-Implementation-Plan.md`

Depends on: #65

This task owns event start/end transition orchestration. Sparse turn advancement and spell-component execution are separate follow-up tasks.

## Primary files

- `client/client_Event.lua`
- `client/client_Traits.lua`
- `client/client_Resources.lua`
- `client/spellcasting/Core.lua` only for reset/transition integration
- `client/spellcasting/AuraManager.lua` only for startup/end integration
- `client/spellcasting/Cooldowns.lua` only for reset integration
- `client/spellcasting/Helpers.lua` for existing dirty visual queues where required
- `server/server_Event.lua` only if #58 profiling proves host-side synchronous construction/broadcast is itself a material hitch

Reuse the cooperative TaskQueue API from #65 and Runtime transactions from #59.

## 1. Add explicit local event transition state

Introduce a local runtime transition structure equivalent to:

```lua
{
    kind = "starting" | "ending",
    eventId = ...,
    transactionId = ...,
    phase = ...,
    generation/revision = ...,
}
```

Requirements:

- only one transition for the active event is authoritative at a time;
- stale queued transition work verifies event ID/generation before applying state;
- transition completion/abort clears retained continuation state;
- normal WoW UI/rendering remains responsive while transition work continues.

Do not add a blocking loading screen.

## 2. Gate conflicting RPE gameplay actions during transitions

While startup/end authoritative work is incomplete, disable/reject RPE actions which would conflict with the partially-transitioned event state.

Examples to inspect:

```text
spell activation/cast actions
end-turn/advance-related local actions
targeting actions that mutate event runtime
reaction/companion controls if they can mutate the same event
```

Harmless UI should remain interactive where possible.

Use one central transition/readiness check rather than scattered arbitrary flags.

## 3. Make startup phases explicit and sliceable

Preserve current startup semantics/order but express phases explicitly, conceptually:

```text
apply/validate event state
prime action-bar metadata
refresh/compile trait runtime
sync automatic trait auras
sync event auras
refresh resolved trait state
initialize/queue resource sync
process startup/consumable prompts
mark event ready
```

Requirements:

- phases that can scale with content use #65 sliceable jobs;
- phases pass forward one stable startup context/snapshot where possible instead of re-resolving shared data;
- do not rebuild the same derived state between phases without an actual revision change;
- startup Achievement trigger participates in the runtime transaction/ChangeSet model from #61 and must not invoke global configuration refresh;
- visual refreshes are dirty/coalesced rather than executed after each startup sub-step.

## 4. Make end-event processing transactional

Client event end must conceptually:

```text
mark event ending
-> reject new conflicting actions
-> process rpe_event_complete Achievements
-> resolve end-phase/consumable effects/prompts
-> commit resulting item/currency/Achievement/Profile changes coherently
-> clear event spellcast/cooldown/aura/trait runtime buckets
-> queue one final visual teardown
-> clear event-scoped revisions/jobs
-> release transition lock
```

Requirements:

- Achievement completion/rewards during event end use the existing outer transaction where practical;
- no Achievement/currency state change invokes `HandleLocalConfigurationChanged()`;
- clear event runtime using direct bucket/index teardown rather than unnecessary broad rescans;
- stale queued event presentation/derived jobs are cancelled through #65 mechanisms.

## 5. Preserve prompt behavior without blocking teardown incorrectly

Current event end may defer reset while consumable/end-phase prompts are active.

Preserve prompt semantics, but represent the wait as a transition phase rather than leaving runtime in an ambiguous half-ended state.

Requirements:

- prompt callback resumes the correct transition generation only;
- obsolete callback from a replaced/new event cannot reset the new event;
- duplicate prompt callbacks cannot double-run teardown.

## 6. Keep network authority/order intact

Do not weaken server/client event authority.

Packet receipt may stage heavy client work, but:

- event IDs/state validation remain immediate;
- required acknowledgements/messages keep existing ordering;
- UI-only invalidation must not generate network traffic;
- client-connect/configuration refresh must not be triggered merely because event runtime state changed.

Modify `server_Event.lua` only for a measured concrete host-side problem; client-side orchestration is the primary scope.

## 7. Integrate transition timings

Using #58 diagnostics, report:

```text
start immediate handler
startup phase slice timings
start total wall-clock transition duration
end immediate handler
end phase slice timings
end total wall-clock transition duration
max single RPE slice/frame contribution
```

Wall-clock multi-frame completion may exceed 16 ms; the requirement is that no individual RPE work chunk creates a frame hitch.

## Acceptance criteria

- [ ] Event startup uses explicit transition phases.
- [ ] Event teardown uses explicit transition phases.
- [ ] Content-scaled startup/end phases are sliceable.
- [ ] Conflicting RPE gameplay actions are gated while authoritative transition work is incomplete.
- [ ] Harmless UI/WoW rendering remains responsive.
- [ ] Startup/end Achievement triggers remain correct and do not cause global configuration refresh.
- [ ] End-event rewards/profile mutations commit coherently rather than refreshing between each mutation.
- [ ] Obsolete event-scoped jobs/callbacks cannot mutate a replacement event.
- [ ] Event runtime buckets/revisions are cleared cleanly at end.
- [ ] Visual startup/teardown refresh is coalesced.
- [ ] Existing event authority/network ordering remains intact.

## Validation matrix

```text
start simple event
-> transition reaches ready
-> controls enabled only when authoritative startup state is ready

start high-content event with many traits/auras
-> startup work spans bounded slices
-> no individual RPE slice exceeds hard threshold
-> resulting runtime matches expected state

start event A then replace/end it with event B while stale derived work exists
-> A jobs/callbacks cannot alter B

end event with no Achievement/rewards
-> teardown completes once
-> runtime buckets cleared

end event completing Achievement with item+currency rewards
-> rewards delivered exactly once
-> one coherent transaction/notification flow
-> no global configuration refresh

end event with consumable prompt
-> transition waits in explicit prompt phase
-> callback resumes same event generation
-> duplicate/stale callback ignored safely

attempt spell/action during starting/ending state
-> blocked through central readiness gate
-> no partial authoritative mutation
```

## Constraints

- Do not redesign turn-step due-work indexes here; next task owns them.
- Do not redesign spell component execution here.
- Do not add a blocking loading screen.
- Do not change event gameplay semantics/order merely to simplify slicing.
- Do not modify server behavior without profiling evidence.
- Do not allow stale transition work to mutate a new/replaced event.

## Coding-agent instructions
Use current `FrontierDev/rpe2` as authoritative. This task is intended for **5.6-Luna-ExtraHigh**. Read both runtime-performance documents and completed #65. Trace current startup runtime flags/steps and `HandleEventEnd`/`ResetEventState`/prompt callbacks before editing. Preserve the existing semantic phase order, but make transition ownership explicit and every content-scaled phase sliceable. Report the transition state machine, action gating rule, converted phases, stale/cancellation handling, files changed, and per-phase timing validation.