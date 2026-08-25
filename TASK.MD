## Goal
Fix GuildSetting/Guild Rank currency authoring so all currency references are selected through dropdowns and the built-in currencies are available alongside dataset-defined currencies.

This task addresses two current defects:

1. built-in currencies (`copper`, `valor`, `justice`, `honor`, `conquest`) do not appear in the Guild Rank currency selectors;
2. requisition costs still require manually typing `currencyRef` into a text field.

No currency schema change is required. Persist exactly the existing currency reference formats:

```text
built-in currency:        copper
built-in currency:        valor
custom dataset currency:  dataset_id:currency_id
```

## Dependency / ordering
**Depends on #47.** Implement after the GuildSetting inspector pages have been converted to scroll views, because both tasks substantially modify `client/ui/editor/inspectors/page_InspectorGuildSetting.lua`.

This task is otherwise independent of #46's runtime presentation changes.

## Current source observations

`core/internal/profile/Currencies.lua` already defines the authoritative built-ins and exposes:

```lua
Profile.GetBuiltinCurrencyDefinitions()
Profile.NormalizeCurrencyKey(...)
Profile.ResolveCurrencyDefinition(...)
Profile.ListCurrencyDefinitions(...)
```

The existing GuildSetting Daily Reward currency UI only lists currencies from a selected dataset, which inherently excludes built-ins because built-ins are not dataset-qualified.

The current requisition cost editor still uses:

```lua
GuildSettingInspectorCostCurrencyRefInput = UI.CreateTextInput(...)
```

and writes the raw text directly to `cost.currencyRef`.

Do not create a second hard-coded built-in currency list if the Profile currency API can be used as the source of truth.

## Primary file

- `client/ui/editor/inspectors/page_InspectorGuildSetting.lua`

Reference/supporting files to inspect:

- `core/internal/profile/Currencies.lua`
- `client/ui/editor/inspectors/item/page_InspectorItemShared.lua`
- `client/ui/editor/inspectors/page_InspectorRecipe.lua`
- `core/ui/elements/Dropdown.lua`

## 1. Add a GuildSetting currency-dropdown item builder

Create a reusable GuildSetting-specific helper that can build currency dropdown items containing:

### Built-ins
Use the definitions returned by:

```lua
Profile.GetBuiltinCurrencyDefinitions()
```

At minimum the current built-ins should appear:

- Copper
- Valor
- Justice
- Honor
- Conquest

The stored dropdown values must be their canonical bare keys (`copper`, `valor`, etc.).

### Dataset-defined currencies
Include authorable custom currencies from the Data Editor datasets, storing the existing dataset-qualified value:

```text
dataset_id:currency_id
```

For authoring, do **not** rely only on activated Profile datasets if that would hide currencies from datasets currently being edited but not activated. Prefer the Data Editor's own dataset collection (`self:GetDatasets()` / existing inspector dataset helpers) as the source for custom authoring choices.

### Organization
Prefer one grouped Currency dropdown with a clear structure such as:

```text
Built-in
  Copper
  Valor
  Justice
  Honor
  Conquest

Dataset A
  Marks of Valor
  Guild Tokens

Dataset B
  ...
```

if the existing Dropdown supports grouped children cleanly.

If a two-control source/currency pattern is retained, use an explicit UI-level `Built-in` source option without inventing or persisting a fake dataset ID. The stored currency reference must still be the canonical bare built-in key.

### Missing/legacy values
If the currently stored currency reference cannot be resolved, preserve it in the dropdown as a clearly marked missing option rather than silently changing or clearing it.

Refreshing the inspector must never rewrite a valid or unresolved stored value merely because the dropdown is rebuilt.

## 2. Replace requisition cost currency text input with a dropdown

Remove the manual `GuildSettingInspectorCostCurrencyRefInput` authoring path.

Each selected requisition cost should expose:

```text
Currency: [dropdown]
Amount:   [numeric text input]
```

Requirements:

- currency dropdown uses the shared helper from section 1;
- built-ins are selectable;
- custom dataset currencies are selectable;
- selected value writes directly to existing `cost.currencyRef`;
- amount continues to write to existing `cost.amount` with current non-negative integer normalization;
- Add/Delete cost behavior remains unchanged;
- selected cost rows refresh correctly after changing currency;
- missing existing references remain representable and are not destroyed on refresh.

Update labels such as `Costs (Currency Ref / Amount)` if necessary so the UI no longer claims the user is entering a raw reference.

## 3. Fix Daily Reward currency selection

Daily Reward entries with:

```lua
type = "currency"
```

must use the same currency selector source and include built-ins.

The current dataset-only currency selection cannot represent a bare built-in currency key correctly. Refactor this presentation accordingly.

Preferred end-state:

```text
Reward Type: Currency
Currency: [grouped dropdown containing built-ins + custom currencies]
Amount:   [input]
```

It is acceptable to remove the separate `Currency Dataset` control for currency rewards if a grouped combined dropdown is used. Item rewards should retain their existing dataset + item selector behavior.

Persist:

```text
reward.ref = "copper"
```

for built-in Copper, and:

```text
reward.ref = "dataset_id:currency_id"
```

for custom currencies.

Do not alter `reward.type`, `reward.amount`, or Daily Reward runtime semantics.

## 4. Use one source of truth for both currency contexts

Requisition costs and Daily Reward currency rewards must use the same helper/item-building rules so they cannot drift apart again.

Do not maintain separate hard-coded lists for the two controls.

## Acceptance criteria

- [ ] GuildSetting currency dropdowns include all current built-in Profile currencies.
- [ ] Built-in currency values persist as bare canonical keys such as `copper`.
- [ ] Custom currencies persist as `dataset_id:currency_id`.
- [ ] Custom currencies from editable datasets are available even when the dataset is not currently activated, where consistent with existing Data Editor behavior.
- [ ] Requisition costs no longer require manual currency ID/reference entry.
- [ ] Requisition cost Currency is a dropdown.
- [ ] Daily Reward currency selection includes built-ins.
- [ ] Daily Reward custom currency selection still works.
- [ ] Item-type Daily Rewards retain their dataset + item selectors.
- [ ] Missing/legacy currency references are shown safely and preserved until the author changes them.
- [ ] Refreshing or switching GuildSetting pages does not silently clear selected currency references.
- [ ] Existing cost amount, reward amount, Add/Delete, normalization, and pending dataset-change behavior is preserved.
- [ ] No GuildSetting or Profile schema change is introduced.

## Validation matrix

```text
new requisition cost -> Copper
-> dropdown selection stores cost.currencyRef = "copper"

new requisition cost -> Valor
-> stores "valor"

new requisition cost -> custom currency in dataset A
-> stores "datasetA:currencyId"

existing cost with custom currency
-> inspector refresh preserves selection

existing cost with unknown/missing currency ref
-> marked missing in dropdown; value is not silently cleared

Daily Reward type = currency -> Copper
-> built-in option visible; reward.ref = "copper"

Daily Reward type = currency -> custom currency
-> custom option visible; dataset-qualified ref persists

Daily Reward type = item
-> existing item dataset/item selectors still work

inactive/non-activated editable dataset with currency
-> currency remains authorable if other Data Editor reference selectors expose that dataset

switch GuildSetting page / reopen Data Editor
-> selected currency references remain unchanged
```

## Coding-agent instructions
Use current `FrontierDev/rpe2` as authoritative. This task is intended for **5.6-Luna-ExtraHigh**. Implement after #47. Inspect `core/internal/profile/Currencies.lua` before editing and use its built-in definitions as the authoritative source. For custom authoring choices, inspect the Data Editor dataset helper behavior so non-activated editable datasets are not accidentally hidden. Replace the requisition cost raw text reference control rather than layering a dropdown beside it. Prefer one shared GuildSetting currency-item builder used by both requisition costs and Daily Rewards. Report exact files changed and validation performed.