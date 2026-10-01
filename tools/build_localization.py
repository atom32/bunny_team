"""Build the Godot translation resource from the reviewed Chinese catalog."""
import json
import re
from pathlib import Path

root = Path(__file__).resolve().parents[1]
source = root / "localization/zh_CN.json"
messages = json.loads(source.read_text())
placeholders = re.compile(r"%(?:[-+0-9.]*[sdf])")
for english, chinese in messages.items():
    # Literal percentages in descriptive prose are not interpolation templates.
    if placeholders.findall(english) != placeholders.findall(chinese):
        raise ValueError(f"Interpolation placeholders differ: {english!r}")
quote = lambda value: "&" + json.dumps(value, ensure_ascii=False)
lines = [f"{quote(key)}: {quote(value)}" for key, value in messages.items()]
(root / "localization/zh_CN.tres").write_text(
    '[gd_resource type="Translation" format=3]\n\n[resource]\n'
    'locale = "zh_CN"\nmessages = {\n' + ",\n".join(lines) + "\n}\n"
)
print(f"Built {len(messages)} Chinese translation entries")
