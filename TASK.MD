## Goal

Make NPC Autopilot respect active synchronized Taunt state when choosing hostile targets, while preserving canonical target legality and the existing threat-first fallback.

Depends on #337, #338, and #339.

This issue assumes:

- authoritative threat state is correct (#336/#337);
- synchronized `tauntState` exists (#338);
- Taunt duration/expiry is correct (#339).

It does **not** add effect authoring or combat-log UI (#340).

Split from #335.

---

## Required targeting policy

For a hostile target group, primary selection becomes:

```text
1. active valid Taunt source
2. threat descending
3. existing distance tie-break
4. eventID ascending
```

Taunt is a **temporary targeting override**, not a threat mutation.

Never write fake/infinite threat values.

---

## Current-source areas to inspect

Trace the current planner snapshot and target-selection paths before editing:

```text
client/autopilot/PlannerIntegration.lua
client/autopilot/PlannerSnapshotUnitsPerformance.lua
client/autopilot/TargetSelector.lua
client/autopilot/Spatial.lua
client/client_Targeting.lua
client/client_AutopilotPlanner.lua
```

Also re-read the EventUnit Taunt representation implemented by #338 rather than assuming field names from this issue.

---

## Required implementation

### 1. Copy Taunt state into the frozen planner snapshot

The frozen NPC representation must include the active Taunt source and remaining duration.

Copy nested state safely; do not retain a mutable reference to live EventUnit state.

### 2. Include Taunt in snapshot/revalidation identity

A planner started with one Taunt state must not publish if live Taunt state changes before finalization.

The frozen unit signature/current equivalent must distinguish at least:

- no Taunt vs active Taunt;
- different source EventUnit IDs;
- different remaining durations.

Use the existing stale-snapshot mechanism. Do not add a second planner lifecycle or auto-replan subsystem.

### 3. Force the Taunt source only when it is a canonical legal candidate

An active Taunt source is selected only if the source is present in the already-built canonical candidates for that hostile target group.

Taunt must **not** make an otherwise illegal target legal.

Therefore a Taunt source which is dead/inactive/hidden when hidden targets are not allowed/wrong disposition/otherwise absent from the canonical candidate set must be ignored for this selection and the selector falls back to normal threat ordering.

Do not reimplement target legality inside `TargetSelector`; use candidate membership.

### 4. Single-target behavior

Given:

```text
NPC threat:
  Player A = 200
  Player B = 50
active Taunt source = Player B
```

and both are legal candidates:

```text
selected primary = Player B
```

After Taunt expires:

```text
selected primary = Player A
```

with the original threat values untouched.

### 5. Multi-target/AoE behavior

For hostile multi-target selection:

- valid active Taunt source becomes the primary target;
- existing secondary-target ordering around that primary remains unchanged;
- existing `minTargets` / `maxTargets` semantics remain unchanged.

Do not force Taunt source into multiple target groups where it is not a legal member.

### 6. Do not affect non-hostile selection

Taunt must not modify:

- healing target selection;
- allied utility target selection;
- caster/self target selection;
- interrupt utility ordering except insofar as normal target legality/selection already applies;
- spell utility scores.

It only changes hostile primary target ordering.

### 7. Manual mode remains unconstrained

Normal/manual NPC targeting must not automatically redirect because of Taunt.

The synchronized state may exist and expire normally, but only Autopilot consumes it as a targeting override.

Do not modify manual targeting widgets or normal player target-selection behavior.

### 8. Extend bounded target diagnostics

Extend the diagnostic added by #337/current equivalent so an active successful override reports a reason equivalent to:

```text
Autopilot target: npc=12 selected=2 reason=taunt remaining=2
```

If the Taunt source is invalid and fallback occurs, the final diagnostic should show the actual fallback reason/selection rather than falsely claiming `reason=taunt`.

---

## Mandatory deterministic regression cases

1. Higher threat on A, active Taunt from B -> B selected.
2. Taunt expires -> A selected from untouched threat table.
3. Taunt source is not in canonical candidates -> normal threat selection.
4. Taunt source is inactive/dead and therefore excluded -> normal threat selection.
5. Hidden Taunt source excluded by normal policy -> normal threat selection.
6. Re-Taunt to a different valid caster -> new source selected.
7. Same-caster refreshed Taunt remains selected with new duration.
8. AoE uses valid Taunt source as primary and preserves secondary ordering.
9. Healing/allied selection is unchanged by NPC Taunt state.
10. Threat values are never modified by planning or selection.
11. Taunt change during planning invalidates stale output.
12. Explicit Replan reads current Taunt state but does not consume duration.
13. Manual mode ignores Taunt for automatic targeting.
14. No-Taunt cases preserve all #337 threat-ordering tests exactly.

---

## Acceptance criteria

- [ ] Frozen Autopilot state contains synchronized Taunt source + duration.
- [ ] Taunt state participates in normal planner stale-snapshot validation.
- [ ] Valid active Taunt source overrides higher threat for hostile primary selection.
- [ ] Taunt cannot make an illegal target legal.
- [ ] Invalid Taunt source falls back cleanly to threat > distance > eventID.
- [ ] AoE uses Taunt as primary without changing secondary selection rules.
- [ ] Expiry restores existing threat ordering immediately.
- [ ] Threat values remain untouched by Taunt planning/selection.
- [ ] Non-hostile and manual target selection remain unchanged.
- [ ] Debug diagnostics distinguish `reason=taunt` from normal threat fallback.
- [ ] No new planner lifecycle, threat system, or target-legality implementation is introduced.