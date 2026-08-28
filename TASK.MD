## Problem

The Achievement inspector currently requires authors to type item/currency references manually instead of selecting valid dataset entries from dropdowns.

Current examples in `client/ui/editor/inspectors/page_InspectorAchievement.lua`:

- `currency_gain` criteria use a free-text `Currency Reference` input.
- `item_gain` criteria use a free-text `Item Ref` input.
- Achievement rewards use a generic free-text `Reference` input even when the reward type is `item` or `currency`.

This is inconsistent with the Recipe inspector, which uses dataset/entry dropdowns for item references. In `client/ui/editor/inspectors/page_InspectorRecipe.lua`, output/input item selection is driven by a dataset dropdown plus an item dropdown, populated from the current dataset contents.

## Goal

Replace free-text item/currency reference authoring in the Achievement editor with validated dropdown selection, following the same authoring pattern as the Recipe editor.

## Required changes

### 1. Item criterion filters

For `item_gain` criteria:

- replace the free-text `itemRef` field with dataset + item dropdown selection;
- populate datasets/items from Data Editor dataset contents, using/reusing the same helper patterns as the Recipe inspector where practical;
- persist the existing canonical `datasetId:itemId` reference format;
- load existing references back into the correct dataset/item selections.

### 2. Currency criterion filters

For `currency_gain` criteria:

- replace the free-text `currencyRef` field with a currency selector;
- include built-in currencies (`copper`, `valor`, `justice`, `honor`, `conquest`);
- include custom currencies from datasets available to the Data Editor;
- persist the existing canonical currency key/reference format;
- load existing references back into the selector correctly.

A dataset + currency two-stage selector is acceptable for custom currencies if that best matches the Recipe inspector pattern; built-in currencies must remain straightforward to select.

### 3. Achievement rewards

The reward editor must switch its reference selector according to reward type:

- `item` -> dataset + item dropdowns;
- `currency` -> currency dropdown/selector;
- amount remains a numeric input.

Changing reward type must update the visible selector and must not leave an incompatible stale reference silently attached to the reward.

### 4. Preserve existing data

- Do not change the Achievement schema.
- Existing valid `itemRef`, `currencyRef`, and reward `ref` values must continue to load and save unchanged.
- If an existing reference no longer resolves, show it as missing/unresolved rather than silently clearing it before the user makes a new selection.
- Do not require datasets to be activated merely to author references in the Data Editor.

## Primary files

- `client/ui/editor/inspectors/page_InspectorAchievement.lua`
- `client/ui/editor/inspectors/page_InspectorRecipe.lua` as the reference implementation/pattern
- shared Data Editor dataset/item/currency selector helpers where appropriate

## Acceptance criteria

- [ ] `item_gain` criteria can select an item without manually typing a reference.
- [ ] `currency_gain` criteria can select built-in and custom currencies without manually typing a reference.
- [ ] Item rewards use dropdown selection rather than a free-text reference.
- [ ] Currency rewards use dropdown selection rather than a free-text reference.
- [ ] Item selection follows the Recipe editor's dataset -> entry interaction pattern.
- [ ] Existing valid Achievement references round-trip without schema changes.
- [ ] Missing references remain visible/diagnosable and are not silently erased.
- [ ] Switching reward type updates the selector and cannot retain an incompatible stale reference unnoticed.
- [ ] Editing an Achievement still queues the normal dataset-entry change path and persists correctly.

## Validation

In the Data Editor:

1. Create/edit an Achievement with an `item_gain` criterion and select an item from another dataset.
2. Create/edit a `currency_gain` criterion using both a built-in currency and a custom dataset currency.
3. Add an item reward and select its item through dropdowns.
4. Add a currency reward and select its currency through dropdowns.
5. Save/reopen the Achievement and confirm all selections resolve to the same stored refs.
6. Change a reward from item -> currency and verify the selector/reference updates cleanly.
7. Load an Achievement containing an unresolved legacy ref and confirm the editor exposes it rather than deleting it.