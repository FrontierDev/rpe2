## Validation result: revision required

Static validation of commit `9d609578788b931d7f14d839aed8833762c532a6` shows that the core #46 implementation is largely correct, but the commit also introduces unrelated visual regressions from the previously accepted Requisitions page. Do **not** close #46 yet.

### What passes

The requested #46 behavior is implemented coherently:

- built-in `copper` requisition costs are normalized through the existing Profile currency API and formatted through `Common:FormatCopper(...)` rather than a duplicate money formatter;
- non-copper currencies retain compact currency-icon + amount rendering;
- mixed cost lists format each component independently;
- copper Daily Reward tooltip amounts use `Common:FormatCopper(...)` instead of `xN`;
- `GetRequisitionEligibility()` remains authoritative for affordability; the page only keys the warning state from the returned `insufficient-currency` reason;
- `ShopEntry:SetCostColor(...)` provides a narrow reusable presentation API;
- the red cost state is reset to `text.secondary` when an entry is rebound or hidden, so recycled rows do not retain stale affordability coloring;
- both Guild Shop and limited Requisition rows pass through the same `BindShopEntry(...)` path;
- disabled rows remain mouse-enabled for item tooltips;
- the paginator now uses a full-width host with a fixed-width pagination layout anchored at the host center, while the grid retains the expandable area above it;
- page-count/navigation and requisition transaction logic were not changed;
- `utils/Common.lua` and `client/client_Guild.lua` were not modified by the implementation.

There are no configured commit status checks on this commit, so this validation is static source inspection rather than an in-game runtime test.

### Blocking regression 1: Daily Reward icon was changed outside scope

This commit changes:

```lua
local DAILY_REWARD_ICON = "Interface\\Icons\\INV_Misc_Gift_01"
```

to:

```lua
local DAILY_REWARD_ICON = "Interface\\Icons\\spell_nature_timestop"
```

#46 does not request a Daily Reward button icon change. This is unrelated scope drift and changes a previously accepted UI element.

**Required revision:** restore the pre-#46 Daily Reward icon:

```lua
local DAILY_REWARD_ICON = "Interface\\Icons\\INV_Misc_Gift_01"
```

unless a separate explicit issue is created/approved to change that icon.

### Blocking regression 2: Both panel headers were renamed

#45 explicitly established the accepted panel headers as:

```text
Guild Shop
Requisitions
```

Commit `9d609578...` changes them to:

```text
Requisitions
Special Requisitions
```

Specifically:

```lua
"Guild Shop" -> "Requisitions"
"Requisitions" -> "Special Requisitions"
```

That rename is unrelated to copper formatting, affordability coloring, or paginator alignment, and regresses the layout accepted in #45.

**Required revision:** restore the exact previous header text:

```lua
self.GuildShopHeader ... "Guild Shop"
self.LimitedRequisitionHeader ... "Requisitions"
```

Do not rename these sections as part of #46.

### Re-validation matrix for rev 1

After the revision, verify at minimum:

```text
Daily Reward button
-> uses the pre-#46 gift icon

left panel header
-> "Guild Shop"

right panel header
-> "Requisitions"

50 / 125 / 12345 copper cost
-> Common money formatting

copper + non-copper mixed cost
-> copper uses Common formatter; other currency uses compact icon + amount

copper Daily Reward
-> formatted money amount, not xN

affordable row
-> normal cost color

insufficient-currency row
-> numeric cost text red; currency textures remain normal; tooltip remains available

character-limit-reached row
-> disabled/subdued but not affordability-red

recycled insufficient -> affordable row
-> red state is cleared

0 / 1 / 14 / 15 shop entries
-> paginator remains centered at the bottom and navigation behavior is unchanged
```

The requested #46 implementation otherwise looks consistent from static source inspection. The two unrelated visual regressions above are the remaining blockers.