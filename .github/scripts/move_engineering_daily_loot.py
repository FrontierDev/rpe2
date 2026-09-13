from pathlib import Path
import re

engineering_path = Path('data/default/professions/engineering.lua')
toc_path = Path('RPEngine_Dev.toc')
helper_path = Path('data/default/professions/engineering_daily_rewards.lua')


def find_matching_brace(text, open_pos):
    depth = 0
    in_string = False
    escape = False
    for index in range(open_pos, len(text)):
        ch = text[index]
        if in_string:
            if escape:
                escape = False
            elif ch == '\\':
                escape = True
            elif ch == '"':
                in_string = False
            continue
        if ch == '"':
            in_string = True
        elif ch == '{':
            depth += 1
        elif ch == '}':
            depth -= 1
            if depth == 0:
                return index
    raise RuntimeError('Unmatched brace')


def extract_items(path, dataset_id):
    source = path.read_text(encoding='utf-8')
    marker = '        items = {'
    start = source.index(marker)
    open_pos = source.index('{', start)
    close_pos = find_matching_brace(source, open_pos)
    body = source[open_pos + 1:close_pos]
    result = {}
    index = 0
    while index < len(body):
        if body[index] != '{':
            index += 1
            continue
        end = find_matching_brace(body, index)
        entry = body[index:end + 1]
        id_match = re.search(r'\n\s*id = "([^"]+)",', entry)
        name_match = re.search(r'\n\s*name = "([^"]+)",', entry)
        if id_match and name_match:
            result[name_match.group(1)] = f'{dataset_id}:{id_match.group(1)}'
        index = end + 1
    return result


material_definitions = [
    ('copper_bar', 'Copper Bar', 20, 6, 10),
    ('rough_stone', 'Rough Stone', 20, 6, 10),
    ('bronze_bar', 'Bronze Bar', 18, 6, 10),
    ('coarse_stone', 'Coarse Stone', 18, 6, 10),
    ('iron_bar', 'Iron Bar', 16, 5, 8),
    ('heavy_stone', 'Heavy Stone', 16, 5, 8),
    ('steel_bar', 'Steel Bar', 14, 4, 7),
    ('solid_stone', 'Solid Stone', 14, 4, 7),
    ('mithril_bar', 'Mithril Bar', 12, 4, 7),
    ('dense_stone', 'Dense Stone', 12, 4, 7),
    ('thorium_bar', 'Thorium Bar', 10, 3, 5),
    ('silver_bar', 'Silver Bar', 4, 1, 2),
    ('gold_bar', 'Gold Bar', 3, 1, 2),
    ('truesilver_bar', 'Truesilver Bar', 2, 1, 2),
    ('dark_iron_bar', 'Dark Iron Bar', 1, 1, 2),
    ('arcanite_bar', 'Arcanite Bar', 1, 1, 1),
]

refs_by_name = {}
refs_by_name.update(extract_items(Path('data/default/professions/blacksmithing.lua'), '61fdf3df'))
refs_by_name.update(extract_items(Path('data/default/professions/misc.lua'), '3eb7e9bb'))

entry_lines = []
for entry_id, name, weight, min_quantity, max_quantity in material_definitions:
    ref = refs_by_name.get(name)
    if not ref:
        raise RuntimeError(f'Could not resolve explicit Engineering cache material: {name}')
    entry_lines.append(
        f'                    {{ id = "{entry_id}", maxQuantity = {max_quantity}, minQuantity = {min_quantity}, ref = "{ref}", type = "item", weight = {weight} }},'
    )
    print(f'{name}: {ref} weight={weight} quantity={min_quantity}-{max_quantity}')

loot_block = '''        loot = {
            {
                conditions = {},
                description = "Daily Engineering material cache. Guarantees one explicitly weighted metal bar or mining stone reward, with common low-tier materials more frequent and valuable high-tier bars progressively rarer.",
                drawCount = 1,
                entries = {
%s
                },
                icon = "interface/icons/inv_gizmo_03.blp",
                id = "n6r3k8vz",
                items = {},
                name = "Engineering Daily Material Cache",
                tags = {},
            },
        },''' % '\n'.join(entry_lines)

text = engineering_path.read_text(encoding='utf-8')
if 'name = "Engineering Daily Material Cache"' in text:
    raise RuntimeError('Engineering Daily Material Cache is already serialized')
marker = '        },\n        recipes = {'
count = text.count(marker)
if count != 1:
    raise RuntimeError(f'Expected exactly one items-to-recipes boundary, found {count}')
text = text.replace(marker, '        },\n' + loot_block + '\n        recipes = {', 1)

version_match = re.search(r'Addon\.Data\.DefaultDatasets:Register\(\{\s*\n\s*version = (\d+),', text)
if not version_match:
    raise RuntimeError('Engineering dataset version not found')
old_version = int(version_match.group(1))
new_version = max(30, old_version + 1)
text = text[:version_match.start(1)] + str(new_version) + text[version_match.end(1):]
engineering_path.write_text(text, encoding='utf-8')

toc = toc_path.read_text(encoding='utf-8')
helper_line = 'data/default/professions/engineering_daily_rewards.lua\n'
if helper_line not in toc:
    raise RuntimeError('Engineering daily rewards helper is not listed in TOC')
toc_path.write_text(toc.replace(helper_line, '', 1), encoding='utf-8')

if not helper_path.exists():
    raise RuntimeError('Engineering daily rewards helper file is missing')
helper_path.unlink()

print(f'Engineering dataset version: {old_version} -> {new_version}')
print('Serialized Engineering Daily Material Cache into engineering.lua')
print('Removed engineering_daily_rewards.lua and TOC entry')
