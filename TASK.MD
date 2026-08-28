## Validation result: FAIL — rev 1

Rev 1 correctly fixes the two major behaviors from the previous validation:

- NPC defenders no longer consult or consume the player defensive-reaction ledger in `Combat:BeginHitCheck(...)`.
- `Combat:ChooseAutomaticReactionAction(entry)` now evaluates eligible actions for the active defence system and selects the one with the highest resolved defensive value instead of blindly taking the first configured action.

The player-only reaction-limit behavior remains intact.

### Remaining blocking defect: shield-gated grouped defences can be re-enabled

`Combat:BuildReactionActions(entry)` currently applies shield eligibility to a newly-created grouped Complex/Percent action **before** it marks that action enabled for the current attack type:

```lua
existing = {
    ...
    enabled = false,
}
applyShieldEligibility(existing)
...
if attackType == tostring(entry.attackType or "spell") then
    existing.enabled = true
end
```

When `allow_block_without_shield == false` and the defender has no shield, `applyShieldEligibility(existing)` correctly sets `enabled = false`, but the later attack-type branch unconditionally sets it back to `true`.

Because rev 1's strongest-NPC-defence selector trusts `action.enabled ~= false`, this can cause an NPC with no shield to select Block as its strongest defence when Block is configured as a grouped Complex or Percent reaction.

This violates the clarified requirement that NPCs choose the strongest **valid** defence and must respect existing eligibility such as shield requirements.

### Required fix

Ensure grouped-action attack-type enabling cannot overwrite an existing eligibility failure.

For example, either:

1. set attack-type applicability first, then run `applyShieldEligibility(existing)` after grouped actions are fully built; or
2. track attack-type applicability separately and set final `enabled` only after all eligibility checks have run.

Do not special-case NPCs here: the shared reaction action should accurately represent validity for both player UI and NPC automatic selection.

### Required validation

```text
allow_block_without_shield = false
NPC has no shield
Complex defences: Dodge=8, Block=20
-> Block action remains disabled
-> NPC chooses Dodge

same setup, NPC equips shield
-> Block becomes valid
-> NPC chooses Block

Percent defences with Block configured similarly
-> same shield gating behavior

player defender without shield
-> Block remains unavailable exactly as before
```

All other rev 1 behavior can remain unchanged.