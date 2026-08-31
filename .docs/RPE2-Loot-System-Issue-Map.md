# RPE 2 — Loot System Issue Map

**PDD:** `.docs/RPE2-Loot-System-PDD.md`  
**Implementation plan:** `.docs/RPE2-Loot-System-Implementation-Plan.md`  
**Implementation target:** current `dev` at the start of each issue  
**Task sizing:** 5.6-Luna-ExtraHigh

## Issues

| Order | Issue | Scope | Depends on |
|---:|---|---|---|
| 1 | #150 — Canonicalize Loot Table data, references, migration, and dependencies | `Loot` schema, legacy preservation, Registry resolver, dependency discovery/rewrite | — |
| 2 | #151 — Add Loot Table Data Editor authoring and validation | Loot inspector, entries, item/currency selectors, authoring validation | #150 |
| 3 | #152 — Implement deterministic Loot resolution and Group/Personal assignment | weighted draws, quantities, reward merging, Group/Personal pure logic, injected RNG | #150 |
| 4 | #153 — Add reliable recipient Loot delivery, receipts, transactions, and Comms | delivery/response operations, sender validation, item/currency transaction, duplicate receipts | #150 |
| 5 | #154 — Implement host Loot grant coordination, delivery tracking, and retry | eligibility, one-time resolution, stable IDs, per-recipient delivery, acknowledgements, exact retry | #152, #153 |
| 6 | #155 — Add structured End-of-Event Loot grants and authoring | `Event` structured grants, legacy `lootRefs`, network compatibility, Settings UI | #150 |
| 7 | #156 — Execute authored Loot during Event end without duplicate resolution | `EndEvent` integration, stable end-grant execution, late responses, non-blocking teardown | #154, #155 |
| 8 | #157 — Add ad-hoc Loot distribution to Event Manager Actions | Direct/Table, Group/Personal, selected player subset, status and retry UI | #154 |
| 9 | #158 — Perform Loot System integration audit, regression hardening, and sign-off | complete behavior matrix, migration, trust, idempotence, event/ad-hoc regressions | #150–#157 |

## Dependency graph

```text
#150 Data model / Registry / dependencies
  ├──> #151 Loot Table Data Editor
  ├──> #152 Pure resolution + assignment ──┐
  ├──> #153 Recipient delivery/receipts ──┼──> #154 Host coordinator
  └──> #155 Event-end grant authoring      │        ├──> #156 Event-end execution
                                          │        └──> #157 Ad-hoc Actions UI
                                          │
#150–#157 ─────────────────────────────────────────────> #158 Integration audit
```

## Parallel work

After #150:

- #151, #152 and #153 can proceed independently if each stays within its issue boundary.
- #155 can also proceed after #150 because it is Event data/authoring only.
- #154 waits for #152 + #153.
- #156 waits for #154 + #155.
- #157 waits for #154.
- #158 is last.

## Cross-task rule

Every task must re-read the current `dev` files and trace the exact live call paths before editing. The PDD and implementation plan define product/architectural intent; they are not permission to assume source files have remained unchanged.
