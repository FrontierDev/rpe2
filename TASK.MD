## Validation result: FAIL — corrected NPC requirement

This comment supersedes the previous validation interpretation.

### Product requirement clarification

NPCs are **always exempt** from the defensive-reaction-per-turn limit.

The limit applies to player defenders only. NPCs must never consume or check the defensive-reaction-use ledger, regardless of whether the Ruleset toggle is enabled or whether a defensive stat is in the bypass list.

NPC automatic defence behavior should instead be:

```text
NPC defender
-> inspect all valid defensive reactions for the active defence system / attack type
-> choose the strongest available defensive reaction
-> resolve it normally
-> do not call CanUseDefensiveReaction for turn-limit purposes
-> do not call ConsumeDefensiveReactionUse
```

This clarification supersedes the issue body's current text/acceptance criterion saying NPC automatic defenses should obey the same limit.

### What is already correct

Current `main` (`a39e184`) correctly implements the player-facing portions:

- Ruleset toggle exists and defaults to `false`.
- Bypass list stores stat references and defaults empty.
- Player ledger is transient and keyed by Event / turn / defender / reaction stat.
- Tick/page changes do not reset it.
- Different defensive stats have independent uses.
- Failed attempts consume the player use.
- Pass does not consume a use.
- Bypass stats remain unlimited.
- Player UI marks a spent reaction unavailable.
- Player resolution re-checks availability rather than trusting UI state.
- Turn rollover/Event teardown prevents stale player uses leaking into later turns/Events.

### Blocking defect 1: NPCs are currently subjected to the player limit

`Combat:BeginHitCheck(...)` in `client/combat/effects/Damage.lua` handles non-player defenders by selecting an automatic action and then explicitly checking/consuming the reaction-limit helpers:

```lua
if entry.defenderUnit.isPlayer ~= true then
    ...
    Combat:CanUseDefensiveReaction(entry, action)
    ...
    Combat:ConsumeDefensiveReactionUse(entry, action)
end
```

That must be removed/bypassed for NPC defenders. NPCs should be able to use the same defensive stat on every incoming attack in the turn.

The player path must continue using the current ledger exactly as intended.

### Blocking defect 2: NPCs do not reliably choose their best defence

`Combat:ChooseAutomaticReactionAction(entry)` currently tends to return the first eligible configured action:

- shared preview path: first enabled action matching the defence system;
- complex path: first configured `statRef`;
- percent path: first configured resistance `statRef`.

That is configuration-order selection, not "best defence" selection.

Update NPC automatic selection so it evaluates all valid defensive reactions for the active defence system and attack type and chooses the strongest one.

For the current combat systems this should mean, at minimum:

```text
AC
-> only the configured AC defence applies

Simple
-> only the configured simple defence applies

Complex
-> among valid/enabled configured defence stats for this attack type, choose the stat with the highest resolved defender stat value

Percent
-> among valid/enabled resistance stats for this attack type, choose the stat with the highest resolved resistance value / resulting defence threshold
```

Respect existing eligibility such as shield requirements. Do not choose a disabled defence merely because its raw Stat value is highest.

If two reactions are mechanically equal, deterministic configured order is an acceptable tie-breaker.

Do not alter hit-check formulas; only automatic reaction choice changes.

### Required validation

```text
rule enabled; player defender
-> first Dodge resolves/consumes
-> second Dodge same turn unavailable
-> Parry remains independently available

rule enabled; NPC defender
-> NPC may use Dodge repeatedly against multiple attacks in the same turn
-> no NPC defensive-use ledger entry is created/consulted

NPC has valid Complex defences:
Dodge = 8
Parry = 12
Block = 10
-> NPC chooses Parry

NPC has Percent resistances:
Dodge = 15
Block = 25
-> NPC chooses Block

highest-valued defence is disabled by an existing eligibility rule
-> NPC chooses the strongest remaining valid defence
```

Keep #79 open until both NPC exemption and strongest-defence selection are implemented.