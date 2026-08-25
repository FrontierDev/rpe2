## Goal
Fix the Guild **Admin** page layout regression visible after #49 while preserving the new table/scroll implementation.

Runtime screenshot shows two concrete problems:

1. the instruction/status line at the top (`Officer access detected for ... Select an online member...`) wastes vertical space and should be removed from the normal Admin layout;
2. the roster table visually overlaps the lower administration controls instead of remaining contained inside the roster panel.

The `UI.Table` roster itself, its columns, row scrolling, rank sorting, selection, and Online/Offline colors are otherwise correct and should be retained.

## Primary file

- `client/character/guild/page_GuildAdmin.lua`

Current #49 implementation uses a root `VerticalLayoutGroup` with:

```text
StatusText
RosterPanel (expandHeight)
AdminSectionsPanel
```

Inside `RosterPanel`, `RPEGuildRosterContentLayout` contains the title plus an expanding `UI.Table`, but its sizing must be made strictly follow the actual panel viewport so table rows cannot render into `AdminSectionsPanel`.

## 1. Remove the top instruction/status row

Remove the routine top instruction text from the visible Admin page.

In particular, the normal officer state must no longer render:

```text
Officer access detected for <guild>. Select an online member to administer RPE Guild Rank.
```

Do not replace it with another persistent instructional sentence elsewhere.

Preserve meaningful exceptional states such as:

- not in a guild;
- no officer/admin access;

but surface them compactly within the existing Admin summary/control region rather than reserving a dedicated top row. The normal officer/member-selection workflow should begin directly with the roster panel.

## 2. Fix roster/admin vertical containment

The roster table must never overlap the lower Admin controls.

Required layout:

```text
Vertical Root
├─ Roster Panel (takes remaining height)
│  ├─ Roster title
│  └─ UI.Table (fills only remaining roster-panel height)
└─ Admin Controls Panel (fixed/bounded lower region)
   ├─ selected-member summary
   ├─ rank controls
   ├─ active section controls
   └─ section selector
```

Requirements:

- `RosterPanel` should consume the remaining available height above the lower Admin panel;
- `AdminSectionsPanel` must remain fully below it;
- the table viewport/body must size from the **actual current height** of `RosterPanel`, not continue using a preferred height that can extend beyond the panel;
- keep `RPEGuildRosterTitle` above the table;
- table body continues to scroll normally when there are more rows than fit;
- no table row, scrollbar, header, or row background may render over the Admin controls;
- no Admin control may render over the roster;
- resize/layout refresh should recompute the table viewport correctly.

Prefer correcting the existing layout-group sizing/anchoring rather than adding masks, arbitrary offsets, or manually hiding overflowing rows.

Likely approaches include making the roster content layout actually distribute its available height (`fitChildrenHeight`/expanding table semantics) or anchoring the table between the title and the bottom of the roster content frame. Use whichever is most consistent with the existing RPE UI system.

## 3. Preserve #49 behavior

Do not regress the parts of #49 that are working:

- roster remains `UI.Table`;
- columns remain Character / Guild Rank / Level / Class / Zone / Status;
- default sort remains numeric WoW `rankIndex` ascending with name tie-break;
- Online remains green and Offline grey;
- clicking a row still selects/querys that member;
- selected-row highlighting remains visible;
- Guild Rank / Achievement / Skill / Item selectors remain hierarchical;
- lower controls continue using layout groups;
- Progression controls and mutations remain intact;
- officer checks, online-target requirement, pending/query state, comms, rank assignment, achievement grant, skill adjustment, item grant, and progression mutations remain unchanged.

No schema or protocol changes are expected.

## Acceptance criteria

- [ ] Routine officer instruction text is no longer shown at the top.
- [ ] Roster starts at the top of the Admin content area.
- [ ] Roster panel and Admin controls panel occupy non-overlapping vertical regions.
- [ ] Table header/body/scrollbar are fully contained inside the roster panel.
- [ ] With a long guild roster, excess members are reached by scrolling rather than by rows extending into the controls area.
- [ ] Admin summary, rank controls, section-specific controls, and section selector remain fully visible and aligned.
- [ ] No overlap occurs at the current Guild window size shown in the runtime screenshot.
- [ ] No #49 roster/table/dropdown/admin behavior regresses.

## Validation matrix

```text
normal officer state
-> no top instruction sentence
-> roster begins at top of Admin page

roster with more rows than viewport
-> table scrolls
-> last visible row ends above Admin controls
-> scrollbar ends above Admin controls

select online member
-> row highlight updates
-> selected-member summary and query work
-> table does not move/overlap controls

switch Achievements / Skills / Items / Progression
-> lower panel layout remains contained
-> roster region remains unchanged

non-officer / not-in-guild
-> meaningful access state still visible in the lower summary/control region
-> no dedicated instruction row is reintroduced

window/layout refresh
-> roster table recalculates available height
-> no overflow into lower panel
```

## Coding-agent instructions
Use current `FrontierDev/rpe2` as authoritative. Inspect `client/character/guild/page_GuildAdmin.lua` and the sizing behavior of `VerticalLayoutGroup`, `UI.Panel`, and `UI.Table`/`ScrollLayout` before editing. This is a narrow layout correction to #49: preserve the table and scroll view, remove the top routine instruction row, and make the two main vertical regions strictly non-overlapping. Report exact files changed and runtime/static validation performed.