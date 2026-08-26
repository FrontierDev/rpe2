# RPE 2 — Remove Guild Progression
## Implementation Plan

**Repository:** `FrontierDev/rpe2`  
**Target branch:** `main`  
**Scope:** Remove Guild Progression from the Guild window, Guild Admin, GuildSetting data model, profile persistence, dependency handling, and Guild Admin protocol payloads.  
**Do not remove:** unrelated class/race/stat/resource progression systems elsewhere in RPE 2.

---

# 1. Goal

Remove the **Guild Progression** feature completely from RPE 2.

This is not a UI-only change.

The current Guild Progression implementation exists across:

- the Guild window;
- Guild Admin;
- `GuildSetting` dataset definitions;
- GuildSetting editor controls;
- profile persistence;
- Guild runtime APIs;
- Guild Admin query/response payloads;
- Guild Admin progression mutations;
- dependency extraction/pruning;
- TOC registration;
- documentation/task instructions.

After this change, the Guild system should contain:

```text
Guild
├─ Requisitions
│  ├─ Daily Rewards
│  ├─ Guild Shop
│  └─ One-Time Requisitions
└─ Admin
   ├─ Guild Rank
   ├─ Achievements
   ├─ Skills
   └─ Items
```

There must be no player-facing or editor-facing Guild Progression feature remaining.

---

# 2. Important Scope Boundary

RPE 2 also uses the word **progression** for unrelated systems such as:

- race/class stat progression;
- resource progression;
- other generic character scaling definitions.

These systems are **not part of this task**.

Do not remove or modify generic structures such as:

```text
statProgressions
resourceProgressions
```

unless a line is explicitly part of the Guild Progression implementation.

This task concerns only Guild-specific progression concepts such as:

```text
GuildSetting.progression
general.enableProgression
GetActiveGuildProgression
profile.guild.byGuild[...].progression
assign_progression_entry
lock_progression_entry
unlock_progression_entry
clear_progression_spell
```

---

# 3. Current Guild Progression Surface

The current implementation includes the following major paths.

## Guild window

```text
client/character/guild/page_GuildProgression.lua
client/character/guild/window_Guild.lua
```

The Guild window currently exposes:

```text
Requisitions
Progression
Admin
```

## GuildSetting dataset model

```text
core/classes/GuildSetting.lua
```

Current GuildSetting progression state includes:

```lua
general = {
    enableRequisitions = false,
    enableDailyRewards = false,
    enableProgression = false,
}

progression = {
    slotCount = 3,
    entries = {},
}
```

Progression entries contain fields such as:

```text
id
name
description
icon
lockedText
spellRefs
```

## Guild profile state

```text
core/internal/profile/Guild.lua
```

The profile layer currently stores progression under Guild-specific profile state and provides APIs for:

```text
GetGuildProgression
SetGuildProgression
SetGuildProgressionSlot
SetGuildProgressionEntryUnlocked
SetGuildProgressionSelectedSpell
ClearGuildProgressionSelectedSpell
```

## Guild runtime

```text
client/client_Guild.lua
```

The runtime currently contains:

- active progression resolution;
- progression mutation helpers;
- local progression mutation APIs;
- progression state serialization in Guild Admin query responses;
- progression state parsing;
- remote progression mutation APIs;
- receiver-side progression mutation handling.

## Guild Admin UI

```text
client/character/guild/page_GuildAdmin.lua
```

The Admin page currently contains a Progression section with controls for:

- assigning entries to slots;
- locking/unlocking entries;
- clearing selected spells.

## GuildSetting editor

```text
client/ui/editor/inspectors/page_InspectorGuildSetting.lua
```

The GuildSetting inspector currently exposes a Progression page and Progression authoring controls.

## Dependencies

```text
core/internal/database/Dependecies.lua
```

GuildSetting dependency analysis currently inspects progression spell references.

## TOC

```text
RPEngine_Dev.toc
```

The Guild Progression page is explicitly loaded.

---

# 4. Implementation Strategy

Remove Guild Progression from the lowest layers upward.

Recommended order:

```text
1. GuildSetting data model
2. Profile Guild progression persistence APIs
3. Dependency handling
4. Guild runtime progression APIs/protocol payloads
5. Guild Admin progression controls
6. Guild window Progression tab
7. TOC entry
8. Documentation/task references
9. Static validation
```

This order minimizes the chance that later code continues depending on removed data structures.

---

# 5. Phase 1 — Remove Progression from GuildSetting

## File

```text
core/classes/GuildSetting.lua
```

## Remove from `general`

Delete:

```lua
enableProgression
```

The normalized general structure should become:

```lua
general = {
    enableRequisitions = ...,
    enableDailyRewards = ...,
}
```

## Remove progression normalization helpers

Delete Guild-specific progression helpers including equivalents of:

```text
normalizeSpellRefs
normalizeProgressionEntry
normalizeProgressionEntries
normalizeProgression
```

Only remove these if they exist solely for `GuildSetting.progression`.

Do not remove similarly named generic helpers used by unrelated classes.

## Remove default progression data

Delete:

```lua
progression = {
    slotCount = 3,
    entries = {},
}
```

from `GuildSetting:New()`.

## Remove progression merge normalization

Delete:

```lua
self.progression = normalizeProgression(self.progression)
```

## Remove progression serialization

Delete:

```lua
progression = normalizeProgression(self.progression)
```

from `GuildSetting:ToTable()`.

## Result

A GuildSetting should now contain only Guild Rank metadata and active Guild features such as:

```lua
{
    id = ...,
    name = ...,
    description = ...,
    guildName = ...,
    wowGuildRankIndices = ...,

    general = {
        enableRequisitions = ...,
        enableDailyRewards = ...,
    },

    requisitions = ...,
    dailyRewards = ...,
    tags = ...,
}
```

---

# 6. Phase 2 — Remove Guild Progression Profile APIs

## File

```text
core/internal/profile/Guild.lua
```

Remove all Guild Progression-specific normalization, read and mutation code.

## Remove helpers

Delete Guild-specific progression helpers such as:

```text
normalizeProgressionEntryId
normalizeProgressionState
getGuildProgressionState
updateGuildProgressionState
```

## Remove public profile APIs

Delete:

```lua
Profile.GetGuildProgression(...)
Profile.SetGuildProgression(...)
Profile.SetGuildProgressionSlot(...)
Profile.SetGuildProgressionEntryUnlocked(...)
Profile.SetGuildProgressionSelectedSpell(...)
Profile.ClearGuildProgressionSelectedSpell(...)
```

Remove any other aliases or wrappers that exist only for Guild Progression.

## Do not alter remaining Guild profile state

Preserve:

```text
assignedRankRef
assignedRankAt
assignedRankBy
requisition usage
daily reward state
daily reward transaction state
guild identity migration
```

## Legacy saved state

Do **not** add migration code whose only purpose is to actively delete:

```lua
profile.guild.byGuild[guildKey].progression
```

Existing SavedVariables may retain stale progression fields.

That data is acceptable as inert legacy state as long as:

- no runtime code reads it;
- no runtime code writes it;
- new normalised state does not depend on it;
- no UI exposes it.

Avoid keeping permanent cleanup code for a removed feature.

---

# 7. Phase 3 — Remove Guild Progression Dependency Handling

## File

```text
core/internal/database/Dependecies.lua
```

GuildSetting dependency analysis currently extracts spell references from:

```text
GuildSetting.progression.entries[*].spellRefs
```

Remove this GuildSetting-specific extraction.

## Remove dependency discovery

Inside GuildSetting source-reference extraction, remove traversal of:

```lua
guildSetting.progression
progression.entries
entry.spellRefs
```

## Remove dependency rewrite/pruning

Remove corresponding mutation/pruning logic which walks progression entries and rewrites/removes progression `spellRefs`.

## Preserve unrelated progression handling

Do not touch generic dependency logic for:

```text
statProgressions
resourceProgressions
```

or other non-Guild progression concepts.

---

# 8. Phase 4 — Remove Guild Runtime Progression Logic

## File

```text
client/client_Guild.lua
```

This is the largest runtime cleanup.

## 8.1 Remove progression normalization helpers

Remove Guild Progression-only helpers such as:

```text
normalizeProgressionSlotCount
getProgressionEntryMap
isConfiguredSpell
```

only where they are exclusive to Guild Progression.

## 8.2 Remove active progression resolution

Delete:

```lua
Guild:GetActiveGuildProgression()
```

and the helper used to build it.

Remove logic that checks:

```lua
general.enableProgression
```

Remove statuses such as:

```text
progression-disabled
progression-unavailable
no-active-progression
```

where they are only used by Guild Progression.

## 8.3 Remove local progression mutations

Delete APIs including:

```lua
Guild:AssignProgressionEntryToSlot(...)
Guild:SetProgressionEntryUnlocked(...)
Guild:SelectProgressionSpell(...)
Guild:ClearProgressionSpell(...)
```

and aliases such as:

```text
SetProgressionSlot
UnlockProgressionEntry
LockProgressionEntry
SelectGuildProgressionSpell
ClearGuildProgressionSpell
```

---

# 9. Phase 5 — Simplify Guild Admin Query Payloads

## File

```text
client/client_Guild.lua
```

Guild Admin member queries currently return:

```text
Achievements
Skills
Progression
```

Change the payload to return only:

```text
Achievements
Skills
```

## Remove progression response serialization

Delete helpers equivalent to:

```text
appendQueryProgressionStateArguments
getProgressionQuerySnapshot
```

Update:

```text
buildQueryResponseArguments
```

so it does not append progression state.

## Remove progression response parsing

Change the parsed profile state from:

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

Remove parsing of:

```text
progressionActive
rankRef
slotCount
slots
unlocked
selectedSpells
```

## Protocol compatibility

Keep the existing Guild Admin opcodes:

```text
GUILD_ADMIN_QUERY
GUILD_ADMIN_QUERY_RESPONSE
GUILD_ADMIN_MUTATION
GUILD_ADMIN_MUTATION_RESPONSE
```

They are still required for:

- Guild Rank assignment;
- Achievement grants;
- Skill adjustments;
- Item grants.

Do not delete or renumber these opcodes merely because progression is removed.

### Protocol version

Because the query payload shape changes, inspect whether `GUILD_ADMIN_PROTOCOL_VERSION` should be incremented.

Preferred behavior:

- if current clients assume progression fields exist at fixed positions, increment the protocol version;
- old/new clients should fail clearly as incompatible rather than silently misparse payloads.

Do not preserve dead progression fields merely to avoid changing the protocol if doing so leaves Progression concepts embedded in the transport layer.

---

# 10. Phase 6 — Remove Guild Admin Progression Mutations

## File

```text
client/client_Guild.lua
```

Remove client-side mutation request APIs such as:

```text
AssignProgressionEntryForMember
SetProgressionEntryLockForMember
ClearProgressionSpellForMember
```

and any related helpers.

Remove all mutation operation strings:

```text
assign_progression_entry
lock_progression_entry
unlock_progression_entry
clear_progression_spell
```

Remove receiver-side branches that dispatch those operations.

Remove Guild Progression-specific validation errors such as:

```text
invalid-progression-slot
unknown-progression-entry
progression-entry-locked
invalid-progression-spell
no-active-progression
```

if they are no longer referenced anywhere.

Preserve Guild Admin mutation handling for:

```text
set_guild_rank
grant_achievement
adjust_skill
give_item
```

and any other non-progression operation currently supported.

---

# 11. Phase 7 — Remove Progression from Guild Admin UI

## File

```text
client/character/guild/page_GuildAdmin.lua
```

Remove the Progression administration section entirely.

## 11.1 Remove progression state helpers

Delete Guild Admin helpers such as:

```text
getSelectedProgressionState
getSelectedProgressionRank
getSelectedProgressionEntry
getSelectedProgressionSpell
ensureSelectedProgressionState
```

## 11.2 Remove selected progression fields

Delete instance state such as:

```lua
self.SelectedProgressionEntryId
self.SelectedProgressionSlot
self.SelectedProgressionSpellRef
```

Change profile state defaults from:

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

Apply this consistently anywhere the Admin page resets member state.

## 11.3 Remove Progression layout

Delete:

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

Remove:

```lua
Progression = ...
```

from `AdminSectionVisibleHeights`.

## 11.4 Remove Progression section button

Change:

```lua
local plannedSections = {
    "Achievements",
    "Skills",
    "Items",
    "Progression",
}
```

to:

```lua
local plannedSections = {
    "Achievements",
    "Skills",
    "Items",
}
```

## 11.5 Remove progression action methods

Delete:

```text
AssignSelectedProgressionEntry
ToggleSelectedProgressionEntryLock
ClearSelectedProgressionSpell
```

and any other progression-specific callbacks.

## 11.6 Remove progression refresh logic

Delete Admin refresh code that:

- resolves the selected member's progression rank;
- populates progression entry dropdowns;
- populates progression slot dropdowns;
- populates selected progression spell fields;
- checks whether progression state matches the selected Guild Rank;
- enables/disables progression controls.

## Preserve Admin behavior

Do not regress:

- guild roster;
- officer access validation;
- selected member query;
- Guild Rank assignment;
- Achievement grant;
- Skill increase/decrease;
- Item grant;
- pending state;
- acknowledgements;
- online target requirement;
- hierarchical selectors;
- table sorting/scrolling/layout.

---

# 12. Phase 8 — Remove Guild Progression Page

## Delete file

```text
client/character/guild/page_GuildProgression.lua
```

The page should be deleted rather than left unused.

---

# 13. Phase 9 — Simplify Guild Window

## File

```text
client/character/guild/window_Guild.lua
```

Remove:

```lua
progressionPage = GuildUI.ProgressionPage
```

from the Guild window instance.

Remove the progression branch from:

```lua
GuildWindow:RefreshTab(...)
```

Delete the `Progression` tab definition.

Final tabs:

```text
Requisitions
Admin
```

The active-tab fallback should remain:

```text
requisitions
```

Check all tab index/name assumptions after removing the middle tab.

Do not leave any hard-coded numeric assumptions that expect Admin to be tab 3.

---

# 14. Phase 10 — Remove Progression from GuildSetting Editor

## File

```text
client/ui/editor/inspectors/page_InspectorGuildSetting.lua
```

## Remove page definition

Change:

```lua
INSPECTOR_PAGE_DEFINITIONS = {
    General,
    Requisitions,
    Daily Rewards,
    Progression,
}
```

to:

```lua
INSPECTOR_PAGE_DEFINITIONS = {
    General,
    Requisitions,
    Daily Rewards,
}
```

## Remove Enable Progression control

Delete the checkbox/control which edits:

```lua
general.enableProgression
```

## Remove Progression authoring UI

Delete controls for:

```text
slotCount
progression entry ID
name
description
icon
lockedText
spellRefs
add/remove progression entries
progression entry selection
```

Remove related refresh, validation, dropdown and mutation helpers.

## Preserve editor pages

The remaining GuildSetting editor must continue to support:

```text
General
Requisitions
Daily Rewards
```

including current Guild Rank mappings and feature toggles.

---

# 15. Phase 11 — Update TOC

## File

```text
RPEngine_Dev.toc
```

Remove:

```text
client/character/guild/page_GuildProgression.lua
```

Keep:

```text
client/client_Guild.lua
client/character/guild/page_GuildRequisitions.lua
client/character/guild/page_GuildAdmin.lua
client/character/guild/window_Guild.lua
```

---

# 16. Phase 12 — Documentation Cleanup

Search documentation for Guild Progression references.

At minimum inspect:

```text
.docs/RPE2-Achievements-Guild-Systems-PDD.md
.docs/RPE2-Final-Guild-Requisitions-Page-Implementation-Plan.md
TASK.MD
```

## PDD

Remove Guild Progression as an intended feature.

Remove sections describing:

- progression definition;
- progression profile state;
- progression UI;
- progression administration;
- progression acceptance criteria;
- progression spell dependencies.

Do not remove unrelated Achievement or Guild Rank/requisition content.

## TASK.MD

The current task text explicitly says Progression controls and mutations should remain intact.

Remove/update that requirement so future coding agents are not instructed to restore the feature.

## Requisitions implementation plan

Only change it if it contains statements that require Progression to exist or relies on three Guild tabs.

Do not unnecessarily rewrite unrelated requisition design work.

---

# 17. Search-Based Cleanup Pass

After the primary edits, search the repository for Guild Progression identifiers.

Search for at least:

```text
enableProgression
GuildProgression
ProgressionPage
GetActiveGuildProgression
GetGuildProgression
SetGuildProgression
progression-entry
assign_progression_entry
lock_progression_entry
unlock_progression_entry
clear_progression_spell
SelectedProgression
RPEGuildProgression
GuildSetting.progression
```

Every remaining match must be inspected.

Allowed remaining matches:

- historical documentation intentionally retained;
- unrelated generic class/race/stat/resource progression code;
- changelog/history text if deliberately preserved.

No active Guild code should retain Guild Progression behavior.

---

# 18. Static Validation

Perform at least the following checks.

## Guild window

```text
Open Guild window
-> only Requisitions and Admin tabs exist
-> Requisitions opens normally
-> Admin opens normally
-> tab switching has no Lua errors
```

## Guild Admin

```text
Select online member
-> member query succeeds
-> Guild Rank state loads
-> Achievement state loads
-> Skill state loads
-> no progression parsing is attempted
```

## Guild Admin mutations

Verify:

```text
Guild Rank assignment
Achievement grant
Skill increase
Skill decrease
Item grant
```

continue to send, validate, acknowledge, and refresh correctly.

## GuildSetting editor

```text
Open GuildSetting
-> General page works
-> Requisitions page works
-> Daily Rewards page works
-> no Progression page appears
-> no Enable Progression toggle appears
```

## Dataset serialization

Create/export/reload a GuildSetting and verify newly serialized data contains no:

```text
enableProgression
progression
slotCount
lockedText
progression spellRefs
```

## Profile behavior

Existing profiles containing legacy:

```lua
profile.guild.byGuild[...].progression
```

must still load without error.

No code should read or mutate that legacy field.

## Dependencies

A GuildSetting referencing requisition items, currencies or daily rewards must still generate the appropriate dataset dependencies.

Removed progression spell references must no longer contribute dependencies.

---

# 19. Acceptance Criteria

The implementation is complete when all of the following are true.

- [ ] The Guild window has only `Requisitions` and `Admin`.
- [ ] `page_GuildProgression.lua` is deleted.
- [ ] `RPEngine_Dev.toc` no longer loads the Progression page.
- [ ] Guild Admin has no Progression section.
- [ ] Guild Admin query payloads contain no progression state.
- [ ] Guild Admin mutation handling contains no progression operations.
- [ ] `client_Guild.lua` exposes no Guild Progression runtime API.
- [ ] `core/internal/profile/Guild.lua` exposes no Guild Progression persistence API.
- [ ] `GuildSetting` contains no `enableProgression`.
- [ ] `GuildSetting` contains no `progression` definition.
- [ ] GuildSetting editor contains no Progression page or controls.
- [ ] GuildSetting dependencies no longer inspect progression spell refs.
- [ ] Requisitions remain functional.
- [ ] Daily Rewards remain functional.
- [ ] Guild Rank assignment remains functional.
- [ ] Achievement administration remains functional.
- [ ] Skill administration remains functional.
- [ ] Item administration remains functional.
- [ ] Existing profiles with stale progression data still load safely.
- [ ] Unrelated class/race/stat/resource progression systems remain unchanged.
- [ ] Repository search finds no active Guild Progression implementation.

---

# 20. Non-Goals

Do not:

```text
remove generic class/race/stat progression systems;
remove Guild Rank assignments;
remove Achievements;
remove Skills administration;
remove Item administration;
remove Requisitions;
remove Daily Rewards;
remove Guild Admin communications wholesale;
renumber Guild Admin opcodes unnecessarily;
add a permanent migration framework solely to erase old progression SavedVariables;
redesign the Guild window beyond removing Progression.
```

---

# 21. Expected Files Changed

Primary files:

```text
core/classes/GuildSetting.lua
core/internal/profile/Guild.lua
core/internal/database/Dependecies.lua
client/client_Guild.lua
client/character/guild/page_GuildAdmin.lua
client/character/guild/window_Guild.lua
client/ui/editor/inspectors/page_InspectorGuildSetting.lua
RPEngine_Dev.toc
TASK.MD
.docs/RPE2-Achievements-Guild-Systems-PDD.md
```

Deleted:

```text
client/character/guild/page_GuildProgression.lua
```

Potential additional files should only be modified where repository search finds an active Guild Progression dependency.

---

# 22. Coding-Agent Instructions

Use the current `FrontierDev/rpe2` repository as authoritative.

Before editing:

1. inspect all files listed above;
2. search the repository for Guild Progression identifiers;
3. distinguish Guild Progression from generic character progression systems.

Implement the removal as a coherent vertical cleanup rather than hiding controls.

Preserve all non-progression Guild functionality.

After editing:

1. search again for Guild Progression references;
2. inspect every remaining match;
3. validate Guild window construction;
4. validate Guild Admin query parsing and mutation dispatch;
5. validate GuildSetting normalization/serialization;
6. validate dependency extraction;
7. report exact files modified/deleted and any protocol version change made.
