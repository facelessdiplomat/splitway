#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$repository_root/Scripts/lib/xcode-environment.sh"
source "$repository_root/Scripts/lib/lint-checks.sh"
cd "$repository_root"

go_module_roots=(Packages/TunnelCore/go Scripts/go-comment-check)

repository_files() {
    git ls-files --cached --others --exclude-standard -- "$@"
}

existing_directories() {
    for directory in "$@"; do
        if [[ -d "$directory" ]]; then
            printf '%s\n' "$directory"
        fi
    done
}

swift_files=()
while IFS= read -r file; do
    [[ -f "$file" ]] && swift_files+=("$file")
done < <(repository_files 'Packages/*.swift' 'Apps/*.swift' 'IntegrationTests/*.swift' 'UITests/*.swift')

go_files=()
while IFS= read -r file; do
    [[ -f "$file" ]] && go_files+=("$file")
done < <(repository_files 'Packages/*.go' 'Scripts/*.go')

go_roots=()
while IFS= read -r directory; do
    go_roots+=("$repository_root/$directory")
done < <(existing_directories "${go_module_roots[@]}")

secret_scan_files=()
stray_tunnel_configurations=()
while IFS= read -r -d '' file; do
    if [[ ! -f "$file" ]] || is_fixture_path "$file"; then
        continue
    fi
    secret_scan_files+=("$file")
    if [[ "$file" == *.conf ]]; then
        stray_tunnel_configurations+=("$file")
    fi
done < <(git ls-files -z --cached --others --exclude-standard)

printf '==> WireGuard secrets\n'
if (( ${#stray_tunnel_configurations[@]} > 0 )); then
    printf 'Tunnel configurations must stay outside the repository:\n' >&2
    printf '  %s\n' "${stray_tunnel_configurations[@]}" >&2
    exit 1
fi
if (( ${#secret_scan_files[@]} > 0 )) && find_wireguard_secrets "${secret_scan_files[@]}" >&2; then
    printf 'WireGuard keys must never be committed, keep real configurations outside the repository\n' >&2
    exit 1
fi

if (( ${#swift_files[@]} > 0 )); then
    printf '==> Linter suppressions\n'
    if find_linter_suppressions "${swift_files[@]}"; then
        printf 'Suppressing linter rules is forbidden, fix the code instead\n' >&2
        exit 1
    fi
    printf '==> SwiftLint\n'
    swiftlint lint --quiet --config .swiftlint.yml "${swift_files[@]}"
    printf '==> swift-format\n'
    xcrun swift-format lint --strict --configuration .swift-format "${swift_files[@]}"
fi

if (( ${#go_files[@]} > 0 )); then
    printf '==> gofmt\n'
    unformatted_go_files="$(gofmt -l "${go_files[@]}")"
    if [[ -n "$unformatted_go_files" ]]; then
        printf 'gofmt reports unformatted files:\n%s\n' "$unformatted_go_files" >&2
        exit 1
    fi
    printf '==> Go comments\n'
    (cd Scripts/go-comment-check && go run . "${go_roots[@]}")
fi

printf 'Lint passed\n'
