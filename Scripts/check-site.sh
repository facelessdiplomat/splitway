#!/usr/bin/env bash
set -euo pipefail

site_root="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/Site}"
missing=0

target_exists() {
    local path="$1"
    if [[ -d "$path" ]]; then
        [[ -f "$path/index.html" ]]
    else
        [[ -f "$path" ]]
    fi
}

while IFS= read -r -d '' page; do
    directory="$(dirname "$page")"
    while IFS= read -r reference; do
        case "$reference" in
            http://* | https://* | mailto:* | \#*) continue ;;
        esac
        location="${reference%%#*}"
        location="${location%%\?*}"
        [[ -z "$location" ]] && continue
        if ! target_exists "$directory/$location"; then
            printf '%s: broken link %s\n' "${page#"$site_root"/}" "$reference" >&2
            missing=$((missing + 1))
        fi
    done < <(grep -oE '(href|src)="[^"]*"' "$page" | sed -E 's/^(href|src)="(.*)"$/\2/')
done < <(find "$site_root" -name '*.html' -print0)

if ((missing > 0)); then
    printf '%d broken links in %s\n' "$missing" "$site_root" >&2
    exit 1
fi
printf 'Site links are intact\n'
