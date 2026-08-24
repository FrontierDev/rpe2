## Goal
Advance `skill_gain` criteria from actual positive persisted Skill increases.

Depends on: #23, #24

## Primary files
- `core/internal/profile/Profile.lua`
- `core/internal/database/Database.lua` only if the canonical setter must expose final applied level more clearly
- `client/client_Achievements.lua`
- existing direct Skill mutation call sites found by repository search

## Canonical change boundary
Prefer a small Profile-level Skill change listener/callback rather than making Profile persistence directly depend on `Client.Achievements`.

Emit only after a successful canonical:

```lua
Profile.SetSkillLevel(skillRef, value)
```

Calculate:

```text
previousLevel
updatedLevel
actualGain = updatedLevel - previousLevel
```

Dispatch only when:

```text
actualGain > 0
```

Use the actual persisted result, not the requested delta/value when normalization or bounds change it.

## Runtime call-site audit
Search for gameplay/Admin code that bypasses the Profile API with direct `Database.SetProfileSkillLevel(...)` calls. Runtime mutation should converge on the canonical Profile API so one Skill-gain boundary exists.

Database normalization/loading must not emit gain events.

## Trigger context
Conceptually:

```lua
{
    skillRef = "dataset:skill",
    previousLevel = 4,
    updatedLevel = 6,
    amount = 2,
    source = "profile-skill-change",
}
```

## Filter semantics
If `filters.skillRef` exists, require exact qualified-reference match.

## Expected Guild Admin behavior
An officer `adjust_skill` increase should count naturally because the member's canonical Profile Skill state increased. A decrease remains a valid Admin mutation but must not count as `skill_gain`.

## Constraints
- Do not emit from Profile load/normalization.
- Do not count decreases or same-value writes.
- Do not bypass existing Skill bounds/normalization.
- Do not implement Item/Event/Combat triggers here.

## Acceptance criteria
- [ ] Positive actual Skill increase advances matching criteria.
- [ ] Decrease does not progress.
- [ ] Same-value set does not progress.
- [ ] Progress amount equals actual persisted positive difference.
- [ ] `skillRef` filter requires exact match.
- [ ] Profile load/normalization does not emit gain.
- [ ] Guild Admin increase counts through the canonical path.
- [ ] Guild Admin decrease remains valid but does not count.
- [ ] Existing Skill bounds/normalization remain authoritative.

## Coding-agent instructions
Read the PDD and issues #23–#24, then inspect `Profile.GetSkillLevel`, `Profile.SetSkillLevel`, Database persistence/normalization, and every runtime Skill mutation call site before editing. Implement Task 4 only. Create one canonical post-persist Skill-gain boundary, use the actual applied positive delta, and keep persistence layers decoupled from client runtime where possible. Review every acceptance criterion and report changed files, validation performed, and deviations.