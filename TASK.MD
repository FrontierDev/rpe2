## Goal
Replace the current opaque-only Achievement reward model with a backward-compatible structured schema for supported Item and Currency rewards while preserving unknown existing reward records.

Depends on: #23

This is a **new design extension** beyond the current PDD's initial Achievement runtime. The PDD preserves `Achievement.rewards` but does not define execution semantics; keep this task deliberately narrow.

## Primary files
- `core/classes/Achievement.lua`
- `core/internal/database/Database.lua`
- `core/internal/database/Dependecies.lua`

## Supported reward schema
Support normalized records:

```lua
{
    id = "reward_1",
    type = "item", -- item | currency
    ref = "dataset:item-or-currency",
    amount = 1,
}
```

Supported types in Phase 5 are **only**:

```text
item
currency
```

Do not add arbitrary scripts, spells, Skills, Guild Rank assignment, Progression mutation, or other reward types.

## Normalization
For supported reward records:
- stable non-empty `id`;
- deterministic duplicate handling consistent with current Achievement/Guild nested IDs;
- `type` restricted to `item` or `currency`;
- trimmed non-empty `ref` where valid authored data supplies one;
- positive integer `amount`;
- deterministic surviving order.

Inspect current `Achievement.lua` opaque reward preservation before deciding how supported and unknown records coexist.

## Unknown/legacy reward compatibility
Current datasets may already contain opaque reward tables or unknown types/fields.

Do **not** silently discard or coerce unknown records into Item/Currency rewards.

Preserve unsupported legacy records during normalization/export/import. Later runtime must ignore unsupported reward types safely rather than execute them by implication.

## Dataset schema
Increment only:

```text
Dataset schema 16 -> 17
```

Follow current monotonic schema behavior; never lower a future higher marker.

## Dependency extraction
For supported rewards:
- Item reward `ref` -> Item dataset dependency;
- dataset Currency `ref` -> Currency dataset dependency;
- built-in currencies such as `copper`, `valor`, `justice`, `honor`, `conquest` -> no dataset dependency.

Do not broadly interpret arbitrary unknown reward strings as dependencies.

## Constraints
- Do not implement reward execution.
- Do not modify Profile schema/state.
- Do not add reward UI yet.
- Preserve existing Achievement criteria/trigger behavior.
- Preserve unsupported reward data.

## Acceptance criteria
- [ ] Existing Achievement definitions load without reward data loss.
- [ ] Supported Item rewards normalize and round-trip.
- [ ] Supported built-in/dataset Currency rewards normalize and round-trip.
- [ ] Supported reward IDs are stable and duplicate-safe.
- [ ] Unsupported legacy reward records are preserved.
- [ ] Supported reward refs participate in dependency extraction.
- [ ] Built-in Currency refs do not create bogus Dataset dependencies.
- [ ] Dataset schema becomes 17 without lowering future markers.
- [ ] No reward gameplay mutation occurs in this task.

## Coding-agent instructions
Read the PDD, inspect current `Achievement.lua` reward preservation, Database Dataset schema/migration/export-import behavior, nested stable-ID patterns, Currency built-in resolution, and dependency extraction before editing. Implement Task 8 only. This task defines safe structured data while retaining opaque/unknown legacy records; do not invent execution semantics or additional reward types. Review every acceptance criterion and report changed files, validation performed, and deviations.