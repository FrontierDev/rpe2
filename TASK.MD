## Goal
Remove ordinary mutable Profile state from the heavyweight **configuration-changed** pipeline and route it through the runtime revision/ChangeSet infrastructure instead.

Authoritative documents:

- `.docs/RPE2-Runtime-Performance-Hitch-Elimination-PDD.md`
- `.docs/RPE2-Runtime-Performance-Hitch-Elimination-Implementation-Plan.md`

Depends on: #59

This is the highest-impact architectural correction in the project. Complete it before attempting downstream UI or event optimizations.

## Primary files

- `core/internal/database/Database.lua`
- `core/internal/profile/Currencies.lua`
- `core/internal/profile/Achievements.lua`
- `core/internal/profile/Profile.lua`
- `client/client_Session.lua`
- runtime transaction/revision module added by #59

Inspect every current `notifyConfigurationChanged(...)` call in `Database.lua` and classify it before editing.

## 1. Audit every configuration-change reason

Produce an explicit source-level classification of all `notifyConfigurationChanged(reason)` call sites into:

```text
authored/configuration change -> remains on global path
mutable runtime/profile state -> moves to narrow runtime path
ambiguous structural profile change -> inspect dependencies and choose deliberately
```

At minimum inspect current reasons involving:

```text
profile-currency
profile-achievements
profile-achievement-rewards
profile equipment/profile structure
skills
spellbook/action bars
race/class/level or equivalent structural choices
dataset/ruleset activation/configuration
```

Do not mechanically move every `profile-*` reason. Some structural Profile choices may genuinely invalidate resolved configuration.

Report the final classification in the task result.

## 2. Add a narrow Profile runtime notification path

Create or wire a Profile/runtime state-change helper that:

- does **not** increment `ConfigurationRevision`;
- does **not** call `QueueLocalConfigurationRefresh`;
- does **not** call `HandleLocalConfigurationChanged`;
- marks the relevant runtime revision(s);
- appends the specific changed key/reference to the active Runtime ChangeSet;
- uses an implicit short transaction when called outside an existing transaction.

Keep the helper close to Database/Profile ownership rather than making low-level setters know about UI windows.

## 3. Refactor currency persistence

`Database.SetProfileCurrencyAmount()` must become a narrow runtime mutation.

Required behavior:

```text
validate/normalize key + value
mutate only the target balance
bump CurrencyRevision + ProfileStateRevision once per committed logical transaction
mark changed currency key in ChangeSet
return persisted value
```

It must not trigger:

```text
recipe knowledge rebuild
trait runtime refresh
Achievement definition index rebuild
Inventory refresh
Action Bar rebuild
client-connect refresh
unrelated resource synchronization
```

Where practical, stop re-normalizing/reallocating the entire currency map for a normal read/write. Preserve backwards-compatible normalization at load/migration boundaries.

Preserve public return values of `Profile.Get/Set/AddCurrencyAmount()`.

## 4. Refactor Achievement state persistence

Move mutable Achievement state and reward-state persistence away from `notifyConfigurationChanged(...)`.

This includes current equivalents of:

```text
SetProfileAchievementState
ClearProfileAchievementState
SetProfileAchievementRewardState
ClearProfileAchievementRewardState
```

Required behavior:

- preserve stored schema and values;
- bump `AchievementRevision` / `ProfileStateRevision` narrowly;
- mark affected Achievement refs in the transaction ChangeSet;
- do not rebuild Achievement **definitions/indexes** because progress changed;
- do not refresh Profile UI directly from the Database layer.

Full trigger/reward batching is owned by the next task; this task fixes persistence/invalidation semantics only.

## 5. Restrict `HandleLocalConfigurationChanged()` to genuine configuration

Keep `Client:HandleLocalConfigurationChanged(reason)` as the heavyweight path for actual configuration changes.

Where low-risk and clear, split its internal work into named subscopes so genuine configuration causes can avoid unrelated work later, but do not turn this task into a complete Session rewrite.

The critical requirement is that normal currency/Achievement state changes no longer reach it.

Remove `profile-currency` / `profile-achievements` / reward-state reasons from any logic that forces client reconnect/hash refresh or broad resource/configuration refresh.

## 6. Guard against future regression

Add a debug assertion/logging hook, classification table, or similarly lightweight safeguard so development builds can detect known runtime-only reasons entering the configuration path.

Do not throw fatal errors in normal user gameplay.

## Acceptance criteria

- [ ] Every `notifyConfigurationChanged` call site has been inspected and classified.
- [ ] Currency amount changes do not increment `ConfigurationRevision`.
- [ ] Achievement progress/reward-state changes do not increment `ConfigurationRevision`.
- [ ] Currency mutations mark `CurrencyRevision` and the changed currency key.
- [ ] Achievement state mutations mark `AchievementRevision` and affected refs.
- [ ] Normal currency/Achievement state changes do not call `HandleLocalConfigurationChanged()`.
- [ ] Normal currency/Achievement state changes do not trigger client-connect refresh.
- [ ] Achievement definition indexes still rebuild after genuine dataset/configuration changes.
- [ ] Existing Profile/Currency/Achievement SavedVariables remain compatible.
- [ ] Public Profile currency/Achievement APIs retain current return semantics.

## Validation matrix

```text
record ConfigurationRevision
grant valor +1
-> balance changes
-> CurrencyRevision changes
-> ConfigurationRevision unchanged
-> no HandleLocalConfigurationChanged("profile-currency")

currency gain that advances no Achievement
-> only currency/profile runtime scopes marked

set Achievement criterion progress
-> AchievementRevision changes
-> ConfigurationRevision unchanged
-> no Achievement definition index rebuild

set Achievement reward state
-> state persists
-> no global configuration refresh

activate/deactivate dataset
-> genuine configuration path still runs
-> ConfigurationRevision changes
-> relevant definition caches/indexes refresh

change a genuinely structural Profile field classified as configuration-derived
-> existing required derived rebuilds still occur
```

## Constraints

- Do not redesign Achievement trigger/reward batching here; next task owns it.
- Do not redesign Inventory here.
- Do not weaken genuine dataset/ruleset/profile-structure invalidation.
- Do not change currency or Achievement gameplay semantics.
- Do not change SavedVariable schema unless an idempotent compatibility normalization is strictly necessary.
- Do not call UI refresh methods from Database/Profile setters.

## Coding-agent instructions
Use current `FrontierDev/rpe2` as authoritative. This task is intended for **5.6-Luna-ExtraHigh**. Read both runtime-performance documents and completed #59. Before editing, search **all** `notifyConfigurationChanged` call sites and classify them by actual dependency impact. This task must fix the architectural boundary, not merely special-case `profile-currency`. Report the classification table, exact reasons moved off the global path, revisions/ChangeSet data emitted, files changed, and validation proving `ConfigurationRevision` stays unchanged during ordinary currency/Achievement mutations.