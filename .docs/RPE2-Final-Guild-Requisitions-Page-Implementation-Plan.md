# RPE 2 — Final Guild Requisitions Page Implementation Plan

**Status:** Implementation plan  
**Target:** `FrontierDev/rpe2`  
**Primary page:** `client/character/guild/page_GuildRequisitions.lua`

## 1. Objective

Replace the current provisional Guild Requisitions page with the final player-facing design.

The final page has four functional regions:

1. A **Daily Reward ImageButton** in the upper-left.
2. The player's **current assigned RPE Guild Rank** beside the button.
3. A **daily reset countdown** directly beneath the rank.
4. A lower two-panel area containing:
   - a **paginated Guild Shop** on the left;
   - a **scrolling one-time/limited Requisitions panel** on the right.

Do not add section headings, instructional text, status paragraphs, help text, empty-state prose, or separate purchase buttons.

The page should make maximum practical use of RPE's existing `HorizontalLayoutGroup`, `VerticalLayoutGroup`, and `GridLayoutGroup` abstractions.

---

## 2. Current Repository State

The relevant functionality already exists in the current repository:

- `client/character/guild/page_GuildRequisitions.lua` already resolves the assigned guild rank, daily reward state, requisition eligibility, and calls `Client.Guild:TryRequisition(...)`.
- `client/client_Guild.lua` already contains transactional requisition purchasing, daily reward validation/award/rollback, guild-rank resolution, and profile-ledger integration.
- `core/classes/GuildSetting.lua` already stores `requisitions` and `dailyRewards` on a Guild Rank/GuildSetting definition.
- `core/internal/profile/Guild.lua` already stores per-guild requisition usage and daily reward claims.
- `core/ui/prefabs/SpellbookEntry.lua` provides the visual basis for the new shop entry prefab.
- `client/character/profile/page_ProfileSpellbook.lua` provides the desired pagination/grid interaction pattern for the Guild Shop.
- `core/ui/elements/ImageButton.lua` provides the required daily reward button element.
- `core/ui/Tooltip.lua` and `BaseElement:SetTooltip()` already support dynamic custom tooltips with icon-bearing rows.
- `core/ui/elements/ScrollLayout.lua` can instantiate a custom row element class and is appropriate for the limited Requisitions panel.

This task should therefore reuse the existing transaction/state APIs and replace the current temporary page presentation rather than create a parallel guild shop system.

---

# 3. Final Page Structure

The intended hierarchy is:

```text
VerticalLayoutGroup — Root
│
├─ HorizontalLayoutGroup — Header
│  │
│  ├─ ImageButton — Daily Reward
│  │
│  └─ VerticalLayoutGroup — Rank/Reset
│     ├─ Text — Guild Rank
│     └─ Text — Daily Reset countdown
│
└─ HorizontalLayoutGroup — Main Content
   │
   ├─ VerticalLayoutGroup — Guild Shop
   │  ├─ GridLayoutGroup — Shop Entries
   │  │  ├─ ShopEntry
   │  │  ├─ ShopEntry
   │  │  └─ ... fixed two-column entry pool
   │  │
   │  └─ HorizontalLayoutGroup — Pagination
   │     ├─ Previous button
   │     ├─ Page indicator
   │     └─ Next button
   │
   └─ ScrollLayout — Limited Requisitions
      ├─ ShopEntry
      ├─ ShopEntry
      └─ ...
```

There must be **no visible `Guild Shop` or `Requisitions` heading** above the two lower regions.

The lower area should retain the approximate proportions of the supplied mockup, with the Guild Shop receiving roughly 70% of the available width and the limited Requisitions panel roughly 30%. Use layout-group weights rather than fixed absolute widths wherever practical.

---

# 4. New `ShopEntry.lua` Prefab

Create:

```text
core/ui/prefabs/ShopEntry.lua
```

Add it to `RPEngine_Dev.toc` after `core/ui/prefabs/SpellbookEntry.lua` and before the Guild character pages are loaded.

## 4.1 Visual design

`ShopEntry` should deliberately follow the existing `SpellbookEntry` visual language:

```text
┌──────┬────────────────────────┐
│ ICON │ Item Name              │
│      │ Item Cost              │
└──────┴────────────────────────┘
```

Retain from `SpellbookEntry`:

- button-backed outer frame;
- left-side item icon;
- cropped icon texture;
- thin icon border;
- hover highlight;
- enabled/disabled visual handling;
- `SetBorderColor(...)`;
- `SetLayoutMetrics(width, height)`;
- the same overall compact row dimensions/style.

The difference is that the text region to the right of the icon contains two rows instead of one:

1. item name;
2. item cost.

Use a small `VerticalLayoutGroup` for these two text elements rather than manually positioning both text rows independently.

## 4.2 Public API

Implement at minimum:

```lua
ShopEntry:SetIcon(texturePath)
ShopEntry:SetItemName(itemName)
ShopEntry:SetCostText(costText)
ShopEntry:SetBorderColor(r, g, b, a)
ShopEntry:SetLayoutMetrics(width, height)
ShopEntry:SetEnabled(enabled)
```

The prefab should also retain normal `BaseElement` tooltip support so the page can call:

```lua
entry:SetTooltip(...)
```

## 4.3 Item-name truncation

The item name must be a **single line** and must never visually overflow into the next column or outside its entry.

If the full name does not fit, render an ellipsis using three periods:

```text
Reinforced Arcanite Longs...
```

Do not wrap the name onto a second line.

`SetItemName()` should keep the full original item name internally and calculate a separate display string.

Implement a helper inside `ShopEntry.lua`, conceptually:

```lua
local function fitTextWithEllipsis(fontString, fullText, maxWidth)
    -- Return fullText when it fits.
    -- Otherwise find the longest prefix for which prefix .. "..." fits.
end
```

Prefer a binary search over the string length rather than repeatedly removing one character at a time.

Recalculate the displayed item name whenever:

- `SetItemName()` changes the name;
- `SetLayoutMetrics()` changes the available text width.

The cost line must also be single-line and must not bleed outside the entry. It may use the same fitting helper if necessary, but the explicit design requirement is that the **item name always ellipsizes correctly**.

## 4.4 Text sizing

The item name should use the normal body size used by `SpellbookEntry`.

The cost line should be slightly smaller and use a secondary/muted text colour so the name remains visually primary.

Both lines must fit within the same vertical envelope as the compact Spellbook-style entry.

---

# 5. Guild Shop Data Semantics

The current GuildSetting schema treats every requisition as character-limited and normalizes `characterLimit` to at least `1`.

Change the meaning of `characterLimit` to:

```text
characterLimit = 0  -> unlimited; display in Guild Shop
characterLimit > 0  -> limited; display in right-hand Requisitions panel
```

Keep the default value at `1` so existing requisitions preserve their current one-time behaviour unless explicitly changed to `0`.

Do **not** introduce a second `shop` dataset collection. Both sections continue to use the existing `rank.requisitions` definitions and are partitioned by `characterLimit` at runtime.

## 5.1 `core/classes/GuildSetting.lua`

Change requisition normalization from a minimum of `1` to a minimum of `0`:

```lua
characterLimit = normalizeInteger(source.characterLimit, 1, 0)
```

No other requisition schema change is required.

## 5.2 GuildSetting inspector

In:

```text
client/ui/editor/inspectors/page_InspectorGuildSetting.lua
```

allow the Character Limit input to save `0`.

Do not add explanatory help text to the inspector. The existing `Character Limit` field remains the authoring control; `0` is simply a valid value.

---

# 6. Unlimited Requisition Transaction Behaviour

Modify `client/client_Guild.lua` so `characterLimit == 0` does not interact with the character usage ledger.

## 6.1 Eligibility

In `Guild:GetRequisitionEligibility(...)`:

- normalize `characterLimit` with a minimum of `0`;
- when `characterLimit > 0`, preserve the existing usage lookup and `character-limit-reached` check;
- when `characterLimit == 0`, skip the usage-limit rejection entirely.

Return enough normalized detail for the transaction path to know whether the requisition is unlimited.

Conceptually:

```lua
local characterLimit = math.max(0, math.floor(...))
local isUnlimited = characterLimit == 0

if not isUnlimited then
    usage = Profile.GetGuildRequisitionUsage(...)
    if usage >= characterLimit then
        return false, "character-limit-reached", ...
    end
end
```

All existing affordability, item-reference, currency-reference, guild-rank, and inventory validation remains unchanged.

## 6.2 Commit

In `Guild:TryRequisition(...)`:

- preserve the existing transactional currency spending;
- preserve the inventory award and rollback logic;
- for `characterLimit > 0`, preserve the existing ledger increment and ledger rollback behaviour;
- for `characterLimit == 0`, **do not increment or write the requisition usage ledger**.

An unlimited shop item can therefore be purchased repeatedly for as long as the player remains eligible and can afford its cost.

---

# 7. Daily Rewards Must Become Click-to-Claim

The current runtime calls `Guild:ProcessDailyRewards()` from `Guild:HandleRuntimeEvent(...)`, which means rewards are automatically processed on login/guild events.

That behaviour conflicts with the final page design, where the player claims the reward by clicking the Daily Reward icon.

## 7.1 Runtime behaviour

Change `Guild:HandleRuntimeEvent(...)` so these events:

```text
PLAYER_ENTERING_WORLD
PLAYER_GUILD_UPDATE
GUILD_ROSTER_UPDATE
```

refresh guild state/window state but **do not award the daily reward**.

The existing daily reward transaction/rollback implementation should remain the authoritative award path.

Add a clear public wrapper if useful:

```lua
function Guild:TryClaimDailyReward()
    return self:ProcessDailyRewards()
end
```

The page should call the public claim method from the ImageButton click handler.

Do not create a second reward-award implementation in the page.

---

# 8. Daily Reward Reset Boundary

The visible countdown and the claim ledger must change at the same reset boundary.

The existing implementation derives the claim key from `date("%Y-%m-%d", GetServerTime())`. Replace that logic with a reset-cycle key derived from WoW's daily reset boundary.

Use Blizzard's daily-reset API when available:

```lua
C_DateAndTime.GetSecondsUntilDailyReset()
```

Create a single Guild helper responsible for both the countdown and cycle key, for example:

```lua
Guild:GetDailyRewardResetState()
```

Return data conceptually like:

```lua
{
    secondsRemaining = 15783,
    cycleKey = "2026-08-26",
}
```

A convenient way to preserve the existing `YYYY-MM-DD` Profile claim format is to define the cycle key as the calendar date of the **next daily reset**:

```lua
local now = Common.GetNow()
local secondsRemaining = C_DateAndTime.GetSecondsUntilDailyReset()
local nextResetTimestamp = now + secondsRemaining
local cycleKey = date("%Y-%m-%d", nextResetTimestamp)
```

This key changes when the daily reset passes while remaining compatible with the existing Profile date normalization.

`Guild:GetDailyRewardStatus()` and `Guild:ProcessDailyRewards()` must use this same cycle key.

If the reset API is unavailable, fail cleanly with the existing unavailable/calendar status rather than silently using a different reset boundary for the claim ledger and countdown.

---

# 9. Header Implementation

Rewrite the top of `page_GuildRequisitions.lua` as one `HorizontalLayoutGroup`.

## 9.1 Daily Reward ImageButton

Create the Daily Reward control with:

```lua
UI.ImageButton
```

Use a square reward/gift icon texture.

The button click behaviour is:

```text
available -> claim -> refresh page
claimed   -> no award
invalid   -> no award
pending   -> ignore additional clicks
```

Do not add a visible `Daily Rewards` label next to or above the icon.

## 9.2 Daily Reward tooltip

The ImageButton tooltip must list all rewards configured for the assigned rank.

Build the tooltip dynamically from the current daily reward status/rank so it always reflects active dataset content.

Example content:

```text
Daily Rewards
[icon] Field Ration            x2
[icon] Guild Commendation      x1
```

Use the existing RPE tooltip system and its icon-bearing line support.

For item rewards:

- resolve item name/icon through the Registry/item definition.

For currency rewards:

- resolve currency name/icon through the Profile currency definition.

Use the standard question-mark icon as a fallback when a referenced icon cannot be resolved.

The tooltip should remain available after the reward has already been claimed. If disabling the ImageButton through `SetEnabled(false)` prevents hover behaviour in the target client, keep the button mouse-enabled, gate claiming in the click handler, and apply the unavailable/claimed visual state separately.

## 9.3 Guild rank text

To the right of the reward icon, show the assigned RPE guild-rank name only in the required form:

```text
Guild Rank: Knight
```

Use the existing assigned-rank resolution from `Client.Guild:GetAssignedGuildRankStatus()`.

Do not append explanatory status prose.

## 9.4 Reset timer

Directly below the rank, show:

```text
Daily Reset in 04:23:18
```

Format the remaining seconds as `HH:MM:SS`.

Start a lightweight one-second ticker while the Requisitions page is visible and cancel it when hidden.

The ticker should normally update only the timer text. If it detects that the reset cycle key has changed, perform a full page refresh so the Daily Reward button becomes claimable for the new cycle.

---

# 10. Guild Shop Layout

The Guild Shop must visually follow the existing Profile Spellbook rather than a generic scrolling list.

## 10.1 Fixed two-column grid

Use a `GridLayoutGroup` with:

```text
columns = 2
```

Create a fixed pool of `ShopEntry` objects, just as the Spellbook creates a fixed pool of `SpellbookEntry` objects.

Use the Spellbook's pagination pattern:

1. collect all unlimited requisitions;
2. calculate page count;
3. slice the current page's rows;
4. populate the fixed entry pool;
5. hide unused entries;
6. update Previous/Next/page controls.

Do **not** use `ScrollLayout` for the Guild Shop.

## 10.2 Page capacity

Use constants near the top of `page_GuildRequisitions.lua`, following the style of `page_ProfileSpellbook.lua`:

```lua
local SHOP_COLUMNS = 2
local SHOP_ROWS = 7
local SHOP_ENTRIES_PER_PAGE = SHOP_COLUMNS * SHOP_ROWS
```

Start with seven rows because the existing Spellbook uses seven compact rows and the Guild window has sufficient vertical space once the header and pagination strip are accounted for.

Keep the row count in one constant so it can be tuned after in-game visual testing without changing pagination logic.

## 10.3 Pagination controls

Mirror the Spellbook's page controls rather than introducing another visual style.

The shop region should have a bottom `HorizontalLayoutGroup` containing:

- Previous button;
- page indicator;
- Next button.

The page indicator can use the same concise form used elsewhere in RPE, e.g.:

```text
Page 1 / 3
```

These controls are functional pagination UI and are not section/help labels.

## 10.4 Entry binding

For each visible unlimited requisition:

- resolve item definition/name/icon;
- build compact cost text;
- set the `ShopEntry` data;
- evaluate eligibility through `Guild:GetRequisitionEligibility(...)`;
- bind left click directly to `Guild:TryRequisition(...)`;
- refresh the page after the transaction attempt.

There is no selection state and no separate `Requisition` button.

The transaction layer remains authoritative; disabled/available UI state is only presentation.

---

# 11. Cost Formatting

Create one helper in `page_GuildRequisitions.lua` for compact cost text so both the Guild Shop and limited Requisitions panel display costs identically.

For each requisition cost:

- resolve the currency definition;
- use the currency display name or compact representation already available in RPE;
- format amount and currency consistently;
- join multiple costs on one line.

Example:

```text
2 Commendations, 50 Silver
```

Do not prefix the line with `Cost:` because the position beneath the item name already defines its meaning.

The full cost list can be included in the ShopEntry tooltip if a tooltip is attached, but no additional on-page help text should be added.

---

# 12. Limited / One-Time Requisitions Panel

The right-hand panel contains every requisition for which:

```lua
characterLimit > 0
```

This includes the normal one-time case (`characterLimit == 1`) and any future finite multi-claim requisitions.

Use:

```lua
UI.ScrollLayout
```

with:

```lua
rowElementClass = UI.ShopEntry
rowHeight = SHOP_ENTRY_HEIGHT
autoFitRows = true
```

Each ShopEntry spans the full width of the right-hand panel.

A limited requisition remains visible after its limit is reached but is rendered unavailable/disabled. Do not remove it from the list, because doing so would cause the list to reorder after claims.

Clicking an eligible limited ShopEntry calls the same existing transaction method as an unlimited shop entry:

```lua
Guild:TryRequisition(assignedRankRef, requisition.id)
```

There is no separate action button.

---

# 13. `page_GuildRequisitions.lua` Rewrite

The current page is a provisional functional UI and should be substantially replaced.

Remove the current page elements and state associated with:

```text
StatusText
DailyPanel
DailyTitle
DailyList
DailyEmptyText
RequisitionTitle
SelectedRequisitionIndex
SelectedRequisitionItems
RequisitionButton
RequisitionActionStatus
RequisitionEmptyText
selection highlighting
instruction/status prose
```

Replace them with:

```text
RootLayout
HeaderLayout
DailyRewardButton
RankResetLayout
GuildRankText
DailyResetText
MainContentLayout
ShopLayout
ShopGrid
ShopEntries[]
ShopPaginationLayout
ShopPreviousButton
ShopPageText
ShopNextButton
LimitedRequisitionList
```

Suggested page state:

```lua
self.CurrentShopPage = 1
self.ShopEntries = {}
self.ShopItems = {}
self.LimitedRequisitionItems = {}
self.DailyRewardPending = false
self.ResetTicker = nil
self.LastResetCycleKey = nil
```

---

# 14. Refresh Flow

`RequisitionsPage:Refresh()` should follow this order:

```text
Resolve assigned RPE guild rank status
        ↓
Update Guild Rank text
        ↓
Resolve daily reward/reset state
        ↓
Update Daily Reward icon/button state
        ↓
Update Daily Reward tooltip source
        ↓
Partition rank.requisitions:
    characterLimit == 0 -> Guild Shop
    characterLimit > 0  -> Limited Requisitions
        ↓
Clamp CurrentShopPage
        ↓
Populate two-column ShopEntry page
        ↓
Populate limited ScrollLayout
        ↓
Update pagination controls
```

Do not perform requisition business logic directly in `Refresh()` beyond calling the existing eligibility API.

---

# 15. Window Title

`client/character/guild/window_Guild.lua` currently appends assigned-rank information to the window title during refresh.

Because the final Requisitions page explicitly displays the player's rank in the header, keep the Guild window title as:

```text
Guild
```

Do not duplicate the rank in the title while this page is active.

The Guild window exposes the two surviving tabs:

```text
Requisitions
Admin
```

---

# 16. Layout Rules

Use RPE layout abstractions wherever they fit naturally.

## Root

```text
VerticalLayoutGroup
```

- header: fixed compact height;
- main content: `expandHeight = true`, `weight = 1`.

## Header

```text
HorizontalLayoutGroup
```

- Daily Reward ImageButton: fixed square width;
- rank/reset column: expand width.

## Rank/reset column

```text
VerticalLayoutGroup
```

- rank text;
- reset text.

## Main content

```text
HorizontalLayoutGroup
```

- shop: `expandWidth = true`, weight approximately `7`;
- limited requisitions: `expandWidth = true`, weight approximately `3`.

## Shop

```text
VerticalLayoutGroup
```

- grid expands to fill available height;
- pagination bar has fixed compact height.

## Shop entries

```text
GridLayoutGroup
columns = 2
fitChildrenWidth = true
```

Use layout spacing constants rather than manual `SetPoint()` calculations for every entry.

Manual anchoring should be limited to places where an RPE layout primitive does not reasonably express the desired prefab internals.

---

# 17. Files to Modify

## New

```text
core/ui/prefabs/ShopEntry.lua
```

## Modify

```text
RPEngine_Dev.toc
core/classes/GuildSetting.lua
client/ui/editor/inspectors/page_InspectorGuildSetting.lua
client/client_Guild.lua
client/character/guild/page_GuildRequisitions.lua
client/character/guild/window_Guild.lua
```

`core/internal/profile/Guild.lua` should not require a schema change if the daily reset cycle remains represented by the existing `YYYY-MM-DD` claim string and unlimited shop entries simply bypass the usage ledger.

---

# 18. Suggested Implementation Order

## Step 1 — Add unlimited requisition semantics

1. Allow `characterLimit = 0` in `GuildSetting.lua`.
2. Allow `0` in the GuildSetting inspector.
3. Update `GetRequisitionEligibility()` to bypass the ledger for unlimited entries.
4. Update `TryRequisition()` to avoid ledger writes for unlimited entries.
5. Verify existing `characterLimit >= 1` behaviour remains unchanged.

## Step 2 — Convert daily rewards to manual claim

1. Stop automatic reward processing in `HandleRuntimeEvent()`.
2. Keep runtime events refreshing guild UI/state.
3. Add/reset-state helper based on the WoW daily reset boundary.
4. Make daily status use the reset-cycle key.
5. Expose a clean click-to-claim Guild API.

## Step 3 — Implement `ShopEntry.lua`

1. Clone the relevant visual structure of `SpellbookEntry.lua`.
2. Replace the single name text area with name + cost rows.
3. Add robust ellipsis logic.
4. Ensure `SetLayoutMetrics()` recalculates text widths/truncation.
5. Add the prefab to the TOC.

## Step 4 — Rewrite the Requisitions page

1. Replace the current provisional page hierarchy.
2. Build the header with ImageButton + rank/reset vertical layout.
3. Build the lower weighted horizontal layout.
4. Build the two-column shop grid and fixed ShopEntry pool.
5. Add Spellbook-style pagination.
6. Build the right-hand ShopEntry ScrollLayout.
7. Bind both entry regions directly to `TryRequisition()`.
8. Remove all selection/action/status UI.

## Step 5 — Reset ticker and tooltip

1. Add one-second visible-page ticker.
2. Refresh the whole page when the reset cycle changes.
3. Build dynamic Daily Reward tooltip rows.
4. Confirm tooltip still works after the reward has been claimed.

## Step 6 — Window cleanup

1. Stop appending the assigned rank to the Guild window title.
2. Keep the title simply `Guild`.

---

# 19. Acceptance Criteria

## Layout

- [ ] The upper-left control is a `UI.ImageButton`.
- [ ] The player's assigned RPE Guild Rank appears to the right of the icon.
- [ ] The daily reset countdown appears immediately below the rank.
- [ ] The Guild Shop occupies the large left portion of the lower page.
- [ ] The Guild Shop uses a **two-column `GridLayoutGroup`**.
- [ ] The Guild Shop visually follows the existing Spellbook grid/pagination pattern.
- [ ] The Guild Shop is paginated and does not scroll.
- [ ] The right-hand limited Requisitions panel uses `ScrollLayout`.
- [ ] Both lower sections display `ShopEntry` objects.
- [ ] There are no visible Guild Shop/Requisitions section headings.
- [ ] There is no instructional/help/status prose on the page.
- [ ] There is no separate Requisition/Purchase button.

## ShopEntry

- [ ] ShopEntry uses the same icon-left/text-right visual language as `SpellbookEntry`.
- [ ] Item name appears above the item cost.
- [ ] Item name never wraps.
- [ ] Item name is truncated with `...` whenever it exceeds the available width.
- [ ] Truncation is recalculated after entry-width changes.
- [ ] Item cost appears directly beneath the name.
- [ ] ShopEntry works at both the wide two-column shop width and narrow requisition-panel width.

## Guild Shop

- [ ] `characterLimit = 0` is accepted by the data model/editor.
- [ ] `characterLimit = 0` entries appear in the Guild Shop only.
- [ ] Unlimited entries can be purchased repeatedly while affordable/eligible.
- [ ] Unlimited entries do not create or increment a Profile requisition-usage ledger entry.
- [ ] Currency spending and inventory awards still use the existing transactional/rollback code.

## Limited Requisitions

- [ ] `characterLimit > 0` entries appear in the right-hand list only.
- [ ] Existing one-time requisition behaviour is preserved for the default `characterLimit = 1`.
- [ ] Finite limits greater than one continue to work.
- [ ] Exhausted requisitions remain visible but unavailable.

## Daily Rewards

- [ ] Logging in or receiving a guild-roster event does not automatically grant the daily reward.
- [ ] Hovering the Daily Reward icon lists all configured rewards.
- [ ] Clicking the icon while eligible awards the configured rewards using the existing transaction path.
- [ ] A claimed reward cannot be claimed again during the same reset cycle.
- [ ] The Daily Reward tooltip remains accessible after claiming.
- [ ] The countdown uses the same daily-reset boundary as claim eligibility.
- [ ] When the reset occurs while the page is open, the button becomes available again without reopening the Guild window.

## Regression

- [ ] The Admin tab is unaffected.
- [ ] Existing guild-rank assignment logic is unaffected.
- [ ] Existing built-in and dataset currency costs continue to work.
- [ ] Existing inventory rollback and currency rollback behaviour remains intact.
- [ ] Existing profiles require no destructive migration.

---

# 20. Non-Goals

This task does not add:

- a separate Guild Shop dataset collection;
- new requisition currencies;
- new guild-rank assignment rules;
- new Guild Admin behaviour;
- separate purchase confirmation dialogs;
- extra explanatory labels/help text;
- a new tooltip framework;
- a new pagination framework.

The final page should remain a presentation layer over RPE 2's existing Guild, Profile, Registry, Inventory, Currency, Tooltip and transaction systems.
