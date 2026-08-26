## Goal
Remove the standalone **Guild Progression page** from the runtime UI and reduce the Guild window to the two surviving tabs:

```text
Requisitions
Admin
```

Authoritative plan: `.docs/RPE2-Remove-Guild-Progression-Implementation-Plan.md`.

Depends on: #52

This task owns the Progression page deletion, Guild window tab/routing cleanup, and TOC load-order cleanup only.

## Primary files

- `client/character/guild/page_GuildProgression.lua` — delete
- `client/character/guild/window_Guild.lua`
- `RPEngine_Dev.toc`

## 1. Delete the Progression page

Delete:

```text
client/character/guild/page_GuildProgression.lua
```

Do not leave an empty compatibility page or hidden frame. The feature is being removed, not disabled.

Before deletion, inspect the file once to confirm there are no non-progression reusable helpers embedded in it. Move nothing unless a genuinely generic helper is still used elsewhere.

## 2. Remove Progression from the Guild window

In `client/character/guild/window_Guild.lua`, remove the Progression page reference and tab definition.

Remove current equivalents of:

```lua
progressionPage = GuildUI.ProgressionPage
```

and the `"progression"` branch from `GuildWindow:RefreshTab(...)`.

Remove the `Progression` tab from `BuildWindow()`.

Final tab order must be:

```text
Requisitions
Admin
```

The default/fallback active tab remains:

```text
requisitions
```

## 3. Check tab-index assumptions

The old structure used three tabs with Admin after Progression.

Inspect the Guild window/tab implementation for any hard-coded numeric assumptions such as:

```text
Admin == tab 3
Progression == tab 2
```

After removal, Admin is the second tab. Prefer name-based routing if the existing window system already supports it.

Do not change unrelated tab framework code.

## 4. Remove the TOC entry

In `RPEngine_Dev.toc`, remove only:

```text
client/character/guild/page_GuildProgression.lua
```

Preserve the load order for:

```text
client/client_Guild.lua
client/character/guild/page_GuildRequisitions.lua
client/character/guild/page_GuildAdmin.lua
client/character/guild/window_Guild.lua
```

Do not reorder unrelated UI files.

## 5. Preserve the existing Guild window contract

Keep unchanged:

- window title remains exactly `Guild`;
- existing dimensions;
- show/hide lifecycle;
- Requisitions page construction and refresh;
- Admin page construction and refresh;
- tab styling;
- page visibility behavior.

Do not redesign the Guild shell.

## Acceptance criteria

- [ ] `client/character/guild/page_GuildProgression.lua` is deleted.
- [ ] `RPEngine_Dev.toc` no longer loads the deleted file.
- [ ] Guild window creates exactly two tabs: Requisitions and Admin.
- [ ] No `GuildUI.ProgressionPage` reference remains in `window_Guild.lua`.
- [ ] `RefreshTab()` contains no progression branch.
- [ ] Requisitions remains the default/fallback tab.
- [ ] Admin functions correctly as the second tab.
- [ ] No hard-coded tab index still assumes a three-tab Guild window.
- [ ] Guild window title/dimensions/lifecycle remain unchanged.
- [ ] Requisitions and Admin page refresh routing still works.

## Validation matrix

```text
open Guild window
-> Requisitions tab visible
-> Admin tab visible
-> no Progression tab

open Guild window fresh
-> Requisitions selected by default

switch Requisitions -> Admin -> Requisitions repeatedly
-> correct page shown each time
-> no Lua errors

refresh while Requisitions active
-> Requisitions refresh path runs

refresh while Admin active
-> Admin refresh path runs

show/hide/reopen Guild window
-> two-tab state remains valid
-> no attempt to construct ProgressionPage
```

## Constraints

- Do not edit Guild Admin internals here; #53 owns Progression removal from Admin.
- Do not edit GuildSetting/editor schema here; #51/#55 own those changes.
- Do not alter Requisitions UI/business logic.
- Do not create a replacement Progression tab.
- Do not reorder unrelated TOC entries.

## Coding-agent instructions
Use current `FrontierDev/rpe2` as authoritative. This task is intended for **5.6-Luna-ExtraHigh**. Read `.docs/RPE2-Remove-Guild-Progression-Implementation-Plan.md` and completed #52 before editing. Inspect `window_Guild.lua` tab construction/routing and the relevant TOC block before deletion. Keep this task narrow: delete the page, remove the tab/routing/load entry, verify two-tab behavior, and report exact files changed/deleted plus validation performed.