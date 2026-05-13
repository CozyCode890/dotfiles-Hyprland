#!/usr/bin/env bash
set -euo pipefail

state_file="${XDG_RUNTIME_DIR:-/tmp}/hypr-last-tiled"

json="$(hyprctl -j activewindow 2>/dev/null || echo '{}')"

# Parse with python (no jq needed)
floating="$(python -c 'import sys,json; d=json.load(sys.stdin); print("1" if d.get("floating") else "0")' <<<"$json")"
addr="$(python -c 'import sys,json; d=json.load(sys.stdin); print(d.get("address",""))' <<<"$json")"

if [[ "$floating" == "0" ]]; then
  # Currently tiled: remember it, then focus a floating window (first floating on this workspace)
  [[ -n "$addr" ]] && printf '%s' "$addr" >"$state_file"
  hyprctl dispatch focuswindow floating >/dev/null 2>&1 || true
else
  # Currently floating: go back to the last tiled window if we have one
  if [[ -s "$state_file" ]]; then
    last="$(cat "$state_file")"
    # focuswindow supports address:... :contentReference[oaicite:1]{index=1}
    hyprctl dispatch focuswindow "address:$last" >/dev/null 2>&1 ||
      hyprctl dispatch focuswindow tiled >/dev/null 2>&1 || true
  else
    hyprctl dispatch focuswindow tiled >/dev/null 2>&1 || true
  fi
fi
