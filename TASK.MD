## Summary

Update all built-in/default datasets to the race/class trait ownership model introduced by #301 and exposed by #302.

This issue is specifically responsible for **data migration/correction**, not the runtime or UI implementation.

Target branch: `dev`.

## Scope

Audit every default Race, Class and Trait definition that participates in racial traits, class passives or class talents.

Current built-in class files include:

- `data/default/classes/mage.lua`
- `data/default/classes/paladin.lua`
- `data/default/classes/priest.lua`
- `data/default/classes/rogue.lua`
- `data/default/classes/warrior.lua`

Also audit the race/trait definitions in `data/default/core.lua` and any other built-in/default dataset that defines Race/Class trait ownership.

## Required class migration

Replace each default class's legacy single `traitRefs` collection with the new explicit collections:

```lua
passiveTraitRefs = { ... }
talentTraitRefs = { ... }
```

Every existing class-owned trait must be intentionally placed into **exactly one** of these collections.

Migration rule:

- a class-intrinsic effect that should always apply when the class is selected -> `passiveTraitRefs`;
- a player-choice class trait -> `talentTraitRefs`;
- do not preserve the old list wholesale and rely on Trait-level flags at runtime.

Use the existing default content and intended gameplay meaning to classify each entry. If an existing definition is contradictory/ambiguous, resolve it explicitly rather than guessing through fallback behavior.

### Known examples

The following current data should be corrected as part of this migration:

- Rogue `Instant Poison` (`z9yfqvhy`) is currently authored as a class trait and should be represented as a **Rogue class passive** in `passiveTraitRefs`.
- Warrior `Defensive Stance` (`duukevtq`) is currently authored as a talent and owned by Warrior; it should be represented in Warrior's `talentTraitRefs`.
- Warrior `Battle Stance` (`r73vv899`) is currently authored as a talent and owned by Warrior; it should be represented in Warrior's `talentTraitRefs`.

Audit the remaining Warrior refs (`0ncx0gfs`, `a8x4ee34`) and all Mage/Paladin/Priest/Rogue refs and assign each to the correct passive/talent collection based on its intended behavior.

Do not drop any currently intended class trait during migration.

## Required race migration/corrections

All racial traits must be owned by the appropriate Race definition, and every race-owned trait is an always-active racial passive.

### Human Spirit defect

`The Human Spirit` (`dm2h660e`) is currently flagged as racial, but the Human race has an empty `traitRefs` collection. Under the canonical ownership model this means the racial is not actually granted by choosing Human.

Correct the Human Race definition so `The Human Spirit` is present in Human's racial `traitRefs`.

Then audit all remaining default traits currently marked/treated as racial and ensure each one is referenced by the correct Race definition.

No default racial should depend solely on a Trait-level `isRacial` flag.

## Remove obsolete ownership flags from default Trait definitions

After the data has been migrated to canonical Race/Class ownership:

- remove obsolete `isRacial` declarations from built-in trait definitions if #301 removes/deprecates that field;
- remove obsolete `isClass` declarations from built-in trait definitions if #301 removes/deprecates that field;
- remove/update any `isTalent` usage whose only purpose was to distinguish a class-owned trait from a class passive, because class ownership/type is now expressed by `passiveTraitRefs` vs `talentTraitRefs`;
- retain unrelated fields such as environmental behavior where applicable.

Do not leave the default datasets in a hybrid state where both the new ownership collections and legacy flags are required to infer the same behavior.

## Preserve identifiers and references

This is a schema/ownership migration, not a content recreation task.

Unless an existing definition is independently broken:

- preserve existing dataset IDs;
- preserve trait IDs;
- preserve names/descriptions/effects/auras/events;
- preserve unlock levels;
- preserve spell/item references;
- preserve class/race IDs.

The migration must not invalidate external references to built-in traits unnecessarily.

## Built-in dataset versioning

Bump the relevant built-in/default dataset versions so installations with older built-in definitions receive the corrected Race/Class/Trait data through the existing default-dataset update mechanism.

Updating a built-in dataset must not reactivate a dataset that the user has explicitly disabled; preserve the existing default-dataset activation semantics.

## Add/extend default-data integrity validation

Add a deterministic validation/test pass for the default datasets so this category of defect is caught in future.

At minimum assert:

1. Every `Race.traitRefs` entry resolves to a valid Trait.
2. Every `Class.passiveTraitRefs` entry resolves to a valid Trait.
3. Every `Class.talentTraitRefs` entry resolves to a valid Trait.
4. A class cannot contain the same ref in both passive and talent collections.
5. Every legacy class-owned ref present before migration is accounted for exactly once after migration unless its deliberate removal is documented.
6. Every built-in trait intended as a racial is owned by at least one Race.
7. Default racial/class ownership does not depend solely on deprecated Trait ownership flags.
8. No default class talent is accidentally available as an unowned generic/manual talent.

Where practical, validate reverse ownership as well so orphaned built-in race/class traits are reported during development.

## Functional verification

Verify in-game/profile behavior after #301/#302 with the migrated data:

- selecting Human immediately grants and applies `The Human Spirit`;
- the Human racial cannot be toggled off;
- selecting Rogue immediately grants its class passives, including `Instant Poison` if that remains the intended passive behavior;
- selecting Warrior exposes `Defensive Stance` and `Battle Stance` in the Warrior talent pool but does not activate them until selected;
- class passives appear under Class Passives;
- class talents appear under Class Talents;
- changing class removes the previous class's passive/talent availability and loads the new class's data correctly.

## Acceptance criteria

- Every built-in Race/Class trait relationship uses the new canonical ownership fields.
- All five current default class files have been audited and migrated.
- `The Human Spirit` is correctly owned by Human and works automatically when Human is selected.
- All existing intended class traits are classified exactly once as either class passive or class talent.
- Built-in Trait definitions no longer rely on duplicate Race/Class ownership flags after migration.
- Relevant default dataset versions are bumped so the migration reaches existing installations without re-enabling disabled datasets.
- Automated/default-data validation detects missing refs, duplicate passive/talent membership, orphaned racial ownership, and other invalid ownership states.