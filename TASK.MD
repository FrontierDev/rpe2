## Rev 2 verification — `dev` @ `c9a5d74`

Rev 2 fixes the rev-1 mutation-before-response problem and the normal execution path is now structurally correct, but **#370 is still not ready to close** because the new two-message protocol has no recovery if the authoritative damage-resolution message fails after damage has already been finalized.

### Fixed from rev 1

The defender no longer calls side-effectful `ApplyResolvedDamage(entry)` before the hit-check response is accepted for sending.

The flow is now:

```text
COMBAT_HIT_CHECK_RESPONSE queued
    -> defender applies/finalizes authoritative damage
    -> defender queues COMBAT_DAMAGE_RESOLVED
    -> attacker completes pending hit
    -> attacker emits on_damage_type from authoritative outcome
```

That removes the prior possibility of consuming absorption before the initial response-send boundary.

The existing rev-1 fixes also remain present:

- ordinary periodic Aura damage emits `on_damage_type`;
- Aura `event_source` / `event_other` wording is correct;
- source-side proc dispatch uses authoritative `damageSchoolRef` and `appliedDelta`;
- full absorption / zero health loss is rejected;
- duplicate emission remains guarded by `damageTypeEventEmitted`.

### Remaining blocker — terminal `COMBAT_DAMAGE_RESOLVED` send failure leaves the source permanently pending

On the attacker, the first successful hit-check response intentionally does **not** complete the hit:

```lua
if resultToken == RESULT_PASS and not hasAuthoritativeDamageOutcome then
    entry.damageResolutionPending = true
    entry.pendingDamageResultToken = RESULT_PASS
    return true, buildCombatResult(entry, nil, "damage_pending")
end
```

The pending hit is cleared only when `COMBAT_DAMAGE_RESOLVED` arrives and re-enters `HandleDamageHitCheckResponse()`.

On the defender, however, by the time `COMBAT_DAMAGE_RESOLVED` is sent:

```lua
local _, damageResult = Combat:ApplyResolvedDamage(entry)
entry.lastDamageResult = damageResult
Combat:FinalizeLocalDamageResult(entry, damageResult)

local damageOutcomeSent = sendCombatWhisper(attackerName, DAMAGE_RESOLVED_OPCODE, ...)
```

the damage, absorption consumption, resource-delta queueing, and local finalization have already happened.

If `sendCombatWhisper(... DAMAGE_RESOLVED ...)` returns false, the implementation only logs:

```lua
Debug.Internal("Authoritative combat damage hand-off failed ...")
```

There is no retry/recovery of the logical damage outcome and no way for the attacker to leave `damageResolutionPending`.

The same problem exists for an asynchronous terminal failure after enqueue. `Comms:SendMessage()` supports `metadata.onFailed`, but `sendCombatWhisper()` supplies only:

```lua
{
    opcode = opcode,
    scope = "client",
}
```

so terminal queue/message failure has no application-level recovery.

The comms queue retries throttling, but it can still terminate with queue-full / max-attempts / other send failure. `Comms:SendMessage()` explicitly exposes `onFailed` for this reason.

### Required correction

Make the authoritative damage hand-off recoverable/idempotent.

At minimum:

- retain the authoritative outcome by `checkId` until the source acknowledges/completes it, or provide bounded retry on failed delivery;
- use the comms `onFailed` callback for terminal failures rather than log-only handling;
- make repeated `COMBAT_DAMAGE_RESOLVED` delivery safe;
- clear retained outcome state once completion is confirmed or the event ends;
- ensure a retry cannot cause a second `on_damage_type` proc.

A small request/ack protocol is preferable if there is already an established pattern in the repo. Do not re-run `ApplyResolvedDamage()` on retry; resend the stored authoritative outcome.

### Other checks

The new operation is loaded after `Operations.lua`, is registered through `Operations:Allocate()`, and is available before `Reaction.lua` requests its opcode. The attacker verifies the outcome sender against the expected defender authority.

Pending-hit lifecycle is otherwise correct:

- initial PASS response leaves the entry in `PendingCombatHitChecksByCheckId`;
- authoritative outcome calls `CompleteHitCheck()`;
- `CompleteHitCheck()` clears the pending entry;
- duplicate outcome delivery after completion is rejected because the pending entry no longer exists.

### Verification status

No CI/workflow run or commit status exists for `c9a5d74`. This is static code-path verification.

Re-test after the delivery-recovery fix with:

- normal player -> player hit;
- partial/full absorption;
- forced `COMBAT_DAMAGE_RESOLVED` queue failure;
- forced terminal send failure;
- duplicate/retried damage-resolved message;
- Fire DoT tick;
- matching/non-matching damage school;
- no duplicate proc.