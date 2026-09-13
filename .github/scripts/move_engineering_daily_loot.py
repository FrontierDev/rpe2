from pathlib import Path
import re

engineering_path = Path('data/default/professions/engineering.lua')
toc_path = Path('RPEngine_Dev.toc')
helper_path = Path('data/default/professions/engineering_daily_rewards.lua')

entries = [
    ('copper_bar', '61fdf3df:nntycdj5', 20, 6, 10),
    ('rough_stone', '61fdf3df:c7urqe23', 20, 6, 10),
    ('bronze_bar', '61fdf3df:xegz4i5q', 18, 6, 10),
    ('coarse_stone', '61fdf3df:qcah9yrg', 18, 6, 10),
    ('heavy_stone', '61fdf3df:u8qtuhfq', 16, 5, 8),
    ('steel_bar', '61fdf3df:ov027km6', 14, 4, 7),
    ('solid_stone', '61fdf3df:o1ogtdcq', 14, 4, 7),
    ('mithril_bar', '61fdf3df:225h536c', 12, 4, 7),
    ('dense_stone', '61fdf3df:a4kj24o4', 12, 4, 7),
    ('thorium_bar', '61fdf3df:5m4zt99z', 10, 3, 5),
    ('silver_bar', '61fdf3df:nvc1anz9', 4, 1, 2),
    ('gold_bar', '61fdf3df:hqook9xe', 3, 1, 2),
    ('truesilver_bar', '61fdf3df:ufv4fdnf', 2, 1, 2),
    ('dark_iron_bar', '61fdf3df:pb24e7k5', 1, 1, 2),
    ('arcanite_bar', '61fdf3df:6hy57ood', 1, 1, 1),
]

entry_lines = [
    f'                    {{ id = "{entry_id}", maxQuantity = {max_q}, minQuantity = {min_q}, ref = "{ref}", type = "item", weight = {weight} }},'
    for entry_id, ref, weight, min_q, max_q in entries
]

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
print(f'Serialized {len(entries)} Engineering Daily Material Cache entries into engineering.lua')
print('Removed engineering_daily_rewards.lua and TOC entry')
