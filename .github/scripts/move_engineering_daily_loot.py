from pathlib import Path
import re


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

refs = {}
refs.update(extract_items(Path('data/default/professions/blacksmithing.lua'), '61fdf3df'))
refs.update(extract_items(Path('data/default/professions/misc.lua'), '3eb7e9bb'))
for name in sorted(name for name in refs if name.endswith(' Bar') or name.endswith(' Stone')):
    print(f'{name} = {refs[name]}')

raise RuntimeError('diagnostic-only run')
