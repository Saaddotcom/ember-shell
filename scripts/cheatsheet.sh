#!/usr/bin/env bash
set -euo pipefail

trim() {
    local value="$1"
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    printf '%s' "$value"
}

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "$script_dir/../binds.conf" && -f "$script_dir/../hyprland.conf" ]]; then
    hypr_dir="$(cd -- "$script_dir/.." && pwd)"
elif [[ -f "$script_dir/../hypr/binds.conf" && -f "$script_dir/../hypr/hyprland.conf" ]]; then
    hypr_dir="$(cd -- "$script_dir/../hypr" && pwd)"
else
    printf 'Could not find Hyprland configuration files.\n' >&2
    exit 1
fi

binds_file="$hypr_dir/binds.conf"
hyprland_file="$hypr_dir/hyprland.conf"

if [[ ! -t 1 ]]; then
    if ! command -v kitty >/dev/null 2>&1; then
        printf 'kitty is required to display the cheatsheet.\n' >&2
        exit 1
    fi

    exec kitty --class cheatsheet --title "Ember Shell Keybindings" "$0"
fi

main_mod="SUPER"
terminal="kitty"

while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ $line =~ ^[[:space:]]*\$mainMod[[:space:]]*=[[:space:]]*([^[:space:]#]+) ]]; then
        main_mod="${BASH_REMATCH[1]}"
    elif [[ $line =~ ^[[:space:]]*\$terminal[[:space:]]*=[[:space:]]*([^[:space:]#]+) ]]; then
        terminal="${BASH_REMATCH[1]}"
    fi
done < "$hyprland_file"

build_cheatsheet() {
    local section="General"
    local last_section=""
    local line comment rest mods key dispatcher args binding action
    local -a mod_parts

    printf 'Ember Shell - Keybindings\n'
    printf 'Generated from hypr/binds.conf\n'

    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line%$'\r'}"

        if [[ $line =~ ^[[:space:]]*#[[:space:]]*(.*)$ ]]; then
            comment="$(trim "${BASH_REMATCH[1]}")"
            if [[ -n "$comment" ]]; then
                section="$comment"
            fi
            continue
        fi

        if [[ $line =~ ^[[:space:]]*bind[a-z]*[[:space:]]*=[[:space:]]*(.*)$ ]]; then
            rest="${BASH_REMATCH[1]}"
            IFS=',' read -r mods key dispatcher args <<< "$rest"

            mods="$(trim "$mods")"
            key="$(trim "$key")"
            dispatcher="$(trim "$dispatcher")"
            args="$(trim "${args:-}")"

            if [[ -z "$key" || -z "$dispatcher" ]]; then
                continue
            fi

            mods="${mods//\$mainMod/$main_mod}"
            read -r -a mod_parts <<< "$mods"
            mods="${mod_parts[*]}"
            mods="${mods// / + }"
            key="${key^^}"

            if [[ -n "$mods" ]]; then
                binding="$mods + $key"
            else
                binding="$key"
            fi

            if [[ -n "$args" ]]; then
                action="$dispatcher $args"
            else
                action="$dispatcher"
            fi
            action="${action//\$terminal/$terminal}"

            if [[ "$section" != "$last_section" ]]; then
                printf '\n%s\n' "$section"
                last_section="$section"
            fi

            printf '  %-28s %s\n' "$binding" "$action"
        fi
    done < "$binds_file"

    printf '\nEdit hypr/binds.conf to change this list.\n'
}

if command -v less >/dev/null 2>&1; then
    build_cheatsheet | less -R
else
    build_cheatsheet
    printf '\nPress Enter to close...'
    read -r _ || true
fi
