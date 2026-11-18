"""Check native PO key/placeholder parity and constant tr() references."""
import ast
from pathlib import Path
import re
ROOT = Path(__file__).resolve().parents[1]
def catalogue(locale):
    entries = {}
    key = None
    for line in (ROOT / 'localization' / f'{locale}.po').read_text().splitlines():
        if line.startswith('msgid '):
            key = ast.literal_eval(line[6:])
        if line.startswith('msgstr ') and key:
            entries[key] = ast.literal_eval(line[7:])
    return entries

def check():
    en, es = catalogue('en'), catalogue('es')
    assert en.keys() == es.keys(), 'Locale key mismatch'
    for key in en:
        assert en[key] and es[key], ('Empty translation', key)
        assert set(re.findall(r'\{(\w+)\}', en[key])) == set(re.findall(r'\{(\w+)\}', es[key])), key
    for source in (ROOT / 'scripts').rglob('*.gd'):
        for key in re.findall(r'\btr\("([\w.]+)"\)', source.read_text()):
            assert key in en, (source, key)
    print(f'OK: {len(en)} translation keys; placeholders and references')
if __name__ == '__main__':
    check()
