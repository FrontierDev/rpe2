## In-game validation blocker — no currency grant path

Repository/static validation still passes, but the required in-game validation cannot currently be executed because there is no player-facing or debug command that grants RPE currency.

### Diagnosis

- `Profile.AddCurrencyAmount(currencyRefOrId, amount)` exists and is the correct gameplay-level API for exercising the #60 path.
- The current `/rpe` command router exposes timing/performance commands and client/UI commands, but no currency mutation command.
- Directly editing SavedVariables or calling `Database.SetProfileCurrencyAmount()` would be a poor validation method because it would bypass the normal `Profile.AddCurrencyAmount()` flow and therefore would not exercise the `currency_gain` Achievement trigger path.

### Required fix before #60 can be closed

Add a minimal development/debug slash command, preferably in `client/client_Commands.lua`, for example:

```text
/rpe debug currency add <currency> <amount>
```

Requirements:

- route through `Addon.Internal.Profile.AddCurrencyAmount(...)`;
- do not mutate SavedVariables or Database state directly;
- accept built-in keys such as `valor` and custom currency refs;
- validate amount > 0 and print the resulting balance;
- remain a development/debug test utility, not a new gameplay reward system.

This command is needed so the mandatory #60 in-game test can cover both:

1. currency gain with no Achievement progress;
2. currency gain that triggers `currency_gain` Achievement progress.

After that test harness exists, rerun the previously requested timing validation and keep #60 open until the user reports the in-game result.