# Task 7 Revision — Fix Requisition Currency Spending

## Goal

Fix the currency-spending bug in `Guild:TryRequisition()`.

Do not redesign the transaction system or change unrelated Task 7 behavior.

## Problem

The current code uses:

```lua
local spent, updated = pcall(Profile.SpendCurrencyAmount, cost.currencyRef, cost.amount)
```

However, `Profile.SpendCurrencyAmount()` returns:

```lua
success, updatedAmount
```

Therefore `pcall()` returns:

```lua
callOk, spendOk, updatedAmount
```

The current implementation captures only the first two values, meaning `updated` receives the boolean `spendOk` instead of the new numeric balance.

This causes the subsequent comparison:

```lua
updated ~= expected
```

to always fail for a successful currency spend, so any Requisition with a currency cost rolls back.

## Required Fix

Capture all three return values from `pcall()`.

Use logic equivalent to:

```lua
local callOk, spendOk, updated =
    pcall(Profile.SpendCurrencyAmount, cost.currencyRef, cost.amount)

local gotAfter, after =
    pcall(Profile.GetCurrencyAmount, cost.currencyRef)

after = gotAfter and tonumber(after) or nil

if not callOk
    or spendOk ~= true
    or not gotAfter
    or updated ~= expected
    or after ~= expected
then
    local restored = rollbackCurrencies()
    return false,
        restored and "currency-transaction-failed" or "rollback-failed",
        detail
end
```

## Constraints

- Fix this bug only.
- Preserve the existing validation order.
- Preserve the existing rollback mechanism.
- Preserve the existing Requisition ledger behavior.
- Preserve `Client.Inventory.AddItem()` as the item-award path.
- Do not add Daily Reward behavior.
- Do not change Guild Rank eligibility behavior.
- Do not use legacy `requiredGuildRankIndex`.
- Do not modify unrelated systems.

## Acceptance Criteria

- [ ] A Requisition with one currency cost succeeds when the player can afford it.
- [ ] A Requisition with multiple currency costs succeeds when all costs are affordable.
- [ ] Built-in `copper` costs work.
- [ ] Insufficient currency causes no spending.
- [ ] A failure after one or more currency deductions restores the original balances.
- [ ] Existing item-award and Requisition-ledger rollback behavior remains intact.
- [ ] No unrelated Task 7 behavior is changed.

## Coding-Agent Instructions

Inspect the current `Guild:TryRequisition()` implementation and `Profile.SpendCurrencyAmount()` return contract before editing.

Implement this fix only.

When finished, review the diff against every acceptance criterion above and report any deviation.