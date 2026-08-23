# RPE 2 — Phase 1 Implementation Plan for Codex

**Target model:** GPT-5.4-Luna, Extra High reasoning  
**Repository:** `FrontierDev/rpe2`  
**Phase:** 1 — UI and Data Layer  
**Source of truth:** current RPE 2 repository and the approved Achievements/Guild Systems PDD. Do not use the predecessor `rpengine` repository.

---

## 0. Execution Rules for Codex

Work through the tasks below in order. Treat each numbered task as a bounded implementation unit. Before editing a task, inspect the named files and adjacent patterns in the current repository. Prefer existing RPE 2 abstractions over new frameworks.

For every task:

1. Inspect the relevant current implementation before changing it.
2. Make the smallest coherent change that satisfies the task.
3. Do not refactor unrelated systems.
4. Preserve the existing `Addon.Internal`, `Addon.Client`, `Addon.UI`, Database, Registry, Profile and Data Editor conventions.
5. Use dataset-qualified references (`datasetId:entryId`) for references to dataset objects.
6. Use RPE UI elements/layouts; do not introduce standalone Blizzard-style UI frameworks where RPE already has an abstraction.
7. Do not create independent event frames for Guild features; extend the existing Runtime dispatch model.
8. Add every new Lua file to `RPEngine_Dev.toc` in dependency-safe load order.
9. Keep imported/exported datasets backward compatible where possible.
10. After each task, report: files changed, behavior added, validation performed, and any unresolved concern.

### Hard Phase 1 boundary

Do **not** implement any of the following in this phase:

- requisition purchases or currency deductions;
- daily reward claiming or automatic login awards;
- automatic Achievement progression/triggers;
- kill/currency/event Achievement hooks;
- Achievement Guild/Raid announcements;
- new Guild Admin comms opcodes;
- remote Profile mutation;
- officer granting of Achievements/items/skills;
- progression unlocking, requirements, rewards or automatic evaluation.

Phase 1 may display/configure the data required by those systems, but it must not execute their gameplay behavior.

---

# Task 1 — Normalize the Existing Achievement Data Model

## Goal

Turn the existing `Achievement` class from a permissive container into a stable Phase 1 definition format suitable for later progression logic, while preserving its existing top-level fields.

## Primary file

- `core/classes/Achievement.lua`

## Required changes

Keep the existing top-level fields:

```lua
id
name
description
icon
criteria
rewards
tags
```

Normalize `name`, `description`, `icon`, `criteria`, `rewards` and `tags` during `Merge()` / `ToTable()`.

Define the Phase 1 criterion shape as:

```lua
{
    id = "stable_criterion_id",
    description = "",
    trigger = "manual",
    goal = 1,
    filters = {},
}
```

Supported trigger tokens in Phase 1 data:

```text
manual
currency_gain
rpe_kill
rpe_event_complete
achievement_earned
```

Behavior is not implemented yet; these are authoring/storage tokens only.

### Criterion normalization requirements

- `id` must be non-empty and stable once authored.
- Missing criterion IDs from older/imported data should receive a deterministic fallback such as `criterion_1`, `criterion_2`, etc.
- Duplicate IDs within one Achievement must be disambiguated deterministically.
- `goal` must normalize to an integer >= 1.
- Unknown/invalid trigger tokens should normalize to `manual` rather than causing an error.
- `filters` must normalize to a table and preserve unknown keys so future filter types can be added without data loss.
- Preserve `rewards` as data, but do not invent reward execution semantics in Phase 1.
- Normalize tags to a clean string list.

## Do not

- add player progress/completion fields to the Achievement definition;
- add `Completed`, `Progress`, `Unlocked`, etc. to dataset data;
- implement trigger handling;
- copy CrusadeToolkit's top-level `single/counter/checklist/meta` state model.

## Acceptance checks

- Creating a new Achievement produces a valid normalized object.
- `FromTable(ToTable(x))` is stable.
- Legacy criteria without IDs receive stable fallback IDs.
- Criterion goals cannot remain zero/negative/non-numeric.
- Unknown filter keys survive round-trip serialization.

---

# Task 2 — Add the `GuildSetting` Dataset Class

## Goal

Create the new dataset class and normalize all Phase 1 Guild configuration structures without implementing gameplay behavior.

## Primary files

- new: `core/classes/GuildSetting.lua`
- `RPEngine_Dev.toc`

## Required top-level structure

```lua
GuildSetting {
    id = nil,
    name = "",
    description = "",
    guildName = "",

    general = {
        enableRequisitions = false,
        enableDailyRewards = false,
        enableProgression = false,
    },

    requisitions = {},
    dailyRewards = {},

    progression = {
        slotCount = 3,
        entries = {},
    },

    tags = {},
}
```

### Requisition definition

```lua
{
    id = "stable_id",
    itemRef = "dataset:item",
    quantity = 1,
    costs = {
        {
            currencyRef = "copper", -- or dataset:currency
            amount = 1,
        },
    },
    requiredGuildRankIndex = nil,
    characterLimit = 1,
}
```

Normalize:

- stable non-empty requisition ID;
- item reference string;
- quantity >= 1;
- each cost amount >= 0;
- optional guild rank index as a non-negative integer or nil;
- `characterLimit` >= 1, default 1.

### Daily reward definition

```lua
{
    id = "stable_id",
    type = "item", -- item | currency
    ref = "dataset:item-or-currency",
    amount = 1,
}
```

Normalize:

- stable ID;
- type to `item` or `currency`;
- reference string;
- amount >= 1.

### Progression definition

Phase 1 stores the generalized CrusadeToolkit-style progression configuration only:

```lua
progression = {
    slotCount = 3,
    entries = {
        {
            id = "aspirant",
            name = "Aspirant",
            description = "",
            icon = "",
            lockedText = "",
            spellRefs = {},
        },
    },
}
```

Normalize stable entry IDs, strings and unique non-empty spell refs. Do not implement requirements, unlocking or rewards in Phase 1.

## Do not

- put character-specific claim/progression state in `GuildSetting`;
- add runtime purchase/reward logic;
- add Holy Order-specific terms to core defaults;
- hard-code guild rank names.

## Acceptance checks

- `GuildSetting:New()` returns a complete safe default.
- `FromTable(ToTable(x))` preserves normalized data.
- Missing nested tables never cause errors.
- Nested entry IDs are stable and duplicate-safe.
- New file loads before any UI attempts to create a GuildSetting entry.

---

# Task 3 — Integrate GuildSettings and New Profile Fields into `Database.lua`

## Goal

Make GuildSettings first-class dataset entries and add persistent Achievement/Guild character state using the existing centralized Database normalization model.

## Primary file

- `core/internal/database/Database.lua`

## Schema changes

Increment:

```text
profiles: 4 -> 5
datasets: 14 -> 15
```

Do not change unrelated schema versions.

## Dataset integration

Add:

```lua
guildSettings = { className = "GuildSetting", singular = "Guild Setting", assignsId = true }
```

to `DATASET_ENTRY_DEFINITIONS`.

Add `guildSettings = ensureTable(data.guildSettings)` to normalized dataset records.

Ensure the existing generic dataset entry create/import/export/update/delete paths accept `guildSettings` in exactly the same manner as other collections.

## Profile integration

Add normalized Profile fields:

```lua
achievements = {}
guild = {}
```

Both must be present in:

- `normalizeProfileRecord(...)`;
- `GetOrCreateActiveProfile()` defaults;
- any default/empty-profile comparison or migration logic that enumerates profile fields.

### Achievement state shape

Normalize to:

```lua
profile.achievements = {
    [achievementRef] = {
        criteria = {
            [criterionId] = 0,
        },
        completedAt = nil,
    },
}
```

Rules:

- achievement keys must be non-empty strings;
- criterion keys must be non-empty strings;
- criterion progress is integer >= 0;
- `completedAt` is nil or a non-negative timestamp-like number.

### Guild state shape

Phase 1 should normalize the outer storage safely without implementing business logic:

```lua
profile.guild = {
    byGuild = {},
}
```

Preserve nested Guild state tables rather than discarding unknown future Phase 2/4 fields.

## Database accessors

Add thin persistence helpers consistent with existing Profile Database accessors, for example:

```lua
Database.ListProfileAchievementStates()
Database.GetProfileAchievementState(achievementRef)
Database.SetProfileAchievementState(achievementRef, state)
Database.ClearProfileAchievementState(achievementRef)

Database.GetProfileGuildState()
Database.SetProfileGuildState(state)
```

Return copies where current Database patterns return copies. Mutators must call the existing configuration-change notification path.

Do not add Achievement completion semantics here.

## Acceptance checks

- Existing schema-4 Profiles load and become valid schema-5 Profiles without data loss.
- Existing schema-14 Datasets load and gain an empty `guildSettings` collection.
- GuildSetting entries can be created by the generic Database entry API.
- Dataset export/import includes GuildSettings.
- Achievement and Guild Profile state survive `/reload`.
- Existing Profile behavior is unchanged.

---

# Task 4 — Add Thin Profile-State Modules for Achievements and Guild Data

## Goal

Expose the new Database state through `Addon.Internal.Profile` without implementing Phase 2/3 behavior.

## Primary files

- new: `core/internal/profile/Achievements.lua`
- new: `core/internal/profile/Guild.lua`
- `RPEngine_Dev.toc`

## Load order

Load both after `Database.lua` and before UI/client modules that consume them. Follow the same namespace-extension pattern used by `core/internal/profile/Currencies.lua`.

## Achievement Profile API

Provide thin wrappers such as:

```lua
Profile.ListAchievementStates()
Profile.GetAchievementState(achievementRef)
Profile.SetAchievementState(achievementRef, state)
Profile.ClearAchievementState(achievementRef)
```

These are persistence primitives only.

## Guild Profile API

Provide:

```lua
Profile.GetGuildState()
Profile.SetGuildState(state)
```

Optionally expose narrowly scoped helper access to `byGuild` if it improves UI readability, but do not implement claims, limits, progression evaluation or mutations specific to later phases.

## Do not

- add `GrantAchievement`;
- add `TryRequisition`;
- add `ClaimDailyReward`;
- add progression unlock methods.

Those belong to later phases.

## Acceptance checks

- APIs behave safely when no Profile existed before the call.
- Returned state cannot accidentally mutate SavedVariables if existing Profile conventions return copies.
- Set/Clear operations persist and notify configuration changes.

---

# Task 5 — Extend Registry and Dataset Dependency Analysis

## Goal

Make Achievement and GuildSetting references participate correctly in the existing dataset reference/dependency system.

## Primary files

- `core/internal/Registry.lua`
- `core/internal/database/Dependecies.lua`

## Registry additions

Add resolvers matching existing Item/Skill/etc. conventions:

```lua
Registry:ResolveAchievementReference(achievementRef)
Registry:ResolveAchievementName(achievementRef)
Registry:ResolveGuildSettingReference(guildSettingRef)
```

Use the existing dataset-qualified reference parsing and entry-cache path; do not create a second resolver mechanism.

## Dependency extraction — Achievement

Inspect criterion filters and collect dataset-qualified references from known fields including:

```text
currencyRef
unitRef
achievementRef
```

Do not assume every arbitrary string filter value is a reference.

## Dependency extraction — GuildSetting

Collect references from:

```text
requisitions[].itemRef
requisitions[].costs[].currencyRef
dailyRewards[].ref
progression.entries[].spellRefs[]
```

For daily rewards, `ref` is a dependency only when it is dataset-qualified; built-in currencies such as `copper` must not create a dataset dependency.

## Deletion/rewrite handling

Inspect all existing dependency recalculation, source deletion and reference-pruning/rewrite paths in `Dependecies.lua`. Extend the relevant paths so Achievement/GuildSetting references are not left as a blind spot when referenced datasets are removed or dependencies are recomputed.

Do not broadly rewrite arbitrary strings.

## Acceptance checks

Create two test datasets conceptually:

```text
Dataset A: defines item/currency/spell/achievement
Dataset B: GuildSetting/Achievement references A
```

Verify:

- B detects A as a dependency;
- same-dataset refs do not create self-dependencies;
- built-in `copper` does not create a dependency;
- reference deletion/recompute behavior is consistent with existing Item/Spell/etc. behavior.

---

# Task 6 — Finish Achievement Authoring in the Data Editor

## Goal

Replace the current Achievement placeholder with a usable editor and add the missing Achievement inspector.

## Primary files

- `client/ui/editor/pages/page_Achievement.lua`
- new: `client/ui/editor/inspectors/page_InspectorAchievement.lua`
- Data Editor core/mapping file(s) containing `ENTRY_DEFINITIONS`, inspector mappings and page refresh mappings
- `RPEngine_Dev.toc`

## Existing integration to preserve

Achievements are already present in generic Data Editor entry definitions and content pages. Do not create a separate Achievement editor window. Complete the existing collection.

## Achievement page

Replace the placeholder text/grid stub with a real selectable list or icon list using existing RPE Data Editor patterns.

Each entry should show at minimum:

- icon;
- name;
- ID or secondary detail;
- useful selection state.

Support the normal generic actions:

- create;
- select;
- delete;
- copy/export/import if those actions are supplied by the shared toolbar/context patterns.

## Inspector integration

Add `achievements -> achievement` to all relevant inspector maps/getters/refreshers and ensure selection navigates to the Achievement inspector.

## Inspector fields

### General

- Name
- Description
- Icon
- Tags

### Criteria

Provide an editable collection supporting:

- Add Criterion
- Delete Criterion
- stable Criterion ID
- Description
- Trigger dropdown
- Goal
- trigger-specific basic filters

Required Phase 1 filter UI:

- `currency_gain`: `currencyRef`
- `rpe_kill`: optional `unitRef`, optional `enemyOnly` boolean
- `achievement_earned`: `achievementRef`
- `manual`: no required filter
- `rpe_event_complete`: no required filter in Phase 1

Use existing RPE dropdown/reference-picker conventions where possible. If no reusable reference picker exists for a type, use a validated text/reference field rather than building a large new picker framework.

### Rewards

Preserve the existing `rewards` field and round-trip it, but **do not invent reward semantics** in Phase 1. Detailed reward editing may remain absent until the reward schema is explicitly designed.

## Acceptance checks

- New Achievement can be authored entirely through the Data Editor.
- Criteria can be added/removed without changing IDs of unaffected criteria.
- Switching trigger type does not corrupt unrelated data.
- Selection/refresh behaves like other Data Editor collections.
- Export/import preserves the authored Achievement.

---

# Task 7 — Add GuildSetting Authoring to the Data Editor

## Goal

Make `guildSettings` a fully usable Data Editor collection and expose all Phase 1 configuration required for later phases.

## Primary files

- new: `client/ui/editor/pages/page_GuildSetting.lua`
- new: `client/ui/editor/inspectors/page_InspectorGuildSetting.lua`
- Data Editor core/mapping file(s)
- `client/ui/editor/pages/page_Datasets.lua` if its dataset-entry count is explicitly enumerated there
- `RPEngine_Dev.toc`

## Data Editor integration

Add GuildSettings to every explicit collection mapping required by the existing editor, including:

- entry definition;
- content page definition;
- page builder/refresh mapping;
- inspector mapping;
- inspector selection getter;
- create/select branch if explicitly enumerated;
- dataset content count/status if explicitly enumerated.

Search for explicit per-collection `elseif`/mapping tables and update all relevant ones. Do not assume adding one mapping is sufficient.

## GuildSetting page

Use the same list/page structure as other dataset collections. Show name and guild binding clearly.

## GuildSetting inspector

### General

- Name
- Description
- Guild Name
- Enable Requisitions
- Enable Daily Rewards
- Enable Progression
- Tags

### Requisitions

Editable list of definitions:

- ID
- Item Ref
- Quantity
- Minimum Guild Rank Index
- Character Limit
- Costs list
  - Currency Ref
  - Amount

The editor may display a resolved item/currency name alongside the raw ref when available.

### Daily Rewards

Editable ordered list:

- ID
- Type (`item` / `currency`)
- Ref
- Amount

### Progression

Structural editor only:

- Slot Count
- Progression entries
  - ID
  - Name
  - Description
  - Icon
  - Locked Text
  - Spell Ref list

Do not implement requirement/unlock/reward configuration in Phase 1.

## Acceptance checks

- GuildSetting can be created, edited, deleted, exported and imported.
- Nested lists retain stable IDs.
- Feature flags persist.
- Cross-dataset refs appear in dependency analysis.
- No purchase/reward/progression behavior occurs from editing or activating the dataset.

---

# Task 8 — Add the Character Profile Achievements Tab

## Goal

Add a read-only, character-facing Achievement view to the existing Profile window using active dataset definitions plus Profile state.

## Primary files

- new: `client/character/profile/page_ProfileAchievements.lua`
- `client/character/profile/window_Profile.lua`
- `RPEngine_Dev.toc`

## Window integration

Add an `Achievements` tab to the existing Profile `UI.Window` tabs list and add it to `RefreshTab()` / instance state exactly like existing Equipment, Spellbook, Traits and Skills pages.

Do not create a second Profile window.

## Data source

Definitions:

```lua
Registry:GetActivatedDatasets()
```

Progress:

```lua
Profile.ListAchievementStates()
```

Compose the qualified ref as:

```text
datasetId:achievementId
```

## UI behavior

Display all Achievements from activated datasets.

Recommended structure:

- left navigation/filter pane;
- `All` category;
- unique Achievement tags as optional dynamic filters;
- scrollable Achievement entries.

Each Achievement entry should display:

- icon;
- name;
- description;
- completed/incomplete appearance;
- completion date when `completedAt` exists;
- criterion progress when criteria exist.

For criterion progress:

```text
current = profile state for criterion ID, default 0
goal = criterion.goal
```

An Achievement is visually complete when `completedAt` exists. Phase 1 does not calculate or set completion automatically.

## Empty/error states

Handle:

- no active datasets;
- active datasets with no Achievements;
- Achievement definition exists but no Profile state;
- Profile state exists for a currently inactive/missing Achievement without throwing errors.

## Acceptance checks

- Tab opens and refreshes on show.
- Newly activated dataset Achievements appear.
- Manually seeded Profile state displays correct progress/completion.
- No automatic progress is generated by viewing the page.

---

# Task 9 — Add the Guild Runtime Facade and Guild Window Shell

## Goal

Create the Guild-facing UI and local read-only guild context required by later phases, without implementing any transactions or remote mutations.

## Primary files

- new: `client/client_Guild.lua`
- new: `client/character/guild/window_Guild.lua`
- new: `client/character/guild/page_GuildRequisitions.lua`
- new: `client/character/guild/page_GuildProgression.lua`
- new: `client/character/guild/page_GuildAdmin.lua`
- `core/internal/Runtime.lua`
- `client/ui/windows/window_LauncherMenu.lua`
- `client/client_Commands.lua`
- `RPEngine_Dev.toc`

## `client_Guild.lua` responsibilities

Provide a narrow local facade for:

```text
current guild identity/name
active GuildSetting resolution
GuildSetting conflict detection
local officer-state query
guild roster readout
Guild window refresh routing
```

Do not put Profile state or transaction logic here yet.

### Active GuildSetting resolution

Search `Registry:GetActivatedDatasets()`.

Resolution rules:

1. Player must be in a guild.
2. Exact `guildName` matches take priority.
3. If no exact match exists, an empty `guildName` may act as a generic match.
4. More than one equally valid match is a conflict.
5. On conflict, return no active setting plus enough information for the UI to explain the conflict.

Do not silently choose the first dataset.

### Officer state

Centralize the officer check in one helper such as:

```lua
Client.Guild:IsLocalPlayerOfficer()
```

Use the appropriate WoW guild permission/rank APIs available to the target interface. Do not scatter rank checks through the UI and do not hard-code `rankIndex == 0 or 1` unless the API contract genuinely requires it.

## Runtime integration

The addon already centralizes events in `core/internal/Runtime.lua`. Extend that model for guild state/roster updates rather than creating a new event frame.

Register/route the appropriate guild lifecycle events, including the current-interface equivalents of:

```text
PLAYER_GUILD_UPDATE
GUILD_ROSTER_UPDATE
```

Route them to a Guild handler that refreshes the Guild window if it exists/is visible.

Do not implement daily reward processing yet.

## Guild window

Create a top-level RPE `UI.Window` titled `Guild` with tabs:

```text
Requisitions
Progression
Admin
```

### Requisitions tab — Phase 1 display only

Render the active GuildSetting's:

- Daily Reward definitions;
- Requisition definitions;
- rank/currency/item labels when resolvable.

No button may perform a purchase. If a Requisition button is rendered for layout completeness, it must be disabled or clearly non-functional in Phase 1.

### Progression tab — Phase 1 display only

Render configured progression entries/slots read-only. No lock evaluation, selection or reward behavior.

### Admin tab — Phase 1 shell

Show the live guild roster/member selector.

For officers, show the planned sections as disabled/non-functional controls or clear placeholders:

- Achievements
- Skills
- Items

For non-officers, show a clear access-denied/insufficient-permissions state.

Do not add addon-message operations in this phase.

## Navigation

Add `Guild` to the existing launcher without reorganizing unrelated menu groups. Prefer a single `Guild` entry in the existing Profile-oriented group unless the current UI structure gives a stronger reason otherwise.

Add:

```text
/rpe guild
```

through the existing command router and a `Client:OpenGuildLauncherDestination()` function.

## Acceptance checks

- `/rpe guild` opens the new window.
- Launcher entry opens the same window.
- All three tabs render.
- Leaving/joining a guild refreshes the UI safely.
- No GuildSetting produces a clean empty state.
- One matching GuildSetting renders its data.
- Multiple equally valid GuildSettings show a conflict state.
- Admin roster populates when guild data is available.
- Non-officers cannot access active Admin controls.
- No requisition, reward, Achievement, skill or item state is mutated by this window.

---

# Task 10 — Phase 1 Integration Audit and Validation

## Goal

Validate the complete Phase 1 as one coherent system and fix only Phase 1 defects.

## Required audit

### Load order

Review `RPEngine_Dev.toc` and ensure:

- new classes load before any code that instantiates them;
- Profile state modules load before Profile/UI consumers;
- Guild/Achievement pages load before their windows build them;
- Data Editor pages/inspectors load before `window_DataEditor.lua` uses them.

### Explicit collection maps

Search the repository for:

```text
achievements
currencies
interactions
DATASET_ENTRY_DEFINITIONS
ENTRY_DEFINITIONS
CONTENT_PAGE_DEFINITIONS
INSPECTOR_PAGE_BY_COLLECTION
```

Use these neighboring collections to find any explicit collection lists that should also include `guildSettings`.

### Schema/migration smoke test

Verify:

- old Profile without `achievements`/`guild` normalizes safely;
- old Dataset without `guildSettings` normalizes safely;
- existing inventory remains untouched;
- existing currencies/skills/equipment/spells remain untouched.

### Dataset round-trip

Create a test Dataset containing:

- one Achievement with multiple criteria;
- one custom currency;
- one Item;
- one Spell;
- one GuildSetting referencing those objects.

Export and import it. Verify all definitions survive and references remain valid.

### Cross-dataset dependency smoke test

Create A/B datasets where B's Achievement/GuildSetting references A. Verify dependency handling.

### Character UI smoke test

Verify:

- Profile -> Achievements;
- Guild -> Requisitions;
- Guild -> Progression;
- Guild -> Admin;
- launcher entry;
- `/rpe guild`.

### Phase boundary audit

Search for and ensure Phase 1 did **not** add:

```text
SendChatMessage achievement announcements
new Guild Admin comms opcodes
currency spending from Requisitions
daily login reward grants
automatic Achievement trigger calls
remote Profile mutation
progression unlock evaluation
```

## Definition of Done

Phase 1 is complete only when all of the following are true:

1. `Achievement` definitions have a stable normalized criterion schema.
2. `GuildSetting` is a first-class dataset entry.
3. Profile schema stores Achievement and Guild state safely.
4. Registry/dependency analysis understands all Phase 1 references.
5. Achievement definitions can be fully authored in the Data Editor.
6. GuildSettings can be fully authored in the Data Editor.
7. Character Profile has a working read-only Achievements tab.
8. A working Guild window exists with Requisitions, Progression and Admin tabs.
9. GuildSetting resolution and conflict presentation work.
10. Admin can read/display the guild roster and gate the UI by officer status.
11. Existing datasets/profiles remain backward compatible.
12. No Phase 2/3/4 gameplay behavior has been accidentally implemented.

---

# Recommended Task Order / Dependencies

```text
Task 1  Achievement model ───────────────┐
                                         ├─> Task 5 Registry/dependencies
Task 2  GuildSetting class ───────┐      │
                                  ├─> Task 3 Database integration ─> Task 4 Profile state APIs
                                  │                           │
                                  │                           ├─> Task 8 Profile Achievements UI
                                  │                           │
                                  ├──────────────> Task 7 GuildSetting editor
                                  │
                                  └──────────────> Task 9 Guild window/runtime shell

Task 1 + Task 3 + Task 5 ────────────────> Task 6 Achievement editor

Tasks 1–9 ───────────────────────────────> Task 10 Integration audit
```

A practical Codex sequence is therefore:

```text
1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 7 -> 8 -> 9 -> 10
```

Avoid combining Tasks 6–9 into one large change. They touch separate UI surfaces and are easier to review when implemented independently.
