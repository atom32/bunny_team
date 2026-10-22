"""Original short synthetic warning / coolant cues; deterministic and no game RNG changes."""
from pathlib import Path
import math
import random
import struct
import wave

root = Path(__file__).resolve().parents[1] / 'assets/audio'
rate = 44100
rng = random.Random(2041)

for name, seconds in [('blockade_lock', .42), ('blockade_vent', .38)]:
    samples = []
    phase = 0.0
    for i in range(round(rate * seconds)):
        t = i / rate
        envelope = min(1, t / .012, (seconds-t) / .045)
        if name == 'blockade_lock':
            frequency = 430 + 520 * t / seconds
            envelope *= 0 if .13 < t < .20 else 1
            phase += math.tau * frequency / rate
            value = .16 * math.sin(phase) * envelope
        else:
            phase += math.tau * (340-170*t/seconds) / rate
            value = (.085 * rng.uniform(-1,1) + .055 * math.sin(phase)) * envelope * (1-t/seconds)
        samples.append(round(value * 32767))
    assert max(map(abs,samples)) < 32767
    with wave.open(str(root / (name+'.wav')), 'wb') as f:
        f.setparams((1, 2, rate, len(samples), 'NONE', 'not compressed'))
        f.writeframes(struct.pack('<'+'h'*len(samples), *samples))
    print(name, len(samples), 'samples; peak', max(map(abs,samples)))
