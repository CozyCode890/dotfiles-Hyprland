#!/usr/bin/env bash
set -euo pipefail

US="keyboard-us"
UN="lotus"

cur="$(fcitx5-remote -n 2>/dev/null || true)"
[[ -z "${cur:-}" ]] && exit 0

if [[ "${cur,,}" == "${US}" ]]; then
  fcitx5-remote -s "$UN" >/dev/null 2>&1 || true
else
  fcitx5-remote -s "$US" >/dev/null 2>&1 || true
fi
