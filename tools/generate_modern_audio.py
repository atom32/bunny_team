"""Deterministic synthesized game cues, no third-party recordings or dependencies."""
from pathlib import Path
import math
import random
import struct
import wave

OUT = Path(__file__).resolve().parents[1] / "assets/audio"
CONFIG = {
    "pistol": (.22, 155, .045, 101),
    "shotgun": (.48, 70, .11, 102),
    "sniper": (.55, 95, .085, 103),
    "lmg": (.19, 115, .05, 104),
}
for name, (duration, frequency, decay, seed) in CONFIG.items():
    rng = random.Random(seed)
    samples = []
    low = 0.0
    for index in range(int(duration * 44100)):
        t = index / 44100
        noise = rng.uniform(-1, 1)
        low += .14 * (noise - low)
        attack = min(1, t / .0008)
        crack = (noise - low) * .48 * math.exp(-t / (decay * .37))
        body = math.sin(2 * math.pi * frequency * t) * .48 * math.exp(-t / decay)
        tail = low * .6 * math.exp(-t / (decay * 2))
        samples.append(struct.pack("<h", round(max(-.95, min(.95, attack * (crack + body + tail))) * 32767)))
    with wave.open(str(OUT / ("modern_" + name + ".wav")), "wb") as stream:
        stream.setparams((1, 2, 44100, 0, "NONE", "not compressed"))
        stream.writeframes(b"".join(samples))
