## Goal
Audit Tasks #51–#56 as one coherent removal of **Guild Progression**, execute the required validation matrix, and fix **concrete defects only**.

Authoritative plan: `.docs/RPE2-Remove-Guild-Progression-Implementation-Plan.md`.

Depends on: #51, #52, #53, #54, #55, #56

Do not start until all preceding Guild Progression Removal tasks are implemented and available in the working tree.

## Primary files to audit

Inspect every file changed by #51–#56, especially:

- `core/classes/GuildSetting.lua`
- `core/internal/profile/Guild.lua`
- `core/internal/database/Dependecies.lua`
- `client/client_Guild.lua`
- `client/character/guild/page_GuildAdmin.lua`
- `client/character/guild/window_Guild.lua`
- `client/ui/editor/inspectors/page_InspectorGuildSetting.lua`
- `RPEngine_Dev.toc`
- `.docs/RPE2-Achievements-Guild-Systems-PDD.md`
- `.docs/RPE2-Final-Guild-Requisitions-Page-Implementation-Plan.md`
- `TASK.MD`

Confirm that:

```text
client/character/guild/page_GuildProgression.lua
```

has been deleted.

Inspect adjacent code only where necessary to validate references or regressions. Do not redesign working systems.

## 1. Repository-wide Guild Progression search audit

Search the repository for at least:

```text
enableProgression
GuildProgression
ProgressionPage
GetActiveGuildProgression
GetGuildProgression
SetGuildProgression
SetGuildProgressionSlot
SetGuildProgressionEntryUnlocked
SetGuildProgressionSelectedSpell
ClearGuildProgressionSelectedSpell
SelectedProgression
RPEGuildProgression
GuildSetting.progression
assign_progression_entry
lock_progression_entry
unlock_progression_entry
clear_progression_spell
page_GuildProgression
```

Inspect **every remaining match**.

Allowed remaining matches are limited to:

- clearly historical/changelog text that cannot be interpreted as an active requirement;
- unrelated generic class/race/stat/resource progression code.

No active Guild runtime, UI, editor, Profile, dataset, dependency, protocol or TOC implementation may retain Guild Progression behavior.

Do not delete generic progression code merely to make a text search empty.

## 2. GuildSetting model/serialization audit

Verify:

```text
new GuildSetting
-> no general.enableProgression
-> no progression table

legacy GuildSetting input containing both fields
-> loads/merges without error
-> normalized live object does not expose active Guild Progression state
-> ToTable() does not serialize either field
```

Confirm the removal did not alter:

```text
Guild Rank metadata
wowGuildRankIndices
Requisitions
Daily Rewards
existing tags/other GuildSetting fields
```

## 3. Profile persistence audit

Verify `core/internal/profile/Guild.lua` exposes no Guild Progression APIs.

Exercise/inspect an existing profile that still contains stale:

```lua
profile.guild.byGuild[...].progression
```

Expected behavior:

```text
profile loads normally
stale progression data is ignored
no code reads it
no code mutates it
no migration is required solely to erase it
```

Verify unrelated Guild Profile state remains intact:

```text
assigned Guild Rank
requisition usage
Daily Reward claims/transactions
guild identity migration
```

## 4. Dependency-system audit

Confirm GuildSetting dependency extraction/rewrite no longer traverses progression spell refs.

Then explicitly validate unrelated generic progression dependency behavior remains intact for structures such as:

```text
statProgressions
resourceProgressions
traitRefs
skillBonuses
```

Also confirm GuildSetting Requisition/Daily Reward item/currency dependencies still work.

## 5. `client_Guild.lua` runtime/protocol audit

Verify there is no active runtime progression resolver or mutation API.

Confirm Guild Admin query responses contain only still-supported member state and do not serialize/parse progression.

Confirm progression Admin operation strings/dispatch branches are gone.

### Preserve generic Admin protocol
Verify the generic opcodes remain available:

```text
GUILD_ADMIN_QUERY
GUILD_ADMIN_QUERY_RESPONSE
GUILD_ADMIN_MUTATION
GUILD_ADMIN_MUTATION_RESPONSE
```

Exercise/inspect:

```text
Set/Clear Guild Rank
Grant Achievement
Adjust Skill
Give Item
```

and confirm request, validation, acknowledgement and refresh paths still work.

### Protocol-version validation
Review the protocol-version decision made in #52 against the final serializer/parser.

If no version bump was made, confirm mixed-version parsing cannot silently reinterpret fields.

If a bump was made, confirm incompatible clients fail through the intended compatibility path rather than corrupting member state.

Fix only a concrete compatibility defect found during this audit.

## 6. Guild window audit

Required final structure:

```text
Guild
├─ Requisitions
└─ Admin
```

Validate:

```text
open window -> Requisitions selected by default
switch Requisitions -> Admin -> Requisitions
refresh each active tab
hide/show/reopen window
```

Confirm:

- no Progression tab appears;
- no `ProgressionPage` is constructed;
- Admin works as the second tab;
- no stale tab-index assumption exists;
- window title remains exactly `Guild`;
- dimensions/lifecycle remain unchanged.

## 7. Guild Admin audit

Verify the Admin section selector contains exactly:

```text
Achievements
Skills
Items
```

Guild Rank controls remain outside/alongside those sections as currently designed.

Exercise:

```text
roster loading
rank sorting
Online/Offline colors
row selection
online member query
Guild Rank mutation
Achievement grant
Skill adjustment
Item grant
Achievements / Skills / Items switching
long roster scrolling
```

Confirm the #49/#50 table/layout behavior remains intact:

- no top routine instruction row is reintroduced;
- roster remains contained above lower Admin controls;
- no overlap occurs;
- hierarchical selectors remain functional.

No Progression state/control/callback may remain.

## 8. GuildSetting inspector audit

Validate all surviving pages:

```text
General
Requisitions
Daily Rewards
```

Confirm:

- no fourth Progression page;
- no Enable Progression checkbox;
- no Progression entry/spell controls;
- all three pages retain #47 scrolling behavior;
- Requisition authoring remains functional;
- Daily Reward item/currency authoring remains functional;
- built-in/custom currency behavior from #48 remains intact;
- legacy definitions do not cause nil-index errors or recreate progression state.

## 9. Requisitions/Daily Reward regression audit

Guild Progression removal must not affect the final Requisitions feature.

At minimum verify:

```text
Guild Shop displays unlimited requisitions
limited Requisitions remain in the right-hand list
Daily Reward button/tooltip works
Daily Reset timer works
Guild Rank display works
requisition affordability/eligibility still works
purchase transaction still works
manual Daily Reward claim still works
```

Preserve the post-#45/#46/#48 UI and currency behavior.

## 10. Documentation consistency audit

Read the active Guild sections of:

```text
.docs/RPE2-Achievements-Guild-Systems-PDD.md
.docs/RPE2-Final-Guild-Requisitions-Page-Implementation-Plan.md
TASK.MD
```

Confirm none still instruct future coding work to preserve or restore Guild Progression.

The documentation should agree on the final Guild structure:

```text
Requisitions
Admin
```

with Admin supporting Guild Rank, Achievements, Skills and Items but no Progression.

## Final definition of done

- [ ] `page_GuildProgression.lua` is deleted.
- [ ] Guild window has exactly Requisitions and Admin tabs.
- [ ] Guild Admin contains no Progression section/state/actions.
- [ ] `client_Guild.lua` contains no Guild Progression runtime/protocol behavior.
- [ ] Guild Admin generic opcodes and non-progression mutations remain functional.
- [ ] `GuildSetting` contains no `enableProgression` or `progression` model.
- [ ] Guild Profile exposes no progression APIs and safely ignores stale saved progression data.
- [ ] GuildSetting dependencies no longer include progression spell refs.
- [ ] Generic non-Guild progression systems remain intact.
- [ ] GuildSetting inspector contains only General/Requisitions/Daily Rewards and preserves current editor behavior.
- [ ] Requisitions/Daily Rewards continue to function normally.
- [ ] Active documentation no longer specifies Guild Progression.
- [ ] Repository-wide search finds no active Guild Progression implementation.
- [ ] Any protocol-version choice is validated against the final serializer/parser.
- [ ] No duplicate/replacement progression subsystem was introduced.

## Constraints

- Fix concrete defects only; do not redesign adjacent systems during the audit.
- Do not remove unrelated generic progression code to satisfy text search.
- Do not add a migration solely to purge stale Guild Progression SavedVariables.
- Do not change Requisition/Daily Reward/Guild Rank/Achievement/Skill/Item semantics unless a regression caused by this removal is identified.
- Do not renumber generic Guild Admin opcodes.

## Coding-agent instructions
Use current `FrontierDev/rpe2` as authoritative. This task is intended for **5.6-Luna-ExtraHigh**. Read `.docs/RPE2-Remove-Guild-Progression-Implementation-Plan.md` and completed issues #51–#56. Inspect the actual final working tree rather than trusting task summaries. Execute every matrix above, inspect every remaining Guild Progression search hit, and fix only concrete defects in this removal. Before marking complete, report the audit performed, exact files changed, protocol compatibility result, validation results, and any remaining intentional progression references.