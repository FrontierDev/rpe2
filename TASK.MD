## Context

Supersedes #329, which specified the wrong visual semantics for absorption.

The current absorption implementation should match Blizzard's default WoW unit-frame behaviour more closely: absorption is **appended to the end of the visible health fill**, not drawn as an independent overlay from the right-hand side of the whole bar.

Blizzard's current UI source (`Blizzard_PersonalResourceDisplay.lua`) does the following:

- obtains current health and total absorbs;
- clamps visible absorb so it does not extend beyond the health bar;
- appends the absorb texture after the current health/incoming-heal section;
- shows an over-absorb glow when health + absorb exceeds the available bar width;
- uses `Interface\\RaidFrame\\Shield-Fill`, `Shield-Overlay`, and `Shield-Overshield` textures.

For RPE, incoming-heal prediction is out of scope. The relevant model is therefore simply current health + absorption.

## Correct visual behaviour

For a unit with 100 max health:

```text
50 health, 25 absorb
[ HEALTH 50 ][ ABSORB 25 ][ EMPTY 25 ]
```

```text
50 health, 50 absorb
[ HEALTH 50 ][      ABSORB 50       ]
```

```text
80 health, 50 absorb
[       HEALTH 80       ][ABSORB 20]
                              ^
                       overshield glow
```

```text
100 health, 50 absorb
[            HEALTH 100            ]
                                  ^
                           overshield glow
```

Absorption must **not** overlap/cover the existing health fill as its main representation.

The visible absorb segment is:

```lua
missingHealth = math.max(0, maxHealth - currentHealth)
visibleAbsorption = math.min(totalAbsorption, missingHealth)
overAbsorb = totalAbsorption > missingHealth
```

Equivalent bar-end representation:

```lua
healthEnd = currentHealth
absorbEnd = math.min(maxHealth, currentHealth + totalAbsorption)
```

The absorb segment occupies only the range between `healthEnd` and `absorbEnd`.

## Reuse the existing ProgressBar layering

`core/ui/elements/ProgressBar.lua` already has two fill layers:

- `secondaryBar` on `ARTWORK`;
- `primaryBar` on `OVERLAY`.

Both are left-anchored and sized independently from `minValue`/`maxValue`.

This is actually a good fit for Blizzard-style appended absorbs:

```lua
primaryValue   = currentHealth
secondaryValue = math.min(maxHealth, currentHealth + totalAbsorption)
```

Because `secondaryBar` sits behind `primaryBar`, the secondary layer from 0 -> currentHealth is hidden by the opaque health fill, leaving only the visible segment from currentHealth -> health+absorb.

This means the existing two-layer `ProgressBar` should be reused rather than maintaining the bespoke `UnitPortrait.absorptionOverlay` width/anchor system introduced for #329/#326.

### Important limitation

`ProgressBar` supports **two fill layers**, not arbitrary stacked layers. That is sufficient for current RPE health + absorption semantics.

The current secondary layer is colour-based (`SetColorTexture`). If the intended WoW appearance requires the actual shield texture rather than a flat colour, extend `ProgressBar` cleanly with optional primary/secondary texture support rather than creating another independently-sized frame in `UnitPortrait`.

A suitable extension could support options such as:

```lua
secondaryTexture = "Interface\\RaidFrame\\Shield-Fill"
secondaryOverlayTexture = "Interface\\RaidFrame\\Shield-Overlay"
```

while retaining existing solid-colour behaviour for all current callers.

Do not introduce an API that is absorb-specific into generic `ProgressBar` if a general optional texture-layer API is sufficient.

## Overshield presentation

If:

```lua
totalAbsorption > (maxHealth - currentHealth)
```

then the visible absorb segment is capped at the end of the health bar and an overshield indicator/glow is shown at the right edge.

Use Blizzard's `Interface\\RaidFrame\\Shield-Overshield` where practical, or an equivalent treatment if the texture does not scale cleanly at the event portrait bar height.

The exact absorption amount remains available in the unit tooltip; the bar does not need to encode overflow magnitude.

Examples:

- 80/100 HP + 10 absorb -> 10-point absorb segment, no glow.
- 80/100 HP + 20 absorb -> absorb fills remaining 20 points; follow Blizzard's inclusive threshold semantics when deciding glow visibility.
- 80/100 HP + 50 absorb -> 20-point visible segment + overshield glow.
- 100/100 HP + any positive absorb -> no visible appended segment; overshield glow indicates the shield.

## ProgressBar resize behaviour

`ProgressBar:Create()` already installs:

```lua
frame:SetScript("OnSizeChanged", function()
    self:UpdateLayout()
end)
```

and `UpdateLayout()` recalculates both bar widths.

This is preferable to the current bespoke absorb overlay implementation, which samples `barFrame:GetWidth()` once in `UnitPortrait:SetAbsorptionState()` and can remain hidden if the width is zero during initial layout.

By expressing absorption through `secondaryValue`, resize/layout changes should automatically keep the appended segment correct.

## UnitPortrait changes

Refactor `core/ui/prefabs/UnitPortrait.lua` so health state is applied approximately as:

```lua
progressBar:SetMinMax(0, maxHealth)
progressBar:SetValue(currentHealth)
progressBar:SetSecondaryValue(
    totalAbsorption > 0
        and math.min(maxHealth, currentHealth + totalAbsorption)
        or nil
)
```

Configure the secondary layer as the absorption visual layer.

Remove or retire the current bespoke width-based `absorptionOverlay` if it becomes redundant. Do not leave two different absorption rendering systems active simultaneously.

The overshield indicator may remain a separate small frame/texture because it represents overflow rather than another fill value.

## State source and invalidation

Keep the existing data flow from `client/ui/widgets/widget_Event.lua`:

```lua
healthState.currentValue
healthState.maxValue
healthState.absorption
healthState.absorptionRevision
```

`buildPortraitDisplayKey()` already includes absorption amount/revision, which allows shield-only changes to redraw a portrait even when health is unchanged.

Do not store aggregate absorption on the event unit or health resource itself.

Do not force a full event-widget rebuild when only one target's absorption changes.

## Tooltip behaviour

Tooltip state must continue to show the exact aggregate absorption and source-level shield data.

Example:

```text
Health: 80 / 100
Absorption: 50

Power Word: Shield
50 / 50 absorption
2 turns
```

The health-bar segment may display only 20 points in that example because the remaining 30 points are overflow; the tooltip still reports the true 50-point shield.

## Primary files / call paths

Inspect current `dev` before implementation:

- `core/ui/elements/ProgressBar.lua`
  - `secondaryValue`
  - `secondaryBar`
  - `UpdateBars()`
  - `ApplyColors()`
  - `OnSizeChanged`
- `core/ui/prefabs/UnitPortrait.lua`
  - `SetProgressState()`
  - `SetAbsorptionState()`
  - current bespoke `absorptionOverlay`
  - overshield indicator
- `client/ui/widgets/widget_Event.lua`
  - `addPortraitAbsorptionState()`
  - `buildPortraitDisplayKey()`
  - `RefreshPortraitSlot()`
  - targeted refresh path
- `client/spellcasting/AuraManager.lua`
  - `GetTotalAbsorption()`
  - runtime-update refresh invalidation

## Do not change

- health current/max values;
- absorption runtime mechanics;
- resource synchronization;
- damage calculation;
- secondary resource bar beneath the health bar (`UnitPortrait.secondaryProgressBar`), which is a separate `ProgressBar` instance and is unrelated to `progressBar.secondaryBar`.

Be careful with terminology: `UnitPortrait.secondaryProgressBar` is the unit's second resource bar; `UnitPortrait.progressBar.secondaryBar` is the second fill layer inside the health bar. Absorption belongs in the latter.

## Acceptance criteria

- [ ] Absorption is appended directly after the current health fill, matching WoW behaviour.
- [ ] It is not independently right-anchored or drawn over the existing health fill as the primary representation.
- [ ] 50/100 HP + 25 absorb visually shows 50% health + 25% absorb + 25% empty.
- [ ] 50/100 HP + 50 absorb visually fills the bar exactly to 100% with health then absorb.
- [ ] 80/100 HP + 50 absorb shows only 20 points of absorb in-bar plus an overshield indicator.
- [ ] 100/100 HP + positive absorb shows the overshield indicator even though there is no free in-bar region for an appended absorb segment.
- [ ] Zero absorption hides the secondary absorb fill and overshield indicator.
- [ ] Shield-only consumption redraws correctly with no health change.
- [ ] Resizing/re-layout keeps the segment aligned automatically.
- [ ] Existing `ProgressBar` two-layer support is reused rather than duplicating fill geometry in `UnitPortrait`.
- [ ] Existing ProgressBar callers that use only the primary layer are unaffected.
- [ ] Existing callers that already use `secondaryValue` retain their current behaviour.
- [ ] The separate secondary resource bar under the portrait is unchanged.
- [ ] Exact absorption amount remains available in tooltips, including overflow beyond visible bar capacity.

## Regression / visual tests

1. 100/100 HP, 0 absorb -> ordinary full health bar, no shield visuals.
2. 50/100 HP, 25 absorb -> health 0-50%, absorb 50-75%, empty 75-100%.
3. 50/100 HP, 50 absorb -> health 0-50%, absorb 50-100%.
4. 80/100 HP, 10 absorb -> health 0-80%, absorb 80-90%, no overshield.
5. 80/100 HP, 50 absorb -> health 0-80%, absorb 80-100%, overshield indicator shown.
6. 100/100 HP, 50 absorb -> full health fill + overshield indicator; no fake 50%-wide overlay over health.
7. Shield 50 -> 20 while health is unchanged -> appended segment/overshield state updates immediately.
8. Shield consumed to 0 -> secondary fill and overshield disappear.
9. Resize portrait/bar after applying shield -> appended segment remains correct.
10. Boss portrait/talking-head portrait use the same shared health-bar behaviour wherever health bars are shown.