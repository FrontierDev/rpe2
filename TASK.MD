## Goal
Audit the complete Phase 1 implementation as one coherent system and fix **Phase 1 defects only**.

Depends on: #1, #2, #3, #4, #5, #6, #7, #8

Do not start this issue until Tasks 2–9 are implemented.

## Required audit
### Load order
Review `RPEngine_Dev.toc` and verify:
- new classes load before instantiation;
- Profile state modules load before UI/client consumers;
- Guild/Achievement pages load before their windows;
- Data Editor pages/inspectors load before `window_DataEditor.lua` uses them.

### Explicit collection maps
Search the repository for neighboring explicit collection handling including:
- `achievements`
- `currencies`
- `interactions`
- `DATASET_ENTRY_DEFINITIONS`
- `ENTRY_DEFINITIONS`
- `CONTENT_PAGE_DEFINITIONS`
- `INSPECTOR_PAGE_BY_COLLECTION`

Identify any explicit maps/branches that should include `guildSettings` and correct omissions.

### Schema/migration smoke test
Verify:
- old Profile without `achievements`/`guild` normalizes safely;
- old Dataset without `guildSettings` normalizes safely;
- inventory remains untouched;
- existing currencies, skills, equipment and spells remain untouched.

### Dataset round-trip
Create/construct a Dataset containing:
- one Achievement with multiple criteria;
- one custom Currency;
- one Item;
- one Spell;
- one GuildSetting referencing those definitions.

Export/import and verify definitions and references survive.

### Cross-dataset dependency test
Use A/B datasets where B's Achievement/GuildSetting references A. Verify dependency discovery/recompute/deletion behavior.

### Character UI smoke test
Verify:
- Profile → Achievements;
- Guild → Requisitions;
- Guild → Progression;
- Guild → Admin;
- Launcher → Guild;
- `/rpe guild`.

### Phase-boundary audit
Search for and ensure Phase 1 did **not** add:
- Achievement `SendChatMessage` announcements;
- Guild Admin comms opcodes;
- Requisition currency spending/purchases;
- automatic daily reward grants;
- automatic Achievement trigger calls;
- remote Profile mutation;
- progression unlock evaluation/reward execution.

## Definition of done
- [ ] Achievement definitions use the stable normalized criterion schema.
- [ ] GuildSetting is a first-class Dataset entry.
- [ ] Profile safely persists Achievement and Guild state.
- [ ] Registry/dependency analysis understands all Phase 1 refs.
- [ ] Achievement authoring is functional.
- [ ] GuildSetting authoring is functional.
- [ ] Profile Achievements tab is functional/read-only.
- [ ] Guild window has Requisitions/Progression/Admin tabs.
- [ ] GuildSetting resolution/conflicts work.
- [ ] Admin roster is displayed and officer-gated.
- [ ] Existing datasets/profiles remain backward compatible.
- [ ] No Phase 2/3/4 runtime behavior has leaked into Phase 1.

## Coding-agent instructions
Treat the repository as authoritative. Compare every Phase 1 acceptance criterion against the implemented state. Fix concrete omissions/regressions only; do not expand scope.