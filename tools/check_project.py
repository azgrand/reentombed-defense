"""Offline structural checks. Runtime verification uses tests/run_tests.gd."""
import json
from pathlib import Path
import re
import wave

root = Path(__file__).resolve().parents[1]
balance = json.loads((root / "data/balance.json").read_text())
for key in ("starting_gold", "starting_lives", "waves", "wave_bonus"):
    assert isinstance(balance[key], int) and balance[key] > 0, key
assert len(balance["towers"]) == 3
assert len({tower["id"] for tower in balance["towers"]}) == 3
for tower in balance["towers"]:
    for key in ("cost", "damage", "range", "cooldown"):
        assert tower[key] > 0, (tower["id"], key)
    assert 0 < tower["slow"] <= 1
    assert tower["splash"] >= 0
    assert re.fullmatch(r"[a-fA-F0-9]{6}", tower["color"])
for source in list(root.rglob("*.gd")) + [root / "project.godot", root / "scenes/main.tscn"]:
    for resource in re.findall(r'res://([^"\n]+)', source.read_text()):
        assert (root / resource).is_file(), (source, resource)
for name in ("build", "wave"):
    with wave.open(str(root / "assets/audio" / f"{name}.wav")) as audio:
        assert audio.getnframes() > 0 and audio.getnchannels() == 1
print("OK: balance, resource references, audio")
