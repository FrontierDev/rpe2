# RPE 2 — NPC Autopilot Issue Map

Implementation plan: `.docs/RPE2-NPC-Autopilot-Implementation-Plan.md`  
Product design: `.docs/RPE2-NPC-Autopilot-PDD.md`

## Existing prerequisite

- #101 — Add host-only DM Helper view to the event widget

## Implementation issues

1. #113 — Add Autopilot event mode and instance capability checks
2. #114 — Add raid-marker TurnActor and TurnStep scheduling
3. #115 — Add host player-position cache and virtual spatial runtime
4. #116 — Add host runtime coordinator and sliceable planner skeleton
5. #117 — Add explicit-caster canonical spell activation snapshots
6. #118 — Add deterministic damage/healing utility evaluation
7. #119 — Add threat, healing, and AoE target selection
8. #120 — Add five-yard melee and shared raid-marker movement planning
9. #121 — Integrate the full frozen cohort planner
10. #122 — Add Pending Authorization state and DM Helper controls
11. #123 — Execute authorized NPC actions through the normal spell lifecycle

## Dependency outline

```text
#113 Event mode/capability
  ↓
#114 TurnActor/TurnStep scheduling
  ↓
#115 Position cache/spatial runtime
  ↓
#116 Sliceable planner skeleton
  ↓
#117 Explicit-caster activation snapshots
  ↓
#118 Spell utility evaluation
  ↓
#119 Target selection
  ↓
#120 Shared-marker melee planning
  ↓
#121 Frozen planner integration
  ↓
#122 Pending authorization + DM Helper controls ← #101
  ↓
#123 Authorized execution
```

Some middle-layer tasks can be implemented in parallel once their direct prerequisites exist, especially #118/#119 and parts of #120. The execution path in #123 should remain last so no intermediate planner task can accidentally mutate gameplay state.
