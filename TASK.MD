## Goal

Add a dedicated RPE Achievement tooltip builder and bind it to Profile Achievement entries so hovering an Achievement exposes its full definition/progress/completion/reward context in a tooltip styled like a WoW Achievement/GameTooltip.

The tooltip must be Achievement-specific, read-only, lazy, and reusable by other RPE surfaces that display Achievement references later.

Depends on: #76, #77

## Current-code investigation / root cause

### 1. There is no Achievement tooltip module

RPE already has domain-specific tooltip builders such as:

```text
client/ui/tooltips/tooltip_Spell.lua
client/ui/tooltips/tooltip_Skill.lua
client/ui/tooltips/tooltip_Trait.lua
client/ui/tooltips/tooltip_Player.lua
client/ui/tooltips/tooltip_Item.lua
```

`RPEngine_Dev.toc` loads these after the shared tooltip system.

There is currently no:

```text
client/ui/tooltips/tooltip_Achievement.lua
```

### 2. Profile Achievement rows do not attach a tooltip

`client/character/profile/page_ProfileAchievements.lua` currently renders Achievement data into list rows but has no Achievement `SetTooltip(...)`/domain-builder integration.

Therefore the only place to see criteria/completion/reward details is whatever fits into the row itself.

### 3. Existing tooltip infrastructure already supports the required lazy pattern

`core/ui/Tooltip.lua` already resolves a tooltip spec when it is shown, including **function-valued specs**. `BaseElement:SetTooltip(...)` stores the spec and hover handlers call `UI.Tooltip:ShowForElement(...)`.

This means the Achievement row can use a lazy binding conceptually like:

```lua
entry:SetTooltip(function(owner)
    return Tooltips.Achievement:Build(detail, owner)
end)
```

without eagerly constructing every tooltip during Profile refresh.

The existing domain tooltip builders, particularly `tooltip_Spell.lua`, already return structured tooltip specs using:

```lua
{
    type = "game",
    title = ...,
    titleColor = ...,
    lines = { ... },
}
```

so a second tooltip framework is not needed.

## WoW reference / adaptation

Reference material inspected:

- Warcraft Wiki — Achievement window: https://warcraft.wiki.gg/wiki/Achievements
- Warcraft Wiki — AchievementLink payload: https://warcraft.wiki.gg/wiki/AchievementLink
- Blizzard Achievement UI source mirror: https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_AchievementUI/Mainline/Blizzard_AchievementUI.lua

Relevant WoW conventions to preserve conceptually:

- Achievement information is presented through the normal WoW `GameTooltip` visual language when exposed as a hyperlink/hover surface;
- achievement completion state includes a completion date;
- criteria are individual pieces of progress, not just one opaque combined string;
- completed/incomplete state is immediately legible;
- progressive state is displayed as current progress toward a goal;
- Achievement UI tooltips use the existing GameTooltip rather than a completely separate tooltip subsystem.

RPE Achievements are dataset definitions, not Blizzard Achievement IDs. Do **not** call `GetAchievementInfo`, `GetAchievementLink`, `GameTooltip:SetHyperlink("achievement:...")`, or otherwise pretend an RPE Achievement is a native WoW Achievement.

Instead, build the equivalent presentation from RPE's definition/Profile state and feed it through the existing RPE tooltip service.

## Required solution

### 1. Add `Tooltips.Achievement`

Create:

```text
client/ui/tooltips/tooltip_Achievement.lua
```

following the namespace/pattern of the existing domain tooltip builders.

Recommended public API:

```lua
Addon.Client.UI.Tooltips.Achievement:Build(detail, owner)
```

The exact detail shape may follow existing conventions, but it should be able to receive/resolve at least:

```text
achievementRef
achievement definition
Profile Achievement state
category/subcategory
criterion state
reward definition/state
resolved dataset context where useful
```

Prefer accepting already-resolved row/detail context from the Profile page while still failing safely if fields are missing.

### 2. Use GameTooltip-style RPE tooltip specs

Default to the existing structured:

```lua
type = "game"
```

presentation so the result visually belongs to WoW/RPE's existing tooltip family.

Do not add a bespoke free-floating Achievement window merely to call it a tooltip.

Only extend `core/ui/Tooltip.lua` if a concrete Achievement requirement cannot be represented through its existing title/double-line/wrapped-line APIs. Keep any extension generic and reusable.

### 3. Tooltip content hierarchy

The tooltip should contain, in this general order:

```text
Achievement Name
Description

Category / Subcategory

Progress / Criteria
  Criterion A                         Complete
  Criterion B                           7 / 10
  Criterion C                           0 / 1

Completed: <date>              -- completed only
or
Incomplete                     -- incomplete only where useful

Reward(s)                      -- when configured
  Item / Currency summary
  delivery state where relevant
```

The exact labels/spacing should follow existing tooltip conventions rather than literally rendering the ASCII structure.

#### Title

- use the Achievement name, with safe fallback to ref/ID;
- completed state may use a gold/positive title accent consistent with #77's completed-card treatment;
- incomplete state should remain readable, not aggressively greyed out.

#### Description

- show authored Achievement description as wrapped body text;
- omit an empty description rather than showing a blank placeholder sentence.

#### Category

After #76, show the built-in category label and optional subcategory in a compact form such as:

```text
Combat — Raids
```

Do not show raw persisted keys (`player_vs_player`) to the user.

#### Criteria

Show criteria individually.

For each criterion:

- use authored criterion description, falling back safely to its ID/trigger where necessary;
- derive current progress from Profile state, defaulting to zero;
- clamp/display progress consistently with the existing Achievement page/runtime semantics;
- show `current / goal` for numeric progress;
- visually distinguish satisfied criteria from incomplete criteria using existing positive/muted colour tokens or compact check-style text;
- do not expose raw filter tables/transport fields as normal user-facing tooltip text.

Do not fabricate an aggregate percentage for heterogeneous criteria.

#### Completion

If `completedAt` exists:

- show an explicit completion date using the same formatter/convention as the Achievement page;
- treat `completedAt` as the authoritative visual completion signal, consistent with existing Profile Achievement semantics.

If incomplete, no fake date/zero timestamp should be shown.

#### Rewards

Where rewards exist, include compact resolved reward information using the existing Item/Currency resolution APIs and reward-state model.

Examples:

```text
Reward: Field Ration x2
Reward: 5 Valor
Rewards received
```

Requirements:

- use Item/Currency names/icons where available through existing resolvers;
- unresolved definitions show a safe missing-reference fallback;
- delivery state from #34 remains distinguishable where useful (`Pending`, `Received`, `Delivery failed`, etc.);
- do not trigger or retry reward delivery from hover.

If the existing tooltip line API supports inline icons cleanly, use them; otherwise prioritize readable text rather than adding a one-off renderer solely for reward icons.

### 4. Bind tooltip lazily to the new Achievement entry prefab

After #77, the dedicated `UI.AchievementEntry` should expose normal BaseElement tooltip behavior.

When binding a row in `page_ProfileAchievements.lua`:

- set a function-valued tooltip spec that builds from the **currently bound row data**;
- make sure recycled rows replace the old tooltip resolver/detail when rebound;
- hovering an incomplete row shows its current progress;
- hovering a completed row shows completion state/date;
- hidden/unbound pooled rows must not retain stale Achievement tooltip data.

Do not build all tooltip lines while refreshing the list. The builder should run on hover.

### 5. Keep visible tooltip data current

The Profile Achievement page already refreshes according to Achievement/Configuration revisions.

Ensure a row rebound after progress/completion change produces the new tooltip data. If the existing tooltip is currently open during a relevant row refresh, either refresh it through the existing `Tooltip:RefreshForElement(...)` mechanism or allow the normal leave/re-enter path to rebuild it; do not introduce a polling ticker.

Do not cache Achievement tooltip content beyond the revisions/data identity that affect it.

### 6. Load order

Update `RPEngine_Dev.toc` so:

```text
core/ui/Tooltip.lua
...
client/ui/tooltips/tooltip_Achievement.lua
...
core/ui/prefabs/AchievementEntry.lua
client/character/profile/page_ProfileAchievements.lua
```

are ordered such that the builder is available before the Profile page binds rows.

The exact relative position among the other domain tooltip files may follow the current TOC convention.

## Primary files

- `client/ui/tooltips/tooltip_Achievement.lua` — new
- `client/character/profile/page_ProfileAchievements.lua`
- `core/ui/prefabs/AchievementEntry.lua` — from #77, tooltip binding/reset support if needed
- `RPEngine_Dev.toc`

Only if a proven generic capability is missing:

- `core/ui/Tooltip.lua`

## Acceptance criteria

- [ ] RPE has a dedicated `Addon.Client.UI.Tooltips.Achievement` builder.
- [ ] Hovering a Profile Achievement entry shows an Achievement tooltip.
- [ ] Tooltip uses the existing RPE/WoW GameTooltip-style system rather than a parallel tooltip framework.
- [ ] Tooltip title shows the Achievement name with safe fallback.
- [ ] Tooltip shows the authored description when present.
- [ ] Tooltip shows the built-in category label and optional freeform subcategory from #76.
- [ ] Tooltip shows each criterion separately with current/goal state.
- [ ] Completed criteria are visually distinguishable from incomplete criteria.
- [ ] Completed Achievement tooltip shows its completion date.
- [ ] Incomplete Achievement tooltip never shows a fake completion date.
- [ ] Configured rewards and meaningful delivery state are shown where available.
- [ ] Missing Achievement/criterion/reward definitions fail safely without Lua errors.
- [ ] Tooltip creation is lazy on hover; opening/refreshing the Achievement page does not eagerly build every tooltip.
- [ ] Hovering never mutates Achievement progress, Profile state, Inventory, Currency state or reward delivery.
- [ ] Recycled AchievementEntry rows cannot show the previous row's tooltip.
- [ ] Progress/completion changes are reflected on the next tooltip build.
- [ ] No native Blizzard Achievement ID/API dependency is introduced.
- [ ] TOC load order makes the builder available before use.

## Validation matrix

```text
incomplete simple Achievement
-> hover shows name + description + criterion 0 / 1
-> no completion date

progressive Achievement at 7 / 10
-> hover shows criterion description + 7 / 10

multi-criterion Achievement
-> each criterion appears separately
-> completed and incomplete criteria distinguishable

completed Achievement
-> hover shows completion date
-> completed title/status treatment

Achievement with category Combat / Raids
-> tooltip shows human-readable Combat — Raids

Achievement with blank subcategory
-> category shown cleanly without dangling separator

Achievement with item + currency rewards
-> readable resolved reward rows
-> reward delivery state where applicable

missing reward/item/currency definition
-> safe fallback, no error

scroll list so row object is recycled from Achievement A to B
-> hover shows B only
-> no stale A title/criteria/rewards

Achievement progresses while Profile page is open
-> refreshed/rebound row's next hover shows new current value

hover repeatedly
-> no Profile/reward/runtime mutation
-> no new ticker/listener leak
```

## Constraints

- Do not use native Blizzard Achievement APIs for RPE definitions.
- Do not make tooltip hover execute Achievement or reward logic.
- Do not duplicate Item/Currency resolution logic if existing helpers can provide display data.
- Do not eagerly build tooltip bodies for every row during page refresh.
- Do not create a second tooltip manager.
- Do not add Achievement Points merely for WoW visual similarity.
- Do not expose internal criterion filter/debug payloads as the normal tooltip.
- Preserve #64 revision-driven Profile behavior and #77 row recycling.

## Coding-agent instructions

Use current `FrontierDev/rpe2` as authoritative and implement after #76/#77. Inspect `core/ui/Tooltip.lua`, `core/ui/abstract/BaseElement.lua`, all current `client/ui/tooltips/tooltip_*.lua` builders (especially Spell/Item), the new AchievementEntry prefab, Profile Achievement reward-state helpers, and TOC ordering before editing. Reuse the function-valued lazy tooltip-spec path already supported by `Tooltip:ShowForElement()`. Report the final tooltip detail/spec contract, any generic Tooltip change (and why it was necessary), files changed, and validation results.