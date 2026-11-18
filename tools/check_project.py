"""Offline structural checks. Runtime verification uses tests/run_tests.gd."""
import json
from pathlib import Path
import re
import wave

root = Path(__file__).resolve().parents[1]
balance = json.loads((root / "data/balance.json").read_text())
for key in ("starting_gold", "starting_lives", "waves", "wave_bonus"):
    assert isinstance(balance[key], int) and balance[key] > 0, key
assert len(balance["towers"]) >= 7
assert len({tower["id"] for tower in balance["towers"]}) == len(balance["towers"])
progression = balance["progression"]
for key, length in (("damage_multipliers",4), ("range_additions",4), ("aura_bonuses",4), ("upgrade_multipliers",3)):
    assert len(progression[key]) == length and all(isinstance(value, (float, int)) and value >= 0 for value in progression[key]), key
assert 0 <= progression["refund_factor"] < 1
for tower in balance["towers"]:
    for key in ("cost", "range"):
        assert tower[key] > 0, (tower["id"], key)
    assert tower["behavior"] in {"single", "splash", "slow", "poison", "chain", "pierce", "aura"}
    if tower["behavior"] == "aura":
        assert tower["damage"] == tower["cooldown"] == 0
        assert 0 < tower["aura_bonus"] < 1
    else:
        assert tower["damage"] > 0 and tower["cooldown"] > 0
    for key in {"poison": ["poison_dps", "poison_duration"], "chain": ["chain_jumps", "chain_radius", "chain_decay"], "pierce": ["pierce_hits", "pierce_tolerance"]}.get(tower["behavior"], []):
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
from check_localization import check, catalogue
english = catalogue("en")
for tower in balance["towers"]:
    assert tower["name_key"] in english and tower["description_key"] in english
    assert len(tower["id"]) > 0
check()
print("OK: balance, resource references, audio")
