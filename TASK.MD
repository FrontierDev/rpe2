## Objective

Bring the NPC Talking Head popup presentation into line with the intended design while explicitly retaining the current health/resource display on the portrait.

Target branch: `dev`.

Source design:

```text
.docs/RPE2-NPC-Talking-Heads-PDD.md
```

This is a corrective follow-up to commit:

```text
1c1fea99ef4e86177c35e8314d882e5b7acf346f
```

## Important product decision

The Talking Head portrait **may continue to show the health bar/resource presentation currently implemented**.

Do not remove the health bar as part of this issue.

## Current review findings

The current implementation differs from the intended presentation in several other ways:

1. hidden NPCs are passed through normal hidden-unit masking for non-host clients;
2. the popup is narrower than the intended Talking Head presentation target;
3. speech can remain visible for up to 18 seconds, which blocks all subsequent combat-ticker presentations because the queue is strict FIFO.

The PDD defines NPC speech as an explicit host-authored reveal and describes a larger 520-560px-class Talking Head surface with a more conservative adaptive display duration.

## Required current-code inspection

Before editing, re-read the current `dev` versions of at least:

```text
client/ui/widgets/widget_Event.lua
client/client_NPCSpeech.lua
core/ui/prefabs/UnitPortrait.lua
.docs/RPE2-NPC-Talking-Heads-PDD.md
```

Trace the final presentation queue and `RenderNPCSpeech()` implementation before modifying it.

## Required changes

### 1. Treat Talking Head speech as an explicit reveal

When the event host deliberately makes an NPC speak, the Talking Head should use that NPC's actual identity/portrait even if the NPC is currently marked `hidden` in the normal Event Widget presentation.

Do not pass the Talking Head speaker through the ordinary participant hidden-unit masking path.

Required behavior:

- resolve the authoritative EventUnit by `speakerEventId`;
- show its actual name;
- show its actual raid marker;
- show its actual EventUnit ID;
- show its actual portrait/model presentation;
- retain team-coloured name presentation;
- retain the health/resource presentation currently shown on the Talking Head portrait.

This reveal applies to the Talking Head presentation only. It must not change the EventUnit's `hidden` state or reveal the unit in the normal portrait roster.

### 2. Increase the Talking Head popup width

Tune the panel toward the intended larger Talking Head surface rather than the current 480px width.

Target approximately:

```text
520-560 px wide
```

Choose the final width based on the existing Event Widget width and current text/portrait geometry.

Requirements:

- portrait remains on the left;
- identity header and dialogue remain on the right;
- long but valid dialogue has materially better line length/readability;
- popup remains centered below the unit portraits;
- no overlap with the normal Event Widget controls;
- bounded dynamic height still works.

The current 76px portrait size may be retained unless the final geometry clearly benefits from a small adjustment.

### 3. Reduce maximum Talking Head queue occupancy

Keep adaptive duration based on dialogue length, but reduce the maximum so one long line cannot block combat ticker traffic for 18 seconds.

Use a deterministic duration in the approximate design range:

```text
minimum: about 5 seconds
maximum: about 12 seconds
```

A reasonable implementation is conceptually:

```text
base duration + text-length component
clamped to 5-12 seconds
```

Do not change combat-log ticker duration; compact combat entries must retain their existing fixed 5-second behavior.

### 4. Preserve strict FIFO behavior

Do not make speech pre-empt combat entries or allow combat entries to overlap speech.

The queue must remain:

```text
presentation A finishes
    -> presentation B begins
```

The duration adjustment exists only to prevent excessive queue starvation from long NPC speech.

### 5. Preserve identity formatting

Keep the current required identity ordering:

```text
<raid marker> <team-coloured NPC name> (#<eventUnitId>)
```

The EventUnit ID should remain neutral text rather than inheriting the team colour.

Speech body must remain plain/escaped text and must not allow arbitrary WoW formatting injection.

## Suggested file scope

Expected primary file:

```text
client/ui/widgets/widget_Event.lua
```

Only touch `client/client_NPCSpeech.lua` or `UI.UnitPortrait` if a narrowly required helper is missing. Do not duplicate portrait resolution or network behavior.

## Validation

Verify at minimum:

1. visible NPC speech still renders correctly;
2. hidden NPC speech shows the real NPC identity/portrait to participants in the Talking Head only;
3. hidden NPC remains hidden in the ordinary Event Widget roster;
4. raid marker/name/EventUnit ID ordering remains correct;
5. only the name is team-coloured;
6. Talking Head health/resource presentation remains visible;
7. panel width is in the intended larger range and remains centered;
8. short speech uses the minimum/near-minimum display duration;
9. long valid speech never exceeds the new ~12-second cap;
10. combat ticker entries remain fixed at 5 seconds;
11. speech followed by combat remains strict FIFO with no overlap;
12. multiple speech entries remain strict FIFO;
13. dynamic popup height still remains bounded;
14. event teardown clears the popup/timer normally.

## Acceptance criteria

- [ ] Host-authored Talking Head speech explicitly reveals the actual NPC identity/portrait even when the normal EventUnit is hidden.
- [ ] The ordinary hidden-unit state/presentation is not otherwise changed.
- [ ] Health/resource display on the Talking Head portrait is retained.
- [ ] Talking Head panel width is increased toward the intended 520-560px range.
- [ ] Adaptive speech duration is capped at approximately 12 seconds rather than 18 seconds.
- [ ] Combat ticker duration and strict FIFO scheduling are unchanged.
- [ ] Existing NPC speech networking and duplicate suppression have no regression.

## Non-goals

- Removing health/resource bars from Talking Head portraits.
- Changing DM Helper cue authoring UI (#295/#296).
- Adding dialogue history.
- Adding voice/audio.
- Changing NPC hidden-state gameplay semantics.
- Changing combat-log presentation timing.