## Goal
Fix three remaining runtime presentation issues on the Guild Requisitions page:

1. requisition costs using the built-in `copper` currency must use the existing copper/money formatter in `Addon.Utils.Common`;
2. Daily Reward entries granting `copper` must use the same copper formatter;
3. the Guild Shop paginator must be centered at the bottom of the left panel, and unaffordable requisition cost text must clearly show the amount in red.

This is a presentation-only task. Preserve all requisition, eligibility, Daily Reward, reset-cycle, transaction, pagination-count, Profile persistence, and Guild Rank semantics.

## Current source observations

The current Requisitions page formats every cost as a generic currency icon plus integer amount. The repository already has:

```lua
Common:FormatCopper(amount)
```

in `utils/Common.lua`, and `Profile.FormatCurrencyAmount(...)` already delegates built-in `copper` to that formatter. Do not duplicate WoW money formatting.

`Guild:GetRequisitionEligibility()` already distinguishes `insufficient-currency` and returns detail containing `currencyRef`, `balance`, and required `amount` for the first failing cost. Reuse the authoritative eligibility result; do not reimplement purchasing rules in the UI.

## Primary files

- `client/character/guild/page_GuildRequisitions.lua`
- `core/ui/prefabs/ShopEntry.lua` only if a small reusable cost-text color API is required
- `utils/Common.lua` should normally remain unchanged

## 1. Copper requisition costs

When a requisition cost resolves to the built-in currency key `copper`, render the amount with `Addon.Utils.Common.FormatCopper` rather than the generic currency-icon formatter.

Examples:

```text
50 copper     -> 50[copper icon]
125 copper    -> 1[silver icon] 25[copper icon]
12345 copper  -> 1[gold icon] 23[silver icon] 45[copper icon]
```

Use the exact existing `Common` implementation and inline texture output. Do not create a second gold/silver/copper formatter.

For non-copper currencies, retain the compact currency-icon + amount behavior introduced by #45.

For mixed multi-currency costs, each component should use the appropriate formatter independently.

## 2. Copper Daily Rewards

In the Daily Reward tooltip, a reward whose normalized currency key is `copper` must display its amount through `Common:FormatCopper(...)`.

Do not show `x12345` for copper. The tooltip may retain the currency label/row structure, but the displayed amount must be the formatted gold/silver/copper string.

Other currencies retain the existing icon/name + integer amount presentation.

Missing/unresolved reward definitions must continue to fail safely.

## 3. Unaffordable requisition cost amount is red

If a requisition is disabled specifically because `GetRequisitionEligibility()` returned:

```text
insufficient-currency
```

then the numeric text in the ShopEntry cost line must render red.

Requirements:

- the currency icon(s) should remain visually normal;
- the amount text is red for an unaffordable row;
- this applies to both unlimited Guild Shop entries and limited Requisition entries;
- affordability color must reset correctly when a recycled `ShopEntry` is rebound to an affordable item;
- rows disabled for a non-affordability reason (for example exhausted character limit) should use the normal disabled/subdued presentation rather than being incorrectly marked as insufficient funds;
- hover/item tooltip behavior remains available on disabled rows.

A narrow `ShopEntry:SetCostColor(...)` / `SetCostTextColor(...)` API is acceptable if needed. Prefer a reusable prefab API over directly reaching into internal font-string fields from the page.

## 4. Center the Guild Shop paginator

The existing previous/page/next paginator belongs at the bottom center of the Guild Shop panel.

Required visual result:

```text
                <   Page 1 / 2   >
```

Requirements:

- horizontally centered relative to the usable Guild Shop panel content width;
- remains at the bottom of the panel beneath the grid;
- remains centered when the window/layout recalculates width;
- does not depend on the number of visible shop entries;
- does not overlap the grid or panel border;
- Previous/Next enabled-state behavior and page calculations are unchanged.

Use the existing layout system where practical; a fixed-width centered paginator host is preferable to fragile hard-coded offsets.

## Acceptance criteria

- [ ] Built-in `copper` requisition costs use `Common:FormatCopper` output.
- [ ] Non-copper requisition costs still use compact currency icon + amount.
- [ ] Mixed costs format copper and non-copper components correctly.
- [ ] Copper Daily Reward amounts use `Common:FormatCopper` rather than `xN`.
- [ ] Other Daily Reward currencies retain their existing presentation.
- [ ] `insufficient-currency` entries render cost amount text red.
- [ ] Affordable/recycled entries restore the normal cost color.
- [ ] Non-affordability disable reasons do not incorrectly use red cost text.
- [ ] Both Guild Shop and limited Requisition rows behave identically.
- [ ] Paginator is horizontally centered at the bottom of the Guild Shop panel.
- [ ] Page count, navigation boundaries, and click transaction behavior are unchanged.

## Validation matrix

```text
cost = 50 copper
-> 50c via Common formatter

cost = 125 copper
-> 1s 25c via Common formatter

cost = 12345 copper
-> 1g 23s 45c via Common formatter

cost = valor
-> existing valor icon + integer amount

cost = copper + valor
-> Common copper format + compact valor format

Daily Reward = 12345 copper
-> formatted 1g 23s 45c amount, not x12345

affordable item
-> normal cost text color

insufficient-currency item
-> amount text red; item tooltip still hoverable

limited item exhausted by characterLimit
-> disabled/subdued, but not falsely red for affordability

recycled row unaffordable -> affordable
-> red state is cleared

0 / 1 / 14 / 15 shop entries
-> paginator remains centered at panel bottom and navigation remains correct
```

## Coding-agent instructions
Use current `FrontierDev/rpe2` as authoritative. This task is intended for **5.6-Luna-ExtraHigh**. Inspect `utils/Common.lua`, `core/internal/profile/Currencies.lua`, `client/client_Guild.lua`, `client/character/guild/page_GuildRequisitions.lua`, and `core/ui/prefabs/ShopEntry.lua` before editing. Reuse the existing copper formatter and authoritative eligibility result; do not duplicate transaction or currency logic. Report exact files changed and validation performed.