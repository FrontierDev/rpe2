## Goal
Remove stale **Guild Progression requirements and documentation** after the code feature has been removed, so future implementation work does not accidentally restore it.

Authoritative plan: `.docs/RPE2-Remove-Guild-Progression-Implementation-Plan.md`.

Depends on: #51, #52, #53, #54, #55

This is a documentation/task-definition cleanup. Do not redesign the implemented Guild systems.

## Primary files

- `.docs/RPE2-Achievements-Guild-Systems-PDD.md`
- `.docs/RPE2-Final-Guild-Requisitions-Page-Implementation-Plan.md` only where it assumes Guild Progression still exists
- `TASK.MD`

Also search `.docs/` and root Markdown files for active Guild Progression requirements that conflict with the completed removal.

## 1. Update the Achievements/Guild Systems PDD

Remove Guild Progression as an intended RPE 2 feature.

At minimum inspect and remove/update sections that describe:

```text
Guild-specific character progression
GuildSetting.general.enableProgression
GuildSetting.progression
Progression entry definitions / spellRefs
Guild Profile progression state
Guild Progression runtime/page behavior
Guild Admin progression management
GuildSetting editor Progression page
Progression dependency extraction
Progression implementation phases/acceptance criteria
```

Preserve the PDD's unrelated content for:

```text
Achievements
Guild Ranks
Requisitions / Guild Shop
Daily Rewards
Guild Admin
Skills
Items
Achievement broadcasting
```

After editing, the document should describe the actual intended Guild system rather than a historical design that still promises Progression.

## 2. Update the final Requisitions implementation plan narrowly

Inspect:

```text
.docs/RPE2-Final-Guild-Requisitions-Page-Implementation-Plan.md
```

Only remove or adjust statements that now incorrectly assume:

- a three-tab Guild window;
- a surviving Progression page;
- Progression must remain unaffected/intact;
- TOC/load ordering involving `page_GuildProgression.lua`.

Do **not** rewrite the Requisitions design itself. Preserve its authoritative Guild Shop, limited requisition, Daily Reward, ShopEntry, pagination and transaction requirements.

## 3. Remove stale `TASK.MD` requirements

Remove or replace inherited wording that treats deleted Guild Progression controls, mutations or tabs as active requirements.

`TASK.MD` must no longer instruct a coding agent to restore or preserve the deleted feature.

Keep any still-relevant current-task conventions if the file is otherwise used as an active Codex handoff, but do not preserve obsolete Issue #50 wording merely for history.

## 4. Search for contradictory active docs

Search Markdown documentation for at least:

```text
Guild Progression
Progression tab
enableProgression
GuildSetting.progression
page_GuildProgression
assign_progression_entry
lock_progression_entry
unlock_progression_entry
clear_progression_spell
```

Inspect every match.

Historical references may remain only where they are clearly historical/changelog context and cannot be mistaken for active product requirements.

## 5. Preserve generic progression terminology

Do not globally replace/delete the word `progression` from documentation.

Unrelated concepts such as class/race/stat/resource progression remain valid and must not be rewritten as part of this task.

## Acceptance criteria

- [ ] Achievements/Guild Systems PDD no longer specifies Guild Progression as an active feature.
- [ ] PDD no longer defines `enableProgression` or `GuildSetting.progression`.
- [ ] PDD no longer describes Guild Profile progression state or Progression Admin controls.
- [ ] Requisitions implementation plan contains no requirement that a Progression tab/page remain functional.
- [ ] Requisitions design/business requirements remain otherwise unchanged.
- [ ] `TASK.MD` contains no instruction to preserve Progression controls/mutations.
- [ ] Active project documentation contains no contradictory requirement to restore Guild Progression.
- [ ] Generic non-Guild progression documentation remains intact.

## Validation matrix

```text
search docs for "Guild Progression"
-> no active product requirement remains

search docs for "enableProgression"
-> no active GuildSetting requirement remains

search docs for "GuildSetting.progression"
-> no active schema requirement remains

read PDD Guild section end-to-end
-> Guild system now describes ranks/requisitions/admin/achievements without a missing Progression phase

read final Requisitions plan
-> two surviving Guild tabs are not contradicted
-> Guild Shop/Requisitions/Daily Reward design remains unchanged

read TASK.MD
-> no coding-agent instruction asks to preserve/rebuild Progression
```

## Constraints

- Do not modify Lua/runtime code in this task unless a documentation search reveals a filename typo only in generated metadata; implementation should already be complete.
- Do not rewrite unrelated PDD sections.
- Do not remove generic character progression documentation.
- Do not change Requisitions business/design decisions.
- Do not turn historical changelog text into current requirements.

## Coding-agent instructions
Use current `FrontierDev/rpe2` as authoritative. This task is intended for **5.6-Luna-ExtraHigh**. Read `.docs/RPE2-Remove-Guild-Progression-Implementation-Plan.md` and inspect the completed code from #51–#55 before editing documentation, so the docs describe the actual resulting system. Make narrow, internally consistent Markdown edits. Search all active Markdown for contradictory Guild Progression requirements and report exact documents/sections changed plus any historical references intentionally retained.
