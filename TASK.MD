## Goal
Make `guildSettings` a fully usable Data Editor collection and expose all Phase 1 configuration required by later phases.

Depends on: #1, #2, #4

## Primary files
- `client/ui/editor/pages/page_GuildSetting.lua` **new**
- `client/ui/editor/inspectors/page_InspectorGuildSetting.lua` **new**
- Data Editor mapping/core files
- `client/ui/editor/pages/page_Datasets.lua` if collection counts are explicitly enumerated
- `RPEngine_Dev.toc`

## Data Editor integration
Add `guildSettings` to every explicit mapping/branch required by the current editor, including where applicable:
- entry definition;
- content page definition;
- page builder/refresh mapping;
- inspector mapping;
- inspector selection getter;
- create/select branches;
- dataset content count/status.

Search explicit per-collection maps/`elseif` chains; do not assume one registration is enough.

## GuildSetting page
Use the existing list/page structure and show at least name plus guild binding.

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
Editable definitions:
- ID
- Item Ref
- Quantity
- Minimum Guild Rank Index
- Character Limit
- Costs list: Currency Ref + Amount

### Daily Rewards
Editable ordered list:
- ID
- Type (`item` / `currency`)
- Ref
- Amount

### Progression
Structural configuration only:
- Slot Count
- Entries: ID, Name, Description, Icon, Locked Text, Spell Ref list

## Constraints
- No purchase behavior.
- No daily reward claiming.
- No progression unlocking/evaluation/selection behavior.
- Use existing UI abstractions and editor patterns.
- Stable nested IDs must survive ordinary edits/reordering.

## Acceptance criteria
- [ ] GuildSetting can be created, selected, edited, deleted, exported and imported.
- [ ] Nested lists retain stable IDs.
- [ ] Feature flags persist.
- [ ] Cross-dataset refs surface through dependency analysis.
- [ ] No gameplay behavior occurs from editing/activating a GuildSetting.

## Coding-agent instructions
Inspect adjacent collection pages/inspectors and all explicit mapping tables before implementing. Avoid introducing a separate editor framework.