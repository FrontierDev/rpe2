from pathlib import Path

path = Path('.github/rpe263_apply.py')
text = path.read_text()
old = '''R = {}
def add(key, path, dataset, name):
    R[key] = find_item_ref(path, dataset, name)

for key, name in [
    ("Bronze Bar", "Bronze Bar"), ("Heavy Stone", "Heavy Stone"), ("Solid Stone", "Solid Stone"),
    ("Iron Bar", "Iron Bar"), ("Silver Bar", "Silver Bar"), ("Gold Bar", "Gold Bar"),
    ("Mithril Bar", "Mithril Bar"), ("Truesilver Bar", "Truesilver Bar"), ("Blacksmith Hammer", "Blacksmith Hammer"),
]:
    add(key, BS, "61fdf3df", name)
'''
new = '''R = {
    "Bronze Bar": "61fdf3df:xegz4i5q",
    "Heavy Stone": "61fdf3df:u8qtuhfq",
    "Solid Stone": "61fdf3df:o1ogtdcq",
    "Iron Bar": "61fdf3df:h4i9b6wc",
    "Silver Bar": "61fdf3df:nvc1anz9",
    "Gold Bar": "61fdf3df:j6g2b8ye",
    "Mithril Bar": "61fdf3df:i5m1b7xd",
    "Truesilver Bar": "61fdf3df:k7t3b9zf",
    "Blacksmith Hammer": "61fdf3df:518sbr8g",
}
def add(key, path, dataset, name):
    R[key] = find_item_ref(path, dataset, name)
'''
if old not in text:
    raise SystemExit('Expected Blacksmithing resolver block not found')
path.write_text(text.replace(old, new, 1))
