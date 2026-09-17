## Context

Spell tooltips are built centrally in `client/ui/tooltips/tooltip_Spell.lua`. The tooltip builder already has access to runtime cooldown-channel state (`cooldownChannelId`, `cooldownChannelName`, `cooldownChannelTriggersGCD`) and the action bar passes resolved channel information into spell tooltip detail.

Cooldown channels are now meaningful player-facing action-economy categories (Main Action, Bonus Action, Buff Action, Free Action, Reaction, etc.). Players need a lightweight way to inspect a spell's channel without permanently adding extra text to every tooltip.

## Goal

When the player is hovering a spell tooltip and **Shift is held**, append a blank line and then the following line at the very bottom of the tooltip:

> This spell is considered a [cooldown channel name].

Example:

> This spell is considered a Bonus Action.

The appended line should be grey.

When Shift is not held, the tooltip should remain unchanged.

## Source-first requirements

Before editing, read the current `dev` versions of at least:

- `client/ui/tooltips/tooltip_Spell.lua`
- `client/ui/widgets/widget_ActionBar.lua`
- the shared tooltip rendering/provider code used by RPE widgets
- `core/internal/ruleset/Ruleset.lua`
- the cooldown-channel resolver/runtime state path in `client/spellcasting/Cooldowns.lua` / helpers

Search the repository for existing modifier-key tooltip behavior (`IsShiftKeyDown`, `MODIFIER_STATE_CHANGED`, tooltip refresh/rebuild hooks) before adding a new mechanism.

Do not assume the tooltip is rebuilt continuously while hovered. Trace whether the current tooltip provider is evaluated only on `OnEnter` or can be refreshed while visible.

## Required behavior

### 1. Append channel information only while Shift is held

For a valid spell tooltip with a valid enabled cooldown channel:

- normal hover: no extra channel-information line;
- hover while Shift is already held: show the extra line;
- press Shift while the tooltip is already visible: the tooltip should update immediately and show the line;
- release Shift while still hovering: the tooltip should update immediately and remove the line.

Do not require the user to move the mouse off and back onto the spell.

### 2. Exact text

Use exactly:

```text
This spell is considered a [cooldown channel name].
```

Substitute the channel's current resolved display name.

Examples:

```text
This spell is considered a Main Action.
This spell is considered a Bonus Action.
This spell is considered a Buff Action.
This spell is considered a Free Action.
This spell is considered a Reaction.
```

Do not expose the numeric channel ID in this line.

### 3. Position and spacing

The channel line must be the **last line of the spell tooltip**.

Insert one blank line immediately before it so it is visually separated from the normal tooltip body.

Equivalent line structure:

```lua
-- existing tooltip lines...
{ text = "" },
{
    text = ("This spell is considered a %s."):format(channelName),
    r = 0.6,
    g = 0.6,
    b = 0.6,
    wrap = true,
}
```

Exact grey values may follow the existing tooltip convention, but the result must visually match other secondary/grey tooltip text.

Do not add spacing after the channel line.

### 4. Resolve the name canonically

The displayed name must come from the canonical resolved cooldown-channel state/ruleset definition, not from a hardcoded channel-number-to-name table.

Preferred sources, in order of existing architecture:

1. already-resolved `cooldownChannelName` on tooltip/runtime activation detail;
2. the canonical spell/channel resolver or `Ruleset.GetCooldownChannel(...)` if the tooltip has a spell definition but no runtime activation state.

Requirements:

- renaming a channel in the active ruleset changes the Shift-hover text;
- Reaction is displayed using whatever Channel 5 is currently named, not the literal string `Reaction`;
- do not duplicate action-economy defaults in `tooltip_Spell.lua`;
- do not infer the name from legacy `triggersGCD` / `ignoreGCD` fields.

### 5. Non-runtime spell tooltips

Spell tooltips may appear outside an active event, where no live activation state exists.

The Shift-hover line must still work wherever `tooltip_Spell.lua` has a valid spell definition and can resolve its `cooldownChannel` against the active ruleset.

Do not limit the feature to action-bar tooltips during events.

If the spell has an invalid/unconfigured channel, do not invent a name or silently remap it. In that case omit the Shift-only sentence rather than displaying misleading information.

### 6. Modifier-state refresh

If the current shared tooltip framework already has a modifier-state refresh mechanism, reuse it.

If not, add the narrowest shared mechanism required so a currently visible RPE tooltip can be rebuilt when Shift changes state. Do not add per-frame polling to every action-bar slot.

Preferred behavior is event-driven via `MODIFIER_STATE_CHANGED` (or the existing equivalent):

- detect Shift state transition;
- if an RPE spell tooltip is currently visible and still has a valid owner/provider, rebuild/re-render that tooltip;
- do not disturb unrelated Blizzard tooltips;
- do not create duplicate event frames/listeners for every slot.

The implementation must also handle left/right Shift consistently via `IsShiftKeyDown()` or equivalent final state checking.

### 7. Tooltip cache/staleness

The line should reflect the current active ruleset channel name. If tooltip data/build results are cached, ensure modifier state and relevant configuration revision are accounted for at the correct layer, or bypass only the presentation fragment as appropriate.

Do not force broad cache invalidation or regenerate authored spell descriptions solely because Shift was pressed if the existing tooltip framework can append/rebuild presentation cheaply.

## Explicit non-goals

Do not in this issue:

- permanently display the cooldown channel without Shift;
- add the channel ID to the tooltip;
- display whether the channel triggers its GCD;
- display whether the channel can be used off-turn;
- add explanatory text about cooldown-channel mechanics;
- change spell channel assignments;
- change cooldown/action-economy behavior;
- add this line to item, trait, skill, player, or achievement tooltips;
- alter the main generated spell description.

## Deterministic validation

Validate at minimum:

1. Main Action spell, no Shift -> no channel line.
2. Main Action spell + Shift -> blank line then `This spell is considered a Main Action.` in grey.
3. Bonus Action spell + Shift -> `This spell is considered a Bonus Action.`.
4. Buff Action spell + Shift -> `This spell is considered a Buff Action.`.
5. Free Action spell + Shift -> `This spell is considered a Free Action.`.
6. Reaction spell + Shift -> `This spell is considered a Reaction.`.
7. Press Shift after tooltip is already visible -> line appears without re-hovering.
8. Release Shift while still hovering -> line disappears without re-hovering.
9. Rename a cooldown channel in the active ruleset -> Shift-hover uses the renamed channel name through the normal configuration refresh path.
10. Spell tooltip outside an active event still resolves and displays its configured channel when possible.
11. Invalid/unconfigured channel -> no misleading channel sentence is appended.
12. The appended sentence is always the final tooltip line and has exactly one blank line before it.
13. Existing spell tooltip description, costs, cast time, cooldown text, conditions, aura sections, and runtime cooldown lines remain unchanged.
14. No per-slot OnUpdate/polling loop is introduced.

## Acceptance criteria

- [ ] Holding Shift on a spell tooltip appends the exact requested channel sentence.
- [ ] The sentence is grey and separated from the normal tooltip by one blank line.
- [ ] The displayed name comes from the canonical resolved cooldown channel.
- [ ] Pressing/releasing Shift while remaining hovered updates the tooltip immediately.
- [ ] The feature works for spell tooltips outside active events where the channel can be resolved.
- [ ] Invalid/unconfigured channels are not mislabeled.
- [ ] No cooldown-channel behavior or spell assignments change as part of this issue.