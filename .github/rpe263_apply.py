from pathlib import Path
import math
import re

ENG = Path("data/default/professions/engineering.lua")

def read(path):
    return Path(path).read_text()

def item_section(text):
    start = text.index("        items = {")
    end = text.index("        recipes = {", start)
    return text[start:end]

def find_item_ref(path, dataset_id, name):
    text = read(path)
    section = item_section(text)
    needle = f'name = "{name}"'
    pos = section.find(needle)
    if pos < 0:
        raise SystemExit(f"Missing canonical item {name!r} in {path}")
    ids = list(re.finditer(r'id = "([^"]+)"', section[:pos]))
    if not ids:
        raise SystemExit(f"Could not resolve id for {name!r} in {path}")
    return f"{dataset_id}:{ids[-1].group(1)}"

def inp(ref, qty, kind="rpe_item"):
    return {"itemRef": ref, "quantity": qty, "kind": kind}

def trainer_cost(skill):
    return math.floor(75 + skill * 28 + skill * skill * 1.6)

def render_inputs(inputs):
    rows = []
    for entry in inputs:
        rows.append(f'''                    {{
                        itemRef = "{entry["itemRef"]}",
                        kind = "{entry["kind"]}",
                        quantity = {entry["quantity"]},
                    }},''')
    return "\n".join(rows)

def render_recipe(r):
    return f'''            {{
                category = "",
                description = "",
                id = "{r["id"]}",
                inputs = {{
{render_inputs(r["inputs"])}
                }},
                learnMode = "trainer",
                name = "{r["name"]}",
                output = {{
                    itemRef = "{r["output"]}",
                    maxQuantity = {r["qty"]},
                    minQuantity = {r["qty"]},
                }},
                reagents = {{}},
                requiredSkillLevel = {r["skill"]},
                results = {{}},
                skillRef = "f82db71a:xprqs3y1",
                tags = {{}},
                trainerCostCopper = {trainer_cost(r["skill"])},
            }},
'''

text = ENG.read_text()
if "    version = 11," not in text:
    raise SystemExit("Expected Engineering packaged version 11 before #263")
if "name = \"Ice Deflector\"" in item_section(text):
    raise SystemExit("Ice Deflector item already exists unexpectedly; re-read current dev")
if "name = \"Goblin Sapper Charge\"" in item_section(text):
    raise SystemExit("Goblin Sapper Charge item already exists unexpectedly; re-read current dev")

item_block = r'''            {
                bindingFlag = "none",
                canDisenchant = false,
                canSell = true,
                canStack = true,
                canTrade = true,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 21,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                },
                consumableType = "potion",
                description = "",
                icon = "interface/icons/inv_gizmo_01.blp",
                id = "m5n0v6wt",
                itemLevel = 31,
                itemType = "consumable",
                maxStackSize = 5,
                name = "Ice Deflector",
                quality = "common",
                stats = {},
                tags = {},
                useSpellRef = "af503002:72d1a295",
            },
            {
                bindingFlag = "none",
                canDisenchant = false,
                canSell = true,
                canStack = true,
                canTrade = true,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 205,
                        showOnTooltip = true,
                        skillRef = "f82db71a:xprqs3y1",
                        tooltipTextOverride = "",
                        type = "skill_requirement",
                    },
                },
                description = "",
                icon = "interface/icons/spell_fire_selfdestruct.blp",
                id = "wl90lopn",
                itemLevel = 41,
                itemType = "consumable",
                maxStackSize = 10,
                name = "Goblin Sapper Charge",
                quality = "common",
                stats = {},
                tags = {},
                useSpellRef = "af503002:bf6ad9eb",
            },
'''
anchor = "        },\n        recipes = {"
if anchor not in text:
    raise SystemExit("Could not locate Engineering item/recipe boundary")
text = text.replace(anchor, item_block + anchor, 1)

aura_block = r'''            {
                description = "",
                duration = 1,
                effects = {
                    {
                        cancelOnDamage = true,
                        forceAutoHitAgainstTarget = false,
                        movementRangeOverride = 0,
                        preventCasting = true,
                        statScaling = {},
                        type = "control",
                    },
                },
                events = {},
                icon = "interface/icons/inv_misc_bomb_04.blp",
                id = "6f878885",
                maxStacks = 1,
                name = "Flash Bomb Incapacitation",
                stackBehavior = "refresh_duration",
                tags = {},
            },
'''
aura_anchor = "        },\n        authorName = "
if aura_anchor not in text:
    raise SystemExit("Could not locate Engineering aura boundary")
text = text.replace(aura_anchor, aura_block + aura_anchor, 1)

spell_block = r'''            {
                castTime = 0,
                charges = 0,
                components = {
                    {
                        castPhase = "on_cast_end",
                        castingGroup = "default",
                        effect = {
                            auraRef = "af503002:6f878885",
                            basePower = 0,
                            duration = 1,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura",
                        },
                        key = "flash-bomb-incapacitation",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 5,
                            minTargets = 1,
                            requiresTarget = true,
                            targetDisposition = "enemy",
                            type = "multi",
                        },
                    },
                },
                conditions = {},
                cooldown = 5,
                cooldownGroup = "engineering_explosive",
                description = "",
                icon = "interface/icons/inv_misc_bomb_04.blp",
                id = "895b5752",
                ignoreGCD = true,
                learnMode = "unavailable",
                name = "Flash Bomb",
                range = 20,
                resourceCosts = {},
                tags = {},
                triggersGCD = false,
            },
'''
spell_anchor = "        },\n        stats = {},"
if spell_anchor not in text:
    raise SystemExit("Could not locate Engineering spell boundary")
text = text.replace(spell_anchor, spell_block + spell_anchor, 1)

flash_old = '''                name = "Flash Bomb",
                quality = "common",
                stats = {},
                tags = {},
            },'''
flash_new = '''                name = "Flash Bomb",
                quality = "common",
                stats = {},
                tags = {},
                useSpellRef = "af503002:895b5752",
            },'''
if flash_old not in text:
    raise SystemExit("Could not locate Flash Bomb item for useSpellRef correction")
text = text.replace(flash_old, flash_new, 1)

dep_old = '''            "732368d4",
            "3eb7e9bb",'''
dep_new = '''            "732368d4",
            "d6ffc4e2",
            "3eb7e9bb",'''
if dep_old not in text:
    raise SystemExit("Could not locate dependency insertion point")
text = text.replace(dep_old, dep_new, 1)

ENG.write_text(text)

BS = "data/default/professions/blacksmithing.lua"
TAILOR = "data/default/professions/tailoring.lua"
LEATHER = "data/default/professions/leatherworking.lua"
JC = "data/default/professions/jewelcrafting.lua"
ENCH = "data/default/professions/enchanting.lua"
ALCH = "data/default/professions/alchemy.lua"
MISC = "data/default/professions/misc.lua"

R = {}
def add(key, path, dataset, name):
    R[key] = find_item_ref(path, dataset, name)

for key, name in [
    ("Bronze Bar", "Bronze Bar"), ("Heavy Stone", "Heavy Stone"), ("Solid Stone", "Solid Stone"),
    ("Iron Bar", "Iron Bar"), ("Silver Bar", "Silver Bar"), ("Gold Bar", "Gold Bar"),
    ("Mithril Bar", "Mithril Bar"), ("Truesilver Bar", "Truesilver Bar"), ("Blacksmith Hammer", "Blacksmith Hammer"),
]:
    add(key, BS, "61fdf3df", name)

for key, name in [("Silk Cloth", "Silk Cloth"), ("Mageweave Cloth", "Mageweave Cloth"), ("Black Mageweave Boots", "Black Mageweave Boots")]:
    add(key, TAILOR, "7259f1d3", name)
for key, name in [("Heavy Leather", "Heavy Leather"), ("Thick Leather", "Thick Leather"), ("Dusky Belt", "Dusky Belt")]:
    add(key, LEATHER, "538a54a0", name)
for key, name in [("Iridescent Pearl", "Iridescent Pearl"), ("Citrine", "Citrine"), ("Aquamarine", "Aquamarine"), ("Star Ruby", "Star Ruby")]:
    add(key, JC, "4999dcec", name)
add("Elemental Fire", ENCH, "732368d4", "Elemental Fire")
for key, name in [("Frost Oil", "Frost Oil"), ("Catseye Elixir", "Catseye Elixir"), ("Goblin Rocket Fuel", "Goblin Rocket Fuel")]:
    add(key, ALCH, "d6ffc4e2", name)
for key, name in [("Elemental Earth", "Elemental Earth"), ("Heavy Stock", "Heavy Stock"), ("Flask of Mojo", "Flask of Mojo")]:
    add(key, MISC, "3eb7e9bb", name)

eng_text = ENG.read_text()
def engref(name):
    section = item_section(eng_text)
    pos = section.find(f'name = "{name}"')
    if pos < 0:
        raise SystemExit(f"Missing Engineering output Item: {name}")
    ids = list(re.finditer(r'id = "([^"]+)"', section[:pos]))
    if not ids:
        raise SystemExit(f"Could not resolve Engineering output id: {name}")
    return "af503002:" + ids[-1].group(1)

recipe_specs = [
    ("34066869", "Ice Deflector", 155, [inp(R["Bronze Bar"],1), inp(R["Frost Oil"],1), inp(R["Blacksmith Hammer"],1,"tool")], 1),
    ("fbcc7f90", "Solid Dynamite", 175, [inp(R["Solid Stone"],1), inp(R["Silk Cloth"],1)], 2),
    ("665b495f", "Iron Grenade", 175, [inp(R["Iron Bar"],1), inp(R["Heavy Stone"],1), inp(R["Silk Cloth"],1), inp(R["Blacksmith Hammer"],1,"tool")], 2),
    ("da28030f", "Bright-Eye Goggles", 175, [inp(R["Heavy Leather"],6), inp(R["Citrine"],2)], 1),
    ("d31efc7a", "Craftsman's Monocle", 185, [inp(R["Heavy Leather"],6), inp(R["Citrine"],2)], 1),
    ("5578c6c3", "Flash Bomb", 185, [inp(R["Iridescent Pearl"],1), inp(R["Heavy Stone"],1), inp(R["Silk Cloth"],1)], 1),
    ("69ea43fe", "Big Iron Bomb", 190, [inp(R["Iron Bar"],3), inp(R["Heavy Stone"],3), inp(R["Silver Bar"],1), inp(R["Blacksmith Hammer"],1,"tool")], 2),
    ("826078e3", "EZ-Thro Dynamite II", 200, [inp(R["Solid Stone"],1), inp(R["Mageweave Cloth"],2)], 1),
    ("44f961b2", "Fire Goggles", 205, [inp(engref("Green Tinted Goggles"),1), inp(R["Citrine"],2), inp(R["Elemental Fire"],2), inp(R["Heavy Leather"],4)], 1),
    ("5603ab3c", "Goblin Construction Helmet", 205, [inp(R["Mithril Bar"],8), inp(R["Citrine"],1), inp(R["Elemental Fire"],4), inp(R["Blacksmith Hammer"],1,"tool")], 1),
    ("70e2f131", "Goblin Mining Helmet", 205, [inp(R["Mithril Bar"],8), inp(R["Citrine"],1), inp(R["Elemental Earth"],4), inp(R["Blacksmith Hammer"],1,"tool")], 1),
    ("a551d40c", "Mithril Blunderbuss", 205, [inp(R["Mithril Bar"],6), inp(R["Heavy Stock"],1), inp(R["Elemental Fire"],2), inp(R["Blacksmith Hammer"],1,"tool")], 1),
    ("7dc38d50", "Goblin Sapper Charge", 205, [inp(R["Mageweave Cloth"],1), inp(R["Solid Stone"],3), inp(R["Mithril Bar"],1)], 1),
    ("7bdbd25d", "Gnomish Goggles", 210, [inp(engref("Fire Goggles"),1), inp(R["Mithril Bar"],1), inp(R["Gold Bar"],2), inp(R["Flask of Mojo"],2), inp(R["Heavy Leather"],2)], 1),
    ("eaef4861", "Hi-Impact Mithril Slugs", 210, [inp(R["Mithril Bar"],1), inp(R["Solid Stone"],1), inp(R["Blacksmith Hammer"],1,"tool")], 200),
    ("60693f42", "Mithril Frag Bomb", 215, [inp(R["Mithril Bar"],2), inp(R["Solid Stone"],1), inp(R["Blacksmith Hammer"],1,"tool")], 3),
    ("13c28e4f", "Gnomish Harm Prevention Belt", 215, [inp(R["Dusky Belt"],1), inp(R["Mithril Bar"],5), inp(R["Truesilver Bar"],2), inp(R["Aquamarine"],2)], 1),
    ("1f3cd8f3", "Catseye Ultra Goggles", 220, [inp(R["Thick Leather"],4), inp(R["Aquamarine"],2), inp(R["Catseye Elixir"],1)], 1),
    ("5dfaa6f0", "Mithril Heavy-bore Rifle", 220, [inp(R["Mithril Bar"],9), inp(R["Heavy Stock"],1), inp(R["Citrine"],2), inp(R["Blacksmith Hammer"],1,"tool")], 1),
    ("39572a4c", "Gnomish Rocket Boots", 225, [inp(R["Black Mageweave Boots"],1), inp(R["Mithril Bar"],2), inp(R["Heavy Leather"],4), inp(R["Solid Stone"],8), inp(R["Gold Bar"],4), inp(R["Blacksmith Hammer"],1,"tool")], 1),
    ("768fba20", "Goblin Rocket Boots", 225, [inp(R["Black Mageweave Boots"],1), inp(R["Mithril Bar"],3), inp(R["Heavy Leather"],4), inp(R["Goblin Rocket Fuel"],2), inp(R["Blacksmith Hammer"],1,"tool")], 1),
    ("00b5af75", "Parachute Cloak", 225, [inp(R["Mageweave Cloth"],4), inp(R["Silk Cloth"],2), inp(R["Mithril Bar"],1), inp(R["Solid Stone"],4)], 1),
    ("d5faea67", "Spellpower Goggles Xtreme", 225, [inp(R["Thick Leather"],4), inp(R["Star Ruby"],2)], 1),
]

eng_text = ENG.read_text()
recipe_section_start = eng_text.index("        recipes = {")
recipe_section_end = eng_text.index("        skills = {}", recipe_section_start)
existing_recipes = eng_text[recipe_section_start:recipe_section_end]
for _, name, _, _, _ in recipe_specs:
    if f'name = "{name}"' in existing_recipes:
        raise SystemExit(f"Recipe already exists on current dev: {name}")

recipes = [{"id":rid,"name":name,"skill":skill,"inputs":inputs,"qty":qty,"output":engref(name)} for rid,name,skill,inputs,qty in recipe_specs]
recipe_block = "".join(render_recipe(r) for r in recipes)
recipe_anchor = "        },\n        skills = {},"
if recipe_anchor not in eng_text:
    raise SystemExit("Could not locate Engineering recipe/skills boundary")
eng_text = eng_text.replace(recipe_anchor, recipe_block + recipe_anchor, 1)
eng_text = eng_text.replace("    version = 11,", "    version = 12,", 1)
ENG.write_text(eng_text)

final = ENG.read_text()
assert final.count('Addon.Data.DefaultDatasets:Register({') == 1
assert "    version = 12," in final
items_final = item_section(final)
recipes_final = final[final.index("        recipes = {"):final.index("        skills = {}")]
spells_final = final[final.index("        spells = {"):final.index("        stats = {}", final.index("        spells = {"))]
auras_final = final[final.index("        auras = {"):final.index("        authorName =", final.index("        auras = {"))]
for name in [r[1] for r in recipe_specs]:
    assert recipes_final.count(f'name = "{name}"') == 1, name
    assert items_final.count(f'name = "{name}"') == 1, name
assert 'useSpellRef = "af503002:72d1a295"' in items_final
assert 'useSpellRef = "af503002:bf6ad9eb"' in items_final
assert 'useSpellRef = "af503002:895b5752"' in items_final
assert auras_final.count('name = "Flash Bomb Incapacitation"') == 1
assert spells_final.count('name = "Flash Bomb"') == 1
assert R["Iridescent Pearl"].startswith("4999dcec:")
assert "Blue Pearl" not in final
assert "Shadow Silk" not in recipes_final
assert '"d6ffc4e2",' in final
for r in recipes:
    assert 150 < r["skill"] <= 225
    assert f'trainerCostCopper = {trainer_cost(r["skill"])}' in recipes_final
slice_start = recipes_final.find('id = "34066869"')
new_slice = recipes_final[slice_start:]
tool_refs = re.findall(r'itemRef = "([^"]+)"\s*,\n\s*kind = "tool"', new_slice)
assert tool_refs and set(tool_refs) == {R["Blacksmith Hammer"]}, set(tool_refs)
print("Validated #263 recipe count:", len(recipes))
print("Pearl ref:", R["Iridescent Pearl"])
print("Engineering version: 12")
