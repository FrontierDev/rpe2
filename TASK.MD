## Goal
Create the Guild-facing read-only runtime facade and top-level Guild window required by later phases, without implementing transactions or remote mutations.

Depends on: #1, #2, #3, #4

## Primary files
- `client/client_Guild.lua` **new**
- `client/character/guild/window_Guild.lua` **new**
- `client/character/guild/page_GuildRequisitions.lua` **new**
- `client/character/guild/page_GuildProgression.lua` **new**
- `client/character/guild/page_GuildAdmin.lua` **new**
- `core/internal/Runtime.lua`
- `client/ui/windows/window_LauncherMenu.lua`
- `client/client_Commands.lua`
- `RPEngine_Dev.toc`

## `client_Guild.lua` responsibilities
Provide a narrow local facade for:
- current guild identity/name;
- active GuildSetting resolution;
- GuildSetting conflict detection;
- local officer-state query;
- guild roster readout;
- Guild window refresh routing.

Do not put Profile transaction/business logic here.

### Active GuildSetting resolution
Search `Registry:GetActivatedDatasets()`.
Rules:
1. Player must be in a guild.
2. Exact `guildName` matches take priority.
3. If no exact match exists, blank `guildName` may act as generic match.
4. Multiple equally valid matches produce a conflict.
5. On conflict, return no active setting plus enough detail for UI explanation.

Never silently choose the first match.

### Officer state
Centralize officer detection in one helper such as `Client.Guild:IsLocalPlayerOfficer()` using the target WoW interface APIs. Do not scatter hard-coded rank checks through pages.

## Runtime integration
Extend the existing centralized `core/internal/Runtime.lua` event dispatch. Do not create an independent event frame.

Register/route appropriate guild lifecycle events (including current-interface equivalents of `PLAYER_GUILD_UPDATE` and `GUILD_ROSTER_UPDATE`) to Guild refresh handling.

Do not implement daily reward processing.

## Guild window
Create one top-level RPE `UI.Window` titled `Guild` with tabs:
- Requisitions
- Progression
- Admin

### Requisitions — display only
Render active GuildSetting Daily Reward and Requisition definitions with useful resolved labels where available. Any action button must be disabled/non-functional.

### Progression — display only
Render configured progression slots/entries read-only. No unlock evaluation, selection or rewards.

### Admin — shell only
Show live guild roster/member selector.
- Officers: planned Achievements/Skills/Items sections as disabled controls/placeholders.
- Non-officers: clear insufficient-permissions state.
- No addon-message operations.

## Navigation
- Add one `Guild` entry to the existing launcher without unrelated reorganization.
- Add `/rpe guild` through existing command routing.
- Add `Client:OpenGuildLauncherDestination()` (or equivalent existing pattern).

## Acceptance criteria
- [ ] `/rpe guild` and Launcher open the same window.
- [ ] All three tabs render.
- [ ] Guild join/leave/roster changes refresh safely.
- [ ] No active setting shows a clean empty state.
- [ ] One matching setting renders read-only data.
- [ ] Equal-priority conflicts are surfaced explicitly.
- [ ] Admin roster populates when guild data is available.
- [ ] Non-officers cannot access active Admin controls.
- [ ] No requisition/reward/Achievement/skill/item state is mutated.

## Coding-agent instructions
Follow existing Runtime, Launcher, command and `UI.Window` patterns. This task is a read-only shell: do not cross into Phase 2/3/4 implementation.