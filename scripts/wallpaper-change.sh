#!/usr/bin/env bash
set -euo pipefail

# Placeholder wallpaper. Pass a path as the first argument to override it.
WALLPAPER="${1:-$HOME/Pictures/Wallpapers/ember.jpg}"

# Quoting prevents the shell from expanding a leading tilde.
if [[ "$WALLPAPER" == "~/"* ]]; then
    WALLPAPER="$HOME/${WALLPAPER#\~/}"
fi

# hyprpaper requires an absolute path.
if [[ "$WALLPAPER" != /* ]]; then
    WALLPAPER="$PWD/$WALLPAPER"
fi

if [[ ! -f "$WALLPAPER" ]]; then
    printf 'Wallpaper not found: %s\n' "$WALLPAPER" >&2
    exit 1
fi

if command -v hyprctl >/dev/null 2>&1; then
    hyprctl hyprpaper unload all >/dev/null 2>&1 || true
    if hyprctl hyprpaper preload "$WALLPAPER" >/dev/null 2>&1; then
        hyprctl hyprpaper wallpaper ",$WALLPAPER" >/dev/null 2>&1 || \
            printf 'hyprpaper could not apply the wallpaper.\n' >&2
    else
        printf 'hyprpaper is not reachable; wallpaper unchanged.\n' >&2
    fi
else
    printf 'hyprctl is not available; wallpaper unchanged.\n' >&2
fi

if command -v matugen >/dev/null 2>&1; then
    matugen image "$WALLPAPER" --mode dark
else
    printf 'matugen is not available; palette unchanged.\n' >&2
fi
