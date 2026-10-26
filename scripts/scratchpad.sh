#!/usr/bin/env bash
set -euo pipefail

if ! command -v hyprctl >/dev/null 2>&1; then
    printf 'hyprctl is required for the scratchpad.\n' >&2
    exit 1
fi

if ! command -v kitty >/dev/null 2>&1; then
    printf 'kitty is required for the scratchpad.\n' >&2
    exit 1
fi

if ! hyprctl clients -j | grep -Eq '"class"[[:space:]]*:[[:space:]]*"scratchpad"'; then
    kitty --class scratchpad --title Scratchpad >/dev/null 2>&1 &
fi

hyprctl dispatch togglespecialworkspace magic >/dev/null
