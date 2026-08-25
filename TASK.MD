## Validation result: revision required

Static validation of commit `fc7984f8e24d3f17efbde4fdc7850688f51b6edd` found the core Task 3 structure is in place, but there are three implementation defects that should be corrected before #40 is closed.

### What passes

- The provisional `StatusText` / Daily Rewards list presentation has been removed.
- The page now uses the required `VerticalLayoutGroup -> Header + MainContent` hierarchy.
- The Header uses `HorizontalLayoutGroup` with an `ImageButton` and a nested `VerticalLayoutGroup` for rank/reset text.
- The lower host regions are stable weighted layout groups with weights `7` and `3`.
- Daily Reward clicking is gated by cached status and `DailyRewardPending`, and delegates to `Client.Guild:TryClaimDailyReward()` rather than duplicating the transaction.
- Tooltip construction is read-only and resolves item/currency display data with question-mark fallback behavior.
- Rank text is concise and reset text uses the #38 reset-state API.
- Ordinary ticker ticks only update the reset text; a cycle-key change calls one full `Refresh()`.
- No Shop grid or limited-requisition row population was introduced early.

### Blocking defect 1: the reset ticker can run while the Guild window/page is not actually visible

`Refresh()` and `StartResetTicker()` use `self.frame:IsShown()` as the visibility gate:

```lua
if not self.frame or self.ResetTicker or not self.frame:IsShown() then
    return
end
```

and:

```lua
if self.frame:IsShown() then
    self:StartResetTicker()
end
```

The Guild window is initially created with `hidden = true`, while the Requisitions child frame itself is still in its shown state. In WoW, `IsShown()` reports the frame's own shown flag and does not account for a hidden ancestor; `IsVisible()` is the effective-visibility check. This means page construction/refresh can install the one-second `OnUpdate` loop while the Guild window is hidden, violating the requirement that the ticker exist only while the Requisitions page is visible.

The same distinction matters across window/tab visibility transitions.

#### Required revision

Gate ticker creation/execution on effective visibility, not only the child frame's shown flag. Use `IsVisible()` where available and/or explicitly tie ticker lifecycle to the actual active tab/window visibility. Ensure:

```text
window hidden -> no active ticker
other Guild tab active -> no active Requisitions ticker
Requisitions tab shown -> exactly one ticker
hide/show repeatedly -> no duplicate ticker state
```

`StopResetTicker()` should leave no live `OnUpdate` handler or stale state that prevents a clean restart.

### Defect 2: claimed/unavailable button visual state is lost after hover

`UpdateDailyRewardVisualState()` correctly applies baseline alpha (`0.5`, `0.7`, or `1`) while leaving the button mouse-enabled for tooltips. However, `UI.ImageButton` inherits the default `ButtonBase` mouse scripts. `ButtonBase` sets alpha to `1` on `OnEnter`, `OnLeave`, and `OnMouseUp`.

Therefore a claimed/invalid reward is initially subdued, but after the first hover/leave its alpha becomes `1` and stays there until another full refresh. That defeats the required persistent subdued/claimed visual state while preserving hoverability.

#### Required revision

Keep the button hoverable, but make its mouse visual handlers restore the status-dependent baseline alpha instead of unconditional `1`, or apply the unavailable visual through a property not overwritten by `ButtonBase` hover scripts (for example texture vertex/desaturation state). Verify claimed and invalid states remain visibly subdued before, during and after tooltip hover.

### Defect 3: the Daily Reward control is not actually square after layout

The button is created as `36 x 36`, but `HeaderLayout` has:

```lua
height = 42,
fitChildrenHeight = true,
```

`HorizontalLayoutGroup` forces every child to the full inner height when `fitChildrenHeight = true`, so the Daily Reward button becomes approximately `36 x 42`, not square as required.

#### Required revision

Preserve a square Daily Reward button after layout. For example, make the header/button dimensions agree, or place the fixed square button in a wrapper whose height can stretch without resizing the button itself. Re-check the final frame dimensions after the layout group has run.

### Re-validation

After revision, validate at minimum:

```text
Guild window constructed but hidden -> no ticker
Guild window shown on Requisitions -> one ticker
switch to Progression/Admin -> ticker stopped
switch back -> one ticker only
close/reopen repeatedly -> no ticker accumulation

available reward -> normal visual, one central claim call
pending -> repeated clicks ignored
claimed/invalid -> subdued visual survives hover/leave, tooltip still works

Daily Reward button -> square after layout
rank/reset text -> unchanged concise format
reset cycle change -> one full Refresh()
```

No configured CI/status checks are attached to this commit, so this validation is based on static source inspection. Issue #40 should remain open pending these revisions.