#!/usr/bin/env bash
set -euo pipefail

dir="${1:?dir (left|right|up|down)}"
step_ratio="${2:-0.05}" # for layoutmsg colresize/rowresize
step_px="${3:-40}"      # for resizeactive (floating)

# Detect if active window is floating (no jq needed)
floating="$(
  python -c 'import sys,json; print("1" if json.load(sys.stdin).get("floating") else "0")' \
    <<<"$(hyprctl -j activewindow)"
)"

if [[ "$floating" == "1" ]]; then
  # Floating: pixel-based resize
  case "$dir" in
  right) hyprctl dispatch -- resizeactive "$step_px 0" ;;
  left) hyprctl dispatch -- resizeactive "-$step_px 0" ;;
  up) hyprctl dispatch -- resizeactive "0 -$step_px" ;;
  down) hyprctl dispatch -- resizeactive "0 $step_px" ;;
  esac
else
  # Tiled: ratio-based resize (works with master layout)
  case "$dir" in
  left) hyprctl dispatch -- layoutmsg "colresize -$step_ratio" ;;
  right) hyprctl dispatch -- layoutmsg "colresize +$step_ratio" ;;
  up) hyprctl dispatch -- resizeactive "0 -$step_px" ;;
  down) hyprctl dispatch -- resizeactive "0 $step_px" ;;
  esac
fi
