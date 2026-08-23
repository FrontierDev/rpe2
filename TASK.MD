## Goal
Expose the new Database-backed Achievement and Guild character state through `Addon.Internal.Profile` without implementing later-phase behavior.

Depends on: #2

## Primary files
- `core/internal/profile/Achievements.lua` **new**
- `core/internal/profile/Guild.lua` **new**
- `RPEngine_Dev.toc`

## Required API
### Achievement state
Provide thin wrappers such as:
- `Profile.ListAchievementStates()`
- `Profile.GetAchievementState(achievementRef)`
- `Profile.SetAchievementState(achievementRef, state)`
- `Profile.ClearAchievementState(achievementRef)`

### Guild state
Provide:
- `Profile.GetGuildState()`
- `Profile.SetGuildState(state)`

Optional narrowly scoped `byGuild` read helpers are acceptable only if they simplify later read-only UI and remain persistence primitives.

## Load order
Load after `Database.lua` and before UI/client consumers. Follow the namespace-extension style used by `core/internal/profile/Currencies.lua` and existing Profile modules.

## Constraints
Do **not** add:
- `GrantAchievement` or completion evaluation;
- `TryRequisition`;
- `ClaimDailyReward`;
- progression unlock/evaluation methods;
- runtime triggers or messaging.

Returned state must follow existing copy/reference conventions so callers cannot accidentally bypass Database persistence notifications.

## Acceptance criteria
- [ ] Calls are safe when no Profile existed previously.
- [ ] Reads follow current Profile/Database copy semantics.
- [ ] Set/Clear operations persist and use existing notification paths.
- [ ] TOC load order is dependency-safe.
- [ ] No Phase 2/3/4 behavior is introduced.

## Coding-agent instructions
Keep these modules deliberately thin. Do not move normalization/business logic out of `Database.lua`.