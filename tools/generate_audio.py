"""Regenerate the project's original short sound effects using Python stdlib."""
import math
from pathlib import Path
import struct
import wave

OUTPUT = Path(__file__).resolve().parents[1] / "assets" / "audio"
OUTPUT.mkdir(parents=True, exist_ok=True)
for name, frequencies in {"build": [520, 780], "wave": [220, 330, 440]}.items():
    samples = []
    for frequency in frequencies:
        count = int(22050 * 0.09)
        for i in range(count):
            envelope = math.sin(math.pi * i / count) ** 2
            samples.append(int(7500 * envelope * math.sin(2 * math.pi * frequency * i / 22050)))
    with wave.open(str(OUTPUT / f"{name}.wav"), "wb") as audio:
        audio.setnchannels(1)
        audio.setsampwidth(2)
        audio.setframerate(22050)
        audio.writeframes(struct.pack(f"<{len(samples)}h", *samples))
