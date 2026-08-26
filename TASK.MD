## Goal
Remove redundant Profile refreshes and make Profile opening/activation **revision-driven**, with cached presentation/view-model data reused until relevant state actually changes.

Authoritative documents:

- `.docs/RPE2-Runtime-Performance-Hitch-Elimination-PDD.md`
- `.docs/RPE2-Runtime-Performance-Hitch-Elimination-Implementation-Plan.md`

Depends on: #63

This task owns Profile presentation lifecycle/caching only. Preserve existing Profile data and gameplay semantics.

## Primary files

- `client/character/profile/window_Profile.lua`
- `client/character/profile/page_ProfileEquipmentStats.lua`
- `client/character/profile/page_ProfileSpellbook.lua`
- `client/character/profile/page_ProfileTraits.lua`
- `client/character/profile/page_ProfileSkills.lua`
- `client/character/profile/page_ProfileAchievements.lua`
- `core/internal/profile/Profile.lua`
- `core/ui/elements/TabContainer.lua` only if a tiny generic activation hook is strictly required

Inspect actual current build/show/OnShow/Refresh call chains for every Profile tab before editing.

## 1. Establish a single page lifecycle contract

Adopt this contract for each Profile page:

```text
Build(parent, owner)
-> construct controls only

page activation / ShowTab
-> RefreshIfDirty()
```

Requirements:

- page `Build()` must not eagerly perform expensive data refresh unless a tiny control-initialization value is structurally required;
- the window builder must not immediately refresh a page that just refreshed itself;
- `OnShow` must not cause a duplicate refresh for the same revision during the same activation;
- `ProfileWindow:Show()` must not broad-refresh every built tab;
- hidden built pages are marked stale/dirty only.

Preserve lazy tab construction in `TabContainer`.

## 2. Add revision tuples per Profile page

Each page must track only the revisions that affect its output.

At minimum:

```text
Equipment/Stats -> EquipmentRevision + relevant ProfileState/ResolvedProfile + ConfigurationRevision
Spellbook -> spellbook/action-bar/configuration inputs actually used by the page
Traits -> trait/profile/configuration inputs actually used
Skills -> SkillRevision + ConfigurationRevision
Achievements -> AchievementRevision + ConfigurationRevision
```

If a missing revision domain is genuinely required, add it narrowly through the #59 runtime revision API rather than falling back to `ProfileStateRevision` for everything.

`RefreshIfDirty()` must return quickly when the tuple is unchanged.

## 3. Add cached Profile presentation/view-model snapshots

Build one or more cached read-only presentation snapshots for expensive data shared by Profile widgets.

For Equipment/Stats this should include, where applicable:

```text
resolved equipped items/slots
resolved stat rows
resolved resource rows
race/class/level presentation values
item-level summary
active equipment scope data
```

Key each cache to the exact revisions that affect it.

Requirements:

- reuse existing resolved stat/resource caches in `Profile.lua`; do not duplicate the same derivation layer;
- avoid cloning/regrouping full resolved lists on every unchanged window show when a safe immutable/presentation snapshot can be reused;
- do not expose a half-built snapshot;
- configuration/equipment/profile changes invalidate only the snapshots they affect.

## 4. Remove irrelevant mount/pet work

Audit `EquipmentStatsPage:RefreshEquipmentHeader()` and related scope helpers.

Required behavior:

```text
character scope -> do not enumerate/build mount choices
mount scope -> build/use mount choices only
pet scope -> build/use pet choices only
```

Cache mount/pet selector data by the revisions/collection state that actually affect it.

Do not change mount/pet gameplay semantics.

## 5. Make tooltip work lazy or revision-cached

Opening Profile must not eagerly build expensive tooltip descriptions for controls the user has not hovered.

For item/stat/trait/spell tooltips:

- build lazily on hover where the current UI abstraction supports it cleanly; or
- cache by the relevant stable revision tuple.

Do not change tooltip content semantics.

## 6. Consume Runtime ChangeSets narrowly

Use the runtime transaction/revision foundation so Profile UI becomes dirty only for relevant committed changes.

Examples:

```text
currency-only mutation -> do not refresh Equipment/Stats unless that page actually displays affected currency data
Achievement progress -> mark Achievements tab dirty
skill adjustment -> mark Skills tab dirty
Inventory-only mutation -> do not broad-refresh Profile
structural equipment/stat change -> mark Equipment/Stats dirty
```

If the Profile window is hidden, perform no rendering work.

## 7. Preserve Profile interaction behavior

Keep unchanged:

```text
tab ordering/labels
selected tab behavior
equipment interactions
spellbook interactions
trait/skill/achievement display semantics
mount/pet scope switching
window sizing/layout
existing Profile public APIs
```

This is a performance lifecycle/caching refactor, not a visual redesign.

## Acceptance criteria

- [ ] Every Profile page follows Build-only + RefreshIfDirty-on-activation ownership.
- [ ] No page refreshes multiple times for the same revision during one open/activation.
- [ ] Hidden tabs do not render because unrelated runtime state changed.
- [ ] Reopening unchanged Profile is primarily a visibility operation.
- [ ] Equipment/Stats reuses revision-cached presentation data.
- [ ] Existing resolved stat/resource caches are reused rather than duplicated.
- [ ] Character scope does not enumerate mounts/pets.
- [ ] Mount/pet choices are resolved only for relevant scope and cached where practical.
- [ ] Expensive tooltip descriptions are lazy/revision-cached.
- [ ] Achievement/Skill/Equipment changes dirty only relevant tabs.
- [ ] Profile values/interactions remain correct.

## Validation matrix

```text
first open Profile on Equipment
-> active tab builds
-> one RefreshIfDirty
-> hidden tabs not built/refreshed

close/reopen unchanged Profile
-> no expensive Equipment snapshot rebuild
-> no duplicate page refresh

switch Equipment -> Skills -> Achievements
-> each stale/unbuilt page refreshes once
-> switch back unchanged -> fast-path

Achievement progress while Profile hidden
-> Achievements tab marked dirty
-> no render until shown

Achievement progress while Equipment tab visible
-> Equipment page does not refresh

Skill adjustment
-> Skills tab dirty only

equipment change
-> Equipment/Stats revision changes
-> relevant snapshot rebuilds once

character scope
-> no mount/pet enumeration

switch to mount scope
-> mount choices built/resolved as needed

hover expensive stat/item/trait/spell
-> tooltip data built on demand or reused from cache
```

## Constraints

- Do not redesign Profile visuals.
- Do not make TabContainer eager.
- Do not use one broad ProfileStateRevision if a narrow existing domain is available.
- Do not duplicate resolved stat/resource derivation logic already cached in Profile.
- Do not refresh hidden pages.
- Do not eagerly construct tooltip descriptions solely because the window opened.
- Preserve all Profile persistence and gameplay semantics.

## Coding-agent instructions
Use current `FrontierDev/rpe2` as authoritative. This task is intended for **5.6-Luna-ExtraHigh**. Read both runtime-performance documents and completed #63. Trace the actual refresh ownership for every Profile tab before editing; do not assume all pages share the same pattern. Reuse existing `Profile` resolved caches and `TabContainer` laziness. Report the final lifecycle per tab, revision tuples, presentation cache keys, mount/pet behavior, files changed, and first-open/reopen timings.