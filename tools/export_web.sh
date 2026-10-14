#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")/.."
GODOT_BIN="${GODOT_BIN:-godot}"
export GODOT_BIN
case "$("$GODOT_BIN" --version)" in
  4.6.3.stable*) ;;
  *) echo 'Brug Godot 4.6.3 stable og de tilhørende export templates.' >&2; exit 1 ;;
esac
mkdir -p builds/web test-results
"$GODOT_BIN" --headless --editor --import --quit
"$GODOT_BIN" --headless --script tests/test_chapter.gd
"$GODOT_BIN" --headless --script tests/test_layouts.gd
"$GODOT_BIN" --headless --export-release Web builds/web/index.html
python3 tools/prepare_pwa.py
python3 tools/check_web_export.py
