#!/bin/zsh
set -eu
workspace="$(cd -- "$(dirname -- "$0")/.." && pwd)"
trial_project="$workspace/.grimdark-loop/campus_batch1_20261012/project"
godot_bin="/Applications/Godot.app/Contents/MacOS/Godot"
if [[ ! -x "$godot_bin" || ! -f "$trial_project/project.godot" ]]; then
  print "找不到 Godot 或校园篇试玩版本。"
  exit 1
fi
exec "$godot_bin" --path "$trial_project" --log-file "$workspace/.grimdark-loop/campus_batch1_20261012/playtest.log"
