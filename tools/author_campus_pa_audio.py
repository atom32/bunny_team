"""Reproduce the project-authored campus PA chirp without external recordings."""
from pathlib import Path
import io
import math
import struct
import wave


def render() -> bytes:
    rate = 44100
    frames = bytearray()
    for index in range(int(rate * .7)):
        t = index / rate
        envelope = min(1, t / .025, (.7 - t) / .09)
        value = .11 * envelope * (math.sin(2 * math.pi * (690 * t + 110 * t * t)) + .2 * math.sin(2 * math.pi * 1380 * t))
        frames.extend(struct.pack('<h', int(max(-1, min(1, value)) * 32767)))
    buffer = io.BytesIO()
    with wave.open(buffer, 'wb') as stream:
        stream.setnchannels(1)
        stream.setsampwidth(2)
        stream.setframerate(rate)
        stream.writeframes(frames)
    return buffer.getvalue()


if __name__ == '__main__':
    target = Path(__file__).resolve().parents[1] / 'assets/audio/campus_pa.wav'
    data = render()
    if target.exists():
        if target.read_bytes() != data:
            raise SystemExit('Existing PA audio differs; refusing to overwrite it.')
        print('Verified identical PA audio; existing file and timestamp preserved.')
    else:
        target.write_bytes(data)
        print('Created original procedural PA chirp.')
