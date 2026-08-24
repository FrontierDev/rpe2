## Goal
Emit a boss-specific Achievement kill trigger while preserving the existing ordinary `rpe_kill` behavior and authority model.

Depends on: #23, #24, #28

## Primary files
- `client/client_Resources.lua`
- `client/client_Achievements.lua`
- `core/classes/EventUnit.lua` only if a narrow boss-state accessor is useful

## Boss authority
The current EventUnit model already normalizes a `boss` boolean. Use that authoritative EventUnit state.

Do not infer boss status from:
- unit name;
- raid marker;
- health quantity;
- Achievement filters;
- arbitrary client-side naming conventions.

## Kill semantics
Reuse the existing authoritative alive->dead transition and transport-bound local action-owner validation.

For an authoritative boss kill credited to the local player, emit both semantic triggers:

```text
rpe_kill
rpe_boss_kill
```

For an ordinary non-boss kill, emit only:

```text
rpe_kill
```

Do not replace or weaken generic kill progression.

## Trigger context
Reuse the existing trusted kill context rather than constructing a second independent death-analysis path. Add confirmed boss state only as needed for matching/debugging.

## Filters
`rpe_boss_kill` must respect the Task 1 filter contract:
- optional exact `unitRef`;
- optional `enemyOnly`.

Use existing Event/team semantics for enemy status.

## Constraints
- Do not duplicate alive/dead transition tracking.
- Do not alter generic `rpe_kill` filters/semantics.
- Do not infer boss status from presentation data.
- Preserve transport-bound action ownership.
- Do not implement reward logic here.

## Acceptance criteria
- [ ] Boss alive->dead triggers `rpe_boss_kill` exactly once.
- [ ] Boss kill continues to trigger ordinary `rpe_kill`.
- [ ] Non-boss kill never triggers `rpe_boss_kill`.
- [ ] Already-dead updates cannot repeat either trigger.
- [ ] Boss status comes from authoritative EventUnit state.
- [ ] `unitRef` and `enemyOnly` filters work.
- [ ] Existing transport-bound kill ownership remains intact.

## Coding-agent instructions
Read the PDD and completed issues #23, #24 and #28, then inspect the current `rpe_kill` alive->dead path, trusted action-owner helper, EventUnit boss normalization and team/enemy determination before editing. Implement Task 7 only. Extend the existing authoritative kill event rather than building a parallel death detector. Review every acceptance criterion and report changed files, validation performed, and deviations.