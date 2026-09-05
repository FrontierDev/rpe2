from pathlib import Path
from collections import Counter
import json
import re

TAILORING_PATH = Path("data/default/professions/tailoring.lua")
TAILORING_ID = "7259f1d3"
SKILL_REF = "f82db71a:goqp0alw"
TRAINER_COST = 152475

RECIPES = [
    {"name":"Wizardweave Robe","inputs":[["Bolt of Runecloth",8],["Dream Dust",2],["Rune Thread",1]]},
    {"name":"Mooncloth Robe","inputs":[["Bolt of Runecloth",6],["Mooncloth",4],["Golden Pearl",2],["Rune Thread",2]]},
    {"name":"Felcloth Robe","inputs":[["Bolt of Runecloth",8],["Felcloth",3],["Demonic Rune",2],["Rune Thread",2]]},
    {"name":"Robe of the Archmage","inputs":[["Bolt of Runecloth",12],["Essence of Fire",10],["Essence of Air",10],["Essence of Earth",10],["Essence of Water",10],["Rune Thread",2]]},
    {"name":"Truefaith Vestments","inputs":[["Bolt of Runecloth",12],["Mooncloth",10],["Righteous Orb",4],["Golden Pearl",4],["Ghost Dye",10],["Rune Thread",2]]},
    {"name":"Robe of the Void","inputs":[["Bolt of Runecloth",12],["Demonic Rune",20],["Felcloth",40],["Essence of Fire",12],["Essence of Undeath",12],["Rune Thread",2]]},
    {"name":"Bloodvine Vest","inputs":[["Mooncloth",3],["Powerful Mojo",3],["Ironweb Spider Silk",2]]},
    {"name":"Flarecore Robe","inputs":[["Mooncloth",10],["Fiery Core",2],["Lava Core",3],["Essence of Fire",6],["Ironweb Spider Silk",4]]},
    {"name":"Glacial Vest","inputs":[["Frozen Rune",7],["Bolt of Runecloth",8],["Essence of Water",6],["Ironweb Spider Silk",8]]},
    {"name":"Sylvan Vest","inputs":[["Bolt of Runecloth",4],["Living Essence",2],["Ironweb Spider Silk",2]]},
    {"name":"Runed Stygian Boots","inputs":[["Bolt of Runecloth",4],["Dark Rune",6],["Felcloth",4],["Enchanted Leather",2],["Ironweb Spider Silk",2]]},
    {"name":"Bloodvine Boots","inputs":[["Mooncloth",4],["Ironweb Spider Silk",2]]},
    {"name":"Felcloth Gloves","inputs":[["Bolt of Runecloth",12],["Felcloth",20],["Demonic Rune",6],["Essence of Undeath",8],["Rune Thread",2]]},
    {"name":"Gloves of Spell Mastery","inputs":[["Bolt of Runecloth",10],["Mooncloth",10],["Ghost Dye",10],["Golden Pearl",6],["Huge Emerald",6],["Enchanted Leather",8],["Rune Thread",2]]},
    {"name":"Flarecore Gloves","inputs":[["Bolt of Runecloth",8],["Fiery Core",6],["Essence of Fire",4],["Enchanted Leather",2],["Rune Thread",2]]},
    {"name":"Inferno Gloves","inputs":[["Bolt of Runecloth",12],["Essence of Fire",10],["Star Ruby",2],["Rune Thread",2]]},
    {"name":"Glacial Gloves","inputs":[["Frozen Rune",5],["Bolt of Runecloth",4],["Essence of Water",4],["Ironweb Spider Silk",4]]},
    {"name":"Wizardweave Turban","inputs":[["Bolt of Runecloth",6],["Dream Dust",4],["Star Ruby",1],["Rune Thread",1]]},
    {"name":"Sylvan Crown","inputs":[["Bolt of Runecloth",4],["Mooncloth",2],["Living Essence",2],["Ironweb Spider Silk",2]]},
    {"name":"Runed Stygian Leggings","inputs":[["Bolt of Runecloth",6],["Dark Rune",8],["Felcloth",6],["Ironweb Spider Silk",2]]},
    {"name":"Bloodvine Leggings","inputs":[["Mooncloth",4],["Powerful Mojo",4],["Ironweb Spider Silk",2]]},
    {"name":"Flarecore Leggings","inputs":[["Mooncloth",8],["Fiery Core",5],["Lava Core",3],["Essence of Fire",10],["Ironweb Spider Silk",4]]},
    {"name":"Flarecore Mantle","inputs":[["Bolt of Runecloth",12],["Fiery Core",4],["Lava Core",4],["Enchanted Leather",6],["Rune Thread",2]]},
    {"name":"Felcloth Shoulders","inputs":[["Bolt of Runecloth",7],["Felcloth",3],["Demonic Rune",2],["Rugged Leather",4],["Rune Thread",2]]},
    {"name":"Mantle of the Timbermaw","inputs":[["Mooncloth",5],["Essence of Earth",5],["Living Essence",5],["Ironweb Spider Silk",2]]},
    {"name":"Sylvan Shoulders","inputs":[["Bolt of Runecloth",2],["Living Essence",4],["Ironweb Spider Silk",2]]},
    {"name":"Belt of the Archmage","inputs":[["Bolt of Runecloth",16],["Ghost Dye",10],["Mooncloth",10],["Essence of Water",12],["Essence of Fire",12],["Large Brilliant Shard",6],["Rune Thread",6]]},
    {"name":"Runed Stygian Belt","inputs":[["Bolt of Runecloth",2],["Dark Rune",6],["Felcloth",2],["Enchanted Leather",2],["Ironweb Spider Silk",2]]},
    {"name":"Flarecore Wraps","inputs":[["Mooncloth",6],["Fiery Core",8],["Essence of Fire",2],["Enchanted Leather",6],["Rune Thread",4]]},
    {"name":"Glacial Wrists","inputs":[["Frozen Rune",4],["Bolt of Runecloth",2],["Essence of Water",2],["Ironweb Spider Silk",4]]},
]

EXISTING_SKILL_300 = [
    "Mooncloth Vest", "Mooncloth Shoulders", "Runecloth Shoulders",
    "Mooncloth Circlet", "Mooncloth Gloves", "Cloak of Warding",
    "Argent Shoulders", "Gaea's Embrace", "Glacial Cloak",
]

ALIASES = {
    "Essence of Air": "Elemental Air",
    "Essence of Water": "Elemental Water",
}

DATASET_PRIORITY = ["7259f1d3", "732368d4", "4999dcec", "3eb7e9bb", "538a54a0", "61fdf3df"]

MUST_RESOLVE = {
    "Runecloth", "Rune Thread", "Mooncloth", "Felcloth", "Dream Dust",
    "Elemental Air", "Elemental Water", "Essence of Fire", "Essence of Earth",
    "Essence of Undeath", "Living Essence", "Righteous Orb", "Demonic Rune",
    "Enchanted Leather", "Fiery Core", "Lava Core", "Frozen Rune", "Dark Rune",
    "Golden Pearl", "Huge Emerald", "Star Ruby", "Rugged Leather",
}


def stable_id(prefix, name):
    value = 2166136261
    for byte in (prefix + name).encode("utf-8"):
        value = (value * 16777619 + byte) % 4294967296
    return f"{value:08x}"


def region(source, start_marker, next_marker):
    start = source.index(start_marker)
    end = source.index(next_marker, start)
    return start, end, source[start:end]


def top_level_blocks(table_region):
    blocks = []
    current = None
    for line in table_region.splitlines(keepends=True):
        stripped = line.rstrip("\r\n")
        if stripped == "            {":
            if current is not None:
                raise AssertionError("Nested top-level block parser state")
            current = [line]
        elif current is not None:
            current.append(line)
            if stripped in ("            },", "            }"):
                blocks.append("".join(current))
                current = None
    return blocks


def get_field(block, field):
    match = re.search(rf'^                {re.escape(field)} = "([^"]+)",$', block, re.MULTILINE)
    return match.group(1) if match else None


def parse_items(source, dataset_id):
    try:
        _, _, items_region = region(source, "        items = {", "        loot = {")
    except ValueError:
        return []
    parsed = []
    for block in top_level_blocks(items_region):
        object_id = get_field(block, "id")
        name = get_field(block, "name")
        if object_id and name:
            parsed.append((name, f"{dataset_id}:{object_id}", block))
    return parsed


def parse_recipes(source):
    _, _, recipes_region = region(source, "        recipes = {", "        resources = {")
    parsed = []
    for block in top_level_blocks(recipes_region):
        object_id = get_field(block, "id")
        name = get_field(block, "name")
        if object_id and name:
            parsed.append((name, object_id, block))
    return parsed


text = TAILORING_PATH.read_text(encoding="utf-8")
original = text
items_before_region = region(text, "        items = {", "        loot = {")[2]
pre_collision_recipes = parse_recipes(text)

# Fix the one concrete pre-existing collision. TBC Red Woolen Boots is skill 95
# and uses Wool Cloth + Light Leather + Fine Thread + Red Dye. The skill-100
# 74yqa5j0 record is a mislabeled duplicate with Blue Dye and must be removed.
red_woolen = [entry for entry in pre_collision_recipes if entry[0] == "Red Woolen Boots"]
assert len(red_woolen) == 2, f"Expected two Red Woolen Boots recipes, found {len(red_woolen)}"
assert {entry[1] for entry in red_woolen} == {"vxy1029k", "74yqa5j0"}
valid_red = next(entry for entry in red_woolen if entry[1] == "vxy1029k")
bad_red = next(entry for entry in red_woolen if entry[1] == "74yqa5j0")
assert 'requiredSkillLevel = 95' in valid_red[2]
assert 'itemRef = "538a54a0:sm9q37oi"' in valid_red[2]
assert 'itemRef = "7259f1d3:oo8796rr"' in valid_red[2]
assert 'requiredSkillLevel = 100' in bad_red[2]
assert 'itemRef = "7259f1d3:nfwx3196"' in bad_red[2]
text = text.replace(bad_red[2], "", 1)

recipes_before = parse_recipes(text)
before_names = [entry[0] for entry in recipes_before]
before_ids = [entry[1] for entry in recipes_before]
assert len(recipes_before) == len(pre_collision_recipes) - 1
assert len(before_names) == len(set(before_names)), "Recipe-name collision remains after Red Woolen Boots correction"
assert len(before_ids) == len(set(before_ids)), "Pre-existing Tailoring recipe IDs are not unique"
assert before_names.count("Red Woolen Boots") == 1
assert next(entry[1] for entry in recipes_before if entry[0] == "Red Woolen Boots") == "vxy1029k"

# Build packaged item reference index from current source files.
item_refs_by_name = {}
all_item_refs = set()
for candidate in sorted(Path("data/default").rglob("*.lua")):
    source = candidate.read_text(encoding="utf-8")
    dataset_match = re.search(r'^        id = "([^"]+)",$', source, re.MULTILINE)
    if not dataset_match:
        continue
    dataset_id = dataset_match.group(1)
    for name, ref, _ in parse_items(source, dataset_id):
        item_refs_by_name.setdefault(name, []).append(ref)
        all_item_refs.add(ref)


def resolve_item(name):
    refs = item_refs_by_name.get(name, [])
    if not refs:
        return None
    by_dataset = {ref.split(":", 1)[0]: ref for ref in refs}
    for dataset_id in DATASET_PRIORITY:
        if dataset_id in by_dataset:
            return by_dataset[dataset_id]
    return sorted(refs)[0]


for required_name in sorted(MUST_RESOLVE):
    assert resolve_item(required_name), f"Expected packaged reagent does not resolve: {required_name}"

assert len(RECIPES) == 30
assert len({recipe["name"] for recipe in RECIPES}) == 30

# Capture current #191 output refs, then ensure none of the 30 recipes already exists.
tailoring_item_refs = {name: ref for name, ref, _ in parse_items(text, TAILORING_ID)}
for recipe in RECIPES:
    assert recipe["name"] in tailoring_item_refs, f"Missing #191 output item: {recipe['name']}"
    assert recipe["name"] not in before_names, f"Recipe already exists: {recipe['name']}"
for name in EXISTING_SKILL_300:
    assert before_names.count(name) == 1, f"Expected existing skill-300 recipe exactly once: {name}"

new_ids = {recipe["name"]: stable_id("recipe:", recipe["name"]) for recipe in RECIPES}
assert len(set(new_ids.values())) == 30
for name, recipe_id in new_ids.items():
    assert recipe_id not in before_ids, f"Generated recipe ID collision: {name} -> {recipe_id}"

# Normalize and resolve inputs. Missing packaged materials are intentionally omitted.
resolved_inputs = {}
omitted = {}
for recipe in RECIPES:
    aggregate = {}
    order = []
    missing = []
    for source_name, source_qty in recipe["inputs"]:
        normalized_name = source_name
        quantity = int(source_qty)
        if normalized_name == "Bolt of Runecloth":
            normalized_name = "Runecloth"
            quantity *= 5
        normalized_name = ALIASES.get(normalized_name, normalized_name)
        ref = resolve_item(normalized_name)
        if not ref:
            missing.append((source_name, int(source_qty)))
            continue
        if ref not in aggregate:
            aggregate[ref] = 0
            order.append(ref)
        aggregate[ref] += quantity
    resolved_inputs[recipe["name"]] = [(ref, aggregate[ref]) for ref in order]
    if missing:
        omitted[recipe["name"]] = missing

felcloth_ref = resolve_item("Felcloth")
assert felcloth_ref == "7259f1d3:8dc72367", felcloth_ref
for recipe in RECIPES:
    if any(name == "Felcloth" for name, _ in recipe["inputs"]):
        assert any(ref == felcloth_ref for ref, _ in resolved_inputs[recipe["name"]]), f"Felcloth lost from {recipe['name']}"

print("Omitted unavailable packaged reagents:")
if omitted:
    for recipe_name in sorted(omitted):
        print("  " + recipe_name + ": " + ", ".join(f"{qty} {name}" for name, qty in omitted[recipe_name]))
else:
    print("  none")


def render_recipe(recipe):
    name = recipe["name"]
    lines = [
        "            {",
        '                category = "",',
        '                description = "",',
        f'                id = "{new_ids[name]}",',
        "                inputs = {",
    ]
    for ref, qty in resolved_inputs[name]:
        lines.extend([
            "                    {",
            f'                        itemRef = "{ref}",',
            '                        kind = "rpe_item",',
            f"                        quantity = {qty},",
            "                    },",
        ])
    lines.extend([
        "                },",
        '                learnMode = "trainer",',
        f"                name = {json.dumps(name)},",
        "                output = {",
        f'                    itemRef = "{tailoring_item_refs[name]}",',
        "                    maxQuantity = 1,",
        "                    minQuantity = 1,",
        "                },",
        "                reagents = {},",
        "                requiredSkillLevel = 300,",
        "                results = {},",
        f'                skillRef = "{SKILL_REF}",',
        "                tags = {},",
        f"                trainerCostCopper = {TRAINER_COST},",
        "            },",
    ])
    return "\n".join(lines) + "\n"

recipes_start, _, recipes_region = region(text, "        recipes = {", "        resources = {")
closing = recipes_region.rfind("        },\n")
assert closing >= 0, "Could not locate recipes table closing"
insert_at = recipes_start + closing
text = text[:insert_at] + "".join(render_recipe(recipe) for recipe in RECIPES) + text[insert_at:]

version_pattern = re.compile(r'^    version = (\d+),$', re.MULTILINE)
assert version_pattern.findall(text) == ["4"], f"Expected Tailoring v4 before #192, found {version_pattern.findall(text)}"
text, replaced = version_pattern.subn("    version = 5,", text, count=1)
assert replaced == 1

# Final deterministic validation.
assert region(text, "        items = {", "        loot = {")[2] == items_before_region, "#192 changed item data"
recipes_after = parse_recipes(text)
after_names = [entry[0] for entry in recipes_after]
after_ids = [entry[1] for entry in recipes_after]
after_by_name = {entry[0]: entry[2] for entry in recipes_after}
assert len(recipes_after) == len(recipes_before) + 30, (len(recipes_before), len(recipes_after))
assert len(after_names) == len(set(after_names)), "Duplicate Tailoring recipe names remain"
assert len(after_ids) == len(set(after_ids)), "Duplicate Tailoring recipe IDs remain"
assert after_names.count("Red Woolen Boots") == 1
assert next(entry[1] for entry in recipes_after if entry[0] == "Red Woolen Boots") == "vxy1029k"

# Every surviving pre-existing recipe is byte-identical.
for old_name, old_id, old_block in recipes_before:
    matches = [entry for entry in recipes_after if entry[0] == old_name]
    assert len(matches) == 1, f"Existing recipe missing/duplicated: {old_name}"
    assert matches[0][1] == old_id, f"Existing recipe ID changed: {old_name}"
    assert matches[0][2] == old_block, f"Existing recipe content changed: {old_name}"

for name in EXISTING_SKILL_300:
    assert after_names.count(name) == 1

for recipe in RECIPES:
    name = recipe["name"]
    block = after_by_name[name]
    assert after_names.count(name) == 1
    assert f'id = "{new_ids[name]}"' in block
    assert 'learnMode = "trainer"' in block and 'learnMode = "book"' not in block
    assert 'requiredSkillLevel = 300' in block
    assert f'skillRef = "{SKILL_REF}"' in block
    assert f'trainerCostCopper = {TRAINER_COST}' in block
    assert f'itemRef = "{tailoring_item_refs[name]}"' in block
    assert "maxQuantity = 1" in block and "minQuantity = 1" in block
    assert "Bolt of Runecloth" not in block
    for ref, qty in resolved_inputs[name]:
        assert ref in all_item_refs, f"Unresolved retained input ref: {name}: {ref}"
        assert f'itemRef = "{ref}"' in block
        assert f"quantity = {qty}" in block
    if any(source_name == "Felcloth" for source_name, _ in recipe["inputs"]):
        assert f'itemRef = "{felcloth_ref}"' in block

assert version_pattern.findall(text) == ["5"]
TAILORING_PATH.write_text(text, encoding="utf-8")
print(f"Validated #192: {len(pre_collision_recipes)} original recipes; removed 1 erroneous duplicate; {len(recipes_after)} final recipes; added 30 trainer skill-300 recipes; version 4 -> 5")
