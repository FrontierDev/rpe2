## Goal
Remove the **Progression administration surface** from the Guild Admin page after the runtime/query support has been removed.

Authoritative plan: `.docs/RPE2-Remove-Guild-Progression-Implementation-Plan.md`.

Depends on: #52

This task is a focused cleanup of `page_GuildAdmin.lua`. Preserve the roster/table/layout work from #49/#50 and all remaining Guild Admin operations.

## Primary file

- `client/character/guild/page_GuildAdmin.lua`

Reference before editing:

- completed #52 `client/client_Guild.lua`
- issue #49 for intended roster/table/hierarchical-selector behavior
- issue #50 for current roster/Admin panel containment behavior

## 1. Remove progression-specific member state

The Admin page currently tracks Progression state alongside Achievements and Skills.

Change all selected-member profile-state defaults/resets from the conceptual shape:

```lua
{
    achievements = {},
    skills = {},
    progression = nil,
}
```

to:

```lua
{
    achievements = {},
    skills = {},
}
```

Delete Progression-only selection state such as:

```text
SelectedProgressionEntryId
SelectedProgressionSlot
SelectedProgressionSpellRef
```

Remove stale progression reset logic from member selection, query refresh, rank mutation and page refresh paths.

## 2. Remove progression helpers

Delete helpers whose only purpose is interpreting or selecting Guild Progression state, including current equivalents of:

```text
getSelectedProgressionState
getSelectedProgressionRank
getSelectedProgressionEntry
getSelectedProgressionSpell
ensureSelectedProgressionState
```

Trace callers before deletion so no generic Guild Rank helper is accidentally removed.

## 3. Remove Progression section UI

Delete the Progression section from the Admin section selector.

Change the conceptual section list from:

```lua
{
    "Achievements",
    "Skills",
    "Items",
    "Progression",
}
```

to:

```lua
{
    "Achievements",
    "Skills",
    "Items",
}
```

Remove `Progression` from section-height tables such as `AdminSectionVisibleHeights`.

Delete Progression-specific layouts and controls, including current equivalents of:

```text
ProgressionActionLayout
ProgressionEntryActionLayout
ProgressionSpellActionLayout
ProgressionEntryDropdown
ProgressionSlotDropdown
AssignProgressionButton
LockProgressionButton
ProgressionSpellDropdown
ClearProgressionSpellButton
```

Do not replace them with empty placeholders.

## 4. Remove Progression actions/callbacks

Delete Admin page methods and event callbacks for progression mutation, including current equivalents of:

```text
AssignSelectedProgressionEntry
ToggleSelectedProgressionEntryLock
ClearSelectedProgressionSpell
```

Remove button enable/disable logic and pending-state branches that exist only for those operations.

## 5. Remove Progression refresh/population logic

Delete refresh code that:

- resolves the selected member's Progression rank/state;
- populates Progression entry dropdowns;
- populates Progression slot dropdowns;
- populates selected Progression spell options;
- matches progression state against the selected Guild Rank;
- enables/disables Progression mutation controls.

After cleanup, Admin refresh should only account for still-supported areas such as:

```text
Guild Rank
Achievements
Skills
Items
```

## 6. Preserve #49/#50 UI behavior

Do not regress the current Admin layout and roster behavior:

- roster remains `UI.Table`;
- columns remain Character / Guild Rank / Level / Class / Zone / Status;
- default rank sorting remains numeric WoW `rankIndex` ascending with name tie-break;
- Online/Offline colors remain;
- selected-row highlighting remains;
- roster/table remains vertically contained above Admin controls;
- no routine top instruction row is reintroduced;
- Guild Rank / Achievement / Skill / Item selectors remain hierarchical;
- lower controls remain layout-group based.

## 7. Preserve Admin security and mutations

Keep unchanged:

```text
officer capability detection
online-target requirement
member query/pending state
rank assignment eligibility
Set/Clear Guild Rank
Achievement grant
Skill adjustment
Item grant
mutation acknowledgements
refresh after mutation
normalized member identity handling
```

No schema change belongs in this task.

## Acceptance criteria

- [ ] Admin section selector contains only Achievements, Skills and Items.
- [ ] No Progression controls, layouts, dropdowns or buttons are created.
- [ ] No Progression-specific selected-member state remains.
- [ ] No Admin page helper/callback calls removed #52 progression runtime APIs.
- [ ] Member query state contains only still-supported Achievement/Skill data.
- [ ] Guild Rank controls still work.
- [ ] Achievement controls still work.
- [ ] Skill controls still work.
- [ ] Item controls still work.
- [ ] Roster `UI.Table`, sorting, selection, status colors and scrolling remain intact.
- [ ] Roster/Admin panel containment from #50 remains intact.
- [ ] No empty visual gap/section remains where Progression used to be.

## Validation matrix

```text
open Guild -> Admin as officer
-> roster begins at top
-> lower Admin controls visible
-> section selector shows Achievements / Skills / Items only

select online member
-> query completes
-> selected-member summary updates
-> no progression state access/error

switch Achievements / Skills / Items repeatedly
-> relevant controls shown
-> layout remains contained

Set Rank / Clear Rank
-> existing behavior unchanged

Grant Achievement
-> existing behavior unchanged

Adjust Skill
-> existing behavior unchanged

Give Item
-> existing behavior unchanged

long roster
-> table scrolls
-> no overlap with lower controls

non-officer / not in guild
-> existing compact access-state behavior remains
```

## Constraints

- Do not redesign the Admin page.
- Do not change `UI.Table`, dropdown infrastructure or layout prefabs unless a concrete regression requires a tiny generic fix.
- Do not modify Guild Admin protocol/runtime semantics beyond adapting to completed #52.
- Do not remove the Guild Progression tab/page here; #54 owns that.
- Do not edit the GuildSetting inspector here; #55 owns that.

## Coding-agent instructions
Use current `FrontierDev/rpe2` as authoritative. This task is intended for **5.6-Luna-ExtraHigh**. Read `.docs/RPE2-Remove-Guild-Progression-Implementation-Plan.md`, completed #52, and the current implementations resulting from #49/#50. Remove Progression-specific UI/state surgically while preserving the working roster and non-progression administration flow. Search the file after editing for `Progression`, `SelectedProgression`, progression mutation names, and stale profile-state fields. Report exact sections removed and validation performed.