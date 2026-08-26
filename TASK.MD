## Goal
Remove all **Guild Progression authoring UI** from the GuildSetting/Guild Rank Data Editor inspector while preserving the three surviving pages and the recent inspector improvements.

Authoritative plan: `.docs/RPE2-Remove-Guild-Progression-Implementation-Plan.md`.

Depends on: #51

This task is intentionally isolated to the editor surface so it does not overlap with the runtime Guild window/Admin cleanup.

## Primary file

- `client/ui/editor/inspectors/page_InspectorGuildSetting.lua`

Reference before editing:

- completed #51 `core/classes/GuildSetting.lua`
- issue #47 for the current per-page scroll-view architecture
- issue #48 for current GuildSetting currency selector behavior
- issue #45 for current inspector visual conventions

## 1. Remove the Progression inspector page

Change the GuildSetting inspector page list from the conceptual structure:

```text
General
Requisitions
Daily Rewards
Progression
```

to:

```text
General
Requisitions
Daily Rewards
```

Remove the Progression page definition, builder invocation, page frame/scroll shell, and page-selection routing.

Do not leave an empty fourth page.

## 2. Remove `Enable Progression`

Delete the General-page control that edits:

```lua
general.enableProgression
```

Remove any refresh/binding/validation code that reads or writes that field.

Do not replace it with another toggle.

## 3. Remove Progression authoring controls

Delete controls and editor state for Guild Progression definition fields, including current equivalents of:

```text
slotCount
progression entry list
entry id
entry name
entry description
entry icon
lockedText
spellRefs
add progression entry
delete progression entry
selected progression entry
selected progression spell/reference
```

Remove related helpers used only to:

- build Progression entry/spell dropdowns;
- normalize selected progression indexes/refs;
- update progression entry fields;
- add/delete progression entries;
- refresh progression controls;
- calculate Progression page dynamic height/scroll range.

Trace helper callers before deletion so generic dataset/reference-selector utilities are preserved.

## 4. Preserve the #47 scroll-view architecture

Issue #47 converted all GuildSetting pages to the shared scroll shell.

After this task:

```text
General        -> remains a scrollable inspector page
Requisitions   -> remains a scrollable inspector page
Daily Rewards  -> remains a scrollable inspector page
```

Remove only the Progression page's shell/registration.

Preserve:

- fixed page selector bar;
- mouse-wheel behavior;
- dynamic scroll-range updates;
- nested `UI.ScrollLayout` behavior;
- resize handling;
- existing visual scrollbar treatment.

Do not revert the remaining pages to fixed non-scroll frames.

## 5. Preserve #48 currency authoring

Do not regress current GuildSetting currency selector behavior:

- built-in currencies remain selectable;
- custom dataset currencies remain selectable;
- requisition costs remain dropdown-based rather than raw reference text;
- Daily Reward currency authoring remains dropdown-based;
- missing/legacy currency references remain safely representable.

Progression removal must not disturb the shared currency/reference helpers still used by Requisitions or Daily Rewards.

## 6. Preserve inspector visual conventions

Keep the existing Spell/Item-style GuildSetting inspector conventions introduced by recent issues:

- selector bar proportions;
- page padding/spacing;
- label/control sizing;
- list/action-row conventions;
- section/panel styling.

Removing Progression should simplify the inspector, not redesign it.

## 7. Handle legacy GuildSetting input safely

After #51, the underlying GuildSetting model no longer exposes active Progression configuration.

The inspector must therefore:

- not attempt to read `definition.progression`;
- not attempt to read/write `general.enableProgression`;
- not recreate missing progression tables as part of refresh;
- open legacy definitions without errors even if their raw source once contained those fields.

The model/normalizer is authoritative for discarding legacy fields; the inspector should simply ignore them.

## Acceptance criteria

- [ ] GuildSetting inspector has exactly General, Requisitions and Daily Rewards pages.
- [ ] No Progression page/frame/scroll shell is created.
- [ ] No `Enable Progression` control exists.
- [ ] No Progression entry list or Progression-specific input/dropdown/button exists.
- [ ] No inspector refresh path reads/writes `GuildSetting.progression`.
- [ ] No inspector refresh path reads/writes `general.enableProgression`.
- [ ] General/Requisitions/Daily Rewards pages remain scrollable and properly clipped.
- [ ] Requisition editor behavior remains intact.
- [ ] Daily Reward editor behavior remains intact.
- [ ] Built-in/custom currency selector behavior from #48 remains intact.
- [ ] Existing visual conventions remain intact.
- [ ] Opening a legacy GuildSetting does not error or recreate progression state.

## Validation matrix

```text
open GuildSetting inspector
-> selector shows General / Requisitions / Daily Rewards only

General page
-> Guild metadata/rank mapping/toggles still editable
-> no Enable Progression control
-> scroll behavior unchanged

Requisitions page
-> lists/selectors/cost editing still work
-> page scroll still works

Daily Rewards page
-> item/currency switching still works
-> built-in currency selection still works
-> page scroll range updates normally

legacy GuildSetting once containing progression fields
-> inspector opens
-> no Progression controls appear
-> no nil-index errors
-> editing unrelated fields does not recreate progression

resize Data Editor
-> three remaining page scroll shells remain valid
```

## Constraints

- Do not edit runtime Guild UI here.
- Do not reintroduce fields removed by #51 to make the inspector easier to compile.
- Do not remove generic dataset/reference/currency helpers still used by Requisitions or Daily Rewards.
- Do not redesign the inspector or page selector.
- Do not change Requisition/Daily Reward schema or business semantics.

## Coding-agent instructions
Use current `FrontierDev/rpe2` as authoritative. This task is intended for **5.6-Luna-ExtraHigh**. Read `.docs/RPE2-Remove-Guild-Progression-Implementation-Plan.md`, completed #51, and the current post-#47/#48 inspector before editing. This file is large: trace helper usage before deletion and keep the patch progression-specific. Search the file after editing for `enableProgression`, `Progression`, `progression.entries`, `slotCount`, `lockedText`, and stale Progression page identifiers. Report exact helpers/controls removed and validation performed on all three surviving pages.